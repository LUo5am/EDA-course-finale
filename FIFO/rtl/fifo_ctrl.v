module fifo_ctrl(
    input w_clk, r_clk, rst_n,
    input w_en, r_en,
    output reg full, empty,
    output [5:0] w_ptr, r_ptr
);
    // 二进制指针寄存器
    reg [5:0] w_ptr_bin = 6'd0, r_ptr_bin = 6'd0;
    
    // 格雷码转换模块（网页9关键技术）
    wire [5:0] w_ptr_gray, r_ptr_gray;
    assign w_ptr_gray = w_ptr_bin ^ (w_ptr_bin >> 1);
    assign r_ptr_gray = r_ptr_bin ^ (r_ptr_bin >> 1);

    // 跨时钟域同步链（网页6方案优化）
    reg [5:0] w_ptr_sync[0:1];  // 写指针同步到读时钟域
    reg [5:0] r_ptr_sync[0:1];  // 读指针同步到写时钟域
    
    // 写时钟域逻辑
    always @(posedge w_clk or negedge rst_n) begin
        if (!rst_n) begin
            w_ptr_bin <= 0;
            r_ptr_sync[0] <= 0;
            r_ptr_sync[1] <= 0;
        end else begin
            // 读指针同步（两级触发器）
            r_ptr_sync[0] <= r_ptr_gray;
            r_ptr_sync[1] <= r_ptr_sync[0];
            
            // 写指针递增
            if (w_en && !full) 
                w_ptr_bin <= w_ptr_bin + 1;
        end
    end

    // 读时钟域逻辑（对称结构）
    always @(posedge r_clk or negedge rst_n) begin
        if (!rst_n) begin
            r_ptr_bin <= 0;
            w_ptr_sync[0] <= 0;
            w_ptr_sync[1] <= 0;
        end else begin
            // 写指针同步
            w_ptr_sync[0] <= w_ptr_gray;
            w_ptr_sync[1] <= w_ptr_sync[0];
            
            // 读指针递增
            if (r_en && !empty)
                r_ptr_bin <= r_ptr_bin + 1;
        end
    end

    // 空满判断逻辑（网页9算法改进）
    always @(*) begin
        // 满标志：最高两位不同，其余相同
        full = (w_ptr_bin[5:4] != r_ptr_sync[1][5:4]) && 
               (w_ptr_bin[3:0] == r_ptr_sync[1][3:0]);
        
        // 空标志：格雷码完全相等
        empty = (w_ptr_sync[1] == r_ptr_bin);
    end

    assign w_ptr = w_ptr_bin;
    assign r_ptr = r_ptr_bin;
endmodule