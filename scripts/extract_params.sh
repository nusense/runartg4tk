#! /usr/bin/env bash

PHYPROC="Bertini"
FCLIN=multiverse170208_Bertini.fcl
OUTPATH=./extracted/Bertini/scan

# special case for Default
# https://cdcvs.fnal.gov/redmine/projects/g4mps/wiki/Mar_2017_ha_Bertini_stat_analysis
# RadiusScale - from 1. to 3.5 (Default=2.82)
# NOTE: officially, the validity range of the RadiusScale is from 1. to 2.82; we have decided to widen it just to experiment
# XSecScale - from 0.1 to 2. (Default=1.)
# FermiScale - from 0.5 to 1. (Default=0.685)
# TrailingRadius - from 0. to 5. (Default=0. although the "best value" is said to be ~0.7)

cat > ${OUTPATH}/0000/params.dat << EOF
RadiusScale            2.82
XSecScale              1.0
FermiScale             0.685
TrailingRadius         0.0
EOF

echo "0000 = Default in ${OUTPATH}/0000/params.dat"
cat ${OUTPATH}/0000/params.dat

exit


UNIV=""

IFS=@    # use this to preserve leading blanks on read (file w/out @ in it)
while read line
do
   # echo "$line"   # use quotes to keep internal spacing

   # bash Regex matching with =~ operator within [[ double brackets ]].
   # NOTE: As of version 3.2 of Bash, expression to match no longer quoted.
      # mac:  3.2.57(1)-release
      # geant4gpvm01: 4.1.2(2)-release
   if [[ "$line" =~ ^${PHYPROC}Random4Univ ]]; then
      UNIV=`echo ${line} | cut -d' ' -f1 | cut -c19-`
   fi
   if [ ! -d ${OUTPATH}/${UNIV} ]; then
      # no place to put it
      echo "skip UNIV=${UNIV}"
      UNIV=""
      continue
   fi
   if [[ -n "${UNIV}" && "$line" =~ ModelParameters: ]]; then
      OUTFILE=${OUTPATH}/${UNIV}/params.dat
      # next 4 lines
      read p1
      read p2
      read p3
      read p4
      # trim leading spaces & ":"
      echo "$p1" | sed -e 's/^ *//g' | tr ':' ' ' >   ${OUTFILE}
      echo "$p2" | sed -e 's/^ *//g' | tr ':' ' ' >>  ${OUTFILE}
      echo "$p3" | sed -e 's/^ *//g' | tr ':' ' ' >>  ${OUTFILE}
      echo "$p4" | sed -e 's/^ *//g' | tr ':' ' ' >>  ${OUTFILE}
      echo "start UNIV=${UNIV} ${OUTFILE}"
   fi
done < ${FCLIN}
unset IFS





# end-of-script
