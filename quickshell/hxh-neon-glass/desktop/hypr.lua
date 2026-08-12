-- Hyprland's share of the hxh-neon-glass theme.
--
-- Loaded by hyprland.lua via dofile through ~/.local/state/dots/active/hypr.lua,
-- which bin/shell-theme repoints on every switch. A switch then runs
-- `hyprctl reload`, which re-parses hyprland.lua and picks this up.
--
-- Scope is deliberately narrow: the properties that make a theme read as a
-- *material* — borders, corners, blur and shadows. Layout (gaps, tiling,
-- animations) is the same whichever theme is on, so it stays in hyprland.lua.
--
-- Every key here MUST be present. hyprland.lua reads them directly rather than
-- merging over defaults, so a missing one is a nil in the compositor config.

return {
    -- Sampled straight out of gon.png: its neon frame runs hot magenta to
    -- electric cyan, so the gradient is the wallpaper's own colours rather than
    -- an approximation.
    --
    -- Held at 60% of those values (#f61cbe / #15fcfd). At full strength the
    -- border is genuinely neon and pulls the eye off the window content it
    -- frames. Scale both stops together to re-tune — 70% is #ac1385 / #0eb0b1,
    -- 55% is #870f68 / #0b8a8b.
    --
    -- 45 degrees is the same axis the sidebar pill rims run along, so window
    -- borders and shell surfaces tilt together.
    active_border   = { colors = { "rgba(931072ff)", "rgba(0c9797ee)" }, angle = 45 },
    inactive_border = "rgba(3a3f4baa)",
    border_size     = 2,

    rounding        = 10,
    rounding_power  = 2,

    shadow = {
        enabled      = true,
        range        = 4,
        render_power = 3,
        color        = 0xee1a1a1a,
    },

    -- Tuned for this theme's mako and rofi glass. Counterintuitively, more blur
    -- looks worse: at size 6 / passes 3 the backdrop behind a notification was
    -- homogenised into flat colour, which reads as "milky" rather than glassy.
    -- Glass needs shapes softened but still recognisable.
    --
    -- These reach every surface with a blur layer rule, and the post-processing
    -- is not cosmetic to them — see the note in hyprland.lua where the sidebar's
    -- blur rule used to be.
    blur = {
        enabled    = true,
        size       = 4,
        passes     = 2,
        vibrancy   = 0.1696,

        -- Darkens what the blur samples. Raising blur size does NOT help
        -- legibility: blur softens detail but preserves average brightness, so
        -- a blurred white page is still white. This is the knob that mutes it.
        --
        -- Kept near 1.0 because this theme's mako and rofi use a dark tint,
        -- which handles legibility on its own. It was 0.60 back when they used
        -- a light frost that fought the text.
        brightness = 0.90,
        contrast   = 0.90,
    },
}
