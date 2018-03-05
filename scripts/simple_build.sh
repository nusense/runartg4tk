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

# end-of-script