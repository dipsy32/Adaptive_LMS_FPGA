# Clock Signal (100 MHz)
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

# Reset mapped to Switch 0 (V17) 
set_property PACKAGE_PIN V17 [get_ports rst_btn]
set_property IOSTANDARD LVCMOS33 [get_ports rst_btn]

# False path for the switch (ignores timing warnings)
set_false_path -from [get_ports rst_btn]