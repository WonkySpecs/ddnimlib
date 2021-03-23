import sequtils
import sdl2, sdl2 / [image, ttf]
import core / [animation, particles, drawing]

type
  SDLException = object of Defect

  Input {.pure.} = enum
    Right, Left, Up, Down, Quit, None
  Inputs = array[Right..None, bool]

  PlayerAnim = enum
    Neutral, Moving

func toInput(key: Scancode): Input =
  case key:
  of SDL_SCANCODE_RIGHT: Input.Right
  of SDL_SCANCODE_LEFT: Input.Left
  of SDL_SCANCODE_UP: Input.Up
  of SDL_SCANCODE_DOWN: Input.Down
  of SDL_SCANCODE_Q: Input.Quit
  else: Input.None

template sdlFailIf(cond: typed, reason: string) =
  if cond: raise SDLException.newException(
    reason & ", SDL error: " & $getError())

proc main =
  sdlFailIf(not sdl2.init(INIT_VIDEO or INIT_TIMER or INIT_EVENTS)):
    "SDL2 initialization failed"

  # defer blocks get called at the end of the procedure, even if an
  # exception has been thrown
  defer: sdl2.quit()

  sdlFailIf(not setHint("SDL_RENDER_SCALE_QUALITY", "2")):
    "Linear texture filtering could not be enabled"

  const imgFlags: cint = IMG_INIT_PNG
  sdlFailIf(image.init(imgFlags) != imgFlags):
    "SDL2 Image initialization failed"
  defer: image.quit()

  sdlFailIf(ttfInit() == SdlError):
    "SDL2 TTF initialization failed"
  defer: ttfQuit()

  let window = createWindow(title = "Some gameything",
    x = SDL_WINDOWPOS_CENTERED, y = SDL_WINDOWPOS_CENTERED,
    w = 800.cint, h = 600.cint, flags = SDL_WINDOW_SHOWN)
  sdlFailIf window.isNil: "Window could not be created"
  defer: window.destroy()

  let renderer = window.createRenderer(index = -1,
    flags = Renderer_Accelerated or Renderer_PresentVsync)
  sdlFailIf renderer.isNil: "Renderer could not be created"
  defer: renderer.destroy()

  var quitting = false
  var pos = vec(50, 50)
  var inputs: Inputs

  let tex = renderer.loadTexture("assets/tophat_blob.png".cstring)
  var sprite = AnimatedSprite[PlayerAnim](spriteSheet: tex)
  let frames = @[
    rect(0.cint, 0.cint, 32.cint, 32.cint),
    rect(32.cint, 0.cint, 32.cint, 32.cint),
    rect(0.cint, 32.cint, 32.cint, 32.cint),
    rect(32.cint, 32.cint, 32.cint, 32.cint)]
  sprite.addAnimation(PlayerAnim.Neutral, frames, 500)
  sprite.addAnimation(PlayerAnim.Moving, frames, 100)

  var ptex = renderer.loadTexture("assets/elf.png")
  var pe = initParticleEmitter(ptex, pos = vec(100, 100), emitDelay = 3.0, particleMaxLife = 10000.0)
  var batch = RenderBatch(renderer: renderer, cam: initCamera(800, 600))
  # Game loop, draws each frame
  while not quitting:
    var event = defaultEvent
    while pollEvent(event):
      case event.kind
      of QuitEvent:
        quitting = true
      of KeyDown:
        inputs[event.key.keysym.scancode.toInput] = true
      of KeyUp:
        inputs[event.key.keysym.scancode.toInput] = false
      else:
        discard

    if inputs[Input.Left]: pos.x -= 1
    if inputs[Input.Right]: pos.x += 1
    if inputs[Input.Up]: pos.y -= 1
    if inputs[Input.Down]: pos.y += 1
    if inputs[Input.Quit]: quitting = true

    let anim = if inputs.anyIt(it): PlayerAnim.Moving
               else: PlayerAnim.Neutral
    sprite.tick(anim, 10)

    pe.tick(10)
    pe.pos = pos

    batch.begin()
    batch.draw(pe)
    batch.draw(sprite, pos, 80, 80)
    batch.renderer.present()

when isMainModule:
    main()
