// =============================================================================
// q9_tb - Self-checking testbench for q9 (Asynchronous FIFO)
// =============================================================================
//
// Problem recap (see q9.sv for the full spec the DUT must satisfy):
//   Dual-clock FIFO: wr_clk/wr_rst/wr_en/wr_data/full on the write side,
//   rd_clk/rd_rst/rd_en/rd_data/empty on the read side, gray-coded
//   synchronized pointers, DEPTH a power of two. wr_en while full and rd_en
//   while empty are no-ops. rd_data is combinational FWFT.
//
// Verification approach:
//   wr_clk and rd_clk are two independent, free-running clocks with
//   different, non-integer-multiple periods (6ns and 11ns) and independent
//   resets. A producer process (on wr_clk) drives randomized wr_en,
//   respecting full, and records every value it successfully pushes, in
//   order, into golden_wr_seq[$]. A consumer process (on rd_clk) drives
//   randomized rd_en, respecting empty, and records every value it
//   successfully pops (sampled from the combinational rd_data right before
//   the pop takes effect), in order, into golden_rd_seq[$]. These run
//   concurrently. After both stop driving new stimulus, the FIFO is
//   drained completely (rd_en held while !empty), which also naturally
//   waits out the CDC synchronizer latency. Finally, golden_wr_seq is
//   compared element-by-element against golden_rd_seq: an asynchronous
//   FIFO's core correctness contract is that read order == write order,
//   even though the two sides run on unrelated clocks. No second copy of
//   the RTL under test is instantiated anywhere in this checking process.
// =============================================================================

module q9_tb;

    localparam DATA_WIDTH = 8;
    localparam DEPTH      = 8;

    typedef logic [DATA_WIDTH-1:0] data_t;

    logic  wr_clk, wr_rst, wr_en;
    data_t wr_data;
    logic  full;

    logic  rd_clk, rd_rst, rd_en;
    data_t rd_data;
    logic  empty;

    int errors;
    data_t golden_wr_seq[$];
    data_t golden_rd_seq[$];

    bit wr_rst_done, rd_rst_done;

    q9 #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .wr_clk (wr_clk),
        .wr_rst (wr_rst),
        .wr_en  (wr_en),
        .wr_data(wr_data),
        .full   (full),
        .rd_clk (rd_clk),
        .rd_rst (rd_rst),
        .rd_en  (rd_en),
        .rd_data(rd_data),
        .empty  (empty)
    );

    // two independent free-running clocks, non-integer-multiple periods
    initial wr_clk = 0;
    always #3 wr_clk = ~wr_clk;      // 6 ns period

    initial rd_clk = 0;
    always #5.5 rd_clk = ~rd_clk;    // 11 ns period

    // independent resets, each held for the first few edges of its own domain
    initial begin
        wr_rst = 1;
        wr_en  = 0;
        wr_data = '0;
        repeat (3) @(posedge wr_clk);
        #1;
        wr_rst = 0;
        wr_rst_done = 1;
    end

    initial begin
        rd_rst = 1;
        rd_en  = 0;
        repeat (3) @(posedge rd_clk);
        #1;
        rd_rst = 0;
        rd_rst_done = 1;
    end

    // watchdog
    initial begin
        #2_000_000;
        $display("TEST FAILED: TIMEOUT");
        $finish;
    end

    // cheap continuous sanity check: full and empty must never both be 1
    // (not part of the core ordering check, but essentially free to verify)
    always @(posedge wr_clk) begin
        if (!wr_rst && full && empty) begin
            errors++;
            $display("[%0t] MISMATCH: full and empty both asserted simultaneously", $time);
        end
    end

    task automatic wr_driver(int n);
        data_t d;
        logic  push;
        for (int i = 0; i < n; i++) begin
            push = (!full) && ($urandom_range(0, 99) < 70);
            d = push ? data_t'($urandom()) : '0;
            wr_en   = push;
            wr_data = d;
            if (push) golden_wr_seq.push_back(d);
            @(posedge wr_clk);
            #1;
        end
        wr_en = 0;
    endtask

    task automatic rd_driver(int n);
        logic pop;
        for (int i = 0; i < n; i++) begin
            pop = (!empty) && ($urandom_range(0, 99) < 60);
            rd_en = pop;
            if (pop) golden_rd_seq.push_back(rd_data);
            @(posedge rd_clk);
            #1;
        end
        rd_en = 0;
    endtask

    initial begin
        errors = 0;

        wait (wr_rst_done && rd_rst_done);
        #1;

        // run producer and consumer concurrently on their own independent
        // clocks for a substantial number of cycles each
        fork
            wr_driver(500);
            rd_driver(700);
        join

        // final drain: keep clocking rd_clk with rd_en asserted while
        // !empty, both to pop any remaining words and to ride out the CDC
        // synchronizer latency for the last few writes to become visible
        begin : drain_block
            int drain_cycles;
            drain_cycles = 0;
            while (!empty && drain_cycles < 5000) begin
                rd_en = 1;
                golden_rd_seq.push_back(rd_data);
                @(posedge rd_clk);
                #1;
                drain_cycles++;
            end
            rd_en = 0;
            if (drain_cycles >= 5000) begin
                errors++;
                $display("[%0t] MISMATCH: FIFO never drained to empty (possible stuck full/empty or lost pointer sync)", $time);
            end
        end

        // a few extra idle cycles for good measure
        repeat (5) @(posedge rd_clk);

        // ---- final ordered-sequence comparison ----
        if (golden_wr_seq.size() != golden_rd_seq.size()) begin
            errors++;
            $display("[%0t] MISMATCH: %0d words written but %0d words read out", $time, golden_wr_seq.size(), golden_rd_seq.size());
        end
        begin
            int n;
            n = (golden_wr_seq.size() < golden_rd_seq.size()) ? golden_wr_seq.size() : golden_rd_seq.size();
            for (int i = 0; i < n; i++) begin
                if (golden_wr_seq[i] !== golden_rd_seq[i]) begin
                    errors++;
                    $display("[%0t] MISMATCH at sequence index %0d: expected=%0h actual=%0h", $time, i, golden_wr_seq[i], golden_rd_seq[i]);
                end
            end
        end

        if (golden_wr_seq.size() == 0) begin
            errors++;
            $display("[%0t] MISMATCH: test produced zero writes -- test itself is broken", $time);
        end

        if (errors == 0) begin
            $display("TEST PASSED");
        end else begin
            $display("TEST FAILED: %0d error(s)", errors);
        end
        $finish;
    end

endmodule
