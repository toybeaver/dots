-- Hyprland's share of the flat theme.
--
-- See hxh-neon-glass/desktop/hypr.lua for what this file is and how it is
-- loaded. Every key here must be present — hyprland.lua reads them directly
-- rather than merging over defaults.

return {
    -- A single colour, not a gradient. Hyprland still wants a list, so this is
    -- a one-stop "gradient" — the same trick the shell uses when it collapses a
    -- rim to signal state. `angle` is irrelevant with one stop but must exist.
    --
    -- Plain white at full strength. On this theme there is no accent competing
    -- with it, so the border can carry the focus signal on its own.
    active_border   = { colors = { "rgba(ffffffff)" }, angle = 0 },

    -- Dark enough to disappear against the wallpaper. With no rounding and no
    -- shadow, an inactive border is the only thing outlining every window, and
    -- at any real brightness the screen turns into a wireframe.
    inactive_border = "rgba(3a3a3aaa)",

    -- 1px, against the glass theme's 2. A hard white edge does not need weight
    -- to register the way a soft neon gradient does.
    border_size     = 1,

    -- Square. This is the single biggest reason the two themes read as
    -- different desktops rather than two colour schemes.
    rounding        = 0,
    rounding_power  = 2,

    -- Off. A shadow is a depth cue, and depth is exactly what this theme is
    -- not doing — surfaces here are flat planes with hairline edges.
    shadow = {
        enabled      = false,
        range        = 0,
        render_power = 1,
        color        = 0x00000000,
    },

    -- Off, and this is load-bearing rather than a saving. This theme's mako,
    -- rofi and control panel are all opaque, so there is nothing behind them to
    -- show through — a blur pass would cost real work and change no pixels.
    --
    -- The other values still have to be present and valid: Hyprland parses the
    -- whole block whether or not it is enabled.
    blur = {
        enabled    = false,
        size       = 1,
        passes     = 1,
        vibrancy   = 0.0,
        brightness = 1.0,
        contrast   = 1.0,
    },
}
