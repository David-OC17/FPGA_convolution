#!/bin/bash
vlib work
vmap work work
vlog -F comp_files.FILES

# Mult complex: tested
# vsim -c tb_mult_complex -do "run -all; quit"

# Mult fixed complex: tested, overflows failing
# vsim -c tb_mult_fixed_complex -do "run -all; quit"

# Adder3 complex
# vsim -c tb_adder3_complex -do "run -all; quit"

# Conv complex
vsim -c tb_conv_complex -do "run -all; quit"