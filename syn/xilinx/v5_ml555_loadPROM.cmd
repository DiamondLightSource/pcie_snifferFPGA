setMode -bs
setCable -port auto
Identify -inferir
identifyMPM
assignFile -p 3 -file "pcie_cc_top.mcs"
Program -p 3 -e -parallel -master -defaultVersion 0
quit
