// =============================================================================
// q21_tb - Self-checking testbench for the first-set-bit / popcount unit.
//   DO NOT EDIT. See q21.sv for the full problem statement.
// =============================================================================
// Problem (summary):
//   Combinational: valid = (data != 0); first_set_idx = index of the
//   least-significant set bit (only meaningful when valid); popcount =
//   number of set bits (0..32).
//
// Verification approach:
//   Golden model computed with a simple behavioral for-loop (counting bits
//   and finding the first set bit) directly in this testbench. Coverage:
//   data==0, data==all-ones, a single bit set at each of the 32 individual
//   positions (to nail down first_set_idx exactly at each boundary), and a
//   large number of random 32-bit patterns checking valid/popcount/
//   first_set_idx together.
// =============================================================================

module q21_tb;

    localparam int NUM_RANDOM = 500;

    logic [31:0] data;
    logic        valid;
    logic [4:0]  first_set_idx;
    logic [5:0]  popcount;

    int errors;

    q21 dut (
        .data          (data),
        .valid         (valid),
        .first_set_idx (first_set_idx),
        .popcount      (popcount)
    );

    function automatic int gold_popcount(input logic [31:0] d);
        int cnt;
        cnt = 0;
        for (int i = 0; i < 32; i++) begin
            if (d[i]) cnt++;
        end
        return cnt;
    endfunction

    function automatic int gold_first_set(input logic [31:0] d);
        for (int i = 0; i < 32; i++) begin
            if (d[i]) return i;
        end
        return -1; // no set bit
    endfunction

    task automatic check(logic [31:0] d);
        int exp_pc;
        int exp_fs;
        logic exp_valid;

        data = d;
        #1;

        exp_pc    = gold_popcount(d);
        exp_valid = (d != 32'd0);

        if (valid !== exp_valid) begin
            errors++;
            $display("[%0t] MISMATCH valid: data=%h expected=%0b got=%0b", $time, d, exp_valid, valid);
        end

        if (popcount !== exp_pc[5:0]) begin
            errors++;
            $display("[%0t] MISMATCH popcount: data=%h expected=%0d got=%0d", $time, d, exp_pc, popcount);
        end

        if (exp_valid) begin
            exp_fs = gold_first_set(d);
            if (first_set_idx !== exp_fs[4:0]) begin
                errors++;
                $display("[%0t] MISMATCH first_set_idx: data=%h expected=%0d got=%0d",
                          $time, d, exp_fs, first_set_idx);
            end
        end
    endtask

    initial begin
        errors = 0;

        // data == 0
        check(32'h0000_0000);

        // data == all ones
        check(32'hFFFF_FFFF);

        // single bit set at every position
        for (int i = 0; i < 32; i++) begin
            check(32'd1 << i);
        end

        // a good number of random patterns
        for (int i = 0; i < NUM_RANDOM; i++) begin
            check($urandom());
        end

        // a few more directed patterns
        check(32'h8000_0000);
        check(32'h0000_0001);
        check(32'hAAAA_AAAA);
        check(32'h5555_5555);
        check(32'h0000_00FF);
        check(32'hFF00_0000);

        if (errors == 0) begin
            $display("TEST PASSED");
        end else begin
            $display("TEST FAILED: %0d error(s)", errors);
        end
        $finish;
    end

endmodule
