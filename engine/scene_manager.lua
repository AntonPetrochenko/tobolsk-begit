local scene_manager = {}
local ini = require 'engine.ini'

love.filesystem.createDirectory('scenes')

local function ini_prepare(in_table)
  local out_table = {}
  for node_index,node in pairs(in_table) do
    local node_record_copy = {}
    -- copy crap that's not function pointers
    for property_name, property_value in pairs(node) do
      -- safe to copy types
      if type(property_value) == 'string' or type(property_value) == 'number' then
        node_record_copy[property_name] = property_value
      end
    end
    out_table[node_index] = node_record_copy
  end
  return out_table
end


local path_prefix = 'scenes/'


local terrain_suffix = '_scene_terrain.bomjine.ini'
local node_suffix = '_scene_nodes.bomjine.ini'
local info_suffix = '_scene_info.bomjine.ini'

--- Saves current world state as a scene. TODO: Rewrite for binary storage. This will break compatibility no matter what!
--- @param name string Scene name
function scene_manager.dev_save(name)
  local out_terrain_data = ini_prepare(WORLD.terrain)
  local out_node_data = ini_prepare(WORLD.nodes)
  local world_meta_data = {
    properties = WORLD.properties
  }
  local out_info_data = ini_prepare(world_meta_data)

  ini.save(path_prefix .. name .. terrain_suffix, out_terrain_data)
  ini.save(path_prefix .. name .. node_suffix, out_node_data)
  ini.save(path_prefix .. name .. info_suffix, out_info_data)
end

-- Restores a scene
function scene_manager.load(name, devmode)
  -- load first
  local in_terrain_data = ini.load(path_prefix .. name .. terrain_suffix)
  -- reset world if haven't failed
  WORLD.reset()

  for idx, terrain_record in pairs(in_terrain_data) do
    local new_terrain = WORLD.create_terrain(
      terrain_record.x_left,
      terrain_record.x_right,
      terrain_record.z_left,
      terrain_record.z_right,
      terrain_record.z_bottom,
      terrain_record.y_far,
      terrain_record.y_near
    )

    for property_name,property_value in pairs(terrain_record) do
      if string.find(property_name, 'tag_') then
        new_terrain[property_name] = property_value
      end
    end
  end


  local in_node_data = ini.load(path_prefix .. name .. node_suffix)
  for idx, node in pairs(in_node_data) do
    WORLD.create_node(node)
  end

  local in_info = ini.load(path_prefix .. name .. info_suffix)
  WORLD.properties = in_info.properties

  WORLD.do_properties()
  if not devmode then
    WORLD.do_nodes()
  end
end

return scene_manager