// ===========================================================================
// q19.sv -- CPU pipeline datapath components (register file with
//           write-forwarding, and a generic pipeline stage register)
//
// NOTE: This is one concrete scoping of an open-ended interview question
// ("design datapath components for a CPU pipeline"); the exact interfaces
// below are what is being tested. This file covers TWO small classic
// datapath building blocks.
//
// -------------------------------------------------------------------------
// (a) regfile32 -- 32x32 register file, 2 read ports, 1 write port
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
//   Semantics, each clock edge, in PRIORITY order:
//     1. rst   (highest) -> q <= 0
//     2. flush            -> q <= 0   (insert a bubble; drops d this cycle)
//     3. stall             -> q holds its current value (d ignored this cycle)
//     4. otherwise (normal)-> q <= d
//
// ===========================================================================

module regfile32 (
  input  logic        clk,
  input  logic        rst,
  input  logic [4:0]  rs1_addr,
  output logic [31:0] rs1_data,
  input  logic [4:0]  rs2_addr,
  output logic [31:0] rs2_data,
  input  logic        we,
  input  logic [4:0]  wr_addr,
  input  logic [31:0] wr_data
);

  // TODO: implement your RTL here

endmodule


module pipe_reg #(
  parameter WIDTH = 8
) (
  input  logic             clk,
  input  logic             rst,
  input  logic             stall,
  input  logic             flush,
  input  logic [WIDTH-1:0] d,
  output logic [WIDTH-1:0] q
);

  // TODO: implement your RTL here

endmodule
