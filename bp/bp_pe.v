module bp_pe(
    input clk,
    input rst_n,
    input acc_rst_n,
    input acc_en,
  //  input [3:0] eta,  // learning_rate (Right-shift times, if eta == 10 then 2^-10)
    input [16-1:0] ph_outer,     // 出力側のph
    input [16-1:0] w_init,
    input [8-1:0] hid_unit,
    output [16-1:0] ph_inner,  // 出力
    output [16-1:0] w_updated
    );

    wire [16-1:0] mul_out;
    wire [16-1:0] mul_out2;
    wire [16-1:0] dif_hid_unit;

    wire [16-1:0] w_updated_wire;

    wire [16+4-1:0] acc_out;

    wire [16-1:0] w_dif;

    wire [11:0] pseudo_acth;
    reg [16+4-1:0] p_acc_out;
    reg [16-1:0] p_dif_hid_unit;
    reg [16-1:0] p_w_init;
    reg [16-1:0] p_w_dif;

    parameter num_shift = 2;

  //  assign w_dif = mul_out2;// >> eta;
    assign w_dif = { mul_out2[15]  ,{num_shift{mul_out2[15]}}, {mul_out2[14:num_shift]}};
  //  assign w_dif = { mul_out2[15]  ,{mul_out2[14:num_shift]}, {num_shift{!mul_out2[15]}} };

    //assign w_updated_wire = p_w_init + p_w_dif;
    adder16_16_16 add (.A(w_init), .B(p_w_dif), .OUT(w_updated_wire));
    assign w_updated = w_updated_wire;


    assign pseudo_acth = {{4{hid_unit[7]}}, hid_unit};
    // difLUT
    dif_lut diflut_act_hidden(.in(pseudo_acth), .y(dif_hid_unit));


    always @(posedge clk) begin
      p_acc_out <= acc_out;
      p_dif_hid_unit <= dif_hid_unit;
      p_w_init <= w_init;
      p_w_dif <= w_dif;
    //  w_updated <= w_updated_wire;

    end



    accumulator_16_20 accumulator (.clk(clk), .reset(rst_n), .acc_reset(acc_rst_n),
                                   .acc_en(acc_en), .X(mul_out), .OUT(acc_out));

    // ph_backprop_multiplier
    multiplier_16_16_16 pho_w_mul     (.A(ph_outer), .B(w_init), .OUT(mul_out));
    multiplier_16_8_16 pho_difh_mul   (.A(ph_outer), .B(hid_unit), .OUT(mul_out2));
    //multiplier_20_16_16 phmid_difh_mul  (.A(acc_out), .B(dif_hid_unit), .OUT(ph_inner));
    multiplier_20_16_16 phmid_difh_mul  (.A(p_acc_out), .B(p_dif_hid_unit), .OUT(ph_inner));


endmodule
