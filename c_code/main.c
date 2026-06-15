/* Copyright 2024 Grug Huhler.  License SPDX BSD-2-Clause.

   This program shows counting on the LEDs of the Tang Nano
   9K FPGA development board.

   Function foo lets one see stores of different size and alignment by
   looking at the wstrb signals from the pico32rv.
*/

#include "leds.h"
#include "uart.h"
#include "countdown_timer.h"

// ============================
// DSP Extension Macros
// Opcode: 0x0B (CUSTOM-0)
// funct7: 7 (0000111)
// funct3: 0 (PADDS16), 1 (PSUBS16), 2 (PMAC16)
// ============================
#define PADDS16(rd, rs1, rs2) \
    __asm__ volatile ( \
        ".insn r 0x0B, 0, 7, %0, %1, %2" \
        : "=r" (rd) \
        : "r" (rs1), "r" (rs2) \
    )

#define PSUBS16(rd, rs1, rs2) \
    __asm__ volatile ( \
        ".insn r 0x0B, 1, 7, %0, %1, %2" \
        : "=r" (rd) \
        : "r" (rs1), "r" (rs2) \
    )

#define PMAC16(rd, rs1, rs2) \
    __asm__ volatile ( \
        ".insn r 0x0B, 2, 7, %0, %1, %2" \
        : "+r" (rd) \
        : "r" (rs1), "r" (rs2) \
    )

// ============================
// Cycle counter
// ============================
static inline unsigned int rdcycle() {
    unsigned int c;
    asm volatile ("rdcycle %0" : "=r"(c));
    return c;
}


void uart_print_dec(unsigned int x)
{
    char buf[12];
    int i = 0;

    if (x == 0) {
        uart_putchar('0');
        return;
    }

    while (x > 0) {
        buf[i++] = '0' + (x % 10);
        x /= 10;
    }

    while (i > 0) {
        uart_putchar(buf[--i]);
    }
}


// ============================
// DSP Tests and Benchmark
// ============================

void test_dsp() {
    uart_puts("\n===== DSP Instruction Tests =====\r\n");
    int a = 0x7FFF0001; // 32767 (hi), 1 (lo)
    int b = 0x00010002; // 1 (hi), 2 (lo)
    int res = 0;

    PADDS16(res, a, b);
    uart_puts("PADDS16 (7FFF0001 + 00010002) = ");
    uart_print_hex(res);
    uart_puts(" (Expected: 7FFF0003)\r\n");

    PSUBS16(res, a, b);
    uart_puts("PSUBS16 (7FFF0001 - 00010002) = ");
    uart_print_hex(res);
    uart_puts(" (Expected: 7FFEFFFF)\r\n");

    res = 10;
    PMAC16(res, a, b);
    uart_puts("PMAC16 (10 + 1 * 2) = ");
    uart_print_hex(res);
    uart_puts(" (Expected: 0000000C)\r\n");
}

#define FIR_TAPS 16
#define DATA_LEN 100

short coeffs[FIR_TAPS] = {
    1, 2, 3, 4, 5, 6, 7, 8,
    8, 7, 6, 5, 4, 3, 2, 1
};

short input_data[DATA_LEN];
int output_std[DATA_LEN];
int output_dsp[DATA_LEN];

void init_data() {
    for (int i = 0; i < DATA_LEN; i++) {
        input_data[i] = (i % 20) - 10;
    }
}

void benchmark_fir() {
    init_data();

    uart_puts("\n===== FIR Filter Benchmark =====\r\n");

    // ----- Standard C -----
    unsigned int t1 = rdcycle();
    for (int i = FIR_TAPS - 1; i < DATA_LEN; i++) {
        int acc = 0;
        for (int j = 0; j < FIR_TAPS; j++) {
            acc += input_data[i - j] * coeffs[j];
        }
        output_std[i] = acc;
    }
    unsigned int t2 = rdcycle();
    unsigned int std_cycles = t2 - t1;

    // ----- DSP Extension -----
    t1 = rdcycle();
    for (int i = FIR_TAPS - 1; i < DATA_LEN; i++) {
        int acc = 0;
        for (int j = 0; j < FIR_TAPS; j++) {
            int a = input_data[i - j];
            int b = coeffs[j];
            PMAC16(acc, a, b);
        }
        output_dsp[i] = acc;
    }
    t2 = rdcycle();
    unsigned int dsp_cycles = t2 - t1;

    // ----- Verify Output -----
    int errors = 0;
    for (int i = FIR_TAPS - 1; i < DATA_LEN; i++) {
        if (output_std[i] != output_dsp[i]) {
            errors++;
        }
    }

    uart_puts("Standard Cycles: ");
    uart_print_dec(std_cycles);
    uart_puts("\r\n");

    uart_puts("DSP Cycles:      ");
    uart_print_dec(dsp_cycles);
    uart_puts("\r\n");

    if (errors == 0) {
        uart_puts("Verification:    PASSED\r\n");
    } else {
        uart_puts("Verification:    FAILED (");
        uart_print_dec(errors);
        uart_puts(" errors)\r\n");
    }
}





/* The picorv32 core implements several counters and
   instructions to access them.  These are part of the
   risc-v specification.  Function readtime uses one
   of them.
*/

static inline unsigned int readtime(void)
{
  unsigned int val;
  unsigned long long jj;
  asm volatile("rdcycle %0" : "=r" (val));
  return val;

}

void endian_test(volatile unsigned int *addr)
{
  volatile unsigned char *cp0, *cp3;
  char byte0, byte3;
  unsigned int i, ok;

  cp0 = (volatile unsigned char *) addr;
  cp3 = cp0 + 3;
  *addr = 0x44332211;
  byte0 = *cp0;
  byte3 = *cp3;
  *cp3 = 0xab;
  i = *addr;

  ok = (byte0 == 0x11) && (byte3 == 0x44) && (i == 0xab332211);
  uart_puts("\r\nEndian test: at ");
  uart_print_hex((unsigned int) addr);
  uart_puts(", byte0: ");
  uart_print_hex((unsigned int) byte0);
  uart_puts(", byte3: ");
  uart_print_hex((unsigned int) byte3);
  uart_puts(",\r\n     word: ");
  uart_print_hex(i);
  if (ok)
    uart_puts(" [PASSED]\r\n");
  else
    uart_puts(" [FAILED]\r\n");
}

void uart_rx_test(void)
{
  char buf[5];
  int i;
  
  uart_puts("Type 4 characters (they will echo): ");
  for (i = 0; i < 4; i++) {
    buf[i] = uart_getchar();
    uart_putchar(buf[i]);
  }
  buf[4] = 0;
  uart_puts("\r\nUART read: ");
  uart_puts(buf);
  uart_puts("\r\n");
}

/* la_functions are useful for looking at the bus using a logic
   analyzer.
*/

void la_wtest(void)
{
  unsigned int v;
  volatile unsigned int *ip = (volatile unsigned int *) &v;
  volatile unsigned short *sp = (volatile unsigned short *) &v;
  volatile unsigned char *cp = (volatile unsigned char *) &v;

  *ip = 0x03020100;  // addr 0x00

  *sp = 0x0302;      // addr 0x00
  *(sp+1) = 0x0100;  // addr 0x02

  *cp = 0x03;        // addr 0x00
  *(cp+1) = 0x02;    // addr 0x01
  *(cp+2) = 0x01;    // addr 0x02
  *(cp+3) = 0x00;    // addr 0x03
}


void la_rtest(void)
{
  unsigned int v;
  volatile unsigned int *ip = (volatile unsigned int *) &v;
  volatile unsigned short *sp = (volatile unsigned short *) &v;
  volatile unsigned char *cp = (volatile unsigned char *) &v;

  *ip = 0x03020100;  // addr 0x00

  *ip;     // addr 0x00

  *sp;     // addr 0x00
  *(sp+1); // addr 0x02

  *cp;     // addr 0x00
  *(cp+1); // addr 0x01
  *(cp+2); // addr 0x02
  *(cp+3); // addr 0x03
}


void cdt_test(void)
{
  unsigned int val;
  unsigned int test_errors = 0;
  
  // If register is little-endian, write to 0x80000013 should set
  // the MSB,  Does it?

  cdt_wbyte3(0xff);
  val = cdt_read();
  if ((val == 0xff000000) || (val < 0xfe000000)) test_errors = 1;

  // Write zero to most significant half-word.
  cdt_whalf2(0);
  val = cdt_read();
  if (val > 0xffff) test_errors |= 2;

  uart_puts("Countdown timer test ");
  if (test_errors) {
    uart_puts("FAILED, mask = ");
    uart_print_hex(test_errors);
    uart_puts("\r\n");
  } else {
    uart_puts("PASSED\r\n");
  }
  
#if 0
  /* These are interesting to see on the logic analyzer */
  cdt_wbyte3(0x3);       // addr 0x80000013
  cdt_wbyte2(0x2);       // addr 0x80000012
  cdt_wbyte1(0x1);       // addr 0x80000011
  cdt_wbyte0(0x0);       // addr 0x80000010
  cdt_whalf2(0x0302);    // addr 0x80000012
  cdt_whalf0(0x0100);    // addr 0x80000010
  cdt_write(0x00010203); // addr 0x80000010
  cdt_write(0x01020300); // addr 0x80000010
  cdt_write(0x02030001); // addr 0x80000010
  cdt_write(0x03000102); // addr 0x80000010
#endif
}

int main()
{
  int i;
  unsigned char v, ch;

  set_leds(6);
  la_wtest();
  la_rtest();

  uart_set_div(234); /* 27000000/115200 */
  endian_test((volatile unsigned int *)&i);


  cdt_test();
  
  /* Test UART input */
  //uart_rx_test();
  
  uart_puts("\r\nStarting DSP benchmark immediately...\r\n");
  //(void) uart_getchar();

  test_dsp();
  benchmark_fir();

  /* Print stuff over and over and have the LED count,
     both writing and reading the LED.
  */

  i = 0;
  while (1) {
    uart_puts("\r\nLoop ");
    uart_print_hex(i);
    uart_puts("\r\n");
    v = get_leds();
    set_leds(v+1);
    
    uart_puts("Four score and seven years ago our fathers brought forth upon this\r\n"
	      "continent, a new nation, conceived in Liberty, and dedicated to the\r\n"
	      "proposition that all men are created equal.  Now we are engaged in a\r\n"
	      "great civil war, testing whether that nation, or any nation so\r\n"
	      "conceived and so dedicated, can long endure. We are met on a great\r\n"
	      "battle-field of that war. We have come to dedicate a portion of that\r\n"
	      "field, as a final resting place for those who here gave their lives that\r\n"
	      "that nation might live. It is altogether fitting and proper that we\r\n"
	      "should do this.\r\n");
    
    uart_puts("time is ");
    uart_print_hex(readtime());
    uart_puts("\r\n");

    cdt_delay(27000000);
    i += 1;
  }
  
  return 0;
}
