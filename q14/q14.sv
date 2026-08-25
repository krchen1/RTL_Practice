// =============================================================================
// q14 - 3-Input Sort
// =============================================================================
// Problem:
//   Implement a purely combinational sorting network that takes three
//   WIDTH-bit unsigned values and outputs them sorted in ascending order.
//
// Interface:
//   parameter WIDTH           : bit width of a, b, c, lo, mid, hi (default 8)
//   input  logic [WIDTH-1:0] a, b, c   : three unsigned inputs, any order
//   output logic [WIDTH-1:0] lo        : the smallest of {a,b,c}
//   output logic [WIDTH-1:0] mid       : the middle value of {a,b,c}
//   output logic [WIDTH-1:0] hi        : the largest of {a,b,c}
//
// Assumptions / edge-case behavior:
//   - Combinational only: no clk/rst.
//   - All values are treated as unsigned.
//   - lo <= mid <= hi always holds.
//   - {lo, mid, hi} is always a permutation of {a, b, c} (same multiset of
//     values, just reordered) -- ties are fine: e.g. if a==b, both copies
//     still appear among {lo,mid,hi}.
// =============================================================================

module q14 #(
    parameter WIDTH = 8
) (
    input  logic [WIDTH-1:0] a,
    input  logic [WIDTH-1:0] b,
    input  logic [WIDTH-1:0] c,
    output logic [WIDTH-1:0] lo,
    output logic [WIDTH-1:0] mid,
    output logic [WIDTH-1:0] hi
);

    // TODO: implement your RTL here

endmodule
