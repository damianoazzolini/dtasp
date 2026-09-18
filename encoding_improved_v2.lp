
% the max size (internal + leaves) is 2^(n+1) - 1, where n is the number of features
% this also applies for max depth
% N = 2 -> 2^(2+1) - 1 = 7
% N = 3 -> 2^(3+1) - 1 = 15
% N = 4 -> 2^(4+1) - 1 = 31

% the size is the total number of nodes (internal + leaves)
% size(15).
node(1..S):- size(S).

even(N):- node(N), N\2 = 0.
odd(N):- node(N), N\2 = 1.

% alternative: each node can be either internal or terminal
% then, avail left and right only for internal nodes

% additional -1 as 1 is internal by definition
n_internal(N):- V = #max{ A : node(A)}, N = ((V-1)/2) - 1.
internal(1).
V{internal(N) : node(N), N != 1}V :- n_internal(V).
terminal(N):- node(N), not internal(N).

% The number of terminal nodes must be balanced between even and odd indexes
% is this correct?
% n_terminal_even(N):- N = #count{X : terminal(X), X\2 = 0}.
% n_terminal_odd(N):- N = #count{X : terminal(X), X\2 = 1}.
% :- n_terminal_even(NE), n_terminal_odd(NO), NE > NO + 1.
% :- n_terminal_odd(NO), n_terminal_even(NE), NO > NE + 1.



% left child of a node: even([index+1, min(2*index, size-1)])
avail_left(Index,IndexLeft):-
    size(Size),
    internal(Index),
    even(IndexLeft),
    IndexLeft >= Index + 1,
    IndexLeft <= min(2*Index,Size-1).      
avail_right(Index,IndexRight):-
    size(Size),
    internal(Index),
    odd(IndexRight),
    IndexRight >= Index + 2,
    IndexRight <= min(2*Index+1,Size).    
    % IndexRight <= min(2*Index+1,size).


        
% left and right child for each node
0{left(Index,IndexLeft) : avail_left(Index,IndexLeft)}1 :- internal(Index).
0{right(Index,IndexRight) : avail_right(Index,IndexRight)}1 :- internal(Index).

% parent indexes must be smaller than child indexes
:- left(Index,IndexLeft), IndexLeft <= Index.
:- right(Index,IndexRight), IndexRight <= Index.

:- node(Node), #count{X : left(Node,X)} > 1.
:- node(Node), #count{X : right(Node,X)} > 1.
:- left(Index0,X), left(Index1,X), Index0 != Index1.
:- right(Index0,X), right(Index1,X), Index0 != Index1.

:- node(Index), not internal(Index), not terminal(Index).

% at least one even and one odd terminal node
:- #count{N : terminal(N), N\2 = 0} = 0.
:- #count{N : terminal(N), N\2 = 1} = 0.


% connectivity constraints
% reachable(1).
% reachable(Index):- index(_,Index), Index > 1, index(_,IndexParent), left(IndexParent,Index), reachable(IndexParent).
% reachable(Index):- index(_,Index), Index > 1, index(_,IndexParent), right(IndexParent,Index), reachable(IndexParent).
% % :- terminal(Index), not reachable(Index).
% :- index(_,Index), not reachable(Index).
% can I replace the reachable construction with a constraint over the number of terminals?
% leaves = 1 + internal nodes
% :- #count{N : terminal(N)} = CT, #count{N : internal(N)} = CI, CT != CI + 1.

% class assignments
class(Index,positive):- terminal(Index), left(_,Index).
class(Index,negative):- terminal(Index), right(_,Index).

% feature assignments

% feature(F):- example(_,F,_).

% each internal node has exactly one feature
1{internal_feature(Index,Feature) : feature(Feature)}1:- internal(Index).
% assume a feature is used only once -- this is not correct, prunes too much
% :- internal_feature(Index0,Feature), internal_feature(Index1,Feature), Index0 != Index1.
% an internal feature can be used only once along a path from the root to a leaf
:- reaches(E, Node0),
    reaches(E, Node1),
    internal_feature(Node0, Feature),
    internal_feature(Node1, Feature),
    Node0 != Node1.
% more pruning: a node and its children cannot have the same feature
:- left(Node,Child), internal_feature(Node, Feature), internal_feature(Child, Feature).
:- right(Node,Child), internal_feature(Node, Feature), internal_feature(Child, Feature).

% pruning: the leaves cannot have all the same class, otherwise the tree is useless
:- not class(_,positive).
:- not class(_,negative).

% The root is reached by every example
reaches(E, 1) :-
    example(E, _, _).

% A positive feature value follows the left branch - also store the length?
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

% Every example must have its target classification: prunes no classification and incorrect
:- target(E, Expected), not classified(E, Expected).
% No example may have an incorrect classification: prunes only incorrect classifications
% not enough alone but this makes much faster the solving
:- target(E, Expected), classified(E, Actual), Actual != Expected.

% % % weak constraints version
% :~ target(E, Expected), not classified(E, Expected).[1@1,E]
% :~ target(E, Expected), classified(E, Actual), Actual != Expected.[1@1,E]

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