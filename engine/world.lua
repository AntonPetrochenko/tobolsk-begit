local ffi = require "ffi"
local cpml = require "engine.cpml"
local uuid = require 'engine.uuid'
local scene_manager = require 'engine.scene_manager'
local node_defs = require 'game.nodes.node_info'
local debug = require 'debug'
local masker= require 'engine.internal_bomjects.masker'
local function nop(...) end
--- @class World
local world = {
  nodes_active = false,
  timescale = 1,
  --- @type table<number, Bomject>
  objects = {},
  --- @type table<number, Terrain>
  terrain = {},
  --- @type table<number, EditorNode>
  nodes = {},
  properties = {
    background = 'img/bg.png'
  },
  not_broken = true,
  error = '',
  traceback = '',
  --- @type Bomject
  err_culprit = {},
  --- @type nil|love.Image
  background_image = nil
}

local framecount = 0

function world.reset()
  world.objects = {}
  world.nodes = {}
  world.terrain = {}
  world.properties = {
    background = 'img/bg.png'
  }
  world.not_broken = true
end

local last_dt = 0

local function __proto_delete (self)
  world.objects[self.__id] = nil
end

function world.add(obj)
  local id = uuid()

  world.objects[id] = obj
  obj.__id = id
  obj.destroy = __proto_delete
end

function world.__screen_space_transforms(object)
  
end

function SCREENSPACE(x,y,z, ...)
  error('Screen space is not defined. Please call world.set_screen_space_transforms',2)
  return 0, 0, ...
end

SCREENSPACE_NEUTRAL = SCREENSPACE

function world.set_screen_space_transforms(fn)
  print('Setting screen space as ', fn)
  SCREENSPACE = fn
  SCREENSPACE_NEUTRAL = function (...)
    local a,b,c = CAMERA_X, CAMERA_Y, CAMERA_Z
    CAMERA_X, CAMERA_Y, CAMERA_Z = 0,0,0
    local out_x, out_y = SCREENSPACE(...)
    CAMERA_X, CAMERA_Y, CAMERA_Z = a,b,c
    return out_x, out_y
  end
  -- test screen space function for compat with draw function calls
  local a,b,c,d = fn(1,2,3,4)
  if (c ~= 4) then
    error('Provided screen space transform MUST return args 4,5,... and on as args 3,4,... as-is, e.g. [function SCREENSPACE(x,y,z,...) return x,y-z,... end]')
  end
  for i,v in pairs({fn(1,2,3)}) do
    print ('screenspace test',i,v)
  end
end

function world.update(dt)
  local profileUpdate = APPLECAKE.profile('World update')
  local ts = world.timescale
  for i,object in pairs(world.objects) do
    local profileObject = APPLECAKE.profile('Update ' .. object.__type .. ' state ' .. object.__state_name)
    if world.not_broken then
      xpcall(object.update, function(err) 
         world.not_broken = false
         world.traceback = debug.traceback()
         world.err_culprit = object
         world.error = 'While updating: ' ..err
      end, object, dt * ts) 
      profileObject:stop()
    end
  end
  if world.nodes_active and world.not_broken then 
    for i,node in pairs(world.nodes) do
      node:update(dt * ts)
    end
  end
  last_dt = dt
  profileUpdate:stop()
end

function world.draw()
  local profileDraw = APPLECAKE.profile('World draw')
  framecount = framecount + 1
  if world.background_image then
    love.graphics.draw(world.background_image,SCREENSPACE(0,0,0))
  end

  local drawlist = {}

  for i, object in pairs(world.objects) do
    drawlist[#drawlist+1] = object
  end
  table.sort(drawlist, function (a,b) 
    return 
      a.vec3_pos.y + a.layer_adjust<
      b.vec3_pos.y + b.layer_adjust
  end)

  for i,object in pairs(drawlist) do

    love.graphics.push('all')
    local x,y = SCREENSPACE(object._x, object._y, object._z)
    love.graphics.translate(x,y)
    local profileObject = APPLECAKE.profile('Draw ' .. object.__type .. ' state ' .. object.__state_name)
    if world.not_broken then
      xpcall(object.draw, function(err) 
        world.not_broken = false
        world.traceback = debug.traceback()
        world.err_culprit = object
        world.error = 'While drawing: ' .. err
        love.graphics.reset()
      end, object)
    end
    profileObject:stop()
    love.graphics.pop()

  end
  if not world.not_broken then
    if imgui.Begin('TIS BORKED!!!!1') then
      imgui.Text('GAME CRASHED!')
      imgui.Text('Caused by instance of ' .. world.err_culprit.__type)
      imgui.Separator()
      imgui.Text(world.error)
      imgui.TextInput('Error culprit UUID', world.err_culprit.__id)
      imgui.Text(world.traceback)
    end
  end
  profileDraw:stop();
end

function world.do_nodes()
  for i, node in pairs(world.nodes) do
    node:init()
  end
  world.nodes_active = true

  for _, terrain in pairs(world.terrain) do
    if not terrain['tag_nomask'] then
      world.add(masker(terrain, true))
      world.add(masker(terrain, false))
    end
  end
end

function world.do_properties()
  if WORLD.properties.background and love.filesystem.getInfo(WORLD.properties.background) then
    WORLD.background_image = love.graphics.newImage(WORLD.properties.background)
  end
end
--==--==--==--==--==--


local function update_kb(self)
  self.linear_k = (self.z_right - self.z_left) / (self.x_right - self.x_left)
  self.linear_b = self.z_left - (self.linear_k * self.x_left)

  local slope_neutral = math.abs(math.atan(self.linear_k) / (math.pi / 2))
  self.slope_increase = 1 + slope_neutral
  self.slope_decrease = 1 - slope_neutral
end

local function get_z_at(self, x)
  return ((self.linear_k * x) + self.linear_b)
end

function world.create_terrain(x_left, x_right, z_left, z_right, z_bottom, y_far, y_near)
  --- @class Terrain
  --- @field linear_k number
  --- @field linear_b number
  --- @field slope_increase number
  --- @field slope_decrease number
  --- @field editor_is_hovered boolean
  local new_terrain = {}
  new_terrain.x_left = x_left
  new_terrain.x_right = x_right
  new_terrain.z_left = z_left
  new_terrain.z_right = z_right

  new_terrain.z_bottom = z_bottom

  new_terrain.y_near = y_near
  new_terrain.y_far = y_far

  new_terrain.update_kb = update_kb
  new_terrain.get_z_at = get_z_at

  new_terrain.is_being_edited = false
  new_terrain:update_kb()
  -- now has linear_k and linear_b

  new_terrain.slope_sign = SIGN(new_terrain.linear_k)

  
 
  world.terrain[#world.terrain+1] = new_terrain
  return new_terrain
end

--- @param data EditorNode
function world.create_node(data)
  local success, script_factory = pcall(function() return require('game.nodes.' .. data.type) end)

  if not success then print('DEEP SHIT: Unknown node type ' .. data.type ) end

  --- @class EditorNode
  --- @field x number
  --- @field y number
  --- @field z number
  --- @field type string
  local new_node = data
  if success then

    local node_scripts = script_factory()

    new_node.init = node_scripts.init or nop
    new_node.update = node_scripts.update or nop

    WORLD.nodes[#WORLD.nodes+1] = new_node
  end
end


--- @param object Bomject
--- @param dt_jank number
function world.collide(object, dt)
  local dt_jank = dt * 3
  local current_object_x, current_object_y, current_object_z = object.vec3_pos:unpack()
  local object_vel_x, object_vel_y, object_vel_z = object.vec3_vel:unpack()

  local goal_object_x = current_object_x + (object_vel_x * dt_jank)
  local goal_object_y = current_object_y + (object_vel_y * dt_jank)
  local goal_object_z = current_object_z + (object_vel_z * dt_jank)
  local is_colliding, terrain, wall_collide, new_z = false, nil, false, goal_object_z
  local collisions = {}
  local collision_wall = nil
  local z_top_max = -99999999
  for i,terrain in pairs(world.terrain) do
    --AABB with kind of a twist
    -- print(object_x > terrain.x_left, object_x < terrain.x_right, object_y < terrain.y_near, object_y > terrain.y_far)
    
    if goal_object_x > terrain.x_left and goal_object_x < terrain.x_right
    and goal_object_y < terrain.y_near and goal_object_y > terrain.y_far 
    then
      -- Object is within this box on the 2D plane. Now check if this box exists here on the Z axis 
      -- kx+b time
      local z_at_object = terrain:get_z_at(goal_object_x)
      if z_at_object > goal_object_z then
          -- we are under the top of the object
          if terrain.z_bottom < goal_object_z then
            -- we are above the bottom
            -- which means, we're inside the box.
            -- verify doom step size for stairs, etc, to allow a transparent step
            -- calculate height difference
            local z_diff = z_at_object - goal_object_z
            

            if z_diff < object._step then
              local previous_z_vel = object.vec3_vel.z
              object.vec3_vel.z = 0
              z_top_max = z_at_object
              collisions[z_at_object] = {
                wall = false,
                terrain = terrain,
                z = z_at_object,
                x = current_object_x,
                y = current_object_y,
                vel_z = previous_z_vel
              }
            else
              -- Colliding with a wall. But which one?
              local resulting_x_position = current_object_x
              local resulting_y_position = current_object_y

              local save_my_ass = true

              if current_object_x < terrain.x_left and current_object_x < terrain.x_right then
                save_my_ass = false
                print('left')
                object.vec3_vel.x = 0
                resulting_x_position = terrain.x_left - 0.01
              end
              if current_object_x > terrain.x_right and current_object_x > terrain.x_left then
                save_my_ass = false
                print('right')
                object.vec3_vel.x = 0
                resulting_x_position = terrain.x_right + 0.01
              end

              if current_object_y > terrain.y_near and current_object_y > terrain.y_far then
                save_my_ass = false
                print('near')
                object.vec3_vel.y = 0
                resulting_y_position = terrain.y_near + 0.01
              end

              if current_object_y < terrain.y_far and current_object_y < terrain.y_near then
                save_my_ass = false
                print('far')
                object.vec3_vel.y = 0
                resulting_y_position = terrain.y_far - 0.01
              end

              if save_my_ass then
                -- all else failed, dick stuck in fan, need to recover

                print ('ass saved')
                return {
                  wall = false,
                  terrain = terrain,
                  z = z_at_object,
                  x = current_object_x,
                  y = current_object_y,
                  vel_z = 0
                }

              end
              collision_wall = {
                wall = true,
                terrain = terrain,
                z = current_object_z,
                x = resulting_x_position,
                y = resulting_y_position,
                vel_z = object_vel_x
              }
            end
          end
      end
    end
  end

  return collisions[z_top_max], collision_wall 
end

function world.ray_downwards(in_x,in_y,in_z)
  local aabb_hits = {}
  for i,terrain in pairs(world.terrain) do
    if in_x > terrain.x_left and in_x < terrain.x_right
    and in_y < terrain.y_near and in_y > terrain.y_far
    then
      aabb_hits[#aabb_hits+1] = terrain
    end
  end

  local test_z = in_z + 10 --small push, just in case we're already in direct collision
  local max_z = -9999999
  local max_z_object = nil

  for i,terrain in pairs(aabb_hits) do
    local terrain_z = terrain:get_z_at(in_x)
    if terrain_z > max_z and terrain_z < test_z then
      max_z = terrain_z
      max_z_object = terrain

    end
  end

  return max_z, max_z_object
end

local sr1, sg1, sb1, sa1 = 1,1,1,0.5
local sr2, sg2, sb2, sa2 = 0,0,0,0.5
local function screenspaceline(point1, point2, opacity, o_r, o_g, o_b)
  love.graphics.push('all')
  
  love.graphics.setColor(o_r or sr1, o_g or sg1, o_b or sb1, sa1 * opacity)
  love.graphics.line(
    point1[1]+1,
    point1[2]+1,
    point2[1]+1,
    point2[2]+1)
  
  love.graphics.setColor(o_r or sr2, o_g or sg2, o_b or sb2, sa2 * opacity)
  love.graphics.line(
    point1[1],
    point1[2],
    point2[1],
    point2[2])
    love.graphics.pop()
  

end

local incrementalColor = 0

local show_functions = {}

local function ezinspector(title, in_object)
  if imgui.TreeNode(title) then
    show_functions[tostring(in_object)] = imgui.Checkbox('Show function pointers', show_functions[tostring(in_object)])
    local keys = {}
    for key, field in pairs(in_object) do
      keys[#keys+1] = key
    end
    table.sort(keys)
    for i,key in pairs(keys) do
      local value = in_object[key]
      local type = type(value)

      
      if (cpml.vec3.is_vec3(value)) then 
        value.x, value.y, value.z = imgui.DragFloat3(key, value.x, value.y, value.z ) 
      elseif type == 'table' then
        ezinspector(key, value)
      elseif type ~= "function" or show_functions[tostring(in_object)] then
        imgui.Text(key .. ' => ' .. '' .. type .. ' ' .. tostring(value))
      end
    end
    imgui.TreePop()
  end
  
end


function world.debug_display_collision(grid_z, grid_scale, show_grid)
  if show_grid then 
    -- top-bottom lines
    love.graphics.push('all')
    love.graphics.setColor(1,1,1,0.3)
    local lines = {}
    for i=0,100 do
      local line_start = {SCREENSPACE(i*grid_scale,0,grid_z)}
      local line_end = {SCREENSPACE(i*grid_scale,10000,grid_z)}

      lines[#lines+1] = {line_start, line_end}
    end

    --left-right lines
    local bottom_limit = math.max(10000/grid_scale, 1) 
    for i=0,bottom_limit do
      local line_start = {SCREENSPACE(0,i*grid_scale,grid_z)}
      local line_end = {SCREENSPACE(9999,i*grid_scale,grid_z)}

      lines[#lines+1] = {line_start, line_end}
    end
    for i,v in pairs(lines) do
      screenspaceline(v[1], v[2], 0.5)
    end
    
    love.graphics.pop()
  end

  
  

  love.graphics.push('all')
  love.graphics.setColor(1,1,1,0.1)
  for i,v in pairs(world.terrain) do
    -- Draw shadow
    if show_grid then
      love.graphics.setColor(0.9,0.9,1,0.3)
      if v.editor_is_hovered then
        love.graphics.setColor(0.9,0.9,1,0.5)
      end
      local gptl = {SCREENSPACE(v.x_left, v.y_far, grid_z)}
      local gptr = {SCREENSPACE(v.x_right, v.y_far, grid_z)}
      local gpbl = {SCREENSPACE(v.x_left, v.y_near, grid_z)}
      local gpbr = {SCREENSPACE(v.x_right, v.y_near, grid_z)}
      love.graphics.polygon("fill", gptl[1], gptl[2], gptr[1], gptr[2], gpbr[1], gpbr[2], gpbl[1], gpbl[2])
    end
    
    local prism_opacity, o_r, o_g, o_b = 0.5, nil, nil, nil
    if v.editor_is_hovered then
      prism_opacity = 1
      o_r = math.random()
      o_g = math.random()
      o_b = math.random()
    end
    
    -- Draw prism
    local near_top_left = {SCREENSPACE(v.x_left, v.y_near, v.z_left)}
    local near_top_right = {SCREENSPACE(v.x_right, v.y_near, v.z_right)}
    local near_bottom_left = {SCREENSPACE(v.x_left, v.y_near, v.z_bottom )}
    local near_bottom_right = {SCREENSPACE(v.x_right, v.y_near, v.z_bottom)}
    local far_top_left = {SCREENSPACE(v.x_left, v.y_far, v.z_left)}
    local far_top_right = {SCREENSPACE(v.x_right, v.y_far, v.z_right)}
    screenspaceline(near_top_left, near_top_right, prism_opacity, o_r, o_g, o_b)
    screenspaceline(near_top_right, near_bottom_right, prism_opacity, o_r, o_g, o_b)
    screenspaceline(near_bottom_right, near_bottom_left, prism_opacity, o_r, o_g, o_b)
    screenspaceline(near_bottom_left, near_top_left, prism_opacity, o_r, o_g, o_b)

    screenspaceline(near_top_left, far_top_left, prism_opacity, o_r, o_g, o_b)
    screenspaceline(near_top_right, far_top_right, prism_opacity, o_r, o_g, o_b)
    screenspaceline(far_top_left, far_top_right, prism_opacity, o_r, o_g, o_b)

    love.graphics.push('all')
    love.graphics.setColor(0,0,0,1)
    love.graphics.print(v.special_layer_adjust or '', near_top_left[1], near_top_left[2])
    love.graphics.pop()
    
  end

  for idx,node in pairs(world.nodes) do
    local cross_target_z = world.ray_downwards(node.x, node.y, node.z)
    love.graphics.push('all')
    love.graphics.setColor(1,0,0,0.5)
    screenspaceline({SCREENSPACE(node.x-10,node.y-10,cross_target_z)},{SCREENSPACE(node.x+10,node.y+10,cross_target_z)}, 1, 1, 0, 0)
    screenspaceline({SCREENSPACE(node.x+10,node.y-10,cross_target_z)},{SCREENSPACE(node.x-10,node.y+10,cross_target_z)}, 1, 1, 0, 0)
    love.graphics.ellipse("fill",SCREENSPACE(node.x, node.y, node.z, grid_scale/8, grid_scale/8))
    love.graphics.printf(node.type, SCREENSPACE(node.x, node.y, node.z+40, 100, "center"))
    love.graphics.pop()
  end
  love.graphics.pop()
end

local function dblClick()
  return imgui.IsItemHovered() and imgui.IsMouseDoubleClicked(0)
end



local show_grid = true
local grid_z = -300
local grid_scale = 32

local function round_to_grid(n)
  local subscale = grid_scale/4
  return math.floor((n/subscale)+0.5)*subscale
end
local enabled_widgets = {}

--- @type string|boolean
local filemode = false
local current_file = 'DRAFT'
local fileinput = current_file

local tagnameinput = ''

function world.editor()
  local editorProfile = APPLECAKE.profile('Editor (mostly imgui calls)')
  if imgui.BeginMainMenuBar({"ImGuiWindowFlags_HorizontalScrollbar "}) then
    if imgui.BeginMenu('File') then
      if imgui.MenuItem('New') then
        filemode = 'new'
        fileinput = ''
      end

      if imgui.MenuItem('Draft') then
        scene_manager.load('draft')
      end

      if imgui.MenuItem('Open') then
        filemode = 'open'
        fileinput = ''
      end
      if imgui.MenuItem('Save') then
        filemode = 'save'
        fileinput = current_file
      end
      imgui.EndMenu()
    end
    
    imgui.PushItemWidth(150)
    if filemode then 
      fileinput = imgui.InputTextWithHint('Filename', filemode .. ' file', fileinput, 32)

      if filemode == 'new' then
        if imgui.Button('Create') then
          current_file = fileinput
          world.reset()
          filemode = false
        end
      end

      if filemode == 'save' then
        if imgui.Button('Save') then
          scene_manager.dev_save(fileinput, {})
          filemode = false
          current_file = fileinput
        end
      end

      if filemode == 'open' then
        local buttonLoadAndRun = imgui.Button('Open and run')
        if imgui.Button('Open') or buttonLoadAndRun then
          local status, err = pcall(function () scene_manager.load(fileinput, not buttonLoadAndRun) end)
          if status then
            filemode = false
            current_file = fileinput
          else
            print(err)
          end
        end
      end

      if imgui.Button('Cancel') then
        filemode = false
      end
    end
    imgui.Separator()
    imgui.Text('Scene: ' .. current_file)
    imgui.Separator()
    world.timescale = imgui.DragFloat('', world.timescale, 0.001, 0.001, 2, string.format("Time scale: %.3f", world.timescale) )
    if imgui.Button('Pause') then
      world.timescale = 0.001
    end
    if imgui.Button('Normal') then
      world.timescale = 1
    end

    imgui.Separator()
    imgui.Text(world.nodes_active and 'LIVE' or 'DEAD')
    if imgui.Button('Run') then
      world.objects = {}
      world.do_nodes()
    end
    if imgui.Button('Kill') then
      world.objects = {}
      world.nodes_active = false
    end


    imgui.Separator()
    enabled_widgets.scene_editor = imgui.Checkbox('Scene editor', enabled_widgets.scene_editor)
    imgui.Separator()
    enabled_widgets.object_inspector = imgui.Checkbox('Object inspector', enabled_widgets.object_inspector)
    imgui.Separator()
    enabled_widgets.profiler = imgui.Checkbox('Profiler', enabled_widgets.profiler)
    imgui.Separator()
    
    imgui.EndMainMenuBar()
  end
  
  world.debug_display_collision(grid_z, grid_scale, show_grid)
  if enabled_widgets.scene_editor then
    if imgui.Begin("Terrain solids", nil, {"ImGuiWindowFlags_MenuBar"}) then
      if (imgui.BeginMenuBar()) then
        if (imgui.MenuItem("Create")) then
            world.create_terrain(100,200,100,150,100, 500, 520)
        end
        imgui.EndMenuBar();
        for i,v in pairs(world.terrain) do
          if v then
            imgui.BeginGroup()
            
            local box_enable = imgui.CollapsingHeader('Box #' .. i)
            if box_enable then
              local delta_x, delta_y, delta_z = imgui.DragFloat3('Move', 0,0,0)
  
              imgui.Button('Free move')
              if imgui.IsItemActive() then
                delta_x, delta_y = imgui.GetMouseDragDelta()
                imgui.ResetMouseDragDelta()
              end
              v.y_near = v.y_near + delta_y
              v.y_far = v.y_far + delta_y
  
              v.x_left = v.x_left + delta_x
              v.x_right = v.x_right + delta_x
  
              v.z_left =  v.z_left + delta_z
              v.z_right = v.z_right + delta_z
              v.z_bottom = v.z_bottom + delta_z
  
              v.x_left, v.x_right =  imgui.DragFloat2('X Limits', v.x_left, v.x_right)
  
              v.z_left, v.z_right =  imgui.DragFloat2('Z Heights', v.z_left, v.z_right)
              local delta_z_top = imgui.DragFloat('Move Z Top', 0)
              v.z_left = v.z_left + delta_z_top
              v.z_right = v.z_right + delta_z_top
  
  
              v.z_bottom = imgui.DragFloat('Z Bottom', v.z_bottom)
              
              v.y_near, v.y_far = imgui.DragFloat2('Y Near/Far Planes', v.y_near, v.y_far)
              if imgui.Button('Align to grid') then
                v.x_left = round_to_grid(v.x_left)
                v.x_right = round_to_grid(v.x_right)
                v.z_left = round_to_grid(v.z_left)
                v.z_right = round_to_grid(v.z_right)
                v.z_bottom = round_to_grid(v.z_bottom)
                v.y_near = round_to_grid(v.y_near)
                v.y_far = round_to_grid(v.y_far)
              end
              v:update_kb()
              
              imgui.Button('Delete this')
              if dblClick() then
                world.terrain[i] = nil
              end
              imgui.SameLine()
              imgui.Button('Flatten')
              if dblClick() then
                local avg = (v.z_left + v.z_right) / 2
                v.z_left = avg
                v.z_right = avg
              end
              imgui.Button('Duplicate')
              if dblClick() then
                world.create_terrain(v.x_left,v.x_right, v.z_left, v.z_right, v.z_bottom, v.y_far, v.y_near)
              end
              imgui.Button('Mirror')
              if dblClick() then
                v.z_left, v.z_right = v.z_right, v.z_left
              end
              imgui.Separator()
              tagnameinput = imgui.InputText('Tag',tagnameinput, 32)
              imgui.SameLine()
              if imgui.Button('Add tag') then
                v['tag_' .. tagnameinput] = '+'
                tagnameinput = ''
              end
              for property_name, property_value in pairs(v) do
                if string.find(property_name, 'tag_') then
                  v[property_name] = imgui.InputText(property_name, property_value, 32)
                  imgui.SameLine()
                  imgui.Button('(Delete tag)')
                  if dblClick() then
                    v[property_name] = nil
                  end
                end
              end
            end
  
            
           
            

            
            imgui.Text('at ' .. v.x_left .. ', ' .. v.y_far)
            imgui.EndGroup()
            v.editor_is_hovered = imgui.IsItemHovered() or box_enable
          end
        end
      end
      imgui.End()
    end
    if imgui.Begin("Node editor") then
      for idx,node in pairs(world.nodes) do
        if imgui.CollapsingHeader(node.type .. ' ' .. idx) then
          love.graphics.push('all')
          love.graphics.setColor(1,0,0,0.3)
          love.graphics.ellipse("fill",SCREENSPACE(node.x, node.y, grid_z, grid_scale/4, grid_scale/8))
          love.graphics.setColor(1,0,0)
          love.graphics.ellipse("fill",SCREENSPACE(node.x, node.y, node.z, grid_scale/8, grid_scale/8))
          love.graphics.printf(node.type, SCREENSPACE(node.x, node.y, node.z+40, 100, "center"))
          love.graphics.pop()


          node.x, node.y, node.z = imgui.DragFloat3('Move', node.x, node.y, node.z)
          
          for idx, property_name in pairs(node_defs[node.type].fields) do
            node[property_name] = imgui.InputText(property_name, node[property_name] or '', 32)
          end
          local cross_target_z = world.ray_downwards(node.x, node.y, node.z)
          if imgui.Button('Fall down') then
            node.z = cross_target_z
          end
          imgui.Button('Delete this')
          if dblClick() then
            world.nodes[idx] = nil
          end
        end
      end
    end
    if imgui.Begin("Spawn menu") then
      for def_name,def in pairs(node_defs) do
        if imgui.Button(def_name) then
          world.create_node({
            x = 100,
            y = 100,
            z = grid_z,
            type = def_name
          })
        end
      end
    end
    if imgui.Begin("Display") then
      sr1, sg1, sb1, sa1 = imgui.ColorEdit4('Line color 1', sr1, sg1, sb1, sa1)
      sr2, sg2, sb2, sa2 = imgui.ColorEdit4('Line color 2', sr2, sg2, sb2, sa2)
      imgui.Button('Move camera')
      if imgui.IsItemActive() then
        local delta_x, delta_y = imgui.GetMouseDragDelta()
        CAMERA_X, CAMERA_Z = CAMERA_X + delta_x, CAMERA_Z - delta_y
        imgui.ResetMouseDragDelta()
      end
      show_grid = imgui.Checkbox('Show grid', show_grid)
      if show_grid then
        grid_z = imgui.DragFloat('Grid Z', grid_z)
        grid_scale = imgui.DragFloat('Grid scale', grid_scale)
        grid_scale = math.max(grid_scale, 2)
      end
    end
    if imgui.Begin("Scene properties") then
      for property_name, property_value in pairs(world.properties) do
        imgui.Text(property_name .. ' => '.. tostring(property_value))
        if type(property_value) == "string" then
          world.properties[property_name] = imgui.InputText(property_name, property_value, 64)
        end
      end
      if imgui.Button('Apply properties') then
        world.do_properties()
      end
    end
  end
  
  
  if enabled_widgets.object_inspector then
    if imgui.Begin("Object inspector") then
      for idx,object in pairs(world.objects) do
        if imgui.CollapsingHeader(object.__type .. ' ' .. object.__id) then
          ezinspector('View lua table', object)
          love.graphics.push('all')
          love.graphics.setColor(1,1,1,0.3)
          love.graphics.ellipse("fill",SCREENSPACE(object._x, object._y, grid_z, grid_scale/4, grid_scale/8))
          love.graphics.pop()
          for name,widget in pairs(object.editor_widgets) do
            if imgui.TreeNode(name) then
              widget(object)
              imgui.TreePop()
            end
          end
        end
      end
    end
  end

  if enabled_widgets.profiler then
    if imgui.Begin("Profiler") then
      if imgui.Button('Start') then
        PROFILE.start()
      end
      imgui.SameLine()
      if imgui.Button('Stop') then
        PROFILE.stop()
      end
      imgui.SameLine()
      if imgui.Button('Reset') then
        PROFILE.reset()
      end
      imgui.Text('Last dt: ' .. last_dt)
      imgui.Text('Frame count: ' .. framecount)
      imgui.Text(PROFILE.report(32))
    end
  end

  editorProfile:stop()
end



return world