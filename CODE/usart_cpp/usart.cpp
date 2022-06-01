#include <cstdio>

#include "io.h"

#define SYSTEM_FREQ (50000000UL)
#define BAUD_RATE (9600UL)

/* The Usart class */
class Usart {
	protected:
		Usart();
	public:
		Usart(Usart const &) = delete;
		Usart &operator=(Usart const &) = delete;
		static Usart& getUsart1();
		virtual void putchar(char c) const = 0;
		void print(const char* s) const;
};

/* USART1 class */
class Usart1: public Usart {
	private:
		Usart1();
    	friend class Usart;
	public:
		virtual void putchar(char c) const override;
};

/* Generic init code */
Usart::Usart() {
}

/* Get USART1 instance */
Usart& Usart::getUsart1() {
	static Usart1 usart;
	return usart;
}

Usart1::Usart1() {
	USART->BAUD = SYSTEM_FREQ/BAUD_RATE - 1;
}


/* Prints a character to the USART */
void Usart1::putchar(char c) const
{
        /* Transmit data */
        USART->DATA = (uint8_t) c;
                
        /* Wait for transmission end */
        while ((USART->STAT & 0x10) == 0);
}

/* Prints a string */
void Usart::print(const char *s) const
{
	if (s == NULL) {
		return;
	}

	while (*s != '\0') {
		putchar(*s++);
	}
}


int main(void)
{
	Usart& usart1 = Usart::getUsart1();

	usart1.print("Hello\r\n");
}
