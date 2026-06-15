// ================================================================
//  tb_rom.vh — ROM dong va task nap chuong trinh
//  Mo ta: Gia lap bo nho doc (ROM) chua ma lenh test
//         Cho phep thay doi chuong trinh giua cac test case
//         ma khong can reset toan bo module
//  Cach dung: `include "tb_rom.vh" trong module testbench
//  Yeu cau:   Khai bao "reg [31:0] rom [0:15];" truoc khi include
// ================================================================

// ----------------------------------------------------------------
//  ROM always block: Tra ve lenh khi CPU yeu cau (mem_valid=1)
//  Giao thuc: CPU dat mem_valid=1 va mem_addr → TB tra mem_rdata
// ----------------------------------------------------------------
always @(posedge clk) begin
    mem_ready <= 0;
    if (mem_valid && !mem_ready) begin
        mem_ready <= 1;
        // Dung 4 bit [5:2] de dia chi word (bo qua 2 bit thap = byte offset)
        mem_rdata <= (mem_addr[5:2] < 10) ? rom[mem_addr[5:2]] : 32'h00000013; // NOP
    end
end

// ----------------------------------------------------------------
//  load_program: Nap 3 lenh DSP vao ROM voi toan hang cho truoc
//
//  So do bo nho:
//  Addr  Instruction         Giai thich
//  0x00  LUI  x1, a[31:12]  Nap phan cao cua a vao x1
//  0x04  ADDI x1, x1, a[11:0] Cong phan thap cua a
//  0x08  LUI  x2, b[31:12]  Nap phan cao cua b vao x2
//  0x0C  ADDI x2, x2, b[11:0]
//  0x10  ADDI x4, x0, acc   Nap gia tri acc ban dau vao x4
//  0x14  PADDS16 x5,x1,x2   LENH DSP 1: cong bao hoa packed
//  0x18  PSUBS16 x3,x1,x2   LENH DSP 2: tru bao hoa packed
//  0x1C  PMAC16  x4,x1,x2   LENH DSP 3: nhan cong don
//  0x20  J . (loop)         Dung CPU
//
//  Ket qua:
//    x5 = PADDS16(a, b)
//    x3 = PSUBS16(a, b)
//    x4 = acc + (a[15:0] * b[15:0])  [signed]
// ----------------------------------------------------------------
task load_program;
    input [31:0] a;    // toan hang x1
    input [31:0] b;    // toan hang x2
    input [31:0] acc;  // gia tri tich luy ban dau cho PMAC16
    begin
        // Nap x1 = a
        rom[0] = {a[31:12] + a[11], 5'd1, 7'h37};
        rom[1] = {a[11:0], 5'd1, 3'b000, 5'd1, 7'h13};

        // Nap x2 = b
        rom[2] = {b[31:12] + b[11], 5'd2, 7'h37};
        rom[3] = {b[11:0], 5'd2, 3'b000, 5'd2, 7'h13};

        // Nap x4 = acc (full 32-bit)
        rom[4] = {acc[31:12] + acc[11], 5'd4, 7'h37};
        rom[5] = {acc[11:0], 5'd4, 3'b000, 5'd4, 7'h13};

        // Ba lenh DSP tuy chinh (Custom-0, opcode=0x0B)
        // PADDS16: funct7=0x07, funct3=000, rd=x5, rs1=x1, rs2=x2
        rom[6] = 32'h0E20828B;
        // PSUBS16: funct7=0x07, funct3=001, rd=x3
        rom[7] = 32'h0E20918B;
        // PMAC16:  funct7=0x07, funct3=010, rd=x4
        rom[8] = 32'h0E20A20B;

        // Vong lap vo han: J . (JAL x0, 0)
        rom[9] = 32'h0000006F;
    end
endtask
