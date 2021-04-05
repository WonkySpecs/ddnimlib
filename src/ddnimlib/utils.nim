from sdl2 import Rect, rect
import linear

template r*(x, y, w, h: int): Rect =
  rect(x.cint, y.cint, w.cint, h.cint)

template r*(pos: Vec[2], size: Vec[2]): Rect =
  rect(pos.x.cint, pos.y.cint, size.x.cint, size.y.cint)

func pos*(r: Rect): Vec[2] = vec(r[0].int, r[1].int)
func size*(r: Rect): Vec[2] = vec(r[2].int, r[3].int)
