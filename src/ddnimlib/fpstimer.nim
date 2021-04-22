from sdl2 import getTicks

const maxSize = 50

type
  FPSTimer* = object
    times: array[maxSize, uint]
    next: int

proc tick*(timer: var FPSTimer) =
  timer.times[timer.next] = getTicks().uint
  timer.next = (timer.next + 1) mod maxSize

func fps*(timer: FPSTimer): float =
  let
    last = timer.times[(timer.next + (maxSize - 1)) mod maxSize]
    first = timer.times[timer.next]
    diff = last - first
    avg = diff.int / maxSize
  1000 / avg
