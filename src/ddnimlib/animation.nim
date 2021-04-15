import tables, sugar, sequtils
from sdl2 import TexturePtr, Rect
import drawing, linear

type
  Animation = object
    frames: seq[Rect]
    frameDelay: int

  AnimatedSprite*[T] = object
    spriteSheet: TexturePtr
    activeAnimation*: T
    timer: float
    animations: Table[T, Animation]

func newSprite*[T](sheet: TexturePtr,
                   frames: Table[T, seq[Rect]],
                   startAnimation: T,
                   frameDelay: int): AnimatedSprite[T] =
  let animations = collect(newSeq):
    for k, v in frames.pairs():
      (k, Animation(frames: v, frameDelay: frameDelay))
  AnimatedSprite[T](
    spriteSheet: sheet,
    activeAnimation: startAnimation,
    timer: 0,
    animations: animations.toTable)

proc addAnimation*[T](sprite: var AnimatedSprite[T],
                      key: T,
                      frames: seq[Rect],
                      frameDelay: int) =
  sprite.animations[key] = Animation(frames: frames, frameDelay: frameDelay)

proc tick*[T](sprite: var AnimatedSprite[T],
              toPlay: T,
              delta: float) =
  if toPlay != sprite.activeAnimation:
    sprite.activeAnimation = toPlay
    sprite.timer = 0
  else:
    sprite.timer += delta

func curFrame(sprite: AnimatedSprite): Rect {.inline.} =
  let animation = sprite.animations[sprite.activeAnimation]
  let totFrameTime = animation.frames.len * animation.frameDelay
  let frameNum = ((sprite.timer.int mod totFrameTime) / animation.frameDelay).int
  animation.frames[frameNum]

proc draw*(view: View,
           sprite: AnimatedSprite,
           pos: Vec[2],
           w, h: int) =
  var r = sprite.curFrame
  view.renderRect(sprite.spriteSheet, r, pos, w, h, 0.0)
