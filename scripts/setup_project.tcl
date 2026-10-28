set script_dir [file dirname [file normalize [info script]]]
set project_dir [file dirname $script_dir]

set rtl_files [list \
    [file join $project_dir rtl graphics_accelerator.sv] \
    [file join $project_dir rtl framebuffer_dp.sv] \
    [file join $project_dir rtl video_timing_640x480.sv] \
    [file join $project_dir rtl tmds_encoder.sv] \
    [file join $project_dir rtl tmds_serializer.sv] \
    [file join $project_dir rtl demo_scene.sv] \
    [file join $project_dir rtl graphics_hdmi_top.sv]]

add_files -norecurse -fileset sources_1 $rtl_files
add_files -norecurse -fileset constrs_1 [file join $project_dir constraints pynq_z2_graphics.xdc]
add_files -norecurse -fileset sim_1 [list \
    [file join $project_dir sim graphics_accelerator_tb.sv] \
    [file join $project_dir sim video_pipeline_tb.sv]]
set_property top graphics_hdmi_top [get_filesets sources_1]
set_property top graphics_accelerator_tb [get_filesets sim_1]
set_property target_simulator XSim [current_project]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
save_project
puts "Graphics project configured. Run simulation, synthesis, then implementation."
