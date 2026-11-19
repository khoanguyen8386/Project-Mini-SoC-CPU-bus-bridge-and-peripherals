`timescale 1ns / 1ps

module tb_unit_suite;

    localparam int CLK_PERIOD = 20;

    // Address map
    localparam logic [31:0] SRAM_BASE  = 32'h0000_0000;
    localparam logic [31:0] GPIO_BASE  = 32'h4000_0000;
    localparam logic [31:0] TIMER_BASE = 32'h4000_1000;
    localparam logic [31:0] UART_BASE  = 32'h4000_2000;
    localparam logic [31:0] CLK_BASE   = 32'h4000_3000;
    localparam logic [31:0] UNDEF_ADDR = 32'h8000_0000;

    logic        HCLK;
    logic        HRESETn;

    // AHB-Lite master signals
    logic [31:0] HADDR;
    logic [1:0]  HTRANS;
    logic [2:0]  HSIZE;
    logic        HWRITE;
    logic [31:0] HWDATA;
    logic [31:0] HRDATA;
    logic        HREADY;
    logic        HRESP;

    // Interconnect <-> Slaves
    logic        HSEL_SRAM, HSEL_APB, HSEL_DEF;
    logic [31:0] HRDATA_SRAM, HRDATA_APB;
    logic        HREADYOUT_SRAM, HRESP_SRAM;
    logic        HREADYOUT_APB, HRESP_APB;

    // APB signals
    logic [31:0] PADDR, PWDATA;
    logic        PENABLE, PWRITE;
    logic        PSEL_GPIO, PSEL_TIMER, PSEL_UART, PSEL_CLK;
    logic [31:0] PRDATA_GPIO, PRDATA_TIMER, PRDATA_UART, PRDATA_CLK;
    logic        PREADY_GPIO, PREADY_TIMER, PREADY_UART, PREADY_CLK;

    // Peripheral I/O
    logic [17:0] sw_in;
    logic [17:0] ledr_out;
    logic        timer_irq;
    logic        uart_txd;
    logic        uart_rxd;
    logic        clk_en_gpio, clk_en_timer, clk_en_uart;

    assign uart_rxd = uart_txd; // UART Loopback

    int unsigned pass_count;
    int unsigned fail_count;
    logic [31:0] rdata;
    logic        resp_err;
    logic [31:0] imem_rdata;

    // AHB Protocol Checker
    ahb_protocol_checker #(.NAME("UNIT_AHB_MON")) u_ahb_mon (
        .HCLK    (HCLK),
        .HRESETn (HRESETn),
        .HADDR   (HADDR),
        .HTRANS  (HTRANS),
        .HSIZE   (HSIZE),
        .HWRITE  (HWRITE),
        .HWDATA  (HWDATA),
        .HRDATA  (HRDATA),
        .HREADY  (HREADY),
        .HRESP   (HRESP)
    );

    ahb_lite_interconnect u_interconnect (
        .HCLK           (HCLK),
        .HRESETn        (HRESETn),
        .HADDR          (HADDR),
        .HTRANS         (HTRANS),
        .HSEL_SRAM      (HSEL_SRAM),
        .HSEL_APB       (HSEL_APB),
        .HSEL_DEF       (HSEL_DEF),
        .HRDATA_SRAM    (HRDATA_SRAM),
        .HREADYOUT_SRAM (HREADYOUT_SRAM),
        .HRESP_SRAM     (HRESP_SRAM),
        .HRDATA_APB     (HRDATA_APB),
        .HREADYOUT_APB  (HREADYOUT_APB),
        .HRESP_APB      (HRESP_APB),
        .HRDATA         (HRDATA),
        .HREADY         (HREADY),
        .HRESP          (HRESP)
    );

    onchip_sram #(
        .MEM_INIT_HEX ("../sw/firmware.hex"),
        .MEM_INIT_MIF ("../sw/firmware.mif")
    ) u_sram (
        .HCLK       (HCLK),
        .HRESETn    (HRESETn),
        .imem_addr  (32'h0000_0000),
        .imem_rdata (imem_rdata),
        .HSEL       (HSEL_SRAM),
        .HADDR      (HADDR),
        .HTRANS     (HTRANS),
        .HSIZE      (HSIZE),
        .HWRITE     (HWRITE),
        .HREADY     (HREADY),
        .HWDATA     (HWDATA),
        .HRDATA     (HRDATA_SRAM),
        .HREADYOUT  (HREADYOUT_SRAM),
        .HRESP      (HRESP_SRAM)
    );

    ahb_to_apb_bridge u_bridge (
        .HCLK         (HCLK),
        .HRESETn      (HRESETn),
        .HSEL         (HSEL_APB),
        .HADDR        (HADDR),
        .HTRANS       (HTRANS),
        .HSIZE        (HSIZE),
        .HWRITE       (HWRITE),
        .HREADY       (HREADY),
        .HWDATA       (HWDATA),
        .HRDATA       (HRDATA_APB),
        .HREADYOUT    (HREADYOUT_APB),
        .HRESP        (HRESP_APB),
        .PADDR        (PADDR),
        .PENABLE      (PENABLE),
        .PWRITE       (PWRITE),
        .PWDATA       (PWDATA),
        .PSEL_GPIO    (PSEL_GPIO),
        .PSEL_TIMER   (PSEL_TIMER),
        .PSEL_UART    (PSEL_UART),
        .PSEL_CLK     (PSEL_CLK),
        .PRDATA_GPIO  (PRDATA_GPIO),
        .PREADY_GPIO  (PREADY_GPIO),
        .PRDATA_TIMER (PRDATA_TIMER),
        .PREADY_TIMER (PREADY_TIMER),
        .PRDATA_UART  (PRDATA_UART),
        .PREADY_UART  (PREADY_UART),
        .PRDATA_CLK   (PRDATA_CLK),
        .PREADY_CLK   (PREADY_CLK)
    );

    apb_gpio u_gpio (
        .PCLK        (HCLK),
        .PRESETn     (HRESETn),
        .clk_en_gpio (clk_en_gpio),
        .PSEL        (PSEL_GPIO),
        .PENABLE     (PENABLE),
        .PWRITE      (PWRITE),
        .PADDR       (PADDR),
        .PWDATA      (PWDATA),
        .PRDATA      (PRDATA_GPIO),
        .PREADY      (PREADY_GPIO),
        .sw_in       (sw_in),
        .ledr_out    (ledr_out)
    );

    apb_timer #(.DEFAULT_RELOAD(32'd20)) u_timer (
        .PCLK         (HCLK),
        .PRESETn      (HRESETn),
        .clk_en_timer (clk_en_timer),
        .PSEL         (PSEL_TIMER),
        .PENABLE      (PENABLE),
        .PWRITE       (PWRITE),
        .PADDR        (PADDR),
        .PWDATA       (PWDATA),
        .PRDATA       (PRDATA_TIMER),
        .PREADY       (PREADY_TIMER),
        .timer_irq    (timer_irq)
    );

    apb_uart #(.CLK_FREQ(50_000_000), .BAUD_RATE(115200)) u_uart (
        .PCLK        (HCLK),
        .PRESETn     (HRESETn),
        .clk_en_uart (clk_en_uart),
        .PSEL        (PSEL_UART),
        .PENABLE     (PENABLE),
        .PWRITE      (PWRITE),
        .PADDR       (PADDR),
        .PWDATA      (PWDATA),
        .PRDATA      (PRDATA_UART),
        .PREADY      (PREADY_UART),
        .uart_txd    (uart_txd),
        .uart_rxd    (uart_rxd)
    );

    apb_clk_ctrl u_clk_ctrl (
        .PCLK         (HCLK),
        .PRESETn      (HRESETn),
        .PSEL         (PSEL_CLK),
        .PENABLE      (PENABLE),
        .PWRITE       (PWRITE),
        .PADDR        (PADDR),
        .PWDATA       (PWDATA),
        .PRDATA       (PRDATA_CLK),
        .PREADY       (PREADY_CLK),
        .clk_en_gpio  (clk_en_gpio),
        .clk_en_timer (clk_en_timer),
        .clk_en_uart  (clk_en_uart)
    );

    // Clock generation
    initial begin
        HCLK = 1'b0;
        forever #(CLK_PERIOD / 2) HCLK = ~HCLK;
    end

    // Compliant AHB-Lite single transfer tasks
    task automatic ahb_write(
        input  logic [31:0] addr,
        input  logic [2:0]  size,
        input  logic [31:0] data,
        output logic        err
    );
        begin
            @(posedge HCLK);
            while (!HREADY) @(posedge HCLK);
            HADDR  <= addr;
            HTRANS <= 2'b10; // NONSEQ
            HSIZE  <= size;
            HWRITE <= 1'b1;

            @(posedge HCLK);
            while (!HREADY) @(posedge HCLK);
            HTRANS <= 2'b00; // IDLE
            HWDATA <= data;

            @(posedge HCLK);
            while (!HREADY) @(posedge HCLK);
            err = HRESP;
        end
    endtask

    task automatic ahb_read(
        input  logic [31:0] addr,
        input  logic [2:0]  size,
        output logic [31:0] data,
        output logic        err
    );
        begin
            @(posedge HCLK);
            while (!HREADY) @(posedge HCLK);
            HADDR  <= addr;
            HTRANS <= 2'b10; // NONSEQ
            HSIZE  <= size;
            HWRITE <= 1'b0;

            @(posedge HCLK);
            while (!HREADY) @(posedge HCLK);
            HTRANS <= 2'b00; // IDLE

            @(posedge HCLK);
            while (!HREADY) @(posedge HCLK);
            data = HRDATA;
            err  = HRESP;
        end
    endtask

    task automatic check_eq(
        input logic [31:0] actual,
        input logic [31:0] expected,
        input string       name
    );
        begin
            if (actual === expected) begin
                $display("[PASS] %s | got 0x%08X", name, actual);
                pass_count++;
            end else begin
                $display("[FAIL] %s | got 0x%08X (expected 0x%08X)", name, actual, expected);
                fail_count++;
            end
        end
    endtask

    initial begin
        $dumpfile("tb_unit_suite.vcd");
        $dumpvars(0, tb_unit_suite);

        pass_count = 0;
        fail_count = 0;

        HRESETn = 1'b0;
        HADDR   = 32'h0;
        HTRANS  = 2'b00;
        HSIZE   = 3'b010;
        HWRITE  = 1'b0;
        HWDATA  = 32'h0;
        sw_in   = 18'h2A5A5;

        repeat (5) @(posedge HCLK);
        HRESETn = 1'b1;
        repeat (3) @(posedge HCLK);

        $display("============================================================");
        $display("  Mini-SoC Unit Test Suite (Bus, Bridge, Peripherals)");
        $display("============================================================");

        // 1. SRAM Word, Byte & Halfword
        ahb_write(SRAM_BASE + 32'hF0, 3'b010, 32'hDEAD_BEEF, resp_err);
        ahb_read (SRAM_BASE + 32'hF0, 3'b010, rdata, resp_err);
        check_eq(rdata, 32'hDEAD_BEEF, "SRAM Word Write/Read");

        ahb_write(SRAM_BASE + 32'hF0, 3'b000, 32'h0000_0055, resp_err);
        ahb_write(SRAM_BASE + 32'hF2, 3'b001, 32'hCAFE_0000, resp_err);
        ahb_read (SRAM_BASE + 32'hF0, 3'b010, rdata, resp_err);
        check_eq(rdata, 32'hCAFE_BE55, "SRAM Byte + Halfword Write/Read");

        // 2. Default Slave HRESP Error
        ahb_read(UNDEF_ADDR, 3'b010, rdata, resp_err);
        check_eq({31'b0, resp_err}, 32'd1, "AHB Default Slave HRESP Error");

        // 3. APB GPIO
        repeat (3) @(posedge HCLK);
        ahb_read(GPIO_BASE + 32'h00, 3'b010, rdata, resp_err);
        check_eq(rdata, {14'b0, 18'h2A5A5}, "APB GPIO SW_IN Read");

        ahb_write(GPIO_BASE + 32'h04, 3'b010, 32'h0003_FFFF, resp_err);
        ahb_write(GPIO_BASE + 32'h08, 3'b010, 32'h0000_00FF, resp_err);
        #1;
        check_eq({14'b0, ledr_out}, 32'h0000_00FF, "APB GPIO LEDR & DIR Mask");

        // 4. APB Timer + IRQ + W1C
        ahb_write(TIMER_BASE + 32'h08, 3'b010, 32'd10, resp_err);
        ahb_write(TIMER_BASE + 32'h00, 3'b010, 32'h0000_0007, resp_err);
        repeat (15) @(posedge HCLK);
        #1;
        check_eq({31'b0, timer_irq}, 32'd1, "APB Timer IRQ Asserted");

        ahb_write(TIMER_BASE + 32'h04, 3'b010, 32'h0000_0001, resp_err);
        #1;
        check_eq({31'b0, timer_irq}, 32'd0, "APB Timer IRQ Cleared (W1C)");

        // 5. APB Clock Controller (freeze timer clock)
        ahb_write(TIMER_BASE + 32'h00, 3'b010, 32'h0000_0000, resp_err);
        ahb_write(TIMER_BASE + 32'h04, 3'b010, 32'h0000_0001, resp_err);
        ahb_write(TIMER_BASE + 32'h08, 3'b010, 32'd10, resp_err);
        ahb_write(TIMER_BASE + 32'h00, 3'b010, 32'h0000_0007, resp_err);
        ahb_write(CLK_BASE   + 32'h00, 3'b010, 32'h0000_0005, resp_err);
        repeat (20) @(posedge HCLK);
        #1;
        check_eq({31'b0, timer_irq}, 32'd0, "APB Clock Gating Freezes Timer");
        ahb_write(CLK_BASE   + 32'h00, 3'b010, 32'h0000_0007, resp_err);

        // 6. APB UART TX->RX Loopback
        ahb_write(UART_BASE + 32'h10, 3'b010, 32'd4, resp_err);
        ahb_write(UART_BASE + 32'h00, 3'b010, 32'h0000_00A5, resp_err);
        repeat (60) @(posedge HCLK);
        ahb_read(UART_BASE + 32'h08, 3'b010, rdata, resp_err);
        check_eq({31'b0, rdata[1]}, 32'd1, "APB UART RX_VALID Set");
        ahb_read(UART_BASE + 32'h04, 3'b010, rdata, resp_err);
        check_eq(rdata, 32'h0000_00A5, "APB UART Loopback Data == 0xA5");

        // 7. AHB Protocol Checker verification
        check_eq(u_ahb_mon.violation_count, 0, "AHB Protocol Checker Zero Violations");

        $display("============================================================");
        $display("  Unit Suite Summary: %0d PASSED, %0d FAILED (%0d AHB tx)",
                 pass_count, fail_count, u_ahb_mon.tx_count);
        $display("============================================================");

        if (fail_count != 0) $fatal(1, "UNIT SUITE FAILED!");
        $finish;
    end

endmodule
