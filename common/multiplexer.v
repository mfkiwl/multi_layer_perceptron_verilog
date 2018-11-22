`ifndef DEFMACRO
    `include "def.v"
    `define DEFMACRO
`endif


module multiplexer(
    /***** from Controller *****/
    input run_ld,
    input run_ff,
    input run_bp,

    /***** Buffer Address *****/
    output [`R_ADDR] x_ra,
    input  [`R_ADDR] x_ra_ff,
    input  [`R_ADDR] x_ra_bp,

    output [`R_ADDR] hid_ra,
    input  [`R_ADDR] hid_ra_ff,
    input  [`R_ADDR] hid_ra_bp,

    output [`R_ADDR] out_ra,
    input  [`R_ADDR] out_ra_ff,
    input  [`R_ADDR] out_ra_bp,

    /***** SRAM Address, Control Signals *****/
    input  [16:0]sram_addr_ld,
    input  sram_data_output_en_ld,
    input  sram_cs_n_ld,
    input  sram_oe_n_ld,
    input  sram_we_n_ld,

    input  [16:0]sram_addr_ff,
    input  [7:0] sram_data_output_ff,
    input  sram_data_output_en_ff,
    input  sram_cs_n_ff,
    input  sram_oe_n_ff,
    input  sram_we_n_ff,


    input  [16:0]sram0_addr_bp,
    input  [7:0] sram0_data_output_bp,
    input  sram0_data_output_en_bp,
    input  sram0_cs_n_bp,
    input  sram0_oe_n_bp,
    input  sram0_we_n_bp,

    input  [16:0]sram1_addr_bp,
    input  [7:0] sram1_data_output_bp,
    input  sram1_data_output_en_bp,
    input  sram1_cs_n_bp,
    input  sram1_oe_n_bp,
    input  sram1_we_n_bp,

    output [16:0]internal_sram0_addr,
    output [7:0] internal_sram0_data_output,
    output internal_sram0_data_output_en,
    output internal_sram0_cs_n,
    output internal_sram0_oe_n,
    output internal_sram0_we_n,

    output [16:0]internal_sram1_addr,
    output [7:0] internal_sram1_data_output,
    output internal_sram1_data_output_en,
    output internal_sram1_cs_n,
    output internal_sram1_oe_n,
    output internal_sram1_we_n
);

    assign x_ra = (run_bp)? x_ra_bp : x_ra_ff;

    assign hid_ra = (run_bp)? hid_ra_bp : hid_ra_ff;

    assign out_ra = (run_bp)? out_ra_bp : out_ra_ff;

    assign internal_sram0_addr = (run_ld)? sram_addr_ld :
                                 (run_bp)? sram0_addr_bp : sram_addr_ff;

    assign internal_sram0_data_output = (run_bp)? sram0_data_output_bp : sram_data_output_ff;

    assign internal_sram0_data_output_en = (run_ld)? sram_data_output_en_ld :
                                           (run_bp)? sram0_data_output_en_bp : sram_data_output_en_ff;

    assign internal_sram0_cs_n = (run_ld)? sram_cs_n_ld :
                                 (run_bp)? sram0_cs_n_bp : sram_cs_n_ff;

    assign internal_sram0_oe_n = (run_ld)? sram_oe_n_ld :
                                 (run_bp)? sram0_oe_n_bp : sram_oe_n_ff;

    assign internal_sram0_we_n = (run_ld)? sram_we_n_ld :
                                 (run_bp)? sram0_we_n_bp : sram_we_n_ff;

    assign internal_sram1_addr = sram1_addr_bp;

    assign internal_sram1_data_output = sram1_data_output_bp;

    assign internal_sram1_data_output_en = sram1_data_output_en_bp;

    assign internal_sram1_cs_n = sram1_cs_n_bp;

    assign internal_sram1_oe_n = sram1_oe_n_bp;

    assign internal_sram1_we_n = sram1_we_n_bp;

endmodule
