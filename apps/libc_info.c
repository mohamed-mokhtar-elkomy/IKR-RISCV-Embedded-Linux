// Prints which C library this program was built against and runs with.
#include <stdio.h>

#ifdef __GLIBC__
#include <gnu/libc-version.h>
#endif

int main(void)
{
#ifdef __GLIBC__
	printf("C library: glibc %s (headers %d.%d)\n",
	       gnu_get_libc_version(), __GLIBC__, __GLIBC_MINOR__);
#else
	printf("C library: not glibc (likely musl)\n");
#endif
	return 0;
}
