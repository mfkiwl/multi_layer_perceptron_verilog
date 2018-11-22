module loss_gen(
    input clk,
    input [8-1:0] t,
    input [12-1:0] y,
    output [16-1:0] ph_out
    );

    wire [8-1:0]difference;
    wire [16-1:0]dif_y;
    wire [8-1:0]act_y;



  //  assign difference = t - act_y;

    // multiplier_16_8_16 pho_difh_mul  (.A(dif_y), .B(difference), .OUT(ph_out));
    // dif_lut diflut_act_out(.in(y), .y(dif_y));
    // lut lut_y (.in(y), .y(act_y));

    reg [8-1:0]p_difference;
    reg [16-1:0]p_dif_y;

    always @(posedge clk) begin
      p_difference <= difference;
      p_dif_y <= dif_y;
    end


    wire [12-1:0] pseudo;
    assign pseudo = { {4{act_y[7]}}, act_y };
    multiplier_16_8_16 pho_difh_mul  (.A(p_dif_y), .B(p_difference), .OUT(ph_out));
    dif_lut diflut_act_out(.in(pseudo), .y(dif_y));
    lut lut_y (.in(y), .y(act_y));

    subtracter8_8_8 sub(.A(t), .B(act_y), .OUT(difference));

endmodule
