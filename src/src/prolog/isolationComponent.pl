

read_isolation_component(FileName,IsoComp):-
  open(FileName,read,IsoCompFile),
  read(IsoCompFile,IsoComp),
  !.

  

isolation([precondition,Pos,PreCond,Seq],IsoComp,[precondition,Pos,[conjunct,pos(0,0,0,0,0,0),PreCond,IsoComp],Seq]):-!.
isolation([X|L],IsoComp,Res):-
  isolation(X,IsoComp,XT),
  Res = [XT|L],
  !
  ;
  isolation(L,IsoComp,LT),
  Res = [X|LT],
  !.
  

tryiso:-
  read_isolation_component('tmpfile/robotcleaner.mch.isocomp',IsoComp),
  trydata(P),
  isolation(P,IsoComp,Res),
  print(Res).
  



trydata(P):-
  P = [operation,pos(38,1,23,3,29,7),[identifier,pos(38,1,23,3,29,7),move12],[sys(list),[]],[sys(list),[]],[precondition,pos(39,1,24,5,29,7),[conjunct,pos(40,1,25,7,25,47),[conjunct,pos(41,1,25,7,25,27),[equal,pos(42,1,25,7,25,13),[identifier,pos(43,1,25,7,25,9),pos],[integer,pos(44,1,25,13,25,13),1]],[greater_equal,pos(45,1,25,17,25,27),[identifier,pos(46,1,25,17,25,22),energy],[integer,pos(47,1,25,27,25,27),6]]],[negation,pos(48,1,25,31,25,47),[equal,pos(49,1,25,35,25,46),[identifier,pos(50,1,25,35,25,40),energy],[integer,pos(51,1,25,44,25,46),100]]]],[sequence,pos(52,1,27,7,28,26),[sys(list),[[assign,pos(53,1,27,7,27,14),[sys(list),[[identifier,pos(54,1,27,7,27,9),pos]]],[sys(list),[[integer,pos(55,1,27,14,27,14),2]]]],[assign,pos(56,1,28,7,28,26),[sys(list),[[identifier,pos(57,1,28,7,28,12),energy]]],[sys(list),[[minus_or_set_subtract,pos(58,1,28,17,28,26),[identifier,pos(59,1,28,17,28,22),energy],[integer,pos(60,1,28,26,28,26),6]]]]]]]]]].

