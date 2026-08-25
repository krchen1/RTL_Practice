// =============================================================================
// q24_tb - Self-checking testbench for q24 (SVA monitor for a sync FIFO)
// =============================================================================
//
// Problem recap (see q24.sv for the full spec): q24 is a passive monitor
// bound to a synchronous FIFO's externally-visible interface (clk, rst,
// wr_en, rd_en, full, empty, wr_data, rd_data). It has no outputs; it
// exposes pass/fail state through a plain `int errors` variable read back
// hierarchically.
//
// This testbench is structurally different from the others in this set,
// because there is no independent "golden model" to check a FIFO
// implementation against here -- the thing under test IS the assertion set
// itself. So this file does the ONE deliberate exception to "don't put a
// second RTL copy in the testbench": it defines two small, self-contained
// reference FIFOs directly in this file, purely as things for the
// student's monitor to watch:
//
//   ref_fifo_good   - a simple, provably correct FIFO (same semantics as
//                      q4: combinational FWFT read, sync active-high reset,
//                      wr_en-while-full and rd_en-while-empty are no-ops).
//   ref_fifo_buggy  - a second FIFO with ONE deliberate, classic bug: its
//                      `full` flag is computed one entry too late (an
//                      off-by-one on the full-detect comparison), which
//                      lets one extra write land past true capacity and
//                      silently overwrite the oldest un-popped entry.
//
// Two-phase structure:
//   PHASE 1 (legal traffic): instantiate ref_fifo_good and a q24 monitor
//   instance wired to it. Drive a substantial randomized, but always LEGAL
//   (never wr_en while its full is 1, never rd_en while its empty is 1),
//   write/read sequence. Since this FIFO is provably correct, this phase
//   must produce ZERO assertion failures. Record legal_phase_errors = that
//   monitor instance's `.errors`.
//
//   PHASE 2 (bug injection): instantiate ref_fifo_buggy and a SECOND q24
//   monitor instance wired to it. Drive traffic that fills it completely
//   and then issues extra write attempts, which the bug allows past
//   capacity. This MUST produce at least one assertion failure -- that's
//   the proof the student's assertions actually catch a real bug and are
//   not just decorative code that never fires. Record bug_phase_errors =
//   that second monitor instance's `.errors`.
//
// Final verdict: TEST PASSED iff legal_phase_errors == 0 AND
// bug_phase_errors > 0.
// =============================================================================

// ---- reference FIFO #1: correct (same semantics as q4) ----
module ref_fifo_good #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH      = 8
) (
    input  logic                  clk,
    input  logic                  rst,
    input  logic                  wr_en,
    input  logic [DATA_WIDTH-1:0] wr_data,
    input  logic                  rd_en,
    output logic [DATA_WIDTH-1:0] rd_data,
    output logic                  full,
    output logic                  empty
);
    localparam AW = $clog2(DEPTH);
    logic [AW:0] wr_ptr, rd_ptr;
    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    assign full  = (wr_ptr[AW] != rd_ptr[AW]) && (wr_ptr[AW-1:0] == rd_ptr[AW-1:0]);
    assign empty = (wr_ptr == rd_ptr);
    assign rd_data = mem[rd_ptr[AW-1:0]];

    always_ff @(posedge clk) begin
        if (rst) begin
            wr_ptr <= '0;
            rd_ptr <= '0;
        end else begin
            if (wr_en && !full) begin
                mem[wr_ptr[AW-1:0]] <= wr_data;
                wr_ptr <= wr_ptr + 1'b1;
            end
            if (rd_en && !empty) begin
                rd_ptr <= rd_ptr + 1'b1;
            end
        end
    end
endmodule

// ---- reference FIFO #2: deliberately buggy (off-by-one full detect) ----
module ref_fifo_buggy #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH      = 8
) (
    input  logic                  clk,
    input  logic                  rst,
    input  logic                  wr_en,
    input  logic [DATA_WIDTH-1:0] wr_data,
    input  logic                  rd_en,
    output logic [DATA_WIDTH-1:0] rd_data,
    output logic                  full,
    output logic                  empty
);
    localparam AW = $clog2(DEPTH);
    logic [AW:0] wr_ptr, rd_ptr;
    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // BUG: full asserts one entry too late, allowing one extra write past
    // true capacity (silent overwrite of the oldest un-popped entry).
    assign full  = (wr_ptr[AW] != rd_ptr[AW]) && (wr_ptr[AW-1:0] == (rd_ptr[AW-1:0] + 1'b1));
    assign empty = (wr_ptr == rd_ptr);
    assign rd_data = mem[rd_ptr[AW-1:0]];

    always_ff @(posedge clk) begin
        if (rst) begin
            wr_ptr <= '0;
            rd_ptr <= '0;
        end else begin
            if (wr_en && !full) begin
                mem[wr_ptr[AW-1:0]] <= wr_data;
                wr_ptr <= wr_ptr + 1'b1;
            end
            if (rd_en && !empty) begin
                rd_ptr <= rd_ptr + 1'b1;
            end
        end
    end
endmodule

module q24_tb;

    localparam DATA_WIDTH = 8;
    localparam DEPTH      = 8;

    logic clk;
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        #500000;
        $display("TEST FAILED: TIMEOUT");
        $finish;
    end

    // ---- Phase 1 wiring: good FIFO + monitor ----
    logic                  rst_g, wr_en_g, rd_en_g, full_g, empty_g;
    logic [DATA_WIDTH-1:0] wr_data_g, rd_data_g;

    ref_fifo_good #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) dut_good (
        .clk(clk), .rst(rst_g),
        .wr_en(wr_en_g), .wr_data(wr_data_g),
        .rd_en(rd_en_g), .rd_data(rd_data_g),
        .full(full_g), .empty(empty_g)
    );

    q24 #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) mon_good (
        .clk(clk), .rst(rst_g),
        .wr_en(wr_en_g), .rd_en(rd_en_g),
        .full(full_g), .empty(empty_g),
        .wr_data(wr_data_g), .rd_data(rd_data_g)
    );

    // ---- Phase 2 wiring: buggy FIFO + monitor ----
    logic                  rst_b, wr_en_b, rd_en_b, full_b, empty_b;
    logic [DATA_WIDTH-1:0] wr_data_b, rd_data_b;

    ref_fifo_buggy #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) dut_bad (
        .clk(clk), .rst(rst_b),
        .wr_en(wr_en_b), .wr_data(wr_data_b),
        .rd_en(rd_en_b), .rd_data(rd_data_b),
        .full(full_b), .empty(empty_b)
    );

    q24 #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) mon_bad (
        .clk(clk), .rst(rst_b),
        .wr_en(wr_en_b), .rd_en(rd_en_b),
        .full(full_b), .empty(empty_b),
        .wr_data(wr_data_b), .rd_data(rd_data_b)
    );

    int legal_phase_errors;
    int bug_phase_errors;

    task automatic drive_good(int n);
        for (int i = 0; i < n; i++) begin
            wr_en_g   = (!full_g)  && ($urandom_range(0, 99) < 60);
            wr_data_g = 8'($urandom());
            rd_en_g   = (!empty_g) && ($urandom_range(0, 99) < 50);
            @(posedge clk);
            #1;
        end
        wr_en_g = 0;
        rd_en_g = 0;
    endtask

    initial begin
        // ---- reset both instances at the start ----
        rst_g = 1; wr_en_g = 0; rd_en_g = 0; wr_data_g = '0;
        rst_b = 1; wr_en_b = 0; rd_en_b = 0; wr_data_b = '0;
        repeat (3) @(posedge clk);
        #1;
        rst_g = 0;
        rst_b = 0;
        #1;

        // ============ PHASE 1: legal traffic on the good FIFO ============
        drive_good(3000);
        // let a couple settle cycles pass
        repeat (3) @(posedge clk);
        #1;
        legal_phase_errors = mon_good.errors;

        // ============ PHASE 2: bug injection on the buggy FIFO ============
        // Fill completely (per the buggy FIFO's own, incorrect, full flag)
        // and then keep issuing writes for a couple extra cycles: because
        // full is late by one, this drives one write past true capacity.
        for (int i = 0; i < DEPTH + 3; i++) begin
            wr_en_b   = !full_b;
            wr_data_b = 8'(i + 1);
            rd_en_b   = 0;
            @(posedge clk);
            #1;
        end
        wr_en_b = 0;
        repeat (3) @(posedge clk);
        #1;
        bug_phase_errors = mon_bad.errors;

        if (legal_phase_errors == 0 && bug_phase_errors > 0) begin
            $display("TEST PASSED");
        end else begin
            $display("TEST FAILED: %0d error(s) in legal phase, %0d error(s) detected in bug-injection phase (expected 0 and >0 respectively)",
                      legal_phase_errors, bug_phase_errors);
        end
        $finish;
    end

endmodule
