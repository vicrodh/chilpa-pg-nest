# Chilpa Nest

This update targets **Chilpa 0.1.3** and its matching plugin contracts.
Release and catalog publication are pending that host release.

**Early-stage experimental plugin. Ideas and feedback are welcome:**
please open an issue with suggestions, rough edges or test results.

A visual library of CD jewel cases, viewed spine first, for mouse and touch.
Double-click or double-tap a case to pull it out and rotate it in 3D within its shelf. Swipe it horizontally
to turn it over; the generated back contains the album's actual track list.
Tap the open case once to reveal Chilpa's existing album overlay. Play loads
the CD, and Eject returns it to its case. Drag the CD into either player.

## Presentation and controls

Nest opens as a complete presentation in the existing Chilpa window. Its
View submenu appears in the standard player's existing flyout. Search is
the only header control. Escape closes a panel, overlay or case before
leaving the presentation; F11 toggles fullscreen and exit restores the
previous window geometry. The library surface, selection and playback are
shared, rather than copied into a second application or audio engine.

The standard NPB remains the default and gains an Eject action while Nest
is active. Enable **Use Nest player** in Nest settings for the optional CD
Deck, based on the supplied design. Standard menus, switches, select fields,
search and album overlays use actual Chilpa components and Theme tokens.

The deck has black and warm silver finishes, with bottom, left and right
docking. Bottom profiles are Full (112 logical px), Slim (76) and Minimal
(64). Auto selects Slim for windows at most 600 px tall or below 1100 px
wide. Slim keeps the visible disc; Minimal uses a slot loader. Both preserve
44 px transport targets at 1024 × 600. The disc stays still during playback.
An optional spectrum is available in wide full decks and tall vertical decks;
it is off by default and uses all 16 bands of the host's real feed, with
12 segments per band and a 25 Hz cadence.
Volume follows the host, including a locked output; seek, previous/next,
stop, pause, shuffle and repeat use its transport. Stop retains the disc.
The spectrum follows audible host playback even when no CD was loaded through
Nest. In that state the LCD shows the current track and transport keys stay
available; Eject still requires a loaded disc.

The primary compact target is a Raspberry Pi 4 with a 1024 × 600 touch
screen. The supplied artifacts are Linux x86_64; an ARM build and physical
Pi/touchscreen smoke are still required. Desktop fixture results do not
establish Raspberry Pi frame rate.

## Shelves, ordering and finishes

Choose Auto or one to four shelves. Auto fits the available height; a fixed
count that does not fit scrolls vertically and snaps to complete shelves.
Every shelf also supports horizontal dragging and inertial flicking.
Delegates and artwork are virtualized. Smaller type leaves more of each
spine readable. Optional separators and the scrolling # / @ / A–Z index
help navigate large libraries without copying the catalog into the plugin.

The default is Artist > Year. Grouping also supports album title, primary
genre, year, decade, label, source and no groups. Secondary order supports
album A–Z / Z–A, year ascending / descending and recently added. The native
host album model owns grouping, ordering and paging.

Chilpa finish follows the active Theme, accent and ambient background. Only
the space behind the cabinet responds to ambient; the shelf and CDs remain
opaque. Black, White and Wood are fixed finishes, with a small tiled wood
graining resource. Preferences survive reopening and package replacement.

Settings adapt to one or two columns and use the available window height.
Scrolling appears only when their content exceeds that space. The same
settings are reachable from the standard NPB submenu and the CD Deck.

The Filters tab selects sources and optionally shows only favorite albums.
These choices belong to Nest and preserve the host library's filters. A remote
album saved to the library is independent of its explicit favorite status.
The source must expose that status; membership alone never creates a heart.
Local albums use Chilpa's existing favorites. The loaded album can be reopened
from View and ejected through its shared album overlay's More menu.

Nest follows Chilpa's active language, including changes while the view is
open: English, Spanish, German, French, Portuguese, Japanese, Dutch and Russian.

## Real spines and solid fallbacks

Solid spines are the default, including after Reset to defaults. Enable real
spine images to use existing scans and automatic lookup; an explicitly saved
choice stays unchanged on upgrade.

One automatic resolver visits visible CDs after scrolling settles. It first
checks the album's MusicBrainz release ID from existing metadata. Otherwise
it searches public CD editions through MusicBrainz and Cover Art Archive.
Only an identified edition or a unique high-confidence year match with an
explicit Spine image is applied automatically. A Back scan alone is offered
for review and cropping; it is not proof of a spine. Availability is limited
by the archive and edition metadata. No authentication tokens are read, and
existing front covers are preserved.

The review panel places available scans first in compact rows, hides failed
editions by default, and allows retry, edge cropping or local PNG/JPEG/WebP
import. Horizontal strips rotate on save. Local import works offline.

Without a reliable spine, the background is the dominant cover color, with
black or white text chosen for the higher contrast, at least 4.5:1. Front
covers are not stretched into fake spines. Real scans retain their graphics,
including collection panoramas. If a cached scan is evicted, the solid
fallback remains usable.

## Host compatibility and trust

Version 0.5 requires the **feat/nest-efficiency** host changes in addition to the
trusted_ui connector. Install and test it with the matching host binary.
The reviewed source and binary identities are recorded in compatibility.json
and in the local validation evidence. Stock hosts lacking this extension
cannot provide Nest's complete presentation or deck integration.

The package uses API version 1, process protocol 1, register_panel and
trusted_ui for qml/Nest.qml. Trusted QML and its native helper execute inside
Chilpa with application, filesystem and network privileges. The process
sandbox does not restrict that interface. Install only code you trust.
Approval and disable/replacement lifecycle are enforced by the host.

The host presentation contract is exposed as the root `display` object:
version 1, host binding, menuEntries and command(action), canLoad/canEject,
dragAlbum, and the optional playerComponent/playerDock/playerExtent/
trayTarget/useCustomPlayer and ambient/minimumWidth/minimumHeight fields. The host mounts one approved component,
provides its existing transport and detaches it on permission revocation.
After a package update, reopen its approved view from the View menu;
preferences are retained.
The process worker only negotiates lifecycle; it owns no catalog or audio.

## Build and try

Requires Linux, C++17, Python 3, pkg-config and Qt 6 Core, Quick, Gui and
Network development packages, including moc.
The helper links Qt dynamically.
Build a separate package for every OS/architecture advertised.

```sh
python3 tools/build-native
python3 tools/run-host /path/to/compatible/chilpa-qt
```

The ZIP and SHA-256 go to dist/. Rebuilding preserves previous archives in
dist/history by their hashes. The packager puts the QML components in one
versioned entry, and native types under a content-hashed module path, so
replacement does not retain old child components or native type identities.
Demo controls, covers and metadata are excluded from the installable ZIP.
DSEG7/DSEG14 Classic Bold are bundled under SIL OFL 1.1, with their license.
Hardware glyphs are static SVG; the disc uses a bounded precomposed texture.

An audio-free synthetic preview requires PySide6 QtGui and QtQml:

```sh
python3 tools/preview --theme wood --case
python3 tools/preview --theme dark --back
python3 tools/preview --size 1440x480 --theme wood --record /tmp/nest.mp4
```

## Verification

```sh
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
  XDG_CACHE_HOME=/tmp/nest-test-cache \
  /usr/lib64/qt6/bin/qmltestrunner -input tests
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=rhi QSG_RHI_BACKEND=opengl \
  /usr/lib64/qt6/bin/qmltestrunner -input tests/tst_spectrum.qml
python3 -m unittest discover -s tests -p 'test_*.py'
python3 tools/check-host /path/to/compatible/chilpa-qt \
  dist/chilpa-nest-0.5.7-linux-x86_64.zip
python3 tools/check-host /path/to/compatible/chilpa-qt \
  dist/chilpa-nest-0.5.7-linux-x86_64.zip --performance --renderer opengl
python3 tools/check-host /path/to/compatible/chilpa-qt \
  dist/chilpa-nest-0.5.7-linux-x86_64.zip --renderer opengl \
  --previous-package /path/to/chilpa-nest-0.5.6-linux-x86_64.zip
python3 tools/check-host /path/to/compatible/chilpa-qt \
  dist/chilpa-nest-0.5.7-linux-x86_64.zip --signal-fixture --renderer opengl
python3 tools/benchmark --gpu --size 1024x600 --output /tmp/nest-perf.json
python3 tools/benchmark --gpu --size 1024x600 --shelf-size 992x440 \
  --palette-check --matched-scroll --max-unready-ratio .01 \
  --output /tmp/nest-scroll-colors.json
python3 tools/measure-spectrum --output /tmp/nest-spectrum.json
python3 tools/check-spectrum --output /tmp/nest-spectrum-pixels/1x/result.json
QT_SCALE_FACTOR=2 python3 tools/check-spectrum \
  --output /tmp/nest-spectrum-pixels/2x/result.json
```

The native check installs the exact ZIP in real Main on a private bus and
profile. Pixel verification requires PySide6 QtGui and reads actual item PNGs.
Six synthetic silent FLAC albums exercise approval, complete view,
shared controls, optional player switching, drag/drop, playback, fullscreen,
window restoration, disable and replacement. Audio goes to file capture;
no existing profile or account is accessed. Physical audio is not verified.
Logs, captures, source hashes and performance results are in ignored
evidence/v5/ (0.5.0), evidence/v51/ (0.5.1), evidence/v52/ (0.5.2) and
evidence/v53/ (0.5.3). The optional signal fixture uses deterministic pink
noise routed only to file capture. It verifies decoded audio with and without
a loaded disc, the host's typed band sequence and actual lit pixels. The
default fixture remains silent; neither test verifies physical audio output.

Version 0.5.2 prepares color samples for eight albums on either side of each
visible rail. Visible colors keep loading while moving, and recycled spines
apply cached colors immediately. Horizontal inertia has a 2000 logical px/s
limit and 2200 logical px/s² deceleration.

Three alternating 0.5.1/0.5.2 pairs used 512 distinct synthetic colored covers,
1024 × 600, a 992 × 440 shelf and the same 900 logical px/s initial flick,
velocity limit and deceleration. Each run sampled 1581 visible album-frames
during motion: gray placeholders fell from 128 (8.1%, at most six at once) to
zero. Both versions kept 40 delegates and produced no idle or hidden frames.
Median retained RSS fell from 229.8 to 200.8 MiB. These instrumented desktop
OpenGL offscreen results check loading behavior, not physical screen or Pi
frame rate. Missing or unreadable covers can still use the neutral fallback.

The earlier 0.4/0.5.0 comparison used three alternating pairs, the same release host, 96 synthetic
silent FLAC albums, 1024 × 600 Auto/Slim, ambient off, and Intel Arc OpenGL
offscreen. After a 12-second playback warmup, each phase measured about
eight seconds with the process CPU clock. Median CPU, as a percentage of
one core, changed as follows:

| Phase | 0.4 | 0.5.0 |
| --- | ---: | ---: |
| Idle | 0.164% | 0.142% |
| Playing, default settings | 8.374% | 1.272% |
| Playing, window hidden | 0.814% | 0.828% |
| Paused | 0.222% | 0.246% |

The new default had eight frames per playback sample and zero idle, paused
or hidden frames. Its largest one-second playback peak was 1.632%; closing
the view still included background work with peaks up to 3.637%. This is
not an all-state CPU cap. Retained playback RSS overlapped between versions
(0.4: 304.2–307.5 MiB; 0.5: 304.1–308.2 MiB). This populated GPU scenario is
separate from the clean Main gate, which passed at 230.66 MiB. The silent
fixture, desktop CPU and offscreen renderer do not establish Raspberry Pi
cost or frame rate with real audio, ambient and a changing spectrum feed.

Version 0.5.1 restored the original 16 × 12 display and 25 Hz cadence.
Native code now owns the meter's animation and fixed vertex-color mesh.
Animation frames stay in C++; QML only supplies the existing input feed.
The GPU uses Qt's built-in material, without a custom shader.
Peaks retain the original 600 ms hold and 8.75-segment-per-second fall;
changing the refresh cadence does not speed up their envelope.
The renderer-only comparison feeds the same deterministic bands to the
original, reduced-grid and restored versions; it excludes the host's
analysis feed. That producer still has a cost even when the displayed bands
do not change. The spectrum remains off by default; a renderer measurement
does not establish a 2% limit for the whole player with it enabled.

Three alternating groups at 256 × 96 with identical 25 Hz synthetic input
measured these median CPU percentages of one core:

| Renderer | Grid | Drawn cadence | CPU |
| --- | ---: | ---: | ---: |
| Original QML | 16 × 12 | 25 Hz | 2.126% |
| 0.5.0 reduced shader | 12 × 8 | 10 Hz | 0.888% |
| 0.5.1 native mesh | 16 × 12 | 25 Hz | 1.290% |

The native version uses 39.3% less CPU than the original at equal density
and cadence. Restoring that quality costs more than the reduced meter.
All disabled-frame counts stayed zero. This fixture excludes audio and
the host's analysis producer; physical Raspberry Pi validation is pending.

Pixel checks compare the GPU mesh with the bitmap, including horizontal
and vertical sizes, small surfaces, inherited opacity and the final input
band. `check-spectrum` uses actual Qt Quick item grabs at 1x and 2x;
QtTest's convenience image grab produced corrupt HiDPI snapshots on the
local Qt build. Its HiDPI pixel cases defer to this independent comparison.

The local 10,000-album standalone comparison used Mesa llvmpipe, a fixed
992 × 440 shelf viewport and three alternating pairs per scenario. Median
retained RSS rose by about 23 MiB over 0.3. Flick p95 remained 19 ms; case
motion p95 changed from 18 to 19 ms. Idle and hidden frames remained zero.
The populated-view memory increase needs review before merging into the
host release branch; this POC does not claim an approved new memory budget.

## Resource ownership

Closed CDs use solid text or a 48 × 768 spine derivative. Hidden, pooled and
off-viewport delegates clear image sources and do not animate. Each visible
horizontal rail keeps only its viewport plus two spine widths of cache per
side; outer rows have zero cache buffer and reuse rail shells. Pooled rails empty
their inner models and release the inner delegate pool. One open case
requests a 512 × 512 cover and releases its track model after returning to
the front. A small tiled texture supplies cabinet graining.

Palette extraction uses two workers, 32 × 32 samples, 512 colors and at most
512 pending requests. A shelf-owned, single-shot 40 ms job coalesces scroll
changes and prepares neighboring metadata/colors, without adding album
delegates or full cover images. Its native preloader holds at most 64 distinct
local URLs of at most 4096 characters. Preloads share the existing workers at
lower priority than visible requests. Hiding stops the job and releases its
subscriptions; requests without subscribers cancel. Disc rendering
uses one 256 × 256 texture per disc, one decode worker and at most four
in-flight decodes. Source rasters are bounded before decoding. The tray disc is
static. No shape engine, live blur or web renderer is used.

Automatic spine lookup has one current request, at most 256 queued albums,
three automatic or eight manual edition candidates, 15-second timeouts,
1 MiB metadata and 12 MiB asset limits, and allowlisted archive hosts. Its
negative/review cache has 2048 fixed slots and at most 1 MiB of UTF-16 record
payload; detailed results retain at most 16 albums. Missing results retry
after 14 days, failures after one hour. Hiding cancels the queue and network
work. The image cache is limited to 64 MiB with eviction only on insert.

Opening takes 520 ms, turning up to 324 ms and disc travel 460 ms. The motorized
tray slides out for 200 ms and returns over 260 ms. Reduced motion
completes those transitions immediately. The shelf has no per-CD timer.
Marquee text runs once after a tap. The LCD progress updates once per second
and follows the pointer immediately during a seek. The hidden standard player
LCD suspends its progress, time, artwork and source snapshot bindings.
The optional spectrum has 16 bands, 12 segments and at most 25 changes per
second, only while visible and playing. Each meter owns one timer and four
16-element integer arrays. The GPU uses Qt's built-in vertex-color material
and one fixed mesh of 3480 vertices: 41,760 bytes of CPU geometry, plus the
backend's GPU buffer. LEDs and background gaps do not overlap, preserving
inherited opacity without an extra layer. Geometry is allocated once;
amplitude changes do not allocate nodes or per-segment objects.
Software and unknown renderers use a bitmap capped at 256 × 96 logical
pixels: 96 KiB × DPR² of RGBA, plus the matching Qt texture. The GPU path
skips bitmap painting. Equal quantized frames stop the clock; hiding,
pausing or disabling releases the feed. Destroying the deck releases the
timer, geometry and bitmap. These resources do not grow with library size.
The host owns playback polling, ambient scheduling,
metadata workers and audio buffers.

MIT licensed except the bundled OFL fonts. Local POC; no catalog or release
is published.

The deck shows a static square cover. Clicking it clears Nest-local search
and source/favorite filters only when they hide that album, locates the loaded album by stable ID, and opens
its back. Click or keyboard-activate a track to play from that position.
Playing another album uses Chilpa's confirmation dialog; cancel keeps the
current disc and playback. The LCD gives title and artist the main area,
with the track counter above elapsed/remaining time.

Version 0.5.4 requires the host's `AlbumGridModel.indexOfAlbum` invokable.
It searches existing snapshot IDs without reading album pages. Track requests
retain at most one temporary native model, released on dispatch, cancellation
or a 15-second timeout. Album navigation waits for the catalog revision after
clearing a filter, with one 15-second deadline and no polling. The cover decodes at most 256 × 256 pixels, with no
rotation or continuous tray animation. Existing permissions are unchanged.

The packaged entry embeds the translation catalogs in its revisioned QML
compilation unit. Hot replacement does not add a new JavaScript import to a
directory that Qt has already cached.

Version 0.5.5 projects the jewel box's final depth onto Qt Quick's stacking
plane while preserving its perspective in X/Y/W. This keeps opaque covers
and the booklet backing visible without offscreen layers or another clock.
`tools/check-case-surfaces --output /tmp/nest-faces/result.json` verifies
actual front/back pixels with JPEG, opaque PNG and alpha PNG across finishes.
Run it with `QT_SCALE_FACTOR=2` for HiDPI or `--renderer software` for fallback.
The native host check also verifies the booklet's rendered background pixels
and quiet rendering while it stays open.

Version 0.5.6 keeps the booklet dark in every finish, with high-contrast light
text and a persistent scrollbar when tracks overflow. The standard Qt
scrollbar has a 32 px hit area and a separate gutter beside the durations.

Version 0.5.7 uses Chilpa's native SourceSwitches with a scoped row model.
The list comes from the host's SourceRows, including saved-music providers
that have not joined the library yet. Switching one on enables its native
library integration; hiding it in Nest preserves its integration elsewhere.
The source model is active only while the Filters panel is visible. This
version requires the matching host with SourceSwitches.sourceModel support.

## Pull request packages

GitHub Actions runs tests and packages this branch on pull requests and pushes
to main. Download the ZIP, SHA-256 and archive-check report from the successful
run's artifacts. These are test artifacts retained for 30 days, not releases;
the workflow does not publish a release or update a plugin catalog.

CI checks do not replace installation of the exact ZIP in a compatible native
and Flatpak host. A build does not establish live account playback or physical
audio output. Release validation remains separate.

CI packages Linux x86_64 with Qt 6.11.2, matching the target host.
ARM and macOS packages and physical Raspberry Pi validation are pending.
