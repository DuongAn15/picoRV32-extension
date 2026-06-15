// ================================================================
//  tc_normal.vh — Kich Ban Binh Thuong (Directed Normal Tests)
//  Muc tieu: Kiem tra logic co ban khi ket qua trong vung an toan
//            Neu nhom nay fail → dung lai, kiem tra truoc khi tiep
//  So luong: 4 test case x 3 check = 12 check-points
// ================================================================

print_section("NHOM 1: BINH THUONG (khong tran so)");

// TC1: Gia tri nho, ket qua hoan toan binh thuong
// PADDS16: H=3+2=5,    L=1+1=2  → 0x0005_0002
// PSUBS16: H=3-2=1,    L=1-1=0  → 0x0001_0000
// PMAC16:  acc=0, 1*1=1          → 0x0000_0001
run(32'h0003_0001, 32'h0002_0001, 32'h0000_0000,
    "TC1: Gia tri nho, khong tran");

// TC2: Gia tri vua, kiem tra 2 kenh HIGH/LOW doc lap
// PADDS16: H=0x1000+0x0500=0x1500,  L=0x0200+0x0100=0x0300
// PSUBS16: H=0x1000-0x0500=0x0B00,  L=0x0200-0x0100=0x0100
// PMAC16:  512 * 256 = 131072 = 0x0002_0000
run(32'h1000_0200, 32'h0500_0100, 32'h0000_0000,
    "TC2: Gia tri vua, 2 kenh doc lap");

// TC3: Hai kenh co gia tri khac nhau hoan toan
// HIGH: 0x3FFF+0x3FFF=0x7FFE (gan tran nhung CHUA bao hoa)
// LOW:  0x000A+0x0005=0x000F
// PMAC16: 10 * 5 = 50 = 0x32
run(32'h3FFF_000A, 32'h3FFF_0005, 32'h0000_0000,
    "TC3: HIGH gan tran nhung chua bao hoa");

// TC4: PMAC16 voi acc khac 0 — kiem tra cong don
// PADDS16: H=0, L=7+3=10=0xA   → 0x0000_000A
// PSUBS16: H=0, L=7-3=4         → 0x0000_0004
// PMAC16:  acc=100, 7*3=21, 100+21=121=0x79
run(32'h0000_0007, 32'h0000_0003, 32'h0000_0064,
    "TC4: PMAC16 voi acc=100 (cong don)");
