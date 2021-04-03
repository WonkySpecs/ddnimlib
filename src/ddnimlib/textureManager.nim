import tables, sequtils

from sdl2 import TexturePtr, RendererPtr
import sdl2/image

type
  TextureManager*[K] = object
    texLocations*: Table[K, string]
    renderer*: RendererPtr
    loaded: Table[string, TexturePtr]

proc preloadAll*[K](mgr: var TextureManager[K]) =
  echo "Preloading ", mgr.texLocations.len, " textures"
  mgr.preload(toSeq(mgr.texLocations.keys()))

proc preload*[K](mgr: var TextureManager[K], toPreload: openArray[K]) =
  for t in toPreload:
    discard mgr.get(t)

proc get*[K](mgr: var TextureManager[K], texKey: K): TexturePtr =
  let loc = mgr.texLocations[texKey]
  if mgr.loaded.hasKey(loc):
    return mgr.loaded[loc]
  let
    tex = mgr.renderer.loadTexture(loc)
  assert tex != nil, "Failed to load texture: " & loc
  mgr.loaded[loc] = tex
  return tex
