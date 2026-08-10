# Nova one-click X11 stretch retry after lifecycle fix — 2026-08-10

## Question

Retry the productized Termux:X11 stretch profile from a genuinely fresh
launcher identity after incomplete run `276`.

## Fixes under test

- The launcher clears stale `ready`, server, client, and relay state only after
  the exact preflight has confirmed no live Nova runtime, then writes a fresh
  session token before launch. Readiness must require that token and the new
  `ready` marker.
- The runtime cleanup helper accepts an explicit space-separated exclusion list
  for the stop wrapper and its immediate parent. The launcher passes those
  PIDs so cleanup can terminate Nova descendants without terminating the
  caller before preference restoration and final state cleanup.
- X11 preference restoration now happens immediately after the exact X11
  cleanup and before runtime cleanup.

The retry uses run ID
`nova-one-click-x11-stretch-retry-20260810T095931Z`, the built APK from this
commit, no physical or synthetic input, and the direct root launcher stop
command that the APK service itself uses. It accepts only fresh-session
identity, a 1280×800 X11 buffer, Android full-surface evidence, original
preference hash restoration, and clean exact-scope teardown.
