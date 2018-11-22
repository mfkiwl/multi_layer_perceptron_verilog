`ifndef DEFMACRO
    `include "../common/def.v"
    `define DEFMACRO
`endif

module boardtest(OSC, RESET_N, M1_A, M1_D, M1_CSn, M1_WEn, M1_OEn, M2_A, M2_D, M2_CSn, M2_WEn, M2_OEn, F_IO, F_PB, F_PC, AnalogIn, Switch, LED);
    /***** IO *****/
    input OSC, RESET_N;

    output [16:0]M1_A;
    inout  [7:0]M1_D;
    output M1_CSn, M1_WEn, M1_OEn;

    output [16:0]M2_A;
    inout  [7:0]M2_D;
    output M2_CSn, M2_WEn, M2_OEn;

    // inout [7:0]F_IO;
    // inout [5:0]F_PB;
    // inout [5:0]F_PC;

    input [7:0]F_IO;
    inout [5:0]F_PB;
    input [5:0]F_PC;


    input  [4:1] AnalogIn;
    input  [3:1] Switch;
    output [3:1] LED;

    wire run_ld;
    wire run_ff;
    wire run_bp;

    wire fin_ld;
    wire fin_ff;
    wire fin_bp;

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

    reg [16:0]sram0_addr;
    reg [7:0]sram0_data;
    reg sram0_cs_n;
    reg sram0_oe_n;
    reg sram_0_we_n;

    reg [16:0]sram1_addr;
    reg [7:0]sram1_data;
    reg sram1_cs_n;
    reg sram1_oe_n;
    reg sram_1_we_n;

    wire [31:0] gpio_output0;
    wire [31:0] gpio_output1;
    wire [31:0] gpio_output2;
    wire [31:0] gpio_output3;
    wire [31:0] gpio_output4;
    wire [31:0] gpio_output5;
    wire [31:0] gpio_output6;
    wire [31:0] gpio_output7;

    wire [31:0] gpio_input0;
    wire [31:0] gpio_input1;
    wire [31:0] gpio_input2;
    wire [31:0] gpio_input3;
    wire [31:0] gpio_input4;
    wire [31:0] gpio_input5;
    wire [31:0] gpio_input6;
    wire [31:0] gpio_input7;

    wire clk;
    wire gene_reset_n;
    reg reset;
    wire [3:1]Switch_n;

    reg [22:0]counter;
    reg [2:0]led_reg;
    reg [31:0] test_state;
    wire push_reset;

    assign push_reset = ~gene_reset_n;
    reg [31:0] gpio_in;
    wire [31:0] gpio_out;

    // Assignment
    assign clk = OSC;

    assign Switch_n = ~Switch;
    assign LED[3:1] = led_reg[2:0];

    assign gpio_input0 = gpio_output0;
    assign gpio_input1 = gpio_out;

    assign gpio_input2 = gpio_output2;
    assign gpio_input3 = gpio_output3;
    assign gpio_input4 = gpio_output4;
    assign gpio_input5 = gpio_output5;
    assign gpio_input6 = gpio_output6;
    assign gpio_input7 = gpio_output7;

    // force reset

    always @ (posedge clk) begin
      reset <= push_reset || gpio_in[4];
    end

    always @(posedge clk)
        if(reset)
            gpio_in <= 0;
        else
            gpio_in <= gpio_output0;

    /***** LED Controlo *****/
    always @(posedge clk)
        if(reset)
        begin
            led_reg <= 3'b000;
        end
        else
        begin
            led_reg <= 3'b111;
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
        .sram_write_data(sram_data_output_ff),
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


        .fin(fin_ff)
     );

    BP backprop(
        .clk(clk),
        .rst_n(!reset),
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

    gene_reset_bycounter #(
        .value(32'h0000ffff)
    )gene_reset(
        .pReset_n(RESET_N),
        .pLocked(1'b1),
        .pClk(clk),
        .pResetOut_n(gene_reset_n)
    );

    spi_external_sram u_target (
        .sysclk(clk),
        .reset(reset),

        .spi_cs_n(F_PB[1]),
        .spi_clk(F_PB[5]),
        .spi_din(F_PB[3]),
        .spi_dout(F_PB[4]),

        .sram0_addr(M1_A),
        .sram0_data(M1_D),
        .sram0_cs_n(M1_CSn),
        .sram0_oe_n(M1_OEn),
        .sram0_we_n(M1_WEn),

        .sram1_addr(M2_A),
        .sram1_data(M2_D),
        .sram1_cs_n(M2_CSn),
        .sram1_oe_n(M2_OEn),
        .sram1_we_n(M2_WEn),

        .internal_enable(internal_enable),

        .internal_sram0_addr(internal_sram0_addr),
        .internal_sram0_data_input(internal_sram0_data_input),
        .internal_sram0_data_output(internal_sram0_data_output),
        .internal_sram0_data_output_en(internal_sram0_data_output_en),
        .internal_sram0_cs_n(internal_sram0_cs_n),
        .internal_sram0_oe_n(internal_sram0_oe_n),
        .internal_sram0_we_n(internal_sram0_we_n),

        .internal_sram1_addr(internal_sram1_addr),
        .internal_sram1_data_input(internal_sram1_data_input),
        .internal_sram1_data_output(internal_sram1_data_output),
        .internal_sram1_data_output_en(internal_sram1_data_output_en),
        .internal_sram1_cs_n(internal_sram1_cs_n),
        .internal_sram1_oe_n(internal_sram1_oe_n),
        .internal_sram1_we_n(internal_sram1_we_n),

        .gpio_output0(gpio_output0),
        .gpio_output1(gpio_output1),
        .gpio_output2(gpio_output2),
        .gpio_output3(gpio_output3),
        .gpio_output4(gpio_output4),
        .gpio_output5(gpio_output5),
        .gpio_output6(gpio_output6),
        .gpio_output7(gpio_output7),

        .gpio_input0(gpio_input0),
        .gpio_input1(gpio_input1),
        .gpio_input2(gpio_input2),
        .gpio_input3(gpio_input3),
        .gpio_input4(gpio_input4),
        .gpio_input5(gpio_input5),
        .gpio_input6(gpio_input6),
        .gpio_input7(gpio_input7)
    );

endmodule
