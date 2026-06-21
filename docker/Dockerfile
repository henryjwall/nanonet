# syntax=docker/dockerfile:1
#
# nanonet toolchain image (OPTIONAL): AMD/Xilinx Vivado ML 2020.1 (WebPACK, free),
# trimmed to the Zynq-7000 / Artix-7 device family. A reproducible, containerized
# alternative to installing Vivado natively on the build VM — it turns hls4ml's
# generated C++ into a PYNQ-Z1/Z2 bitstream via the VivadoAccelerator backend (which
# drives `vivado_hls` + `vivado`, both bundled in this one install). The native VM
# install is the primary path; see ../docs/development-flow.md.
#
# WHY 2020.1: it's the last release that still ships the classic `vivado_hls` that
# the VivadoAccelerator backend expects (2020.2+ replaced it with Vitis HLS, which
# that backend does not use). XC7Z020 is covered by the free WebPACK edition, so no
# license server is needed.
#
# ── x86-64 ONLY ──────────────────────────────────────────────────────────────────
# Vivado does not run on Apple Silicon. Build this on an x86 Linux host (the build
# VM, or any amd64 box) — NOT on the M3 Mac. From the repo root:
#
#   ./docker/build.sh ./Xilinx_Unified_2020.1_0602_1208.tar.gz
#
# The AMD installer is login-gated and NOT redistributable: download the
# "Vivado Design Suite 2020.1: All OS installer Single-File Download" tarball
# yourself and place it in the build context. See docker/README.md.
# ─────────────────────────────────────────────────────────────────────────────────

FROM ubuntu:18.04

# INSTALLER is the basename of the Vivado single-file installer tarball, which must
# sit in the build context (repo root). INSTALL_DIR must match Destination= in the
# install config.
ARG INSTALLER
ARG INSTALL_DIR=/opt/Xilinx
ARG DEBIAN_FRONTEND=noninteractive

# Runtime/installer dependencies for a headless (no X11) batch install of 2020.1.
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        libtinfo5 \
        libncurses5 \
        libx11-6 \
        libxext6 \
        libxrender1 \
        libxtst6 \
        libxi6 \
        libgtk2.0-0 \
        locales \
        net-tools \
        unzip \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

# Extract the installer, run the device-trimmed batch install, then delete the
# ~35 GB tarball and extracted tree in the SAME layer so nothing huge persists.
COPY docker/install_config.vivado-2020.1.txt /tmp/install_config.txt
COPY ${INSTALLER} /tmp/installer.tar.gz

RUN set -eux; \
    mkdir -p /tmp/installer; \
    tar -xzf /tmp/installer.tar.gz -C /tmp/installer --strip-components=1; \
    /tmp/installer/xsetup \
        --agree XilinxEULA,3rdPartyEULA,WebTalkTerms \
        --batch Install \
        --config /tmp/install_config.txt; \
    rm -rf /tmp/installer /tmp/installer.tar.gz /tmp/install_config.txt

# Put the toolchain on PATH for login shells (`bash -l`).
ENV XILINX_VIVADO=${INSTALL_DIR}/Vivado/2020.1
ENV PATH=${XILINX_VIVADO}/bin:$PATH
RUN printf '. %s/settings64.sh\n' "${XILINX_VIVADO}" > /etc/profile.d/vivado.sh

# Sanity-check that both tools the VivadoAccelerator backend needs are present.
RUN bash -lc 'vivado -version && vivado_hls -version'

WORKDIR /work
CMD ["/bin/bash", "-l"]
