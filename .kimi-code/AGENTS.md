<!-- Imported from Cursor: /home/w7a8n1y4a/Documents/gitlab/pepe/pepeunit/pepeunit/.cursor/rules/client.mdc -->

# Pepeunit client

Flutter app at the repo root. UI is custom hex cells (`lib/hive`). Platforms: web, linux, macos, windows, android, ios.

Code is the source of truth. Read these files; do not copy them into answers or comments:

- sections, accent colors, icons, axial coordinates — `menuSections` in `lib/navigation/sections.dart`
- section visibility — `menuSectionEnabled` in `lib/instances/network_view.dart`
- routes — `lib/main.dart` (`go_router`, path URL strategy)
- backend window — `backendCompatible` in `lib/api/backend_version.dart` (currently `1.5.x`)
- scene colors — `sceneBackground`, `hexFill`, `hexMuted`, `errorColor` in `lib/hive/hex_scene.dart`
- scale ticks — `scaleTickCells` in `lib/hive/hex_order.dart`
- background mosaic — `HiveBackground` and `Mosaic` in `lib/hive/background.dart`, pictures in `lib/hive/icon_atlas.dart`; it sits under the router in `lib/main.dart`
- press effects and the echo lines between cells — `lib/hive/hex_motion.dart`; instant screen change — `lib/hive/page_transition.dart`
- plan and open questions — `roadmap/frontend-refactor.md`, and only when the task is about the plan

Modules: `account/`, `instances/`, `hive/`, `features/{account,network,home,menu,code}`, `locale/`, `api/`. Shared screen pieces: `features/hex_page.dart` (Back, error cell), `features/file_drop.dart`, and `features/line_input.dart` (underlined field and its validation line). `popOrHome` is `navigation/back.dart`. A screen that returns a choice to its opener uses `openPick` / `givePick` from `navigation/pick.dart`, never `context.pop`, because a scale change replaces the route. Every code, log, and notice modal is one `CodeModal` with a `CodeView`, `CodeEditor`, or `LogView` body from `features/code/`; pure text helpers for it live in `units/code_format.dart`.

Constraints:

- Screens are pointy-top hex cells. Input changes per platform (mouse / touch); the renderer stays shared.
- Dark theme only. Icons are SVG in `assets/icons/<category>/`, mainly white. Categories: `sections` (home menu), `actions`, `status`, `objects`, `services`. A new icon goes into one of them, and the folder is listed in `pubspec.yaml` because Flutter does not read subfolders. UI font is OpenGost.
- Every SVG asset must either be created specifically for this project, including generated artwork, or be third-party artwork under a verified MIT license. This applies to commercial use and the sale of any part of the app. For third-party assets, record the source, author, license, and modifications, and preserve the required copyright and license notices. Never copy, trace, or derive an SVG from artwork with an unknown or non-MIT license.
- The background mosaic draws every SVG under `assets/background/<theme>/` and nothing from `assets/icons/`, so a new file appears there by itself. The themed catalog is white outline SVG on a 64×64 box, drawn for the mosaic only, and a theme folder is listed in `pubspec.yaml` like the icon folders. Pages stay transparent; the scene color is set once in `main.dart`. Tests build `PepeunitApp(background: false)`.
- Account storage is `PlatformVaultStore`. API client is hand-written: `PepeunitApi`.
- Roles and `pu_ff_*` flags from the instance portrait limit actions and menu items.
- Implement a roadmap item marked «план» only when the task names it. An spacing fix on home does not include the background mosaic, animations, or deep links.
- A menu level exists to reach an action. Add another level only when the screen is unreadable without it.
- Reply to the user in Russian. Code, identifiers, and these rules stay in English.

<!-- End imported from Cursor: /home/w7a8n1y4a/Documents/gitlab/pepe/pepeunit/pepeunit/.cursor/rules/client.mdc -->

<!-- Imported from Cursor: /home/w7a8n1y4a/Documents/gitlab/pepe/pepeunit/pepeunit/.cursor/rules/hex-scale.mdc -->

# Hex scale

A scale tick caps how many cells may be on screen, including Back. The count is `scaleTickCells` in `lib/hive/hex_order.dart`. Placement and fill order stay as in `hex-layout.mdc`. A tick only decides how far along that order the screen may go.

- Tick 1: 7 cells
- Tick 2: 10 cells
- Tick 3: 13 cells
- Tick 4: 16 cells
- Tick 5: 19 cells

Each step after tick 1 adds three cells. The wheel and a two-finger pinch move one tick. Scroll up or pinch apart raises the tick. Scroll down or pinch together lowers it. The gesture hits the whole scene, including empty gaps, not only a cell.

Menus stay on tick 1 and do not zoom. A static form does not zoom; it keeps the cells that screen defines.

Search screens open on tick 3: peer search, user search, repository search, and the alerts list. Their tick moves from 1 through 5 in either direction. A list that still overflows at tick 5 pages. Other zoomable lists open on tick 1 and rise only while the next tick still shows another cell.

An error is always shown. It takes the next free slot in the current tick. When that tick is full, the screen may use one tick more, and the error takes the next free slot there. The query tick does not change.

The query key stays `scope`. Its value is the tick.

<!-- End imported from Cursor: /home/w7a8n1y4a/Documents/gitlab/pepe/pepeunit/pepeunit/.cursor/rules/hex-scale.mdc -->

<!-- Imported from Cursor: /home/w7a8n1y4a/Documents/gitlab/pepe/pepeunit/pepeunit/.cursor/rules/hive-ui.mdc -->

# Hex UI

Scope: apply these rules when working with `lib/hive/**` or `lib/features/**`.

Rendering is `HexSlot`, `HexPainter`, and `HexLayout` in `lib/hive/hex_scene.dart`. Take section colors and accents from code.

Menu cell anatomy:

1. Border uses the section accent. The Back cell uses `hexMuted`.
   A cell may carry `HexSlot.rim` instead of one border color: `hexRimSegments` colors (6 sides × 8), clockwise from the top vertex. `rimMix` alternates colors around the border in proportion to their weights. The unit menu `Inputs and outputs` cell is the first user: input and output counts.
2. Label sits on the upper-left edge. Text longer than 12 characters runs along both upper edges.
3. Center is an SVG icon, a PNG avatar, or text. An icon may carry a short caption on its lower half through `HexSlot.center`, like the extension on a file icon: the DataPipe editor cell shows `.yml` on `file.svg`. A choice and a value in the same cell use `cellFont`: 0.068 of the cell side, at least 11. Log levels and account parameters are the reference.

The scene and the cell fill are rough, not flat (`GrainTile` in `lib/hive/grain.dart`, `sceneGrain` and `cellGrain` in `hex_scene.dart`). Every pixel of the scene is opaque; a cell fill is drawn at `hexFillOpacity`, so the mosaic shows faintly through it. `CodeModal` uses the same grain, denser: `GrainBox(tile: cellGrain, opacity: modalFillOpacity)` inside a `BevelFrame` (`lib/hive/bevel.dart`): the four corners are cut, never right angles, and the border runs over the grain. Panels inside a text use the same frame. A new panel does not take a flat `hexFill`. Every pixel strays a little from its neighbour inside a narrow band around the palette color: `sceneBackground` and `hexFill` stay the mean of their grain. One noise tile is made in code and tiled. A grain is `GrainTile.texel` device pixels, so it keeps its size on every scale tick and screen density. The scene grain sits under the router in `main.dart` (`GrainBox`), under the mosaic.

Icon size is `iconScaleOf` in `lib/hive/icon_scale.dart`. `HexScene` applies it, and a screen does not pass a scale. One file is one size on every screen. The icon square is `0.72` of the cell radius, the size of `back.svg` and the home menu. Ink shorter than `instances.svg` (0.88 of that square) grows until its longer side matches. Icons that already fill the square stay at 1. The ceiling is 1.6, where the picture meets the edge labels. `settings.svg` is 1.6, `power.svg` is 1.5, `telegram.svg` and `sight.svg` are 1.2. Avatar circles stay `1.15 * 0.85` of the radius. When an icon file changes, re-measure its opaque pixels and update the fill.
4. Lower edges may carry `footer` and `footerLeft`. From 13 characters a lower caption spans both lower edges. `sideRight` and `sideLeft` run along the vertical edges and are read from the bottom up. User cards put the role on the right. Repo cards put the size on the right, the linked unit count on the lower left as `N шт.`, and public or private on the lower right. The home registry cell puts the repository count on the lower right, `N шт.`
5. Hover on a tappable cell brightens the border and scales the border, the edge labels, and the picture together, and only after the pointer moves. A form cell stays still; the clickable rows inside it scale on their own. A tap that stays on the screen sends a short ray burst: six rays in the cell color (`PressPainter` in `lib/hive/hex_motion.dart`). While a waiting ring, a burst, or an echo line plays, the background mosaic rests (`MotionLoad`, `MotionLease`), so those frames are not shared with it. A tap that opens another menu does not.
6. While `busy` is set on that cell, three arc segments rotate in the gap between the center mark and the edge labels until the request ends. The cell keeps its own color. Only the pressed cell is busy.

7. A command or a sync cell that ends sends one echo over the scene: lines in the gaps between touching cells, `addColor` on success and `errorColor` on failure. All the lines are one path and pulse together: they come up and go out, so they share one brightness. An edge with no cell on the other side gets no line, so the outer contour never closes. A screen passes a new `HexEcho` to `HexPage` after each such request: unit commands, the instance commands menu, repository and dashboard sync, the peer scan, and a tap on the card of a repository, unit, node, dashboard, or panel, which reads that entity again (green when it was read, red when it failed). Saving a setting sends none.

Screens change at once, with no transition and no wait (`InstantPageTransitions` in `lib/hive/page_transition.dart`). Do not add one back: a delay shows the old screen under the transparent new one.

Motion stays light. A press effect or an echo is a few primitives driven by one controller, with nothing allocated per frame. A cell keeps its border, captions, and picture in one `RepaintBoundary`, so an effect above it never paints the glyphs again. Reduced motion from the system turns off the press effect and the echo.

Placement, fill order, and menu Back slots are in `hex-layout.mdc`.

The gap between borders scales with the cell. Sizes are standard, reduced, enlarged, or a custom multiplier. A form scrolls vertically when it overflows. Padding follows the aspect ratio and keeps the used area as large as it can.

Screen size changes labels, cells, and icons. Platform changes input only. Outside a menu, Back sits where that screen defines it.

Scale ticks, the wheel, and pinch are in `hex-scale.mdc`. `ScopeFrame` reads the tick from `?scope=`. Static forms keep zoom off.

On a combined screen, secondary actions go into a submenu. Cell size shows hierarchy. A card does not show every action at once.

<!-- End imported from Cursor: /home/w7a8n1y4a/Documents/gitlab/pepe/pepeunit/pepeunit/.cursor/rules/hive-ui.mdc -->

<!-- Imported from Cursor: /home/w7a8n1y4a/Documents/gitlab/pepe/pepeunit/pepeunit/.cursor/rules/hex-layout.mdc -->

# Hex placement

Scope: apply these rules when working with `lib/hive/**` or `lib/features/**`.

Address a cell by ring and angle. Store the slot as axial `(q, r)` for `HexLayout`. Angles are degrees around the center cell: 0° is right, 90° is up, counter-clockwise. Positive `r` in `HexLayout._axial` is down.

Ring 0 is the center. Ring N is a one-cell-thick perimeter of 6N lattice cells. The nominal step is `360 / (6N)` degrees. Ring 1 and ring 2 land on these angles exactly. From ring 3 the address is the lattice cell of that ring nearest the nominal angle. Do not place a ring on one circle of equal radius.

- Ring 1: 0, 60, 120, 180, 240, 300
- Ring 2: those, plus 30, 90, 150, 210, 270, 330
- Ring N: multiples of `360 / (6N)`

Ring 1 `(q, r)`: 0° `(1, 0)`, 60° `(1, -1)`, 120° `(0, -1)`, 180° `(-1, 0)`, 240° `(-1, 1)`, 300° `(0, 1)`.

The center cell is the screen center. A larger cluster stays centered on it.

## Fill order

The center cell is first. Finish ring N before ring N+1. Home slots stay `menuSections`; this order lays out a variable set of cells.

Portrait or square (`width <= height`), each ring:

1. Top, 120° → 60° inclusive
2. Bottom, 300° → 240° inclusive
3. Left, (120°, 240°) exclusive, angle increasing
4. Right, 60° → 300° the short way through 0°, exclusive

Landscape (`width > height`): left, right, top, bottom, with the same arcs and directions.

Top and bottom are filled first on a tall screen, so the cluster gains height before width. Left and right are filled first on a wide screen, so it gains width before height.

## Menu

A menu stays on scale tick 1. How many cells a tick allows, and when an error may raise that tick, is in `hex-scale.mdc`.

Back is `assets/icons/actions/back.svg` with a `hexMuted` border. The home root has none. On an intermediate menu layer, Back is ring 1 at 300°. On the last menu layer, Back is the center. That slot is reserved. Content cells take the next free slot in the fill order.

<!-- End imported from Cursor: /home/w7a8n1y4a/Documents/gitlab/pepe/pepeunit/pepeunit/.cursor/rules/hex-layout.mdc -->
