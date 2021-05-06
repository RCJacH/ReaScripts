--[[
    Description: Setup the pin mapping of selected airwindows console summing track, with console bus as the last fx and console channel as all others.
    Version: 1.0a
    Author: RCJacH
    Reference: 
    Changelog:
      * v1.0a (2021-05-06)
        + Initial Release.
--]]

local track_count = reaper.CountSelectedTracks(0)
if not track_count or track_count == 0 then return end

local function Msg(str)
    reaper.ShowConsoleMsg(tostring(str).."\n")
end

function bitstr2int(bitstr)
  local int = 0
  for i=1, #bitstr do
    local v = bitstr:sub(i, i)
    if v == "1" then int = int + (2 ^ i) end
  end
  return int
end

function parsePinBits(bitstr)
  local lo32bits = bitstr:sub(1, 32)
  local hi32bits = bitstr:sub(33)
  return bitstr2int(lo32bits), bitstr2int(hi32bits)
end

function calcBusInputPinBits(fx_total, is_pin_even)
  local bitstr = (string.rep("00", 32 - fx_total) .. string.rep("01", fx_total)):reverse()
  return parsePinBits(bitstr)
end

function calcChannelInputPinBits(fx_i)
  local bitstr = (string.rep("00", 31 - fx_i) .. "01" .. string.rep("00", fx_i)):reverse()
  return parsePinBits(bitstr)
end

reaper.Undo_BeginBlock()

for tr_i = 0, track_count - 1 do
  local track = reaper.GetSelectedTrack(0, tr_i)
  local fx_count = reaper.TrackFX_GetCount(track)
  if fx_count then
    fx_totalx = fx_count - 1
    reaper.SetMediaTrackInfo_Value(track, "I_NCHAN", fx_totalx * 2)
    for fx_i=0, fx_totalx do
      if fx_i == fx_totalx then
        local lo32, hi32 = calcBusInputPinBits(fx_totalx)
        reaper.TrackFX_SetPinMappings(track, fx_i, 0, 0, lo32>>1, hi32>>1)
        reaper.TrackFX_SetPinMappings(track, fx_i, 0, 1, lo32, hi32)
        reaper.TrackFX_SetPinMappings(track, fx_i, 1, 0, 1, 0)
        reaper.TrackFX_SetPinMappings(track, fx_i, 1, 1, 2, 0)
      else
        local lo32, hi32 = calcChannelInputPinBits(fx_i)
        for isOutput=0, 1 do
          reaper.TrackFX_SetPinMappings(track, fx_i, isOutput, 0, lo32>>1, hi32>>1)
          reaper.TrackFX_SetPinMappings(track, fx_i, isOutput, 1, lo32, hi32)
        end
      end
    end
  end
end

reaper.UpdateArrange()
reaper.Undo_EndBlock2(0, "Set Airwindows Console trackFX Pin Mapping", -1)
