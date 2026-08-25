// =============================================================================
// q10 - Binary <-> Gray Code Conversion
// =============================================================================
// Problem:
//   Implement a purely combinational module that performs BOTH directions of
//   binary/Gray-code conversion at once, using two completely independent
//   input/output pairs:
//     1) bin_in  -> gray_out   (binary-to-Gray)
//     2) gray_in -> bin_out    (Gray-to-binary)
//   These two conversions do not have to round-trip against each other since
//   they use separate ports (bin_in is unrelated to gray_in), but each
//   direction individually must implement the standard conversion formula
//   below, and therefore the two directions ARE true inverses of one another
//   (feeding gray_out back into gray_in must reproduce the original bin_in).
//
// Interface:
//   parameter WIDTH          : bit width of all four ports (default 8)
//   input  logic [WIDTH-1:0] bin_in    : binary input
//   output logic [WIDTH-1:0] gray_out  : Gray-code encoding of bin_in
//   input  logic [WIDTH-1:0] gray_in   : Gray-code input
//   output logic [WIDTH-1:0] bin_out   : binary decoding of gray_in
//
// Assumptions / edge-case behavior:
//   - Combinational only: no clk/rst.
//   - Binary-to-Gray:  gray_out = bin_in ^ (bin_in >> 1)
//   - Gray-to-binary (cascaded XOR from MSB down to LSB):
//       bin_out[WIDTH-1] = gray_in[WIDTH-1]
//       bin_out[i]       = bin_out[i+1] ^ gray_in[i]   for i = WIDTH-2 downto 0
//   - The two directions are independent datapaths sharing one module, but
//     because each implements the standard formula, applying gray_out back
//     onto gray_in must yield bin_out == the original bin_in for every value.
// =============================================================================

module q10 #(
    parameter WIDTH = 8
) (
    input  logic [WIDTH-1:0] bin_in,
    output logic [WIDTH-1:0] gray_out,
    input  logic [WIDTH-1:0] gray_in,
    output logic [WIDTH-1:0] bin_out
);

    // TODO: implement your RTL here

endmodule
