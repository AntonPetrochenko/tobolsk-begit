local bomject = require 'engine.bomject'

return function (x,y,z,image,price)
  --- @class Metal: Bomject
  local new_metal = bomject 'Metal' {
    _x = x,
    _y = y,
    _z = z,
    _
  }
  
  new_metal.image = image
  new_metal.price = price
  new_metal.width = image:getWidth() / 2

  new_metal:define_state('default', {
    enter = NOP,
    update = NOP,
    draw = function (self)
      DROPSHADOW(self)
      love.graphics.draw(self.image,0,0,0,1,1,self.image:getWidth()/2, self.image:getHeight())
    end
  })

  return new_metal
end