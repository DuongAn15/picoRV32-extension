# Just run "make" to create ../src/mem_init.v

CFLAGS = -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles -O1
LDFLAGS = -Tlink_cmd.ld -Wl,-m,elf32lriscv

CC = riscv64-unknown-elf-gcc
OBJCOPY = riscv64-unknown-elf-objcopy
OBJDUMP = riscv64-unknown-elf-objdump

all: mem_init.v prog.hex conv_to_init

conv_to_init: conv_to_init.c
	gcc -o conv_to_init conv_to_init.c

mem_init.v: prog.bin conv_to_init
	rm -f ../src/mem_init.v
	./conv_to_init prog.bin > ../src/mem_init.v

main.o: main.c
	$(CC) $(CFLAGS) -c main.c

countdown_timer.o: countdown_timer.c
	$(CC) $(CFLAGS) -c countdown_timer.c

uart.o: uart.c
	$(CC) $(CFLAGS) -c uart.c

leds.o: leds.c
	$(CC) $(CFLAGS) -c leds.c

prog.elf: startup.s main.o countdown_timer.o uart.o leds.o
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^ -lgcc

prog.bin: prog.elf
	$(OBJCOPY) prog.elf -O binary prog.bin

prog.hex: prog.bin
	od -v -Ax -t x4 prog.bin > prog.hex

clean:
	rm -f prog.elf prog.hex prog.bin main.o conv_to_init countdown_timer.o uart.o leds.o

