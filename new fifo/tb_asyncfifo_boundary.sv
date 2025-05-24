`timescale 1ns/1ps
module tb_asyncfifo_boundary (
    input  logic tb_wclk,
    input  logic tb_rclk,
    output logic wr_en,
    input  logic wr_full,
    output logic [15:0] wr_data,
    input  logic rd_empty,
    input  logic [5:0] wr_usedw,
    input  logic [5:0] rd_usedw,
    output logic rd_en,
    input  logic overflow,    // ??????[4](@ref)
    input  logic underflow    // ??????[4](@ref)
);

parameter FIFO_DEPTH = 64;
logic [5:0] wr_ptr = 0;       // ??????[1](@ref)
logic [5:0] rd_ptr = 0;       // ??????[1](@ref)
logic [5:0] wr_ptr_gray;      // ??????[7](@ref)
logic [5:0] rd_ptr_gray;      // ??????[7](@ref)
logic [5:0] wr_ptr_sync;      // ???????[4](@ref)
logic [5:0] rd_ptr_sync;      // ???????[4](@ref)

// ???????[5](@ref)
function automatic [5:0] bin2gray(input [5:0] bin);
    return (bin >> 1) ^ bin;
endfunction

// ????????????[4](@ref)
always @(posedge tb_wclk) begin
    {rd_ptr_sync, rd_ptr_gray} <= {rd_ptr_gray, bin2gray(rd_ptr)};
end

// ????????????[4](@ref)
always @(posedge tb_rclk) begin
    {wr_ptr_sync, wr_ptr_gray} <= {wr_ptr_gray, bin2gray(wr_ptr)};
end

// ?????[3](@ref)
covergroup fifo_cov;
    full_cp: coverpoint wr_full {
        bins full = {1};
    }
    empty_cp: coverpoint rd_empty {
        bins empty = {1};
    }
    overflow_cp: coverpoint overflow;
    underflow_cp: coverpoint underflow;
    cross_ops: cross wr_en, rd_en;  // ????????[7](@ref)
endgroup
fifo_cov cov = new();

task automatic test_boundary();
    // ????
    $display("=== Overflow Test ===");
    repeat(FIFO_DEPTH) write_transaction($urandom());
    write_transaction($urandom());
    #1 assert(wr_full && overflow) else $error("Overflow detection failed");
    
    // ????
    $display("=== Underflow Test ===");
    repeat(FIFO_DEPTH) read_transaction();
    read_transaction();
    #1 assert(rd_empty && underflow) else $error("Underflow detection failed");
    
    // ??????
    $display("=== Pointer Wrap Test ===");
    repeat(FIFO_DEPTH*2) begin
        write_transaction($urandom());
        read_transaction();
    end
    assert(wr_usedw == 0 && rd_usedw == 0) 
        else $error("Pointer wrap error");
endtask

task automatic test_random_ops(int cycles=2000);
    fork
        // ?????
        begin : WR_PROC
            for(int i=0; i<cycles; i++) begin
                @(posedge tb_wclk iff !wr_full);
                wr_en = $urandom_range(0,1);
                wr_data = $urandom();
                wr_ptr <= wr_en ? wr_ptr + 1 : wr_ptr;
                cov.sample();  // ?????[3](@ref)
            end
        end
        
        // ?????
        begin : RD_PROC
            for(int i=0; i<cycles; i++) begin
                @(posedge tb_rclk iff !rd_empty);
                rd_en = $urandom_range(0,1);
                rd_ptr <= rd_en ? rd_ptr + 1 : rd_ptr;
                cov.sample();  // ?????[3](@ref)
            end
        end
        
        // ????
        #100_000_000 $error("Test timeout");
    join_any
    disable fork;
endtask

task write_transaction(input [15:0] data);
    @(posedge tb_wclk);
    wr_en = 1;
    wr_data = data;
    @(posedge tb_wclk);
    wr_en = 0;
    wr_ptr <= wr_ptr + 1;  // ?????[1](@ref)
endtask

task read_transaction();
    @(posedge tb_rclk);
    rd_en = 1;
    @(posedge tb_rclk);
    rd_en = 0;
    rd_ptr <= rd_ptr + 1;  // ?????[1](@ref)
endtask

// ???????
final begin
    $display("=== Coverage Summary ===");
    $display("Full Coverage: %.2f%%", cov.full_cp.get_coverage());
    $display("Empty Coverage: %.2f%%", cov.empty_cp.get_coverage());
    $display("Overflow Coverage: %.2f%%", cov.overflow_cp.get_coverage());
    $display("Underflow Coverage: %.2f%%", cov.underflow_cp.get_coverage());
end

endmodule
