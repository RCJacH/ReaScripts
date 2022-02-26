--[[
    Description: Set the parent send channel offset for each of all selected tracks to a sequential stereo pair
    Version: 1.0a
    Author: RCJacH
    Reference: 
    Changelog:
      * v1.0a (2021-05-06)
        + Initial Release.
--]]

local track_count = reaper.CountSelectedTracks(0)
if not track_count or track_count == 0 then return end

assert(track_count < 32, "Only maximum of 32 tracks allowed")
reaper.Undo_BeginBlock()

local start_channel = reaper.GetMediaTrackInfo_Value(reaper.GetSelectedTrack(0, 0), "C_MAINSEND_OFFS")
for i = 0, track_count - 1 do
  reaper.SetMediaTrackInfo_Value(reaper.GetSelectedTrack(0, i), "C_MAINSEND_OFFS", start_channel + i * 2)
end

reaper.UpdateArrange()
reaper.Undo_EndBlock2(0, "Set Sequential parent Send Channel Offsets of Selected Tracks to ", -1)
