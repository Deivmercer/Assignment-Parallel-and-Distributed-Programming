-module(mapreduce31).
-export([mapreduce/5, test/0]).

mapreduce(Mapper, Mappers, Reducer, Reducers, Input) ->
    Self = self(),
    Ref = make_ref(),
    Partitions = partition(Mappers, Input),
    ReducerPids = [spawn_link(fun () -> handle_reduce(Self, Ref, Reducer, []) end) || _ <- lists:seq(1, Reducers)],
    MapperPids = [spawn_mapper(Self, Ref, Mapper, Reducers, ReducerPids, Part) || Part <- Partitions],
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


spawn_mapper(Master, Ref, Mapper, Reducers, ReducerPids, Data) ->
    spawn_link(fun () ->
        Map = [{erlang:phash2(MapKey, Reducers), {MapKey, MapValue}}
            || {DataKey, DataValue} <- Data, {MapKey, MapValue} <- Mapper(DataKey, DataValue)],
        Result = groupkeys(lists:sort(Map)),
        Chunks = chunk(Result, Reducers),
        send_data(ReducerPids, Chunks),
        Master ! {map, {self(), Ref}}
               end).


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


test() ->
    Mapper = fun (_Key, Text) ->
        [{Word, 1} || Word <- Text]
             end,
    Reducer = fun (Word, Counts) ->
        [{Word, lists:sum(Counts)}]
              end,
    mapreduce(Mapper, 2, Reducer, 10, [{a, ["hello", "world", "hello", "text"]}, {b, ["world", "a", "b", "text"]}]).
