(* Project 8 – Baltimore Homicides, OCaml *)

(* Define homicide record type *)
type homicide = {
  id : string;
  year : int option;
  month : int option;
  neighborhood : string;
  weapon : string;
  age : int option;
  gender : string;
}

(* Utility: safe int parsing *)
let int_of_string_opt s =
  match String.trim s with
  | "" -> None
  | x -> (try Some (int_of_string x) with _ -> None)

(* Split a CSV line on commas (naive, assumes no embedded commas). *)
let split_commas line =
  let rec aux i j acc =
    if j = String.length line then
      let field = String.sub line i (j - i) in
      List.rev (field :: acc)
    else if line.[j] = ',' then
      let field = String.sub line i (j - i) in
      aux (j + 1) (j + 1) (field :: acc)
    else
      aux i (j + 1) acc
  in
  aux 0 0 []

(* Parse a CSV row into a homicide record. Adjust indices to match the dataset. *)
let homicide_of_row row =
  match row with
  | id :: year :: month :: _date :: _time :: _loc :: neighborhood :: weapon :: age :: gender :: _rest ->
      {
        id;
        year = int_of_string_opt year;
        month = int_of_string_opt month;
        neighborhood = String.trim neighborhood;
        weapon = String.trim weapon;
        age = int_of_string_opt age;
        gender = String.trim gender;
      }
  | _ ->
      (* Skip malformed rows by raising; caller will filter. *)
      failwith "Malformed row"

(* Read all lines from stdin, skipping header, and parse to records. *)
let read_homicides_from_channel ic =
  let rec read_lines acc =
    match input_line ic with
    | line -> read_lines (line :: acc)
    | exception End_of_file -> List.rev acc
  in
  let lines = read_lines [] in
  match lines with
  | [] -> []
  | _header :: rows ->
      rows
      |> List.map (fun l -> split_commas l)
      |> List.filter_map (fun cols ->
             try Some (homicide_of_row cols) with _ -> None)

(* Analysis 1: homicides per year *)
let homicides_per_year homicides =
  let add_year m h =
    match h.year with
    | None -> m
    | Some y ->
        let count = try List.assoc y m with Not_found -> 0 in
        (y, count + 1) :: List.remove_assoc y m
  in
  List.fold_left add_year [] homicides
  |> List.sort (fun (y1, _) (y2, _) -> compare y1 y2)

let top_neighborhoods n homicides =
  let add_nb m h =
    let nb = h.neighborhood in
    let count = try List.assoc nb m with Not_found -> 0 in
    (nb, count + 1) :: List.remove_assoc nb m
  in
  let counts = List.fold_left add_nb [] homicides in
  let sorted = List.sort (fun (_, c1) (_, c2) -> compare c2 c1) counts in
  let rec take k lst =
    match (k, lst) with
    | 0, _ | _, [] -> []
    | k, x :: xs -> x :: take (k - 1) xs
  in
  take n sorted

(* Pretty-print helpers (I/O only in main) *)
let print_year_stats stats =
  List.iter (fun (y, c) -> Printf.printf "%d: %d homicides\n" y c) stats

let print_top_neighborhoods stats =
  List.iter (fun (nb, c) -> Printf.printf "%s: %d homicides\n" nb c) stats

let () =
  (* Main: read CSV from file path given as first arg *)
  if Array.length Sys.argv < 2 then (
    prerr_endline "Usage: baltimore_homicides <csv_path>";
    exit 1
  );
  let csv_path = Sys.argv.(1) in
  let ic = open_in csv_path in
  let homicides = read_homicides_from_channel ic in
  close_in ic;

  (* Analysis 1: homicides per year *)
  print_endline "Homicides per year:";
  homicides_per_year homicides |> print_year_stats;

  print_endline "";

  (* Analysis 2: top 10 neighborhoods by incidence *)
  print_endline "Top 10 neighborhoods by incidence:";
  top_neighborhoods 10 homicides |> print_top_neighborhoods;
