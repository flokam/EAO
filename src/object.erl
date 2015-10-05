-module(object).
-export([create/0,create/1,object/1, active_object/2,run_concurrent_method/7]).


create()->
spawn(?MODULE,object,[dict:new()]).

create(Methods)->
spawn(?MODULE,object,[Methods]).



object(Methods) ->
receive
%%update method
	{methodupdate,RequestPID,Methodname,Method} ->
		New_Methods=dict:store(Methodname,Method,Methods),
                RequestPID!{response,self(),true},
		object(New_Methods);
%%add method
	{method_add,RequestPID,Methodname,Method} ->
		New_Methods=dict:store(Methodname,Method,Methods),
                RequestPID!{response,self(),true},
		object(New_Methods);
        	


%% activity binding
        {bind,RequestPID,ActivityPID}->
                %%one time
                io:format("binding ~p at ~p~n", [ActivityPID,self()]),
                RequestPID!{binding,true},
                active_object(Methods,ActivityPID);
         
%%process termination
	{dispose} ->
		io:format("object: ~p disposed~n", [self()]);
            
%%invalide message       
	{} ->
		object(Methods)
end.

active_object(Methods,Activity)->
%%pseudoconstructor
case dict:is_key(init, Methods) of
                true -> spawn(?MODULE,run_concurrent_method,[Methods,init,nil,nil,nil,nil,h]);
                _ ->  nil
                end,
%%end pseudoconstructor                
receive
%%methodinvocation
        %%simple Filter to avoid H-methods
        {methodinvocation,RequestPID,init,Arguments,Activity,Token} ->
            %%debug-print
		io:format("!!!!!!!!!!: ~p request INIT ~n", [RequestPID]),
                io:format("~p not found at ~p~n", [init,self()]),
                active_object(Methods,Activity);
	{methodinvocation,RequestPID,Methodname,Arguments,Activity,Token} ->
		%%debug-print
		io:format("RequestPID: ~p request ~p ~n", [RequestPID,Methodname]),
                case dict:is_key(Methodname, Methods) of
                    true -> spawn(?MODULE,run_concurrent_method,[Methods,Methodname,Arguments,RequestPID,Token,Activity,l]);
                    _ ->
                    io:format("~p not found at ~p~n", [Methodname,self()]),
                     nil
                end,
                active_object(Methods,Activity);
%%clone        
        {clone,RequestPID,Activity}->
                RequestPID!{clone,self(),create(dict:from_list(dict:to_list(Methods)))},
                active_object(Methods,Activity);

%%process termination
	{dispose,Activity} ->
		io:format("active object: ~p disposed~n", [self()]);
            
%%invalide message       
	{} ->
		active_object(Methods,Activity)
end.                

%%% changed for Dictionary

run_concurrent_method(Methods,Methodname,Arguments,RequestPID,Token,Activity,SecurityLevel)->
io:format("invoke method: ~p at ~p with ~p~n", [Methodname,self(),Arguments]),

try
        %%extracting Method
        Method = dict:fetch(Methodname,Methods),
        %%simple Self_Funktion for Dictionary to use as Self(Methodname)
        case SecurityLevel == h of
        %% H-Self
        true->
        io:format("highlevel-method~p~n", [Methodname]),
        Self=fun(X)->dict:fetch(X,Methods) end;
        false->
        %% L-Self use activity-call, where just visible methods available
        io:format("lowlevel-method~p~n", [Methodname]),
        %%little hack, unified syntax or curying should be better O!M
        Self=fun(X)->fun(_,Y)->future:get_value(future:create(methodinvocation,Activity,X,Y)) end end
        end,
        
        case Arguments == nil of
        true -> Value = Method(Self);
        false ->Value = Method(Self,Arguments)
        end,
        case RequestPID == nil of
        true ->
            nil;
        false ->
        io:format("send result to ~p with ~p~n", [RequestPID,Value]),

            RequestPID!{set_value,Token,Value}
        end
catch
    _:Reason ->
    io:format("error:~p on invoke method: ~p at ~p in ~p~n", [Reason,Methodname,Methods,self()])
end.