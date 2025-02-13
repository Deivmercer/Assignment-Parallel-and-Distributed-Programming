-module(task1).
-export([eval/1, eval/2, map/2, filter/2, split/2, groupby/2]).

%%%%%%%%
% eval/1
%%%%%%%%

eval({Op, E1, E2}) when erlang:is_tuple(E1) ->
    EvalE1 = eval(E1),
    case EvalE1 of
        {ok, ResE1} ->
            eval({Op, ResE1, E2});
        error ->
            error
    end;

eval({Op, E1, E2}) when erlang:is_number(E1),
                        erlang:is_tuple(E2) ->
    EvalE2 = eval(E2),
    case EvalE2 of
        {ok, ResE2} ->
            eval({Op, E1, ResE2});
        error ->
            error
    end;

eval({add, E1, E2}) when erlang:is_number(E1),
                         erlang:is_number(E2) ->
    {ok, E1 + E2};

eval({mul, E1, E2}) when erlang:is_number(E1),
                         erlang:is_number(E2) ->
    {ok, E1 * E2};

eval({'div', E1, E2}) when erlang:is_number(E1),
                           erlang:is_number(E2) ->
    {ok, E1 / E2};

eval({sub, E1, E2}) when erlang:is_number(E1),
                         erlang:is_number(E2) ->
    {ok, E1 - E2};

eval({_, _, _}) ->
    error.

%%%%%%%%
% eval/2
%%%%%%%%

eval({Op, E1, E2}, L) when erlang:is_tuple(E1) ->
    EvalE1 = eval(E1, L),
    case EvalE1 of
        {ok, ResE1} ->
            eval({Op, ResE1, E2}, L);
        {Error, Message} ->
            {Error, Message}
    end;

eval({Op, E1, E2}, L) when erlang:is_tuple(E2) ->
    EvalE2 = eval(E2, L),
    case EvalE2 of
        {ok, ResE2} ->
            eval({Op, E1, ResE2}, L);
        {Error, Message} ->
            {Error, Message}
    end;

eval({Op, E1, E2}, L) when erlang:is_atom(E1),
                           erlang:is_map(L) ->
    case maps:is_key(E1, L) of
        true ->
            ValE1 = maps:get(E1, L),
            eval({Op, ValE1, E2}, L);
        false ->
            {error, variable_not_found}
    end;

eval({Op, E1, E2}, L) when erlang:is_number(E1),
                           erlang:is_atom(E2),
                           erlang:is_map(L) ->
    case maps:is_key(E2, L) of
        true ->
            ValE2 = maps:get(E2, L),
            eval({Op, E1, ValE2}, L);
        false ->
            {error, variable_not_found}
    end;

eval({Op, E1, E2}, _) when erlang:is_number(E1),
                           erlang:is_number(E2) ->
    eval({Op, E1, E2});

eval(_, _) ->
    {error, unknown_error}.

%%%%%%%
% map/2
%%%%%%%

map_acc(_, [], Acc) ->
    Acc;

map_acc(F, [H | T], Acc) ->
    map_acc(F, T, [F(H) | Acc]).

map(F, L) when erlang:is_function(F),
               erlang:is_list(L) ->
    lists:reverse(map_acc(F, L, [])).

%%%%%%%%%%
% filter/2
%%%%%%%%%%

filter_acc(_, [], Acc) ->
    Acc;

filter_acc(P, [H | T], Acc) ->
    case P(H) of
        true ->
            Updated = [H | Acc];
        false ->
            Updated = Acc
    end,
    filter_acc(P, T, Updated).

filter(P, L) when erlang:is_function(P),
                  erlang:is_list(L) ->
    lists:reverse(filter_acc(P, L, [])).

%%%%%%%%%
% split/2
%%%%%%%%%

split_acc(_, [], Acc) ->
    Acc;

split_acc(P, [H | T], {True, False}) ->
    case P(H) of
        true ->
            UpdatedTrue = [H | True],
            UpdatedFalse = False;
        false ->
            UpdatedTrue = True,
            UpdatedFalse = [H | False]
    end,
    split_acc(P, T, {UpdatedTrue, UpdatedFalse}).

split(P, L) when erlang:is_function(P),
                 erlang:is_list(L) ->
    {True, False} = split_acc(P, L, {[], []}),
    {lists:reverse(True), lists:reverse(False)}.

%%%%%%%%%%%
% groupby/2
%%%%%%%%%%%

groupby_acc(_, [], Acc, _) ->
    Acc;

groupby_acc(F, [H | T], Acc, I) ->
    Result = F(H),
    case maps:is_key(Result, Acc) of
        true ->
            UpdatedAcc = maps:update(Result, [I | maps:get(Result, Acc)], Acc);
        false ->
            UpdatedAcc = maps:put(Result, [I], Acc)
    end,
    groupby_acc(F, T, UpdatedAcc, I + 1).

groupby(F, L) when erlang:is_function(F),
                   erlang:is_list(L) ->
    Result = groupby_acc(F, L, #{}, 1),
    map_map(fun (X) -> lists:reverse(X) end, Result).

% The following function is an implementation of the map function for maps,
% which iterates over the keys of a map and applies a function to every value.
map_map(_, M, []) when erlang:is_map(M) ->
    M;

map_map(F, M, [H | T]) when erlang:is_map(M) ->
    Acc = maps:update(H, F(maps:get(H, M)), M),
    map_map(F, Acc, T).

map_map(F, M) when erlang:is_function(F),
                   erlang:is_map(M) ->
    map_map(F, M, maps:keys(M)).