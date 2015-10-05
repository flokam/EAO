-module(mymath).
-export([factorial/1,isdivisor/2]).

factorial(N) when N > 0 ->
    N * factorial(N-1);
factorial(0) ->
    1.
	
isdivisor(Y,X) when Y rem X == 0 -> true;
isdivisor(_,_) -> false.

