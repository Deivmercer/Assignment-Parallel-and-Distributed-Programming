-module(gen_worker).
-export([start/2, stop/1, async/2, await/1, await_all/1]).

-callback handle_work(Value :: term()) -> {result, Result :: term()} | no_result.

start(Callback, Max) ->
    spawn_pool(Callback, Max).

stop(Pid) ->
    Pid ! stop.

async(Pid, W) ->
    Ref = make_ref(),
    Pid ! {work, self(), Ref, W},
    Ref.

await(Ref) ->
    receive
        {Ref, {result, Res}} ->
            {result, Res};
        {Ref, {no_result}} ->
            no_result;
        {Ref, error} ->
            error
    end.

await_all([]) ->
    [];

await_all([Ref | Refs]) ->
    Res = await(Ref),
    case Res of
        {result, R} ->
            [R | await_all(Refs)];
        no_result ->
            await_all(Refs);
        error ->
            [error | await_all(Refs)]
    end.

spawn_pool(Callback, Size) ->
    Pids = [spawn(fun () -> worker(Callback) end) || _ <- lists:seq(1, Size)],
    spawn(fun () -> master(Pids) end).

stop_workers([]) ->
    ok;

stop_workers([Pid | Pids]) ->
    Pid ! stop,
    stop_workers(Pids).

worker(Callback) ->
    receive
        {work, From, Ref, Value} ->
            Res = catch Callback:handle_work(Value),
            case Res of
                {'EXIT', _} ->
                    From ! {Ref, error};
                _ ->
                    From ! {Ref, Res}
            end,
            worker(Callback);
        stop ->
            ok
    end.

master([Pid | Pids]) ->
    receive
        {work, From, Ref, Value} ->
            Pid ! {work, From, Ref, Value},
            master(Pids ++ [Pid]);
        stop ->
            stop_workers([Pid | Pids])
    end.
