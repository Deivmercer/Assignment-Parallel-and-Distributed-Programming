-module(bank).
-export([start/0, balance/2, deposit/3, withdraw/3, lend/4]).

start() ->
    spawn(fun () -> bank_server(#{}) end).

balance(Pid, Who) ->
    MRef = monitor(process, Pid),
    Ref = make_ref(),
    Pid ! {balance, self(), Ref, Who},
    receive
        {'DOWN', MRef, _, _, _} ->
            no_bank;
        {Ref, ok, Balance} ->
            {ok, Balance};
        {Ref, no_account} ->
            no_account
    end.

deposit(Pid, Who, X) ->
    MRef = monitor(process, Pid),
    Ref = make_ref(),
    Pid ! {deposit, self(), Ref, Who, X},
    receive
        {'DOWN', MRef, _, _, _} ->
            no_bank;
        {Ref, ok, Balance} ->
            {ok, Balance}
    end.

withdraw(Pid, Who, X) ->
    MRef = monitor(process, Pid),
    Ref = make_ref(),
    Pid ! {withdraw, self(), Ref, Who, X},
    receive
        {'DOWN', MRef, _, _, _} ->
            no_bank;
        {Ref, ok, Balance} ->
            {ok, Balance};
        {Ref, insufficient_funds} ->
            insufficient_funds
    end.

lend(Pid, From, To, X) ->
    MRef = monitor(process, Pid),
    Ref = make_ref(),
    Pid ! {lend, self(), Ref, From, To, X},
    receive
        {'DOWN', MRef, _, _, _} ->
            no_bank;
        {Ref, no_account, Who} ->
            {no_account, Who};
        {Ref, ok} ->
            ok;
        {Ref, insufficient_funds} ->
            insufficient_funds
    end.

bank_server(State) ->
    receive
        {balance, From, Ref, Who} ->
            case maps:is_key(Who, State) of
                true ->
                    From ! {Ref, ok, maps:get(Who, State)};
                false ->
                    From ! {Ref, no_account}
            end,
            bank_server(State);
        {deposit, From, Ref, Who, X} ->
            case maps:is_key(Who, State) of
                true ->
                    NewBalance = maps:get(Who, State) + X,
                    NewState = State#{Who => NewBalance},
                    From ! {Ref, ok, NewBalance};
                false ->
                    NewState = State#{Who => X},
                    From ! {Ref, ok, X}
            end,
            bank_server(NewState);
        {withdraw, From, Ref, Who, X} ->
            case maps:get(Who, State, 0) >= X of
                true ->
                    NewBalance = maps:get(Who, State) - X,
                    NewState = State#{Who => NewBalance},
                    From ! {Ref, ok, NewBalance};
                false ->
                    NewState = State,
                    From ! {Ref, insufficient_funds}
            end,
            bank_server(NewState);
        {lend, From, Ref, Who, To, X} ->
            {NoWho, NoTo} = {maps:is_key(Who, State), maps:is_key(To, State)},
            case {NoWho, NoTo} of
                {false, false} ->
                    From ! {Ref, no_account, both},
                    bank_server(State);
                {false, true} ->
                    From ! {Ref, no_account, Who},
                    bank_server(State);
                {true, false} ->
                    From ! {Ref, no_account, To},
                    bank_server(State);
                {true, true} ->
                    case maps:get(Who, State, 0) >= X of
                        true ->
                            NewBalanceWho = maps:get(Who, State) - X,
                            NewBalanceTo = maps:get(To, State) + X,
                            NewState = State#{Who => NewBalanceWho, To => NewBalanceTo},
                            From ! {Ref, ok};
                        false ->
                            NewState = State,
                            From ! {Ref, insufficient_funds}
                    end,
                    bank_server(NewState)
            end
    end.