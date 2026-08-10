# Nova FROG source-level swapchain boundary — 2026-08-10

## Result

The installed FROG layer is a swapchain wrapper, not a Vulkan swapchain
provider. The inspected source is
`/Users/kurt/Developer/gamescope-valve/layer/VkLayer_FROG_gamescope_wsi.cpp`
at Gamescope commit `fb9f84ee247a1f02b1a132da60e94585db84bf61`, with
SHA-256
`00d3e34c9829da5ee12edec97c3a136e390dbf6f86608c51b32164d622f2a52c`.

The relevant code establishes three facts:

1. FROG exposes only `VK_EXT_hdr_metadata` and
   `VK_GOOGLE_display_timing` as layer device extensions. It does not expose
   or synthesize `VK_KHR_swapchain`.
2. Its `CreateDevice` hook appends
   `VK_EXT_swapchain_maintenance1`, enables its feature, and then calls the
   underlying dispatch's `CreateDevice`. That is consistent with the live log
   saying the extension is unavailable on the Freedreno device.
3. Its `CreateSwapchainKHR` hook eventually calls the underlying dispatch's
   `CreateSwapchainKHR` and wraps the resulting swapchain in the Gamescope
   protocol. It does not implement a swapchain against a headless-only
   device.

The exact native Turnip inventory already recorded under the same private
environment reports 153 device extensions, no `VK_KHR_swapchain`, and
`present support = false`. Geometry Wars then reaches FROG/DXVK but is
rejected by DXVK at the required `khrSwapchain` check. These results agree
across source and device evidence.

## Decision

Do not spend another identical game run or one-click launcher patch on this
FROG profile. A rendering fix would require one of the following materially
different implementations:

- a Turnip/Freedreno device path that exposes a real Vulkan swapchain and
  presentation support;
- a substantially different FROG layer that advertises and implements a
  complete swapchain/device-extension emulation contract over Gamescope; or
- a different client rendering path, such as a working X11 OpenGL/WineD3D or
  software Vulkan route.

The first two are lower-level compositor/driver work and are outside the
current one-click application refinement. Keep the FROG changes and artifacts
as a bounded research branch; return the main effort to the already-visible
Termux:X11 Steam session and its application, input, audio, and launch
boundaries.
