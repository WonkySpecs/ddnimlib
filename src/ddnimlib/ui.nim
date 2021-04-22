#[
A very barebones immediate mode UI library, mostly inspired by
[Nuklear](https://github.com/Immediate-Mode-UI/Nuklear). Unlike any decent
IM UI library, this one only has one backend, the SDL renderer (with vague ideas
to switch to opengl at some point).

If this requires more features than I want to implement, probably best to
create bindings for Nuklear and use it directly.
]#

import options, strutils, tables, sugar
import sdl2, sdl2 / ttf
import linear, utils, drawing, text, colors

type
  Interaction* = enum
    None, Clicked, Hovered

  ID = string

  MouseButtonInput = object
    down: bool
    pos: Vec[2]

  Inputs = object
    mousePos: Vec[2]
    leftClick: Option[MouseButtonInput]

  RowLayout = ref object
    nextX, rowY, rowHeight, maxWidth, minItemWidth, width: float
    itemMargin: Vec[2]

  Container = ref object
    parent: Option[Container]
    pos, padding: Vec[2]
    size: Option[Vec[2]]
    layout: Option[RowLayout]
    bg: TextureRegion
    renderQueue: seq[tuple[tr: TextureRegion, dest: Rect, col: Option[Color]]]

  Context* = ref object
    hot: ID
    active: ID
    inputs: Inputs
    container: Option[Container]
    containerOrig: Vec[2]
    renderer: RendererPtr
    fontName: string
    textStores: Table[int, TextStore]
    hasInputFocus*: bool

func newUIContext*(fontFilename: string): Context =
  new result
  result.fontName = fontFilename

proc font(ctx: var Context, size: int): TextStore =
  if not ctx.textStores.hasKey(size):
    ctx.textStores[size] = newTextStore(openFont(ctx.fontName, size.cint))
  result = ctx.textStores[size]

proc containerDepth(ctx: Context): int = 1

proc id(ctx: Context, label: string): ID =
  result = ('>'.repeat(ctx.containerDepth()) & label).ID

proc isActive(ctx: Context, label: string): bool = ctx.active == ctx.id(label)
proc isHot(ctx: Context, label: string): bool = ctx.hot == ctx.id(label)
proc setHot(ctx: Context, label: string) = ctx.hot = ctx.id(label)
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

proc draw(ctx: Context, tr: var TextureRegion, dest: var Rect, col=none(Color)) =
  if ctx.container.isSome:
    ctx.container.get().renderQueue.add (tr, dest, col)
  else:
    if col.isSome: tr.setColorMod(col.get())
    ctx.renderer.copy(tr, dest)
    if col.isSome: tr.setColorMod(white)

proc startInput*(ctx: Context) = ctx.inputs.leftClick = none(MouseButtonInput)
proc start*(ctx: Context, renderer: RendererPtr) =
  ctx.renderer = renderer
  ctx.container = none(Container)
  ctx.hasInputFocus = false

func mouseIn(ctx: Context, r: Rect): bool =
  let p = ctx.inputs.mousePos
  result = r.contains(p)

func calcContainerSize(ctx: Context): Vec[2] =
  let layoutOpt = ctx.container.map(c => c.layout).flatten
  assert layoutOpt.isSome, "Cannot calc size for container without layout"
  let l = layoutOpt.get()
  vec(10, 100)

proc startContainer*(ctx: Context,
                     pos: Vec[2],
                     bg: var TextureRegion,
                     size=none(Vec[2]),
                     padding=vec(5, 5)) =
  let parent = ctx.container
  ctx.container = some(
    Container(parent: parent, pos: pos, size: size, padding: padding, bg: bg))
  let porig = if parent.isSome: parent.get().pos + parent.get().padding
              else: vec(0, 0)
  ctx.containerOrig = porig + pos

proc startContainer*(ctx: Context,
                     pos: Vec[2],
                     bg: var TextureRegion,
                     size: Vec[2],
                     padding=vec(5, 5)) =
  ctx.startContainer(pos, bg, some(size), padding)

proc endContainer*(ctx: Context) =
  if ctx.container.isNone:
    echo "DEBUG: endContainer called with no container"
    return

  let
    c = ctx.container.get()
    size = if c.size.isSome: c.size.get()
           else: ctx.calcContainerSize()

  var dest = r(c.pos, size)
  ctx.renderer.copy(c.bg, dest)

  if ctx.mouseIn(dest): ctx.hasInputFocus = true

  ctx.container = c.parent
  if ctx.container.isSome:
    let p = ctx.container.get()
    ctx.containerOrig = p.pos + p.padding
  else:
    ctx.containerOrig = vec(0, 0)

  for (tr, dest, col) in c.renderQueue.mitems:
    if col.isSome: tr.setColorMod(col.get())
    ctx.renderer.copy(tr, dest)
    if col.isSome: tr.setColorMod(white)

proc startLayout*(ctx: Context, itemMargin=vec(3, 3), minItemWidth=0.0) =
  assert ctx.container.isSome, "Cannot start layout outside container"

  var container = ctx.container.get()
  let maxWidth = if container.size.isSome:
    let s = container.size.get()
    s.x - 2 * container.padding.x
  else: 9999
  container.layout = some(
    RowLayout(nextX: container.padding.x,
              rowY: container.padding.y,
              maxWidth: maxWidth,
              itemMargin: itemMargin,
              minItemWidth: minItemWidth))

proc layoutNewRow(container: Container) =
  assert container.layout.isSome, "Cannot start new row without layout"
  let layout = container.layout.get()
  layout.nextX = container.padding.x
  layout.rowY += layout.rowHeight + layout.itemMargin.y
  layout.rowHeight = 0

proc layoutNewRow*(ctx: Context) = ctx.container.get().layoutNewRow()

proc endLayout*(ctx: Context) =
  assert ctx.container.isSome, "Cannot end layout outside container"
  var
    c = ctx.container.get()
    l = c.layout.get()
  if c.size.isNone:
    c.size = some(vec(l.width, l.rowY + l.rowHeight))
  c.layout = none(RowLayout)

proc elemDest(ctx: Context, relPos: Vec[2], size: Vec[2]): Rect =
  ## Absolute position if not in a container
  ## Relative to container origin if not in a layout
  ## Otherwise the next position in rows naively packed left->right, top->bot
  if ctx.container.isNone: return r(relPos, size)
  let container = ctx.container.get()
  if container.layout.isNone: return r(ctx.containerOrig + relPos, size)
  var layout = container.layout.get()

  let x = layout.nextX + max(size.x, layout.minItemWidth)
  # Start a new row if item would be too wide.
  if x > layout.maxWidth:
    container.layoutNewRow()

  if size.y > layout.rowHeight: layout.rowHeight = size.y
  result = r(ctx.containerOrig + vec(layout.nextX, layout.rowY), size)
  layout.nextX = x + layout.itemMargin.x
  layout.width = max(layout.width, layout.nextX)

proc doButtonIcon*(ctx: Context,
                   icon: var TextureRegion,
                   label: string,
                   size: Vec[2],
                   pos=vec(0, 0)): Interaction =
  result = None
  var dest = ctx.elemDest(pos, size)
  if ctx.isActive(label):
    if ctx.mouseUp():
      ctx.active = ""
      result = Clicked
  elif ctx.isHot(label) and ctx.mouseDownIn(dest):
    ctx.setActive(label)

  if ctx.mouseIn(dest):
    var bg = dest.padded()
    ctx.renderer.setDrawColor(231, 255, 150)
    ctx.renderer.fillRect(bg)

    ctx.setHot(label)
    if result == None: result = Hovered

  let col = if ctx.isActive(label): some(color(150, 150, 150, 255))
            else: none(Color)
  ctx.draw(icon, dest, col)

proc doLabel*(ctx: var Context,
              text: string,
              fg: Color,
              size=24,
              bg=none(Color),
              pos=vec(0, 0)) =
  var
    tw, th: cint
    font = ctx.font(size)
    tex = font.getTextTexture(ctx.renderer, text, fg, bg)
  discard tex.queryTexture(nil, nil, addr tw, addr th)
  var
    dest = ctx.elemDest(pos, vec(tw, th))
    tr = texRegion(tex)
  ctx.draw(tr, dest)
