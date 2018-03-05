# ======================================================================
#  runartg4tk main build file
#
#  . mrb slp   # Run if you have local products to set up
#  . mrbsetenv     # Needed to set up local development products
#  mrb b       # Build
#  mrb t       # Test (if applicable)
#  mrb i       # Install to local products
#
# ======================================================================

# use cmake 3.7 or later
cmake_minimum_required (VERSION 3.7)

project(runartg4tk)

# cetbuildtools contains our cmake modules
SET ( CETBUILDTOOLS_VERSION $ENV{CETBUILDTOOLS_VERSION} )
IF (NOT CETBUILDTOOLS_VERSION)
MESSAGE (FATAL_ERROR "ERROR: setup cetbuildtools to get the cmake modules")
ENDIF()

set(CMAKE_MODULE_PATH $ENV{CANVAS_DIR}/Modules $ENV{CANVAS_DIR}/Modules
$ENV{CETBUILDTOOLS_DIR}/Modules
${CMAKE_MODULE_PATH})

include(CetCMakeEnv)
cet_cmake_env()

#set_install_root()

if ( ${APPLE} )
cet_set_compiler_flags(DIAGS CAUTIOUS
WERROR
EXTRA_FLAGS -pedantic

)
else()
cet_set_compiler_flags(DIAGS CAUTIOUS
WERROR
EXTRA_FLAGS -pedantic

)
endif()

cet_report_compiler_flags()

# Locate some UPS areas (the versions are just minimum required)
# and setup include paths
# These are needed for Art stuff

find_ups_product(cetbuildtools v7_00_03)
#
#

# Build these directories
add_subdirectory( scripts )

# ups - table and config files

add_subdirectory(ups)


# packaging utility

include(UseCPack)






