set script_dir [file dirname [file normalize [info script]]]
set project_dir [file dirname $script_dir]
set report_dir [file join $project_dir reports]
set output_dir [file join $project_dir output]
file mkdir $report_dir
file mkdir $output_dir

open_project [file join $project_dir Graphics.xpr]
reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1
open_run synth_1
report_utilization -file [file join $report_dir post_synth_utilization.rpt]
report_timing_summary -file [file join $report_dir post_synth_timing.rpt]

launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
open_run impl_1
report_utilization -file [file join $report_dir post_route_utilization.rpt]
report_timing_summary -file [file join $report_dir post_route_timing.rpt]
report_power -file [file join $report_dir post_route_power.rpt]
write_bitstream -force [file join $output_dir graphics_accelerator.bit]
puts "Build complete. Reports are in $report_dir."
