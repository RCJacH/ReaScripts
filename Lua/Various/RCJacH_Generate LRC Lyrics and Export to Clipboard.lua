--[[
  @author RCJacH
  @description Generate LRC Lyrics and Export to Clipboard
  @about
    # What Does This Do

    This script generates the lyrics in [LRC](https://en.wikipedia.org/wiki/LRC_(file_format)) format
    from the take name of all items on the first selected track,
    and export the result to the system clipboard.
    - Take name starting with # is cosidered as ID tag.
    - Empty take name is rendered with only time code, usually for spacing purposes.
  @link
    Github Repository https://github.com/RCJacH/ReaScripts
  @version 1.0
]]--

function format_time(seconds)
  local minus, mm, ss, xx
  mm = math.floor(seconds / 60)
  ss = seconds % 60
  ss, xx = tostring(ss):match('[?]-(%d+).(%d*)')
  return string.format("[%02d:%02s.%s]", mm, ss, xx:sub(1, 2))
end

reaper.PreventUIRefresh(1)
track = reaper.GetSelectedTrack(0, 0)
itemsCount = reaper.CountTrackMediaItems(track)
lyrics = ""
for itemidx = 0, itemsCount - 1, 1 do
  local item, location, take
  --, takeName, time
  --, title, content
  item = reaper.GetTrackMediaItem(track, itemidx)
  location = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  take = reaper.GetActiveTake(item)
  takeName = reaper.GetTakeName(take)
  title, content = takeName:match("^(#*)(.*)")
  if title == "" then
    content = format_time(location) .. content
  else
    content = "[" .. content .. "]"
  end
  lyrics = lyrics .. content .. "\n"
end
reaper.CF_SetClipboard(lyrics)
lyrics = "The following lyrics has been copied to the system clipboard:\n\n" .. lyrics
reaper.ShowMessageBox(lyrics, "Lyrics", 0)
reaper.PreventUIRefresh(-1)
