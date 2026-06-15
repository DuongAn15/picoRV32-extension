// ================================================================
//  tc_overflow_negative.vh — Tran So va So Am
//  Muc tieu A: Kiem tra bao hoa dung/am o PADDS16 va PSUBS16
//  Muc tieu B: Kiem tra two's complement trong ca 3 lenh DSP
//  So luong: 17 test case x 3 check = 51 check-points
// ================================================================

// ----------------------------------------------------------------
//  PHAN A: TRAN SO BAO HOA
// ----------------------------------------------------------------
print_section("NHOM 3A: TRAN SO (bao hoa duong va am)");

// OVF-P1: PADDS tran duong 1 don vi
run(32'h7FFF_7FFF, 32'h0001_0001, 32'h0000_0000,
    "OVF-P1: PADDS 7FFF+0001 tran duong");

// OVF-P2: PADDS hai so duong lon
// 0x6000+0x3000=0x9000 → bao hoa → 0x7FFF
run(32'h6000_6000, 32'h3000_3000, 32'h0000_0000,
    "OVF-P2: PADDS 6000+3000=9000 bao hoa");

// OVF-P3: PADDS hai kenh bat doi xung
// HIGH: 0x7FFF+0x0001=bao hoa → 0x7FFF
// LOW:  0x0010+0x0005=0x0015   (binh thuong)
run(32'h7FFF_0010, 32'h0001_0005, 32'h0000_0000,
    "OVF-P3: PADDS HIGH tran, LOW binh thuong");

// OVF-P4: PADDS tran am 1 don vi
// -32768 + (-1) = -32769 → bao hoa → 0x8000
run(32'h8000_8000, 32'hFFFF_FFFF, 32'h0000_0000,
    "OVF-P4: PADDS 8000+FFFF tran am 1 don vi");

// OVF-P5: PADDS hai so am lon
// 0x9000+0x9000: -28672+(-28672)=-57344 → 0x8000
run(32'h9000_9000, 32'h9000_9000, 32'h0000_0000,
    "OVF-P5: PADDS 9000+9000 tran am nang");

// OVF-S1: PSUBS tran DUONG (tru so am → ket qua duong lon)
// 0 - (-32768) = +32768 → vuot tran duong → 0x7FFF
run(32'h0000_0000, 32'h8000_8000, 32'h0000_0000,
    "OVF-S1: PSUBS 0000-8000 tran duong (tru MIN)");

// OVF-S2: PSUBS MAX - MIN
// 32767 - (-32768) = 65535 → bao hoa → 0x7FFF
run(32'h7FFF_7FFF, 32'h8000_8000, 32'h0000_0000,
    "OVF-S2: PSUBS 7FFF-8000=65535 bao hoa duong");

// OVF-S3: PSUBS tran am
// -32768 - 1 = -32769 → bao hoa → 0x8000
run(32'h8000_8000, 32'h0001_0001, 32'h0000_0000,
    "OVF-S3: PSUBS 8000-0001 tran am 1 don vi");

// OVF-S4: PSUBS hai kenh tran nguoc chieu
// HIGH: 0x8000-0x0001 → tran am   → 0x8000
// LOW:  0x0000-0x8000 → tran duong → 0x7FFF
run(32'h8000_0000, 32'h0001_8000, 32'h0000_0000,
    "OVF-S4: PSUBS HIGH tran am, LOW tran duong");

// ----------------------------------------------------------------
//  PHAN B: SO AM (two's complement)
// ----------------------------------------------------------------
print_section("NHOM 3B: SO AM (two's complement)");

// NEG-1: Am + Am khong tran
// (-1)+(-1) = -2 = 0xFFFE (KHONG bao hoa — -2 van trong vung hop le)
run(32'hFFFF_FFFF, 32'hFFFF_FFFF, 32'h0000_0000,
    "NEG-1: (-1)+(-1)=-2 khong bao hoa");

// NEG-2: Am + Duong triet tieu
run(32'hFFFB_FFFB, 32'h0005_0005, 32'h0000_0000,
    "NEG-2: (-5)+(+5)=0 triet tieu");

// NEG-3: Am + Duong → ket qua duong
// (-5) + 7 = +2
run(32'hFFFB_FFFB, 32'h0007_0007, 32'h0000_0000,
    "NEG-3: (-5)+(+7)=+2 ket qua duong");

// NEG-4: PSUBS Am - Am
// (-1) - (-1) = 0
run(32'hFFFF_FFFF, 32'hFFFF_FFFF, 32'h0000_0000,
    "NEG-4: PSUBS (-1)-(-1)=0");

// NEG-5: PSUBS Am - Am lon hon → duong
// (-3) - (-5) = +2 (am tru am lon hon → ket qua duong)
run(32'hFFFD_FFFD, 32'hFFFB_FFFB, 32'h0000_0000,
    "NEG-5: PSUBS (-3)-(-5)=+2 am tru am lon hon");

// NEG-6: PMAC Am x Am → Duong
// (-3) * (-5) = +15 (am x am = duong)
run(32'h0000_FFFD, 32'h0000_FFFB, 32'h0000_0000,
    "NEG-6: PMAC (-3)x(-5)=+15 am x am = duong");

// NEG-7: PMAC Am x Duong → Am
// (-3) * 5 = -15
run(32'h0000_FFFD, 32'h0000_0005, 32'h0000_0000,
    "NEG-7: PMAC (-3)x(+5)=-15 am x duong = am");

// NEG-8: PMAC Duong x Am + acc
// acc=100, (-1)*(-1)=+1, 100+1=101
run(32'h0000_FFFF, 32'h0000_FFFF, 32'h0000_0064,
    "NEG-8: PMAC acc=100 + (-1)x(-1)=1 → 101");
