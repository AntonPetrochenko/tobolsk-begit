local engine = require 'engine.init'
local player = require 'game.objects.player'
local ffi = require ('ffi')

GAME = {}

function engine.update(dt)
  WORLD.update(dt)
end

CAMERA_X = 0
CAMERA_Y = 0
CAMERA_Z = 0

function engine.draw()
  WORLD.draw()
  imgui.ShowDemoWindow()
  WORLD.editor()
end


function engine.load()

  love.window.setMode(1200,900)

  love.window.setVSync(1)

  WORLD.set_screen_space_transforms(function(x,y,z, ...)
    return x + CAMERA_X, (y + CAMERA_Y)/2 - (z + CAMERA_Z), ...
  end)
end