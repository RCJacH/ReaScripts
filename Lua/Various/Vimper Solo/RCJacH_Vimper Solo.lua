do
  local info = debug.getinfo(1,'S');
  local base_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
  package.path = package.path .. ";" .. base_path.. "?.lua"
end

local Main = require ("Engine")

local GUI = {
  name = "Vimper Solo",
  x = 200,
  y = 200,
  w = 500,
  h = 550,
}

gfx.init(GUI.name, GUI.w, GUI.h, 0, GUI.x, GUI.y)
Main(0)