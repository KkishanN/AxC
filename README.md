# Approximate Computing (AxC)

[![University](https://img.shields.io/badge/Universität-Paderborn-blue.svg)](https://www.uni-paderborn.de/)
[![Course](https://img.shields.io/badge/Course-Approximate%20Computing%20(AxC)-green.svg)]()
[![Hardware](https://img.shields.io/badge/Language-VHDL%20%7C%20C%2B%2B17%20%7C%20Python-orange.svg)]()
[![Status](https://img.shields.io/badge/Build-Passing-brightgreen.svg)]()

Graduate coursework and systems research developed for the **Approximate Computing (AxC 2026)** curriculum at **Universität Paderborn**, instructed by **Dr. Muhammad Awais** and **Prof. Dr. Marco Platzner**.

This repository hosts algorithmic and hardware approximation frameworks across deep learning, digital signal processing, and symbolic hardware accelerators.

---

## Repository Modules

```
AxC/
├── lab1/ (Task1/)                       # Approximate Machine Learning (LeNet-5 on MNIST)
│   ├── lab1_sol.ipynb                  # Complete solution notebook with interactive evaluations
│   ├── Lab1_Task_AxC_Course26.pdf      # Lab 1 assignment specification
│   ├── README.md                       # Comprehensive report & F1-score comparison tables
│   └── data/MNIST/                     # MNIST raw training and testing dataset
│
└── lab2/ (Task2/)                       # Hardware Approximate Computing & Spatial Reducer
    ├── README.md                       # Complete Module 2 technical report & Pareto analysis
    ├── Lab2_3_Task_AxC_Course26.pdf    # Lab 2 assignment specification
    │
    ├── [Part A: Approximate FIR Filter Design Space Exploration]
    │   ├── fir_filter.vhd              # Synthesizable 10-stage pipelined FIR filter (1.0ns clock)
    │   ├── approx_components.vhd       # Parameterized approximate adders & multipliers
    │   ├── fir_filter_tb.vhd           # GHDL testbench for exact vs. approximate verification
    │   ├── dse_beam_search.py          # Beam Search DSE algorithm (10,000 samples, MSE <= 5%)
    │   ├── pareto_plot.py              # Pareto curve generation script
    │   ├── pareto_results.json / .csv  # Top 10 candidate architectures data
    │   ├── pareto_curve.png            # Visual plot of Area vs. NMSE frontier
    │   └── synth_dc.tcl                # Synopsys Design Compiler synthesis script
    │
    └── [Part B: Silicon for Symbolic Computation: Spatial Interaction Reducer]
        └── spatial_interaction_reducer/
            ├── include/
            │   ├── ic32.hpp            # 32-bit packed interaction term representation
            │   ├── bram_memory.hpp     # 8-bank interleaved memory arbiter
            │   └── rule_blocks.hpp     # Hardware FSM execution units
            ├── src/main.cpp            # Cycle-accurate benchmark harness
            ├── Makefile                # Build configuration
            └── README.md               # Dedicated hardware architecture documentation
```

---

## Lab 1: Approximate Machine Learning with LeNet-5

Explore accuracy vs. computational efficiency trade-offs on convolutional neural networks:
- **Weight Pruning (Task 1)**: Evaluates random vs. magnitude-based weight pruning ($10\%\dots50\%$) on all fully connected layers. Magnitude-based pruning preserves $>97.6\%$ test F1-score at 50% parameter reduction.
- **PCA Data Compression (Task 2)**: Reconstructs MNIST images with 20% and 40% of the least significant principal components removed. 20% component removal yields an F1-score of $0.983$ (virtually lossless compared to the $0.988$ exact baseline).
- **Pixel Variance Pruning (Task 3)**: Eliminates non-informative input pixels across the training dataset.
- **Combined Pipeline (Task 4)**: Compound compression yielding ~44% footprint reduction while maintaining $0.979$ test F1-score.

👉 **Full Report & Notebook:** [lab1/](file:///lab1) / [Task1/](file:///Task1)

---

## Lab 2: Hardware Approximate Computing & Spatial Reducer

### Part A: 10-Stage Approximate FIR Filter & Beam Search DSE
Optimizes the hardware area of a 10-stage digital FIR filter subject to strict timing and error tolerances:
- **Design Specifications**: Pipelined architecture meeting $T_{\text{clk}} = 1.0\text{ ns}$ ($1.0\text{ GHz}$ clock target) and latency $\le 3$ cycles.
- **DSE Algorithm**: Beam Search ($K = 3$) evaluating candidate configurations on **10,000 uniform random samples** in $[0, 255]$ without repetition.
- **Constraint Enforcement**: Strictly prunes designs violating $\text{NMSE} \le 5.0\%$.
- **Pareto-Optimal Top Candidate**:
  - **Estimated Area**: $12,176.0\ \mu\text{m}^2$ (**10.34% area savings** over $13,580.0\ \mu\text{m}^2$ baseline).
  - **Quality**: Normalized Mean Squared Error of **0.000031%** (well within the 5.0% ceiling).
- **Synthesis**: Includes Synopsys Design Compiler (`synth_dc.tcl`) scripts for gate-level area and power extraction.

### Part B: Silicon for Symbolic Computation: Spatial Interaction Reducer
A cycle-accurate C++17 hardware simulator and FPGA architecture for Interaction Calculus graph reduction runtimes (HVM2 / Bend):
- **Decentralized Spatial Rule Blocks**: Dedicated FSM pipelines for `APP-LAM`, `DUP-SUP`, `APP-SUP`, `DUP-LAM`, `ERA`, and `NUM/SUC`.
- **8-Bank Interleaved On-Chip BRAM**: Dual-port conflict arbiter with free-list node recycling, eliminating external DRAM bottlenecks.
- **Performance Benchmark**:
  - Depth-14 Bitonic Sort / Tree Reduction Net: **24,576 rewrites** reduced in **0.307 ms**.
  - **Throughput**: **80.01 MInt/s** (Million Interactions Per Second) at 250 MHz target clock.
  - **Energy Efficiency**: Consumes $184.98\text{ J/GInt}$, delivering **2.26× higher energy efficiency than CPU baselines** ($418.00\text{ J/GInt}$).

👉 **Full Report & Source Code:** [lab2/](file:///lab2) / [Task2/](file:///Task2)

---

## Quick Start & Verification

### Run FIR Filter Beam Search DSE
```bash
cd lab2
python3 dse_beam_search.py
python3 pareto_plot.py
```

### Run Spatial Interaction Reducer Simulation
```bash
cd lab2/spatial_interaction_reducer
make clean && make
./spatial_reducer_sim
```

### Run LeNet-5 Evaluation
```bash
cd lab1
jupyter notebook lab1_sol.ipynb
```

---

## Author
**Kishan Nadageri**  
M.Sc. Computer Engineering, Universität Paderborn  
GitHub: [@KkishanN](https://github.com/KkishanN)
