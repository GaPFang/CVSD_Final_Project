#######################################################
#                                                     
#  Innovus Command Logging File                     
#  Created on Thu Dec 12 13:30:20 2024                
#                                                     
#######################################################

#@(#)CDS: Innovus v17.11-s080_1 (64bit) 08/04/2017 11:13 (Linux 2.6.18-194.el5)
#@(#)CDS: NanoRoute 17.11-s080_1 NR170721-2155/17_11-UB (database version 2.30, 390.7.1) {superthreading v1.44}
#@(#)CDS: AAE 17.11-s034 (64bit) 08/04/2017 (Linux 2.6.18-194.el5)
#@(#)CDS: CTE 17.11-s053_1 () Aug  1 2017 23:31:41 ( )
#@(#)CDS: SYNTECH 17.11-s012_1 () Jul 21 2017 02:29:12 ( )
#@(#)CDS: CPE v17.11-s095
#@(#)CDS: IQRC/TQRC 16.1.1-s215 (64bit) Thu Jul  6 20:18:10 PDT 2017 (Linux 2.6.18-194.el5)

set_global _enable_mmmc_by_default_flow      $CTE::mmmc_default
suppressMessage ENCEXT-2799
getDrawView
loadWorkspace -name Physical
win
save_global ed25519.conf
set init_gnd_net VSS
set init_lef_file {library/lef/tsmc13fsg_8lm_cic.lef library/lef/tpz013g3_8lm_cic.lef library/lef/RF2SH64x16.vclef library/lef/antenna_8.lef}
set init_verilog ed25519_syn.v
set init_mmmc_file mmmc.view
set init_io_file ed25519.ioc
set init_top_cell ed25519
set init_pwr_net VDD
init_design
clearGlobalNets
globalNetConnect VDD -type pgpin -pin VDD -inst *
globalNetConnect VDD -type net -net VDD
globalNetConnect VSS -type pgpin -pin VSS -inst *
globalNetConnect VSS -type net -net VSS
saveDesign DBS/init