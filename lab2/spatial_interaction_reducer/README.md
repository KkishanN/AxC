# Silicon for Symbolic Computation: Spatial Interaction-Net Reducer

A cycle-accurate hardware simulator for an **Interaction-Net Reducer on Reconfigurable Fabric (FPGA)**. 

Evaluates spatial hardware execution of the **Interaction Calculus (IC)** against CPU and GPU baselines, measuring rewrite throughput (interactions per second), memory bank stall cycles, and energy efficiency (Joules per billion interactions).

---

## 🏗️ Architecture Overview

Unlike von Neumann architectures that interpret rewrite rules through instruction fetch-decode loops, or GPUs that suffer from warp divergence on irregular graph traversals, this design maps interaction combinators directly into **spatial rule blocks**:

1. **Spatial Rule Blocks**: Dedicated FSM hardware units for:
   - `APP-LAM`: Atomic port swap for single-cycle substitution (zero term traversal).
   - `DUP-SUP`: Equal label annihilation or commutation into duplicate superpositions.
   - `APP-SUP` & `DUP-LAM`: Distributive term copying.
   - `ERA`: Immediate node deallocation to on-chip free-list.
   - `NUM/SUC`: Direct natural-number arithmetic.
2. **Banked On-Chip BRAM / URAM**:
   - 8 interleaved memory banks with conflict arbitration.
   - Dedicated free-list allocator for floating duplication nodes.
3. **Decentralized Work Distribution**:
   - Asynchronous message-passing FIFO network routing active redexes directly between rule blocks with no central scheduler.

---

## 📊 Benchmark & Verification Results

Simulated at a target clock frequency of **250 MHz** on Xilinx UltraScale+ FPGA architecture (14.8W dynamic power envelope):

| Benchmark Net | Active Rule Blocks | Total Rewrites | Sim Clock Cycles | Wall Clock | Throughput (MInt/s) | Energy (J / GInt) | Efficiency vs CPU |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **Bitonic Reduction (Depth 14)** | 8 Units | 24,576 | 76,792 | 0.307 ms | **80.01 MInt/s** | **184.98 J/GInt** | **2.26× More Efficient** |
| **Tree Reduction (Depth 16)** | 16 Units | 98,304 | 350,200 | 1.401 ms | **70.18 MInt/s** | **210.90 J/GInt** | **1.98× More Efficient** |

### Key Findings:
- **Energy Superiority over General-Purpose CPUs**: Consumes **184.98 Joules per billion interactions**, yielding a **2.26× energy efficiency gain** over high-performance single-thread CPUs (~418 J/GInt).
- **Memory Hazard Quantification**: Uncovered that 8-bank memory arbitration incurs a ~96% stall rate on high-concurrency tree nets, demonstrating that future hardware revisions require 32+ interleaved banks or spatial crossbars to unleash peak spatial parallel throughput.

---

## 🛠️ Quick Start

```bash
# Compile with clang++
make

# Run cycle-accurate simulation benchmarks
make run
```
