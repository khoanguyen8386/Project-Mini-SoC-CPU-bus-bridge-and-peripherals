`timescale 1ns / 1ps

module tb_mini_soc;

    localparam int CLK_PERIOD = 20; // 50 MHz
    localparam int CLK_FREQ   = 50_000_000;
    localparam int BAUD_RATE  = 115200;
    localparam int BIT_PERIOD = CLK_FREQ / BAUD_RATE; // ~434 clocks

    logic        HCLK;
    logic        HRESETn;
    logic [17:0] gpio_sw_in;
    logic [17:0] gpio_ledr_out;
    logic        uart_txd;
    logic        uart_rxd;
    logic [31:0] dbg_pc;
    logic        dbg_timer_irq;

    int unsigned pass_count;
    int unsigned fail_count;

    // Instantiate Full SoC DUT
    mini_soc_top #(
        .CLK_FREQ       (CLK_FREQ),
        .UART_BAUD_RATE (BAUD_RATE),
        .TIMER_RELOAD   (32'd50_000_000),
        .MEM_INIT_HEX   ("../sw/firmware.hex"),
        .MEM_INIT_MIF   ("../sw/firmware.mif")
    ) dut (
        .HCLK          (HCLK),
        .HRESETn       (HRESETn),
        .gpio_sw_in    (gpio_sw_in),
        .gpio_ledr_out (gpio_ledr_out),
        .uart_txd      (uart_txd),
        .uart_rxd      (uart_rxd),
        .dbg_pc        (dbg_pc),
        .dbg_timer_irq (dbg_timer_irq)
    );

    // Monitor internal AHB-Lite bus with protocol checker
    ahb_protocol_checker #(.NAME("SOC_AHB_MON")) u_ahb_mon (
        .HCLK    (dut.HCLK),
        .HRESETn (dut.HRESETn),
        .HADDR   (dut.HADDR),
        .HTRANS  (dut.HTRANS),
        .HSIZE   (dut.HSIZE),
        .HWRITE  (dut.HWRITE),
        .HWDATA  (dut.HWDATA),
        .HRDATA  (dut.HRDATA),
        .HREADY  (dut.HREADY),
        .HRESP   (dut.HRESP)
    );

    // Clock generation
    initial begin
        HCLK = 1'b0;
        forever #(CLK_PERIOD / 2) HCLK = ~HCLK;
    end

    // Serial UART 8N1 Decoder on uart_txd
    logic [7:0] uart_rx_byte;
    initial begin : uart_decoder
        @(posedge HRESETn);
        forever begin
            // Wait for start bit (falling edge)
            @(negedge uart_txd);
            // Sample mid-start bit
            repeat (BIT_PERIOD / 2) @(posedge HCLK);
            if (uart_txd === 1'b0) begin
                for (int i = 0; i < 8; i++) begin
                    repeat (BIT_PERIOD) @(posedge HCLK);
                    uart_rx_byte[i] = uart_txd;
                end
                repeat (BIT_PERIOD) @(posedge HCLK); // stop bit
                $display("[%0t][UART_DEC] Received byte: 0x%02X ('%c')",
                         $time, uart_rx_byte, (uart_rx_byte >= 8'h20 && uart_rx_byte <= 8'h7E) ? uart_rx_byte : ".");
            end
        end
    end

    task automatic wait_cycles(input int n);
        repeat (n) @(posedge HCLK);
    endtask

    task automatic check_ledr(input logic [17:0] expected, input string test_name);
        if (gpio_ledr_out === expected) begin
            $display("[PASS] %s | LEDR = 18'h%05X", test_name, gpio_ledr_out);
            pass_count++;
        end else begin
            $display("[FAIL] %s | LEDR = 18'h%05X (expected 18'h%05X)", test_name, gpio_ledr_out, expected);
            fail_count++;
        end
    endtask

    initial begin
        $dumpfile("tb_mini_soc.vcd");
        $dumpvars(1, tb_mini_soc);
        $dumpvars(1, tb_mini_soc.dut);

        pass_count = 0;
        fail_count = 0;

        HRESETn    = 1'b0;
        gpio_sw_in = 18'h00000;
        uart_rxd   = 1'b1;

        $display("============================================================");
        $display("  Mini-SoC Full System Testbench (with AHB Monitor & UART)");
        $display("============================================================");

        // 1. Reset check
        wait_cycles(5);
        if (gpio_ledr_out === 18'h00000 && dbg_pc === 32'h0000_0000 && dbg_timer_irq === 1'b0) begin
            $display("[PASS] Reset state verified (PC=0x%08X, LEDR=0x%05X, IRQ=%b)",
                     dbg_pc, gpio_ledr_out, dbg_timer_irq);
            pass_count++;
        end else begin
            $display("[FAIL] Reset state mismatch (PC=0x%08X, LEDR=0x%05X, IRQ=%b)",
                     dbg_pc, gpio_ledr_out, dbg_timer_irq);
            fail_count++;
        end

        @(negedge HCLK);
        HRESETn = 1'b1;

        // 2. Mode 00: KITT Scanner ($s2 = 16'h0003) XOR SW[11:0]
        gpio_sw_in = {2'b00, 1'b0, 3'b000, 12'h5A5};
        wait_cycles(400);
        check_ledr(18'h005A6, "Mode 00: KITT XOR 12'h5A5");

        // 3. Mode 01: Fibonacci Calculator
        gpio_sw_in = {2'b01, 1'b0, 3'b000, 7'b0, 5'd10};
        wait_cycles(500);
        check_ledr(18'h10037, "Mode 01: Fibonacci(10) = 55");

        gpio_sw_in = {2'b01, 1'b0, 3'b000, 7'b0, 5'd15};
        wait_cycles(600);
        check_ledr(18'h10262, "Mode 01: Fibonacci(15) = 610");

        // 4. Mode 10: Software Multiplier
        gpio_sw_in = {2'b10, 1'b0, 3'b000, 6'd7, 6'd6};
        wait_cycles(500);
        check_ledr(18'h2002A, "Mode 10: Multiplier 7 * 6 = 42");

        gpio_sw_in = {2'b10, 1'b0, 3'b000, 6'd25, 6'd12};
        wait_cycles(600);
        check_ledr(18'h2012C, "Mode 10: Multiplier 25 * 12 = 300");

        // 5. Mode 11: LFSR + Clock-Gating Freeze (SW[15]=1)
        gpio_sw_in = {2'b11, 1'b1, 3'b000, 12'h000};
        wait_cycles(400);
        check_ledr(18'h30003, "Mode 11: LFSR + Freeze (SW[15]=1)");

        // 6. AHB Protocol Checker verification
        if (u_ahb_mon.violation_count == 0) begin
            $display("[PASS] AHB Protocol Checker Zero Violations (%0d AHB transfers)", u_ahb_mon.tx_count);
            pass_count++;
        end else begin
            $display("[FAIL] AHB Protocol Checker found %0d violations!", u_ahb_mon.violation_count);
            fail_count++;
        end

        $display("============================================================");
        $display("  SoC Testbench Summary: %0d PASSED, %0d FAILED", pass_count, fail_count);
        $display("============================================================");

        if (fail_count != 0) $fatal(1, "SOC SIMULATION FAILED!");
        $finish;
    end

endmodule
