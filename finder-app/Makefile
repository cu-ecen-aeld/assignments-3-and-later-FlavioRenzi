# Variables
CC = $(CROSS_COMPILE)gcc
CFLAGS = -Wall -Wextra -Werror
TARGET = writer

# Default target
all: $(TARGET)

# Build the writer application
$(TARGET): writer.c
	$(CC) $(CFLAGS) -o $(TARGET) writer.c

# Clean target
clean:
	rm -f $(TARGET) *.o

.PHONY: all clean
