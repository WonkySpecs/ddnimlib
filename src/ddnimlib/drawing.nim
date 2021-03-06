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

  TextureRegion* = object
    tex*: TexturePtr
    region: Option[Rect]

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

func toScreenRect(worldPos: Vec[2],
                  worldSize: Vec[2],
                  cam: Camera): Rect {.inline.} =
  let
    screenPos = worldPos.toScreen(cam)
    screenSize = worldSize * cam.zoom
  r(screenPos, screenSize)

proc start*(view: View) =
  view.renderer.setRenderTarget(view.target)
  view.renderer.setDrawColor(r=0, g=0, b=0)
  view.renderer.clear()

proc finish*(view: View) =
  view.renderer.setRenderTarget(nil);
  view.renderer.setDrawColor(r=0, g=0, b=0)
  view.renderer.clear()
  view.renderer.copyEx(view.target,
                       srcrect=nil, dstrect=nil,
                       view.cam.rot,
                       center=nil, SDL_FLIP_NONE)

proc setAlphaMod*(tr: TextureRegion, a: uint8) = tr.tex.setTextureAlphaMod(a)
proc setColorMod*(tr: TextureRegion, r, g, b: uint8) =
  discard tr.tex.setTextureColorMod(r, g, b)
proc setColorMod*(tr: TextureRegion, r, g, b: int) =
  discard tr.tex.setTextureColorMod(r.uint8, g.uint8, b.uint8)
proc setColorMod*(tr: TextureRegion, c: Color) =
  discard tr.tex.setTextureColorMod(c.r, c.g, c.b)

func texRegion*(tex: TexturePtr, region=none(Rect)): TextureRegion =
  TextureRegion(tex: tex, region: region)

proc drawRect*(view: View, pos, size: Vec[2]) =
  var dest = toScreenRect(pos, size, view.cam)
  view.renderer.drawRect(dest)

proc render*(view: View,
             tex: TexturePtr,
             src: var Rect,
             pos: Vec[2],
             size: Vec[2],
             rot = 0.0) =
  var dest = toScreenRect(pos, size, view.cam)
  view.renderer.copyEx(tex, addr src, addr dest, rot, nil)

proc renderAbs*(view: View,
                tr: var TextureRegion,
                pos: Vec[2],
                size: Vec[2],
                rot = 0.0) =
  var dest = r(pos, size)
  if tr.region.isSome:
    var src = tr.region.get()
    view.renderer.copyEx(tr.tex, addr src, addr dest, rot, nil)
  else:
    view.renderer.copyEx(tr.tex, nil, addr dest, rot, nil)

proc copy*(renderer: RendererPtr, tr: var TextureRegion, dest: var Rect) =
  if tr.region.isSome:
    var src = tr.region.get()
    renderer.copy(tr.tex, addr src, addr dest)
  else:
    renderer.copy(tr.tex, nil, addr dest)

proc render*(view: View,
             tr: var TextureRegion,
             pos: Vec[2],
             size: Vec[2],
             rot = 0.0) =
  var dest = toScreenRect(pos, size, view.cam)
  view.renderer.copy(tr, dest)

func getSize*(tr: TextureRegion): Vec[2] =
  if tr.region.isSome:
    tr.region.get().size()
  else:
    tr.tex.getSize()
