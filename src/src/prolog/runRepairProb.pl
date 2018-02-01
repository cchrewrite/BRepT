#!/usr/bin/env swipl

:-[repairProb].

:-initialization main.

main:-
  print(ppp),nl,
  current_prolog_flag(argv, Argv),
  format('Hello World, argv:~w\n', [Argv]),
  (
    nth0(0,Argv,FileName),
    nth0(1,Argv,HistoryFile),
    nth0(2,Argv,IsoCompFile),
    nth0(3,Argv,RevCompFile),
    nth0(4,Argv,N1),
    atom_number(N1,NumChange),
    nth0(5,Argv,TmpFolder),
    nth0(6,Argv,OutMchName),
    change_prob_operation(FileName,[HistoryFile,IsoCompFile,RevCompFile],NumChange,TmpFolder,OutMchName),
    fail
    ;
    halt(0)
  ).





