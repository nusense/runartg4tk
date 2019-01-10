#! /usr/bin/env bash
#
##############################################################################
export THISFILE="$0"
export b0=`basename $0`
export SCRIPT_VERSION=2018-12-12

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] ; then
  echo "script ${BASH_SOURCE[0]} is being sourced ..."
  QUITCMD="return"
else
  echo "script is being run ..."
  QUITCMD="exit"
fi


export OUTPUTTOP="/pnfs/geant4/persistent/rhatcher/genana_g4vmp"
export MULTIVERSE=multiverse181212_Bertini        # e.g. (fcl base)

export MRB_SOURCE=/geant4/app/rhatcher/mrb_work_area-2018-12-12/srcs
export SCRIPT=${MRB_SOURCE}/runartg4tk/scripts/genana_g4vmp_proclevel_condor.sh
export TARBALL=localProducts_runartg4tk_v09_00_00_e17_prof_2019-01-10.tar.bz2

HERENOW=`pwd`
# need this for ROOT
source /geant4/app/rhatcher/setup_everything_std-2018-12-12.sh > /dev/null 2>&1
cd ${HERENOW}


export MULTI_UNIVERSE_SPEC="${MULTIVERSE},0,10"

export GOODLIST=${MULTIVERSE}_complete_exptsetup.txt

export STAGING_DIR=${MULTIVERSE}_staging_dir

if [ ! -f ${GOODLIST} ]; then
  echo -e "${OUTRED}no ${GOODLIST}${OUTNOCOL}"
  echo "about to \"${QUITCMD}\""
  ${QUITCMD} 42
fi

if [  ! -d ${STAGING_DIR}/extracted ]; then
  mkdir -p ${STAGING_DIR}/extracted
fi
echo PWD=`pwd`
echo into ${STAGING_DIR}

DESTDIRTOP=${OUTPUTTOP}/${MULTIVERSE}
for d in ${DESTDIRTOP}/* ; do

  if [ ! -d ${d} ]; then continue; fi
  exptsetup=`basename ${d}`
  # skip funky directories
  if [[ "${d}" =~ .*_save ]]; then continue ; fi
  if [[ "${d}" =~ .*_nohist ]]; then continue ; fi
  if [[ "${d}" =~ .*_bleck ]]; then continue ; fi

  # is it in our ${GOODLIST} already?
  isgood=`grep -c ${exptsetup} ${GOODLIST}`
  if [ ${isgood} -eq 0 ]; then
    echo -e "${OUTRED}${exptsetup} in missing from ${GOODLIST}${OUTNOCOL}"
    continue;
  fi
  echo -e "${OUTGREEN}processing ${exptsetup}${OUTNOCOL}"

  # compression level 6
  # no more than 1002 files
  export SUMFILE=${STAGING_DIR}/${exptsetup}.sum.hist.root
  if [ -f ${SUMFILE} ]; then
    echo -e "${OUTGREEN}    ${SUMFILE} exists${OUTNOCOL}"
  else
    hadd -f6 -n 1002 ${SUMFILE} ${d}/*.hist.root
  fi

  #
  echo -e "${OUTORANGE} ... extract_universe ${exptsetup}${OUTNOCOL}"

  SCRIPT="${MRB_SOURCE}/runartg4tk/scripts/extract_universes.C"
  root -b -q ${SCRIPT}\(\"${SUMFILE}\",\"${STAGING_DIR}/extracted\"\) \
      > ${STAGING_DIR}/${exptsetup}.split.log 2>&1

done

# ${MRB_SOURCE}/runartg4tk/scripts/extract_params.sh

# end-of-script
