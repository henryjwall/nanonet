# PYNQ-Z1 / PYNQ-Z2

The target board: a **PYNQ-Z1 or PYNQ-Z2** — *not yet finalized*. Both are built on the same AMD/Xilinx
**Zynq-7020** SoC (XC7Z020), so for `nanonet` they're interchangeable; the choice is purely price/availability.

> **Status:** bid placed on a PYNQ-Z1; may buy a PYNQ-Z2 instead. Same chip either way — the only deltas are
> peripheral ports (irrelevant here), the SD image, and the `board=` flag.

## What it is

The Zynq-7020 (XC7Z020) is a **System-on-Chip**: a dual-core ARM Cortex-A9 ("PS" — Processing System) fused
on one die with Artix-class FPGA fabric ("PL" — Programmable Logic). That SoC structure is the whole reason
it's a good hls4ml target — the ARM side runs Linux and handles data movement, so you don't have to build a
host link before you can run an accelerator.

## Specs (identical for Z1 and Z2)

| Resource | Zynq-7020 (XC7Z020) |
|---|---|
| Logic cells | ~85,000 |
| LUTs | 53,200 |
| Flip-flops | 106,400 |
| **DSP slices** (multipliers) | **220** (DSP48E1) |
| Block RAM | ~4.9 Mb (~630 KB), 140 × 36 Kb blocks |
| ARM cores | 2 × Cortex-A9 (up to ~650–866 MHz) |
| On-board DDR3 | 512 MB |
| Connectivity | Gigabit Ethernet, microSD boot, USB |

The **220 DSP slices** are the headline for ML: real hardware multipliers mean genuine int8 / fixed-point
inference, not the binary-only corner a multiplier-less part (like the iCEstick's iCE40-HX1K) forces.

## Z1 vs Z2 — the only differences

| | PYNQ-Z1 (Digilent) | PYNQ-Z2 (TUL) |
|---|---|---|
| FPGA | XC7Z020 | XC7Z020 (**identical**) |
| Audio | mic + mono out | stereo line in/out |
| Video | none | HDMI in + out |
| hls4ml flag | `board='pynq-z1'` | `board='pynq-z2'` |
| PYNQ SD image | PYNQ-Z1 image | PYNQ-Z2 image |

**None of the peripheral differences matter for `nanonet`** — data moves in/out over DMA, not those ports.
The two practical things to get right once you pick one: flash the **matching** SD image, and set the
**matching** `board=` flag in hls4ml.

## Why it's good for hls4ml

- **PYNQ** ("Python Productivity for Zynq") boots **Linux + Jupyter on the ARM cores**. Flash an SD image and
  the board is a small Linux computer with an FPGA attached.
- hls4ml's **`VivadoAccelerator` backend** officially supports both `pynq-z1` and `pynq-z2`. It generates not
  just the network IP but the **entire surrounding system** — DMA, AXI interfaces, bitstream — plus a **Python
  driver class**.
- Deployment is turnkey: copy the `.bit` / `.hwh` to the board, then from Jupyter:
  `nn = NeuralNetworkOverlay('model.bit', X.shape, y.shape); y = nn.predict(X)`. The ARM + DMA move data for you.

On a bare FPGA board (no ARM), *you'd* have to build that host link — UART/PCIe/DMA plumbing — before seeing a
single result. The SoC hands you all of it.

## Free toolchain coverage

The **Zynq-7020 is covered by the free Vivado ML Standard edition** — no license required. Combined with the
free Vitis HLS and the free PYNQ SD image, the entire software stack is **$0**.

## Board setup (high level)

1. Flash the **PYNQ SD-card image for your specific board** (Z1 and Z2 use *different* images) to a microSD.
2. Set the boot-mode jumper to SD; power via USB or barrel jack.
3. Connect Ethernet (direct to the Mac or via a router).
4. Browse to the board's Jupyter (`http://<board-ip>:9090`, default password `xilinx`).
5. Upload the hls4ml-generated `.bit` + `.hwh` + driver, then run inference from a notebook. Make sure the
   hls4ml `board=` flag matched the board you flashed.

## Alternatives considered

| Board | FPGA | Verdict |
|---|---|---|
| **PYNQ-Z1 / PYNQ-Z2** | Zynq-7020 | **Chosen.** Free + turnkey + enough DSP. Same chip; pick on price/stock. |
| Cora Z7-07S | Zynq-7007S | Cheaper (~$99), but not PYNQ/hls4ml-supported OOTB → custom board definition needed. |
| Arty A7-35T | Artix-7 35T | Cheapest with DSPs, but **no ARM → no PYNQ**; manual UART host link. |
| KV260 / ZCU104 | Zynq UltraScale+ | More powerful, but pricier and larger parts can need a **paid** Vivado license. |
| DE10-Nano | Cyclone V SoC (Intel) | Free Quartus, but hls4ml's Quartus path is less polished than PYNQ. |

**Takeaway:** the PYNQ-Z1/Z2 is the only option that is free, turnkey, *and* capable enough at once. Among
officially-supported turnkey boards, the Z1/Z2 is also the cheapest — so the main way to save money is the
**used market**.

## Purchase notes

- PYNQ-Z1 (Digilent) and PYNQ-Z2 (TUL) both use the **XC7Z020** and are interchangeable for this project. Buy
  whichever is cheaper / in stock.
- The TUL **PYNQ-Z2 "Basic Kit"** (Farnell `1M1-M000127DVB`) bundles the board + 8 GB microSD + PSU + cables.
  The "Advanced Kit" (`...DVA`) adds peripheral modules you don't need here.
- Either way, a **16 GB+ microSD** gives more headroom than the bundled 8 GB.
