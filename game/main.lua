local engine = require 'engine.init'
local player = require 'game.objects.player'
local ffi = require ('ffi')
local scene_manager = require('engine.scene_manager')

FONT = love.graphics.newFont("/assets/fonts/PressStart2P-Regular.ttf",20)
love.graphics.setFont( FONT )
GAME = {}
TURN = 1

IS_GAME = true

function engine.update(dt)
  if IS_GAME then
    WORLD.update(dt)
  end
end

CAMERA_X = 0
CAMERA_Y = 0
CAMERA_Z = 0

local names = {
  [1] = "Больжедор",
  [2] = "Герасимыч",
  [3] = "Веталь",
  [4] = "Ахмыл"
}

function engine.draw()
  if IS_GAME then
    WORLD.draw()
    -- imgui.ShowDemoWindow()
    -- WORLD.editor()
  else
    local player_id = 0
    love.graphics.setColor(1,1,1,1)
    for i,v in pairs(GAME) do
      love.graphics.print(names[i],50 + 400 * player_id,120)      
      local image = love.graphics.newImage('img/' .. v.id .. '/win/1.png')
      love.graphics.draw(image,50 + 400 * player_id,164)
      love.graphics.print('Очки: '..v.score,50 + 400 * player_id,334)
      player_id = player_id + 1
    end
  end
end


function engine.load()

  love.window.setMode(1200,900)

  love.window.setVSync(1)

  WORLD.set_screen_space_transforms(function(x,y,z, ...)
    return x + CAMERA_X, (y + CAMERA_Y)/2 - (z + CAMERA_Z), ...
  end)

  scene_manager.load('start_scene')
end