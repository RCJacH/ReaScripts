--[[
  @author RCJacH
  @description Split items under mouse (obey snapping and selection)
  @link
    Github Repository https://github.com/RCJacH/ReaScript
  @version 1.0

  @about
    Split selected items at mouse cursor (obey snapping), if no items are selected
    split only the item under mouse cursor, if there is no item under mouse cursor,
    split all items with confirmation.
]]

local CMD_SPLIT_SELECTED_ITEM = reaper.NamedCommandLookup("_S&M_SPLIT10")


function split_all_items(cursor_pos)
  local item_count = reaper.CountMediaItems(-1)
  reaper.Main_OnCommand(40513, 0)
  local confirm = reaper.ShowMessageBox("WARNING: This will split all items at mouse position!", "SPLIT ALL ITEMS?", 1)
  if confirm == 1 then
    reaper.Main_OnCommand(40757, 0)
  end
end

function split_item_under_mouse(item, cursor_pos)
  reaper.SetMediaItemSelected(item, true)
  reaper.Main_OnCommand(CMD_SPLIT_SELECTED_ITEM, 0)
  reaper.SetMediaItemSelected(item, false)
  reaper.SetMediaItemSelected(reaper.GetSelectedMediaItem(-1, 0), false)
end

function split_item(cursor_pos)
  local item, pos
  local screen_x, screen_y = reaper.GetMousePosition()
  local sel_item_count = reaper.CountSelectedMediaItems(-1)

  item, pos = reaper.BR_ItemAtMouseCursor()
  if sel_item_count > 0 then 
    if reaper.IsMediaItemSelected(item) then
      reaper.Main_OnCommand(CMD_SPLIT_SELECTED_ITEM, 0)
    end
    return
  end

  if not item then
    item = reaper.GetItemFromPoint(screen_x, screen_y, true)
  end
  if not item then
    split_all_items(cursor_pos)
    return
  end

  split_item_under_mouse(item, cursor_pos)
end

function Main()
  local cursor_pos = reaper.GetCursorPosition()
  split_item(cursor_pos)
  reaper.SetEditCurPos(cursor_pos, 0, 0)
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock("Split items under mouse (obey snapping and selection", 0)
