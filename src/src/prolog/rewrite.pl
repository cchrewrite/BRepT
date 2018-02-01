% Usage: substitute_list_all(+OldElem,+OldList,+NewElem,-NewList).
substitute_list_all(_,[],_,[]):-!.
substitute_list_all(E,E,NE,NE):-!.
substitute_list_all(E,X,_,X):-
  \+is_list(X),
  E \= X,
  !.
substitute_list_all(E,[X|L],NE,[NX|NL]):-
  substitute_list_all(E,X,NE,NX),
  substitute_list_all(E,L,NE,NL),
  !.

multi_substitute_list_all([],Exp,Exp):-!.
multi_substitute_list_all([[X,Y]|RList],Exp,Res):-
  substitute_list_all(X,Exp,Y,ResTmp),
  multi_substitute_list_all(RList,ResTmp,Res),
  !.

% Symbolic evaluation for abstract programs.
:-dynamic abs_prog/2.
abstraction_evaluation(Abs,Res):-
  get_time(PID),
  assert(abs_prog(PID,Abs)),
  abs_eval_sub(PID,0,[],Res).

test_abs_eval_1(Res):-
  abstract_program_try(P),
  member(abstraction(Abs),P),
  abstraction_evaluation(Abs,Res).

abs_eval_sub(PID,N0,Prev,Res):-
print_by_line(Prev),nl,
  N is N0 + 1,
  abs_prog(PID,AP),
  length(AP,LAP),
  (
    N =< LAP,
    nth1(N,AP,P),
    (
      P = [assign,X,Y,_],
      multi_substitute_list_all(Prev,Y,EY),
      abs_eval_sub(PID,N,[[X,EY]|Prev],Res)
      ;
      P \= [assign,_,_,_],
      abs_eval_sub(PID,N,Prev,Res)
    )
    ;
    N > LAP,
    Res = Prev
  ),
  !.
  

% Usage: rewrite_basic(+Expression,+Rule,-Result).
rewrite_basic(Exp,[_,Exp,Res],Res).
rewrite_basic([Exp|ExpList],Rule,[Res|ExpList]):-
  rewrite_basic(Exp,Rule,Res).
rewrite_basic([Exp|ExpList],Rule,[Exp|ResList]):-
  rewrite_basic(ExpList,Rule,ResList).

test1(Res):-
  rule_set_1(R),
  Exp = [[a,b,c],[b,d,a],[c,e,c],[a,[a,[a,b,c],c],c],[b,a,[b,a,[c,d,e]]]],
  member(Rule,R),
  rewrite_basic(Exp,Rule,Res).

% This function is not complete.
rewrite_full(Exp,RrtRuleSet,ImpRuleSet,SearchDepth,Res):-
  member(R,RrtRuleSet),
  copy_term(R,[Cond,LExp,RExp]),
  rewrite_basic(Exp,[Cond,LExp,RExp]),
  sld_resolution(Cond,ImpRuleSet).
  
