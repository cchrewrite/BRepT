MACHINE
  DiningPhilDeadlock
VARIABLES
  phil1l,phil2l,phil3l,phil1r,phil2r,phil3r,pos1,pos2,pos3
INVARIANT
  phil1l : 0..1 &
  phil2l : 0..1 &
  phil3l : 0..1 &
  phil1r : 0..1 &
  phil2r : 0..1 &
  phil3r : 0..1 &
  pos1 : 0..1 &
  pos2 : 0..1 &
  pos3 : 0..1 &
  phil1l + phil2l + phil3l + phil1r + phil2r + phil3r + pos1 + pos2 + pos3 = 3

INITIALISATION
  phil1l := 0 ;
  phil2l := 0 ;
  phil3l := 0 ;
  phil1r := 0 ;
  phil2r := 0 ;
  phil3r := 0 ;
  pos1 := 1 ;
  pos2 := 1 ;
  pos3 := 1

OPERATIONS

  pickleft1 =
    PRE
      pos1 = 1
    THEN
      pos1 := 0 ;
      phil1l := 1
    END ;

  pickleft2 =
    PRE
      pos2 = 1
    THEN
      pos2 := 0 ;
      phil2l := 1
    END ;

  pickleft3 =
    PRE
      pos3 = 1
    THEN
      pos3 := 0 ;
      phil3l := 1
    END ;

  pickright1 =
    PRE
      pos2 = 1
    THEN
      pos2 := 0 ;
      phil1r := 1
    END ;

  pickright2 =
    PRE
      pos3 = 1
    THEN
      pos3 := 0 ;
      phil2r := 1
    END ;

  pickright3 =
    PRE
      pos1 = 1
    THEN
      pos1 := 0 ;
      phil3r := 1
    END ;

  eat1 =
    PRE
      phil1l = 1 &
      phil1r = 1
    THEN
      phil1l := 0 ;
      phil1r := 0 ;
      pos1 := 1 ;
      pos2 := 1
    END ;

  eat2 =
    PRE
      phil2l = 1 &
      phil2r = 1
    THEN
      phil2l := 0 ;
      phil2r := 0 ;
      pos2 := 1 ;
      pos3 := 1
    END ;
  

  eat3 =
    PRE
      phil3l = 1 &
      phil3r = 1
    THEN
      phil3l := 0 ;
      phil3r := 0 ;
      pos3 := 1 ;
      pos1 := 1
    END

END
