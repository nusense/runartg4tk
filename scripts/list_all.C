#include <iostream>
#include <iomanip>
#include "TFile.h"
#include "TDirectory.h"
#include "TH1.h"
#include "TH2.h"

void list_sub(TFile* f1, std::string path, int level) {
  ++level;
  std::string indent = "  ";
  for (int i=0; i<level; ++i) indent += "  ";
  std::cout << path << std::endl;

  f1->cd(path.c_str());
  TList* listOfKeys = gDirectory->GetListOfKeys();
  listOfKeys->Sort(); // ! don't depend on returned order
  TKey *key;

  // process histograms at this level
  TIter keyHistItr(listOfKeys);
  std::string prevTitle = "";
  while ((key = (TKey*)keyHistItr())) {
    TClass *cl = gROOT->GetClass(key->GetClassName());
    if ( ! cl->InheritsFrom("TH1") ) continue;
    TH1 *h = (TH1*)key->ReadObj();
    std::string currName  = h->GetName();
    std::string currTitle = h->GetTitle();
    if ( currTitle != prevTitle ) {
      std::cout << indent << "  " << currName << " | " << currTitle
        << " ;" << key->GetCycle()
                << " [" << key->GetClassName() << "]"
                << std::endl;
    }
    prevTitle = currTitle;
  }

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
