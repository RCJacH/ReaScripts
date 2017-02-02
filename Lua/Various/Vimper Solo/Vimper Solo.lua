--[[
  ReaScript Name: Vimper Solo
  Author: RCJacH
  Website: https://github.com/RCJacH/ReaScripts
  License: GPL - http://www.gnu.org/licenses/gpl.html
  Version: 1.0
  Reference: 
    Vimper

  Description:
  ------
    This script allows user to type in a series of keys to trigger categorized
    actions.

  Instruction:
  ------
  1. Place all files in the same folder.
  2. Load and assign a key shortcut to "Vimper Solo.lua".
  3. Use default binding or change it to your liking.
    a. Create groups using lua table, and make sure to write a NAME key.
    b. Add the group to the return table with an unique key in the group.
    c. You can add infinite level of groups within groups.

    d. In each group, the key is the key you press (case sensitive).
    e. For value, you can put just a command ID or use a table with
    f. the reaper command id first, and the displaying label second.
  4. Trigger the key shortcut in reaper to load the GUI.
  5. GUI has to be in focus to detect further keyswitches.
]]

-- ====> System
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
  draw = fn_gui_draw,
}

gfx.init(GUI.name, GUI.w, GUI.h, 0, GUI.x, GUI.y)
Main(0)