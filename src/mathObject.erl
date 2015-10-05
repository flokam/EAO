-module(mathObject,[Name,GenericFun]).
-export([factorial/1,name/0,genericfun/1,setGenericfun/1,setName/1]).


factorial(N) when N > 0 ->
    N * factorial(N-1);
factorial(0) ->
    1.

name()->
Name.

genericfun(X)->
GenericFun(X).

setGenericfun(NewFun)->
new(Name,NewFun).

setName(NewName)->
new(NewName,GenericFun).