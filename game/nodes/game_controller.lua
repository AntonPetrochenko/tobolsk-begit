local player = require 'game.objects.player'

local function update (node)

end

local function init (node)
  for _,v in pairs(GAME) do
    local new_player = player(node.x - v.id * math.random() - v.turn * 32, node.y - v.id * math.random(), node.z, v.joystick, v.id)
    WORLD.add(new_player)
    new_player.playerdata = v
  end
end


return function () return
{
  update = function () end,
  init = init
}
end