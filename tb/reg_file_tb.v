`timescale 1ns / 1ps

module reg_file_tb;

    // Testbench Stimulus Signals
    reg         clk;
    reg         rst;
    reg         reg_write;
    reg  [4:0]  rs1_addr;
    reg  [4:0]  rs2_addr;
    reg  [4:0]  rd_addr;
    reg  [31:0] rd_data;

    wire [31:0] rs1_data;
    wire [31:0] rs2_data;

    integer error_count = 0;

    // Instantiate Device Under Test (DUT)
    reg_file dut (
        .clk       (clk),
        .rst       (rst),
        .reg_write (reg_write),
        .rs1_addr  (rs1_addr),
        .rs2_addr  (rs2_addr),
        .rd_addr   (rd_addr),
        .rd_data   (rd_data),
        .rs1_data  (rs1_data),
        .rs2_data  (rs2_data)
    );

    // 100 MHz Clock Generation (10ns period)
    always #5 clk = ~clk;

    // Self-checking verification task
    task check_ports;
        input [31:0]   exp_rs1;
        input [31:0]   exp_rs2;
        input [8*36:1] test_name;
        begin
            #1; // Combinational settling delay
            if (rs1_data !== exp_rs1 || rs2_data !== exp_rs2) begin
                $display("[FAIL] %0s | rs1: 0x%08h (Exp: 0x%08h) | rs2: 0x%08h (Exp: 0x%08h)",
                         test_name, rs1_data, exp_rs1, rs2_data, exp_rs2);
                error_count = error_count + 1;
            end else begin
                $display("[PASS] %0s | rs1: 0x%08h | rs2: 0x%08h", test_name, rs1_data, rs2_data);
            end
        end
    endtask

    initial begin
        // Signal Initialization
        clk       = 0;
        rst       = 1;
        reg_write = 0;
        rs1_addr  = 5'd0;
        rs2_addr  = 5'd0;
        rd_addr   = 5'd0;
        rd_data   = 32'h0;

        $display("==================================================");
        $display("     STARTING RV32I REGISTER FILE VERIFICATION    ");
        $display("==================================================");

        // --- Test 1: Synchronous Reset Verification ---
        // Hold reset across 2 clock cycles
        #20;
        rst = 0;
        rs1_addr = 5'd5;
        rs2_addr = 5'd12;
        check_ports(32'h0000_0000, 32'h0000_0000, "Reset zeroes all registers");

        // --- Test 2: Synchronous Write & Asynchronous Readback ---
        @(posedge clk);
        reg_write = 1;
        rd_addr   = 5'd1;           // Write to x1 (ra in RISC-V ABI)
        rd_data   = 32'hA5A5_5A5A;
        @(posedge clk);
        reg_write = 0;              // Deassert write enable
        rs1_addr  = 5'd1;           // Read x1 on port 1
        rs2_addr  = 5'd0;           // Read x0 on port 2
        check_ports(32'hA5A5_5A5A, 32'h0000_0000, "Write & Readback x1");

        // --- Test 3: Simultaneous Dual-Port Asynchronous Read ---
        @(posedge clk);
        reg_write = 1;
        rd_addr   = 5'd2;           // Write to x2 (sp in RISC-V ABI)
        rd_data   = 32'h7FFF_FFF0;
        @(posedge clk);
        reg_write = 0;
        rs1_addr  = 5'd1;           // Port 1 reads x1
        rs2_addr  = 5'd2;           // Port 2 reads x2 simultaneously
        check_ports(32'hA5A5_5A5A, 32'h7FFF_FFF0, "Simultaneous Dual Read (x1 & x2)");

        // --- Test 4: Critical RISC-V Invariant: Write-to-x0 Must Be Discarded ---
        @(posedge clk);
        reg_write = 1;
        rd_addr   = 5'd0;           // Attempt writing non-zero to x0
        rd_data   = 32'hFFFF_FFFF;
        @(posedge clk);
        reg_write = 0;
        rs1_addr  = 5'd0;
        rs2_addr  = 5'd0;
        check_ports(32'h0000_0000, 32'h0000_0000, "Write-to-x0 Discard Protection");

        // --- Test 5: Write-Enable Gating Check ---
        @(posedge clk);
        reg_write = 0;              // Write enable LOW
        rd_addr   = 5'd1;           // Target x1
        rd_data   = 32'hDEAD_BEEF;  // Should NOT overwrite existing 0xA5A55A5A
        @(posedge clk);
        rs1_addr  = 5'd1;
        check_ports(32'hA5A5_5A5A, 32'h0000_0000, "Write Enable Low Rejection");

        // --- Test 6: Asynchronous / Combinational Read Latency Check ---
        // Change read address midway through clock cycle without posedge
        #3;
        rs1_addr = 5'd2;
        check_ports(32'h7FFF_FFF0, 32'h0000_0000, "Asynchronous Mid-Cycle Read Latency");

        // --- Verdict ---
        #10;
        $display("==================================================");
        if (error_count == 0)
            $display(">>> ALL REGISTER FILE TESTS PASSED SUCCESSFULLY! <<<");
        else
            $display(">>> TEST SUITE FAILED WITH %0d ERRORS <<<", error_count);
        $display("==================================================");

        $finish;
    end

endmodule