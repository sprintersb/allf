This is a small C + Makefile project to work out aspects of the
quality of avr-gcc /
[AVR-LibC](https://avrdudes.github.io/avr-libc/) floating point implementation.
It uses the [AVRtest](https://github.com/sprintersb/atest) to
simulate a small C program that works out the relative errors.

## The maximal relative Error as a Graph

The `plot.svg` and `plot.png` targets can be used to generate a graphic
representation of the relative error of functions from math.h.
It requires [Gnuplot](http://www.gnuplot.info/). The example

![expf relative error over [-1,10] in ULPs](images/expf-m4-10-ulp.svg)

has been generated with
``` none
$ make plot.svg NX=50000 LO='-4' HI='10' DIM=600,400 OUT=ulp FUNC=expf
```
It shows the relative error of `expf` over the interval [-4, 10] in
[ULPs](https://en.wikipedia.org/wiki/Unit_in_the_last_place).

The recognized parameters can be displayey by running `make help`.
Supported functions are univariate float&rarr;float and
long double&rarr;long double functions from math.h.

## The maximal relative Error

The `delta` target can be ised to work out the maximal relative error
of a univariate floating point function from math.h.

It calculates the relative error for every value x in the specified
interval with a given ULP stride.  For example, a stride of 1 will
calculate the error for every x value in the interval.  This can be
quite time consuming since the function has to be evaluated at
up to 2<sup>32</sup> places.  To that end, the Makefile allows to
run the calculations in parallel.  Here is an example with 2 processes:

```none
$ nice -10 make delta NUM=2 LO=0.9 HI=1 STEP=1 FUNC=asinf
```
The output is something like:
```none
...
NUM=2: [9.000000e-01, 1.000000e+00] += 0x1
1677724 values = 0.84M/run = 0.39 min expected execution time
== 0/2: 0x3f667136: 9.001650e-01 -> 2.128456e-07
== 1/2: 0x3f66863b: 9.004857e-01 -> 2.127056e-07
eval: 0/2: 0x3f667136 = 9.001650e-01 -> 2.128456e-07  log10: -6.671935  log2: -22.163689
```
So the maximal relative error is around 2.128&middot;10<sup>-7</sup>
and is realized for a float value with hex representation 0x3f667136.

## Recognized Makefile Variables

```none
$ make help
```
```none
Specifying the function to investigate:
    FUNC=[logf]     Float function to investigate.
    LO=[0.5]        Lower / upper bound for the x values. A float
    HI=[1-1]        value like inf with an optional ULP addend.
    OUT=[float]     Output format: float or ulp.
How the target program is compiled:
    CC=[avr-gcc]    AVR compiler for the target program.
    MCU=[atmega128] AVR device under simulation.
    ARGS=           Extra arguments for the compiler.

The delta target
================

Determine the maximal relative error of a float function
FUNC over the interval [LO, HI] and with ulp stride STEP.
GNU make will spawn NUM processes running AVRtest.

Custom parameters:
    NUM=[1]         Number of parallel jobs.
    STEP=[1]        Stride for x in units of ULPs.
Example:
    nice -10 make delta NUM=2 LO=0.54 HI=0.55 FUNC=logf

The plot.png and plot.svg targets
=================================

Let Gnuplot produce a PNG resp. SVG graphic of the relative error
of a function FUNC over the interval [LO, HI].

Custom parameters:
    NX=[1000]       The number of equidistant x-values in [LO, HI].
    DIM=[850,500]   The size in pixels of the produced image.
Example:
    make plot.svg LO='-1' HI='10' FUNC=expf
```


