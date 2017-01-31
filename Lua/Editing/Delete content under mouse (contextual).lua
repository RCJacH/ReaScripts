--[[
  ReaScript Name: Delete Content Under Mouse (Contextual)
  Author: RCJacH
  Website: https://github.com/RCJacH/ReaScripts
  License: GPL - http://www.gnu.org/licenses/gpl.html
  Version: 1.0

  Description:
  ------
  Delete track/item/take/envelope depending on mouse position.
]]

function Main()
  reaper.Undo_BeginBlock()
  local window, segment, details
  window, segment, details = reaper.BR_GetMouseCursorContext() -- get mouse context
  if segment == "track" and not details:match('env_') then
    local track = reaper.BR_GetMouseCursorContext_Track()
    if details == "" then
      reaper.DeleteTrack(track)
    elseif details == "item" then
      local item = reaper.BR_GetMouseCursorContext_Item()
      if reaper.CountTakes(item) > 1 then
        reaper.Main_OnCommandEx(reaper.NamedCommandLookup("_BR_DELETE_TAKE_MOUSE", 0), 0, 0 )
      else
        reaper.DeleteTrackMediaItem(track, item)
      end
    end
  elseif segment == "envelope" or details:match('env_') then
    reaper.Main_OnCommandEx(reaper.NamedCommandLookup("_BR_DEL_ENV_PT_MOUSE", 0), 0, 0 )
  end
  reaper.UpdateArrange()
  reaper.Undo_EndBlock("Delete contextual content under mouse", 0)
end
Main()
