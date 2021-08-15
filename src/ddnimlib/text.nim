import tables, deques, options, sets, sugar
import sdl2, sdl2 / ttf
import utils

type
  TextKey = tuple
    text: string
    fg: Color
    bg: Option[Color]
  TextStore* = ref object
    font: FontPtr
    textures: Table[TextKey, TexturePtr]
    accesses: Deque[TextKey]
    texturesSizeThresh: int
    accessesMaxLen: int

func newTextStore*(font: FontPtr): TextStore =
  new result
  result.font = font
  result.texturesSizeThresh = 100
  result.accessesMaxLen = 50

proc renderText*(renderer: RendererPtr,
                 font: FontPtr,
                 text: string,
                 fg: Color,
                 bg: Option[Color]): TexturePtr =
  let 
    surf = if bg.isSome: renderText(font, text.cstring, fg, bg.get())
           else: renderTextSolid(font, text.cstring, fg)
    tex = renderer.createTextureFromSurface(surf)
  surf.freeSurface
  result = tex

proc access(store: TextStore, k: TextKey) =
  store.accesses.addLast(k)
  if store.accesses.len > store.accessesMaxLen:
    store.accesses.popFirst()

proc flushLastUsed(store: TextStore) =
  ## Remove any textures from the store that haven't been accessed recently
  var s = collect(initHashSet):
    for a in store.accesses.items: {a}

  let ks = collect(newSeq):
    for k in store.textures.keys(): k

  for k in ks:
    if not s.contains(k):
      store.textures[k].destroy()
      store.textures.del(k)

proc getTextTexture*(store: var TextStore,
                     renderer: RendererPtr,
                     text: string,
                     fg: Color,
                     bg: Option[Color]): TexturePtr =
  let k = (text: text, fg: fg, bg: bg).TextKey
  if store.textures.hasKey(k):
    return store.textures[k]

  let tex = renderer.renderText(store.font, text, fg, bg)
  store.access(k)
  store.textures[k] = tex
  if store.textures.len > store.texturesSizeThresh:
    store.flushLastUsed()
  result = tex
