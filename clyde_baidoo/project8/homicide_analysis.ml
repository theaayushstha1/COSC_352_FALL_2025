type homicide = {
  date: string;
  year: int;
  month: int;
  victim_name: string;
  victim_age: int option;
  victim_race: string;
  victim_gender: string;
  weapon: string;
  neighborhood: string;
  district: string;
  disposition: string;
}

let safe_trim s = String.trim s

let safe_substring s start len =
  try String.sub s start len
  with _ -> ""

let split_csv_line line =
  let len = String.length line in
  let rec parse acc current in_quote pos =
    if pos >= len then
      List.rev (safe_trim current :: acc)
    else
      let c = String.get line pos in
      match c with
      | '"' -> parse acc current (not in_quote) (pos + 1)
      | ',' when not in_quote ->
          parse (safe_trim current :: acc) "" false (pos + 1)
      | _ -> parse acc (current ^ String.make 1 c) in_quote (pos + 1)
  in
  parse [] "" false 0

let parse_int s =
  try Some (int_of_string (safe_trim s))
  with _ -> None

let parse_homicide fields =
  match fields with
  | date :: name :: age :: race :: gender :: weapon :: neighborhood :: district :: disposition :: _ ->
      let year = parse_int (safe_substring date 0 4) in
      let month = parse_int (safe_substring date 5 2) in
      (match year, month with
       | Some y, Some m ->
           Some {
             date = date;
             year = y;
             month = m;
             victim_name = name;
             victim_age = parse_int age;
             victim_race = safe_trim race;
             victim_gender = safe_trim gender;
             weapon = safe_trim weapon;
             neighborhood = safe_trim neighborhood;
             district = safe_trim district;
             disposition = safe_trim disposition;
           }
       | _ -> None)
  | _ -> None

let read_csv filename =
  let ic = open_in filename in
  let rec read_lines acc =
    try
      let line = input_line ic in
      read_lines (line :: acc)
    with End_of_file ->
      close_in ic;
      List.rev acc
  in
  let lines = read_lines [] in
  match lines with
  | [] -> []
  | _ :: data_lines ->
      List.filter_map (fun line -> parse_homicide (split_csv_line line)) data_lines


let homicides_by_year homicides =
  let add_to_year_map map h =
    let count = try List.assoc h.year map with Not_found -> 0 in
    (h.year, count + 1) :: List.remove_assoc h.year map
  in
  List.fold_left add_to_year_map [] homicides
  |> List.sort (fun (y1, _) (y2, _) -> compare y1 y2)

let calculate_trend yearly_data =
  let n = float_of_int (List.length yearly_data) in
  if n < 2.0 then "Insufficient data" else
    let sum_x, sum_y, sum_xy, sum_x2 =
      List.fold_left (fun (sx, sy, sxy, sx2) (x, y) ->
        let fx = float_of_int x and fy = float_of_int y in
        (sx +. fx, sy +. fy, sxy +. fx *. fy, sx2 +. fx *. fx)
      ) (0., 0., 0., 0.) yearly_data
    in
    let slope = (n *. sum_xy -. sum_x *. sum_y) /. (n *. sum_x2 -. sum_x *. sum_x) in
    if slope > 1.0 then Printf.sprintf "Increasing (+%.0f/year)" slope
    else if slope < -1.0 then Printf.sprintf "Decreasing (%.0f/year)" slope
    else "Stable"

let top_neighborhoods n homicides =
  let add_to_map map h =
    if h.neighborhood = "" then map else
      let count = try List.assoc h.neighborhood map with Not_found -> 0 in
      (h.neighborhood, count + 1) :: List.remove_assoc h.neighborhood map
  in
  let counts = List.fold_left add_to_map [] homicides in
  let sorted = List.sort (fun (_, c1) (_, c2) -> compare c2 c1) counts in
  let rec take n lst =
    match n, lst with
    | 0, _ | _, [] -> []
    | n, x :: xs -> x :: take (n - 1) xs
  in
  take n sorted

let weapon_distribution homicides =
  let add_weapon map h =
    let w = if h.weapon = "" then "Unknown" else h.weapon in
    let count = try List.assoc w map with Not_found -> 0 in
    (w, count + 1) :: List.remove_assoc w map
  in
  List.fold_left add_weapon [] homicides
  |> List.sort (fun (_, c1) (_, c2) -> compare c2 c1)

let demographics homicides =
  let total = List.length homicides in
  let ages = List.filter_map (fun h -> h.victim_age) homicides in
  let avg_age =
    if ages = [] then 0.0
    else float_of_int (List.fold_left (+) 0 ages) /. float_of_int (List.length ages)
  in
  
  let add_race map h =
    let r = if h.victim_race = "" then "Unknown" else h.victim_race in
    let count = try List.assoc r map with Not_found -> 0 in
    (r, count + 1) :: List.remove_assoc r map
  in
  let races = List.fold_left add_race [] homicides
              |> List.sort (fun (_, c1) (_, c2) -> compare c2 c1) in
  
  let add_gender map h =
    let g = if h.victim_gender = "" then "Unknown" else h.victim_gender in
    let count = try List.assoc g map with Not_found -> 0 in
    (g, count + 1) :: List.remove_assoc g map
  in
  let genders = List.fold_left add_gender [] homicides
                |> List.sort (fun (_, c1) (_, c2) -> compare c2 c1) in
  
  (avg_age, races, genders, total)

let pct part total =
  if total = 0 then 0.0
  else (float_of_int part /. float_of_int total) *. 100.0

let print_header () =
  print_endline "\n╔════════════════════════════════════════╗";
  print_endline "║  Baltimore Homicides Analysis Tool    ║";
  print_endline "║  Functional Programming in OCaml       ║";
  print_endline "╚════════════════════════════════════════╝\n"

let print_sep () =
  print_endline "\n========================================\n"

let print_yearly_analysis homicides =
  print_endline "ANALYSIS 1: HOMICIDES PER YEAR";
  print_sep ();
  let yearly = homicides_by_year homicides in
  let total = List.fold_left (fun acc (_, c) -> acc + c) 0 yearly in
  List.iter (fun (year, count) ->
    Printf.printf "%d: %4d homicides (%.1f%%)\n" year count (pct count total)
  ) yearly;
  Printf.printf "\nTotal: %d homicides\n" total;
  Printf.printf "Trend: %s\n" (calculate_trend yearly)

let print_neighborhood_analysis homicides =
  print_sep ();
  print_endline "ANALYSIS 2: TOP 10 NEIGHBORHOODS";
  print_sep ();
  let top = top_neighborhoods 10 homicides in
  List.iteri (fun i (name, count) ->
    Printf.printf "%2d. %-40s %4d (%.1f%%)\n" 
      (i+1) name count (pct count (List.length homicides))
  ) top

let print_weapon_analysis homicides =
  print_sep ();
  print_endline "ANALYSIS 3: WEAPON DISTRIBUTION";
  print_sep ();
  let weapons = weapon_distribution homicides in
  let total = List.length homicides in
  List.iter (fun (weapon, count) ->
    Printf.printf "%-30s %4d (%.1f%%)\n" weapon count (pct count total)
  ) weapons

let print_demographic_analysis homicides =
  print_sep ();
  print_endline "ANALYSIS 4: VICTIM DEMOGRAPHICS";
  print_sep ();
  let (avg_age, races, genders, total) = demographics homicides in
  Printf.printf "Average age: %.1f years\n\n" avg_age;
  print_endline "Race:";
  List.iter (fun (race, count) ->
    Printf.printf "  %-20s %4d (%.1f%%)\n" race count (pct count total)
  ) races;
  print_endline "\nGender:";
  List.iter (fun (gender, count) ->
    Printf.printf "  %-20s %4d (%.1f%%)\n" gender count (pct count total)
  ) genders

let () =
  print_header ();
  let filename =
    if Array.length Sys.argv > 1 then Sys.argv.(1)
    else "baltimore_homicides_combined.csv"
  in
  try
    Printf.printf "Loading data from: %s\n" filename;
    let homicides = read_csv filename in
    if List.length homicides = 0 then (
      Printf.eprintf "\nError: No valid records found in %s\n" filename;
      Printf.eprintf "Please check your CSV file format.\n";
      exit 1
    ) else (
      Printf.printf "✓ Loaded %d homicide records\n" (List.length homicides);
      print_yearly_analysis homicides;
      print_neighborhood_analysis homicides;
      print_weapon_analysis homicides;
      print_demographic_analysis homicides;
      print_sep ();
      print_endline "Analysis complete!\n"
    )
  with
  | Sys_error msg ->
      Printf.eprintf "\nError: %s\n" msg;
      Printf.eprintf "Make sure the CSV file exists and is readable.\n";
      exit 1