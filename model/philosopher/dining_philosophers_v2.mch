
MACHINE dining_philosophers_v2
ABSTRACT_VARIABLES
  L1,
  L2,
  L3,
  R1,
  R2,
  R3,
  P1,
  P2,
  P3
INVARIANT
    L1 : 0 .. 1
  & L2 : 0 .. 1
  & L3 : 0 .. 1
  & R1 : 0 .. 1
  & R2 : 0 .. 1
  & R3 : 0 .. 1
  & P1 : 0 .. 1
  & P2 : 0 .. 1
  & P3 : 0 .. 1
  & L1 + R3 + P1 = 1
  & L2 + R1 + P2 = 1
  & L3 + R2 + P3 = 1
INITIALISATION
    BEGIN
        L1 := 0
      ;
        L2 := 0
      ;
        L3 := 0
      ;
        R1 := 0
      ;
        R2 := 0
      ;
        R3 := 0
      ;
        P1 := 1
      ;
        P2 := 1
      ;
        P3 := 1
    END
OPERATIONS
  PL1 = 
    PRE 
        P1 = 1
    THEN
        P1 := 0
      ;
        L1 := 1
    END;
  
  PL2 = 
    PRE 
        P2 = 1
    THEN
        P2 := 0
      ;
        L2 := 1
    END;
  
  PL3 = 
    PRE 
        P3 = 1
    THEN
        P3 := 0
      ;
        L3 := 1
    END;
  
  PR1 = 
    PRE 
        P2 = 1
    THEN
        P2 := 0
      ;
        R1 := 1
    END;
  
  PR2 = 
    PRE 
        P3 = 1
    THEN
        P3 := 0
      ;
        R2 := 1
    END;
  
  PR3 = 
    PRE 
        P1 = 1
    THEN
        P1 := 0
      ;
        R3 := 1
    END;
  
  PD1 = 
    PRE 
        L1 = 1
      & R1 = 1
    THEN
        L1 := 0
      ;
        R1 := 0
      ;
        P1 := 1
      ;
        P2 := 1
    END;
  
  PD2 = 
    PRE 
        L2 = 1
      & R2 = 1
    THEN
        L2 := 0
      ;
        R2 := 0
      ;
        P2 := 1
      ;
        P3 := 1
    END;
  
  PD3 = 
    PRE 
        L3 = 1
      & R3 = 1
    THEN
        L3 := 0
      ;
        R3 := 0
      ;
        P3 := 1
      ;
        P1 := 1
    END
END
