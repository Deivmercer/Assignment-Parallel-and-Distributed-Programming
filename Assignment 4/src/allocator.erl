-module(allocator).
-export([start/1, request/2, release/2]).

start(Resources) ->
    spawn(fun() -> allocator(Resources, Resources, []) end).

request(Allocator, Resources) ->
    Allocator ! {request, self(), Resources},
    receive
        {granted, Resources} ->
            Resources;
        {error, Resources} ->
            error
    end.

release(Allocator, Resources) ->
    Allocator ! {release, Resources},
    ok.

allocator(AvailableRes, Resources, Waiting) ->
    receive
        {request, From, Request} ->
            case check_resources(Request, Resources) of
                true ->
                    case check_resources(Request, AvailableRes) of
                        true ->
                            NewAvailable = maps:without(Request, AvailableRes),
                            From ! {granted, Request},
                            allocator(NewAvailable, Resources, Waiting);
                        false ->
                            Allocator = self(),
                            Pid = spawn(fun () -> wait(Allocator, From, Request) end),
                            allocator(AvailableRes, Resources, Waiting ++ [Pid])
                    end;
                false ->
                    From ! {error, Request},
                    allocator(AvailableRes, Resources, Waiting)
            end;
        {release, Released} ->
            NewAvailable = maps:merge(AvailableRes, Released),
            notify(Waiting),
            allocator(NewAvailable, Resources, [])
    end.

check_resources([], _) ->
    true;

check_resources([Key | Req], Resources) ->
    case maps:is_key(Key, Resources) of
        true ->
            check_resources(Req, Resources);
        false ->
            false
    end.

wait(Allocator, From, Resources) ->
    MRef = monitor(process, Allocator),
    receive
        wake ->
            Allocator ! {request, From, Resources};
        {'DOWN', MRef, _, _, _} ->
            From ! {error, Resources}
    end.

notify([]) ->
    ok;

notify([Pid | Waiting]) ->
    Pid ! wake,
    notify(Waiting).
