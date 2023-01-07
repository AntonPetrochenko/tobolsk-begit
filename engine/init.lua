WORLD = require 'engine.world'
PROFILE = require 'engine.profile'
APPLECAKE = require("engine.applecake")(true) -- False will disable AppleCake for your project
APPLECAKE.setBuffer(true) -- Buffer data, and only send it to be saved when appleCake.flush is called
APPLECAKE.beginSession()

imgui = require 'imgui'

require 'engine.helpers'

local function nop()

end

local callbacks = {}

function love.load(arg)

  
  print('Unreal Bomjine 2')
  love.graphics.setBackgroundColor(35/255, 42/255, 50/255, 1)

  callbacks.load()

  love.window.setTitle('Unreal Bomjine 2 (' .. love.filesystem.getIdentity() .. ')' )
  print(love.filesystem.getSaveDirectory())

  
end

function love.mousemoved(x, y, dx, dy)
  imgui.MouseMoved(x, y)
  if callbacks.mousemoved then callbacks.mousemoved (x, y, dx, dy) end
end

function love.mousepressed(x, y, button, isTouch)
  imgui.MousePressed(button)
  if callbacks.mousepressed then callbacks.mousepressed(x, y, button, isTouch) end
end

function love.mousereleased(x, y, button, isTouch)
  imgui.MouseReleased(button)
  if callbacks.mousereleased then callbacks.mousereleased(x, y, button, isTouch) end
end

function love.keypressed(key, scancode, isrepeat)
  imgui.KeyPressed(key)
  if callbacks.keypressed then callbacks.keypressed(key, scancode, isrepeat) end
end

function love.keyreleased(key)
  imgui.KeyReleased(key)
  if callbacks.keyreleased then callbacks.keyreleased(key) end
end

function love.wheelmoved(x, y)
  imgui.WheelMoved(y)
  if callbacks.wheelmoved then callbacks.wheelmoved(x, y) end
end

function love.textinput(text)
  imgui.TextInput(text)
  if callbacks.textinput then callbacks.textinput(text) end
end

love.quit = function()
  if callbacks.quit then callbacks.quit() end
  APPLECAKE.endSession()
end

local profileFrame
function love.update(dt)
  profileFrame = APPLECAKE.profile('Frame', {}, profileFrame)
  imgui.NewFrame({"ImGuiConfigFlags_DockingEnable"})

  callbacks.update(dt)
end

function love.draw()
  callbacks.draw()
    
  -- -- code to render imgui
  local imguiRender = APPLECAKE.profile('Imgui rendering', {})
  imgui.Render()
  imguiRender:stop()

  profileFrame:stop()
end


return callbacks