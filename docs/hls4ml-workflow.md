# hls4ml workflow

[hls4ml](https://fastmachinelearning.org/hls4ml/) converts a trained neural network into FPGA firmware.
It originated in the CERN/LHC community for **nanosecond-latency** inference (L1 triggers) — the same
low-latency property that makes it interesting for fast inference generally.

## The mental model: it's a C++ code generator with a thin Python launcher

The "Python-ness" of hls4ml is skin-deep:

- **Python (thin glue, ~50 lines):** load a trained model, set a config (precision, reuse factor, strategy),
  call `convert_*` and `build()`.
- **C++ (the substance you own):** hls4ml emits a **human-readable Vitis HLS C++ project** — the layer kernels,
  the templates, the testbench. You can read it, tune it, and push it through the normal flow.

So you can be a C++ person and use it happily. The one genuinely Python-bound part is **training** (the ML
ecosystem — Keras/QKeras, PyTorch/Brevitas — is Python). Train once in Python, then live in C++/HLS.

## The four stages

```
  (1) TRAIN            (2) CONVERT             (3) BUILD                (4) DEPLOY
  Keras / QKeras  ──▶  hls4ml → HLS C++  ──▶   Vitis HLS + Vivado  ──▶  PYNQ overlay
  [ Mac ]              [ Mac ]                 [ CI / x86 Linux ]       [ board, from Mac ]
```

### 1. Train + quantize (Mac)

Use **QKeras** for quantization-aware training (or plain Keras + post-training precision). Smaller bit-widths
= less hardware. Validate the quantized accuracy against the float baseline before going further.

```python
from tensorflow.keras.models import Sequential
from qkeras import QDense, QActivation, quantized_bits
# ... a small MLP with quantized layers, trained on your dataset ...
```

### 2. Convert → HLS C++ (Mac)

```python
import hls4ml

config = hls4ml.utils.config_from_keras_model(model, granularity='name')
config['Model']['Precision']   = 'ap_fixed<16,6>'   # total bits, integer bits
config['Model']['ReuseFactor'] = 1                  # 1 = fully parallel (fast, big); higher = reuse HW (small, slower)
config['Model']['Strategy']    = 'Latency'          # 'Latency' (small nets) or 'Resource' (bigger nets)

hls_model = hls4ml.converters.convert_from_keras_model(
    model,
    hls_config=config,
    backend='VivadoAccelerator',   # generates the full PYNQ system, not just IP
    board='pynq-z2',
    output_dir='hls4ml_prj',
)
```

### 3. Build → bitstream (CI / x86 Linux)

This step shells out to **Vitis HLS** (C++ → RTL) and **Vivado** (RTL → `.bit`), so it runs on the Blacksmith
runner, not the Mac.

```python
hls_model.compile()                 # optional: bit-accurate C-sim (needs HLS headers → run on CI)
hls_model.build(csim=False, synth=True, export=True, bitfile=True)
```

Output: a `.bit` bitstream + `.hwh` hardware handoff + a generated Python driver. The CI job uploads these as
artifacts.

### 4. Deploy (board, driven from Mac)

Copy `.bit` / `.hwh` / driver to the PYNQ-Z2, then from Jupyter:

```python
from axi_stream_driver import NeuralNetworkOverlay
nn = NeuralNetworkOverlay('hls4ml_nn.bit', X_test.shape, y_test.shape)
y_hw, latency, throughput = nn.predict(X_test, profile=True)
```

*(Exact driver/class names vary by hls4ml version — check the generated project.)*

## The knobs that matter

| Knob | Effect |
|---|---|
| **Precision** (`ap_fixed<W,I>`) | Bit-width of weights/activations. Lower = less DSP/LUT, lower accuracy. The main lever. |
| **ReuseFactor** | How many times a multiplier is reused. `1` = fully parallel (fastest, most DSPs); higher = fewer DSPs, more cycles. The main area↔latency trade. |
| **Strategy** | `Latency` for small nets (unrolled), `Resource` for larger ones (shared, BRAM-backed weights). |
| Per-layer overrides | `granularity='name'` lets you set precision/reuse per layer. |

## What runs on the Mac vs. CI

| Task | Mac | CI |
|---|---|---|
| Train / quantize | ✅ | |
| `convert_from_keras_model` (generate C++) | ✅ | |
| Quantized-accuracy check (QKeras) | ✅ | |
| Bit-accurate hls4ml C-sim | | ✅ (needs HLS headers) |
| `build()` → Vitis HLS + Vivado → `.bit` | | ✅ |

## Gotchas

- **You need both Vivado *and* Vitis HLS** in the build image — Vitis HLS synthesizes the network's C++,
  Vivado builds the bitstream. Trim both to the **7-series / Zynq-7000** device family to keep the install small.
- **Pin versions.** hls4ml documents which Vivado/Vitis versions it's tested against — mismatches cause
  build failures. Install the version the current hls4ml release recommends.
- **Start tiny.** Get a minimal net through the *whole* pipeline before optimizing accuracy; the pipeline is
  the hard part, not the model.

## Related: trees, not just nets

The same group maintains **[conifer](https://github.com/thesps/conifer)**, which converts **gradient-boosted
tree ensembles** (XGBoost / scikit-learn / ONNX) into FPGA firmware at tens-of-nanoseconds latency. For
systematic / signal-style workloads, tree ensembles are often as relevant as neural nets — worth a look as a
follow-on.
