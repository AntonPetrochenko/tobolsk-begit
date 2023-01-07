local uuid = require 'engine.uuid'
local cpml = require 'engine.cpml'
local imgui = require 'imgui'

GRAVITY = 10

local function nop(self, dt) end
---Scaffolds a new object from a standard lua table (first half, just sets a name)
---@param name string
---@return function
return function (name) 
  ---Scaffolds a new object from a standard lua table (first half, does the actual magic)
  ---@param default_fields any
  ---@return Bomject
  return function (default_fields)
    --- @class Bomject
    --- @field __id string
    --- @field _x number
    --- @field _y number
    --- @field _z number
    --- @field _step number
    --- @field vec3_acc table | number,
    --- @field vec3_pos table | number,
    --- @field vec3_vel table | number,
    local bomject = default_fields or {}

    bomject.layer_adjust = bomject.layer_adjust or 0

    bomject.__state_name = 'default'

    bomject.__type = name

    --- @type table <number, BomjectTimer>
    bomject.__timers = {}

    bomject.__states = {}
    bomject.__current_update_function = nop
    bomject.__current_draw_function = nop
    bomject.__common_update_function = nop
    bomject.__transforms = nop
    bomject.__common_transforms = nop

    --- @type table <string, BomjectSpriteAnimation>
    bomject.animations = {}

    bomject.vec3_pos = cpml.vec3.new(bomject._x, bomject._y, bomject._z)
    bomject.vec3_vel = cpml.vec3(0,0,0)
    bomject.vec3_acc = cpml.vec3(0,0,0)

    function bomject.update(self, dt)
      self.vec3_vel = self.vec3_vel + self.vec3_acc * dt
      self.vec3_pos = self.vec3_pos + self.vec3_vel * dt
      

      for i,timer in pairs(self.__timers) do
        if timer.active then
          timer.time = timer.time + dt
          if timer.callback and timer.time >= timer.goal then
            timer.active = false
            timer.callback(self, timer)
          end
        end
      end


            

      self:__common_update_function(dt)
      self:__current_update_function(dt)

      self._x, self._y, self._z = self.vec3_pos:unpack()
    end

    ---Make a new frame-by-frame sprite animation using bomjine timers
    ---@param self Bomject
    ---@param name string animation name
    ---@param directory string path to the animation directory WITHOUT TRAILING SLASH
    ---@param extension string file extension for frame files
    ---@param duration number how many frames to load
    ---@param frame_delay number interval between each frame
    function bomject.make_animation(self, name, directory, extension, duration, frame_delay)
      ---@class BomjectSpriteAnimation
      local new_animation = {}

      ---@type table<number, love.Image>
      new_animation.frames = {}
      for i=1,duration do
        new_animation.frames[#new_animation.frames+1] = love.graphics.newImage(directory .. '/' .. i .. '.' .. extension)
      end

      ---@param animation BomjectSpriteAnimation
      function new_animation.draw(animation, sx, sy, r)
        local sx = sx or 1
        local sy = sy or 1
        local r = r or 0
        local current_frame_image = animation.frames[animation.current_frame]
        love.graphics.draw(current_frame_image, 0, 0, r, sx, sy, current_frame_image:getWidth()/2, current_frame_image:getHeight())
      end

      new_animation.current_frame = 1

      new_animation.timer = bomject:timer({
        name = 'animation_' .. name,
        goal = frame_delay,
        ---comment
        ---@param in_self Bomject
        ---@param timer BomjectTimer
        callback = function (in_self, timer) 
          timer:reset()
          new_animation.current_frame = new_animation.current_frame + 1
          if new_animation.current_frame > #new_animation.frames then new_animation.current_frame = 1 end
        end
      })

      self.animations[name] = new_animation
      return new_animation
    end

    function bomject.draw(self)
      love.graphics.push('all')
      self:__common_transforms()
      self:__current_draw_function()
      love.graphics.pop()
    end

    function bomject.set_state(self, name)
      local new_state = self.__states[name]
      if (not new_state) then error('Bad state name [' .. name .. ']', 2) end

      if (new_state.enter) then new_state.enter(self) end
      self.__current_draw_function = new_state.draw
      self.__current_update_function = new_state.update
      self.__transforms = new_state.transforms
    end

    function bomject.define_state(self, name, state)
      state.update = state.update or error('State [' .. name .. '] is missing update function')
      state.draw = state.draw or error('State [' .. name .. '] is missing draw function')
      state.transforms = state.transforms or nop

      self.__states[name] = state

      if not self.__HAS_DEFAULT_STATE then 
        self:set_state(name) 
        self.__HAS_DEFAULT_STATE = true
      end
    end

    ---comment
    ---@param self Bomject
    ---@param in_props BomjectTimerProps
    ---@return BomjectTimer
    function bomject.timer(self, in_props)
      --- @class BomjectTimerProps
      --- @field goal number
      --- @field callback function<Bomject, BomjectTimer>
      --- @field name string
      local props = in_props or {}
      props.name = props.name or uuid()
      --- @class BomjectTimer
      local new_timer = {
        time = 0,
        active = true,
        goal = props.goal,
        callback = props.callback,
        reset = function (self_timer)
          self_timer.time = 0
          self_timer.active = true
        end,
        force = function (self_timer)
          self_timer.active = true
          self_timer.time = self_timer.goal
        end
      }
      self.__timers[props.name] = new_timer
      return new_timer
    end

    function bomject.define_common_update(self, f) self.__common_update_function = f end
    function bomject.define_common_transforms(self, f) self.__common_transforms = f end


    bomject.editor_widgets = {}
    
    function bomject.define_editor_widget(self, title, fn)
      self.editor_widgets[title] = fn
    end

    bomject:define_editor_widget('Inspect timers', function(self)
      for name, timer in pairs(self.__timers) do
        imgui.Text(name)
        if timer.goal then
          imgui.ProgressBar(timer.time/timer.goal)
          if imgui.Button('Force') then
            timer:force()
          end
          imgui.SameLine()
        else
          timer.time = imgui.DragFloat('seconds passed',timer.time)
        end
        if imgui.Button('Reset') then
          timer:reset()
        end
        
        imgui.Separator()
      end
    end)


    return bomject
  end
end