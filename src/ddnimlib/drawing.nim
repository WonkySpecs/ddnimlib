import sdl2
import linear, utils

type
  Camera* = object
    vw, vh: int
    pos*: Vec[2]
    rot*, zoom*: float

  RenderBatch* = object
    renderer*: RendererPtr
    cam*: Camera
    frameTarget: TexturePtr

func initCamera(vw, vh: int): Camera =
  result.vw = vw
  result.vh = vh
  result.pos = vec(0, 0)
  result.rot = 0
  result.zoom = 1.0

proc initBatch*(renderer: RendererPtr, vw, vh: int) : RenderBatch =
  result.renderer = renderer
  result.cam = initCamera(vw, vw)
  result.frameTarget = renderer.createTexture(SDL_PIXELFORMAT_RGBA8888,
                                               SDL_TEXTUREACCESS_TARGET,
                                               vw.cint, vh.cint)

func toScreen(worldPos: Vec[2], c: Camera): Vec[2] =
  (c.zoom * (worldPos - c.pos)) + vec(c.vw / 2, c.vh / 2)

func toWorld*(screenPos: Vec[2], c: Camera): Vec[2] =
  (screenPos - vec(c.vw / 2, c.vh / 2)) / c.zoom + c.pos

proc start*(batch: RenderBatch) =
  batch.renderer.setRenderTarget(batch.frameTarget)
  batch.renderer.setDrawColor(r=50, g=50, b=50)
  batch.renderer.clear()

template toScreenRect(worldPos: Vec[2],
                      worldSize: Vec[2],
                      cam: Camera): Rect =
  let
    screenPos = pos.toScreen(cam)
    screenSize = vec(w, h) * cam.zoom
  r(screenPos, screenSize)

proc render*(batch: RenderBatch,
             tex: TexturePtr,
             pos: Vec[2],
             w, h: int,
             rot = 0.0) =
  var dest = toScreenRect(pos, vec(w, h), batch.cam)
  batch.renderer.copyEx(tex, nil, addr dest, rot, nil)

proc renderRect*(batch: RenderBatch,
                 tex: TexturePtr,
                 src: var Rect,
                 pos: Vec[2],
                 w, h: int,
                 rot = 0.0) =
  var dest = toScreenRect(pos, vec(w, h), batch.cam)
  batch.renderer.copyEx(tex, addr src, addr dest, rot, nil)

proc finish*(batch: RenderBatch) =
  batch.renderer.setRenderTarget(nil);
  batch.renderer.setDrawColor(r=0, g=0, b=0)
  batch.renderer.clear()
  batch.renderer.copyEx(batch.frameTarget,
                        srcrect=nil, dstrect=nil,
                        batch.cam.rot,
                        center=nil, SDL_FLIP_NONE)
