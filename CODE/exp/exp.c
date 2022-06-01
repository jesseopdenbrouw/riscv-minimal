/*
 * float.c -- Some simple test to see if the float libs are
 *            working correctly. Calculations are done with
 *            software functions.
 *
 *
 *
 *
 */

volatile float e = 0.0f;
volatile float fac = 1.0f;

int main(void)
{
	int i;

	for (i = 1; i<20; i++)
	{
		e = e + 1.0f/fac;
		fac = fac * i;
	}

	return 0;
}
