`timescale 1ns/1ps

module graphics_hdmi_top (
    input  logic       sysclk,
    input  logic       btn,
    input  logic       hdmi_tx_hpdn,
    output logic       hdmi_tx_clk_p,
    output logic       hdmi_tx_clk_n,
    output logic [2:0] hdmi_tx_d_p,
    output logic [2:0] hdmi_tx_d_n,
    output logic [3:0] led
);

    localparam int WIDTH   = 640;
    localparam int HEIGHT  = 480;
    localparam int COORD_W = 10;
    localparam int COLOR_W = 12;
    localparam int ADDR_W  = $clog2(WIDTH * HEIGHT);

    logic rst;
    logic pixel_ce;

    logic cmd_valid;
    logic cmd_ready;
    logic [1:0] cmd_shape;
    logic [COORD_W-1:0] cmd_x0, cmd_y0, cmd_x1, cmd_y1, cmd_x2, cmd_y2;
    logic [COLOR_W-1:0] cmd_color;
    logic draw_busy;
    logic draw_done;
    logic scene_complete;

    logic pixel_valid;
    logic [COORD_W-1:0] pixel_x;
    logic [COORD_W-1:0] pixel_y;
    logic [COLOR_W-1:0] pixel_color;
    logic [ADDR_W-1:0] write_addr;

    logic [9:0] video_x;
    logic [9:0] video_y;
    logic video_active;
    logic video_hsync;
    logic video_vsync;
    logic frame_start;
    logic [ADDR_W-1:0] read_addr;
    logic [COLOR_W-1:0] framebuffer_pixel;

    logic delayed_active;
    logic delayed_hsync;
    logic delayed_vsync;
    logic [7:0] red;
    logic [7:0] green;
    logic [7:0] blue;
    logic [9:0] red_code;
    logic [9:0] green_code;
    logic [9:0] blue_code;

    logic [2:0] reset_pipe = 3'b111;

    always_ff @(posedge sysclk) begin
        if (btn)
            reset_pipe <= 3'b111;
        else
            reset_pipe <= {reset_pipe[1:0], 1'b0};
    end

    assign rst = reset_pipe[2];
    assign write_addr = pixel_y * WIDTH + pixel_x;
    assign read_addr = video_active ? (video_y * WIDTH + video_x) : '0;

    assign red   = {framebuffer_pixel[11:8], framebuffer_pixel[11:8]};
    assign green = {framebuffer_pixel[7:4],  framebuffer_pixel[7:4]};
    assign blue  = {framebuffer_pixel[3:0],  framebuffer_pixel[3:0]};

    assign led[0] = draw_busy;
    assign led[1] = scene_complete;
    assign led[2] = frame_start;
    assign led[3] = ~hdmi_tx_hpdn;

    demo_scene scene (
        .clk(sysclk),
        .rst(rst),
        .cmd_ready(cmd_ready),
        .draw_done(draw_done),
        .cmd_valid(cmd_valid),
        .cmd_shape(cmd_shape),
        .cmd_x0(cmd_x0), .cmd_y0(cmd_y0),
        .cmd_x1(cmd_x1), .cmd_y1(cmd_y1),
        .cmd_x2(cmd_x2), .cmd_y2(cmd_y2),
        .cmd_color(cmd_color),
        .scene_complete(scene_complete)
    );

    graphics_accelerator #(
        .SCREEN_WIDTH(WIDTH),
        .SCREEN_HEIGHT(HEIGHT),
        .COORD_W(COORD_W),
        .COLOR_W(COLOR_W)
    ) rasterizer (
        .clk(sysclk),
        .rst(rst),
        .cmd_valid(cmd_valid),
        .cmd_ready(cmd_ready),
        .cmd_shape(cmd_shape),
        .cmd_x0(cmd_x0), .cmd_y0(cmd_y0),
        .cmd_x1(cmd_x1), .cmd_y1(cmd_y1),
        .cmd_x2(cmd_x2), .cmd_y2(cmd_y2),
        .cmd_color(cmd_color),
        .pixel_valid(pixel_valid),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .pixel_color(pixel_color),
        .busy(draw_busy),
        .done(draw_done)
    );

    framebuffer_dp #(
        .WIDTH(WIDTH),
        .HEIGHT(HEIGHT),
        .COLOR_W(COLOR_W),
        .ADDR_W(ADDR_W)
    ) framebuffer (
        .wr_clk(sysclk),
        .wr_en(pixel_valid),
        .wr_addr(write_addr),
        .wr_data(pixel_color),
        .rd_clk(sysclk),
        .rd_en(pixel_ce),
        .rd_addr(read_addr),
        .rd_data(framebuffer_pixel)
    );

    video_timing_640x480 timing (
        .clk(sysclk),
        .rst(rst),
        .pixel_ce(pixel_ce),
        .x(video_x),
        .y(video_y),
        .active_video(video_active),
        .hsync(video_hsync),
        .vsync(video_vsync),
        .frame_start(frame_start)
    );

    always_ff @(posedge sysclk) begin
        if (rst) begin
            delayed_active <= 1'b0;
            delayed_hsync  <= 1'b1;
            delayed_vsync  <= 1'b1;
        end else if (pixel_ce) begin
            delayed_active <= video_active;
            delayed_hsync  <= video_hsync;
            delayed_vsync  <= video_vsync;
        end
    end

    tmds_encoder encode_red (
        .clk(sysclk), .rst(rst), .ce(pixel_ce),
        .video_data(red), .control_data(2'b00),
        .video_enable(delayed_active), .tmds_code(red_code)
    );

    tmds_encoder encode_green (
        .clk(sysclk), .rst(rst), .ce(pixel_ce),
        .video_data(green), .control_data(2'b00),
        .video_enable(delayed_active), .tmds_code(green_code)
    );

    tmds_encoder encode_blue (
        .clk(sysclk), .rst(rst), .ce(pixel_ce),
        .video_data(blue), .control_data({delayed_vsync, delayed_hsync}),
        .video_enable(delayed_active), .tmds_code(blue_code)
    );

    tmds_serializer serializer (
        .clk_5x(sysclk),
        .rst(rst),
        .red_code(red_code),
        .green_code(green_code),
        .blue_code(blue_code),
        .pixel_ce(pixel_ce),
        .tmds_clk_p(hdmi_tx_clk_p),
        .tmds_clk_n(hdmi_tx_clk_n),
        .tmds_data_p(hdmi_tx_d_p),
        .tmds_data_n(hdmi_tx_d_n)
    );

endmodule
