import sdl2, sdl2 / [image, ttf]

template sdlFailIf*(cond: typed, reason: string) =
  if cond: raise SDLException.newException(
    reason & ", SDL error: " & $getError())

template initSdl*() =
  sdlFailIf(not sdl2.init(INIT_VIDEO or INIT_TIMER or INIT_EVENTS)):
    "SDL2 initialization failed"
  defer:sdl2.quit()

  sdlFailIf(not setHint("SDL_RENDER_SCALE_QUALITY", "2")):
    "Linear texture filtering could not be enabled"

  const imgFlags: cint = IMG_INIT_PNG
  sdlFailIf(image.init(imgFlags) != imgFlags):
    "SDL2 Image initialization failed"
  defer: image.quit()

  sdlFailIf(ttfInit() == SdlError):
    "SDL2 TTF initialization failed"
  defer: ttfQuit()

func createWindow*(w, h: int, title: string, flags=SDL_WINDOW_SHOWN) : WindowPtr =
  result = createWindow(title = title,
    x = SDL_WINDOWPOS_CENTERED, y = SDL_WINDOWPOS_CENTERED,
    w = w.cint, h = h.cint, flags = flags)

func createRenderer*(window: WindowPtr) : RendererPtr =
  result = window.createRenderer(index = -1,
    flags = Renderer_Accelerated or Renderer_PresentVsync)
