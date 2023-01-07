function HSL(h, s, l, a)
	if s<=0 then return l,l,l,a end
	h, s, l = h*6, s, l
	local c = (1-math.abs(2*l-1))*s
	local x = (1-math.abs(h%2-1))*c
	local m,r,g,b = (l-.5*c), 0,0,0
	if h < 1     then r,g,b = c,x,0
	elseif h < 2 then r,g,b = x,c,0
	elseif h < 3 then r,g,b = 0,c,x
	elseif h < 4 then r,g,b = 0,x,c
	elseif h < 5 then r,g,b = x,0,c
	else              r,g,b = c,0,x
	end return r+m, g+m, b+m, a
end

function SIGN(number)
	return (number > 0 and 1) or (number == 0 and 0) or -1
end

function CONCAT_TABLES(t1, t2)
	for i=1,#t2 do
		 t1[#t1+1] = t2[i]
	end
	return t1
end

function NOP(...) end

function DROPSHADOW(object)
	love.graphics.push('all')
	love.graphics.setColor(0,0,0,0.5)
	local shadow_z = WORLD.ray_downwards(object.vec3_pos:unpack())
	local draw_x, draw_y = SCREENSPACE(0, 0, shadow_z - object.vec3_pos.z)
	love.graphics.ellipse("fill", draw_x, draw_y, 16, 8)
	love.graphics.pop()

end