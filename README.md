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

- [x] Understand why binary pointers are unsafe across clock domains
- [x] Understand Gray code
- [x] Implement binary-to-Gray conversion
- [x] Implement Gray-to-binary conversion
- [x] Verify Gray-code transitions

### Asynchronous FIFO

- [x] Implement binary read/write pointers
- [x] Generate Gray-coded pointers
- [x] Synchronize write pointer into read domain
- [x] Synchronize read pointer into write domain
- [x] Derive asynchronous FIFO empty logic
- [x] Derive asynchronous FIFO full logic
- [x] Implement asynchronous FIFO RTL
- [x] Build a self-checking testbench
- [x] Verify different clock frequencies
- [x] Verify simultaneous read/write
- [x] Verify overflow and underflow behavior

## Repository Structure

```text
asynchronous-fifo/
├── rtl/  #Synthesizable Verilog Source
├── tb/   # testbenches
├── docs/ # Architecture and verification logs
├── .gitignore
└── README.md
```

## Documentation
- [Architecture & Block Diagram](docs/Architecture.md)
- [Verification Report](docs/verification_report.md)
- [Desgin Notes and Explained working](docs/DesginNotes.md)


##STATUS

**Core async FIFO implemented and passing directed test cases.**
Next: randomized/scoreboard-based verification, broader clock-ratio stress testing.