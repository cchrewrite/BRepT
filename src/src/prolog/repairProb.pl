:-[utils,restrictedGeneticRepair,isolationComponent,revisionComponent].

read_history_operations(FileName,HisList):-
  open(FileName,read,HisFile),
  read_history_sub(HisFile,HisList),
  close(HisFile).
read_history_sub(HisFile,HisList):-
  read_string(HisFile,"\n"," ;",End,HH),
  (
    End = -1,
    HisList = [],
    !
    ;
    End >= 0,
    read_history_sub(HisFile,HL1),
    atom_string(HHA,HH),
    HisList = [HHA|HL1]
  ).

read_prob_machine(FileName,ProbList):-
  open(FileName,read,ProbFile),
  read_prob_sub(ProbFile,ProbList),
  close(ProbFile).
read_prob_sub(ProbFile,ProbList):-
  read(ProbFile,HH),
  (
    HH = end_of_file,
    ProbList = [],
    !
    ;
    HH \= end_of_file,
    read_prob_sub(ProbFile,PL1),
    ProbList = [HH|PL1]
  ).

% Usage: change_subterm(+Term,+SubTerm,-Result).
% This function finds SubTerm from Term and changes it. The change is only applied once.
change_subterm(T,T,RepList,NumChange,NewT):-
  prob_machine_to_list(T,TL),
  (
    % The cost of isolation is 1.
    NumChange = 1,
    member(isolation(OpeName,IsoRep),RepList),
    T = operation(_,identifier(_,OpeName),_,_,_),
print([replist,RepList]),
print(isolation(OpeName,IsoRep)),nl,
print(TL),nl,
    isolation(TL,IsoRep,NewTL)
    ;
    % The cost of revision is 2.
    NumChange = 2,
    RepList = [revision(OpeName,IsoComp,RevComp)],
    T = operations(_,_),
    split_and_revise(TL,revision(OpeName,IsoComp,RevComp),NewTL)
    ;
    r_genetic_change(TL,RepList,NumChange,_,NewTLSetAll),
    append(_,[NewTLSet],NewTLSetAll),
    member([NewTL,_],NewTLSet)
  ),
  prob_list_to_machine(NewTL,NewT).

change_subterm(T,SubT,RepList,NumChange,ResT):-
  \+is_list(T),
  T \= SubT,
  T =.. [Func|Args],
  append(A1,[X|A2],Args),
  change_subterm(X,SubT,RepList,NumChange,XT),
  append(A1,[XT|A2],ArgsT),
  ResT =.. [Func|ArgsT].
change_subterm(T,SubT,RepList,NumChange,ResT):-
  is_list(T),
  T \= SubT,
  append(A1,[X|A2],T),
  change_subterm(X,SubT,RepList,NumChange,XT),
  append(A1,[XT|A2],ResT).

prob_machine_to_list(pos(X1,X2,X3,X4,X5,X6),pos(X1,X2,X3,X4,X5,X6)):-!.
prob_machine_to_list(X,X):-
  atom(X),
  !.
prob_machine_to_list(X,X):-
  number(X),
  !.
prob_machine_to_list(P,[Func|ArgsT]):-
  \+is_list(P),
  \+atom(P),
  P =.. [Func|Args],
  prob_machine_to_list_sub(Args,ArgsT),
  !.
prob_machine_to_list(P,[sys(list),PT]):-
  is_list(P),
  prob_machine_to_list_sub(P,PT),
  !.
prob_machine_to_list_sub([],[]):-!.
prob_machine_to_list_sub([X|L],[XT|LT]):-
  prob_machine_to_list(X,XT),
  prob_machine_to_list_sub(L,LT),
  !.


prob_list_to_machine(pos(X1,X2,X3,X4,X5,X6),pos(X1,X2,X3,X4,X5,X6)):-!.
prob_list_to_machine(sequence(Pos,Asgm),sequence(Pos,Asgm)):-!.
prob_list_to_machine(initialisation(Pos,Asgm),initialisation(Pos,Asgm)):-!.
prob_list_to_machine(initialization(Pos,Asgm),initialization(Pos,Asgm)):-!.
prob_list_to_machine(X,X):-
  atom(X),
  !.
prob_list_to_machine(X,X):-
  number(X),
  !.
prob_list_to_machine([Func|ArgsT],P):-
  Func \= sys(list),
  prob_list_to_machine_sub(ArgsT,Args),
%print(xxxxxxxxxx),nl,
  P =.. [Func|Args],
%print(yyyyyyyyyyyy),nl,
  !.
prob_list_to_machine([sys(list),ArgsT],P):-
  prob_list_to_machine_sub(ArgsT,P),
  !.
prob_list_to_machine_sub([],[]):-!.
prob_list_to_machine_sub([XT|LT],[X|L]):-
  prob_list_to_machine(XT,X),
  prob_list_to_machine_sub(LT,L),
  !.


write_new_machine_to_file(FileName,Mch):-
  open(FileName,write,Stream),
  write_new_machine_to_file_sub(Stream,Mch),
  close(Stream).

write_new_machine_to_file_sub(_,[]):-!.
write_new_machine_to_file_sub(Stream,[X|L]):-
  write_term(Stream,X,[quoted(true)]),
  write(Stream,'.'),
  nl(Stream),
  write_new_machine_to_file_sub(Stream,L),
  !.


change_operations(Prog,[],_,0,Prog):-!.
change_operations(Prog,[_|OpeList],RepList,NumChange,NewProg):-
  change_operations(Prog,OpeList,RepList,NumChange,NewProg).
change_operations(Prog,[initialisation|OpeList],RepList,NumChange,NewProg):-
  for(I,1,NumChange),
  change_subterm(Prog,initialisation(_,_),RepList,I,PT),
  N1 is NumChange - I,
  change_operations(PT,OpeList,RepList,N1,NewProg).
change_operations(Prog,[OpeName|OpeList],RepList,NumChange,NewProg):-
  for(I,1,NumChange),
  change_subterm(Prog,operation(_,identifier(_,OpeName),_,_,_),RepList,I,PT),
  N1 is NumChange - I,
  change_operations(PT,OpeList,RepList,N1,NewProg).
change_operations(Prog,[OpeName|OpeList],RepList,NumChange,NewProg):-
  member(revision(OpeName,IsoComp,RevComp),RepList),
  for(I,1,NumChange),
  change_subterm(Prog,operations(_,_),[revision(OpeName,IsoComp,RevComp)],I,PT),
  N1 is NumChange - I,
  change_operations(PT,OpeList,RepList,N1,NewProg).





% Usage: replace_subterm(+Term,+SubTerm,+NewSubterm,-Result).
% This function finds SubTerm from Term and replace it with NewSubterm. The replacement is applied only once.
replace_subterm(T,T,U,U):-!.
replace_subterm(X,T,U,Y):-
  append(L1,[P|L2],X),
%print(P),nl,
  replace_subterm(P,T,U,Q),
  append(L1,[Q|L2],Y),
  !.




% Generating an outgoing subgraph model, which is used to evaluate the cost created by a revised component.

generate_outgoing_subgraph_model(X,IsoInit,Y):-
  prob_machine_to_list(X,XT),
%print(XT),nl,
  (
    replace_subterm(XT,[initialisation,_,_],IsoInit,YT)
    ;
    replace_subterm(XT,[initialization,_,_],IsoInit,YT)
  ),
  prob_list_to_machine(YT,Y).


/*

nitialisation(
  pos(26,1,16,1,19,12),
  sequence(pos(27,1,17,3,19,12),[assign(pos(28,1,17,3,17,10),[identifier(pos(29,1,17,3,17,5),pos)],[integer(pos(30,1,17,10,17,10),1)]),assign(pos(31,1,18,3,18,21),[identifier(pos(32,1,18,3,18,8),energy)],[identifier(pos(33,1,18,13,18,21),maxenergy)]),assign(pos(34,1,19,3,19,12),[identifier(pos(35,1,19,3,19,7),nnnnn)],[integer(pos(36,1,19,12,19,12),0)])])
)

*/

find_all_ope_from_path([],T,T):-!.
find_all_ope_from_path(Path,T,OpeList):-
  append(L,[X],Path),
  \+member(X,T),
  find_all_ope_from_path(L,[X|T],OpeList),
  !.
find_all_ope_from_path(Path,T,OpeList):-
  append(L,[X],Path),
  member(X,T),
  find_all_ope_from_path(L,T,OpeList),
  !.
find_all_ope_from_path(Path,OpeList):-
  find_all_ope_from_path(Path,[],OpeList),
  !.

:-dynamic mchfile_record/2.
change_prob_operation(FileName,[HistoryFile,IsoCompFile,RevCompFile],NumChange,OutFolder,OutProbName):-
  get_time(PID),
  assert(mchfile_record(PID,0)),
  read_prob_machine(FileName,ProbMch),
  read_history_operations(HistoryFile,HisList),
/*
prob_machine_to_list(ProbMch,RRR),
print_by_line(RRR),
prob_list_to_machine(RRR,ProbMchT),
print_by_line(ProbMchT),
!.
*/
  read_isolation_component(IsoCompFile,IsoComp),
  read_revision_component(RevCompFile,RevComp),
  atom_concat(IsoCompFile,'.init',IsoInitFileName),
  open(IsoInitFileName,read,IsoInitFile),
  read(IsoInitFile,IsoInit),
  find_all_ope_from_path(HisList,OpeList),
  append(_,[LastOpe],OpeList),
  RepList = [/*isolation(LastOpe,IsoComp),*/revision(LastOpe,IsoComp,RevComp)],%,rep(16,18,0),rep(6,3,0)],
  append(M1,[P|M2],ProbMch),
  % Output the subgraph model of the original model to a file.
  generate_outgoing_subgraph_model(P,IsoInit,PSub),
  append(M1,[PSub|M2],MchSub),
  atom_concat(FileName,'.sub.prob',FileNameSub),
  write_new_machine_to_file(FileNameSub,MchSub),
  % Change the original model.
  change_operations(P,[initialisation|OpeList],RepList,NumChange,PT),
  append(M1,[PT|M2],NewMch),
  mchfile_record(PID,NumMch),
  retractall(mchfile_record(PID,_)),
  MchID is NumMch + 1,
  assert(mchfile_record(PID,MchID)),
  % Output the revised model to a file.
  atom_concat('.',MchID,FN1),
  atom_concat(OutProbName,FN1,FN2),
  atom_concat(OutFolder,'/',FN3),
  atom_concat(FN3,FN2,FN4),
  atom_concat(FN4,'.prob',NewFileName),
  %print('Writing a new machine to: '),print(NewFileName),nl,
  write_new_machine_to_file(NewFileName,NewMch),
  % Output the subgraph model of the revised model to a file.
  generate_outgoing_subgraph_model(PT,IsoInit,PTSub),
  append(M1,[PTSub|M2],NewMchSub),
  atom_concat(FN4,'.sub.prob',NewFileNameSub),
  write_new_machine_to_file(NewFileNameSub,NewMchSub).

% Rewrite a prob constraint to a list.

/*

% Constraints for z3 are the conjunction of invariants and a precondition.
output_constraints_for_z3(FileName,[HistoryFile,IsoCompFile],NumChange,OutFolder,OutProbName):-
  read_prob_machine(FileName,ProbMch),
  read_history_operations(HistoryFile,HisList),

  read_isolation_component(IsoCompFile,IsoComp),
  find_all_ope_from_path(HisList,OpeList),
  append(_,[LastOpe],OpeList),
  RepList = [isolation(LastOpe,IsoComp)],%,rep(16,18,0),rep(6,3,0)],
  append(M1,[P|M2],ProbMch),
  change_operations(P,[initialisation|OpeList],RepList,NumChange,PT),
  append(M1,[PT|M2],NewMch),
  mchfile_record(PID,NumMch),
  retractall(mchfile_record(PID,_)),
  MchID is NumMch + 1,
  assert(mchfile_record(PID,MchID)),
  atom_concat('.',MchID,FN1),
  atom_concat(OutProbName,FN1,FN2),
  atom_concat(OutFolder,'/',FN3),
  atom_concat(FN3,FN2,FN4),
  atom_concat(FN4,'.prob',NewFileName),
  %print('Writing a new machine to: '),print(NewFileName),nl,
  write_new_machine_to_file(NewFileName,NewMch).



*/

