import options
import sdl2
import linear, utils

type
  Camera* = object
    vw, vh: int
    pos*: Vec[2]
    rot*, zoom*: float

  View* = object
    renderer*: RendererPtr
    cam*: Camera
    target: TexturePtr

func initCamera(vw, vh: int): Camera =
  result.vw = vw
  result.vh = vh
  result.pos = vec(0, 0)
  result.rot = 0
  result.zoom = 1.0

proc initView*(renderer: RendererPtr, vw, vh: int) : View =
  result.renderer = renderer
  result.cam = initCamera(vw, vh)
  result.target = renderer.createTexture(SDL_PIXELFORMAT_RGBA8888,
                                         SDL_TEXTUREACCESS_TARGET,
                                         vw.cint, vh.cint)

func toScreen(worldPos: Vec[2], c: Camera): Vec[2] =
  (c.zoom * (worldPos - c.pos)) + vec(c.vw / 2, c.vh / 2)

func toWorld*(screenPos: Vec[2], c: Camera): Vec[2] =
  (screenPos - vec(c.vw / 2, c.vh / 2)) / c.zoom + c.pos

template toScreenRect(worldPos: Vec[2],
                      worldSize: Vec[2],
                      cam: Camera): Rect =
  let
    screenPos = pos.toScreen(cam)
    screenSize = vec(w, h) * cam.zoom
  r(screenPos, screenSize)

proc start*(view: View) =
  view.renderer.setRenderTarget(view.target)
  view.renderer.setDrawColor(r=0, g=0, b=0)
  view.renderer.clear()

proc render*(view: View,
             tex: TexturePtr,
             pos: Vec[2],
             w, h: int,
             rot = 0.0) =
  var dest = toScreenRect(pos, vec(w, h), view.cam)
  view.renderer.copyEx(tex, nil, addr dest, rot, nil)

proc renderRect*(view: View,
                 tex: TexturePtr,
                 src: var Rect,
                 pos: Vec[2],
                 w, h: int,
                 rot = 0.0) =
  var dest = toScreenRect(pos, vec(w, h), view.cam)
  view.renderer.copyEx(tex, addr src, addr dest, rot, nil)

proc render*(view: View,
             tex: TexturePtr,
             src: var Option[Rect],
             pos: Vec[2],
             w, h: int,
             rot = 0.0) =
  if src.isSome:
    renderRect(view, tex, src.get(), pos, w, h, rot)
  else:
    render(view, tex, pos, w, h, rot)

proc finish*(view: View) =
  view.renderer.setRenderTarget(nil);
  view.renderer.setDrawColor(r=0, g=0, b=0)
  view.renderer.clear()
  view.renderer.copyEx(view.target,
                       srcrect=nil, dstrect=nil,
                       view.cam.rot,
                       center=nil, SDL_FLIP_NONE)

proc copy*(renderer: RendererPtr, tex: TexturePtr, src: var Option[Rect], dest: var Rect) =
  if src.isSome:
    renderer.copy(tex, addr src.get(), addr dest)
  else:
    renderer.copy(tex, nil, addr dest)