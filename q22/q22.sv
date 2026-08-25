// ===========================================================================
// q22.sv -- Grayscale (average) conversion without a divider
//
// Title: Grayscale (average) conversion without a divider
//
// Problem:
//   Given 8-bit R, G, B color channels, compute an 8-bit grayscale value
//   approximating (R+G+B)/3, WITHOUT using a true division/modulo operator
//   in the RTL. Purely combinational.
//
// Interface:
//   input  logic [7:0] r, g, b   -- color channels
//   output logic [7:0] gray      -- approximate average
//
// Required implementation technique (pinned down exactly -- this is the
// point of the exercise, not just "average the channels"):
//   gray = ((r + g + b) * 683) >> 11;
//   This is a multiply-by-reciprocal-approximation trick: 683/2048 is
//   approximately 1/3 (1/3.000488...), which is well within rounding
//   tolerance for 8-bit color, and avoids a true divider in hardware.
//   Sanity check on range: max sum = 255*3 = 765; 765*683 = 522495;
//   522495 >> 11 = 255. So the result always fits in 8 bits with no
//   overflow/saturation logic needed.
//
// Assumptions / edge cases pinned down for testability:
//   - This is purely combinational: no clk/rst on this module.
//   - The testbench's golden model uses this EXACT SAME formula (computed
//     with plain integer arithmetic), NOT a floating point or true-division
//     "ideal average". Matching the true rounded average is NOT the spec --
//     matching this exact shift-based approximation formula is.
// ===========================================================================

module q22 (
  input  logic [7:0] r,
  input  logic [7:0] g,
  input  logic [7:0] b,
  output logic [7:0] gray
);

  // TODO: implement your RTL here

endmodule
