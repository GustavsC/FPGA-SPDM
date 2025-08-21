#!/bin/bash

# Source Vivado environment
source /opt/Xilinx/Vivado/2023.1/settings64.sh

# Run your TCL script
MALLOC_CHECK_=3 LD_PRELOAD=/lib/x86_64-linux-gnu/libudev.so.1 vivado -mode batch -source fpga.tcl -notrace

