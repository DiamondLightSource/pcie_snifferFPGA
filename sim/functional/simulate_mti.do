onbreak {resume}
if [file exists work] {
  vdel -all
}

vlib work
vmap work
vcom -f dls_cc_list.f
vlog -work work -f endpoint_blk_plus.f
vlog -work work /dls_sw/apps/FPGA/Xilinx10.1i/ISE/verilog/src/glbl.v
vlog -work work -f board_rtl_x04.f

vsim +notimingchecks +TESTNAME=fulltest -L work -L secureip -L unisims_ver -do wave.do work.board glbl
