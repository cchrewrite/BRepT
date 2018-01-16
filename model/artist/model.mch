MACHINE
  TravellingArtist
SETS
  City = {city_1, city_2, city_3, city_4, city_5}
CONSTANTS
  max_energy,
  connections

PROPERTIES
  max_energy = 3 &
  connections = {(city_1, city_2),(city_2, city_3),(city_1, city_4),(city_2, city_5)}
 
VARIABLES
  pos,energy
INVARIANT
  pos : City &
  energy : 0..max_energy
ASSERTIONS
  not(pos = city_5)


INITIALISATION
  pos := city_1 ;
  energy := 0

OPERATIONS
  eat =
    PRE
      pos = city_1
    THEN
      energy := energy + 1
    END ;

  move(city_x,city_y) =
    PRE
      energy >= 1 &
      pos = city_x &
      city_x : City &
      city_y : City &
      (((city_x, city_y) : connections) or ((city_y, city_x) : connections))

      
    THEN
      pos := city_y ;
      energy := energy - 1
    END

END

