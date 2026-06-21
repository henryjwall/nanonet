# Vivado toolchain image (optional)

A containerized build of Vivado ML 2020.1, trimmed to the Zynq-7000 / Artix-7 device family. This is an
**optional, reproducible alternative** to installing Vivado directly onto the build VM.

> **The primary path is a native install on the build VM** — see
> [`../docs/development-flow.md`](../docs/development-flow.md). On a box you own and keep, a native
> install is simpler and persists. Reach for this image when you want a **pinned, reproducible toolchain
> environment** you can rebuild byte-for-byte anywhere x86 — e.g. to run the build in a clean container
> on the VM, or to move the exact same environment to another machine later.

The device-trim choices in `install_config.vivado-2020.1.txt` are shared with the native install, so the
two paths produce the same toolchain.

## What's in it, and why

| Choice | Value | Reason |
|---|---|---|
| Tool | **Vivado ML 2020.1** | Last release with the classic `vivado_hls` that hls4ml's `VivadoAccelerator` backend drives. 2020.2+ dropped it for Vitis HLS, which that backend doesn't use (`VitisAccelerator` isn't ready). |
| Edition | **Vivado HL WebPACK** (free) | XC7Z020 (Z-7020) is in the free WebPACK device set → no license server, $0. |
| Products | **Vivado only** (incl. `vivado_hls`) | For the `VivadoAccelerator` path you do *not* need a separate Vitis install. One product = smaller image. |
| Devices | **Zynq-7000 + Artix-7** only | XC7Z020 is the target; its fabric is Artix-7 class. Everything else is trimmed out. |
| Base | `ubuntu:18.04` | Officially supported host OS for Vivado 2020.1. |

> ⚠️ **x86-64 only.** Vivado doesn't run on Apple Silicon, and emulating it on the M3 is
> unusably slow. Build and run this image on an x86 Linux host (the build VM, or any amd64 box). The
> `--platform linux/amd64` flag is baked into `build.sh`.

## 1. Get the installer (manual, login-gated)

AMD requires a (free) account and EULA acceptance, and the installer is **not
redistributable**, so it can't be `curl`'d inside the Dockerfile. Download:

> **Vivado Design Suite — 2020.1 → "Vivado Design Suite 2020.1: All OS installer
> Single-File Download"** (a ~35 GB `.tar.gz`)

from <https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools/archive.html>.

The full single-file installer contains every device; the install **config trims it down**,
so the final image only carries Zynq-7000 + Artix-7. The big tarball is build-context
only — it's deleted in the same Docker layer and never persists in the image.

## 2. (Recommended) Verify the device module names

The `Modules=` labels in `install_config.vivado-2020.1.txt` are release-specific. To get a
guaranteed-correct list for your exact installer, extract it and generate a template:

```bash
tar -xzf Xilinx_Unified_2020.1_*.tar.gz
./Xilinx_Unified_2020.1_*/xsetup -b ConfigGen      # choose Vivado → Vivado HL WebPACK
# -> writes ~/.Xilinx/install_config.txt with every Module for this release
```

Then keep the device families you want at `:1` and set the rest to `:0`. The shipped config
already reflects the intended trim; this step is just belt-and-braces.

## 3. Build

```bash
# from the repo root, on an x86 Linux host:
./docker/build.sh ./Xilinx_Unified_2020.1_0602_1208.tar.gz nanonet/vivado:2020.1
```

`build.sh` copies the installer into the build context if needed, then runs
`docker build --platform linux/amd64` with the right `--build-arg`.

## 4. Smoke test

```bash
docker run --rm --platform linux/amd64 nanonet/vivado:2020.1 vivado -version
docker run --rm --platform linux/amd64 nanonet/vivado:2020.1 vivado_hls -version
```

Both must report `v2020.1`. (The Dockerfile also runs these at build time, so a bad
install fails the build rather than shipping a broken image.)

## Notes & gotchas

- **Image size:** even trimmed, expect a ~30 GB image. Fine on the build VM's 80 GB disk.
- **Installer flavor:** this image uses the full single-file installer for a reproducible *offline*
  build. For a *native* install on the VM, the small "web installer" is easier — it downloads only the
  trimmed device data and you authenticate to AMD interactively over SSH.
- **Don't commit the installer.** It's huge and non-redistributable; `.gitignore` excludes
  `Xilinx_Unified_*.tar.gz`.
- **Board files:** the `VivadoAccelerator` backend ships its own pynq-z1/pynq-z2 board files,
  so no manual board-file install is needed for those targets.
