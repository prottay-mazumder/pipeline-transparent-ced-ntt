# Barrett NTT CED Pipeline

## Overview
This project implements a fully pipelined Number Theoretic Transform (NTT) architecture for finite field polynomial multiplication over GF(97), enhanced with Barrett modular reduction and pipeline-transparent concurrent error detection (CED).

The design is targeted for FPGA/ASIC deployment and focuses on high-throughput, synthesizable, and fault-tolerant polynomial multiplication.

## Features
- Fully pipelined 5-stage Cooley–Tukey DIF NTT architecture
- Polynomial multiplication over GF(97) with 32 coefficients
- Barrett modular reduction replacing hardware division
- ROM-less twiddle factor handling
- Zero-overhead combinational concurrent error detection (CED)
- Pipeline-synchronized error propagation mechanism
- Synthesizable RTL design compatible with Vivado/XSIM

## Architecture Highlights
- Each butterfly unit includes built-in CED logic without additional pipeline depth
- Error detection based on algebraic invariants of DIF butterflies
- Barrett reduction used for all modular arithmetic operations
- Error signals accumulated and aligned with pipeline output timing

## Verification
The design is validated using a self-checking testbench that:
- Confirms correct polynomial convolution results
- Ensures correct pipeline behavior
- Verifies absence of false-positive error detections under fault-free conditions

## Applications
- Post-quantum cryptography (PQC) hardware accelerators
- Lattice-based cryptographic systems (e.g., NTT-based schemes)
- Fault-tolerant FPGA/ASIC signal processing pipelines

## Implementation Notes
- Language: Verilog / SystemVerilog (assumed)
- Target tools: Xilinx Vivado, XSIM
- Modular arithmetic optimized using Barrett reduction

## References
- NTT and Cooley–Tukey FFT-style decomposition
- Barrett modular reduction algorithm
- Concurrent error detection techniques in pipelined architectures

## Author
[Your Name]
