// =============================================================================
// q24 - SystemVerilog assertions for a synchronous FIFO
// =============================================================================
//
// Problem:
//   This question is different from a normal RTL design exercise: you are
//   NOT implementing a FIFO. You are writing a PASSIVE MONITOR/CHECKER
//   module that watches the externally-visible interface of some
//   synchronous FIFO (which you do not get to see the internals of, and
//   which is instantiated elsewhere) and uses SystemVerilog assertions
//   (`assert property`) to verify, from the outside, that it is behaving
//   like a correct FIFO. This module drives none of its inputs -- it only
//   observes them.
//
// Interface:
//   parameter DATA_WIDTH = 8
//   parameter DEPTH      = 16    // must match the true capacity of
//                                  whatever FIFO this monitor is bound to,
//                                  so capacity-based checks are meaningful
//
//   input logic                   clk
//   input logic                   rst        // synchronous, active-high,
//                                               same reset as the FIFO
//                                               being monitored
//   input logic                   wr_en
//   input logic                   rd_en
//   input logic                   full
//   input logic                   empty
//   input logic [DATA_WIDTH-1:0]  wr_data
//   input logic [DATA_WIDTH-1:0]  rd_data
//
// What to do:
//   Write as many `assert property` statements (or, where a property truly
//   needs a small amount of bookkeeping state -- like a running occupancy
//   count -- a combination of a little procedural logic plus an assertion
//   on it) as you can think of, to check FIFO correctness using only these
//   externally-visible signals. On any failure, increment `errors` and
//   print an `$error(...)` with useful context. `errors` is a plain
//   variable (not a port) that the testbench reads back hierarchically
//   after each test phase.
//
//   A starting list of properties to implement:
//     1. No write when full:  !(wr_en && full)
//     2. No read when empty:  !(rd_en && empty)
//     3. full and empty are never simultaneously true (not a real case for
//        any DEPTH > 0 FIFO, which is all we ever deal with here).
//     4. Occupancy / count monotonicity: track a running belief of how many
//        entries are in the FIFO (increment on an accepted write, decrement
//        on an accepted read, using the FIFO's own full/empty to decide
//        what counts as "accepted" -- exactly what a real FIFO's internal
//        write/read logic would gate on too). That running count must never
//        exceed DEPTH and must never go negative. This is a strong, fully
//        black-box-observable check: if `full` is ever asserted late (or
//        never), this count will blow past DEPTH and you'll catch a real
//        overflow/corruption bug even though you can't see memory internals.
//     5. Data integrity: whatever byte is written must eventually be read
//        back out, in FIFO (first-in-first-out) order. Honest note: this is
//        the hardest one to express as a single clean `assert property`
//        from pure black-box signals -- doing it "properly" with SVA alone
//        typically needs a local tracking queue anyway. It's most natural
//        to implement it as a small scoreboard: push wr_data on every
//        accepted write, and on every accepted read compare rd_data against
//        the front of that queue before popping it. Treat this one as a
//        stretch goal (or as your "property 5" even though it's really a
//        light scoreboard rather than a pure property) -- don't feel you
//        need to force it into an `assert property` one-liner.
//
// =============================================================================

module q24 #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH      = 16
) (
    input logic                  clk,
    input logic                  rst,
    input logic                  wr_en,
    input logic                  rd_en,
    input logic                  full,
    input logic                  empty,
    input logic [DATA_WIDTH-1:0] wr_data,
    input logic [DATA_WIDTH-1:0] rd_data
);

    int errors = 0;

    // TODO: implement your assertions below

endmodule
