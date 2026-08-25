---
name: Hi Hat
description: A calibrated listening chamber for direct, verified, locally owned lossless playback.
colors:
  signal: "#B7FF3C"
  signal-dark-content: "#182100"
  chamber: "#111311"
  chamber-low: "#151815"
  chamber-raised: "#191C19"
  chamber-high: "#212521"
  mineral: "#E8ECE6"
  trace: "#90988F"
  aluminum: "#C9CFCA"
  dark-outline: "#626962"
  dark-outline-variant: "#303530"
  light-signal: "#426800"
  light-surface: "#F7FAF5"
  light-on-surface: "#191D18"
  light-surface-low: "#F0F3ED"
  light-surface-raised: "#E9EDE6"
  light-surface-high: "#E2E6DE"
  light-outline: "#747A71"
  light-outline-variant: "#C4C9C0"
  dark-error: "#FFB4AB"
  light-error: "#BA1A1A"
typography:
  display-large:
    fontFamily: "system-ui, sans-serif"
    fontSize: "54px"
    fontWeight: 300
    letterSpacing: "-1.6px"
  display-medium:
    fontFamily: "system-ui, sans-serif"
    fontSize: "42px"
    fontWeight: 300
    letterSpacing: "-1.1px"
  headline-large:
    fontFamily: "system-ui, sans-serif"
    fontSize: "32px"
    fontWeight: 600
    letterSpacing: "-0.6px"
  headline-medium:
    fontFamily: "system-ui, sans-serif"
    fontSize: "26px"
    fontWeight: 600
    letterSpacing: "-0.4px"
  title-large:
    fontFamily: "system-ui, sans-serif"
    fontSize: "21px"
    fontWeight: 600
  title-medium:
    fontFamily: "system-ui, sans-serif"
    fontSize: "17px"
    fontWeight: 600
  body-large:
    fontFamily: "system-ui, sans-serif"
    fontSize: "17px"
    fontWeight: 400
    lineHeight: 1.45
  body-medium:
    fontFamily: "system-ui, sans-serif"
    fontSize: "15px"
    fontWeight: 400
    lineHeight: 1.42
  label-large:
    fontFamily: "system-ui, sans-serif"
    fontSize: "14px"
    fontWeight: 600
    letterSpacing: "0.2px"
rounded:
  artwork-small: "8px"
  interactive: "12px"
  artwork-large: "14px"
  circular: "999px"
spacing:
  hairline: "2px"
  tight: "4px"
  xs: "8px"
  sm: "12px"
  md: "16px"
  control: "18px"
  lg: "24px"
  xl: "32px"
  section: "46px"
  monumental: "54px"
components:
  search-field:
    textColor: "{colors.mineral}"
    typography: "{typography.display-medium}"
    padding: "18px 0"
  track-result:
    rounded: "{rounded.interactive}"
    padding: "12px 8px"
  artwork-thumbnail:
    rounded: "{rounded.artwork-small}"
    size: "58px"
  artwork-player:
    rounded: "{rounded.artwork-large}"
  transport-primary:
    backgroundColor: "{colors.signal}"
    textColor: "{colors.signal-dark-content}"
    rounded: "{rounded.circular}"
    size: "72px"
  mini-player-dark:
    backgroundColor: "{colors.chamber-raised}"
    height: "72px"
  navigation-bar-dark:
    backgroundColor: "{colors.chamber-low}"
    height: "72px"
  navigation-rail-dark:
    backgroundColor: "{colors.chamber-low}"
    width: "88px"
---

# Design System: Hi Hat

## Overview

**Creative North Star: "Calibrated Silence"**

Hi Hat behaves like an acoustic calibration chamber rather than a promotional streaming dashboard. Broad, absorptive fields let album artwork become the only vivid image, while mineral text and a rare acid-chartreuse signal make playback, verified quality, progress, and connectivity immediately legible. The tone is modern, premium, calm, and technical without becoming laboratory-dense.

The interface is an adaptive Material 3 operating surface. Search is monumental, results read as a restrained ledger, and the player is a persistent instrument on wide Windows layouts or a compact status strip on smaller Android layouts. Polish comes from hierarchy, alignment, honest state labels, and machined circular transport controls—not feature volume or decorative spectacle.

**Key Characteristics:**

- Anechoic charcoal surfaces with a complete mineral light counterpart.
- Acid-chartreuse reserved for live signal, verified quality, active progress, focus, and selection.
- Platform-native system type with light, tightly tracked display text and firm operational labels.
- Flat ledger rows, tonal surface separation, square artwork, and circular primary transport.
- Adaptive Material navigation and persistent visibility of the current playback state.

## Colors

The palette is an acoustic neutral field punctuated by one unmistakable live-signal hue; light mode preserves the same role hierarchy with a deeper green for readable contrast.

### Primary

- **Acid Signal** (`signal`): the dark-scheme accent for active playback, verified quality, progress, selected navigation, connectivity, focus, and primary controls.
- **Deep Signal** (`light-signal`): the light-scheme equivalent, darkened to hold contrast against pale mineral surfaces.

### Secondary

- **Brushed Aluminum** (`aluminum`): the cool secondary role for quieter controls and supporting emphasis; it must never compete with the live signal.

### Neutral

- **Anechoic Chamber** (`chamber`): the dark canvas and default scaffold surface.
- **Low Chamber** (`chamber-low`): navigation and the first tonal separation above the canvas.
- **Raised Chamber** (`chamber-raised`): the mini player and other persistent raised regions.
- **High Chamber** (`chamber-high`): artwork fallbacks and stronger nested surface separation.
- **Mineral Type** (`mineral`): primary content on dark surfaces.
- **Trace Gray** (`trace`): subdued readings and descriptive information.
- **Dark Outlines** (`dark-outline`, `dark-outline-variant`): field strokes, dividers, and quiet structural rules.
- **Mineral Paper** (`light-surface`) with low, raised, and high variants: the light-scheme canvas and tonal layers.
- **Graphite Type** (`light-on-surface`): primary content on light surfaces.
- **Light Outlines** (`light-outline`, `light-outline-variant`): structural strokes in the light scheme.

### Named Rules

**The Live Signal Rule.** Chartreuse means active, verified, selected, focused, or progressing. Do not spend it on passive decoration.

**The Artwork Owns Color Rule.** Outside semantic system feedback, album artwork is the only large vivid field.

## Typography

**Display Font:** platform system sans-serif  
**Body Font:** platform system sans-serif  
**Label Font:** platform system sans-serif

**Character:** Native system type keeps Android and Windows familiar and scalable. Thin, tightly tracked display roles create monumental calm; semibold titles and labels carry operational certainty without introducing a separate brand face.

### Hierarchy

- **Display Large:** very light and tightly tracked; reserved for the largest identity or search moments.
- **Display Medium:** the canonical monumental search-entry role.
- **Headline Large:** semibold screen identity, including the compact Hi Hat masthead.
- **Headline Medium:** semibold track titles, empty-state statements, and focused player identity.
- **Title Large:** section headings and the rail wordmark.
- **Title Medium:** track names and compact player identity.
- **Body Large:** prominent supporting copy and artist information, with relaxed leading.
- **Body Medium:** default secondary and descriptive content.
- **Label Large:** semibold technical readings such as VERIFIED SOURCE and OUTPUT; restrained tracking supports calibration-instrument character.

### Named Rules

**The Native Clarity Rule.** Keep the platform system font and semantic Flutter text roles so text scaling and platform familiarity survive every viewport.

**The Monument Rule.** Use display type for the primary act of search, not for routine settings, metadata, or navigation.

## Layout

The shell changes topology at 980 logical pixels. Below that threshold, each destination owns the full safe-area body, a 72-pixel mini player appears above a 72-pixel Material navigation bar when a track exists, and search uses 24-pixel leading padding below 700 pixels. At 980 pixels and above, a navigation rail replaces the bottom bar and a persistent player panel occupies 360 pixels; at 1320 pixels it grows to 440 pixels. The rail is 88 pixels collapsed and extends to 184 pixels from 1260 pixels upward.

Expanded layouts read left to right as navigation, working ledger, and listening instrument, separated by one-pixel dividers. Search header content uses generous vertical staging: a large 54-pixel pause separates identity from the monumental search line, then a calibration rule anchors results. Result content remains dense enough to scan, with 58-pixel artwork, 16-pixel media gaps, and 12-pixel vertical row padding. Player content is centered within 28-pixel padding and uses flexible spacers so artwork and transport remain balanced across window heights.

All primary shells sit inside safe-area insets. Lists scroll independently through slivers; empty and error states center within a readable maximum width rather than stretching. Use the observed 4/8/12/16/18/24/32 rhythm, escalating to 46–54 pixels only between major conceptual regions. Interactive targets must remain at least 48 logical pixels even when the visible icon or mark is smaller.

**The Topology Rule.** Compact uses bottom navigation plus an optional mini player; expanded uses a rail plus a persistent player. Never stretch one topology into the other.

## Elevation & Depth

The system is flat by default and uses Material tonal elevation rather than decorative drop shadows. Four closely stepped surface levels establish shell, navigation, persistent playback, and nested fallback regions; hairline outline-variant dividers clarify structural splits. Modal Material components may retain platform-standard elevation, but content rows and player regions do not float as isolated cards.

**The Absorptive Surface Rule.** Depth should feel like neighboring acoustic materials, not stacked glossy cards. Prefer tonal shifts and dividers to shadows.

## Shapes

Geometry contrasts disciplined rectangles with machined circles. Album artwork is square and clipped gently: thumbnails use the small radius, large player artwork uses the larger radius. Full result rows have a modest interactive radius visible through ink response, but remain visually flat at rest. The primary play/pause control is a true 72-pixel circle; navigation indicators follow Material 3 pill geometry. Underlined fields and straight dividers preserve the ledger character.

**The Instrument Geometry Rule.** Use circles for transport and live control, restrained rounding for media and hit regions, and straight rules for structure.

## Components

### Buttons

- **Primary transport:** a 72-pixel filled circle using the current primary signal color and on-primary icon; play and pause icons are 36 pixels.
- **Action buttons:** standard Material 3 filled or tonal buttons with icons for save, retry, and import actions. Preserve Material focus, pressed, disabled, and high-contrast behavior.
- **Icon buttons:** platform Material icon buttons with tooltips where the action is not already named; the interactive target remains at least 48 logical pixels.
- **Motion:** use Material state transitions. Honor reduced-motion settings by removing nonessential travel and retaining only immediate or cross-faded state feedback.

### Cards / Containers

- **Result ledger:** not a card stack. Each result is a full-width ink-responsive row with thumbnail, identity, quality, and play/progress affordance; one-pixel indented dividers maintain scan rhythm.
- **Empty and error states:** centered, narrow containers with a signal-colored icon, headline, concise body, and at most one recovery action.
- **Artwork:** vivid content when available; otherwise a high tonal surface with a neutral album icon. Never fabricate cover art.

### Inputs / Fields

- **Search:** an underlined, display-sized field with a 36-pixel search icon inside a minimum 48-pixel prefix region. Dark mode uses the mineral content color.
- **Settings fields:** the same Material underline language at normal type scale, with 18-pixel vertical content padding.
- **Focus:** the outline changes to the primary signal and increases to a two-pixel stroke; keyboard focus must remain plainly visible.
- **Errors and disabled states:** use the active scheme's semantic Material error and disabled treatments, not the signal accent.

### Navigation

- **Compact:** three-destination Material navigation bar for Search, Library, and Settings, 72 pixels high, with a low tonal surface and a translucent primary indicator.
- **Expanded:** Material navigation rail with the same destinations, collapsed by default and extended on very wide windows. The HI HAT wordmark leads the rail.
- **State:** selected destinations use the primary-tinted indicator; system Back, keyboard traversal, and standard focus semantics remain intact.

### Track Result Ledger

Each row exposes title, artist, optional album, verified quality, and a play or transfer-progress affordance without opening an intermediate detail screen. Active acquisition disables repeat activation and replaces play with an 82-pixel linear progress reading. Text truncates to one line so quality and action never fall off the row.

### Player Instrument

The expanded player combines large square artwork, centered track identity, a two-pixel seek track, time readings, circular transport, and two calibrated metadata rows: VERIFIED SOURCE and OUTPUT. Acquisition phases appear as honest, plain-language progress beneath those readings. Compact mode reduces this to a 72-pixel tonal strip with track identity and play/pause, keeping playback visible without impersonating the full instrument.

## Do's and Don'ts

### Do:

- **Do** reserve the signal accent for live, verified, selected, focused, or progressing states.
- **Do** use Material 3 navigation, fields, buttons, snackbars, semantics, and interaction states on Android and Windows.
- **Do** preserve artwork, track identity, playback state, verified quality, and output path as the visual information hierarchy.
- **Do** keep every touch target at least 48 logical pixels and support system text scaling, keyboard focus, screen readers, safe areas, high contrast, and reduced motion.
- **Do** express acquisition states explicitly: resolving, downloading, verifying, transferring, local-ready, playing, and failed.
- **Do** maintain both dark and light role-based color schemes rather than applying a mechanical inversion.

### Don't:

- **Don't** turn results, settings, or metadata into a floating-card dashboard.
- **Don't** use chartreuse as ambient decoration, a large background field, or a substitute for artwork.
- **Don't** add gradients, glass effects, arbitrary shadows, promotional banners, recommendation carousels, or streaming-service chrome.
- **Don't** hide lossy fallback or imply quality that has not been verified from the downloaded file.
- **Don't** invent custom navigation, transport gestures, or controls that break Material conventions, system Back, keyboard operation, or accessibility semantics.
- **Don't** animate progress theatrically; state change should be calm, immediate, and informative.
