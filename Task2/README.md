# Lab Module 2: Hardware Approximate Computing & Spatial Architecture

**Institution:** Universität Paderborn  
**Course:** Approximate Computing (AxC 2026)  
**Author:** Kishan Nadageri  
**Instructors:** Dr. Muhammad Awais, Prof. Dr. Marco Platzner  

---

## Overview

This module encompasses two core systems for approximate and symbolic hardware computation:
1. **Approximate FIR Filter Design Space Exploration (DSE)**: A complete VHDL synthesizable 10-stage digital signal processing filter optimized via Beam Search heuristic exploration under strict quality constraints ($\text{MSE} \le 5.0\%$) and synthesized with Synopsys Design Compiler.
2. **Silicon for Symbolic Computation: Spatial Interaction Reducer**: A cycle-accurate C++17 hardware simulator modeling parallel spatial rule-blocks and interleaved on-chip BRAM memory for massively parallel graph reduction (Interaction Calculus / HVM2 / Bend).

---

## Part 1: Approximate FIR Filter Design Space Exploration (DSE)

### 1. Filter Specifications & Constraints
- **Architecture**: 10-Stage Transposed / Pipelined FIR Filter.
- **Input / Output**: 32-bit `std_logic_vector` words.
- **Coefficients**:
  - $b_0 = b_9 = 3$
  - $b_1 = b_8 = 25$
  - $b_2 = b_7 = 96$
  - $b_3 = b_6 = 384$
  - $b_4 = b_5 = 3073$
- **Timing Constraint**: Clock period $T_{\text{clk}} = 1.0\text{ ns}$ ($1.0\text{ GHz}$).
- **Throughput**: 1 result per cycle.
- **Latency**: $\le 3$ clock cycles.

### 2. Approximate Arithmetic Units
- **`approx_adder`**: Parameterized 32-bit adder supporting $1\dots8$ bits of Least Significant Bit (LSB) truncation (eliminating lower carry-propagation chains) and Most Significant Bit (MSB) truncation.
- **`approx_multiplier`**: Parameterized 32-bit multiplier truncating lower $1\dots8$ partial-product columns.

### 3. Beam Search DSE Algorithm
- **Beam Width**: $K = 3$ (expands the top-3 area-saving candidate architectures at each step).
- **Test Dataset**: $10,000$ uniform random input vectors drawn from $[0, 255]$ without repetition.
- **Error Criterion**: $\text{NMSE} = \frac{\sum (y_{\text{exact}} - y_{\text{approx}})^2}{\sum y_{\text{exact}}^2} \times 100\% \le 5.0\%$.
- **Area Estimation Model**: Precomputed standard-cell gate areas (Nangate 45nm / 65nm cell baseline):
  - Exact 32-bit Multiplier: $1250.0\ \mu\text{m}^2$
  - Exact 32-bit Adder: $120.0\ \mu\text{m}^2$
  - Baseline Filter Arithmetic Area: $10 \times 1250 + 9 \times 120 = 13,580.0\ \mu\text{m}^2$.

### 4. Top 10 Pareto-Optimal Candidate Configurations
The DSE beam search evaluated dozens of configurations across 18 iterations, isolating the top 10 candidates with lowest circuit area satisfying $\text{NMSE} \le 5.0\%$:

| Rank | Estimated Area ($\mu\text{m}^2$) | Area Savings (%) | NMSE (%) | Multiplier LSB Truncation $[b_0\dots b_9]$ | Adder LSB Truncation $[a_0\dots a_8]$ |
|:---:|:---:|:---:|:---:|:---:|:---:|
| **1** | **12,176.0** | **10.34%** | **0.000031%** | `[8, 8, 8, 8, 2, 0, 0, 0, 0, 2]` | `[0, 0, 0, 0, 0, 0, 0, 0, 0]` |
| **2** | **12,176.0** | **10.34%** | **0.000031%** | `[8, 8, 8, 8, 0, 2, 0, 0, 0, 2]` | `[0, 0, 0, 0, 0, 0, 0, 0, 0]` |
| **3** | **12,176.0** | **10.34%** | **0.000031%** | `[8, 8, 8, 8, 2, 0, 0, 0, 2, 0]` | `[0, 0, 0, 0, 0, 0, 0, 0, 0]` |
| **4** | **12,176.0** | **10.34%** | **0.000031%** | `[8, 8, 8, 8, 2, 0, 0, 2, 0, 0]` | `[0, 0, 0, 0, 0, 0, 0, 0, 0]` |
| **5** | **12,176.0** | **10.34%** | **0.000031%** | `[8, 8, 8, 8, 0, 2, 0, 0, 2, 0]` | `[0, 0, 0, 0, 0, 0, 0, 0, 0]` |
| **6** | **12,176.0** | **10.34%** | **0.000031%** | `[8, 8, 8, 8, 0, 2, 0, 2, 0, 0]` | `[0, 0, 0, 0, 0, 0, 0, 0, 0]` |
| **7** | **12,176.0** | **10.34%** | **0.000031%** | `[8, 8, 8, 8, 2, 2, 0, 0, 0, 0]` | `[0, 0, 0, 0, 0, 0, 0, 0, 0]` |
| **8** | **12,176.0** | **10.34%** | **0.000031%** | `[8, 8, 8, 8, 0, 0, 2, 0, 0, 2]` | `[0, 0, 0, 0, 0, 0, 0, 0, 0]` |
| **9** | **12,176.0** | **10.34%** | **0.000031%** | `[8, 8, 8, 8, 0, 0, 2, 0, 2, 0]` | `[0, 0, 0, 0, 0, 0, 0, 0, 0]` |
| **10** | **12,176.0** | **10.34%** | **0.000031%** | `[8, 8, 8, 8, 0, 0, 2, 2, 0, 0]` | `[0, 0, 0, 0, 0, 0, 0, 0, 0]` |

*Key finding:* Multipliers with smaller weights ($b_0, b_1, b_8, b_9$) can be truncated up to 8 bits with virtually negligible global MSE impact, reducing circuit area by over 10%.

### 5. Running the FIR DSE & Logic Synthesis
```bash
# 1. Run the Beam Search DSE algorithm (evaluates 10,000 samples and generates JSON/CSV results)
python3 dse_beam_search.py

# 2. Generate the Pareto Frontier Plot
python3 pareto_plot.py

# 3. Synthesize candidate with Synopsys Design Compiler (on remote UPB server)
singularity exec /ceg/container/Synopsys_2015.06-SP4.sif dc_shell -f synth_dc.tcl
```

---

## Part 2: Silicon for Symbolic Computation: Spatial Interaction Reducer

A high-performance cycle-accurate hardware simulator for graph reduction runtimes (Interaction Calculus / HVM2 / Bend).

### Architecture Highlights
- **Decentralized Spatial Rule Blocks**: Dedicated FSM pipelines for interaction net primitives:
  - `APP-LAM` (Function substitutions)
  - `DUP-SUP` (Annihilation & Commutation)
  - `APP-SUP` (Distributions)
  - `DUP-LAM` (Duplications)
  - `ERA` (Garbage collection / Erasure)
  - `NUM / SUC` (Arithmetic operations)
- **8-Bank Interleaved On-Chip BRAM**:
  - Eliminates external DRAM bottlenecks through spatial address hashing ($A \pmod 8$).
  - Dual-port cycle-by-cycle conflict arbiter with free-list node recycling.

### Benchmark Results
Executed on Bitonic Sort & Tree Reduction Net at 250 MHz target FPGA clock frequency:

```
=================================================================
  FPGA Spatial Reducer Simulation Results (Depth 14, 8 Rule-Blocks)
=================================================================
Target Clock Frequency:               250 MHz
Active Hardware Rule Blocks:          8 spatial units
Total Rewrite Interactions:           24,576 rewrites
  - APP-LAM (Substitutions):          8,192
  - DUP-SUP (Annihilations):          16,384
Total Hardware Clock Cycles:          76,792 cycles
Simulated Execution Time:             0.3072 ms
Throughput:                           80.01 MInt/s (Million Interactions/sec)
-----------------------------------------------------------------
ENERGY COMPARISON
-----------------------------------------------------------------
Spatial Reducer FPGA (14.8W):         184.98 Joules / Billion Interactions
CPU Baseline (Ryzen 9, single-core):  418.00 Joules / Billion Interactions
Energy Efficiency vs CPU Baseline:    2.26x MORE ENERGY EFFICIENT
=================================================================
```

### Compiling & Running Spatial Reducer Simulator
```bash
cd spatial_interaction_reducer
make clean && make
./spatial_reducer_sim
```

---

## Repository Structure

```
Task2/ (also accessible via lab2/)
├── approx_components.vhd       # Synthesizable VHDL approximate adders and multipliers
├── fir_filter.vhd              # Synthesizable 10-stage pipelined FIR filter (1.0ns clock)
├── fir_filter_tb.vhd           # GHDL simulation testbench
├── dse_beam_search.py          # Beam Search DSE algorithm (10,000 samples, MSE <= 5%)
├── pareto_plot.py              # Generates Pareto trade-off curve
├── pareto_results.json         # Top 10 candidate architectures data
├── pareto_results.csv          # CSV export of Pareto configurations
├── pareto_curve.png            # Visual plot of Area vs NMSE frontier
├── synth_dc.tcl                # Synopsys Design Compiler synthesis script
├── fadd.vhd / fadd_tb.vhd      # Full adder tutorial files
├── Lab2_3_Task_AxC_Course26.pdf # Course assignment specification
└── spatial_interaction_reducer/
    ├── include/
    │   ├── ic32.hpp            # 32-bit packed interaction calculus term representation
    │   ├── bram_memory.hpp     # 8-bank interleaved memory arbiter
    │   └── rule_blocks.hpp     # Hardware FSM execution units
    ├── src/
    │   └── main.cpp            # Cycle-accurate benchmark harness
    ├── Makefile                # Build configuration
    └── README.md               # Dedicated architecture documentation
```
