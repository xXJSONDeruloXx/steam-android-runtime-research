# Nova Steam font coverage open question

Status: documented for follow-up; not on the current presentation/input critical path.

The live fullscreen Steam Gamepad UI visibly renders some language names as
empty square/rectangle glyphs. The current screenshot shows this in the
language selector for several CJK and other non-Latin entries, while Latin,
Cyrillic, Greek, and some accented Latin entries render normally. The same
symptom was noticed by inspection in the network-selection UI. This is a
rendering/asset-coverage issue, not evidence that the Steam UI state or input
event was lost.

## Current evidence

- The active Steam page is the real `Steam Big Picture Mode` webhelper page,
  not the Android lab view.
- The Android display path is 1280x960 and continues presenting after the
  long-run fence test crosses frame 390.
- The page DOM contains the expected language strings, including CJK names;
  the missing shapes are therefore visible glyph substitution/fallback, not
  missing UI text.
- Steam CEF currently reports the software `softpipe`/ANGLE path. Font
  selection and glyph rasterization have not yet been isolated from that
  rendering path.

## Follow-up gate

After fullscreen presentation reaches the Steam login screen, capture a fixed
font matrix for the language and network pages:

1. Save the page URL, body text, computed CSS `font-family`, and
   `document.fonts` status through the existing CDP probe.
2. Inside the Holo rootfs, record `fc-match`, `fc-list`, fontconfig paths, and
   the webhelper locale/encoding environment.
3. Compare the required Unicode ranges against the installed fonts and add a
   narrowly scoped font package or app-owned font directory if coverage is
   absent. Keep the Android system font stack out of the rootfs unless a
   controlled test proves it is safe and license-compatible.
4. Re-run the same pages at 1280x960 and verify that the glyphs render without
   changing the input or presentation contract.

The result should distinguish missing font coverage, fontconfig discovery,
CEF/Skia fallback, and a genuine GPU text-rasterization defect. Do not let
this investigation delay the current login, networking, audio, and hardware
graphics gates unless unreadable glyphs block a required user action.
