// ================================================================
//  tb_golden.vh — Golden Model (Phan mem chuan)
//  Mo ta: Ham tinh ket qua dung 100% cho 3 lenh DSP
//         CPU phai cho ket qua khop voi cac ham nay
//  Cach dung: `include "tb_golden.vh" trong module testbench
// ================================================================

// ----------------------------------------------------------------
//  sat_add16: Cong bao hoa 16-bit signed
//  Dau vao: a, b (16-bit signed)
//  Dau ra:  a+b kiem soat trong [-32768, 32767]
//           neu tran duong → 0x7FFF
//           neu tran am    → 0x8000
// ----------------------------------------------------------------
function [15:0] sat_add16;
    input signed [15:0] a, b;
    reg signed [16:0] s;
    begin
        // Mo rong len 17-bit de phat hien tran
        s = {a[15], a} + {b[15], b};
        if      (s >  17'sh7FFF) sat_add16 = 16'h7FFF; // tran duong → tran
        else if (s < -17'sh8000) sat_add16 = 16'h8000; // tran am   → san
        else                     sat_add16 = s[15:0];  // binh thuong
    end
endfunction

// ----------------------------------------------------------------
//  sat_sub16: Tru bao hoa 16-bit signed
// ----------------------------------------------------------------
function [15:0] sat_sub16;
    input signed [15:0] a, b;
    reg signed [16:0] d;
    begin
        d = {a[15], a} - {b[15], b};
        if      (d >  17'sh7FFF) sat_sub16 = 16'h7FFF;
        else if (d < -17'sh8000) sat_sub16 = 16'h8000;
        else                     sat_sub16 = d[15:0];
    end
endfunction

// ----------------------------------------------------------------
//  golden_padds: PADDS16 x5, x1, x2
//  Xu ly 2 kenh 16-bit HOAN TOAN DOC LAP
// ----------------------------------------------------------------
function [31:0] golden_padds;
    input [31:0] a, b;
    begin
        golden_padds = {
            sat_add16(a[31:16], b[31:16]),  // kenh HIGH
            sat_add16(a[15:0],  b[15:0])    // kenh LOW
        };
    end
endfunction

// ----------------------------------------------------------------
//  golden_psubs: PSUBS16 x3, x1, x2
// ----------------------------------------------------------------
function [31:0] golden_psubs;
    input [31:0] a, b;
    begin
        golden_psubs = {
            sat_sub16(a[31:16], b[31:16]),
            sat_sub16(a[15:0],  b[15:0])
        };
    end
endfunction

// ----------------------------------------------------------------
//  golden_pmac: PMAC16 x4, x1, x2
//  Chi dung phan LOW 16-bit cua x1 va x2 (co dau)
//  Ket qua cong don vao acc 32-bit (KHONG bao hoa)
// ----------------------------------------------------------------
function [31:0] golden_pmac;
    input [31:0] a, b, acc;
    reg signed [15:0] al, bl;
    reg signed [31:0] prod;
    begin
        al          = a[15:0];          // lay phan LOW, xu ly co dau
        bl          = b[15:0];
        prod        = al * bl;          // nhan 16x16 → 32-bit signed
        golden_pmac = acc + prod;       // cong don vao acc
    end
endfunction
