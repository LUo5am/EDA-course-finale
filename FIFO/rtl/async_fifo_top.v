module async_fifo_top(
    input w_clk, r_clk,      // 异步读写时钟（同频）
    input rst_n,             // 异步复位
    input [15:0] data_in,    // 16位数据输入
    output [15:0] data_out,  // 16位数据输出
    output full, empty,      // 状态标志
    input w_en, r_en         // 读写使能
);
    // 控制信号连接
    wire [5:0] w_addr, r_addr;
    
    // 实例化控制模块（网页13架构参考）
    fifo_ctrl ctrl_inst (
        .w_clk(w_clk),
        .r_clk(r_clk),
        .rst_n(rst_n),
        .w_en(w_en),
        .r_en(r_en),
        .full(full),
        .empty(empty),
        .w_ptr(w_addr),
        .r_ptr(r_addr)
    );

    // 实例化双端口RAM（课程设计要求16K存储）
// 参数传递必须严格匹配
dp_ram #(
    .DEPTH(64),   // 深度=64（符合16K存储需求：64×256=16,384）
    .WIDTH(16)    // 位宽=16位
) ram_inst (
    .w_clk(w_clk),
    .r_clk(r_clk),
    .w_en(w_en),
    .r_en(r_en),
    .w_addr(w_addr),
    .r_addr(r_addr),
    .data_in(data_in),
    .data_out(data_out)
);
endmodule