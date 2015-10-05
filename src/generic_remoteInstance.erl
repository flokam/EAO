-module(generic_remoteInstance).
-export([new/1]).

new(Activity)->
case is_pid(Activity) of
    true->
        generic_remoteStub:new(Activity);
    false->
        %% make pid request
        Activity!{get_pid,self()},
        PID = receive
            {pid,ActivityPID}->ActivityPID
            end,
        generic_remoteStub:new(PID)
end.


