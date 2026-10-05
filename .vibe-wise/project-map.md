# Project Map

## Purpose
RTL practice set: 25 classic RTL interview questions in SystemVerilog. Each `qN/` folder has `qN.sv` (learner implements; header holds the spec and interface, body is a `// TODO`) and `qN_tb.sv` (self-checking testbench, not to be edited). A testbench prints `TEST PASSED` or `TEST FAILED: <n> error(s)`.

## Requirements
- Implement each module to the spec in its `qN.sv` header; the testbench checks that spec exactly.
- Conventions: `clk` 10 ns period, `rst` synchronous active-high, multi-bit signals as `logic [N-1:0]`.

## Components
- `q1`–`q25/`: one question each (arbiters, FIFOs, ROB, CDC, FSMs, Gray code, MUXes, LRU, sort/median, clock dividers, ready/valid downsizer, pipeline datapath, sequence detector, bit tricks, UART TX, SVA).
- `Makefile`: Questa flow (`make test Q=qN`, `make test-all`, `make gui Q=qN`, `make clean`).
- `README.md`: question index and run instructions.
- `scratch.v`: untracked scratch notes comparing Verilog and SystemVerilog styles (`always @(*)` vs `always_comb`, `always @(posedge clk)` vs `always_ff`, `reg`/`wire` vs `logic`).

## Main Flow
```
edit qN/qN.sv  --make test Q=qN-->  vlog + vsim (Questa)  -->  qN_tb checks DUT  -->  TEST PASSED / FAILED
```

## Data and Trust Boundaries
No storage, network, or external services. Simulation only.

## Build and Deployment
Questa via `module load questa` (school Linux server), or paste `qN.sv` and `qN_tb.sv` into EDA Playground. No deployment.

## Unknowns
- Which questions are already implemented: only `q25.sv` was inspected and it is still a TODO stub.
- Whether Questa/a simulator is available on this Windows machine.
