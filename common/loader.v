`ifndef DEFMACRO
    `include "def.v"
    `define DEFMACRO
`endif

module loader(
    input clk,
    input reset,
    input run,

    output reg [16:0]sram_addr,
    output reg sram_data_output_en,
    output reg sram_cs_n,
    output reg sram_oe_n,
    output reg sram_we_n,

    output reg [`R_ADDR] x_wa,
    output reg [`R_ADDR] t_wa,
    output reg x_we,
    output reg t_we,
    output reg fin

);
    
    always @(posedge clk)
        if(reset)
        begin
            sram_addr           <= 0;
            sram_data_output_en <= 0;
            sram_cs_n           <= 0;
            sram_we_n           <= 1;
            sram_oe_n           <= 0;
            x_wa                <= 0;
            t_wa                <= 0;
            x_we                <= 0;
            t_we                <= 0;
            fin                 <= 0;
        end
        else if(run && !fin)
        begin
            if(sram_addr == 0)
            begin
                sram_addr <= `ADDR_INPUT_START;
                x_wa      <= 0;
                x_we      <= 1;
                t_wa      <= 0;
                t_we      <= 0;
                fin       <= 0;
            end
            else if(sram_addr < `ADDR_INPUT_END)
            begin
                sram_addr <= sram_addr + 1;
                x_wa      <= x_wa + 1;
                x_we      <= 1;
                t_wa      <= 0;
                t_we      <= 0;
                fin       <= 0;
            end
            else if(sram_addr == `ADDR_INPUT_END)
            begin
                sram_addr <= `ADDR_LABEL_START;
                x_wa      <= 0;
                x_we      <= 0;
                t_wa      <= 0;
                t_we      <= 1;
                fin       <= 0; 
            end
            else if(sram_addr < `ADDR_LABEL_END)
            begin
                sram_addr <= sram_addr + 1;
                x_wa      <= 0;
                x_we      <= 0;
                t_wa      <= t_wa + 1;
                t_we      <= 1;
                fin       <= 0;
            end
            else
            begin
                sram_addr <= 0;
                x_wa      <= 0;
                x_we      <= 0;
                t_wa      <= 0;
                t_we      <= 0;
                fin       <= 1;
            end
        end
        else if(run && fin)
        begin
            sram_addr <= 0;
            x_wa      <= 0;
            x_we      <= 0;
            t_wa      <= 0;
            t_we      <= 0;
            fin       <= 1;
        end
        else
        begin
            sram_addr <= 0;
            x_wa      <= 0;
            x_we      <= 0;
            t_wa      <= 0;
            t_we      <= 0;
            fin       <= 0;
        end
endmodule

