#include <iostream>
#include <iomanip>
#include "TFile.h"
#include "TDirectory.h"
#include "TH1.h"
#include "TH2.h"

bool verbose = true;

void list_one_th1(std::string& indent, TKey* key) {
  TH1 *h = (TH1*)key->ReadObj();
  std::string currName  = h->GetName();
  std::string currTitle = h->GetTitle();
  std::string className = key->GetClassName();
  int         currCycle = key->GetCycle();

  //if ( currTitle != prevTitle ) {
  std::cout << indent << "  [" << className
            << ";" << std::setw(2) << currCycle << "] "
            << currName << " | " << currTitle;
  if ( verbose ) {
    std::cout << std::endl << indent << "  " << "    binning: ";
    int nb = h->GetNbinsX();
    const TArrayD& bx = *(h->GetXaxis()->GetXbins());
    int nbx = bx.GetSize();
    char sep = '{';
    cout << " nb=" << nb << " ";
    if ( nbx == 0 ) {
      std::cout << "{ uniform "
                << h->GetXaxis()->GetXmin() << ":"
                << h->GetXaxis()->GetXmax() << " ";
    } else {
      // irregular bins
      for (int i=0; i<nbx; ++i) {
        std::cout << sep << bx[i];
        sep = ',';
      }
    }
    std::cout << "}";
  } // verbose = print bin limits
  std::cout << std::endl;
  //}
  //prevTitle = currTitle;
}

void list_sub(TFile* f1, std::string path, int level) {
  ++level;
  std::string indent = "  ";
  for (int i=0; i<level; ++i) indent += "  ";
  std::cout << path << std::endl;

  f1->cd(path.c_str());
  TList* listOfKeys = gDirectory->GetListOfKeys();
  // naturally comes out ordered decreasing cycle #
  ///  listOfKeys->Sort(); // ! don't depend on returned order
  TKey *key;

  // process histograms at this level
  TIter keyHistItr(listOfKeys);
  std::string prevName = "";
  std::string currName = "";
  int         prevCycle = 0;
  int         currCycle = 0;
  std::string prevTitle = "";
  std::map<std::string,int> typecount;
  while ((key = (TKey*)keyHistItr())) {
    TClass *cl = gROOT->GetClass(key->GetClassName());

    prevName  = currName;
    prevCycle = currCycle;
    currName  = key->GetName();
    currCycle = key->GetCycle();
    std::string className = key->GetClassName();

    /*
    std::cout << " currName " << currName << ";" << currCycle
              << " prevName " << prevName << ";" << prevCycle << std::endl;
    */
    if ( currName == prevName ) continue;
    ++typecount[className];

    if ( cl->InheritsFrom("TH1") ) {
      list_one_th1(indent,key);
    }
  }
  std::cout << indent << "  Summary of directory: ";
  std::map<std::string,int>::const_iterator mitr = typecount.begin();
  for ( ; mitr != typecount.end(); ++mitr ) {
    std::cout << mitr->first << "[" << mitr->second << "] ";
  }
  std::cout << std::endl;

  TIter keyDirItr(listOfKeys);
  while ((key = (TKey*)keyDirItr())) {
    TClass *cl = gROOT->GetClass(key->GetClassName());
    if ( ! cl->InheritsFrom("TDirectory") ) continue;
    std::string subpath = path + std::string("/") + key->GetName();
    list_sub(f1,subpath,level);
  }

}

void list_all(std::string fname="data/thin_target_hist.root") {
  std::cout << "file:  " << fname << std::endl;
  TFile *f1 = TFile::Open(fname.c_str());
  list_sub(f1,"/",-1);
}
