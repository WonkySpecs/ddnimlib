from sdl2 import Rect, rect
import linear

template r*(x, y, w, h: int): Rect =
  rect(x.cint, y.cint, w.cint, h.cint)

template r*(pos: Vector[2], size: Vector[2]): Rect =
  rect(pos.x.cint, pos.y.cint, size.x.cint, size.y.cint)
