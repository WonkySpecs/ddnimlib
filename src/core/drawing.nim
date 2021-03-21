import sdl2
import linear

export linear

type
  Camera* = object
    vw, vh: int
    pos*: Vector[2]
    zoom*: float

  RenderBatch* = object
    renderer*: RendererPtr
    cam*: Camera

func initCamera*(vw, vh: int): Camera =
  result.vw = vw
  result.vh = vh
  result.pos = vec(0, 0)
  result.zoom = 1.0

func toScreen(c: Camera, worldPos: Vector[2]): Vector[2] =
  (c.zoom * (worldPos - c.pos)) + vec(c.vw / 2, c.vh / 2)

proc begin*(batch: RenderBatch) =
  batch.renderer.setDrawColor(r = 50, g = 50, b = 50)
  batch.renderer.clear()

proc render*(batch: RenderBatch,
             tex: TexturePtr,
             pos: Vector[2],
             w, h: int,
             rot = 0.0) =
  let sv = batch.cam.toScreen(pos)
  var dest = rect(sv.x.cint,
                  sv.y.cint,
                  (w.float * batch.cam.zoom).cint,
                  (h.float * batch.cam.zoom).cint)
  batch.renderer.copyEx(tex, nil, addr dest, rot, nil)

proc renderRect*(batch: RenderBatch,
                 tex: TexturePtr,
                 src: var Rect,
                 pos: Vector[2],
                 w, h: int,
                 rot = 0.0) =
  let sv = batch.cam.toScreen(pos)
  var dest = rect(sv.x.cint,
                  sv.y.cint,
                  (w.float * batch.cam.zoom).cint,
                  (h.float * batch.cam.zoom).cint)
  batch.renderer.copyEx(tex, addr src, addr dest, rot, nil)
