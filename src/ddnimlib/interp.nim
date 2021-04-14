import math
from sdl2 import Color

func lerp*(c1, c2: Color, amount: range[0.0..1.0]): Color =
  Color(((c1.r.float * (1 - amount) + amount * c2.r.float).uint8,
         (c1.g.float * (1 - amount) + amount * c2.g.float).uint8,
         (c1.b.float * (1 - amount) + amount * c2.b.float).uint8,
         (c1.a.float * (1 - amount) + amount * c2.a.float).uint8))
