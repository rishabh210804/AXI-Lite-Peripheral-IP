# Primary Clock Definition (100 MHz target on s_axi_aclk)
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} [get_ports s_axi_aclk]

# Input / Output Delays (20% setup delay budgeting)
set_input_delay -clock sys_clk_pin 2.000 [get_ports s_axi_aresetn]
set_input_delay -clock sys_clk_pin 2.000 [get_ports s_axi_aw*]
set_input_delay -clock sys_clk_pin 2.000 [get_ports s_axi_w*]
set_input_delay -clock sys_clk_pin 2.000 [get_ports s_axi_ar*]

set_output_delay -clock sys_clk_pin 2.000 [get_ports s_axi_r*]
set_output_delay -clock sys_clk_pin 2.000 [get_ports s_axi_b*]
set_output_delay -clock sys_clk_pin 2.000 [get_ports irq_out]