/*
 * program to test trigoniometry functions
 * on the processor. Due to large ROM contents
 * we need to select the functions used.
 *
 */

#include <math.h>

int main(void)
{
/*
	volatile float w = 1.0f;
      	volatile x;

	x = sinf(w);

	x = asinf(w);

	x = logf(w);

*/
	volatile double y = 1.0;
	volatile double z;

	z = sin(y);

/*
	z = asin(y);

	z = log(y);
*/
	return 0;
}
