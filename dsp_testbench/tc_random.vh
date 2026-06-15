// ================================================================
//  tc_random.vh — Kiem Thu Ngau Nhien (Random Testing)
//  Muc tieu: Tim bug o nhung gia tri ma directed test bo sot
//            Golden model tu dong tinh dap an → khong can biet truoc
//  So luong:
//    R1: 50 tests x 3 check = 150 check-points (pure random)
//    R2: 30 tests x 3 check = 90 check-points  (weighted near-boundary)
//    R3: 50 tests x 3 check = 150 check-points (multi-seed)
//  Tong: 130 test cases, 390 check-points
//
//  Yeu cau bien: integer rng_seed, ri, rj, rs;
//                reg [31:0] ra, rb, racc;
//                reg [31:0] near_vals[0:7];
// ================================================================

// ----------------------------------------------------------------
//  Khoi tao bang gia tri gan bien (dung cho weighted random)
// ----------------------------------------------------------------
begin : init_near_vals
    near_vals[0] = 32'h7FFF_7FFF;  // MAX
    near_vals[1] = 32'h8000_8000;  // MIN
    near_vals[2] = 32'hFFFF_FFFF;  // -1
    near_vals[3] = 32'h0001_0001;  // +1
    near_vals[4] = 32'h7FFE_7FFE;  // MAX-1
    near_vals[5] = 32'h8001_8001;  // MIN+1
    near_vals[6] = 32'h0000_0000;  // Zero
    near_vals[7] = 32'hFFFE_FFFE;  // -2
end

// ----------------------------------------------------------------
//  R1: PURE RANDOM — 50 cap hoan toan ngau nhien
//  Seed co dinh: co the reproduce lai khi gap loi
// ----------------------------------------------------------------
print_section("NHOM 4-R1: PURE RANDOM (50 tests, seed=42)");
rng_seed = 42;

for (ri=0; ri<50; ri=ri+1) begin
    ra   = {$random(rng_seed), $random(rng_seed)};  // 32-bit ngau nhien
    rb   = {$random(rng_seed), $random(rng_seed)};
    racc = $random(rng_seed) & 32'hFFFF;     // acc 16-bit

    if (ri % 10 == 0)
        $display("     R1: %0d/50 ...", ri);

    run_random(ra, rb, racc, ri, 42);
end
$display("     R1 hoan thanh.");

// ----------------------------------------------------------------
//  R2: WEIGHTED RANDOM — 30 tests, 70% gan bien
//  Muc tieu: tang xac suat tim bug o vung nguy hiem
//  Chien luoc:
//    70%: lay tu near_vals + nhieu nho (±7)
//    30%: hoan toan ngau nhien
// ----------------------------------------------------------------
print_section("NHOM 4-R2: WEIGHTED RANDOM (30 tests, tap trung bien)");
rng_seed = 137;

for (ri=0; ri<30; ri=ri+1) begin
    if (($random(rng_seed) % 10) < 7) begin
        // 70%: gia tri gan bien + nhieu nho
        ra = near_vals[$random(rng_seed) % 8]
           + ($random(rng_seed) % 8);
        rb = near_vals[$random(rng_seed) % 8]
           + ($random(rng_seed) % 8);
    end else begin
        // 30%: hoan toan ngau nhien
        ra = {$random(rng_seed), $random(rng_seed)};
        rb = {$random(rng_seed), $random(rng_seed)};
    end
    racc = $random(rng_seed) & 32'hFFFF;

    if (ri % 10 == 0)
        $display("     R2: %0d/30 ...", ri);

    run_random(ra, rb, racc, ri, 137);
end
$display("     R2 hoan thanh.");

// ----------------------------------------------------------------
//  R3: MULTI-SEED — 5 seed x 10 tests = 50 tests
//  Muc tieu: dam bao ket qua khong phu thuoc vao bo gia tri cu the
//  Moi seed = 1 "bo de thi" hoan toan khac
// ----------------------------------------------------------------
print_section("NHOM 4-R3: MULTI-SEED (5 seeds x 10 tests)");

begin : multi_seed_block
    integer seed_list [0:4];
    seed_list[0] =   7;
    seed_list[1] =  13;
    seed_list[2] =  99;
    seed_list[3] = 256;
    seed_list[4] = 1024;

    for (rs=0; rs<5; rs=rs+1) begin
        rng_seed = seed_list[rs];
        $display("     Seed = %0d ...", rng_seed);

        for (rj=0; rj<10; rj=rj+1) begin
            ra   = {$random(rng_seed), $random(rng_seed)};
            rb   = {$random(rng_seed), $random(rng_seed)};
            racc = $random(rng_seed) & 32'hFFFF;
            run_random(ra, rb, racc, rj, seed_list[rs]);
        end
    end
end
$display("     R3 hoan thanh.");
