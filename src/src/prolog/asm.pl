state_try(S):-
  S = [
    [a,num100],
    [b,num200],
    [c,[a,plus,b]]
  ].

operation_try(P):-
  P = [
    pre([-[a,equal,num100],-[b,equal,num200]]),
    assignment([[],c,[a,minus,b]],[],[])
  ].

% Firstly, use sld_resolution to prove pre().
% Then use rewriting to assign values.
