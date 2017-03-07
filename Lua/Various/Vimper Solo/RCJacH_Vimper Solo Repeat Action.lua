--[[
  This script is part of Vimper Solo Package
  NoIndex: true
--]]

do
  local info = debug.getinfo(1,'S');
  local base_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
  package.path = package.path .. ";" .. base_path.. "?.lua"
end

local Main = require ("Engine")

Main(1)