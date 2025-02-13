-module(monitor).
-export([start/0, init/1]).
-behavior(supervisor).

start() ->
    supervisor:start_link(?MODULE, []).

init(_) ->
    SupFlags = #{
        strategy => one_for_one,
        intensity => 10,
        period => 5
    },
    ChildSpec = [#{
        id => double_id,
        start => {double, start, []},
        restart => permanent
    }],
    {ok, {SupFlags, ChildSpec}}.
