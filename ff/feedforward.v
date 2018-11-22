`ifndef DEFMACRO
    `include "../common/def.v"
    `define DEFMACRO
`endif

module feedforward(
    input                clk,
    input                reset,
    input                run,
    output reg           fin,

    input      [7:0]     sram_read_data,
    output reg [7:0]     sram_write_data,
    output reg [16:0]    sram_addr,
    output reg           sram_data_output_en,
    output reg           sram_cs_n,
    output reg           sram_we_n,
    output reg           sram_oe_n,

    input      [7:0]     x,
    output reg [`R_ADDR] x_addr,

    input      [11:0]    hid_q,
    output reg [11:0]    hid_d,
    output [`R_ADDR] hid_write_addr,
    output [`R_ADDR] hid_read_addr,
    output reg           hid_we,

    input      [11:0]    out_q,
    output reg [11:0]    out_d,
    output [`R_ADDR] out_write_addr,
    output [`R_ADDR] out_read_addr,
    output reg           out_we
    );

    reg  [31:0] state;

    reg  [`R_ADDR] hid_addr;
    reg  [`R_ADDR] out_addr;

    reg  [7:0]  data_a;
    reg  [7:0]  data_b;
    reg  [11:0] data_c;
    wire [11:0] data_y;

    reg  [11:0] lut_d;
    wire [7:0]  lut_q;

    wire [7:0]  mul;

    assign hid_read_addr  = hid_addr;
    assign hid_write_addr = hid_addr;
    assign out_read_addr  = out_addr;
    assign out_write_addr = out_addr;


    always @(posedge clk)
    begin
        if(reset)
        begin
            fin                 <= 0;

            sram_write_data     <= 0;
            sram_addr           <= 0;
            sram_data_output_en <= 0;
            sram_cs_n           <= 0;
            sram_we_n           <= 1;
            sram_oe_n           <= 0;

            x_addr              <= 0;

            hid_d               <= 0;
            hid_addr            <= 0;
            hid_we              <= 0;

            out_d               <= 0;
            out_addr            <= 0;
            out_we              <= 0;

            state               <= 0;

            data_a              <= 0;
            data_b              <= 0;
            data_c              <= 0;
            lut_d               <= 0;
        end

        else if(run) begin
            if(state == 0)
            begin
                if(!fin)
                begin
                    sram_addr           <= `ADDR_WH_START;
                    sram_cs_n           <= 0;
                    sram_we_n           <= 1;
                    sram_oe_n           <= 0;
                    sram_data_output_en <= 0;
                    sram_write_data     <= 0;

                    x_addr              <= 0;

                    hid_d               <= 0;
                    hid_addr            <= 0;
                    hid_we              <= 0;

                    out_d               <= 0;
                    out_addr            <= 0;
                    out_we              <= 0;

                    data_a              <= 0;
                    data_b              <= 0;
                    data_c              <= 0;
                    lut_d               <= 0;

                    fin                 <= 0;
                    state               <= 10;
                end
            end

            /************* In -> Hidden の積和演算 *************/
            else if(state == 10)
            begin
                data_a <= x;
                data_b <= sram_read_data;
                data_c <= hid_q;
                state     <= state + 1;
            end

            else if(state == 11)
            begin
                hid_d  <= data_y;
                hid_we <= 1;
                state  <= state + 1;
            end

            else if(state == 12)
            begin
                if(sram_addr == `ADDR_WH_END)
                begin
                    x_addr <= 0;
                    hid_addr <= 0;
                    hid_d <= 0;
                    hid_we <= 0;
                    out_addr <= 0;
                    sram_addr <= `ADDR_WO_START;
                    state <= 20;
                end
                else if(hid_addr == `N_H - 1)
                begin
                    x_addr <= x_addr + 1;
                    hid_addr <= 0;
                    hid_d <= 0;
                    hid_we <= 0;
                    sram_addr <= sram_addr + 1;
                    state <= 10;
                end
                else
                begin
                    hid_addr <= hid_addr + 1;
                    hid_d <= 0;
                    hid_we <= 0;
                    sram_addr <= sram_addr + 1;
                    state <= 10;
                end
            end

            /************* Hidden -> Out の積和演算 *************/
            else if(state == 20)
            begin
                lut_d <= hid_q;
                state <= state + 1;
            end

            else if(state == 21)
            begin
                data_a <= lut_q;
                data_b <= sram_read_data;
                data_c <= out_q;
                state  <= state + 1;
            end

            else if(state == 22)
            begin
                out_d  <= data_y;
                out_we <= 1;
                state  <= state + 1;
            end

            else if(state == 23)
            begin
                if(sram_addr == `ADDR_WO_END)
                begin
                    hid_addr  <= 0;
                    out_addr  <= 0;
                    out_d     <= 0;
                    out_we    <= 0;
                    sram_addr <= `ADDR_OUTPUT_START;
                    state     <= 30;
                end
                else if(out_addr == `N_OUT - 1)
                begin
                    hid_addr  <= hid_addr + 1;
                    out_addr  <= 0;
                    out_d     <= 0;
                    out_we    <= 0;
                    sram_addr <= sram_addr + 1;
                    state     <= 20;
                end
                else
                begin
                    out_addr  <= out_addr + 1;
                    out_d     <= 0;
                    out_we    <= 0;
                    sram_addr <= sram_addr + 1;
                    state     <= 20;
                end
            end

            /************* SRAM書き込み *************/
            else if(state == 30)
            begin
                lut_d <= out_q;
                state <= state + 1;
            end

            else if(state == 31)
            begin
                sram_write_data     <= lut_q;
                sram_data_output_en <= 1;
                sram_cs_n           <= 0;
                sram_we_n           <= 0;
                state               <= state + 1;
            end

            else if(state == 32)
            begin
                sram_cs_n <= 1;
                sram_we_n <= 1;
                state     <= state + 1;
            end
            else if(state == 33)
            begin
                if(sram_addr == `ADDR_OUTPUT_END)
                begin
                    out_addr            <= 0;
                    sram_addr           <= 0;
                    sram_write_data     <= 0;
                    sram_data_output_en <= 0;
                    state               <= 40;
                end
                else
                begin
                    out_addr            <= out_addr + 1;
                    sram_addr           <= sram_addr + 1;
                    sram_write_data     <= 0;
                    sram_data_output_en <= 0;
                    state               <= 30;
                end
            end

            /************* 終了 *************/
            else if(state == 40)
            begin
                fin   <= 1;
                state <= 0;
            end

        end
    end

    multiplier_8_8_8 inst_ff_multiplier(
        .A(data_a),
        .B(data_b),
        .OUT(mul)
    );

    adder_8_12_12 inst_ff_adder(
        .A(mul),
        .B(data_c),
        .OUT(data_y)
    );

    lut inst_lut(
        .in(lut_d),
        .y(lut_q)
    );

endmodule