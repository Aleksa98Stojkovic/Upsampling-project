variable dispScriptFile [file normalize [info script]]

proc getScriptDirectory {} {
    variable dispScriptFile
    set scriptFolder [file dirname $dispScriptFile]
    return $scriptFolder
}

set sdir [getScriptDirectory]
cd [getScriptDirectory]

# KORAK#1: Definisanje direktorijuma u kojima ce biti smesteni projekat i konfiguracioni fajl
set resultDir ..\/..\/result\/Upsampling
file mkdir $resultDir
create_project pkg_upsampling ..\/..\/result\/Upsampling -part xc7z010clg400-1 -force
set_property board_part digilentinc.com:zybo-z7-10:part0:1.0 [current_project]
set_property target_language VHDL [current_project]


# KORAK#2: Ukljucivanje svih izvornih fajlova u projekat
add_files -norecurse ..\/hdl\/AXI_router.vhd
add_files -norecurse ..\/hdl\/bias_ROM.vhd
add_files -norecurse ..\/hdl\/Cache_line_register.vhd
add_files -norecurse ..\/hdl\/Cache_read_control_unit.vhd
add_files -norecurse ..\/hdl\/Cache_Top.vhd
add_files -norecurse ..\/hdl\/Dual_Port_BRAM.vhd
add_files -norecurse ..\/hdl\/FSM_PB.vhd
add_files -norecurse ..\/hdl\/IP_top.vhd
add_files -norecurse ..\/hdl\/IP_with_router_top.vhd
add_files -norecurse ..\/hdl\/MAC.vhd
add_files -norecurse ..\/hdl\/PB_Group.vhd
add_files -norecurse ..\/hdl\/PB_top.vhd
add_files -norecurse ..\/hdl\/PISO_down.vhd
add_files -norecurse ..\/hdl\/PISO_up.vhd
add_files -norecurse ..\/hdl\/Register_bank_sync.vhd
add_files -norecurse ..\/hdl\/result_write.vhd
add_files -norecurse ..\/hdl\/RF_for_write.vhd
add_files -norecurse ..\/hdl\/Upsampling_IP_v1_0.vhd
add_files -norecurse ..\/hdl\/Upsampling_IP_v1_0_M_AXI.vhd
add_files -norecurse ..\/hdl\/Upsampling_IP_v1_0_S_AXI.vhd
add_files -norecurse ..\/hdl\/Weights_Mem_Controler.vhd
add_files -norecurse ..\/hdl\/Weights_Memory.vhd
add_files -norecurse ..\/hdl\/Weights_Memory_top.vhd
add_files -norecurse ..\/hdl\/Write_Ctrl.vhd
# add_files -fileset constrs_1 ..\/xdc\/VGA.xdc
update_compile_order -fileset sources_1

# KORAK#3: Pokretanje procesa sinteze
launch_runs synth_1
wait_on_run synth_1
puts "*****************************************************"
puts "* Sinteza zavrsena! *"
puts "*****************************************************"

# KORAK#4: Pakovanje Jezgra
update_compile_order -fileset sources_1
ipx::package_project -root_dir ..\/..\/ -vendor xilinx.com -library user -taxonomy /UserIP -force

set_property vendor FTN [ipx::current_core]
set_property name Upsampling_IP [ipx::current_core]
set_property display_name Upsampling_IP_V1_0 [ipx::current_core]
set_property description {Upsampling IP jezgro} [ipx::current_core]
set_property company_url http://www.ftn.uns.ac.rs [ipx::current_core]
set_property vendor_display_name FTN [ipx::current_core]
set_property taxonomy {/UserIP} [ipx::current_core]
set_property supported_families {zynq Production} [ipx::current_core]

set_property core_revision 2 [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]
set_property  ip_repo_paths ..\/..\/ [current_project]
update_ip_catalog
ipx::check_integrity -quiet [ipx::current_core]
ipx::archive_core ..\/..\/Upsampling_IP_V1_0.zip [ipx::current_core]
close_project
