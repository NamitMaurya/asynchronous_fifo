# Design Notes — Asynchronous FIFO

This document explains the *why* behind the design, not just the *what*.
The architecture doc shows the block diagram and module connections; this doc captures the reasoning that led to those choices.

---

## 1. Why can't we just cross a signal directly between clock domains?

Any signal crossing from one clock domain into another can arrive at the receiving flip-flop at an unpredictable moment relative to that domain's clock edge,outside the flip-flop's setup/hold window. When that happens, the flip-flop's output can go **metastable**: it moves at an invalid voltage level for an uncertain amount of time before resolving to a `0` or a `1`. If that unresolved value is sampled by another flip-flop, or if different flip-flops resolve it differently, the result is unpredictable and can turn out as a real functional bug.

We can't stop metastability from occurring, it's a physical consequence of crossing clock domains, but we can reduce the **probability** that it propagates into the whole circuit, by giving the signal time to resolve before anything depends on it.

## 2. Why two flip-flops, not one?

A single synchronizing flip-flop reduces the *window* during which metastability can occur, but if that first flop is still metastable exactly when the next clock edge samples it, the problem just moves one stage lower instead of being solved.

Adding a second flip-flop gives the first flop's output a full clock period to resolve before it's sampled again. The **Mean Time Between Failures(MTBF)** of a synchronizer improves exponentially with each additional flip-flop, and two stages is the standard, widely-used balance between reliability and added latency for most designs. This is why `two_flop_synchronizers` is exactly that ,two registers (`sync_1`,`sync_2`) in series, not one.

**Cost of this choice:** every value crossed through this synchronizer is delayed by up to 2 cycles of the receiving clock before it's usable. This latency is why the FIFO's full/empty detection is always slightly conservative.

## 3. Why Gray code instead of crossing the binary pointer directly?

A binary counter can change **multiple bits at once** on a single increment. For example, incrementing binary `011` → `100` flips three bits simultaneously. If that transition is caught mid-change by a synchronizer, different bits can resolve on different sides of the transition, producing a synchronized value that was never actually a valid pointer value at any point in time, not the old value, not the new value, something in between that doesn't correspond to any real FIFO state.

**Gray code** is constructed so that only **one bit changes between any two consecutive values**. If a Gray-coded value is sampled mid-transition, the synchronizer can only ever resolve to either the value just before the transition or the value just after it — never anything invalid in between. That's the entire reason the write and read pointers are Gray-coded (`wr_ptr_gray`, `rd_ptr_gray`) before being passed through the two-flop synchronizers, while the binary pointers (`wr_ptr_bn`, `rd_ptr_bn`) stay local to their own domain and are only used for memory addressing.

In this design, Gray coding is done via the standard `binary ^ (binary >> 1)` conversion, rather than as a separate module.

## 4. Why does the pointer need one extra bit beyond the address width?

With `ADDR_WIDTH = $clog2(DEPTH)` bits, a pointer can only represent `DEPTH` distinct values before wrapping back to `0` — which is exactly the range needed to *address* memory, but it's not enough to *distinguish* full from empty. A full FIFO and an empty FIFO both have `wr_ptr == rd_ptr` in the low `ADDR_WIDTH` bits, because the write pointer has simply wrapped all the way around and caught back up to the read pointer.Extending the pointer to `ADDR_WIDTH + 1` bits fixes this: only the lower `ADDR_WIDTH` bits are used for actual memory addressing, but the extra MSB acts as a wrap-count flag. Empty is detected when the full pointers (including the extra bit) are exactly equal. Full is detected when the lower bits are equal *and* the MSBs differ — meaning the write pointer has wrapped exactly one more time than the read pointer. That comparison is what the full/empty logic below is built on.
```verilog
assign full_next = ({~rd_ptr_sync[ADDR_WIDTH:ADDR_WIDTH-1] , rd_ptr_sync[ADDR_WIDTH-2:0]} == wr_ptr_gray_next) ;
assign empty_next = (rd_ptr_gray_next == wr_ptr_sync) ;
```

## 5. Why look-ahead (`full_next`/`empty_next`) instead of just checking the registered pointers?

If `full`/`empty` were computed directly from the already-registered pointer values, the flag would always be **one cycle late** relative to the operation that actually caused the FIFO to become full or empty — because the pointer update and the flag computation would be racing against each other on the same edge, one cycle behind reality.

Instead, `full_next` and `empty_next` are computed **combinationally** from what the *next* pointer value will be (`wr_ptr_gray_next`, comparing against the already-synchronized opposite-domain pointer), and it's this look-ahead value that gets registered into `full`/`empty` on the next clock edge. This means the flag becomes accurate on the very next cycle after the operation that caused it, rather than lagging an extra cycle behind, which matters because a late `full` flag could let a write silently overflow the FIFO before the flag catches up.

## 6. Why does the write side compare against `rd_ptr_sync` (and not `rd_ptr_gray` directly), and vice versa?

Each domain only ever has access to the **synchronized** copy of the other domain's pointer, that's the whole point of the two-flop synchronizer. Comparing directly against the other domain's raw Gray pointer (`rd_ptr_gray` from inside the write-clock logic, for example) would be exactly the unsafe direct-crossing problem described in section 1: reading a signal that isn't guaranteed to be stable relative to your own clock.

This is also why `full` is necessarily a **conservative, slightly stale** signal — by the time a read pointer update has propagated through its synchronizer into the write domain, it may already be one or two write- clock cycles old. The FIFO will never report "not full" when it actually is full, but it may take a couple of extra cycles after a read before `full` correctly deasserts. This is expected, safe behavior — better to be briefly conservative than to ever falsely permit an overflow.

## 7. Why a separate reset synchronizer per clock domain, instead of one global reset?

Reset needs to **assert immediately** and **asynchronously** — a stuck or misbehaving FIFO shouldn't have to wait for a clock edge to be reset. But if reset is **released** asynchronously too, it can create the same kind of metastability risk as any other uncontrolled cross-domain signal: whichever domain happens to sample the deassertion edge at the wrong moment risks undefined flip-flop behavior right as the design is coming out of reset.

`reset_synchronizer` solves this with the standard **async-assert,sync-deassert** pattern: reset takes effect immediately (asynchronous `posedge rst_in` in the sensitivity list), but release is passed through a synchronizer so that *deassertion* is clean and predictable in each domain's own clock. Because `clk_w` and `clk_r` run at different, unrelated frequencies, each domain needs its own instance (`rst_w`, `rst_r`) — a single synchronized reset couldn't be correct for both domains simultaneously.

## 8. Why does `data_out` sometimes appear "late" when checked in simulation?

This isn't a design issue, but it's worth documenting since it caused real confusion during verification (see `verification_report.md`). `data_out` is updated with a **nonblocking assignment** on `posedge clk_r`. Nonblocking assignments evaluate their right-hand side immediately but only commit the write in the simulator's **NBA (Nonblocking Assign) region**, which runs strictly after all same-timestep procedural code (including testbench checks) has finished executing. A testbench that samples `data_out` immediately after the same edge that updates it — without yielding past the NBA region — will see the *previous* value, not the one just written. This is a simulation/testbench timing subtlety, not a property of the hardware itself: real hardware doesn't have this ambiguity, only event-driven simulators do.

---

## Summary of Core Design Decisions

| Decision | Reason |
|---|---|
| Two-flop synchronizer (not one, not three+) | Balances MTBF improvement against added latency |
| Gray-coded pointers crossed, not binary | Guarantees only one bit changes per transition — safe under metastability |
| Pointer width = `ADDR_WIDTH + 1` | Extra MSB distinguishes full from empty when address bits are equal |
| Look-ahead `full_next`/`empty_next` | Avoids a one-cycle-late flag that could allow overflow |
| Full/empty compared against synchronized pointer | Never read a signal that hasn't crossed the CDC boundary safely |
| Per-domain reset synchronizer | Each domain must deassert reset safely on its own unrelated clock |