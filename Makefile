.PHONY: all run eval clean help

help:
	@echo ""
	@echo "Specifying the level of parallelization:"
	@echo "    NUM=[1]         Level of parallelization and number of jobs."
	@echo "Specifying the function under investigation:"
	@echo "    FUNC=[logf]     Float function to investigate."
	@echo "    LO=[0.5]        Lower / upper bound for the x values. A float"
	@echo "    HI=[1-1]        value like inf with an optional ULP addend."
	@echo "    STEP=[1]        Only each step-th x (ULP) will be investigated."
	@echo "    OUT=[float]     Output format: float or ulp."
	@echo "Specifying how the target program is compiled:"
	@echo "    CC=[avr-gcc]    AVR compiler for the target program."
	@echo "    MCU=[atmega128] AVR device under simulation."
	@echo "    ARGS=           Extra arguments for the compiler."
	@echo "Specifying how the target program is being run:"
	@echo "    AARGS=          Extra arguments for AVRtest."
	@echo "    XARGS=          Extra arguments for the simulated program."
	@echo "Example:"
	@echo "    make clean ; nice -10 make eval NUM=2 LO=0.54 HI=0.55 FUNC=logf"
	@echo ""

run: all.data

# What will be investigated.
FUNC=logf
LO="0.5"
HI="1-1"
STEP=1
OUT=float

NUM=1

CC=avr-gcc
MCU=atmega128

AVRTEST_HOME=$(shell dirname `which avrtest`)

nums  := $(shell bash -c 'echo -n "$$(seq 0 $$(( '$(NUM)' - 1)) )"')
afunc := $(shell bash -c 'echo -n avrtest_$${0::-1}l' $(FUNC))

FLT = -Wl,-u,vfprintf -lprintf_flt

$(info nums=$(nums))
$(info AVRTEST_HOME=$(AVRTEST_HOME))

elf = run.elf
dats := $(foreach num,$(nums),d-$(num).data)

all: $(elf)

exit_o := $(AVRTEST_HOME)/exit-$(MCU).o

run.elf: run.c
	$(CC) $< -Os -mmcu=$(MCU) -o $@ -I$(AVRTEST_HOME) $(exit_o) $(FLT) -save-temps -dp -dumpbase "" -DFUNC=$(FUNC) -DAFUNC=$(afunc) $(ARGS)

# What doesn't wor as expected is to gather stderr outputs in individual
# files and then let a acript print them in an orderly manner.  What
# doesn't work as expected is tee-ing stderr for /immediate/ output
# of run.c messages like expected run time.
d-%.data : run.elf
	avrtest -q ./$< $(AARGS) -args -num=$(NUM) -n=$* -lo="$(LO)" -hi="$(HI)" -step=$(STEP) -out=$(OUT) $(XARGS) > $@

.PHONY: all-data

all.data: all-data

all-data:
	$(MAKE) -j$(NUM) $(dats)
	cat $(dats) > all.data
	cat all.data

eval.x: eval.c
	gcc $< -O -o $@ -std=c99 -Wall -Werror -lm

eval: eval.x all.data
	cat all.data | ./eval.x -out=$(OUT)

clean:
	rm -f $(wildcard *.[isox] *.data *.elf)
