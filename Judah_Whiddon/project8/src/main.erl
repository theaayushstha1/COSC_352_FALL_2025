%% src/main.erl
-module(main).
-export([start/0]).

start() ->
    FilePath = "data/baltimore_homicides_combined.csv",
    io:format("Loading data from ~s...~n", [FilePath]),
    Rows = parser:load_rows(FilePath),

    Total        = analytics:count_total(Rows),
    WeaponCounts = analytics:count_by_weapon(Rows),

    %% TOTAL HOMICIDES
    io:format("=== Total Homicides in Dataset ===~n"),
    io:format("Total: ~B~n~n", [Total]),

    %% WEAPON DISTRIBUTION
    io:format("=== Weapon Type Distribution ===~n"),
    print_weapon_counts(WeaponCounts),

    ok.

%% ---------------------------------------------------------
%% Weapon printing (NO DUPLICATES)
%% ---------------------------------------------------------

print_weapon_counts(Map) ->
    Pairs = maps:to_list(Map),
    print_weapon_pairs(Pairs).

print_weapon_pairs([]) ->
    ok;
print_weapon_pairs([{Weapon, Count} | Rest]) ->
    io:format("~s : ~B~n", [Weapon, Count]),
    print_weapon_pairs(Rest).
