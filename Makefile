.PHONY: deltas delta clean help force

help:
	@echo ""
	@cat help.txt
	@echo ""

deltas: all.data

CC=avr-gcc
MCU=atmega128
AVRTEST_HOME=$(shell dirname `which avrtest`)

# What will be investigated.
FUNC=logf
LO="0.5"
HI="1-1"
OUT=float

# target delta
STEP=1
NUM=1

# targets plot.png / plot.svg
NX = 1000
DIM = 850,500
PIXX = $(shell bash -c 'cut -d, -f1 <<< "$(DIM)"')
PIXY = $(shell bash -c 'cut -d, -f2 <<< "$(DIM)"')

nums  := $(shell bash -c 'echo -n "$$(seq 0 $$(( '$(NUM)' - 1)) )"')
afunc := $(shell bash -c 'echo -n avrtest_$${0::-1}l' $(FUNC))

FLT = -Wl,-u,vfprintf -lprintf_flt

# $(info nums=$(nums))
$(info AVRTEST_HOME=$(AVRTEST_HOME))

dats := $(foreach num,$(nums),d-$(num).data)

exit_o := $(AVRTEST_HOME)/exit-$(MCU).o

CC_ARGS = -Os -mmcu=$(MCU) -o $@ -I$(AVRTEST_HOME) $(exit_o) -save-temps -dp

delta.elf: delta.c force
	$(CC) $< $(CC_ARGS) $(FLT) -DFUNC=$(FUNC) -DAFUNC=$(afunc) $(ARGS)
	avr-objdump -d $@ > delta.lst

plot.elf: plot.c config.h force
	$(CC) $< $(CC_ARGS) $(FLT) -DFUNC=$(FUNC) -DAFUNC=$(afunc) $(ARGS)
	avr-objdump -d $@ > plot.lst

config.h: gen-config.sh force
	./$< $(FUNC) > $@

force: ; @true

# What doesn't work as expected is to gather stderr outputs in individual
# files and then let a script print them in an orderly manner.  What
# doesn't work as expected is tee-ing stderr for /immediate/ output
# of delta.c messages like expected run time.
d-%.data : delta.elf
	avrtest -q ./$< $(AARGS) -args -num=$(NUM) -n=$* -lo="$(LO)" -hi="$(HI)" -step=$(STEP) -out=$(OUT) $(XARGS) > $@

plot.data : plot.elf
	avrtest -q ./$< $(AARGS) -args -nx=$(NX) -lo="$(LO)" -hi="$(HI)" -out=$(OUT) $(XARGS) | grep '^==' | sed -e 's:^==::' > $@

GPLOT_ARGS = -e pixx=\"$(PIXX)\" -e pixy=\"$(PIXY)\"

plot.svg : plot.data plot.gplot
	gnuplot $(GPLOT_ARGS) plot.gplot

plot.png : plot.data plot.gplot
	gnuplot $(GPLOT_ARGS) -e png_svg=\"png\" plot.gplot

all.data: force
	$(MAKE) -j$(NUM) $(dats)
	cat $(dats) > $@
	cat all.data

eval.x: eval.c
	gcc $< -O -o $@ -std=c99 -Wall -Werror -lm

delta: eval.x all.data
	cat all.data | ./eval.x -out=$(OUT)

clean:
	rm -f $(wildcard *.[isox] *.data *.elf *.lst config.h)
