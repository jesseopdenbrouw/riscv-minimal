volatile long int w;
volatile long int x;
volatile long int y;
volatile long int z = -1;

volatile long long int r = 4;

long int ary[] = { 2, 5 ,7, 8 , 9};

int main(void) {

	//register long long int a = 14, b = 7;

	//r = a + b;

	z = -1;
	
	r = r + r;

	z = z + z;

	return 0;
}
