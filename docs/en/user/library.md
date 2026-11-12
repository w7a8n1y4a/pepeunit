# Library

The `Library` section works without signing in.

Cell | What it opens
-- | --
`Presentation` | A full-page interactive introduction to Pepeunit, about 5 minutes long
`Documentation` | This documentation
`Tools` | `README generator`
`About` | Version, updates, apps, links, project support
`Tree of 6 paths` | All screens and cells of the client on one map

## Presentation

Nine slides for a live presenter: Units, the path from Git to a device, updates, MQTT connections, operations, DataPipe and Grafana, self-hosting and federation. Also opens directly at `/library/presentation`, without signing in.

- Navigate with the buttons, `←` / `→`, `Page Up` / `Page Down`, Space to advance, or horizontal swipes. `Home` and `End` go to the first and last slides. The `Slides` button opens a honeycomb slide map.
- Select components, connect a sensor to a fan, change the temperature and enable a data filter. These are local demonstrations with sample data.
- The `Notes` button (`N` on narrow screens) or the `N` key shows the presenter script and planned time range. Notes appear on the presentation screen itself; hide them when showing the audience.
- Click the timer to start or pause it. The speaking plan totals `5:00`; the presenter advances the slides. The final slide offers a “Go to main menu” button, a restart that resets the timer and a link to the first Unit guide.
- `RU` / `EN` switches the presentation language. The fullscreen button or `F` enters fullscreen when supported by the browser. Close with the cross button. `Esc` closes the presentation when the browser does not intercept it to leave fullscreen.

On narrow or short screens, slide content scrolls while navigation remains available. When an interactive control has focus, arrows and Space operate that control; click an empty part of the slide to restore presentation keyboard navigation.

## Documentation

The table of contents is on the left, the text of the article on the right. On a wide screen, the outline of the article itself sits next to it: a tap takes you to a heading. The page address keeps the open article and section, so you can share it: the icon next to a heading copies the link.

The `RU` / `EN` mark on the top bar switches the language of the documentation. The open article stays open. The choice is kept and does not change the language of the app: [Account](/user/account).

Hotkeys:

- `Ctrl+K` / `Cmd+K` or `/` - search the whole documentation
- `Ctrl+F` / `Cmd+F` - search the open article. The browser's own search does not see the client's text

The tip of a cell leads to the right article: [how to open it](/user/start#how-the-screen-works).

## Tools

`README generator` turns [pepeunit.toml](/developer/files/struct-pepeunit-toml) into [readme.md](/developer/files/struct-readme) for a `Unit` repository. Pick a file or drop it on the cell. Signing in is required.

## About

Cell | What it does
-- | --
`Client version` | The current version
`Check updates` | Looks for a new version and shows what changed in it. In the desktop and phone apps it can be downloaded right away
`Native apps` | Client files: `Android` - `.apk`, `iOS` - `.ipa`, `Linux` - `.AppImage`, `macOS` - `.dmg`, `Windows` - `.exe`
`Social` | Pepeunit communities and repositories
`Support` | Addresses for supporting the project, spending rules, and `CSV` reports

## Tree of 6 paths

A map of all screens: the main menu is in the center, surrounded by compact section branches with their screens and cells. The wheel and a pinch change the scale, dragging moves the map. The search at the top looks for a screen or a cell and draws the path to it from the main menu.

The bottom right shows the current role (`Bot`, `User`, `Admin`, or `Owner`) and an availability bar. Its filled portion represents available screens and cells; the number inside shows available out of total. Without signing in, the role is `Bot`. Availability also depends on the selected instance and its enabled sections. Unavailable nodes remain dimmed on the map; their cards explain the restrictions.
