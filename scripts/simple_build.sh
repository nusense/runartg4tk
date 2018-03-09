#! /usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] ; then
  echo "script ${BASH_SOURCE[0]} is being sourced ..."
  QUITCMD="return"
  HERE=`dirname ${BASH_SOURCE[0]}`
else
  echo "script $0 is being run ..."
  HERE=`dirname ${0}`
  QUITCMD="exit"
fi
# make it canonical
HERE=`readlink -f ${HERE}`
echo "HERE=${HERE}"

if [ -z "${MRB_INSTALL}" ]; then
  echo -e "${OUTRED}need \${MRB_INSTALL} defined${OUTNOCOL}"
  ${QUITCMD}
fi

echo -e "${OUTCYAN}"
set -o xtrace
cp ${HERE}/bootstrap_ups.sh ${MRB_INSTALL}
set +o xtrace
echo -e "${OUTNOCOL}"


## how to get this automatically???
#LIBSUB=slf6.x86_64.e15.prof
# don't know if this will work for "debug" (ordering???)
BUILDTYPE=`basename ${MRB_BUILDDIR} | sed -e 's/build_//g'`
LIBSUB=`echo ${BUILDTYPE}.${MRB_QUALS} | tr ":" "."`

BASEDESTDIR=${MRB_INSTALL}/runartg4tk/${RUNARTG4TK_VERSION}
LIBDESTDIR=${BASEDESTDIR}/${LIBSUB}/lib
if [[ ! -d ${LIBDESTDIR} ]]; then
  echo -e "${OUTRED}missing:"
  echo -e "  LIBDESTDIR=${LIBDESTDIR}"
  echo -e "${OUTNOCOL}"
else
  echo -e "${OUTCYAN}"
  set -o xtrace
  mkdir -p ${BASEDESTDIR}/include/PlotUtils
  cd  ${MRB_SOURCE}/RooMUHistos/PlotUtils
  ls *.h
  cp *.h ${BASEDESTDIR}/include/PlotUtils
  rm ${BASEDESTDIR}/include/PlotUtils/LinkDef.h
  cd ${MRB_SOURCE}/RooMUHistos/lib/
  ls *
  cp * ${LIBDESTDIR}
  set +o xtrace
  echo -e "${OUTNOCOL}"
fi

# end-of-script