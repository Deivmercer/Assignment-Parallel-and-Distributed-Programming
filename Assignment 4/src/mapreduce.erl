-module(mapreduce).
-export([mapreduce/6, test_distributed/0]).

% net_kernel:connect_node('a@Davides-MacBook-Pro'), net_kernel:connect_node('b@Davides-MacBook-Pro'), net_kernel:connect_node('c@Davides-MacBook-Pro'), c(mapreduce), mapreduce:test_distributed().

mapreduce(Nodes, Mapper, Mappers, Reducer, Reducers, Input) ->
    Self = self(),
    Ref = make_ref(),
    Partitions = partition(Mappers, Input),
    ReducerPids = spawn_reducer(Reducers, fun () -> handle_reduce(Self, Ref, Reducer, []) end, Nodes, []),
    MapperPids = spawn_mapper_dist(Nodes, [], Self, Ref, Mapper, Reducers, ReducerPids, Partitions),
    [receive
         {map, {Pid, Ref}} ->
             ok
     end || Pid <- MapperPids],
    [Pid ! {start, Ref} || Pid <- ReducerPids],
    Output = [receive
                  {reduce, {Pid, Ref, Data}} ->
                      Data
              end || Pid <- ReducerPids],
    lists:sort(lists:flatten(Output)).


groupkeys([]) ->
    [];

groupkeys([{K, V} | Rest]) ->
    groupkeys(K, [V], Rest).

groupkeys(K, Vs, [{K, V} | Rest]) ->
    groupkeys(K, [V | Vs], Rest);

groupkeys(K, Vs, Rest) ->
    [{K, lists:reverse(Vs)} | groupkeys(Rest)].


partition(N, L) ->
    partition(N, L, length(L)).

partition(1, L, _) ->
    [L];

partition(N, L, Len) ->
    {Prefix, Suffix} = lists:split(Len div N, L),
    [Prefix | partition(N - 1, Suffix, Len - (Len div N))].


chunk(Data, Chunks) ->
    chunk(Data, Chunks + 1, 1).

chunk(_, Chunks, I) when Chunks=:= I ->
    [];

chunk(Data, Chunks, I) ->
    [[Value || {MapKey, MapValue} <- Data, MapKey =:= I, Value <- MapValue] | chunk(Data, Chunks, I + 1)].


handle_mapper(Master, Ref, Mapper, Reducers, ReducerPids, Data) ->
    Map = [{erlang:phash2(MapKey, Reducers), {MapKey, MapValue}}
        || {DataKey, DataValue} <- Data, {MapKey, MapValue} <- Mapper(DataKey, DataValue)],
    Result = groupkeys(lists:sort(Map)),
    Chunks = chunk(Result, Reducers),
    send_data(ReducerPids, Chunks),
    Master ! {map, {self(), Ref}}.


handle_reduce(Master, Ref, Reducer, Chunk) ->
    receive
        {chunk, NewChunk} ->
            handle_reduce(Master, Ref, Reducer, Chunk ++ NewChunk);
        {start, Ref} ->
            Reduce = [KV || {K,Vs} <- groupkeys(lists:sort(Chunk)), KV <- Reducer(K,Vs)],
            Master ! {reduce, {self(), Ref, Reduce}}
    end.


send_data([], []) ->
    ok;

send_data([Pid | ReducerPids], [Chunk | Chunks]) ->
    Pid ! {chunk, Chunk},
    send_data(ReducerPids, Chunks).


connect_nodes([]) ->
    ok;

connect_nodes([Node | Nodes]) ->
    net_kernel:connect_node(Node),
    connect_nodes(Nodes).


spawn_reducer(0, _, _, Pids) ->
    Pids;

spawn_reducer(N, Function, [Node | Nodes], Pids) ->
    Pid = spawn_link(Node, Function),
    spawn_reducer(N - 1, Function, Nodes ++ [Node], Pids ++ [Pid]).


spawn_mapper_dist(_, Pids, _, _, _, _, _, []) ->
    Pids;

spawn_mapper_dist([Node | Nodes], Pids, Master, Ref, Mapper, Reducers, ReducerPids, [Data | Other]) ->
    Pid = spawn_link(Node, fun () ->
            handle_mapper(Master, Ref, Mapper, Reducers, ReducerPids, Data)
        end),
    spawn_mapper_dist(Nodes ++ [Node], Pids ++ [Pid], Master, Ref, Mapper, Reducers, ReducerPids, Other).


test_distributed() ->
    N = ['a@Davides-MacBook-Pro', 'b@Davides-MacBook-Pro', 'c@Davides-MacBook-Pro'],
%%    connect_nodes(N),
    Mapper = fun (_Key, Text) ->
        [{Word, 1} || Word <- Text]
             end,
    Reducer = fun (Word, Counts) ->
        [{Word, lists:sum(Counts)}]
              end,
    mapreduce(N, Mapper, 3, Reducer, 10, [{a, ["hello", "world", "hello", "text"]}, {b, ["world", "a", "b", "text"]}]).
