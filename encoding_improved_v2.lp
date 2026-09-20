
% the max size (internal + leaves) is 2^(n+1) - 1, where n is the number of features
% this also applies for max depth
% N = 2 -> 2^(2+1) - 1 = 7
% N = 3 -> 2^(3+1) - 1 = 15
% N = 4 -> 2^(4+1) - 1 = 31

% --------------------- Tree construction

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
% the last and the second last nodes are always terminal
V{internal(N) : node(N), N != 1, size(S), N < S-1}V :- n_internal(V).
terminal(N):- node(N), not internal(N).
% terminal(N):- size(N).
% terminal(N):- size(S), N = S - 1.

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
% avail_right(Index,IndexRight):-
%     size(Size),
%     internal(Index),
%     odd(IndexRight),
%     IndexRight >= Index + 2,
%     IndexRight <= min(2*Index+1,Size).    
%     % IndexRight <= min(2*Index+1,size).


        
% left and right child for each node
1{left(Index,IndexLeft) : avail_left(Index,IndexLeft)}1 :- internal(Index), Index > 1.
left(1,2).
% 0{right(Index,IndexRight) : avail_right(Index,IndexRight)}1 :- internal(Index).
% improvement: once I get the left index I, the right is fixed as I+1 
right(Index,IndexRight):- left(Index,IndexLeft), IndexRight = IndexLeft + 1. %, avail_right(Index,IndexRight).

% parent indexes must be smaller than child indexes
:- left(Index,IndexLeft), IndexLeft <= Index.
% :- right(Index,IndexRight), IndexRight <= Index. % superfluous as right is always left + 1

% :- node(Node), #count{X : left(Node,X)} > 1. % useless as left is unique by construction
% :- node(Node), #count{X : right(Node,X)} > 1. % useless as right is unique by construction
% an index cannot be reused
:- left(Index0,X), left(Index1,X), Index0 != Index1.
% :- right(Index0,X), right(Index1,X), Index0 != Index1. % useless as right is always left + 1

% useless by construction as internal and terminal are complementary
% :- node(Index), not internal(Index), not terminal(Index).

% at least one even and one odd terminal node
:- #count{N : terminal(N), N\2 = 0} = 0.
:- #count{N : terminal(N), N\2 = 1} = 0.

% exactly one parent for each node (except the root)
parent(C) :- left(_, C).
parent(C) :- right(_, C).

:- node(C), C > 1, not parent(C).
:- node(C), C > 1,
   #count { P : left(P, C) } = PL,
   #count { P : right(P, C) } = PR,
   PL + PR != 1.


% connectivity constraints
% reachable(1).
% reachable(Index):- index(_,Index), Index > 1, index(_,IndexParent), left(IndexParent,Index), reachable(IndexParent).
% reachable(Index):- index(_,Index), Index > 1, index(_,IndexParent), right(IndexParent,Index), reachable(IndexParent).
% % :- terminal(Index), not reachable(Index).
% :- index(_,Index), not reachable(Index).
% can I replace the reachable construction with a constraint over the number of terminals?
% leaves = 1 + internal nodes
% :- #count{N : terminal(N)} = CT, #count{N : internal(N)} = CI, CT != CI + 1.

% % class assignments - this is not correct
% %  the class of a terminal node is determined by the examples that reach it, not by the index
% class(Index,positive):- terminal(Index), left(_,Index).
% class(Index,negative):- terminal(Index), right(_,Index).

% feature assignments

% feature(F):- example(_,F,_).

% ----------------------- Feature assignment to internal nodes

% each internal node has exactly one feature
1{internal_feature(Index,Feature) : feature(Feature)}1:- internal(Index).
% a feature can be used at most (i + 1) / 2 with i internal nodes
% max_feature_same_node(M):- n_internal(N), M = (N+1)/2. - is this sound?
% :- max_feature_same_node(M), feature(Feature), #count{N : internal_feature(N,Feature)} > M. 
% assume a feature is used only once -- this is not correct, prunes too much
% :- internal_feature(Index0,Feature), internal_feature(Index1,Feature), Index0 != Index1.

% an internal feature can be used only once along a path from the root to a leaf
% :- reaches(E, Node0),
%     reaches(E, Node1),
%     internal_feature(Node0, Feature),
%     internal_feature(Node1, Feature),
%     Node0 != Node1.
ancestor(A, B) :- left(A, B).
ancestor(A, B) :- right(A, B).
ancestor(A, C) :- ancestor(A, B), left(B, C).
ancestor(A, C) :- ancestor(A, B), right(B, C).

:- ancestor(A, B),
   internal_feature(A, F),
   internal_feature(B, F).

% % more pruning: a node and its children cannot have the same feature - included in the above constraint, but maybe it helps
% :- left(Node,Child), internal_feature(Node, Feature), internal_feature(Child, Feature).
% :- right(Node,Child), internal_feature(Node, Feature), internal_feature(Child, Feature).
% % the two children of a node cannot have the same feature - this is not correct, prunes too much
% % :- left(Node,ChildL), right(Node,ChildR), internal_feature(ChildL, Feature), internal_feature(ChildR, Feature).

% ------------------ Terminal nodes class assignment

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

% % Classification at a reached terminal
% classified(E, Class) :-
%     reaches(E, Terminal),
%     terminal(Terminal),
%     class(Terminal, Class).
% % Every example must have its target classification: prunes no classification and incorrect
% :- target(E, Expected), not classified(E, Expected).
% % No example may have an incorrect classification: prunes only incorrect classifications
% % not enough alone but this makes much faster the solving
% :- target(E, Expected), classified(E, Actual), Actual != Expected.

% pruning: the leaves cannot have all the same class, otherwise the tree is useless
:- not class(_,positive).
:- not class(_,negative).

% the terminal node gets the class of the example
class(Terminal, Class) :- terminal(Terminal), reaches(E, Terminal), target(E, Class).
% a terminal node cannot have two different classes
:- class(T,C0), class(T,C1), C0 != C1.
% all examples must reach a terminal node
at_terminal(E, T) :- reaches(E, T), terminal(T).
:- example(E,_,_), not at_terminal(E, _).
% :- target(E0,T0), target(E1,T1), E0 != E1, at_terminal(E0,T), at_terminal(E1,T), T0 != T1.

% % % weak constraint version
% :~ target(E, Expected), classified(E, Actual), Actual != Expected.[1@1,E]
% missclassified(N):- N = #count{E : target(E, Expected), classified(E, Actual), Actual != Expected}.
% #show missclassified/1.

% prune: two nodes in the same paths cannot have the same feature - this makes everything slow
% :- reaches(E, Node0), reaches(E, Node1), internal_feature(Node0, Feature), internal_feature(Node1, Feature), Node0 != Node1.

% TODO improvement: impose a depth limit?


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