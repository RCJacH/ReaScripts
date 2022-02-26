--[[
  @author RCJacH
  @description Quick add or edit take marker under mouse cursor
  @link
    Github Repository https://github.com/RCJacH/ReaScript
  @version 1.0

  @about
    Opens the Edit Take Marker window if a take marker exists under the mouse cursor, else quick add a new one.
]]

local CMD_ADD_TAKE_MARKER = 42391
local CMD_EDIT_TAKE_MARKER = 42388

function Main()
  local item, pos = reaper.BR_ItemAtMouseCursor()
  local take = reaper.GetActiveTake(item)
  local take_marker_count = reaper.GetNumTakeMarkers(take)
  reaper.Main_OnCommand(CMD_ADD_TAKE_MARKER, 0)
  local take_marker_count_after = reaper.GetNumTakeMarkers(take)
  if take_marker_count_after == take_marker_count then
    reaper.Main_OnCommand(CMD_EDIT_TAKE_MARKER, 0)
  end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock("Quick add or edit take marker under mouse cursor", 0)
