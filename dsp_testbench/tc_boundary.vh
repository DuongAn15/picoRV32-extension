// ================================================================
//  tc_boundary.vh — Kich Ban Bien Gioi
//  Muc tieu: Kiem tra cac gia tri dac biet: 0, 1, 0x7FFF, 0x8000
//            Day la nhom tim "off-by-one bug" trong mach bao hoa
//  So luong: 9 test case x 3 check = 27 check-points
// ================================================================

print_section("NHOM 2: BIEN GIOI (0, 1, 0x7FFF, 0x8000, 0xFFFF)");

// BC1: Zero + Zero — moi phep deu = 0
run(32'h0000_0000, 32'h0000_0000, 32'h0000_0000,
    "BC1: 0+0=0 (zero identity)");

// BC2: One + Zero — ket qua = chinh no
run(32'h0001_0001, 32'h0000_0000, 32'h0000_0000,
    "BC2: 1+0=1 (identity element)");

// BC3: MAX + 1 → VUOT TRAN 1 DON VI (quan trong nhat)
// 0x7FFF + 0x0001 = 0x8000 → phai bao hoa → 0x7FFF
// BUG pho bien: dieu kien '>=' thay '>' → cho ra 0x8000!
run(32'h7FFF_7FFF, 32'h0001_0001, 32'h0000_0000,
    "BC3: 7FFF+0001 vuot tran 1 don vi → bao hoa 7FFF");

// BC4: MAX + MAX → bao hoa nang
// 0x7FFF + 0x7FFF = 0xFFFE → bao hoa → 0x7FFF
run(32'h7FFF_7FFF, 32'h7FFF_7FFF, 32'h0000_0000,
    "BC4: 7FFF+7FFF=FFFE → bao hoa 7FFF");

// BC5: MIN + (-1) → vuot san 1 don vi
// -32768 + (-1) = -32769 → bao hoa → 0x8000
run(32'h8000_8000, 32'hFFFF_FFFF, 32'h0000_0000,
    "BC5: 8000+FFFF vuot san 1 don vi → bao hoa 8000");

// BC6: MIN + MIN → bao hoa am nang
// -32768 + -32768 = -65536 → bao hoa → 0x8000
run(32'h8000_8000, 32'h8000_8000, 32'h0000_0000,
    "BC6: 8000+8000 bao hoa am nang");

// BC7: (-1) + 1 = 0 — triet tieu nhau
// 0xFFFF + 0x0001 = 0x0000 (binh thuong, khong bao hoa)
run(32'hFFFF_FFFF, 32'h0001_0001, 32'h0000_0000,
    "BC7: (-1)+(+1)=0 triet tieu");

// BC8: PSUBS bao hoa DUONG — hay bi bo quen!
// 0x0000 - 0x8000 = 0 - (-32768) = +32768 → vuot tran duong → 0x7FFF
// Nhieu nguoi chi kiem tra bao hoa am cua PSUBS!
run(32'h0001_0001, 32'h8000_8000, 32'h0000_0000,
    "BC8: PSUBS 0001-8000 bao hoa DUONG (hay bi bo quen)");

// BC9: Ket qua chinh xac bang bien (khong bao hoa)
// 0x4000 + 0x3FFF = 0x7FFF — dung bang tran nhung KHONG bao hoa
// BUG: neu dung '>=' thay '>' se bao hoa oan!
run(32'h4000_4000, 32'h3FFF_3FFF, 32'h0000_0000,
    "BC9: 4000+3FFF=7FFF chinh xac tai tran (khong bao hoa)");
