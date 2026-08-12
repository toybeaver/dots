-- Hyprland's share of the neo-brutal-dark theme.
--
-- See hxh-neon-glass/desktop/hypr.lua for what this file is and how it is
-- loaded. Every key must be present — hyprland.lua reads them directly.

return {
    -- A single colour, not a gradient. A gradient border is the one thing this
    -- style will not tolerate; Hyprland still wants a list, so this is a
    -- one-stop "gradient" and the angle is irrelevant.
    active_border   = { colors = { "rgba(b39cffff)" }, angle = 0 },
    inactive_border = "rgba(2a2a2aff)",

    -- Thick. The border is the entire visual system here, and at 1-2px it reads
    -- as a hairline rather than as ink.
    border_size     = 3,

    -- Square. Not "slightly rounded" — the whole point is the hard corner.
    rounding        = 0,
    rounding_power  = 2,

    -- Off. A soft shadow implies a light source and a soft material, which is
    -- exactly what this style refuses. The shell draws its own HARD offset
    -- shadows instead; see brutal/BrutalSurface.qml.
    shadow = {
        enabled      = false,
        range        = 0,
        render_power = 1,
        color        = 0x00000000,
    },

    -- Off, and load-bearing rather than a saving. Every surface in this theme
    -- is opaque, so there is nothing behind anything to frost.
    blur = {
        enabled    = false,
        size       = 1,
        passes     = 1,
        vibrancy   = 0.0,
        brightness = 1.0,
        contrast   = 1.0,
    },
}
