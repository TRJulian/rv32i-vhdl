# RV32I CPU

A self-designed RV32I RISC-V processor in VHDL, developed simulation-first with GHDL and based on the ISA specification rather than on an existing implementation.

The repository is at an early stage. It currently holds two modules and their testbenches; the datapath and control follow.

## Status

`hack_alu`: the NAND2Tetris Hack ALU in behavioural VHDL. 18 functions selected by six control bits (`zx`, `nx`, `zy`, `ny`, `f`, `no`), with zero and negative flag outputs. Ports are `signed` via `numeric_std`, the data width is generic, and the module is purely combinational. `ghdl --synth` reports no inferred latches and the netlist contains no clocked processes.

`seq_detect_1011`: detects the bit sequence 1011 in a serial stream, including overlapping matches, so the input 1011011 produces two pulses. Registered Mealy, written as one clocked process. Synchronous reset, so reset is an ordinary synchronous input with no recovery/removal constraint and no separate distribution network. Synthesis reports no inferred latches and 3 flip-flops.

## Layout

```
rtl/            synthesisable modules
tb/             one self-checking testbench per module in rtl/
rtl/ramp/       modules built to develop RTL and verification technique
tb/ramp/        their testbenches
build/          GHDL work library (generated, not tracked)
```

The `ramp/` modules are not instantiated by the core and will not be. They are kept for their verification evidence: the oracle design, coverage arithmetic and mutation results described below were developed on them.

## Build and run

`make help` lists every target. The common ones:

```bash
make check TOP=hack_alu                           # analyse, simulate, latch check, lint
make check TOP=seq_detect_1011
```

Simulation alone:

```bash
make sim TOP=hack_alu                             # exhaustive sweep at reduced width
make sim TOP=hack_alu GENERICS=-gDATA_WIDTH=16    # boundary operands at full width
make sim TOP=seq_detect_1011
```

The two `hack_alu` runs cover different things: the first sweeps every operand pair at a reduced width, the second applies boundary operands at the full width. Expected output:

```
PASS: all 4608 vectors
PASS: all 450 vectors
PASS: all possible 4096 12-bit sequences
```

Inspect inferred hardware. GHDL treats an inferred latch as an error, so `make synth` exits nonzero if one is inferred:

```bash
make synth TOP=hack_alu
make synth TOP=seq_detect_1011
make ff    TOP=seq_detect_1011    # flip-flop count in bits, summed from register widths
```

Check style compliance across every file:

```bash
make lint
```

`build/` is created by the Makefile, so a fresh clone needs no setup beyond the tools listed below.

## Verification

Every module ships with a self-checking testbench. Correctness is decided by assertions inside the simulation, never by inspecting a waveform.

### hack_alu

The oracle is independent of the design under test. Expected values come from the 18 named Hack functions evaluated with VHDL's own operators (`+`, `-`, `not`, `and`, `or`) rather than from re-applying the six control bits in the testbench. Re-deriving them would reimplement the DUT's algorithm, so a misunderstanding shared by both would pass unnoticed. In the case of subtraction, the hack_alu reaches `x - y` as `not (not x + y)` through its staged transformations, while the check uses the `-` operator. Two paths leading to the same result.

Coverage is exhaustive at a reduced width. The data width is generic, so the testbench runs at 4 bits, where all 256 operand pairs across all 18 functions fit in 4608 vectors. At 16 bits the same sweep would need 2^32 pairs per function. Staging and control-decode defects are width-independent and are fully covered by the small width. A second run at 16 bits applies boundary operands to cover width-dependent defects, which the reduced width cannot reach.

The testbench is mutation tested. Defects are injected into the hack_alu deliberately and the unmodified testbench is re-run. A testbench that still passes is not testing what it appears to test. Tying either flag output low, removing the `zx`, `ny` or `no` stage, and swapping `and` for `or` in the function multiplexer are each detected.

Current result: 4608 exhaustive vectors at 4 bits and 450 directed vectors at 16 bits, no failures, all injected defects caught.

### seq_detect_1011

The oracle is independent of the state graph. The testbench keeps the last four bits it drove in a shift window and compares that window against `1011`. It never reproduces the transition rule, so an error in the state graph cannot be mirrored into the check.

Coverage is exhaustive over input sequences rather than over inputs. A test case here is a whole sequence rather than a single bit, so the testbench drives all 4096 twelve-bit sequences, giving 49152 checks. Twelve bits is long enough to contain a reset settle, a full match, an immediately overlapping match, and a near miss that exercises the transition out of `101` on a `0`.

Reset is asserted before every sequence and the output is checked while reset is still asserted. Placing that check inside the loop rather than once at startup means it runs after sequences that ended with the output high, which tests that reset clears a set output.

Fourteen injected defects are detected: every edge of the state graph including both overlap edges, both output polarities, reset polarity, and reset made conditional on a subset of states. An earlier version of the testbench missed one. The output during the reset cycle was verified by nothing, because the first check ran only after the first data bit had already reassigned it. The per-sequence reset check closes that hole.

Stimulus is driven on the falling edge and sampled half a period later, giving 500 ns of setup margin at the 1 MHz simulation clock. This was measured rather than assumed, by sweeping a delay inserted between the driver and the module input: 499 ns passes, 501 ns fails. An earlier version drove stimulus at the sampling edge itself. That passes with zero margin and breaks as soon as any signal sits between the driver and the input.

## Tooling and conventions

- **GHDL** with `--std=08` for analysis, elaboration and simulation, and `--synth` to inspect inferred hardware. Waveforms are viewed in **GTKWave** via `make wave`.
- **make** wraps the tool invocations so that flags such as `--workdir` and the VSG configuration path cannot be forgotten. Targets are listed by `make help` rather than enumerated here, so that this file cannot drift from the Makefile.
- **VSG** enforces layout and naming on every file. `vsg_config.yaml` is committed and is the authoritative statement of the conventions in use; it is deliberately not restated in prose, because a copy drifts as soon as a rule changes. In summary, identifiers encode port direction, type, and whether a signal is driven by a clocked process, and the non-standard `std_logic_arith` package family is rejected.
- **vhdl_ls.toml** maps both source directories into the `work` library for the language server and is configured to raise unused declarations to errors.
- **Yosys** is optional. It is used only by `make stat` and `make schematic`, which report cell counts and draw the synthesised module. Nothing else depends on it.

Modules are instantiated directly as entities rather than through component declarations, so there is no duplicated port list to drift out of sync.

## Scope

The target is the RV32I base integer instruction set, verified against the RISC-V architecture conformance suite. RV64, the F, D, C and A extensions, and virtual memory are out of scope by design; the goal is a demonstrably correct core rather than a broad one.
