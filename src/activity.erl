-module(activity).
-export([active/1,active/2,activity/1, clone_activity/6,sync_activeobject_methodmanipulation/4,sync_activeobject_clone/2]).

%% changed  clone_activity for process support

%% region activity
active(Object)->
PID= spawn(?MODULE,activity,[Object]),
Self =self(),
%%Binding
Object!{bind,Self,PID},
receive
    {binding,true}->io:format("binding ok~n");
    {binding,false}->exit(PID,kill),io:format("bindingerror: ~p ~n", [Object])
end,
PID.

active(Object,Name)->
PID = active(Object),
register(Name,PID).


%% with active object as process
activity(ActiveObject)->
receive
    
    %%Methodinvovcation->active object delegation
    {methodinvocation,RequestPID, Methodname, Arguments,Token}->
        %%run method concurrent
        %%debug-print
        io:format("try invoke method: ~p at ~p~n", [Methodname,ActiveObject]),
        ActiveObject!{methodinvocation,RequestPID,Methodname,Arguments,self(),Token},
        activity(ActiveObject);
     
     %%Methodupdate
     {methodupdate,RequestPID,Methodname,Method,Token}->
         spawn(?MODULE,clone_activity,[ActiveObject,Methodname,Method,RequestPID,self(),Token]),
         activity(ActiveObject);
    %%type
    {get_type,RequestPID}->
        %%debug-print
        io:format("type request from ~p~n", [RequestPID]),
        RequestPID!{type,self(),activity},
        activity(ActiveObject);
    
    {get_pid,RequestPID}->
    %%debug-print
        io:format("pid request from ~p at ~p~n", [RequestPID,self()]),
        RequestPID!{pid,self()},
        activity(ActiveObject);
        
    %%process termination
    {dispose}->
        ActiveObject!{dispose,self()},
        %%debug-print
        io:format("activity: ~p disposed~n", [self()]);
    
    %%invalide message    
    {}->activity(ActiveObject)    
end.




%%% changed for Process
clone_activity(ActiveObject,Methodname,Method,RequestPID,Activity,Token)->
io:format("update method: ~p at ~p in ~p~n", [Methodname,ActiveObject,self()]),
try
        %%update entry in activeobject
        NewObject = sync_activeobject_clone(ActiveObject,Activity),
       sync_activeobject_methodmanipulation(methodupdate,NewObject,Methodname,Method),
        case RequestPID == nil of
        true ->
            nil;
        false ->
            RequestPID!{set_value,Token,(active(NewObject))}
        end
catch
    _:Reason ->
    io:format("error:~p on update method: ~p at ~pin ~p~n", [Reason,Methodname,ActiveObject,self()])
end.

sync_activeobject_methodmanipulation(Action,ActiveObject,Methodname,Method)->
ActiveObject!{Action,self(),Methodname,Method},
Value = receive
	{response,ActiveObject,ReturnValue} ->ReturnValue
	end,
Value.
sync_activeobject_clone(ActiveObject,Activity)->
ActiveObject!{clone,self(),Activity},
Value = receive
	{clone,ActiveObject,ReturnValue} ->ReturnValue
	end,
Value.
