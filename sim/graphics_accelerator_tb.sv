`timescale 1ns/1ps

module graphics_accelerator_tb;
    localparam int WIDTH = 64;
    localparam int HEIGHT = 48;
    localparam int COORD_W = 6;

    logic clk = 1'b0;
    logic rst;
    logic cmd_valid;
    logic cmd_ready;
    logic [1:0] cmd_shape;
    logic [COORD_W-1:0] cmd_x0, cmd_y0, cmd_x1, cmd_y1, cmd_x2, cmd_y2;
    logic [11:0] cmd_color;
    logic pixel_valid;
    logic [COORD_W-1:0] pixel_x, pixel_y;
    logic [11:0] pixel_color;
    logic busy;
    logic done;

    bit seen [0:WIDTH-1][0:HEIGHT-1];
    integer pixel_count;
    integer failures;
    integer x;
    integer y;

    always #4 clk = ~clk;

    graphics_accelerator #(
        .SCREEN_WIDTH(WIDTH),
        .SCREEN_HEIGHT(HEIGHT),
        .COORD_W(COORD_W),
        .COLOR_W(12)
    ) dut (.*);

    always @(posedge clk) begin
        if (pixel_valid) begin
            seen[pixel_x][pixel_y] = 1'b1;
            pixel_count = pixel_count + 1;
            if (pixel_color !== cmd_color) begin
                $error("Color mismatch at (%0d,%0d)", pixel_x, pixel_y);
                failures = failures + 1;
            end
        end
    end

    task automatic clear_scoreboard;
        begin
            pixel_count = 0;
            for (x = 0; x < WIDTH; x = x + 1)
                for (y = 0; y < HEIGHT; y = y + 1)
                    seen[x][y] = 1'b0;
        end
    endtask

    task automatic send_command(
        input logic [1:0] shape,
        input integer x0,
        input integer y0,
        input integer x1,
        input integer y1,
        input integer x2,
        input integer y2,
        input logic [11:0] color
    );
        begin
            while (!cmd_ready) @(posedge clk);
            cmd_shape <= shape;
            cmd_x0 <= x0;
            cmd_y0 <= y0;
            cmd_x1 <= x1;
            cmd_y1 <= y1;
            cmd_x2 <= x2;
            cmd_y2 <= y2;
            cmd_color <= color;
            cmd_valid <= 1'b1;
            @(posedge clk);
            cmd_valid <= 1'b0;
            while (!done) @(posedge clk);
            @(posedge clk);
        end
    endtask

    task automatic expect_pixel(input integer px, input integer py);
        begin
            if (!seen[px][py]) begin
                $error("Missing expected pixel (%0d,%0d)", px, py);
                failures = failures + 1;
            end
        end
    endtask

    initial begin
        rst = 1'b1;
        cmd_valid = 1'b0;
        cmd_shape = '0;
        cmd_x0 = '0; cmd_y0 = '0;
        cmd_x1 = '0; cmd_y1 = '0;
        cmd_x2 = '0; cmd_y2 = '0;
        cmd_color = '0;
        failures = 0;
        clear_scoreboard();

        repeat (4) @(posedge clk);
        rst <= 1'b0;
        repeat (2) @(posedge clk);

        send_command(2'd0, 2, 2, 8, 5, 0, 0, 12'hF21);
        expect_pixel(2,2); expect_pixel(3,3); expect_pixel(4,3);
        expect_pixel(5,4); expect_pixel(6,4); expect_pixel(7,5); expect_pixel(8,5);
        if (pixel_count != 7) begin
            $error("Line generated %0d pixels, expected 7", pixel_count);
            failures = failures + 1;
        end

        clear_scoreboard();
        send_command(2'd1, 13, 12, 10, 10, 0, 0, 12'h2E5);
        for (x = 10; x <= 13; x = x + 1) begin
            expect_pixel(x, 10);
            expect_pixel(x, 12);
        end
        expect_pixel(10, 11);
        expect_pixel(13, 11);
        if (pixel_count != 10) begin
            $error("Rectangle generated %0d pixels, expected 10", pixel_count);
            failures = failures + 1;
        end

        clear_scoreboard();
        send_command(2'd2, 20, 20, 24, 20, 20, 24, 12'h68F);
        for (y = 20; y <= 24; y = y + 1)
            for (x = 20; x <= 24 - (y - 20); x = x + 1)
                expect_pixel(x, y);
        if (pixel_count != 15) begin
            $error("Triangle generated %0d pixels, expected 15", pixel_count);
            failures = failures + 1;
        end

        if (failures == 0)
            $display("PASS: line, rectangle, and filled-triangle rasterization");
        else
            $fatal(1, "FAIL: %0d checks failed", failures);
        $finish;
    end

endmodule
