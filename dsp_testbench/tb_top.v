// ================================================================
//  tb_top.v — KHUNG CHINH (Main Testbench)
//  Du an: He thong kiem thu chuyen nghiep cho PicoRV32 + DSP
//
//  Cau truc module:
//    tb_top.v              ← FILE NAY (khung chinh)
//    ├── tb_golden.vh      ← Ham golden model (dap an chuan)
//    ├── tb_rom.vh         ← ROM dong + task load_program
//    ├── tb_tasks.vh       ← Task check, run, run_random, report
//    └── [Test Cases]
//        ├── tc_normal.vh            (4  TCs, 12  checks)
//        ├── tc_boundary.vh          (9  TCs, 27  checks)
//        ├── tc_overflow_negative.vh (17 TCs, 51  checks)
//        └── tc_random.vh            (130 TCs, 390 checks)
//
//  Tong: 160 test cases, 480 check-points
//
//  Cach chay:
//    iverilog -g2005 -o sim tb_top.v picorv32.v && vvp sim
//    gtkwave tb_dsp_pro.vcd &   (xem waveform neu co loi)
//
//  Exit code: 0 = tat ca PASS, 1 = co LOI (dung duoc trong CI/CD)
// ================================================================

`timescale 1ns/1ps

module tb_top;

// ----------------------------------------------------------------
//  PHAN 1: KHAI BAO TIN HIEU
// ----------------------------------------------------------------
reg clk;
reg resetn;

// Giao dien bus bo nho CPU
reg         mem_ready;
reg  [31:0] mem_rdata;
wire        mem_valid;
wire        mem_instr;
wire [31:0] mem_addr;
wire [31:0] mem_wdata;
wire [3:0]  mem_wstrb;

// ----------------------------------------------------------------
//  PHAN 2: INSTANTIATE CPU
//  Thong so phai khop voi du an picorv32.v dang dung
// ----------------------------------------------------------------
picorv32 #(
    .ENABLE_REGS_DUALPORT(1),   // Doc 2 thanh ghi cung 1 luc
    .TWO_CYCLE_ALU       (1),   // ALU 2 chu ky → can cho PMAC16
    .ENABLE_IRQ          (0),   // Tat ngat, don gian hoa kiem thu
    .REGS_INIT_ZERO      (1)    // Tat ca thanh ghi = 0 khi reset
) cpu (
    .clk      (clk      ),
    .resetn   (resetn   ),
    .mem_valid(mem_valid ),
    .mem_instr(mem_instr ),
    .mem_ready(mem_ready ),
    .mem_addr (mem_addr  ),
    .mem_wdata(mem_wdata ),
    .mem_wstrb(mem_wstrb ),
    .mem_rdata(mem_rdata )
);

// ----------------------------------------------------------------
//  PHAN 3: TAO XUNG NHIP (Clock Generation)
//  Chu ky 10ns = 100 MHz
// ----------------------------------------------------------------
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

// ----------------------------------------------------------------
//  PHAN 4: EXPOSE THANH GHI → GTKWAVE
//  Truy cap truc tiep vao mang thanh ghi ben trong CPU
//  Nho nho: dung hierarchical reference (cpu.cpuregs[N])
// ----------------------------------------------------------------
wire [31:0] x1 = cpu.cpuregs[1];
wire [31:0] x2 = cpu.cpuregs[2];
wire [31:0] x3 = cpu.cpuregs[3];   // Ket qua PSUBS16
wire [31:0] x4 = cpu.cpuregs[4];   // Ket qua PMAC16
wire [31:0] x5 = cpu.cpuregs[5];   // Ket qua PADDS16

// ----------------------------------------------------------------
//  PHAN 5: BIEN KIEM THU (Test Infrastructure Variables)
// ----------------------------------------------------------------
integer pass_count;   // So check-point PASS
integer fail_count;   // So check-point FAIL
integer test_num;     // So thu tu test case hien tai

// Bien cho random testing
integer      rng_seed;
integer      ri, rj, rs;
reg  [31:0]  ra, rb, racc;
reg  [31:0]  near_vals [0:7];   // Bang gia tri gan bien cho weighted random

// ----------------------------------------------------------------
//  PHAN 6: ROM DONG
//  Mang luu chuong trinh test, thay doi giua cac test case
// ----------------------------------------------------------------
reg [31:0] rom [0:15];

// ----------------------------------------------------------------
//  PHAN 7: INCLUDE CAC MODULE HO TRO
//  Thu tu quan trong: golden → rom → tasks
// ----------------------------------------------------------------
`include "tb_golden.vh"   // Ham tinh ket qua chuan
`include "tb_rom.vh"      // ROM always block + load_program task
`include "tb_tasks.vh"    // check, run, run_random, print_report

// ----------------------------------------------------------------
//  PHAN 8: CHUOI TEST CHINH
// ----------------------------------------------------------------
initial begin
    // Thiet lap ghi VCD cho GTKWave
    $dumpfile("tb_dsp_pro.vcd");
    $dumpvars(0, tb_top);

    // Khoi tao bien dem
    pass_count = 0;
    fail_count = 0;
    test_num   = 0;

    // In banner
    $display("");
    $display("╔══════════════════════════════════════════════════╗");
    $display("║   HE THONG KIEM THU DSP CHUYEN NGHIEP          ║");
    $display("║   PicoRV32 + PADDS16 / PSUBS16 / PMAC16        ║");
    $display("╠══════════════════════════════════════════════════╣");
    $display("║   Cau hinh:                                     ║");
    $display("║     TWO_CYCLE_ALU = 1 (can cho PMAC16)         ║");
    $display("║     REGS_INIT_ZERO = 1                          ║");
    $display("║   Tong: 160 test cases / 480 check-points       ║");
    $display("╚══════════════════════════════════════════════════╝");

    // Reset CPU truoc khi bat dau
    resetn = 0;
    #20;

    // ── Chay lan luot 4 nhom ──────────────────────────────
    `include "tc_normal.vh"             // Nhom 1: Binh thuong
    `include "tc_boundary.vh"           // Nhom 2: Bien gioi
    `include "tc_overflow_negative.vh"  // Nhom 3: Tran so + so am
    `include "tc_random.vh"             // Nhom 4: Ngau nhien

    // In bao cao cuoi va ket thuc
    print_report;
end

endmodule
