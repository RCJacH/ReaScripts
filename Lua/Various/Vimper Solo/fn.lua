-------------------------------------------------------------------------
-- This file provides the additional functions used by this script
-------------------------------------------------------------------------
local LastAction
do
  local info = debug.getinfo(1,'S');
  local base_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
  LastAction = base_path.."last_action.ini"
end

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
  RETURN = 8;
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

-- Table Functions
local fn_add, fn_hasIndex, fn_hasValue, fn_index

fn_add = function (table, value)
  -- This function adds a row of new value at the end of the table
  table[#table + 1] = value
end

fn_hasIndex = function (table, index)
  -- This function checks if an index exists in a table
  assert(type(table) == "table", "Table required for search table by index")
  assert(index, "Index required for search table by index")
  for k, _ in pairs(table) do
    if (k == index) then return true end
  end
  return false
end

fn_hasValue = function (table, value)
  -- This function checks if a value exists in a table
  assert(type(table) == "table", "Table required for search table by value")
  assert(value, "Value required for search table by value")
  for _,v in pairs(table) do
    if (v == value) then return true end
  end
  return false
end

fn_index = function (table, value)
  -- This function gets table index from a value
  assert(type(table) == "table", "Table required for search table by value")
  assert(value, "Value required for search table by value")
  for k, v in pairs(table) do
    if (v == value) then return k end
  end
  return nil
end


-- File Functions
local fn_withFile, fn_setFile, fn_readFile
local fn_getLastAction, fn_getLastGroup, fn_setLastAction

fn_withFile = function (path, mode, fn)
  local f = io.open(path, mode)
  local ret
  if f then
    ret = fn(f)
    f:close()
  end
  return ret
end

fn_writeFile = function (file, c)
  local f = io.open(file, 'w')
  f:write(c)
  f:close()
end

fn_readFile = function (file)
  local f = io.open(file, 'r')
  local ret = f and f:read('*a') or nil
  f:close()
  return ret
end

fn_getLastAction = function()
  local s, t = fn_readFile(LastAction), {}
  for v in s:gmatch"%S+" do
    fn_add(t, tostring(v))
  end
  return t
end

fn_getLastGroup = function()
  local t = fn_getLastAction()
  if #t then t[#t] = nil end
  return t
end

fn_setLastAction = function(c)
  local s =""
  if c then
    for _, v in ipairs(c) do
      s = s..v.." "
    end
  end
  fn_writeFile(LastAction, s)
end

-- Key Functions
fn_getChar = function(inChar)
  return fn_hasValue(a_MULTIBYTE, inChar) and fn_index(a_MULTIBYTE, inChar)
        or string.char(inChar)
end

fn_getKey = function(inKey)
  local i_keyByte, s_rawkey, mod
  local i_modByte = 0
  -- mod = inKey:match "[!^+]+"
  -- if mod then
  --   for w in mod:gmatch "[!^+]" do
  --     i_modByte = (w == "^" and i_modByte - 96) or
  --       (w == "!" and i_modByte + 224) or 
  --       (w == "+" and i_modByte + 32)
  --   end
  --   local start = string.len(inKey) - string.len(mod) + 1
  --   inKey = inKey:sub(start, -1)
  -- end
  i_keyByte = fn_hasIndex(a_MULTIBYTE, inKey) and a_MULTIBYTE[inKey]
         or string.byte(inKey)
  return i_keyByte + i_modByte
end


-- Groups
local a_table = {
  add                = fn_add,
  hasIndex           = fn_hasIndex,
  hasValue           = fn_hasValue,
  index              = fn_index,
}

local a_file = {
  r = fn_readFile,
  w = fn_writeFile,
  f = fn_withFile,
  getLastAction = fn_getLastAction,
  getLastGroup = fn_getLastGroup,
  setLastAction = fn_setLastAction,
}

local a_key = {
  getChar = fn_getChar,
  getKey = fn_getKey,  
}

return {
  t = a_table,
  f = a_file,
  k = a_key,
}