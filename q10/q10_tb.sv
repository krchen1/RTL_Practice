// =============================================================================
// q10_tb - Self-checking testbench for Binary <-> Gray Code Conversion
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
//
// This testbench:
//   - Exhaustively drives all 256 values of bin_in (WIDTH=8) and checks
//     gray_out against the golden binary-to-Gray formula.
//   - Exhaustively drives all 256 values of gray_in and checks bin_out
//     against the golden Gray-to-binary formula.
//   - Performs a round-trip check: for each of the 256 bin_in values, takes
//     the DUT's gray_out and feeds it into gray_in, then checks that bin_out
//     equals the original bin_in, proving the two directions are inverses.
// =============================================================================

module q10_tb;

    localparam int WIDTH = 8;

    logic [WIDTH-1:0] bin_in;
    logic [WIDTH-1:0] gray_out;
    logic [WIDTH-1:0] gray_in;
    logic [WIDTH-1:0] bin_out;

    int errors;

    q10 #(.WIDTH(WIDTH)) dut (
        .bin_in   (bin_in),
        .gray_out (gray_out),
        .gray_in  (gray_in),
        .bin_out  (bin_out)
    );

    // Golden binary-to-Gray function
    function automatic [WIDTH-1:0] golden_bin2gray(input [WIDTH-1:0] b);
        golden_bin2gray = b ^ (b >> 1);
    endfunction

    // Golden Gray-to-binary function (cascaded XOR, MSB down to LSB)
    function automatic [WIDTH-1:0] golden_gray2bin(input [WIDTH-1:0] g);
        logic [WIDTH-1:0] b;
        b[WIDTH-1] = g[WIDTH-1];
        for (int i = WIDTH-2; i >= 0; i--) begin
            b[i] = b[i+1] ^ g[i];
        end
        golden_gray2bin = b;
    endfunction

    initial begin
        errors = 0;
        gray_in = '0;

        // 1) Exhaustive binary-to-Gray check
        for (int i = 0; i < (1 << WIDTH); i++) begin
            bin_in = i[WIDTH-1:0];
            #1;
            if (gray_out !== golden_bin2gray(bin_in)) begin
                errors++;
                $display("MISMATCH (bin2gray): bin_in=%0d (0x%0h) expected gray_out=0x%0h actual=0x%0h",
                          bin_in, bin_in, golden_bin2gray(bin_in), gray_out);
            end
        end

        // 2) Exhaustive Gray-to-binary check
        for (int i = 0; i < (1 << WIDTH); i++) begin
            gray_in = i[WIDTH-1:0];
            #1;
            if (bin_out !== golden_gray2bin(gray_in)) begin
                errors++;
                $display("MISMATCH (gray2bin): gray_in=%0d (0x%0h) expected bin_out=0x%0h actual=0x%0h",
                          gray_in, gray_in, golden_gray2bin(gray_in), bin_out);
            end
        end

        // 3) Round-trip check: bin_in -> gray_out -> gray_in -> bin_out == bin_in
        for (int i = 0; i < (1 << WIDTH); i++) begin
            bin_in = i[WIDTH-1:0];
            #1;
            gray_in = gray_out;
            #1;
            if (bin_out !== bin_in) begin
                errors++;
                $display("MISMATCH (round-trip): bin_in=%0d (0x%0h) -> gray_out=0x%0h -> gray_in -> bin_out=0x%0h (expected %0d)",
                          bin_in, bin_in, gray_out, bin_out, bin_in);
            end
        end

        if (errors == 0) begin
            $display("TEST PASSED");
        end else begin
            $display("TEST FAILED: %0d error(s)", errors);
        end
        $finish;
    end

endmodule
