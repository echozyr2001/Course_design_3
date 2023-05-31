CC := gcc
CFLAGS := -g -Wall -D_FILE_OFFSET_BITS=64
OBJS := $(patsubst %.c, %.o, $(wildcard *.c))

LIBS := -lfuse

TARGET := oufs

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^ $(LIBS)

clean:
	rm -f $(TARGET) $(OBJS)
