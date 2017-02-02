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
local i_backKey = 8
-- Booleans

-- Tables
local a_keyPressed
local curGroup
local lastGroup


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
  local i, curLevel = 1, Bindings
  local s, n
  while i <= #a_keyPressed do
    n = a_keyPressed[i]
    if not curLevel[n] then
      a_keyPressed[#a_keyPressed] = nil -- Nullify last key
      break
    end
    curLevel = curLevel[n]
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
local function fn_gui_draw(inGroup)
  local a_keyList = {}
  -- Sort key list by their ASCII bytes
  for k, v in pairs(inGroup) do
    if k ~= "NAME" then
      local nv = fn.k.getKey(k)
      fn.t.add(a_keyList, {nv, k})
    end
  end
  table.sort(a_keyList, function(a,b) return a[1] < b[1] end)
  lastGroup = inGroup

  -- Draw Group Name
  gfx.x = i_gui_gNameX
  gfx.y = i_gui_gNameY
  gfx.setfont(1, i_gui_font, i_gui_gSz)
  gfx.drawstr(inGroup.NAME.."\n")

  -- Draw Group Key Lists
  gfx.y = gfx.y + i_gui_gSz
  gfx.setfont(1, i_gui_font, i_gui_lSz)
  for k, v in ipairs(a_keyList) do
    v = v[2]
    local n = type(inGroup[v]) == "table" and 
              (inGroup[v].NAME and inGroup[v].NAME or inGroup[v][2])
              or inGroup[v]
    gfx.x = i_gui_listX
    gfx.y = gfx.y + i_gui_lSz
    gfx.drawstr(v..": "..n.."\n")
  end
  gfx.update()
end

-- Public

function Main(isRepeat)
  -- Variable localization
  local i_keyChar, s_keyChar
  -- Input properties initialization
  isRepeat = isRepeat or 0
  if isRepeat == 1 then
    a_keyPressed = fn.f.getLastAction()
    fn_triggerCmd()
    return 1
  else
    a_keyPressed = a_keyPressed or fn.f.getLastGroup()
    curGroup = curGroup or fn_chkBindings()
  end
  i_keyChar = math.modf(gfx.getchar())

  -- When pressed escape or closed GUI, exit
  if i_keyChar == 27 or i_keyChar == -1 then
    if #a_keyPressed == 0 then fn.f.setLastAction() end
    return 0
  end

  -- If a keypress is detected, build a table of inputed keys
  if i_keyChar ~= 0 then
    if i_keyChar == i_backKey then -- Backspace is used to return to last menu
      a_keyPressed[#a_keyPressed] = nil
    else
      s_keyChar = fn.k.getChar(i_keyChar)
      fn.t.add(a_keyPressed, s_keyChar)
    end
    if fn_triggerCmd() then return 1 end
  end

  if curGroup ~= lastGroup then fn_gui_draw(curGroup) end
  reaper.defer(Main)
end
-- <==== Functions

return Main;
