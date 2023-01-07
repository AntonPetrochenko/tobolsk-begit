local bomject = require 'engine.bomject'
local cpml = require 'engine.cpml'
local scene_manager = require 'engine.scene_manager'

return function (x,y,z,joy)
  --- @class Player: Bomject
  --- @field playerdata table
  local new_player = bomject 'Player' {
    _x = x,
    _y = y,
    _z = z,
    _step = 10
  }

  new_player.facing_left = false
  --- @type Terrain | nil
  new_player.ground = nil
  new_player.walking = false

  new_player:make_animation('walk','img/kunio/walk','png',4,0.1)
  new_player:make_animation('stand','img/kunio/stand','png',1,0.1)
  new_player:make_animation('squat','img/kunio/squat','png',1,0.1)
  new_player:make_animation('jump','img/kunio/jump','png',1,0.1)

  --- @type love.Joystick
  new_player.joy = joy

  new_player:define_state('squat', {
    enter = function (self) 
      self.vec3_acc.z = 0
      self.vec3_vel = cpml.vec3.zero()
      self:timer({
        goal = 0.3,
        name = 'squat',
        callback = function (self, timer)
          self:set_state('default')
        end
      })
    end,
    update = function (self, dt)

    end,
    draw = function (self)
      DROPSHADOW(self)
      local sx = self.facing_left and -1 or 1
      self.animations.squat:draw(sx)
    end
  })

  new_player:define_state('default', {
    ---@param self Player
    enter = function (self , argv)
      self.__timers.squat = nil
    end,
    ---@param self Player
    update = function (self, dt)

      if self.ground then
        self.vec3_pos.z = self.ground:get_z_at(self.vec3_pos.x)
        self.vec3_acc.z = 0
        self.vec3_vel.z = 0
        if not (self.vec3_pos.x > self.ground.x_left and self.vec3_pos.x < self.ground.x_right
          and self.vec3_pos.y < self.ground.y_near and self.vec3_pos.y > self.ground.y_far ) then
            self.ground = nil
            print 'no longer in aabb'
        end
      else
        self.vec3_acc.z = -800
      end

      
      local delta_x, delta_y

      if self.joy then
        self.walking = false

        delta_x, delta_y = self.joy:getGamepadAxis("leftx"), self.joy:getGamepadAxis("lefty")
        if math.abs(delta_x) < 0.3 then delta_x = 0 end
        if math.abs(delta_y) < 0.3 then delta_y = 0 else self.walking = true end
        if delta_x < -0.3 then self.walking = true self.facing_left = true end
        if delta_x > 0.3 then self.walking = true self.facing_left = false end

        if self.joy:isGamepadDown("a") and self.ground then
          self.vec3_vel.z = 300
          self.vec3_acc.z = 0
          self.ground = nil
        end

        local slope_coefficient = 1
        if self.ground then
          
          if SIGN(delta_x) == self.ground.slope_sign then
            slope_coefficient = self.ground.slope_decrease
          else
            slope_coefficient = self.ground.slope_increase
          end
        end

        self.vec3_vel.x = delta_x * 300 * slope_coefficient
        self.vec3_vel.y = delta_y * 300

        
      end

      if self.ground then
        if self.ground.tag_dirt then
          self.vec3_vel.x = self.vec3_vel.x / 2
        end
        if self.ground.tag_conveyor and tonumber(self.ground.tag_conveyor) then
          self.vec3_vel.x = self.vec3_vel.x + tonumber(self.ground.tag_conveyor)
        end
        if self.ground.tag_scene_transition then
          local metal_count = 0
          for i,v in pairs(WORLD.objects) do
            if v.__type == 'Metal' then
              metal_count = metal_count + 1
            end
          end
          if metal_count == 0 then
            scene_manager.load(self.ground.tag_scene_transition)
            for i,v in pairs(GAME) do
              print(v)
            end
          end
        end
      end

      for i,v in pairs(WORLD.objects) do
        if v.__type == 'Metal' then
          if (self.vec3_pos:dist(v.vec3_pos) < v.width) then
            self:set_state('squat')
            v:destroy()
            self.playerdata.score = self.playerdata.score + v.price
          end
        end
      end
      

      local collision_top, collision_wall = WORLD.collide(self, dt)

      if collision_top and self.vec3_vel.z < 1 then
        self.vec3_pos.z = collision_top.z

        if collision_top.vel_z < -200 then
          self:set_state('squat')
        end
        self.ground = collision_top.terrain
      end

      if collision_wall then
        -- self.vec3_pos.x = collision_wall.x
        -- self.vec3_pos.y = collision_wall.y
        if self.ground then
          self.vec3_vel.z = 0
        end
        print(self.vec3_vel.x)
      end
    end,
    ---@param self Player
    draw = function (self, dt)
      DROPSHADOW(self)
      local sx = self.facing_left and -1 or 1
      if self.walking and self.ground then
        self.animations.walk:draw(sx)
      elseif not self.ground then
        self.animations.jump:draw(sx)
      else
        self.animations.stand:draw(sx)
      end

      love.graphics.print(math.floor(self.vec3_pos.y) + math.floor(self.layer_adjust) + math.floor(self.vec3_pos.z), 0, - 128)
    end
  })

  return new_player
  
end