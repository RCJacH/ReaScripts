--[[
Author: RCJacH
Description: Humanize MIDI notes
About:
  Humanize selected notes, or all notes if none selected, in the active
  MIDI editor, based on how a player would, i.e. timing and velocity
  drifting based on 1/f noise, and realizing that drift and trying
  to compensate. This script also keeps legato or non-legato between notes.
  Plus, timing variation is based on the current grid setting, it mimics
  how a player feels the subdivision while playing.

  Parameters:
    Experience:
      A more experienced player drifts less and makes less over-compensation.
    Tightness:
      Tighter means putting more effort to compensate when drift happens.
Links:
  Github Repository https://github.com/RCJacH/ReaScript
Version: 0.1
Changelog:
 * v0.1 (2023-04-22)
  + Initial release
--]]

-------------------------------------
-- Global
-------------------------------------

local PLUGIN_NAME = "MIDI Humanizer"

if not reaper.CF_GetSWSVersion then
  reaper.ShowConsoleMsg("SWS extension required to get closest grid.")
end

if not reaper.JS_ReaScriptAPI_Version then
  reaper.ShowConsoleMsg("js_ReaScriptAPI extension required to remove window frames.\n")
end

-------------------------------------
-- Debug
-------------------------------------

DEBUG = false
function dbg(...)
  if DEBUG == true then
    local s = ''
    for _, v in pairs({...}) do
      s = s .. ' ' .. tostring(v)
    end
    reaper.ShowConsoleMsg(s .. '\n')
  end
end

-------------------------------------
-- Note
-------------------------------------
local Note = {}
Note.__index = Note

function Note.new(take, noteidx)
    local retval, _, _, startppqpos, endppqpos, _, pitch, velocity = reaper.MIDI_GetNote(take, noteidx)
    local self = {
      take = take,
      noteidx = noteidx,
      startppqpos = startppqpos,
      endppqpos = endppqpos,
      pitch = pitch,
      velocity = velocity
    }
    setmetatable(self, Note)
    return self
end

function Note:set()
  reaper.MIDI_SetNote(
    self.take,
    self.noteidx,
    nil,
    nil,
    self.startppqpos,
    self.endppqpos,
    nil,
    self.pitch,
    self.velocity,
    true
  )
end

function Note:start_qn()
  return reaper.MIDI_GetProjQNFromPPQPos(self.take, self.startppqpos)
end

function Note:end_qn()
  return reaper.MIDI_GetProjQNFromPPQPos(self.take, self.endppqpos)
end

function Note:nearest_start_grid()
  return reaper.MIDI_GetProjQNFromPPQPos(
    self.take,
    reaper.BR_GetClosestGridDivision(self.startppqpos)
  )
end

-------------------------------------
-- White Noise
-------------------------------------

local WhiteNoise = {}
WhiteNoise.__index = WhiteNoise

function WhiteNoise.new(max_octaves, seed)
  math.randomseed(seed or os.time())
  local self = {
    octaves = {},
    max_octaves = max_octaves or 16,
  }
  for i=0, self.max_octaves do
    self.octaves[i] = 0
  end

  setmetatable(self, WhiteNoise)
  return self
end

function WhiteNoise.generate()
  return math.random() * 2 - 1
end

function WhiteNoise:update(index)
  for octave = 1, self.max_octaves do
    if index % (1 << (octave - 1)) == 0 then
      self.octaves[octave] = self.generate()
    end
  end
end

local PinkNoise = {}
PinkNoise.__index = PinkNoise

function PinkNoise.new(...)
  local self = {
    white_noise = WhiteNoise.new(...),
    current_sample = 0,
    index = 0
  }
  setmetatable(self, PinkNoise)
  return self
end

function PinkNoise:next_sample()
  self.index = self.index + 1
  self.white_noise:update(self.index)
  local max_octaves = self.white_noise.max_octaves
  local sample = 0
  for octave = 1, max_octaves do
    sample = sample + self.white_noise.octaves[octave]
  end
  self.current_sample = sample / max_octaves
  return self.current_sample
end

-------------------------------------
-- Interpolation
-------------------------------------

local easing = {}
easing.__index = easing

function easing.cosine(x, v)
  return (0.5 * (1 - math.cos(x ^ v * math.pi)))
end

function easing.sigmoid(x, v)
  return 1 / (1 + math.exp(-10 * x ^ v + 5))
end

function easing.hermite(x, v)
  return 1 - (x ^ 2 * (2 * x - 3) + 1) ^ (1 / v) * math.sin(0.5 * math.pi)
end

function easing.equally_distributed(x, f, v, c)
  v = v or 1
  c = c or 0.5

  if x <= c then
    if c < 0.5 then
      x = (x + (1 - 2 * c)) / (1 - c)
    else
      x = x / c
    end
    return f(x, v)
  else
    if c > 0.5 then
      x = 1 - (x - c) / c
    else
      x = 1 - (x - c) / (1 - c)
    end
    return f(x, v)
  end
end

-------------------------------------
-- Player
-------------------------------------

local Player = {}
Player.__index = Player

function Player.new(take)
  local note_placeholder = Note.new(take, -1)
  note_placeholder.startppqpos = 0.0
  note_placeholder.endppqpos = 0.0

  local self = {
    experience = 0.5,
    rev_exp = 0.5,
    tightness = 0.5,
    chord_threshold = 20,
    noise = PinkNoise.new(),
    beat_emphasis = 0.8,
    lastnote = note_placeholder,
    effort = {
      timing = 0,
      velocity = 0,
    },
    drift = {
      timing = 0,
      velocity = 0,
    },
    offset = {
      timing = 0,
      velocity = 0,
    }
  }
  setmetatable(self, Player)
  return self
end

function Player:set_experience(experience)
  self.experience = experience
  self.rev_exp = 1 - experience
end

function Player:set_tightness(tightness)
  self.tightness = tightness
end

function Player:get_emphasis(measure_start_qn, beat_qn, grid_qn)
  local emphasis = beat_qn == measure_start_qn and 4 or beat_qn == grid_qn and 2 or 1

  if emphasis > 1 then
    emphasis = emphasis * self.beat_emphasis
  end

  return 1 / emphasis
end

function Player:update_status(emphasis)
  self:update_effort(emphasis)
  self:update_drift(emphasis)
end

function Player:update_effort(emphasis)
  local do_drift_timing = math.abs(self.drift.timing) > 0.1 * self.rev_exp
  local do_drift_velocity = math.abs(self.drift.velocity) > 0.1 * self.rev_exp
  local timing_compensation = do_drift_timing and self.drift.timing * -self:get_random_effort(emphasis, true) or 0
  local velocity_compensation = do_drift_velocity and self.drift.velocity * -self:get_random_effort(emphasis, true) or 0

  local side_effect_timing = do_drift_velocity and velocity_compensation * self:get_random_effort(emphasis, false) ^ 2 * 0.25 or 0
  local side_effect_velocity = do_drift_timing and timing_compensation * self:get_random_effort(emphasis, false) ^ 2 * 0.25 or 0

  dbg("compensations: t", timing_compensation, '|', side_effect_timing, '|v', velocity_compensation, '|', side_effect_velocity)

  self.effort.timing = timing_compensation + side_effect_timing
  self.effort.velocity = velocity_compensation + side_effect_velocity

  dbg("effort:", self.effort.timing, '|', self.effort.velocity)
end

function Player:get_random_effort(emphasis, may_overshoot)
  local overshoot = may_overshoot and 0.125 * self.rev_exp ^ (0.8 / emphasis) or 0
  local effort = easing.equally_distributed(math.random(), easing.cosine, 2 ^ (2 * (self.tightness - 0.5)), 0)
  effort = 1 - effort * (1 + overshoot)
  effort = effort < 0 and 1 + -effort or effort
  return effort
end

function Player:update_drift(emphasis)
  local controlled_noise = self:get_controlled_noise_sample()
  dbg("controlled_noise:", controlled_noise)
  local compensation_factor = 1 - (self.effort.timing and 0.75 or 0.5) * self.experience
  self.drift.timing = self.drift.timing + self.effort.timing + controlled_noise * emphasis * compensation_factor

  compensation_factor = 1 - (self.effort.velocity and 0.75 or 0.5) * self.experience
  self.drift.velocity = self.drift.velocity + self.effort.velocity + controlled_noise * emphasis * compensation_factor

  dbg("drift:", self.drift.timing, '|', self.drift.velocity)

end

function Player:get_controlled_noise_sample()
  local noise_sample = self.noise:next_sample()
  return noise_sample
end

-------------------------------------
-- Process
-------------------------------------
local Process = {}
Process.__index = Process

function Process.new()
  local editor = reaper.MIDIEditor_GetActive()
  if not editor then return end

  local take = reaper.MIDIEditor_GetTake(editor)
  if not take then return end

  local retval, note_count = reaper.MIDI_CountEvts(take)
  if not retval or not note_count then return end

  local self = {
    take = take,
    noteidx = -1,
    note_count = note_count,
    query = {},
  }

  setmetatable(self, Process)
  return self
end

function Process:call(player)
	reaper.PreventUIRefresh(1)
  self.player = player
  reaper.MIDI_DisableSort(self.take)
  local cnt = 0
  while true do
    self.noteidx = reaper.MIDI_EnumSelNotes(self.take, self.noteidx)
    if self.noteidx == -1 then break end
    self:iterating_sel_notes()
    cnt = cnt + 1
  end
  if cnt == 0 then
    for i = 0, self.note_count - 1 do
      self.noteidx = i
      self:iterating_sel_notes()
    end
  end
  reaper.MIDI_Sort(self.take)
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
  reaper.Undo_OnStateChange(PLUGIN_NAME)
end

function Process:iterating_sel_notes()
  local note = Note.new(self.take, self.noteidx)
  if #self.query == 0 then
    self.query[#self.query + 1] = note
    return
  end

  local lastnote = self.query[#self.query]
  if math.abs(note.startppqpos - lastnote.startppqpos) <= self.player.chord_threshold then
    self.query[#self.query + 1] = note
    return
  end

  self:process_query()
  self.player.lastnote = lastnote
  self.query = { note }
end

function Process:process_query()
  local first_note = self.query[1]
  local first_note_start_qn = first_note:start_qn()
  local beat_qn, offbeat_qn = math.modf(first_note_start_qn + 0.5)
  local grid_qn = first_note:nearest_start_grid()
  local retval, measure_start_qn, _ = reaper.TimeMap_QNToMeasures(-1, beat_qn)
  local emphasis = self.player:get_emphasis(measure_start_qn, beat_qn, grid_qn)

  self.player:update_status(emphasis)

  local timing_offset, vel_offset
  for _, note in ipairs(self.query) do
    timing_offset, vel_offset = self:process_note(note)
  end

  self.player.offset.timing = timing_offset
  self.player.offset.velocity = vel_offset
end

function Process:process_note(note)
  local lastnote = self.player.lastnote

  local was_legato = note.startppqpos < lastnote.endppqpos
  local grid_size, swing = reaper.MIDI_GetGrid(note.take)

  local raw_startppqpos = note.startppqpos
  local raw_velocity = note.velocity
  local raw_start_qn = note:start_qn()
  local new_start_qn = self:apply_start_qn_modulation(note:start_qn(), grid_size)
  note.startppqpos = reaper.MIDI_GetPPQPosFromProjQN(note.take, new_start_qn)

  local timing_diff = note.startppqpos - raw_startppqpos
  local is_now_legato = lastnote.endppqpos > note.startppqpos
  if (was_legato and not is_now_legato) or (not was_legato and is_now_legato) then
    lastnote.endppqpos = lastnote.endppqpos + timing_diff
    lastnote:set()
  end

  note.velocity = self:apply_velocity_modulation(note.velocity)
  note:set()

  return new_start_qn - raw_start_qn, note.velocity - raw_velocity
end

function Process:apply_start_qn_modulation(start_qn, grid_size)
  return start_qn + grid_size * -self.player.drift.timing
end

function Process:apply_velocity_modulation(velocity)
  local limit = 64
  local new_velocity = velocity + limit * self.player.drift.velocity
  new_velocity = math.max(1, math.min(new_velocity, 127))
  return math.floor(new_velocity)
end

-------------------------------------
-- GUI
-------------------------------------

local GUI = {}
GUI.__index = GUI

function GUI.new(grid_size, x_label, y_label)
  grid_size = grid_size or 160
  local x, y = reaper.GetMousePosition()
  local font_size = math.floor(grid_size / 10)
  local min_line_width = math.max(font_size / 16, 1)
  local w = grid_size + font_size * 1.5
  local h = grid_size + font_size * 1.5
  x = x - w * 0.5
  y = y - h * 0.5
  gfx.setfont(1, "Arial", font_size)
  gfx.init(PLUGIN_NAME, w, h, 0, x, y)
  local hwnd = reaper.JS_Window_Find(PLUGIN_NAME, true)
  if hwnd then
    local WS_POPUP = 0x80000000
    local WS_VISIBLE = 0x10000000
    local style = WS_POPUP | WS_VISIBLE
    reaper.JS_Window_SetStyle(hwnd, style)
  end
  local _, left, top, right, bottom = reaper.JS_Window_GetRect(hwnd)
  local self = {
    hwnd = hwnd,
    w = right - left,
    h = math.abs(bottom - top),
    gx = font_size * 1.5,
    gy = font_size * 2,
    grid_size = grid_size,
    font_size = font_size,
    x_label = x_label,
    y_label = y_label,
    left_mouse = 0,
    min_line_width = min_line_width,
  }
  setmetatable(self, GUI)
  return self
end

-- Check if the mouse is inside the button
function GUI:is_mouse_inside_grid()
  local mx = gfx.mouse_x
  local my = gfx.mouse_y
  return (
    mx >= self.gx
    and mx <= self.gx + self.grid_size
    and my >= self.gy
    and my <= self.gy + self.grid_size
  )
end

function GUI:mouse_position_in_grid()
  local mx = gfx.mouse_x
  local my = gfx.mouse_y
  local gx = self.gx
  local gy = self.gy
  local grid_size = self.grid_size
  return (mx - gx) / grid_size, 1 - (my - gy) / grid_size
end

function GUI:draw_grid()
  local x = self.gx
  local y = self.gy
  local full_grid = self.grid_size
  local half_grid = full_grid * 0.5
  gfx.set(0.298039, 0.337255, 0.415686, 1)
  for i = 1, self.min_line_width * 3 do
    gfx.rect(x - i, y - i, full_grid + i * 2, full_grid + i * 2, 0)
  end
  gfx.set(0.298039, 0.337255, 0.415686, 0.5)
  for i = 1, self.min_line_width * 2 do
    local sign = i % 2 and -1 or 1
    local j = i // 2
    gfx.line(x, y + half_grid + sign * j, x + full_grid, y + half_grid + sign * j)
    gfx.line(x + half_grid + sign * j, y, x + half_grid + sign * j, y + full_grid)
  end

  -- Display current value
  local mx = gfx.mouse_x
  local my = gfx.mouse_y
  local x, y = self:mouse_position_in_grid()
  if x < 0 or x > 1 or y < 0 or y > 1 then return end

  local str = string.format("(%.2f, %.2f)", x, y)
  local str_len = gfx.measurestr(str)
  local my_grid = y * self.grid_size
  local font_size = self.font_size
  if my_grid < font_size then
    gfx.x = mx - str_len / 2
    gfx.y = my - font_size
  elseif (self.grid_size - my_grid) < font_size then
    gfx.x = mx - str_len / 2
    gfx.y = my + font_size
  elseif x <= 0.5 then
    gfx.x = mx
    gfx.y = my - font_size / 2
  else
    gfx.x = mx - str_len
    gfx.y = my - font_size / 2
  end
  gfx.set(0.847059, 0.870588, 0.913725, 1)
  gfx.drawstr(str)
end

function GUI:draw_axes_labels()
  gfx.set(0.847059, 0.870588, 0.913725, 1)
  gfx.x, gfx.y = (gfx.w - gfx.measurestr(self.x_label)) / 2, gfx.h - self.font_size * 1.5
  gfx.drawstr(self.x_label)

  gfx.y = (gfx.h - #self.y_label * self.font_size * 0.75) / 2
  for i = 1, #self.y_label do
    local char = self.y_label:byte(i)
    local char_w = gfx.measurechar(char)
    gfx.x = self.font_size * 0.7 - char_w / 2
    gfx.drawchar(char)
    gfx.y = gfx.y + self.font_size * 0.7
  end
end

function GUI:draw()
  gfx.set(0.180392, 0.203922, 0.25098, 1)
  gfx.rect(0, 0, self.w, self.h)
  gfx.set(0.505882, 0.631373, 0.756863, 1)
  gfx.x, gfx.y = (gfx.w - gfx.measurestr(PLUGIN_NAME)) / 2, self.font_size * 0.5
  gfx.drawstr(PLUGIN_NAME)
  self:draw_axes_labels()
  self:draw_grid()

  local key = gfx.getchar()
  if key == 27 then
    return -1
  end

  local mouse_clicked = gfx.mouse_cap&1 == 1
  if mouse_clicked then
    if self.left_mouse ~= -1 and self:is_mouse_inside_grid() then
      self.left_mouse = 1
    else
      self.left_mouse = -1
    end
  else
    if self.left_mouse == 1 and self:is_mouse_inside_grid() then
      return 1, self:mouse_position_in_grid()
    end
    self.left_mouse = 0
  end

  gfx.update()
  return 0
end

-------------------------------------
-- Main
-------------------------------------

local function main()
  local window = reaper.JS_Window_GetForeground()
  local process = Process.new()
  if not process then return end
  local player = Player.new(process.take)
  local gui = GUI.new(160, 'Experience', 'Tightness')

  local open = 0
  local x, y
  local function loop()
    local focusedWindow = reaper.JS_Window_GetFocus()
    local parentWindow = reaper.JS_Window_GetParent(focusedWindow)
    if gui.hwnd ~= focusedWindow and gui.hwnd ~= parentWindow then
      gfx.quit()
      return
    end
    if open == 0 then
      open, x, y = gui:draw(player)
      reaper.defer(loop)
    else
      if open == 1 then
        player:set_experience(x)
        player:set_tightness(y)
        process:call(player)
      end
      gfx.quit()
      reaper.JS_Window_SetForeground(window)
    end
  end

  loop()
end

main()
