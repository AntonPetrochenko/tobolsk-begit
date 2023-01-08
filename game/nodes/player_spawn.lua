local player = require 'game.objects.player'

local available_joysticks = love.joystick.getJoysticks()

local function update (node)
  local target_joystick = available_joysticks[tonumber(node.joystick_id)]
  if target_joystick and target_joystick:isGamepadDown('start') then
    for i=0,0,4 do
      local new_player = player(node.x - i * math.random(), node.y - i * math.random(), node.z, target_joystick, node.joystick_id)
      WORLD.add(new_player)
      local new_playerdata = {
        id = tonumber(node.joystick_id),
        joystick = target_joystick,
        turn = 0,
        score = 0
      }
      new_player.playerdata = new_playerdata
      GAME[node.joystick_id] = new_playerdata
    end
    node.update = function() end
  end
end

local function init (node)
  local target_joystick = available_joysticks[tonumber(node.joystick_id)]
  if not target_joystick then 
    node.update = function() end 
  else
    node.update = update
  end


end


return function () return
{
  update = function () end,
  init = init
}
end