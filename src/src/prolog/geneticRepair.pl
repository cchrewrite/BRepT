% Generate a list of "sys(newSym)".
generate_sysempty_list(0,[]):-!.
generate_sysempty_list(N,[sys(newSym)|L]):-
  N1 is N - 1,
  generate_sysempty_list(N1,L),
  !.

% Generate a new predicate tree.
generate_predicate_tree([Func,NumArgs],[Func|Args]):-
  NumArgs > 0,
  generate_sysempty_list(NumArgs,Args),
  !.
generate_predicate_tree([Func,NumArgs],Func):-
  NumArgs = 0,
  !.
  
% Apply a single change to an expression (in the form of lists).
% Exp - The original expression. i.e. [plus,a,[mult,b,c]].
% Pred - A predicate used to change the expression. i.e. [plus,2], where "plus" is the functor of the predicate, and "2" is the number of arguments.
% Depth - The depth of search. e.g. The number of changes applied to the original expression.
% PID - The process ID.
% Res - Results.


% Add a new arguments (The functor is also revised. It is also applied to predicates without any arguments).
genetic_change_basic(X,system(addArg),[sys(newSym),sys(newSym)]):-
  \+is_list(X),
  !.
genetic_change_basic([_|Args],system(addArg),[sys(newSym)|NewArgs]):-
  append(L1,L2,Args),
  append(L1,[sys(newSym)|L2],NewArgs).

% Delete an old arguments (The functor is also revised. It is only applied to predicates with one or more than one arguments. The deleted argument should be a predicate without any arguments).
genetic_change_basic([_|Args],system(delArg),Res):-
  append(L1,[X|L2],Args),
  \+is_list(X), % If X is not a list, then it does not have any arguments.
  append(L1,L2,NewArgs),
  (
    NewArgs = [],
    Res = sys(newSym)
    ;
    NewArgs \= [],
    Res = [sys(newSym)|NewArgs]
  ).


% Replace the old functor with the new functor when their numbers of arguments agree with each other.
genetic_change_basic(Func,[Pred,0],Pred):-
  \+is_list(Func),
  Func \= Pred.
genetic_change_basic([Func|Args],[Pred,NumArgs],[Pred|Args]):-
  Func \= Pred,
  length(Args,NumArgs).


  

% Change sub expressions.
genetic_change_basic([Func|Args],Pred,[Func|NewArgs]):-
  append(L1,[X|L2],Args),
  genetic_change_basic(X,Pred,NewX),
  append(L1,[NewX|L2],NewArgs).


% Test if a changed expression is valid. A valid expression should contain no "sys(newSym)" annotation.
valid_expression(E):-
  flatten(E,ET),
  \+member(sys(newSym),ET),
  !.

% Count the number of "sys(newSym)" in an expression.
count_sysnewsym(Exp,Res):-
  flatten(Exp,E),
  count_sysnewsym_sub(E,Res),
  !.
count_sysnewsym_sub([],0):-!.
count_sysnewsym_sub([sys(newSym)|L],Res):-
  count_sysnewsym_sub(L,R),
  Res is R + 1,
  !.
count_sysnewsym_sub([X|L],Res):-
  X \= sys(newSym),
  count_sysnewsym_sub(L,Res),
  !.


% Change an expression (in the form of lists) via genetic algorithm.
% Exp - The original expression. i.e. [plus,a,[mult,b,c]].
% PredSet - A set of possible predicates for changing the expression. i.e. [[plus,2],[minus,2],[mult,2],[a,0],[b,0],[c,0],system(addArg),system(delArg),system(permuteArg)]. In particular, "system(Method)" denotes build-in methods.
% Depth - The depth of search. e.g. The number of changes applied to the original expression.
% PID - The process ID.
% Res - Results.
:-retractall(gen_record(_,_)).
:-dynamic gen_record/2.
genetic_change(Exp,PredSet,Depth,PID,Res):-
  get_time(PID),
  assert(gen_record(PID,Exp)),
  genetic_change_bfs([Exp],PredSet,Depth,PID,Res).

genetic_change_bfs(_,_,Depth,_,[]):-
  Depth =< 0,
  !.
genetic_change_bfs(ExpSet,PredSet,Depth,PID,[ResSet|ResSetList]):-
  Depth > 0,
  D is Depth - 1,
  findall(
    NewExp,
    (
      member(Exp,ExpSet),
      member(Pred,PredSet),
      genetic_change_basic(Exp,Pred,NewExp),
      count_sysnewsym(NewExp,NumNewSym),
      NumNewSym < Depth,
      \+gen_record(PID,NewExp),
      assert(gen_record(PID,NewExp))
    ),
    NewExpSet
  ),
  findall(
    [R,Depth],
    (
      member(R,NewExpSet),
      valid_expression(R)
    ),
    ResSet
  ),
  genetic_change_bfs(NewExpSet,PredSet,D,PID,ResSetList).

/*
% Check if expressions P and Q has the same type structure, based on type information in TypeSet.

% Pass the check if the expressions are untyped.
check_type(_,_,untyped):-!.
 
check_type(P,Q,TypeSet):-
  \+is_list(P),
  \+is_list(Q),
  get_type([P,0],TypeSet,T),
  get_type([Q,0],TypeSet,T),
  !.
check_type(P,[Q|ArgsQ],TypeSet):-
  \+is_list(P),
  length(ArgsQ,LQ),
  get_type([P,0],TypeSet,T),
  get_type([Q,LQ],TypeSet,T),
  !.
check_type([P|ArgsP],Q,TypeSet):-
  \+is_list(Q),
  length(ArgsP,LP),
  get_type([P,LP],TypeSet,T),
  get_type([Q,0],TypeSet,T),
  !.
check_type([P|ArgsP],[Q|ArgsQ],TypeSet):-
  length(ArgsP,LP),
  length(ArgsQ,LQ),
  get_type([P,LP],TypeSet,T),
  get_type([Q,LQ],TypeSet,T),
  LP = LQ,
  check_type_sub()
  !.




% Get the type of P (not a list) from TypeSet. T is the type of P.
get_type(P,TypeSet,T):-
  member([T,PL],TypeSet),
  member(P,PL),
  !.
*/
