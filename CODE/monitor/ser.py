#
# ser.py - simple serial printing script
#
# you need the serial module
#
import serial
import sys

port = "/dev/ttyUSB0"

try:
    ser = serial.Serial(port, baudrate=9600, timeout=1)  # open serial port

except:
    print("Error opening device!")
    sys.exit("Bailing out!")

print("Device = %s" % ser.name)         # check which port was really used

try: 
    line = ser.readline()

except:
    print("Error reading from device!")
    sys.exit("Bailing out!")

sys.stdout.buffer.write(line)

try:
    ser.write(b'hello\r\n')     # write a string

except:
    print("Error writing to device!")
    ser.close()             # close port
    sys.exit("Bailing out!")

try: 
    line = ser.readline()

except:
    print("Error reading from device!")
    ser.close()             # close port
    sys.exit("Bailing out!")

sys.stdout.buffer.write(line)
ser.close()             # close port

