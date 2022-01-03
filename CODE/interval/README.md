# Clock

Simple clock that counts from the last reset.
it uses the gettimeofday function call.
The clock is implemented via the CSR registers
TIME and TIMEH. It needs the USART to transmit
data.

We use the `clock` function to create a delay
of 5 seconds. Note that `clock` uses an unsigned
32-bit value and wrappes every 4294.967296
seconds, about every 71.5 minutes.

# Status

Works on the board
