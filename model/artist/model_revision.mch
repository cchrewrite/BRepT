
MACHINE example_artist
SETS /* enumerated */
  City={city_1,city_2,city_3,city_4,city_5}
CONCRETE_CONSTANTS
  max_energy,
  connections
ABSTRACT_VARIABLES
  pos,
  energy
PROPERTIES
    max_energy : INTEGER
  & connections : POW(City * City)
  & max_energy = 3
  & connections = {city_1 |-> city_2,city_2 |-> city_3,city_1 |-> city_4,city_2 |-> city_5}
INVARIANT
    pos : City
  & energy : 0 .. max_energy
ASSERTIONS
  not(pos = city_5)
INITIALISATION
    BEGIN
        pos := city_1
      ;
        energy := 0
    END
OPERATIONS
  eat = 
    PRE 
        pos = city_1
    THEN
        energy := energy + 1
      ;
        IF pos = city_1 & energy = 4 THEN
          energy := 3
        END
    END;
  
  move(city_x,city_y) = 
    PRE 
        city_x : City
      & city_y : City
      & energy >= 1
      & pos = city_x
      & (city_x |-> city_y : connections or city_y |-> city_x : connections)
    THEN
        pos := city_y
      ;
        energy := energy - 1
      ;
        IF pos = city_4 & energy = 0 THEN
          energy := 1
        END
      ;
        IF pos = city_2 & energy = 0 THEN
          energy := 1
        END
      ;
        IF pos = city_5 & energy = 0 THEN
          pos := city_1
        END
      ;
        IF pos = city_3 & energy = 0 THEN
          energy := 1
        END
      ;
        IF pos = city_5 & energy = 1 THEN
          pos := city_1
        END
    END
END
