`ifndef DEFMACRO
    `include "../common/def.v"
    `define DEFMACRO
`endif
// backprop向け パラメータ
`define MUL_WIDTH       16  // 乗算器のビット幅
`define ADD_WIDTH       `MUL_WIDTH+4  // 積和演算後のビット幅

module BP(
    input clk,
    input rst_n,
    input run,

    // SRAM
  //  input [7:0] read_data_0, read_data_1, // のちのち不要
    input [7:0] sram0_data_input,
    input [7:0] sram1_data_input,

    output [16:0] sram0_addr,
    output [7:0]  sram0_data_output,
    output [16:0] sram1_addr,
    output [7:0]  sram1_data_output,

    // Additional
    output sram0_output_en, sram0_cs_n, sram0_oe_n, sram0_we_n,
    output sram1_output_en, sram1_cs_n, sram1_oe_n, sram1_we_n,

    // buffer
    input [8-1:0] in_buf_out, t_buf_out,
    input [12-1:0] hid_buf_out, out_buf_out,
    output [10-1:0] t_buf_addr, out_buf_addr, in_buf_addr, hid_buf_addr,

    // 終了フラグ
    output finish

    );


    reg sram0_output_en_reg, sram0_cs_n_reg, sram0_oe_n_reg, sram0_we_n_reg;
    reg sram1_output_en_reg, sram1_cs_n_reg, sram1_oe_n_reg, sram1_we_n_reg;
    assign sram0_output_en = sram0_output_en_reg;
    assign sram0_cs_n = sram0_cs_n_reg;
    assign sram0_oe_n = sram0_oe_n_reg;
    assign sram0_we_n = sram0_we_n_reg;
    assign sram1_output_en = sram1_output_en_reg;
    assign sram1_cs_n = sram1_cs_n_reg;
    assign sram1_oe_n = sram1_oe_n_reg;
    assign sram1_we_n = sram1_we_n_reg;


    reg [15:0]ph_hid[0:`N_H-1]; // (各層のユニット数-1)
    reg [15:0]ph_out[0:`N_OUT-1]; // (各層のユニット数-1)

    reg finish_reg;
    reg [8-1:0] state;
    integer i;

    wire [8-1:0] act_hid_unit;
// for SRAM
    reg [17-1:0] r_w_addr_reg;
    reg [8-1:0] out_dat_reg;


// for SRAM Assign
    wire acc_rst_n;
    reg acc_rst_n_reg;
    assign sram0_addr = r_w_addr_reg[17-1:0];
    assign sram1_addr = r_w_addr_reg[17-1:0];
    assign sram0_data_output[8-1:0] = out_dat_reg[8-1:0];
    assign sram1_data_output[8-1:0] = out_dat_reg[8-1:0];

    assign acc_rst_n = acc_rst_n_reg;
    assign finish = finish_reg;

    reg [8-1:0] t_in;
    reg [12-1:0] y_in;
    wire [16-1:0] ph_output;

    reg [3:0] eta;
    reg [16-1:0] ph_outer;
    reg [16-1:0] w_init;
    reg [12-1:0] hid_unit;
    wire [16-1:0] ph_inner;
    wire [16-1:0] w_updated;

    reg acc_en_reg;

    reg [10-1:0] cnt_0;
    reg [10-1:0] cnt_1;

    assign out_buf_addr = cnt_0;
    assign hid_buf_addr = cnt_1;
    assign in_buf_addr = cnt_1;
    assign t_buf_addr = cnt_0;

    /*  外部の共通バッファを使うため不要
    reg [12-1:0] y[0:4-1]; // 活性前
    reg [8-1:0] t[0:4-1];
    reg [12-1:0] h[0:8-1]; // 活性前
    reg [8-1:0] input_d[0:16-1]; // 入力
    */

     always @(posedge clk) begin
      if (rst_n == 0) begin
          // RESET
          state <= 0;
          finish_reg <= 0;
          for (i=0; i<`N_H; i=i+1) begin
            ph_hid[i] <= 0;
          end
          for (i=0; i<`N_OUT; i=i+1) begin
            ph_out[i] <= 0;
          end
          cnt_0 <= 0;
          cnt_1 <= 0;
          r_w_addr_reg <= 0;
          out_dat_reg <= 0;
          sram0_output_en_reg <= 0;
          sram0_cs_n_reg <= 1;
          sram0_oe_n_reg <= 0;
          sram0_we_n_reg <= 1;
          sram1_output_en_reg <= 0;
          sram1_cs_n_reg <= 1;
          sram1_oe_n_reg <= 0;
          sram1_we_n_reg <= 1;

      end else if(run) begin
      // state 0-9 出力層のph算出
      // state 10-29 出力層から中間層にかけての逆伝播および
      //              中間層から出力層にかけての重みの更新
      // state 30-49  入力層から中間層にかけての重みの更新
      // state 50   終了ステート
        if (state == 0) begin
          // WAIT
          cnt_0 <= 0;
          cnt_1 <= 0;
          finish_reg <= 0;
          sram0_output_en_reg <= 0;
          sram0_cs_n_reg <= 1;
          sram0_oe_n_reg <= 0;
          sram0_we_n_reg <= 1;
          sram1_output_en_reg <= 0;
          sram1_cs_n_reg <= 1;
          sram1_oe_n_reg <= 0;
          sram1_we_n_reg <= 1;

          if (!finish == 1) begin
            state <= 1;
            cnt_0 <= 0;
            for (i=0; i<`N_H; i=i+1) begin
              ph_hid[i] <= 0;
            end
            for (i=0; i<`N_OUT; i=i+1) begin
              ph_out[i] <= 0;
            end
            r_w_addr_reg <= 0;
            out_dat_reg <= 0;
          end
          eta <= 1;
          acc_en_reg <= 0;

        end else if (state == 1) begin
          // ph_out computing
          cnt_0 <= cnt_0 + 1;
          state <= 2;
          if (cnt_0 <= `N_OUT) begin
            t_in <= t_buf_out;
            y_in <= out_buf_out;
          end else begin
            state <= 10;
            cnt_0 <= 0;
            cnt_1 <= 0;
          end
          acc_rst_n_reg <= 0;

        end else if (state == 2) begin
            state <= 3;

        end else if (state == 3) begin
            if ((cnt_0 <= `N_OUT + 1) && (cnt_0 >= 1)) begin
              ph_out[cnt_0 - 1] <= ph_output;
            end
            state <= 1;
        end else if (state == 10) begin
          //読み出し要求0
          r_w_addr_reg <= (cnt_1 * `N_OUT) + cnt_0 + `ADDR_WO_START;
          sram0_output_en_reg <= 0;
          sram0_cs_n_reg <= 0;

          state <= state + 1;
        end else if (state == 11) begin
          state <= state + 1;




        end else if (state == 12) begin
          //DataFetch0
          w_init[15:8] <= sram0_data_input;
          sram1_output_en_reg <= 0;
          sram1_cs_n_reg <= 0;
          sram0_cs_n_reg <= 1;
          //読み出し要求1
          state <= state + 1;
        end else if (state == 13) begin
        // Wait
          state <= state + 1;

      //    read_data_1 <= internal_sram1_data_input;
        end else if (state == 14) begin
          // DataFetch
          state <= state + 1;

          w_init[7:0] <= sram1_data_input;

          ph_outer <= ph_out[cnt_0];
          //hid_unit <= h[cnt_1];
          hid_unit <= hid_buf_out;
        end else if (state == 15) begin
          // Compute
          acc_rst_n_reg <= 1;
          acc_en_reg <= 1;
          //state <= state + 1;
          state <= 22;
        end else if (state == 22) begin
          state <= 16;
          acc_en_reg <= 0;
        end else if (state == 16) begin
          state <= state + 1;
          out_dat_reg <= w_updated[15:8];

        end else if (state == 17) begin
          // Write0
          state <= state + 1;
          sram0_output_en_reg <= 1;
          sram0_cs_n_reg <= 0;
          sram0_we_n_reg <= 0;
          sram1_output_en_reg <= 0;
          sram1_cs_n_reg <= 1;
          sram1_we_n_reg <= 1;
        end else if (state == 18) begin
          state <= state + 1;
          sram0_cs_n_reg <= 1;
          sram0_we_n_reg <= 1;
        // SRAM1
          out_dat_reg <= w_updated[7:0];

        end else if (state == 19) begin
          // Write1
          state <= state + 1;
          sram1_output_en_reg <= 1;
          sram1_cs_n_reg <= 0;
          sram1_we_n_reg <= 0;
          sram0_output_en_reg <= 0;


        end else if (state == 20) begin
          // 分岐
            sram0_we_n_reg <= 1;
            sram1_cs_n_reg <= 1;
            sram1_we_n_reg <= 1;
            if ((cnt_1 == `N_H - 1) && (cnt_0 == `N_OUT - 1)) begin
              state <= state + 1;
              acc_rst_n_reg <= 0;
              ph_hid[cnt_1] <= ph_inner;
            end else begin
                if (cnt_0 >= `N_OUT - 1) begin
                  cnt_0 <= 10'b0;
                  acc_rst_n_reg <= 0;
                  ph_hid[cnt_1] <= ph_inner;
                  cnt_1 <= cnt_1 + 1;
                end else begin
                  cnt_0 <= cnt_0 + 1;
                end
                state <= 6'd10;
            end
        end else if (state == 21) begin
          // END
          state <= 30;//41;
          cnt_0 <= 10'h0;
          cnt_1 <= 10'h0;

        end else if (state == 30) begin
        //読み出し要求0
          r_w_addr_reg <= (cnt_1 * `N_H) + cnt_0; // 注意！　逆転中
          state <= state + 1;
        end else if (state == 31) begin
          state <= state + 1;
          sram0_output_en_reg <= 0;
          sram0_cs_n_reg <= 0;
        //  read_data_0 <= internal_sram0_data_input;

        end else if (state == 32) begin
          //DataFetch0
          w_init[15:8] <= sram0_data_input;
          //読み出し要求1

          state <= state + 1;
        end else if (state == 33) begin
          state <= state + 1;
          sram1_output_en_reg <= 0;
          sram1_cs_n_reg <= 0;
          // input_buffer_adr <= cnt_1;
      //    read_data_1 <= internal_sram1_data_input;
          hid_unit <= {{4{in_buf_out[7]}}, in_buf_out};
        end else if (state == 34) begin
          // Wait
          state <= state + 1;
          w_init[7:0] <= sram1_data_input;
          ph_outer <= ph_hid[cnt_0];
          //hid_unit <= input_d[cnt_1];       //


        end else if (state == 35) begin
          // Compute
          acc_rst_n_reg <= 1;
          acc_en_reg <= 1;
        //  state <= state + 1;
          state <= 42;

        end else if (state == 42) begin
          state <= 36;
          acc_en_reg <= 0;
        end else if (state == 36) begin
        // SRAM0へ
          out_dat_reg <= w_updated[15:8];
          state <= state + 1;
          //acc_en_reg <= 0;
        end else if (state == 37) begin
          // Write0
          state <= state + 1;
          sram0_output_en_reg <= 1;
          sram0_cs_n_reg <= 0;
          sram0_we_n_reg <= 0;
          sram1_output_en_reg <= 0;
          sram1_cs_n_reg <= 1;
          sram1_we_n_reg <= 1;

        end else if (state == 38) begin
          state <= state + 1;
          // SRAM1へ
         out_dat_reg <= w_updated[7:0];
         sram0_cs_n_reg <= 1;
         sram0_we_n_reg <= 1;

        end else if (state == 39) begin
          // Write1
          state <= state + 1;
          sram1_output_en_reg <= 1;
          sram1_cs_n_reg <= 0;
          sram1_we_n_reg <= 0;
          sram0_output_en_reg <= 0;
          sram0_cs_n_reg <= 1;
          sram0_we_n_reg <= 1;
        end else if (state == 40) begin
          sram1_cs_n_reg <= 1;
          sram1_we_n_reg <= 1;
          // 分岐
            if ((cnt_1 == `N_IN - 1) && (cnt_0 == `N_H - 1)) begin
              state <= state + 1;
              acc_rst_n_reg <= 0;
            end else begin
                if (cnt_0 >= `N_H - 1) begin
                  cnt_0 <= 10'h0;
                  acc_rst_n_reg <= 0;
                  cnt_1 <= cnt_1 + 1;
                end else begin
                  cnt_0 <= cnt_0 + 1;
                end
                state <= 6'd30;
            end
        end else if (state == 41) begin
          // END
          state <= 6'd50;
          finish_reg <= 1;
        end else if (state == 50) begin
      //    state <= 6'd0;
          sram0_we_n_reg <= 1;
          sram0_output_en_reg <= 0;
          sram1_we_n_reg <= 1;
          sram1_output_en_reg <= 0;
        end
      end
    end


    //LUT
    lut lut_h(.in(hid_unit), .y(act_hid_unit));

    bp_pe #(.num_shift(`N_SHIFT)) bp_pe (  .clk(clk),  .acc_en(acc_en_reg), .acc_rst_n(acc_rst_n), .rst_n(rst_n),//  .eta(eta),
                  .ph_outer(ph_outer),
                  .w_init(w_init),  .hid_unit( (state <= 29)? act_hid_unit : hid_unit[7:0]),
                  //.hid_unit(act_hid_unit),
                  .ph_inner(ph_inner),  .w_updated(w_updated));

    loss_gen loss_gen(.clk(clk), .t(t_in), .y(y_in), .ph_out(ph_output));






endmodule
