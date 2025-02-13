-module(monitor).
-export([start/0]).

start() ->
    Pid = double:start(),
    _ = spawn(fun () -> my_monitor(Pid) end).

my_monitor(Pid) ->
    Ref = monitor(process, Pid),
    receive
        {'DOWN', Ref, process, _, _} ->
            demonitor(Ref),
            start()
    end.
