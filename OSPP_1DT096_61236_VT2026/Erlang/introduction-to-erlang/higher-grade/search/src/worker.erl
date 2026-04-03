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
            process_flag(trap_exit, true),
            Master ! {worker_started, self()},
            loop(Server, Master, Min, Max, Guesses, false)
    end,
    
    Guess = utils:random(Min, Max),
    Server ! {guess, Guess, self()},
    master:log_guess(Master, self()),

    receive
        {wrong, Guess} ->
            io:format("~p ~*.. B~n", [self(), utils:width(Max), Guess]),
            Master ! {wrong, Guesses + 1, self()},
            loop(Server, Master, Min, Max, Guesses + 1, false);

        {right, Guess} ->
            Master ! {correct, Guesses + 1, self()},
            tbi;
        {'EXIT', _From, loser} ->
            io:format("~p I lose :(~n", [self()])
    end.
