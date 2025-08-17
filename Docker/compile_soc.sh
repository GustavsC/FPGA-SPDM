#!/bin/bash

# Source Vivado environment
source /opt/Xilinx/Vivado/2023.1/settings64.sh

# Search files in this DIR
DIR="/FPGA-SPDM/SoC/SoC_with_SPDM"

cd "$DIR" || exit 1

# Run your TCL script
MALLOC_CHECK_=3 LD_PRELOAD=/lib/x86_64-linux-gnu/libudev.so.1 vivado -mode batch -source /FPGA-SPDM/SoC/SoC_with_SPDM/digilent_netfpga_sume.tcl -notrace

