import sdl2
import linear

export linear

type
  Camera* = object
    vw, vh: int
    x*, y*, zoom*: float

  RenderBatch* = object
    renderer*: RendererPtr
    cam*: Camera

func initCamera*(vw, vh: int): Camera =
  result.vw = vw
  result.vh = vh
  result.x = vw / 2
  result.y = vh / 2
  result.zoom = 1.0

func toScreen(c: Camera, x, y: float): Vector[2] =
  (c.zoom * (([x, y].Vector) - ([c.x, c.y].Vector))) + [c.vw / 2, c.vh / 2].Vector

proc begin*(batch: RenderBatch) =
  batch.renderer.setDrawColor(r = 50, g = 50, b = 50)
  batch.renderer.clear()

proc render*(batch: RenderBatch,
             tex: TexturePtr,
             x, y: float,
             w, h: int,
             rot = 0.0) =
  let sv = batch.cam.toScreen(x, y)
  var dest = rect(sv.x.cint,
                  sv.y.cint,
                  (w.float * batch.cam.zoom).cint,
                  (h.float * batch.cam.zoom).cint)
  batch.renderer.copyEx(tex, nil, addr dest, rot, nil)

proc renderRect*(batch: RenderBatch,
                 tex: TexturePtr,
                 src: var Rect,
                 x, y: float,
                 w, h: int,
                 rot = 0.0) =
  let sv = batch.cam.toScreen(x, y)
  var dest = rect(sv.x.cint,
                  sv.y.cint,
                  (w.float * batch.cam.zoom).cint,
                  (h.float * batch.cam.zoom).cint)
  batch.renderer.copyEx(tex, addr src, addr dest, rot, nil)
