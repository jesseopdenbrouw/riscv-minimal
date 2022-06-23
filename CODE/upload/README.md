
# upload

This program uploads an S-record file to the THUAS RISC-V processor.
For use with the onboard bootloader. After reset, the bootloader
waits for about 5 seconds @ 50 MHz for `upload` to contact. Start
the `upload` program within these 5 seconds and the S-record file
will be transferred. Currently, the transmission speed is fixed
at 9600 bps.

Usage:

    upload -d <device> -t <timeout> srec-file

Default device is /dev/ttyUSB0
timeout in deci seconds (0.1 sec)
