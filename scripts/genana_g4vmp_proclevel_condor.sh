#! /usr/bin/env bash
#
#  A script for running artg4tk in the Geant4 Varied Model Parameter environment
#  see:  https://cdcvs.fnal.gov/redmine/projects/g4mps/wiki/Phase2_App_01052016
#
##############################################################################
export THISFILE="$0"
export b0=`basename $0`
export SCRIPT_VERSION=2019-02-05
echo "script version ${SCRIPT_VERSION} ${THISFILE}"
#
#export TARBALL_DEFAULT_DIR=/pnfs/geant4/persistent/rhatcher
export TARBALL_DEFAULT_DIR=/pnfs/geant4/resilient/rhatcher
###
#export TARBALL=localProducts_runartg4tk_v0_03_00_e15_prof_2018-03-21.tar.bz2
#export TARBALL=localProducts_runartg4tk_v0_03_00_e15_prof_2018-04-05.tar.bz2
#export TARBALL=localProducts_runartg4tk_v09_00_00_e17_prof_2019-01-04.tar.bz2
#export  TARBALL=localProducts_runartg4tk_v09_00_00_e17_prof_2019-01-10.tar.bz2
export  TARBALL=localProducts_runartg4tk_v09_00_00_e17_prof_2019-02-05.tar.bz2
#    unrolls to localProducts_runartg4tk_v9_00_00_e17_prof/...

export  TARBALL_DOSSIER=dossier_files.2018-12-13.tar.gz
# 0 = use dossier directly
# 1 = try to get tarball, unroll locally (fallback to 2)
# 2 = use home.fnal.gov/~rhatcher
export UNROLLED_DOSSIER=1

# these need process_args opts
export BOOTSTRAP_SCRIPT="bootstrap_ups.sh"
# semicolon separated things to setup after unrolling tarball
#   BASE=from tarball name
#   product%version%qualifiers
export SETUP_PRODUCTS="BASE;ifdhc%%"
# not necessary:   export SETUP_PRODUCTS="artg4tk%v09_00_00%e17:prof;BASE;ifdhc%%"

# how verbose this script should be
export VERBOSE=0
# if not running on condor worker node, use available scratch space
# non-condor jobs can override with --scratch flag
### apparently /scratch isn't writable [ugh]
### export FAKESCRATCHBASE=/scratch/${USER}
export FAKESCRATCHBASE=/geant4/data/${USER}
# don't change these
export USINGFAKESCRATCH=0
export KEEPSCRATCH=1
# actually run the art command?
export RUNART=1

# base directory for returning results
# art files with s$persistent$scratch$g
export OUTPUTTOP="/pnfs/geant4/persistent/rhatcher/genana_g4vmp"

# output of running art in separate .out and .err files?
export REDIRECT_ART=1

export UPS_OVERRIDE="-H Linux64bit+2.6-2.12"

#### a particular choice for defaults

export MULTIVERSE=multiverse181212_Bertini        # e.g. (fcl base)
export MULTI_UNIVERSE_SPEC="${MULTIVERSE},0,10"   # each job (process) in cluster does 10 universes, start 0
export G4HADRONICMODEL=Bertini  #  e.g. Bertini
export UBASE=0                  #  0=Default, others are RandomUniv[xxxx]
export USTRIDE=1                #  how many to do in this $PROCESS unit, 10
export PROBE=piminus            #  allow either name or pdg
export P3=0,0,5.0               #  GeV
#export PROBEP=5.0              #   e.g. 5.0 6.5  # (GeV)
export TARGET=Cu                #  e.g. Cu
export NEVENTS=5000000          #  e.g. 500,000, 500000 -> 5000000
export JOBOFFSET=0              #  offset PROCESS # by this

# not yet supported ...
export PASS=0                   # allow for multiple passes (more events) of same config
                                #  though this requires summming _art_ files, and doing analysis again

export DOSSIER_LIST="HARP,ITEP"

export G4VERBOSITY=0

export RNDMSEED_SPECIAL=123456789
export RNDMSEED=${RNDMSEED_SPECIAL} # will override w/ JOBID number or command line flag
export JOBIDOFFSET=0

#
##############################################################################
function usage() {
cat >&2 <<EOF
Purpose:  Run 'artg4tk' w/ the Geant4 Varied Model Parameter setup
          version ${SCRIPT_VERSION}

  ${b0} --output <output-path> [other options]

     -h | --help                  this helpful blurb
     -v | --verbose               increase script verbosity

     -o | --output <path>         path to top of output area
                                  (creates subdir for the results)
                                  [${OUTPUTTOP}]

     -n | --nevents <nevents>     # of events to generate (single job) [${NEVENTS}]

     -u | --universes <fname>,[ubase=0],[ustride=10]
                                  ART PROLOG file with multiple universes
                                  [/path/]filename[,ubase[,ustride]]
                                  umin = ubase + \${PROCESS}*ustride
                                  umax = umin  + ustride - 1
                                  [${MULTI_UNIVERSE_SPEC}]
                                  ( so for 1000 universes, use cluster -N 100 and 0,10 here )

     -p | --physics <model>       G4 Hadronic Model name [${G4HADRONICMODEL}]

     -t | --target <nucleus>      target nucleus element (e.g. "Pb") [${TARGET}]
     -c | --pdg | --probe <code>  incident particle pdg code [${PROBE}]
          --p3 <px,py,pz>         incident particle 3-vector
     -z | --pz <pz>               incident particle p_z (p_x=p_y=0)
                                  [ ${PROBE_PX}, ${PROBE_PY}, ${PROBE_PZ} ] // in GeV/c

          --g4verbose <int>       set G4 verbosity [${G4VERBOSITY}]

          --seed <int-val>        explicitly set random seed
                                  (otherwise based on PASS)

     -x | --pass <int>            set pass (default 0)

     -T | --tarball <tball>       name of tarball to fetch

     -P | --pname <pname>         ART process name [${ARTPNAME}]

 Experts:

     --scratchbase <path>       if \${_CONDOR_SCRATCH_DIR} not set (i.e. not
                                running as a condor job on a worker node)
                                then try creating an area under here
                                [${FAKESCRATCHBASE}]
     --keep-scratch             don't delete the contents of the scratch
                                area when using the above [${KEEPSCRATCH}]

     --no-redirect-output       default is to redirect ART output to .out/.err
                                if set then leave them to stdout/stderr
     --no-art-run               skip the actual running of ART executable


     --debug                    set verbose=999

EOF
}

#
##############################################################################
function process_args() {

  PRINTUSAGE=0

  DOTRACE=`echo "$@" | grep -c -- --trace`
  ISDEBUG=`echo "$@" | grep -c -- --debug`
  if [ $DOTRACE -gt 0 ]; then set -o xtrace ; fi
  if [ $ISDEBUG -gt 0 ]; then VERBOSE=999 ; fi
  if [ $ISDEBUG -gt 0 ]; then echo "pre-getopt  \$#=$#  \$@=\"$@\"" ; fi

  # longarg "::" means optional arg, if not supplied given as null string
  # use this for targfile lowth peanut
  TEMP=`getopt -n $0 -s bash -a \
     --longoptions="help verbose output: \
                    nevts: nevents: \
                    universe: universes: physics: model: hadronic: \
                    target: pdg: probe: p3: pz: g4verbose: seed: joboffset: \
                    tarball: pname: pass: \
                    scratchbase: keep-scratch \
                    no-redirect-output no-art-run no-run-art skip-art \
                    debug trace" \
     -o hvo:n:u:p:m:t:c:z:j:x:T:P:-: -- "$@" `
  eval set -- "${TEMP}"
  if [ $ISDEBUG -gt 0 ]; then echo "post-getopt \$#=$#  \$@=\"$@\"" ; fi
  unset TEMP

  let iarg=0
  while [ $# -gt 0 ]; do
    let iarg=${iarg}+1
    if [ $VERBOSE -gt 2 ]; then
      printf "arg[%2d] processing \$1=\"%s\" (\$2=\"%s\")\n" "$iarg" "$1" "$2"
    fi
    case "$1" in
      "--"                 ) shift;                           break  ;;
      -h | --help          ) PRINTUSAGE=1                            ;;
      -v | --verbose       ) let VERBOSE=${VERBOSE}+1                ;;
#
      -o | --out*          ) export OUTPUTTOP="$2";           shift  ;;
      -n | --nev*          ) export NEVENTS="$2";             shift  ;;
      -u | --univ*         ) export MULTI_UNIVERSE_SPEC="$2"; shift  ;;
      -p | --physics | \
      -m | --model   | \
           --hadronic      ) export G4HADRONICMODEL="$2";     shift  ;;
      -t | --target        ) export TARGET="$2";              shift  ;;
      -c | --pdg | --probe ) export PROBE="$2";               shift  ;;
           --p3            ) export P3="$2";                  shift  ;;
      -z | --pz            ) export P3="0,0,$2";              shift  ;;
           --g4verbose     ) export G4VERBOSE="$2";           shift  ;;
           --seed          ) export RNDMSEED="$2";            shift  ;;
      -j | --joboffset     ) export JOBOFFSET="$2";           shift  ;;
      -x | --pass          ) export PASS="$2";                shift  ;;
#
      -T | --tarball       ) export TARBALL="$2";             shift  ;;
      -P | --pname         ) export ARTPNAME="$2";            shift  ;;
#
           --scratch*      ) export FAKESCRATCHBASE="$2";     shift  ;;
           --keep-scratch  ) export KEEPSCRATCH=1;                   ;;
           --no-redir*     ) export REDIRECT_ART=0;                  ;;
           --no-art*    | \
           --no-run-art | \
           --skip-art      ) export RUNART=0;                        ;;
           --debug         ) export VERBOSE=999                      ;;
           --trace         ) export DOTRACE=1                        ;;
      -*                   ) echo "unknown flag $opt ($1)"
                             usage
                             ;;
     esac
     shift  # eat up the arg we just used
  done
  usage_exit=0

  # must have a tarball
  # but don't check if user asked for --help
  if [ ${PRINTUSAGE} == 0 ]; then
    if [[ -z "${TARBALL}" ]]
    then
      echo -e "${OUTRED}You must supply values for:${OUTNOCOL}"
      echo -e "${OUTRED}   --tarball   ${OUTNOCOL}[${OUTGREEN}${TARBALL}${OUTNOCOL}]"
      usage_exit=42
    fi
  fi

  # figure out which universes
  if [ -z "${PROCESS}" ]; then PROCESS=0; fi  # not on the grid as a job
  let JOBID=${PROCESS}+${JOBOFFSET}
  export JOBID

  # convert spaces, tabs, [semi]colons to commas
  MULTI_UNIVERSE_SPEC=`echo ${MULTI_UNIVERSE_SPEC} | tr " \t:;" ","`
  MULTI_UNIVERSE_SPEC="${MULTI_UNIVERSE_SPEC},,,"
  MULTIVERSE_BASE=`echo ${MULTI_UNIVERSE_SPEC} | cut -d',' -f1 `   #
  MULTIVERSE_BASE=`basename ${MULTIVERSE_BASE} .fcl`               # to be found in tarball w/ .fcl extension
  MULTIVERSE_FILE=${MULTIVERSE_BASE}.fcl
  UBASE=`echo ${MULTI_UNIVERSE_SPEC} | cut -d',' -f2`
  # if uspecified UBASE=0
  if [ -z "${UBASE}" ]; then UBASE=0; fi
  USTRIDE=`echo ${MULTI_UNIVERSE_SPEC} | cut -d',' -f3`
  # if unspecified USTRIDE=10
  if [ -z "${USTRIDE}" ]; then USTRIDE=10; fi

  let UNIV_FIRST=${JOBID}*${USTRIDE}+${UBASE}   # 0 based counting
  let UNIV_LAST=${UNIV_FIRST}+${USTRIDE}-1
  echo -e "${OUTCYAN}PROCESS=${PROCESS} (JOBOFFSET=${JOBOFFSET}) use UNIVERSES [${UNIV_FIRST}:${UNIV_LAST}]${OUTNOCOL}"

  # noramlize probe specified by user ...
  export PROBENAME=XYZZY          #  e.g. piplus, piminus, proton
  export PROBEPDG=XYZZY           #  e.g. 211,    -211,    2212

  case ${PROBE} in
      11 | eminus    ) export PROBEPDG=11   ; export PROBENAME=eminus    ;;
     -11 | eplus     ) export PROBEPDG=-11  ; export PROBENAME=eplus     ;;
      13 | muminus   ) export PROBEPDG=13   ; export PROBENAME=muminus   ;;
     -13 | muplus    ) export PROBEPDG=-13  ; export PROBENAME=muplus    ;;
     111 | pizero    ) export PROBEPDG=111  ; export PROBENAME=pizero    ;;
     211 | piplus    ) export PROBEPDG=211  ; export PROBENAME=piplus    ;;
    -211 | piminus   ) export PROBEPDG=-211 ; export PROBENAME=piminus   ;;
     130 | kzerolong ) export PROBEPDG=130  ; export PROBENAME=kzerolong ;;
     311 | kzero     ) export PROBEPDG=311  ; export PROBENAME=kzero     ;;
     321 | kplus     ) export PROBEPDG=321  ; export PROBENAME=kplus     ;;
    -321 | kminus    ) export PROBEPDG=-321 ; export PROBENAME=kminus    ;;
    2212 | proton    ) export PROBEPDG=2212 ; export PROBENAME=proton    ;;
    2112 | neutron   ) export PROBEPDG=2112 ; export PROBENAME=neutron   ;;
    *                )
       echo -e "${OUTRED}bad PROBE=${PROBE}${OUTNOCOL}" ; exit 42 ;;
  esac

  # normalize momentum is user set
  # turn most punctuation (except ".") into space
  # strip leading space
  if [ -n "${P3}" ]; then
    #echo "initial P3 ${P3}"
    P3=`echo "${P3},0.0,0.0,0.0" | tr "\[\],:;\"\t" " " | sed -e 's/^ *//' `
    #echo "final ${P3}"
    export PROBE_PX=`echo ${P3} | cut -d' ' -f1`
    export PROBE_PY=`echo ${P3} | cut -d' ' -f2`
    export PROBE_PZ=`echo ${P3} | cut -d' ' -f3`
    if [ ${VERBOSE} -gt 0 ]; then
      echo -e "${OUTGREEN}using px py pz: ${PROBE_PX} ${PROBE_PY} ${PROBE_PZ} ${OUTNOCOL}"
    fi
  else
    if [ -n "${PROBEP}" ]; then
      export PROBE_PX=0
      export PROBE_PY=0
      export PROBE_PZ=${PROBEP}
    else
      echo -e "${OUTRED}no \${P3} or \${PROBEP} given ${OUTNOCOL}"
      usage_exit=42
    fi
  fi
  if [ ${usage_exit} -eq 0 ]; then
    # calculate projectile total momentum
    px=${PROBE_PX}
    py=${PROBE_PY}
    pz=${PROBE_PZ}

    # calculate momentum ... 1 digit after decimal point
    probepcalc="sqrt(($px*$px)+($py*$py)+($pz*$pz))"
    export PROBEP5=`echo  "scale=5; ${probepcalc}" | bc`
    echo -e "${OUTGREEN}bc scale=5; ${probepcalc} ==> ${PROBEP5}${OUTNOCOL}"
    # 1 or 2 digits after the decimal point (printf should round for us)
    # but strip trailing 0's, and no bare trail .'s
    export PROBEP=`printf "%0.2f" ${PROBEP5} | sed -e 's/0*$//' -e 's/\.$//' `
    echo -e "${OUTGREEN}calculated \${PROBEP}=${PROBEP} GeV${OUTNOCOL}"
    unset px py pz
  fi

  # PROBEPNODOT e.g. 5   6p5
  # used in dossier PROLOGs, should be no trailing 'p0's
  PROBEPNODOT=`echo ${PROBEP} | sed -e 's/\./p/' `

  echo -e "${OUTGREEN}\${PROBE}=${PROBE} : normalized \${PROBENAME}=${PROBENAME} \${PROBEPDG}=${PROBEPDG}${OUTNOCOL}"
  echo -e "${OUTGREEN}\${PROBEP}=${PROBEP} \${PROBENODOT}=${PROBEPNODOT}${OUTNOCOL}"

  # show the defaults correctly now
  if [ $PRINTUSAGE -gt 0 -o ${usage_exit} -ne 0 ]; then
    echo " "
    usage
    if [ $PRINTUSAGE -gt 1 ]; then
      extended_help
    fi
    exit ${usage_exit}
  fi

  # any left over non-flag args
  export OPTARGS="$@"
  if [ ${VERBOSE} -gt 2 ]; then
    echo "OPTARGS=${OPTARGS}"
  fi

}

##############################################################################
function fetch_setup_tarball() {
  # fetch the tarball, use it to setup environment including its own products

  # full path given ??
  export TARBALL_IN=${TARBALL}
  c1=`echo ${TARBALL_IN} | cut -c1`
  if [ "$c1" != "/" ]; then TARBALL=${TARBALL_DEFAULT_DIR}/${TARBALL_IN} ; fi
  TARBALL_BASE=`basename ${TARBALL}`

  # if we can see it then use cp, otherwise "ifdh cp"
  if [ -f ${TARBALL} ]; then
    CP_CMD="cp"
  else
    which_ifdh=`which ifdh 2>/dev/null`
    if [ -z "${which_ifdh}" ]; then
      source /cvmfs/fermilab.opensciencegrid.org/products/common/etc/setup
      setup ifdhc
    fi
    CP_CMD="ifdh cp"
    export IFDH_CP_MAXRETRIES=1  # 8 is crazytown w/ exponential backoff
  fi
  echo ""

  # local dossier is "optional"
  if [ ${UNROLLED_DOSSIER} -eq 1 ]; then

    # full path given ??
    c1=`echo ${TARBALL_DOSSIER} | cut -c1`
    if [ "$c1" != "/" ]; then TARBALL_DOSSIER=${TARBALL_DEFAULT_DIR}/${TARBALL_DOSSIER} ; fi
    TARBALL_DOSSIER_BASE=`basename ${TARBALL_DOSSIER}`
    echo -e "${OUTGREEN}tarball:  ${TARBALL_DOSSIER}${OUTNOCOL}"
    echo -e "${OUTGREEN}base:     ${TARBALL_DOSSIER_BASE}${OUTNOCOL}"

    echo -e "${OUTGREEN}${CP_CMD} ${TARBALL_DOSSIER} ${TARBALL_DOSSIER_BASE}${OUTNOCOL}"
    ${CP_CMD} ${TARBALL_DOSSIER} ${TARBALL_DOSSIER_BASE}
    echo "${CP_CMD} status $?"
    if [ ! -f ${TARBALL_DOSSIER_BASE} ]; then
      echo -e "${OUTRED}failed to fetch:  ${TARBALL_DOSSIER_BASE}${OUTNOCOL}"
    else
      case ${TARBALL_DOSSIER_BASE} in
         *.gz | *.tgz ) TAR_OPT="z" ;;
         *.bz2        ) TAR_OPT="j" ;;
         *     ) echo -e "${OUTRED}neither .gz nor .bz2 file extension: ${TARBALL_DOSSIER_BASE}${OUTNOCOL}"
                 TAR_OPT="z" ;;
      esac
      # unroll
      echo -e "${OUTCYAN}tar x${TAR_OPT}f ${TARBALL_DOSSIER_BASE}${OUTNOCOL}"
      tar x${TAR_OPT}f ${TARBALL_DOSSIER_BASE}
      if [ $? -ne 0 ]; then
        # failed to unroll, use fallback approach
        export UNROLLED_DOSSIER=2
      fi
    fi
  fi

  # now the real important tarball w/ UPS product
  echo -e "${OUTGREEN}in as:    ${TARBALL_IN}${OUTNOCOL}"
  echo -e "${OUTGREEN}tarball:  ${TARBALL}${OUTNOCOL}"
  echo -e "${OUTGREEN}base:     ${TARBALL_BASE}${OUTNOCOL}"

  echo -e "${OUTGREEN}${CP_CMD} ${TARBALL} ${TARBALL_BASE}${OUTNOCOL}"
  ${CP_CMD} ${TARBALL} ${TARBALL_BASE}
  echo "${CP_CMD} status $?"
  ls -l
  if [ ! -f ${TARBALL_BASE} ]; then
    echo -e "${OUTRED}failed to fetch:  ${TARBALL_BASE}${OUTNOCOL}"
  fi

  case ${TARBALL_BASE} in
     *.gz | *.tgz ) TAR_OPT="z" ;;
     *.bz2        ) TAR_OPT="j" ;;
     *     ) echo -e "${OUTRED}neither .gz nor .bz2 file extension: ${TARBALL_BASE}${OUTNOCOL}"
             TAR_OPT="z" ;;
  esac

  echo -e "${OUTCYAN}looking for ${BOOTSTRAP_SCRIPT}${OUTNOCOL}"
  # expect to find script "${BOOTSTRAP_SCRIPT}"
  bootscript=`tar t${TAR_OPT}f ${TARBALL_BASE} | grep ${BOOTSTRAP_SCRIPT} | tail -1`
  localarea=`echo ${bootscript} | cut -d'/' -f1`
  echo -e "${OUTGREEN}bootscript=${bootscript}${OUTNOCOL}"
  echo -e "${OUTGREEN}localarea=${localarea}${OUTNOCOL}"

  # unroll
  echo -e "${OUTCYAN}tar x${TAR_OPT}f ${TARBALL_BASE}${OUTNOCOL}"
  tar x${TAR_OPT}f ${TARBALL_BASE}
  if [ -z "${bootscript}" -o ! -f ${bootscript} ]; then
     echo -e "${OUTRED}no file ${bootscript} (${BOOTSTRAP_SCRIPT}) in tarball ${TARBALL}${OUTNOCOL}"
     exit 42
  fi
  source ${bootscript}
  export PRODUCTS=`pwd`/${localarea}:${PRODUCTS}

  for prd in `echo ${SETUP_PRODUCTS} | tr ';' ' '` ; do
    if [ -z "$prd" ]; then continue; fi
    if [ "$prd" == "BASE" ]; then
      PROD=`echo ${localarea} | cut -d'_' -f2`
      VERSIONS=`ls -1 ${localarea}/${PROD} | grep -v version `
      for vtest in ${VERSIONS} ; do
        if [[ ${localarea} =~ .*${PROD}_${vtest}_.* ]]; then
          VERS=$vtest
          break
        fi
      done
      QUAL=`echo ${localarea} | sed -e "s/${PROD}_${VERS}/ /g" | cut -d' ' -f2 | tr '_' ':'`
    else
      PROD=`echo ${prd}%% | cut -d "%" -f1`
      VERS=`echo ${prd}%% | cut -d "%" -f2`
      QUAL=`echo ${prd}%% | cut -d "%" -f3`
    fi
    if [ -n "${QUAL}" ]; then
      echo -e "${OUTCYAN}setup ${PROD} ${VERS} -q ${QUAL}${OUTNOCOL}"
      setup ${PROD} ${VERS} -q ${QUAL}
    else
      echo -e "${OUTCYAN}setup ${PROD} ${VERS}${OUTNOCOL}"
      setup ${PROD} ${VERS}
    fi
  done

  export MYMKDIRCMD="ifdh mkdir_p"
  export MYCOPYCMD="ifdh cp"
  # IFDH_CP_MAXRETRIES: maximum retries for copies on failure -- defaults to 7
  export IFDH_CP_MAXRETRIES=2  # 7 is silly
  # if STDOUT is a tty, then probably interactive use
  # avoid the "ifdh" bugaboo I'm having testing interactively
  if [ -t 1 ]; then
    export MYMKDIRCMD="mkdir -p"
    export MYCOPYCMD="cp"
  fi
  echo -e "${OUTGREEN}using \"${MYCOPYCMD}\" for copying${OUTNOCOL}"
  echo -e "${OUTGREEN}using \"${MYMKDIRCMD}\" for mkdir${OUTNOCOL}"

}
#
##############################################################################
function fetch_file() {
  # make local copies of files from (presumably) PNFS
  # relative to ${OUTPUTTOP}
  fgiven=$1
  fbase=`basename $fgive`
  fsrc=${OUTPUTTOP}/${fgiven}
  if [ -f ${fbase} ]; then
    echo -e "${OUTRED}${fbase} already exists locally ... odd"
  else
    ${MYCOPYCMD} ${fsrc} ${fbase}
    status=$?
    if [[ ${status} -ne  0 || ! -f ${fbase} ]]; then
      echo -e "${OUTRED}copy of ${fsrc} failed status=${status}"
    fi
  fi
}

##############################################################################
function make_genana_fcl() {

echo -e "${OUTCYAN}`pwd`${OUTNOCOL}"
echo -e "${OUTCYAN}creating ${CONFIGFCL}${OUTNOCOL}"

export CONFIGFCL=${CONFIGBASE}.fcl

# needs to loop over universes
cat > ${CONFIGFCL} <<EOF
# this is ${CONFIGFCL}
#
# MULTIVERSE        e.g. multiverse181212_Bertini  (fcl base) [${MULTIVERSE}]
# G4HADRONICMODEL   e.g. Bertini                              [${G4HADRONICMODEL}]
# PROBENAME         e.g. piplus, piminus, proton              [${PROBENAME}]
# PROBEPDG          e.g. 211,    -211,    2212                [${PROBEPDG}]
# PROBEP            e.g. 5.0 6.5   # (GeV)                    [${PROBEP}]
# PROBEPNODOT       e.g. 5   6p5   # used in dossier PROLOGs,
#                                  # but, no trailing 'p0's   [${PROBEPNODOT}]
# TARGET            e.g. Cu                                   [${TARGET}]
# NEVENTS           e.g. 5000                                 [${NEVENTS}]

##### these are cases where both HARP & ITEP have data
##### otherwise we _have_ to generate fcl file based on which expt has data
#       2 piminus_on_C_at_5GeV
#       2 piminus_on_Cu_at_5GeV
#       2 piminus_on_Pb_at_5GeV
#       2 piplus_on_C_at_3GeV
#       2 piplus_on_C_at_5GeV
#       2 piplus_on_Cu_at_3GeV
#       2 piplus_on_Cu_at_5GeV
#       2 piplus_on_Pb_at_3GeV
#       2 piplus_on_Pb_at_5GeV
#####


#include "${MULTIVERSE}.fcl"
#include "HARP_dossier.fcl"
#include "ITEP_dossier.fcl"

process_name: genanaX${CONFIGBASESMALL}

source: {

   module_type: EmptyEvent
   maxEvents: ${NEVENTS}

} # end of source:

services: {

   message: {
      debugModules : ["*"]
      suppressInfo : []
      destinations : {
         LogToConsole : {
            type : "cout"
            threshold : "DEBUG"
            categories : { default : { limit : 50 } }
         } # end of LogToConsole
      } # end of destinations:
   } # end of message:

   RandomNumberGenerator: {}
   TFileService: {
      fileName: "${CONFIGBASE}.hist.root"
   }

   ProcLevelSimSetup: {
      HadronicModelName:  "${G4HADRONICMODEL}"
      TargetNucleus:  "${TARGET}"
      RNDMSeed:  1
   }
   # leave this on ... documentation of what was set
   PhysModelConfig: { Verbosity: true }

} # end of services:

outputs: {

   outroot: {
      module_type: RootOutput
      fileName: "${CONFIGBASE}.artg4tk.root"
   }

} # end of outputs:

physics: {

   producers: {

      PrimaryGenerator: {
         module_type: EventGenerator
         nparticles : 1
         pdgcode:  ${PROBEPDG}
         momentum: [ 0.0, 0.0, ${PROBEP} ] // in GeV
      }

EOF

for univ in ${UNIVERSE_NAMES}; do
   printf "      %-25s : @local::%s\n" ${univ} ${univ} >> ${CONFIGFCL}
done

cat >> ${CONFIGFCL} << EOF

   } # end of producers:

   analyzers: {

EOF

for univ in ${UNIVERSE_NAMES}; do
  for expt in ${EXPT_MATCH}; do
cat >> ${CONFIGFCL} << EOF
     ${univ}${expt}:
     {
        module_type: Analyzer${expt}
        ProductLabel: "${univ}"
        IncludeExpData:
        {
            DBRecords:  @local::${expt}_${EXPTSETUP_BASE}
EOF
   if [ ${UNROLLED_DOSSIER} -eq 1 ]; then
cat >> ${CONFIGFCL} << EOF
            # local dossier files
            BaseURL:   "./dossier_files"
            DictQuery: "/dictionary/dictionary_%s.json"
            RecQuery:  "/records/rec_%06d.json"
EOF
   fi
   if [ ${UNROLLED_DOSSIER} -eq 2 ]; then
cat >> ${CONFIGFCL} << EOF
            # local dossier files
            BaseURL:   "http://home.fnal.gov/~rhatcher/dossier_files"
            DictQuery: "/dictionary/dictionary_%s.json"
            RecQuery:  "/records/rec_%06d.json"
EOF
   fi
cat >> ${CONFIGFCL} << EOF
        }
     }

EOF
  done
done

cat >> ${CONFIGFCL} << EOF
   } # end of analyzers:

   path1:     [ PrimaryGenerator
EOF

for univ in ${UNIVERSE_NAMES}; do
   printf "              , %s\n" ${univ} >> ${CONFIGFCL}
done

cat >> ${CONFIGFCL} << EOF
              ] // end-of path1

   path2:     [
EOF

char=" "
for univ in ${UNIVERSE_NAMES}; do
  for expt in ${EXPT_MATCH}; do
   printf "              %s %s\n" "$char" ${univ}${expt} >> ${CONFIGFCL}
   char=","
  done
done

cat >> ${CONFIGFCL} << EOF
              ] // end-of path2

   stream1:       [ outroot ]
   trigger_paths: [ path1 ]
   end_paths:     [ path2, stream1 ]

} # end of physics:
EOF


}

#
##############################################################################
function print_universe_names() {

echo ""
if [ $NUNIV -lt 20 ]; then
  echo -e "${OUTGREEN}${UNIVERSE_NAMES}"
else
  # need to enclose in ""'s so as to retain \n's
  echo -e "${OUTGREEN} (first and last 5):"
  echo "${UNIVERSE_NAMES}" | head -n 5
  echo "..."
  echo "${UNIVERSE_NAMES}" | tail -n 5
fi
echo -e "${OUTNOCOL}"

}

#
##############################################################################
function infer_universe_names() {
#
# create a list of universe names based on configurations in the
# ${MULTI_UNIVERSE_FILE}, entries in which should look like:
#
#   <label> : {
#       module_type:  ProcLevelMPVaryProducer
#       Verbosity: ...
#       HadronicModel: {
#           DefaultPhysics:  {true|false}
#           ModelParameters: {
#              <variable1> : <value1>
#              <variable2> : <value2>
#           }
#       }
#   }
#
# each of those <label>s is a "universe" ... we need their names.
# (assume ":" & "{" are on the same line ... and weed out "HadronicModel"
# and "ModelParameters" as our heuristic for label names)
#

# complete list
export UNIVERSE_NAMES=`cat ${LOCAL_MULTIVERSE_FILE} | \
                       grep "{" | grep ":" | \
                       grep -v HadronicModel | \
                       grep -v ModelParameters | \
                       tr -d " :{" `

export NUNIV=`echo "$UNIVERSE_NAMES" | wc -w`
echo " "
if [ ${VERBOSE} -gt 1 ]; then
  echo -e "${OUTGREEN}${NUNIV} universes in ${LOCAL_MULTIVERSE_FILE}${OUTNOCOL}"
  print_universe_names
fi

# 0 based counting
MINU=0
let MAXU=${NUNIV}-1
export MINU
export MAXU

if [ ${VERBOSE} -gt 0 ]; then
  echo -e "${OTUGREEN}initial REQ [${UNIV_FIRST}:${UNIV_LAST}] of [${MINU}:${MAXU}]${OUTNOCOL}"
fi

if [ ${UNIV_FIRST} -lt ${MINU} ]; then UNIV_FIRST=${MINU} ; fi
if [ ${UNIV_LAST}  -gt ${MAXU} ]; then UNIV_LAST=${MAXU} ; fi

if [ ${VERBOSE} -gt 1 ]; then
  echo -e "${OUTGREEN}bounded REQ [${UNIV_FIRST}:${UNIV_LAST}] of [${MINU}:${MAXU}]${OUTNOCOL}"
fi

if [[ ${UNIV_FIRST} -ne ${MINU} || ${UNIV_LAST} -ne ${MAXU} ]] ; then
  # need to trim ...
  let i=-1 # using 0 based counting
  export UNIVERSE_NAMES_FULL=${UNIVERSE_NAMES}
  UNIVERSE_NAMES=""
  for univ in ${UNIVERSE_NAMES_FULL} ; do
    let i=${i}+1
    if [ ${i} -lt ${UNIV_FIRST} ] ; then continue; fi
    if [ ${i} -gt ${UNIV_LAST}  ] ; then break; fi
    if [ -z "${UNIVERSE_NAMES}" ]; then
      export UNIVERSE_NAMES="${univ}"
    else
      export UNIVERSE_NAMES=`echo -e "${UNIVERSE_NAMES}\n${univ}"`
    fi
  done

  NUNIV=`echo "$UNIVERSE_NAMES" | wc -w`
  if [ ${VERBOSE} -gt 1 ]; then
    echo " "
    echo -e "${OUTGREEN}trimmmed to ${NUNIV} universes [${UNIV_FIRST}:${UNIV_LAST}] in ${LOCAL_MULTIVERSE_FILE}${OUTNOCOL}"
    print_universe_names
  fi
fi

}


#
##############################################################################
# find the supplied fcl file in the usual paths
# if found return full path as ${LOCAL_FCL_FILE}
# if not found echo error, set $?=1
function find_fcl_file() {
  FCL_FILE=${1}
  unset LOCAL_FCL_FILE

  # allow for full path and local directory
  for p in `echo "${FHICL_FILE_PATH}:.:/" | tr : "\n" ` ; do
    if [ -f ${p}/${FCL_FILE} ]; then
      export LOCAL_FCL_FILE=${p}/${FCL_FILE}
      break
    fi
  done
  if [[ -z "${LOCAL_FCL_FILE}" || ! -f "${LOCAL_FCL_FILE}" ]] ; then
    echo -e "${OUTRED}failed to find ${FCL_FILE} anywhere${OUTNOCOL}"
    echo -e "${OUTRED}failed to find ${FCL_FILE} anywhere${OUTNOCOL}" >&2
    return 1
  else
    return 0
  fi
}
#
##############################################################################
# use an https://en.wikipedia.org/wiki/Here_document#Unix_shells
# to create file.  un-\'ed $ or back-ticks (`) will be expanded from
# the current environment when run

#
##############################################################################
function setup_colors() {
# if running interactively, allow for color coding
##case "$-" in
##  *i* )
##    # if $- contains "i" then interactive session
# better --- test if stdout is a tty
  if [ -t 1 ]; then
    export ESCCHAR="\x1B" # or \033 # Mac OS X bash doesn't support \e as esc?
    export OUTBLACK="${ESCCHAR}[0;30m"
    export OUTBLUE="${ESCCHAR}[0;34m"
    export OUTGREEN="${ESCCHAR}[0;32m"
    export OUTCYAN="${ESCCHAR}[0;36m"
    export OUTRED="${ESCCHAR}[0;31m"
    export OUTPURPLE="${ESCCHAR}[0;35m"
    export OUTORANGE="${ESCCHAR}[0;33m" # orange, more brownish?
    export OUTLTGRAY="${ESCCHAR}[0;37m"
    export OUTDKGRAY="${ESCCHAR}[1;30m"
    # labelled "light but appear in some cases to show as "bold"
    export OUTLTBLUE="${ESCCHAR}[1;34m"
    export OUTLTGREEN="${ESCCHAR}[1;32m"
    export OUTLTCYAN="${ESCCHAR}[1;36m"
    export OUTLTRED="${ESCCHAR}[1;31m"
    export OUTLTPURPLE="${ESCCHAR}[1;35m"
    export OUTYELLOW="${ESCCHAR}[1;33m"
    export OUTWHITE="${ESCCHAR}[1;37m"
    export OUTNOCOL="${ESCCHAR}[0m" # No Color
  fi
##  ;;
##  * )
##    ESCCHAR=""
##    ;;
##esac
# use as:   echo -e "${OUTRED} this is red ${OUTNOCOL}"
}
##############################################################################

#
##############################################################################
function check_scratch_area() {

# make sure we're in a scratch area
# needed during init so we can write locally before copying to output area
# in case output area is /pnfs
export ORIGINALDIR=`pwd`
if [ -n "${_CONDOR_SCRATCH_DIR}" ]; then
  export USINGFAKESCRATCH=0
  # actually on condor worker node ...
else
  # not on a worker node ... need to pick somewhere else
  _CONDOR_SCRATCH_DIR=${FAKESCRATCHBASE}/fake_CONDOR_SCRATCH_DIR_$$
  export USINGFAKESCRATCH=1
  echo -e "${OUTBLUE}${b0}: fake a \${_CONDOR_SCRATCH_DIR} as ${_CONDOR_SCRATCH_DIR} ${OUTNOCOL}"
  if [ ! -d ${_CONDOR_SCRATCH_DIR} ]; then
    mkdir -p ${_CONDOR_SCRATCH_DIR}
  fi
fi
if [ ! -d ${_CONDOR_SCRATCH_DIR} ]; then
  echo -e "${OUTRED}could not create ${_CONDOR_SCRATCH_DIR}${OUTNOCOL}"
  exit 42
fi
cd ${_CONDOR_SCRATCH_DIR}
}

#
##############################################################################
function check_for_gdml_file()
{
  if [ ! -f ${GDMLFILENAME} ]; then
    echo -e "${OUTRED}${GDMLFILENAME} is not directly available${OUTNOCOL}"
    # ModelParamStudyProducer:G4Default@Construction
    #    doesn't look any place but the named file (i.e. "." unless specified)
##$ find /geant4/app/rhatcher/mrb_work_area/ -name lariat.gdml
##   /geant4/app/rhatcher/mrb_work_area/build_slf6.x86_64/gdml/lariat.gdml
##   /geant4/app/rhatcher/mrb_work_area/srcs/artg4tk/gdml/lariat.gdml

    if [ -f ${MRB_INSTALL}/gdml/${GDMLFILENAME} ]; then
      echo -e "${OUTRED}copy ${GDMLFILENAME} from ${MRB_INSTALL}${OUTNOCOL}"
      cp ${MRB_INSTALL}/gdml/${GDMLFILENAME} .
    else
      if [ -f ${MRB_BUILDDIR}/gdml/${GDMLFILENAME} ]; then
        echo -e "${OUTRED}copy ${GDMLFILENAME} from ${MRB_BUILDDIR}${OUTNOCOL}"
        cp ${MRB_BUILDDIR}/gdml/${GDMLFILENAME} .
      fi
    fi
    echo ""
  fi

}

#
##############################################################################
function report_node_info()
{
  nodeA=`uname -n `
  node1=`uname -n | cut -d. -f1`
  krel=`uname -r`
  ksys=`uname -s`
  now=`date "+%Y-%m-%d %H:%M:%S" `
  if [ -f /etc/redhat-release ]; then
    redh=`cat /etc/redhat-release 2>/dev/null | \
         sed -e 's/Scientific Linux/SL/' -e 's/ Fermi/F/' -e 's/ release//' `
  fi
  echo -e "${b0}:${OUTBLUE} report_node_info at ${now} ${OUTNOCOL}"
  echo "   running on ${nodeA} "
  echo "   OS ${ksys} ${krel} ${redh}"
  echo "   user `id`"
  echo "   uname `uname -a`"
  echo "   PWD=`pwd`"
  echo " "
}

function report_setup()
{
  echo -e "${b0}:${OUTBLUE} report_setup:  script_version ${SCRIPT_VERSION}${OUTNOCOL}"
  echo "   using `which art`"
  echo "   using `which ifdh`"
  echo "   using \${GEANT4_DIR}=${GEANT4_DIR}"
  echo "   \${PRODUCTS}="
  echo ${PRODUCTS} | tr ":" "\n" | sed -e 's/^/     /g'
  echo "   \${LD_LIBRARY_PATH}="
  echo ${LD_LIBRARY_PATH} | tr ":" "\n" | sed -e 's/^/     /g'
  echo "   \${FHICL_FILE_PATH}="
  echo ${FHICL_FILE_PATH} | tr ":" "\n" | sed -e 's/^/     /g'
  echo " "
}

function report_config_summary()
{
  echo -e "${b0}:${OUTBLUE} config_summary ${CONFIGBASE}${OUTNOCOL}"
  echo "   DESTDIR        ${DESTDIR}"
  echo "   DESTDIRART     ${DESTDIRART}"
  echo "   PROCESS        ${PROCESS}"
  echo "   JOBOFFSET      ${JOBOFFSET}"
  echo "   JOBID          ${JOBID}"
  echo "   MULTIVERSE     ${MULTIVERSE} [${UNIV_FIRST}:${UNIV_LAST}]"
  echo "   nevents        ${NEVENTS}"
  echo "   hadronic model ${G4HADRONICMODEL}"
  echo "   target         \"${TARGET}\""
  echo "   probe          ${PROBENAME} (${PROBEPDG}) [ ${PROBE_PX}, ${PROBE_PY}, ${PROBE_PZ} ] GeV/c"
  echo " "
}
##############################################################################


##############################################################################


setup_colors

echo -e "${OUTCYAN}process_args $@ ${OUTNOCOL}"
process_args "$@"

# find our own little place to do this job's processing
# (easy on condor job worker nodes; interactive .. more difficult)
echo -e "${OUTCYAN}check_scratch_area ${OUTNOCOL}"
check_scratch_area

# fetch the tarball that has the work to do
echo -e "${OUTCYAN}fetch_setup_tarball ${OUTNOCOL}"
fetch_setup_tarball

echo -e "${OUTGREEN}currently `pwd`${OUTNOCOL}"
cd ${_CONDOR_SCRATCH_DIR}
echo -e "${OUTGREEN}woring in `pwd`${OUTNOCOL}"

echo -e "${OUTORANGE}JOBID=${JOBID}${OUTNOCOL}"

if [ ${RNDMSEED} -eq ${RNDMSEED_SPECIAL} ]; then
  # user didn't set a seed, set it to the jobid
  echo -e "${OUTORANGE}export RNDMSEED=${RNDMSEED}${OUTNOCOL}"
  #echo -e "${OUTORANGE}export RNDMSEED=${JOBID}${OUTNOCOL}"
  # export RNDMSEED=${JOBID}
fi

if [ "`pwd`" != "${_CONDOR_SCRATCH_DIR}" ]; then
  echo -e "${OUTRED}about to fetch_multiverse but in `pwd`${OUTNOCOL}"
  echo -e "${OUTRED}instead of ${_CONDOR_SCRATCH_DIR}${OUTNOCOL}"
  cd ${_CONDOR_SCRATCH_DIR}
fi

echo -e "${OUTGREEN}looking for ${MULTIVERSE_FILE}${OUTNOCOL}"
# find LOCAL_MULTIVERSE_FILE ... should be in $FHICL_FILE_PATH after setup
find_fcl_file ${MULTIVERSE_FILE}
if [ $? -ne 0 ]; then
  # failed to find the file .. no point going on
  echo -e "${OUTRED}===========>>> ERRROR${OUTNOCOL}"
  echo -e "${OUTRED}... no point in going on.  bail out.${OUTNOCOL}"
  echo -e "${OUTRED}... no point in going on.  bail out.${OUTNOCOL}" >&2
  exit 3
fi
LOCAL_MULTIVERSE_FILE=${LOCAL_FCL_FILE}
echo -e "${OUTGREEN}found ${LOCAL_MULTIVERSE_FILE}${OUTNOCOL}"


# [HARP|ITEP]_${PROBENAME}_on_${TARGET}_at_${PROBEPNODOT}GeV
export EXPTSETUP_BASE=${PROBENAME}_on_${TARGET}_at_${PROBEPNODOT}GeV
echo -e "${OUTCYAN}look for EXPTSETUP_BASE=${EXPTSETUP_BASE}${OUTNOCOL}"
EXPT_MATCH=""
FCL_MATCH=""

for EXPT in `echo ${DOSSIER_LIST} | tr ",;:" " "` ; do
  # find the fcl file
  LOOKFOR=${EXPT}_dossier.fcl
  #echo -e -n "${OUTGREEN}looking for ${LOOKFOR}${OUTNOCOL}"
  LOOKFOR_RESULT=LOCAL_${EXPT}_DOSSIER_FILE
  find_fcl_file ${LOOKFOR}
  if [ $? -ne 0 ]; then
    echo -e "${OUTRED}could not find ${LOOKFOR}${OUTNOCOL}"
    exit 4
  fi
  export LOCAL_${EXPT}_DOSSIER_FILE=${LOCAL_FCL_FILE}

  # "indirect variable reference"  val=${!vnamenam}
  #if [ -z "${!LOOKFOR}" ]; then

  n=`grep -c ${EXPTSETUP_BASE} ${!LOOKFOR_RESULT}`
  case $n in
    0 ) echo -e "${OUTGREEN}found NO instances in ${LOOKFOR}${OUTNOCOL}"
        ;;
    1 ) echo -e "${OUTGREEN}found instance in ${LOOKFOR}${OUTNOCOL}"
        EXPT_MATCH="${EXPT_MATCH} ${EXPT}"
        ;;
    * ) echo -e "${OUTRED}found ${n} instances in ${LOOKFOR}${OUTNOCOL}"
        echo -e "${OUTRED}not unique !!${OUTNOCOL}"
        exit 5
        ;;
  esac
 done

if [ -z "${EXPT_MATCH}" ]; then
  echo -e "${OUTRED}no valid experimental data${OUTNOCOL}"
  exit 6
fi

echo -e "${OUTORANGE}EXPTSETUP valid for ${EXPT_MATCH}${OUTNOCOL}"

infer_universe_names

if [ ${VERBOSE} -gt 1 ]; then
  echo -e "${OUTGREEN}post- infer_universe_names${OUTNOCOL}"
  pwd
  ls -l
  if [ -d 0 ]; then
    echo "what is the 0 directory?"
    ls -l 0
  fi
fi

UNIV_FIRST_4=`printf "%04d" ${UNIV_FIRST}`
UNIV_LAST_4=`printf "%04d" ${UNIV_LAST}`
export CONFIGBASE=${EXPTSETUP_BASE}_U${UNIV_FIRST_4}_${UNIV_LAST_4}
if [ ${PASS} -ne 0 ]; then
  export CONFIGBASE=${CONFIGBASE}_P${PASS}
fi

export CONFIGBASESMALL=`echo ${CONFIGBASE} | sed -e 's/_on_//' -e 's/_at_//' | tr -d '_' `

export DESTDIR=${OUTPUTTOP}/${MULTIVERSE}/${EXPTSETUP_BASE}
export DESTDIRART=`echo $DESTDIR | sed -e 's/persistent/scratch/g'`
echo -e ""
echo -e "${OUTORANGE}CONFIGBASE=${CONFIGBASE}${OUTNOCOL}"
echo -e "${OUTORANGE}CONFIGBASESMALL=${CONFIGBASESMALL}${OUTNOCOL}"

make_genana_fcl

echo -e "${OUTRED}-------------------------------------${OUTNOCOL}"
report_config_summary
report_node_info
report_setup
echo -e "${OUTRED}-------------------------------------${OUTNOCOL}"

#if [ ${VERBOSE} -gt 1 ]; then
  echo -e "${OUTGREEN}contents of ${CONFIGBASE} are:${OUTORANGE}"
  echo "--------------------------------------------------------------------"
  cat ${CONFIGFCL}
  echo "--------------------------------------------------------------------"
  echo -e "${OUTNOCOL}"
  echo " "
#fi

# run the job

# look in current directory for any include fcl files ...
export FHICL_FILE_PATH=${FHICL_FILE_PATH}:.

now=`date "+%Y-%m-%d %H:%M:%S" `
echo -e "${OUTPURPLE}art start  ${now}"
if [ ${RUNART} -ne 0 ]; then
  # HERE'S THE ACTUAL "ART" COMMAND
  if [ ${REDIRECT_ART} -ne 0 ]; then
    echo "art -c ${CONFIGFCL} 1> ${CONFIGBASE}.out 2> ${CONFIGBASE}.err"
          art -c ${CONFIGFCL} 1> ${CONFIGBASE}.out 2> ${CONFIGBASE}.err
          ART_STATUS=$?
  else
    echo "art -c ${CONFIGFCL}"
          art -c ${CONFIGFCL}
          ART_STATUS=$?
  fi
else
  ART_STATUS=255  # didn't run ... can't be 0
fi
now=`date "+%Y-%m-%d %H:%M:%S" `
echo -e "art finish ${now}"
if [ ${ART_STATUS} -eq 0 ]; then
  echo -e "${OUTGREEN}art returned status ${ART_STATUS}${OUTNOCOL}"
else
  echo -e "${OUTRED}art returned status ${ART_STATUS}${OUTNOCOL}"
fi
echo -e "${OUTNOCOL}"

if [[ ${VERBOSE} -gt 1 && ${REDIRECT_ART} -ne 0 ]] ; then
  echo -e "${OUTGREEN}contents of ${CONFIGBASE}.out is:${OUTORANGE}"
  echo "--------------------------------------------------------------------"
  cat ${CONFIGBASE}.out
  echo "--------------------------------------------------------------------"
  echo -e "${OUTGREEN}contents of ${CONFIGBASE}.err is:${OUTORANGE}"
  echo "--------------------------------------------------------------------"
  cat ${CONFIGBASE}.err
  echo "--------------------------------------------------------------------"
  echo -e "${OUTNOCOL}"
  echo " "
fi


# copy files back!
echo -e "${OUTGREEN}start copy back section${OUTNOCOL}"
echo -e "${OUTGREEN}start copy back section${OUTNOCOL}" >&2

${MYMKDIRCMD} ${DESTDIR}
MKDIR_STATUS=$?
if [ ${MKDIR_STATUS} -ne 0 ]; then
  echo -e "${OUTRED}${MYMKDIRCMD} ${DESTDIR} ${OUTNOCOL} returned ${MKDIR_STATUS}${OUTNOCOL}"
fi
if [ "${DESTDIRART}" != "${DESTDIR}" ]; then
  ${MYMKDIRCMD} ${DESTDIRART}
  MKDIR_STATUS=$?
  if [ ${MKDIR_STATUS} -ne 0 ]; then
    echo -e "${OUTRED}${MYMKDIRCMD} ${DESTDIRART} ${OUTNOCOL} returned ${MKDIR_STATUS}${OUTNOCOL}"
  fi
fi
# for ifdh mkdir is there some way to distinguish between
# "couldn't create directory" (permissions, whatever) vs. "already exists"?
# mkdir(2) says EEXIST returned for later
#   /usr/include/asm-generic/errno-base.h:#define EEXIST 17 /* File exists */
# but mkdir run interactively returns 1 ...

localList="${CONFIGBASE}.artg4tk.root ${CONFIGBASE}.hist.root ${CONFIGFCL}"
localList="${localList}"
if [ ${REDIRECT_ART} -ne 0 ]; then
  localList="${localList} ${CONFIGBASE}.out ${CONFIGBASE}.err"
fi

for inFile in ${localList} ; do
  if [ -f ${inFile} ]; then
    DESTDIR1=${DESTDIR}
    if [[ "${inFile}" =~ .*artg4tk.root ]]; then
      DESTDIR1=${DESTDIRART}
    fi
    if [ -s ${inFile} ]; then
      echo -e "${OUTPURPLE}${MYCOPYCMD} ${inFile} ${DESTDIR1}/${inFile}${OUTNOCOL}"
      ${MYCOPYCMD} ${inFile} ${DESTDIR1}/${inFile}
    else
      echo -e "${OUTRED}zero length ${inFile} -- skip copy back${OUTNOCOL}"
    fi
  else
    echo -e "${OUTRED}missing local ${inFile} to copy back${OUTNOCOL}"
  fi
done

echo " "
# clean-up
if [ ${USINGFAKESCRATCH} -ne 0 ]; then
  if [ ${KEEPSCRATCH} -eq 0 ]; then
    echo -e "${OUTBLUE}${b0}: rm -r ${_CONDOR_SCRATCH_DIR} ${OUTNOCOL}"
  #  rm -r ${_CONDOR_SCRATCH_DIR}
  else
    echo -e "${OUTBLUE}${b0}: leaving ${_CONDOR_SCRATCH_DIR} ${OUTNOCOL}"
  fi
fi

echo -e "${OUTBLUE}${b0}: end-of-script${OUTNOCOL}"

exit ${ART_STATUS}
return
set -o xtrace
set +o xtrace
###


# end-of-script
