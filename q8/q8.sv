// =============================================================================
// q8 - FSM: divisible-by-3 (or 5) checker for a serial bit stream
// =============================================================================
// Problem:
//   A binary number is streamed in one bit at a time, MOST-SIGNIFICANT BIT
//   FIRST. Each new bit is logically appended to the LSB end of the number
//   seen so far:
//       running_value = running_value*2 + bit_in
//   Track, after every bit consumed, whether the value accumulated so far is
//   evenly divisible by a parameter MOD (default 3; must also work correctly
//   when instantiated with MOD=5 - the implementation must be generic in
//   MOD, not special-cased for MOD==3).
//
// Interface:
//   parameter int MOD          - divisor to check against (>=2). Default 3.
//   input  logic clk           - free-running clock.
//   input  logic rst           - synchronous, active-high. Resets all
//                                 internal state (running remainder -> 0).
//   input  logic bit_in        - the next bit of the number being streamed
//                                 in, valid only on cycles where bit_valid=1.
//   input  logic bit_valid     - pulses high for one cycle whenever bit_in
//                                 holds a new bit to consume. State updates
//                                 ONLY on cycles where bit_valid is high.
//   input  logic clear         - synchronous. Like rst but scoped: pulse it
//                                 (independent of rst) to reset the internal
//                                 running remainder back to "value 0" so you
//                                 can start tracking a brand-new number
//                                 without a full module reset.
//   output logic divisible     - indicator that the value accumulated so far
//                                 is evenly divisible by MOD.
//
// Assumptions / pinned-down behavior:
//   - On rst or clear, the internal remainder resets to 0, so divisible is
//     TRUE for the empty/zero value (0 is divisible by anything), as
//     expected.
//   - divisible is REGISTERED: it is derived combinationally from an
//     internal remainder register that itself updates synchronously (only
//     on cycles where bit_valid or clear or rst is asserted). This means
//     divisible reflects the value AFTER a given bit_valid pulse's bit has
//     been consumed, visible starting the cycle after that pulse (standard
//     registered-remainder behavior) - NOT combinationally in the same
//     cycle as bit_in changes.
//   - Implementation hint: classic DFA/Mealy machine over MOD states
//     representing the running remainder mod MOD. Each time bit_valid
//     pulses:
//         next_remainder = (remainder*2 + bit_in) % MOD
//     On rst or clear, remainder <= 0.
// =============================================================================

module q8 #(
    parameter int MOD = 3
) (
    input  logic clk,
    input  logic rst,
    input  logic bit_in,
    input  logic bit_valid,
    input  logic clear,
    output logic divisible
);

    // TODO: implement your RTL here

endmodule
