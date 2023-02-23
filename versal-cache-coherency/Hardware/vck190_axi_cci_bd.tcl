
################################################################
# This is a generated script based on design: vck190_axi_cci
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2022.2
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source vck190_axi_cci_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xcvc1902-vsva2197-2MP-e-S
   set_property BOARD_PART xilinx.com:vck190:part0:2.2 [current_project]
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name vck190_axi_cci

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_gid_msg -ssname BD::TCL -id 2006 -severity "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:axi_cdma:4.1\
xilinx.com:ip:axi_gpio:2.0\
xilinx.com:ip:axi_noc:1.0\
xilinx.com:ip:smartconnect:1.0\
xilinx.com:ip:proc_sys_reset:5.0\
xilinx.com:ip:versal_cips:3.3\
xilinx.com:ip:xlslice:1.0\
"

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set ddr4_dimm1 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 ddr4_dimm1 ]

  set ddr4_dimm1_sma_clk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 ddr4_dimm1_sma_clk ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {200000000} \
   ] $ddr4_dimm1_sma_clk


  # Create ports

  # Create instance: axi_cdma_0, and set properties
  set axi_cdma_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_cdma:4.1 axi_cdma_0 ]
  set_property CONFIG.C_INCLUDE_SG {0} $axi_cdma_0


  # Create instance: axi_cdma_1, and set properties
  set axi_cdma_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_cdma:4.1 axi_cdma_1 ]
  set_property CONFIG.C_INCLUDE_SG {0} $axi_cdma_1


  # Create instance: axi_cdma_2, and set properties
  set axi_cdma_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_cdma:4.1 axi_cdma_2 ]
  set_property CONFIG.C_INCLUDE_SG {0} $axi_cdma_2


  # Create instance: axi_cdma_3, and set properties
  set axi_cdma_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_cdma:4.1 axi_cdma_3 ]
  set_property CONFIG.C_INCLUDE_SG {0} $axi_cdma_3


  # Create instance: axi_gpio_0, and set properties
  set axi_gpio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_0 ]
  set_property -dict [list \
    CONFIG.C_ALL_OUTPUTS {1} \
    CONFIG.C_ALL_OUTPUTS_2 {1} \
    CONFIG.C_GPIO2_WIDTH {7} \
    CONFIG.C_GPIO_WIDTH {7} \
    CONFIG.C_IS_DUAL {1} \
  ] $axi_gpio_0


  # Create instance: axi_gpio_1, and set properties
  set axi_gpio_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_1 ]
  set_property -dict [list \
    CONFIG.C_ALL_OUTPUTS {1} \
    CONFIG.C_ALL_OUTPUTS_2 {1} \
    CONFIG.C_GPIO2_WIDTH {7} \
    CONFIG.C_GPIO_WIDTH {7} \
    CONFIG.C_IS_DUAL {1} \
  ] $axi_gpio_1


  # Create instance: axi_noc_0, and set properties
  set axi_noc_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc:1.0 axi_noc_0 ]
  set_property -dict [list \
    CONFIG.CH0_DDR4_0_BOARD_INTERFACE {ddr4_dimm1} \
    CONFIG.HBM_CHNL0_CONFIG {HBM_PC0_PRE_DEFINED_ADDRESS_MAP ROW_BANK_COLUMN HBM_PC1_PRE_DEFINED_ADDRESS_MAP ROW_BANK_COLUMN HBM_PC0_USER_DEFINED_ADDRESS_MAP NONE HBM_PC1_USER_DEFINED_ADDRESS_MAP NONE\
HBM_WRITE_BACK_CORRECTED_DATA TRUE} \
    CONFIG.MC1_CONFIG_NUM {config17} \
    CONFIG.MC2_CONFIG_NUM {config17} \
    CONFIG.MC3_CONFIG_NUM {config17} \
    CONFIG.MC_BOARD_INTRF_EN {true} \
    CONFIG.MC_CASLATENCY {22} \
    CONFIG.MC_CHAN_REGION1 {DDR_LOW1} \
    CONFIG.MC_DDR4_2T {Disable} \
    CONFIG.MC_F1_TRCD {13750} \
    CONFIG.MC_F1_TRCDMIN {13750} \
    CONFIG.MC_SYSTEM_CLOCK {Differential} \
    CONFIG.MC_TRC {45750} \
    CONFIG.MC_TRCD {13750} \
    CONFIG.MC_TRCDMIN {13750} \
    CONFIG.MC_TRCMIN {45750} \
    CONFIG.MC_TRP {13750} \
    CONFIG.MC_TRPMIN {13750} \
    CONFIG.NUM_CLKS {10} \
    CONFIG.NUM_MC {1} \
    CONFIG.NUM_MCP {4} \
    CONFIG.NUM_MI {2} \
    CONFIG.NUM_SI {8} \
    CONFIG.sys_clk0_BOARD_INTERFACE {ddr4_dimm1_sma_clk} \
  ] $axi_noc_0


  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc_0/M00_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc_0/M01_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc_0/S00_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_1 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc_0/S01_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_2 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc_0/S02_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_3 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc_0/S03_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_rpu} \
 ] [get_bd_intf_pins /axi_noc_0/S04_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_pmc} \
 ] [get_bd_intf_pins /axi_noc_0/S05_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.CONNECTIONS {M00_AXI { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} } \
   CONFIG.DEST_IDS {M00_AXI:0x100} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /axi_noc_0/S06_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.CONNECTIONS {M01_AXI { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} } \
   CONFIG.DEST_IDS {M01_AXI:0x140} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /axi_noc_0/S07_AXI]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S00_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk0]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S01_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk1]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S02_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk2]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S03_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk3]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S04_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk4]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S05_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk5]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S06_AXI:S07_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk6]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {} \
 ] [get_bd_pins /axi_noc_0/aclk7]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {M00_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk8]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {M01_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk9]

  # Create instance: axi_smc, and set properties
  set axi_smc [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 axi_smc ]
  set_property -dict [list \
    CONFIG.NUM_MI {6} \
    CONFIG.NUM_SI {1} \
  ] $axi_smc


  # Create instance: rst_versal_cips_0_333M, and set properties
  set rst_versal_cips_0_333M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_versal_cips_0_333M ]

  # Create instance: smartconnect_0, and set properties
  set smartconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_0 ]
  set_property CONFIG.NUM_SI {1} $smartconnect_0


  # Create instance: smartconnect_1, and set properties
  set smartconnect_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_1 ]
  set_property CONFIG.NUM_SI {1} $smartconnect_1


  # Create instance: smartconnect_2, and set properties
  set smartconnect_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_2 ]
  set_property CONFIG.NUM_SI {1} $smartconnect_2


  # Create instance: smartconnect_3, and set properties
  set smartconnect_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_3 ]
  set_property CONFIG.NUM_SI {1} $smartconnect_3


  # Create instance: versal_cips_0, and set properties
  set versal_cips_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips:3.3 versal_cips_0 ]
  set_property -dict [list \
    CONFIG.DDR_MEMORY_MODE {Custom} \
    CONFIG.DEBUG_MODE {JTAG} \
    CONFIG.DESIGN_MODE {1} \
    CONFIG.PS_BOARD_INTERFACE {ps_pmc_fixed_io} \
    CONFIG.PS_PL_CONNECTIVITY_MODE {Custom} \
    CONFIG.PS_PMC_CONFIG { \
      DDR_MEMORY_MODE {Connectivity to DDR via NOC} \
      DEBUG_MODE {JTAG} \
      DESIGN_MODE {1} \
      PMC_GPIO0_MIO_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 0 .. 25}}} \
      PMC_GPIO1_MIO_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 26 .. 51}}} \
      PMC_I2CPMC_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 46 .. 47}}} \
      PMC_MIO37 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA high} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
      PMC_OSPI_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 0 .. 11}} {MODE Single}} \
      PMC_OT_CHECK {{DELAY 0} {ENABLE 0}} \
      PMC_QSPI_COHERENCY {0} \
      PMC_QSPI_FBCLK {{ENABLE 1} {IO {PMC_MIO 6}}} \
      PMC_QSPI_PERIPHERAL_DATA_MODE {x4} \
      PMC_QSPI_PERIPHERAL_ENABLE {1} \
      PMC_QSPI_PERIPHERAL_MODE {Dual Parallel} \
      PMC_REF_CLK_FREQMHZ {33.3333} \
      PMC_SD1 {{CD_ENABLE 1} {CD_IO {PMC_MIO 28}} {POW_ENABLE 1} {POW_IO {PMC_MIO 51}} {RESET_ENABLE 0} {RESET_IO {PMC_MIO 12}} {WP_ENABLE 0} {WP_IO {PMC_MIO 1}}} \
      PMC_SD1_COHERENCY {0} \
      PMC_SD1_DATA_TRANSFER_MODE {8Bit} \
      PMC_SD1_PERIPHERAL {{CLK_100_SDR_OTAP_DLY 0x3} {CLK_200_SDR_OTAP_DLY 0x2} {CLK_50_DDR_ITAP_DLY 0x36} {CLK_50_DDR_OTAP_DLY 0x3} {CLK_50_SDR_ITAP_DLY 0x2C} {CLK_50_SDR_OTAP_DLY 0x4} {ENABLE 1} {IO\
{PMC_MIO 26 .. 36}}} \
      PMC_SD1_SLOT_TYPE {SD 3.0} \
      PMC_USE_PMC_NOC_AXI0 {1} \
      PS_BOARD_INTERFACE {ps_pmc_fixed_io} \
      PS_CAN1_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 40 .. 41}}} \
      PS_ENET0_MDIO {{ENABLE 1} {IO {PS_MIO 24 .. 25}}} \
      PS_ENET0_PERIPHERAL {{ENABLE 1} {IO {PS_MIO 0 .. 11}}} \
      PS_ENET1_PERIPHERAL {{ENABLE 1} {IO {PS_MIO 12 .. 23}}} \
      PS_GEN_IPI0_ENABLE {1} \
      PS_GEN_IPI0_MASTER {A72} \
      PS_GEN_IPI1_ENABLE {1} \
      PS_GEN_IPI1_MASTER {R5_0} \
      PS_GEN_IPI2_ENABLE {1} \
      PS_GEN_IPI3_ENABLE {1} \
      PS_GEN_IPI4_ENABLE {1} \
      PS_GEN_IPI5_ENABLE {1} \
      PS_GEN_IPI6_ENABLE {1} \
      PS_HSDP_EGRESS_TRAFFIC {JTAG} \
      PS_HSDP_INGRESS_TRAFFIC {JTAG} \
      PS_HSDP_MODE {None} \
      PS_I2C1_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 44 .. 45}}} \
      PS_IRQ_USAGE {{CH0 1} {CH1 1} {CH10 0} {CH11 0} {CH12 0} {CH13 0} {CH14 0} {CH15 0} {CH2 1} {CH3 1} {CH4 0} {CH5 0} {CH6 0} {CH7 0} {CH8 0} {CH9 0}} \
      PS_MIO19 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL disable} {SCHMITT 0} {SLEW slow} {USAGE Reserved}} \
      PS_MIO21 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL disable} {SCHMITT 0} {SLEW slow} {USAGE Reserved}} \
      PS_MIO7 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL disable} {SCHMITT 0} {SLEW slow} {USAGE Reserved}} \
      PS_MIO9 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL disable} {SCHMITT 0} {SLEW slow} {USAGE Reserved}} \
      PS_NUM_FABRIC_RESETS {1} \
      PS_PCIE_RESET {{ENABLE 1}} \
      PS_PL_CONNECTIVITY_MODE {Custom} \
      PS_UART0_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 42 .. 43}}} \
      PS_USB3_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 13 .. 25}}} \
      PS_USE_FPD_CCI_NOC {1} \
      PS_USE_FPD_CCI_NOC0 {1} \
      PS_USE_M_AXI_FPD {1} \
      PS_USE_NOC_FPD_CCI0 {1} \
      PS_USE_NOC_FPD_CCI1 {1} \
      PS_USE_NOC_LPD_AXI0 {1} \
      PS_USE_PMCPL_CLK0 {1} \
      PS_USE_S_AXI_ACE {0} \
      PS_USE_S_AXI_GP2 {1} \
      PS_USE_S_AXI_LPD {1} \
      SMON_ALARMS {Set_Alarms_On} \
      SMON_ENABLE_TEMP_AVERAGING {0} \
      SMON_TEMP_AVERAGING_SAMPLES {0} \
    } \
    CONFIG.PS_PMC_CONFIG_APPLIED {1} \
  ] $versal_cips_0


  # Create instance: xlslice_0, and set properties
  set xlslice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_0 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {3} \
    CONFIG.DIN_TO {0} \
    CONFIG.DIN_WIDTH {7} \
    CONFIG.DOUT_WIDTH {4} \
  ] $xlslice_0


  # Create instance: xlslice_1, and set properties
  set xlslice_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_1 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {6} \
    CONFIG.DIN_TO {4} \
    CONFIG.DIN_WIDTH {7} \
    CONFIG.DOUT_WIDTH {3} \
  ] $xlslice_1


  # Create instance: xlslice_2, and set properties
  set xlslice_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_2 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {3} \
    CONFIG.DIN_WIDTH {7} \
    CONFIG.DOUT_WIDTH {4} \
  ] $xlslice_2


  # Create instance: xlslice_3, and set properties
  set xlslice_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_3 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {6} \
    CONFIG.DIN_TO {4} \
    CONFIG.DIN_WIDTH {7} \
    CONFIG.DOUT_WIDTH {3} \
  ] $xlslice_3


  # Create instance: xlslice_4, and set properties
  set xlslice_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_4 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {3} \
    CONFIG.DIN_TO {0} \
    CONFIG.DIN_WIDTH {7} \
    CONFIG.DOUT_WIDTH {4} \
  ] $xlslice_4


  # Create instance: xlslice_5, and set properties
  set xlslice_5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_5 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {6} \
    CONFIG.DIN_TO {4} \
    CONFIG.DIN_WIDTH {7} \
    CONFIG.DOUT_WIDTH {3} \
  ] $xlslice_5


  # Create instance: xlslice_6, and set properties
  set xlslice_6 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_6 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {3} \
    CONFIG.DIN_WIDTH {7} \
    CONFIG.DOUT_WIDTH {4} \
  ] $xlslice_6


  # Create instance: xlslice_7, and set properties
  set xlslice_7 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_7 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {6} \
    CONFIG.DIN_TO {4} \
    CONFIG.DIN_WIDTH {7} \
    CONFIG.DOUT_WIDTH {3} \
  ] $xlslice_7


  # Create interface connections
  connect_bd_intf_net -intf_net axi_cdma_0_M_AXI [get_bd_intf_pins axi_cdma_0/M_AXI] [get_bd_intf_pins smartconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net axi_cdma_1_M_AXI [get_bd_intf_pins axi_cdma_1/M_AXI] [get_bd_intf_pins smartconnect_1/S00_AXI]
  connect_bd_intf_net -intf_net axi_cdma_2_M_AXI [get_bd_intf_pins axi_cdma_2/M_AXI] [get_bd_intf_pins smartconnect_2/S00_AXI]
  connect_bd_intf_net -intf_net axi_cdma_3_M_AXI [get_bd_intf_pins axi_cdma_3/M_AXI] [get_bd_intf_pins smartconnect_3/S00_AXI]
  connect_bd_intf_net -intf_net axi_noc_0_CH0_DDR4_0 [get_bd_intf_ports ddr4_dimm1] [get_bd_intf_pins axi_noc_0/CH0_DDR4_0]
  connect_bd_intf_net -intf_net axi_noc_0_M00_AXI [get_bd_intf_pins axi_noc_0/M00_AXI] [get_bd_intf_pins versal_cips_0/NOC_FPD_CCI_0]
  connect_bd_intf_net -intf_net axi_noc_0_M01_AXI [get_bd_intf_pins axi_noc_0/M01_AXI] [get_bd_intf_pins versal_cips_0/NOC_FPD_CCI_1]
  connect_bd_intf_net -intf_net axi_smc_M00_AXI [get_bd_intf_pins axi_cdma_0/S_AXI_LITE] [get_bd_intf_pins axi_smc/M00_AXI]
  connect_bd_intf_net -intf_net axi_smc_M01_AXI [get_bd_intf_pins axi_cdma_1/S_AXI_LITE] [get_bd_intf_pins axi_smc/M01_AXI]
  connect_bd_intf_net -intf_net axi_smc_M02_AXI [get_bd_intf_pins axi_gpio_0/S_AXI] [get_bd_intf_pins axi_smc/M02_AXI]
  connect_bd_intf_net -intf_net axi_smc_M03_AXI [get_bd_intf_pins axi_cdma_2/S_AXI_LITE] [get_bd_intf_pins axi_smc/M03_AXI]
  connect_bd_intf_net -intf_net axi_smc_M04_AXI [get_bd_intf_pins axi_cdma_3/S_AXI_LITE] [get_bd_intf_pins axi_smc/M04_AXI]
  connect_bd_intf_net -intf_net axi_smc_M05_AXI [get_bd_intf_pins axi_gpio_1/S_AXI] [get_bd_intf_pins axi_smc/M05_AXI]
  connect_bd_intf_net -intf_net ddr4_dimm1_sma_clk_1 [get_bd_intf_ports ddr4_dimm1_sma_clk] [get_bd_intf_pins axi_noc_0/sys_clk0]
  connect_bd_intf_net -intf_net smartconnect_0_M00_AXI [get_bd_intf_pins smartconnect_0/M00_AXI] [get_bd_intf_pins versal_cips_0/S_AXI_GP2]
  connect_bd_intf_net -intf_net smartconnect_1_M00_AXI [get_bd_intf_pins smartconnect_1/M00_AXI] [get_bd_intf_pins versal_cips_0/S_AXI_LPD]
  connect_bd_intf_net -intf_net smartconnect_2_M00_AXI [get_bd_intf_pins axi_noc_0/S06_AXI] [get_bd_intf_pins smartconnect_2/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_3_M00_AXI [get_bd_intf_pins axi_noc_0/S07_AXI] [get_bd_intf_pins smartconnect_3/M00_AXI]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_0 [get_bd_intf_pins axi_noc_0/S00_AXI] [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_0]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_1 [get_bd_intf_pins axi_noc_0/S01_AXI] [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_1]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_2 [get_bd_intf_pins axi_noc_0/S02_AXI] [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_2]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_3 [get_bd_intf_pins axi_noc_0/S03_AXI] [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_3]
  connect_bd_intf_net -intf_net versal_cips_0_LPD_AXI_NOC_0 [get_bd_intf_pins axi_noc_0/S04_AXI] [get_bd_intf_pins versal_cips_0/LPD_AXI_NOC_0]
  connect_bd_intf_net -intf_net versal_cips_0_M_AXI_FPD [get_bd_intf_pins axi_smc/S00_AXI] [get_bd_intf_pins versal_cips_0/M_AXI_FPD]
  connect_bd_intf_net -intf_net versal_cips_0_PMC_NOC_AXI_0 [get_bd_intf_pins axi_noc_0/S05_AXI] [get_bd_intf_pins versal_cips_0/PMC_NOC_AXI_0]

  # Create port connections
  connect_bd_net -net Net [get_bd_pins smartconnect_0/S00_AXI_arcache] [get_bd_pins smartconnect_0/S00_AXI_awcache] [get_bd_pins xlslice_0/Dout]
  connect_bd_net -net Net1 [get_bd_pins smartconnect_1/S00_AXI_arprot] [get_bd_pins smartconnect_1/S00_AXI_awprot] [get_bd_pins xlslice_3/Dout]
  connect_bd_net -net Net2 [get_bd_pins smartconnect_2/S00_AXI_arprot] [get_bd_pins smartconnect_2/S00_AXI_awprot] [get_bd_pins xlslice_5/Dout]
  connect_bd_net -net axi_cdma_0_cdma_introut [get_bd_pins axi_cdma_0/cdma_introut] [get_bd_pins versal_cips_0/pl_ps_irq0]
  connect_bd_net -net axi_cdma_1_cdma_introut [get_bd_pins axi_cdma_1/cdma_introut] [get_bd_pins versal_cips_0/pl_ps_irq1]
  connect_bd_net -net axi_cdma_2_cdma_introut [get_bd_pins axi_cdma_2/cdma_introut] [get_bd_pins versal_cips_0/pl_ps_irq2]
  connect_bd_net -net axi_cdma_3_cdma_introut [get_bd_pins axi_cdma_3/cdma_introut] [get_bd_pins versal_cips_0/pl_ps_irq3]
  connect_bd_net -net axi_gpio_0_gpio2_io_o [get_bd_pins axi_gpio_0/gpio2_io_o] [get_bd_pins xlslice_2/Din] [get_bd_pins xlslice_3/Din]
  connect_bd_net -net axi_gpio_0_gpio_io_o [get_bd_pins axi_gpio_0/gpio_io_o] [get_bd_pins xlslice_0/Din] [get_bd_pins xlslice_1/Din]
  connect_bd_net -net axi_gpio_1_gpio2_io_o [get_bd_pins axi_gpio_1/gpio2_io_o] [get_bd_pins xlslice_6/Din] [get_bd_pins xlslice_7/Din]
  connect_bd_net -net axi_gpio_1_gpio_io_o [get_bd_pins axi_gpio_1/gpio_io_o] [get_bd_pins xlslice_4/Din] [get_bd_pins xlslice_5/Din]
  connect_bd_net -net rst_versal_cips_0_333M_peripheral_aresetn [get_bd_pins axi_cdma_0/s_axi_lite_aresetn] [get_bd_pins axi_cdma_1/s_axi_lite_aresetn] [get_bd_pins axi_cdma_2/s_axi_lite_aresetn] [get_bd_pins axi_cdma_3/s_axi_lite_aresetn] [get_bd_pins axi_gpio_0/s_axi_aresetn] [get_bd_pins axi_gpio_1/s_axi_aresetn] [get_bd_pins axi_smc/aresetn] [get_bd_pins rst_versal_cips_0_333M/peripheral_aresetn] [get_bd_pins smartconnect_0/aresetn] [get_bd_pins smartconnect_1/aresetn] [get_bd_pins smartconnect_2/aresetn] [get_bd_pins smartconnect_3/aresetn]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi0_clk [get_bd_pins axi_noc_0/aclk0] [get_bd_pins versal_cips_0/fpd_cci_noc_axi0_clk]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi1_clk [get_bd_pins axi_noc_0/aclk1] [get_bd_pins versal_cips_0/fpd_cci_noc_axi1_clk]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi2_clk [get_bd_pins axi_noc_0/aclk2] [get_bd_pins versal_cips_0/fpd_cci_noc_axi2_clk]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi3_clk [get_bd_pins axi_noc_0/aclk3] [get_bd_pins versal_cips_0/fpd_cci_noc_axi3_clk]
  connect_bd_net -net versal_cips_0_lpd_axi_noc_clk [get_bd_pins axi_noc_0/aclk4] [get_bd_pins versal_cips_0/lpd_axi_noc_clk]
  connect_bd_net -net versal_cips_0_noc_fpd_cci_axi0_clk [get_bd_pins axi_noc_0/aclk8] [get_bd_pins versal_cips_0/noc_fpd_cci_axi0_clk]
  connect_bd_net -net versal_cips_0_noc_fpd_cci_axi1_clk [get_bd_pins axi_noc_0/aclk9] [get_bd_pins versal_cips_0/noc_fpd_cci_axi1_clk]
  connect_bd_net -net versal_cips_0_pl0_ref_clk [get_bd_pins axi_cdma_0/m_axi_aclk] [get_bd_pins axi_cdma_0/s_axi_lite_aclk] [get_bd_pins axi_cdma_1/m_axi_aclk] [get_bd_pins axi_cdma_1/s_axi_lite_aclk] [get_bd_pins axi_cdma_2/m_axi_aclk] [get_bd_pins axi_cdma_2/s_axi_lite_aclk] [get_bd_pins axi_cdma_3/m_axi_aclk] [get_bd_pins axi_cdma_3/s_axi_lite_aclk] [get_bd_pins axi_gpio_0/s_axi_aclk] [get_bd_pins axi_gpio_1/s_axi_aclk] [get_bd_pins axi_noc_0/aclk6] [get_bd_pins axi_noc_0/aclk7] [get_bd_pins axi_smc/aclk] [get_bd_pins rst_versal_cips_0_333M/slowest_sync_clk] [get_bd_pins smartconnect_0/aclk] [get_bd_pins smartconnect_1/aclk] [get_bd_pins smartconnect_2/aclk] [get_bd_pins smartconnect_3/aclk] [get_bd_pins versal_cips_0/m_axi_fpd_aclk] [get_bd_pins versal_cips_0/pl0_ref_clk] [get_bd_pins versal_cips_0/s_axi_gp2_aclk] [get_bd_pins versal_cips_0/s_axi_lpd_aclk]
  connect_bd_net -net versal_cips_0_pl0_resetn [get_bd_pins rst_versal_cips_0_333M/ext_reset_in] [get_bd_pins versal_cips_0/pl0_resetn]
  connect_bd_net -net versal_cips_0_pmc_axi_noc_axi0_clk [get_bd_pins axi_noc_0/aclk5] [get_bd_pins versal_cips_0/pmc_axi_noc_axi0_clk]
  connect_bd_net -net xlslice_1_Dout [get_bd_pins smartconnect_0/S00_AXI_arprot] [get_bd_pins smartconnect_0/S00_AXI_awprot] [get_bd_pins xlslice_1/Dout]
  connect_bd_net -net xlslice_2_Dout [get_bd_pins smartconnect_1/S00_AXI_arcache] [get_bd_pins smartconnect_1/S00_AXI_awcache] [get_bd_pins xlslice_2/Dout]
  connect_bd_net -net xlslice_4_Dout [get_bd_pins smartconnect_2/S00_AXI_arcache] [get_bd_pins smartconnect_2/S00_AXI_awcache] [get_bd_pins xlslice_4/Dout]
  connect_bd_net -net xlslice_6_Dout [get_bd_pins smartconnect_3/S00_AXI_arcache] [get_bd_pins smartconnect_3/S00_AXI_awcache] [get_bd_pins xlslice_6/Dout]
  connect_bd_net -net xlslice_7_Dout [get_bd_pins smartconnect_3/S00_AXI_arprot] [get_bd_pins smartconnect_3/S00_AXI_awprot] [get_bd_pins xlslice_7/Dout]

  # Create address segments
  assign_bd_address -offset 0xFFFC0000 -range 0x00040000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_ocm_ram_0] -force
  assign_bd_address -offset 0xF2000000 -range 0x00020000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_pmc_ram] -force
  assign_bd_address -offset 0xFFE90000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_r5_1_atcm_global] -force
  assign_bd_address -offset 0xFFEB0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_r5_1_btcm_global] -force
  assign_bd_address -offset 0xFFE00000 -range 0x00040000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_r5_tcm_ram_global] -force
  assign_bd_address -offset 0xFFFC0000 -range 0x00040000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_ocm_ram_0] -force
  assign_bd_address -offset 0xF2000000 -range 0x00020000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_ram] -force
  assign_bd_address -offset 0xFFE90000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_r5_1_atcm_global] -force
  assign_bd_address -offset 0xFFEB0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_r5_1_btcm_global] -force
  assign_bd_address -offset 0xFFE00000 -range 0x00040000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_r5_tcm_ram_global] -force
  assign_bd_address -offset 0xFFFC0000 -range 0x00040000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_ocm_ram_0] -force
  assign_bd_address -offset 0xF2000000 -range 0x00020000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_pmc_ram] -force
  assign_bd_address -offset 0xFFE90000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_r5_1_atcm_global] -force
  assign_bd_address -offset 0xFFEB0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_r5_1_btcm_global] -force
  assign_bd_address -offset 0xFFE00000 -range 0x00040000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_r5_tcm_ram_global] -force
  assign_bd_address -offset 0xFFFC0000 -range 0x00040000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_ocm_ram_0] -force
  assign_bd_address -offset 0xF2000000 -range 0x00020000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_pmc_ram] -force
  assign_bd_address -offset 0xFFE90000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_r5_1_atcm_global] -force
  assign_bd_address -offset 0xFFEB0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_r5_1_btcm_global] -force
  assign_bd_address -offset 0xFFE00000 -range 0x00040000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_r5_tcm_ram_global] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_0] [get_bd_addr_segs axi_noc_0/S00_AXI/C0_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_0] [get_bd_addr_segs axi_noc_0/S00_AXI/C0_DDR_LOW1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_1] [get_bd_addr_segs axi_noc_0/S01_AXI/C1_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_1] [get_bd_addr_segs axi_noc_0/S01_AXI/C1_DDR_LOW1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_2] [get_bd_addr_segs axi_noc_0/S02_AXI/C2_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_2] [get_bd_addr_segs axi_noc_0/S02_AXI/C2_DDR_LOW1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_3] [get_bd_addr_segs axi_noc_0/S03_AXI/C3_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_3] [get_bd_addr_segs axi_noc_0/S03_AXI/C3_DDR_LOW1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs axi_noc_0/S04_AXI/C0_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs axi_noc_0/S04_AXI/C0_DDR_LOW1] -force
  assign_bd_address -offset 0xA4000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/M_AXI_FPD] [get_bd_addr_segs axi_cdma_0/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0xA4010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/M_AXI_FPD] [get_bd_addr_segs axi_cdma_1/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0xA4030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/M_AXI_FPD] [get_bd_addr_segs axi_cdma_2/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0xA4040000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/M_AXI_FPD] [get_bd_addr_segs axi_cdma_3/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0xA4020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/M_AXI_FPD] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xA4050000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/M_AXI_FPD] [get_bd_addr_segs axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs axi_noc_0/S05_AXI/C0_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs axi_noc_0/S05_AXI/C0_DDR_LOW1] -force

  # Exclude Address Segments
  exclude_bd_addr_seg -offset 0xFFA80000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_adma_0]
  exclude_bd_addr_seg -offset 0xFFA90000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_adma_1]
  exclude_bd_addr_seg -offset 0xFFAA0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_adma_2]
  exclude_bd_addr_seg -offset 0xFFAB0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_adma_3]
  exclude_bd_addr_seg -offset 0xFFAC0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_adma_4]
  exclude_bd_addr_seg -offset 0xFFAD0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_adma_5]
  exclude_bd_addr_seg -offset 0xFFAE0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_adma_6]
  exclude_bd_addr_seg -offset 0xFFAF0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_adma_7]
  exclude_bd_addr_seg -offset 0xFD5C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_apu_0]
  exclude_bd_addr_seg -offset 0xFF070000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_canfd_1]
  exclude_bd_addr_seg -offset 0xF0800000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_coresight_0]
  exclude_bd_addr_seg -offset 0xF0D10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_coresight_a720_cti]
  exclude_bd_addr_seg -offset 0xF0D00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_coresight_a720_dbg]
  exclude_bd_addr_seg -offset 0xF0D30000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_coresight_a720_etm]
  exclude_bd_addr_seg -offset 0xF0D20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_coresight_a720_pmu]
  exclude_bd_addr_seg -offset 0xF0D50000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_coresight_a721_cti]
  exclude_bd_addr_seg -offset 0xF0D40000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_coresight_a721_dbg]
  exclude_bd_addr_seg -offset 0xF0D70000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_coresight_a721_etm]
  exclude_bd_addr_seg -offset 0xF0D60000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_coresight_a721_pmu]
  exclude_bd_addr_seg -offset 0xF0CA0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_coresight_apu_cti]
  exclude_bd_addr_seg -offset 0xF0C60000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_coresight_apu_ela]
  exclude_bd_addr_seg -offset 0xF0C30000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_coresight_apu_etf]
  exclude_bd_addr_seg -offset 0xF0C20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_coresight_apu_fun]
  exclude_bd_addr_seg -offset 0xF0F80000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_coresight_cpm_atm]
  exclude_bd_addr_seg -offset 0xF0FA0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_coresight_cpm_cti2a]
  exclude_bd_addr_seg -offset 0xF0FD0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_coresight_cpm_cti2d]
  exclude_bd_addr_seg -offset 0xF0F40000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_coresight_cpm_ela2a]
  exclude_bd_addr_seg -offset 0xF0F50000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_coresight_cpm_ela2b]
  exclude_bd_addr_seg -offset 0xF0F60000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_coresight_cpm_ela2c]
  exclude_bd_addr_seg -offset 0xF0F70000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_coresight_cpm_ela2d]
  exclude_bd_addr_seg -offset 0xF0F20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_coresight_cpm_fun]
  exclude_bd_addr_seg -offset 0xF0F00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_coresight_cpm_rom]
  exclude_bd_addr_seg -offset 0xF0B80000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_coresight_fpd_atm]
  exclude_bd_addr_seg -offset 0xF0B70000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_coresight_fpd_stm]
  exclude_bd_addr_seg -offset 0xF0980000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_coresight_lpd_atm]
  exclude_bd_addr_seg -offset 0xFD1A0000 -range 0x00020000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_crf_0]
  exclude_bd_addr_seg -offset 0xFF5E0000 -range 0x00020000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_crl_0]
  exclude_bd_addr_seg -offset 0xF1260000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_crp_0]
  exclude_bd_addr_seg -offset 0xFF0C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_ethernet_0]
  exclude_bd_addr_seg -offset 0xFF0D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_ethernet_1]
  exclude_bd_addr_seg -offset 0xFD360000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_fpd_afi_0]
  exclude_bd_addr_seg -offset 0xFD380000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_fpd_afi_2]
  exclude_bd_addr_seg -offset 0xFD5E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_fpd_cci_0]
  exclude_bd_addr_seg -offset 0xFD700000 -range 0x00100000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_fpd_gpv_0]
  exclude_bd_addr_seg -offset 0xFD000000 -range 0x00100000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_fpd_maincci_0]
  exclude_bd_addr_seg -offset 0xFD390000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_fpd_slave_xmpu_0]
  exclude_bd_addr_seg -offset 0xFD610000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_fpd_slcr_0]
  exclude_bd_addr_seg -offset 0xFD690000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_fpd_slcr_secure_0]
  exclude_bd_addr_seg -offset 0xFD5F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_fpd_smmu_0]
  exclude_bd_addr_seg -offset 0xFD800000 -range 0x00800000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_fpd_smmutcu_0]
  exclude_bd_addr_seg -offset 0xFF030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_i2c_1]
  exclude_bd_addr_seg -offset 0xFF330000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_ipi_0]
  exclude_bd_addr_seg -offset 0xFF340000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_ipi_1]
  exclude_bd_addr_seg -offset 0xFF350000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_ipi_2]
  exclude_bd_addr_seg -offset 0xFF360000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_ipi_3]
  exclude_bd_addr_seg -offset 0xFF370000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_ipi_4]
  exclude_bd_addr_seg -offset 0xFF380000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_ipi_5]
  exclude_bd_addr_seg -offset 0xFF3A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_ipi_6]
  exclude_bd_addr_seg -offset 0xFF3F0000 -range 0x00001000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_ipi_buffer]
  exclude_bd_addr_seg -offset 0xFF320000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_ipi_pmc]
  exclude_bd_addr_seg -offset 0xFF390000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_ipi_pmc_nobuf]
  exclude_bd_addr_seg -offset 0xFF310000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_ipi_psm]
  exclude_bd_addr_seg -offset 0xFF9B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_lpd_afi_0]
  exclude_bd_addr_seg -offset 0xFF0A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_lpd_iou_secure_slcr_0]
  exclude_bd_addr_seg -offset 0xFF080000 -range 0x00020000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_lpd_iou_slcr_0]
  exclude_bd_addr_seg -offset 0xFF410000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_lpd_slcr_0]
  exclude_bd_addr_seg -offset 0xFF510000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_lpd_slcr_secure_0]
  exclude_bd_addr_seg -offset 0xFF990000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_lpd_xppu_0]
  exclude_bd_addr_seg -offset 0xFF960000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_ocm_ctrl]
  exclude_bd_addr_seg -offset 0xFF980000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_ocm_xmpu_0]
  exclude_bd_addr_seg -offset 0xF11E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_pmc_aes]
  exclude_bd_addr_seg -offset 0xF11F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_pmc_bbram_ctrl]
  exclude_bd_addr_seg -offset 0xF12D0000 -range 0x00001000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_pmc_cfi_cframe_0]
  exclude_bd_addr_seg -offset 0xF12B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_pmc_cfu_apb_0]
  exclude_bd_addr_seg -offset 0xF11C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_pmc_dma_0]
  exclude_bd_addr_seg -offset 0xF11D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_pmc_dma_1]
  exclude_bd_addr_seg -offset 0xF1250000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_pmc_efuse_cache]
  exclude_bd_addr_seg -offset 0xF1240000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_pmc_efuse_ctrl]
  exclude_bd_addr_seg -offset 0xF1110000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_pmc_global_0]
  exclude_bd_addr_seg -offset 0xF1020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_pmc_gpio_0]
  exclude_bd_addr_seg -offset 0xF1000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_pmc_i2c_0]
  exclude_bd_addr_seg -offset 0xF0310000 -range 0x00008000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_pmc_ppu1_mdm_0]
  exclude_bd_addr_seg -offset 0xF1030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_pmc_qspi_0]
  exclude_bd_addr_seg -offset 0xC0000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_pmc_qspi_ospi_flash_0]
  exclude_bd_addr_seg -offset 0xF6000000 -range 0x02000000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_pmc_ram_npi]
  exclude_bd_addr_seg -offset 0xF1200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_pmc_rsa]
  exclude_bd_addr_seg -offset 0xF12A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_pmc_rtc_0]
  exclude_bd_addr_seg -offset 0xF1050000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_pmc_sd_1]
  exclude_bd_addr_seg -offset 0xF1210000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_pmc_sha]
  exclude_bd_addr_seg -offset 0xF1220000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_pmc_slave_boot]
  exclude_bd_addr_seg -offset 0xF2100000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_pmc_slave_boot_stream]
  exclude_bd_addr_seg -offset 0xF1270000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_pmc_sysmon_0]
  exclude_bd_addr_seg -offset 0xF1230000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_pmc_trng]
  exclude_bd_addr_seg -offset 0xF12F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_pmc_xmpu_0]
  exclude_bd_addr_seg -offset 0xF1310000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_pmc_xppu_0]
  exclude_bd_addr_seg -offset 0xF1300000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_pmc_xppu_npi_0]
  exclude_bd_addr_seg -offset 0xFFC90000 -range 0x0000F000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_psm_global_reg]
  exclude_bd_addr_seg -offset 0xFF9A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_rpu_0]
  exclude_bd_addr_seg -offset 0xFF000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_sbsauart_0]
  exclude_bd_addr_seg -offset 0xFF130000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_scntr_0]
  exclude_bd_addr_seg -offset 0xFF140000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_scntrs_0]
  exclude_bd_addr_seg -offset 0xFF9D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_usb_0]
  exclude_bd_addr_seg -offset 0xFE200000 -range 0x00100000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs versal_cips_0/S_AXI_GP2/pspmc_0_psv_usb_xhci_0]
  exclude_bd_addr_seg -offset 0xFFA80000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_adma_0]
  exclude_bd_addr_seg -offset 0xFFA90000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_adma_1]
  exclude_bd_addr_seg -offset 0xFFAA0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_adma_2]
  exclude_bd_addr_seg -offset 0xFFAB0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_adma_3]
  exclude_bd_addr_seg -offset 0xFFAC0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_adma_4]
  exclude_bd_addr_seg -offset 0xFFAD0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_adma_5]
  exclude_bd_addr_seg -offset 0xFFAE0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_adma_6]
  exclude_bd_addr_seg -offset 0xFFAF0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_adma_7]
  exclude_bd_addr_seg -offset 0xFD5C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_apu_0]
  exclude_bd_addr_seg -offset 0xFF070000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_canfd_1]
  exclude_bd_addr_seg -offset 0xF0800000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_0]
  exclude_bd_addr_seg -offset 0xF0D10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_a720_cti]
  exclude_bd_addr_seg -offset 0xF0D00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_a720_dbg]
  exclude_bd_addr_seg -offset 0xF0D30000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_a720_etm]
  exclude_bd_addr_seg -offset 0xF0D20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_a720_pmu]
  exclude_bd_addr_seg -offset 0xF0D50000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_a721_cti]
  exclude_bd_addr_seg -offset 0xF0D40000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_a721_dbg]
  exclude_bd_addr_seg -offset 0xF0D70000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_a721_etm]
  exclude_bd_addr_seg -offset 0xF0D60000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_a721_pmu]
  exclude_bd_addr_seg -offset 0xF0CA0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_apu_cti]
  exclude_bd_addr_seg -offset 0xF0C60000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_apu_ela]
  exclude_bd_addr_seg -offset 0xF0C30000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_apu_etf]
  exclude_bd_addr_seg -offset 0xF0C20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_apu_fun]
  exclude_bd_addr_seg -offset 0xF0F80000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_cpm_atm]
  exclude_bd_addr_seg -offset 0xF0FA0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_cpm_cti2a]
  exclude_bd_addr_seg -offset 0xF0FD0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_cpm_cti2d]
  exclude_bd_addr_seg -offset 0xF0F40000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_cpm_ela2a]
  exclude_bd_addr_seg -offset 0xF0F50000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_cpm_ela2b]
  exclude_bd_addr_seg -offset 0xF0F60000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_cpm_ela2c]
  exclude_bd_addr_seg -offset 0xF0F70000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_cpm_ela2d]
  exclude_bd_addr_seg -offset 0xF0F20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_cpm_fun]
  exclude_bd_addr_seg -offset 0xF0F00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_cpm_rom]
  exclude_bd_addr_seg -offset 0xF0B80000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_fpd_atm]
  exclude_bd_addr_seg -offset 0xF0B70000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_fpd_stm]
  exclude_bd_addr_seg -offset 0xF0980000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_lpd_atm]
  exclude_bd_addr_seg -offset 0xFC000000 -range 0x01000000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_cpm]
  exclude_bd_addr_seg -offset 0xFD1A0000 -range 0x00020000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_crf_0]
  exclude_bd_addr_seg -offset 0xFF5E0000 -range 0x00020000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_crl_0]
  exclude_bd_addr_seg -offset 0xF1260000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_crp_0]
  exclude_bd_addr_seg -offset 0xFF0C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_ethernet_0]
  exclude_bd_addr_seg -offset 0xFF0D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_ethernet_1]
  exclude_bd_addr_seg -offset 0xFD360000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_fpd_afi_0]
  exclude_bd_addr_seg -offset 0xFD380000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_fpd_afi_2]
  exclude_bd_addr_seg -offset 0xFD5E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_fpd_cci_0]
  exclude_bd_addr_seg -offset 0xFD700000 -range 0x00100000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_fpd_gpv_0]
  exclude_bd_addr_seg -offset 0xFD000000 -range 0x00100000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_fpd_maincci_0]
  exclude_bd_addr_seg -offset 0xFD390000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_fpd_slave_xmpu_0]
  exclude_bd_addr_seg -offset 0xFD610000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_fpd_slcr_0]
  exclude_bd_addr_seg -offset 0xFD690000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_fpd_slcr_secure_0]
  exclude_bd_addr_seg -offset 0xFD5F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_fpd_smmu_0]
  exclude_bd_addr_seg -offset 0xFD800000 -range 0x00800000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_fpd_smmutcu_0]
  exclude_bd_addr_seg -offset 0xFF030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_i2c_1]
  exclude_bd_addr_seg -offset 0xFF330000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_ipi_0]
  exclude_bd_addr_seg -offset 0xFF340000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_ipi_1]
  exclude_bd_addr_seg -offset 0xFF350000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_ipi_2]
  exclude_bd_addr_seg -offset 0xFF360000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_ipi_3]
  exclude_bd_addr_seg -offset 0xFF370000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_ipi_4]
  exclude_bd_addr_seg -offset 0xFF380000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_ipi_5]
  exclude_bd_addr_seg -offset 0xFF3A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_ipi_6]
  exclude_bd_addr_seg -offset 0xFF3F0000 -range 0x00001000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_ipi_buffer]
  exclude_bd_addr_seg -offset 0xFF320000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_ipi_pmc]
  exclude_bd_addr_seg -offset 0xFF390000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_ipi_pmc_nobuf]
  exclude_bd_addr_seg -offset 0xFF310000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_ipi_psm]
  exclude_bd_addr_seg -offset 0xFF9B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_lpd_afi_0]
  exclude_bd_addr_seg -offset 0xFF0A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_lpd_iou_secure_slcr_0]
  exclude_bd_addr_seg -offset 0xFF080000 -range 0x00020000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_lpd_iou_slcr_0]
  exclude_bd_addr_seg -offset 0xFF410000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_lpd_slcr_0]
  exclude_bd_addr_seg -offset 0xFF510000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_lpd_slcr_secure_0]
  exclude_bd_addr_seg -offset 0xFF990000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_lpd_xppu_0]
  exclude_bd_addr_seg -offset 0xFF960000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_ocm_ctrl]
  exclude_bd_addr_seg -offset 0xFF980000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_ocm_xmpu_0]
  exclude_bd_addr_seg -offset 0xF11E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_aes]
  exclude_bd_addr_seg -offset 0xF11F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_bbram_ctrl]
  exclude_bd_addr_seg -offset 0xF12D0000 -range 0x00001000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_cfi_cframe_0]
  exclude_bd_addr_seg -offset 0xF12B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_cfu_apb_0]
  exclude_bd_addr_seg -offset 0xF11C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_dma_0]
  exclude_bd_addr_seg -offset 0xF11D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_dma_1]
  exclude_bd_addr_seg -offset 0xF1250000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_efuse_cache]
  exclude_bd_addr_seg -offset 0xF1240000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_efuse_ctrl]
  exclude_bd_addr_seg -offset 0xF1110000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_global_0]
  exclude_bd_addr_seg -offset 0xF1020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_gpio_0]
  exclude_bd_addr_seg -offset 0xF1000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_i2c_0]
  exclude_bd_addr_seg -offset 0xF0310000 -range 0x00008000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_ppu1_mdm_0]
  exclude_bd_addr_seg -offset 0xF1030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_qspi_0]
  exclude_bd_addr_seg -offset 0xC0000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_qspi_ospi_flash_0]
  exclude_bd_addr_seg -offset 0xF6000000 -range 0x02000000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_ram_npi]
  exclude_bd_addr_seg -offset 0xF1200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_rsa]
  exclude_bd_addr_seg -offset 0xF12A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_rtc_0]
  exclude_bd_addr_seg -offset 0xF1050000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_sd_1]
  exclude_bd_addr_seg -offset 0xF1210000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_sha]
  exclude_bd_addr_seg -offset 0xF1220000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_slave_boot]
  exclude_bd_addr_seg -offset 0xF2100000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_slave_boot_stream]
  exclude_bd_addr_seg -offset 0xF1270000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_sysmon_0]
  exclude_bd_addr_seg -offset 0xF1230000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_trng]
  exclude_bd_addr_seg -offset 0xF12F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_xmpu_0]
  exclude_bd_addr_seg -offset 0xF1310000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_xppu_0]
  exclude_bd_addr_seg -offset 0xF1300000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_xppu_npi_0]
  exclude_bd_addr_seg -offset 0xFFC90000 -range 0x0000F000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_psm_global_reg]
  exclude_bd_addr_seg -offset 0xFF9A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_rpu_0]
  exclude_bd_addr_seg -offset 0xFF000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_sbsauart_0]
  exclude_bd_addr_seg -offset 0xFF130000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_scntr_0]
  exclude_bd_addr_seg -offset 0xFF140000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_scntrs_0]
  exclude_bd_addr_seg -offset 0xFF9D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_usb_0]
  exclude_bd_addr_seg -offset 0xFE200000 -range 0x00100000 -target_address_space [get_bd_addr_spaces axi_cdma_1/Data] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_usb_xhci_0]
  exclude_bd_addr_seg -offset 0xFFA80000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_adma_0]
  exclude_bd_addr_seg -offset 0xFFA90000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_adma_1]
  exclude_bd_addr_seg -offset 0xFFAA0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_adma_2]
  exclude_bd_addr_seg -offset 0xFFAB0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_adma_3]
  exclude_bd_addr_seg -offset 0xFFAC0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_adma_4]
  exclude_bd_addr_seg -offset 0xFFAD0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_adma_5]
  exclude_bd_addr_seg -offset 0xFFAE0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_adma_6]
  exclude_bd_addr_seg -offset 0xFFAF0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_adma_7]
  exclude_bd_addr_seg -offset 0xFD5C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_apu_0]
  exclude_bd_addr_seg -offset 0xFF070000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_canfd_1]
  exclude_bd_addr_seg -offset 0xF0800000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_coresight_0]
  exclude_bd_addr_seg -offset 0xF0D10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_coresight_a720_cti]
  exclude_bd_addr_seg -offset 0xF0D00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_coresight_a720_dbg]
  exclude_bd_addr_seg -offset 0xF0D30000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_coresight_a720_etm]
  exclude_bd_addr_seg -offset 0xF0D20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_coresight_a720_pmu]
  exclude_bd_addr_seg -offset 0xF0D50000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_coresight_a721_cti]
  exclude_bd_addr_seg -offset 0xF0D40000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_coresight_a721_dbg]
  exclude_bd_addr_seg -offset 0xF0D70000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_coresight_a721_etm]
  exclude_bd_addr_seg -offset 0xF0D60000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_coresight_a721_pmu]
  exclude_bd_addr_seg -offset 0xF0CA0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_coresight_apu_cti]
  exclude_bd_addr_seg -offset 0xF0C60000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_coresight_apu_ela]
  exclude_bd_addr_seg -offset 0xF0C30000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_coresight_apu_etf]
  exclude_bd_addr_seg -offset 0xF0C20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_coresight_apu_fun]
  exclude_bd_addr_seg -offset 0xF0F80000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_coresight_cpm_atm]
  exclude_bd_addr_seg -offset 0xF0FA0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_coresight_cpm_cti2a]
  exclude_bd_addr_seg -offset 0xF0FD0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_coresight_cpm_cti2d]
  exclude_bd_addr_seg -offset 0xF0F40000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_coresight_cpm_ela2a]
  exclude_bd_addr_seg -offset 0xF0F50000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_coresight_cpm_ela2b]
  exclude_bd_addr_seg -offset 0xF0F60000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_coresight_cpm_ela2c]
  exclude_bd_addr_seg -offset 0xF0F70000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_coresight_cpm_ela2d]
  exclude_bd_addr_seg -offset 0xF0F20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_coresight_cpm_fun]
  exclude_bd_addr_seg -offset 0xF0F00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_coresight_cpm_rom]
  exclude_bd_addr_seg -offset 0xF0B80000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_coresight_fpd_atm]
  exclude_bd_addr_seg -offset 0xF0B70000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_coresight_fpd_stm]
  exclude_bd_addr_seg -offset 0xF0980000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_coresight_lpd_atm]
  exclude_bd_addr_seg -offset 0xFD1A0000 -range 0x00020000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_crf_0]
  exclude_bd_addr_seg -offset 0xFF5E0000 -range 0x00020000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_crl_0]
  exclude_bd_addr_seg -offset 0xF1260000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_crp_0]
  exclude_bd_addr_seg -offset 0xFF0C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_ethernet_0]
  exclude_bd_addr_seg -offset 0xFF0D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_ethernet_1]
  exclude_bd_addr_seg -offset 0xFD360000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_fpd_afi_0]
  exclude_bd_addr_seg -offset 0xFD380000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_fpd_afi_2]
  exclude_bd_addr_seg -offset 0xFD5E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_fpd_cci_0]
  exclude_bd_addr_seg -offset 0xFD700000 -range 0x00100000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_fpd_gpv_0]
  exclude_bd_addr_seg -offset 0xFD000000 -range 0x00100000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_fpd_maincci_0]
  exclude_bd_addr_seg -offset 0xFD390000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_fpd_slave_xmpu_0]
  exclude_bd_addr_seg -offset 0xFD610000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_fpd_slcr_0]
  exclude_bd_addr_seg -offset 0xFD690000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_fpd_slcr_secure_0]
  exclude_bd_addr_seg -offset 0xFD5F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_fpd_smmu_0]
  exclude_bd_addr_seg -offset 0xFD800000 -range 0x00800000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_fpd_smmutcu_0]
  exclude_bd_addr_seg -offset 0xFF030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_i2c_1]
  exclude_bd_addr_seg -offset 0xFF330000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_ipi_0]
  exclude_bd_addr_seg -offset 0xFF340000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_ipi_1]
  exclude_bd_addr_seg -offset 0xFF350000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_ipi_2]
  exclude_bd_addr_seg -offset 0xFF360000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_ipi_3]
  exclude_bd_addr_seg -offset 0xFF370000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_ipi_4]
  exclude_bd_addr_seg -offset 0xFF380000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_ipi_5]
  exclude_bd_addr_seg -offset 0xFF3A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_ipi_6]
  exclude_bd_addr_seg -offset 0xFF320000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_ipi_pmc]
  exclude_bd_addr_seg -offset 0xFF390000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_ipi_pmc_nobuf]
  exclude_bd_addr_seg -offset 0xFF310000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_ipi_psm]
  exclude_bd_addr_seg -offset 0xFF9B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_lpd_afi_0]
  exclude_bd_addr_seg -offset 0xFF0A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_lpd_iou_secure_slcr_0]
  exclude_bd_addr_seg -offset 0xFF080000 -range 0x00020000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_lpd_iou_slcr_0]
  exclude_bd_addr_seg -offset 0xFF410000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_lpd_slcr_0]
  exclude_bd_addr_seg -offset 0xFF510000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_lpd_slcr_secure_0]
  exclude_bd_addr_seg -offset 0xFF990000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_lpd_xppu_0]
  exclude_bd_addr_seg -offset 0xFF960000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_ocm_ctrl]
  exclude_bd_addr_seg -offset 0xFF980000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_ocm_xmpu_0]
  exclude_bd_addr_seg -offset 0xF11E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_pmc_aes]
  exclude_bd_addr_seg -offset 0xF11F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_pmc_bbram_ctrl]
  exclude_bd_addr_seg -offset 0xF12D0000 -range 0x00001000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_pmc_cfi_cframe_0]
  exclude_bd_addr_seg -offset 0xF12B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_pmc_cfu_apb_0]
  exclude_bd_addr_seg -offset 0xF11C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_pmc_dma_0]
  exclude_bd_addr_seg -offset 0xF11D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_pmc_dma_1]
  exclude_bd_addr_seg -offset 0xF1250000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_pmc_efuse_cache]
  exclude_bd_addr_seg -offset 0xF1240000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_pmc_efuse_ctrl]
  exclude_bd_addr_seg -offset 0xF1110000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_pmc_global_0]
  exclude_bd_addr_seg -offset 0xF1020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_pmc_gpio_0]
  exclude_bd_addr_seg -offset 0xF1000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_pmc_i2c_0]
  exclude_bd_addr_seg -offset 0xF0310000 -range 0x00008000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_pmc_ppu1_mdm_0]
  exclude_bd_addr_seg -offset 0xF1030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_pmc_qspi_0]
  exclude_bd_addr_seg -offset 0xC0000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_pmc_qspi_ospi_flash_0]
  exclude_bd_addr_seg -offset 0xF6000000 -range 0x02000000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_pmc_ram_npi]
  exclude_bd_addr_seg -offset 0xF1200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_pmc_rsa]
  exclude_bd_addr_seg -offset 0xF12A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_pmc_rtc_0]
  exclude_bd_addr_seg -offset 0xF1050000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_pmc_sd_1]
  exclude_bd_addr_seg -offset 0xF1210000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_pmc_sha]
  exclude_bd_addr_seg -offset 0xF1220000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_pmc_slave_boot]
  exclude_bd_addr_seg -offset 0xF2100000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_pmc_slave_boot_stream]
  exclude_bd_addr_seg -offset 0xF1270000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_pmc_sysmon_0]
  exclude_bd_addr_seg -offset 0xF1230000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_pmc_trng]
  exclude_bd_addr_seg -offset 0xF12F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_pmc_xmpu_0]
  exclude_bd_addr_seg -offset 0xF1310000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_pmc_xppu_0]
  exclude_bd_addr_seg -offset 0xF1300000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_pmc_xppu_npi_0]
  exclude_bd_addr_seg -offset 0xFFC90000 -range 0x0000F000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_psm_global_reg]
  exclude_bd_addr_seg -offset 0xFF9A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_rpu_0]
  exclude_bd_addr_seg -offset 0xFF000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_sbsauart_0]
  exclude_bd_addr_seg -offset 0xFF130000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_scntr_0]
  exclude_bd_addr_seg -offset 0xFF140000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_scntrs_0]
  exclude_bd_addr_seg -offset 0xFF9D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_usb_0]
  exclude_bd_addr_seg -offset 0xFE200000 -range 0x00100000 -target_address_space [get_bd_addr_spaces axi_cdma_2/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_0/pspmc_0_psv_usb_xhci_0]
  exclude_bd_addr_seg -offset 0xFFA80000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_adma_0]
  exclude_bd_addr_seg -offset 0xFFA90000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_adma_1]
  exclude_bd_addr_seg -offset 0xFFAA0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_adma_2]
  exclude_bd_addr_seg -offset 0xFFAB0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_adma_3]
  exclude_bd_addr_seg -offset 0xFFAC0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_adma_4]
  exclude_bd_addr_seg -offset 0xFFAD0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_adma_5]
  exclude_bd_addr_seg -offset 0xFFAE0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_adma_6]
  exclude_bd_addr_seg -offset 0xFFAF0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_adma_7]
  exclude_bd_addr_seg -offset 0xFD5C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_apu_0]
  exclude_bd_addr_seg -offset 0xFF070000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_canfd_1]
  exclude_bd_addr_seg -offset 0xF0800000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_coresight_0]
  exclude_bd_addr_seg -offset 0xF0D10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_coresight_a720_cti]
  exclude_bd_addr_seg -offset 0xF0D00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_coresight_a720_dbg]
  exclude_bd_addr_seg -offset 0xF0D30000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_coresight_a720_etm]
  exclude_bd_addr_seg -offset 0xF0D20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_coresight_a720_pmu]
  exclude_bd_addr_seg -offset 0xF0D50000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_coresight_a721_cti]
  exclude_bd_addr_seg -offset 0xF0D40000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_coresight_a721_dbg]
  exclude_bd_addr_seg -offset 0xF0D70000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_coresight_a721_etm]
  exclude_bd_addr_seg -offset 0xF0D60000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_coresight_a721_pmu]
  exclude_bd_addr_seg -offset 0xF0CA0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_coresight_apu_cti]
  exclude_bd_addr_seg -offset 0xF0C60000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_coresight_apu_ela]
  exclude_bd_addr_seg -offset 0xF0C30000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_coresight_apu_etf]
  exclude_bd_addr_seg -offset 0xF0C20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_coresight_apu_fun]
  exclude_bd_addr_seg -offset 0xF0F80000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_coresight_cpm_atm]
  exclude_bd_addr_seg -offset 0xF0FA0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_coresight_cpm_cti2a]
  exclude_bd_addr_seg -offset 0xF0FD0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_coresight_cpm_cti2d]
  exclude_bd_addr_seg -offset 0xF0F40000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_coresight_cpm_ela2a]
  exclude_bd_addr_seg -offset 0xF0F50000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_coresight_cpm_ela2b]
  exclude_bd_addr_seg -offset 0xF0F60000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_coresight_cpm_ela2c]
  exclude_bd_addr_seg -offset 0xF0F70000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_coresight_cpm_ela2d]
  exclude_bd_addr_seg -offset 0xF0F20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_coresight_cpm_fun]
  exclude_bd_addr_seg -offset 0xF0F00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_coresight_cpm_rom]
  exclude_bd_addr_seg -offset 0xF0B80000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_coresight_fpd_atm]
  exclude_bd_addr_seg -offset 0xF0B70000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_coresight_fpd_stm]
  exclude_bd_addr_seg -offset 0xF0980000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_coresight_lpd_atm]
  exclude_bd_addr_seg -offset 0xFD1A0000 -range 0x00020000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_crf_0]
  exclude_bd_addr_seg -offset 0xFF5E0000 -range 0x00020000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_crl_0]
  exclude_bd_addr_seg -offset 0xF1260000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_crp_0]
  exclude_bd_addr_seg -offset 0xFF0C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_ethernet_0]
  exclude_bd_addr_seg -offset 0xFF0D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_ethernet_1]
  exclude_bd_addr_seg -offset 0xFD360000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_fpd_afi_0]
  exclude_bd_addr_seg -offset 0xFD380000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_fpd_afi_2]
  exclude_bd_addr_seg -offset 0xFD5E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_fpd_cci_0]
  exclude_bd_addr_seg -offset 0xFD700000 -range 0x00100000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_fpd_gpv_0]
  exclude_bd_addr_seg -offset 0xFD000000 -range 0x00100000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_fpd_maincci_0]
  exclude_bd_addr_seg -offset 0xFD390000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_fpd_slave_xmpu_0]
  exclude_bd_addr_seg -offset 0xFD610000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_fpd_slcr_0]
  exclude_bd_addr_seg -offset 0xFD690000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_fpd_slcr_secure_0]
  exclude_bd_addr_seg -offset 0xFD5F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_fpd_smmu_0]
  exclude_bd_addr_seg -offset 0xFD800000 -range 0x00800000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_fpd_smmutcu_0]
  exclude_bd_addr_seg -offset 0xFF030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_i2c_1]
  exclude_bd_addr_seg -offset 0xFF330000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_ipi_0]
  exclude_bd_addr_seg -offset 0xFF340000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_ipi_1]
  exclude_bd_addr_seg -offset 0xFF350000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_ipi_2]
  exclude_bd_addr_seg -offset 0xFF360000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_ipi_3]
  exclude_bd_addr_seg -offset 0xFF370000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_ipi_4]
  exclude_bd_addr_seg -offset 0xFF380000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_ipi_5]
  exclude_bd_addr_seg -offset 0xFF3A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_ipi_6]
  exclude_bd_addr_seg -offset 0xFF320000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_ipi_pmc]
  exclude_bd_addr_seg -offset 0xFF390000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_ipi_pmc_nobuf]
  exclude_bd_addr_seg -offset 0xFF310000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_ipi_psm]
  exclude_bd_addr_seg -offset 0xFF9B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_lpd_afi_0]
  exclude_bd_addr_seg -offset 0xFF0A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_lpd_iou_secure_slcr_0]
  exclude_bd_addr_seg -offset 0xFF080000 -range 0x00020000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_lpd_iou_slcr_0]
  exclude_bd_addr_seg -offset 0xFF410000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_lpd_slcr_0]
  exclude_bd_addr_seg -offset 0xFF510000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_lpd_slcr_secure_0]
  exclude_bd_addr_seg -offset 0xFF990000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_lpd_xppu_0]
  exclude_bd_addr_seg -offset 0xFF960000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_ocm_ctrl]
  exclude_bd_addr_seg -offset 0xFF980000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_ocm_xmpu_0]
  exclude_bd_addr_seg -offset 0xF11E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_pmc_aes]
  exclude_bd_addr_seg -offset 0xF11F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_pmc_bbram_ctrl]
  exclude_bd_addr_seg -offset 0xF12D0000 -range 0x00001000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_pmc_cfi_cframe_0]
  exclude_bd_addr_seg -offset 0xF12B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_pmc_cfu_apb_0]
  exclude_bd_addr_seg -offset 0xF11C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_pmc_dma_0]
  exclude_bd_addr_seg -offset 0xF11D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_pmc_dma_1]
  exclude_bd_addr_seg -offset 0xF1250000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_pmc_efuse_cache]
  exclude_bd_addr_seg -offset 0xF1240000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_pmc_efuse_ctrl]
  exclude_bd_addr_seg -offset 0xF1110000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_pmc_global_0]
  exclude_bd_addr_seg -offset 0xF1020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_pmc_gpio_0]
  exclude_bd_addr_seg -offset 0xF1000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_pmc_i2c_0]
  exclude_bd_addr_seg -offset 0xF0310000 -range 0x00008000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_pmc_ppu1_mdm_0]
  exclude_bd_addr_seg -offset 0xF1030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_pmc_qspi_0]
  exclude_bd_addr_seg -offset 0xC0000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_pmc_qspi_ospi_flash_0]
  exclude_bd_addr_seg -offset 0xF6000000 -range 0x02000000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_pmc_ram_npi]
  exclude_bd_addr_seg -offset 0xF1200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_pmc_rsa]
  exclude_bd_addr_seg -offset 0xF12A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_pmc_rtc_0]
  exclude_bd_addr_seg -offset 0xF1050000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_pmc_sd_1]
  exclude_bd_addr_seg -offset 0xF1210000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_pmc_sha]
  exclude_bd_addr_seg -offset 0xF1220000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_pmc_slave_boot]
  exclude_bd_addr_seg -offset 0xF2100000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_pmc_slave_boot_stream]
  exclude_bd_addr_seg -offset 0xF1270000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_pmc_sysmon_0]
  exclude_bd_addr_seg -offset 0xF1230000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_pmc_trng]
  exclude_bd_addr_seg -offset 0xF12F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_pmc_xmpu_0]
  exclude_bd_addr_seg -offset 0xF1310000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_pmc_xppu_0]
  exclude_bd_addr_seg -offset 0xF1300000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_pmc_xppu_npi_0]
  exclude_bd_addr_seg -offset 0xFFC90000 -range 0x0000F000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_psm_global_reg]
  exclude_bd_addr_seg -offset 0xFF9A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_rpu_0]
  exclude_bd_addr_seg -offset 0xFF000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_sbsauart_0]
  exclude_bd_addr_seg -offset 0xFF130000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_scntr_0]
  exclude_bd_addr_seg -offset 0xFF140000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_scntrs_0]
  exclude_bd_addr_seg -offset 0xFF9D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_usb_0]
  exclude_bd_addr_seg -offset 0xFE200000 -range 0x00100000 -target_address_space [get_bd_addr_spaces axi_cdma_3/Data] [get_bd_addr_segs versal_cips_0/NOC_FPD_CCI_1/pspmc_0_psv_usb_xhci_0]


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


