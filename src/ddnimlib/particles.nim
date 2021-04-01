import random
import sdl2
import drawing, linear

type
  Particle* = object
    pos, vel: Vec[2]
    rot, drot, scaleX, scaleY, lifetime: float

  ParticleEmitter* = object
    tex: TexturePtr
    particles: seq[Particle]
    pos*: Vec[2]
    emitDelay, sinceEmit, particleMaxLife: float

proc initParticleEmitter*(tex: TexturePtr,
                          pos: Vec[2],
                          emitDelay, particleMaxLife: float):
                          ParticleEmitter =
  result.tex = tex
  result.particles = @[]
  result.pos = pos
  result.emitDelay = emitDelay
  result.sinceEmit = 0
  result.particleMaxLife = particleMaxLife

proc tick(p: var Particle, delta: float) =
  p.pos += p.vel
  p.rot += p.drot
  p.lifetime += delta
  
proc tick*(emitter: var ParticleEmitter,
           delta: float) =
  emitter.sinceEmit += delta
  while emitter.sinceEmit > emitter.emitDelay:
    emitter.particles.add Particle(
      pos: emitter.pos,
      rot: rand(360.0),
      vel: vec(rand(3.0) - 1.5, rand(3.0) - 1.5),
      drot: rand(10.0) - 5.0,
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

proc draw*(batch: RenderBatch, emitter: ParticleEmitter) =
  for p in emitter.particles:
    batch.render(emitter.tex, p.pos, 10, 10, p.rot)
