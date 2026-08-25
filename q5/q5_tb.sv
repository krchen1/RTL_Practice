// =============================================================================
// q5_tb - Self-checking testbench for q5 (high-speed synchronous FIFO)
// =============================================================================
//
// Problem recap (see q5.sv for the full spec the DUT must satisfy):
//   Same interface as q4, but rd_data has ONE CYCLE of registered read
//   latency (word popped on cycle T appears on rd_data at cycle T+1), while
//   full/empty remain same-cycle accurate. THE HAZARD: if wr_en and rd_en
//   are both asserted while the FIFO is EMPTY, the just-written word must
//   still surface on rd_data exactly one cycle later (bypassed straight
//   from wr_data), not two cycles later.
//
// Verification approach:
//   Golden model = an independent SV queue (golden_q[$]) tracking true FIFO
//   contents, plus a separate `expected_rd_data` scalar that models the
//   registered read-data latency explicitly: whenever a pop is accepted
//   this cycle (per the same rules the DUT must implement, including the
//   empty+bypass case), we record what value must appear on rd_data
//   *starting the following cycle*, and hold that expectation until the
//   next accepted pop updates it. No second copy of the RTL is used.
//
//   A directed test drives the exact same-cycle write+read-from-empty
//   hazard and checks the 1-cycle bypass latency and the resulting empty
//   state. Randomized traffic (respecting nothing — the DUT must itself
//   implement the no-op-while-full/empty rules) is then run and checked
//   every cycle against the golden model.
// =============================================================================

module q5_tb;

    localparam DATA_WIDTH = 8;
    localparam DEPTH      = 8;

    typedef logic [DATA_WIDTH-1:0] data_t;

    logic  clk;
    logic  rst;
    logic  wr_en;
    data_t wr_data;
    logic  rd_en;
    data_t rd_data;
    logic  full;
    logic  empty;

    int errors;
    data_t golden_q[$];
    data_t expected_rd_data;
    bit    expected_rd_data_valid;

    q5 #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .clk    (clk),
        .rst    (rst),
        .wr_en  (wr_en),
        .wr_data(wr_data),
        .rd_en  (rd_en),
        .rd_data(rd_data),
        .full   (full),
        .empty  (empty)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        #200000;
        $display("TEST FAILED: TIMEOUT");
        $finish;
    end

    task automatic check_now(string tag);
        logic exp_full, exp_empty;
        exp_empty = (golden_q.size() == 0);
        exp_full  = (golden_q.size() == DEPTH);

        if (full !== exp_full) begin
            errors++;
            $display("[%0t] %s: MISMATCH full: expected=%0b actual=%0b", $time, tag, exp_full, full);
        end
        if (empty !== exp_empty) begin
            errors++;
            $display("[%0t] %s: MISMATCH empty: expected=%0b actual=%0b", $time, tag, exp_empty, empty);
        end
        if (expected_rd_data_valid) begin
            if (rd_data !== expected_rd_data) begin
                errors++;
                $display("[%0t] %s: MISMATCH rd_data: expected=%0h actual=%0h", $time, tag, expected_rd_data, rd_data);
            end
        end
    endtask

    // Drive one cycle. Mirrors exactly the accept rules the DUT must
    // implement: wr_push = wr_en && !full; rd_pop = rd_en && (!empty ||
    // (wr_en && !full))  -- the second disjunct is the same-cycle bypass
    // case (reading from empty while a write is simultaneously accepted).
    task automatic do_cycle(logic wr_en_i, data_t wr_data_i, logic rd_en_i, string tag);
        logic was_full, was_empty;
        logic wr_push, rd_pop;
        data_t popped_val;

        wr_en   = wr_en_i;
        wr_data = wr_data_i;
        rd_en   = rd_en_i;

        // check state established by the previous edge before applying new
        // effects (rd_data is registered so it's stable/expected here too)
        check_now({tag, " (pre-edge)"});
        was_full  = full;
        was_empty = empty;

        wr_push = wr_en_i && !was_full;
        rd_pop  = rd_en_i && (!was_empty || (wr_en_i && !was_full));

        if (rd_pop) begin
            popped_val = was_empty ? wr_data_i : golden_q[0];
        end

        if (wr_push) golden_q.push_back(wr_data_i);

        if (rd_pop) begin
            if (was_empty) void'(golden_q.pop_back());  // remove the entry just pushed & bypassed
            else            void'(golden_q.pop_front());
        end

        if (rd_pop) begin
            expected_rd_data       = popped_val;
            expected_rd_data_valid = 1;
        end

        @(posedge clk);
        #1;

        check_now({tag, " (post-edge)"});
    endtask

    task automatic apply_reset();
        rst     = 1;
        wr_en   = 0;
        rd_en   = 0;
        wr_data = '0;
        golden_q.delete();
        expected_rd_data_valid = 0;
        @(posedge clk);
        @(posedge clk);
        #1;
        rst = 0;
        #1;
        check_now("post-reset");
    endtask

    data_t d;

    initial begin
        errors = 0;

        apply_reset();

        // ---- Directed: THE HAZARD ----
        // From empty, write and read on the same cycle. rd_data must show
        // the written word exactly one cycle later, and empty must be true
        // again right after (write+pop cancel out in occupancy).
        do_cycle(1'b1, 8'hC7, 1'b1, "hazard-wr-rd-from-empty");
        if (!empty) begin
            errors++;
            $display("[%0t] hazard: expected empty after simultaneous wr/rd from empty, got empty=0", $time);
        end
        if (!expected_rd_data_valid || expected_rd_data !== 8'hC7) begin
            errors++;
            $display("[%0t] hazard: internal check setup error", $time);
        end
        // one more idle cycle to double check rd_data holds
        do_cycle(1'b0, 8'h00, 1'b0, "hazard-hold");

        // Repeat the hazard a few more times with different data, back to back
        do_cycle(1'b1, 8'h3D, 1'b1, "hazard-2");
        do_cycle(1'b1, 8'h91, 1'b1, "hazard-3");
        do_cycle(1'b0, 8'h00, 1'b0, "hazard-settle");

        // ---- Directed: fill to full, verify full flag timing ----
        for (int i = 0; i < DEPTH; i++) begin
            do_cycle(1'b1, data_t'(8'h20 + i), 1'b0, "fill-to-full");
        end
        if (!full) begin
            errors++;
            $display("[%0t] Expected full after filling %0d entries", $time, DEPTH);
        end
        // attempted write while full: no-op
        do_cycle(1'b1, 8'hEE, 1'b0, "write-while-full");

        // drain to empty, checking registered read data throughout
        for (int i = 0; i < DEPTH; i++) begin
            do_cycle(1'b0, 8'h00, 1'b1, "drain-to-empty");
        end
        // allow the last registered read to appear
        do_cycle(1'b0, 8'h00, 1'b0, "drain-flush");
        if (!empty) begin
            errors++;
            $display("[%0t] Expected empty after draining", $time);
        end
        // attempted read while truly empty (no simultaneous write): no-op
        do_cycle(1'b0, 8'h00, 1'b1, "read-while-empty");

        // ---- Randomized traffic (includes chances to re-hit the hazard) ----
        for (int i = 0; i < 4000; i++) begin
            logic w, r;
            w = $urandom_range(0, 99) < 55;
            r = $urandom_range(0, 99) < 45;
            d = data_t'($urandom());
            do_cycle(w, d, r, "random");
        end

        // drain fully at the end
        for (int i = 0; i < DEPTH + 2; i++) begin
            do_cycle(1'b0, 8'h00, 1'b1, "final-drain");
        end
        do_cycle(1'b0, 8'h00, 1'b0, "final-check");
        if (!empty) begin
            errors++;
            $display("[%0t] Expected empty at end of test", $time);
        end

        if (errors == 0) begin
            $display("TEST PASSED");
        end else begin
            $display("TEST FAILED: %0d error(s)", errors);
        end
        $finish;
    end

endmodule
