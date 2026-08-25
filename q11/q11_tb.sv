// =============================================================================
// q11_tb - Self-checking testbench for NAND, XOR, NOT built from 2:1 MUXes
// =============================================================================
// Problem:
//   Implement three single-bit logic functions (NOT, XOR, NAND) of inputs
//   a and b, but you may NOT use raw gate primitives or bitwise/logical
//   operators (&, |, ^, ~, &&, ||, !, ?:, case, etc.) anywhere on the
//   datapath. You must build every function ONLY out of instances of the
//   given `mux2` helper module below (already implemented for you -- do not
//   modify it). Instantiate mux2 one or more times per function, chaining
//   instances together as needed (an intermediate signal produced by one
//   mux2 instance may feed the select or data inputs of another).
//
//   This constraint is an HONOR-SYSTEM instruction: the testbench can only
//   mechanically check the resulting truth tables, it cannot verify you
//   didn't sneak in a raw operator. Follow the "only mux2 instances" rule
//   honestly -- that is the actual point of the exercise.
//
//   Hints:
//     NOT(a)      = mux2(sel=a, d0=1'b1, d1=1'b0)
//     XOR(a,b)    = mux2(sel=a, d0=b,    d1=NOT(b))   -- needs NOT(b) from
//                   a second mux2 instance
//     NAND(a,b)   = mux2(sel=a, d0=1'b1, d1=NOT(b))   -- reuse a NOT(b) mux2
//
// Given helper module (fully implemented, do not modify):
//   module mux2(input logic sel, input logic d0, input logic d1,
//               output logic y);
//     assign y = sel ? d1 : d0;
//   endmodule
//
// Interface:
//   input  logic a, b       : single-bit operands
//   output logic y_not      : NOT(a)        (does not depend on b)
//   output logic y_xor      : a XOR b
//   output logic y_nand     : NAND(a,b) = NOT(a AND b)
//
// Assumptions / edge-case behavior:
//   - Combinational only: no clk/rst.
//   - y_not must equal !a regardless of b.
//   - Build every output using only mux2 instances (see constraint above).
//
// This testbench exhaustively checks all 4 combinations of (a,b) against the
// golden truth tables: y_not == !a, y_xor == a^b, y_nand == ~(a&b).
// =============================================================================

module q11_tb;

    logic a, b;
    logic y_not, y_xor, y_nand;

    int errors;

    q11 dut (
        .a      (a),
        .b      (b),
        .y_not  (y_not),
        .y_xor  (y_xor),
        .y_nand (y_nand)
    );

    initial begin
        errors = 0;

        for (int ai = 0; ai < 2; ai++) begin
            for (int bi = 0; bi < 2; bi++) begin
                a = ai[0];
                b = bi[0];
                #1;

                if (y_not !== !a) begin
                    errors++;
                    $display("MISMATCH (y_not): a=%0b b=%0b expected=%0b actual=%0b", a, b, !a, y_not);
                end

                if (y_xor !== (a ^ b)) begin
                    errors++;
                    $display("MISMATCH (y_xor): a=%0b b=%0b expected=%0b actual=%0b", a, b, (a ^ b), y_xor);
                end

                if (y_nand !== ~(a & b)) begin
                    errors++;
                    $display("MISMATCH (y_nand): a=%0b b=%0b expected=%0b actual=%0b", a, b, ~(a & b), y_nand);
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
