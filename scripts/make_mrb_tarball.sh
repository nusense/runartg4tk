#! /usr/bin/env bash

if [ -z "${MRB_TOP}" ]; then
  echo -e "${OUTRED}MRB must be setup${OUTNOCOL}"
  exit
fi
if [[ "${BASH_SOURCE[0]}" != "${0}" ]] ; then
  echo -e "${OUTRED}script ${BASH_SOURCE[0]} is supposed to be run, not sourced ...${OUTNOCOL}"
  return
fi

export TARBALL_OUTDIR=/pnfs/geant4/persistent/rhatcher/

export TARBALL_STEM=`basename ${MRB_INSTALL}`
cd ${MRB_TOP}

export DATE=`date "+%Y-%m-%d"`
export TARBALL_BASE=${TARBALL_STEM}_${DATE}.tar.bz2

case ${TARBALL_BASE} in
   *.gz | *.tgz ) copt="z" ;;
   *.bz2        ) copt="j" ;;
esac

echo -e "${OUTGREEN}create ${TARBALL_BASE}${OUTNOCOL}"

if [ -f ${TARBALL_BASE} ]; then rm -f ${TARBALL_BASE} ]; fi
if [ -f ${TARBALL_OUTDIR}/${TARBALL_BASE} ]; then rm -f ${TARBALL_OUTDIR}/${TARBALL_BASE} ]; fi

tar cv${copt}f ${TARBALL_BASE} ${TARBALL_STEM}
cp             ${TARBALL_BASE} ${TARBALL_OUTDIR}/${TARBALL_BASE}
rm             ${TARBALL_BASE}

echo -e "${OUTGREEN}moved to ${TARBALL_OUTDIR}${OUTNOCOL}"

# end-of-script
