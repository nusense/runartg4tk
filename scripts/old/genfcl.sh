#! /usr/bin/env bash

export MULTIVERSE=multiverse170208_Bertini
export HADRONMODEL=Bertini
export PROBENAME=piminus
export PROBEPDG=-211
export EPROBE=5.0
export EPROBENODOT=5
export TARGETSYMBOL=C
export NEVT=500

cat > my.fcl <<EOF
# MULTIVERSE    e.g. multiverse170208_Bertini  (fcl base)
# HADRONMODEL   e.g. Bertini
# PROBENAME     e.g. piplus, piminus, proton
# PROBEPDG      e.g. 211,    -211,    2212
# EPROBE        e.g. 5.0 6.5   # (GeV)
# EPROBENODOT   e.g. 5   6p5   # used in dossier PROLOGs, no trailing 'p0's
# TARGETSYMBOL  e.g. Cu
# NEVNT         e.g. 5000

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

process_name: genana_${MULTIVERSE}_${PROBENAME}_${TARGETSYMBOL}_${EPROBENODOT}

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
      fileName: "genana_${MULTIVERSE}_${PROBENAME}_${TARGETSYMBOL}_${EPROBENODOT}_U0000-U0010.hist.root"
   }

   ProcLevelSimSetup: {
      HadronicModelName:  "${HADRONMODEL}"
      TargetNucleus:  "${TARGETSYMBOL}"
      RNDMSeed:  1
   }
   # leave this on ... documentation of what was set
   PhysModelConfig: { Verbosity: true }

} # end of services:

outputs: {

   outroot: {
      module_type: RootOutput
      fileName: "genana_${MULTIVERSE}_${PROBENAME}_${TARGETSYMBOL}_${EPROBENODOT}_U0000-U0010.artg4tk.root"
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


# end-of-script