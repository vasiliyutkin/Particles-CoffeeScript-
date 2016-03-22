class Vec2 #creating main class for vectors
        constructor: (x, y) ->
                @x = x ? 0
                @y = y ? 0
        add: (vec) -> #add vector method
                @x += vec.x
                @y += vec.y
                return @
        copy: -> new Vec2 @x, @y
        @getRandom: (min, max) ->
                new Vec2 do Math.random * (max - min) + min,
                        do Math.random * (max - min) + min
 
 
 
class World #creating World class wich takes canvas as an argument
        constructor: (@canvas) ->
                @ctx = @canvas.getContext '2d' #geting context from canvas
                @canvasWidth = @canvas.width = 700 #set width
                @canvasHeight = @canvas.height = 700 #set height of canvas
 
                @objects = [] #creating obj's array
                @controllable = {} #creating obj for scroll events
                @mouse = new Vec2 @canvasWidth / 2, @canvasHeight / 2
 
                @params =
                        gravity: new Vec2 0, -.2
 
                @canvas.addEventListener "mousemove", ((e) =>
                        [@mouse.x, @mouse.y] = [e.offsetX, e.offsetY]
                ), no #moving particles to mouse position on canvas
 
                @canvas.addEventListener "mousewheel",((e) => #mousewheel shift and alt evants for diffrent particles scatter
                        do e.preventDefault
                        if @controllable instanceof ParticleSystem
                                if e.shiftKey
                                        @controllable.scatter = Math.max 0, @controllable.scatter - e.wheelDelta / 100
                                else if e.altKey
                                        @controllable.particleSize = Math.max 0, @controllable.particleSize - e.wheelDelta / 100
                                else
                                        @controllable.particleLife = Math.max 1, @controllable.particleLife - e.wheelDelta / 10
 
                ), no
 
        addObject: (constructor, config, controllable) ->
                config.world = @
                obj = new constructor config
                do obj.setControllable if controllable
                @objects.push obj
 
 
        removeObject: (index) -> @objects.splice index, 1
 
        start: -> do @tick
 
        tick: ->
                do @update
                do @draw
                # bind перемещает контекст в класс World
                webkitRequestAnimationFrame @tick.bind @
 
        update: ->
                object.update ind for object, ind in @objects when object
                #вызывается если объект существует
 
        draw: ->
                @ctx.clearRect 0, 0, @canvasWidth, @canvasHeight
                @ctx.globalAlpha = 1
                do object.draw for object in @objects
 
class _Object #creating main class
        constructor: (config) ->
                @loc = config.loc ? new Vec2
                @speed = config.speed ? new Vec2
                @world = config.world
 
        update: ->
                unless @ instanceof ParticleSystem
                        @speed.add @world.params.gravity
                @loc.add @speed
 
        notVisible: (threshold) ->
                @loc.y > @world.canvasHeight + threshold or
                @loc.y < -threshold or
                @loc.x > @world.canvasWidth + threshold or
                @loc.x < -threshold
 
        setControllable: ->
                @world.controllable = @
                @loc = @world.mouse
 
class ParticleSystem extends _Object #creating main system particle class 
        constructor: (config) ->
                super config
                @particles = []
                @maxParticles = config.maxParticles ? 300
                @particleLife = config.particleLife ? 60
                @particleSize = config.particleSize ? 24
                @creationRate = config.creationRate ? 3
                @scatter = config.scatter ? 1.3
 
        addParticle: (config) ->
                config.system = @
                config.world = @world
                @particles.push new Particle config
 
        removeParticle: (index) -> @particles.splice index ,1
 
        update: ->
                unless @particles.length > @maxParticles
                        for i in [0..@creationRate]
                                @addParticle {
                                        loc: do @loc.copy
                                        speed: Vec2.getRandom -@scatter, @scatter
                                }
                particle.update ind for particle, ind in @particles when particle
 
        draw: ->
                do particle.draw for particle in @particles
 
class Particle extends _Object #class for particals creation
        constructor: (config) ->
                super config
                @system = config.system
                @initialLife = @system.particleLife
                @life = @initialLife
                @size = @system.particleSize
       
        update: (ind) ->
                super
                @size = Math.max 0, @system.particleSize * (@life-- / @initialLife)
                if @notVisible 100 or @life < 0 then @system.removeParticle ind
 
        draw: ->
                @world.ctx.globalCompositeOperation = "darken"
                @world.ctx.globalAlpha =  @life / @initialLife
 
                grad = @world.ctx.createRadialGradient @loc.x, @loc.y, 0, @loc.x, @loc.y, @size
                grad.addColorStop 1, "lightgreen"
                grad.addColorStop 0, "#101"
                grad.addColorStop .3, "#1a1a1a"
                @world.ctx.fillStyle = grad
 
                do @world.ctx.beginPath
                @world.ctx.arc @loc.x, @loc.y, @size, 0, 2 * Math.PI
                do @world.ctx.fill
 
test = new World document.getElementById 'canvas' #creating new instance of World class
window.test = test
#creating new instanse of particle
test.addObject ParticleSystem, { 
        loc: new Vec2 200, 400
        particleSize: 8
        particleLife: 55
        scatter: .4
}, on
#creating new instanse of particle
test.addObject ParticleSystem, { 
        loc: new Vec2 200, 500
        particleSize: 4
        particleLife: 80
        scatter: 1.6
}, on
#creating new instanse of particle
test.addObject ParticleSystem, { 
        loc: new Vec2 100, 600
        particleSize: 2
        particleLife: 60
        scatter: 1.2
}, on
 
do test.start #starting app's drawing particles