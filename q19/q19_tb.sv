// ===========================================================================
// q19_tb.sv -- Self-checking testbench for q19 (DO NOT EDIT)
//
// Title: CPU pipeline datapath components (register file with
//        write-forwarding, and a generic pipeline stage register)
//
// NOTE: This is one concrete scoping of an open-ended interview question
// ("design datapath components for a CPU pipeline"); the exact interfaces
// below are what is being tested. This file covers TWO small classic
// datapath building blocks, tested together in one testbench.
//
// -------------------------------------------------------------------------
// (a) regfile32 -- 32x32 register file, 2 read ports, 1 write port
//
//   module regfile32 (
//     input  logic        clk, rst,
//     input  logic [4:0]  rs1_addr,
//     output logic [31:0] rs1_data,
//     input  logic [4:0]  rs2_addr,
//     output logic [31:0] rs2_data,
//     input  logic        we,
//     input  logic [4:0]  wr_addr,
//     input  logic [31:0] wr_data
//   );
//
//   Semantics:
//     - 32 registers x 32 bits. rs1/rs2 reads are COMBINATIONAL. The write
//       port is synchronous (registers update on posedge clk when we=1).
//     - Register 0 is hardwired to 0 (standard RISC convention): writes to
//       address 0 are ignored, and reads of address 0 always return 0.
//     - CRITICAL requirement (the actual point of this exercise):
//       WRITE-THEN-READ SAME-CYCLE FORWARDING. If we=1 this cycle, writing
//       wr_data to wr_addr, and rs1_addr (or rs2_addr) equals wr_addr this
//       SAME cycle, the corresponding read port must combinationally
//       reflect the NEW wr_data being written this cycle, not the stale
//       previously-stored value. This models the forwarding needed when an
//       instruction reads a register in the same cycle an earlier
//       instruction is writing it back.
//     - On rst: all registers clear to 0.
//
// -------------------------------------------------------------------------
// (b) pipe_reg -- generic pipeline stage register
//
//   module pipe_reg #(parameter WIDTH = 8) (
//     input  logic             clk, rst,
//     input  logic             stall,
//     input  logic             flush,
//     input  logic [WIDTH-1:0] d,
//     output logic [WIDTH-1:0] q
//   );
//
//   Semantics, each clock edge, in PRIORITY order:
//     1. rst   (highest) -> q <= 0
//     2. flush            -> q <= 0   (insert a bubble; drops d this cycle)
//     3. stall             -> q holds its current value (d ignored this cycle)
//     4. otherwise (normal)-> q <= d
//
// ===========================================================================

module q19_tb;

  // ----------------------------------------------------------------------
  // Shared clock/reset
  // ----------------------------------------------------------------------
  logic clk, rst;

  initial clk = 0;
  always #5 clk = ~clk;

  int errors;

  // Watchdog
  initial begin
    #500000;
    $display("TEST FAILED: TIMEOUT");
    $finish;
  end

  // ----------------------------------------------------------------------
  // (a) regfile32 instantiation + golden model
  // ----------------------------------------------------------------------
  logic [4:0]  rs1_addr, rs2_addr, wr_addr;
  logic [31:0] rs1_data, rs2_data, wr_data;
  logic        we;

  regfile32 rf_dut (
    .clk      (clk),
    .rst      (rst),
    .rs1_addr (rs1_addr),
    .rs1_data (rs1_data),
    .rs2_addr (rs2_addr),
    .rs2_data (rs2_data),
    .we       (we),
    .wr_addr  (wr_addr),
    .wr_data  (wr_data)
  );

  logic [31:0] gold_regs [32];

  function automatic void rf_golden_reset();
    int i;
    begin
      for (i = 0; i < 32; i++) gold_regs[i] = 32'd0;
    end
  endfunction

  // Compute expected read value combinationally (with forwarding), given
  // the CURRENT stored register state (before this cycle's write commits).
  function automatic [31:0] rf_expected_read(input [4:0] addr);
    begin
      if (addr == 5'd0) begin
        rf_expected_read = 32'd0;
      end else if (we && (wr_addr == addr) && (wr_addr != 5'd0)) begin
        rf_expected_read = wr_data; // same-cycle forwarding
      end else begin
        rf_expected_read = gold_regs[addr];
      end
    end
  endfunction

  task automatic rf_check(string tag);
    logic [31:0] exp1, exp2;
    begin
      exp1 = rf_expected_read(rs1_addr);
      exp2 = rf_expected_read(rs2_addr);
      if (rs1_data !== exp1) begin
        errors++;
        $display("[%0t] MISMATCH regfile32 (%s): rs1_addr=%0d expected=%0h actual=%0h",
                  $time, tag, rs1_addr, exp1, rs1_data);
      end
      if (rs2_data !== exp2) begin
        errors++;
        $display("[%0t] MISMATCH regfile32 (%s): rs2_addr=%0d expected=%0h actual=%0h",
                  $time, tag, rs2_addr, exp2, rs2_data);
      end
    end
  endtask

  // Commit the golden write (call right after checking, before advancing
  // past the clock edge that performs the write).
  task automatic rf_commit_write();
    begin
      if (we && wr_addr != 5'd0) begin
        gold_regs[wr_addr] = wr_data;
      end
    end
  endtask

  // ----------------------------------------------------------------------
  // (b) pipe_reg instantiation + golden model
  // ----------------------------------------------------------------------
  localparam int PW = 8;
  logic             pr_stall, pr_flush;
  logic [PW-1:0]    pr_d, pr_q;
  logic [PW-1:0]    pr_gold_q;

  pipe_reg #(.WIDTH(PW)) pr_dut (
    .clk   (clk),
    .rst   (rst),
    .stall (pr_stall),
    .flush (pr_flush),
    .d     (pr_d),
    .q     (pr_q)
  );

  task automatic pr_check(string tag);
    begin
      if (pr_q !== pr_gold_q) begin
        errors++;
        $display("[%0t] MISMATCH pipe_reg (%s): expected q=%0h actual q=%0h",
                  $time, tag, pr_gold_q, pr_q);
      end
    end
  endtask

  // ----------------------------------------------------------------------
  // Main stimulus
  // ----------------------------------------------------------------------
  initial begin
    errors    = 0;
    rs1_addr  = 0;
    rs2_addr  = 0;
    we        = 0;
    wr_addr   = 0;
    wr_data   = 0;
    pr_stall  = 0;
    pr_flush  = 0;
    pr_d      = 0;
    pr_gold_q = '0;
    rst       = 1;

    @(negedge clk);
    @(negedge clk);
    rst = 0;
    rf_golden_reset();
    @(negedge clk);

    // ---- regfile32: post-reset check (all regs should read 0) ----
    rs1_addr = 5'd0; rs2_addr = 5'd0; we = 0;
    #1;
    rf_check("post-reset both addr0");
    rs1_addr = 5'd5; rs2_addr = 5'd17;
    #1;
    rf_check("post-reset arbitrary addrs");

    // ---- regfile32: directed same-cycle forwarding cases ----
    // Write to reg 3, read reg3 on rs1 same cycle -> must forward
    we = 1; wr_addr = 5'd3; wr_data = 32'hDEAD_BEEF;
    rs1_addr = 5'd3; rs2_addr = 5'd3;
    #1;
    rf_check("forward same addr both ports");
    @(negedge clk);
    rf_commit_write();
    we = 0;
    #1;
    rf_check("after commit, stored value visible");

    // Write reg 7, but read a different addr on rs1, same addr on rs2
    we = 1; wr_addr = 5'd7; wr_data = 32'h1234_5678;
    rs1_addr = 5'd2; rs2_addr = 5'd7;
    #1;
    rf_check("forward only rs2");
    @(negedge clk);
    rf_commit_write();
    we = 0;
    #1;
    rf_check("after commit rs2-forward case");

    // Attempt write to reg0 -- must be ignored, read of reg0 always 0
    we = 1; wr_addr = 5'd0; wr_data = 32'hFFFF_FFFF;
    rs1_addr = 5'd0; rs2_addr = 5'd0;
    #1;
    rf_check("write to reg0 ignored, forwarding suppressed for reg0");
    @(negedge clk);
    rf_commit_write();
    we = 0;
    #1;
    rf_check("after attempted reg0 write, still 0");

    // Randomized regfile32 stimulus, heavy on same-cycle same-address cases
    for (int i = 0; i < 300; i++) begin
      we       = $urandom_range(0,1);
      wr_addr  = $urandom_range(0,31);
      wr_data  = $urandom;
      // Bias rs1/rs2 to sometimes match wr_addr to stress forwarding
      if ($urandom_range(0,2) == 0) rs1_addr = wr_addr;
      else                          rs1_addr = $urandom_range(0,31);
      if ($urandom_range(0,2) == 0) rs2_addr = wr_addr;
      else                          rs2_addr = $urandom_range(0,31);
      #1;
      rf_check("random");
      @(negedge clk);
      rf_commit_write();
    end
    we = 0;

    // ---- pipe_reg: directed sequence covering every combination ----
    // Normal load
    pr_flush = 0; pr_stall = 0; pr_d = 8'hAA;
    @(negedge clk);
    pr_gold_q = 8'hAA;
    pr_check("normal load AA");

    pr_d = 8'h55;
    @(negedge clk);
    pr_gold_q = 8'h55;
    pr_check("normal load 55");

    // Stall: q must hold, d ignored
    pr_stall = 1; pr_d = 8'hFF;
    @(negedge clk);
    // pr_gold_q unchanged
    pr_check("stall holds");

    pr_d = 8'h11;
    @(negedge clk);
    pr_check("stall holds again");

    // Release stall, normal load resumes
    pr_stall = 0; pr_d = 8'h77;
    @(negedge clk);
    pr_gold_q = 8'h77;
    pr_check("resume normal after stall");

    // Flush: q must clear regardless of d
    pr_flush = 1; pr_d = 8'hCC;
    @(negedge clk);
    pr_gold_q = '0;
    pr_check("flush clears");

    pr_flush = 0; pr_d = 8'h33;
    @(negedge clk);
    pr_gold_q = 8'h33;
    pr_check("normal after flush");

    // Flush while stalled: flush must win (priority order)
    pr_stall = 1; pr_flush = 1; pr_d = 8'h99;
    @(negedge clk);
    pr_gold_q = '0;
    pr_check("flush-while-stalled: flush wins");

    // Both still asserted next cycle -> stays cleared (flush still wins)
    pr_d = 8'h44;
    @(negedge clk);
    pr_gold_q = '0;
    pr_check("flush-while-stalled continued");

    // Drop flush but keep stall -> should hold (still 0)
    pr_flush = 0; pr_stall = 1; pr_d = 8'h66;
    @(negedge clk);
    pr_check("stall after flush, holds 0");

    // Release stall -> normal load
    pr_stall = 0; pr_d = 8'h66;
    @(negedge clk);
    pr_gold_q = 8'h66;
    pr_check("normal after release");

    // rst overrides everything, including flush/stall/d
    pr_stall = 1; pr_flush = 1; pr_d = 8'hE7;
    rst = 1;
    @(negedge clk);
    pr_gold_q = '0;
    pr_check("rst overrides stall+flush+d");
    rst = 0;

    // Randomized pipe_reg stimulus covering all combos
    pr_flush = 0; pr_stall = 0;
    for (int i = 0; i < 300; i++) begin
      pr_stall = $urandom_range(0,1);
      pr_flush = $urandom_range(0,1);
      pr_d     = $urandom_range(0, (1<<PW)-1);
      @(negedge clk);
      if (pr_flush)      pr_gold_q = '0;
      else if (pr_stall) pr_gold_q = pr_gold_q; // hold
      else               pr_gold_q = pr_d;
      pr_check("random pipe_reg");
    end

    if (errors == 0) begin
      $display("TEST PASSED");
    end else begin
      $display("TEST FAILED: %0d error(s)", errors);
    end
    $finish;
  end

endmodule
