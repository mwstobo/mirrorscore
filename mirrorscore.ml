open Lwt.Infix

module StringMap = Map.Make(String)

let extract_score acc remote_mirror =
  let url = Yojson.Basic.Util.member "url" remote_mirror |> Yojson.Basic.Util.to_string in
  let score = Yojson.Basic.Util.member "score" remote_mirror |> Yojson.Basic.Util.to_number_option in
  match score with
  | None -> acc
  | Some score -> ((Printf.sprintf "%s%s" url "$repo/os/$arch"), score) :: acc

let get_remote_scores =
  Uri.of_string "https://www.archlinux.org/mirrors/status/json/"
  |> Cohttp_lwt_unix.Client.get >>= fun (resp, body) ->
  Cohttp_lwt.Body.to_string body >|= fun body ->
  let status_code = Cohttp.Code.code_of_status resp.status in
  if Cohttp.Code.is_error status_code then Error status_code
  else
    Ok begin
      Yojson.Basic.from_string body
      |> Yojson.Basic.Util.member "urls"
      |> Yojson.Basic.Util.to_list
      |> List.fold_left extract_score []
      |> fun l -> (StringMap.empty |> StringMap.add_seq (List.to_seq l))
    end

let get_score remote_scores acc mirror =
  match StringMap.find_opt mirror remote_scores with
  | None -> prerr_endline (Printf.sprintf "ERROR: No such mirror: %s" mirror); acc
  | Some score -> (mirror,  score) :: acc

let rec read_stdin acc =
  try read_stdin (input_line stdin :: acc)
  with End_of_file -> acc

let () =
  let mirrorlist = read_stdin [] in
  Lwt_main.run begin
    get_remote_scores >|= function
      Ok remote_scores ->
        mirrorlist
        |> List.map (Str.global_replace (Str.regexp_string "Server = ") "")
        |> List.fold_left (get_score remote_scores) []
        |> List.stable_sort (fun s1 s2 -> Float.compare (snd s1) (snd s2))
        |> List.map fst
        |> List.map (Printf.sprintf "%s%s" "Server = ")
        |> List.iter print_endline
    | Error code ->
      prerr_endline (Printf.sprintf "ERROR: Failed to fetch scores with code %d" code)
  end
