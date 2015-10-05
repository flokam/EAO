-module(generic_remoteStub,[Activity]).
-export([async_rmi/2,async_rmu/2]).

async_rmi(Methodname,Arguments)->
uFuture:new(future:create(methodinvocation,Activity,Methodname,Arguments)).

async_rmu(Methodname,Method)->
uFuture:new(future:create(methodupdate,Activity,Methodname,Method)).