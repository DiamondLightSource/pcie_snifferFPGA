setMode -bs
setCable -port auto
Identify -inferir
identifyMPM
assignFile -p 1 -file "pcie_cc_top.bit"
program -p 1
quit
