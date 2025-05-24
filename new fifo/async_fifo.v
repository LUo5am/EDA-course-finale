//--------------------- async_fifo.v 修正版 ------------------------
module async_fifo #(
    parameter FIFO_WIDTH = 16,   // 16位数据宽度
    parameter FIFO_DEPTH = 64    // 64深度
)(
    // 端口声明
    input                   wr_clk, wrst_n,
    input                   rd_clk, rrst_n,
    input                   wr_en,
    input  [FIFO_WIDTH-1:0] wr_data,
    output                  wr_full, wr_empty,
    output [$clog2(FIFO_DEPTH)-1:0] wr_usedw,
    input                   rd_en,
    output [FIFO_WIDTH-1:0] rd_data,
    output                  rd_full, rd_empty, 
    output [$clog2(FIFO_DEPTH)-1:0] rd_usedw
);

//----------------- 参数与宏定义 ---------------------
localparam RAM_ADDR_W = 10;      // 16K存储需求：2^10=1024地址
localparam FIFO_ADDR_W = $clog2(FIFO_DEPTH);
localparam PTR_WIDTH = FIFO_ADDR_W + 1; 

//----------------- 寄存器声明 -----------------------
reg [PTR_WIDTH-1:0] wr_ptr, rd_ptr;  
reg [PTR_WIDTH-1:0] rd_ptr_g1, rd_ptr_g2; // 补充缺失声明

//----------------- 双端口RAM实例化 ---------------------
wire [FIFO_ADDR_W-1:0] wr_addr = wr_ptr[FIFO_ADDR_W-1:0];
wire [FIFO_ADDR_W-1:0] rd_addr = rd_ptr[FIFO_ADDR_W-1:0];

dual_port_ram #(
    .DATA_WIDTH(FIFO_WIDTH),
    .ADDR_WIDTH(RAM_ADDR_W)
) u_ram (
    .wr_clk(wr_clk),
    .wr_en(wr_en & ~wr_full),
    .wr_addr({{(RAM_ADDR_W-FIFO_ADDR_W){1'b0}}, wr_addr}),
    .wr_data(wr_data),
    
    .rd_clk(rd_clk),
    .rd_en(rd_en & ~rd_empty),
    .rd_addr({{(RAM_ADDR_W-FIFO_ADDR_W){1'b0}}, rd_addr}),
    .rd_data(rd_data)
);

//----------------- 指针控制逻辑修正 -----------------
wire [PTR_WIDTH-1:0] wr_ptr_g = wr_ptr ^ (wr_ptr >> 1);
wire [PTR_WIDTH-1:0] rd_ptr_g = rd_ptr ^ (rd_ptr >> 1);

// 同步器实例化
wire [PTR_WIDTH-1:0] wr2rd_ptr_g, rd2wr_ptr_g;
sync_cell #(PTR_WIDTH) wr2rd_sync(rd_clk, wr_ptr_g, wr2rd_ptr_g);
sync_cell #(PTR_WIDTH) rd2wr_sync(wr_clk, rd_ptr_g, rd2wr_ptr_g);

// 格雷码转二进制函数修正
function [PTR_WIDTH-1:0] gray2bin(input [PTR_WIDTH-1:0] gray);
    integer i;
    begin
        gray2bin[PTR_WIDTH-1] = gray[PTR_WIDTH-1];
        for(i=PTR_WIDTH-2; i>=0; i=i-1)
            gray2bin[i] = gray2bin[i+1] ^ gray[i];
    end
endfunction

wire [PTR_WIDTH-1:0] wr2rd_ptr = gray2bin(wr2rd_ptr_g);
wire [PTR_WIDTH-1:0] rd2wr_ptr = gray2bin(rd2wr_ptr_g);

// 空满判断逻辑
assign wr_full  = (wr_ptr[PTR_WIDTH-1] != rd2wr_ptr[PTR_WIDTH-1]) &&
                 (wr_ptr[PTR_WIDTH-2:0] == rd2wr_ptr[PTR_WIDTH-2:0]);
assign rd_empty = (rd_ptr == wr2rd_ptr);
assign wr_empty = (wr_ptr == rd2wr_ptr);
assign rd_full  = (rd_ptr[PTR_WIDTH-1] != wr2rd_ptr[PTR_WIDTH-1]) &&
                 (rd_ptr[PTR_WIDTH-2:0] == wr2rd_ptr[PTR_WIDTH-2:0]);

// 写指针控制
always @(posedge wr_clk or negedge wrst_n) begin
    if (!wrst_n) begin
        wr_ptr <= 0;
    end else if (wr_en && !wr_full) begin
        wr_ptr <= wr_ptr + 1;
    end
end

// 读指针控制
always @(posedge rd_clk or negedge rrst_n) begin
    if(!rrst_n) begin
        rd_ptr <= 0;
    end else if (rd_en && !rd_empty) begin
        rd_ptr <= rd_ptr + 1;
    end
end

// 数据量指示修正
// 修正后的合法表达式
assign wr_usedw = (wr_ptr >= rd2wr_ptr) ? 
                 (wr_ptr - rd2wr_ptr) : 
                 (2**(PTR_WIDTH) - rd2wr_ptr + wr_ptr);
assign rd_usedw = (wr2rd_ptr >= rd_ptr) ? 
                 (wr2rd_ptr - rd_ptr) : 
                 (2**(PTR_WIDTH) - rd_ptr + wr2rd_ptr);

endmodule

//----------------- 同步器模块 ------------------------
module sync_cell #(
    parameter WIDTH = 4
)(
    input clk,
    input [WIDTH-1:0] din,
    output [WIDTH-1:0] dout
);
    reg [WIDTH-1:0] sync_reg[0:1];
    always @(posedge clk) begin
        sync_reg[0] <= din;
        sync_reg[1] <= sync_reg[0];
    end
    assign dout = sync_reg[1];
endmodule

//----------------- 双端口RAM模块 ----------------------
module dual_port_ram #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 10
)(
    input wr_clk,
    input wr_en,
    input [ADDR_WIDTH-1:0] wr_addr,
    input [DATA_WIDTH-1:0] wr_data,
    
    input rd_clk,
    input rd_en,
    input [ADDR_WIDTH-1:0] rd_addr,
    output reg [DATA_WIDTH-1:0] rd_data
);
    reg [DATA_WIDTH-1:0] mem [(1<<ADDR_WIDTH)-1:0];
    
    always @(posedge wr_clk) begin
        if(wr_en) mem[wr_addr] <= wr_data;
    end
    
    always @(posedge rd_clk) begin
        if(rd_en) rd_data <= mem[rd_addr];
    end
endmodule