`ifndef DEFMACRO
    `include "../common/def.v"
    `define DEFMACRO
`endif
`timescale 1ns/1ps
module tbench;
    reg clk;
    reg reset;
    reg [`R_DATA] sram0 [0:4095];
    reg [`R_DATA] sram1 [0:4095];

    wire run_ld;
    wire run_ff;
    wire run_bp;

    wire fin_ld;
    wire fin_ff;
    wire fin_bp;

    reg [31:0] gpio_in;
    wire [31:0] gpio_out;

    wire [16:0]sram_addr_ld;
    wire sram_data_output_en_ld;
    wire sram_cs_n_ld;
    wire sram_oe_n_ld;
    wire sram_we_n_ld;

    wire [16:0]sram_addr_ff;
    wire [7:0] sram_data_output_ff;
    wire sram_data_output_en_ff;
    wire sram_cs_n_ff;
    wire sram_oe_n_ff;
    wire sram_we_n_ff;

    wire [16:0]sram0_addr_bp;
    wire [7:0] sram0_data_output_bp;
    wire sram0_data_output_en_bp;
    wire sram0_cs_n_bp;
    wire sram0_oe_n_bp;
    wire sram0_we_n_bp;

    wire [16:0]sram1_addr_bp;
    wire [7:0] sram1_data_output_bp;
    wire sram1_data_output_en_bp;
    wire sram1_cs_n_bp;
    wire sram1_oe_n_bp;
    wire sram1_we_n_bp;


    wire [16:0]internal_sram0_addr;
    wire [7:0]internal_sram0_data_input;
    wire [7:0]internal_sram0_data_output;
    wire internal_sram0_data_output_en;
    wire internal_sram0_cs_n;
    wire internal_sram0_oe_n;
    wire internal_sram0_we_n;

    wire [16:0]internal_sram1_addr;
    wire [7:0]internal_sram1_data_input;
    wire [7:0]internal_sram1_data_output;
    wire internal_sram1_data_output_en;
    wire internal_sram1_cs_n;
    wire internal_sram1_oe_n;
    wire internal_sram1_we_n;

    wire internal_enable;

    wire [`R_DATA] x_q;
    wire [`R_ADDR] x_ra;
    wire [`R_ADDR] x_wa;
    wire [`R_ADDR] x_ra_ff;
    wire [`R_ADDR] x_ra_bp;
    wire x_we;

    wire [`R_DATA] t_q;
    wire [`R_ADDR] t_wa;
    wire [`R_ADDR] t_ra;
    wire t_we;

    wire [`R_NEURON] hid_q;
    wire [`R_NEURON] hid_d;
    wire [`R_ADDR] hid_ra;
    wire [`R_ADDR] hid_ra_ff;
    wire [`R_ADDR] hid_ra_bp;
    wire [`R_ADDR] hid_wa;
    wire hid_we;

    wire [`R_NEURON] out_q;
    wire [`R_NEURON] out_d;
    wire [`R_ADDR] out_ra;
    wire [`R_ADDR] out_ra_ff;
    wire [`R_ADDR] out_ra_bp;
    wire [`R_ADDR] out_wa;
    wire out_we;
    reg  push_reset;

    integer i, j, iter;


    /***** SRAM 0 *****/
    /*** Read ***/
    assign internal_sram0_data_input = (internal_enable &&
                                       (!internal_sram0_cs_n) &&
                                       (!internal_sram0_data_output_en))?
                                        sram0[internal_sram0_addr] : 8'hXX;
    /*** Write ***/
    always @(posedge clk)
        if(internal_enable &&
           internal_sram0_cs_n == 0 &&
           internal_sram0_we_n == 0 &&
           internal_sram0_data_output_en == 1)
           sram0[internal_sram0_addr] <= internal_sram0_data_output;

    /***** SRAM 1 *****/
    /*** Read ***/
    assign internal_sram1_data_input = (internal_enable &&
                                       (!internal_sram1_cs_n) &&
                                       (!internal_sram1_data_output_en))?
                                        sram1[internal_sram1_addr] : 8'hXX;

    /*** Write ***/
    always @(posedge clk)
        if(internal_enable &&
           internal_sram1_cs_n == 0 &&
           internal_sram1_we_n == 0 &&
           internal_sram1_data_output_en == 1)
           sram1[internal_sram1_addr] <= internal_sram1_data_output;

    // クロック
    always #(`CLOCK_PERIOD/2) begin
        clk <= ~clk;
    end

    always @(posedge clk)
    begin
        reset <= push_reset || gpio_in[4];
    end

    // リセット
    task global_reset;
    begin
        @(posedge clk)
        push_reset <= 1'b1;
        @(posedge clk)
        push_reset <= 1'b0;
    end
    endtask

    // SRAM初期化

    /********** 適当 **********/
    /********** DEC -> BIN encoder **********/

     /********** one-hot入力 **********/
     task sram_initialization;
     begin
         for(i = 0; i <= 4095 ; i = i + 1)
         begin
         if(i <= `ADDR_WH_END)
         begin
             sram0[i] <= i*29;
             sram1[i] <= i*31;
         end
         else if(i <= `ADDR_WO_END)
         begin
             sram0[i] <= i*29;
             sram1[i] <= i*31;
         end
         else if(i <= `ADDR_INPUT_END)
         begin
             if(i % 16 == 10)
             begin
                 j = i % 16;
                 sram0[i] <= 8'b0_01_00000;
                 sram1[i] <= 8'b0_01_00000;
             end
             else
             begin
                 sram0[i] <= 8'b0_00_01000;
                 sram1[i] <= 0;
             end
         end
         else if(i <= `ADDR_LABEL_END)
         begin
             sram0[i] <= 0;
             sram1[i] <= 0;
         end
         else begin
             sram0[i] <= 0;
             sram1[i] <= 0;
         end
    end
    end
     endtask


    // テストシナリオ
    // テストシナリオ
    initial begin
        clk <= 0;
        reset <= 0;
        push_reset <= 0;
        iter <= 0;

        $monitoron;

        $monitor("iter:%d state: internal_enable:%d gpio_in:%h gpio_out:%h run_ld:%d fin_ld:%d run_ff:%d fin_ff:%d run_bp:%d fin_bp:%d",
        iter, internal_enable, gpio_in, gpio_out, run_ld, fin_ld, run_ff, fin_ff, run_bp, fin_bp);

        sram_initialization();
      //  sram_label_init;
        global_reset();

        for(i = 0; i <= `ADDR_WO_END; i = i + 1)
            $display("sram0[%h]: %h \t sram1[%h]: %h",
                     i, sram0[i], i, sram1[i]);

        $display("INPUT");
        for(i = `ADDR_INPUT_START; i <= `ADDR_INPUT_END; i = i + 1)
            $display("sram0[%h]: %h \t sram1[%h]: %h",
                     i, sram0[i], i, sram1[i]);

        $display("LABEL");
        for(i = `ADDR_LABEL_START; i <= `ADDR_LABEL_END; i = i + 1)
            $display("sram0[%h]: %h \t sram1[%h]: %h",
                     i, sram0[i], i, sram1[i]);

        @(posedge clk);
        for(i = 0; i <= 2047; i = i + 1)
        begin
            iter <= i;
            gpio_in <= 32'h10;
            while(gpio_out != 32'h10)
            begin
                @(posedge clk);
            end

            // sram0[`ADDR_WH_START + 0] <= 8'b0_01_00000;
            // sram0[`ADDR_WH_START + 1] <= 8'b0_01_00000;
            // sram0[`ADDR_WH_START + 2] <= 8'b0_01_00000;
            // sram0[`ADDR_WH_START + 3] <= 8'b0_01_00000;
            //
            // sram0[`ADDR_WO_START + 0] <= 8'b0_01_00000;
            // sram0[`ADDR_WO_START + 1] <= 8'b0_01_00000;



            if (i % 4 == 0) begin
          //  if (1) begin
                sram0[`ADDR_INPUT_START + 0] <= 8'b0_00_00000;
                sram0[`ADDR_INPUT_START + 1] <= 8'b0_00_00000;
                sram0[`ADDR_INPUT_START + 2] <= 8'b0_00_00000;
                sram0[`ADDR_INPUT_START + 3] <= 8'b0_00_00000;
                sram0[`ADDR_INPUT_START + 4] <= 8'b0_00_00000;
                sram0[`ADDR_INPUT_START + 5] <= 8'b0_00_00000;
                sram0[`ADDR_INPUT_START + 6] <= 8'b0_00_00000;
                sram0[`ADDR_INPUT_START + 7] <= 8'b0_00_00000;
                sram0[`ADDR_INPUT_START + 8] <= 8'b0_00_00000;
                sram0[`ADDR_INPUT_START + 9] <= 8'b0_00_00000;
                sram0[`ADDR_LABEL_START + 0] <= 8'b0_00_00000;
                //sram0[`ADDR_LABEL_START + 1] <= 8'b0_01_00000;
            end else if (i % 4 == 1) begin
                sram0[`ADDR_INPUT_START + 0] <= 8'b0_01_00000;
                sram0[`ADDR_INPUT_START + 1] <= 8'b0_01_00000;
                sram0[`ADDR_INPUT_START + 2] <= 8'b0_01_00000;
                sram0[`ADDR_INPUT_START + 3] <= 8'b0_01_00000;
                sram0[`ADDR_INPUT_START + 4] <= 8'b0_01_00000;
                sram0[`ADDR_INPUT_START + 5] <= 8'b0_00_00000;
                sram0[`ADDR_INPUT_START + 6] <= 8'b0_00_00000;
                sram0[`ADDR_INPUT_START + 7] <= 8'b0_00_00000;
                sram0[`ADDR_INPUT_START + 8] <= 8'b0_00_00000;
                sram0[`ADDR_INPUT_START + 9] <= 8'b0_00_00000;

                sram0[`ADDR_LABEL_START + 0] <= 8'b0_01_00000;
                //sram0[`ADDR_LABEL_START + 1] <= 8'b0_00_00010;
            end else if (i % 4 == 2) begin
                sram0[`ADDR_INPUT_START + 0] <= 8'b0_00_00000;
                sram0[`ADDR_INPUT_START + 1] <= 8'b0_00_00000;
                sram0[`ADDR_INPUT_START + 2] <= 8'b0_00_00000;
                sram0[`ADDR_INPUT_START + 3] <= 8'b0_00_00000;
                sram0[`ADDR_INPUT_START + 4] <= 8'b0_00_00000;
                sram0[`ADDR_INPUT_START + 5] <= 8'b0_01_00000;
                sram0[`ADDR_INPUT_START + 6] <= 8'b0_01_00000;
                sram0[`ADDR_INPUT_START + 7] <= 8'b0_01_00000;
                sram0[`ADDR_INPUT_START + 8] <= 8'b0_01_00000;
                sram0[`ADDR_INPUT_START + 9] <= 8'b0_01_00000;
                sram0[`ADDR_LABEL_START + 0] <= 8'b0_01_00000;
            end else if (i % 4 == 3) begin
                sram0[`ADDR_INPUT_START + 0] <= 8'b0_01_00000;
                sram0[`ADDR_INPUT_START + 1] <= 8'b0_01_00000;
                sram0[`ADDR_INPUT_START + 2] <= 8'b0_01_00000;
                sram0[`ADDR_INPUT_START + 3] <= 8'b0_01_00000;
                sram0[`ADDR_INPUT_START + 4] <= 8'b0_01_00000;
                sram0[`ADDR_INPUT_START + 5] <= 8'b0_01_00000;
                sram0[`ADDR_INPUT_START + 6] <= 8'b0_01_00000;
                sram0[`ADDR_INPUT_START + 7] <= 8'b0_01_00000;
                sram0[`ADDR_INPUT_START + 8] <= 8'b0_01_00000;
                sram0[`ADDR_INPUT_START + 9] <= 8'b0_01_00000;
                sram0[`ADDR_LABEL_START + 0] <= 8'b0_00_00000;
            end



            gpio_in <= 32'h8;   // 32'h4:FFのみ 32'h8:FF+BP 32'hc:BPのみ
            while(gpio_out != 32'hf)
            begin
                @(posedge clk);
            end
            @(posedge clk);
        end
        @(posedge clk);

        for(i = 0; i < `N_IN; i = i + 1)
            $display("input_buffer[%h]: %h", i, input_buffer.ram[i]);

        for(i = 0; i < `N_OUT; i = i + 1)
            $display("label_buffer[%h]: %h", i, label_buffer.ram[i]);

        for(i = 0; i < `N_H; i = i + 1)
            $display("hidden_buffer[%h]: %h", i, hidden_buffer.ram[i]);

        for(i = 0; i < `N_OUT; i = i + 1)
            $display("output_buffer[%h]: %h", i, output_buffer.ram[i]);

        $display("Weight");
        for(i = 0; i <= `ADDR_WO_END; i = i + 1)
            $display("sram0[%h]: %h \t sram1[%h]: %h",
                     i, sram0[i], i, sram1[i]);

        $display("Output");
        for(i = `ADDR_OUTPUT_START; i <= `ADDR_OUTPUT_END; i = i + 1)
            $display("sram0[%h]: %h", i, sram0[i]);

        $display("ph_hid");
        for(i = 0; i < `N_H; i = i + 1)
            $display("ph_hid[%h] %h",i ,backprop.ph_hid[i]);

        $display("ph_out");
        for(i = 0; i < `N_OUT; i = i + 1)
            $display("ph_out[%h] %h",i ,backprop.ph_out[i]);

        $monitoroff;
        $stop();
    end

    controller controller(
        .clk(clk),
        .reset(reset),
        .gpio_in(gpio_in),
        .fin_ld(fin_ld),
        .fin_ff(fin_ff),
        .fin_bp(fin_bp),
        .internal_enable(internal_enable),
        .run_ld(run_ld),
        .run_ff(run_ff),
        .run_bp(run_bp),
        .gpio_out(gpio_out)
    );

    loader loader(
        .clk(clk),
        .reset(reset),
        .run(run_ld),
        .sram_addr(sram_addr_ld),
        .sram_data_output_en(sram_data_output_en_ld),
        .sram_cs_n(sram_cs_n_ld),
        .sram_oe_n(sram_oe_n_ld),
        .sram_we_n(sram_we_n_ld),
        .x_wa(x_wa),
        .t_wa(t_wa),
        .x_we(x_we),
        .t_we(t_we),
        .fin(fin_ld)
    );

    buffer #(
        .ADDR_WIDTH(`W_ADDR),
        .WORD_NUM(`N_IN),
        .WORD_WIDTH(`W_DATA)
    )input_buffer(
        .clk(clk),
        .reset(reset),
        .we(x_we),
        .ra(x_ra),
        .wa(x_wa),
        .d(internal_sram0_data_input),
        .q(x_q)
    );

    buffer #(
        .ADDR_WIDTH(`W_ADDR),
        .WORD_NUM(`N_OUT),
        .WORD_WIDTH(`W_DATA)
    )label_buffer(
        .clk(clk),
        .reset(reset),
        .we(t_we),
        .ra(t_ra),
        .wa(t_wa),
        .d(internal_sram0_data_input),
        .q(t_q)
    );

    buffer #(
        .ADDR_WIDTH(`W_ADDR),
        .WORD_NUM(`N_H),
        .WORD_WIDTH(`W_NEURON)
    )hidden_buffer(
        .clk(clk),
        .reset(reset),
        .we(hid_we),
        .ra(hid_ra),
        .wa(hid_wa),
        .d(hid_d),
        .q(hid_q)
    );

    buffer #(
        .ADDR_WIDTH(`W_ADDR),
        .WORD_NUM(`N_OUT),
        .WORD_WIDTH(`W_NEURON)
    )output_buffer(
        .clk(clk),
        .reset(reset),
        .we(out_we),
        .ra(out_ra),
        .wa(out_wa),
        .d(out_d),
        .q(out_q)
    );

    feedforward feedforward(
        .clk(clk),
        .reset(reset),
        .run(run_ff),
        .sram_read_data(internal_sram0_data_input),
        .sram_addr(sram_addr_ff),
        .sram_data_output_en(sram_data_output_en_ff),
        .sram_cs_n(sram_cs_n_ff),
        .sram_we_n(sram_we_n_ff),
        .sram_oe_n(sram_oe_n_ff),

        .x(x_q),
        .x_addr(x_ra_ff),

        .hid_q(hid_q),
        .hid_d(hid_d),
        .hid_write_addr(hid_wa),
        .hid_read_addr(hid_ra_ff),
        .hid_we(hid_we),

        .out_q(out_q),
        .out_d(out_d),
        .out_write_addr(out_wa),
        .out_read_addr(out_ra_ff),
        .out_we(out_we),

        .sram_write_data(sram_data_output_ff),

        .fin(fin_ff)
     );

    BP backprop(
        .clk(clk),
        .rst_n(~reset),
        .run(run_bp),
        .finish(fin_bp),

        .in_buf_out(x_q),
        .in_buf_addr(x_ra_bp),

        .t_buf_out(t_q),
        .t_buf_addr(t_ra),

        .hid_buf_out(hid_q),
        .hid_buf_addr(hid_ra_bp),

        .out_buf_out(out_q),
        .out_buf_addr(out_ra_bp),

        .sram0_data_input(internal_sram0_data_input),
        .sram0_addr(sram0_addr_bp),
        .sram0_data_output(sram0_data_output_bp),
        .sram0_output_en(sram0_data_output_en_bp),
        .sram0_cs_n(sram0_cs_n_bp),
        .sram0_oe_n(sram0_oe_n_bp),
        .sram0_we_n(sram0_we_n_bp),

        .sram1_data_input(internal_sram1_data_input),
        .sram1_addr(sram1_addr_bp),
        .sram1_data_output(sram1_data_output_bp),
        .sram1_output_en(sram1_data_output_en_bp),
        .sram1_cs_n(sram1_cs_n_bp),
        .sram1_oe_n(sram1_oe_n_bp),
        .sram1_we_n(sram1_we_n_bp)
        );

     multiplexer multiplexer(

        .run_ld(run_ld),
        .run_ff(run_ff),
        .run_bp(run_bp),

        .x_ra(x_ra),
        .x_ra_ff(x_ra_ff),
        .x_ra_bp(x_ra_bp),

        .hid_ra(hid_ra),
        .hid_ra_ff(hid_ra_ff),
        .hid_ra_bp(hid_ra_bp),

        .out_ra(out_ra),
        .out_ra_ff(out_ra_ff),
        .out_ra_bp(out_ra_bp),

        .sram_addr_ld(sram_addr_ld),
        .sram_data_output_en_ld(sram_data_output_en_ld),
        .sram_cs_n_ld(sram_cs_n_ld),
        .sram_oe_n_ld(sram_oe_n_ld),
        .sram_we_n_ld(sram_we_n_ld),

        .sram_addr_ff(sram_addr_ff),
        .sram_data_output_ff(sram_data_output_ff),
        .sram_data_output_en_ff(sram_data_output_en_ff),
        .sram_cs_n_ff(sram_cs_n_ff),
        .sram_we_n_ff(sram_we_n_ff),
        .sram_oe_n_ff(sram_oe_n_ff),

        .sram0_addr_bp(sram0_addr_bp),
        .sram0_data_output_bp(sram0_data_output_bp),
        .sram0_data_output_en_bp(sram0_data_output_en_bp),
        .sram0_cs_n_bp(sram0_cs_n_bp),
        .sram0_we_n_bp(sram0_we_n_bp),
        .sram0_oe_n_bp(sram0_oe_n_bp),

        .sram1_addr_bp(sram1_addr_bp),
        .sram1_data_output_bp(sram1_data_output_bp),
        .sram1_data_output_en_bp(sram1_data_output_en_bp),
        .sram1_cs_n_bp(sram1_cs_n_bp),
        .sram1_we_n_bp(sram1_we_n_bp),
        .sram1_oe_n_bp(sram1_oe_n_bp),

        .internal_sram0_addr(internal_sram0_addr),
        .internal_sram0_data_output(internal_sram0_data_output),
        .internal_sram0_data_output_en(internal_sram0_data_output_en),
        .internal_sram0_cs_n(internal_sram0_cs_n),
        .internal_sram0_oe_n(internal_sram0_oe_n),
        .internal_sram0_we_n(internal_sram0_we_n),

        .internal_sram1_addr(internal_sram1_addr),
        .internal_sram1_data_output(internal_sram1_data_output),
        .internal_sram1_data_output_en(internal_sram1_data_output_en),
        .internal_sram1_cs_n(internal_sram1_cs_n),
        .internal_sram1_oe_n(internal_sram1_oe_n),
        .internal_sram1_we_n(internal_sram1_we_n)
    );

endmodule
