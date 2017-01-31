-------------------------------------------------------------------------
-- This file provides the additional functions used by this script
-------------------------------------------------------------------------
local LastAction
do
  local info = debug.getinfo(1,'S');
  local base_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
  LastAction = base_path.."last_action.ini"
end


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
  for v in s:gmatch"%d+" do
    fn_add(t, v)
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
      s = s..v..","
    end
  end
  fn_writeFile(LastAction, s)
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

return {
  t = a_table,
  f = a_file,
}