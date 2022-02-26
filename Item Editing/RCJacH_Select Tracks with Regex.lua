--[[
    Description: Select Tracks with Regex
    Version: 1.0a
    Author: RCJacH
    Reference: 
    Changelog:
      * v1.0a (2021-05-05)
        + Initial Release.
--]]

local track_count = reaper.CountTracks(0)
if track_count == 0 then return end

local retval, regex = reaper.GetUserInputs("Search Pattern for Selecting Tracks", 1, "Lua Regex", "")
if not retval then return end



reaper.Undo_BeginBlock()

for i = 0, track_count - 1 do
  local track = reaper.GetTrack(0, i)
  local retval, name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
  local result = name:match(regex)
  reaper.SetTrackSelected(track, result ~= nil)
end

reaper.UpdateArrange()
reaper.Undo_EndBlock2(0, "Select Tracks with Regex", -1)
