// =============================================================================
// q5 - High-speed synchronous FIFO (registered read, same-cycle write/read
//      bypass hazard)
// =============================================================================
//
// Problem:
//   This is the "make it fast" version of q4's FIFO. Same parameters and
//   port list as q4, but with a REGISTERED (flip-flop-output / synchronous
//   read) data path instead of q4's combinational FWFT read, which is what
//   lets a real implementation hit a much higher clock frequency (no long
//   combinational path from the read pointer, through the memory array, out
//   to rd_data). This registration introduces a subtle same-cycle
//   write/read hazard that is the actual design problem this question is
//   testing (see point 3 below) — that is the interesting part, not the
//   FIFO bookkeeping itself.
//
// Interface (identical to q4):
//   parameter DATA_WIDTH = 8    // width of each data word, in bits
//   parameter DEPTH      = 16   // number of entries. ASSUMPTION: power of two.
//
//   input  logic                   clk
//   input  logic                   rst       // synchronous, active-high
//   input  logic                   wr_en
//   input  logic [DATA_WIDTH-1:0]  wr_data
//   input  logic                   rd_en
//   output logic [DATA_WIDTH-1:0]  rd_data
//   output logic                   full
//   output logic                   empty
//
// Behavioral differences from q4 (READ THIS CAREFULLY):
//
//   1. REGISTERED READ LATENCY: rd_data is NOT combinational. When rd_en is
//      asserted on a cycle where !empty, the word being popped appears on
//      rd_data on the NEXT clock edge (one cycle of latency), not
//      immediately/combinationally the same cycle as in q4. This models
//      reading out of a synchronous-read memory (a real flip-flop-output
//      array/SRAM), which is required to reach high Fmax.
//
//   2. full/empty ARE STILL SAME-CYCLE ACCURATE: even though the read data
//      path now has latency, full and empty must still be exact,
//      same-cycle-accurate reflections of true occupancy, functionally
//      identical (from a testbench's point of view) to q4's full/empty
//      timing. (Internally you would typically compute these from
//      registered pointers with next-state look-ahead so they update
//      exactly on the same edge as the pointers — but externally the
//      contract is identical to q4.)
//
//   3. THE HAZARD THIS QUESTION IS TESTING: because reads are now
//      registered/latent, a naive implementation would take 2 cycles (1
//      cycle for a write to land in the memory array, plus 1 more cycle for
//      the registered read to surface it) before a newly-written word could
//      be read back out. Required behavior: if wr_en and rd_en are BOTH
//      asserted on a cycle where the FIFO is currently EMPTY (i.e. you are
//      writing a brand-new word in and trying to read it back out on that
//      very same cycle), rd_data must still show that new word exactly ONE
//      cycle later — the SAME 1-cycle latency as any other read — NOT two
//      cycles later. A naive synchronous-read memory would not yet have
//      captured the just-written word in time to serve it, so you need an
//      explicit bypass/forwarding path that routes wr_data directly around
//      the memory array into the registered read-data path for exactly this
//      case.
//
// Other behaviors carried over unchanged from q4:
//   - wr_en while full is a no-op (write ignored, full stays asserted).
//   - rd_en while empty (and NOT simultaneously bypassing a same-cycle
//     write, per point 3) is a no-op.
//   - Synchronous, active-high reset clears all internal state to empty.
//   - Simultaneous wr_en & rd_en while neither full nor empty: both the
//     write and the pop happen that cycle (normal case, occupancy net
//     unchanged); the popped word (the OLD head, not the new one just
//     written) surfaces on rd_data one cycle later, same as any other pop.
//
// =============================================================================

module q5 #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH      = 16
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

    // TODO: implement your RTL here

endmodule
