# RV32I CPU

A self-designed RV32I RISC-V processor in VHDL, developed simulation-first with GHDL and based on the ISA specification rather than on an existing implementation.

The repository is at an early stage. It currently holds one module and its testbench; the datapath and control follow.

## Status

`alu`: the NAND2Tetris Hack ALU in behavioural VHDL. 18 functions selected by six control bits (`zx`, `nx`, `zy`, `ny`, `f`, `no`), with zero and negative flag outputs. Ports are `signed` via `numeric_std`, the data width is generic, and the module is purely combinational. `ghdl --synth` reports no inferred latches and the netlist contains no clocked processes.

## Layout

```
rtl/    synthesisable modules
tb/     one self-checking testbench per module in rtl/
build/  GHDL work library (generated, not tracked)
```

## Build and run

```bash
mkdir -p build
ghdl -a --std=08 --workdir=build rtl/*.vhd tb/*.vhd
ghdl -e --std=08 --workdir=build alu_tb
ghdl -r --std=08 --workdir=build alu_tb
ghdl -r --std=08 --workdir=build alu_tb -gDATA_WIDTH=16
```

The two runs cover different things: the first sweeps every operand pair at a reduced width, the second applies boundary operands at the full width. Expected output:

```
PASS: all 4608 vectors
PASS: all 450 vectors
```

Check style compliance:

```bash
vsg -c vsg_config.yaml -f rtl/*.vhd -f tb/*.vhd
```

Check inferred hardware. GHDL treats an inferred latch as an error, so a silent run is the check passing:

```bash
ghdl --synth --std=08 --workdir=build rtl/alu.vhd -e alu > /dev/null
```

## Verification

Every module ships with a self-checking testbench. Correctness is decided by assertions inside the simulation, never by inspecting a waveform.

The oracle is independent of the design under test. Expected values come from the 18 named Hack functions evaluated with VHDL's own operators (`+`, `-`, `not`, `and`, `or`) rather than from re-applying the six control bits in the testbench. Re-deriving them would reimplement the DUT's algorithm, so a misunderstanding shared by both would pass unnoticed. In the case of subtraction, the ALU reaches `x - y` as `not (not x + y)` through its staged transformations, while the check uses the `-` operator. Two paths leading to the same result.

Coverage is exhaustive at a reduced width. The data width is generic, so the testbench runs at 4 bits, where all 256 operand pairs across all 18 functions fit in 4608 vectors. At 16 bits the same sweep would need 2^32 pairs per function. Staging and control-decode defects are width-independent and are fully covered by the small width. A second run at 16 bits applies boundary operands to cover width-dependent defects, which the reduced width cannot reach.

The testbench is mutation tested. Defects are injected into the ALU deliberately and the unmodified testbench is re-run. A testbench that still passes is not testing what it appears to test. Tying either flag output low, removing the `zx`, `ny` or `no` stage, and swapping `and` for `or` in the function multiplexer are each detected.

Current result: 4608 exhaustive vectors at 4 bits and 450 directed vectors at 16 bits, no failures, all injected defects caught.

## Tooling and conventions

- **GHDL** with `--std=08` for analysis, elaboration and simulation, and `--synth` to inspect inferred hardware. Waveforms are viewed in GTKWave.
- **VSG** enforces layout and naming on every file. The configuration is committed as `vsg_config.yaml` and is the authoritative statement of the conventions in use. Briefly: ports carry `_i` / `_o` / `_io` direction suffixes, types end in `_t`, process labels in `_proc`, instance labels begin `u_`, generics and constants and enumeration literals are uppercase, and the non-standard `std_logic_arith` package family is rejected.
- **vhdl_ls.toml** maps both source directories into the `work` library for the language server and raises unused declarations to errors.

Modules are instantiated directly as entities rather than through component declarations, so there is no duplicated port list to drift out of sync.

## Scope

The target is the RV32I base integer instruction set, verified against the RISC-V architecture conformance suite. RV64, the F, D, C and A extensions, and virtual memory are out of scope by design; the goal is a demonstrably correct core rather than a broad one.
