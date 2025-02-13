-module(double).
-export([start/0, double/1]).

start() ->
    Pid = spawn(fun double/0),
    register(double, Pid),
    Pid.

double() ->
    receive
        {Pid, Ref, N} ->
            Pid ! {Ref, N * 2},
            double()
    end.

double(Term) ->
    MRef = monitor(process, double),
    Ref = make_ref(),
    double ! {self(), Ref, Term},
    receive
        {'DOWN', MRef, _, _, _} ->
            double ! {self(), Ref, Term};
        {Ref, Res} ->
            Res
    end.
