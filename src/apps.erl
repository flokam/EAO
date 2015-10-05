-module(apps).
-export([test_mi/0,test_mu/0,test_mis/0,test_rmi/0,start_sandra/0,start_jakob/0,hotel/0,broker/0,customer/0,test_sec_llhl/0,test_sec_lh/0]).
-import(activity,[active/1,active/2]).
-import(future,[create/4,get_value/1]).
-import(object,[create/0,create/1]).

%%simple securitycheck
test_sec_llhl()->
%%a object with one low ->low and one high->low   invocationpattern
M=dict:store(ll,fun(Self)-> M=Self(l),M(Self,10) end,dict:store(l,fun(Self,X)->X+X end,dict:store(init,fun(Self)-> M=Self(l),io:format("low-method call->: ~p~n",[M(Self,30)]) end,dict:new()))),
O = create(M),
A =  active(O),
F = create(methodinvocation,A,ll,nil),
io:format("future: ~p~n", [F]),
%% get the Future-Value
io:format("future_value: ~p~n", [get_value(F)]).

test_sec_lh()->
%%a object with one low ->high  invocationpattern
M=dict:store(lh,fun(Self)-> M=Self(init),M(Self,nil) end,dict:store(l,fun(Self,X)->X+X end,dict:store(init,fun(Self)-> M=Self(l),io:format("low-method call->: ~p~n",[M(Self,30)]) end,dict:new()))),
O = create(M),
A =  active(O),
F = create(methodinvocation,A,lh,nil),
io:format("future: ~p~n", [F]),
%% get the Future-Value
io:format("future_value: ~p~n", [get_value(F)]).



%%simple methodinvocation
test_mi()->
%% create object using modulefunction
O = create(dict:store(name,fun(Self)->'FOO'end,dict:store(factorial,fun(Self,X)->mymath:factorial(X) end,dict:new()))),
io:format("activeobject: ~p~n", [O]),
%% create activity
A =  active(O),
io:format("activity: ~p~n", [A]),
%%start methodinvokation
F = create(methodinvocation,A,factorial,10),
io:format("future: ~p~n", [F]),
%% get the Future-Value
io:format("future_value: ~p~n", [get_value(F)])
.
%%end

%%simple methodupdate
test_mu()->
%% create object
O = create(dict:store(genericfun,fun(Self,X)->0 end,dict:store(factorial,fun(Self,X)->mymath:factorial(X) end,dict:new()))),
io:format("activeobject: ~p~n", [O]),
%% create activity
A =  active(O),
io:format("activity: ~p~n", [A]),
F = create(methodinvocation,A,factorial,10),
io:format("future: ~p~n", [F]),
io:format("future_value: ~p~n", [get_value(F)]),
get_value(create(methodinvocation,A,genericfun,10)),
%%UPDATE -> New Activity
%%long syntax
NewActivity = get_value(create(methodupdate,A,genericfun,fun(Self,X)->X end)),
get_value(create(methodinvocation,NewActivity,genericfun,10))
.
%%end

%%simple methodinvocation using self
test_mis()->
%% create object
O = object:create(dict:store(genericfun,fun(Self,X)->M=Self(factorial),M(Self,X) end,dict:store(factorial,fun(Self,X)->mymath:factorial(X) end,dict:new()))),
%% create activity
A =  active(O),
io:format("activity: ~p~n", [A]),
F = create(methodinvocation,A,factorial,10),
io:format("future: ~p~n", [F]),
io:format("future_value: ~p~n", [get_value(F)]),
get_value(create(methodinvocation,A,genericfun,20)).
%%end


%%rmi-stub example
test_rmi()->
O = create(dict:from_list([{genericfun,fun(Self,X)->M=Self(factorial),M(Self,X) end},{factorial,fun(Self,X)->mymath:factorial(X) end}])),
%% create activity
A = generic_remoteStub:new(active(O)),
io:format("activity: ~p~n", [A]),
io:format("future_value_generic: ~p~n", [(A:async_rmi(genericfun,10)):get_value()]),
%% Update
V = ((generic_remoteStub:new((A:async_rmu(genericfun,fun(Self,X)->X end)):get_value())):async_rmi(genericfun,10)):get_value(),
io:format("future_value_generic_afterupdate: ~p~n",[V]).

%% distribution one machine use in two shell's
%%first node called sandra 
start_sandra()->
O = create(dict:from_list([{genericfun,fun(Self,X)->X end},{factorial,fun(Self,X)->mymath:factorial(X) end}])),
%% create activity
active(O,alpha).

%%second node
start_jakob()->
Alpha= generic_remoteStub:new({alpha,sandra@nexus}),
io:format("future_value_generic: ~p~n", [(Alpha:async_rmi(genericfun,10)):get_value()]),
%%make update and new invocation
((generic_remoteStub:new((Alpha:async_rmu(genericfun,fun(Self,X)->timer:sleep(X) end)):get_value())):async_rmi(genericfun,1000)):get_value()
.



%%cutomen-broker-hotel exmaple
hotel()->
O = create(dict:from_list([{room,fun(Self,Date)->bookingreference end}])),
active(O,hotel).

broker()->
O = create(dict:from_list([{book,fun(Self,Date)-> Hotel = generic_remoteStub:new(hotel), Hotel:async_rmi(room,Date) end}])),
%% create activity
active(O,broker).

customer()->
Broker = generic_remoteStub:new(broker),
Broker:async_rmi(book,date).

