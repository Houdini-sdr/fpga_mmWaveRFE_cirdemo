# Constraints for the verilog-axis axis_async_fifo instance in pam_controller.
#
# The FIFO gray pointers intentionally cross between the AXI clock and cmd_clk2x.
# Keep this file to static XDC commands: Vivado parses packaged IP constraints in
# a restricted scoped-XDC mode where Tcl procs/loops are rejected.

set_property ASYNC_REG TRUE [get_cells -quiet -hier -regexp {.*cmd_wr_fifo_m_rst_sync_reg.*}]
set_property ASYNC_REG TRUE [get_cells -quiet -hier -regexp {.*cmd_wr_fifo/wr_ptr_gray_sync[12]_reg_reg.*}]
set_property ASYNC_REG TRUE [get_cells -quiet -hier -regexp {.*cmd_wr_fifo/rd_ptr_gray_sync[12]_reg_reg.*}]
set_property ASYNC_REG TRUE [get_cells -quiet -hier -regexp {.*cmd_wr_fifo/[sm]_rst_sync[123]_reg_reg.*}]

# The FIFO internally propagates each reset into the opposite clock domain with
# a one-bit synchronizer. Use the same bounded CDC style as verilog-axis' own
# Vivado timing script, but keep it static for packaged-IP scoped XDC parsing.
set_max_delay -from [get_cells -quiet -hier -regexp {.*cmd_wr_fifo/s_rst_sync1_reg_reg.*}] -to [get_cells -quiet -hier -regexp {.*cmd_wr_fifo/s_rst_sync2_reg_reg.*}] 4.237 -datapath_only
set_max_delay -from [get_cells -quiet -hier -regexp {.*cmd_wr_fifo/m_rst_sync1_reg_reg.*}] -to [get_cells -quiet -hier -regexp {.*cmd_wr_fifo/m_rst_sync2_reg_reg.*}] 10.000 -datapath_only

# The read-domain reset stretcher uses asynchronous assertion and synchronous
# release. Ignore timing to the async preset pins.
set_false_path -to [get_pins -quiet -hier -regexp {.*cmd_wr_fifo_m_rst_sync_reg\[[0-9]+\]/PRE}]

# The distributed-RAM storage has synchronous writes and asynchronous reads;
# the read-side output registers are enabled only after pointer synchronization.
set_false_path -quiet -from [get_pins -quiet -hier -regexp {.*cmd_wr_fifo/mem_reg_.*/RAM[A-H]/CLK}] -to [get_cells -quiet -hier -regexp {.*cmd_wr_fifo/m_axis_pipe_reg_reg\[0\]\[[0-9]+\].*}]

# AXI clock to cmd_clk2x: source period is 10 ns, destination period is 4.237 ns.
set_max_delay -from [get_cells -quiet -hier -regexp {.*cmd_wr_fifo/wr_ptr(_gray)?_reg_reg.*}] -to [get_cells -quiet -hier -regexp {.*cmd_wr_fifo/wr_ptr_gray_sync1_reg_reg.*}] 10.000 -datapath_only
set_bus_skew -from [get_cells -quiet -hier -regexp {.*cmd_wr_fifo/wr_ptr(_gray)?_reg_reg.*}] -to [get_cells -quiet -hier -regexp {.*cmd_wr_fifo/wr_ptr_gray_sync1_reg_reg.*}] 4.237

# cmd_clk2x to AXI clock: source period is 4.237 ns, destination period is 10 ns.
set_max_delay -from [get_cells -quiet -hier -regexp {.*cmd_wr_fifo/rd_ptr(_gray)?_reg_reg.*}] -to [get_cells -quiet -hier -regexp {.*cmd_wr_fifo/rd_ptr_gray_sync1_reg_reg.*}] 4.237 -datapath_only
set_bus_skew -from [get_cells -quiet -hier -regexp {.*cmd_wr_fifo/rd_ptr(_gray)?_reg_reg.*}] -to [get_cells -quiet -hier -regexp {.*cmd_wr_fifo/rd_ptr_gray_sync1_reg_reg.*}] 4.237
