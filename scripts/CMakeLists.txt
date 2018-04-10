# CMakeLists.txt file for gdml detector description files

# install files in this directory
file(GLOB script_files *.sh)
file(GLOB root_c_files *.C)
install( FILES ${script_files}  ${root_c_files}
         DESTINATION ${product}/${version}/scripts )

# select scripts in bin as well
install( FILES ${script_files}  ${root_c_files}
         DESTINATION ${flavorqual_dir}/bin )

# Also install in the build area
#foreach(aFile ${script_files})
#  get_filename_component( basename ${aFile} NAME )
#  configure_file( ${aFile} ${CMAKE_BINARY_DIR}/scripts/${basename} COPYONLY )
#endforeach(aFile)

