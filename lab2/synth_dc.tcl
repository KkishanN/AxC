# ==============================================================================
# Synopsys Design Compiler (DC) Synthesis Script
# 10-Stage Approximate FIR Filter
# Approximate Computing (AxC)
# ==============================================================================

# Set search path and target technology libraries
set target_library [list typical.db]
set link_library   [list * typical.db]

# Define design directory and target top-level entity
set TOP_ENTITY "fir_filter"

# Read VHDL source files
analyze -format vhdl [list approx_components.vhd fir_filter.vhd]
elaborate $TOP_ENTITY

# Link and check design integrity
current_design $TOP_ENTITY
link
check_design

# Define Clock Timing Constraint: 1.0 ns period (1.0 GHz target)
create_clock -name "clk" -period 1.0 -waveform {0 0.5} [get_ports clk]
set_clock_uncertainty 0.05 [get_clocks clk]
set_input_delay  0.2 -clock clk [all_inputs -no_clocks]
set_output_delay 0.2 -clock clk [all_outputs]

# Compile and optimize for area minimization
compile_ultra -area_effort high

# Generate reports
report_area > report_area.txt
report_timing > report_timing.txt
report_power > report_power.txt

# Export netlist
write -format vhdl -hierarchy -output fir_filter_synth.vhd
write -format ddc -hierarchy -output fir_filter_synth.ddc

echo "Synthesis and Area Reporting Completed Successfully."
