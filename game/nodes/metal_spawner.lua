local metal = require 'game.objects.metal'

local function update (node)
end

local function init (node)
  for _,v in pairs(WORLD.terrain) do
    if v['tag_metal'] then
      for __=1,tonumber(v['tag_metal']) or 1 do
        local x = math.random(v.x_left, v.x_right)
        local y = math.random(v.y_near, v.y_far)
        local z = v.get_z_at(v, x)
        local image = love.graphics.newImage('assets/obstacle2.png')
        WORLD.add(metal(x, y, z, image, 300))
      end
    end
  end
end


return function () return
{
  update = function () end,
  init = init
}
end