%% src/parser.erl
-module(parser).
-export([load_rows/1]).

%% ============================================================
%% Load CSV
%% ============================================================

load_rows(Path) ->
    {ok, Bin} = file:read_file(Path),
    Text = binary_to_list(Bin),
    Lines = string:split(Text, "\n", all),
    DataLines = tl(Lines),  %% drop header
    parse_lines(DataLines, []).

parse_lines([], Acc) ->
    lists:reverse(Acc);
parse_lines([Line | Rest], Acc) ->
    Stripped = string:trim(Line),
    case Stripped of
        "" ->
            parse_lines(Rest, Acc);
        _ ->
            RowMap = build_row_map(Stripped),
            parse_lines(Rest, [RowMap | Acc])
    end.

%% ============================================================
%% Build a record (date string + weapon)
%% ============================================================

build_row_map(Line) ->
    %% split on commas; the 2nd field is always the Date Died
    Fields  = string:split(Line, ",", all),
    DateStr = get_field(Fields, 2),
    Weapon  = infer_weapon(Line),
    #{date => DateStr, weapon => Weapon}.

%% Safe index (1-based); return "" if missing
get_field(Fields, N) ->
    case lists:nthtail(N - 1, Fields) of
        [Value | _] -> string:trim(Value);
        _           -> ""
    end.

%% ============================================================
%% Weapon Inference (NO GUARDS)
%% ============================================================

infer_weapon(Line) ->
    Lower = string:lowercase(Line),
    case string:find(Lower, "shoot") of
        nomatch ->
            case string:find(Lower, "stab") of
                nomatch ->
                    case string:find(Lower, "blunt") of
                        nomatch ->
                            case string:find(Lower, "fire") of
                                nomatch -> "Other/Unknown";
                                _       -> "Fire"
                            end;
                        _ -> "Blunt force"
                    end;
                _ -> "Stabbing"
            end;
        _ -> "Shooting"
    end.
