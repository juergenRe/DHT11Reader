# get the directory where this script resides
set thisDir [file dirname [info script]]
puts $thisDir
# source common utilities
#source -notrace $thisDir/utils.tcl

# Set various names
# origin_dir: proj folder of creating project
# _customIPFolder: base folder for all custom IP; resides at the same level as all project folders
set origin_dir "."
set actPath [pwd]
set _customIPFolder "CustomIP"
set _IP_name_ "DHT11Reader"
#define as integer number!
set _Version 1     
#set _Force	"-force"
set _Force ""

# create the directories to package the IP cleanly
if {![file exists ${origin_dir}/../../$_customIPFolder/$_IP_name_]} {
   file mkdir ${origin_dir}/../../$_customIPFolder/$_IP_name_
}

if {![file exists ${origin_dir}/../../$_customIPFolder/$_IP_name_/src]} {
   file mkdir ${origin_dir}/../../$_customIPFolder/$_IP_name_/src
}

if {![file exists ${origin_dir}/../../$_customIPFolder/$_IP_name_/xgui]} {
   file mkdir ${origin_dir}/../../$_customIPFolder/$_IP_name_/xgui
}

if {![file exists ${origin_dir}/../../$_customIPFolder/$_IP_name_/proj]} {
   file mkdir ${origin_dir}/../../$_customIPFolder/$_IP_name_/proj
}

foreach f [glob ../src/hdl/*.v*] {
   file copy -force $f ${origin_dir}/../../$_customIPFolder/$_IP_name_/src
}

# Create project
cd ${origin_dir}/../../$_customIPFolder/$_IP_name_/proj
create_project -force $_IP_name_ . -part xc7z020clg400-1

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}


set obj [get_filesets sources_1]
add_files -norecurse -fileset $obj [glob ./../src/*.v*]

set_property -name "top" -value $_IP_name_ -objects $obj
set_property -name "top_auto_set" -value "0" -objects $obj

update_compile_order -fileset sources_1

ipx::package_project "$_Force" -root_dir ./.. -library ip -vendor rej -taxonomy /AXI4Components
if {[string equal $_Force "-force"]} {
	set_property core_revision $_Version [ipx::current_core]
}

ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]

ipx::unload_core ./../component.xml

close_project

# return to folder where we started command
cd $actPath
