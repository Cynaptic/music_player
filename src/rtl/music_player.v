`timescale 1ns / 1ps
//==============================================================================
// Music Player - outputs note code to CD4051 for 555 timer tone generation
//==============================================================================

module music_player #(
    parameter CLK_FREQ  = 50_000_000,
    parameter BEAT_FREQ = 4
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       play,
    output wire [2:0] note_out,   // Decoder address (selects resistor)
    output wire [3:0] beat_out,   // current beat count
    output wire       rest_out,   // rest flag
    output wire       end_flag,   // end of song
    output wire [5:0] addr_out    // ROM address
);

    // ROM interface
    reg  [5:0] addr;
    wire [7:0] rom_data;
    music_rom rom(.addr(addr), .data(rom_data));

    // Decode ROM: {rest, beat[3:0], note[2:0]}
    assign note_out = rom_data[2:0];
    assign beat_out = rom_data[6:3];
    assign rest_out = rom_data[7];
    assign end_flag = (rom_data == 8'hFF);
    assign addr_out = addr;

    // Timing
    localparam BEAT_CYCLES = CLK_FREQ / BEAT_FREQ;
    reg [31:0] clk_cnt;
    reg [3:0]  beat_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr <= 0;
            clk_cnt <= 0;
            beat_cnt <= 1;
        end else if (play && !end_flag) begin
            if (clk_cnt >= BEAT_CYCLES - 1) begin
                clk_cnt <= 0;
                if (beat_cnt >= rom_data[6:3]) begin
                    beat_cnt <= 1;
                    addr <= addr + 1;
                end else begin
                    beat_cnt <= beat_cnt + 1;
                end
            end else begin
                clk_cnt <= clk_cnt + 1;
            end
        end
    end

endmodule


//==============================================================================
// Music ROM - Twinkle Twinkle Little Star
// {rest[7], beat[6:3], note[2:0]}
// note: 0=Do 1=Re 2=Mi 3=Fa 4=Sol 5=La 6=Si 7=Do'
//==============================================================================
module music_rom (
    input  wire [5:0] addr,
    output reg  [7:0] data
);
    always @(*) begin
        case (addr)
            // A: 1 1 5 5 | 6 6 5- | 4 4 3 3 | 2 2 1-
            6'h00: data = 8'h10;  // Do  2
            6'h01: data = 8'h10;  // Do  2
            6'h02: data = 8'h14;  // Sol 2
            6'h03: data = 8'h14;  // Sol 2
            6'h04: data = 8'h15;  // La  2
            6'h05: data = 8'h15;  // La  2
            6'h06: data = 8'h24;  // Sol 4
            6'h07: data = 8'h13;  // Fa  2
            6'h08: data = 8'h13;  // Fa  2
            6'h09: data = 8'h12;  // Mi  2
            6'h0A: data = 8'h12;  // Mi  2
            6'h0B: data = 8'h11;  // Re  2
            6'h0C: data = 8'h11;  // Re  2
            6'h0D: data = 8'h20;  // Do  4
            // B: 5 5 4 4 | 3 3 2- | 5 5 4 4 | 3 3 2-
            6'h0E: data = 8'h14;  // Sol 2
            6'h0F: data = 8'h14;  // Sol 2
            6'h10: data = 8'h13;  // Fa  2
            6'h11: data = 8'h13;  // Fa  2
            6'h12: data = 8'h12;  // Mi  2
            6'h13: data = 8'h12;  // Mi  2
            6'h14: data = 8'h21;  // Re  4
            6'h15: data = 8'h14;  // Sol 2
            6'h16: data = 8'h14;  // Sol 2
            6'h17: data = 8'h13;  // Fa  2
            6'h18: data = 8'h13;  // Fa  2
            6'h19: data = 8'h12;  // Mi  2
            6'h1A: data = 8'h12;  // Mi  2
            6'h1B: data = 8'h21;  // Re  4
            // A: 1 1 5 5 | 6 6 5- | 4 4 3 3 | 2 2 1-
            6'h1C: data = 8'h10;  // Do  2
            6'h1D: data = 8'h10;  // Do  2
            6'h1E: data = 8'h14;  // Sol 2
            6'h1F: data = 8'h14;  // Sol 2
            6'h20: data = 8'h15;  // La  2
            6'h21: data = 8'h15;  // La  2
            6'h22: data = 8'h24;  // Sol 4
            6'h23: data = 8'h13;  // Fa  2
            6'h24: data = 8'h13;  // Fa  2
            6'h25: data = 8'h12;  // Mi  2
            6'h26: data = 8'h12;  // Mi  2
            6'h27: data = 8'h11;  // Re  2
            6'h28: data = 8'h11;  // Re  2
            6'h29: data = 8'h20;  // Do  4
            6'h2A: data = 8'hFF;  // End
            default: data = 8'hFF;
        endcase
    end
endmodule
