-module(main).
-export([fac_tr/1, right_triangles/1, max/1]).

main(_) ->
    Result1 = fac_tr(10),
    io:format("~p~n", [Result1]).
    Result2 = right_triangles(32),
    io:format("~p~n", [Result2]).
    Result3 = max([2, 0, 2, 6]),
    io:format("~p~n", [Result3]).

-spec fac_tr(N :: integer()) -> integer().
fac_tr(N) ->
    fac_tr(N, 1).

fac_tr(0, Acc) ->
    Acc;
fac_tr(N, Acc) ->
    fac_tr(N - 1, N * Acc).
    
-spec right_triangles(N) -> [{A, B, C}]
    when N :: integer(),
         A :: integer(),
         B :: integer(),
         C :: integer().
right_triangles(N) ->
    L = lists:seq(1, N),
    [{A, B, C} || A <- L, B <- L, C <- L, A * A + B * B == C * C].
    
-spec max(L) -> M
    when L :: [integer()],
         M :: integer().
max([H | T]) ->
    F = fun(X, Y) when X > Y -> X; (X, Y) -> Y end,
    lists:foldl(F, H, T).