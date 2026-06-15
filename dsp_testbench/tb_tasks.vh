// ================================================================
//  tb_tasks.vh — Cac Task Tien Ich Kiem Thu
//  Mo ta: Cac task dung chung cho tat ca test case:
//         - check: So sanh got vs expected, dem PASS/FAIL
//         - run:   Reset CPU, chay chuong trinh, kiem tra ket qua
//         - run_random: Chay 1 cap ngau nhien voi golden model
//         - print_report: In tong ket cuoi cung
//  Cach dung: `include "tb_tasks.vh" trong module testbench
//  Yeu cau:   Khai bao cac bien pass_count, fail_count, test_num
// ================================================================

// ----------------------------------------------------------------
//  check: So sanh ket qua CPU vs ket qua ky vong
//  In PASS neu dung, FAIL + chi tiet neu sai
// ----------------------------------------------------------------
task check;
    input [127:0] sig_name;   // ten tin hieu (de in log)
    input [31:0]  got;        // gia tri CPU tra ve
    input [31:0]  expected;   // gia tri ky vong tu golden model
    begin
        if (got === expected) begin
            $display("    [PASS]  %-22s  0x%08X", sig_name, got);
            pass_count = pass_count + 1;
        end else begin
            $display("    [FAIL]  %-22s  got=0x%08X  exp=0x%08X  <<<", sig_name, got, expected);
            $display("            HIGH: got=%0d exp=%0d  |  LOW: got=%0d exp=%0d",
                $signed(got[31:16]),      $signed(expected[31:16]),
                $signed(got[15:0]),       $signed(expected[15:0]));
            fail_count = fail_count + 1;
        end
    end
endtask

// ----------------------------------------------------------------
//  run: Chay 1 test case co dinh (directed test)
//  Quy trinh:
//    1. Nap chuong trinh vao ROM
//    2. Reset CPU (4 chu ky clock)
//    3. Cho 2000ns de CPU chay xong 8 lenh
//    4. So sanh x3, x4, x5 voi golden model
// ----------------------------------------------------------------
task run;
    input [31:0]  a;        // toan hang x1
    input [31:0]  b;        // toan hang x2
    input [31:0]  acc;      // gia tri acc ban dau cho PMAC16
    input [255:0] label;    // ten test case (in vao log)
    begin
        test_num = test_num + 1;
        $display("\n  [TC#%0d] %s", test_num, label);
        $display("     x1=0x%08X (H=%0d L=%0d) | x2=0x%08X (H=%0d L=%0d) | acc=%0d",
            a, $signed(a[31:16]), $signed(a[15:0]),
            b, $signed(b[31:16]), $signed(b[15:0]),
            $signed(acc));

        load_program(a, b, acc);

        // Reset CPU: keo resetn xuong 4 chu ky, sau do tha len
        resetn = 0;
        repeat(4) @(posedge clk);
        resetn = 1;

        // Cho du thoi gian: 8 lenh x ~25 chu ky x 10ns = 2000ns
        #2000;

        // Kiem tra ket qua voi golden model
        check("PADDS16 x5", x5, golden_padds(a, b));
        check("PSUBS16 x3", x3, golden_psubs(a, b));
        check("PMAC16  x4", x4, golden_pmac(a, b, acc));
    end
endtask

// ----------------------------------------------------------------
//  run_random: Chay 1 cap ngau nhien (dung trong vong lap random)
//  Khac run o cho: khong in chi tiet toan hang de giam log
//  Chi in khi FAIL de de debug
// ----------------------------------------------------------------
task run_random;
    input [31:0]  a, b, acc;
    input integer iter;       // so thu tu trong vong lap
    input integer rseed;      // seed da dung (de reproduce)
    begin
        test_num = test_num + 1;

        load_program(a, b, acc);
        resetn = 0;
        repeat(4) @(posedge clk);
        resetn = 1;
        #2000;

        // Kiem tra PADDS16
        if (x5 !== golden_padds(a, b)) begin
            $display("    [FAIL]  PADDS16 x5  iter=%0d seed=%0d", iter, rseed);
            $display("            a=0x%08X b=0x%08X", a, b);
            $display("            got=0x%08X  exp=0x%08X", x5, golden_padds(a,b));
            fail_count = fail_count + 1;
        end else pass_count = pass_count + 1;

        // Kiem tra PSUBS16
        if (x3 !== golden_psubs(a, b)) begin
            $display("    [FAIL]  PSUBS16 x3  iter=%0d seed=%0d", iter, rseed);
            $display("            a=0x%08X b=0x%08X", a, b);
            $display("            got=0x%08X  exp=0x%08X", x3, golden_psubs(a,b));
            fail_count = fail_count + 1;
        end else pass_count = pass_count + 1;

        // Kiem tra PMAC16
        if (x4 !== golden_pmac(a, b, acc)) begin
            $display("    [FAIL]  PMAC16  x4  iter=%0d seed=%0d", iter, rseed);
            $display("            a=0x%08X b=0x%08X acc=0x%08X", a, b, acc);
            $display("            got=0x%08X  exp=0x%08X", x4, golden_pmac(a,b,acc));
            fail_count = fail_count + 1;
        end else pass_count = pass_count + 1;
    end
endtask

// ----------------------------------------------------------------
//  print_section: In tieu de phan (phan cach cac nhom test)
// ----------------------------------------------------------------
task print_section;
    input [255:0] title;
    begin
        $display("\n%0s", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        $display("  %s", title);
        $display("%0s", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    end
endtask

// ----------------------------------------------------------------
//  print_report: In tong ket cuoi cung va exit voi ma loi dung
// ----------------------------------------------------------------
task print_report;
    begin
        $display("\n");
        $display("╔══════════════════════════════════════════════════╗");
        $display("║             BAO CAO KIEM THU DSP                ║");
        $display("╠══════════════════════════════════════════════════╣");
        $display("║  Tong so test case  : %3d                       ║", test_num);
        $display("║  Check points       : %3d                       ║", pass_count + fail_count);
        $display("║  PASS               : %3d                       ║", pass_count);
        $display("║  FAIL               : %3d                       ║", fail_count);
        $display("╠══════════════════════════════════════════════════╣");

        if (fail_count == 0) begin
            $display("║  KET QUA: TAT CA PASS                           ║");
            $display("║  PADDS16 / PSUBS16 / PMAC16 chinh xac 100%%     ║");
        end else begin
            $display("║  KET QUA: CO %3d LOI — can debug               ║", fail_count);
            $display("╠══════════════════════════════════════════════════╣");
            $display("║  GIA Y DEBUG:                                   ║");
            $display("║  - PADDS fail: kiem tra dieu kien '>' vs '>='  ║");
            $display("║  - PSUBS fail: kiem tra bao hoa DUONG (tru am) ║");
            $display("║  - PMAC  fail: kiem tra dau cua nhan signed    ║");
            $display("║  - Random fail: dung seed in ra de reproduce   ║");
        end
        $display("╚══════════════════════════════════════════════════╝");

        // Tra ve exit code: 0=pass, 1=fail (dung trong CI/CD)
        if (fail_count > 0)
            $fatal(1, "Co %0d loi trong qua trinh kiem thu!", fail_count);
        else
            $finish;
    end
endtask
