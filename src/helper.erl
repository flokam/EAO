-module(helper).
-export([gettype/1,gettype/0,gettoken/0]).

%%region gettype
gettype(X) when is_atom(X)->
X;
gettype(X) when is_pid(X) ->
X!{get_type,self()},
gettype();
gettype(_) ->
other.

gettype()->
receive
    {type,_,ReturnType}->gettype(ReturnType);
    {}->gettype()
end.
%%end region gettype

%% region gettoken
gettoken()->
random:uniform(100).

%%end region gettoken
