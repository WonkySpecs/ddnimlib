import sequtils
import sdl2, sdl2 / [image, ttf]
import core / [animation, particles, drawing, init]

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

proc main =
  initSdl()

  let window = createWindow(800, 600, "title")
  sdlFailIf window.isNil: "Window could not be created"
  defer: window.destroy()

  let renderer = window.createRenderer()
  sdlFailIf renderer.isNil: "Renderer could not be created"
  defer: renderer.destroy()

  var quitting = false
  var pos = vec(-400, 0)
  var inputs: Inputs

  let tex = renderer.loadTexture("assets/tophat_blob.png".cstring)
  var sprite = AnimatedSprite[PlayerAnim](spriteSheet: tex)
  let frames = @[
    rect(0.cint, 0.cint, 32.cint, 32.cint),
    rect(32.cint, 0.cint, 32.cint, 32.cint),
    rect(0.cint, 32.cint, 32.cint, 32.cint),
    rect(32.cint, 32.cint, 32.cint, 32.cint)]
  sprite.addAnimation(PlayerAnim.Neutral, frames, 300)
  sprite.addAnimation(PlayerAnim.Moving, frames, 50)

  var ptex = renderer.loadTexture("assets/elf.png")
  var pe = initParticleEmitter(ptex,
                               pos = vec(100, 100),
                               emitDelay = 3.0,
                               particleMaxLife = 10000.0)
  var batch = RenderBatch(renderer: renderer, cam: initCamera(800, 600))

  const fpsCap = 200
  const frameTimeMinMS = (1000 / fpsCap).int
  const targetFPS = 60
  const targetFrameTimeNS = 1_000_000 / targetFPS
  var lastFrameNs = getPerformanceCounter().int

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

    batch.begin()
    batch.draw(pe)
    batch.draw(sprite, pos, 80, 80)
    batch.renderer.present()

    if fpsCap > 0:
      let elapsedMS = ((getPerformanceCounter().int - lastFrameNs) / 1000).int
      if elapsedMS < frameTimeMinMS:
        delay((frameTimeMinMS - elapsedMS).uint32)

when isMainModule:
    main()
