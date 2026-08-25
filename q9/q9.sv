// =============================================================================
// q9 - Asynchronous (dual-clock-domain) FIFO
// =============================================================================
//
// Problem:
//   Implement a FIFO whose write side and read side are driven by two
//   independent, unsynchronized clocks (a classic clock-domain-crossing,
//   CDC, structure). Use the standard Gray-code pointer technique: keep a
//   binary write pointer and binary read pointer in their own clock
//   domains, convert each to Gray code, and synchronize each pointer into
//   the OTHER clock domain with a 2-flop synchronizer. full/empty are then
//   computed by comparing the local pointer against the synchronized
//   (and, for full, bit-reversed-MSB adjusted) remote pointer.
//
// Interface:
//   parameter DATA_WIDTH = 8    // width of each data word, in bits
//   parameter DEPTH      = 16   // number of entries. MUST be a power of two
//                                 -- this is a hard requirement (not just a
//                                 simplifying assumption) for the Gray-code
//                                 pointer/full-empty trick used here: the
//                                 pointers are (log2(DEPTH)+1)-bit binary
//                                 counters and the standard full-detect
//                                 comparison (MSB + second-MSB inverted)
//                                 only works cleanly for a power-of-two ring.
//
//   // write domain
//   input  logic                   wr_clk
//   input  logic                   wr_rst     // synchronous, active-high,
//                                                w.r.t. wr_clk
//   input  logic                   wr_en
//   input  logic [DATA_WIDTH-1:0]  wr_data
//   output logic                   full
//
//   // read domain
//   input  logic                   rd_clk
//   input  logic                   rd_rst     // synchronous, active-high,
//                                                w.r.t. rd_clk
//   input  logic                   rd_en
//   output logic [DATA_WIDTH-1:0]  rd_data
//   output logic                   empty
//
// Behavior / assumptions pinned down for testability:
//   - wr_clk and rd_clk are independent, free-running clocks with no fixed
//     phase or frequency relationship (not even an integer ratio).
//   - wr_rst resets only the write-domain state (write pointer + the
//     synchronizer registers that live in the write domain); similarly
//     rd_rst resets only the read-domain state. Each is synchronous to its
//     own clock.
//   - wr_en while full is a no-op (write ignored, no corruption).
//   - rd_en while empty is a no-op.
//   - rd_data is combinational, FIRST-WORD-FALL-THROUGH style (same
//     convention as q4): it always shows the current head-of-queue entry
//     (don't-care when empty); asserting rd_en for one cycle while !empty
//     pops that entry.
//   - full/empty are necessarily a few clock cycles "pessimistic" right
//     after an access on the opposite side, because the Gray-coded pointer
//     has to cross the 2-flop synchronizer before the other domain can see
//     it. This is inherent to any real asynchronous FIFO and is expected,
//     not a bug -- the testbench does not make cycle-exact assertions about
//     full/empty; it checks that the end-to-end sequence of words read out
//     exactly matches, in order, the sequence of words written in.
//
// =============================================================================

module q9 #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH      = 16
) (
    // write domain
    input  logic                  wr_clk,
    input  logic                  wr_rst,
    input  logic                  wr_en,
    input  logic [DATA_WIDTH-1:0] wr_data,
    output logic                  full,

    // read domain
    input  logic                  rd_clk,
    input  logic                  rd_rst,
    input  logic                  rd_en,
    output logic [DATA_WIDTH-1:0] rd_data,
    output logic                  empty
);

    // TODO: implement your RTL here

endmodule
