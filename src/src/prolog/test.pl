% A test program for genetic_change_basic/3.
test_gcb1(Res):-
  Exp = [plus,a,[mult,[minus,e,f],c]],
  %Pred = [plus,2],
  %Pred = system(addArg),
  Pred = system(delArg),
  genetic_change_basic(Exp,Pred,Res).

% A test program for genetic_change/5.
test_gc1(Depth,Res):-
  Exp = [plus,a,[mult,[minus,e,f],c]],
  PredSet = [[plus,2],[minus,2],[mult,2],[a,1],[b,1],[c,1],system(addArg),system(delArg),system(permuteArg)],
  genetic_change(Exp,PredSet,Depth,_,Res),
  member(ResT,Res),nl,print(Exp),nl,nl,
  print_by_line(ResT),nl,
  length(ResT,LL),
  print([number,of,possible,expression,is,LL]).
