-module(bank).
-export([start/0, init/1, handle_cast/2, handle_call/3, balance/2, deposit/3, withdraw/3, lend/4]).
-behavior(gen_server).

start() ->
    {ok, Pid} = gen_server:start(?MODULE, [], []),
    Pid.

init(_) ->
    {ok, #{}}.

handle_cast(_, _) ->
    ok.

balance(Pid, Who) ->
    case is_process_alive(Pid) of
        true ->
            Ref = make_ref(),
            Res = gen_server:call(Pid, {balance, Ref, Who}),
            case Res of
                {Ref, ok, Balance} ->
                    {ok, Balance};
                {Ref, no_account} ->
                    no_account
            end;
        false ->
            no_bank
    end.

deposit(Pid, Who, X) ->
    case is_process_alive(Pid) of
        true ->
            Ref = make_ref(),
            {Ref, ok, Balance} = gen_server:call(Pid, {deposit, Ref, Who, X}),
            {ok, Balance};
        false ->
            no_bank
    end.

withdraw(Pid, Who, X) ->
    case is_process_alive(Pid) of
        true ->
            Ref = make_ref(),
            Res = gen_server:call(Pid, {withdraw, Ref, Who, X}),
            case Res of
                {Ref, ok, Balance} ->
                    {ok, Balance};
                {Ref, insufficient_funds} ->
                    insufficient_funds
            end;
        false ->
            no_bank
    end.

lend(Pid, From, To, X) ->
    case is_process_alive(Pid) of
        true ->
            Ref = make_ref(),
            Res = gen_server:call(Pid, {lend, Ref, From, To, X}),
            case Res of
                {Ref, no_account, Who} ->
                    {no_account, Who};
                {Ref, ok} ->
                    ok;
                {Ref, insufficient_funds} ->
                    insufficient_funds
            end;
        false ->
            no_bank
    end.

handle_call({balance, Ref, Who}, _, State) ->
    case maps:is_key(Who, State) of
        true ->
            Reply = {Ref, ok, maps:get(Who, State)};
        false ->
            Reply = {Ref, no_account}
    end,
    {reply, Reply, State};

handle_call({deposit, Ref, Who, X}, _, State) ->
    case maps:is_key(Who, State) of
        true ->
            NewBalance = maps:get(Who, State) + X,
            NewState = State#{Who => NewBalance},
            Reply = {Ref, ok, NewBalance};
        false ->
            NewState = State#{Who => X},
            Reply = {Ref, ok, X}
    end,
    {reply, Reply, NewState};

handle_call({withdraw, Ref, Who, X}, _, State) ->
    case maps:get(Who, State, 0) >= X of
        true ->
            NewBalance = maps:get(Who, State) - X,
            NewState = State#{Who => NewBalance},
            Reply = {Ref, ok, NewBalance};
        false ->
            NewState = State,
            Reply = {Ref, insufficient_funds}
    end,
    {reply, Reply, NewState};

handle_call({lend, Ref, From, To, X}, _, State) ->
    {NoWho, NoTo} = {maps:is_key(From, State), maps:is_key(To, State)},
    case {NoWho, NoTo} of
        {false, false} ->
            {reply, {Ref, no_account, both}, State};
        {false, true} ->
            {reply, {Ref, no_account, From}, State};
        {true, false} ->
            {reply, {Ref, no_account, To}, State};
        {true, true} ->
            case maps:get(From, State, 0) >= X of
                true ->
                    NewBalanceFrom = maps:get(From, State) - X,
                    NewBalanceTo = maps:get(To, State) + X,
                    NewState = State#{From => NewBalanceFrom, To => NewBalanceTo},
                    Reply = {Ref, ok};
                false ->
                    NewState = State,
                    Reply = {Ref, insufficient_funds}
            end,
            {reply, Reply, NewState}
    end.
