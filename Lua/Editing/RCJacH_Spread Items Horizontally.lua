--[[
  ReaScript Name: Spread items horizontally
  Author: RCJacH
  Website: https://github.com/RCJacH/ReaScripts
  Version: 1.0

  Description:
  ------

]]


-- 


function main()
  reaper.Undo_BeginBlock()
  local place, pos, length
  -- Get selected item count
  num_items = reaper.CountSelectedMediaItems(0)

  -- Get base location

  -- Get selected items

  for i = 0, num_items - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    if i == 0 then
      place = pos + length
    else
      reaper.SetMediaItemPosition(item, place, false)
      place = place + length
    end
  end


  reaper.Undo_EndBlock("Spread items horizontally", -1)
end

main()
reaper.UpdateArrange()
