--[[
  ReaScript Name: Glue selected items preserving first item name
  Author: RCJacH
  Link: https://github.com/RCJacH/ReaScripts
  Version: 1.0
  About:
    Glue selected items, and rename result to:
    1.The name of the first item If all item names are identical;
    2.The name of each nonidentical items.
    3.Remove the "Glued" in item name (but not the file name unfortunately)
]]

-- Licensed under the GNU GPL - http://www.gnu.org/licenses/gpl.html

function merge_track_take_names(track_pointer, apply_to_first_take) 
  local first_take, item, take, take_name, b_exist
  local merged_name = ""
  local a_names = {}
  if track_pointer then
    for i = 0, reaper.CountTrackMediaItems(track_pointer) do
      item = reaper.GetTrackMediaItem(track_pointer, i)
      if item then
        if reaper.IsMediaItemSelected(item) then
          take = reaper.GetActiveTake(item)
          if take then
            take_name = reaper.GetTakeName(take)
            if #a_names > 0 then
              b_exist = false
              for k, v in ipairs(a_names) do
                b_exist = take_name == v and true
              end
              if not b_exist then
                a_names[#a_names + 1] = take_name
              end
            else
              first_take = take
              a_names[#a_names + 1] = take_name
            end
          end
        end
      end
    end
  end
  -- apply merged_name to first selected item in track (if "apply_to_first_take" is 1)
  if #a_names > 0 then
    merged_name = table.concat(a_names, " + ")
    reaper.GetSetMediaItemTakeInfo_String(first_take, "P_NAME", merged_name, 1)
  end
  return merged_name
end


-- This function applies "merged take names" to the first takes of tracks
-- 
function glue()
  local merged_name, item, take, take_name, source, filenamebuf
  reaper.Undo_BeginBlock()
  for i = 0, reaper.CountTracks(0) do
    merged_name = merge_track_take_names(reaper.GetTrack(0, i), 1)
  end
  
  -- GLUE ITEMS WITHOUT TIME SELECTION
  reaper.Main_OnCommand(40362, 0)
  
  -- remove "glued" string from take names
  for i = 0, reaper.CountSelectedMediaItems(0) do
    item = reaper.GetSelectedMediaItem(0, i)
    if item then
      take = reaper.GetActiveTake(item)
      if take then
        take_name = reaper.GetTakeName(take)
        if take_name:match(".glued") then
          reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", take_name:gsub(".glued",""), 1)
        end
      end
    end
  end
  reaper.Undo_EndBlock("Glue Named", -1)
end

glue()