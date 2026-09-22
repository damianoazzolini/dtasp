% example(e128,f6,positive).
% target(e1,negative).
value(positive).
value(negative).
dir(left).
dir(right).

feature(X):-example(_,X,_).
instance(E) :- example(E,_,_).

depth(0..3).

{nodes(K,F):feature(F)} :- depth(K).
:-#count{F:nodes(0,F)}!=1.


{parent(F1,K,F):nodes(K-1,F1)} = 1 :- depth(K),K>0, nodes(K,F).

hasChild(K-1,F) :- parent(F,K,F1).
:-hasChild(K,F), #count{F1: parent(F,K+1,F1)}!=2.

leaf(K,F) :- nodes(K,F), not hasChild(K,F).

{edge(K-1,F1,V,F):value(V)} = 1 :- parent(F1,K,F).
:-edge(K,F,V,F1),edge(K,F,V,F2),F1!=F2.

{label(K,F,V,L):value(L)}=1:-leaf(K,F),value(V).

reach(E,1,F1) :- edge(0,F,V,F1),example(E,F,V).
reach(E,K+1,F2) :- reach(E,K,F1),edge(K,F1,V,F2),example(E,F1,V).

prediction(E,L) :- reach(E,K,F),label(K,F,V,L),example(E,F,V).

predicted(E) :- prediction(E,L).
:-instance(E), not predicted(E).

:-prediction(E,L),target(E,T),T!=L.
%:~hasChild(K,F). [1@1,K,F]

#show nodes/2.
#show parent/3.
#show leaf/2.
#show edge/4.
#show label/4.