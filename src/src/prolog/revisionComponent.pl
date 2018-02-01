:-[isolationComponent].

read_revision_component(FileName,RevComp):-
  open(FileName,read,RevCompFile),
  read(RevCompFile,RevComp),
  !.

operation_revision([precondition,Pos,PreCond,Seq],[negation,pos(0,0,0,0,0,0),IsoPreCond],RevComp,[precondition,pos(0,0,0,0,0,0),IsoPreCond,RevComp]):-!.


%operations(pos(97,1,30,1,168,7),[OP1,OP2])

split_and_revise(TL,revision(OpeName,IsoComp,RevComp),NewTL):-
  TL = [operations,PosTL,[sys(list),OpeList]],
  % Split.
  append(L1,[[operation,_,[identifier,_,OpeName],U,V,P]|L2],OpeList),
  atom_concat(OpeName,'_m',NameM),
  atom_concat(OpeName,'_r',NameR),
  isolation([operation,pos(0,0,0,0,0,0),[identifier,pos(0,0,0,0,0,0),NameM],U,V,P],IsoComp,OpeM),
  % Revise.
  IsoComp = [negation,pos(0,0,0,0,0,0),IsoPreCond],
  member(NewAsgn,RevComp),
  OpeR = [operation,pos(0,0,0,0,0,0),[identifier,pos(0,0,0,0,0,0),NameR],U,V,[precondition,pos(0,0,0,0,0,0),IsoPreCond,NewAsgn]],
  append(L1,[OpeM,OpeR|L2],NewOpeList),
  NewTL = [operations,PosTL,[sys(list),NewOpeList]].

/*
split_and_revise([operations, Pos, OpeList],OpeName,IsoComp,RevComp,Res):-
  nl,print(pppppppppppp),nl,print(OpeList),nl,
  !.
split_and_revise([X|L],IsoComp,RevComp,Res):-
print(X),nl,
  split_and_revise(X,IsoComp,RevComp,XT),
  Res = [XT|L],
  !
  ;
  split_and_revise(L,IsoComp,RevComp,LT),
  Res = [X|LT],
  !.
*/  

