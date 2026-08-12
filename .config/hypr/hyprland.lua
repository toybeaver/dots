------------------
---- THEME ----
------------------

-- The active theme's Hyprland block: borders, corners, blur and shadows.
--
-- A theme is a whole Quickshell config directory under ~/.config/quickshell,
-- and each one ships a desktop/hypr.lua returning the table below.
-- bin/shell-theme points ~/.local/state/dots/active/hypr.lua at the current
-- one and then runs `hyprctl reload`, which re-parses this file and picks the
-- new values up. Nothing here names a theme.
--
-- The fallback matters: on a fresh checkout the symlink does not exist yet,
-- because Hyprland parses this file BEFORE autostart runs shell-theme. Rather
-- than error into a borderless, blurless desktop, fall back to the glass
-- theme's values — the same ones that used to be inline here.
local function theme_style()
    local fallback = {
        active_border   = { colors = { "rgba(931072ff)", "rgba(0c9797ee)" }, angle = 45 },
        inactive_border = "rgba(3a3f4baa)",
        border_size     = 2,
        rounding        = 10,
        rounding_power  = 2,
        shadow = { enabled = true, range = 4, render_power = 3, color = 0xee1a1a1a },
        blur = {
            enabled = true, size = 4, passes = 2,
            vibrancy = 0.1696, brightness = 0.90, contrast = 0.90,
        },
    }

    local home = os.getenv("HOME")
    if not home then return fallback end

    local ok, style = pcall(dofile, home .. "/.local/state/dots/active/hypr.lua")
    if ok and type(style) == "table" then return style end
    return fallback
end

local style = theme_style()


------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
hl.monitor({
    output   = "eDP-1",
    mode     = "preferred",
    position = "760x1440",
    scale    = "1",
})
hl.monitor({
    output   = "HDMI-A-1",
    mode     = "preferred",
    position = "0x0",
    scale    = "1",
})


---------------------
---- MY PROGRAMS ----
---------------------

-- Set programs that you use
local terminal    = "ghostty"
local fileManager = "nautilus"
-- Appearance comes from ~/.config/rofi/config.rasi, which @theme-imports
-- the active theme through a symlink. No theme is named here.
local menu        = "rofi -show drun"


-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
--
hl.on("hyprland.start", function () 
  hl.exec_cmd("systemctl --user import-environment DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE")

  -- One line, on purpose. swaybg, mako and the shell all look different per
  -- theme, so shell-theme owns all three: it points the active-config symlinks,
  -- sets the wallpaper, starts mako against the theme's config and launches the
  -- shell. A theme switch runs the same code, so login and switching cannot
  -- drift apart.
  hl.exec_cmd("/home/toyb/.config/quickshell/bin/shell-theme start")
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")


-----------------------
----- PERMISSIONS -----
-----------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Permissions/
-- Please note permission changes here require a Hyprland restart and are not applied on-the-fly
-- for security reasons

-- hl.config({
--   ecosystem = {
--     enforce_permissions = true,
--   },
-- })

-- hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
-- hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
-- hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")


-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 7,

        border_size = style.border_size,

        -- Border colours come from the active theme — see THEME at the top of
        -- this file and <theme>/desktop/hypr.lua for the values and why they
        -- are what they are.
        col = {
            active_border   = style.active_border,
            inactive_border = style.inactive_border,
        },

        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = false,

        -- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {
        -- Themed: see THEME at the top of this file.
        rounding       = style.rounding,
        rounding_power = style.rounding_power,

        -- Change transparency of focused and unfocused windows
        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = style.shadow,

        -- Themed, and this is the setting most worth reading the theme file
        -- for. It reaches every surface with a blur layer rule, and the
        -- post-processing in it is not cosmetic — see the note where the
        -- sidebar's blur rule used to be, and the tuning notes in
        -- <theme>/desktop/hypr.lua. A flat theme turns this off entirely.
        blur = style.blur,
    },

    animations = {
        enabled = true,
    },
})

-- Default curves and animations, see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

-- Default springs
hl.curve("easy",           { type = "spring", mass = 1, stiffness = 238.1191, dampening = 24.21279333 })

hl.animation({ leaf = "global",        enabled = true,  speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true,  speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true,  speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn",     enabled = true,  speed = 4.1,  spring = "easy",         style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true,  speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true,  speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true,  speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true,  speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true,  speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true,  speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true,  speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true,  speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor",    enabled = true,  speed = 7,    bezier = "quick" })

-- Ref https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- "Smart gaps" / "No gaps when only"
-- uncomment all if you wish to use that.
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({
--     name  = "no-gaps-wtv1",
--     match = { float = false, workspace = "w[tv1]" },
--     border_size = 0,
--     rounding    = 0,
-- })
-- hl.window_rule({
--     name  = "no-gaps-f1",
--     match = { float = false, workspace = "f[1]" },
--     border_size = 0,
--     rounding    = 0,
-- })

-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more
hl.config({
    dwindle = {
        preserve_split = true, -- You probably want this
    },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/ for more
hl.config({
    master = {
        new_status = "master",
    },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/ for more
hl.config({
    scrolling = {
        fullscreen_on_one_column = true,
    },
})

----------------
----  MISC  ----
----------------

hl.config({
    misc = {
        force_default_wallpaper = 0,    -- Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo   = false, -- If true disables the random hyprland logo / anime girl background. :(
    },
})


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = true,
        },
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})

-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/ for more
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER" -- Sets "Windows" key as main modifier

-- MOD+SHIFT+Q: press once to arm, press again within 3s to actually exit
local exitCmd = "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"
local exitArmed = false

hl.bind(mainMod .. " + SHIFT + Q", function()
    if exitArmed then
        hl.exec_cmd(exitCmd)
        return
    end

    exitArmed = true
    hl.notification.create({
        text = "Press " .. mainMod .. "+SHIFT+Q again to exit Hyprland",
        duration = 3000,
        icon = "warning",
    })
    hl.timer(function() exitArmed = false end, { timeout = 3000, type = "oneshot" })
end)

-- Example binds, see https://wiki.hypr.land/Configuring/Basics/Binds/ for more
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
local closeWindowBind = hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + G", hl.dsp.layout("togglesplit"))    -- dwindle only

-- Session lock. Uses ext-session-lock-v1 via Quickshell, so the compositor
-- itself holds the lock — killing the process does NOT reveal the session.
--
-- -n (--no-duplicate) matters: launching a second locker while one is already
-- holding the lock would fail, and this makes the extra invocation a no-op
-- rather than a confusing error.
--
-- If the locker ever dies while locked, the session stays locked by design.
-- Recover from a TTY (Ctrl+Alt+F2): loginctl unlock-session
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd("quickshell -c lock -n"))

-- The Copilot key opens the control center.
--
-- Microsoft's spec has that key emit Shift+Super+F23 rather than a keysym of
-- its own, which is why it binds like an ordinary chord. Confirmed on this
-- keyboard by probing candidates at runtime, not assumed from the spec.
--
-- Anything bound to SUPER+SHIFT+F23 by hand would collide with it.
--
-- This goes through the running shell's IPC handler rather than launching
-- anything: the control center lives inside the already running bar, so there
-- is no process to start. It opens on whichever monitor has focus. If the bar
-- is not running the call just fails and nothing happens.
--
-- It used to lock the session; MOD+Escape still does that.
hl.bind(mainMod .. " + SHIFT + F23", hl.dsp.exec_cmd(
    "/home/toyb/.config/quickshell/bin/shell-theme ipc call control toggle"))

-- Lid close locks the session.
--
-- `locked = true` so it still fires if the session is somehow already locked;
-- the locker's -n makes that a no-op rather than an error.
--
-- logind still suspends on lid close (HandleLidSwitch is left at its default).
-- This only adds the lock, so the machine locks and then sleeps, and comes back
-- to the lock screen. Nothing sequences the two, but logind honours inhibitor
-- delays before sleeping while the locker maps in well under a second.
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("quickshell -c lock -n"), { locked = true })

-- Power button asks before shutting down, same press-again pattern as
-- mainMod+SHIFT+Q.
--
-- This only works if logind is told to keep its hands off the key. Its default
-- HandlePowerKey is `poweroff`, which shuts the machine down before Hyprland
-- ever sees the press. See /etc/systemd/logind.conf.d/10-power-key.conf.
local powerArmed = false

hl.bind("XF86PowerOff", function()
    if powerArmed then
        hl.exec_cmd("systemctl poweroff")
        return
    end

    powerArmed = true
    hl.notification.create({
        text = "Press the power button again to shut down",
        duration = 3000,
        icon = "warning",
    })
    hl.timer(function() powerArmed = false end, { timeout = 3000, type = "oneshot" })
end)

-- Screenshots. Print alone selects a region (niri's default behaviour);
-- every capture lands in ~/Pictures/screenshots and on the clipboard.
local screenshot = "/home/toyb/.config/hypr/scripts/screenshot.sh"
hl.bind("Print",                    hl.dsp.exec_cmd(screenshot .. " region"))
hl.bind("SHIFT + Print",            hl.dsp.exec_cmd(screenshot .. " screen"))
hl.bind(mainMod .. " + Print",      hl.dsp.exec_cmd(screenshot .. " window"))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + H",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J",  hl.dsp.focus({ direction = "down" }))

hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }))

hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ action = "toggle" }))

-- mainMod+TAB cycles focus through every mapped window on every workspace.
--
-- hl.dsp.window.cycle_next() cannot do this: it is confined to the active
-- workspace, so with five workspaces in use it only ever reaches a fraction of
-- the windows. Focusing a window that lives elsewhere switches to its
-- workspace on its own, so walking a global list is all this needs.
--
-- Order is (workspace id, stable_id), deliberately NOT focus history. Focus
-- history is what alt-tab uses, but alt-tab also knows when the modifier is
-- released and commits the choice at that moment. A bind cannot see the
-- release, so in MRU order the second press would walk straight back to where
-- the first press came from -- a two-window ping-pong, not a cycle. A fixed
-- order visits every window exactly once before wrapping.
--
-- stable_id is monotonic per window and never reused, so this order only
-- changes when a window opens or closes, never as a side effect of focusing.
--
-- Special workspaces are excluded (their ids are negative); they are already
-- reachable with mainMod+S.
local function cycleAllWindows(step)
    local windows = {}
    for _, w in ipairs(hl.get_windows({ mapped = true })) do
        if w.workspace and w.workspace.id > 0 then
            windows[#windows + 1] = w
        end
    end

    if #windows == 0 then return end

    table.sort(windows, function(a, b)
        if a.workspace.id ~= b.workspace.id then
            return a.workspace.id < b.workspace.id
        end
        return a.stable_id < b.stable_id
    end)

    -- Find where we are. The active window can legitimately be absent from the
    -- list -- nothing focused at all, or focus sitting on the special
    -- workspace -- in which case start the cycle at the beginning rather than
    -- doing nothing.
    local current
    local active = hl.get_active_window()
    if active then
        for i, w in ipairs(windows) do
            if w.address == active.address then
                current = i
                break
            end
        end
    end

    if not current then
        hl.dispatch(hl.dsp.focus({ window = windows[1] }))
        return
    end

    -- Lua's % floors, so a step of -1 wraps to the end instead of going
    -- negative.
    hl.dispatch(hl.dsp.focus({ window = windows[(current - 1 + step) % #windows + 1] }))
end

hl.bind(mainMod .. " + TAB",                 function() cycleAllWindows(1) end)
-- Reverse is bound under both names on purpose: with SHIFT held the US layout
-- turns Tab into ISO_Left_Tab, and which of the two a compositor matches on is
-- not something to leave to chance.
hl.bind(mainMod .. " + SHIFT + TAB",          function() cycleAllWindows(-1) end)
hl.bind(mainMod .. " + SHIFT + ISO_Left_Tab", function() cycleAllWindows(-1) end)

-- Switch workspaces with mainMod + [1-5]
-- Move active window to a workspace with mainMod + SHIFT + [1-5]
for i = 1, 5 do
    local key = i % 6 -- 6 maps to key 0
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end

-- Example special workspace (scratchpad)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind(mainMod .. " + equal", hl.dsp.window.resize({ x = 40,  y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + minus", hl.dsp.window.resize({ x = -40, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + 0", hl.dsp.layout("splitratio 1 exact"))

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Example window rules that are useful

local suppressMaximizeRule = hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

-- Layer rules also return a handle.
-- local overlayLayerRule = hl.layer_rule({
--     name  = "no-anim-overlay",
--     match = { namespace = "^my-overlay$" },
--     no_anim = true,
-- })
-- overlayLayerRule:set_enabled(false)

-- The sidebar deliberately has NO blur rule, in any theme.
--
-- It used to. Removing it fixed the pills rendering dark and speckled with green
-- dots. Two causes, both from the blur:
--
--   * brightness/contrast/vibrancy are applied to whatever the blur samples, so
--     lowering brightness to 0.60 for mako and rofi silently darkened the pills
--     too. Only where alpha exceeded ignore_alpha, which is why the transparent
--     gutter beside them stayed correct and the effect looked inexplicable.
--   * the pills' frost grain makes their alpha oscillate roughly 0.045-0.073,
--     straddling ignore_alpha (0.05). Pixels either side of that threshold were
--     blurred or not, producing the speckle.
--
-- The sidebar loses nothing: it reserves an exclusive zone over a near-flat
-- wallpaper, so there was never anything behind it worth blurring. Its glass is
-- drawn entirely by neon-glass/shaders/glass.frag. Do not re-add a blur rule.

-- Frosted glass for mako notifications.
-- No xray: notifications float over window content, and that content is exactly
-- what should be frosted behind them.
hl.layer_rule({
    name  = "mako-glass",
    match = { namespace = "^notifications$" },

    blur         = true,
    ignore_alpha = 0.05,
})

-- Frosted glass for the rofi launcher, same treatment as mako.
hl.layer_rule({
    name  = "rofi-glass",
    match = { namespace = "^rofi$" },

    blur         = true,
    ignore_alpha = 0.05,
})

-- Frosted glass for the control center panel.
--
-- ignore_alpha is doing real work here, not just following the mako/rofi
-- pattern. This surface covers the WHOLE screen — the panel plus the dim behind
-- it — so blurring at the usual 0.05 would frost the entire desktop rather than
-- the popup. The two regions sit at very different alphas:
--
--   dim only          0.55
--   dim + panel base  ~0.89   (0.55 dim composited under the panel's own fill)
--
-- so a threshold between them blurs the panel and leaves the rest of the screen
-- sharp. 0.70 sits clear of both.
--
-- Unlike the sidebar, the panel's alpha does not oscillate near the threshold —
-- its grain is 0.014 on top of a fill of ~0.75, nowhere near 0.70 — so there is
-- no risk of the speckle that killed the sidebar's rule.
-- Scoped to ONE theme, deliberately. Each theme namespaces its layers with its
-- own name (see `sidebarLayer` / `controlLayer` in its consts/Theme.qml), so
-- this matches hxh-neon-glass and nothing else. The flat `temp` theme has an opaque
-- panel and wants no blur at all — it simply matches no rule.
--
-- A new theme that wants frosting needs its own copy of this block. That is the
-- intended cost: blur tuning is part of a theme's material, not a global.
hl.layer_rule({
    name  = "hxh-neon-glass-control-glass",
    match = { namespace = "^hxh-neon-glass-control$" },

    blur         = true,
    ignore_alpha = 0.70,
})

-- Hyprland-run windowrule
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})
