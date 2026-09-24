`timescale 1ns / 1ps

module reg_file (
    input  wire        clk,        // System clock
    input  wire        rst,        // Synchronous active-high reset
    input  wire        reg_write,  // Write enable control signal
    input  wire [4:0]  rs1_addr,   // Read address 1 (x0 - x31)
    input  wire [4:0]  rs2_addr,   // Read address 2 (x0 - x31)
    input  wire [4:0]  rd_addr,    // Destination write address (x0 - x31)
    input  wire [31:0] rd_data,    // 32-bit data to write
    output wire [31:0] rs1_data,   // Read output 1
    output wire [31:0] rs2_data    // Read output 2
);

    // 32 architectural registers, each 32 bits wide
    reg [31:0] rf [31:0];
    integer i;

    // -------------------------------------------------------------
    // 1. Synchronous Write Port (Clocked on posedge)
    // -------------------------------------------------------------
    // Hardware Rule: Register x0 is read-only zero.
    // Writes targeting address 5'd0 must be discarded.
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1) begin
                rf[i] <= 32'h0000_0000;
            end
        end else if (reg_write && (rd_addr != 5'd0)) begin
            rf[rd_addr] <= rd_data;
        end
    end

    // -------------------------------------------------------------
    // 2. Asynchronous / Combinational Dual Read Ports
    // -------------------------------------------------------------
    // Instructions like ADD read operands in the same cycle they decode.
    // If an address points to 0, permanently output 32'h0.
    assign rs1_data = (rs1_addr == 5'd0) ? 32'h0000_0000 : rf[rs1_addr];
    assign rs2_data = (rs2_addr == 5'd0) ? 32'h0000_0000 : rf[rs2_addr];

endmodule