#[
A very barebones immediate mode UI library, mostly inspired by 
[Nuklear](https://github.com/Immediate-Mode-UI/Nuklear). Unlike any decent
IM UI library, this one only has one backend, the SDL renderer (with vague ideas
to switch to opengl at some point).

If this requires more features than I want to implement, probably best to
create bindings for Nuklear and use it directly.
]#

import options, strutils, tables
import sdl2, sdl2 / ttf
import linear, utils, drawing, text

type
  ID = string

  MouseButtonInput = object
    down: bool
    pos: Vec[2]
    
  Inputs = object
    mousePos: Vec[2]
    leftClick: Option[MouseButtonInput]

  RowLayout = ref object
    nextX, rowY, rowHeight, maxWidth: float
    itemMargin: Vec[2]

  Container = ref object
    parent: Option[Container]
    pos, size, padding: Vec[2]
    layout: Option[RowLayout]

  Context* = ref object
    focussed: ID
    active: ID
    inputs: Inputs
    container: Option[Container]
    containerOrig: Vec[2]
    renderer: RendererPtr
    textStore: TextStore

func newUIContext*(fontFilename: string): Context =
  new result
  result.textStore = newTextStore(openFont(fontFilename, 24))

func absOrig(ctx: Context): Vec[2] =
  result = vec(0, 0)
  var container = ctx.container
  while container.isSome:
    let c = container.get()
    result += c.pos + c.padding
    container = c.parent

proc containerDepth(ctx: Context): int = 1

proc id(ctx: Context, label: string): ID =
  result = ('>'.repeat(ctx.containerDepth()) & label).ID

proc isActive(ctx: Context, label: string): bool = ctx.active == ctx.id(label)
proc isFocussed(ctx: Context, label: string): bool = ctx.focussed == ctx.id(label)
proc setFocussed(ctx: Context, label: string) = ctx.focussed = ctx.id(label)
proc setActive(ctx: Context, label: string) = ctx.active = ctx.id(label)
  
proc setMousePos*(ctx: Context, pos: Vec[2]) = ctx.inputs.mousePos = pos
proc pressMouse*(ctx: Context, pos: Vec[2]) =
  ctx.inputs.leftClick = some(MouseButtonInput(down: true, pos: pos))
proc releaseMouse*(ctx: Context, pos: Vec[2]) =
  ctx.inputs.leftClick = some(MouseButtonInput(down: false, pos: pos))

func mouseUp(ctx: Context): bool =
  ctx.inputs.leftClick.isSome and not ctx.inputs.leftClick.get().down
func mouseUpIn(ctx: Context, r: Rect): bool =
  if ctx.inputs.leftClick.isNone: return false
  let click = ctx.inputs.leftClick.get()
  if click.down: return false
  result = r.contains(click.pos)
func mouseDownIn(ctx: Context, r: Rect): bool =
  if ctx.inputs.leftClick.isNone: return false
  let click = ctx.inputs.leftClick.get()
  if not click.down: return false
  result = r.contains(click.pos)

proc startInput*(ctx: Context) = ctx.inputs.leftClick = none(MouseButtonInput)
proc start*(ctx: Context, renderer: RendererPtr) =
  ctx.renderer = renderer
  ctx.container = none(Container)

func mouseIn(ctx: Context, r: Rect): bool =
  let p = ctx.inputs.mousePos
  result = r.contains(p)

proc startContainer*(ctx: Context,
                     pos: Vec[2],
                     size: Vec[2],
                     bg=none(TexturePtr),
                     padding=vec(5, 5)) =
  let parent = ctx.container
  ctx.container = some(
    Container(parent: parent, pos: pos, size: size, padding: padding))
  let porig = if parent.isSome: parent.get().pos + parent.get().padding
              else: vec(0, 0)
  ctx.containerOrig = porig + pos
  if bg.isSome:
    var dest = r(ctx.containerOrig, size)
    ctx.renderer.copy(bg.get(), nil, addr dest)

proc startContainer*(ctx: Context,
                     pos: Vec[2],
                     size: Vec[2],
                     bg: TexturePtr,
                     padding=vec(5, 5)) =
  ctx.startContainer(pos, size, some(bg), padding)

proc endContainer*(ctx: Context) =
  if ctx.container.isNone: return
  let c = ctx.container.get()
  ctx.container = c.parent
  ctx.containerOrig = if ctx.container.isSome:
    let p = ctx.container.get()
    p.pos + p.padding
  else: vec(0, 0)

proc startLayout*(ctx: Context, itemMargin=vec(3, 3)) =
  assert ctx.container.isSome, "Cannot start layout outside container"

  var container = ctx.container.get()
  container.layout = some(
    RowLayout(nextX: container.padding.x,
              rowY: container.padding.y,
              rowHeight: 0,
              maxWidth: container.size.x - 2 * container.padding.x,
              itemMargin: itemMargin))

proc endLayout*(ctx: Context) =
  assert ctx.container.isSome, "Cannot end layout outside container"
  ctx.container.get().layout = none(RowLayout)

proc elemDest(ctx: Context, relPos: Vec[2], size: Vec[2]): Rect =
  ## Absolute position if not in a container
  ## Relative to container origin if not in a layout
  ## Otherwise the next position in rows naively packed left->right, top->bot
  if ctx.container.isNone: return r(relPos, size)
  let container = ctx.container.get()
  if container.layout.isNone: return r(ctx.containerOrig + relPos, size)
  var layout = container.layout.get()

  # Start a new row if item would be too wide.
  if layout.nextX + size.x > layout.maxWidth:
    layout.nextX = container.padding.x
    layout.rowY += layout.rowHeight + layout.itemMargin.y
    layout.rowHeight = 0

  if size.y > layout.rowHeight: layout.rowHeight = size.y
  result = r(ctx.containerOrig + vec(layout.nextX, layout.rowY), size)
  layout.nextX += size.x + layout.itemMargin.x

proc doButtonIcon*(ctx: Context,
                   icon: var TextureRegion,
                   label: string,
                   size: Vec[2],
                   pos=vec(0, 0)): bool =
  result = false
  var dest = ctx.elemDest(pos, size)
  if ctx.isActive(label):
    if ctx.mouseUp():
      ctx.active = ""
      result = ctx.mouseUpIn(dest):
  elif ctx.isFocussed(label) and ctx.mouseDownIn(dest):
    ctx.setActive(label)

  if ctx.mouseIn(dest):
    var padded = dest.padded()
    ctx.setFocussed(label)
    ctx.renderer.setDrawColor(231, 255, 150)
    ctx.renderer.fillRect(padded)

  if ctx.isActive(label): discard icon.tex.setTextureColorMod(150, 150, 150)
  ctx.renderer.copy(icon, dest)
  discard icon.tex.setTextureColorMod(255, 255, 255)

proc doLabel*(ctx: Context,
              text: string,
              fg: Color,
              bg=none(Color),
              pos=vec(0, 0)) =
  var
    tw, th: cint
    tex = ctx.textStore.getTextTexture(ctx.renderer, text, fg, bg)
  discard tex.queryTexture(nil, nil, addr tw, addr th)
  var dest = ctx.elemDest(pos, vec(tw, th))
  ctx.renderer.copy(tex, nil, addr dest)
