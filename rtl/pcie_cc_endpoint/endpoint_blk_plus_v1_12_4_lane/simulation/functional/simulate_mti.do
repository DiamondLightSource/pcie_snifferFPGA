
vlib work
vmap work
vlog -work work +incdir+../.+../../source \
      -f ../source_rtl.f \
      $env(XILINX)/verilog/src/glbl.v

vlog -work work +incdir+../.+../../example_design \
      -f board_rtl_x04.f 

vsim +notimingchecks -t 1ps +TESTNAME=sample_smoke_test0 -L work -L secureip -L unisims_ver \
    work.board glbl

run -all
