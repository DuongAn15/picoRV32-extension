# PicoRV32 DSP Extension trên FPGA Tang Nano 9K

Dự án này mở rộng vi kiến trúc lõi vi xử lý mã nguồn mở **PicoRV32 (RISC-V)** bằng cách tích hợp thêm một Khối Xử lý Tín hiệu Số chuyên dụng (DSP Extension - Hardware Accelerator). Dự án được thiết kế để nạp trực tiếp và chạy trên bo mạch FPGA **Gowin Tang Nano 9K**.

## Công Nghệ
- **Tập Lệnh Tùy Chỉnh (Custom Instructions):** Bổ sung 3 lệnh hoàn toàn mới vào kiến trúc tập lệnh RISC-V thông qua opcode `CUSTOM-0` (0x0B).
  - `PADDS16`: Cộng song song hai số 16-bit.
  - `PSUBS16`: Trừ song song hai số 16-bit.
  - `PMAC16`: Nhân song song hai số 16-bit và trực tiếp cộng dồn vào thanh ghi đích (Multiply-Accumulate) chỉ trong 1 lệnh duy nhất.
- **Mô Phỏng SoC Hoàn Chỉnh (Testbench):** Tự động hóa kiểm thử mã C trên Icarus Verilog với `tb_soc.v`, hỗ trợ hiển thị dữ liệu truyền UART ra Terminal theo thời gian thực (real-time).
- **Giao Tiếp C/C++:** Đóng gói các lệnh phần cứng thành các Macro Nội tuyến (Inline Assembly) siêu nhẹ trong file `c_code/main.c`.

## Kết Quả Đánh Giá Hiệu Năng (Benchmark)
Bài kiểm tra thực tế sử dụng Thuật toán Lọc **FIR (Finite Impulse Response)** 16-tap qua 100 mẫu dữ liệu. Kết quả thu được trực tiếp từ FPGA (cũng như giả lập) qua cổng UART:

```text
===== FIR Filter Benchmark =====
Standard Cycles: 181877
DSP Cycles:      53496
Verification:    PASSED
```
- **Thời gian chạy:** Rút ngắn xuống còn Chưa tới 1/3 (Tăng tốc độ **~3.4 lần - 340%**).
- **Độ chính xác:** 100% không có sai số.
- **Tiêu thụ tài nguyên:** Chi phí thêm một vài LUT/Flip-flops rất thấp nhờ việc "ký sinh" khối DSP vào sâu bên trong cấu trúc ALU của PicoRV32.

## 📂 Cấu Trúc Mã Nguồn
- 📁 `src/`: Mã nguồn phần cứng Verilog. Gồm lõi mở rộng (`picorv32.v`), file đóng gói top-level (`top.v`), khối nhớ RAM (`sram.v`), UART (`simpleuart.v`) và SoC testbench (`tb_soc.v`).
- 📁 `c_code/`: Mã nguồn phần mềm C. Gồm luồng chính chạy benchmark (`main.c`), các khối UART/Timer, và `Makefile` để biên dịch sang mã máy RISC-V (`prog.hex`).
- 📁 `dsp_testbench/`: Testbench Verilog chuyên sâu để kiểm tra riêng các module DSP.
- 📁 `docs/`: Các tài liệu Báo cáo hàng tuần (Tuần 1-4) phân tích lý thuyết, kiến trúc và giải pháp chi tiết.

## 🛠️ Hướng Dẫn Sử Dụng
Dự án được tối ưu hóa cho chuỗi công cụ mã nguồn mở **OSS-CAD-Suite** (Yosys, NextPNR, OpenFPGALoader).

### 1. Chạy Mô phỏng trên máy tính (Simulation)
Không cần nạp FPGA, bạn có thể chạy mô phỏng toàn bộ SoC (cả chạy code C) bằng cách biên dịch mã C và dùng Icarus Verilog:
```bash
# Biên dịch file C ra file mã máy prog.hex
cd c_code
make prog.hex

# Chạy mô phỏng hệ thống (Sẽ in kết quả UART ra màn hình)
cd ../src
iverilog -o tb_soc.vvp tb_soc.v top.v picorv32.v sram.v simpleuart.v uart_wrap.v countdown_timer.v reset.v tang_nano_9k_leds.v
vvp tb_soc.vvp
```

### 2. Nạp Mạch Thật (FPGA Synthesis & Flash)
Dự án đã có sẵn file cấu hình `picorv.lushay.json`. Nếu bạn dùng VSCode cùng extension **Lushay Code**:
1. Cắm cáp USB kết nối Tang Nano 9K vào máy.
2. Bấm nút `Build and Program FPGA` trên thanh công cụ của VSCode.
3. Mở Serial Monitor kết nối đến cổng COM tương ứng với Baudrate: `115200`. Bấm phím bất kỳ hoặc nút Reset trên mạch để đọc kết quả benchmark thực tế!

---
*Dự án Thiết kế Hệ Thống Nhúng / Vi Mạch Cơ Bản - Phát triển Vi xử lý mã nguồn mở.*
