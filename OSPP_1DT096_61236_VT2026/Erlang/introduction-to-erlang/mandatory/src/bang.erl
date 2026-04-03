%% @doc Process supervision. To study process supervision you will construct an
%% Erlang system with one supervisor process and one worker process called bang.

%% @author Karl Marklund <karl.marklund@it.uu.se>

-module(bang).
-export([start/0]).


%% @doc Start the system. 
-spec start() -> ok. 
start() ->
    io:format("~nSupervisor with PID ~p started~n", [self()]),

    process_flag(trap_exit, true),

    Counter = 5,
    Pids = [start_bang(Counter)],
    supervisor_loop(Counter, Pids).

start_bang(Counter) ->
    Supervisor = self(),
    PID = spawn_link(fun() -> bang(Supervisor, Counter) end),
    io:format("bang(~w) with PID ~p started~n", [Counter, PID]),
    PID.

counter_msg(Counter) when Counter rem 2 == 1 -> tick;
counter_msg(_Counter) -> tock.

supervisor_loop(Counter, Pids) ->
    receive
        {countdown, 0} ->
            io:format("~w ~s~n", [0, counter_msg(0)]),
            io:format(">>SUPERBANG<<~n"),
            [exit(Pid, kill) || Pid <- Pids],  %% kill all children;
            ok;
        {countdown, N} ->
            io:format("~w ~s~n", [N, counter_msg(N)]),
            supervisor_loop(N - 1, Pids);
        {'EXIT', PID, Reason} -> 
            case Reason of
                random_death ->
                    io:format("bang(~w) with PID ~p EXPLODED! Restarting...~n", [Counter, PID]),
                    NewProcess = start_bang(Counter),
                    supervisor_loop(Counter, [NewProcess | Pids -- [PID]]); 
                bang ->
                    io:format("~w ~s~n", [0, counter_msg(0)]),
                    io:format(">>BANG<<~n"),
                    [exit(Pid, kill) || Pid <- Pids],    %% kill all children;
                    ok;  
                _ ->
                    io:format("Process ~w terminated with reason ~w! ~n", [PID, Reason]),
                    supervisor_loop(Counter, Pids -- [PID])
            end
    end.

bang(Supervisor, 0) ->
    Supervisor ! {countdown, 0},
    timer:sleep(1000),
    exit(bang);
bang(Supervisor, Counter) ->
    timer:sleep(1000),
    death:gamble(0.3),
    Supervisor ! {countdown, Counter},
    bang(Supervisor, Counter - 1).
