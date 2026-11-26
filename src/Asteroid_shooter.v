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

wire hsync;
wire vsync;
wire [1:0] R;
wire [1:0] G;
wire [1:0] B;
wire video_active;
wire [9:0] pix_x;
wire [9:0] pix_y;

assign uo_out =
    {hsync, B[0], G[0], R[0],
     vsync, B[1], G[1], R[1]};

assign uio_out = 0;
assign uio_oe  = 0;

wire _unused_ok = &{ena, ui_in[7:4], uio_in};

hvsync_generator vga_sync_gen (
    .clk(clk),
    .reset(~rst_n),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(video_active),
    .hpos(pix_x),
    .vpos(pix_y)
);

localparam SHIP_WIDTH  = 40;
localparam SHIP_HEIGHT = 16;
localparam SHIP_Y      = 440;
localparam SHIP_SPEED  = 4;

localparam BULLET_WIDTH  = 4;
localparam BULLET_HEIGHT = 10;
localparam BULLET_SPEED  = 20;

localparam ASTEROID_SIZE = 24;

parameter NEW_GAME = 2'b00;
parameter PLAY      = 2'b01;
parameter GAME_OVER = 2'b10;

reg [1:0] state;

reg [9:0] ship_x;

reg [9:0] bullet_x;
reg [9:0] bullet_y;
reg bullet_active;

reg [9:0] asteroid_x;
reg [9:0] asteroid_y;

reg [7:0] score;

wire bullet_hit;

assign bullet_hit =
    bullet_active &&
    (bullet_x < asteroid_x + ASTEROID_SIZE) &&
    (bullet_x + BULLET_WIDTH > asteroid_x) &&
    (bullet_y < asteroid_y + ASTEROID_SIZE) &&
    (bullet_y + BULLET_HEIGHT > asteroid_y);

wire ship_hit;

assign ship_hit =
    (asteroid_x < ship_x + SHIP_WIDTH) &&
    (asteroid_x + ASTEROID_SIZE > ship_x) &&
    (asteroid_y < SHIP_Y + SHIP_HEIGHT) &&
    (asteroid_y + ASTEROID_SIZE > SHIP_Y);

always @(posedge vsync or negedge rst_n) begin

    if (!rst_n) begin
        state         <= NEW_GAME;
        ship_x        <= 300;
        bullet_x      <= 0;
        bullet_y      <= 0;
        bullet_active <= 0;
        asteroid_x    <= 300;
        asteroid_y    <= 40;
        score         <= 0;
    end

    else if (ui_in[0]) begin
        state         <= NEW_GAME;
        ship_x        <= 300;
        bullet_x      <= 0;
        bullet_y      <= 0;
        bullet_active <= 0;
        asteroid_x    <= 300;
        asteroid_y    <= 40;
        score         <= 0;
    end

    else begin
        case (state)

            NEW_GAME: begin
                state <= PLAY;
            end

            PLAY: begin

                if (ui_in[1]) begin
                    if (ship_x >= SHIP_SPEED)
                        ship_x <= ship_x - SHIP_SPEED;
                    else
                        ship_x <= 0;
                end

                else if (ui_in[2]) begin
                    if (
                        ship_x + SHIP_WIDTH + SHIP_SPEED
                        <= 640
                    )
                        ship_x <= ship_x + SHIP_SPEED;
                    else
                        ship_x <= 640 - SHIP_WIDTH;
                end

                if (!bullet_active && ui_in[3]) begin
                    bullet_active <= 1;
                    bullet_x <=
                        ship_x + SHIP_WIDTH/2
                        - BULLET_WIDTH/2;
                    bullet_y <=
                        SHIP_Y - BULLET_HEIGHT;
                end

                else if (bullet_active) begin
                    if (bullet_y < BULLET_SPEED)
                        bullet_active <= 0;
                    else
                        bullet_y <= bullet_y
                                    - BULLET_SPEED;
                end

                if (bullet_hit) begin
                    bullet_active <= 0;
                    asteroid_y <= 40;
                    score <= score + 1;

                    if (asteroid_x < 480)
                        asteroid_x <= asteroid_x + 113;
                    else
                        asteroid_x <= asteroid_x - 377;
                end

                else if (
                    ship_hit ||
                    asteroid_y + ASTEROID_SIZE >= 480
                ) begin
                    state <= GAME_OVER;
                end

                else begin
                    if (score >= 10)
                        asteroid_y <= asteroid_y + 2;
                    else
                        asteroid_y <= asteroid_y + 1;
                end
            end

            GAME_OVER: begin
                state <= GAME_OVER;
            end

            default: begin
                state <= NEW_GAME;
            end

        endcase
    end
end

reg ship;
reg bullet;
reg asteroid;
reg scorebar;

wire [10:0] score_width;

assign score_width = {score, 3'b000};

always @(*) begin

    ship =
        (pix_x >= ship_x) &&
        (pix_x < ship_x + SHIP_WIDTH) &&
        (pix_y >= SHIP_Y) &&
        (pix_y < SHIP_Y + SHIP_HEIGHT);

    bullet =
        bullet_active &&
        (pix_x >= bullet_x) &&
        (pix_x < bullet_x + BULLET_WIDTH) &&
        (pix_y >= bullet_y) &&
        (pix_y < bullet_y + BULLET_HEIGHT);

    asteroid =
        (pix_x >= asteroid_x) &&
        (pix_x < asteroid_x + ASTEROID_SIZE) &&
        (pix_y >= asteroid_y) &&
        (pix_y < asteroid_y + ASTEROID_SIZE);

    scorebar =
        (pix_x >= 10) &&
        (pix_x < 11'd10 + score_width) &&
        (pix_y >= 10) &&
        (pix_y < 20);
end

reg [5:0] color;

always @(*) begin

    if (state == GAME_OVER)
        color = 6'b110000;

    else if (bullet)
        color = 6'b111100;

    else if (asteroid)
        color = 6'b111000;

    else if (ship)
        color = 6'b001100;

    else if (scorebar)
        color = 6'b001111;

    else
        color = 6'b000000;
end

assign R = video_active ? color[5:4] : 0;
assign G = video_active ? color[3:2] : 0;
assign B = video_active ? color[1:0] : 0;

endmodule

`default_nettype wire