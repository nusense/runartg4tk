#include <iostream>
#include <iomanip>
#include <string>
#include <fstream>
#include <vector>
using namespace std;

#include <cstdio>  // sprintf

#include "TObject.h"
#include "TRandom3.h"

// forward declaration
std::string makeUniqueLabel(std::string baseLabel, size_t i);

//-----------------------------------------------------------------------
class ModelParam {
public:
  ModelParam() { } // need default constructor
  ModelParam(std::string name, std::string model,
             double vmin, double vmax, double vdflt)
             : fname(name), fmodel(model)
             , fvmin(vmin), fvmax(vmax), fvdflt(vdflt)
             , fdistrib("flat"), fdv1(0), fdv2(0), fenabled(false) { ; }
  std::string   GetName()        const { return fname; }
  std::string   GetModel()       const { return fmodel; }
  double        GetVMin()        const { return fvmin; }
  double        GetVMax()        const { return fvmax; }
  std::string   GetDistrib()     const { return fdistrib; }
  double        GetValue()       const { return fvalue; }
  bool          IsEnabled()      const { return fenabled; }
  ModelParam&   SetDistrib(std::string dname, double v1, double v2);
  ModelParam&   SetEnabled(bool enable=true);
  ModelParam&   SetRandomValue();
  ModelParam&   SetStepValue(int i, int n);
  std::ostream& WriteConfig(std::ostream& s);
private:
  std::string   fname;      // parameter name
  std::string   fmodel;     // physic model associated with
  double        fvmin;      // min allowed value
  double        fvmax;      // max allowed value
  double        fvdflt;     // (expected default value)
  std::string   fdistrib;   // for now only "flat","binary" distributions
                            // "step" for non-random
  double        fdv1, fdv2; // parameters for distributions (guass, etc)
  double        fvalue;     // chosen value
  bool          fenabled;   // enabled ?
};
ModelParam& ModelParam::SetDistrib(std::string dname, double v1, double v2)
{
  fdistrib = dname;
  fdv1     = v1;
  fdv2     = v2;
  fenabled = true;
  if ( dname != "flat"   &&
       dname != "binary" &&
       dname != "step"      ) {
    std::cerr << "Sorry, ModelParam::SetDistrib only supports 'flat' "
              << "'binary' & 'step' at the current time"
              << std::endl;
    fenabled = false;
  }
  return *this;
}
ModelParam& ModelParam::SetEnabled(bool enable) {
  fenabled = enable;
  return *this;
}
ModelParam& ModelParam::SetRandomValue()
{
  if ( fdistrib == "flat") {
    fvalue = gRandom->Uniform(fvmin,fvmax);
  } else if ( fdistrib == "binary" ) {
    fvalue = ( (gRandom->Uniform(0,1)<0.5) ? 0 : 1 );
  } else {
    std::cerr << "Sorry, ModelParam::GetRandomValue only supports 'flat' "
              << "and 'binary' at the current time"
              << std::endl << "   unhandled '" << fdistrib << "' distribution "
              << "treated as 'flat'"
              << std::endl;
    fvalue = gRandom->Uniform(fvmin,fvmax);
  }
  return *this;
}
ModelParam& ModelParam::SetStepValue(int i, int n)
{
  // want frac to be [0:1] for i=0...(n-1)
  double frac = (double)(i)/(double)(n-1);
  fvalue = fvmin + (fvmax-fvmin)*frac;
  return *this;
}
std::ostream& ModelParam::WriteConfig(std::ostream& s)
{
  s << "#  " << std::setw(10) << fmodel << "  "
    << std::setw(20) << fname << " "
    << std::setw(12) << fvmin << " "
    << std::setw(12) << fvmax << " "
    << std::setw(10) << fdistrib;
  if ( fdistrib != "flat" && fdistrib != "binary" ) {
    s << " (params " << fdv1 << "," << fdv2 << ")";
  }
  s << " [" << std::setw(12) << fvdflt << "] ";
  s << std::endl;
  return s;
}

/*
//// artg4tk/G4PhysModelParamStudy/G4Components/ModelConfigMapper.cc

//// Bertini
RadiusScaleByRatio    <ratio>
RadiusScale           <value>
XSecScaleByRatio      <ratio>
XSecScale             <value>
FermiScaleByRatio     <ratio>
FermiScale            <value>
TrailingRadiusByRatio <ratio>
TrailingRadius        <value>
GammaQDScaleByRatio   <ratio>
GammaQDScale          <value>

UsePreCompound   0/1
DoCoalescence    0/1

 // running the ModelConfigMapper tells me that
 ***** Default settings for Geant4 model bertini
 * /process/had/cascade/alphaRadiusScale 0.7
 * /process/had/cascade/cluster2DPmax 0.09
 * /process/had/cascade/cluster3DPmax 0.108
 * /process/had/cascade/cluster4DPmax 0.115
 * /process/had/cascade/crossSectionScale 1
 * /process/had/cascade/doCoalescence 1
 * /process/had/cascade/fermiScale 0.685187
 * /process/had/cascade/gammaQuasiDeutScale 1
 * /process/had/cascade/nuclearRadiusScale 2.81967
 * /process/had/cascade/piNAbsorption 0
 * /process/had/cascade/shadowningRadius 0
 * /process/had/cascade/smallNucleusRadius 2.83721
 * /process/had/cascade/use3BodyMom 0
 * /process/had/cascade/usePhaseSpace 0
 * /process/had/cascade/usePreCompound 0
 * /process/had/cascade/useTwoParamNuclearRadius 0
 * /process/had/cascade/verbose 0

Julia suggests:
    RadiusScale     1.0 - 3.5
    XSecScale       0.1 - 2.0
    FermiScale      0.5 - 1.0
    TrailingRadius  0.0 - 5.0

*/

// here's a choice of Bertini model parameters with "sensible" ranges

/*
// pass 1
ModelParam    bertiniRadiusScale("RadiusScale",   "Bertini", 1.0, 3.5, -999 );
ModelParam      bertiniXSecScale("XSecScale",     "Bertini", 0.1, 3.0, -999 );
ModelParam     bertiniFermiScale("FermiScale",    "Bertini", 0.5, 1.0, -999 );
ModelParam bertiniTrailingRadius("TrailingRadius","Bertini", 0.0, 5.0, -999 );
*/

///////////////////////////////////////////////////////////////////////////////////////
// pass 2
//
// artg4tk toolkit model paramter names:
//    https://cdcvs.fnal.gov/redmine/projects/g4mps/wiki/List_of_G4_model_parameters
// Bertini code
//     http://www-geant4.kek.jp/lxr/source/processes/hadronic/models/cascade/cascade/src/G4CascadeParameters.cc

const double OLD_RADIUS_UNITS=(3.3836/1.2);
const double BERT_FERMI_SCALE=1.932/OLD_RADIUS_UNITS;
const double eps=0.00001;  // absolutely keep things in range

const double fslo=(BERT_FERMI_SCALE/2.0)+eps;
const double fshi=(BERT_FERMI_SCALE*2.0)-eps;

const double rslo=(OLD_RADIUS_UNITS/2.0)+eps;
const double rshi=(OLD_RADIUS_UNITS*2.0)-eps;

ModelParam       bertiniFermiScale("FermiScale",       "Bertini", fslo,  fshi,  BERT_FERMI_SCALE);
ModelParam      bertiniRadiusScale("RadiusScale",      "Bertini", rslo,  rshi,  OLD_RADIUS_UNITS);
ModelParam   bertiniTrailingRadius("TrailingRadius",   "Bertini", 0.0,   2.0,   0.0             ); //         5->2
ModelParam        bertiniXSecScale("XSecScale",        "Bertini", 0.5,   2.0,   1.0             ); // .1->.5, 3->2

ModelParam    bertiniPiNAbsorption("piNAbsorption",    "Bertini", 0.0,   1.0,   0.0             );
ModelParam    bertiniCluster2DPmax("Cluster2DPmax",    "Bertini", 0.045, 0.180, 0.090           );
ModelParam    bertiniCluster3DPmax("Cluster3DPmax",    "Bertini", 0.054, 0.216, 0.108           );
ModelParam    bertiniCluster4DPmax("Cluster4DPmax",    "Bertini", 0.0575,0.230, 0.115           );

// for now don't vary these
ModelParam   bertiniSmallNucRadius("SmallNucScale",    "Bertini", 0.996, 2.984, 1.992 ); // or 8/oldrad*radscl
ModelParam bertiniAlphaRadiusScale("AlphaRadiusScale", "Bertini", 0.42,  1.680, 0.84  ); // or 0.70
ModelParam     bertiniGammaQDScale("GammaQDScale",     "Bertini", 0.5,   2.0,   1.0   );

//ModelParam blah("xyz","no-such-hadron-model", 0.0, 999.9 );

//-----------------------------------------------------------------------
class UnivGenerator {
public:
  UnivGenerator(std::string model = "Bertini")
    : fmodel(model) { }
  // ModelParam's that are Add()'ed aren't owned by the UnivGenerator
  void          Add(ModelParam* mp);
  std::ostream& WriteConfigRangeInfo(std::ostream& s);

  std::ostream& WriteNewUniverse(std::ostream& s, std::string label,
                                 bool isProcLevel=true);

  std::ostream& WriteRandomUniverses(std::ostream& s, size_t nuniv,
                                     bool isProcLevel=true);

  std::ostream& WriteScanUniverses(std::ostream& s, size_t nuniv,
                                   bool isProcLevel=true);

  /*
  std::ostream& WriteGridUniverses(std::ostream& s, size_t nuniv,
                                   bool isProcLevel=true);
  */


private:


  std::string              fmodel; // model (cross check)
  std::vector<ModelParam*> fvparams;
};
void UnivGenerator::Add(ModelParam* mp)
{
  if ( mp->GetModel() != fmodel ) {
    std::cerr << "Sorry, can't add a ModelParam [" << mp->GetName()
              << "," << mp->GetModel() << "]"
              << std::endl
              << "           to a UnivGenerator [" << fmodel << "]"
              << std::endl;
    return;
  }
  fvparams.push_back(mp);
}
std::ostream& UnivGenerator::WriteConfigRangeInfo(std::ostream& s)
{
  size_t nparams = fvparams.size();
  s << std::endl;
  if ( nparams == 0 ) {
    s << "# config for default " << fmodel << " universe" << std::endl;
  } else {
    s << "# parameters for block of " << fmodel << " universes" << std::endl;
    for (size_t i=0; i<nparams; ++i) {
      ModelParam* mp = fvparams[i];
      mp->WriteConfig(s);
    }
  }
  return s;
}
std::ostream& UnivGenerator::WriteNewUniverse(std::ostream& s,
                                              std::string label,
                                              bool isProcLevel)
{
  s << std::endl;

  if ( isProcLevel ) {
    size_t nparams = fvparams.size();

    s << fmodel << label << " : { " << std::endl
      << "    module_type:  ProcLevelMPVaryProducer " << std::endl
      << "    Verbosity: 0" << std::endl
      << "    HadronicModel: {" << std::endl
      << "        DefaultPhysics: "
      << ((nparams==0)?"true":"false") << std::endl
      << "        ModelParameters: {" << std::endl;
    for (size_t i=0; i<nparams; ++i) {
      ModelParam* mp = fvparams[i];
      if ( ! mp->IsEnabled() ) continue;
      s << "            " << std::setiosflags(std::ios_base::left)
        << std::setw(20)
        << mp->GetName()  << std::resetiosflags(std::ios_base::left) << " : "
        << mp->GetValue() << std::endl;
    }
    s << "        } # end-of-ModelParameters" << std::endl
      << "    } # end-of-HadronicModel" << std::endl
      << "} # end-of-" << fmodel << label << std::endl;

  } else {
    // not isProcLevel
    std::cerr << "Sorry, UnivGenerator::WriteNewUniverse currently only "
              << "knows about ProcLevel configs" << std::endl;
    s << "# Sorry, UnivGenerator::WriteNewUniverse currently only " << std::endl
      << "# knows about ProcLevel configs " << std::endl
      << "#    skip " << fmodel << label << std::endl;

  }
  return s;
}

std::ostream& UnivGenerator::WriteRandomUniverses(std::ostream& s,
                                                  size_t nuniv,
                                                  bool isProcLevel)
{
  std::string baseLabel = "Random4Univ";
  std::string uniqLabel;
  for (size_t iu=1; iu<(nuniv+1); ++iu) {
    uniqLabel = makeUniqueLabel(baseLabel,iu);
    std::cout << "generate " << fmodel << uniqLabel << "\r" << std::flush;

    size_t nparams = fvparams.size();
    for (size_t i=0; i<nparams; ++i) {
      ModelParam* mp = fvparams[i];
      if ( ! mp->IsEnabled() ) {
        cout << "mp " << mp->GetName() << " not enabled "
             << "dist " << mp->GetDistrib() << endl;
        continue;
      }
      mp->SetRandomValue();
    }

    WriteNewUniverse(s,uniqLabel,isProcLevel);
  }
  return s;
}

std::ostream& UnivGenerator::WriteScanUniverses(std::ostream& s,
                                                size_t nuniv,
                                                bool isProcLevel)
{
  std::string basebaseLabel = "StepUniv";
  std::string baseLabel;
  std::string uniqLabel;
  ModelParam* mp;
  size_t nparams = fvparams.size();

  // loop over each parameter ... scan over it's range w/ "nuniv" settings
  for (size_t iparam=0; iparam<nparams; ++iparam) {

    // turn everything off
    for (size_t j=0; j<nparams; ++j) {
      mp = fvparams[j];
      mp->SetEnabled(false);
    }
    // turn on only this parameter as we scan over it
    mp = fvparams[iparam]; // this is what we're scanning over
    mp->SetEnabled(true);
    baseLabel = mp->GetName() + basebaseLabel;
    /*
    std::cout << " ...." << fmodel << " ... " << iparam << " pname=\""
              << mp->GetName() << "\" baseLabel=\"" << baseLabel << std::endl;
    */

    for (size_t iu=0; iu<nuniv; ++iu) {
      uniqLabel = makeUniqueLabel(baseLabel,iu);
      std::cout << "generate " << fmodel << uniqLabel << "\r" << std::flush;
      mp->SetStepValue(iu,nuniv);
      WriteNewUniverse(s,uniqLabel,isProcLevel);
    }
    std::cout << std::endl;
  }
  return s;
}


//-----------------------------------------------------------------------
// helper function
std::string makeUniqueLabel(std::string baseLabel, size_t i)
{
  char buffer[100];
  // 1 .. 9999 possible universes
  sprintf(buffer,"%04ld",i);
  std::string outLabel = baseLabel;
  outLabel += std::string(buffer);
  return outLabel;
}

//-----------------------------------------------------------------------
// main routine
//-----------------------------------------------------------------------
void generate_universes(std::string basename = "multiverse181212",  // output file basename
                        signed long int nunivIn = +1000,  // # of universes to gen
                                                   // beyond the default
                        // +N = random, -N = steps each param
                        std::string hadronModel = "Bertini",
                        bool isProcLevel = true,
                        int seed = 0)                  //
{

  gRandom = new TRandom3(seed);

  std::string filename = basename;   // eg. multiverse170208
  filename += "_";
  filename += hadronModel;
  filename += ".fcl";

  // start file, BEGIN_PROLOG
  std::ofstream fclfile(filename.c_str());
  fclfile << "BEGIN_PROLOG" << std::endl;

  // begin with a default universe
  std::cout << "generate " << hadronModel << "Default" << std::endl;
  UnivGenerator defaultUniv(hadronModel);

  defaultUniv.WriteConfigRangeInfo(fclfile);
  defaultUniv.WriteNewUniverse(fclfile,"Default",isProcLevel);

  UnivGenerator multi4Univ(hadronModel);

  if ( hadronModel == "Bertini" ) {
    // now some multi-verse ones
    bertiniRadiusScale.SetEnabled(true);
    multi4Univ.Add(&bertiniRadiusScale);

    bertiniXSecScale.SetEnabled(true);
    multi4Univ.Add(&bertiniXSecScale);

    bertiniFermiScale.SetEnabled(true);
    multi4Univ.Add(&bertiniFermiScale);

    bertiniTrailingRadius.SetEnabled(true);
    multi4Univ.Add(&bertiniTrailingRadius);

    // new for pass 2
    bertiniPiNAbsorption.SetEnabled(true);
    multi4Univ.Add(&bertiniPiNAbsorption);

    bertiniCluster2DPmax.SetEnabled(true);
    multi4Univ.Add(&bertiniCluster2DPmax);
    bertiniCluster3DPmax.SetEnabled(true);
    multi4Univ.Add(&bertiniCluster3DPmax);
    bertiniCluster4DPmax.SetEnabled(true);
    multi4Univ.Add(&bertiniCluster4DPmax);

    // but not these
    /*
    bertiniSmallNucRadius.SetEnabled(true);
    multi4Univ.Add(&bertiniSmallNucRadius);

    bertiniAlphaRadiusScale.SetEnabled(true);
    multi4Univ.Add(&bertiniAlphaRadiusScale);

    bertiniGammaQDScale.SetEnabled(true);
    multi4Univ.Add(&bertiniGammaQDScale);
    */
  }

  // test user silliness ... cross check
  // multi4Univ.Add(&blah);

  multi4Univ.WriteConfigRangeInfo(fclfile);

  bool dorandom = (nunivIn>0);
  size_t nuniv = (nunivIn>0) ? nunivIn : -nunivIn;
  /*
  std::cout << nunivIn << " random " << dorandom
            << " nuniv " << nuniv << std::endl;
  */

  if ( dorandom ) {

    multi4Univ.WriteRandomUniverses(fclfile,nuniv,isProcLevel);

  } else {

    multi4Univ.WriteScanUniverses(fclfile,nuniv,isProcLevel);

  }

  // END_PROLOG, close file
  fclfile << std::endl;
  fclfile << "END_PROLOG" << std::endl;
  fclfile.close();

  std::cout << std::endl;
  std::cout << "done generating universes:  " << filename << std::endl;
}
