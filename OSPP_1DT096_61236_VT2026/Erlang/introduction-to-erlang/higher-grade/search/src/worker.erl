-module(worker).

-export([start/4]).

%% @doc Starts a worker process. The worker will make random guesses between
%% `Min' and `Max'.

-spec start(Server, Master, Min, Max) -> Worker when
      Server :: pid(), 
      Master :: pid(),
      Min :: number(), 
      Max :: number(),
      Worker :: pid().

start(Server, Master, Min, Max) ->
   spawn(fun() -> loop(Server, Master, Min, Max, 0, true) end).

-spec loop(Server, Master, Min, Max, Guesses, Init) -> ok when
      Server :: pid(), 
      Master :: pid(),
      Min :: number(), 
      Max :: number(),
      Guesses :: integer(),
      Init :: boolean().
loop(Server, Master, Min, Max, Guesses, Init) ->
    case Init of
        false ->
            ok;
        true ->
            timer:sleep(100),
            % process_flag(trap_exit, true),
            Master ! {worker_started, self()},
            loop(Server, Master, Min, Max, Guesses, false)
    end,
    timer:sleep(utils:random(100, 300)),
    Guess = utils:random(Min, Max),
    Server ! {guess, Guess, self()},
    % master:log_guess(Master, self()),

    receive
        {wrong, Guess} ->
            io:format("~p ~*.. B Nope :(~n", [self(), utils:width(Max), Guess]),
            Master ! {wrong, {Guesses + 1, Guess, searching}, self()},
            loop(Server, Master, Min, Max, Guesses + 1, false);
        {right, Guess} ->
            io:format("~p ~*.. B <=== FOUND IT :-)~n", [self(), utils:width(Max), Guess]),
            Master ! {correct, {Guesses + 1, Guess, winner}, self()},
            exit(winner);
        {too_late, Guess} -> 
            % io:format("~p ~*.. B Too late :( ~n", [self(), utils:width(Max), Guess]),
            Master ! {too_late, {Guesses + 1, Guess, loser}, self()},
            loop(Server, Master, Min, Max, Guesses, false);
        {'EXIT', _From, loser} ->
            io:format("~p I lose :(~n", [self()]),
            exit(loser);
        Msg ->
            io:format("worker:loop/6 Unknown message ~p~n", [Msg]),
            loop(Server, Master, Min, Max, Guesses, false)
    end.
