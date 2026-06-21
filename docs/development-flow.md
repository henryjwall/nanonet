# Development flow

The end-to-end pipeline for `nanonet`: how work is split across the **Mac**, a **persistent x86
build VM**, and the **PYNQ-Z1/Z2 board**.

## The core constraint

AMD Vivado — the tool that turns hls4ml's generated C++ into a bitstream — **only runs on x86-64
Linux/Windows**. There is no macOS build, and an Apple Silicon M3 cannot emulate the x86 tools at
usable speed. So the work splits into three zones:

```
  ┌─────────────────────────┐     ┌──────────────────────────────┐     ┌────────────────────────┐
  │  MacBook M3 (local)      │     │  x86 build VM (Hetzner)      │     │  PYNQ-Z1/Z2 board      │
  │                          │     │  Vivado installed once,      │     │                        │
  │  • train net (QKeras)    │     │  persists on disk            │     │  • boots PYNQ Linux    │
  │  • hls4ml convert → C++  │ ──▶ │  • vivado_hls: C++ → RTL     │ ──▶ │  • load .bit overlay   │
  │  • commit + push         │rsync│  • vivado: RTL → bitstream   │ .bit│  • run inference       │
  │  • flash board, run NB   │ ◀── │  • rsync .bit back to Mac    │     │  • report latency      │
  └─────────────────────────┘     └──────────────────────────────┘     └────────────────────────┘
        what's fun, stays local        the ~30 GB toolchain, rented cheap     Jupyter in a browser
```

## What runs where

| Step | Location | Notes |
|---|---|---|
| Train + quantize model | **Mac** | Keras/QKeras (or PyTorch/Brevitas). Native on Apple Silicon. |
| hls4ml convert → HLS C++ | **Mac** | Pure Python; generates the project, no Vivado needed. |
| Numerical validation (quantized accuracy) | **Mac** | Compare QKeras model vs float baseline. |
| Bit-accurate hls4ml C-sim | **Build VM** | Needs the HLS headers; run it next to the build, not on the Mac. |
| Vivado HLS synthesis (C++ → RTL) | **Build VM** | x86 Linux only. |
| Vivado build (RTL → `.bit`) | **Build VM** | x86 Linux only. Driven by hls4ml's `VivadoAccelerator` backend. |
| Flash SD, deploy, run inference | **Mac + board** | Board boots its own Linux; drive it from the Mac's browser. |

## The build VM

A small, **persistent** x86 Linux VM with Vivado installed once. You SSH in from the Mac, push the
generated hls4ml project over, build, and pull the artifacts back. That's the entire x86 build need in
one cheap box — install the toolchain a single time and it stays on disk.

**Recommended: Hetzner Cloud CX32** — 4 vCPU (Intel, x86), 8 GB RAM, 80 GB NVMe, ~€6.80/mo.

- Avoid Hetzner's **CAX** line: it's ARM, Vivado won't run. Must be **CX** (Intel) or **CPX** (AMD).
- 8 GB RAM is the practical floor and fine for the tiny Z-7020 nets we start with. If a build OOMs: add
  swap, or temporarily **rescale to CX42** (16 GB) for that build and scale back down afterwards
  (Hetzner rescales CPU/RAM up *and* down; disk only grows).
- 80 GB disk holds a **device-trimmed** Vivado 2020.1 install (Zynq-7000 / Artix-7 only, ~30 GB) with
  room for project scratch — use the **web installer** so you never have to store the 35 GB single-file
  tarball.

### Keeping it cheap

Hetzner bills a server until you **delete** it — powering off does *not* stop billing. Two models:

- **Simplest:** leave CX32 running → flat ~€6.80/mo, always there.
- **Cheapest:** install Vivado → **snapshot** it (~€0.011/GB/mo, so ~€0.50/mo for the install) → delete
  the server → recreate from the snapshot only when you build. A few build-hours a month ≈ well under
  £1/mo. Costs a ~3-min recreate (and a new IP) per session.

Either way, **snapshot the box right after installing Vivado** — cheap insurance against a botched VM.

### Installing the toolchain

Vivado **2020.1**, free **WebPACK** edition (covers XC7Z020, no license server), trimmed to
**Zynq-7000 + Artix-7**. 2020.1 is the last release with the classic `vivado_hls` that the
`VivadoAccelerator` backend drives (2020.2+ replaced it with Vitis HLS, which that backend doesn't use).
The device-trim choices are captured in `docker/install_config.vivado-2020.1.txt` — the web installer
just needs the same families ticked. (`docker/` also holds an optional containerized build of the same
toolchain; see `docker/README.md`.)

## Phased plan

1. **Plumbing first (no ML).** Stand up the build VM, install trimmed Vivado, snapshot it, and produce a
   *trivial* bitstream end-to-end — pull the artifact back to the Mac. Prove the pipeline before adding a
   network.
2. **Board bring-up.** Flash the PYNQ image, get on the network, run a hello-world overlay from Jupyter.
3. **First net.** A tiny MLP via hls4ml `VivadoAccelerator` → `.bit` → run on board, measure latency.
4. **Iterate.** Tune precision / `ReuseFactor` for accuracy vs. resources; grow the network.

## Open questions to verify

- [ ] **Trimmed install size** — confirm the 7-series-only Vivado 2020.1 install fits comfortably in
      80 GB alongside project scratch.
- [ ] **8 GB RAM headroom** — confirm a small Z-7020 place-and-route completes on CX32 without OOM; keep
      the CX42 rescale as the fallback.
- [ ] **Board pick** — Z1 vs Z2 (same chip); set the matching `board=` flag + SD image once decided.
