## PYNQ-Z2 125 MHz system clock
set_property -dict { PACKAGE_PIN H16 IOSTANDARD LVCMOS33 } [get_ports sysclk]
create_clock -add -name sys_clk_pin -period 8.000 -waveform {0.000 4.000} [get_ports sysclk]

## BTN0 resets and redraws the demo scene
set_property -dict { PACKAGE_PIN D19 IOSTANDARD LVCMOS33 } [get_ports btn]

## User LEDs: busy, scene complete, frame pulse, HDMI connected
set_property -dict { PACKAGE_PIN R14 IOSTANDARD LVCMOS33 } [get_ports {led[0]}]
set_property -dict { PACKAGE_PIN P14 IOSTANDARD LVCMOS33 } [get_ports {led[1]}]
set_property -dict { PACKAGE_PIN N16 IOSTANDARD LVCMOS33 } [get_ports {led[2]}]
set_property -dict { PACKAGE_PIN M14 IOSTANDARD LVCMOS33 } [get_ports {led[3]}]

## HDMI output (directly connected to programmable logic)
set_property -dict { PACKAGE_PIN L17 IOSTANDARD TMDS_33 } [get_ports hdmi_tx_clk_n]
set_property -dict { PACKAGE_PIN L16 IOSTANDARD TMDS_33 } [get_ports hdmi_tx_clk_p]
set_property -dict { PACKAGE_PIN K18 IOSTANDARD TMDS_33 } [get_ports {hdmi_tx_d_n[0]}]
set_property -dict { PACKAGE_PIN K17 IOSTANDARD TMDS_33 } [get_ports {hdmi_tx_d_p[0]}]
set_property -dict { PACKAGE_PIN J19 IOSTANDARD TMDS_33 } [get_ports {hdmi_tx_d_n[1]}]
set_property -dict { PACKAGE_PIN K19 IOSTANDARD TMDS_33 } [get_ports {hdmi_tx_d_p[1]}]
set_property -dict { PACKAGE_PIN H18 IOSTANDARD TMDS_33 } [get_ports {hdmi_tx_d_n[2]}]
set_property -dict { PACKAGE_PIN J18 IOSTANDARD TMDS_33 } [get_ports {hdmi_tx_d_p[2]}]
set_property -dict { PACKAGE_PIN R19 IOSTANDARD LVCMOS33 PULLUP true } [get_ports hdmi_tx_hpdn]

## Keep the DDR TMDS output registers in I/O logic.
set_property IOB TRUE [get_cells -hier -filter {NAME =~ *gen_ddr*oddr_inst}]
