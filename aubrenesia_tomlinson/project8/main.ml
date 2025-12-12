(* ===================================================== *)
(* Baltimore Homicide Analysis Tool                      *)
(* ===================================================== *)

type homicide = {
  id : int;
  date_died : string;
  name : string;
  age : int option;
  address : string;
  notes : string;
  no_violent_history : bool option;
  camera_present : bool option;
  case_closed : bool option;  (* will always be Some true/false *)
  source_page : string;
  year : int;
  lat : float option;
  lon : float option;
}



let to_int_opt s =
  try Some (int_of_string s) with _ -> None

let to_float_opt s =
  try Some (float_of_string s) with _ -> None

let to_bool_opt s =
  match String.lowercase_ascii s with
  | "true" | "yes" | "1" -> Some true
  | "false" | "no"  | "0" -> Some false
  | _ -> None


let parse_case_closed s =
  let s = String.lowercase_ascii (String.trim s) in
  match s with
  | "closed" -> Some true
  | "" -> Some false
  | _ -> Some false

let split_csv_line line =
  String.split_on_char ',' line |> List.map String.trim



let parse_homicide line =
  match split_csv_line line with
  | id_s :: date_died :: name :: age_s :: address :: notes
    :: no_hist :: camera :: case_closed_s :: source_page
    :: year_s :: lat_s :: lon_s :: _ ->

      let id = to_int_opt id_s in
      let year = to_int_opt year_s in

      (* Rows without ID or year are invalid — skip them *)
      begin match (id, year) with
      | (Some id, Some year) ->
          Some {
            id;
            date_died;
            name;
            age = to_int_opt age_s;
            address;
            notes;
            no_violent_history = to_bool_opt no_hist;
            camera_present = to_bool_opt camera;
            case_closed = parse_case_closed case_closed_s;
            source_page;
            year;
            lat = to_float_opt lat_s;
            lon = to_float_opt lon_s;
          }
      | _ ->
          None  (* skip malformed rows *)
      end

  | _ -> None


let read_csv filename =
  let ic = open_in filename in
  ignore (input_line ic); (* skip header line *)
  let rec loop acc =
    match input_line ic with
    | line ->
        let acc =
          match parse_homicide line with
          | Some h -> h :: acc
          | None -> acc
        in loop acc
    | exception End_of_file ->
        close_in ic;
        List.rev acc
  in loop []


let homicides_per_year homicides =
  List.fold_left
    (fun acc h ->
      let current =
        match List.assoc_opt h.year acc with Some v -> v | None -> 0
      in
      (h.year, current + 1) :: List.remove_assoc h.year acc)
    [] homicides
  |> List.sort (fun (y1, _) (y2, _) -> compare y1 y2)

let case_closed_stats homicides =
  List.fold_left
    (fun (closed, open_) h ->
      match h.case_closed with
      | Some true -> (closed + 1, open_)
      | Some false -> (closed, open_ + 1)
      | None -> (closed, open_)  (* shouldn't happen now *)
    )
    (0, 0) homicides


let () =
  let filename = "baltimore_homicides_combined.csv" in
  let homicides = read_csv filename in

  print_endline "====== HOMICIDES PER YEAR ======";
  homicides_per_year homicides
  |> List.iter (fun (year, count) ->
         Printf.printf "%d: %d homicides\n" year count);

  print_endline "\n====== CASE-CLOSED STATS ======";
  let (closed, open_) = case_closed_stats homicides in
  Printf.printf "Closed cases: %d\n" closed;
  Printf.printf "Open cases:   %d\n" open_;
