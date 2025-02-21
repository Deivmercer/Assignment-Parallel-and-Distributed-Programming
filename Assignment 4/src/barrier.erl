-module(barrier).
-export([start/1, wait/2]).

start(Refs) ->
    spawn(fun() -> barrier(length(Refs), Refs, []) end).

wait(Barrier, Ref) ->
    MRef = monitor(process, Barrier),
    Barrier ! {arrive, Ref, self()},
    receive
        {continue, Ref} -> ok;
        {'DOWN', MRef, _, _, _} -> ok
    end.

notify_clients([]) ->
    done;

notify_clients([{Pid, Ref} | Rest]) ->
    Pid ! {continue, Ref},
    notify_clients(Rest).

barrier(0, _, Arrived) ->
    notify_clients(Arrived);

barrier(N, Refs, Arrived) ->
    receive
        {arrive, Ref, Pid} ->
            case lists:member(Ref, Refs) of
                true ->
                    barrier(N - 1, Refs, [{Pid, Ref} | Arrived]);
                false ->
                    notify_clients([{Pid, Ref}]),
                    barrier(N, Refs, Arrived)
            end
    end.
