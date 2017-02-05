-- Glue selected items preserving names
-- Author: spk77
-- Author URl: http://forum.cockos.com/member.php?u=49553
-- Source URl: https://github.com/X-Raym/REAPER-EEL-Scripts
-- Licence: GPL v3
-- Release Date: 01-02-2015
-- Forum Thread URl: http://forum.cockos.com/showthread.php?p=1470398

-- Version: 1.0
-- Version Date: 01-02-2015
-- Required : Reaper 4.76

-- Hosted by X-Raym
-- Thanks to spk77 for having succeed to do this !

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