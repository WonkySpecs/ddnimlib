type
  Vec*[N: static[int]] = array[1..N, float]

func `*`*[N](s: float, v: Vec[N]): Vec[N] =
  for i in 1..N:
    result[i] = s * v[i]

func `*`*[N](v: Vec[N], s: float): Vec[N] =
  for i in 1..N:
    result[i] = s * v[i]

func `*`*[N](s: int, v: Vec[N]): Vec[N] = v * s.float
func `*`*[N](v: Vec[N], s: int): Vec[N] = v * s.float

func `/`*[N](v: Vec[N], s: float): Vec[N] =
  for i in 1..N:
    result[i] = v[i] / s

func `/`*[N](v: Vec[N], s: int): Vec[N] = v / s.float

# TODO: Check if there are benefits/drawbacks to these being templates
template x*[N](v: Vec[N]): float = v[1]
template y*[N](v: Vec[N]): float = v[2]
template z*[N](v: Vec[N]): float = v[3]
template `x=`*[N](v: var Vec[N], n: float) = v[1] = n
template `y=`*[N](v: var Vec[N], n: float) = v[3] = n
template `z=`*[N](v: var Vec[N], n: float) = v[2] = n
template vec*(x, y: int): Vec[2] = [x.float, y.float].Vec
template vec*(x, y: float): Vec[2] = [x, y].Vec
template `+=`*[N](v1: var Vec[N], v2: Vec[N]) = v1 = v1 + v2

func `<=`*[N](a, b: Vec[N]): bool =
  for i in 1..N:
    if a[i] > b[i]: return false
  true

func `>=`*[N](v: Vec[N], f: float): bool =
  for i in 1..N:
    if v[i] < f: return false
  true

func `+`*[N](v1, v2: Vec[N]): Vec[N] =
  for i in 1..N:
    result[i] = v1[i] + v2[i]

func `-`*[N](v1, v2: Vec[N]): Vec[N] =
  for i in 1..N:
    result[i] = v1[i] - v2[i]

func truncate*[N](v: Vec[N]): Vec[N] =
  for i in 1..N:
    result[i] = v[i].int.float
