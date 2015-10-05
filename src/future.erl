-module(future).
-export([create/4,state_finished/1,state_dowork/1,get_value/1]).
-import(helper,[gettype/1]).


%%future synchronisation
get_value(FuturePID)->
FuturePID!{get_value,self()},
Value = receive
	{response,FuturePID,ReturnValue} ->
                case gettype(ReturnValue) of
		    future -> get_value(ReturnValue);
                    _ -> ReturnValue %%activity -> ReturnValue;
                end
	end,
Value.

%%future set mode
state_dowork(Token)->
receive
%%set value
    {set_value,Token,Value}->
    io:format("get value: ~p at future:~p from: ~p~n", [Value,Token,self()]),
    state_finished(Value);
        
%%type
    {type,RequestPID}->
        %%debug-print
        io:format("type request from ~p~n", [RequestPID]),
        RequestPID!{type,self(),future},
        state_dowork(Token);
        
%%process termination
    {dispose} ->
       io:format("future: ~p disposed~n", [self()]);

%%invalid message       
    {Other} ->
    io:format("invalid message dw: ~p at future~p~n", [Other,self()]),
       state_dowork(Token)
end.

%%future get mode
state_finished(Value)->
receive
%%get value
    {get_value,Caller}->
       Caller!{response,self(),Value},
       state_finished(Value);
       
%%type
    {get_type,RequestPID}->
        %%debug-print
        io:format("type request from ~p~n", [RequestPID]),
        RequestPID!{type,self(),future},
        state_finished(Value);
        
%%process termination
    {dispose} ->
	io:format("future: ~p disposed~n", [self()]);

%%invalide message       
       {Other} ->
       io:format("invalid message f: ~p at future~p~n", [Other,self]),
	state_finished(Value)
end.

%%future creation
create(Action,Activity,Methodname,Arguments)->
Token = helper:gettoken(),
FuturePID=spawn(?MODULE,state_dowork,[Token]),
%%static callback
%%Callback = fun(Value)->FuturePID!{set_value,Value} end,
%%invoke method
%%Activity!{Action,Callback,Methodname,Arguments},
Activity!{Action,FuturePID,Methodname,Arguments,Token},

FuturePID.


%% other approach
%% fun()->future_get_value(FuturePID) end

%% end region future
