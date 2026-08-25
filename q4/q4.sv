// =============================================================================
// q4 - Synchronous FIFO, generic depth
// =============================================================================
//
// Problem:
//   Implement a standard single-clock-domain FIFO (first-in, first-out queue)
//   with parameterizable data width and depth.
//
// Interface:
//   parameter DATA_WIDTH = 8    // width of each data word, in bits
//   parameter DEPTH      = 16   // number of entries the FIFO can hold.
//                                 ASSUMPTION: DEPTH is a power of two. This
//                                 is a standard simplifying assumption for
//                                 FIFO pointer arithmetic (wraparound is a
//                                 simple binary increment/overflow) and is
//                                 not something your RTL needs to check.
//
//   input  logic                   clk       // free-running clock
//   input  logic                   rst       // synchronous, active-high reset
//   input  logic                   wr_en     // write request (write side)
//   input  logic [DATA_WIDTH-1:0]  wr_data   // write data
//   input  logic                   rd_en     // read/pop request (read side)
//   output logic [DATA_WIDTH-1:0]  rd_data   // data at the head of the queue
//   output logic                   full      // FIFO is at capacity
//   output logic                   empty     // FIFO holds no entries
//
// Behavior / assumptions pinned down for testability:
//   - Synchronous reset: on rst, the FIFO becomes empty (all internal
//     pointers/state clear). rst is active-high and sampled at posedge clk.
//   - wr_en while full is a no-op: the write is silently ignored, no data is
//     corrupted or overwritten, full stays asserted.
//   - rd_en while empty is a no-op: nothing happens, empty stays asserted.
//   - rd_data is FIRST-WORD-FALL-THROUGH (FWFT): it is a purely combinational
//     function of the current head-of-queue entry. Whenever the FIFO is
//     non-empty, rd_data continuously shows the oldest un-popped word,
//     *without* needing rd_en asserted to "present" it. Asserting rd_en for
//     one cycle while !empty pops that entry; on the following cycle,
//     rd_data shows the new head of queue (or is don't-care if the FIFO is
//     now empty).
//   - full and empty are combinational functions of the internal write/read
//     pointers (i.e. same-cycle accurate, not registered/delayed).
//   - Simultaneous wr_en and rd_en on the same cycle, when the FIFO is
//     neither full nor empty, perform both operations that cycle (a write
//     and a pop happen together; occupancy stays the same).
//
// =============================================================================

module q4 #(
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
