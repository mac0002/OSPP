%% @doc A server that keeps track of  <a target="_blank"
%% href="https://www.rd.com/culture/ablaut-reduplication/">ablaut
%% reduplication</a> pairs. You should implement two versions of the server. One
%% stateless server and one stateful server.
%%
%% <ul>
%% <li>
%% The stateless server keeps
%% track of a static number of ablaut reduplication pairs. Each pair is handled
%% by a separate message receive pattern.
%% </li>
%% <li>
%% The stateful server keeps
%% track of dynamic number of ablaut reduplication pairs using a <a
%% target="_blank" href="https://erlang.org/doc/man/maps.html">Map</a>.
%% </li>
%% </ul>
%% <p>
%% You should also implement process supervision of the server.
%% <ul>
%% <li>
%% The supervisor should <a target="_blank"
%% href="https://erlang.org/doc/reference_manual/processes.html#registered-processes">register</a>
%% the server process under the name `server'.
%% </li>
%% <li>
%% The name of a registered process can be used instead of the Pid when sending
%% messages to the process.
%% </li>
%% <li>
%% The supervisor should restart the server if the server terminates due to an
%% error.
%% </li>
%% </ul>
%% </p>

%% Quick start Erlang shell prompts:
%% l(server), l(client), server:start(true, true).

-module(server).
-export([start/2, update/0, update/1, stop/0, stop/1, loop/1, loop/2, supervisor/2]).

%% @doc The initial state of the stateful server.

-spec pairs() -> map().

pairs() ->
    #{ping => pong,
      tick => tock,
      hipp => hopp,
      ding => dong}.

%% @doc Starts the server.

-spec start(Stateful, Supervised) -> Server when
      Stateful :: boolean(),
      Supervised :: boolean(),
      Server :: pid().

start(false, false) ->
    spawn(fun() -> loop(false) end);
start(false, true) ->
    spawn(fun() -> supervisor(false, pairs()) end);
start(true, false) ->
    spawn(fun() -> loop(false, pairs()) end);
start(true, true) ->
    spawn(fun() -> supervisor(true, pairs()) end).

%% @doc The server supervisor. The supervisor must trap exit, spawn the server
%% process, link to the server process and wait the server to terminate. If the
%% server terminates due to an error, the supervisor should make a recursive
%% call to it self to restart the server.

-spec supervisor(Stateful, Pairs) -> ok when
    Stateful :: boolean(),
    Pairs :: map().

supervisor(Stateful, Pairs) ->
    process_flag(trap_exit, true),
    SID = case Stateful of
        false ->
            spawn_link(fun() -> server:loop(true) end);
        true ->
            spawn_link(fun() -> server:loop(true, Pairs) end)
    end,
    register(server, SID),
    receive 
        {'EXIT', PID, Reason} ->
            % unregister(server),
            case Reason of 
                simulated_bug -> 
                    io:format("Server ~p terminated with reason ~p! Restarting...~n", [PID, Reason]),
                    supervisor(Stateful, Pairs);
                HashMap when is_map(HashMap) ->       
                    io:format("Server ~p terminated with reason UPDATE! Restarting...~n", [PID]),
                    server:supervisor(Stateful, HashMap);
                _ -> 
                    io:format("Server ~p terminated with reason ~p!~n", [PID, Reason]),
                    ok
            end
    end.



%% @doc Terminates the supervised server.

-spec stop() -> ok | error.

stop() ->
    stop(server).

-spec stop(Server) -> ok | error when
      Server :: pid().

%% @doc Terminates the unsupervised server.

stop(Server) ->
    Server ! {stop, self()},
    receive
        {stop, ok} ->
            ok;
        Msg ->
            io:format("stop/1: Unknown message: ~p~n", [Msg]),
            error
    end.

%% @doc Makes the supervised server perform a hot code swap.

-spec update() -> ok | error.

update() ->
    update(server).

%% @doc Makes the unsupervised server perform a hot code swap.

-spec update(Server) -> ok | error when
      Server :: pid().

update(Server) ->
    Server ! {update, self()},
    receive
        {update, ok} ->

            ok;
        Msg ->
            io:format("update/1: Unknown message: ~p~n", [Msg]),
            error
    end.

%% @doc The process loop for the stateless server. The stateless server keeps
%% track of a static number of ablaut reduplication pairs. Each pair is handled
%% by a separate message receive pattern.

-spec loop(Suped) -> {stop, ok} when
      Suped :: boolean().
loop(Suped) ->
    receive
        {ping, blipp, From} ->
            % exit(simulated_bug),
            From ! {pong, blopp},
            exit(simulated_bug);
        {ping, ding, From} ->
            From ! {pong, dong},
            loop(Suped);
        {ping, ping, From} ->
            From ! {pong, pong},
            loop(Suped);
        {ping, tick, From} ->
            From ! {pong, tock},
            loop(Suped);
        {ping, king, From} ->
            From ! {pong, kong},
            loop(Suped);
        print ->
            io:format("Stateless... Cold!~n"),
            % io:format("Hot! Hot! HOT!~n"),
            loop(Suped);
        {stop, From} ->
            From ! {stop, ok};
        {update, From}  ->
            case Suped of 
                false -> 
                    From ! {update, ok},
                    server:loop(Suped);
                true ->
                    From ! {update, ok},
                    % unregister(server),
                    % register(server, self()),
                    % server:loop(Suped, Pairs);
                    exit(#{})
            end;
        Msg ->
            io:format("loop/1: Unknown message: ~p~n", [Msg]),
            loop(Suped)
    end.


%% @doc The process loop for the stateful server. The stateful server keeps
%% track of dynamic number of ablaut reduplication pairs using a <a
%% target="_blank" href="https://erlang.org/doc/man/Pairss.html">Map</a>.

-spec loop(Suped, Pairs) -> {stop, ok} when
      Pairs :: map(),
      Suped :: boolean().

loop(Suped, Pairs) ->
    % io:format("Server ~p is running.~n", [self()]),
    % unregister(server),
    % register(server, self()),
    receive
        {ping, flip, From} ->
            From ! {pong, flop},
            % loop(Suped, Pairs);
            exit(simulated_bug);
        {ping, Ping, From} ->
            %% Send correct reply.
            case maps:find(Ping, Pairs) of 
                {ok, Pong} ->
                    From ! {pong, Pong},
                    loop(Suped, Pairs);
                error -> 
                    From ! unknown,
                    loop(Suped, Pairs)
            end;
        %% Handle the update, put and stop actions.
        {put, Ping, Pong, From} ->
            NewPairs = maps:put(Ping, Pong, Pairs),
            From ! {put, Ping, maps:get(Ping, NewPairs), ok},
            loop(Suped, NewPairs);
        print ->
            [io:format("Current pairs: ~p => ~p~n", [K, V]) || {K, V} <- maps:to_list(Pairs)],
            % io:format("Hot! Hot! HOT!~n"),
            % From ! {print, Pairs},
            loop(Suped, Pairs);
        {stop, From} ->
            From ! {stop, ok};
        {update, From}  ->
            case Suped of 
                false -> 
                    From ! {update, ok},
                    server:loop(Suped, Pairs);
                true ->
                    From ! {update, ok},
                    % unregister(server),
                    % register(server, self()),
                    % server:loop(Suped, Pairs);
                    exit(Pairs)
            end;
        Msg ->
            io:format("loop/2: Unknown message: ~p~n", [Msg]),
            loop(Suped, Pairs)
    end.
