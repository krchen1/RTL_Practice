// =============================================================================
// q4_tb - Self-checking testbench for q4 (Synchronous FIFO, generic depth)
// =============================================================================
//
// Problem recap (see q4.sv for the full spec the DUT must satisfy):
//   Single-clock-domain FIFO. Parameters DATA_WIDTH, DEPTH (power of two).
//   Ports: clk, rst (sync active-high), wr_en, wr_data, rd_en, rd_data,
//   full, empty. wr_en while full = no-op. rd_en while empty = no-op.
//   rd_data is FIRST-WORD-FALL-THROUGH (combinational head-of-queue value).
//   full/empty are combinational, same-cycle-accurate.
//
// Verification approach:
//   The golden/expected model is an independent SystemVerilog queue
//   (golden_q[$]) with NO instantiation of a second copy of the RTL under
//   test. Each cycle we:
//     1. Sample the DUT's full/empty *before* the upcoming clock edge (these
//        reflect the state established by the previous edge, and are stable
//        combinational outputs at this point).
//     2. Decide, using those same pre-edge full/empty values, whether the
//        stimulus about to be applied will actually cause a push/pop
//        (mirroring the "no-op while full/empty" rule the DUT must obey).
//     3. Advance the golden queue accordingly, wait for the clock edge, then
//        compare the DUT's new full, empty, and rd_data against the queue.
//
//   Directed scenarios: fill to full, attempted write while full, drain to
//   empty, attempted read while empty, simultaneous wr_en & rd_en while
//   neither full nor empty. Then randomized wr_en/rd_en traffic for many
//   cycles, checked every cycle.
// =============================================================================

module q4_tb;

    localparam DATA_WIDTH = 8;
    localparam DEPTH      = 8;   // smaller than the RTL default so full/empty
                                  // are reached quickly and often in tests

    typedef logic [DATA_WIDTH-1:0] data_t;

    logic                  clk;
    logic                  rst;
    logic                  wr_en;
    data_t                 wr_data;
    logic                  rd_en;
    data_t                 rd_data;
    logic                  full;
    logic                  empty;

    int errors;
    data_t golden_q[$];

    q4 #(
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

    // clock
    initial clk = 0;
    always #5 clk = ~clk;

    // watchdog
    initial begin
        #200000;
        $display("TEST FAILED: TIMEOUT");
        $finish;
    end

    // Drive one cycle's worth of stimulus and check the resulting DUT
    // outputs against the golden model. `check_rd_data_now` additionally
    // checks rd_data / full / empty combinationally *before* applying new
    // stimulus (i.e. against the currently-settled golden state).
    task automatic check_now(string tag);
        logic exp_full, exp_empty;
        data_t exp_rd_data;
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
        if (!exp_empty) begin
            exp_rd_data = golden_q[0];
            if (rd_data !== exp_rd_data) begin
                errors++;
                $display("[%0t] %s: MISMATCH rd_data: expected=%0h actual=%0h", $time, tag, exp_rd_data, rd_data);
            end
        end
    endtask

    task automatic do_cycle(logic wr_en_i, data_t wr_data_i, logic rd_en_i, string tag);
        logic was_full, was_empty;
        // apply stimulus for the upcoming edge
        wr_en   = wr_en_i;
        wr_data = wr_data_i;
        rd_en   = rd_en_i;

        // pre-edge flags: settled from the previous edge, checked now
        check_now({tag, " (pre-edge)"});
        was_full  = full;
        was_empty = empty;

        // predict golden update
        if (wr_en_i && !was_full) golden_q.push_back(wr_data_i);
        if (rd_en_i && !was_empty) void'(golden_q.pop_front());

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
        @(posedge clk);
        @(posedge clk);
        #1;
        rst = 0;
        #1;
        check_now("post-reset");
    endtask

    data_t rnd_data;

    initial begin
        errors = 0;

        apply_reset();

        // ---- Directed: fill to full ----
        for (int i = 0; i < DEPTH; i++) begin
            rnd_data = data_t'(i + 8'h10);
            do_cycle(1'b1, rnd_data, 1'b0, "fill-to-full");
        end
        if (!full) begin
            errors++;
            $display("[%0t] Expected FIFO full after filling %0d entries, but full=0", $time, DEPTH);
        end

        // ---- Directed: attempted write while full (must be no-op) ----
        do_cycle(1'b1, 8'hEE, 1'b0, "write-while-full");
        do_cycle(1'b1, 8'hEF, 1'b0, "write-while-full-2");

        // ---- Directed: drain to empty ----
        for (int i = 0; i < DEPTH; i++) begin
            do_cycle(1'b0, 8'h00, 1'b1, "drain-to-empty");
        end
        if (!empty) begin
            errors++;
            $display("[%0t] Expected FIFO empty after draining, but empty=0", $time);
        end

        // ---- Directed: attempted read while empty (must be no-op) ----
        do_cycle(1'b0, 8'h00, 1'b1, "read-while-empty");
        do_cycle(1'b0, 8'h00, 1'b1, "read-while-empty-2");

        // ---- Directed: simultaneous wr_en & rd_en while neither full nor empty ----
        // prime with a couple entries first
        do_cycle(1'b1, 8'hA0, 1'b0, "prime-1");
        do_cycle(1'b1, 8'hA1, 1'b0, "prime-2");
        for (int i = 0; i < 4; i++) begin
            rnd_data = data_t'(8'hB0 + i);
            do_cycle(1'b1, rnd_data, 1'b1, "simul-wr-rd");
        end
        // drain whatever remains from this directed block
        while (!empty) begin
            do_cycle(1'b0, 8'h00, 1'b1, "drain-after-simul");
        end

        // ---- Randomized traffic ----
        for (int i = 0; i < 3000; i++) begin
            logic w, r;
            data_t d;
            w = $urandom_range(0, 99) < 55; // biased toward writing to hit full
            r = $urandom_range(0, 99) < 45;
            d = data_t'($urandom());
            do_cycle(w, d, r, "random");
        end

        // fully drain and verify final state
        while (!empty) begin
            do_cycle(1'b0, 8'h00, 1'b1, "final-drain");
        end
        do_cycle(1'b0, 8'h00, 1'b0, "final-check");

        if (errors == 0) begin
            $display("TEST PASSED");
        end else begin
            $display("TEST FAILED: %0d error(s)", errors);
        end
        $finish;
    end

endmodule
