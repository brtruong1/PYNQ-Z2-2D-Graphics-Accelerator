`timescale 1ns/1ps

module video_pipeline_tb;
    logic clk = 1'b0;
    logic rst;
    logic pixel_ce;
    logic [9:0] x;
    logic [9:0] y;
    logic active_video;
    logic hsync;
    logic vsync;
    logic frame_start;

    logic [7:0] video_data;
    logic [1:0] control_data;
    logic video_enable;
    logic [9:0] tmds_code;
    integer cycles;
    integer active_count;
    integer hsync_low_count;

    always #4 clk = ~clk;

    video_timing_640x480 timing (.*);
    tmds_encoder encoder (
        .clk(clk), .rst(rst), .ce(pixel_ce),
        .video_data(video_data),
        .control_data(control_data),
        .video_enable(video_enable),
        .tmds_code(tmds_code)
    );

    initial begin
        rst = 1'b1;
        pixel_ce = 1'b1;
        video_data = 8'h00;
        control_data = 2'b00;
        video_enable = 1'b0;
        cycles = 0;
        active_count = 0;
        hsync_low_count = 0;
        repeat (3) @(posedge clk);
        rst <= 1'b0;

        #1;
        if (tmds_code !== 10'b1101010100)
            $fatal(1, "Incorrect TMDS control symbol 00");
        control_data = 2'b01; #1;
        if (tmds_code !== 10'b0010101011)
            $fatal(1, "Incorrect TMDS control symbol 01");
        control_data = 2'b10; #1;
        if (tmds_code !== 10'b0101010100)
            $fatal(1, "Incorrect TMDS control symbol 10");
        control_data = 2'b11; #1;
        if (tmds_code !== 10'b1010101011)
            $fatal(1, "Incorrect TMDS control symbol 11");

        control_data = 2'b00;
        while (cycles < 800) begin
            @(posedge clk);
            cycles = cycles + 1;
            if (active_video)
                active_count = active_count + 1;
            if (!hsync)
                hsync_low_count = hsync_low_count + 1;
        end

        #1;

        if (active_count != 640)
            $fatal(1, "Active width was %0d, expected 640", active_count);
        if (hsync_low_count != 96)
            $fatal(1, "HSYNC width was %0d, expected 96", hsync_low_count);
        if (x != 0 || y != 1)
            $fatal(1, "Timing did not advance to start of line 2: x=%0d y=%0d", x, y);

        $display("PASS: 640x480 timing and TMDS control symbols");
        $finish;
    end

endmodule
