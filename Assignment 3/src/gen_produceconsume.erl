-module(gen_produceconsume).
-export([start/2, stop/1, produce/2, consume/1]).

-callback handle_produce(Value :: term()) -> {ok, Task :: term()}.
-callback handle_consume(Task :: term()) -> ok.

start(Callback, T) ->
    spawn(fun () -> manage(Callback, [], 0, T) end).

stop(Pid) ->
    Pid ! stop.

produce(Pid, T) ->
    Ref = make_ref(),
    Pid ! {produce, self(), Ref, T},
    receive
        {ok, Ref} ->
            ok
    end.

consume(Pid) ->
    Ref = make_ref(),
    Pid ! {consume, self(), Ref},
    receive
        {ok, Ref} ->
            ok
    end.

manage(Callback, Queue, Size, MaxSize) ->
    receive
        {produce, From, Ref, T} when Size < MaxSize ->
            {ok, Task} = Callback:handle_produce(T),
            From ! {ok, Ref},
            manage(Callback, Queue ++ [Task], Size + 1, MaxSize);
        {consume, From, Ref} when Size > 0 ->
            [Q | Rest] = Queue,
            Callback:handle_consume(Q),
            From ! {ok, Ref},
            manage(Callback, Rest, Size - 1, MaxSize);
        stop ->
            ok
    end.
