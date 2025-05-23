.PHONY: all run eval clean help

help:
	@echo ""
	@echo "Specifying the level of parallelization:"
	@echo "    NUM=[1]         Level of parallelization."
	@echo "Specifying the function under investigation:"
	@echo "    FUNC=[logf]     Float function to investigate."
	@echo "    LO=[0.5]        Lower / upper bound for the x values. It's"
	@echo "    HI=[1-1]        a float value with an optional ULP addend."
	@echo "    STEP=[1]        Only each step-th x will be investigated."
	@echo "Specifying how the target program is compiled:"
	@echo "    CC=[avr-gcc]    AVR compiler for the target program."
	@echo "    MCU=[atmega128] AVR device under simulation."
	@echo "    ARGS=           Extra arguments for the compiler."
	@echo "Specifying how the target program is being run:"
	@echo "    AARGS=          Extra arguments for AVRtest."
	@echo "    XARGS=          Extra arguments for the simulated program."
	@echo "Example:"
	@echo "    make clean ; nice -10 make eval -j2 NUM=2 LO=0.54 HI=0.55 FUNC=logf"
	@echo ""

run: all.data

# What will be investigated.
FUNC=logf
LO="0.5"
HI="1-1"
STEP=1

NUM=1

CC=avr-gcc
MCU=atmega128

AVRTEST_HOME=$(shell dirname `which avrtest`)

nums  := $(shell ./nums.sh $(NUM))
afunc := $(shell ./afunc.sh $(FUNC))

FLT = -Wl,-u,vfprintf -lprintf_flt

$(info $(nums))
$(info AVRTEST_HOME=$(AVRTEST_HOME))

elf = run.elf
dats := $(foreach num,$(nums),d-$(num).data)

all: $(elf)

run.elf: run.c
	$(CC) $< -Os -mmcu=$(MCU) -o $@ -I$(AVRTEST_HOME) $(AVRTEST_HOME)/exit-$(MCU).o $(FLT) -save-temps -dp -dumpbase "" -DFUNC=$(FUNC) -DAFUNC=avrtest_$(afunc)l $(ARGS)

d-%.data : run.elf
	avrtest -q ./$< $(AARGS) -args -num=$(NUM) -n=$* -lo="$(LO)" -hi="$(HI)" -step=$(STEP) $(XARGS) > $@

all.data: $(dats)
	cat $^ > $@
	cat $@

eval.x: eval.c
	gcc $< -O -o $@ -std=c99 -Wall -Werror -lm

eval: eval.x all.data
	cat all.data | ./eval.x

clean:
	rm -f $(wildcard *.[isox] *.data *.elf)
