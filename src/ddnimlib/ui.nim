import options, sugar, sequtils
import sdl2
import linear, text, utils

type
  UIElement* = ref object of RootObj
    tex: Option[TexturePtr] ## NOT optional for buttons and labels
    size: Vec[2] ## The size to render at. Should be set from the source texture size
    hidden: bool

  Label = ref object of UIElement
    bg: Option[TexturePtr]

  Button* = ref object of UIElement
    actions: seq[proc(){.closure.}]

  Container* = ref object of UIElement
    children: seq[tuple[elem: UIElement, pos: Vec[2]]]

    ## Layout properties used to set child positions when calling `alignLeft`
    padding: Vec[2] ## Internal padding
    childMargin: Vec[2] ## Margin between child elements

proc alignLeft*(container: var Container) =
  ## Packs child elements linearly left to right, top to bottom.
  ## If elements don't fit they will overflow off the bottom.
  let internalSize = container.size - container.padding * 2
  var
    rowHeight = 0.0
    x = container.padding.x
    y = container.padding.y

  for i in 0..container.children.high:
    let size = container.children[i].elem.size + container.childMargin * 2
    if size.x + x > container.size.x:
      rowHeight = 0
      x = container.padding.x
      y = y + rowHeight + container.padding.y
    if size.y > rowHeight: rowHeight = size.y
    container.children[i].pos = vec(x, y)

func initContainer*(size: Vec[2],
                    children: seq[UIElement],
                    bg=none(TexturePtr),
                    padding=vec(5, 5),
                    childMargin=vec(2, 2),
                    hidden=false): Container =
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
                    size: Vec[2]): seq[Button] =
  assert icons.len == callbacks.len
  result = collect(newSeq):
    for (i, c) in zip(icons, callbacks):
      Button(tex: some(i), actions: @[c], size: size)

proc click*(btn: Button) =
  for f in btn.actions:
    f()

proc draw(renderer: RendererPtr,
          btn: Button,
          dest: var Rect) =
  discard renderer.copy(btn.tex.get(), nil, addr dest)

proc draw(renderer: RendererPtr,
          label: Label,
          dest: var Rect,
          textStore: TextStore) =
  if label.bg.isSome:
    discard renderer.copy(label.bg.get(), nil, addr dest)
  discard renderer.copy(label.tex.get(), nil, addr dest)

proc draw*(renderer: RendererPtr,
           container: Container,
           pos: Vec[2],
           textStore: TextStore) =
  if container.hidden: return
  var dest = r(pos, container.size)
  if container.tex.isSome:
    discard renderer.copy(container.tex.get(), nil, addr dest)

  for (c, relPos) in container.children:
    if c.hidden: continue
    if c is Container:
      renderer.draw(c.Container, pos + relPos, textStore)
    else:
      dest = r((pos + relPos), c.size)
      if c is Label: renderer.draw(c.Label, dest, textStore)
      if c is Button: renderer.draw(c.Button, dest)
