#[
A very barebones immediate mode UI library, mostly inspired by 
[Nuklear](https://github.com/Immediate-Mode-UI/Nuklear). Unlike any decent
IM UI library, this one only has one backend, the SDL renderer (with vague ideas
to switch to opengl at some point).

If this requires more features than I want to implement, probably best to
create bindings for Nuklear and use it directly.
]#

import options, strutils
import sdl2
import linear, utils

type
  ID = string

  MouseButtonInput = object
    down: bool
    pos: Vec[2]
    
  Inputs = object
    mousePos: Vec[2]
    leftClick: Option[MouseButtonInput]

  Container = ref object
    parent: Option[Container]
    pos: Vec[2]
    size: Vec[2]
    padding: Vec[2]

  Context* = ref object
    focussed: ID
    active: ID
    inputs: Inputs
    container: Option[Container]
    containerOrig: Vec[2]
    renderer: RendererPtr

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

proc doButtonIcon*(ctx: Context,
                   icon: TexturePtr,
                   label: string,
                   pos: Vec[2],
                   size: Vec[2]): bool =
  result = false
  var dest = r(ctx.containerOrig + pos, size)
  if ctx.isActive(label):
    if ctx.mouseUpIn(dest):
      result = true
      ctx.active = ""
  elif ctx.isFocussed(label) and ctx.mouseDownIn(dest):
    ctx.setActive(label)

  if ctx.mouseIn(dest):
    ctx.setFocussed(label)

  ctx.renderer.copy(icon, nil, addr dest)
