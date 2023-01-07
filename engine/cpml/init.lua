--[[
-------------------------------------------------------------------------------
-- @author Colby Klein
-- @author Landon Manning
-- @copyright 2016
-- @license MIT/X11
-------------------------------------------------------------------------------
                  .'@@@@@@@@@@@@@@#:
              ,@@@@#;            .'@@@@+
           ,@@@'                      .@@@#
         +@@+            ....            .@@@
       ;@@;         '@@@@@@@@@@@@.          @@@
      @@#         @@@@@@@@++@@@@@@@;         `@@;
    .@@`         @@@@@#        #@@@@@          @@@
   `@@          @@@@@` Cirno's  `@@@@#          +@@
   @@          `@@@@@  Perfect   @@@@@           @@+
  @@+          ;@@@@+   Math     +@@@@+           @@
  @@           `@@@@@  Library   @@@@@@           #@'
 `@@            @@@@@@          @@@@@@@           `@@
 :@@             #@@@@@@.    .@@@@@@@@@            @@
 .@@               #@@@@@@@@@@@@;;@@@@@            @@
  @@                  .;+@@#'.   ;@@@@@           :@@
  @@`                            +@@@@+           @@.
  ,@@                            @@@@@           .@@
   @@#          ;;;;;.          `@@@@@           @@
    @@+         .@@@@@          @@@@@           @@`
     #@@         '@@@@@#`    ;@@@@@@          ;@@
      .@@'         @@@@@@@@@@@@@@@           @@#
        +@@'          '@@@@@@@;            @@@
          '@@@`                         '@@@
             #@@@;                  .@@@@:
                :@@@@@@@++;;;+#@@@@@@+`
                      .;'+++++;.

Loading routine modified by CardboardBox so it would behave better with our engine
--]]
local modules = (...) and (...):gsub('%.init$', '') .. ".modules." or ""

local cpml = {
	_LICENSE = "engine.cpml is distributed under the terms of the MIT license. See LICENSE.md.",
	_URL = "https://github.com/excessive/cpml",
	_VERSION = "1.2.9",
	_DESCRIPTION = "Cirno's Perfect Math Library: Just about everything you need for 3D games. Hopefully."
}


cpml["bvh"] = require "engine.cpml.modules.bvh"
cpml["color"] = require "engine.cpml.modules.color"
cpml["constants"] = require "engine.cpml.modules.constants"
cpml["intersect"] = require "engine.cpml.modules.intersect"
cpml["mat4"] = require "engine.cpml.modules.mat4"
cpml["mesh"] = require "engine.cpml.modules.mesh"
cpml["octree"] = require "engine.cpml.modules.octree"
cpml["quat"] = require "engine.cpml.modules.quat"
cpml["simplex"] = require "engine.cpml.modules.simplex"
cpml["utils"] = require "engine.cpml.modules.utils"
cpml["vec2"] = require "engine.cpml.modules.vec2"
cpml["vec3"] = require "engine.cpml.modules.vec3"
cpml["bound2"] = require "engine.cpml.modules.bound2"
cpml["bound3"] = require "engine.cpml.modules.bound3"


-- for _, file in ipairs(files) do
-- 	cpml[file] = require(modules .. file)
-- end

return cpml
