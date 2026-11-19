`timescale 1ns / 1ps

// AMBA 3 AHB-Lite Bus Protocol Checker (iverilog -g2012 compatible)
module ahb_protocol_checker #(
    parameter string NAME = "AHB_MON"
)(
    input logic        HCLK,
    input logic        HRESETn,
    input logic [31:0] HADDR,
    input logic [1:0]  HTRANS,
    input logic [2:0]  HSIZE,
    input logic        HWRITE,
    input logic [31:0] HWDATA,
    input logic [31:0] HRDATA,
    input logic        HREADY,
    input logic        HRESP
);

    logic        prev_hready;
    logic        prev_hresp;
    logic [1:0]  prev_htrans;
    logic [31:0] prev_haddr;
    logic [2:0]  prev_hsize;
    logic        prev_hwrite;
    logic        expect_err_cycle2;

    int unsigned tx_count;
    int unsigned violation_count;

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            prev_hready       <= 1'b1;
            prev_hresp        <= 1'b0;
            prev_htrans       <= 2'b00;
            prev_haddr        <= 32'h0;
            prev_hsize        <= 3'b010;
            prev_hwrite       <= 1'b0;
            expect_err_cycle2 <= 1'b0;
            tx_count          <= 0;
            violation_count   <= 0;
        end else begin
            // 1. Check for X/Z on control signals
            if ($isunknown(HTRANS) || $isunknown(HREADY) || $isunknown(HRESP)) begin
                $display("[%0t][%s][ERROR] Unknown (X/Z) on AHB control signals: HTRANS=%b HREADY=%b HRESP=%b",
                         $time, NAME, HTRANS, HREADY, HRESP);
                violation_count <= violation_count + 1;
            end

            if (HTRANS[1] === 1'b1) begin
                if ($isunknown(HADDR) || $isunknown(HWRITE) || $isunknown(HSIZE)) begin
                    $display("[%0t][%s][ERROR] Unknown (X/Z) on AHB address-phase signals during active transfer",
                             $time, NAME);
                    violation_count <= violation_count + 1;
                end
            end

            // 2. Check address-phase stability during wait states (when not in error cycle 1)
            if (!prev_hready && !prev_hresp && prev_htrans[1]) begin
                if (HADDR !== prev_haddr || HWRITE !== prev_hwrite || HSIZE !== prev_hsize || HTRANS !== prev_htrans) begin
                    $display("[%0t][%s][ERROR] AHB master changed address/control during wait state! prev(ADDR=0x%08X TRANS=%b) curr(ADDR=0x%08X TRANS=%b)",
                             $time, NAME, prev_haddr, prev_htrans, HADDR, HTRANS);
                    violation_count <= violation_count + 1;
                end
            end

            // 3. Check 2-cycle ERROR response protocol
            if (expect_err_cycle2) begin
                if (!(HRESP === 1'b1 && HREADY === 1'b1)) begin
                    $display("[%0t][%s][ERROR] AHB 2-cycle ERROR protocol violated: expected HRESP=1, HREADY=1, got HRESP=%b, HREADY=%b",
                             $time, NAME, HRESP, HREADY);
                    violation_count <= violation_count + 1;
                end
                expect_err_cycle2 <= 1'b0;
            end else if (HRESP === 1'b1 && HREADY === 1'b0) begin
                expect_err_cycle2 <= 1'b1;
            end

            // Count completed address-phase transfers
            if (HREADY === 1'b1 && HTRANS[1] === 1'b1) begin
                tx_count <= tx_count + 1;
            end

            // Latch previous cycle
            prev_hready <= HREADY;
            prev_hresp  <= HRESP;
            prev_htrans <= HTRANS;
            prev_haddr  <= HADDR;
            prev_hsize  <= HSIZE;
            prev_hwrite <= HWRITE;
        end
    end

endmodule
