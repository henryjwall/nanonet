# nanonet

Deploy a small quantized neural network for **low-latency inference on an FPGA**, generated
in a software-style flow (no hand-written RTL).


## The shape of the project

- **Model:** a small net (start tiny — e.g. an MNIST-scale MLP), quantized to fixed-point.
- **Hardware:** PYNQ-Z2 board (AMD/Xilinx **Zynq-7020** SoC — dual ARM cores welded to FPGA fabric).
- **Software-style HDL:** [hls4ml](https://fastmachinelearning.org/hls4ml/) — convert a trained
  Keras/QKeras model straight to HLS C++, then to a bitstream. No VHDL, minimal hand-RTL.


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

