`ifndef DEFMACRO
    `include "def.v"
    `define DEFMACRO
`endif
// 2-port memory

// 2-port memory
module buffer#(
    parameter ADDR_WIDTH = 8, // アドレス幅
    parameter WORD_NUM = 196, // ワード範囲
    parameter WORD_WIDTH = 8  // ワード幅(bit)
    )(
    input clk,
    input reset,
    input we,
    input [ADDR_WIDTH-1:0] ra, // 読み出しアドレス
    input [ADDR_WIDTH-1:0] wa, // 書き込みアドレス
    input [WORD_WIDTH-1:0] d,  // 書き込みデータ
    output [WORD_WIDTH-1:0] q  // 読み出しデータ
    );

    integer i;
    // reg [WORD_WIDTH-1:0] ram[0:WORD_NUM-1] /* synthesis noprune */; // Quartus最適化抑制
    reg [WORD_WIDTH-1:0] ram[0:WORD_NUM-1];

    reg we_reg;
    reg [ADDR_WIDTH-1:0] wa_reg;
    reg [WORD_WIDTH-1:0] d_reg;

    assign q = ram[ra];

    always @(posedge clk)
    begin
        we_reg <= we;
        wa_reg <= wa;
        d_reg  <= d;
    end
    // RAM
    always @(posedge clk)
        if(reset)
            for(i = 0; i < WORD_NUM; i = i + 1)
                ram[i] <= 8'b00000000;
        else if(we_reg)
            ram[wa_reg] <= d_reg;
endmodule
