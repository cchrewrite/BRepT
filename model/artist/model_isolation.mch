
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
        not(pos = city_1 & energy = 0)
      & not(pos = city_1 & energy = 1)
      & not(pos = city_1 & energy = 2)
      & not(pos = city_1 & energy = 3)
      & pos = city_1
    THEN
      energy := energy + 1
    END;
  
  move(city_x,city_y) = 
    PRE 
        city_x : City
      & city_y : City
      & not(pos = city_1 & energy = 3)
      & not(pos = city_2 & energy = 2)
      & not(pos = city_1 & energy = 2)
      & not(pos = city_2 & energy = 1)
      & not(pos = city_1 & energy = 1)
      & energy >= 1
      & pos = city_x
      & (city_x |-> city_y : connections or city_y |-> city_x : connections)
    THEN
        pos := city_y
      ;
        energy := energy - 1
    END
END
