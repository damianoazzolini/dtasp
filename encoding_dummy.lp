% must be odd
% with this version, you get sat only for the optimal size
% #const size=11. 
% search for the best size
% avail_sizes(1..21).
% 1{size(S) : avail_sizes(S), S\2 = 1}1.

% :~ size(S). [S@1,S]

% size(7).

% the max size (internal + leaves) is 2^(n+1) - 1, where n is the number of features

% letters for debug
% node(a).
% node(b).
% node(c).
% node(d).
% node(e).
% index(a,1).
% node(1..size).
% id(1..size).
size(13).
node(1..S):- size(S).
id(1..S):- size(S).
index(1,1).



even(N):- id(N), N\2 = 0.
odd(N):- id(N), N\2 = 1.


% generate all possible assignments of indexes to nodes
1{index(Node,Id) : node(Node)}1:- id(Id).
% each node has exactly one index
:- node(N), not index(N,_).
% :- index(N0, Id), index(N1, Id), N0 != N1. % this prunes nothing
% top node always has index 1

% left child of a node: even([index+1, min(2*index, size-1)])
avail_left(Index,IndexLeft):-
    size(Size),
    index(Node,Index),
    even(IndexLeft),
    IndexLeft >= Index + 1,
    IndexLeft <= min(2*Index,Size-1).
    % IndexLeft <= min(2*Index,size-1).
% right child of a node: odd([index+2, min(2*index + 1, size)])
avail_right(Index,IndexRight):-
    size(Size),
    index(Node,Index),
    odd(IndexRight),
    IndexRight >= Index + 2,
    IndexRight <= min(2*Index+1,Size).
    % IndexRight <= min(2*Index+1,size).

% one left child and one right child for each node
% {left(Index,IndexLeft) : avail_left(Index,IndexLeft)}.
% {right(Index,IndexRight) : avail_right(Index,IndexRight)}.
0{left(Index,IndexLeft) : avail_left(Index,IndexLeft)}1 :- index(_,Index).
0{right(Index,IndexRight) : avail_right(Index,IndexRight)}1 :- index(_,Index).



% parent indexes must be smaller than child indexes
:- left(Index,IndexLeft), IndexLeft <= Index.
:- right(Index,IndexRight), IndexRight <= Index.

:- index(Node,Index), #count{X : left(Index,X)} > 1.
:- index(Node,Index), #count{X : right(Index,X)} > 1.
:- left(Index0,X), left(Index1,X), Index0 != Index1.
:- right(Index0,X), right(Index1,X), Index0 != Index1.

terminal(Index):- index(_,Index), not left(Index,_), not right(Index,_).
:- terminal(1).
internal(Index):- index(_,Index), right(Index,_), left(Index,_).
% :- #count{N : terminal(N)} < 2. 

:- index(_,Index), not internal(Index), not terminal(Index).

% connectivity constraints
% reachable(1).
% reachable(Index):- index(_,Index), Index > 1, index(_,IndexParent), left(IndexParent,Index), reachable(IndexParent).
% reachable(Index):- index(_,Index), Index > 1, index(_,IndexParent), right(IndexParent,Index), reachable(IndexParent).
% % :- terminal(Index), not reachable(Index).
% :- index(_,Index), not reachable(Index).
% can I replace the reachable construction with a constraint over the number of terminals?
% leaves = 1 + internal nodes
:- #count{N : terminal(N)} = CT, #count{N : internal(N)} = CI, CT != CI + 1.

% class assignments
class(Index,positive):- index(_,Index), terminal(Index), left(_,Index).
class(Index,negative):- index(_,Index), terminal(Index), right(_,Index).

% feature assignments

% feature(F):- example(_,F,_).

% each internal node has exactly one feature
1{internal_feature(Index,Feature) : feature(Feature)}1:- internal(Index).
% assume a feature is used only once -- this is not correct, prunes too much
% :- internal_feature(Index0,Feature), internal_feature(Index1,Feature), Index0 != Index1.
% pruning: a feature cannot be used more than > internal nodes - 1 times, can we improve this?

% pruning: the leaves cannot have all the same class, otherwise the tree is useless
% :- #count{Index : class(Index,positive)} = 0.
% :- #count{Index : class(Index,negative)} = 0.
:- not class(_,positive).
:- not class(_,negative).

% The root is reached by every example
reaches(E, 1) :-
    example(E, _, _).

% A positive feature value follows the left branch
reaches(E, Child) :-
    reaches(E, Parent),
    left(Parent, Child),
    internal_feature(Parent, Feature),
    example(E, Feature, positive).

% A negative feature value follows the right branch
reaches(E, Child) :-
    reaches(E, Parent),
    right(Parent, Child),
    internal_feature(Parent, Feature),
    example(E, Feature, negative).

% Classification at a reached terminal
classified(E, Class) :-
    reaches(E, Terminal),
    terminal(Terminal),
    class(Terminal, Class).

% Every example must have its target classification
:- target(E, Expected),
   not classified(E, Expected).

% No example may have an incorrect classification
:- classified(E, Actual),
   target(E, Expected),
   Actual != Expected.

% #show classified/2.
% prune: two nodes in the same paths cannot have the same feature - this makes everything slow
% :- reaches(E, Node0), reaches(E, Node1), internal_feature(Node0, Feature), internal_feature(Node1, Feature), Node0 != Node1.

% TODO improvement: impose a depth limit?

%%%%%%%%%% below wrong
% % compute classification of examples based on the tree structure and feature assignments
% % if an example reaches a terminal node, it is classified according to the class of that node
% % assume right -> neg, left -> pos
% discriminated(Feature,NodeIndex,positive):-
%     % feature(Feature),
%     index(_,NodeIndex),
%     left(NodeParent,NodeIndex),
%     internal_feature(NodeParent,Feature).
% discriminated(Feature,NodeIndex,negative):-
%     % feature(Feature),
%     index(_,NodeIndex),
%     right(NodeParent,NodeIndex),
%     internal_feature(NodeParent,Feature).

% discriminated(Feature,NodeIndexTerminal,Class):-
%     terminal(NodeIndexTerminal),
%     connected(Node,NodeIndexTerminal),
%     discriminated(Feature,Node,Class).

% % check consistency - should not prune
% :- discriminated(F,N,positive), discriminated(F,N,negative).

% % in the leaves I want all discriminated along the path towards the leaf
% connected(A,B):- left(A,B).
% connected(A,B):- right(A,B).
% connected(A,C):- left(A,B), connected(B,C).
% connected(A,C):- right(A,B), connected(B,C).


% % % impose all examples are classified ok
% % discriminated_at(Example,Feature,Class,TerminalIndex):-
% %     example(Example,Feature,Class),
% %     discriminated(Feature,TerminalIndex,Class),
% %     terminal(TerminalIndex),
% %     class(TerminalIndex,TargetClass), % same class
% %     target(Example,TargetClass).

% % :- example(E,_,_), not discriminated_at(E,_,_,_).

% % cannot fall into a terminal
% cannot(Example,T) :- %,Feature):-
%     terminal(T),
%     example(Example,Feature,C0),
%     discriminated(Feature,T,C1),
%     C0 != C1.
% cannot(Example,T) :- %,Feature):-
%     terminal(T),
%     class(T,TC0),
%     example(Example,_,_),
%     target(Example,TC1),
%     TC0 != TC1.

% n_terminals(N):- N = #count{X : terminal(X)}.
% % means that there should be at least one terminal node that classifies the example correctly
% ccannot(NT):- example(E,_,_), #count{ X : cannot(E,X)} = NT.
% :- ccannot(NT), n_terminals(NT).

% #show c/3.
% #show cannot/2.
% #show n_terminals/1.
% #show ccannot/1.


% discriminated_at(e1,f3,negative,5)
% discriminated_at(e2,f4,negative,5)
% discriminated_at(e3,f4,positive,2)

% minimize the number of features used - useless by now as the three is fixed
% :~ internal_feature(_,Feature). [1@1,Feature]

% #show may_fall_into_terminal/2.
% #show discriminated_at/4.
% #show discriminated_at(e1,Feature,Class,TerminalIndex) : discriminated_at(e1,Feature,Class,TerminalIndex).

% #show connected/2.

% % #show internal/1.
% % #show index/2.
#show left/2.
#show right/2.
% #show terminal/1.
% % % #show reachable/1.
#show class/2.
#show internal_feature/2.
% #show discriminated/3.

#show.
% % #show discriminated(A,B,C) : discriminated(A,B,C), terminal(B).
% #show discriminated(A,B,C) : discriminated(A,B,C), terminal(B).