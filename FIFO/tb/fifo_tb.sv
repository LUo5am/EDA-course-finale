module fifo_tb;
    // 信号声明
    logic w_clk = 0, r_clk = 0;
    logic rst_n = 0;
    logic [15:0] data_in, data_out;
    logic w_en, r_en, full, empty;
    logic [15:0] data_queue[$];  // 统一在模块顶部声明

    // 时钟生成（100MHz同频异相）
    always #5 w_clk = ~w_clk;
    always #5.1 r_clk = ~r_clk;

    async_fifo_top dut(.*);

    // 复位逻辑（双时钟域同步）
    initial begin
        rst_n = 0;
        repeat(2) @(posedge w_clk); // 写时钟域同步
        repeat(2) @(posedge r_clk); // 读时钟域同步
        rst_n <= 1;
    end

    // 数据写入记录
    initial begin
        forever @(posedge w_clk) begin
            if (w_en && !full) begin  // 添加块结构
                data_queue.push_back(data_in);
            end
        end
    end

    // 数据读取校验（增强安全性）
    initial begin
        forever @(posedge r_clk) begin
            if (r_en && !empty) begin
                if (data_queue.size() == 0) begin
                    $error("Read from empty queue!");
                end else begin
                     automatic logic [15:0] expected = data_queue.pop_front();
                    if (data_out !== expected) begin
                        $error("Data mismatch: exp=%h, act=%h", expected, data_out);
                    end
                end
            end
        end
    end

    // 覆盖率收集（符合课程设计要求）
    covergroup fifo_cg @(posedge w_clk);
        full: coverpoint full { 
            bins full_assert = {1}; 
            bins not_full    = {0};
        }
        empty: coverpoint empty {
            bins empty_assert = {1};
            bins not_empty    = {0};
        }
        cross_full_empty: cross full, empty;
    endgroup

    initial begin
         static fifo_cg cg_inst = new(); 
    end

    // 测试任务（统一缩进格式）
    initial begin
        test_full();
        test_empty();
        test_mixed(2000);
    end

    task test_full();
        // 写入64个数据后关闭写使能
        repeat(64) begin
            @(posedge w_clk);
            w_en <= 1;
            data_in <= $urandom();
        end
        @(posedge w_clk) w_en <= 0; 

        // 验证满标志（换行对齐）
        assert(full) else 
            $error("Full flag not asserted when FIFO should be full");
        @(posedge w_clk);
        w_en <= 1;
        data_in <= $urandom();
        assert(!full) else 
            $error("Full flag not cleared");
    endtask

    task test_empty();
        repeat(64) begin
            @(posedge r_clk);
            r_en <= 1;
        end
        assert(empty) else 
            $error("Empty flag error");
        @(posedge r_clk);
        r_en <= 1;
        assert(empty) else 
            $error("Empty flag not updated");
    endtask

    task test_mixed(input int cycles);
        for (int i=0; i<cycles; i++) begin
            if ($urandom_range(100) < 30) begin
                @(posedge w_clk) w_en <= !full;
            end else begin
                @(posedge r_clk) r_en <= !empty;
            end
            @(posedge w_clk or posedge r_clk); 
        end
    endtask
endmodule