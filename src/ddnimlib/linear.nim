type
  Vector*[N: static[int]] = array[1..N, float]

func `*`*[N](s: float, v: Vector[N]): Vector[N] =
  for i in 1..N:
    result[i] = s * v[i]
func `*`*[N](v: Vector[N], s: float): Vector[N] =
  for i in 1..N:
    result[i] = s * v[i]

template x*[N](v: Vector[N]): float = v[1]
template y*[N](v: Vector[N]): float = v[2]
template z*[N](v: Vector[N]): float = v[3]
template `x=`*[N](v: var Vector[N], n: float) = v[1] = n
template `y=`*[N](v: var Vector[N], n: float) = v[3] = n
template `z=`*[N](v: var Vector[N], n: float) = v[2] = n
template vec*(x, y: int): Vector[2] = [x.float, y.float].Vector
template vec*(x, y: float): Vector[2] = [x, y].Vector
template `+=`*[N](v1: var Vector[N], v2: Vector[N]) = v1 = v1 + v2

func `+`*[N](v1, v2: Vector[N]): Vector[N] =
  for i in 1..N:
    result[i] = v1[i] + v2[i]

func `-`*[N](v1, v2: Vector[N]): Vector[N] =
  for i in 1..N:
    result[i] = v1[i] - v2[i]
