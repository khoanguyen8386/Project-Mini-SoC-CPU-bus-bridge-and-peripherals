# System Requirements Specification (SRS) & Microarchitecture
**Project:** Topic 19 — AMBA 3 AHB-Lite / APB3 Mini-SoC  
**Target Device:** Intel/Altera Cyclone IV E (`EP4CE115F29C7` on Terasic DE2-115)  
**System Clock (`HCLK` / `PCLK`):** 50.000 MHz (`CLOCK_50`, `PIN_Y2`, $T_{\text{clk}} = 20\text{ ns}$)

---

## 1. System Overview & Architectural Philosophy

This Mini-SoC integrates a 32-bit single-cycle MIPS32 processor core with a two-tier industry-standard ARM AMBA bus hierarchy:
1. **High-Bandwidth Tier (AMBA 3 AHB-Lite v1.0):** Connects the CPU data master port to low-latency on-chip M9K SRAM (`HSEL_SRAM`), the AHB-to-APB Bridge (`HSEL_APB`), and a protocol-compliant Default Slave (`HSEL_DEF`) that returns a two-cycle `ERROR` response on unmapped address accesses.
2. **Low-Power Peripheral Tier (AMBA 3 APB):** Isolates lower-speed I/O peripherals (`GPIO`, `Timer`, `UART`, and `Clock Controller`) behind an AHB-to-APB synchronous bridge. Each peripheral is gated via FPGA-safe synchronous clock-enable signals (`clk_en_*`) controlled by the APB Clock Control block.

### 1.1 Dual-Port M9K Memory Architecture (Harvard Execution + Unified AHB Access)
To allow a single-cycle MIPS CPU to fetch instructions every cycle without structural bus hazards while still adhering strictly to the single-master AMBA 3 AHB-Lite topology (ARM IHI 0033A Section 1.1):
- The on-chip memory (`onchip_sram.v`) is implemented as a true dual-port Cyclone IV M9K Block RAM (1024 words $\times$ 32 bits = 4 KB).
- **Port A (Instruction Fetch):** Directly connected to the CPU Program Counter (`imem_addr` / `imem_rdata`) for zero-wait-state instruction execution.
- **Port B (Data & Firmware Inspection):** Connected as **AHB-Lite Slave 0 (`HSEL_SRAM`)** at `0x0000_0000 – 0x0000_0FFF`, supporting byte, halfword, and word reads/writes (`HSIZE = 3'b000, 3'b001, 3'b010`).

---

## 2. Top-Level Block Diagram

```mermaid
graph TB
    subgraph DE2_115_Board["Terasic DE2-115 Board (EP4CE115F29C7)"]
        CLK50["CLOCK_50 (PIN_Y2)<br/>50 MHz"]
        KEY0["KEY[0] (PIN_M23)<br/>Active-Low Reset"]
        SW_IN["SW[17:0]<br/>Slide Switches"]
        LEDR_OUT["LEDR[17:0]<br/>Red LEDs"]
        UART_PINS["UART_TXD (PIN_G9)<br/>UART_RXD (PIN_G12)"]

        subgraph Mini_SoC["mini_soc_top"]
            RST_SYNC["2-FF Reset Synchronizer<br/>Async Assert / Sync Deassert"]
            
            subgraph CPU_Sub["CPU Subsystem"]
                MIPS["Single-Cycle MIPS32 Core<br/>+ Hardware IRQ Vector (0x0000_0010)<br/>+ Bus Stall Control"]
                AHB_M["AHB-Lite Master Wrapper<br/>(Address & Data Phase FSM)"]
            end

            subgraph AHB_Fabric["AMBA 3 AHB-Lite Interconnect (ARM IHI 0033A)"]
                DEC["Central Address Decoder<br/>HSEL_SRAM | HSEL_APB | HSEL_DEF"]
                MUX["Slave-to-Master Multiplexor<br/>Retimed Data-Phase HSEL_d"]
                DEF_SLV["Default Slave<br/>2-Cycle HRESP=ERROR"]
            end

            SRAM["On-Chip Dual-Port M9K SRAM<br/>4 KB (firmware.hex / .mif)<br/>0x0000_0000 - 0x0000_0FFF"]
            BRIDGE["AHB-Lite to APB3 Bridge<br/>Wait-State Insertion (HREADYOUT)"]

            subgraph APB_Bus["AMBA 3 APB Peripheral Bus (0x4000_0000 - 0x4000_3FFF)"]
                P_GPIO["APB Slave 0: GPIO<br/>0x4000_0000<br/>(clk_en_gpio)"]
                P_TIM["APB Slave 1: 32-bit Timer<br/>0x4000_1000<br/>(clk_en_timer)"]
                P_UART["APB Slave 2: UART 115200 8N1<br/>0x4000_2000<br/>(clk_en_uart)"]
                P_CLK["APB Slave 3: Clock Control<br/>0x4000_3000<br/>(Always Enabled)"]
            end
        end
    end

    CLK50 --> RST_SYNC
    KEY0 --> RST_SYNC
    RST_SYNC -->|HRESETn| Mini_SoC
    MIPS <-->|Port A: IFetch| SRAM
    MIPS <--> AHB_M
    AHB_M -->|HADDR, HTRANS, HWRITE, HSIZE, HWDATA| DEC
    DEC -->|HSEL_SRAM| SRAM
    DEC -->|HSEL_APB| BRIDGE
    DEC -->|HSEL_DEF| DEF_SLV
    SRAM -->|HRDATA_SRAM, HREADYOUT_SRAM| MUX
    BRIDGE -->|HRDATA_APB, HREADYOUT_APB| MUX
    DEF_SLV -->|HRESP_DEF, HREADYOUT_DEF| MUX
    MUX -->|HRDATA, HREADY, HRESP| AHB_M

    BRIDGE -->|PADDR, PSELx, PENABLE, PWRITE, PWDATA| APB_Bus
    P_CLK -->|clk_en_gpio, clk_en_timer, clk_en_uart| APB_Bus
    P_TIM -->|timer_irq| MIPS
    SW_IN --> P_GPIO
    P_GPIO --> LEDR_OUT
    P_UART <--> UART_PINS