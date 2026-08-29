# Asynchronous FIFO — Design & Verification Report

## 1. Overview

Design under test: a parameterized asynchronous FIFO (`async_fifo`) implementing
the standard Cliff Cummings-style dual-clock CDC scheme:

- Gray-coded read/write pointers crossed between clock domains
- 2-flop synchronizers for each pointer crossing (`two_flop_synchronizers`)
- Dedicated async-assert / sync-deassert reset synchronizer per clock domain
  (`reset_synchronizer`)
- Look-ahead `full_next` / `empty_next` combinational logic to avoid the
  classic one-cycle-late full/empty bug

**Parameters used in verification:** `DEPTH = 8`, `DATA_WIDTH = 8`
(`ADDR_WIDTH = 3`, pointer width = 4 bits including the wrap/MSB bit).

**Clocks:** `clk_w` = 100 MHz (10 ns period), `clk_r` ≈ 73 MHz (6.849315 ns
half-period) — deliberately non-integer-ratio to stress the CDC logic rather
than mask bugs behind a clean clock relationship.

---

## 2. Bugs Found During Bring-Up

The one substantive verification bug found was a testbench read-data race.

| # | Issue | Symptom | Root Cause | Fix |
|---|-------|---------|------------|-----|
| 1 | Testbench read-data race | `verify_fifo()` consistently reported the *previous* read's value (one-read lag), even though pointer/Gray-code/full/empty logic was correct | `data_out` is driven with a nonblocking assignment on `posedge clk_r`; testbench sampled it immediately after the same edge, in the same **Active region**, before the **NBA region** committed the write | Added `#1` (equivalently `@(negedge clk_r)`) at the end of `read_fifo()` task to push the check past the NBA region |

### Verilog scheduling note (bug #1)

Within a single simulation timestep, the event scheduler processes regions in order: **Active → Inactive → NBA → Postponed**. Nonblocking assignments (`<=`) evaluate their RHS in the Active region but only *write* their LHS in the NBA region, which runs strictly after all testbench procedural code has completed for that timestep. Any testbench check that samples a nonblocking-driven signal immediately after the triggering edge, without yielding past the NBA region, will observe the old value. `$monitor` do not suffer from this because they execute in the Postponed region, after NBA has settled.

---

## 3. Test Cases Executed

All tests run against `DEPTH=8`, `DATA_WIDTH=8`, with independent `clk_w` (100 MHz) and `clk_r` (~73 MHz) domains and an async-assert reset applied at the start of simulation.

| Test Case | Description | Result |
|-----------|-------------|--------|
| Reset behavior | FIFO held in reset for several `clk_r` cycles before release | Pass |
| Write till full | 9 consecutive writes into an 8-entry FIFO; `full` correctly asserts after the 8th write, 9th write correctly blocked | Pass |
| Read till empty | 8 reads with data verification against write order (FIFO ordering preserved) | Pass (8/8 `verify_fifo` checks) |
| Wrap-around | Multiple partial write/read cycles causing write and read pointers to wrap past the memory depth boundary more than once | Pass |
| Read + write while full | Read and write issued back-to-back while FIFO reports full; write correctly blocked until `full` deasserts, no data corruption | Pass |
| Read + write while empty | Write issued while FIFO reports empty, followed by a read; correct data returned, no spurious read | Pass |
| End-of-test reset | Reset re-asserted after final checks; FIFO returns to known state (`full=0`, `empty=1`, pointers zeroed) | Pass |

**Total: 11/11 `verify_fifo` checks passed, 0 errors.**

---

## 4. Simulation Summary

- Simulator: Vivado
- Total simulated time: ~1.034 µs
- `$finish` reached cleanly with no unexpected `X`/`Z` propagation on `full`,
  `empty`, `data_out`, or the Gray-coded synchronizer chain at any point
  after reset release

---