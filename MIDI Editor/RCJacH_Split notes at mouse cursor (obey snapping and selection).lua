--[[
  @author RCJacH
  @description Split notes at mouse cursor (obey snapping and selection)
  @link
    Github Repository https://github.com/RCJacH/ReaScript
  @version 1.1.1
  @changelog
    fix wrong note length after splitting

  @about
    Split selected notes at mouse cursor (obey snapping), if no notes are selected
    split only the note under mouse cursor, if there is no note under mouse cursor,
    split all notes.
]]

function split_no_selection(take, mouse_pos, mouse_pitch)
  local pending = {}
  local i = 0
  local retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, i)

  while retval do
    if startppqpos < mouse_pos and endppqpos > mouse_pos then
      local v = {take, selected, muted, mouse_pos, endppqpos, chan, pitch, vel, true}
      reaper.MIDI_SetNote(take, i, selected, muted, startppqpos, mouse_pos, chan, pitch, vel, true)
      if pitch == mouse_pitch then
        reaper.MIDI_InsertNote(table.unpack(v))
        return
      end
      pending[#pending + 1] = v
    end
    i = i + 1
    retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
  end

  for _, v in ipairs(pending) do
    reaper.MIDI_InsertNote(table.unpack(v))
  end
end

function split_selected(take, cur_sel_note_idx, mouse_pos)
  local pending = {}
  while cur_sel_note_idx ~= -1 do
    local retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, cur_sel_note_idx)
    if startppqpos < mouse_pos and endppqpos > mouse_pos then
      reaper.MIDI_SetNote(take, cur_sel_note_idx, selected, muted, startppqpos, mouse_pos, chan, pitch, vel, true)
      pending[#pending + 1] = {take, selected, muted, mouse_pos, endppqpos, chan, pitch, vel, true}
    end
    cur_sel_note_idx = reaper.MIDI_EnumSelNotes(take, cur_sel_note_idx)
  end

  for _, v in pairs(pending) do
    reaper.MIDI_InsertNote(table.unpack(v))
  end
end

function split(take, mouse_pos, mouse_pitch)
  local cur_sel_note_idx = reaper.MIDI_EnumSelNotes(take, -1)

  if cur_sel_note_idx == -1 then
    split_no_selection(take, mouse_pos, mouse_pitch)
  else
    split_selected(take, cur_sel_note_idx, mouse_pos)
  end

end

function main()
  local active_editor = reaper.MIDIEditor_GetActive()
  local take = reaper.MIDIEditor_GetTake(active_editor)
  local window, segment, details = reaper.BR_GetMouseCursorContext()
  
  if window ~= "midi_editor" then return end
  if segment == "piano" then return end

  local _, _, mouse_pitch, _, _, _ = reaper.BR_GetMouseCursorContext_MIDI()
  local mouse_time = reaper.BR_GetMouseCursorContext_Position()
  if reaper.MIDIEditor_GetSetting_int(active_editor, "snap_enabled") == 1 then
    mouse_time = reaper.SnapToGrid(-1, mouse_time)
  end
  local mouse_pos = reaper.MIDI_GetPPQPosFromProjTime(take, mouse_time)
  
  reaper.MIDI_DisableSort(take)
  split(take, mouse_pos, mouse_pitch)
  reaper.MIDI_Sort(take)
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
main()
reaper.PreventUIRefresh(-1)

reaper.Undo_EndBlock("Split notes at mouse cursor (obey snapping and selection)", 0)
