# PYNQ-Z2

The target board: a **PYNQ-Z2**, built around the AMD/Xilinx **Zynq-7020** SoC.

## What it is

The Zynq-7020 (XC7Z020) is a **System-on-Chip**: a dual-core ARM Cortex-A9 ("PS" — Processing System)
fused on one die with Artix-class FPGA fabric ("PL" — Programmable Logic). That SoC structure is the whole
reason it's a good hls4ml target — the ARM side runs Linux and handles data movement, so you don't have to
build a host link before you can run an accelerator.

## Specs

| Resource | Zynq-7020 (XC7Z020) |
|---|---|
| Logic cells | ~85,000 |
| LUTs | 53,200 |
| Flip-flops | 106,400 |
| **DSP slices** (multipliers) | **220** (DSP48E1) |
| Block RAM | ~4.9 Mb (~630 KB), 140 × 36 Kb blocks |
| ARM cores | 2 × Cortex-A9 (up to ~650–866 MHz) |
| On-board DDR3 (PYNQ-Z2) | 512 MB |
| Connectivity | Gigabit Ethernet, HDMI in + out, audio, microSD boot, USB |
| Expansion | Arduino + Raspberry Pi headers, 2× Pmod |
| Price | ~$140–200 |

The **220 DSP slices** are the headline for ML: real hardware multipliers mean genuine int8 / fixed-point
inference, not the binary-only corner a multiplier-less part (like the iCEstick's iCE40-HX1K) forces.

## Why it's good for hls4ml

- **PYNQ** ("Python Productivity for Zynq") boots **Linux + Jupyter on the ARM cores**. The board becomes a
  small Linux computer with an FPGA attached — flash an SD image and it's ready.
- hls4ml has a dedicated **`VivadoAccelerator` backend** that targets PYNQ boards (`board='pynq-z2'`). It
  generates not just the network IP but the **entire surrounding system** — DMA, AXI interfaces, bitstream —
  plus a **Python driver class**.
- Deployment is turnkey: copy the `.bit` / `.hwh` to the board, then from Jupyter:
  `nn = NeuralNetworkOverlay('model.bit', X.shape, y.shape); y = nn.predict(X)`. The ARM + DMA move data
  in and out for you.

On a bare FPGA board (no ARM), *you'd* have to build that host link — UART/PCIe/DMA plumbing — before seeing
a single result. The SoC hands you all of it.

## Free toolchain coverage

The **Zynq-7020 is covered by the free Vivado ML Standard edition** — no license required. Combined with the
free Vitis HLS and the free PYNQ SD image, the entire software stack is **$0**.

## Board setup (high level)

1. Flash the **PYNQ SD-card image** (Ubuntu-based) for the PYNQ-Z2 to a microSD.
2. Set the boot-mode jumper to SD; power via USB or barrel jack.
3. Connect Ethernet (direct to the Mac or via a router).
4. Browse to the board's Jupyter (`http://<board-ip>:9090`, default password `xilinx`).
5. Upload the hls4ml-generated `.bit` + `.hwh` + driver, then run inference from a notebook.

## Alternatives considered

| Board | FPGA | Verdict |
|---|---|---|
| **PYNQ-Z2 / PYNQ-Z1** | Zynq-7020 | **Chosen.** Free + turnkey + enough DSP. Z1 ≈ Z2 (Z2 adds HDMI-in/audio). |
| Cora Z7 | Zynq-7010 | Cheaper, PYNQ-capable, but half the DSPs (80) — only very small nets. |
| Arty A7-100T | Artix-7 100T | More LUTs but **no ARM → no PYNQ**; you'd build your own host link. |
| KV260 / ZCU104 | Zynq UltraScale+ | More powerful, but pricier and larger parts can need a **paid** Vivado license. |
| DE10-Nano | Cyclone V SoC (Intel) | Free Quartus, but hls4ml's Quartus path is less polished than PYNQ. |

**Takeaway:** the PYNQ-Z2 is the only option that is free, turnkey, *and* capable enough at once.

## Purchase notes

- PYNQ-Z1 (Digilent) and PYNQ-Z2 (TUL) both use the **XC7Z020** and are interchangeable for this project.
  Get whichever is cheaper / in stock; the Z2 just adds a few peripherals (HDMI-in, audio).
- Also grab a **microSD card** (16 GB+) for the PYNQ image.
