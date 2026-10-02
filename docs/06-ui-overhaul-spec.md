---
layout: default
title: UI Overhaul Spec — Liquid Glass Map-First
---

# UI Overhaul Spec — Apple Liquid Glass + Map-First Home

**Status:** spec (not implemented). **Goal:** full visual overhaul of the
`commencys` Flutter app — Apple Liquid Glass (iOS 26 style) material system
plus a map-centric home, replacing the current scroll-feed home.
**Non-goals:** no backend, API-contract, or ticket-lifecycle changes
(`docs/02-design.md` stays normative).

> Note: `docs/06-maintenance.md` already uses the `06-` prefix; this file
> reuses it per task instruction, not as part of the SDLC numbering.

## 1. Current-state audit (what "sucks" and why)

Read from `lib/` at HEAD (`7bfc52d`):

| # | Problem | Evidence |
|---|---------|----------|
| 1 | Map is buried one tap deep; home is a static feed | `home_screen.dart` = `CustomScrollView` + SOS hero + 2×2 grid; map lives behind `Live map` card → `/map` |
| 2 | No tab bar at all — 5 disconnected routes, back-stack navigation | `main.dart`: `initialRoute: '/'` + 4 pushed routes, no `TabBar`/`BottomNavigationBar` |
| 3 | Current "glass" is too opaque to read as glass over a map | `GlassCard`: white gradient `0xE6FFFFFF → 0xB8FFFFFF` (90%→72% opaque), blur sigma **18** — over busy map tiles this looks like a white card, not a lens |
| 4 | Glass used in the **content layer**, against Apple guidance | Every list card / form section is a `GlassCard` (alerts rows, report form, home grid) — Apple: reserve glass for the floating navigation layer, never glass-on-glass |
| 5 | Map screen chrome fights the map | `map_screen.dart`: opaque `AppBar`, plain `CircularProgressIndicator` pinned top, `FloatingActionButton.extended` — map gets a letterboxed strip, not full-bleed |
| 6 | No dark-mode story, no motion spec, no low-power fallback | `AppTheme.light()` only; `AnimatedContainer` 200 ms on SOS only; every `BackdropFilter` runs unconditionally |

## 2. Principles (Apple rules, mapped to this app)

From WWDC25 session 219 "Meet Liquid Glass" and
`developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass`,
plus the field report "How to Apply Liquid Glass to Your App" (STRV):

1. **Content-first** — glass frames the map; if glass draws more attention
   than incidents underneath, it is misused. Map tiles = content layer.
2. **Glass lives only in the floating navigation layer.** Search pill, status
   strip, bottom sheet, tab bar, FABs. Incident rows *inside* the sheet,
   form fields, and timeline cards are **flat content** (solid surfaces),
   never `BackdropFilter`.
3. **Never glass-on-glass.** A card on top of the bottom sheet is solid.
   A button on top of the tab bar uses fill/transparency, not blur.
4. **One variant: Regular.** (Apple's Regular vs Clear must never mix.)
   All panels share one recipe family; emphasis comes from tint, not from
   mixing materials.
5. **Concentric radii.** Sheet 28 → cards inside 20 → chips 999; tab bar
   stadium → active capsule nested with equal inset. Inner radius =
   outer radius − padding.
6. **SOS is safety chrome: always visible, never auto-hidden.**
   Apple suggests tab bars minimize on scroll — we explicitly opt out.
   The SOS action is reachable in **one tap from every tab**.
7. **Cohesive 3 C's** (STRV): content-first, concentric, cohesive — a
   single glass component in a flat app reads as a bug. Adopt everywhere
   in the nav layer or nowhere.

## 3. Design tokens

### 3.1 Glass recipes (the core of the overhaul)

All values calibrated against: current `GlassCard` (sigma 18, too flat),
`cupertino_liquid_glass` 0.7.x defaults (`blurSigma: 40`,
`tintOpacity: 0.3`, `edgeLightColor: 0x60FFFFFF`, 52 pt bar / 25 pt icons /
44 pt targets), and Apple "Regular" behavior (adaptive tint + shadow that
deepen when content scrolls beneath).

| Token | `glassBar` (tab bar, search pill, status strip, FABs) | `glassSheet` (draggable bottom sheet) | `glassMarker` (selected-pin callout only) |
|---|---|---|---|
| Blur sigma X/Y | **32** | **28** | 24 |
| Saturation boost | ×1.5 (Rec.709 luma matrix) | ×1.4 | ×1.3 |
| Tint, light mode | white @ 38% top → white @ 16% bottom | white @ 55% → white @ 35% (sheet needs more legibility for lists) | white @ 45% → 25% |
| Tint, dark mode | `#1C1C1E` @ 55% → 35% | `#1C1C1E` @ 72% → 55% | `#1C1C1E` @ 60% → 40% |
| Specular (top-edge sheen) | linear white `0x99FFFFFF → 0x00FFFFFF`, top 40% height | same, top 25% (large surfaces: subtler) | same as bar |
| Edge light | 1 px stroke `0x60FFFFFF` top/left | 1 px stroke `0x4DFFFFFF` top edge only | 1 px `0x60FFFFFF` |
| Hairline border | black @ 7% outside stroke (separation on light tiles) | black @ 7% | black @ 8% |
| Shadow resting | black @ 14%, blur 28, offset (0, 10) | black @ 16%, blur 32, offset (0, −4) (sheet casts *up*) | black @ 20%, blur 16, (0, 6) |
| Shadow scrolled-under | black @ 22%, blur 32 (deepens when map pans beneath) | n/a (sheet *is* the scroller) | n/a |
| Corner radius | stadium (999) for pill/tab bar; 24 for square FABs | **28** top, 0 bottom when docked; 28 all when floating peek | 20 |

Delta vs today: sigma 18 → 28–32; opacity 90/72% → 16–55% range;
add saturation matrix + specular layer + edge light (all missing today).

Suggested implementation shape (hand-rolled, ~150 lines, no new
dependency — see §7):

```dart
// lib/widgets/liquid_glass.dart (new)
class LiquidGlassPanel extends StatelessWidget {
  final Widget child;
  final double sigma;            // 24–32 per §3.1
  final double saturation;       // 1.3–1.5
  final Gradient tint;           // light/dark adaptive
  final Gradient? specular;      // top-edge sheen overlay
  final BorderRadiusGeometry radius;
  final List<BoxShadow> shadow;
  // ...
  // BackdropFilter(ImageFilter.blur) + saturation ColorFilter
  // + DecoratedBox(specular) + border — wrapped in RepaintBoundary.
}
```

The saturation layer is a `BackdropFilter` with a color-matrix filter
(Rec.709 luma + saturation boost), the same technique used by the
`liquid_glass_widgets` package's shader-free mode. One `BackdropFilter`
composites blur + saturation — do not stack two filters per panel.

### 3.2 Radius / spacing / type scale

| Token | Value | Notes |
|---|---|---|
| `r-sheet` / `r-card` / `r-chip` / `r-pill` | 28 / 20 / 14 / 999 | concentric: card inside sheet = 28 − 8 padding = 20 ✓ |
| Tab bar | floating stadium, height **68**, h-margin 16, bottom = safe-area + 12 | content 52 pt, icons 24 px, min target 44×44 |
| Search pill | height 52, radius 999, top = safe-area + 12, h-margin 16 | text 15, w600, hint tertiary |
| Sheet snaps | **0.16 peek / 0.45 half / 0.92 full** (fraction of screen height) | peek shows grabber + summary + horizontal incident cards |
| SOS detached button | Ø 60, center-docked in tab bar, red gradient (existing `sosStart/sosEnd`), white 2 px ring + red glow | overrides glass tint (functional color allowed) |
| Type | system (SF/Roboto), existing `textTheme` kept | titles 20/w800 −0.5 ls; body 14/15; labels 12/w700 for pills |
| Status colors | keep `AppColors` severity + soft pairs verbatim | map pins, pills, timeline unchanged semantically |

### 3.3 Dark mode

New `AppTheme.dark()`: background `#000000` grouped `#1C1C1E`; glass tints
from §3.1 dark column; glyphs on glass flip white (Apple: symbols mirror
glass light/dark flips); map tiles switch to a dark tile style
(CARTO dark-matter URL swap in one `TileLayer` constant — OSM default
has no dark variant). SOS gradient identical in both modes (safety color
must not shift).

### 3.4 Motion

| Interaction | Spec |
|---|---|
| Tab switch capsule | `SpringSimulation`, stiffness ≈ 300, damping ≈ 26; capsule slides, icon scales 1.0 → 1.12 |
| Sheet drag | `DraggableScrollableSheet`, snap to §3.2 fractions, `ClampingScrollPhysics`-like fling; no springs on release (must feel deterministic) |
| Pin tap → callout | scale 1.0 → 1.15 in 180 ms `easeOutCubic`; callout fades/slides 8 px up in 220 ms |
| SOS press | existing 200 ms container morph kept; add haptic (`HapticFeedback.heavyImpact()`) on fire |
| Live alert arrival | status strip pulses once (opacity 1 → 0.55 → 1, 600 ms), list inserts with size-fade |
| Reduce motion / high contrast | `MediaQuery.disableAnimations` → all durations → 0; high-contrast / reduce-transparency → `enableGlass: false` fallback: solid `systemGrey6`-equivalent surfaces, zero `BackdropFilter` cost |

## 4. Recommended layout: full-bleed map home

`/` becomes `MapHomeScreen` — the map **is** the home. All five current
routes collapse into one surface + tab bar:

```text
┌─────────────────────────────┐
│ ▓▓ MAP (full-bleed tiles) ▓▓ │  ← flutter_map, edge-to-edge,
│ ┌─────────────────────────┐ │     no AppBar, extends behind
│ │ 🔍 Search pill (glass)  │ │     status bar + home indicator
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │ ● 3 active near you [2!] │ │  ← status strip (glassBar)
│ └─────────────────────────┘ │
│                             │
│         (pins layer)        │  ← severity-ring markers (§6),
│                    ┌───┐    │     own-location blue dot +
│                    │ + │    │     accuracy circle
│                    ├───┤    │
│                    │ ◎ │    │  ← Report FAB / recenter (glassBar,
│                    └───┘    │     stacked, right, above tab bar)
│ ┌─────────────────────────┐ │
│ │ ══ grabber              │ │  ← DraggableScrollableSheet
│ │ Nearby · 3 incidents    │ │     (glassSheet): peek 0.16 →
│ │ [card][card][card] →   │ │     horizontal incident cards;
│ └─────────────────────────┘ │     half 0.45 → list; full 0.92 →
│ ┌─────────────────────────┐ │     list + filters + timeline
│ │Map Alerts (SOS) Report ☰│ │  ← floating glass tab bar (68 h)
│ └─────────────────────────┘ │
└─────────────────────────────┘
```

Z-order (bottom → top): tiles → accuracy circle → pins → own dot →
bottom sheet → right-side FABs → status strip → search pill → tab bar →
SOS detached button → incident callout sheet → SnackBar.

Behavior rules:

- **Sheet vs tab bar:** sheet at peek/half leaves the tab bar visible and
  interactive; sheet dragged past 0.6 **covers** the tab bar (tab bar
  fades out in 150 ms, returns when sheet drops below 0.6). No glass-on-glass.
- **Search pill** filters pins + sheet list by text; submitting also
  geocodes-against-known-landmarks (client-side list first, no new backend).
- **Status strip** mirrors today's map-screen banner (green dot / count /
  urgent pill) and doubles as the WS live indicator (`LIVE`/`SYNCING`
  pill moves here from `alerts_screen.dart`).
- **Right FAB stack** (bottom-up, 16 px above tab bar): recenter ◎
  (glassBar circle Ø 52) → report ＋ (glassBar circle Ø 52, red tint).
  The old `FloatingActionButton.extended` is deleted.
- **Pin tap** does not open a modal: it selects the pin (ring highlight)
  and expands the sheet to half with that incident's detail card pinned
  to the top of the sheet + `StatusTimeline` inline. One tap less than
  today's modal-bottom-sheet path.
- **Keyboard:** search focus expands sheet to half (form space); report
  flow opens as a **full-height glass sheet route** (`/report` kept as a
  route, restyled: glass app bar + flat form cards — form fields are
  content layer, solid white).
- **`/sos` stays a full route** (never a sheet — must not be
  swipe-dismissable in a panic). Entry: center SOS button (tap = arm
  confirm sheet with big red slider? No — fail-safe today is tap-to-send;
  keep tap-to-send, add 3-2-1 abort window after fire) + `SOS mode` paths.
- **`/alerts` stays a route** behind the Alerts tab, restyled: glass app
  bar, flat rows (rows lose `GlassCard`, gain solid `card` surface —
  fixes violation #4).
- **Server/backend setting** (today's `_ServerDialog` on home) moves to
  the ☰ tab (5th tab: Menu — server URL, dark-mode toggle, reduce-glass
  toggle, about + 112/119 disclaimer).

## 5. Tab bar spec (floating glass)

Five slots, `glassBar` stadium container:

`[Map] [Alerts(+badge)] [(SOS) center Ø60 red] [Report] [☰ Menu]`

- Active tab: glass capsule highlight (white @ 35% light / white @ 18%
  dark) sliding with spring (§3.4); inactive icons tertiary, active ink
  (or red for Alerts when an unacknowledged critical exists — the only
  functional tint besides SOS).
- Badge on Alerts = count of unacked critical/high; max "9+".
- Touch-down (not touch-up) activation + selection haptic, per
  `cupertino_liquid_glass` tab-bar behavior and iOS `UITabBar`.
- Semantics: each tab exposes label + "Tab X of 5" + selected state.
- Never auto-hides on scroll (overrides Apple's minimize-on-scroll;
  justified in code comment: emergency reachability).

## 6. Map layer spec

- Tiles: keep OSM default light; add dark-matter URL for dark mode;
  attribution retained (OSM license requirement) as a subtle bottom-left
  chip above the sheet peek (not inside the tab bar).
- Pins: keep the severity-ring circle concept, restyle — solid soft-color
  fill (no blur on pins: they sit *on* content, tiny blur areas are pure
  GPU cost), 2 px severity stroke, white inner icon (`categoryIcon`),
  shadow from §3.1; critical pins get a slow pulse ring (pauses under
  reduce-motion). Selected pin: +4 px ring in ink color + callout card.
- Own location: system-blue dot + accuracy-radius circle (uses
  `accuracyM` already plumbed in `LocationService`/models).
- Clustering: client-side grid cluster for zoom < 13 (count bubble,
  ink fill, white text); expand on tap by zooming one level. No backend change.
- Offline: tiles fail → flat grouped-background + existing `EmptyState`
  copy; pins from last fetch persist with "offline — showing cached" line
  in the status strip.

## 7. Implementation plan

**Dependency decision:** hand-roll `LiquidGlassPanel` (recommended).
Rationale: the surface is small (4 recipes, §3.1); both candidate
packages are pure-Dart but would force an SDK bump (`pubspec.yaml`
pins `sdk: '>=3.2.0 <4.0.0'`, `cupertino_liquid_glass` needs Flutter
3.32+/Dart 3.11+) and import a tab-bar/spring system we only partly
want (we diverge: no auto-hide, center SOS). Borrow their *parameter
defaults*, not their code. Revisit only if native `glassEffect` parity
is ever required (needs a platform bridge — out of scope).

New files:

- `lib/widgets/liquid_glass.dart` — `LiquidGlassPanel` + `SpecularPainter`
  + saturation matrix const + `GlassFallback` (`enableGlass: false` branch).
- `lib/widgets/glass_tab_bar.dart` — floating bar, capsule + spring,
  center SOS slot, badges, semantics.
- `lib/widgets/search_pill.dart`, `lib/widgets/status_strip.dart`.
- `lib/screens/map_home_screen.dart` — full-bleed map + sheet + FABs
  (absorbs current `home_screen.dart` + `map_screen.dart`).
- `lib/screens/menu_screen.dart` — server URL, theme, glass toggle, disclaimer.
- `lib/theme/app_theme.dart` — add `dark()`, glass token consts (§3.1).

Modified: `main.dart` (tab root, 5 tabs, `/sos` + `/report` full routes);
`home_screen.dart` + `map_screen.dart` → deleted after migration;
`alerts_screen.dart`, `report_screen.dart`, `sos_screen.dart` — de-glassed
content cards, glass app bars; `glass.dart` — `GlassCard` deprecated
(documented shim over `LiquidGlassPanel` for one release, then delete);
`status_timeline.dart` — unchanged logic, flat card container.

Performance rules (hard): ≤ 4 concurrent `BackdropFilter`s on screen
(pill, strip, sheet, tab bar — callout replaces sheet's, never stacks);
every glass panel in a `RepaintBoundary`; sheet list rows are plain
`Container`s; profile pan-at-120 Hz on a mid device before merge.

## 8. Accessibility & safety acceptance

- Contrast: ink-on-glass ≥ 4.5:1 in both modes (verify with titles over
  darkest/lightest tile samples, not over blank backgrounds).
- Every pin is a semantic button ("Fire incident, high severity, 300 m").
- SOS reachable in 1 tap from any tab; `/sos` never behind a dismissable sheet.
- `acknowledged ≠ dispatched` rendering (§2-design lifecycle) preserved
  verbatim in the sheet detail card — overhaul must not re-style the
  timeline into ambiguity (keep green-only-at-≥-dispatched rule).
- 112/119 disclaimer survives on SOS screen + Menu (legal copy, do not drop).

## 9. Build order + verification

1. Tokens + `LiquidGlassPanel` (widget gallery route in debug only,
   screenshot over light/dark tiles). ✓ contrast spot-check.
2. `MapHomeScreen` shell: full-bleed map + search pill + status strip
   (no sheet yet). ✓ existing `_load`/markers logic moved untouched.
3. Sheet (3 snaps) + pin-select wiring + detail card + timeline. ✓ one-tap-less flow.
4. Tab bar + 5-tab IA + Menu screen; delete old home/map screens. ✓ nav test.
5. De-glass alerts/report/SOS content; dark mode; fallbacks. ✓ `flutter analyze`, golden screenshots light/dark, 120 Hz pan profile.

Done = all §8 checks pass + `flutter analyze` clean + manual pass on a
physical phone (server-URL setting in Menu pointing at LAN backend,
per `app_config.dart` docs).

## 10. Open questions

- Dark tile provider: CARTO dark-matter (free with attribution) vs
  self-hosted — CARTO assumed, confirm ToS for emergency use.
- Search geocoding: client-side landmark list v1 — acceptable?
- Confirm keeping tap-to-send SOS (vs press-and-hold) — safety review.

## References

- Apple WWDC25 Session 219, "Meet Liquid Glass" (lensing, adaptive
  layers, Regular vs Clear, no glass-on-glass, scroll edge effects).
- Apple Developer Documentation, "Adopting Liquid Glass" (floating tab
  bars, minimize behavior, concentric controls, sheet radius, safe areas).
- STRV, "How to Apply Liquid Glass to Your App" (3 C's: content-first,
  concentric, cohesive; floating tab bar + capsule indicator).
- `cupertino_liquid_glass` 0.7.x (pub.dev) — parameter defaults borrowed:
  `blurSigma: 40` scale, `tintOpacity: 0.3`, `edgeLightColor 0x60FFFFFF`,
  52 pt bar / 25 pt icons / 44 pt targets, spring tab bar, grouped
  backdrop readback, `enableGlass: false` fallback.
- `liquid_glass_widgets` (GitHub) — shader-free recipe: `BackdropFilter`
  blur + Rec.709 saturation matrix + specular rim stroke; high-contrast
  fallback to plain frosted panel.
- NN/g, "Bottom Sheets: Definition and UX Guidelines" — snap discipline,
  back-to-dismiss, sheet/tab interplay informing §4 behavior rules.
