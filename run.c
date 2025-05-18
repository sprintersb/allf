#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdarg.h>
#include <string.h>
#include <ctype.h>
#include <math.h>

#include "avrtest.h"

int N = 0;   // In [0, Num).
int Num = 0; // Size of the cohort.
float Lo = 0.5, Hi = 1.5;
uint32_t Step = 1;

#ifndef FUNC
#define FUNC logf
#endif

#define avrtest_(X) avrtest_##X
#define AFUNC_(X) avrtest_(X)
#define AFUNC AFUNC_(FUNC)

#define stringy_(X) #X
#define stringy(X) stringy_(X)

void error (const char *msg, ...)
{
    va_list args;
    va_start (args, msg);
    fprintf (stderr, "\nerror: ");
    vfprintf (stderr, msg, args);
    fprintf (stderr, "\n");
    va_end (args);

    exit (1);
}

void info (const char *msg, ...)
{
    va_list args;
    va_start (args, msg);
    vfprintf (stderr, msg, args);
    va_end (args);
}

static inline float utof (uint32_t u)
{
    float f;
    __builtin_memcpy (&f, &u, 4);
    return f;
}

static inline uint32_t ftou (float f)
{
    uint32_t u;
    __builtin_memcpy (&u, &f, 4);
    return u;
}

static inline bool is_prefix (const char *pre, const char *s)
{
    return 0 == strncmp (pre, s, strlen (pre));
}

static inline bool is_last (void)
{
    return N == Num - 1;
}

static bool get_int (const char *arg, const char *prefix, int *pi)
{
    if (! is_prefix (prefix, arg))
        return false;
    *pi = atoi (arg + strlen (prefix));
    return true;
}

static bool get_u32 (const char *arg, const char *prefix, uint32_t *pi)
{
    if (! is_prefix (prefix, arg))
        return false;
    *pi = (uint32_t) atol (arg + strlen (prefix));
    return true;
}

/* Recognize sum of 2 terms: 1st is float, 2nd is ulong (float as bits).
   For example, the smallest float > 0 can be written as "0+1" or "0+0x1". */

static bool get_float (const char *arg, const char *prefix, float *pf)
{
    char *pend, *pend2;
    if (! is_prefix (prefix, arg))
        return false;
    *pf = avrtest_strtof (arg + strlen (prefix), &pend);

    if (*pend)
    {
        while (isspace (*pend))
            ++pend;

        if (*pend != '+' && *pend != '-')
            error ("unrecognized float in %s\n", arg);

        uint32_t add = strtoul (1 + pend, &pend2, 0);
        if (*pend2)
            error ("unrecognized float in %s\n", arg);
        uint32_t fu = ftou (*pf);
        *pf = utof (*pend == '+' ? fu + add : fu - add);
    }

    return true;
}

static float get_delta (float x)
{
    float y0 = AFUNC (x);
    float y = FUNC (x);
    float ulp = avrtest_ulpf (y, y0);
    if (avrtest_cmpf (ulp, 0) == 0)
        return 0;

    float d = avrtest_subf (y, y0);
    return avrtest_divf (d, y0);
}

static inline float f_incr (float x, uint32_t s)
{
    return utof (ftou (x) + s);
}

void show_time (float secs)
{
}

void show_expected_runtime (int n_loops)
{
    uint32_t cyc = avrtest_cycles ();

    uint32_t n_xs = (ftou (Hi) - ftou (Lo)) / Step + 1;
    info ("%lu values = ", n_xs);
    n_xs = 1 + n_xs / Num;
    if (n_xs > 500000)
        info ("%.2fM", n_xs / 1e6f);
    else if (n_xs > 500)
        info ("%.2fk", n_xs / 1e3f);
    else
        info ("%lu", n_xs);
    info ("/run = %.2f min expected execution time\n",
             // Assume 90MHz AVRtest performace.
             n_xs / (90e6f * 60.0f * n_loops) * cyc);
}


float get_minmax (float *px)
{
    uint32_t inc = Step * Num;
    float d_mi = +1000;
    float d_ma = -1000;
    float mami = 0;
    uint32_t cnt = 0;

    avrtest_reset_cycles ();

    for (float x = f_incr (Lo, Step * N);
         avrtest_cmpf (x, Hi) <= 0;
         x = f_incr (x, inc))
    {
        if (is_last() && cnt++ == 100)
            show_expected_runtime (100);
        float d = get_delta (x);
        d_ma = avrtest_fmaxf (d, d_ma);
        d_mi = avrtest_fminf (d, d_mi);

        d = avrtest_fmaxf (d_ma, -d_mi);
        if (avrtest_cmpf (d, mami) > 0)
        {
            mami = d;
            *px = x;
        }
    }

    return mami;
}

int main (int argc, char *argv[])
{
    for (int i = 1; i < argc; ++i)
        if (get_int (argv[i], "-n=", &N))
            break;

    if (N == 0)
        info ("FUNC = %s\n", stringy(FUNC));

    for (int i = 1; i < argc; ++i)
    {
        if (N == 0)
            info ("argv[%d] = '%s'\n", i, argv[i]);

        if (! get_int (argv[i], "-n=", &N)
            && ! get_int (argv[i], "-num=", &Num)
            && ! get_float (argv[i], "-lo=", &Lo)
            && ! get_float (argv[i], "-hi=", &Hi)
            && ! get_u32 (argv[i], "-step=", &Step))
        {
            error ("unknown option %s\n", argv[i]);
        }
    }

    if (N < 0 || N >= Num)
        error ("N=%d not in [0, Num=%d)", N, Num);
    if (Lo > Hi)
        error ("Lo=%e > Hi=%e\n", Lo, Hi);

    if (N == 0)
        info ("NUM=%d: [%e, %e] += 0x%lx\n", Num, Lo, Hi, Step);

    float x = nan("");
    float mami = get_minmax (&x);
    printf ("== %d/%d: 0x%08lx: %e -> %e\n", N, Num, ftou(x), x, mami);

    return 0;
}
