import sequtils, math
import sdl2, sdl2 / [image, ttf]
import core / [animation, particles, drawing, init, linear, utils]

type
  SDLException = object of Defect

  Input {.pure.} = enum
    Right, Left, Up, Down, Quit, None
  Inputs = array[Right..None, bool]

  PlayerAnim = enum
    Neutral, Moving

func toInput(key: Scancode): Input =
  case key:
  of SDL_SCANCODE_D: Input.Right
  of SDL_SCANCODE_A: Input.Left
  of SDL_SCANCODE_W: Input.Up
  of SDL_SCANCODE_S: Input.Down
  of SDL_SCANCODE_Q: Input.Quit
  else: Input.None

proc main =
  const
    vw = 800
    vh = 600
    fpsCap = 200
    frameTimeMinMS = (1000 / fpsCap).int
    targetFPS = 60
    targetFrameTimeNS = 1_000_000 / targetFPS

  initSdl()

  let window = createWindow(vw, vh, "title")
  sdlFailIf window.isNil: "Window could not be created"
  defer: window.destroy()

  let renderer = window.createRenderer()
  sdlFailIf renderer.isNil: "Renderer could not be created"
  defer: renderer.destroy()

  var
    lastFrameNs = getPerformanceCounter().int
    tex = renderer.loadTexture("assets/tophat_blob.png")
    sprite = AnimatedSprite[PlayerAnim](spriteSheet: tex)
    ptex = renderer.loadTexture("assets/elf.png")
    pe = initParticleEmitter(ptex,
                             pos = vec(100, 100),
                             emitDelay = 3.0,
                             particleMaxLife = 10000.0)
    batch = initBatch(renderer, vw, vh)
    quitting = false
    pos = vec(-400, 0)
    inputs: Inputs

  let frames = @[
    r(0, 0, 32, 32),
    r(32, 0, 32, 32),
    r(0, 32, 32, 32),
    r(32, 32, 32, 32)]
  sprite.addAnimation(PlayerAnim.Neutral, frames, 300)
  sprite.addAnimation(PlayerAnim.Moving, frames, 50)

  # Game loop, draws each frame
  while not quitting:
    let time = getPerformanceCounter().int
    let delta = (time - lastFrameNs) / targetFrameTimeNS.int
    lastFrameNs = time

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

    if inputs[Input.Left]: pos.x -= delta
    if inputs[Input.Right]: pos.x += delta
    if inputs[Input.Up]: pos.y -= delta
    if inputs[Input.Down]: pos.y += delta
    if inputs[Input.Quit]: quitting = true

    let anim = if inputs.anyIt(it): PlayerAnim.Moving
               else: PlayerAnim.Neutral
    sprite.tick(anim, delta)

    pe.tick(delta)
    pe.pos = pos

    batch.start()
    batch.draw(pe)
    batch.draw(sprite, pos, 80, 80)
    batch.finish()

    if fpsCap > 0:
      let elapsedMS = ((getPerformanceCounter().int - lastFrameNs) / 1000).int
      if elapsedMS < frameTimeMinMS:
        delay((frameTimeMinMS - elapsedMS).uint32)

when isMainModule:
    main()
