from sdl2 import Rect, rect, getMouseState
import linear

template r*(x, y, w, h: int): Rect =
  rect(x.cint, y.cint, w.cint, h.cint)

template r*(pos: Vec[2], size: Vec[2]): Rect =
  rect(pos.x.cint, pos.y.cint, size.x.cint, size.y.cint)

func pos*(r: Rect): Vec[2] = vec(r[0].int, r[1].int)
func size*(r: Rect): Vec[2] = vec(r[2].int, r[3].int)

func right(r: Rect): float = (r.x + r.w).float
func bot(r: Rect): float = (r.y + r.h).float

func contains*(r: Rect, p: Vec[2]): bool =
  p.x.cint >= r.x and p.x <= r.right and p.y.cint >= r.y and p.y <= r.bot

func getMousePos*(): Vec[2] =
  var mx, my: cint
  discard getMouseState(addr mx, addr my)
  result = vec(mx, my)
