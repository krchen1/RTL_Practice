// ===========================================================================
// q13.sv -- LRU replacement tracker, 4-way
//
// Title: LRU replacement tracker, 4-way
//
// NOTE: This is one concrete scoping of an open-ended interview question
// ("design an LRU replacement policy"); the exact interface below is what
// is being tested.
//
// Scoping: this module tracks WHICH of 4 "ways" is least-recently-used --
// it is the replacement-policy logic only, not a full cache datapath. It
// models just the LRU state-tracking logic for a 4-way set, as used inside
// a larger cache design -- not the full cache datapath/tag/data arrays.
//
// Interface:
//   input  logic       clk, rst      -- clk 10ns period, rst sync active-high
//   input  logic       access_vld    -- pulses when way access_way was
//                                        touched (hit or fill) this cycle
//   input  logic [1:0] access_way    -- which of the 4 ways (0-3) was touched
//   output logic [1:0] lru_way       -- COMBINATIONAL: currently least-
//                                        recently-used way (next eviction victim)
//
// Semantics:
//   - Whenever access_vld pulses, way access_way becomes the
//     MOST-recently-used way.
//   - lru_way is combinational and always valid: it reflects whichever of
//     the 4 ways is currently least-recently-used.
//   - On rst: the initial recency order LRU -> MRU is way 0, way 1, way 2,
//     way 3. So lru_way == 0 immediately after reset, before any access.
// ===========================================================================

module q13 (
  input  logic       clk,
  input  logic       rst,
  input  logic       access_vld,
  input  logic [1:0] access_way,
  output logic [1:0] lru_way
);

  // TODO: implement your RTL here

endmodule
