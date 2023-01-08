local bomject = require "engine.bomject"
--- @param terrain Terrain
return function(terrain, near)

  --different top values are used for near and far
  -- for near mode
  local near_top_left = {SCREENSPACE_NEUTRAL(terrain.x_left, terrain.y_near, terrain.z_left)}
  local near_top_right = {SCREENSPACE_NEUTRAL(terrain.x_right, terrain.y_near, terrain.z_right)}

  -- for far mode
  local far_top_left = {SCREENSPACE_NEUTRAL(terrain.x_left, terrain.y_far, terrain.z_left)}
  local far_top_right = {SCREENSPACE_NEUTRAL(terrain.x_right, terrain.y_far, terrain.z_right)}


  local near_bottom_left = {SCREENSPACE_NEUTRAL(terrain.x_left, terrain.y_near, terrain.z_bottom )}
  local near_bottom_right = {SCREENSPACE_NEUTRAL(terrain.x_right, terrain.y_near, terrain.z_bottom)}


  local selected_top_left = near and near_top_left or far_top_left
  local selected_top_right = near and near_top_right or far_top_right
  

  --- @class BomjineTerrainMasker: Bomject
  local new_masker = bomject ("INTERNAL_Masker_" .. (near and 'near' or 'far'))  {
    _x = 0,
    _y = 0,
    _z = 0,
    _step = 0
  }

  new_masker.image = geometryCanvas
  local z_min = math.min(terrain.z_left, terrain.z_right)
  new_masker.layer_adjust = near and terrain.y_near or terrain.y_far
  new_masker:define_state('default', {
    enter = NOP,
    draw = function (self) 
      love.graphics.stencil(function () 
        love.graphics.polygon("fill",
        selected_top_left[1], selected_top_left[2],
        selected_top_right[1], selected_top_right[2],
        near_bottom_right[1], near_bottom_right[2],
        near_bottom_left[1], near_bottom_left[2]
      )
      end , "replace", 1)
      love.graphics.setStencilTest("greater", 0)
  
      love.graphics.draw(WORLD.background_image)
    end,
    update = NOP,
  })

  return new_masker
end