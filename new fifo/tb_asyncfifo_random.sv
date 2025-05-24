`timescale 1ns/1ps
module tb_asyncfifo_random #(
    parameter FIFO_DEPTH = 64,
    parameter DATA_WIDTH = 16
)(
    input  logic tb_wclk,
    input  logic tb_rclk,
    input  logic tb_wrst_n,
    input  logic tb_rrst_n,
    // FIFO????
    input  logic wr_full,
    input  logic rd_empty,
    input  logic [5:0] wr_usedw,
    input  logic [5:0] rd_usedw,
    input  logic overflow,
    input  logic underflow,
    // ????
    output logic wr_en,
    output logic rd_en,
    // ????
    output logic [DATA_WIDTH-1:0] wr_data,
    input  logic [DATA_WIDTH-1:0] rd_data
);

// ??????????
logic [5:0] wr_ptr = 0, rd_ptr = 0;
logic [5:0] wr_ptr_gray, rd_ptr_gray;
logic [5:0] wr_ptr_sync, rd_ptr_sync;

function automatic [5:0] bin2gray(input [5:0] bin);
    return (bin >> 1) ^ bin;
endfunction

// ??????????
always @(posedge tb_rclk or negedge tb_rrst_n) begin
    if (!tb_rrst_n) {wr_ptr_sync, wr_ptr_gray} <= 0;
    else begin
        wr_ptr_gray <= bin2gray(wr_ptr);
        wr_ptr_sync <= wr_ptr_gray;
    end
end

// ??????????
always @(posedge tb_wclk or negedge tb_wrst_n) begin
    if (!tb_wrst_n) {rd_ptr_sync, rd_ptr_gray} <= 0;
    else begin
        rd_ptr_gray <= bin2gray(rd_ptr);
        rd_ptr_sync <= rd_ptr_gray;
    end
end

// ?????
covergroup fifo_cov;
    full_cp: coverpoint wr_full {
        bins full_asserted = (1 => 1);
    }
    empty_cp: coverpoint rd_empty {
        bins empty_asserted = (1 => 1);
    }
    overflow_cp: coverpoint overflow;
    underflow_cp: coverpoint underflow;
    cross_ops: cross wr_en, rd_en;
endgroup
fifo_cov cov = new();

task automatic test_boundary();
    // ????
    repeat(FIFO_DEPTH) write_transaction($urandom());
    repeat(3) begin  // ??????[6](@ref)
        @(posedge tb_wclk);
        wr_en = 1;
        #1 assert(overflow && wr_usedw == FIFO_DEPTH) 
            else $error("Overflow detection failed");
    end
    wr_en = 0;

    // ????
    repeat(FIFO_DEPTH) read_transaction();
    repeat(3) begin  // ??????[6](@ref)
        @(posedge tb_rclk);
        rd_en = 1;
        #1 assert(underflow && rd_usedw == 0)
            else $error("Underflow detection failed");
    end
    rd_en = 0;

    // ??????[1](@ref)
    repeat(FIFO_DEPTH*2) begin
        write_transaction($urandom());
        read_transaction();
    end
endtask

task automatic test_random_ops(int cycles=2000);
    fork
        // ?????
        begin
            for(int i=0; i<cycles; i++) begin
                @(posedge tb_wclk iff !wr_full);
                wr_en = $urandom_range(0,1);
                wr_data = $urandom();
                if(wr_en) begin
                    wr_ptr <= (wr_ptr + 1) % FIFO_DEPTH;
                    cov.sample();
                end
            end
        end

        // ?????
        begin
            for(int i=0; i<cycles; i++) begin
                @(posedge tb_rclk iff !rd_empty);
                rd_en = $urandom_range(0,1);
                if(rd_en) begin
                    rd_ptr <= (rd_ptr + 1) % FIFO_DEPTH;
                    cov.sample();
                end
            end
        end

        // ???????[1,6](@ref)
        forever begin
            @(posedge tb_rclk);
            if(rd_en && !rd_empty) begin
                #1 assert(rd_data === wr_data - (FIFO_DEPTH - rd_usedw))
                    else $error("Data mismatch at addr %0d", rd_ptr);
            end
        end

        // ????
        #100_000_000 $error("Test timeout");
    join_any
    disable fork;
endtask

final begin
    $display("\n=== ????? ===");
    $display("??????: %.2f%%", cov.full_cp.get_coverage());
    $display("??????: %.2f%%", cov.empty_cp.get_coverage());
    $display("???????: %.2f%%", cov.overflow_cp.get_coverage());
    $display("???????: %.2f%%", cov.underflow_cp.get_coverage());
    $display("?????????: %.2f%%\n", cov.cross_ops.get_coverage());
end
endmodule
