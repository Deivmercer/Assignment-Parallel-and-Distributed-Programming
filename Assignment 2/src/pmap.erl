-module(pmap).
-export([unordered/2, unordered/3, ordered/3]).

unordered(Fun, L) ->
    Pids = [spawn_and_start_worker(Fun, E) || E <- L],
    Res = gather_unordered(length(L)),
    stop_worker(Pids),
    Res.

unordered(Fun, L, MaxWorkers) ->
    ActualMax = min(length(L), MaxWorkers),
    Pids = [spawn_worker() || _ <- lists:seq(1, ActualMax)],
    start_worker(Pids, Fun, L),
    Res = gather_unordered(length(L)),
    stop_worker(Pids),
    Res.

ordered(Fun, L, MaxWorkers) ->
    ActualMax = min(length(L), MaxWorkers),
    Pids = [spawn_worker() || _ <- lists:seq(1, ActualMax)],
    Reqs = start_worker(Pids, Fun, L, []),
    Res = gather(Reqs),
    stop_worker(Pids),
    Res.

worker() ->
    receive
        {Master, F, E} ->
            Master ! {self(), F(E)},
            worker();
        {Master, Ref, F, E} ->
            Master ! {self(), Ref, F(E)},
            worker();
        stop ->
            ok
    end.

spawn_and_start_worker(F, E) ->
    Pid = spawn(fun worker/0),
    Pid ! {self(), F, E},
    Pid.

spawn_worker() ->
    spawn(fun worker/0).

start_worker(_, _, []) ->
    ok;

start_worker([Pid | Pids], F, [H | T]) ->
    Pid ! {self(), F, H},
    start_worker(Pids ++ [Pid], F, T).

start_worker(_, _, [], Reqs) ->
    Reqs;

start_worker([Pid | Pids], F, [H | T], Reqs) ->
    Ref = make_ref(),
    Pid ! {self(), Ref, F, H},
    start_worker(Pids ++ [Pid], F, T, Reqs ++ [{Pid, Ref}]).

stop_worker([]) ->
    ok;

stop_worker([Pid | Pids]) ->
    Pid ! stop,
    stop_worker(Pids).

gather_unordered(0) ->
    [];

gather_unordered(L) when is_number(L) ->
    receive
        {_, R} ->
            [R | gather_unordered(L - 1)]
    end.

gather([]) ->
    [];

gather([{Pid, Ref} | Reqs]) ->
    receive
        {Pid, Ref, R} ->
            [R | gather(Reqs)]
    end.
