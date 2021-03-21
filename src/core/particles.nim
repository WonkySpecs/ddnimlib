import random, math
import sdl2

type
  Particle* = object
    x, y, rot, dx, dy, drot, scaleX, scaleY, lifetime: float

  ParticleEmitter* = object
    tex: TexturePtr
    particles: seq[Particle]
    x*, y*, emitDelay, sinceEmit, particleMaxLife: float

proc initParticleEmitter*(tex: TexturePtr,
                          x, y, emitDelay, particleMaxLife: float):
                          ParticleEmitter =
  result.tex = tex
  result.particles = @[]
  result.x = x
  result.y = y
  result.emitDelay = emitDelay
  result.sinceEmit = 0
  result.particleMaxLife = particleMaxLife

proc tick(p: var Particle, delta: float) =
  p.x += p.dx
  p.y += p.dy
  p.rot += p.drot
  p.lifetime += delta
  
proc tick*(emitter: var ParticleEmitter,
           delta: float) =
  emitter.sinceEmit += delta
  while emitter.sinceEmit > emitter.emitDelay:
    emitter.particles.add Particle(
      x: emitter.x, y: emitter.y, rot: rand(360.0),
      dx: rand(3.0) - 1.5, dy: rand(3.0) - 1.5, drot: rand(10.0) - 5.0,
      scaleX: 1, scaleY: 1, lifetime: 0)
    emitter.sinceEmit -= emitter.emitDelay

  # Obviously not efficient, will reuse objects later
  var toDelete = newSeq[int]()
  for i, p in emitter.particles.mpairs:
    p.tick(delta)
    if p.lifetime > emitter.particleMaxLife:
      toDelete.add(i)

  for i in toDelete:
    emitter.particles.delete(i)

proc render*(emitter: ParticleEmitter, renderer: RendererPtr) =
  for p in emitter.particles:
    var dest = rect(p.x.cint, p.y.cint, 10.cint, 10.cint)
    renderer.copyEx(emitter.tex, nil, addr dest, p.rot, nil)
