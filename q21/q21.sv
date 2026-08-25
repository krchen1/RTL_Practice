// =============================================================================
// q21 - 32-bit input: (a) index of first set bit, (b) population count
// =============================================================================
// Problem:
//   Purely combinational module. Given a 32-bit input word, report the bit
//   index of its least-significant set bit and the total count of set bits.
//
// Interface:
//   input  logic [31:0] data          - the input word.
//   output logic         valid         - 1 if data != 0 (i.e. first_set_idx
//                                         is meaningful), else 0.
//   output logic [4:0]   first_set_idx - the bit index (0..31) of the
//                                         LEAST-significant set bit of data
//                                         (scanning from bit 0 upward, the
//                                         first '1' found). Only meaningful
//                                         when valid==1.
//   output logic [5:0]   popcount      - the number of '1' bits in data
//                                         (0..32, hence 6 bits wide).
//
// Assumptions / pinned-down behavior:
//   - valid = (data != 32'd0).
//   - When data==32'd0: valid==0 and popcount==0 are checked by the
//     testbench; first_set_idx may be anything in that case (not checked).
//   - Purely combinational: no clk/rst on this module.
// =============================================================================

module q21 (
    input  logic [31:0] data,
    output logic         valid,
    output logic [4:0]   first_set_idx,
    output logic [5:0]   popcount
);

    // TODO: implement your RTL here

endmodule
