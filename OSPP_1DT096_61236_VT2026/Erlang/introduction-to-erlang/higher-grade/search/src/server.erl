-module(server).

-export([start/1, stop/1]).

%% @doc Starts a new `Server' with a `Secret' number.

-spec start(Secret) -> Server when
      Secret :: integer(),
      Server :: pid().

start(Secret) ->
    io:format("~nPss, starting the server with secret data '~p'~n", [Secret]),
    spawn(fun() -> loop(Secret, false) end).

%% @doc Stops the `Server'.

-spec stop(Server) -> stop when
      Server :: pid.

stop(Server) ->
    Server ! stop.

-spec loop(Secret, Leaked) -> ok when
      Secret :: integer(),
      Leaked :: boolean().
loop(Secret, Leaked) when Secret >= 1 ->
    case Leaked of
        false ->
            receive
                {guess, Secret, From} ->
                    From ! {right, Secret},
                    loop(Secret, true);
                {guess, N, From} ->
                    From ! {wrong, N},
                    loop(Secret, Leaked);
                stop ->
                    ok;
                Msg ->
                    io:format("server:loop/1 Unhandled message: ~p~n", [Msg]),
                    loop(Secret, Leaked)
            end;
        true ->
            receive
                {guess, N, From} ->
                    From ! {too_late, N},
                    loop(Secret, Leaked);
                stop ->
                    ok;
                Msg ->
                    io:format("server:loop/1 Unhandled message: ~p~n", [Msg]),
                    loop(Secret, Leaked)
            end
    end.
    % loop(Secret).
