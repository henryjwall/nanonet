# nanonet

Deploy a small quantized neural network for **low-latency inference on an FPGA**, generated
in a software-style flow (no hand-written RTL), and developed entirely from an Apple Silicon Mac.

The name: a *nano*-scale net, targeting *nanosecond*-class inference latency — the property that
makes ML-on-FPGA interesting, and the one that matters for low-latency systems.

## The shape of the project

- **Model:** a small net (start tiny — e.g. an MNIST-scale MLP), quantized to fixed-point.
- **Hardware:** PYNQ-Z2 board (AMD/Xilinx **Zynq-7020** SoC — dual ARM cores welded to FPGA fabric).
- **Software-style HDL:** [hls4ml](https://fastmachinelearning.org/hls4ml/) — convert a trained
  Keras/QKeras model straight to HLS C++, then to a bitstream. No VHDL, minimal hand-RTL.
- **Dev machine:** Apple Silicon MacBook (M3). Training, conversion, and board control happen here.
- **Build host:** AMD Vivado/Vitis **do not run on macOS / Apple Silicon**, so the bitstream build is
  offloaded to an x86 Linux CI runner ([Blacksmith](https://www.blacksmith.sh/), free tier).

## Why this stack

| Decision | Reason |
|---|---|
| hls4ml over hand-RTL | C++/Python-style flow; the team is C++-focused; same golden model for verification |
| PYNQ-Z2 over a bare FPGA | Zynq SoC + PYNQ makes deployment turnkey (DMA + Python driver generated for you) |
| PYNQ-Z2 over the iCEstick | iCEstick (iCE40-HX1K) has 1,280 LUTs and **no multipliers** → binary-only. Z2 has 220 DSPs → real int8/fixed-point nets |
| Blacksmith CI for builds | M3 can't run Vivado; CI gives free x86 Linux builds + SSH debug, no AWS bill |

## Cost

Software is **$0** (hls4ml, Vivado ML Standard, Vitis HLS, PYNQ image all free; Zynq-7020 needs no
Vivado license). Recurring build cost targets **$0** via Blacksmith's free 3,000 min/month. The only
spend is the **board (~$140–200)** + a microSD card.

## Repo layout

```
nanonet/
├── README.md
└── docs/
    ├── development-flow.md   # the end-to-end pipeline: Mac → CI → board
    ├── pynq-z2.md            # the board: specs, why it fits, setup
    └── hls4ml-workflow.md    # train → convert → build → deploy, with code
```

## Docs

- [Development flow](docs/development-flow.md) — how the whole pipeline fits together across Mac, CI, and board.
- [PYNQ-Z2](docs/pynq-z2.md) — the target board and why it was chosen.
- [hls4ml workflow](docs/hls4ml-workflow.md) — the model → hardware flow, with code skeletons.

## Status

🌱 Scaffolding. Next: stand up the Blacksmith build (minimal Vivado+Vitis Docker image) and get a
trivial bitstream end-to-end before touching the network.
