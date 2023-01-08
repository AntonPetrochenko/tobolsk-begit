local bomject = require 'engine.bomject'
local cpml = require 'engine.cpml'
local scene_manager = require 'engine.scene_manager'

local mud_sprite = love.graphics.newImage('img/mudpie.png')

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
      local stun_time = 0.3
      if self.ground and self.ground['tag_dirt'] then
        print('v gavno upal')
        stun_time = 1.3
      end
      print(self.ground)
      self:timer({
        goal = stun_time,
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
      if self.ground and self.ground['tag_dirt'] then
        love.graphics.draw(mud_sprite, 0,-5,0,1,1,16,32)
        love.graphics.draw(mud_sprite, -3,0,0,1,1,16,32)
        love.graphics.draw(mud_sprite, 4,0,0,1,1,16,32)
        love.graphics.draw(mud_sprite, 0,0,0,1,1,16,32)
      end
    end
  })

  local function walk_movement(self, dt)
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
  end

  local function post_collision(self, dt)
    local collision_top, collision_wall = WORLD.collide(self, dt)

    if collision_top and self.vec3_vel.z < 1 then
      self.vec3_pos.z = collision_top.z
      self.ground = collision_top.terrain
      if collision_top.vel_z < -200 then
        self:set_state('squat')
      end
      
    end

    if collision_wall then
      -- self.vec3_pos.x = collision_wall.x
      -- self.vec3_pos.y = collision_wall.y
      if self.ground then
        self.vec3_vel.z = 0
      end
      print(self.vec3_vel.x)
    end
  end

  local function pre_collision(self, dt)
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
  end

  new_player:define_state('default', {
    ---@param self Player
    enter = function (self , argv)
      self.__timers.squat = nil
    end,
    ---@param self Player
    update = function (self, dt)

      pre_collision(self, dt)

      walk_movement(self, dt)

      post_collision(self, dt)
      

      if self.ground then
        if self.ground.tag_dirt then
          self.vec3_vel.x = self.vec3_vel.x / 2
          self.vec3_vel.y = self.vec3_vel.y / 2
        end
        if self.ground.tag_conveyor and tonumber(self.ground.tag_conveyor) then
          self.vec3_vel.x = self.vec3_vel.x + tonumber(self.ground.tag_conveyor)
        end
        if self.ground.tag_scene_transition then
          local players = 0
          local players_alive = 0
          for _,_ in pairs(GAME) do
            players = players + 1
          end
          if players >= 2 then
            self:destroy()
            for _,v in pairs(GAME) do
              if v.id == self.playerdata.id then
                self.playerdata.turn = TURN
              end
            end
            TURN = TURN + 1
            for _,v in pairs(WORLD.objects) do
              if v.__type == 'Player' then
                players_alive = players_alive + 1
              end
            end
            if players_alive == 0 then
              TURN = 1
              scene_manager.load(self.ground.tag_scene_transition)
            end
          end
        end
      end

      for _,v in pairs(WORLD.objects) do
        if v.__type == 'Metal' then
          if (self.vec3_pos:dist(v.vec3_pos) < v.width) then
            self:set_state('squat')
            self.playerdata.score = self.playerdata.score + v.price
            print(self.playerdata.id,self.playerdata.score)
            v:destroy()
          end
        end
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

      if self.ground and self.ground['tag_dirt'] then
        love.graphics.draw(mud_sprite, 0,0,0,1,1,16,32)
      end
    end
  })

  return new_player
  
end