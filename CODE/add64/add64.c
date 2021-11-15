volatile long long int r;

int main(void) {

	register long long int a = 3, b = 5;

	r = a + b;

	r = r << 1;

	return 0;
}
