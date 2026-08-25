// =============================================================================
// q16 - Fibonacci and factorial (iterative RTL)
// =============================================================================
// Problem:
//   Build a single module that computes EITHER fib(n) OR n! iteratively
//   (i.e. over multiple clock cycles using an internal accumulator/FSM -
//   NOT combinationally in one cycle; that's the point of the exercise).
//
// Interface:
//   input  logic clk            - free-running clock.
//   input  logic rst            - synchronous, active-high. Clears all
//                                  state: done -> 0, result -> 0, FSM -> idle.
//   input  logic start          - single-cycle pulse that begins a new
//                                  computation. Only sampled meaningfully
//                                  while the module is NOT busy computing
//                                  (i.e. while done==1, or right after
//                                  reset before any computation has run).
//                                  Asserting start while busy is not a
//                                  defined/tested case.
//   input  logic [4:0] n        - the argument (0-31). Sampled at the start
//                                  pulse.
//   input  logic mode           - 0 = compute fib(n); 1 = compute n!.
//                                  Sampled at the start pulse.
//   output logic done           - LEVEL signal. Low while a computation is
//                                  in progress. Goes HIGH the cycle the
//                                  result becomes valid and STAYS high
//                                  (with result held stable) until the next
//                                  start pulse is accepted, at which point
//                                  done drops low again -- visible starting
//                                  at the very clock edge that samples that
//                                  start pulse (standard registered-output
//                                  behavior) -- while the new computation
//                                  runs.
//   output logic [31:0] result  - the computed value. Only meaningful while
//                                  done==1.
//
// fib definition used: fib(0)=0, fib(1)=1, fib(2)=1, fib(3)=2, fib(4)=3, ...
//                       (fib(k) = fib(k-1) + fib(k-2) for k>=2)
//
// Assumptions / pinned-down behavior:
//   - mode==0 (Fibonacci): the full 5-bit input range n in [0,31] is SAFE -
//     fib(31) = 1,346,269, comfortably within 32 bits. No extra restriction
//     needed on n for this mode.
//   - mode==1 (factorial): n MUST be in [0,12] to stay within 32 bits -
//     12! = 479,001,600 fits; 13! = 6,227,020,800 overflows 32 bits. The
//     testbench only drives n in [0,12] whenever mode==1. Behavior for
//     n>12 in factorial mode is undefined/not tested.
//   - On rst: done=0, result=0, internal state cleared, ready to accept the
//     first start pulse.
//   - Implementation hint: an FSM (IDLE/RUN/DONE) driving an iterative
//     accumulator. For Fibonacci, keep a running pair (a,b) initialized
//     (0,1) and apply (a,b) <- (b, a+b) once per cycle for n iterations;
//     the result is the final "a". For factorial, keep an accumulator
//     initialized to 1 and multiply by successive integers 1..n over n
//     cycles.
// =============================================================================

module q16 (
    input  logic        clk,
    input  logic        rst,
    input  logic        start,
    input  logic [4:0]  n,
    input  logic        mode,
    output logic        done,
    output logic [31:0] result
);

    // TODO: implement your RTL here

endmodule
