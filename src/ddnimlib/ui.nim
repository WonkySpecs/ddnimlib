import options, sugar, sequtils
import sdl2
import linear, text, utils

type
  ElementKind* = enum
    Container, Label, Button

  UIElement* = ref object
    tex: Option[TexturePtr] ## NOT optional for buttons and labels
    size*: Vec[2] ## The size to render at. Should be set from the source texture size
    hidden: bool
    case kind*: ElementKind
    of Label: bg: Option[TexturePtr]
    of Button: actions: seq[proc(){.closure.}]
    of Container:
      children: seq[tuple[elem: UIElement, pos: Vec[2]]]
      ## Layout properties used to set child positions when calling `alignLeft`
      padding: Vec[2] ## Internal padding
      childMargin: Vec[2] ## Margin between child elements

proc alignLeft*(container: var UIElement) =
  assert container.kind == Container
  ## Packs child elements linearly left to right, top to bottom.
  ## If elements don't fit they will overflow off the bottom.
  let internalSize = container.size - container.padding * 2
  var
    rowHeight = 0.0
    x = container.padding.x
    y = container.padding.y

  for i in 0..container.children.high:
    let size = container.children[i].elem.size + container.childMargin * 2
    if x + size.x > internalSize.x:
      rowHeight = 0
      x = container.padding.x
      y = y + rowHeight + container.padding.y
    if size.y > rowHeight: rowHeight = size.y
    container.children[i].pos = vec(x, y)
    x += size.x

proc initContainer*(size: Vec[2],
                    children: seq[UIElement],
                    bg=none(TexturePtr),
                    padding=vec(5, 5),
                    childMargin=vec(2, 2),
                    hidden=false): UIElement =
  new result
  result.size = size
  result.children = children.map(c => (c, vec(0, 0)))
  result.tex = bg
  result.padding = padding
  result.childMargin = childMargin
  result.hidden = false
  alignLeft(result)

func createButtons*(icons: seq[TexturePtr],
                    callbacks: seq[proc(){.closure.}],
                    size: Vec[2]): seq[UIElement] =
  assert icons.len == callbacks.len
  result = collect(newSeq):
    for (i, c) in zip(icons, callbacks):
      UIElement(kind: Button, tex: some(i), actions: @[c], size: size)

proc click*(container: UIElement, pos: Vec[2]): Option[UIElement] =
  assert container.kind == Container
  for (c, childPos) in container.children:
    case c.kind:
    of Button:
      let relPos = pos - childPos
      if relPos >= 0 and relPos <= c.size: return some(c)
    else: discard #TODO: Handle nested container clicks

proc onClick*(btn: UIElement) =
  assert btn.kind == Button
  for f in btn.actions:
    f()

proc draw*(renderer: RendererPtr,
           container: UIElement,
           pos: Vec[2],
           textStore: TextStore) =
  assert container.kind == Container
  if container.hidden: return
  var dest = r(pos, container.size)
  if container.tex.isSome:
    discard renderer.copy(container.tex.get(), nil, addr dest)

  for (c, relPos) in container.children:
    if c.hidden: continue
    case c.kind:
    of Container:
      renderer.draw(c, pos + relPos, textStore)
    of Label:
      dest = r((pos + relPos), c.size)
      if c.bg.isSome:
        discard renderer.copy(c.bg.get(), nil, addr dest)
      discard renderer.copy(c.tex.get(), nil, addr dest)
    of Button:
      dest = r((pos + relPos), c.size)
      discard renderer.copy(c.tex.get(), nil, addr dest)
