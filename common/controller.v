`ifndef DEFMACRO
    `include "def.v"
    `define DEFMACRO
`endif

module controller(
    input clk,
    input reset,
    input [31:0] gpio_in,
    input fin_ld,
    input fin_ff,
    input fin_bp,
    output reg internal_enable,
    output reg run_ld,
    output reg run_ff,
    output reg run_bp,
    output reg [31:0] gpio_out
);


    reg [31:0] gpio_in_reg;
    reg flag_fin_ld, flag_fin_ff, flag_fin_bp;

    always @(posedge clk)
        gpio_in_reg <= gpio_in;

    always @(posedge clk)
        if(reset)
        begin
            flag_fin_ld     <= 0;
            flag_fin_ff     <= 0;
            flag_fin_bp     <= 0;
            run_ld          <= 0;
            run_ff          <= 0;
            run_bp          <= 0;
            internal_enable <= 0;
            gpio_out        <= 32'h10;
        end
        else if(gpio_in_reg == 32'h4)
        begin
            if(!flag_fin_ld)
                if(fin_ld)
                begin
                    run_ld          <= 0;
                    run_ff          <= 1;
                    flag_fin_ld     <= 1;
                    internal_enable <= 1;
                end
                else
                begin
                    run_ld          <= 1;
                    flag_fin_ld     <= 0;
                    internal_enable <= 1;
                end
            else if(!flag_fin_ff)
                if(fin_ff)
                begin
                    run_ff          <= 0;
                    flag_fin_ff     <= 1;
                    internal_enable <= 0;
                    gpio_out        <= 32'hf;
                end
                else
                begin
                    run_ff          <= 1;
                    flag_fin_ff     <= 0;
                    internal_enable <= 1;
                end
        end
        else if(gpio_in_reg == 32'h8)
        begin
            if(!flag_fin_ld)
                if(fin_ld)
                begin
                    run_ld          <= 0;
                    run_ff          <= 1;
                    flag_fin_ld     <= 1;
                    internal_enable <= 1;
                end
                else
                begin
                    run_ld          <= 1;
                    flag_fin_ld     <= 0;
                    internal_enable <= 1;
                end
            else if(!flag_fin_ff)
                if(fin_ff)
                begin
                    run_ff          <= 0;
                    run_bp          <= 1;
                    flag_fin_ff     <= 1;
                    internal_enable <= 1;
                end
                else
                begin
                    run_ff          <= 1;
                    flag_fin_ff     <= 0;
                    internal_enable <= 1;
                end
            else if(!flag_fin_bp)
                if(fin_bp)
                begin
                    run_bp          <= 0;
                    flag_fin_bp     <= 1;
                    internal_enable <= 0;
                    gpio_out        <= 32'hf;
                end
                else
                begin
                    run_bp          <= 1;
                    flag_fin_bp     <= 0;
                    internal_enable <= 1;
                end
        end
        else if(gpio_in_reg == 32'hc)
        begin
            if(!flag_fin_ld)
                if(fin_ld)
                begin
                    run_ld          <= 0;
                    run_bp          <= 1;
                    flag_fin_ld     <= 1;
                    internal_enable <= 1;
                end
                else
                begin
                    run_ld          <= 1;
                    flag_fin_ld     <= 0;
                    internal_enable <= 1;
                end
            else if(!flag_fin_bp)
                if(fin_bp)
                begin
                    run_bp          <= 0;
                    flag_fin_bp     <= 1;
                    internal_enable <= 0;
                    gpio_out        <= 32'hf;
                end
                else
                begin
                    run_bp          <= 1;
                    flag_fin_bp     <= 0;
                    internal_enable <= 1;
                end
        end
        else
        begin
            run_ld          <= 0;
            run_ff          <= 0;
            run_bp          <= 0;
            gpio_out        <= 32'h10;
            internal_enable <= 0;
            flag_fin_ld     <= 0;
            flag_fin_ff     <= 0;
            flag_fin_bp     <= 0;
        end

endmodule
