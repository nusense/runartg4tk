#! /usr/bin/env bash
#
#  A script for running artg4tk in the Geant4 Varied Model Parameter environment
#  see:  https://cdcvs.fnal.gov/redmine/projects/g4mps/wiki/Phase2_App_01052016
#
##############################################################################
export THISFILE="$0"
export b0=`basename $0`
export SCRIPT_VERSION=2018-03-19
#
###
export TARBALL=localProducts_runartg4tk_v0_03_00_e15_prof_2018-03-12.tar.bz2
#  unrolls to  localProducts_runartg4tk_v0_03_00_e15_prof/...
export TARBALL_DEFAULT_DIR=/pnfs/geant4/persistent/rhatcher/

# these need process_args opts
export BOOTSTRAP_SCRIPT="bootstrap_ups.sh"
# semicolon separated things to setup after unrolling tarball
#   BASE=from tarball name
#   product%version%qualifiers
export SETUP_PRODUCTS="BASE;ifdhc%%"
# not necessary:   export SETUP_PRODUCTS="artg4tk%v5_00_00%e15:prof;BASE;ifdhc%%"

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
export OUTPUTTOP="/pnfs/geant4/persistent/rhatcher/genana_g4vmp"

# output of running art in separate .out and .err files?
export REDIRECT_ART=1

export UPS_OVERRIDE="-H Linux64bit+2.6-2.12"

#### a particular choice for defaults

export MULTIVERSE=multiverse170208_Bertini        # e.g. (fcl base)
export MULTI_UNIVERSE_SPEC="${MULTIVERSE},0,10"   # each job (process) in cluster does 10 universes, start 0
export G4HADRONICMODEL=Bertini  #  e.g. Bertini
export UBASE=0                  #  0=Default, others are RandomUniv[xxxx]
export USTRIDE=10               #  how many to do in this $PROCESS unit
export PROBE=piminus            #  allow either name or pdg
export P3=0,0,5.0               #  GeV
#export PROBEP=5.0               #   e.g. 5.0 6.5  # (GeV)
export TARGETSYMBOL=Cu          #  e.g. Cu
export NEVENTS=500000           #  e.g. 500,000
export PASS=0                   #  allow for multiple passes (more events) of same config
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

     -t | --target <nucleus>      target nucleus element (e.g. "Pb") [${TARGETNUCLEUS}]
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
                    target: pdg: probe: p3: pz: g4verbose: seed: pass: \
                    tarball: pname: \
                    scratchbase: keep-scratch \
                    no-redirect-output no-art-run no-run-art skip-art \
                    debug trace" \
     -o hvo:n:u:p:m:t:c:z:x:T:P:-: -- "$@" `
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
      -t | --target        ) export TARGETNUCLEUS="$2";       shift  ;;
      -c | --pdg | --probe ) export PROBE="$2";               shift  ;;
           --p3            ) export P3="$2";                  shift  ;;
      -z | --pz            ) export P3="0,0,$2";              shift  ;;
           --g4verbose     ) export G4VERBOSE="$2";           shift  ;;
           --seed          ) export RNDMSEED="$2";            shift  ;;
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
  # convert spaces, tabs, [semi]colons to commas
  MULTI_UNIVERSE_SPEC=`echo ${MULTI_UNIVERSE_SPEC} | tr " \t:;" ","`
  MULTI_UNIVERSE_SPEC="${MULTI_UNIVERSE_SPEC},,,"
  MULTIVERSE_FILE=`echo ${MULTI_UNIVERSE_SPEC} | cut -d',' -f1 `   #
  MULTIVERSE_FILE=`basename ${MULTIVERSE_FILE} .fcl`               # to be found in tarball w/ .fcl extension
  UBASE=`echo ${MULTI_UNIVERSE_SPEC} | cut -d',' -f2`
  if [ -z "${UBASE}" ]; then UBASE=0; fi
  USTRIDE=`echo ${MULTI_UNIVERSE_SPEC} | cut -d',' -f3`
  if [ -z "${USTRIDE}" ]; then USTRIDE=10; fi
  let UNIV_FIRST=${PROCESS}*${USTRIDE}+${UBASE}
  let UNIV_LAST=${UNIV_FIRST}+${USTRIDE}-1

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
           echo "sqrt(($px*$px)+($py*$py)+($pz*$pz));scale=1"
    export PROBEP=`echo "sqrt(($px*$px)+($py*$py)+($pz*$pz));scale=1" | bc`
    echo -e "${OUTGREEN}calculated \${PROBEP}=${PROBEP} GeV${OUTNOCOL}"
    unset px py pz
  fi

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
       echo -e "{$OUTRED} bad PROBE=${PROBE}${OUTNOCOL}" ; exit 42 ;;
  esac

  # EPROBENODOT e.g. 5   6p5
  # used in dossier PROLOGs, no trailing 'p0's
  EPROBENODOT=`echo ${PROBEP} | sed -e 's/\./p/' -e 's/p0//' `

  # echo "PROBENAME=${PROBENAME} PROBE_PDG=${PROBE_PDG}"

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

  echo -e "${OUTGREEN}in as:    ${TARBALL}${OUTNOCOL}"
  # full path given ??
  c1=`echo ${TARBALL} | cut -c1`
  if [ "$c1" != "/" ]; then TARBALL=${TARBALL_DEFAULT_DIR}/${TARBALL} ; fi
  TARBALL_BASE=`basename ${TARBALL}`
  echo -e "${OUTGREEN}tarball:  ${TARBALL}${OUTNOCOL}"
  echo -e "${OUTGREEN}base:     ${TARBALL_BASE}${OUTNOCOL}"

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
  fi
  echo -e "${OUTGREEN}${CP_CMD} ${TARBALL} ${TARBALL_BASE}${OUTNOCOL}"
  ${CP_CMD} ${TARBALL} ${TARBALL_BASE}

  case ${TARBALL_BASE} in
     *.gz | *.tgz ) TAR_OPT="z" ;;
     *.bz2        ) TAR_OPT="j" ;;
     *     ) echo -e "${OUTRED}neither .gz nor .bz2 file extension: ${TARBALL_BASE}${OUTNOCOL}"
             TAR_OPT="z" ;;
  esac

  echo -e "${OUTGREEN}looking for ${BOOTSTRAP_SCRIPT}${OUTNOCOL}"
  # expect to find script "${BOOTSTRAP_SCRIPT}"
  bootscript=`tar t${TAR_OPT}f ${TARBALL} | grep ${BOOTSTRAP_SCRIPT} | tail -1`
  localarea=`echo ${bootscript} | cut -d'/' -f1`
  echo -e "${OUTGREEN}bootscript=${bootscript}${OUTNOCOL}"
  echo -e "${OUTGREEN}localarea=${localarea}${OUTNOCOL}"

  # unroll
  tar x${TAR_OPT}f ${TARBALL}
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
      echo -e "${OUTGREEN}setup ${PROD} ${VERS} -q ${QUAL}${OUTNOCOL}"
      setup ${PROD} ${VERS} -q ${QUAL}
    else
      echo -e "${OUTGREEN}setup ${PROD} ${VERS}${OUTNOCOL}"
      setup ${PROD} ${VERS}
    fi
  done
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

# make a list of configs

[HARP|ITEP]_${PROBENAME}_on_${TARGETSYMBOL}_at_${EPROBENODOT}GeV

# needs to loop over universes
cat > ${CONFIG}.fcl <<EOF
# MULTIVERSE        e.g. multiverse170208_Bertini  (fcl base)
# G4HADRONICMODEL   e.g. Bertini
# PROBENAME         e.g. piplus, piminus, proton
# PROBEPDG          e.g. 211,    -211,    2212
# EPROBE            e.g. 5.0 6.5   # (GeV)
# EPROBENODOT       e.g. 5   6p5   # used in dossier PROLOGs, no trailing 'p0's
# TARGETSYMBOL      e.g. Cu
# NEVENTS           e.g. 5000

##### this will only work for cases where both HARP & ITEP have data
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
   maxEvents: ${NEVT}

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
      fileName: "${CONFIG}.hist.root"
   }

   ProcLevelSimSetup: {
      HadronicModelName:  "${G4HADRONICMODEL}"
      TargetNucleus:  "${TARGETSYMBOL}"
      RNDMSeed:  1
   }
   # leave this on ... documentation of what was set
   PhysModelConfig: { Verbosity: true }

} # end of services:

outputs: {

   outroot: {
      module_type: RootOutput
      fileName: "${CONFIG}.artg4tk.root"
   }

} # end of outputs:

physics: {

   producers: {

      PrimaryGenerator: {
         module_type: EventGenerator
         nparticles : 1
         pdgcode:  ${PROBEPDG}
         momentum: [ 0.0, 0.0, ${EPROBE} ] // in GeV
      }

EOF

cat > ${CONFIG}.fcl <<EOF
      BertiniDefault            : @local::BertiniDefault
      BertiniRandom4Univ0001    : @local::BertiniRandom4Univ0001
      BertiniRandom4Univ0002    : @local::BertiniRandom4Univ0002
      BertiniRandom4Univ0003    : @local::BertiniRandom4Univ0003
      BertiniRandom4Univ0004    : @local::BertiniRandom4Univ0004
      BertiniRandom4Univ0005    : @local::BertiniRandom4Univ0005
      BertiniRandom4Univ0006    : @local::BertiniRandom4Univ0006
      BertiniRandom4Univ0007    : @local::BertiniRandom4Univ0007
      BertiniRandom4Univ0008    : @local::BertiniRandom4Univ0008
      BertiniRandom4Univ0009    : @local::BertiniRandom4Univ0009
      BertiniRandom4Univ0010    : @local::BertiniRandom4Univ0010

   } # end of producers:

   analyzers: {

     // Analyze Variants

     BertiniDefaultHARP:
     {
        module_type: AnalyzerHARP
        ProductLabel: "BertiniDefault"
        IncludeExpData:
        {
            DBRecords:  @local::HARP_${PROBENAME}_on_${TARGETSYMBOL}_at_${EPROBENODOT}GeV
        }
     }

     BertiniDefaultITEP:
     {
        module_type: AnalyzerITEP
        ProductLabel: "BertiniDefault"
        IncludeExpData:
        {
            DBRecords:  @local::ITEP_${PROBENAME}_on_${TARGETSYMBOL}_at_${EPROBENODOT}GeV
        }
     }

     BertiniRandom4Univ0001HARP:
     {
        module_type: AnalyzerHARP
        ProductLabel: "BertiniRandom4Univ0001"
        IncludeExpData:
        {
            DBRecords:  @local::HARP_${PROBENAME}_on_${TARGETSYMBOL}_at_${EPROBENODOT}GeV
        }
     }

     BertiniRandom4Univ0001ITEP:
     {
        module_type: AnalyzerITEP
        ProductLabel: "BertiniRandom4Univ0001"
        IncludeExpData:
        {
            DBRecords:  @local::ITEP_${PROBENAME}_on_${TARGETSYMBOL}_at_${EPROBENODOT}GeV
        }
     }

     BertiniRandom4Univ0002HARP:
     {
        module_type: AnalyzerHARP
        ProductLabel: "BertiniRandom4Univ0002"
        IncludeExpData:
        {
            DBRecords:  @local::HARP_${PROBENAME}_on_${TARGETSYMBOL}_at_${EPROBENODOT}GeV
        }
     }

     BertiniRandom4Univ0002ITEP:
     {
        module_type: AnalyzerITEP
        ProductLabel: "BertiniRandom4Univ0002"
        IncludeExpData:
        {
            DBRecords:  @local::ITEP_${PROBENAME}_on_${TARGETSYMBOL}_at_${EPROBENODOT}GeV
        }
     }

     BertiniRandom4Univ0003HARP:
     {
        module_type: AnalyzerHARP
        ProductLabel: "BertiniRandom4Univ0003"
        IncludeExpData:
        {
            DBRecords:  @local::HARP_${PROBENAME}_on_${TARGETSYMBOL}_at_${EPROBENODOT}GeV
        }
     }

     BertiniRandom4Univ0003ITEP:
     {
        module_type: AnalyzerITEP
        ProductLabel: "BertiniRandom4Univ0003"
        IncludeExpData:
        {
            DBRecords:  @local::ITEP_${PROBENAME}_on_${TARGETSYMBOL}_at_${EPROBENODOT}GeV
        }
     }

     BertiniRandom4Univ0004HARP:
     {
        module_type: AnalyzerHARP
        ProductLabel: "BertiniRandom4Univ0004"
        IncludeExpData:
        {
            DBRecords:  @local::HARP_${PROBENAME}_on_${TARGETSYMBOL}_at_${EPROBENODOT}GeV
        }
     }

     BertiniRandom4Univ0004ITEP:
     {
        module_type: AnalyzerITEP
        ProductLabel: "BertiniRandom4Univ0004"
        IncludeExpData:
        {
            DBRecords:  @local::ITEP_${PROBENAME}_on_${TARGETSYMBOL}_at_${EPROBENODOT}GeV
        }
     }

     BertiniRandom4Univ0005HARP:
     {
        module_type: AnalyzerHARP
        ProductLabel: "BertiniRandom4Univ0005"
        IncludeExpData:
        {
            DBRecords:  @local::HARP_${PROBENAME}_on_${TARGETSYMBOL}_at_${EPROBENODOT}GeV
        }
     }

     BertiniRandom4Univ0005ITEP:
     {
        module_type: AnalyzerITEP
        ProductLabel: "BertiniRandom4Univ0005"
        IncludeExpData:
        {
            DBRecords:  @local::ITEP_${PROBENAME}_on_${TARGETSYMBOL}_at_${EPROBENODOT}GeV
        }
     }

     BertiniRandom4Univ0006HARP:
     {
        module_type: AnalyzerHARP
        ProductLabel: "BertiniRandom4Univ0006"
        IncludeExpData:
        {
            DBRecords:  @local::HARP_${PROBENAME}_on_${TARGETSYMBOL}_at_${EPROBENODOT}GeV
        }
     }

     BertiniRandom4Univ0006ITEP:
     {
        module_type: AnalyzerITEP
        ProductLabel: "BertiniRandom4Univ0006"
        IncludeExpData:
        {
            DBRecords:  @local::ITEP_${PROBENAME}_on_${TARGETSYMBOL}_at_${EPROBENODOT}GeV
        }
     }

     BertiniRandom4Univ0007HARP:
     {
        module_type: AnalyzerHARP
        ProductLabel: "BertiniRandom4Univ0007"
        IncludeExpData:
        {
            DBRecords:  @local::HARP_${PROBENAME}_on_${TARGETSYMBOL}_at_${EPROBENODOT}GeV
        }
     }

     BertiniRandom4Univ0007ITEP:
     {
        module_type: AnalyzerITEP
        ProductLabel: "BertiniRandom4Univ0007"
        IncludeExpData:
        {
            DBRecords:  @local::ITEP_${PROBENAME}_on_${TARGETSYMBOL}_at_${EPROBENODOT}GeV
        }
     }

     BertiniRandom4Univ0008HARP:
     {
        module_type: AnalyzerHARP
        ProductLabel: "BertiniRandom4Univ0008"
        IncludeExpData:
        {
            DBRecords:  @local::HARP_${PROBENAME}_on_${TARGETSYMBOL}_at_${EPROBENODOT}GeV
        }
     }

     BertiniRandom4Univ0008ITEP:
     {
        module_type: AnalyzerITEP
        ProductLabel: "BertiniRandom4Univ0008"
        IncludeExpData:
        {
            DBRecords:  @local::ITEP_${PROBENAME}_on_${TARGETSYMBOL}_at_${EPROBENODOT}GeV
        }
     }

     BertiniRandom4Univ0009HARP:
     {
        module_type: AnalyzerHARP
        ProductLabel: "BertiniRandom4Univ0009"
        IncludeExpData:
        {
            DBRecords:  @local::HARP_${PROBENAME}_on_${TARGETSYMBOL}_at_${EPROBENODOT}GeV
        }
     }

     BertiniRandom4Univ0009ITEP:
     {
        module_type: AnalyzerITEP
        ProductLabel: "BertiniRandom4Univ0009"
        IncludeExpData:
        {
            DBRecords:  @local::ITEP_${PROBENAME}_on_${TARGETSYMBOL}_at_${EPROBENODOT}GeV
        }
     }

     BertiniRandom4Univ0010HARP:
     {
        module_type: AnalyzerHARP
        ProductLabel: "BertiniRandom4Univ0010"
        IncludeExpData:
        {
            DBRecords:  @local::HARP_${PROBENAME}_on_${TARGETSYMBOL}_at_${EPROBENODOT}GeV
        }
     }

     BertiniRandom4Univ0010ITEP:
     {
        module_type: AnalyzerITEP
        ProductLabel: "BertiniRandom4Univ0010"
        IncludeExpData:
        {
            DBRecords:  @local::ITEP_${PROBENAME}_on_${TARGETSYMBOL}_at_${EPROBENODOT}GeV
        }
     }

   } # end of analyzers:

   path1:     [ PrimaryGenerator
              , BertiniDefault
              , BertiniRandom4Univ0001
              , BertiniRandom4Univ0002
              , BertiniRandom4Univ0003
              , BertiniRandom4Univ0004
              , BertiniRandom4Univ0005
              , BertiniRandom4Univ0006
              , BertiniRandom4Univ0007
              , BertiniRandom4Univ0008
              , BertiniRandom4Univ0009
              , BertiniRandom4Univ0010
              ]

  path2: [
          BertiniRandom4Univ0001HARP,     BertiniRandom4Univ0001ITEP,
          BertiniRandom4Univ0002HARP,     BertiniRandom4Univ0002ITEP,
          BertiniRandom4Univ0003HARP,     BertiniRandom4Univ0003ITEP,
          BertiniRandom4Univ0004HARP,     BertiniRandom4Univ0004ITEP,
          BertiniRandom4Univ0005HARP,     BertiniRandom4Univ0005ITEP,
          BertiniRandom4Univ0006HARP,     BertiniRandom4Univ0006ITEP,
          BertiniRandom4Univ0007HARP,     BertiniRandom4Univ0007ITEP,
          BertiniRandom4Univ0008HARP,     BertiniRandom4Univ0008ITEP,
          BertiniRandom4Univ0009HARP,     BertiniRandom4Univ0009ITEP,
          BertiniRandom4Univ0010HARP,     BertiniRandom4Univ0010ITEP
        ]



   stream1:   [ outroot ]
   end_paths: [ path1, stream1, path2 ]

} # end of physics:

EOF

}




function fetch_multiverse() {
# FHICL file handling is stupid and won't accept full path names for
# files (I know why, they just won't fix it with 2 lines...), so we
# need to make a local copy of the input file.  Also, use a couple of
# places it might be if just the basename is given..
#
export MULTI_UNIVERSE_FILE=`echo ${MULTI_UNIVERSE_SPEC} | cut -d',' -f1`
export LOCAL_MULTI_UNIVERSE_FILE=`basename ${MULTI_UNIVERSE_FILE}`

export LOCAL_MULTI_UNIVERSE_FILE_BASE=`basename ${LOCAL_MULTI_UNIVERSE_FILE} .fcl`

ispnfs=`echo ${MULTI_UNIVERSE_FILE} | cut -c1-5 | grep -q "/pnfs"`

if [ "${MULTI_UNIVERSE_FILE}" != "${LOCAL_MULTI_UNIVERSE_FILE}" ]; then
  # path given
  ${MYCOPYCMD} ${MULTI_UNIVERSE_FILE} ${LOCAL_MULTI_UNIVERSE_FILE}
fi
if [ ! -f ${LOCAL_MULTI_UNIVERSE_FILE} ]; then
  # drat ... try some other places (perhaps a partial sub-path)
  for trybase in ${MULTI_UNIVERSE_FILE} ${LOCAL_MULTI_UNIVERSE_FILE} ; do
    for trypath in ${OUTPUTTOP} ${MRB_TOP} ${MRB_TOP}/.. ; do
      if [ -f ${LOCAL_MULTI_UNIVERSE_FILE} ]; then
        continue
      fi
      echo -e "${OUTGREEN}try:  ${MYCOPYCMD} ${trypath}/${trybase} ${LOCAL_MULTI_UNIVERSE_FILE}${OUTNOCOL}"
      ${MYCOPYCMD} ${trypath}/${trybase} ${LOCAL_MULTI_UNIVERSE_FILE}
      FETCH_STATUS=$?
      if [ ${FETCH_STATUS} -eq 0 ]; then
        echo -e "${OUTGREEN}fetch returned status ${FETCH_STATUS} (good!)${OUTNOCOL}"
      else
        echo -e "${OUTRED}fetch returned status ${FETCH_STATUS}${OUTNOCOL}"
      fi
    done
  done
fi

if [ ! -f ${LOCAL_MULTI_UNIVERSE_FILE} ]; then
  # failed to find the file .. no point going on
  echo -e "${OUTRED}===========>>> ERRROR${OUTNOCOL}"
  echo -e "${OUTRED}failed to find ${MULTI_UNIVERSE_FILE} anywhere${OUTNOCOL}"
  echo -e "${OUTRED}failed to find ${MULTI_UNIVERSE_FILE} anywhere${OUTNOCOL}" >&2
  echo -e "${OUTRED}... no point in going on.  bail out.${OUTNOCOL}"
  echo -e "${OUTRED}... no point in going on.  bail out.${OUTNOCOL}" >&2
  exit 1
fi

}

#
##############################################################################
function print_universe_names() {

echo ""
if [ $NUNIV -lt 20 ]; then
  echo -e "${OUTGREEN}${UNIVERSE_NAMES}"
else
  # need to enclose in ""'s so as to retain \n's
  echo -e "${OUTGREEN} (first and last 10):"
  echo "${UNIVERSE_NAMES}" | head -n 10
  echo "..."
  echo "${UNIVERSE_NAMES}" | tail -n 10
fi
echo -e "${OUTNOCOL}"

}

#
##############################################################################
function infer_universe_names() {
#
# create a list of universe names based on configuratiosn in the
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

export UNIVERSE_NAMES=`cat ${LOCAL_MULTI_UNIVERSE_FILE} | \
                       grep "{" | grep ":" | \
                       grep -v HadronicModel | \
                       grep -v ModelParameters | \
                       tr -d " :{" `

export NUNIV=`echo "$UNIVERSE_NAMES" | wc -w`
if [ ${VERBOSE} -gt 1 ]; then
  echo -e "${OUTGREEN}${NUNIV} universes in ${LOCAL_MULTI_UNIVERSE_FILE}${OUTNOCOL}"
  print_universe_names
fi
export MINU=1
export MAXU=${NUNIV}

# if user requested only a subset ... then trim this list here
# first extract the requested range ... (1 or 2 values after commas)
REQMINU=`echo "${MULTI_UNIVERSE_SPEC},,," | cut -d',' -f2`
REQMAXU=`echo "${MULTI_UNIVERSE_SPEC},,," | cut -d',' -f3`
if [ ${VERBOSE} -gt 1 ]; then
  echo -e "initial REQ '${REQMINU}' '${REQMAXU}' of '${MINU}' '${MAXU}'"
fi
if [ -z "${REQMINU}" ]; then REQMINU=${MINU} ; fi
if [ -z "${REQMAXU}" ]; then REQMAXU=${MAXU} ; fi
if [ ${VERBOSE} -gt 1 ]; then
  echo -e "non-blank REQ '${REQMINU}' '${REQMAXU}' of '${MINU}' '${MAXU}'"
fi

if [ ${REQMINU} -lt ${MINU} ]; then REQMINU=${MINU} ; fi
if [ ${REQMAXU} -gt ${MAXU} ]; then REQMAXU=${MAXU} ; fi

if [ ${VERBOSE} -gt 1 ]; then
  echo -e "upper/lower bounds REQ '${REQMINU}' '${REQMAXU}' of '${MINU}' '${MAXU}'"
fi

if [[ ${REQMINU} -ne ${MINU} || ${REQMAXU} -ne ${MAXU} ]] ; then
  # need to trim ...
  let i=0
  export UNIVERSE_NAMES_FULL=${UNIVERSE_NAMES}
  UNIVERSE_NAMES=""
  for univ in ${UNIVERSE_NAMES_FULL} ; do
    let i=${i}+1
    if [[ ${i} -lt ${REQMINU} || ${i} -gt ${REQMAXU} ]] ; then continue; fi
      if [ -z "${UNIVERSE_NAMES}" ]; then
        export UNIVERSE_NAMES="${univ}"
      else
        export UNIVERSE_NAMES=`echo -e "${UNIVERSE_NAMES}\n${univ}"`
      fi
  done

  NUNIV=`echo "$UNIVERSE_NAMES" | wc -w`
  if [ ${VERBOSE} -gt 1 ]; then
    echo " "
    echo -e "${OUTGREEN}trimmmed to ${NUNIV} universes [${MINU}:${MAXU}] in ${LOCAL_MULTI_UNIVERSE_FILE}${OUTNOCOL}"
    print_universe_names
  fi
fi
}

#
##############################################################################
function old_create_fcl() {
# use an https://en.wikipedia.org/wiki/Here_document#Unix_shells
# to create file.  un-\'ed $ or back-ticks (`) will be expanded from
# the current environment when run

echo -e "${OUTGREEN}create_fcl  ${CONFIG}${OUTNOCOL}"

let FIRSTRUN=${JOBID}
let FIRSTSUBRUN=0
let FIRSTEVENT=${JOBID}*${NEVENTS}

rm -f  ${CONFIG}.fcl
touch  ${CONFIG}.fcl
cat >> ${CONFIG}.fcl << EOF

#include "${LOCAL_MULTI_UNIVERSE_FILE}"

process_name: process${ARTPNAME}

source: {

   module_type: EmptyEvent
   maxEvents:   ${NEVENTS}
   firstRun:    ${FIRSTRUN}
   firstSubRun: ${FIRSTSUBRUN}
   firstEvent:  ${FIRSTEVENT}

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
   ProcLevelSimSetup: {
      HadronicModelName:  "${G4HADRONICMODEL}"
      TargetNucleus:  "${TARGETNUCLEUS}"
      RNDMSeed:  ${RNDMSEED}
   }
   # leave this on ... documentation of what was set
   PhysModelConfig: { Verbosity: true }

} # end of services:

outputs: {

   out${ARTPNAME}: {
      module_type: RootOutput
      fileName: "${CONFIG}.artg4tk.root"
   }

} # end of outputs:

physics: {

   producers: {

      PrimaryGenerator: {
         module_type: EventGenerator
         nparticles : 1
         pdgcode:  ${PROBEPDG}
         momentum: [ ${PROBE_PX}, ${PROBE_PY}, ${PROBE_PZ} ] // in GeV
      }

EOF

for univ in ${UNIVERSE_NAMES}; do
   printf "      %-25s : @local::%s\n" ${univ} ${univ} >> ${CONFIG}.fcl
done

cat >> ${CONFIG}.fcl << EOF

   } # end of producers:

   analyzers: {

   } # end of analyzers:

   path1:     [ PrimaryGenerator
EOF

for univ in ${UNIVERSE_NAMES}; do
   printf "              , %s\n" ${univ} >> ${CONFIG}.fcl
done

cat >> ${CONFIG}.fcl << EOF
              ]
   stream1:   [ out${ARTPNAME} ]
   end_paths: [ path1, stream1 ]

} # end of physics:
EOF
} # end-of-function create_fcl

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

function create_setup_everything() {

return

echo -e "${OUTGREEN}creating setup_everything.sh in `pwd`${OUTNOCOL}"
echo -e "${OUTGREEN}  with ${ARTG4TK_MRB}${OUTNOCOL}"

export ARTG4TK_QUAL_UNDERSCORE=`echo "${ARTG4TK_QUAL}" | tr ":" "_" `

cat > setup_everything.sh <<EOF
# this file is intended to be sourced by a bash shell

# trigger automount
cat ${EXTERNALS}/setup > /dev/null 2>&1
# possibly give it some time
if [ ! -f ${EXTERNALS}/setup ]; then echo "sleep 3 (a)" ; sleep 3; fi
if [ ! -f ${EXTERNALS}/setup ]; then
  echo -e "\${OUTRED}not finding ${EXTERNALS}/setup\${OUTNOCOL}"
  echo -e "\${OUTRED}  ... this will probably end in tears\${OUTNOCOL}"
  echo -e "\${OUTRED}-------------------------------------\${OUTNOCOL}"
  df -ahT --sync
  echo -e "\${OUTRED}-------------------------------------\${OUTNOCOL}"
fi

STARTDIR=\`pwd\`
# bootstrap UPS
source ${EXTERNALS}/setup

# add another location so we can use the best-est "ifdhc"
#    /grid/fermiapp/products/common/db
COMMON_UPS=/cvmfs/fermilab.opensciencegrid.org/products/common/db
LARSOFT_UPS=/cvmfs/fermilab.opensciencegrid.org/products/larsoft
export PRODUCTS=\${PRODUCTS}:\${COMMON_UPS}:\${LARSOFT_UPS}

# interact w/ PNFS only through ifdh cp & friends
setup ifdhc

# setup default one so we get dependent products, mrb will override
setup artg4tk ${ARTG4TK_VERSION} -q ${ARTG4TK_QUAL}
setup mrb     ${MRB_VERSION}

# these are only need for code development, but whatever ...
# then we can use this interactively later
setup gitflow v1_8_0
setup git v2_3_0
export MRB_PROJECT=artg4tk

case \${ARTG4TK_MRB} in
   *.tar.gz  | *.tgz  ) copt="z" ;;
   *.tar.bz2 | *.tbz2 ) copt="j" ;;
   *.tar              ) copt=""  ;;
   *                  ) copt="IS-A-REAL-PATH" ;;
esac
if [ "\${copt}" != "IS-A-REAL-PATH" ]; then
  echo -e "\${OUTRED}input is a tarball ... try unpacking\${OUTNOCOL}"
  export ARTG4TK_MRB_TARBALL=\${ARTG4TK_MRB}
  export TARBALL_BASE=\`basename \${ARTG4TK_MRB_TARBALL}\`
  ${MYCOPYCMD} \${ARTG4TK_MRB_TARBALL} \${TARBALL_BASE}
  if [ ! -f \${TARBALL_BASE} ]; then
     echo -e "\${OUTRED}\"${MYCOPYCMD}\" failed; try simple \"cp\" to get ${TARBALL_BASE}\${OUTNOCOL}"
     cp \${ARTG4TK_MRB_TARBALL} \${TARBALL_BASE}
  fi
  if [ ! -f \${TARBALL_BASE} ]; then
     echo -e "\${OUTRED}failed to get \${TARBALL_BASE} ... tears, there will be tears\${OUTNOCOL}"
     exit 42
  fi
  if [ \${VERBOSE} -gt 1 ]; then
    echo -e "\${OUTRED}  TARBALL_BASE=\${TARBALL_BASE}\${OUTNOCOL}"
    echo -e "\${OUTRED}     tar tv\${copt}f \${TARBALL_BASE} | head -1 | sed -e 's%^\./%%' | cut -d'/' -f1"
  fi
  # don't use "v" option (otherwise prints permissione, etc)
  TARBALL_TOP_DIR=\`tar t\${copt}f \${TARBALL_BASE} | head -1 | sed -e 's%^\./%%' | cut -d'/' -f1\`
  if [ \${VERBOSE} -gt 1 ]; then
    echo -e "\${OUTRED}  TARBALL_TOP_DIR=\${TARBALL_TOP_DIR}\${OUTNOCOL}"
    echo tar x\${copt}f \${TARBALL_BASE}
  fi
  tar x\${copt}f \${TARBALL_BASE}
  # make it so we can delete it all later ...
  chmod -R +w \${TARBALL_TOP_DIR}
  export ARTG4TK_MRB=\`pwd\`/\${TARBALL_TOP_DIR}
  echo -e "\${OUTRED}new ARTG4TK_MRB=\${ARTG4TK_MRB}\${OUTNOCOL}"

  ##### this file has hardcode ${MRB_TOP} & ${MRB_SOURCE} to where it was built
  # find what was there ... and substitute where we've unpacked it
  LOCALSETUPFILE="\${ARTG4TK_MRB}/localProducts_artg4tk_${ARTG4TK_VERSION}_${ARTG4TK_QUAL_UNDERSCORE}/setup"
  # "massage" it to point where it actually _is_
  echo -e "\${OUTPURPLE}update to current location: \${LOCALSETUPFILE} \${OUTNOCOL}"
  MRB_TOP_OLD=\`cat \${LOCALSETUPFILE} | egrep "setenv *MRB_TOP" | tr -d '"' | tr -s ' ' | sed -e 's/^ *//g' | cut -d' ' -f3 \`
  sed -i.orig -e "s%\${MRB_TOP_OLD}%\${ARTG4TK_MRB}%g" \${LOCALSETUPFILE}
  if [ \${VERBOSE} -gt 1 ]; then
    echo -e "\${OUTRED}sed -i.orig -e \"s%\${MRB_TOP_OLD}%\${ARTG4TK_MRB}%g\" \${LOCALSETUPFILE} is now: \${OUTORANGE}"
    echo "--------------------------------------------------------------------"
    cat \${LOCALSETUPFILE}
    echo "--------------------------------------------------------------------"
  fi

  # end-of-tarball handling
fi

echo -e "\${OUTGREEN}cd \${ARTG4TK_MRB}\${OUTNOCOL}"
cd \${ARTG4TK_MRB}

echo -e "\${OUTGREEN}source ./localProducts_artg4tk_${ARTG4TK_VERSION}_${ARTG4TK_QUAL_UNDERSCORE}/setup \${OUTNOCOL}"
##### this file has hardcode ${MRB_TOP} & ${MRB_SOURCE} to where it was built
## hopefully this was dealt with above when unpackingtar ball
source ./localProducts_artg4tk_${ARTG4TK_VERSION}_${ARTG4TK_QUAL_UNDERSCORE}/setup

if [ \${VERBOSE} -gt 1 ]; then
  echo "   LD_LIBRARY_PATH="
  echo \${LD_LIBRARY_PATH} | tr ":" "\n" | sed -e 's/^/     /g'
fi

# mrbsetenv is an alias for the complete command below;
# it will NOT work if issued from a script - one has to "source" it explicitly
# and this should be done AFTER source-ing this ./localProducts...../setup thing
# such deps on MRB are NOT super convenient, and at some point we might want
# to explore alternatives ^_^
#
echo -e "\${OUTGREEN}source \${MRB_DIR}/bin/mrbSetEnv\${OUTNOCOL}"
# supply explicit null arg ... otherwise pulls args from calling script
source \${MRB_DIR}/bin/mrbSetEnv "" "" ""

if [ \${VERBOSE} -gt 1 ]; then
  echo "   LD_LIBRARY_PATH="
  echo \${LD_LIBRARY_PATH} | tr ":" "\n" | sed -e 's/^/     /g'
fi

### this seems to wipe local build area from LD_LIBRARY_PATH
### so don't use it unless the products are "installed"
### ##echo -e "\${OUTGREEN}mrb setup_local_products\${OUTNOCOL}"
### ###mrb setup_local_products
### # 'mrb setup_local_products' forces me to use 'mrbslp' alias instead (WTF?)
### echo -e "\${OUTGREEN}mrbslp\${OUTNOCOL}"
### mrbslp
###
### if [ \${VERBOSE} -gt 1 ]; then
###   echo "   LD_LIBRARY_PATH="
###   echo \${LD_LIBRARY_PATH} | tr ":" "\n" | sed -e 's/^/     /g'
### fi

echo -e "\${OUTGREEN}cd \${ARTG4TK_MRB}/srcs/RooMUHistos\${OUTNOCOL}"
cd \${ARTG4TK_MRB}/srcs/RooMUHistos
source ./env_set.sh

if [ \${VERBOSE} -gt 1 ]; then
  echo "   LD_LIBRARY_PATH="
  echo \${LD_LIBRARY_PATH} | tr ":" "\n" | sed -e 's/^/     /g'
fi

echo -e "\${OUTGREEN}cd \${ARTG4TK_MRB}\${OUTNOCOL}"
cd \${ARTG4TK_MRB}

# jumped around above ... go back to where we should be
echo -e "\${OUTGREEN}cd \${STARTDIR}\${OUTNOCOL}"
cd \${STARTDIR}

if [ \${VERBOSE} -gt 0 ]; then
  echo -e "\${OUTGREEN}done setup_everything.sh \${OUTNOCOL}"
  echo -e "\${OUTGREEN}currently in \`pwd\` \${OUTNOCOL}"
  echo -e "\${OUTGREEN}MRB_TOP=\${MRB_TOP}\${OUTNOCOL}"
  echo -e "\${OUTGREEN}MRB_SOURCE=\${MRB_SOURCE}\${OUTNOCOL}"
fi

# end-of-script
EOF

if [ ${VERBOSE} -gt 1 ]; then
  echo -e "${OUTGREEN}setup_everything.sh:${OUTORANGE}"
  echo "--------------------------------------------------------------------"
  cat setup_everything.sh
  echo "--------------------------------------------------------------------"
  echo -e "${OUTNOCOL}"
  echo " "
fi
}

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
  echo "   using \${ARTG4TK_MRB}=${ARTG4TK_MRB}"
  echo "   \${PRODUCTS}="
  echo ${PRODUCTS} | tr ":" "\n" | sed -e 's/^/     /g'
  echo "   \${LD_LIBRARY_PATH}="
  echo ${LD_LIBRARY_PATH} | tr ":" "\n" | sed -e 's/^/     /g'
  echo " "
}

function report_config_summary()
{
  echo -e "${b0}:${OUTBLUE} config_summary ${CONFIG}${OUTNOCOL}"
  echo "   DESTDIR        ${DESTDIR}"
  echo "   JOBID          ${JOBID}"
  echo "   MULTIVERSE     ${MULTIVERSE}"
  echo "   nevents        ${NEVENTS}"
  echo "   hadronic model ${G4HADRONICMODEL}"
  echo "   target         \"${TARGETNUCLEUS}\""
  echo "   probe:        ${PROBENAME} (${PROBEPDG}) [ ${PROBE_PX}, ${PROBE_PY}, ${PROBE_PZ} ] GeV/c"
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
  echo -e "${OUTORANGE}export RNDMSEED=${JOBID}${OUTNOCOL}"
  export RNDMSEED=${JOBID}
fi

exit
return
###

  echo -e "${OUTRED}-------------------------------------${OUTNOCOL}"
  report_config_summary
  report_node_info
  report_setup
  echo -e "${OUTRED}-------------------------------------${OUTNOCOL}"

export MYMKDIRCMD="ifdh mkdir_p"
export MYCOPYCMD="ifdh cp"
# IFDH_CP_MAXRETRIES: maximum retries for copies on failure -- defaults to 7
export IFDH_CP_MAXRETRIES=1  # 7 is silly
# if STDOUT is a tty, then probably interactive use
# avoid the "ifdh" bugaboo I'm having testing interactively
if [ -t 1 ]; then
  export MYMKDIRCMD="mkdir -p"
  export MYCOPYCMD="cp"
fi
echo -e "${OUTGREEN}using \"${MYCOPYCMD}\" for copying${OUTNOCOL}"

if [ "`pwd`" != "${_CONDOR_SCRATCH_DIR}" ]; then
  echo -e "${OUTRED}about to fetch_multiverse but in `pwd`${OUTNOCOL}"
  echo -e "${OUTRED}instead of ${_CONDOR_SCRATCH_DIR}${OUTNOCOL}"
  cd ${_CONDOR_SCRATCH_DIR}
fi

#fetch_multiverse
#infer_universe_names
#if [ ${VERBOSE} -gt 1 ]; then
#  echo -e "${OUTGREEN}post- fetch_multiverse/infer_universe_names${OUTNOCOL}"
#  pwd
#  ls -l
#  if [ -d 0 ]; then
#    echo "what is the 0 directory?"
#    ls -l 0
#  fi
#fi

#fetch_file ${MULTIVERSE}/${MULTIVERSE}.fcl
#for expt in ${DOSSIER_LIST} ; do
#  fetch_file ${expt}_dossier.fcl
#done

if [ -z "${MINU}" ]; then
  URANGE="UALL"
else
  MINU4=`printf "%04d" ${MINU}`
  MAXU4=`printf "%04d" ${MAXU}`
  URANGE="U${MINU4}-${MAXU4}"
fi
# output file name and directory based on universe (subset) and JOBID
# echo -e "${OUTPURPLE}${b0}: pwd=`pwd` [${MINU}:${MAXU}] ${OUTNOCOL}"

# should include universe ranges
export CONFIGBASE=${PROBENAME}_on_${TARGETSYMBOL}_at_${EPROBENODOT}GeV

export CONFIGBASESMALL=`echo ${CONFIGBASE} | sed -e 's/_on_//' -e 's/_at_//' | tr -d '_' `


JOBID4=`printf "%04d" ${JOBID}`
#export CONFIGBASE=${LOCAL_MULTI_UNIVERSE_FILE_BASE}_${PROBEP}GeV_${PROBENAME}_${TARGETNUCLEUS}_${URANGE}
export CONFIG=${CONFIGBASE}_J${JOBID4}
export DESTDIR=${OUTPUTTOP}/${MULTIVERSE}/${CONFIGBASE}/${JOBID4}
echo -e ""


#create_fcl
#make_genana_fcl

if [ ${VERBOSE} -gt 1 ]; then
  echo -e "${OUTGREEN}contents of ${CONFIG} are:${OUTORANGE}"
  echo "--------------------------------------------------------------------"
  #cat ${CONFIG}.fcl
  echo "--------------------------------------------------------------------"
  echo -e "${OUTNOCOL}"
  echo " "
fi

echo " "
report_config_summary
report_node_info
report_setup
echo " "

# run the job

# look in current directory for any include fcl files ...
export FHICL_FILE_PATH=${FHICL_FILE_PATH}:.

now=`date "+%Y-%m-%d %H:%M:%S" `
echo -e "${OUTPURPLE}art start  ${now}"
if [ ${RUNART} -ne 0 ]; then
  # HERE'S THE ACTUAL "ART" COMMAND
  if [ ${REDIRECT_ART} -ne 0 ]; then
    echo "art -c ${CONFIG}.fcl 1> ${CONFIG}.out 2> ${CONFIG}.err"
   #       art -c ${CONFIG}.fcl 1> ${CONFIG}.out 2> ${CONFIG}.err
          ART_STATUS=$?
  else
    echo "art -c ${CONFIG}.fcl"
    #      art -c ${CONFIG}.fcl
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
  echo -e "${OUTGREEN}contents of ${CONFIG}.out is:${OUTORANGE}"
  echo "--------------------------------------------------------------------"
  #cat ${CONFIG}.out
  echo "--------------------------------------------------------------------"
  echo -e "${OUTGREEN}contents of ${CONFIG}.err is:${OUTORANGE}"
  echo "--------------------------------------------------------------------"
  #cat ${CONFIG}.err
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
  #echo -e "${OUTRED}${MYMKDIRCMD} ${DESTDIR} ${OUTNOCOL} returned ${MKDIR_STATUS}${OUTNOCOL}"
fi
# for ifdh mkdir is there some way to distinguish between
# "couldn't create directory" (permissions, whatever) vs. "already exists"?
# mkdir(2) says EEXIST returned for later
#   /usr/include/asm-generic/errno-base.h:#define EEXIST 17 /* File exists */
# but mkdir run interactively returns 1 ...

localList="${CONFIG}.artg4tk.root ${CONFIG}.hist.root ${CONFIG}.fcl ${LOCAL_MULTI_UNIVERSE_FILE}"
localList="${localList} setup_everything.sh"
if [ ${REDIRECT_ART} -ne 0 ]; then
  localList="${localList} ${CONFIG}.out ${CONFIG}.err"
fi

for inFile in ${localList} ; do
  if [ -f ${inFile} ]; then
    if [ -s ${inFile} ]; then
      echo -e "${OUTPURPLE}${MYCOPYCMD} ${inFile} ${DESTDIR}/${inFile}${OUTNOCOL}"
 #     ${MYCOPYCMD} ${inFile} ${DESTDIR}/${inFile}
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

# end-of-script
