// =============================================================================
// q12_tb - Self-checking testbench for 4:1 MUX built from 2:1 MUXes
// =============================================================================
// Problem:
//   Implement a 4:1 multiplexer, but you may NOT use raw ternary (?:),
//   case/casez, or array-indexing-with-select on the datapath. You must
//   build it ONLY out of instances of the given `mux2` helper module below
//   (already implemented for you -- do not modify it), arranged as a tree:
//     - one mux2 selects between d[1] and d[0] using sel[0]
//     - a second mux2 selects between d[3] and d[2] using sel[0]
//     - a third mux2 selects between the two results above using sel[1]
//
//   This constraint is an HONOR-SYSTEM instruction: the testbench can only
//   mechanically check y == d[sel] for every case, it cannot verify you
//   didn't sneak in a raw ternary/case. Follow the "only mux2 instances,
//   built as a tree of three" rule honestly -- that is the point of the
//   exercise (it's how real 4:1 muxes are built from standard-cell 2:1
//   mux primitives).
//
// Given helper module (fully implemented, do not modify):
//   module mux2(input logic sel, input logic d0, input logic d1,
//               output logic y);
//     assign y = sel ? d1 : d0;
//   endmodule
//
// Interface:
//   input  logic [3:0] d    : four 1-bit data inputs, d[0]..d[3]
//   input  logic [1:0] sel  : select, chooses which d[sel] to output
//   output logic       y    : selected data bit
//
// Assumptions / edge-case behavior:
//   - Combinational only: no clk/rst.
//   - y == d[sel] for every value of sel (0,1,2,3) and every value of d.
//   - Build the mux using exactly a 3-instance mux2 tree as described above.
//
// This testbench exhaustively checks all 4 values of sel crossed with all 16
// values of d (64 total cases), verifying y == d[sel] every time.
// =============================================================================

module q12_tb;

    logic [3:0] d;
    logic [1:0] sel;
    logic       y;

    int errors;

    q12 dut (
        .d   (d),
        .sel (sel),
        .y   (y)
    );

    initial begin
        errors = 0;

        for (int di = 0; di < 16; di++) begin
            for (int si = 0; si < 4; si++) begin
                d   = di[3:0];
                sel = si[1:0];
                #1;

                if (y !== d[sel]) begin
                    errors++;
                    $display("MISMATCH: d=%04b sel=%0d expected=%0b actual=%0b", d, sel, d[sel], y);
                end
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
