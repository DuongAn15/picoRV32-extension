# PicoRV32 PCPI Custom Coprocessor trên FPGA Tang Nano 9K

Nhánh **`picoRV32-extension-test`** này trình bày cách thiết kế và tích hợp một Bộ Đồng Xử Lý tùy chỉnh (Custom Coprocessor) chạy song song với lõi vi xử lý mở **PicoRV32 (RISC-V)**. Việc giao tiếp được thực hiện thông qua chuẩn giao thức **PCPI (Pico Co-Processor Interface)**. 

Dự án được cấu hình để nạp và chạy trên board mạch **Gowin Tang Nano 9K**.

## 🌟 Điểm Nhấn Công Nghệ
Thay vì phải sửa đổi mã nguồn phức tạp bên trong ALU của CPU, dự án này giữ nguyên cấu trúc lõi PicoRV32 và bật cổng giao tiếp PCPI (`ENABLE_PCPI = 1`). Bộ đồng xử lý (`my_coprocessor.v`) sẽ trực tiếp "lắng nghe" bus lệnh và thực thi các lệnh tùy chỉnh.

- **Opcode tùy chỉnh:** Sử dụng Opcode `0x0B` (`0001011`).
- **3 Lệnh Coprocessor Phần cứng:**
  - `CADD` (funct3 = 0): Phép cộng 32-bit qua coprocessor.
  - `CXOR` (funct3 = 1): Phép XOR 32-bit qua coprocessor.
  - `CSHL` (funct3 = 2): Phép Dịch trái (Shift Left) 32-bit qua coprocessor.
- **Microarchitecture:** Coprocessor hoạt động theo kiến trúc State Machine siêu nhỏ gọn (chỉ tốn 2 chu kỳ: 1 chu kỳ `busy` bắt tín hiệu và 1 chu kỳ tính toán trả về kết quả `pcpi_ready`).

## 📊 Hệ Thống Đánh Giá (Benchmark Suite)
Mã C (`main.c`) đã định nghĩa sẵn macro `CUSTOM_OP` để đóng gói các lệnh PCPI thông qua Inline Assembly.
Hàm `benchmark_all()` thực hiện đo đạc chu kỳ phần cứng cực kỳ tỉ mỉ bằng thanh ghi `rdcycle`:
1. **Đo đạc độ trễ vòng lặp (Loop Overhead):** Trích xuất riêng chi phí của vòng lặp `for` để tính kết quả vi kiến trúc khách quan nhất.
2. **Native CPU vs PCPI:** Đo và so sánh số chu kỳ tiêu tốn giữa các lệnh chuẩn của CPU (ADD, XOR, SLL) và các lệnh chạy ngoài bộ Đồng xử lý (CADD, CXOR, CSHL) trên 1000 vòng lặp.

## 📂 Cấu Trúc Mã Nguồn
- 📁 `src/my_coprocessor.v`: Module phần cứng xử lý logic của Bộ Đồng Xử Lý qua giao thức PCPI.
- 📁 `src/top.v`: Tích hợp PicoRV32 và nối cáp tín hiệu (Wiring) `pcpi_*` sang bộ đồng xử lý.
- 📁 `c_code/main.c`: Bộ macro C và thuật toán Benchmark.

## 🛠️ Hướng Dẫn Nạp Mạch Thật
Dự án có thể được tổng hợp (Synthesis) và nạp thẳng (Flash) lên mạch thật bằng chuỗi công cụ **OSS-CAD-Suite** (Yosys, NextPNR).
1. Sử dụng VSCode với extension **Lushay Code** (đã có file cấu hình `picorv.lushay.json`).
2. Cắm cáp board Tang Nano 9K và bấm nút `Build and Program FPGA`.
3. Mở cổng COM (Baudrate: 115200) để xem ngay các chỉ số so sánh (chu kỳ máy) giữa CPU và Coprocessor.
