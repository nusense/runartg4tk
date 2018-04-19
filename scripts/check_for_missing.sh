#! /usr/bin/env bash
#
##############################################################################
export THISFILE="$0"
export b0=`basename $0`
export SCRIPT_VERSION=2018-04-10

export CLEAR_COMPLETE=0  # start fresh w/ ${GOODLIST}?

export OUTPUTTOP="/pnfs/geant4/persistent/rhatcher/genana_g4vmp"
export MULTIVERSE=multiverse170208_Bertini
export USTART=0
export USTRIDE=1 # 10 # stride used for ${SUBMITLIST}
export EXPECTED_UNIV=1000
export FORM="%04d"

# since make-up files might use a different stride we can't count files
#export NHIST_SHORTCUT=99999
export SHOWOK=1

export MRB_SOURCE=/geant4/app/rhatcher/mrb_work_area-2018-03-05/srcs
export SCRIPT=${MRB_SOURCE}/runartg4tk/scripts/genana_g4vmp_proclevel_condor.sh
export TARBALL=localProducts_runartg4tk_v0_03_00_e15_prof_2018-04-05.tar.bz2

export MULTIVERSE=multiverse170208_Bertini        # e.g. (fcl base)
export MULTI_UNIVERSE_SPEC="${MULTIVERSE},0,10"

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

export SCRIPT=/geant4/app/rhatcher/mrb_work_area-2018-03-05/srcs/runartg4tk/scripts/genana_g4vmp_proclevel_condor.sh
export TARBALL=${TARBALL}

export SLEEPTIME=15
export LOGFILE=jobs_to_submit.jobsub.log

function now ()
{
    date "+%Y-%m-%d %H:%M:%S"
}

EOF
chmod +x ${SUBMITLIST}

function gen_submit() {
  blk_start=$1
  blk_last=$2
  blk_stride=$3

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
  CMD1="jobsub_submit -g -N ${blk_sets} file://${SCRIPT} ${ARGS} ${UARG1} --tarball=${TARBALL}"

  if [ ${blk_sets} -gt 0 ]; then
    echo "echo \`now\` ${exptsetup} -N ${blk_sets} ${UARG1}" >> ${SUBMITLIST}
    echo "echo \`now\` ${exptsetup} -N ${blk_sets} ${UARG1} >> \${LOGFILE}" >> ${SUBMITLIST}
    echo "${CMD1} >> \${LOGFILE} 2>&1"   >> ${SUBMITLIST}
    echo "sleep \${SLEEPTIME}" >> ${SUBMITLIST}
  fi
  let nsets_to_submit=${nsets_to_submit}+${blk_sets}

  if [ ${blk_mod} -gt 0 ]; then

    UARG2="--universes ${MULTIVERSE},${blk_start2},${blk_mod}"
    CMD2="jobsub_submit -g -N 1 file://${SCRIPT} ${ARGS} ${UARG2} --tarball=${TARBALL}"

    echo "echo \`now\` ${exptsetup} -N 1 ${UARG2}" >> ${SUBMITLIST}
    echo "echo \`now\` ${exptsetup} -N 1 ${UARG2} >> \${LOGFILE}" >> ${SUBMITLIST}

    echo "${CMD2} >> \${LOGFILE} 2>&1"   >> ${SUBMITLIST}
    echo "sleep \${SLEEPTIME} " >> ${SUBMITLIST}
    let nsets_to_submit=${nsets_to_submit}+1

  fi

  echo "echo ================================================== >> \${LOGFILE}" >> ${SUBMITLIST}

}


DESTDIRTOP=${OUTPUTTOP}/${MULTIVERSE}
for d in ${DESTDIRTOP}/* ; do
#for d in ${DESTDIRTOP}/piminus_on_Pb_at_12GeV ${DESTDIRTOP}/piplus_on_C_at_5GeV ; do
#for d in ${DESTDIRTOP}/piplus_on_C_at_5GeV ${DESTDIRTOP}/piplus_on_Be_at_5GeV ${DESTDIRTOP}/proton_on_U_at_8p5GeV ; do
#  mkdir -p $d

  if [ ! -d ${d} ]; then continue; fi
  exptsetup=`basename ${d}`
  # skip funky directories
  if [[ "${d}" =~ .*_save ]]; then continue ; fi
  if [[ "${d}" =~ .*_nohist ]]; then continue ; fi
  if [[ "${d}" =~ .*_bleck ]]; then continue ; fi

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
  thissetrunning=-1
  thissetnext=0
  thissetmissing=""
  nthisset_univ=0

  fbookend=${d}/${exptsetup}_U1000_9999.hist.root

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

    if [ ${fpairlo} -lt ${thissetfirst} ]; then thissetfirst=${fpairlo} ; fi
    if [ ${fpairhi} -ge ${thissetlast}  ]; then thissetlast=${fpairhi}  ; fi

    let thissetnext=${thissetrunning}+1
    if [ ${fpairlo} -ne ${thissetnext} ]; then
       let missinghi=${fpairlo}-1
       thissetmissing="${thissetmissing} [${thissetnext}:${missinghi}]"

       gen_submit ${thissetnext} ${missinghi} ${USTRIDE}

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
