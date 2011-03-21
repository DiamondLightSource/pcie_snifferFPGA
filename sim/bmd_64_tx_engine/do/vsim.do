onerror resume
onbreak resume
onElabError resume

view wave
#add wave -radix Hexadecimal /bmd_64_tx_engine_tb/uut/*
do wave.do

configure wave -signalnamewidth 1

run 20 us

