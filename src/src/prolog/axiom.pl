axiom_list(S):-
  S = [
    [axiom1,[+aaa,-bbb,-ccc]],
    [axiom2,[+bbb,-ccc]],
    [axiom3,[+ppp,-qqq]],
    [axiom4,[+ccc,-[+ppp,-qqq,-[+rrr,-sss]]]],
    [axiom5,[+rrr,-sss]],
    [axiom6,[+qqq]]
  ].

test1:-
  axiom_list(A),
  %Goal = [-aaa],
  Goal = [-[+ppp,-[+ppp,-qqq,-[+rrr,-sss]]]],
  sld_resolution(Goal,A,10,Res),
  print_by_line(Res),nl.
