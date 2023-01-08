local function update (node)

end

local function init (node)
  IS_GAME = false
end


return function () return
{
  update = function () end,
  init = init
}
end