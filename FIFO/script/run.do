# 手动添加设计文件（右键添加）
vlog ../rtl/gray_conv.v
vlog ../rtl/dp_ram.v
vlog ../rtl/fifo_ctrl.v
vlog ../rtl/async_fifo_top.v
# 添加测试平台
vlog -sv ../tb/fifo_tb.sv

# 启动仿真
vsim work.fifo_tb
add wave *
run 1000ns