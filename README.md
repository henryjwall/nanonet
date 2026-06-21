# nanonet

Deploy a small quantized neural network for **low-latency inference on an FPGA**, generated
in a software-style flow (no hand-written RTL).


## The shape of the project

- **Model:** a small net (start tiny — e.g. an MNIST-scale MLP), quantized to fixed-point.
- **Hardware:** PYNQ-Z1 *or* Z2 board — *board choice not yet finalized* (both are the same AMD/Xilinx
  **Zynq-7020** SoC: dual ARM cores welded to FPGA fabric, so nothing downstream changes either way).
- **Software-style HDL:** [hls4ml](https://fastmachinelearning.org/hls4ml/) — convert a trained
  Keras/QKeras model straight to HLS C++, then to a bitstream. No VHDL, minimal hand-RTL.


## Repo layout

```
nanonet/
├── README.md
└── docs/
    ├── development-flow.md   # the end-to-end pipeline: Mac → CI → board
    ├── pynq-z1-z2.md         # the board (Z1 or Z2): specs, why it fits, setup
    └── hls4ml-workflow.md    # train → convert → build → deploy, with code
```

## Docs

- [Development flow](docs/development-flow.md) — how the whole pipeline fits together across Mac, CI, and board.
- [PYNQ-Z1/Z2](docs/pynq-z1-z2.md) — the target board (Z1 or Z2) and why it was chosen.
- [hls4ml workflow](docs/hls4ml-workflow.md) — the model → hardware flow, with code skeletons.
