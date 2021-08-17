import options, hashes
from sdl2 import Rect, rect, getMouseState, Color, TexturePtr, queryTexture
import linear

func r*(x, y, w, h: int): Rect {.inline.} =
  rect(x.cint, y.cint, w.cint, h.cint)

func r*(pos: Vec[2], size: Vec[2]): Rect {.inline.} =
  rect(pos.x.cint, pos.y.cint, size.x.cint, size.y.cint)

func pos*(r: Rect): Vec[2] = vec(r[0].int, r[1].int)
func size*(r: Rect): Vec[2] = vec(r[2].int, r[3].int)

func right(r: Rect): float = (r.x + r.w).float
func bot(r: Rect): float = (r.y + r.h).float

func contains*(r: Rect, p: Vec[2]): bool {.inline} =
  p.x.cint >= r.x and p.x <= r.right and p.y.cint >= r.y and p.y <= r.bot

func getMousePos*(): Vec[2] =
  var mx, my: cint
  discard getMouseState(addr mx, addr my)
  result = vec(mx, my)

func padded*(r: Rect, pad=1): Rect {.inline} =
  r(r.x - pad, r.y - pad, r.w + 2 * pad, r.h + 2 * pad)

func center*(r: Rect): Vec[2] {.inline} =
  vec(r.x.float + r.w / 2, r.y.float + r.h / 2)

func c*(r, g, b: range[0..255]): Color =
  (r.uint8, g.uint8, b.uint8, 255.uint8)

proc hash*(opt: Option): Hash =
  var h: Hash = 0
  if opt.isSome:
    h = hash(opt.get())

func getSize*(tex: TexturePtr): Vec[2] =
  var tw, th: cint
  tex.queryTexture(nil, nil, addr tw, addr th)
  vec(tw.int, th.int)
