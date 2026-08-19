# Asynchronous FIFO

A learning-focused implementation of an asynchronous FIFO in Verilog, developed from the fundamentals of Clock Domain Crossing (CDC).

The project is being built step-by-step rather than directly implementing an asynchronous FIFO.

## Learning Roadmap

### CDC Fundamentals

- [x] Understand clock domains
- [x] Understand setup/hold violations
- [x] Understand metastability
- [x] Implement two-flip-flop synchronizer
- [x] Verify synchronizer through simulation

### Gray Code

- [ ] Understand why binary pointers are unsafe across clock domains
- [ ] Understand Gray code
- [ ] Implement binary-to-Gray conversion
- [ ] Implement Gray-to-binary conversion
- [ ] Verify Gray-code transitions

### Asynchronous FIFO

- [ ] Implement binary read/write pointers
- [ ] Generate Gray-coded pointers
- [ ] Synchronize write pointer into read domain
- [ ] Synchronize read pointer into write domain
- [ ] Derive asynchronous FIFO empty logic
- [ ] Derive asynchronous FIFO full logic
- [ ] Implement asynchronous FIFO RTL
- [ ] Build a self-checking testbench
- [ ] Verify different clock frequencies
- [ ] Verify simultaneous read/write
- [ ] Verify overflow and underflow behavior

## Repository Structure

```text
asynchronous-fifo/
├── rtl/
├── tb/
├── sim/
├── docs/
├── .gitignore
└── README.md
```

## STATUS

 **ONGOING**
