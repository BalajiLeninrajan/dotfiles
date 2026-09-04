-- SPDX-License-Identifier: MIT
--
-- 10-t2-palm.lua -- stronger palm rejection for the T2 MacBook internal trackpad.
--
-- libinput's own palm detection on this pad is: size > AttrPalmSizeThreshold
-- (see /etc/libinput/local-overrides.quirks), disable-while-typing with a
-- 200/500 ms window that ignores modifier keys, and thumb jailing. Edge zones
-- are compiled out for Apple pads, and pressure is unusable on this digitizer.
--
-- This plugin sits *below* libinput and hides touches from it. Measured contact
-- sizes (ABS_MT_TOUCH_MAJOR): a finger moving the cursor reaches 500-850, a
-- thumb ~1050, a resting palm 1600-2200. So size alone cannot separate a firm
-- finger from a light palm; the rules lean on *context* instead: a touch that
-- lands while the keyboard is in use is treated with much more suspicion.
--
--   typing : "typing context" is the TYPING_MS after a (non-modifier) key.
--   hold   : every new touch is held back for HOLD_MS. If its size passes
--            PALM_SIZE (TYPING_SIZE while typing) while hidden, it is a palm
--            and stays hidden for its whole life; otherwise it is handed to
--            libinput at its current position. This removes the cursor twitch
--            a landing palm causes while it grows toward libinput's threshold.
--   zone   : touches that start in the top TOP_MM (right under the space bar),
--            or -- while typing -- within SIDE_MM of the left/right edge (heel
--            of the hand), are held until they move RELEASE_MM; if they just
--            sit there for ZONE_RELEASE_MS they are palms.
--   dwt    : touches that start within the disable-while-typing window after a
--            key are hidden. The window is DWT_MS when the key is part of a
--            typing burst (previous key < BURST_MS earlier) and DWT_SINGLE_MS
--            after an isolated key (a shortcut, a lone Enter). When the window
--            ends the touch is handed over if it began after the last key and
--            did not just sit in a zone; otherwise it dies.
--   kill   : on a key press, visible touches with size >= TYPING_SIZE, or that
--            began in a zone and never moved, are ended -- a palm that was
--            resting before typing started.
--
-- Decisions are logged at debug level, prefixed "t2palm:". Watch them with
--   python3 ~/.local/share/t2-palm-test.py --quiet
-- (libinput debug-events --enable-plugins does not load plugins on Fedora).
-- ~/.local/share/t2-touch-log.py replays these rules on live touches so
-- thresholds can be tuned before restarting niri.
-- Loaded by niri at startup from ~/.config/libinput/plugins; edit, then log
-- out/in. Delete or rename the file to disable.

libinput:register({1})

local CFG = {
  hold_ms         = 35,   -- delay before a new touch reaches libinput (~3 frames)
  palm_size       = 1100, -- hidden touch reaching this size is a palm (thumb max ~1050)
  typing_size     = 900,  -- same while typing; visible touches this big die at a key press
  top_mm          = 12,   -- top-edge zone height, always on
  side_mm         = 10,   -- left/right zone width, only while typing
  zone_release_ms = 300,  -- zone touch must move within this or it is a palm
  release_mm      = 3,    -- movement that frees a zone touch
  dwt_ms          = 1000, -- window after a key inside a typing burst
  dwt_single_ms   = 300,  -- window after an isolated key
  burst_ms        = 1000, -- keys closer together than this form a burst
  typing_ms       = 3000, -- typing context lasts this long after the last key
  debug           = true,
}

local US = 1000                     -- usec per ms
local A = function(code) return (3 << 16) | code end
local SLOT, MAJOR, MINOR = A(0x2f), A(0x30), A(0x31)
local PX, PY, TID = A(0x35), A(0x36), A(0x39)
local MODIFIERS = { [29]=true, [97]=true, [42]=true, [54]=true, [56]=true,
                    [100]=true, [125]=true, [126]=true }

local tp = nil
local xres, yres, xmin, ymin, width_mm = 1, 1, 0, 0, 0
local cur_slot = 0                  -- slot the kernel is currently reporting
local li_slot = -1                  -- slot libinput last saw selected
local slots = {}                    -- slot -> touch state
local last_key = -(1 << 50)
local dwt_len = CFG.dwt_single_ms * US  -- window opened by the last key
local kill_pending = false
local BTN_TOUCH = (1 << 16) | 0x14a
local synced = false                -- do we know the kernel's current slot?
local all_up = false                -- has the pad been seen with no contacts?

local function log(msg)
  if CFG.debug then libinput:log_debug("t2palm: " .. msg) end
end

local function is_mt(u)
  if (u >> 16) ~= 3 then return false end
  local c = u & 0xffff
  return c >= 0x30 and c <= 0x3e
end

local function mm_x(x) return (x - xmin) / xres end
local function mm_y(y) return (y - ymin) / yres end
local function typing(now) return now - last_key < CFG.typing_ms * US end

local function moved_mm(st)
  local dx = (st.x - st.x0) / xres
  local dy = (st.y - st.y0) / yres
  return math.sqrt(dx * dx + dy * dy)
end

-- zone a touch began in, independent of context
local function zone_of(st)
  if mm_y(st.y0) < CFG.top_mm then return "top" end
  local x = mm_x(st.x0)
  if x < CFG.side_mm or x > width_mm - CFG.side_mm then return "side" end
  return nil
end

local function push(out, usage, value)
  out[#out + 1] = { usage = usage, value = value }
end

-- returns true if it had to emit a slot select
local function select_slot(out, slot)
  if li_slot ~= slot then
    push(out, SLOT, slot)
    li_slot = slot
    return true
  end
  return false
end

local function emit_begin(out, slot, st)
  select_slot(out, slot)
  push(out, TID, st.id)
  push(out, PX, st.x)
  push(out, PY, st.y)
  push(out, MAJOR, st.major)
  push(out, MINOR, st.minor)
  st.vis = true
end

local function emit_end(out, slot, st)
  select_slot(out, slot)
  push(out, TID, -1)
  st.vis = false
end

local function classify(st, now)
  st.zone = zone_of(st)
  if now - last_key < dwt_len then
    st.reason = "dwt"
  elseif st.zone == "top" or (st.zone == "side" and typing(now)) then
    st.reason = "zone"
    st.deadline = now + CFG.zone_release_ms * US
  else
    st.reason = "hold"
    st.deadline = now + CFG.hold_ms * US
  end
end

local function decide(st, now)
  local lim = typing(now) and CFG.typing_size or CFG.palm_size
  if st.maxmaj >= lim then return "kill", "size " .. st.maxmaj end
  local r = st.reason
  if r == "hold" then
    if now >= st.deadline then return "release", "hold over" end
  elseif r == "zone" then
    if moved_mm(st) >= CFG.release_mm then return "release", "moved out of " .. st.zone .. " zone" end
    if now >= st.deadline then return "kill", "parked in " .. st.zone .. " zone" end
  elseif r == "dwt" then
    if now - last_key >= dwt_len then
      if st.t0 <= last_key then return "kill", "began before last key" end
      if st.zone and moved_mm(st) < CFG.release_mm then
        return "kill", "parked in " .. st.zone .. " zone while typing"
      end
      return "release", "typing window over"
    end
  end
  return nil
end

-- Apply pending decisions for one touch. Returns "pass" (libinput already
-- sees it, forward its events), "shown" (begin injected now) or "hidden".
local function act(out, slot, st, now)
  if st.dead then return "hidden" end
  if st.vis then
    if kill_pending then
      local why = nil
      if st.major >= CFG.typing_size then
        why = string.format("key press while resting (maj %d)", st.major)
      elseif st.zone and moved_mm(st) < CFG.release_mm then
        why = "key press while parked in " .. st.zone .. " zone"
      end
      if why then
        emit_end(out, slot, st)
        st.dead = true
        log(string.format("slot %d id %d killed: %s", slot, st.id, why))
        return "hidden"
      end
    end
    return "pass"
  end
  local d, why = decide(st, now)
  if d == "release" then
    emit_begin(out, slot, st)
    log(string.format("slot %d id %d shown after %dms: %s", slot, st.id, (now - st.t0) // US, why))
    return "shown"
  elseif d == "kill" then
    st.dead = true
    log(string.format("slot %d id %d palm: %s", slot, st.id, why))
  end
  return "hidden"
end

local function rearm()
  local t = nil
  for _, st in pairs(slots) do
    if not st.dead and not st.vis then
      local d = (st.reason == "dwt") and (last_key + dwt_len) or st.deadline
      if d and (not t or d < t) then t = d end
    end
  end
  if t then libinput:timer_set_absolute(t + US) else libinput:timer_cancel() end
end

local function on_tp_frame(dev, frame, now)
  if not synced then
    -- The kernel only sends ABS_MT_SLOT when the slot changes, so until it
    -- does we cannot attribute slot-less events. Pass frames through until
    -- either an explicit slot arrives, or the pad has been empty (the next
    -- touch then lands in slot 0, the lowest free slot).
    local explicit, begins_implicit = false, false
    for _, ev in ipairs(frame) do
      local u = ev.usage
      if u == SLOT then
        explicit = true
        cur_slot = ev.value
      elseif u == BTN_TOUCH and ev.value == 0 then
        all_up = true
      elseif not explicit and u == TID and ev.value >= 0 then
        begins_implicit = true
      end
    end
    if explicit then
      synced, li_slot = true, cur_slot
      log("synced on explicit slot " .. cur_slot)
      return nil
    elseif all_up and begins_implicit then
      cur_slot, li_slot, synced = 0, 0, true
      log("synced: first touch on an empty pad is slot 0")
    else
      return nil
    end
  end

  -- split the frame into per-slot sections and everything else
  local sections, others, cur = {}, {}, nil
  for _, ev in ipairs(frame) do
    local u = ev.usage
    if u == SLOT then
      cur_slot = ev.value
      cur = { slot = cur_slot, evs = {}, explicit = true }
      sections[#sections + 1] = cur
    elseif is_mt(u) then
      if not cur then
        cur = { slot = cur_slot, evs = {}, explicit = false }
        sections[#sections + 1] = cur
      end
      cur.evs[#cur.evs + 1] = ev
    else
      others[#others + 1] = ev
    end
  end

  -- update touch state
  for _, s in ipairs(sections) do
    local st = slots[s.slot]
    local began, ended = false, false
    local nx, ny, nmaj, nmin
    for _, ev in ipairs(s.evs) do
      local u = ev.usage
      if u == TID then
        if ev.value >= 0 then
          began = true
          st = { id = ev.value, t0 = now, major = 0, minor = 0, maxmaj = 0,
                 vis = false, dead = false }
          slots[s.slot] = st
        else
          ended = true
        end
      elseif u == PX then nx = ev.value
      elseif u == PY then ny = ev.value
      elseif u == MAJOR then nmaj = ev.value
      elseif u == MINOR then nmin = ev.value
      end
    end
    if st then
      if nx then st.x = nx end
      if ny then st.y = ny end
      if nmaj then st.major = nmaj end
      if nmin then st.minor = nmin end
      if began then
        st.x, st.y = st.x or 0, st.y or 0
        st.x0, st.y0 = st.x, st.y
        classify(st, now)
        log(string.format("slot %d id %d begin x=%.0fmm y=%.0fmm maj=%d zone=%s %s -> %s",
                          s.slot, st.id, mm_x(st.x), mm_y(st.y), st.major, st.zone or "-",
                          typing(now) and "typing" or "idle", st.reason))
      end
      local big = math.max(st.major, st.minor)
      if big > st.maxmaj then st.maxmaj = big end
    end
    s.st, s.began, s.ended = st, began, ended
  end

  -- build the outgoing frame
  local out, modified, seen = {}, false, {}
  for _, s in ipairs(sections) do
    local st, slot = s.st, s.slot
    seen[slot] = true
    if not st then
      -- touch predates the plugin: forward untouched
      if select_slot(out, slot) and not s.explicit then modified = true end
      for _, ev in ipairs(s.evs) do push(out, ev.usage, ev.value) end
    elseif s.ended then
      slots[slot] = nil
      if st.vis then
        if select_slot(out, slot) and not s.explicit then modified = true end
        for _, ev in ipairs(s.evs) do push(out, ev.usage, ev.value) end
        st.vis = false
      else
        modified = true
        if st.reason == "hold" and not st.dead and st.maxmaj < CFG.palm_size then
          -- a real tap shorter than the hold: replay it
          emit_begin(out, slot, st)
          dev:append_frame({ { usage = SLOT, value = slot }, { usage = TID, value = -1 } })
          li_slot = slot
          log(string.format("slot %d id %d replayed as tap (%dms)", slot, st.id, (now - st.t0) // US))
        end
      end
    else
      local r = act(out, slot, st, now)
      if r == "pass" then
        if select_slot(out, slot) and not s.explicit then modified = true end
        for _, ev in ipairs(s.evs) do push(out, ev.usage, ev.value) end
      else
        modified = true
      end
    end
  end
  -- touches with no events this frame may still have a deadline due
  for slot, st in pairs(slots) do
    if not seen[slot] then
      local before = #out
      act(out, slot, st, now)
      if #out ~= before then modified = true end
    end
  end
  kill_pending = false
  for _, ev in ipairs(others) do push(out, ev.usage, ev.value) end
  rearm()

  if not modified then return nil end
  if #out > 64 then
    log("frame too large after rewrite (" .. #out .. " events), passing original")
    return nil
  end
  return out
end

local function on_kbd_frame(dev, frame, now)
  for _, ev in ipairs(frame) do
    local u = ev.usage
    if (u >> 16) == 1 and ev.value == 1 then
      local code = u & 0xffff
      if code < 0x100 and not MODIFIERS[code] then
        local burst = now - last_key < CFG.burst_ms * US
        dwt_len = (burst and CFG.dwt_ms or CFG.dwt_single_ms) * US
        last_key = now
        kill_pending = true
        libinput:timer_set_relative(US)
        return
      end
    end
  end
end

libinput:connect("timer-expired", function(now)
  if not tp then return end
  local out = {}
  for slot, st in pairs(slots) do act(out, slot, st, now) end
  kill_pending = false
  if #out > 0 then tp:append_frame(out) end
  rearm()
end)

libinput:connect("new-evdev-device", function(dev)
  local props = dev:udev_properties()
  local name = dev:name() or ""
  if props.ID_INPUT_TOUCHPAD and string.find(name, "Apple Internal Keyboard / Trackpad", 1, true) then
    local abs = dev:absinfos()
    local ax, ay = abs[PX], abs[PY]
    if not (ax and ay and ax.resolution > 0 and ay.resolution > 0) then
      libinput:log_error("t2palm: " .. name .. " has no x/y resolution, not managing it")
      return
    end
    xres, yres, xmin, ymin = ax.resolution, ay.resolution, ax.minimum, ay.minimum
    width_mm = (ax.maximum - ax.minimum) / xres
    tp, slots, li_slot = dev, {}, -1
    synced, all_up = false, false
    dev:connect("evdev-frame", on_tp_frame)
    dev:connect("device-removed", function() tp = nil; slots = {} end)
    libinput:log_info(string.format(
      "t2palm: managing %s (%.0fmm wide; hold %dms, sizes %d/%d, top %dmm, side %dmm, dwt %d/%dms)",
      name, width_mm, CFG.hold_ms, CFG.palm_size, CFG.typing_size, CFG.top_mm, CFG.side_mm,
      CFG.dwt_ms, CFG.dwt_single_ms))
  elseif props.ID_INPUT_KEYBOARD and not props.ID_INPUT_TOUCHPAD then
    dev:connect("evdev-frame", on_kbd_frame)
  end
end)
