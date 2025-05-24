`timescale 1ns/1ps

module tb_asyncfifo_basic();

//----------------- ???? -------------------
parameter CLK_CYCLE = 10;       // 100MHz??
parameter TEST_CYCLES = 2000;   // ??????

//----------------- ???? -------------------
logic        tb_wclk;
logic        tb_rclk;
logic        tb_wrst_n;
logic        tb_rrst_n;
logic        wr_en;
logic        rd_en;
logic [15:0] wr_data;

//----------------- ???? -------------------
wire        wr_full;
wire        wr_empty;
wire [5:0]  wr_usedw;
wire [15:0] rd_data;
wire        rd_full;
wire        rd_empty;
wire [5:0]  rd_usedw;

//----------------- ???? -------------------
initial begin
    tb_wclk = 1;
    forever #(CLK_CYCLE/2) tb_wclk = ~tb_wclk;
end

initial begin
    tb_rclk = 1;
    forever #(CLK_CYCLE/2) tb_rclk = ~tb_rclk;
end

//----------------- ????? -------------------
covergroup cg_fifo @(posedge tb_wclk);
    cp_full: coverpoint {wr_full, rd_full} {
        bins wr_full = {2'b10};
        bins rd_full = {2'b01};
    }
    cp_empty: coverpoint {wr_empty, rd_empty} {
        bins wr_empty = {2'b10};
        bins rd_empty = {2'b01};
    }
    cp_wr_ops: coverpoint wr_en;
    cp_rd_ops: coverpoint rd_en;
    cross_wr_rd: cross cp_wr_ops, cp_rd_ops;
    
    cp_boundary: coverpoint wr_usedw {
        bins empty = {0};
        bins full  = {64};
        bins mid   = {[1:63]};
    }
endgroup

cg_fifo fifo_cov = new();

//----------------- ????? -------------------
initial begin
    initialize();
    
    // ????1???/??
    test_full_empty();
    reset_fifo();
    
    // ????2???????
    test_random_ops();
    reset_fifo();
    
    // ????3?????
    test_boundary();
    
    #100;
    $display("Coverage: %.2f%%", fifo_cov.get_inst_coverage());

 
  
    $finish;
end

//----------------- ???? --------------D:/modelsim/examples/new fifo/tb_asyncfifo_basic.sv-----
task initialize();
    tb_wrst_n = 0;
    tb_rrst_n = 0;
    wr_en  = 0;
    rd_en  = 0;
    wr_data= 0;
    #(CLK_CYCLE*5);
    tb_wrst_n = 1;
    tb_rrst_n = 1;
    #(CLK_CYCLE*2);
endtask

task reset_fifo();
    tb_wrst_n = 0;
    tb_rrst_n = 0;
    #(CLK_CYCLE*2);
    tb_wrst_n = 1;
    tb_rrst_n = 1;
    #(CLK_CYCLE*2);
endtask





//----------------- DUT??? -------------------
async_fifo #(
    .FIFO_WIDTH(16),
    .FIFO_DEPTH(64)
) dut (
    .wr_clk      (tb_wclk),
    .wrst_n      (tb_wrst_n),
    .rd_clk      (tb_rclk),
    .rrst_n      (tb_rrst_n),
    .wr_en       (wr_en),
    .wr_data     (wr_data),
    .wr_full     (wr_full),
    .wr_empty    (wr_empty),
    .wr_usedw    (wr_usedw),
    .rd_en       (rd_en),
    .rd_data     (rd_data),
    .rd_full     (rd_full),
    .rd_empty    (rd_empty),
    .rd_usedw    (rd_usedw)
);

endmodule
