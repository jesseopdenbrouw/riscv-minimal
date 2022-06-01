#include <msp430.h> 

class Uart {
protected:
    Uart();
public:
    Uart(Uart const &) = delete;
    Uart &operator=(Uart const &) = delete;
    static Uart& getUart0();
    static Uart& getUart1();
    virtual char getc(void) const = 0;
    virtual void putc(char c) const = 0;
    void putstring(const char* s) const;
};

class Uart0: public Uart {
private:
    Uart0();
    friend class Uart;
public:
    virtual char getc(void) const override;
    virtual void putc(char c) const override;
};

class Uart1: public Uart {
private:
    Uart1();
    friend class Uart;
public:
    virtual char getc(void) const override;
    virtual void putc(char c) const override;
};

Uart::Uart() {
    // eventueel gemeenschappelijke init code
}

Uart& Uart::getUart0() {
    static Uart0 uart;
    return uart;
}
Uart& Uart::getUart1() {
    static Uart1 uart;
    return uart;
}


Uart0::Uart0() {
    UCA0CTL1 |= UCSWRST;
    UCA0CTL0 = 0;
    UCA0CTL1 = UCSSEL_2 | UCSWRST;
    UCA0BR0 = 6;
    UCA0BR1 = 0;
    UCA0MCTL = UCBRS_0 | UCBRF_8 | UCOS16;
    P1SEL |= BIT2 | BIT1;
    P1SEL2 |= BIT2 | BIT1;
    UCA0CTL1 &= ~UCSWRST;
}

Uart1::Uart1() {
    // Hier init voor Uart1
    // die zit niet in mijn MSP430 dus alleen commentaar
    //UCA1CTL1 |= UCSWRST;
    //UCA1CTL0 = 0;
    // enz
}

char Uart0::getc(void) const
{
    while ((IFG2 & UCA0RXIFG) == 0);
    char c = UCA0RXBUF;
    return c;
}

char Uart1::getc(void) const
{
    //while ((IFG2 & UCA1RXIFG) == 0);
    //char c = UCA1RXBUF;
    //return c;
    return 'd';
}

void Uart0::putc(char c) const
{
    while ((IFG2 & UCA0TXIFG) == 0);
    UCA0TXBUF = c;
}

void Uart1::putc(char c) const
{
    //while ((IFG2 & UCA1TXIFG) == 0);
    //UCA1TXBUF = c;
}

void Uart::putstring(const char* s) const
{
    while (*s != '\0')
    {
        putc(*s++);
    }
}

int main(void)
{
    WDTCTL = WDTPW | WDTHOLD; // stop watchdog timer
    // DCO = 1 MHz
    DCOCTL = 0;
    BCSCTL1 = CALBC1_1MHZ; // Set range
    DCOCTL = CALDCO_1MHZ; // Set DCO step + modulation

    Uart& uart0 = Uart::getUart0();

    uart0.putstring("Echo> ");
    while (1)
    {
        char c = uart0.getc();
        uart0.putc(c);
        if (c == '\r')
        {
            uart0.putstring("\nEcho> ");
        }
    }
    return 0;
}
