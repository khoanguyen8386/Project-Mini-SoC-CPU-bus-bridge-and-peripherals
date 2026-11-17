# Mini-SoC: MIPS32 CPU, AMBA AHB/APB Bus Bridge & Peripherals

A 32-bit **MIPS32** Mini-SoC implemented in Verilog HDL, featuring an **AMBA AHB-Lite** system bus, an **AHB-to-APB3** bridge, on-chip SRAM, and memory-mapped APB peripherals, synthesized and verified on the **Terasic DE2-115** FPGA board (`EP4CE115F29C7` @ 50 MHz).

## Architecture Overview

```text
+-------------------+       +-------------------+       +-----------------------+
|   cpu_core_mips   |<----->|  cpu_ahb_wrapper  |<----->| ahb_lite_interconnect |
| (Single-Cycle +   |       +-------------------+       +-----------+-----------+
|  Stall & IRQ)     |                                               |
+-------------------+                                  +------------+------------+
        ^                                              |                         |
        | imem_addr/rdata                              v                         v
        +-------------------------------------> +-------------+       +--------------------+
                                                | onchip_sram |       | ahb_to_apb_bridge  |
                                                +-------------+       +---------+----------+
                                                                                |
                                                      +------------+------------+------------+
                                                      |            |            |            |
                                                      v            v            v            v
                                                  apb_gpio     apb_timer    apb_uart   apb_clk_ctrl
```

### Key Features
- **CPU Core (`cpu_core_mips`):** Single-cycle MIPS32 core with bus-stall support (`cpu_stall`) and hardware interrupt handling (`timer_irq`, `epc`, `eret`).
- **Bus Architecture:** AMBA AHB-Lite interconnect (`0x0000_0xxx` for SRAM, `0x4000_xxxx` for APB) and AHB-to-APB3 bridge (`ST_IDLE` -> `ST_SETUP` -> `ST_ACCESS`).
- **Peripherals:**
  - `apb_gpio` (`0x4000_0000`): 18-bit `SW` input & 18-bit `LEDR` output.
  - `apb_timer` (`0x4000_1000`): Programmable countdown timer with auto-reload and interrupt generation.
  - `apb_uart` (`0x4000_2000`): Serial UART controller (115200 baud).
  - `apb_clk_ctrl` (`0x4000_3000`): Per-peripheral clock gating control.
- **DE2-115 Board Wrapper (`de2_115_wrapper`):** Reset synchronizer (`KEY[0]`), Binary-to-BCD converter, 8-digit 7-segment display (`HEX0`–`HEX7`), and 16x2 LCD controller.

## Repository Structure

```text
├── docs/       # SRS, Architecture, Chip Reference Manual & Learning Guide
├── fpga/       # Intel Quartus Prime 20.1.1 project (my_soc.qpf, pinout .qsf, timing .sdc)
├── rtl/        # Verilog RTL source files (CPU, AHB/APB bus, peripherals, wrappers)
└── sw/         # MIPS32 assembly firmware (firmware.asm, .hex, .mif)
```

## Quick Start (Terasic DE2-115)

1. Open `fpga/my_soc.qpf` in **Intel Quartus Prime (v20.1.1+)**.
2. Ensure `de2_115_wrapper` is set as the Top-Level Entity.
3. Run **Compile Design** (Synthesis, Fitter, Assembler).
4. Program the generated `.sof` file in `fpga/output_files/` onto the DE2-115 board via USB-Blaster.

### Firmware Demo Controls (`sw/firmware.asm`)
- **`KEY[0]`**: Active-low system reset.
- **`SW[17:16]`**: Select 1 of 4 demo modes (displayed on `LEDR[15:0]` and `HEX0`–`HEX7`):
  - `00`: Knight Rider (KITT) scanner XORed with `SW[11:0]`
  - `01`: Fibonacci calculator `Fib(SW[4:0])`
  - `10`: Software multiplier `SW[11:6] * SW[5:0]`
  - `11`: 32-bit LFSR pseudo-random matrix + KITT wave
- **`SW[15]`**: Hardware clock-gating freeze (`1` = gate Timer clock, `0` = run).
- **`SW[14:12]`**: Real-time Timer interrupt speed (`000` = fastest, `111` = slowest).
