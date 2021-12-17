#
# ser.py - simple serial printing script
#
# you need the serial module
#
import serial
ser = serial.Serial('/dev/ttyUSB0')  # open serial port
print(ser.name)         # check which port was really used
line = ser.readline()
print(line)
ser.write(b'hello\r\n')     # write a string
line = ser.readline()
print("%s" % line)
ser.close()             # close port

