# this file is intended to be sourced by a bash shell
# bootstrap UPS
#   --build   # setup build products (cmake, mrb)
#   --base    # setup base products (geant4, art)
#   --local   # setup artg4tk and other stuff
#   --bluearc

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] ; then
  echo "script ${BASH_SOURCE[0]} is being sourced ..."
  QUITCMD="return"
  BOOTSTRAP_HERE=`dirname ${BASH_SOURCE[0]}`
else
  echo "script $0 is being run ..."
  BOOTSTRAP_HERE=`dirname ${0}`
  QUITCMD="exit"
fi
# make it canonical
BOOTSTRAP_HERE=`readlink -f ${BOOTSTRAP_HERE}`

USECVMFS=yes
SETUPBUILD=  # products necessary for building (cmake, mrb)
SETUPBASE=   # base products (geant4, art)
SETUPLOCAL=  # mrb localproducts_ result area (possibly a unrolled tarball)
             # related to "BOOTSTRAP_HERE"

export EXX=e15
export QOPT=prof

VER_CMAKE="cmake       v3_10_1"
VER_MRB="mrb           v1_13_02"
VER_CET="cetbuildtools v7_00_03"

VER_GEANT4="geant4     v4_10_4    -q +${EXX}:+${QOPT}:+cl23"
VER_ART="art           v2_10_02   -q +${EXX}:+${QOPT}"
VER_ARTG4TK="artg4tk   v5_00_00   -q +${EXX}:+${QOPT}"

for arg in ${@} ; do
  case $arg in
    *build*   ) SETUPBUILD=yes
                ;;
    *base*    ) SETUPBASE=yes
                ;;
    *local*   ) SETUPLOCAL=yes
                ;;
    --bluearc ) unset USECVMFS
                ;;
    *         ) echo "unknown arg=\"${arg}\""
                ;;
  esac
done


if [ -n "${USECVMFS}" ]; then
  source /cvmfs/oasis.opensciencegrid.org/geant4/externals/setup
  # add another location so we can use the best-est "ifdhc"
  #    /grid/fermiapp/products/common/db
  COMMON_UPS=/cvmfs/fermilab.opensciencegrid.org/products/common/db
  LARSOFT_UPS=/cvmfs/fermilab.opensciencegrid.org/products/larsoft
  MU2E_UPS=/cvmfs/mu2e.opensciencegrid.org/artexternals

  export PRODUCTS=${PRODUCTS}:${COMMON_UPS}:${LARSOFT_UPS}:${MU2E_UPS}
else
  source /geant4/app/externals/setup
  # other locations
  COMMON_UPS=/grid/fermiapp/products/common/db
  LARSOFT_UPS=/grid/fermiapp/products/larsoft

  RWHUPS=/geant4/app/rhatcher/externals
  ALTUPS=/geant4/app/altups/

  export PRODUCTS=${RWHUPS}:${ALTUPS}:${PRODUCTS}:${COMMON_UPS}:${LARSOFT_UPS}
fi

# interact w/ PNFS only through ifdh cp & friends
setup ifdhc

if [ -n "${SETUPBUILD}" ]; then
  setup ${VER_CMAKE}

  #now-by-mrb# setup gitflow       v1_10_2    # was v1_8_0
  #now-by-mrb# setup git           v2_11_0    # was v2_3_0
  #now-by-mrb# setup cetpkgsupport v1_08_06
  #
  setup ${VER_MRB}
  setup ${VER_CET}
fi

if [ -n "${SETUPBASE}" ]; then
  setup ${VER_GEANT4}
  setup ${VER_ART}
fi

if [ -n "${SETUPLOCAL}" ]; then
  if [ ! -d ${BOOTSTRAP_HERE}/.upsfiles ]; then
    echo -e "${OUTRED}BOOTSTRAP_HERE is not a UPS area"
    echo -e "${BOOTSTRAP_HERE}${OUTNOCOL}"
  else
    export PRODUCTS=${BOOTSTRAP_HERE}:${PRODUCTS}
    setup ${VER_ARTG4TK}
  fi
fi

# end-of-script
