// =============================================================================
// q15 - 3-Input Median
// =============================================================================
// Problem:
//   Implement a purely combinational module that outputs the median (middle)
//   value of three WIDTH-bit unsigned inputs.
//
// Interface:
//   parameter WIDTH           : bit width of a, b, c, med (default 8)
//   input  logic [WIDTH-1:0] a, b, c   : three unsigned inputs, any order
//   output logic [WIDTH-1:0] med       : the median (middle) value of {a,b,c}
//                                         -- neither the min nor the max
//
// Assumptions / edge-case behavior:
//   - Combinational only: no clk/rst.
//   - All values are treated as unsigned.
//   - med is always one of a, b, or c (by value; when there are duplicate
//     values, any one of them being reported is fine as long as the VALUE
//     of med is the mathematically correct median value).
//   - Ties: if exactly two of the three inputs are equal, that repeated
//     value is the median regardless of whether the third (distinct) value
//     is larger or smaller than the pair (e.g. a==b != c => med == a == b,
//     whether c is bigger or smaller). If all three are equal, med equals
//     that common value.
// =============================================================================

module q15 #(
    parameter WIDTH = 8
) (
    input  logic [WIDTH-1:0] a,
    input  logic [WIDTH-1:0] b,
    input  logic [WIDTH-1:0] c,
    output logic [WIDTH-1:0] med
);

    // TODO: implement your RTL here

endmodule
