`timescale 1ns/1ps
module tb_asyncfifo_full_empty (
    input  logic tb_wclk,      // ???[6](@ref)
    input  logic tb_rclk,      // ???
    input  logic tb_wrst_n,    // ???
    input  logic tb_rrst_n,    // ???
    // FIFO????
    input  logic wr_full,      // ????[1](@ref)
    input  logic rd_empty,     // ????
    input  logic [5:0] wr_usedw,  // ??????
    input  logic [5:0] rd_usedw,  // ??????
    input  logic overflow,     // ??????[4](@ref)
    input  logic underflow,    // ??????
    // ????
    output logic wr_en,        // ???[7](@ref)
    output logic rd_en,        // ???
    // ????
    output logic [15:0] wr_data // ???
);

parameter FIFO_DEPTH = 64;     // FIFO??[5](@ref)
logic [5:0] wr_ptr = 0;       // ??????
logic [5:0] rd_ptr = 0;       // ??????
logic [5:0] rd_ptr_sync;      // ???????????
logic [5:0] wr_ptr_sync;      // ???????????

// ????????[5,7](@ref)
logic [5:0] wr_ptr_gray;      // ??????
logic [5:0] rd_ptr_gray;      // ??????
logic [5:0] wr_ptr_gray_sync; // ??????????
logic [5:0] rd_ptr_gray_sync; // ??????????

// ???????
function automatic [5:0] bin2gray(input [5:0] bin);
    return (bin >> 1) ^ bin; // ???????[7](@ref)
endfunction

// ????????????
always @(posedge tb_wclk or negedge tb_wrst_n) begin
    if(!tb_wrst_n) begin
        rd_ptr_gray_sync <= 0;
        rd_ptr_sync <= 0;
    end else begin
        // ?????[7](@ref)
        rd_ptr_gray_sync <= rd_ptr_gray;
        rd_ptr_sync <= rd_ptr_gray_sync;
    end
end

// ????????????
always @(posedge tb_rclk or negedge tb_rrst_n) begin
    if(!tb_rrst_n) begin
        wr_ptr_gray_sync <= 0;
        wr_ptr_sync <= 0;
    end else begin
        // ?????[7](@ref)
        wr_ptr_gray_sync <= wr_ptr_gray;
        wr_ptr_sync <= wr_ptr_gray_sync;
    end
end

// ?????[9](@ref)
covergroup fifo_cov @(posedge tb_wclk);
    full_cp: coverpoint wr_full {
        bins full_reached = (1 => 1); // ?????
    }
    empty_cp: coverpoint rd_empty {
        bins empty_reached = (1 => 1); // ?????
    }
    overflow_cp: coverpoint overflow; // ??????
    underflow_cp: coverpoint underflow; // ??????
    cross_flags: cross full_cp, empty_cp; // ??????
endgroup
fifo_cov cov = new();

task test_full_empty();
    // ??????????[1,4](@ref)
    $display("=== Full Flag Test ===");
    while(!wr_full) begin
        @(posedge tb_wclk);
        wr_en = 1;
        wr_data = $urandom();
        #1;
        // ??????
        assert(wr_usedw === (wr_ptr - rd_ptr_sync)) 
            else $error("Usedw calculation error");
        wr_ptr <= wr_ptr + 1;
        wr_ptr_gray <= bin2gray(wr_ptr + 1); // ?????[5](@ref)
    end
    wr_en = 0;
    
    // ????????[4](@ref)
    repeat(2) begin
        @(posedge tb_wclk);
        wr_en = 1; // ??????FIFO
        #1 assert(overflow) else $error("Overflow not detected");
    end
    wr_en = 0;

    // ??????????[1,4](@ref)
    $display("=== Empty Flag Test ===");
    while(!rd_empty) begin
        @(posedge tb_rclk);
        rd_en = 1;
        #1;
        // ??????
        assert(rd_usedw === (wr_ptr_sync - rd_ptr)) 
            else $error("Usedw calculation error");
        rd_ptr <= rd_ptr + 1;
        rd_ptr_gray <= bin2gray(rd_ptr + 1); // ?????[5](@ref)
    end
    rd_en = 0;
    
    // ????????[4](@ref)
    repeat(2) begin
        @(posedge tb_rclk);
        rd_en = 1; // ?????FIFO
        #1 assert(underflow) else $error("Underflow not detected");
    end
    rd_en = 0;

    // ???????[5,7](@ref)
    check_gray_sync:
    assert($countones(wr_ptr_gray ^ wr_ptr_gray_sync) <= 1)
        else $error("Gray code sync error: %b vs %b", 
            wr_ptr_gray, wr_ptr_gray_sync);
endtask

// ???????
final begin
    $display("Coverage Summary:");
    $display("Full State Coverage: %.2f%%", cov.full_cp.get_coverage());
    $display("Empty State Coverage: %.2f%%", cov.empty_cp.get_coverage());
    $display("Overflow Coverage: %.2f%%", cov.overflow_cp.get_coverage());
    $display("Underflow Coverage: %.2f%%", cov.underflow_cp.get_coverage());
end

endmodule