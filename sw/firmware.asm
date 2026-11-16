# =============================================================================
# Mini-SoC 4-Mode CPU Benchmark & Visual Showcase Firmware (MIPS32)
# Target: Terasic DE2-115 (Cyclone IV E EP4CE115F29C7 @ 50 MHz)
# =============================================================================
# Global Controls (Active in ALL Modes):
#   SW[17:16] : Mode Selector (00, 01, 10, 11) -> Shown on LEDR[17:16]
#   SW[15]    : Hardware Clock-Gating Freeze (1 = Gate Timer Clock, 0 = Run)
#   SW[14:12] : Real-Time Timer Speed Control (000 = Fastest, 111 = Slowest)
#
# 4 Showcase Modes (Displayed on LEDR[15:0]):
#   Mode 00 (SW[17:16]=00) : Knight Rider / KITT Scanner + SW[11:0] XOR Overlay
#   Mode 01 (SW[17:16]=01) : Dynamic Programming Fibonacci Calculator Fib(SW[4:0])
#   Mode 10 (SW[17:16]=10) : Software Multiplier A * B (A = SW[11:6], B = SW[5:0])
#   Mode 11 (SW[17:16]=11) : 32-Bit LFSR Pseudo-Random Matrix + KITT Wave
# =============================================================================

_reset_vec:                         # [Word 00..03 | 0x0000_0000]
    lui   $s0, 0x4000               # 00: $s0 = 0x4000_0000 (APB Base)
    ori   $s2, $zero, 0x0003        # 01: $s2 = 16'h0003 (2-LED KITT Scanner Bar)
    ori   $k0, $zero, 0x0001        # 02: $k0 = 1 (Constant 1)
    j     _init                     # 03: Jump to _init (Word 18)

_irq_vec:                           # [Word 04..17 | 0x0000_0010] Timer ISR
    sw    $k0, 0x1004($s0)          # 04: Clear Timer TIMEOUT_IF (W1C = 1)
    sll   $k1, $s4, 1               # 05: LFSR step: $k1 = $s4 << 1
    xori  $s4, $k1, 0x5A39          # 06: $s4 = ($s4 << 1) ^ 0x5A39
    bne   $s3, $zero, _kitt_right   # 07: If dir != 0, move right
    sll   $s2, $s2, 1               # 08: Move KITT bar left ($s2 <<= 1)
    ori   $k1, $zero, 0xC000        # 09: Left boundary mask (LEDR[15:14])
    bne   $s2, $k1, _isr_exit       # 10: If not at left edge, exit ISR
    ori   $s3, $zero, 0x0001        # 11: Hit left edge -> reverse direction to right
    j     _isr_exit                 # 12: Jump to ERET
_kitt_right:
    srl   $s2, $s2, 1               # 13: Move KITT bar right ($s2 >>= 1)
    ori   $k1, $zero, 0x0003        # 14: Right boundary mask (LEDR[1:0])
    bne   $s2, $k1, _isr_exit       # 15: If not at right edge, exit ISR
    ori   $s3, $zero, 0x0000        # 16: Hit right edge -> reverse direction to left
_isr_exit:
    eret                            # 17: Return from Interrupt

_init:                              # [Word 18..19 | 0x0000_0048]
    ori   $t0, $zero, 0x0007        # 18: $t0 = AUTO_RELOAD | IRQ_EN | ENABLE
    sw    $t0, 0x1000($s0)          # 19: Start APB Hardware Timer

_main:                              # [Word 20..31 | 0x0000_0050]
    lw    $t0, 0x0000($s0)          # 20: Read SW[17:0] from GPIO_SW_IN
    srl   $t1, $t0, 14              # 21: Align SW[15] to bit 1
    andi  $t1, $t1, 0x0002          # 22: Mask bit 1 (TIMER_CLK_EN)
    xori  $t1, $t1, 0x0007          # 23: SW[15]=0 -> 7 (Run), SW[15]=1 -> 5 (Freeze Timer)
    sw    $t1, 0x3000($s0)          # 24: Write APB Clock Controller (CLK_EN_REG)
    srl   $t1, $t0, 12              # 25: Extract SW[14:12] speed setting
    andi  $t1, $t1, 0x0007          # 26: $t1 = 0..7
    addiu $t1, $t1, 1               # 27: $t1 = 1..8
    sll   $t1, $t1, 22              # 28: $t1 = (1..8) * 4.19M cycles (~0.08s..0.67s)
    beq   $t1, $s5, _mode_dec       # 29: Only update TIMER_RELOAD when SW[14:12] changes
    ori   $s5, $t1, 0x0000          # 30: Save new speed setting in $s5
    sw    $t1, 0x1008($s0)          # 31: Update APB Timer Reload Register

_mode_dec:                          # [Word 32..37 | 0x0000_0080]
    srl   $t5, $t0, 16              # 32: $t5 = SW[17:16] (Mode 0..3)
    beq   $t5, $k0, _mode_fib       # 33: Mode 01 -> Fibonacci Calculator
    ori   $t6, $zero, 0x0002        # 34: $t6 = 2
    beq   $t5, $t6, _mode_mul       # 35: Mode 10 -> Software Multiplier
    ori   $t6, $zero, 0x0003        # 36: $t6 = 3
    beq   $t5, $t6, _mode_lfsr      # 37: Mode 11 -> LFSR Cyberpunk Matrix

_mode_kitt:                         # [Word 38..40 | Mode 00: KITT Scanner]
    andi  $t2, $t0, 0x0FFF          # 38: $t2 = SW[11:0] interactive pattern
    xor   $t4, $s2, $t2             # 39: Overlay KITT scanner bar with SW[11:0]
    j     _display                  # 40: Output to LEDs

_mode_fib:                          # [Word 41..49 | Mode 01: Fibonacci(SW[4:0])]
    andi  $t1, $t0, 0x001F          # 41: N = SW[4:0] (0..24)
    ori   $t4, $zero, 0x0000        # 42: f0 = 0
    ori   $t2, $zero, 0x0001        # 43: f1 = 1
_fib_loop:
    beq   $t1, $zero, _display      # 44: When N == 0, $t4 holds Fib(N)
    addu  $t3, $t4, $t2             # 45: next = f0 + f1
    ori   $t4, $t2, 0x0000          # 46: f0 = f1
    ori   $t2, $t3, 0x0000          # 47: f1 = next
    addiu $t1, $t1, -1              # 48: N--
    j     _fib_loop                 # 49: Repeat loop

_mode_mul:                          # [Word 50..57 | Mode 10: Multiplier A * B]
    srl   $t1, $t0, 6               # 50: Shift SW[11:6] down
    andi  $t1, $t1, 0x003F          # 51: A = SW[11:6] (0..63)
    andi  $t2, $t0, 0x003F          # 52: B = SW[5:0]  (0..63)
    ori   $t4, $zero, 0x0000        # 53: product = 0
_mul_loop:
    beq   $t2, $zero, _display      # 54: When B == 0, $t4 holds A * B
    addu  $t4, $t4, $t1             # 55: product += A
    addiu $t2, $t2, -1              # 56: B--
    j     _mul_loop                 # 57: Repeat loop

_mode_lfsr:                         # [Word 58 | Mode 11: LFSR Matrix]
    xor   $t4, $s4, $s2             # 58: Combine 32-bit LFSR with KITT Scanner

_display:                           # [Word 59..63 | Common LED Output]
    andi  $t4, $t4, 0xFFFF          # 59: Mask 16-bit result for LEDR[15:0]
    sll   $t5, $t5, 16              # 60: Place Mode ID onto LEDR[17:16]
    or    $t4, $t4, $t5             # 61: Combine {Mode[1:0], Result[15:0]}
    sw    $t4, 0x0004($s0)          # 62: Drive GPIO_LEDR_OUT (LEDR[17:0])
    j     _main                     # 63: Next frame
