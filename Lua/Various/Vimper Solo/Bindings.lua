local Transport, Navigation, MIDI, Layout, Track, Item, Take, Envelope, Groups


Transport = {
  NAME = "Transport",
  p = {40073, "Pause/Play"},
  ['['] = {40042, "Go to end of project"},
  [']'] = {40043, "Go to end of project"},
  RIGHT = {40085, "Fast forward a little bit"},
  LEFT = {40085, "Rewind a little bit"},
  r = {1068, "Toggle Repeat"},
  SPACE = {40044, "Play/Stop"},
}

Navigation = {
  NAME = "Navigation",
}

MIDI = {
  NAME = "MIDI Editor",
  
}

Layout = {
  NAME = "Layout",
  d = {48500, "Default Layout"},
  
}

Track = {
  NAME = "Track",
  
}

Item = {
  NAME = "Item",
  e = {41848, "Stretch at mouse"},
  d = {41295, "Duplicate item"},
  f = {
    NAME = "Item Fade",
    ['/'] = {"_RS5b9ffa0b6fb23c2342fdc9b5b329fde14130ecb0", "Fade in to mouse"},
    ['\\'] = {"_RSda12211743f373b6890f510ea9e2277926005b46", "Fade out from mouse"},
    ['['] = {41191, "Remove fade in"},
    [']'] = {41192, "Remove fade out"},

  },
  r = {41051, "Reverse"},
  R = {40270, "Reverse to new take"},
  l = {40636, "Loop item source"},
  f = {40641, "Toggle free positioning"},
  o = {40688, "Lock"},
  O = {41340, "Lock to active take"},
  s = {41559, "Solo"},
  m = {40719, "Mute"},
  h = {40181, "Invert Phase"},
  p = {
    NAME = "Item Pitch",
    s = {40204, "Pitch up one semitone"},
    S = {40205, "Pitch down one semitone"},
    o = {40515, "Pitch up one octave"},
    O = {40516, "Pitch down one octave"},
    c = {40206, "Pitch down one cent"},
    C = {40207, "Pitch down one cent"},
    r = {40653, "Reset item pitch"},
  },
  c = {
    NAME = "Item Channel",
    m = {
      NAME = "Mono",
      [0] = {40178, "Set to Left+Right"},
      [1] = {40179, "Set to Left"},
      [2] = {40180, "Set to Right"},
      [3] = {41388, "Set to Channel 3"},
      [4] = {41389, "Set to Channel 4"},
      [5] = {41390, "Set to Channel 5"},
      [6] = {41391, "Set to Channel 6"},
      [7] = {41392, "Set to Channel 7"},
      [8] = {41393, "Set to Channel 8"},
      [9] = {41394, "Set to Channel 9"},
      a = {41395, "Set to Channel 10"},
      b = {41396, "Set to Channel 11"},
      c = {41397, "Set to Channel 12"},
      d = {41398, "Set to Channel 13"},
      e = {41399, "Set to Channel 14"},
      f = {41400, "Set to Channel 15"},
      g = {41401, "Set to Channel 16"},
    },
    s = {
      NAME = "Stereo",
      [1] = {41450, "Set to Channel 1|2"},
      [2] = {41452, "Set to Channel 3|4"},
      [3] = {41454, "Set to Channel 5|6"},
      [4] = {41456, "Set to Channel 7|8"},
      [5] = {41458, "Set to Channel 9|10"},
      [6] = {41460, "Set to Channel 11|12"},
      [7] = {41462, "Set to Channel 13|14"},
      [8] = {41464, "Set to Channel 15|16"},
      [9] = {41466, "Set to Channel 17|18"},
      a = {41468, "Set to Channel 19|20"},
      b = {41470, "Set to Channel 21|22"},
      c = {41472, "Set to Channel 23|24"},
      d = {41474, "Set to Channel 25|26"},
      e = {41476, "Set to Channel 27|28"},
      f = {41478, "Set to Channel 29|30"},
      g = {41480, "Set to Channel 31|32"},
    },
    n = {40176, "Normal"},
  },
}

Take = {
  NAME = "Take",
  UP = {40126, "Previous take"},
  DOWN = {40125, "Next take"},
  t = {40131, "Crop to active take"},
  T = {41348, "Remove all empty takes"},
  DELETE = {40129, "Delete active take"},
  i = {40438, "Implode items across tracks"},
  I = {40543, "Implode items same track"},
  e = {40224, "Explode across tracks"},
  E = {40642, "Explode in place"},
  a = {41352, "Add empty lane after active take"},
  A = {41351, "Add empty lane before active take"},
  x = {"_S&M_CUT_TAKE", "Cut take"},
  c = {"_S&M_COPY_TAKE", "Copy take"},
  v = {"_S&M_PASTE_TAKE_AFTER", "Paste take after"},
  V = {"_S&M_PASTE_TAKE", "Paste take into"},
  d = {40639, "Duplicate active take"} -- Take: Duplicate active take
}

Envelope = {
  NAME = "Envelope",
  
}

return {
  NAME = "Vimper Solo",
  r = Transport,
  n = Navigation,
  m = MIDI,
  l = Layout,
  t = Track,
  i = Item,
  a = Take,
  e = Envelope,
}
-- return Groups;