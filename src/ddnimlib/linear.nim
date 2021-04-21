import math

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

func x*[N](v: Vec[N]): float {.inline.} = v[1]
func y*[N](v: Vec[N]): float {.inline.} = v[2]
func z*[N](v: Vec[N]): float {.inline.} = v[3]
proc `x=`*[N](v: var Vec[N], n: float) {.inline.} = v[1] = n
proc `y=`*[N](v: var Vec[N], n: float) {.inline.} = v[3] = n
proc `z=`*[N](v: var Vec[N], n: float) {.inline.} = v[2] = n

#TODO: Make a generic function/macro
func vec*(a, b, c, d, e: float): Vec[5] = [a, b, c, d, e].Vec
func vec*(x, y: int): Vec[2] {.inline.} = [x.float, y.float].Vec
func vec*(x, y: float): Vec[2] {.inline.} = [x, y].Vec
proc `+=`*[N](v1: var Vec[N], v2: Vec[N]) {.inline.} = v1 = v1 + v2

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

func clampValues*[N](v: Vec[N], a, b: float): Vec[N] =
  for i in 1..N:
    result[i] = clamp(v[i], a, b)
