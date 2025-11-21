(* Project 8: Functional analytics on Baltimore homicides *)

(* --- Types --- *)
type homicide = {
  date : string;
  year : int;
  month : int;
  address_block : string;
  notes : string;
  victim_age : int option;
  victim_name : string;
}

(* --- Helpers --- *)
let safe_int s =
  try Some (int_of_string s) with _ -> None

let parse_date_to_year_month (date_str : string) : int * int =
  (* Dates are like "01/02/20" *)
  match String.split_on_char '/' date_str with
  | m :: _d :: y :: _ ->
      let yy =
        match safe_int y with
        | Some v when String.length y = 2 -> 2000 + v
        | Some v -> v
        | None -> 0
      in
      let mm = match safe_int m with Some v -> v | None -> 0 in
      (yy, mm)
  | _ -> (0, 0)

let trim s =
  let is_space = function ' ' | '\t' | '\r' | '\n' -> true | _ -> false in
  let len = String.length s in
  let rec left i = if i < len && is_space s.[i] then left (i+1) else i in
  let rec right i = if i >= 0 && is_space s.[i] then right (i-1) else i in
  let l = left 0 and r = right (len-1) in
  if r < l then "" else String.sub s l (r - l + 1)

(* --- Row -> homicide mapping --- *)
let row_to_homicide headers row : homicide option =
  let get col =
    try
      let idx = List.fold_left (fun acc (i, h) -> if h = col then i else acc) (-1)
        (List.mapi (fun i h -> (i, h)) headers)
      in if idx >= 0 then List.nth row idx |> trim else ""
    with _ -> ""
  in
  let date = get "Date Died" in
  let name = get "Name" in
  let age = get "Age" |> trim |> safe_int in
  let address_block = get "Address Block Found" in
  let notes = get "Notes" in
  let year =
    match safe_int (get "year" |> trim) with
    | Some yy -> yy
    | None -> 0
  in
  let _, month = parse_date_to_year_month date in
  if year = 0 then None
  else
    Some { date; year; month; address_block; notes; victim_age = age; victim_name = name }

(* --- Analyses --- *)

(* 1) Homicides per year *)
let homicides_per_year (hs : homicide list) : (int * int) list =
  let counts =
    List.fold_left
      (fun acc h ->
         let prev = try List.assoc h.year acc with Not_found -> 0 in
         (h.year, prev + 1) :: List.remove_assoc h.year acc)
      [] hs
  in
  List.sort (fun (y1, _) (y2, _) -> compare y1 y2) counts

(* 2) Top N address blocks by incidence *)
let top_addresses n (hs : homicide list) : (string * int) list =
  let counts =
    List.fold_left
      (fun acc h ->
         let key = String.trim h.address_block in
         if key = "" then acc
         else
           let prev = try List.assoc key acc with Not_found -> 0 in
           (key, prev + 1) :: List.remove_assoc key acc)
      [] hs
  in
  let sorted = List.sort (fun (_, c1) (_, c2) -> compare c2 c1) counts in
  let rec take k lst =
    match (k, lst) with
    | 0, _ -> []
    | _, [] -> []
    | k, x :: xs -> x :: take (k - 1) xs
  in
  take n sorted

(* --- Pretty printers --- *)
let pp_year_counts counts =
  List.map (fun (y, c) -> Printf.sprintf "%d,%d" y c) counts
  |> String.concat "\n"

let pp_top_addresses pairs =
  List.map (fun (n, c) -> Printf.sprintf "%s,%d" n c) pairs
  |> String.concat "\n"

(* --- Main --- *)
let () =
  let csv_path =
    try Sys.getenv "CSV_PATH"
    with Not_found -> "data/baltimore_homicides_combined.csv"
  in
  let table = Csv.load csv_path in
  match table with
  | [] ->
      Printf.printf "Empty CSV at %s\n%!" csv_path
  | headers :: rows ->
      let homicides =
        rows
        |> List.filter_map (row_to_homicide headers)
      in
      let year_counts = homicides_per_year homicides in
      let top5 = top_addresses 5 homicides in
      Printf.printf "Homicides per year (year,count):\n%s\n\n%!"
        (pp_year_counts year_counts);
      Printf.printf "Top 5 address blocks (address,count):\n%s\n%!"
        (pp_top_addresses top5)
