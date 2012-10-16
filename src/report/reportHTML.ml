(*
 * This file is part of Bisect.
 * Copyright (C) 2008-2012 Xavier Clerc.
 *
 * Bisect is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * Bisect is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *)

open ReportUtils

let css =  [
  "body {" ;
  "    background: white;" ;
  "    white-space: nowrap;" ;
  "}" ;
  "" ;
  ".title {" ;
  "    font-size: xx-large;" ;
  "    font-weight: bold;" ;
  "}" ;
  "" ;
  ".section {" ;
  "    font-size: larger;" ;
  "    font-weight: bold;" ;
  "}" ;
  "" ;
  ".footer {" ;
  "    font-size: smaller;" ;
  "    text-align: center;" ;
  "}" ;
  "" ;
  ".codeSep {" ;
  "    border: none 0;" ;
  "    border-top: 1px solid gray;" ;
  "    height: 1px;" ;
  "}" ;
  "" ;
  ".indexSep {" ;
  "    border: none 0;" ;
  "    border-top: 1px solid gray;" ;
  "    height: 1px;" ;
  "    width: 75%;" ;
  "}" ;
  "" ;
  ".lineNone { white-space: nowrap; background: white; font-family: monospace; }" ;
  ".lineAllVisited { white-space: nowrap; background: #30FF6A; font-family: monospace; }" ;
  ".lineAllUnvisited { white-space: nowrap; background: #FF4423; font-family: monospace; }" ;
  ".lineMixed { white-space: nowrap; background: #E4FF5B; font-family: monospace; }" ;
  "" ;
  "table.simple {" ;
  "    border-width: 1px;" ;
  "    border-spacing: 0px;" ;
  "    border-top-style: solid;" ;
  "    border-bottom-style: solid;" ;
  "    border-color: black;" ;
  "    font-size: smaller;" ;
  "}" ;
  "" ;
  "table.simple th {" ;
  "    border-width: 1px;" ;
  "    border-spacing: 0px;" ;
  "    border-bottom-style: solid;" ;
  "    border-color: black;" ;
  "    text-align: center;" ;
  "    font-weight: bold;" ;
  "}" ;
  "" ;
  "table.simple td {" ;
  "    border-width: 1px;" ;
  "    border-spacing: 0px;" ;
  "    border-style: none;" ;
  "}" ;
  "" ;
  "table.gauge {" ;
  "    border-width: 0px;" ;
  "    border-spacing: 0px;" ;
  "    padding: 0px;" ;
  "    border-style: none;" ;
  "    border-collapse: collapse;" ;
  "    font-size: smaller;" ;
  "}" ;
  "" ;
  "table.gauge td {" ;
  "    border-width: 0px;" ;
  "    border-spacing: 0px;" ;
  "    padding: 0px;" ;
  "    border-style: none;" ;
  "    border-collapse: collapse;" ;
  "}" ;
  "" ;
  ".gaugeOK { background: green; }" ;
  ".gaugeKO { background: red; }" ;
  ".gaugeNO { background: gray; }" ;
  ""
]

let output_css filename =
  Common.try_out_channel
    false
    filename
    (fun channel -> output_strings css [] channel)

let html_footer =
  let time = current_time () in
  Printf.sprintf "Generated by <a href=\"%s\">Bisect %s</a> on %s"
    url
    Version.value
    time

let html_of_stats s =
  let len = List.length s in
  let s1, s2 = split_after ((succ len) / 2) s in
  let hos s =
    [ "$(tabs)<table class=\"simple\">" ;
      "$(tabs)  <tr><th>kind</th><th width=\"16px\">&nbsp;</th><th>coverage</th></tr>" ] @
    (List.map
       (fun (k, r) ->
         Printf.sprintf "$(tabs)  <tr><td>%s</td><td width=\"16px\">&nbsp;</td><td>%d / %d (%s%%)</td></tr>"
           (Common.string_of_point_kind k)
           r.ReportStat.count
           r.ReportStat.total
           (if r.ReportStat.total <> 0 then
             string_of_int ((r.ReportStat.count * 100) / r.ReportStat.total)
           else
             "-"))
       s) @
    [ "$(tabs)</table>" ] in
  (hos s1), (hos s2)

let output_html_index verbose title filename l =
  verbose "Writing index file ...";
  Common.try_out_channel
    false
    filename
    (fun channel ->
      let stats =
        List.fold_left
          (fun acc (_, _, s) -> ReportStat.add acc s)
          (ReportStat.make ())
          l in
      output_strings
        [  "<html>" ;
           "  <head>" ;
           "    <title>$(title)</title>" ;
           "    <link rel=\"stylesheet\" type=\"text/css\" href=\"style.css\">" ;
           "  </head>" ;
           "  <body>" ;
           "    <div class=\"title\">$(title)</div>" ;
           "    <br/>" ;
           "    <hr class=\"indexSep\"/>" ;
           "    <center>" ;
           "    <br/>" ;
           "    <div class=\"section\">Overall statistics</div>" ;
           "    <table>" ;
           "      <tr>" ;
           "        <td valign=\"top\">" ]
        [ "title", title ]
        channel;
      let st1, st2 = html_of_stats stats in
      output_strings
        st1
        ["tabs", "          "]
        channel;
      output_strings
        [  "        </td>" ;
           "        <td valign=\"top\">" ]
        []
        channel;
      output_strings
        st2
        ["tabs", "          "]
        channel;
      output_strings
        [ "        </td>" ;
          "      </tr>" ;
          "    </table>" ;
          "    <br/>" ;
          "    </center>" ;
          "    <br/>" ;
          "    <hr class=\"indexSep\"/>" ;
          "    <center>" ;
          "    <br/>" ;
          "    <div class=\"section\">Per-file coverage</div>" ;
          "      <table class=\"simple\">" ;
          "        <tr>" ;
          "          <th>coverage</th>" ;
          "          <th width=\"16px\">&nbsp;</th>" ;
          "          <th>file</th>";
          "        </tr>" ]
        []
        channel;
      let gauge stats name =
        let a, b = ReportStat.summarize stats in
        let x = if b = 0 then 100 else (100 * a) / b in
        let y = 100 - x in
        output_strings
          [ "        <tr>" ;
            "          <td>" ;
            "            <table class=\"gauge\">" ;
            "              <tr>" ;
            "                <td class=\"$(g)\" width=\"$(x)px\"/>" ;
            "                <td class=\"gaugeKO\" width=\"$(y)px\"/>" ;
            "                <td>&nbsp;$(p)%</td>" ;
            "              </tr>" ;
            "            </table>" ;
            "          </td>" ;
            "          <td width=\"16px\">&nbsp;</td>" ;
            "          <td>$(name)</td>";
            "        </tr>" ]
          [ "g", (if b = 0 then "gaugeNO" else "gaugeOK");
            "x", string_of_int x ;
            "y", string_of_int y ;
            "p", (if b = 0 then "-" else string_of_int x) ;
            "name", name ]
          channel in
      List.iter
        (fun (in_file, out_file, stats) ->
          gauge stats (Printf.sprintf "<a href=\"%s\">%s</a>" out_file in_file))
        l;
      gauge stats "<i>total</i>";
      output_strings
        [ "      </table>" ;
          "    </center>" ;
          "    <br/>" ;
          "    <hr class=\"indexSep\"/>" ;
          "    <p class=\"footer\">$(footer)</p>" ;
          "  </body>" ;
          "</html>" ]
        ["footer", html_footer]
        channel)

let escape_line tab_size line offset points =
  let buff = Buffer.create (String.length line) in
  let ofs = ref offset in
  let pts = ref points in
  let marker n =
    Buffer.add_string buff "(*[";
    Buffer.add_string buff (string_of_int n);
    Buffer.add_string buff "]*)" in
  let marker_if_any () =
    match !pts with
    | (o, n) :: tl when o = !ofs ->
        marker n;
        pts := tl
    | _ -> () in
  String.iter
    (fun ch ->
      marker_if_any ();
      (match ch with
      | '<' -> Buffer.add_string buff "&lt;"
      | '>' -> Buffer.add_string buff "&gt;"
      | ' ' -> Buffer.add_string buff "&nbsp;"
      | '\"' -> Buffer.add_string buff "&quot;"
      | '&' -> Buffer.add_string buff "&amp;"
      | '\t' -> for _i = 1 to tab_size do Buffer.add_string buff "&nbsp;" done
      | _ -> Buffer.add_char buff ch);
      incr ofs)
    line;
  List.iter (fun (_, n) -> marker n) !pts;
  Buffer.contents buff

let output_html verbose tab_size title no_navbar no_folding in_file out_file script_file script_file_basename resolver visited =
  verbose (Printf.sprintf "Processing file '%s' ..." in_file);
  let cmp_content = Common.read_points (resolver in_file) in
  verbose (Printf.sprintf "... file has %d points" (List.length cmp_content));
  let len = Array.length visited in
  let stats = ReportStat.make () in
  let pts = ref (List.map
                    (fun (ofs, pt, k) ->
                      let nb = if pt < len then visited.(pt) else 0 in
                      ReportStat.update stats k (nb > 0);
                      (ofs, nb))
                    cmp_content) in
  let in_channel, out_channel = open_both in_file out_file in
  (try
    let navbar_script =
      if no_navbar then
        []
      else
        [ "    <script type=\"text/javascript\">" ;
          "      <!--" ;
          "        function jump(id) {" ;
          "          document.body.scrollTop = document.getElementById(id).offsetTop;" ;
          "        }" ;
          "      -->" ;
          "    </script>" ] in
    output_strings
      ([ "<html>" ;
         "  <head>" ;
         "    <title>$(title)</title>" ;
         "    <link rel=\"stylesheet\" type=\"text/css\" href=\"style.css\">" ] @
       navbar_script @
       (if no_folding then
         []
       else
         [ "    <script language=\"javascript\" src=\"$(script_file)\"></script>" ]) @
       [ "  </head>" ;
         "  <body>" ;
         "    <div class=\"section\">File: $(in_file) (<a href=\"index.html\">return to index</a>)</div>" ;
         "    <br/>" ;
         "    <hr class=\"codeSep\"/>" ;
         "    <br/>" ;
         "    <table>" ;
         "      <tr>" ;
         "        <td valign=\"top\" class=\"section\">Statistics:&nbsp;&nbsp;</td>" ;
         "        <td valign=\"top\">" ])
      [ "in_file", in_file ;
        "title", title ;
        "script_file", script_file_basename ]
      out_channel;
    let st1, st2 = html_of_stats stats in
    output_strings
      st1
      ["tabs", "          "]
      out_channel;
    output_strings
      [  "        </td>" ;
         "        <td valign=\"top\">" ]
      []
      out_channel;
    output_strings
      st2
      ["tabs", "          "]
      out_channel;
    let fold_links =
      if no_folding then
        []
      else
        [ "<div style=\"font-size: smaller;\">" ^
          "<a href=\"javascript:foldAll();\">fold all</a> " ^
          "<a href=\"javascript:unfoldAll();\">unfold all</a>" ^
          "</div>" ] in
    output_strings
      ([ "        </td>" ;
         "      </tr>" ;
         "    </table>" ;
         "    <br/>" ;
         "    <hr class=\"codeSep\"/>" ;
         "    <br/>" ;
         "    <div class=\"section\">Source:</div>" ;
         "    <br/>" ] @
       fold_links @
       [ "    <code>" ])
      []
      out_channel;
    let line_no = ref 0 in
    let navigator = ref [] in
    let fold_starts = ref [] in
    let fold_ends = ref [] in
    (try
      while true do
        incr line_no;
        let start_ofs = pos_in in_channel in
        let line = input_line in_channel in
        let end_ofs = pos_in in_channel in
        let before, after = split (fun (o, _) -> o < end_ofs) !pts in
        let line' = escape_line tab_size line start_ofs before in
        let visited, unvisited =
          List.fold_left
            (fun (v, u) (_, nb) ->
              ((v || (nb > 0)), (u || (nb = 0))))
            (false, false)
            before in
        let jump =
          Printf.sprintf " style=\"cursor: pointer;\" onclick=\"javascript:jump('line%06d');\" title=\"jump to line %d\""
            !line_no
            !line_no in
        let cls, nav_color, nav_elements, foldable = match visited, unvisited with
        | false, false -> "lineNone", "gray", "", true
        | true, false -> "lineAllVisited", "gray", "", true
        | false, true -> "lineAllUnvisited", "red", jump, false
        | true, true -> "lineMixed", "yellow", jump, false in
        let starting_fold =
          if foldable && (List.length !fold_starts) = (List.length !fold_ends) then begin
            fold_starts := !line_no :: !fold_starts;
            output_strings
              [ "      <div id=\"fold$(line_no)\">" ]
              [ "line_no", (Printf.sprintf "%06d" !line_no) ]
              out_channel;
            true
          end else
            false in
        if (not foldable) && (List.length !fold_starts) <> (List.length !fold_ends) then begin
          fold_ends := (pred !line_no) :: !fold_ends;
          output_strings
            [ "      </div>" ]
            [ ]
            out_channel
        end;
        let nav_line =
          Printf.sprintf "        <tr><td bgcolor=\"%s\"%s></td></tr>"
            nav_color
            nav_elements in
        navigator := nav_line :: !navigator;
        let icon =
          if no_folding then
            ""
          else if starting_fold then
            Printf.sprintf
              "<a href=\"javascript:fold('fold%06d');\"><img border=\"0\" height=\"10\" width=\"10\" src=\"minus.png\" title=\"fold code\"/></a>"
              !line_no
          else if foldable then
            "<img border=\"0\" height=\"10\" width=\"10\"src=\"dash.png\"/>"
          else
            "<img border=\"0\" height=\"10\" width=\"10\"src=\"blank.png\"/>" in
        output_strings
          [ "      <div id=\"line$(line_no)\" class=\"$(cls)\">$(icon)$(line_no)| $(line)</div>" ]
          [ "cls", cls ;
            "line_no", (Printf.sprintf "%06d" !line_no) ;
            "line", (if line' = "" then "&nbsp;" else line') ;
            "icon", icon ]
          out_channel;
        pts := after
      done
    with End_of_file -> ());
    if (List.length !fold_starts) <> (List.length !fold_ends) then begin
      fold_ends := (pred !line_no) :: !fold_ends;
      output_strings
        [ "      </div>" ]
        [ ]
        out_channel
    end;
    let navigator_div =
      if no_navbar then
        []
      else
        [ "    <div id=\"navigator\" style=\"border: solid black 1px; position: fixed; z-index:100; right: 10px; top: 10px; bottom: 10px; width: 16px;\">" ;
          "      <table width=\"100%\" height=\"100%\" border=\"0\" cellspacing=\"0\">" ] @
        (List.rev !navigator) @
        [ "      </table>" ;
          "    </div>" ] in
    output_strings
      ([ "    </code>" ;
         "    <br/>" ] @
       navigator_div @
       [ "    <div class=\"section\">Legend:</div>" ;
         "    &nbsp;&nbsp;&nbsp;<span class=\"lineNone\">some code</span>&nbsp;-&nbsp;line containing no point<br/>" ;
         "    &nbsp;&nbsp;&nbsp;<span class=\"lineAllVisited\">some code</span>&nbsp;-&nbsp;line containing only visited points<br/>" ;
         "    &nbsp;&nbsp;&nbsp;<span class=\"lineAllUnvisited\">some code</span>&nbsp;-&nbsp;line containing only unvisited points<br/>" ;
         "    &nbsp;&nbsp;&nbsp;<span class=\"lineMixed\">some code</span>&nbsp;-&nbsp;line containing both visited and unvisited points<br/>" ;
         "    <br/>" ;
         "    <hr class=\"codeSep\"/>" ;
         "    <p class=\"footer\">$(html_footer)</p>" ;
         "  </body>" ;
         "</html>" ])
      [ "html_footer", html_footer ]
      out_channel;
    Common.try_out_channel
      false
      script_file
      (fun channel ->
        output_strings
          [ "var texts = new Array();" ;
            "var states = new Array();" ;
            "" ]
          []
          channel;
        List.iter2
          (fun fstart fend ->
            output_strings
              [ "texts['$(id)'] = '$(icon)<i>&nbsp;&nbsp;code folded from line $(start) to line $(end)</i>';" ;
                "states['$(id)'] = false;" ]
              [ "id", (Printf.sprintf "fold%06d" fstart) ;
                "icon",
                (Printf.sprintf
                   "<a href=\"javascript:fold(\\'fold%06d\\');\"><img border=\"0\" height=\"10\" width=\"10\" src=\"plus.png\" title=\"unfold code\"/></a>"
                   fstart) ;
                "start", string_of_int fstart ;
                "end", string_of_int fend ]
              channel)
          (List.rev !fold_starts)
          (List.rev !fold_ends);
        output_strings
          [ "" ;
            "function fold(id) {" ;
            "  tmp = document.getElementById(id).innerHTML;" ;
            "  document.getElementById(id).innerHTML = texts[id];" ;
            "  texts[id] = tmp;" ;
            "  states[id] = !(states[id]);" ;
            "}" ;
            "" ;
            "function unfoldAll() {" ;
            "  for (key in states) {" ;
            "    if (states[key]) {" ;
            "      fold(key);" ;
            "    }" ;
            "  }" ;
            "}" ;
            "" ;
            "function foldAll() {" ;
            "  for (key in states) {" ;
            "    if (!(states[key])) {" ;
            "      fold(key);" ;
            "    }" ;
            "  }" ;
            "}" ]
          []
          channel)
  with e ->
    close_in_noerr in_channel;
    close_out_noerr out_channel;
    raise e);
  close_in_noerr in_channel;
  close_out_noerr out_channel;
  stats

let blank_png = [|
  0x89; 0x50; 0x4e; 0x47; 0x0d; 0x0a; 0x1a; 0x0a;
  0x00; 0x00; 0x00; 0x0d; 0x49; 0x48; 0x44; 0x52;
  0x00; 0x00; 0x00; 0x0a; 0x00; 0x00; 0x00; 0x0a;
  0x08; 0x06; 0x00; 0x00; 0x00; 0x8d; 0x32; 0xcf;
  0xbd; 0x00; 0x00; 0x00; 0x01; 0x73; 0x52; 0x47;
  0x42; 0x00; 0xae; 0xce; 0x1c; 0xe9; 0x00; 0x00;
  0x00; 0x06; 0x62; 0x4b; 0x47; 0x44; 0x00; 0xff;
  0x00; 0xff; 0x00; 0xff; 0xa0; 0xbd; 0xa7; 0x93;
  0x00; 0x00; 0x00; 0x09; 0x70; 0x48; 0x59; 0x73;
  0x00; 0x00; 0x0b; 0x13; 0x00; 0x00; 0x0b; 0x13;
  0x01; 0x00; 0x9a; 0x9c; 0x18; 0x00; 0x00; 0x00;
  0x07; 0x74; 0x49; 0x4d; 0x45; 0x07; 0xd9; 0x05;
  0x03; 0x0e; 0x18; 0x19; 0xcf; 0x5e; 0xda; 0x4a;
  0x00; 0x00; 0x00; 0x0e; 0x49; 0x44; 0x41; 0x54;
  0x18; 0xd3; 0x63; 0x60; 0x18; 0x05; 0x83; 0x13;
  0x00; 0x00; 0x01; 0x9a; 0x00; 0x01; 0x0b; 0xa2;
  0x9d; 0x1f; 0x00; 0x00; 0x00; 0x00; 0x49; 0x45;
  0x4e; 0x44; 0xae; 0x42; 0x60; 0x82
|]

let dash_png = [|
  0x89; 0x50; 0x4e; 0x47; 0x0d; 0x0a; 0x1a; 0x0a;
  0x00; 0x00; 0x00; 0x0d; 0x49; 0x48; 0x44; 0x52;
  0x00; 0x00; 0x00; 0x0a; 0x00; 0x00; 0x00; 0x0a;
  0x08; 0x06; 0x00; 0x00; 0x00; 0x8d; 0x32; 0xcf;
  0xbd; 0x00; 0x00; 0x00; 0x01; 0x73; 0x52; 0x47;
  0x42; 0x00; 0xae; 0xce; 0x1c; 0xe9; 0x00; 0x00;
  0x00; 0x06; 0x62; 0x4b; 0x47; 0x44; 0x00; 0xff;
  0x00; 0xff; 0x00; 0xff; 0xa0; 0xbd; 0xa7; 0x93;
  0x00; 0x00; 0x00; 0x09; 0x70; 0x48; 0x59; 0x73;
  0x00; 0x00; 0x0b; 0x13; 0x00; 0x00; 0x0b; 0x13;
  0x01; 0x00; 0x9a; 0x9c; 0x18; 0x00; 0x00; 0x00;
  0x07; 0x74; 0x49; 0x4d; 0x45; 0x07; 0xd9; 0x05;
  0x03; 0x0e; 0x1b; 0x28; 0xb5; 0xad; 0x89; 0xb3;
  0x00; 0x00; 0x00; 0x1e; 0x49; 0x44; 0x41; 0x54;
  0x18; 0xd3; 0x63; 0x60; 0xa0; 0x39; 0x70; 0x71;
  0x71; 0xf9; 0xef; 0xe2; 0xe2; 0xf2; 0x1f; 0x5d;
  0x9c; 0x89; 0x58; 0x03; 0x86; 0x82; 0x42; 0xea;
  0x03; 0x00; 0x56; 0x54; 0x03; 0xa1; 0x79; 0x35;
  0xf3; 0x91; 0x00; 0x00; 0x00; 0x00; 0x49; 0x45;
  0x4e; 0x44; 0xae; 0x42; 0x60; 0x82
|]

let minus_png = [|
  0x89; 0x50; 0x4e; 0x47; 0x0d; 0x0a; 0x1a; 0x0a;
  0x00; 0x00; 0x00; 0x0d; 0x49; 0x48; 0x44; 0x52;
  0x00; 0x00; 0x00; 0x0a; 0x00; 0x00; 0x00; 0x0a;
  0x08; 0x02; 0x00; 0x00; 0x00; 0x02; 0x50; 0x58;
  0xea; 0x00; 0x00; 0x00; 0x01; 0x73; 0x52; 0x47;
  0x42; 0x00; 0xae; 0xce; 0x1c; 0xe9; 0x00; 0x00;
  0x00; 0x2e; 0x49; 0x44; 0x41; 0x54; 0x18; 0xd3;
  0x63; 0x60; 0xc0; 0x0b; 0x18; 0x19; 0x18; 0x18;
  0xfe; 0xff; 0xff; 0x8f; 0x5d; 0x8e; 0x91; 0x91;
  0x09; 0xbf; 0x6e; 0x02; 0xd2; 0x0c; 0xb8; 0x0c;
  0x87; 0x08; 0x12; 0xd0; 0xcd; 0x82; 0xc7; 0x00;
  0xc2; 0xba; 0x89; 0x70; 0x1a; 0x1e; 0x00; 0x00;
  0x96; 0x20; 0x0c; 0x07; 0xfb; 0x84; 0xbf; 0x6c;
  0x00; 0x00; 0x00; 0x00; 0x49; 0x45; 0x4e; 0x44;
  0xae; 0x42; 0x60; 0x82
|]

let plus_png = [|
  0x89; 0x50; 0x4e; 0x47; 0x0d; 0x0a; 0x1a; 0x0a;
  0x00; 0x00; 0x00; 0x0d; 0x49; 0x48; 0x44; 0x52;
  0x00; 0x00; 0x00; 0x0a; 0x00; 0x00; 0x00; 0x0a;
  0x08; 0x02; 0x00; 0x00; 0x00; 0x02; 0x50; 0x58;
  0xea; 0x00; 0x00; 0x00; 0x01; 0x73; 0x52; 0x47;
  0x42; 0x00; 0xae; 0xce; 0x1c; 0xe9; 0x00; 0x00;
  0x00; 0x37; 0x49; 0x44; 0x41; 0x54; 0x18; 0xd3;
  0x63; 0x60; 0xc0; 0x0b; 0x18; 0x19; 0x18; 0x18;
  0xfe; 0xff; 0xff; 0x8f; 0x5d; 0x8e; 0x91; 0x91;
  0x09; 0x8d; 0xcf; 0xc8; 0xc8; 0x88; 0x2c; 0xc2;
  0xc4; 0x40; 0x10; 0x60; 0x35; 0x1c; 0x22; 0x48;
  0x40; 0x37; 0x0b; 0xb2; 0x5a; 0x88; 0xc5; 0xc8;
  0x86; 0x11; 0xa7; 0x1b; 0x8f; 0x23; 0xf0; 0x01;
  0x00; 0x63; 0xaf; 0x12; 0x0c; 0x9b; 0x01; 0xf8;
  0x13; 0x00; 0x00; 0x00; 0x00; 0x49; 0x45; 0x4e;
  0x44; 0xae; 0x42; 0x60; 0x82
|]

let output_png_files dir =
  List.iter
    (fun (file, data) ->
      output_bytes data (Filename.concat dir file))
    [ "blank.png", blank_png ;
      "dash.png",  dash_png ;
      "minus.png", minus_png ;
      "plus.png",  plus_png ]

let output verbose dir tab_size title no_navbar no_folding resolver data =
  let files = Hashtbl.fold
      (fun in_file visited acc ->
        let l = List.length acc in
        let basename = Printf.sprintf "file%04d" l in
        let out_file = (Filename.concat dir basename) ^ ".html" in
        let script_file = (Filename.concat dir basename) ^ ".js" in
        let script_file_basename = basename ^ ".js" in
        let stats = output_html verbose tab_size title no_navbar no_folding in_file out_file script_file script_file_basename resolver visited in
        (in_file, (basename ^ ".html"), stats) :: acc)
      data
      [] in
  if not no_folding then output_png_files dir;
  output_html_index verbose title (Filename.concat dir "index.html") (List.sort compare files);
  output_css (Filename.concat dir "style.css")
