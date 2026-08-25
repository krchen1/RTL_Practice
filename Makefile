########################################################################
# RTL Practice Set - Makefile (Questa/ModelSim flow, NCSU ECE servers)
#
# Usage:
#   make test Q=q1        Compile + simulate a single question
#   make test-all         Run every question and print a PASS/FAIL summary
#   make gui Q=q1         Same as `test` but opens the Questa waveform GUI
#   make clean            Remove all generated work/ dirs and transcripts
#   make clean Q=q1       Remove generated files for a single question
#
# Requires the "questa" environment module (Lmod). The recipes below load
# it automatically via `module load questa`; edit QUESTA_MOD below if your
# server needs a specific version (e.g. questa/2024.2).
########################################################################

SHELL := /bin/bash
QUESTA_MOD := questa

QUESTIONS := $(sort $(patsubst %/,%,$(wildcard q[0-9]*/)))

.PHONY: test test-all gui clean help

help:
	@echo "Targets:"
	@echo "  make test Q=qN      - compile & simulate question N"
	@echo "  make test-all       - run all questions, print summary"
	@echo "  make gui Q=qN       - open question N in the Questa GUI"
	@echo "  make clean [Q=qN]   - remove generated sim files"

test:
ifndef Q
	$(error Usage: make test Q=qN   e.g. make test Q=q1)
endif
	@source /etc/profile; \
	module load $(QUESTA_MOD); \
	cd $(Q); \
	rm -rf work transcript; \
	vlib work; \
	vlog -sv -quiet $(Q).sv $(Q)_tb.sv && \
	vsim -c -do "run -all; quit -f" $(Q)_tb

gui:
ifndef Q
	$(error Usage: make gui Q=qN   e.g. make gui Q=q1)
endif
	@source /etc/profile; \
	module load $(QUESTA_MOD); \
	cd $(Q); \
	rm -rf work transcript; \
	vlib work; \
	vlog -sv -quiet $(Q).sv $(Q)_tb.sv && \
	vsim -do "run -all" $(Q)_tb

test-all:
	@source /etc/profile; \
	module load $(QUESTA_MOD); \
	pass=0; fail=0; \
	for q in $(QUESTIONS); do \
		printf "%-6s ... " "$$q"; \
		( cd $$q && rm -rf work transcript && vlib work >/dev/null && \
		  vlog -sv -quiet $$q.sv $${q}_tb.sv && \
		  vsim -c -do "run -all; quit -f" $${q}_tb ) > /tmp/$$q.sim.log 2>&1; \
		if grep -q "TEST PASSED" /tmp/$$q.sim.log; then \
			echo "PASS"; pass=$$((pass+1)); \
		else \
			echo "FAIL"; fail=$$((fail+1)); \
		fi; \
	done; \
	echo "----------------------------------------"; \
	echo "Summary: $$pass passed, $$fail failed (see /tmp/<q>.sim.log for details)"

clean:
ifdef Q
	rm -rf $(Q)/work $(Q)/transcript $(Q)/*.wlf
else
	rm -rf q*/work q*/transcript q*/*.wlf
endif
