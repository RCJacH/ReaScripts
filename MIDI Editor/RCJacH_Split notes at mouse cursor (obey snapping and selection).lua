--[[
  @author RCJacH
  @description Split notes at mouse cursor (obey snapping and selection)
  @link
    Github Repository https://github.com/RCJacH/ReaScript
  @version 1.2.1
  @changelog
    fix unmodified origin note length when splitting a hovered unselected note

  @about
    Split selected notes at mouse cursor (obey snapping), if no notes are selected
    split only the note under mouse cursor, if there is no note under mouse cursor,
    split all notes.
]]


function split_no_selection(take, mouse_pos, mouse_pitch)
  local pending_insert = {}
  local pending_set = {}
  local i = 0
  local retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, i)

  while retval do
    if startppqpos < mouse_pos and endppqpos > mouse_pos then
      local v = {selected, muted, mouse_pos, endppqpos, chan, pitch, vel, true}
      if pitch == mouse_pitch then
        reaper.MIDI_SetNote(take, i, selected, muted, startppqpos, mouse_pos, chan, pitch, vel, true)
        reaper.MIDI_InsertNote(take, table.unpack(v))
        return
      end
      pending_set[#pending_set + 1] = {i, selected, muted, startppqpos, mouse_pos, chan, pitch, vel, true}
      pending_insert[#pending_insert + 1] = v
    end
    i = i + 1
    retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
  end

  for _, v in ipairs(pending_set) do
    reaper.MIDI_SetNote(take, table.unpack(v))
  end

  for _, v in ipairs(pending_insert) do
    reaper.MIDI_InsertNote(take, table.unpack(v))
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
  local window, segment, details = reaper.BR_GetMouseCursorContext()
  
  if window ~= "midi_editor" then return end
  if segment == "piano" then return end

  local editor, _, mouse_pitch, _, _, _ = reaper.BR_GetMouseCursorContext_MIDI()
  local take = reaper.MIDIEditor_GetTake(editor)
  local mouse_time = reaper.BR_GetMouseCursorContext_Position()
  local mouse_pos
  if reaper.MIDIEditor_GetSetting_int(editor, "snap_enabled") == 1 then
    local grid_size, swing = reaper.MIDI_GetGrid(take)
    local base_grid_size = grid_size * 2
    local _, _, _, fullbeats, _ = reaper.TimeMap2_timeToBeats(-1, mouse_time)
    local beat, frac = math.modf(fullbeats)
    local grid, frac = math.modf(frac / base_grid_size)
    local split_point = 0.5 + 0.25 * swing
    local diff = frac - split_point
    if diff < 0 then
      frac = math.abs(diff) < split_point / 2 and split_point or 0
    else
      frac = diff > (1 - split_point) / 2 and 1 or split_point
    end
    mouse_pos = reaper.MIDI_GetPPQPosFromProjQN(take, beat + (grid + frac) * base_grid_size)
  else
    mouse_pos = reaper.MIDI_GetPPQPosFromProjTime(take, mouse_time)
  end

  reaper.MIDI_DisableSort(take)
  split(take, mouse_pos, mouse_pitch)
  reaper.MIDI_Sort(take)
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
main()
reaper.PreventUIRefresh(-1)

reaper.Undo_EndBlock("Split notes at mouse cursor (obey snapping and selection)", 0)
