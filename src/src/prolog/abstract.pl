

% Read a,b,c. Compute: If a > b, then res = (a - b) * c, otherwise res = (b - a) * c. res2 = res * res.
abstract_program_try(P):-
  P = [
    constant([read1,read2,read3]),
    variable([a,b,c,res]),
    evaluation([
      [assign,a(0),none,[]],
      [assign,b(0),none,[]],
      [assign,c(0),none,[]],
      [assign,res(0),none,[]],
      [assign,res2(0),none,[]],
      [assign,a(1),read1,[]],
      [assign,b(1),read2,[]],
      [assign,c(1),read3,[]],
      [assign,res(1),[[a(1),-,b(1)],*,c(1)],[[a(1),>,b(1)]]],
      [assign,res2(1),[res(1),*,res(1)],[[a(1),>,b(1)]]],
      [check,res(1),check_point_1,[[a(1),>,b(1)]]],
      [assign,res(2),[[b(1),-,a(1)],*,c(1)],[[lnot,[a(1),>,b(1)]]]],
      [assign,res2(2),[res(2),*,res(2)],[[lnot,[a(1),>,b(1)]]]],
      [check,res(2),check_point_1,[[lnot,[a(1),>,b(1)]]]]
    ])
  ].

% Read a,b,c. Compute a * c + b * c.
abstract_program_try_2(P):-
  P = [
    constant([read1,read2,read3]),
    variable([a,b,c,res]),
    abstract([
      [assign,a(0),none],
      [assign,b(0),none],
      [assign,c(0),none],
      [assign,res(0),none],
      [assign,a(1),read1],
      [assign,b(1),read2],
      [assign,c(1),read3],
      [assign,res(1),[[a(1),+,b(1)],*,c(1)]],
      [check,res(2),check_point_1]
    ])
  ].

