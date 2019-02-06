#! /usr/bin/env bash
#
##############################################################################
export THISFILE="$0"
export b0=`basename $0`
export SCRIPT_VERSION=2019-02-05

export SUBSET=$1

export CLEAR_COMPLETE=0  # start fresh w/ ${GOODLIST}?

export OUTPUTTOP="/pnfs/geant4/persistent/rhatcher/genana_g4vmp"
export OUTPUTTOPSCR="/pnfs/geant4/scratch/rhatcher/genana_g4vmp"
export MULTIVERSE=multiverse181212_Bertini
export USTART=0
export USTRIDE=1 # was 10 # stride used for ${SUBMITLIST}
export USTRIDE_SN=1
export USTRIDE_TA=1
export USTRIDE_PB=1
export USTRIDE_U=1
export EXPECTED_UNIV=1000
export FORM="%04d"

###  --expected-lifetime='short'|'medium'|'long'|NUMBER[UNITS]
#                         '3h' , '8h' , '85200s' (23.66hr ~2.958xmedium)
# default 8hr
UTIME="--expected-lifetime=medium"
UTIME_SN="--expected-lifetime=long"
UTIME_TA="--expected-lifetime=long"
UTIME_PB="--expected-lifetime=long"
UTIME_U="--expected-lifetime=long"

# stragglers
#UTIME="--expected-lifetime=long"
#UTIME_TA="--expected-lifetime=28h"
#UTIME_PB="--expected-lifetime=28h"
#UTIME_U="--expected-lifetime=28h"

# for defaults + 99 universes
export USTART=0
export USTRIDE=1 # 10 # stride used for ${SUBMITLIST}
export EXPECTED_UNIV=100

# for universes 0100 to 0499
#export USTART=100
#export USTRIDE=1 # 10 # stride used for ${SUBMITLIST}
#export EXPECTED_UNIV=400

##export EXPECTED_UNIV=500

let BOOKEND_UNIV=${USTART}+${EXPECTED_UNIV}
export BOOKEND_UNIV
export BOOKEND_UNIV_4DIGITS=`printf "%0d" $BOOKEND_UNIV`

# since make-up files might use a different stride we can't count files
#export NHIST_SHORTCUT=99999
export SHOWOK=1

export MRB_SOURCE=/geant4/app/rhatcher/mrb_work_area-2018-12-12/srcs
export SCRIPT=${MRB_SOURCE}/runartg4tk/scripts/genana_g4vmp_proclevel_condor.sh
#export TARBALL=localProducts_runartg4tk_v09_00_00_e17_prof_2019-01-10.tar.bz2

#export TARBALL_DEFAULT_DIR=/pnfs/geant4/persistent/rhatcher
export TARBALL_DEFAULT_DIR=/pnfs/geant4/resilient/rhatcher
export TARBALL=`ls -tr ${TARBALL_DEFAULT_DIR}/localProducts_runartg4tk* | tail -1`

export MULTI_UNIVERSE_SPEC="${MULTIVERSE},0,1"  # "0,10"

export GOODLIST=${MULTIVERSE}_complete_exptsetup.txt
export SUBMITLIST=jobs_to_submit.sh

nsets_to_submit=0

if [ ${CLEAR_COMPLETE} -ne 0 ]; then
  rm -f ${GOODLIST}
fi
if [ ! -f ${GOODLIST} ]; then touch ${GOODLIST} ; fi

rm -f ${SUBMITLIST}
touch ${SUBMITLIST}

cat > ${SUBMITLIST} <<EOF
#! /usr/bin/env bash

# trick UPS into thinking it hastn't been setup yet
unset PRODUCTS
unset SETUP_UPS
unset UPS_DIR
unset SETUP_JOBSUB_CLIENT

source /cvmfs/fermilab.opensciencegrid.org/products/common/etc/setup

setup jobsub_client
export GROUP=dune
export JOBSUB_GROUP=dune  # this one I think

export SCRIPT=${SCRIPT}
export TARBALL=${TARBALL}

export SLEEPTIME=1.5s  # linux-only non-integer time
export LOGFILE=jobs_to_submit.jobsub.log

function now ()
{
    date "+%Y-%m-%d %H:%M:%S"
}

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] ; then
  echo "script ${BASH_SOURCE[0]} is being sourced ..."
  QUITCMD="return"
else
  echo "script is being run ..."
  QUITCMD="exit"
fi
#echo "about to \"${QUITCMD}\""
#${QUITCMD} 42
#echo "this should not be seen"

EOF
chmod +x ${SUBMITLIST}

function gen_submit() {
  blk_start=$1
  blk_last=$2
  blk_stride=$3
  blk_time=$4

  let blk_n=${blk_last}-${blk_start}+1
  let blk_sets=${blk_n}/${blk_stride}
  let blk_n2=${blk_sets}*${blk_stride}

  let blk_start2=${blk_start}+${blk_n2}
  let blk_mod=${blk_n}%${blk_stride}
  let blk_mod2=${blk_n}-${blk_n2}

  echo "#" >>${SUBMITLIST}
  echo "# start ${blk_start} last ${blk_last} stride ${blk_stride}" >>${SUBMITLIST}
  echo "# n ${blk_n} sets ${blk_sets} n2 ${blk_n2}" >>${SUBMITLIST}
  echo "# start2 ${blk_start2} mod ${blk_mod} ${blk_mod2}" >>${SUBMITLIST}
  echo "#" >>${SUBMITLIST}


  ARGS="--probe=${PROBE} --target=${TARGET} --pz=${PZ}"

  UARG1="--universes ${MULTIVERSE},${blk_start},${blk_stride}"
  CMD1="jobsub_submit -g -N ${blk_sets} ${blk_time} file://\${SCRIPT} ${ARGS} ${UARG1} --tarball=${TARBALL}"

  if [ ${blk_sets} -gt 0 ]; then
    echo "echo \`now\` ${exptsetup} -N ${blk_sets} ${UARG1}" >> ${SUBMITLIST}
    echo "echo \`now\` ${exptsetup} -N ${blk_sets} ${UARG1} >> \${LOGFILE}" >> ${SUBMITLIST}
    echo "${CMD1} >> \${LOGFILE} 2>&1"   >> ${SUBMITLIST}
    echo "sleep \${SLEEPTIME}" >> ${SUBMITLIST}
  fi
  let nsets_to_submit=${nsets_to_submit}+${blk_sets}

  if [ ${blk_mod} -gt 0 ]; then

    UARG2="--universes ${MULTIVERSE},${blk_start2},${blk_mod}"
    CMD2="jobsub_submit -g -N 1 file://\${SCRIPT} ${ARGS} ${UARG2} --tarball=${TARBALL}"

    echo "echo \`now\` ${exptsetup} -N 1 ${UARG2}" >> ${SUBMITLIST}
    echo "echo \`now\` ${exptsetup} -N 1 ${UARG2} >> \${LOGFILE}" >> ${SUBMITLIST}

    echo "${CMD2} >> \${LOGFILE} 2>&1"   >> ${SUBMITLIST}
    echo "sleep \${SLEEPTIME} " >> ${SUBMITLIST}
    let nsets_to_submit=${nsets_to_submit}+1

  fi

  echo "echo ================================================== >> \${LOGFILE}" >> ${SUBMITLIST}

}

DESTDIRTOP=${OUTPUTTOP}/${MULTIVERSE}
DESTDIRSCRTOP=${OUTPUTTOPSCR}/${MULTIVERSE}

grep -h : ${DESTDIRTOP}/*.fcl | cut -d: -f1 | cut -d_ -f2- | \
      tr -d ' \t' | sort -u > conditions.list
nc=`wc -l conditions.list | cut -d' ' -f1`
if [ $nc -eq 0 ]; then
  echo -e "${OUTRED}... ah, missing ${DESTDIRTOP} fcl files???${OUTNOCOL}"
fi


while read line ; do
  # echo "$line"   # use quotes to keep internal spacing
  if [ ! -d ${DESTDIRTOP}/${line} ]; then
    echo -e "${OUTRED}create output persistent subdir ${line}${OUTNOCOL}"
    mkdir -p ${DESTDIRTOP}/${line}
  fi
  if [ ! -d ${DESTDIRSCRTOP}/${line} ]; then
    echo -e "${OUTRED}create output scratch subdir ${line}${OUTNOCOL}"
    mkdir -p ${DESTDIRSCRTOP}/${line}
  fi
done < conditions.list


for d in ${DESTDIRTOP}/*${SUBSET}* ; do
#for d in ${DESTDIRTOP}/piplus_on_U_at_6GeV ; do
  #echo -e "${OUTORANGE}looking for $d ${OUTNOCOL}"

  if [ ! -d ${d} ]; then continue; fi
  exptsetup=`basename ${d}`
  # skip funky directories
  if [[ "${d}" =~ .*_save ]]; then continue ; fi
  if [[ "${d}" =~ .*_nohist ]]; then continue ; fi
  if [[ "${d}" =~ .*_bleck ]]; then continue ; fi
  if [[ "${d}" =~ .*_bork.* ]]; then continue ; fi

  # is it in our ${GOODLIST} already?
  isgood=`grep -c ${exptsetup} ${GOODLIST}`
  # echo ==== grep -c ${exptsetup} ${GOODLIST}
  # echo ==== ${isgood}
  if [ ${isgood} -gt 0 ]; then
    if [ ${isgood} -eq 1 ]; then
      echo -e "${OUTGREEN}${exptsetup} in ${GOODLIST}${OUTNOCOL}"
    else
      echo -e "${OUTGREEN}${exptsetup} in ${GOODLIST}${OUTORANGE} ${isgood} times${OUTNOCOL}"
    fi
    continue;
  fi

  # echo -e "${OUTGREEN}${exptsetup}${OUTNOCOL}"
  flist=`ls -1 ${d}/*.hist.root 2>/dev/null | sort`
  # preserve \n
  nhist=`echo "$flist" | wc -l`

  TARGET=`echo ${exptsetup} | cut -d_ -f3`
  PROBE=`echo ${exptsetup}  | cut -d_ -f1`
  PZ=`echo ${exptsetup} | cut -d_ -f5 | sed -e 's/GeV//g' -e 's/p/\./g'`


#  if [ -z "${flist}" ]; then
#    echo -e "${OUTRED}${exptsetup} hast no .hist.root files ${OUTNOCOL} "
#    let missinghi=${EXPECTED_UNIV}-1
#    gen_submit ${USTART} ${missinghi} ${USTRIDE}
#
#    continue;
#  fi

#  if [ ${nhist} -eq ${NHIST_SHORTCUT} ]; then
#    if [ ${SHOWOK} -ne 0 ]; then
#      echo -e "${OUTGREEN}${exptsetup} has ${NHIST_SHORTCUT} .hist.root files${OUTNOCOL}"
#    fi
#    continue
#  fi

  thissetfirst=999999
  thissetlast=0
#  thissetrunning=-1
  let thissetrunning=${USTART}-1
  thissetnext=0
  thissetmissing=""
  nthisset_univ=0

  fbookend=${d}/${exptsetup}_U${BOOKEND_UNIV_4DIGITS}_9999.hist.root

  for f in $flist ${fbookend} ; do
    fbase=`basename $f .hist.root `

#echo "flist=$flist"
#echo "f=$f fbase=$fbase"
#exit
    # names look like ${exptsetup}_U{0000}_{0009}.hist.root
    # trim of leading U and leading 0's take care for 0..0->0
    # 's/U0*//g' turns U0000->''
    fpair=`echo ${fbase} | sed -e "s/${exptsetup}//g" -e 's/_U0*/U/g' -e 's/U_/0_/g' -e 's/U//g' -e 's/_0*/ /g' | tr "_" " " | tr -s ' '`

    fpairlo=`echo ${fpair} | cut -d' ' -f1`
    fpairhi=`echo ${fpair} | cut -d' ' -f2`
    if [ "${f}" != "${fbookend}" ]; then
      if [ ${fpairhi} -lt ${USTART} ]; then
        #echo -e "${OUTORANGE}skip ${fpair} too low${OUTNOCOL}"
        continue
      fi
      if [ ${fpairlo} -ge ${BOOKEND_UNIV} ]; then
        #echo -e "${OUTORANGE}skip ${fpair} too high${OUTNOCOL}"
        continue
      fi
    fi

    if [ ${fpairlo} -lt ${thissetfirst} ]; then
        thissetfirst=${fpairlo}
        if [ ${thissetfirst} -lt ${USTART} ]; then
            thissetfirst=${USTART}
        fi
    fi
    if [ ${fpairhi} -ge ${thissetlast}  ]; then
        thissetlast=${fpairhi}
        if [ ${thissetlast} -ge ${BOOKEND_UNIV} ]; then
             thissetlast=${BOOKEND_UNIV}
        fi
    fi

    let thissetnext=${thissetrunning}+1
    if [ ${fpairlo} -ne ${thissetnext} ]; then
       let missinghi=${fpairlo}-1
       thissetmissing="${thissetmissing} [${thissetnext}:${missinghi}]"

       THIS_USTRIDE=${USTRIDE}
       THIS_TIME=${UTIME}
       TGT=`echo ${exptsetup} | cut -d_ -f3`
       PZ=`echo ${exptsetup}  | cut -d_ -f5 | sed -e 's/GeV//g' | tr p "."`
       LOWPZ=0
       case ${PZ} in
        1 | 1.4 | 2 | 3 ) LOWPZ=1 ;;
        *               ) LOWPZ=0 ;;
       esac
       # special stride & times
       case ${TGT} in
         U ) THIS_USTRIDE=${USTRIDE_U}
             if [ ${LOWPZ} -eq 0 ] ; then
                 THIS_TIME=${UTIME_U}
             fi
             ;;
        Pb ) THIS_USTRIDE=${USTRIDE_PB}
             if [ ${LOWPZ} -eq 0 ] ; then THIS_TIME=${UTIME_PB} ; fi
             ;;
        Ta ) THIS_USTRIDE=${USTRIDE_TA}
             if [ ${LOWPZ} -eq 0 ] ; then THIS_TIME=${UTIME_TA} ; fi
             ;;
        Sn ) THIS_USTRIDE=${USTRIDE_SN}
             if [ ${LOWPZ} -eq 0 ] ; then THIS_TIME=${UTIME_SN} ; fi
             ;;
         * ) echo "normal" > /dev/null
             ;;
       esac
#echo -e "${OUTORANGE}THIS_TIME ${THIS_TIME} ${PZ} ${LOWPZ} ${TGT} ${OUTNOCOL}"
       gen_submit ${thissetnext} ${missinghi} ${THIS_USTRIDE} ${THIS_TIME}

    fi
    if [ "${f}" == "${fbookend}" ]; then break ; fi
    thissetrunning=${fpairhi}
    let nthisset_univ=${nthisset_univ}+${fpairhi}-${fpairlo}+1
  done # loop over files


  if [ -z "${thissetmissing}" -a ${nthisset_univ} -eq ${EXPECTED_UNIV} ]; then
    if [ ${SHOWOK} -ne 0 ]; then
      echo -e "${OUTGREEN}${exptsetup} range [${thissetfirst}:${thissetlast}] -- ${nthisset_univ} universes${OUTNOCOL}"
      echo ${exptsetup} >> ${GOODLIST}
    fi
  else
#    let nmiss=${NHIST_SHORTCUT}-${nhist}
     # possible missing on the tail end ... now w/ bookend
#    if [ ${thissetnext} -ne ${EXPECTED_UNIV} ]; then
#       echo "#===> missing tail thissetnext ${thissetnext} " >> ${SUBMITLIST}
#       # case of _none_ found
#       if [ ${thissetnext} -lt 0 ]; then thissetnext=0 ; fi
#       if [ ${thissetnext} -gt ${EXPECTED_UNIV} ]; then thissetnext=0 ; fi
#       let missinghi=${EXPECTED_UNIV}-1
#       gen_submit ${thissetnext} ${missinghi} ${USTRIDE}
#    fi
    echo -e "${OUTRED}${exptsetup} range [${thissetfirst}:${thissetlast}] -- ${nthisset_univ} universes"
    echo "########################################" >> ${SUBMITLIST}
    echo "# ${exptsetup} ${thissetmissing}"         >> ${SUBMITLIST}
    echo "########################################" >> ${SUBMITLIST}
    echo "" >> ${SUBMITLIST}
    echo ${thissetmissing} | tr " " "\n"
    echo -e "${OUTNOCOL}"
  fi
done

echo -e "${OUTORANGE}${nsets_to_submit} sets to submit${OUTNOCOL}"
echo -e "${OUTORANGE}check ${SUBMITLIST}${OUTNOCOL}"
echo -e "${OUTORANGE}check ${GOODLIST}${OUTNOCOL}"

# end-of-script
