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

local Bindings = require ("Bindings")
local fn = require("fn")

local function Msg(str)
  reaper.ShowConsoleMsg(str.."\n")
end
-- <==== System

-- ====> Variables
-- Strings

-- Integers
local i_gui_gNameX = 25
local i_gui_gNameY = 10
local i_gui_listX = 50
local i_gui_gSz = 24
local i_gui_lSz = 18
local i_gui_font = "Calibri"
-- Booleans

-- Tables
local a_keyPressed = fn.f.getLastGroup()
local curGroup
local lastGroup = curGroup
local a_MULTIBYTE = {
  LEFT = 1818584692,
  RIGHT = 1919379572,
  UP = 30064,
  DOWN = 1685026670,
  TAB = 9,
  END = 6647396,
  HOME = 1752132965,
  PGUP = 1885828464,
  PGDN = 1885824110,
  ENTER = 13,
  SPACE = 32,
  DELETE = 6579564,
  INSERT = 6909555,
  F1 = 26161,
  F2 = 26162,
  F3 = 26163,
  F4 = 26164,
  F5 = 26165,
  F6 = 26166,
  F7 = 26167,
  F8 = 26168,
  F9 = 26169,
  F10 = 26170,
  F11 = 26171,
  F12 = 26172,
}

-- <==== Variables

-- ====> Functions
-- Private
local function fn_getCmdID(inID)
  local retID = (type(inID) == "table" and not inID.NAME) and inID[1]
    or string.sub(inID, 1 ,1) == "_" and
    reaper.NamedCommandLookup(inID) or inID
  return retID
end

local function fn_runCmd(inID, flag, proj)
  local ID = fn_getCmdID(inID)
  flag = flag or 0
  proj = proj or 0
  reaper.Main_OnCommandEx(ID, flag, proj)
end


local function fn_setting(inStr)
end

-- Checks associated commands in Bindings file.
local function fn_chkBindings()
  local i = 1
  local curLevel = Bindings
  local s, n
  while i <= #a_keyPressed do
    n = a_keyPressed[i]
    s = fn.t.hasValue(a_MULTIBYTE, n) and fn.t.index(a_MULTIBYTE, n)
        or string.char(n)
    if not curLevel[n] and not curLevel[s] then
      a_keyPressed[#a_keyPressed] = nil -- Nullify last key
      break
    end
    curLevel = curLevel[n] or curLevel[s]
    i = i + 1
  end
  return curLevel
end

local function fn_triggerCmd()
  local b_triggered
  local cmdID = fn_chkBindings()
  if type(cmdID) == "table" and cmdID.NAME then -- Group
    curGroup = cmdID
  else
    cmdID = fn_getCmdID(cmdID)
    if type(cmdID) == "number" then -- Reaper command
      fn_runCmd(cmdID)
      b_triggered = true
      fn.f.setLastAction(a_keyPressed)
    elseif type(cmdID) == "string" then -- Script setting
      fn_setting(cmdID)
    end
    a_keyPressed[#a_keyPressed] = nil
  end
  return b_triggered
end

-- GUI
local function fn_gui_draw()
  local a_keyList = {}
  -- Sort key list by their ASCII bytes
  for k, v in pairs(curGroup) do
    if k ~= "NAME" then
      local nv = fn.t.hasIndex(a_MULTIBYTE, k) and a_MULTIBYTE[k] or string.byte(k)
      fn.t.add(a_keyList, nv)
    end
  end
  table.sort(a_keyList, function(a,b) return a < b end)
  lastGroup = curGroup

  -- Draw Group Name
  gfx.x = i_gui_gNameX
  gfx.y = i_gui_gNameY
  gfx.setfont(1, i_gui_font, i_gui_gSz)
  gfx.drawstr(curGroup.NAME.."\n")

  -- Draw Group Key Lists
  gfx.y = gfx.y + i_gui_gSz
  gfx.setfont(1, i_gui_font, i_gui_lSz)
  for k, v in ipairs(a_keyList) do
    v = fn.t.hasValue(a_MULTIBYTE, v) and fn.t.index(a_MULTIBYTE, v) or string.char(v)
    if type(tonumber(v))=="number" then v = tonumber(v) end
    local n = type(curGroup[v]) == "table" and 
              (curGroup[v].NAME and curGroup[v].NAME or curGroup[v][2])
              or curGroup[v]
    gfx.x = i_gui_listX
    gfx.y = gfx.y + i_gui_lSz
    gfx.drawstr(v..": "..n.."\n")
  end
  gfx.update()
end

local GUI = {
  name = "Vimper Solo",
  x = 200,
  y = 200,
  w = 350,
  h = 500,
  draw = fn_gui_draw,
}

-- Public
curGroup = fn_chkBindings()

function Main()
  local i_keyChar
  i_keyChar = math.modf(gfx.getchar())

  -- When pressed escape or closed GUI, exit
  if i_keyChar == 27 or i_keyChar == -1 then
    if #a_keyPressed == 0 then fn.f.setLastAction() end
    return 0
  end

  -- If a keypress is detected, build a table of inputed keys
  if i_keyChar > 0 then
    if i_keyChar == 8 then -- Backspace is used to return to last menu
      a_keyPressed[#a_keyPressed] = nil
    else
      fn.t.add(a_keyPressed, i_keyChar)
    end
    if fn_triggerCmd() then return 1 end
  end

  if curGroup ~= lastGroup then fn_gui_draw() end
  reaper.defer(Main)
end
-- <==== Functions

gfx.init(GUI.name, GUI.w, GUI.h, 0, GUI.x, GUI.y)
Main()