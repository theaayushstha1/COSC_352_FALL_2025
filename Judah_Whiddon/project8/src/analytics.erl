%% src/analytics.erl
-module(analytics).
-export([count_total/1, count_by_weapon/1]).

%% Rows look like: #{date := "01/02/20", weapon := "Shooting"}

%% ============================================================
%% TOTAL HOMICIDE COUNT
%% ============================================================

count_total(Rows) ->
    length(Rows).

%% ============================================================
%% WEAPON DISTRIBUTION
%% ============================================================

count_by_weapon(Rows) ->
    lists:foldl(fun add_weapon/2, #{}, Rows).

add_weapon(#{weapon := Weapon}, Acc) ->
    Old = maps:get(Weapon, Acc, 0),
    Acc#{ Weapon => Old + 1 }.

