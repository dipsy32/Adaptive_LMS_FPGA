# Adaptive_LMS_FPGA
Adaptive Sign-Error LMS Noise Canceller with OBC on Artix-7 FPGA

This project implements an 8-tap Sign-Error LMS Adaptive Noise Canceller on the Basys-3 (Artix-7) FPGA. The inner product is computed using Offset Binary Coding (OBC), replacing multipliers with shift–add logic for a resource-efficient hardware architecture.

## Repository Structure
- `src` – Verilog source files (`lms_core.v`, `rom_data.v`, `top_lms_system.v`, etc.)
- `tb` – Testbench modules for simulation.
- `constraints` – XDC file for Basys-3 pin assignments and clock.
- `python` – Python Golden Model and ROM data generation.
- `snapshots` – Block Diagram, Python Model Output waveform, Behavioral and ILA waveform screenshots, timing and power plots.
- `docs` – Final project report.

## How to Use
1. Create a Vivado project targeting **Basys-3 (XC7A35T-1CPG236C)**.
2. Add all files from `src` and `constraints`.
3. Optionally run testbenches from `tb` for behavioral simulation.
4. Run **Synthesis → Implementation → Generate Bitstream**.
5. Program the FPGA and observe `d_in`, `y_out`, and `e_out` using ILA.

## Python Golden Model
The script in `python/python_golden_model.py`:
- Generates noisy input and desired signals.
- Runs a Sign-Error LMS Adaptive Noise Canceller in floating-point.
- Exports ROM initialization data for `rom_data.v`.

Project for: *FPGA Implementation of Adaptive LMS Filter using Offset Binary Coding (OBC)*, submitted on **25 November 2025**.
