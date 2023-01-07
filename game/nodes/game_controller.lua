local player = require 'game.objects.player'

local function update (node)

end

local function init (node)
  for old_node_idx,old_node in pairs(WORLD.nodes) do
    for i,v in pairs(old_node) do
      -- local new_player = player(v.x - i * math.random(), v.y - i * math.random(), v.z, GAME[i].)
      print(GAME[i])
    end
  end
end


return function () return
{
  update = function () end,
  init = init
}
end