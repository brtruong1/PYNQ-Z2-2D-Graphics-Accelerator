# FPGA 2D Graphics Accelerator

A command-driven 2D rasterizer for the PYNQ-Z2. The design draws Bresenham lines,
rectangle outlines, and filled triangles into a 640x480 RGB444 framebuffer, then
streams the framebuffer to the board's HDMI output using a DVI-compatible TMDS
pipeline.
<img width="731" height="531" alt="image" src="https://github.com/user-attachments/assets/de50a3b6-a04b-451f-8826-e5982271f6d3" />
