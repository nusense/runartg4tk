/*

Loop over _summed_ files (all universes for one exptsetup)
  For each _summed_ file looks like:

     file:  summed/piplus_on_C_at_5GeV.sum.hist.root
     /
     //BertiniDefaultHARP
        NSec | Number of secondary per inelastic interaction ;1 [TH1D]
        piminus_FW_0 | 0.05<theta<0.1 [rad] ;1 [TH1D]
        piminus_FW_1 | 0.1<theta<0.15 [rad] ;1 [TH1D]
        piminus_FW_2 | 0.15<theta<0.2 [rad] ;1 [TH1D]
        ...
     //BertiniDefaultHARP/ExpData
        ExpDataR9901 | Production of pi+ in pi+ on C interactions at 5GeV/c, 0.05<theta<0.1 [rad] ;1 [TH1D]
        ExpDataR9902 | Production of pi+ in pi+ on C interactions at 5GeV/c, 0.1<theta<0.15 [rad] ;1 [TH1D]
        ExpDataR9903 | Production of pi+ in pi+ on C interactions at 5GeV/c, 0.15<theta<0.2 [rad] ;1 [TH1D]
        ...
     //BertiniDefaultHARP/Plots
     //BertiniDefaultITEP
        NSec | Number of secondary per inelastic interaction ;1 [TH1D]
        neutron_at_0.00011GeV | EKin=0.00011GeV ;1 [TH1D]
        neutron_at_0.00013GeV | EKin=0.00013GeV ;1 [TH1D]
        neutron_at_0.00015GeV | EKin=0.00015GeV ;1 [TH1D]
        ...
     //BertiniDefaultITEP/ExpData
        ExpDataR2192 | Production of proton in pi+ on C interactions at 5GeV/c, theta=59.1 [deg] ;1 [TH1D]
        ExpDataR2193 | Production of proton in pi+ on C interactions at 5GeV/c, theta=89.0 [deg] ;1 [TH1D]
        ExpDataR2194 | Production of proton in pi+ on C interactions at 5GeV/c, theta=119.0 [deg] ;1 [TH1D]
        ExpDataR2195 | Production of proton in pi+ on C interactions at 5GeV/c, theta=159.6 [deg] ;1 [TH1D]
        ExpDataR2201 | Production of neutron in pi+ on C interactions at 5GeV/c, theta=119.0 [deg] ;1 [TH1D]
        ...
     //BertiniDefaultITEP/Plots
     //BertiniRandomUniv0001HARP
        NSec | Number of secondary per inelastic interaction ;1 [TH1D]
        piminus_FW_0 | 0.05<theta<0.1 [rad] ;1 [TH1D]
        piminus_FW_1 | 0.1<theta<0.15 [rad] ;1 [TH1D]
        ...

   we want (individual data or universe) output files that look like:

     //HARP
     //HARP/piplus_on_C_at_5GeV
     //HARP/piplus_on_C_at_5GeV/piminus
        piminus_0p05_theta_0p1_rad | Production of pi- in pi+ on C interactions at 5GeV/c, 0.05<theta<0.1 [rad] ;1 [TH1D]
        piminus_0p15_theta_0p2_rad | Production of pi- in pi+ on C interactions at 5GeV/c, 0.15<theta<0.2 [rad] ;1 [TH1D]
        piminus_0p1_theta_0p15_rad | Production of pi- in pi+ on C interactions at 5GeV/c, 0.1<theta<0.15 [rad] ;1 [TH1D]
        piminus_0p2_theta_0p25_rad | Production of pi- in pi+ on C interactions at 5GeV/c, 0.2<theta<0.25 [rad] ;1 [TH1D]
        piminus_0p35_theta_0p55_rad | Production of pi- in pi+ on C interactions at 5GeV/c, 0.35<theta<0.55 [rad] ;1 [TH1D]
        piminus_0p55_theta_0p75_rad | Production of pi- in pi+ on C interactions at 5GeV/c, 0.55<theta<0.75 [rad] ;1 [TH1D]
        piminus_0p75_theta_0p95_rad | Production of pi- in pi+ on C interactions at 5GeV/c, 0.75<theta<0.95 [rad] ;1 [TH1D]
        piminus_0p95_theta_1p15_rad | Production of pi- in pi+ on C interactions at 5GeV/c, 0.95<theta<1.15 [rad] ;1 [TH1D]
        piminus_1p15_theta_1p35_rad | Production of pi- in pi+ on C interactions at 5GeV/c, 1.15<theta<1.35 [rad] ;1 [TH1D]
        piminus_1p35_theta_1p55_rad | Production of pi- in pi+ on C interactions at 5GeV/c, 1.35<theta<1.55 [rad] ;1 [TH1D]
        piminus_1p55_theta_1p75_rad | Production of pi- in pi+ on C interactions at 5GeV/c, 1.55<theta<1.75 [rad] ;1 [TH1D]
        piminus_1p75_theta_1p95_rad | Production of pi- in pi+ on C interactions at 5GeV/c, 1.75<theta<1.95 [rad] ;1 [TH1D]
        piminus_1p95_theta_2p15_rad | Production of pi- in pi+ on C interactions at 5GeV/c, 1.95<theta<2.15 [rad] ;1 [TH1D]
     //HARP/piplus_on_C_at_5GeV/piplus
        piplus_0p05_theta_0p1_rad | Production of pi+ in pi+ on C interactions at 5GeV/c, 0.05<theta<0.1 [rad] ;1 [TH1D]
        piplus_0p15_theta_0p2_rad | Production of pi+ in pi+ on C interactions at 5GeV/c, 0.15<theta<0.2 [rad] ;1 [TH1D]
        piplus_0p1_theta_0p15_rad | Production of pi+ in pi+ on C interactions at 5GeV/c, 0.1<theta<0.15 [rad] ;1 [TH1D]
        piplus_0p2_theta_0p25_rad | Production of pi+ in pi+ on C interactions at 5GeV/c, 0.2<theta<0.25 [rad] ;1 [TH1D]
        piplus_0p35_theta_0p55_rad | Production of pi+ in pi+ on C interactions at 5GeV/c, 0.35<theta<0.55 [rad] ;1 [TH1D]
        piplus_0p55_theta_0p75_rad | Production of pi+ in pi+ on C interactions at 5GeV/c, 0.55<theta<0.75 [rad] ;1 [TH1D]
        piplus_0p75_theta_0p95_rad | Production of pi+ in pi+ on C interactions at 5GeV/c, 0.75<theta<0.95 [rad] ;1 [TH1D]
        piplus_0p95_theta_1p15_rad | Production of pi+ in pi+ on C interactions at 5GeV/c, 0.95<theta<1.15 [rad] ;1 [TH1D]
        piplus_1p15_theta_1p35_rad | Production of pi+ in pi+ on C interactions at 5GeV/c, 1.15<theta<1.35 [rad] ;1 [TH1D]
        piplus_1p35_theta_1p55_rad | Production of pi+ in pi+ on C interactions at 5GeV/c, 1.35<theta<1.55 [rad] ;1 [TH1D]
        piplus_1p55_theta_1p75_rad | Production of pi+ in pi+ on C interactions at 5GeV/c, 1.55<theta<1.75 [rad] ;1 [TH1D]
        piplus_1p75_theta_1p95_rad | Production of pi+ in pi+ on C interactions at 5GeV/c, 1.75<theta<1.95 [rad] ;1 [TH1D]
        piplus_1p95_theta_2p15_rad | Production of pi+ in pi+ on C interactions at 5GeV/c, 1.95<theta<2.15 [rad] ;1 [TH1D]
     //ITEP
     //ITEP/piplus_on_C_at_5GeV
     //ITEP/piplus_on_C_at_5GeV/neutron
        neutron_theta_119p0_deg | Production of neutron in pi+ on C interactions at 5GeV/c, theta=119.0 [deg] ;1 [TH1D]
     //ITEP/piplus_on_C_at_5GeV/proton
        proton_theta_119p0_deg | Production of proton in pi+ on C interactions at 5GeV/c, theta=119.0 [deg] ;1 [TH1D]
        proton_theta_159p6_deg | Production of proton in pi+ on C interactions at 5GeV/c, theta=159.6 [deg] ;1 [TH1D]
        proton_theta_59p1_deg | Production of proton in pi+ on C interactions at 5GeV/c, theta=59.1 [deg] ;1 [TH1D]
        proton_theta_89p0_deg | Production of proton in pi+ on C interactions at 5GeV/c, theta=89.0 [deg] ;1 [TH1D]

 */

#include <iostream>
#include <iomanip>
#include <string>
#include <vector>
#include <set>
#include <map>
#include <algorithm>
#include <sstream>
using namespace std;  // I'm lazy

#include <glob.h>
#include <math.h>
#include <cstdlib>  // [un]setenv

#include "TROOT.h"
#include "TKey.h"
#include "TClass.h"

#include "TDirectory.h"
#include "TFile.h"
#include "TCanvas.h"
#include "TH1D.h"
#include "TSystem.h"

// globals (bah, I'm so naughty)
bool gVerbose = true;

// forward declarations
void         extract_universes(std::string infiles="./summed/*_on_*_at_*.hist.root",
                               std::string outpath="./extracted");
std::set<std::string>  fetch_file_list(std::string infiles);
std::set<std::string>  fetch_directory_list(TFile* f, bool verbose = true);
std::string            directory_to_physmodel(const std::string& dirname);
std::string            directory_to_scanid(const std::string& dirname);
std::string            directory_to_exptname(const std::string& filename);
std::string            filename_to_exptsetup(const std::string& filename);
std::string            dossier_to_newrootpath(const std::string& exptname,
                                              const std::string& exptsetup,
                                              const TH1D* vhdata);

std::vector<TH1D*>     fetch_hists(TFile* f, std::string dirname,
                                   std::string sub="",
                                   int verbose=1);

  // e.g. scan/0000 (also make scan/0000/data) with Default ==> 0000

  //  [outpath]/Bertini/scan/0000/thin_target_hist.root
  //  [outpath]/data/scan/0000/thin_target_hist.root
  //               (but all 0000 : XXXX are identical)

  //     in thin_target_hist.root
  //         HARP/piplus_on_Cu_at_5GeV/
  //               TH1D name  harp_piplus_5p0GeV_on_C_to_piplus_<anglerange>
  //                    title piplus_<anglerange>

  // existing name "piminus_FW_0" title "0.05<theta<0.1 [rad]"
  //               "ExpDataRXXXX" title "Production of pi+ in pi- on Cu interactions at 5GeV/c, 0.15<theta<0.2 [rad]"
void get_output_file_and_path(TFile*& outfile,                  // in: current file,  out: new file
                              const std::string& outpath,      // "./extracted"
                              const std::string& filepath,     // "Bertini/scan/0009" or "data" (or "dossier")
                              const std::string& newrootpath,  // "/HARP/piplus_on_C_at_1GeV/piminus/
                              const std::string& exptsetup,    //       "piplus_on_C_at_1GeV"
                              int verbose=0);


// if "useGlobalName" is set, then use this file name
// otherwise base it off of "exptsetup"
bool useGlobalName=false;
std::string globalFileName = "thin_target.hist.root";

// rename data histograms
// re-name, re-title, re-bin MC histograms

TH1D* regularize_data_hist(const TH1D* hedold);
TH1D* find_data_match(const std::vector<TH1D*>& vhed,const TH1D* hmc);
TH1D* regularize_mc_hist(const TH1D* hmc,const TH1D* hdata);

// utility function
std::vector<std::string> tokenizeString(std::string values,
                                        std::string sepchar);


//--------------------------------------------------------------
void extract_universes(std::string infiles, std::string outpath) {

  // main routine

  // expand ~ + $ENV; then wildcard pattern to list of files
  std::string infilesExpanded = gSystem->ExpandPathName(infiles.c_str());
  std::set<std::string> filenames = fetch_file_list(infilesExpanded);

  // two passes ... once to process "data" the other for the "mc"

  // pass 0:  collect a full set of "ExptData" histograms
  //     "ExptDataRXXX" = histogram name (XXXX=dossier record #)
  //     mapped to where it was found:   <file>:<dirname>:<newpath>:<nbins>:<nentries>:
  //        e.g. <file>://BertiniDefaultITEP/ExpData:ITEP/piplus_on_C_at_5GeV/piminus:<nbins>:<nentries>
  std::map<std::string,std::string> dossier2path;
  std::map<std::string,TH1D*>       dossier2th1d;

  // ITEP/piplux_on_C_at_5GeV :  all the data hists independent of result product
  std::map<std::string,std::vector<TH1D*> > exptinfo2datahists;

  TFile* tfdossier = 0;
  TFile* tfdata    = 0;
  TFile* tfmc      = 0;

  for (int domc = 0; domc <= 1; ++domc ) {

    cout << "start domc=" << domc << endl << flush;

    std::set<std::string>::const_iterator fitr = filenames.begin();
    for ( ; fitr != filenames.end(); ++fitr ) {
      std::string filename = *fitr;
      TFile* tfile = TFile::Open( filename.c_str(), "READONLY");
      if ( tfile->IsZombie() ) {
        cerr << "...... " << *fitr << " is a zombie" << endl;
        continue;
      }
      cout << endl << "start processing file " << filename << endl << flush;

      std::set<std::string> dir_list = fetch_directory_list(tfile,false);
      cout << "processing: " << setw(4) << dir_list.size() << " univ+expt in "
           << filename << endl << flush;

      int idir = 0;
      std::string scanid    = ""; // "0000" ..
      std::string exptname  = ""; // "HARP" "ITEP"
      std::string exptsetup = ""; // piplus_5p0Gev_on_C
      std::string physmodel = ""; // Bertini
      std::string product   = ""; // Production of [piminus|piplus|proton|neutron]
      std::string exptinfo  = ""; //  "<exptname>/<exptsetup>"

      exptsetup = filename_to_exptsetup(filename);
      cout << "  guessed exptsetup: " << exptsetup << endl << flush;

      idir = 0;
      std::set<std::string>::const_iterator ditr1 = dir_list.begin();
      for ( ; ditr1 != dir_list.end(); ++ditr1 ) {
        std::string dirname   = *ditr1;

        cout << "[" << setw(4) << idir++ << "] " << dirname << flush;
        scanid    = directory_to_scanid(dirname);
        exptname  = directory_to_exptname(dirname);
        physmodel = directory_to_physmodel(dirname);

        exptinfo  = exptname + "/" + exptsetup;

        //==============================================================
        // pass 0 ... handle data
        //==============================================================
        if ( domc == 0 ) {
          vector<TH1D*> vhed = fetch_hists(tfile,dirname,"ExpData",0);

          cout << dirname << " had "
               << vhed.size() << " data histograms" << '\r' << flush;

          for (size_t ih=0; ih<vhed.size(); ++ih) {
            std::ostringstream datainfo_oss;
            TH1D* hedold = vhed[ih];
            std::string hname = hedold->GetName();
            std::string newrootpath = dossier_to_newrootpath(exptname,exptsetup,hedold);
            datainfo_oss << filename << ":" << dirname
                         << std::string(":\n  :")
                         << newrootpath
                         << std::string(":\n    :")
                         << std::string(hedold->GetTitle())
                         << std::string(":\n     xbins xmin xmax entries:")
                         << hedold->GetNbinsX()
                         << ":" << hedold->GetXaxis()->GetXmin()
                         << ":" << hedold->GetXaxis()->GetXmax()
                         << ":" << hedold->GetEntries();
            std::string datainfo = datainfo_oss.str();
            std::string currEntry = dossier2path[hname];
            if ( currEntry == "" ) {
              // not yet seen
              std::cout << endl << "adding " << hname << ":: " << datainfo << std::endl;
              dossier2path[hname] = datainfo;

              // write this unmolested version into "dossier" file
              get_output_file_and_path(tfdossier,outpath,"dossier",newrootpath,exptsetup,0);
              hedold->Write();
              hedold->SetDirectory(0); // now disconnect from file
              dossier2th1d[hname] = hedold; // save a copy w/ this lookup
              exptinfo2datahists[exptinfo].push_back(hedold); // and another

              // write a regularized version into "data" file
              get_output_file_and_path(tfdata,outpath,"data",newrootpath,exptsetup,0);

              TH1D* hednew = regularize_data_hist(hedold);
              hednew->Write();
              hednew->SetDirectory(0); // now disconnect hist from file

            } else {
              // entry exists ... isn't going to match because of <dirname>
              // and possibly <file>
              // remove 1st & 2nd field
              std::vector<std::string> currEntryFields = tokenizeString(currEntry,":");
              std::vector<std::string> datainfoFields  = tokenizeString(datainfo,":");
              bool same = true;
              size_t n = min(currEntryFields.size(),datainfoFields.size());
              for (size_t i = 2; i < n; ++i) {
                if ( currEntryFields[i] != datainfoFields[i] ) same = false;
              }
              if ( ! same ) {
                // there but mismatch
                // code needed here to decide which one to use ...
                std::cout << endl << "CONFLICT for " << hname << std::endl
                          << currEntry << std::endl
                          << datainfo  << std::endl;
              } // ! same
            } // already entry in dossier2path
          } // loop over data histograms in the rootdirectory
        } // domc == 0

        //==============================================================
        // pass 1 ... handle mc
        //==============================================================
        if ( domc == 1 ) {
          cout << "=== process mc histograms exptinfo "
               << exptinfo << " scanid " << scanid << flush;

          vector<TH1D*> vhmc = fetch_hists(tfile,dirname,"",0);

          // find all the relevant data histograms
          std::vector<TH1D*> vhed = exptinfo2datahists[exptinfo];

          std::string filepath = physmodel + "/scan/" + scanid;

          // here we make copies w/ new names, titles, binning (to match data)
          size_t nmc_written = 0;
          for (size_t ih=0; ih<vhmc.size(); ++ih) {
            TH1D* hmcold   = vhmc[ih];
            // skip MC only histograms
            std::string mcname = hmcold->GetName();
            if ( mcname.find("NSec") != std::string::npos ) continue;
            if ( mcname.find("GeV")  != std::string::npos ) continue;

            TH1D* hedmatch = find_data_match(vhed,hmcold);

            // not all MC hist have actual data ...
            if ( hedmatch != 0 ) {

              std::string newrootpath = dossier_to_newrootpath(exptname,exptsetup,hedmatch);

              get_output_file_and_path(tfmc,outpath,filepath,newrootpath,exptsetup,0);

              TH1D* hmcnew   = regularize_mc_hist(hmcold,hedmatch);
              hmcnew->Write();
              delete hmcnew;
              ++nmc_written;

            } // hedmatch
          } // loop of mc histograms

          // clean up
          for (size_t ih=0; ih<vhmc.size(); ++ih) { delete vhmc[ih]; vhmc[ih]=0; }

          cout << "... wrote " << setw(3) << nmc_written << " mc histograms" << '\r' << flush;
          if ( vhed.size() != nmc_written ) {
            cerr << endl << "ERROR ...THIS DIDN'T MATCH " << vhed.size() << " vs. "
                 << nmc_written << "' <================RWH " << endl;
          }

        } // domc == 1

      // for (size_t ih=0; ih<vhed_union.size(); ++ih) { delete vhed_union[ih]; vhed_union[ih]=0; }

      //cout << "...done with directory " << dirname << endl;
      //static int count_down = 20;
      //if ( --count_down == 0 ) exit(1);

      } // loop over directories

      std::cout << endl << "..clear dir_list for " << filename << '\r' << flush;
      dir_list.clear();
      std::cout << "..close file         " << filename << '\r' << flush;
      tfile->Close();  // this seems particularly slow for some reason
      delete tfile;
      tfile = 0;

      std::cout << "...... done with file " << filename << std::endl << flush;
      if ( domc == 0 ) {
        std::cout << "dossier2path has "
                  << dossier2path.size() << " entries" << std::endl << flush;
      }
    } // loop over files

    cout << "done domc=" << domc << endl;

  } // loop "data" or "mc"

  // clean up
  get_output_file_and_path(tfdossier,"close","close","","",1);
  get_output_file_and_path(tfdata,"close","close","","",1);
  get_output_file_and_path(tfmc,"close","close","","",1);

} // extract_universe()

std::set<std::string> fetch_file_list(std::string infiles) {
  std::set<std::string> list;

  glob_t g;  // struct on stack will go away
  int flags = GLOB_TILDE;
  glob(infiles.c_str(),flags,NULL,&g);

  int nfiles = g.gl_pathc;
  if ( nfiles == 0 ) {
    cerr << "infiles \"" << infiles << "\" resolved to 0 files" << endl;
    return list;
  }
  for (int ifile=0; ifile < nfiles; ++ifile) {
    list.insert(g.gl_pathv[ifile]);
  }
  cout << "fetch_file_list returned " << list.size() << " entries" << endl;
  return list;
}

std::set<std::string> fetch_directory_list(TFile* f, bool verbose) {
  std::set<std::string> list;

   TIter next(f->GetListOfKeys());
   TKey *key;
   while ((key = (TKey*)next())) {
     //cout << " found a " << key->GetClassName() << endl;
     TClass *cl = gROOT->GetClass(key->GetClassName());
     if ( ! cl->InheritsFrom("TDirectory") ) continue;
     list.insert( key->GetName() );
   }

   if (verbose) {
     cout << "   " << list.size() << " universes" << endl;
     std::set<std::string>::const_iterator uitr = list.begin();
     for ( ; uitr != list.end(); ++uitr ) {
       cout << "       " << *uitr << endl;
     }
   }

   return list;
}

std::vector<TH1D*> fetch_hists(TFile* f, std::string dirname,
                               std::string sub, int verbose) {

  std::vector<TH1D*> list;

  string infolder = dirname;
  if ( sub != "" ) infolder += ( std::string("/") + sub );
  TDirectory *d = f->GetDirectory(infolder.c_str());

  if (verbose) {
    cout << "looking in " << infolder << endl;
  }
  if ( ! d ) {
    std::cout << endl << "   " << infolder << " no such directory!";
    if ( sub != "" ) {
      TDirectory *dup = f->GetDirectory(dirname.c_str());
      if ( dup ) {
        std::cout << " BUT " << dirname << " does exist";
      }
    }
    std::cout << endl;
    return list;
  }

  TIter next(d->GetListOfKeys());
  TKey *key = 0;
  while ((key = (TKey*)next())) {
    //cout << " found a " << key->GetClassName() << endl;
    TClass *cl = gROOT->GetClass(key->GetClassName());
    if ( ! cl->InheritsFrom("TH1D") ) continue;
    TH1D* h = 0;
    d->GetObject(key->GetName(),h);
    if ( h ) list.push_back( h );
    else {
      cout << "failed to get " << key->GetName() << endl;
    }
  }

  if (verbose) cout << "   " << list.size() << " histograms" << endl;
  if (verbose > 1) {
    std::vector<TH1D*>::const_iterator uitr = list.begin();
    for ( ; uitr != list.end(); ++uitr ) {
      TH1D* h1 = *uitr;
      cout << "       "
           << setw(25) << std::left << h1->GetName() << " | "
           << setw(3) << h1->GetNbinsX() << " | [ "
           << setw(5) << h1->GetXaxis()->GetXmin() << " : "
           << setw(6) << h1->GetXaxis()->GetXmax() << " ] | "
           << h1->GetTitle() << endl;
    }
  }
  return list;

}

// https://stackoverflow.com/questions/18972258/index-of-nth-occurrence-of-the-string
size_t find_nth(const string& haystack, size_t pos,
                const string& needle, size_t nth)
{
  // find the Nth instance of "needle" in the "haystack"
  // starting at position "pos" in haystack
  // "nth" count from 0 !!
  // return std::string::npos if instance not found

  // call using
  //   find_nth("hay_needle_stack_needle_stuff",0,"needle",0) -> 4
  //   find_nth("hay_needle_stack_needle_stuff",0,"needle",1) -> 18
  // don't try to give "pos" a non-zero value
  // return value is always relative to start of haystack
  size_t found_pos = haystack.find(needle, pos);
  if(0 == nth || string::npos == found_pos)  return found_pos;
  return find_nth(haystack, found_pos+1, needle, nth-1);
}

//////////////////////////////////////////////////////////////////////////
void test_find_nth() {
  std::string haystack = "needle_in_a_haystack";
  cout << "haystack '" << haystack << "' needle '" << "_" << "'" << endl;
  cout << "testof find_nth " << 0 << " pos " << find_nth(haystack,0,"_",0) << endl;
  cout << "testof find_nth " << 1 << " pos " << find_nth(haystack,0,"_",1) << endl;
  cout << "testof find_nth " << 2 << " pos " << find_nth(haystack,0,"_",2) << endl;
  cout << "testof find_nth " << 3 << " pos " << find_nth(haystack,0,"_",3) << endl;
  cout << "testof find_nth " << 4 << " pos " << find_nth(haystack,0,"_",4) << endl;
  cout << "haystack '" << haystack << "' needle '" << "%" << "'" << endl;
  cout << "testof find_nth " << 0 << " pos " << find_nth(haystack,0,"%",0) << endl;
  cout << "testof find_nth " << 1 << " pos " << find_nth(haystack,0,"%",1) << endl;
  cout << "start with offset 7" << endl;
  cout << "testof find_nth " << 0 << " pos " << find_nth(haystack,7,"_",0) << endl;
  cout << "testof find_nth " << 1 << " pos " << find_nth(haystack,7,"_",1) << endl;
  cout << "testof find_nth " << 2 << " pos " << find_nth(haystack,7,"_",2) << endl;
  cout << "testof find_nth " << 3 << " pos " << find_nth(haystack,7,"_",3) << endl;
  cout << "testof find_nth " << 4 << " pos " << find_nth(haystack,7,"_",4) << endl;
}
//////////////////////////////////////////////////////////////////////////

// https://stackoverflow.com/questions/2896600/how-to-replace-all-occurrences-of-a-character-in-string
void replace_all(std::string& str, const std::string& from,
                        const std::string& to) {
  size_t start_pos = 0;
  while((start_pos = str.find(from, start_pos)) != std::string::npos) {
    str.replace(start_pos, from.length(), to);
    start_pos += to.length(); // Handles case where 'to' is a substring of 'from'
  }
}


std::vector<std::string> tokenizeString(std::string values,
                                        std::string sepchar)
{
  // Separate "values" string into elements under the assumption
  // that they are separated by any of the characters in "spechar".

  std::vector<std::string> rlist;

  bool tokVerbose=false;
  if (tokVerbose)
    std::cout << "values " << values
              << " separated by \"" << sepchar << "\"" << std::endl;

  size_t pos_beg = 0;
  size_t str_end = values.size();
  while ( pos_beg != string::npos && pos_beg < str_end ) {
    size_t pos_end = values.find_first_of(sepchar.c_str(),pos_beg);
    std::string onevalue = values.substr(pos_beg,pos_end-pos_beg);
    if (tokVerbose)
      std::cout << " onevalue \"" << onevalue  << "\" in ["
                << pos_beg << "," << pos_end << ")"<< std::endl;
    pos_beg = pos_end+1;
    if ( pos_end == string::npos ) pos_beg = str_end;
    if ( onevalue != "" ) {
      rlist.push_back(onevalue);
    }
  }

  return rlist;
}

std::string trim(const std::string& str,
                 const std::string& whitespace = " \t")
{
  const size_t strBegin = str.find_first_not_of(whitespace);
  if (strBegin == std::string::npos)
    return ""; // no content

  const size_t strEnd = str.find_last_not_of(whitespace);
  const size_t strRange = strEnd - strBegin + 1;

  return str.substr(strBegin, strRange);
}

std::string directory_to_physmodel(const std::string& dirname) {
  // assume form XXXXUniv{1234}{EXPT}
  size_t p = dirname.find("Bertini");
  if ( p != std::string::npos ) return "Bertini";
  cerr << "not Bertini ... not yet supported " << dirname << endl << std::flush ;
  exit(42);
  return "no_physmodel";
}

std::string directory_to_scanid(const std::string& dirname) {
  // assume form XXXXUniv{1234}{EXPT}
  if ( dirname.find("Default") != std::string::npos ) {
    // map "Default" to 0000
    return "0000";
  }
  size_t p = dirname.find("Univ");
  if ( p == std::string::npos ) return "no_scan_id";
  return dirname.substr(p+4,4);  // (start,count)
}
std::string directory_to_exptname(const std::string& dirname) {
  // assume form XXXXUniv{1234}{EXPT}  XXXXDefault{EXPT}
  size_t p = dirname.find("Univ");
  if ( p != std::string::npos ) {
    return dirname.substr(p+8,std::string::npos);  // (start,count)
  }
  p = dirname.find("Default");
  if ( p != std::string::npos ) {
    return dirname.substr(p+7,std::string::npos);  // (start,count)
  }
  return "no_expt_name";

}
std::string filename_to_exptsetup(const std::string& filename) {
  // assume form:
  // /path/piminus_on_Cu_at_5GeV_*.hist.root
  std::string ftmp = filename;
  size_t pslash = ftmp.find_last_of('/');
  if ( pslash != std::string::npos ) {
    ftmp.erase(0,pslash+1);
  }
  size_t p4 = find_nth(ftmp,0,"_",4);
  if ( p4 != std::string::npos ) return ftmp.substr(0,p4);  // start,n
  else {
    // perhaps its' only
    // /path/piminus_on_Cu_at_5GeV.*.root
    size_t pdot = ftmp.find_first_of(".",0);
    if ( pdot != std::string::npos ) return ftmp.substr(0,pdot);
    else {
      cout << "filename_to_exptsetup fail: "
           << "'" << filename << "'" << endl
           << "pslash=" << pslash << endl
           << "'" << ftmp << "' p4=" << p4 << endl;
      exit(43);
    }
    return "bad_filename_exptsetup";
  }
}



std::string dossier_to_newrootpath(const std::string& exptname,
                                   const std::string& exptsetup,
                                   const TH1D* hdata) {
  // do transformations to bring in alignment with
  //    HARP/piminus_on_Cu_at_5GeV/piminus
  // examples are:
  //   Production of pi- in pi- on Cu interactions at 5GeV/c, theta range
  //   Production of pi- in proton-Cu interactions at 5GeV/c

  std::string result = "no_dossier_info";
  // remove any leading trailing whitespace
  std::string trial = trim(hdata->GetTitle());
  if ( exptname == "HARP" || exptname == "ITEP" ) {
    // trim off theta range bit
    size_t poscomma = trial.find_first_of(',');
    if ( poscomma != std::string::npos ) {
      trial.erase(poscomma,std::string::npos);
    }
    replace_all(trial,"pi-","piminus");
    replace_all(trial,"pi+","piplus");
    replace_all(trial,"proton-","proton on ");
    replace_all(trial,"Production of ","");
    replace_all(trial,"interactions ","");
    replace_all(trial,"GeV/c","GeV");

    // cout << "trial is \"" << trial << "\"" << endl;
    // now it should look like "piminus in piminus on Cu at 5GeV"
    replace_all(trial," ","_");

    // find 1st (as in 0,1...so really 2nd) "_" starting at 0th char
    // now it should look like "piminus_in_piminus_on_Cu_at_5GeV"
    //                              0th^  ^1th

    size_t pos_setup = find_nth(trial,0,"_",1);
    //cout << "trial is \"" << trial << "\"  pos = " << pos << endl;
    if ( pos_setup == std::string::npos ) {
      return std::string("bad_dossier_name_") + trial;
    }
    std::string exptsetup_alt =
      trial.substr(pos_setup+1,std::string::npos);
    // 1.4GeV -> 1p4GeV
    replace_all(exptsetup_alt,".","p");
    if ( exptsetup != exptsetup_alt ) {
      cerr << "ERROR: dossier_to_newrootpath passed '"
           << exptsetup << "' but extracted '"
           << exptsetup_alt << "'" << endl;
      exit(44);
    }
    result = exptname + "/" + exptsetup;

    // find "product"
    size_t pos_ = trial.find_first_of("_",0);
    result = result + "/" + trial.substr(0,pos_);
  } // HARP || ITEP

  return result;
}


//////////////////////////////////////////////////////////////////////////

void get_output_file_and_path(TFile*& outfile,
                              const std::string& outpath,
                              const std::string& filepath,
                              const std::string& newrootpath,
                              const std::string& exptsetup,
                              int verbose) {

  if (outpath == "close" && filepath == "close") {
    if ( outfile ) {
      // close current open file
      outfile->Write();
      outfile->Close();
      delete outfile;
      outfile = 0;
    }
    return;
  }


  //  [outpath]/Bertini/scan/0000/thin_target_hist.root
  //  [outpath]/data/thin_target_hist.root

  //     in thin_target_hist.root
  //         HARP/piplus_on_Cu_at_5GeV/
  //               TH1D name  harp_piplus_5p0GeV_on_C_to_piplus_<anglerange>
  //                    title piplus_<anglerange>

  std::string newPath   = outpath + "/" + filepath + "/";
  // make the filesystem path
  // note bizarre return value convention: FALSE if one _can_ access file
  if ( gSystem->AccessPathName(newPath.c_str(),kWritePermission) == true )
       gSystem->mkdir(newPath.c_str(),true);

  // make the ROOT file
  //     NEW or CREATE - new for writing, fail if exists
  //     RECREATE  - new overwritten
  //     UPDATE    - open existing, if no file created
  //     READ      - only read access
  const char* opt = "UPDATE";
  if (useGlobalName) newPath += globalFileName;
  else               newPath += exptsetup;

  if ( newPath.find(".root") != (newPath.size()-5) ) newPath += ".hist.root";

  if ( gSystem->AccessPathName(newPath.c_str(),kWritePermission) == true )
    opt = "NEW";  // not strictly necessary, could use UPDATE

  std::string currPath = "";
  if ( outfile ) currPath = outfile->GetName();
  // same file ?
  if ( currPath == newPath ) {
    // same path
    if (verbose>1)
      cout << "   get_output_file already open: " << newPath << "," << opt << ")" << endl;
  } else {
    if ( outfile ) {
      // close current open file
      outfile->Write();
      outfile->Close();
      delete outfile;
      outfile = 0;
    }
    if (verbose>1)
      cout << "   get_output_file TFile::Open(" << newPath << "," << opt << ")" << endl;
    outfile = TFile::Open(newPath.c_str(),opt);
    if ( ! outfile || outfile->IsZombie() ) {
      cerr << "problem openning " << opt << " file " << newPath << endl;
      outfile = 0;
      return;
    }
  }

  // make the appropriate subdirectory _in_ the file
  outfile->cd();
  if (verbose>1)
    cout << "   // outfile = " << outfile->GetName() << endl;

  // check if <exptname>/<exptsetup> directory exists w/ GetDirectory()

  TDirectory* adir   = outfile->GetDirectory(newrootpath.c_str());
  // create if necessary, but move to that directory
  if ( ! adir ) {
    adir   = outfile->mkdir(newrootpath.c_str());
    if (verbose>0)
      cout << "   outfile->mkdir(" << newrootpath << ")" << endl;
  }
  bool okay = outfile->cd(newrootpath.c_str());
  if ( verbose>1 || !okay )
    cout << "   outfile->cd(" << newrootpath << "); // returned " << (okay?"okay":"not-okay") << endl;

  if ( ! okay ) {
    cerr << "ERROR ... failed to cd() into subdir '" << newrootpath << "' of "
         << currPath << endl << std::flush;
    exit(42);
  }

  if (verbose>1)
    cout << "   gDirectory->GetName() // = " << (gDirectory)->GetName() << endl;

  return;
}

//////////////////////////////////////////////////////////////////////////

std::string regularize_thetastr(const std::string& thetastr_in) {
  std::string thetastr(trim(thetastr_in));
  replace_all(thetastr,".","p");       // decimal point
  replace_all(thetastr,"<","_");       // HARP
  replace_all(thetastr,"\\u003c","_"); // HARP unicode <
  replace_all(thetastr,"=","_");       // ITEP
  replace_all(thetastr," ","_");       // spaces -> _
  replace_all(thetastr,"[","");        // remove [ ]
  replace_all(thetastr,"]","");        // remove [ ]
  return thetastr;
}

  // HARP:
  //   data Name:  ExpDataR{xxxx}
  //   data Title: Production of pi- in pi- on Cu interactions at 5GeV, 0.05<theta<0.1 [rad]
  //   mc   Name:  piminus_{FW|LA}_{N}
  //   mc   Title: 0.05<thata<0.1 [rad]
  //
  //   new  Name:  piminus_0p05_theta_0p1_rad
  //   new  Title: (same as data)

  // ITEP:
  //    data Name:  ExpDataR{xxxx}
  //    data Title: Production of proton in pi- on Cut interactions at 5GeV/c, theta=119.0 [deg]
  //    mc   Name:  proton_at_119deg    # note lack of .0 here
  //    mc   Title: theta=119 [deg]     # note lack of .0 here
  //                                    # at 15, 89, 119, 177
  //
  //    new  Name:  proton_theta_119p0_deg
  //    new  Title: (same as data)

std::string prodpart_data(const TH1D* hed) {
  std::string title   = trim(hed->GetTitle());
  std::string prodpart = tokenizeString(title," ")[2];
  replace_all(prodpart,"pi-","piminus");
  replace_all(prodpart,"pi+","piplus");
  return prodpart;
}

std::string prodpart_mc(const TH1D* hmc) {
  std::string name   = trim(hmc->GetName());
  std::string prodpart = tokenizeString(name,"_")[0];
  replace_all(prodpart,"pi-","piminus");
  replace_all(prodpart,"pi+","piplus");
  return prodpart;
}

std::string thetastr_data(const TH1D* hed) {
  std::string title = hed->GetTitle();
  size_t pcomma = title.find(",");
  std::string thetastr =
    regularize_thetastr(title.substr(pcomma+1,std::string::npos));
  return thetastr;
}

std::string thetastr_mc(const TH1D* hmc) {
  std::string title = hmc->GetTitle();
  // deal with (possible) missing .0 in ITEP MC names
  size_t itepdeg = title.find(" [deg]");
  if ( itepdeg != std::string::npos ) {
    // ITEP format ...
    size_t itepdot = itepdeg - 2;
    if ( title[itepdot] != '.' ) {
      title.insert(itepdeg,".0");
    }
  }
  size_t pcomma = title.find(",");
  if ( pcomma == std::string::npos ) {
    return regularize_thetastr(title);
  } else {
    return regularize_thetastr(title.substr(pcomma+1,std::string::npos));
  }
  return "not-possible-thetastr_mc";
}


std::string regularize_data_name(const TH1D* hedold) {
  bool verbose = false;

  std::string oldname = hedold->GetName();
  std::string prodpart = prodpart_data(hedold);
  std::string thetastr = thetastr_data(hedold);

  std::string newname = prodpart + "_" + thetastr;
  if (verbose) {
    cout << "data title   " << hedold->GetTitle() << endl;
    cout << "oldname " << oldname << endl;
    cout << "newname " << newname << endl;
    cout << "prodpart '" << prodpart << "' thetastr '" << thetastr << "'" << endl;
  }
  return newname;
}

std::string regularize_mc_name(const TH1D* hmcold) {
  bool verbose = false;

  std::string oldname = hmcold->GetName();
  std::string prodpart = prodpart_mc(hmcold);
  std::string thetastr = thetastr_mc(hmcold);

  std::string newname = prodpart + "_" + thetastr;
  if (verbose) {
    cout << "mc   title   " << hmcold->GetTitle() << endl;
    cout << "oldname " << oldname << endl;
    cout << "newname " << newname << endl;
  }
  return newname;
}

TH1D* regularize_data_hist(const TH1D* hedold) {

  std::string newname = regularize_data_name(hedold);
  TH1D* hdata = (TH1D*)hedold->Clone();
  hdata->SetName(newname.c_str());
  //hdata->SetTitle(hedold->GetTitle());

  // no adjustments to contents
  return hdata;
}

TH1D* find_data_match(const std::vector<TH1D*>& vhed, const TH1D* hmc) {
  bool verbose = false;

  TH1D* hmatch = 0;
  std::string mcname  = regularize_mc_name(hmc);

  for (size_t ih=0; ih<vhed.size(); ++ih) {
    TH1D* htmp = vhed[ih];
    std::string edname = regularize_data_name(htmp);

    if ( edname == mcname ) {
      hmatch = htmp;
      break;
    }
  }
  if ( verbose && hmatch == 0 ) {
    cout << "no data match for " << regularize_mc_name(hmc) << " '"
         << hmc->GetName() << "' '" << hmc->GetTitle() << "'" << endl;
  }

  return hmatch;
}

TH1D* regularize_mc_hist(const TH1D* hmcold, const TH1D* hdata) {
  std::string newname = regularize_data_name(hdata);
  // pull binning & title from _data_ !!!
  TH1D* hmc = (TH1D*)hdata->Clone();
  hmc->SetName(newname.c_str());
  //hdata->SetTitle(hdata->GetTitle());

  // but now has data data
  hmc->Reset(); // empty
  // loop over the bins we have to fill ...
  int nbins = hmc->GetNbinsX();
  // ignore under & overflow (shouldn't be filled for data histograms
  for (int ibin=1; ibin<=nbins; ++ibin) {
    double bin_center   = hmc->GetBinCenter(ibin);
    double bin_low_edge = hmc->GetBinLowEdge(ibin);
    double bin_width    = hmc->GetBinWidth(ibin);

    int ibin_old = hmcold->FindFixBin(bin_center);  // "fix" = don't extend
    double bin_center_old   = hmcold->GetBinCenter(ibin_old);
    double bin_low_edge_old = hmcold->GetBinLowEdge(ibin_old);
    double bin_width_old    = hmcold->GetBinWidth(ibin_old);

    const double eps = 1.0e-5;
    if ( fabs(bin_center_old   - bin_center   ) > eps ||
         fabs(bin_low_edge_old - bin_low_edge ) > eps ||
         fabs(bin_width_old    - bin_width    ) > eps    ) {
      cout << endl << "ERROR: " << newname << " bin " << ibin << "/" << ibin_old
           << " mismatch " << endl
           << "   center   " << bin_center   << " " << bin_center_old << endl
           << "   low edge " << bin_low_edge << " " << bin_low_edge_old << endl
           << "   width    " << bin_width    << " " << bin_width_old << endl
           << "   <========== RWH" << endl;
    }
    double content = hmcold->GetBinContent(ibin_old);
    double error   = hmcold->GetBinError(ibin_old);

    hmc->SetBinContent(ibin,content);
    hmc->SetBinError(ibin,error);
  }
  return hmc;
}

void addUnique(std::vector<std::string>& vstrings, std::string value)
{
  // Add "value" to "vstrings" if it isn't already there.
  // We're not using std::set because we want to preserve any order
  bool found = false;
  for (unsigned int i = 0; i < vstrings.size(); ++i) {
    if ( vstrings[i] == value ) {
      found = true;
      break;
    }
  }
  if ( ! found ) vstrings.push_back(value);
}


//////////////////////////////////////////////////////////////////////////



void stuff(
    string infile="piminus_on_Cu_at_5GeV_Bertini_analysis_DEFAULT.hist.root"
                      ) {

  TFile* fin = TFile::Open(infile.c_str());

  // art labels
  //     1 BertiniDefault
  //   999 BertiniRandom4Univ0001 ... 0999
  //
  //     1 BertiniDefault
  //   100 BertiniFermiScaleStepUniv0000 : 0099
  //   100 BertiniRadiusScaleStepUniv0000 : 0099
  //   100 BertiniTrailingRadiusStepUniv0000 : 0099
  //   100 BertiniXSecScaleStepUniv0000 : 0099
  //

  // Bertini[Universe]HARP/
  //    Geant4ModelConfig/ (TObjArray size=16) version for every input file
  //    ExpData/
  //       ExpDataR[ABCD]   -- (TH1D)  ABCD = Dossier Record
  //                        title: "Production of pi- in pi- on Cu interactions at 5GeV/c, 0.1<theta<0.15 [rad]"
  //    Plots/
  //        cnv_Bertinie[Universe]HARP_pi[plus|minus]_[FW_0:3|LA_0:8]
  //    NSec (TH1D)
  //    pi[plus|minus]_[FW_0:3|LA_0:8] (TH1D)
  //    Beam_ThinTarget_Config (TNamed)  [but unreadable w/ bare root]
  //    pi[plus|minus]_RecordChi2 (TNamed)

  // Bertini[Universe]ITEP/
  //    Geant4ModelConfig/ (TObjArray size=16) version for every input file
  //    ExpData/
  //       ExpDataR[ABCD]   -- (TH1D)  ABCD = Dossier Record
  //                        title: "Production of pi- in pi- on Cu interactions at 5GeV/c, 0.1<theta<0.15 [rad]"
  //    Plots/
  //        cnv_Bertini[Universe]ITEP ... (names include . [GeV]...)
  //    NSec (TH1D)
  //    [proton|neutron]_at_XXX.Xdeg (TH1D)
  //    [proton|neutron]_at_Xe-0X [GeV]  (TH1D)
  //    Beam_ThinTarget_Config (TNamed)
  //    [proton|neutron]_RecordChi2 (TNamed)


}

/***

   TFile *f1 = TFile::Open("hsimple.root");
   TIter next(f1->GetListOfKeys());
   TKey *key;
   TCanvas c1;
   c1.Print("hsimple.ps[");
   while ((key = (TKey*)next())) {
      TClass *cl = gROOT->GetClass(key->GetClassName());
      if (!cl->InheritsFrom("TH1")) continue;
      TH1 *h = (TH1*)key->ReadObj();
      h->Draw();
      c1.Print("hsimple.ps");
   }
   c1.Print("hsimple.ps]");
}

 ***/
