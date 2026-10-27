# Design

- Colours are asset-catalog colour sets named after the tokens; `Theme.swift` exposes them as `Color.ink.*`-style statics. Heatmap steps are an array.
- The tab bar is a custom capsule overlay (`.glassEffect` with a dark tint, hairline stroke, deep shadow) over a hidden system tab bar, so the selected pill can be tinted.
- Display font: `Font.custom("SpaceGrotesk-SemiBold", size:, relativeTo:)` with `@ScaledMetric` helpers. The TTF is registered with `UIAppFonts`.
