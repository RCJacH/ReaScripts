--[[
    Description: Set Channel Offset of All Selected Tracks with prompt input
    Version: 1.0a
    Author: RCJacH
    Reference: 
    Changelog:
      * v1.0a (2021-05-05)
        + Initial Release.
--]]

local track_count = reaper.CountSelectedTracks(0)
if not track_count or track_count == 0 then return end

local retval, s_channel = reaper.GetUserInputs("Set Start Channel for Channel Offsets to Parent", 1, "Starting Channel", "1")
if not retval then return end

assert(tonumber(s_channel), "invalid input: " .. s_channel .. " is not a number")

local i_channel = tonumber(s_channel)

assert((i_channel > 0) and (i_channel < 64), "invalid input: " .. s_channel .. " is out of range")

reaper.Undo_BeginBlock()

for i = 0, track_count - 1 do
  reaper.SetMediaTrackInfo_Value(reaper.GetSelectedTrack(0, i), "C_MAINSEND_OFFS", i_channel - 1)
end

reaper.UpdateArrange()
reaper.Undo_EndBlock2(0, "Set Channel Offsets of Selected Tracks to " .. s_channel, -1)
