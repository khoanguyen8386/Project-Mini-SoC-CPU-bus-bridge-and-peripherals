```markdown
# Mini-SoC Chip Reference Manual & Register Programmer's Guide
**Architecture:** 32-Bit Little-Endian MIPS32 / AMBA 3 AHB-Lite & APB3 SoC  
**System Clock:** 50 MHz (`CLOCK_50`)

---

## 1. System Memory Map

The 32-bit address space (`0x0000_0000` to `0xFFFF_FFFF`) is partitioned by the central AHB-Lite Decoder (`ahb_lite_interconnect.v`) and secondary APB Bridge Decoder (`ahb_to_apb_bridge.v`) as follows:

| Bus Tier | Select Signal | Start Address | End Address | Size | Target Block / Function |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **AHB-Lite** | `HSEL_SRAM` | `0x0000_0000` | `0x0000_0FFF` | 4 KB | On-Chip Dual-Port M9K Instruction/Data SRAM |
| **AHB-Lite** | `HSEL_DEF` | `0x0000_1000` | `0x3FFF_FFFF` | ~1 GB | Unmapped Region (Default Slave -> 2-Cycle `HRESP=ERROR`) |
| **AHB-Lite** | `HSEL_APB` | `0x4000_0000` | `0x4000_3FFF` | 16 KB | AHB-to-APB Bridge Window |
| ↳ **APB** | `PSEL_GPIO` | `0x4000_0000` | `0x4000_0FFF` | 4 KB | **APB Slave 0:** GPIO Controller (`SW[17:0]`, `LEDR[17:0]`) |
| ↳ **APB** | `PSEL_TIMER` | `0x4000_1000` | `0x4000_1FFF` | 4 KB | **APB Slave 1:** 32-Bit Hardware Timer + IRQ |
| ↳ **APB** | `PSEL_UART` | `0x4000_2000` | `0x4000_2FFF` | 4 KB | **APB Slave 2:** UART Controller (115200 8N1) |
| ↳ **APB** | `PSEL_CLK` | `0x4000_3000` | `0x4000_3FFF` | 4 KB | **APB Slave 3:** Low-Power Clock-Enable Controller |
| **AHB-Lite** | `HSEL_DEF` | `0x4000_4000` | `0xFFFF_FFFF` | ~3 GB | Unmapped Region (Default Slave -> 2-Cycle `HRESP=ERROR`) |

### 1.1 On-Chip SRAM Memory Layout (`0x0000_0000 – 0x0000_0FFF`)
| Address Offset | MIPS Symbol | Purpose |
| :--- | :--- | :--- |
| `0x0000_0000` | `_reset_vec` | CPU Reset Vector (`PC` initializes to `0x0000_0000` on `HRESETn=0`) |
| `0x0000_0010` | `_irq_vec` | Hardware Interrupt Vector (jumped to when `timer_irq=1` and `IE=1`) |
| `0x0000_0020` | `_main` | Main Firmware Text Segment |
| `0x0000_0F00` | `_data` | Global Variables / Interrupt Counter Storage |
| `0x0000_0FFC` | `_stack_top` | Initial Stack Pointer (`$sp`) |

---

## 2. CPU Architecture & Interrupt Mechanism (`cpu_core_mips.v`)

The CPU implements the standard single-cycle MIPS32 instruction set plus a lightweight hardware interrupt controller for `timer_irq`:

### 2.1 Supported Instruction Encodings
| Mnemonic | Format | Opcode (`[31:26]`) | Funct (`[5:0]`) | Operation |
| :--- | :--- | :--- | :--- | :--- |
| `ADD rd, rs, rt` | R | `6'b000000` | `6'b100000` | `R[rd] = R[rs] + R[rt]` |
| `SUB rd, rs, rt` | R | `6'b000000` | `6'b100010` | `R[rd] = R[rs] - R[rt]` |
| `AND rd, rs, rt` | R | `6'b000000` | `6'b100100` | `R[rd] = R[rs] & R[rt]` |
| `OR rd, rs, rt` | R | `6'b000000` | `6'b100101` | `R[rd] = R[rs] \| R[rt]` |
| `XOR rd, rs, rt` | R | `6'b000000` | `6'b100110` | `R[rd] = R[rs] ^ R[rt]` |
| `NOR rd, rs, rt` | R | `6'b000000` | `6'b100111` | `R[rd] = ~(R[rs] \| R[rt])` |
| `SLT rd, rs, rt` | R | `6'b000000` | `6'b101010` | `R[rd] = ($signed(R[rs]) < $signed(R[rt])) ? 1 : 0` |
| `SLL rd, rt, shamt`| R | `6'b000000` | `6'b000000` | `R[rd] = R[rt] << shamt` (`NOP` when all zeros) |
| `SRL rd, rt, shamt`| R | `6'b000000` | `6'b000010` | `R[rd] = R[rt] >> shamt` |
| `JR rs` | R | `6'b000000` | `6'b001000` | `PC = R[rs]` |
| `ADDI rt, rs, imm` | I | `6'b001000` | — | `R[rt] = R[rs] + SignExt(imm)` |
| `ANDI rt, rs, imm` | I | `6'b001100` | — | `R[rt] = R[rs] & ZeroExt(imm)` |
| `ORI rt, rs, imm` | I | `6'b001101` | — | `R[rt] = R[rs] \| ZeroExt(imm)` |
| `XORI rt, rs, imm` | I | `6'b001110` | — | `R[rt] = R[rs] ^ ZeroExt(imm)` |
| `LUI rt, imm` | I | `6'b001111` | — | `R[rt] = {imm, 16'h0000}` |
| `LW rt, imm(rs)` | I | `6'b100011` | — | `R[rt] = Mem32[R[rs] + SignExt(imm)]` |
| `SW rt, imm(rs)` | I | `6'b101011` | — | `Mem32[R[rs] + SignExt(imm)] = R[rt]` |
| `BEQ rs, rt, imm` | I | `6'b000100` | — | `if (R[rs] == R[rt]) PC = PC + 4 + (SignExt(imm)<<2)` |
| `BNE rs, rt, imm` | I | `6'b000101` | — | `if (R[rs] != R[rt]) PC = PC + 4 + (SignExt(imm)<<2)` |
| `J target` | J | `6'b000010` | — | `PC = {PC_plus4[31:28], target, 2'b00}` |
| `JAL target` | J | `6'b000011` | — | `R[31] = PC + 4; PC = {PC_plus4[31:28], target, 2'b00}` |
| `ERET` | COP0 | `6'b010000` | `6'b011000` | `PC = EPC; irq_en <= 1'b1; in_isr <= 1'b0` (`0x42000018`) |

### 2.2 Hardware Interrupt Sequence (`timer_irq`)
- On reset, internal interrupt enable `irq_en = 1'b1` and `in_isr = 1'b0`.
- When `timer_irq == 1'b1 && irq_en == 1'b1 && !in_isr && !cpu_stall`:
  1. The current instruction completes (or if at an instruction boundary, the next `PC` is saved into `EPC`).
  2. `in_isr` is set to `1'b1` and `irq_en` is cleared to `1'b0` to prevent nested interrupt re-entry.
  3. `PC` jumps to the fixed Interrupt Service Routine vector at `0x0000_0010`.
- Inside the ISR, firmware clears the Timer `STATUS.IF` bit (W1C) at `0x4000_1004` and executes `ERET` (`0x42000018`), which restores `PC <= EPC` and re-enables `irq_en <= 1'b1`.

---

## 3. APB Peripheral Register Specifications

### 3.1 APB Slave 3: Low-Power Clock Controller (`apb_clk_ctrl.v`)
**Base Address:** `0x4000_3000`  
*Note: This peripheral is always clocked so software can wake up or gate other peripherals at any time.*

#### Register Summary
| Offset | Name | Access | Reset Value | Description |
| :--- | :--- | :--- | :--- | :--- |
| `0x00` | `CLK_EN_REG` | R/W | `0x0000_0007` | Peripheral Synchronous Clock-Enable Control Register |

#### `CLK_EN_REG` (`0x4000_3000`) Bit Fields
| Bits | Field Name | Access | Reset | Description |
| :--- | :--- | :--- | :--- | :--- |
| `[31:3]` | `RESERVED` | RO | `29'h0` | Reserved. Reads as `0`; writes ignored. |
| `[2]` | `UART_CLK_EN` | R/W | `1'b1` | `1`: Enable UART clock (`clk_en_uart`). `0`: Gate UART logic. |
| `[1]` | `TIMER_CLK_EN`| R/W | `1'b1` | `1`: Enable Timer clock (`clk_en_timer`). `0`: Gate Timer logic. |
| `[0]` | `GPIO_CLK_EN` | R/W | `1'b1` | `1`: Enable GPIO clock (`clk_en_gpio`). `0`: Gate GPIO logic. |

---

### 3.2 APB Slave 0: General Purpose I/O (`apb_gpio.v`)
**Base Address:** `0x4000_0000`  
**Clock Gate Signal:** `clk_en_gpio` (`CLK_EN_REG[0]`)

#### Register Summary
| Offset | Name | Access | Reset Value | Description |
| :--- | :--- | :--- | :--- | :--- |
| `0x00` | `GPIO_SW_IN` | RO | `0x0000_0000` | Synchronized DE2-115 Slide Switches (`SW[17:0]`) |
| `0x04` | `GPIO_LEDR_OUT`| R/W | `0x0000_0000` | DE2-115 Red LEDs Output Register (`LEDR[17:0]`) |
| `0x08` | `GPIO_DIR` | R/W | `0x0003_FFFF` | Direction / Output Enable Mask (`1` = Drive `LEDR` bit) |

#### `GPIO_SW_IN` (`0x4000_0000`) Bit Fields
| Bits | Field Name | Access | Reset | Description |
| :--- | :--- | :--- | :--- | :--- |
| `[31:18]`| `RESERVED` | RO | `14'h0` | Reads as `0`. |
| `[17:0]` | `SW_DATA` | RO | `18'h0` | Real-time state of DE2-115 `SW[17:0]` passed through a 2-FF synchronizer. |

#### `GPIO_LEDR_OUT` (`0x4000_0004`) Bit Fields
| Bits | Field Name | Access | Reset | Description |
| :--- | :--- | :--- | :--- | :--- |
| `[31:18]`| `RESERVED` | RO | `14'h0` | Reads as `0`. |
| `[17:0]` | `LEDR_DATA` | R/W | `18'h0` | Output value driven onto `LEDR[17:0]` (masked by `GPIO_DIR[17:0]`). |

#### `GPIO_DIR` (`0x4000_0008`) Bit Fields
| Bits | Field Name | Access | Reset | Description |
| :--- | :--- | :--- | :--- | :--- |
| `[31:18]`| `RESERVED` | RO | `14'h0` | Reads as `0`. |
| `[17:0]` | `LEDR_OE` | R/W | `18'h3FFFF`| Output mask: `LEDR[i] = LEDR_DATA[i] & LEDR_OE[i]`. Defaults to all enabled. |

---

### 3.3 APB Slave 1: 32-Bit Hardware Timer (`apb_timer.v`)
**Base Address:** `0x4000_1000`  
**Clock Gate Signal:** `clk_en_timer` (`CLK_EN_REG[1]`)  
**Interrupt Output:** `timer_irq` (Active-HIGH level interrupt to CPU)

#### Register Summary
| Offset | Name | Access | Reset Value | Description |
| :--- | :--- | :--- | :--- | :--- |
| `0x00` | `TIMER_CTRL` | R/W | `0x0000_0000` | Timer Control Register |
| `0x04` | `TIMER_STATUS` | R/W1C | `0x0000_0000` | Timer Interrupt Status Register (Write-1-to-Clear) |
| `0x08` | `TIMER_RELOAD` | R/W | `0x02FA_F080` | 32-Bit Reload Value (Default `50,000,000` = 1.0 sec @ 50 MHz) |
| `0x0C` | `TIMER_COUNT` | RO | `0x02FA_F080` | Current 32-Bit Down-Counter Value |

#### `TIMER_CTRL` (`0x4000_1000`) Bit Fields
| Bits | Field Name | Access | Reset | Description |
| :--- | :--- | :--- | :--- | :--- |
| `[31:3]` | `RESERVED` | RO | `29'h0` | Reads as `0`. |
| `[2]` | `AUTO_RELOAD` | R/W | `1'b0` | `1`: Reload `TIMER_COUNT <= TIMER_RELOAD` automatically on underflow (`COUNT == 0`). `0`: One-shot mode. |
| `[1]` | `IRQ_EN` | R/W | `1'b0` | `1`: Assert `timer_irq` output when `TIMER_STATUS.TIMEOUT_IF == 1`. |
| `[0]` | `ENABLE` | R/W | `1'b0` | `1`: Counter decrements every 50 MHz clock cycle (when `clk_en_timer=1`). |

#### `TIMER_STATUS` (`0x4000_1004`) Bit Fields
| Bits | Field Name | Access | Reset | Description |
| :--- | :--- | :--- | :--- | :--- |
| `[31:1]` | `RESERVED` | RO | `31'h0` | Reads as `0`. |
| `[0]` | `TIMEOUT_IF` | R/W1C | `1'b0` | Set to `1` by hardware when `TIMER_COUNT` reaches `0`. Write `1` to clear (`0` writes have no effect). |

---

### 3.4 APB Slave 2: UART Controller (`apb_uart.v`)
**Base Address:** `0x4000_2000`  
**Clock Gate Signal:** `clk_en_uart` (`CLK_EN_REG[2]`)  
**Default Baud Rate:** 115,200 bps @ 50 MHz (`BAUD_DIV = 434`, 8 Data Bits, No Parity, 1 Stop Bit)

#### Register Summary
| Offset | Name | Access | Reset Value | Description |
| :--- | :--- | :--- | :--- | :--- |
| `0x00` | `UART_TXDATA` | WO | `0x0000_0000` | Transmit Data Register (Writing `[7:0]` starts transmission) |
| `0x04` | `UART_RXDATA` | RO | `0x0000_0000` | Receive Data Register (Reading clears `RX_VALID` flag) |
| `0x08` | `UART_STATUS` | RO | `0x0000_0004` | UART Line Status Register |
| `0x0C` | `UART_CTRL` | R/W | `0x0000_0003` | UART Control Register (`TX_EN`, `RX_EN`, `SIM_FAST_BAUD`) |
| `0x10` | `UART_BAUDDIV` | R/W | `0x0000_01B2` | 16-Bit Baud Rate Divider (`0x01B2` = **434** decimal for 50 MHz) |

#### `UART_STATUS` (`0x4000_2008`) Bit Fields
| Bits | Field Name | Access | Reset | Description |
| :--- | :--- | :--- | :--- | :--- |
| `[31:3]` | `RESERVED` | RO | `29'h0` | Reads as `0`. |
| `[2]` | `TX_READY` | RO | `1'b1` | `1`: Transmitter is idle (`!TX_BUSY`) and ready to accept a new byte. |
| `[1]` | `RX_VALID` | RO | `1'b0` | `1`: A complete byte has been received in `UART_RXDATA[7:0]`. Cleared automatically when `UART_RXDATA` is read or by writing `1` to `UART_STATUS[1]`. |
| `[0]` | `TX_BUSY` | RO | `1'b0` | `1`: UART TX shift register is actively transmitting a frame. |

#### `UART_CTRL` (`0x4000_200C`) Bit Fields
| Bits | Field Name | Access | Reset | Description |
| :--- | :--- | :--- | :--- | :--- |
| `[31:2]` | `RESERVED` | RO | `30'h0` | Reads as `0`. |
| `[1]` | `RX_EN` | R/W | `1'b1` | `1`: Enable UART Receiver FSM. |
| `[0]` | `TX_EN` | R/W | `1'b1` | `1`: Enable UART Transmitter FSM. |

#### `UART_BAUDDIV` (`0x4000_2010`) Bit Fields
| Bits | Field Name | Access | Reset | Description |
| :--- | :--- | :--- | :--- | :--- |
| `[31:16]`| `RESERVED` | RO | `16'h0` | Reads as `0`. |
| `[15:0]` | `BAUD_DIV` | R/W | `16'd434`| Clock cycles per bit period ($\ge 4$). Defaults to `434` ($50\text{ MHz} / 115200\text{ bps}$). |