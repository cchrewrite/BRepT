% If no goal, then resolution is successful.
sld_resolution([],_,_,[]).

% If the first goal does not have premises, then resolve it.
sld_resolution([-Goal|GList],AxiomSet,MaxDepth,Result):-
  Goal \= [+_|_],
  D1 is MaxDepth - 1,
  member(Axiom,AxiomSet),
  copy_term(Axiom,[AxName,[+Goal|NewGoal]]),
  append(NewGoal,GList,NewGoalList),
  % Save current results for logging.
  copy_term(NewGoalList,NT),
  % Resolve the next goal.
  sld_resolution(NewGoalList,AxiomSet,D1,ResTemp),
  Result = [[get,NT,by,AxName]|ResTemp].

% If the first goal has premises, then add the premises to the axiom set and resolve it (For instance, if the goal is -[+a,-b,-c], then add +b and +c to the axiom set and resolve -a).
sld_resolution([-Goal|GList],AxiomSet,MaxDepth,Result):-
  Goal = [+G|_],
  % Find all premises which are facts.
  findall(
    [premise,[+P]],
    (
      member(-P,Goal),
      P \= [+_|_]
    ),
    PSet
  ),
  % Find all premises which are implication rules.
  findall(
    [premise,Q],
    (
      member(-Q,Goal),
      Q = [+_|_]
    ),
    QSet
  ),
  % Bulid a premise set, and add it to the axiom set.
  append(PSet,QSet,PremiseSet),
  append(AxiomSet,PremiseSet,APSet),
  % Resolve the first goal.
  sld_resolution([-G],APSet,MaxDepth,ResTmp1),
  length(ResTmp1,D2),
  D1 is MaxDepth - D2,
  % resolve the other goals.
  sld_resolution(GList,AxiomSet,D1,ResTmp2),
  append(ResTmp1,ResTmp2,Result).
  
  
