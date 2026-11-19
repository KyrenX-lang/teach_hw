/*
 * Copyright (c) 2024 Uri Shaked
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_vga_example (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    // VGA signals
    wire hsync;
    wire vsync;
    wire [1:0] R;
    wire [1:0] G;
    wire [1:0] B;
    wire video_active;
    wire [9:0] pix_x;
    wire [9:0] pix_y;

    // TinyVGA PMOD output mapping
    assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

    // Unused bidirectional pins
    assign uio_out = 0;
    assign uio_oe  = 0;

    // Suppress unused-signal warnings
    wire _unused_ok = &{ena, ui_in, uio_in};
    
    // reg [9:0] counter;

  
    hvsync_generator vga_sync_gen (
        .clk        (clk),
        .reset      (~rst_n),
        .hsync      (hsync),
        .vsync      (vsync),
        .display_on (video_active),
        .hpos       (pix_x),
        .vpos       (pix_y)
    );

    
    reg flag_red;
    reg cross_vertical;
    reg cross_horizontal;
    reg cross_white;
    reg [5:0] pixel_color;

    
    assign flag_red = (pix_x >= 1) && (pix_x < 1000) &&
        (pix_y >= 50)  && (pix_y < 437);
        

    
    assign cross_vertical = (pix_x >= 280) && (pix_x < 360) &&
        (pix_y >= 120) && (pix_y < 360);
       

    
    assign cross_horizontal =(pix_x >= 200) && (pix_x < 440) &&
        (pix_y >= 200) && (pix_y < 280);

        
   
    assign cross_white = cross_vertical || cross_horizontal;

    
    assign pixel_color =cross_white ? 6'b111111 : flag_red ? 6'b110000:6'b000000;    
                     

          
       
    
    assign R = video_active ? pixel_color[5:4] : 2'b00;
    assign G = video_active ? pixel_color[3:2] : 2'b00;
    assign B = video_active ? pixel_color[1:0] : 2'b00;

endmodule

`default_nettype wire
