# Approximate Computing - Lab Module 2

This folder (`Task2`) is set up as a starting point for your Approximate Computing Lab 2 project. Below is a guide on how to use the different tools installed on your local machine and the remote server.

## Overview of the Tools

1. **Python / C++**: You will use these languages to write your Design Space Exploration (DSE) algorithm (e.g., Beam Search).
2. **GHDL**: A local, open-source VHDL simulator you can use to check your VHDL files (like the FIR filter) before sending them to the Synopsys synthesizer.
3. **GTKWave**: A tool to visually inspect the simulated waveforms of your VHDL logic.
4. **Synopsys Design Compiler (DC)**: The industry-standard tool for synthesizing your VHDL down to logic gates and generating accurate area/power metrics. This tool is hosted on the university's remote virtual machine.

---

## "Hello World" VHDL Example

I have provided two files as a simple "Hello World" example for VHDL:
- **`fadd.vhd`**: A simple 1-bit full adder.
- **`fadd_tb.vhd`**: The testbench for simulating the adder.

### Step 1: Simulate the VHDL locally

You can use **GHDL** to compile and run your VHDL testbench locally on your Windows machine. Open your terminal (e.g., PowerShell or MSYS2 MinGW64) and navigate to the `Task2` folder.

1. **Analyze (Compile) the VHDL files**:
   ```bash
   ghdl -a fadd.vhd
   ghdl -a fadd_tb.vhd
   ```

2. **Elaborate the testbench**:
   ```bash
   ghdl -e fadd_tb
   ```

3. **Run the simulation and export waveforms**:
   ```bash
   ghdl -r fadd_tb --vcd=fadd.vcd
   ```
   *Note: This creates an `fadd.vcd` file which contains the simulation waveform data.*

### Step 2: View the Waveforms

You can view the `.vcd` file using **GTKWave**.
Run the following command in your terminal:
```bash
gtkwave fadd.vcd
```
This will open a graphical window where you can drag and drop your signals (`a`, `b`, `ci`, `o`, `co`) into the view area to observe their transitions.

---

## Step 3: Write your DSE Algorithm

For the Design Space Exploration part, you can use Python or C++.
- **Python**: Installed globally (Version 3.12+). You can write your beam search logic in a `.py` file and simply run:
  ```bash
  python dse.py
  ```
- **C++**: The `g++` compiler is installed via MSYS2. You can compile your C++ DSE tool using:
  ```bash
  g++ -o dse_app dse.cpp
  ./dse_app
  ```

Your DSE script should ideally read or generate different approximate configurations of the VHDL files and compute the 10,000-sample Mean Squared Error (MSE) to check the 5% condition.

---

## Step 4: Logic Synthesis with Synopsys DC

Once your DSE algorithm finishes and selects the top-10 candidate VHDL designs, you need to synthesize them to get their true hardware area. Since Synopsys DC requires a special environment, it is not run locally.

1. **Connect to the remote VM via SSH**:
   Open a terminal and run:
   ```bash
   ssh your_imt_username@ceg-axc.cs.upb.de
   ```
   *(Note: You must be on the campus network or using the university VPN).*

2. **Launch Synopsys Design Compiler**:
   Once logged in, you run the containerized Synopsys tool:
   ```bash
   singularity exec /ceg/container/Synopsys_2015.06-SP4.sif dc_shell
   ```

3. **Synthesize**:
   From inside `dc_shell`, you will load your libraries, analyze your `.vhd` files, compile, and run `report_area` as instructed in **Tutorial 2**.
