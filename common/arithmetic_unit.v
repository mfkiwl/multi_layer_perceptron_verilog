// 乗算器
// 各フォーマット
/*
8bit →  8'b0_00_00000 符号_整数_小数  // 1_2_5
16bit   16'b0_00_0000000000000    //  1_2_13
20bit   20'b0_000000_0000000000000  // 1_6_13
*/

module subtracter8_8_8(
    input     [8-1:0] A,
    input     [8-1:0] B,
    output    [8-1:0] OUT
  );
  wire [8+1-1:0] extA;
  wire [8+1-1:0] extB;
  wire [8+1-1:0] SUB;
  wire [2-1:0] carry;

  assign extA = {A[7],A};
  assign extB = {B[7],B};
  assign SUB = extA - extB;
  assign carry = SUB[8:7];


//  assign OUT = {SUB[8],SUB[6:0]};
  assign OUT = (carry == 2'b01) ? {1'b0,{7{1'b1}}} : (carry == 2'b10) ? {1'b1,{7{1'b0}}} : {SUB[8],SUB[6:0]};
endmodule

module adder16_16_16(
    input     [16-1:0] A,
    input     [16-1:0] B,
    output    [16-1:0] OUT
  );
  wire [16+1-1:0] extA;
  wire [16+1-1:0] extB;
  wire [16+1-1:0] ADD;
  wire [2-1:0] carry;

  assign extA = {A[15],A};
  assign extB = {B[15],B};
  assign ADD = extA + extB;
  assign carry = ADD[16:15];

//  assign OUT = {ADD[16],ADD[14:0]};

  assign OUT = (carry == 2'b01) ? {1'b0,{15{1'b1}}} : (carry == 2'b10) ? {1'b1,{15{1'b0}}} : {ADD[15],ADD[14:0]};

endmodule

module accumulator_16_20(
    input      clk,
    input      reset,
    input      acc_reset,
    input      acc_en,
    input      [15:0] X,
    output reg [19:0] OUT
);
    wire [20:0] extX;
    wire [20:0] extOUT;
    wire [20:0] ADD;
    wire [1:0]  carry;

    assign extX   = {{5{X[15]}}, X};
    assign extOUT = {OUT[19], OUT};
    assign ADD    = extX + extOUT;
    assign carry  = ADD[20:19];

    always @(posedge clk)
    begin
        if(!reset)
        begin
            OUT <= 0;
        end
        else if(!acc_reset)
        begin
            OUT <= 0;
        end
        else if(acc_en)
        begin
            if(carry == 2'b01)
            begin
                OUT <= {1'b0, {19{1'b1}}};
            end
            else if(carry == 2'b10)
            begin
                OUT <= {1'b1, {19{1'b0}}};
            end
            else
            begin
                OUT <= ADD[19:0];
            end

        end
    end
endmodule


module adder_8_12_12(
    input  [7:0] A,
    input  [11:0] B,
    output [11:0] OUT
);
    wire [12:0] extA;
    wire [12:0] extB;
    wire [12:0] ADD;
    wire [1:0]  carry;

    assign extA  = {{5{A[7]}}, A};
    assign extB  = {B[11], B};
    assign ADD   = extA + extB;
    assign carry = ADD[12:11];
    assign OUT = (carry == 2'b01)? {1'b0, {11{1'b1}}} :
                 (carry == 2'b10)? {1'b1, {11{1'b0}}} :
                 ADD[11:0];

endmodule

module multiplier_8_8_8(
    input [7:0] A,
    input [7:0] B,
    output [7:0] OUT
);

    wire [15:0] extA;
    wire [15:0] extB;
    wire [15:0] MUL;

    wire carry_n;

    assign extA = {{8{A[7]}}, A};
    assign extB = {{8{B[7]}}, B};
    assign MUL  = extA * extB;

    assign carry_n = (MUL[15] == MUL[14] && MUL[14] == MUL[13] && MUL[13] == MUL[12]);

    assign OUT  = (MUL[15] == 1 && carry_n == 0) ? {1'b1, {7{1'b0}}} : (MUL[15] == 1 && carry_n == 0) ? {1'b0, {7{1'b1}}}:{MUL[15], MUL[11:10], MUL[9:5]};
endmodule


module multiplier_16_16_16(
	input [16-1:0] A, B,
	output [16-1:0] OUT
	);

  wire [32-1:0] extA;
  wire [32-1:0] extB;
  wire [32-1:0] MUL;

  wire carry_n;

  assign extA = {{16{A[15]}}, A};
  assign extB = {{16{B[15]}}, B};
  assign MUL  = extA * extB;

  assign carry_n = (MUL[31] == MUL[30] && MUL[30] == MUL[29] && MUL[29] == MUL[28]);

  assign OUT  = (MUL[31] == 1 && carry_n == 0) ? {1'b1, {15{1'b0}}} : (MUL[31] == 1 && carry_n == 0) ? {1'b0, {15{1'b1}}}:{MUL[16 * 2 - 1], MUL[27:13]};

endmodule

module multiplier_16_8_16(
	input [16-1:0] A,
  input [8-1:0]B,
	output [16-1:0] OUT
	);
  wire [16-1:0] extA;
  wire [16-1:0] extB;

  assign extA = A;
  assign extB = {B,{8{B[7]}}};

  multiplier_16_16_16 mul(.A(extA), .B(extB), .OUT(OUT));
endmodule

module multiplier_20_16_16(
	input [20-1:0] A,
  input [16-1:0]B,
	output [16-1:0] OUT
	);

  wire [36-1:0] extA;
  wire [36-1:0] extB;
  wire [36-1:0] MUL;
  wire carry_n;
  assign extA = {{16{A[19]}}, A};
  assign extB = {{20{B[15]}}, B};
  assign MUL  = extA * extB;

  assign carry_n = (MUL[35] == MUL[34] && MUL[34] == MUL[33] && MUL[33] == MUL[32] && MUL[32] == MUL[31] && MUL[31] == MUL[30] && MUL[30] == MUL[29] && MUL[29] == MUL[28]);
  assign OUT  = (MUL[35] == 1 && carry_n == 0) ? {1'b1, {15{1'b0}}} : (MUL[35] == 1 && carry_n == 0) ? {1'b0, {15{1'b1}}}:{MUL[36 - 1], MUL[27:13]};

endmodule
