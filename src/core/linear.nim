type
  Matrix*[W, H: static[int]] = array[1..H, array[1..W, float]]

  Vector*[N: static[int]] = array[1..N, float]

func `*`*[N](s: float, v: Vector[N]): Vector[N] =
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

func ident33*(): Matrix[3, 3] =
  Matrix[3, 3]([[1.0, 0.0, 0.0],
   [0.0, 1.0, 0.0],
   [0.0, 0.0, 1.0]])

# Some (probably very inefficient) matrix ops
func `*`*[N: static[int]](m1, m2: Matrix[N, N]): Matrix[N, N] =
  for i in 1..N:
    for j in 1..N:
      for n in 1..N:
        result[i][j] += m1[j][n] * m2[n][i]

func `*`*[W, H: static[int]](n: float, m: Matrix[W, H]): Matrix[W, H] =
  for j in 1..H:
    for i in 1..W:
      result[i][j] = m[i][j] * n
