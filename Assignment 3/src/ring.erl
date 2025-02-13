-module(ring).
-export([start/2, spawn_process/0, pass_value/4, stop_process/1]).

start(N, M) ->
    Pids = [spawn_process() || _ <- lists:seq(1, N)],
    Res = pass_value(Pids, Pids, M, 0),
    stop_process(Pids),
    Res.

spawn_process() ->
    spawn(fun increment/0).

stop_process([]) ->
    ok;

stop_process([Pid | Pids]) ->
    Pid ! stop,
    stop_process(Pids).

pass_value(_, [], 1, Value) ->
    Value;

pass_value(Pids, [], Loop, Value) ->
    pass_value(Pids, Pids, Loop - 1, Value);

pass_value(Pids, [Pid | Rest], Loop, Value) ->
    Pid ! {self(), Value},
    receive
        NewValue ->
            pass_value(Pids, Rest, Loop, NewValue)
    end.

increment() ->
    receive
        {From, Value} ->
            From ! Value + 1,
            increment();
        stop ->
            ok
    end.
