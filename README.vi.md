<div align="center">

# LKKN-DND Mini-SoC: Tự Thiết Kế Chip Vi Xử Lý 32-Bit & Hệ Thống Máy Tính Thu Nhỏ Trên FPGA

[![English](https://img.shields.io/badge/Language-English_(Click_to_switch)-0366d6?style=for-the-badge)](README.md)
[![Tiếng Việt](https://img.shields.io/badge/Ngôn_ngữ-Tiếng_Việt_(Đang_xem)-2ea44f?style=for-the-badge)](README.vi.md)

[![Architecture](https://img.shields.io/badge/Bộ_Não_CPU-MIPS32_32--Bit-blue.svg)](#)
[![Bus](https://img.shields.io/badge/Đường_Truyền-AMBA_AHB--Lite_%2F_APB3-orange.svg)](#)
[![HDL](https://img.shields.io/badge/Ngôn_Ngữ_Thiết_Kế-Verilog_HDL-brightgreen.svg)](#)
[![FPGA](https://img.shields.io/badge/Mạch_Phần_Cứng-Terasic_DE2--115_(Cyclone_IV_E)-red.svg)](#)
[![Tool](https://img.shields.io/badge/Phần_Mềm-Quartus_Prime_20.1.1-purple.svg)](#)

*Dự án tự thiết kế từ con số 0 một "con chip máy tính thu nhỏ" (System-on-Chip) hoàn chỉnh bằng ngôn ngữ phần cứng Verilog, nạp xuống bảng mạch điện tử FPGA Terasic DE2-115 để chạy các thuật toán tính toán và điều khiển màn hình theo thời gian thực.*

</div>

<p align="center">
  <a href="docs/images/mini_soc_top.svg">
    <img src="docs/images/mini_soc_top.svg" width="100%" alt="Sơ đồ 9 khối bên trong lõi chip LKKN-DND Mini-SoC">
  </a>
  <br/>
  <sub><b>Hình 1:</b> Bản vẽ "giải phẫu" 9 bộ phận bên trong lõi chip <code>mini_soc_top</code> do nhóm tự thiết kế (Bấm vào ảnh để phóng to xem từng sợi dây nối)</sub>
</p>

<p align="center">
  <a href="docs/images/full_chip.svg">
    <img src="docs/images/full_chip.svg" width="100%" alt="Sơ đồ toàn bộ con chip kèm bộ giải mã màn hình LCD và đèn LED 7 đoạn">
  </a>
  <br/>
  <sub><b>Hình 2:</b> Toàn cảnh con chip hoàn chỉnh (<code>de2_115_wrapper</code>) khi ghép thêm mạch đổi số thập phân bậc thang, bộ điều khiển 8 đèn số đỏ và màn hình chữ LCD (Bấm vào ảnh để phóng to)</sub>
</p>

---

## 1. Giới Thiệu Dễ Hiểu (Dành Cho Mọi Người & Gia Đình)

Bình thường khi sử dụng điện thoại hay máy tính, bên trong chúng đều có một **con chip vi xử lý (CPU)** làm nhiệm vụ suy nghĩ và tính toán. Trong đồ án này, thay vì mua một con chip làm sẵn, tụi con đã **tự tay viết từng dòng lệnh thiết kế mạch điện để chế tạo ra một con chip máy tính 32-bit của riêng mình** mang tên **`LKKN DND MINISOC`**:

1. **Bộ não trung tâm (`CPU MIPS32`):** Có khả năng đọc hiểu 64 câu lệnh chương trình, tự làm các phép tính cộng, trừ, nhân, so sánh và xử lý đa nhiệm.
2. **Hệ thống đường cao tốc truyền dữ liệu (`AMBA AHB-Lite & APB3`):** Giống như hệ thống giao thông trong thành phố, giúp bộ não CPU liên lạc siêu tốc với bộ nhớ RAM và các thiết bị bên ngoài mà không bị kẹt xe.
3. **4 Thiết bị ngoại vi tích hợp sẵn trong chip:**
   - **Bộ đọc công tắc & bật đèn (`GPIO`):** Đọc thao tác gạt 18 công tắc của người dùng và điều khiển 18 bóng đèn LED đỏ.
   - **Đồng hồ bấm giờ tự động (`Timer`):** Đếm chính xác từng phần triệu giây để nhắc CPU làm việc đúng giờ.
   - **Cổng giao tiếp máy tính (`UART`):** Truyền tin nhắn từ mạch lên máy tính.
   - **Công tắc tiết kiệm điện thông minh (`Clock Controller`):** Có thể ngắt xung nhịp của các bộ phận đang nghỉ để tiết kiệm năng lượng.
4. **Màn hình hiển thị trực quan:** Tự động đổi kết quả nhị phân của máy tính sang **con số thập phân bình thường** để hiện lên **8 đèn số màu đỏ (`HEX7..HEX0`)** và **màn hình chữ tinh thể lỏng LCD (`LKKN DND MINISOC`)**.

| Thông số của Chip | Chi tiết |
| :--- | :--- |
| **Tên hiển thị trên màn hình LCD** | `LKKN DND MINISOC` |
| **Bảng mạch thử nghiệm** | Terasic DE2-115 (`Intel Cyclone IV E EP4CE115F29C7`), tốc độ **50 triệu nhịp/giây (50 MHz)** |
| **Số lượng linh kiện logic sử dụng** | **9,094 khối Logic Elements** và **3,497 thanh ghi Flip-Flops** |

---

## 2. Xem Con Chip Hoạt Động Thực Tế Qua 4 Chế Độ

Để chứng minh con chip thực sự "biết suy nghĩ và tính toán" chứ không chỉ là mạch bật/tắt đèn thông thường, tụi con đã nạp vào bộ nhớ của chip một phần mềm gồm **4 chế độ thông minh** (chọn bằng 2 công tắc ngoài cùng bên trái **`SW17`** và **`SW16`**):

### 🔹 Chế độ `00` (`SW[17:16] = 00`): Hiệu ứng Sóng Ánh Sáng Chạy Qua Lại (`M0:KITT`)
* **Con chip làm gì?** Đồng hồ bên trong chip tự động đếm thời gian và báo cho bộ não CPU dịch chuyển 2 bóng đèn sáng lướt mượt mà từ phải sang trái, chạm mép trái lại tự động nảy ngược về bên phải. Người dùng có thể gạt công tắc `SW[14:12]` để tăng tốc hoặc giảm tốc độ chạy của đèn ngay lập tức!
* **Màn hình hiển thị:** Dòng trên hiện tên nhóm **`LKKN DND MINISOC`**, dòng dưới hiện **`M0:KITT OUT:0006`**.

| Ảnh chụp thực tế trên mạch (`M0:KITT`) | Video hoạt động thực tế (Bấm vào ảnh để mở `.mp4`) |
| :---: | :---: |
| <a href="docs/images/mode00_kitt.jpg"><img src="docs/images/mode00_kitt.jpg" width="100%" alt="Ảnh chụp Chế độ 00 KITT"></a> | <a href="docs/images/mode00_kitt.mp4"><img src="docs/images/mode00_kitt.gif" width="100%" alt="Video Chế độ 00 KITT"></a> |

---

### 🔹 Chế độ `01` (`SW[17:16] = 01`): Giải Bài Toán Dãy Số Fibonacci ($F(N)$)
* **Con chip làm gì?** Dãy số Fibonacci là dãy số nổi tiếng trong toán học mà số sau bằng tổng 2 số liền trước ($0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, \dots$). Khi gạt công tắc chọn số thứ tự $N$ (từ 0 đến 24), bộ não CPU tự chạy vòng lặp cộng dồn liên tiếp và hiện ngay đáp số lên màn hình:
  * Chọn $N = 10$ $\rightarrow$ Màn hình hiện **`00055`**
  * Chọn $N = 20$ $\rightarrow$ Màn hình hiện **`06765`**
  * Chọn $N = 24$ $\rightarrow$ Màn hình hiện **`46368`** (`M1:FIB OUT:46368`) chỉ trong chưa đầy một phần triệu giây!

| Ảnh chụp thực tế ($F(24) = 46,368$) | Video hoạt động thực tế (Bấm vào ảnh để mở `.mp4`) |
| :---: | :---: |
| <a href="docs/images/mode01_fib.jpg"><img src="docs/images/mode01_fib.jpg" width="100%" alt="Ảnh chụp Chế độ 01 Fibonacci"></a> | <a href="docs/images/mode01_fib.mp4"><img src="docs/images/mode01_fib.gif" width="100%" alt="Video Chế độ 01 Fibonacci"></a> |

---

### 🔹 Chế độ `10` (`SW[17:16] = 10`): Máy Tính Nhân Hai Số Bằng Phần Mềm ($A \times B$)
* **Con chip làm gì?** Dù phần cứng cơ bản chỉ có mạch Cộng và Trừ, tụi con đã lập trình cho CPU tự thực hiện phép nhân hai số $A \times B$ bằng thuật toán cộng lặp. Khi gạt số thứ nhất ($A$) và số thứ hai ($B$) trên hàng công tắc, màn hình lập tức hiện tích số (ví dụ $7 \times 3 = 21$, $7 \times 7 = 49$):
* **Màn hình hiển thị:** **`M2:MUL OUT:00049`** và đèn số đỏ hiện **`00049`**.

| Ảnh chụp thực tế ($7 \times 7 = 49$) | Video hoạt động thực tế (Bấm vào ảnh để mở `.mp4`) |
| :---: | :---: |
| <a href="docs/images/mode10_mul.jpg"><img src="docs/images/mode10_mul.jpg" width="100%" alt="Ảnh chụp Chế độ 10 Phép nhân"></a> | <a href="docs/images/mode10_mul.mp4"><img src="docs/images/mode10_mul.gif" width="100%" alt="Video Chế độ 10 Phép nhân"></a> |

---

### 🔹 Chế độ `11` (`SW[17:16] = 11`): Vòng Quay Số Ngẫu Nhiên & Công Tắc "Đóng Băng Thời Gian" (`PAUSED!`)
* **Con chip làm gì?**
  - Khi chạy bình thường, CPU liên tục trộn các con số để tạo ra hiệu ứng đèn nhảy ngẫu nhiên giống như ma trận máy tính (`M3:LFSR`).
  - **Điểm đặc biệt nhất:** Khi gạt công tắc **`SW15`**, CPU ra lệnh cắt xung nhịp của bộ đếm thời gian để tiết kiệm điện. Ngay lập tức, toàn bộ dàn đèn đang nhảy **đứng băng tại chỗ** và màn hình LCD báo chữ **`PAUSED!`** (Tạm dừng). Khi gạt `SW15` xuống, mọi thứ lại chạy tiếp!

| Ảnh chụp thực tế (`M3:LFSR OUT:36D7`) | Video thử tính năng Đóng băng `PAUSED!` (Bấm để mở `.mp4`) |
| :---: | :---: |
| <a href="docs/images/mode11_lfsr.jpg"><img src="docs/images/mode11_lfsr.jpg" width="100%" alt="Ảnh chụp Chế độ 11 LFSR"></a> | <a href="docs/images/mode11_lfsr.mp4"><img src="docs/images/mode11_lfsr.gif" width="100%" alt="Video Chế độ 11 LFSR và PAUSED"></a> |

---

## 3. Cấu Trúc Thư Mục Dự Án

* **[README.md](README.md):** Bản giới thiệu tiếng Anh (Main English Documentation).
* **[docs/01_SRS_and_Architecture.md](docs/01_SRS_and_Architecture.md):** Tài liệu đặc tả kiến trúc hệ thống và sơ đồ khối.
* **[docs/02_Chip_Reference_Manual.md](docs/02_Chip_Reference_Manual.md):** Sổ tay tra cứu bản đồ bộ nhớ và thanh ghi của con chip.
* **[docs/03_Step_By_Step_Learning_Guide.md](docs/03_Step_By_Step_Learning_Guide.md):** Hướng dẫn từng bước thực hiện đồ án và lộ trình 3 tuần.
* **`rtl/`:** Toàn bộ 11 file mã nguồn phần cứng Verilog tạo nên con chip.
* **`sw/`:** Mã nguồn phần mềm 4 chế độ ([firmware.asm](sw/firmware.asm), [firmware.hex](sw/firmware.hex), [firmware.mif](sw/firmware.mif)).
* **`sim/`:** Bộ testbench tự kiểm tra, AHB Protocol Checker và script chạy mô phỏng ([run_sim.bat](sim/run_sim.bat), [Makefile](sim/Makefile)).
* **`fpga/`:** Project Quartus Prime và file nạp mạch ([output_files/de2_115_wrapper.sof](fpga/output_files/de2_115_wrapper.sof)).

---

## 4. Hướng Dẫn Sử Dụng Dự Án (Từ Mô Phỏng Đến Nạp Mạch FPGA)

### 4.1. Chạy mô phỏng kiểm tra trên máy tính (Simulation)
Yêu cầu cài sẵn **Icarus Verilog** (`iverilog`, `vvp`) và **GTKWave** (tùy chọn để xem sóng).
* **Windows:** Bấm đúp vào [sim/run_sim.bat](sim/run_sim.bat) hoặc chạy `sim\run_sim.bat` trong CMD/PowerShell.
* **Linux / macOS / WSL:**
  ```bash
  cd sim
  make all     # Chạy cả unit test (tb_unit_suite) và full SoC (tb_mini_soc)
  make wave    # Mở dạng sóng tb_mini_soc.vcd bằng GTKWave
  make clean   # Dọn file tạm .vvp và .vcd
  ```
* Kết quả đạt chuẩn: `tb_unit_suite` (**11 PASSED, 0 FAILED**) và `tb_mini_soc` (**8 PASSED, 0 FAILED**), 0 lỗi giao thức AHB.

---

### 4.2. Biên dịch & Nạp xuống mạch Terasic DE2-115 (Quartus Prime)
1. Cấp nguồn và kết nối mạch **Terasic DE2-115** với máy tính qua cổng **USB-Blaster**.
2. **Cách nhanh (dùng file `.sof` có sẵn):**
   * Mở **Quartus Prime Programmer**, chọn **Hardware Setup** $\rightarrow$ **USB-Blaster**.
   * Nhấn **Add File...** và chọn [fpga/output_files/de2_115_wrapper.sof](fpga/output_files/de2_115_wrapper.sof).
   * Tích **Program/Configure** rồi nhấn **Start** để nạp chip.
3. **Cách biên dịch lại từ mã nguồn:**
   * Mở project [fpga/my_soc.qpf](fpga/my_soc.qpf) bằng **Intel Quartus Prime (20.1.1 Lite)**.
   * Chạy **Compile Design** (đã cấu hình sẵn pin trong `de2_115_wrapper.qsf` và clock 50 MHz trong `de2_115_wrapper.sdc`).
   * Mở **Programmer** và nạp file `.sof` vừa tạo.

---

### 4.3. Hướng dẫn thao tác trên bảng mạch DE2-115
Sau khi nạp xong, nhấn **`KEY[0]`** để reset CPU về `PC = 0x0000_0000`, sau đó dùng hàng công tắc gạt **`SW[17:0]`**:

| Công tắc / Nút nhấn | Chức năng |
| :--- | :--- |
| **`KEY[0]`** | Reset toàn bộ hệ thống (nhấn để khởi động lại chương trình) |
| **`SW[17:16]`** | Chọn chế độ: `00` (KITT), `01` (Fibonacci), `10` (Nhân $A \times B$), `11` (LFSR) |
| **`SW[15]`** | Đóng băng xung nhịp Timer (`1` = Tạm dừng / `PAUSED!`, `0` = Chạy tiếp) |
| **`SW[14:12]`** | Điều chỉnh tốc độ Timer (`000` nhanh nhất $\rightarrow$ `111` chậm nhất) |
| **`SW[11:0]`** | • Mode `00`: Tạo mẫu XOR chồng lên vệt đèn KITT<br/>• Mode `01`: `SW[4:0]` nhập số $N$ (`0..24`) để tính $F(N)$<br/>• Mode `10`: `SW[11:6]` nhập $A$ (`0..63`), `SW[5:0]` nhập $B$ (`0..63`) để tính $A \times B$ |

**Quan sát kết quả hiển thị:**
* **`LEDR[17:0]`:** Hiển thị mã chế độ ở `LEDR[17:16]` và kết quả nhị phân 16-bit ở `LEDR[15:0]`.
* **`HEX7..HEX0`:** `HEX7..6` hiện `PC`, `HEX5` hiện chế độ (`0..3`), `HEX4..0` hiện giá trị thập phân 5 chữ số.
* **Màn hình LCD 16×2:** Dòng 1 hiện `LKKN DND MINISOC`, dòng 2 hiện chế độ và kết quả theo thời gian thực.

---

### 4.4. Tùy chỉnh phần mềm (Firmware)
* Mã nguồn hợp ngữ MIPS32 nằm tại [sw/firmware.asm](sw/firmware.asm).
* Khi thay đổi chương trình, cập nhật hai file khởi tạo bộ nhớ [sw/firmware.hex](sw/firmware.hex) (cho mô phỏng `iverilog`) và [sw/firmware.mif](sw/firmware.mif) (cho Quartus M9K RAM), sau đó chạy lại mô phỏng hoặc biên dịch lại trên Quartus.
