.PHONY: all deltas delta clean help

help:
	@echo ""
	@cat help.txt
	@echo ""

deltas: all.data

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

elf = delta.elf
dats := $(foreach num,$(nums),d-$(num).data)

all: $(elf)

exit_o := $(AVRTEST_HOME)/exit-$(MCU).o

delta.elf: delta.c
	$(CC) $< -Os -mmcu=$(MCU) -o $@ -I$(AVRTEST_HOME) $(exit_o) $(FLT) -save-temps -dp -dumpbase "" -DFUNC=$(FUNC) -DAFUNC=$(afunc) $(ARGS)
	avr-objdump -d $@ > delta.lst

# What doesn't work as expected is to gather stderr outputs in individual
# files and then let a script print them in an orderly manner.  What
# doesn't work as expected is tee-ing stderr for /immediate/ output
# of delta.c messages like expected run time.
d-%.data : delta.elf
	avrtest -q ./$< $(AARGS) -args -num=$(NUM) -n=$* -lo="$(LO)" -hi="$(HI)" -step=$(STEP) -out=$(OUT) $(XARGS) > $@

.PHONY: all-data

all.data: all-data

all-data:
	$(MAKE) -j$(NUM) $(dats)
	cat $(dats) > all.data
	cat all.data

eval.x: eval.c
	gcc $< -O -o $@ -std=c99 -Wall -Werror -lm

delta: eval.x all.data
	cat all.data | ./eval.x -out=$(OUT)

clean:
	rm -f $(wildcard *.[isox] *.data *.elf *.lst)
