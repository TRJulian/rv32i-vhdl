# ---- Configuration -----------------------------------------------------------

TOP       ?= alu
TB        ?= $(TOP)_tb
STD       ?= 08
BUILD     ?= build

PKG_DIR   ?= pkg
RTL_DIR   ?= rtl
TB_DIR    ?= tb

# find, not wildcard: wildcard does not recurse, so a nested layout would
# silently analyse nothing. Sorted for reproducible ordering. If a module ever
# instantiates another, set RTL_SRCS explicitly in dependency order instead.
PKG_SRCS ?= $(shell find $(PKG_DIR) $(RTL_DIR) $(TB_DIR) -name '*_pkg.vhd' | sort)
RTL_SRCS ?= $(shell find $(RTL_DIR) -name '*.vhd' ! -name '*_pkg.vhd' | sort)
TB_SRCS  ?= $(shell find $(TB_DIR)  -name '*.vhd' ! -name '*_pkg.vhd' | sort)
SRCS     := $(PKG_SRCS) $(RTL_SRCS) $(TB_SRCS)

# Make variables are case-sensitive, so `make sim top=foo` silently leaves TOP
# at its default and runs the wrong testbench. Catch the common miscasings.
ifneq ($(origin top),undefined)
  $(error use TOP=, not top= (make variables are case-sensitive))
endif
ifneq ($(origin tb),undefined)
  $(error use TB=, not tb=)
endif

GHDL      ?= ghdl
GHDLFLAGS := --std=$(STD) --workdir=$(BUILD)

VSG       ?= vsg
VSGCFG    ?= vsg_config.yaml
YOSYS     ?= yosys

.DEFAULT_GOAL := help

# ---- Simulation --------------------------------------------------------------

$(BUILD):
	@mkdir -p $(BUILD)

analyze: | $(BUILD)
	@$(GHDL) -a $(GHDLFLAGS) $(SRCS)

elaborate: analyze
	@$(GHDL) -e $(GHDLFLAGS) $(TB)

sim: elaborate
	@echo "sim: TOP=$(TOP) TB=$(TB)"
	@$(GHDL) -r $(GHDLFLAGS) $(TB) $(GENERICS)

wave: elaborate
	@$(GHDL) -r $(GHDLFLAGS) $(TB) $(GENERICS) --wave=$(BUILD)/$(TB).ghw
	@gtkwave $(BUILD)/$(TB).ghw >/dev/null 2>&1 &

# ---- Synthesis ---------------------------------------------------------------

# Elaborated from the analysed library, so these do not depend on where the
# source file lives. An inferred latch is a hard error, so a silent run is the
# latch check; --latches is deliberately never passed.
synth: analyze
	@$(GHDL) --synth $(GHDLFLAGS) $(TOP) > /dev/null \
		&& echo "$(TOP): 0 latches inferred"

netlist: analyze
	@$(GHDL) --synth $(GHDLFLAGS) --out=verilog $(TOP) > $(BUILD)/$(TOP).v

# Flip-flop count in BITS. GHDL names each inferred register nNN_q and declares
# it with its width, so the count is the sum of the declared widths. Counting
# `always` blocks or yosys $dff cells counts registers, not bits.
ff: netlist
	@grep -E "^[[:space:]]+reg .*_q;" $(BUILD)/$(TOP).v || true
	@grep -E "^[[:space:]]+reg .*_q;" $(BUILD)/$(TOP).v \
		| sed -E 's/.*reg \[([0-9]+):([0-9]+)\].*/\1-\2+1/; s/.*reg [a-zA-Z_].*/1/' \
		| paste -sd+ - | sed 's/^$$/0/' | bc \
		| xargs printf "$(TOP): %s flip-flops\n"

stat: netlist
	@$(YOSYS) -q -l $(BUILD)/yosys.log \
		-p "read_verilog $(BUILD)/$(TOP).v; prep -top $(TOP); stat"
	@awk '/^=== $(TOP) ===$$/{b=""; f=1; next} /^End of script/{f=0} \
		f{b = b $$0 "\n"} END{printf "%s", b}' $(BUILD)/yosys.log

schematic: netlist
	@$(YOSYS) -q -l $(BUILD)/yosys.log \
		-p "read_verilog $(BUILD)/$(TOP).v; prep -top $(TOP); \
		    show -format pdf -prefix $(BUILD)/$(TOP)_sch -viewer none"
	@echo "$(BUILD)/$(TOP)_sch.pdf"

# ---- Style -------------------------------------------------------------------

# -c is mandatory on both. VSG does not auto-discover a config, and its naming
# rules are disabled by default, so --fix without -c rewrites identifiers to
# the default convention and silently undoes the project style.
lint:
	@$(VSG) -c $(VSGCFG) -f $(SRCS)

fmt:
	@$(VSG) -c $(VSGCFG) --fix -f $(SRCS)

# ---- Gates -------------------------------------------------------------------

check: sim synth lint
	@echo "check: $(TOP) analysed, simulated, latch-free, style clean"

# ---- Housekeeping ------------------------------------------------------------

clean:
	@rm -rf $(BUILD)

help:
	@echo "targets: analyze elaborate sim wave synth netlist ff stat schematic"
	@echo "         lint fmt check clean"
	@echo "vars:    TOP=$(TOP) TB=$(TB) STD=$(STD) GENERICS="
	@echo "example: make check TOP=hack_alu"

.PHONY: analyze elaborate sim wave synth netlist ff stat schematic lint fmt \
	check clean help
