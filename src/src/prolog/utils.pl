print_by_line([]):-!.
print_by_line([X|L]):-
  print(X),nl,
  print_by_line(L),
  !.

print_message([]):-nl,!.
print_message([X|L]):-
  print(X),
  print(' '),
  print_message(L).

for(P,P,Q):-
  Q >= P.
for(I,P,Q):-
  Q > P,
  P1 is P + 1,
  for(I,P1,Q).
