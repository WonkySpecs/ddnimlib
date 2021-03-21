import math
import 
  sdl2, sdl2/image, sdl2/ttf, sequtils

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

  let tex = renderer.loadTexture("assets/tophat_blob.png".cstring)

  # Set the default color to use for drawing

  # Game loop, draws each frame
  var quitting = false
  var x = 20.0
  var y = 20.0
  var inputs: Inputs

  var sprite = AnimatedSprite[PlayerAnim](spriteSheet: tex)
  let frames = @[
    rect(0.cint, 0.cint, 32.cint, 32.cint),
    rect(32.cint, 0.cint, 32.cint, 32.cint),
    rect(0.cint, 32.cint, 32.cint, 32.cint),
    rect(32.cint, 32.cint, 32.cint, 32.cint)]
  sprite.addAnimation(PlayerAnim.Neutral, frames, 500)
  sprite.addAnimation(PlayerAnim.Moving, frames, 100)

  var ptex = renderer.loadTexture("assets/elf.png")
  var pe = initParticleEmitter(ptex, x = 100.0, y = 100.0, emitDelay = 3.0, particleMaxLife = 10000.0)
  var cam = initCamera(800, 600)
  var batch = RenderBatch(renderer: renderer, cam: cam)

  var c = 1
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

    if inputs[Input.Left]: x -= 1
    if inputs[Input.Right]: x += 1
    if inputs[Input.Up]: y -= 1
    if inputs[Input.Down]: y += 1
    if inputs[Input.Quit]: quitting = true

    if inputs.anyIt(it):
      sprite.tick(PlayerAnim.Moving, 10)
    else:
      sprite.tick(PlayerAnim.Neutral, 10)

    inc c
    pe.tick(10)
    pe.x = x
    pe.y = y

    batch.cam.zoom = 1.5 + sin(c / 50)
    batch.begin()
    batch.draw(pe)
    batch.draw(sprite, x, y, 80, 80)
    batch.renderer.present()
main()
