onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic -radix hexadecimal /bmd_tx_engine_tb/uut/clk
add wave -noupdate -format Logic -radix hexadecimal /bmd_tx_engine_tb/uut/rst_n
add wave -noupdate -format Logic -radix hexadecimal /bmd_tx_engine_tb/uut/pop_data
add wave -noupdate -format Logic /bmd_tx_engine_tb/uut/pop_data_d1
add wave -noupdate -format Logic /bmd_tx_engine_tb/uut/pop_data_d2
add wave -noupdate -format Logic /bmd_tx_engine_tb/uut/mask
add wave -noupdate -format Logic /bmd_tx_engine_tb/uut/fofb_node_mask_d0
add wave -noupdate -format Logic -radix unsigned {/bmd_tx_engine_tb/uut/fofb_node_mask_slr[0]}
add wave -noupdate -format Literal -radix hexadecimal /bmd_tx_engine_tb/uut/xy_buf_dat
add wave -noupdate -format Literal -radix hexadecimal /bmd_tx_engine_tb/uut/xy_buf_dat_lt
add wave -noupdate -format Literal -radix hexadecimal /bmd_tx_engine_tb/uut/xy_buf_dat_prev
add wave -noupdate -format Literal -radix hexadecimal /bmd_tx_engine_tb/uut/trn_td
add wave -noupdate -format Logic -radix hexadecimal /bmd_tx_engine_tb/uut/trn_tdst_rdy_n
add wave -noupdate -format Logic /bmd_tx_engine_tb/uut/timeframe_end_i
add wave -noupdate -format Literal -radix hexadecimal /bmd_tx_engine_tb/uut/fofb_node_mask_i
add wave -noupdate -format Literal -radix hexadecimal /bmd_tx_engine_tb/uut/trn_trem_n
add wave -noupdate -format Logic -radix hexadecimal /bmd_tx_engine_tb/uut/trn_tsof_n
add wave -noupdate -format Logic -radix hexadecimal /bmd_tx_engine_tb/uut/trn_teof_n
add wave -noupdate -format Logic -radix hexadecimal /bmd_tx_engine_tb/uut/trn_tsrc_rdy_n
add wave -noupdate -format Logic -radix hexadecimal /bmd_tx_engine_tb/uut/trn_tsrc_dsc_n
add wave -noupdate -format Logic -radix hexadecimal /bmd_tx_engine_tb/uut/trn_tdst_dsc_n
add wave -noupdate -format Literal -radix unsigned /bmd_tx_engine_tb/uut/fofb_node_mask_slr
add wave -noupdate -format Literal -radix hexadecimal /bmd_tx_engine_tb/uut/bmd_64_tx_state
add wave -noupdate -format Literal -radix hexadecimal /bmd_tx_engine_tb/uut/xy_buf_addr_o
add wave -noupdate -format Literal -radix unsigned /bmd_tx_engine_tb/uut/xy_buf_dat_i
add wave -noupdate -format Literal -radix hexadecimal /bmd_tx_engine_tb/uut/xy_buf_addr
add wave -noupdate -format Literal -radix hexadecimal /bmd_tx_engine_tb/uut/xy_buf_addr_next
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
configure wave -namecolwidth 272
configure wave -valuecolwidth 40
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {9994459 ps} {10170262 ps}
