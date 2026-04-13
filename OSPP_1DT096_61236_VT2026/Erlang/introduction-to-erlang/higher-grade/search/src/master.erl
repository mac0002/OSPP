% l(master), l(server), l(worker).
% master:start(10, 1, 100).

-module(master).

-export([start/3, stop/1]).

init() ->
    maps:new().

%% @doc Starts the server and `NumWorkers' workers. The server is started with a
%% random secret number between `Min' and `Max'.

-spec start(NumWorkers, Min, Max) -> Master when
      NumWorkers :: integer(),
      Min :: integer(),
      Max :: integer(),
      Master :: pid().

start(NumWorkers, Min, Max) ->
    Secret = utils:random(Min, Max),
    Server = server:start(Secret),
    Master = spawn(fun() -> loop(NumWorkers, init()) end),

    [worker:start(Server, Master, Min, Max) || _ <- lists:seq(1, NumWorkers)],

    Master.

% log_guess(Master, Worker) ->
%     Master ! {guess, Worker}.

%% @doc Stops the `Master'.

-spec stop(Master) -> stop when 
      Master :: pid().

stop(Master) ->
    Master ! stop.

loop(0, Map) ->
    % io:format("DONE ~p~n", [Map]);
    io:format("Final Statistics from the master:~n~n"),
    % Winners = maps:filter(fun(_K, V) -> V =:= {_, _, winner} end, Map),
    % Losers = maps:filter(fun(_K, V) -> V =:= {_, _, loser} end, Map),
    % io:format("~p => ~p~n", maps:filter(fun(K, V) -> V /= {_, _, loser} end, Map)),
    [io:format("~p => ~p~n", [K, V]) || {K, V = {_, _, winner}} <- maps:to_list(Map)],
    [io:format("~p => ~p~n", [K, V]) || {K, V = {_, _, loser}} <- maps:to_list(Map)];

loop(CountDown, Map) ->
    % process_flag(trap_exit, true),
    receive
        {wrong, GuessInfo, Worker} ->
            loop(CountDown, maps:update(Worker, GuessInfo, Map));
        {correct, GuessInfo, Worker} ->
            io:format("Someone guessed correctly!~n~n"),
            % ResultMap = maps:update(Worker, GuessInfo, Map),
            ResultMap = maps:map(fun(K, V) ->
                {A, B, _} = V,
                case K == Worker of
                    false -> {A, B, loser};
                    true -> GuessInfo
                end
            end, Map),
            % [Loser ! {'EXIT', self(), loser} || {Loser, {_GuessNum, _Guess, loser}} <- maps:to_list(ResultMap)],
            % io:format("Final statistics from the master:~n~n"),
            % [io:format("~p => ~p~n", [K, V]) || {K, V} <- maps:to_list(ResultMap)];
            loop(0, ResultMap);
        {too_late, GuessInfo, Worker} -> 
            Worker ! {'EXIT', self(), loser}, 
            loop(CountDown - 1, maps:update(Worker, GuessInfo, Map));
        print ->
            % io:format("~p~n", [Map]),
            io:format("Statistics from the master:~n~n"),
            [io:format("~p => ~p~n", [K, V]) || {K, V} <- maps:to_list(Map)],
            loop(CountDown, Map);
        stop  ->
            ok;
        {worker_started, Worker} ->
            loop(CountDown, maps:put(Worker, {0, 0, just_started}, Map));
        Msg ->
            io:format("master:loop/2 Unknown message ~p~n", [Msg]),
            loop(CountDown, Map)
    end.
