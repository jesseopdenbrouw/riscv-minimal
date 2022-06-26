#include <stdio.h>
#include <errno.h>
#include <fcntl.h> 
#include <string.h>
#include <termios.h>
#include <unistd.h>
#include <stdlib.h>

int set_interface_attribs(int fd, int speed, int parity)
{
	struct termios tty;

	memset (&tty, 0, sizeof tty);

	if (tcgetattr(fd, &tty) != 0) {
	        printf("error %d from tcgetattr\n", errno);
	        return -1;
	}

	cfsetospeed(&tty, speed);
	cfsetispeed(&tty, speed);

	tty.c_cflag = (tty.c_cflag & ~CSIZE) | CS8;     // 8-bit chars
	// disable IGNBRK for mismatched speed tests; otherwise receive break
	// as \000 chars
	tty.c_iflag &= ~IGNBRK;         // disable break processing
	tty.c_lflag = 0;                // no signaling chars, no echo,
	                                // no canonical processing
	tty.c_oflag = 0;                // no remapping, no delays
	tty.c_cc[VMIN]  = 0;            // read doesn't block
	tty.c_cc[VTIME] = 5;            // 0.5 seconds read timeout

	tty.c_iflag &= ~(IXON | IXOFF | IXANY); // shut off xon/xoff ctrl

	tty.c_cflag |= (CLOCAL | CREAD);// ignore modem controls,
	                                // enable reading
	tty.c_cflag &= ~(PARENB | PARODD);      // shut off parity
	tty.c_cflag |= parity;
	tty.c_cflag &= ~CSTOPB;
	tty.c_cflag &= ~CRTSCTS;

	if (tcsetattr(fd, TCSANOW, &tty) != 0) {
	        printf("error %d from tcsetattr\n", errno);
	        return -1;
	}

	return 0;
}

void set_blocking(int fd, int should_block, int timeout)
{
	struct termios tty;

	memset(&tty, 0, sizeof tty);

	if (tcgetattr(fd, &tty) != 0) {
	        printf("error %d from tggetattr\n", errno);
	        return;
	}

	tty.c_cc[VMIN]  = should_block ? 1 : 0;
	tty.c_cc[VTIME] = timeout;            // 0.5 seconds read timeout

	if (tcsetattr(fd, TCSANOW, &tty) != 0)
	        printf("error %d setting term attributes\n", errno);
}

int main(int argc, char *argv[]) {

	/* The serial port */	
	char *portname = "/dev/ttyUSB0";
	/* Buffer... */
	char line[1000] = { 0 };
	/* Number of chars read in via port */
	int n;


	FILE *fin;
	int linenr = 0;

	/* Options */
	int opt;
	int verbose = 0;
	int timeout = 10;
	int jump = 0;
	int slepe = 0;

	/* Check for 0 extra arguments */
	if (argc == 1) {
		printf("upload -v -d <device> -t <timeout> filename\n");
		printf("Upload S-record file to THUAS RISC-V processor\n");
		printf("-v           -- verbose\n");
		printf("-j           -- run application after upload\n");
		printf("-d <device>  -- serial device\n");
		printf("-t <timeout> -- timeout in deci seconds\n");
		printf("-s <sleep>   -- sleep micro seconds after each character\n");
		exit(EXIT_SUCCESS);
	}

	/* Parse options */
	while ((opt = getopt(argc, argv, "vd:t:js:")) != -1) {
	        switch (opt) {
	        case 'd':
	            portname = optarg;
	            break;
	        case 'j':
	            jump = 1;
	            break;
	        case 'v':
	            verbose = 1;
	            break;
		case 't':
		    timeout = atoi(optarg);
		    if (timeout < 0) {
			    timeout = 0;
		    }
		    break;
		case 's':
		    slepe = atoi(optarg);
		    if (slepe < 0) {
			    slepe = 0;
		    }
		    break;
	        default: /* '?' */
		    fprintf(stderr, "Unknown option '%c'\n", opt);
	            exit(EXIT_FAILURE);
	        }
	}

	if (optind >= argc) {
	    fprintf(stderr, "Please supply an input filename\n");
	    exit(EXIT_FAILURE);
	}

	fin = fopen(argv[optind], "r");
	if (fin == NULL) {
		fprintf(stderr, "Cannot open input file %s\n", argv[optind]);
		exit (EXIT_FAILURE);
	}

	if (verbose) {
		printf("Serial port is: %s\n", portname);
	}

	/* Open the device */	
	int fd = open(portname, O_RDWR | O_NOCTTY | O_SYNC);

	/* Check if device is open */
	if (fd < 0) {
	        printf("error %d opening %s: %s\n", errno, portname, strerror (errno));
		return -1;
	}

	/* Set transmission parameters */
	set_interface_attribs(fd, B9600, 0);
	/* Set non-blocking */
	set_blocking(fd, 0, timeout);

	/* Write the ! to start uploading */
	printf("Sending '!'... ");
	fflush(stdout);
	n = write(fd, "!", 1);

	/* Read in data from device */
	while (1) {
		n = read(fd, line, 1);
		if (n == 0) {
			break;
		}
		if (line[0] == '\n') {
			break;
		}
	}

	if (n == 0) {
		printf("Cannot contact bootloader!\n");
		exit(-2);
	} else {
		printf("OK\n");
	}


	while (fgets(line, sizeof line - 2, fin)) {
		linenr++;
		printf("Write ");
		fflush(stdout);
		for (int i=0; i < strlen(line); i++) {
			n = write(fd, line+i, 1);
			if (line[i] != '\n' && line[i] != '\r') {
				printf("%c", line[i]);
			}
			fflush(stdout);
			usleep(slepe);
		}
		memset(line, 0, sizeof line);
		/* Read in data from device */
		while (1) {
			n = read(fd, line, 1);
			if (n == 0) {
				break;
			}
			if (line[0] == '\n') {
				break;
			}
		}
		if (n == 0) {
			printf("Nothing read while sending data!\n");
			exit(-3);
		} else {
			printf("  OK\n");
		}
	}

	usleep(1000);

	if (jump) {
		printf("Write 'J' ");
		n = write(fd, "J", 1);
	} else {
		printf("Write '#' ");
		n = write(fd, "#", 1);
	}

	/* Read in data from device */
	while (1) {
		n = read(fd, line, 1);
		if (n == 0) {
			break;
		}
		if (line[0] == '\n') {
			break;
		}
	}
	if (n == 0) {
		printf("Nothing read while sending end of transmission!\n");
		exit(-3);
	} else {
		printf("  OK\n");
	}


	/* Close devices */
	close(fd);
	fclose(fin);
}
