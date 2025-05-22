module dp_ram #(
    parameter DEPTH = 64,    // 显式声明参数
    parameter WIDTH = 16     // 默认值需与课程设计要求一致
)(
    input w_clk, r_clk,
    input w_en, r_en,
    input [$clog2(DEPTH)-1:0] w_addr, // 动态计算地址位宽
    input [$clog2(DEPTH)-1:0] r_addr,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);
    reg [WIDTH-1:0] mem[0:DEPTH-1];  // 参数化存储阵列

    always @(posedge w_clk) begin
        if (w_en) mem[w_addr] <= data_in;
    end

    always @(posedge r_clk) begin
        data_out <= (r_en) ? mem[r_addr] : {WIDTH{1'bz}}; // 高阻态输出
    end
endmodule