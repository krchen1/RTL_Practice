// ===========================================================================
// q22_tb.sv -- Self-checking testbench for q22 (DO NOT EDIT)
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
//   - The golden model in this testbench uses the EXACT SAME formula
//     above (computed with plain integer arithmetic), NOT a floating
//     point or true-division "ideal average". Matching the true rounded
//     average is NOT the spec -- matching this exact shift-based
//     approximation formula is. The two can differ by +/-1 due to the
//     reciprocal approximation's inherent rounding error; that is
//     expected and is not a bug.
// ===========================================================================

module q22_tb;

  logic [7:0] r, g, b;
  logic [7:0] gray;

  int errors;
  int NUM_RANDOM = 2000;

  // DUT
  q22 dut (
    .r    (r),
    .g    (g),
    .b    (b),
    .gray (gray)
  );

  // Golden model: exact same shift-based approximation formula.
  function automatic [7:0] golden_gray(input [7:0] rr, gg, bb);
    int sum;
    int prod;
    begin
      sum  = rr + gg + bb;      // max 765, fits easily in int
      prod = sum * 683;         // max 522495, needs >=20 bits -> int (32b) is fine
      golden_gray = (prod >> 11) & 8'hFF;
    end
  endfunction

  task automatic check_case(input [7:0] rr, gg, bb, string tag);
    logic [7:0] exp_gray;
    begin
      r = rr; g = gg; b = bb;
      #1; // allow combinational settle
      exp_gray = golden_gray(rr, gg, bb);
      if (gray !== exp_gray) begin
        errors++;
        $display("[%0t] MISMATCH (%s): r=%0d g=%0d b=%0d : expected gray=%0d actual gray=%0d",
                  $time, tag, rr, gg, bb, exp_gray, gray);
      end
    end
  endtask

  initial begin
    errors = 0;

    // Directed edge cases
    check_case(8'd0,   8'd0,   8'd0,   "black");
    check_case(8'd255, 8'd255, 8'd255, "white");
    check_case(8'd255, 8'd0,   8'd0,   "pure red");
    check_case(8'd0,   8'd255, 8'd0,   "pure green");
    check_case(8'd0,   8'd0,   8'd255, "pure blue");
    check_case(8'd1,   8'd1,   8'd1,   "tiny");
    check_case(8'd254, 8'd254, 8'd254, "near-max");
    check_case(8'd128, 8'd128, 8'd128, "mid-gray");
    check_case(8'd0,   8'd255, 8'd255, "cyan");
    check_case(8'd255, 8'd0,   8'd255, "magenta");
    check_case(8'd255, 8'd255, 8'd0,   "yellow");
    // Values that stress rounding of 683/2048
    check_case(8'd3,   8'd0,   8'd0,   "sum=3 stress");
    check_case(8'd2,   8'd0,   8'd0,   "sum=2 stress");
    check_case(8'd1,   8'd0,   8'd0,   "sum=1 stress");
    check_case(8'd85,  8'd85,  8'd85,  "sum=255 stress");
    check_case(8'd86,  8'd85,  8'd85,  "sum=256 stress");

    // Randomized sweep
    for (int i = 0; i < NUM_RANDOM; i++) begin
      check_case($urandom_range(0,255), $urandom_range(0,255), $urandom_range(0,255), "random");
    end

    if (errors == 0) begin
      $display("TEST PASSED");
    end else begin
      $display("TEST FAILED: %0d error(s)", errors);
    end
    $finish;
  end

endmodule
