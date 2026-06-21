# Development flow

The end-to-end pipeline for `nanonet`: how work is split across the **Mac**, a **cloud CI build host**,
and the **PYNQ-Z1/Z2 board**.

## The core constraint

AMD Vivado and Vitis HLS — the tools that turn hls4ml's generated C++ into a bitstream — **only run on
x86-64 Linux/Windows**. There is no macOS build, and an Apple Silicon M3 cannot emulate the x86 tools at
usable speed. So the work splits into three zones:

```
  ┌─────────────────────────┐     ┌──────────────────────────────┐     ┌────────────────────────┐
  │  MacBook M3 (local)      │     │  Blacksmith CI (x86 Linux)   │     │  PYNQ-Z1/Z2 board      │
  │                          │     │                              │     │                        │
  │  • train net (QKeras)    │     │  • Vitis HLS: C++ → RTL      │     │  • boots PYNQ Linux    │
  │  • hls4ml convert → C++  │ ──▶ │  • Vivado: RTL → bitstream  │ ──▶ │  • load .bit overlay   │
  │  • commit + push         │ git │  • upload .bit as artifact  │ .bit│  • run inference       │
  │  • flash board, run NB   │ ◀── │  • (SSH in to debug)        │     │  • report latency      │
  └─────────────────────────┘     └──────────────────────────────┘     └────────────────────────┘
        what's fun, stays local        the 100GB toolchain, rented           Jupyter in a browser
```

## What runs where

| Step | Location | Notes |
|---|---|---|
| Train + quantize model | **Mac** | Keras/QKeras (or PyTorch/Brevitas). Native on Apple Silicon. |
| hls4ml convert → HLS C++ | **Mac** | Pure Python; generates the project, no Vivado needed. |
| Numerical validation (quantized accuracy) | **Mac** | Compare QKeras model vs float baseline. |
| Bit-accurate hls4ml C-sim | **CI** | Needs the HLS headers; run it next to the build, not on the Mac. |
| Vitis HLS synthesis (C++ → RTL) | **CI** | x86 Linux only. |
| Vivado build (RTL → `.bit`) | **CI** | x86 Linux only. Driven by hls4ml's `VivadoAccelerator` backend. |
| Flash SD, deploy, run inference | **Mac + board** | Board boots its own Linux; drive it from the Mac's browser. |

## The CI build host (Blacksmith)

Why Blacksmith instead of an AWS VM: it's an x86 Ubuntu CI runner with a **free tier (3,000 min/month)**,
strong **single-core** performance (Vivado place-and-route is single-thread-bound), and **free SSH access**
into running jobs for interactive debugging. Net recurring cost target: **$0**.

### Runner sizing

| Instance | vCPU | RAM | Disk |
|---|---|---|---|
| `blacksmith-8vcpu-ubuntu-2404` | 8 | 32 GB | **160 GB** |

The 160 GB disk comfortably holds a **device-trimmed** Vivado + Vitis HLS install (7-series / Zynq-7000
device family only — *not* the full 100 GB+ all-device install). The 32 GB RAM is ample for a small
Zynq-7020 build.

### Keeping it free: the ephemeral-runner problem

CI runners start with a **wiped disk** every job. To avoid reinstalling the toolchain each run (which would
burn minutes and bandwidth):

- **Bake the minimal Vivado+Vitis image into a Docker image**, pushed to a **free registry**
  (GitHub Container Registry / Docker Hub free tier). Each job pulls it and builds. You pay only in minutes.
- **Avoid the paid persistence add-ons** (Sticky Disks, Docker Layer Caching are each **$0.50/GB/mo**, and
  sticky disks evict after 7 days of inactivity anyway). They're speed optimizations, not requirements.

### Interactive debugging via SSH

Blacksmith lets you **SSH into a live job** using your GitHub keys (no extra cost). Pattern: a
`workflow_dispatch` job with a long `sleep` step holds the runner open so you can SSH in and wrangle the
Vivado install / hls4ml build by hand. Caveats: the runner is **ephemeral** (installs don't persist past the
job), and the job **burns free minutes while held open**. Requires an org admin to enable the feature.

## Phased plan

1. **Plumbing first (no ML).** Stand up the Blacksmith workflow: build a minimal-Vivado Docker image, produce
   a *trivial* bitstream end-to-end, download the artifact. Prove the pipeline before adding a network.
2. **Board bring-up.** Flash the PYNQ image, get on the network, run a hello-world overlay from Jupyter.
3. **First net.** A tiny MLP via hls4ml `VivadoAccelerator` → `.bit` → run on board, measure latency.
4. **Iterate.** Tune precision / `ReuseFactor` for accuracy vs. resources; grow the network.

## Open questions to verify before relying on "free"

- [ ] **Free-minute multiplier** — does an 8-vCPU runner consume the 3,000 free minutes faster than a
      2-vCPU one? May favor a smaller runner for builds.
- [ ] **Trimmed image size** — measure the actual size of a 7-series-only Vivado + Vitis HLS install to
      confirm it fits the 160 GB (or even 80 GB) runner.
- [ ] **SSH enablement** — confirm the Blacksmith org admin can enable SSH access.
- [ ] **Vivado/Vitis version pinning** — match the version hls4ml's current release is tested against.
- [ ] **Board pick** — Z1 vs Z2 (same chip); set the matching `board=` flag + SD image once decided.
