
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
TFile*      get_output_file(const std::string& outpath,
                            const std::string& physmodel,
                            const std::string& scanid,
                            const std::string& exptname,
                            const std::string& exptsetup);


// rename data histograms
// re-name, re-title, re-bin MC histograms

TH1D* regularize_data_hist(const TH1D* hedold);
TH1D* find_data_match(const std::vector<TH1D*>& vhed,const TH1D* hmc);
TH1D* regularize_mc_hist(const TH1D* hmc,const TH1D* hdata);


//--------------------------------------------------------------
void extract_universes(std::string infiles, std::string outpath) {

  // main routine

  // expand ~ + $ENV; then wildcard pattern to list of files
  std::string infilesExpanded = gSystem->ExpandPathName(infiles.c_str());
  std::set<std::string> filenames = fetch_file_list(infilesExpanded);

  std::set<std::string>::const_iterator fitr = filenames.begin();
  for ( ; fitr != filenames.end(); ++fitr ) {
    std::string filename = *fitr;
    TFile* tfile = TFile::Open( filename.c_str(), "READONLY");
    if ( tfile->IsZombie() ) {
      cerr << "...... " << *fitr << " is a zombie" << endl;
      continue;
    }
    cout << "start processing file " << filename << endl;

    std::set<std::string> dir_list = fetch_directory_list(tfile);
    cout << "processing: " << setw(4) << dir_list.size() << " univ+expt in "
         << *fitr << endl;
    int idir = 0;
    std::set<std::string>::const_iterator ditr = dir_list.begin();
    for ( ; ditr != dir_list.end(); ++ditr ) {
      std::string dirname   = *ditr;
      cout << "[" << setw(3) << idir++ << "] " << dirname << endl;
      std::string scanid    = directory_to_scanid(dirname);    // "0000" ..
      std::string exptname  = directory_to_exptname(dirname);  // "HARP" "ITEP"
      std::string exptsetup = filename_to_exptsetup(filename); // piplus_5p0Gev_on_C
      std::string physmodel = directory_to_physmodel(dirname);

      vector<TH1D*> vhed = fetch_hists(tfile,dirname,"ExpData");
      if ( vhed.size() == 0 ) {
        // we NEED this ExptData histograms to know binning
        // each universe's subdir should have the same ...
        // so try a different subdir
        std::set<std::string>::const_iterator ditr2 = dir_list.begin();
        for ( ; ditr2 != dir_list.end(); ++ditr2 ) {
          std::string dirname2   = *ditr2;
          vector<TH1D*> vhed = fetch_hists(tfile,dirname2,"ExpData");
          if ( vhed.size() != 0 ) {
            cout << "...could not find ExpData in " << dirname
                 << " so using histograms from " << dirname2 << endl;
            break;  // found one, so we can move on
          }
        }
        // if we fall through with nothing ...
        if ( vhed.size() == 0 ) {
          cerr << "...Failed to get ExpData for any subdir in this file"
               << endl;
          continue; // nada, move to next file
        }
      }
      vector<TH1D*> vhmc = fetch_hists(tfile,dirname);

      cout << dirname << " had " << vhmc.size() << " mc and "
           << vhed.size() << " data histograms" << endl;

      std::string exptsetup_alt = dossier_to_exptsetup(vhed);
      cout << "   scanid " << scanid << " exptname " << exptname
           << " exptsetup " << exptsetup
           << " alt exptsetup " << exptsetup_alt << endl;
      if ( exptsetup != exptsetup_alt ) {
        cerr << "exptsetup mismatch '" << exptsetup << "' '"
             << exptsetup_alt << "' <================RWH " << endl;
        bool bad_dossier = ( exptsetup_alt.find("bad_dossier_name")   != std::string::npos );
        bool no_dossier  = ( exptsetup_alt.find("no_dossier_info")    != std::string::npos );
        bool bad_fname   = ( exptsetup.find("bad_filename_exptsetup") != std::string::npos );
        if ( bad_fname ) {
          // filename didn't work ...
          if ( bad_dossier || no_dossier ) {
            cout << "...bailing out of directory " << dirname << endl;
            continue; // exit this loop's iteration ... go on to next directory
            // TODO:  really should clean up vhmc & vhed
          }
          // use what we found in dossier
          exptsetup = exptsetup_alt;
        }
      }

      // !!!! finally do something ...
      // make the directories (& root files + subdir) if they don't yet exist
      // cd into the appropriate in-file subdir

      cout << "=== process ExpData histograms" << endl;
      // process data histograms
      TFile* filedata = get_output_file(outpath,"data",scanid,
                                        exptname,exptsetup);

      // here we make copies w/ new names (but leave titles)
      for (size_t ih=0; ih<vhed.size(); ++ih) {
        TH1D* hedold = vhed[ih];
        TH1D* hednew = regularize_data_hist(hedold);
        hednew->Write();
        delete hednew;
      }
      // done w/ data output file/subdir
      filedata->Write();
      filedata->Close();
      delete filedata;
      filedata = 0;


      cout << "=== process MC histograms" << endl;
      // process MC histograms
      TFile* filemc   = get_output_file(outpath,physmodel,scanid,
                                        exptname,exptsetup);
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
          TH1D* hmcnew   = regularize_mc_hist(hmcold,hedmatch);
          hmcnew->Write();
          delete hmcnew;
          ++nmc_written;
        }
      }
      cout << "... wrote " << vhed.size() << " data and "
           << nmc_written << " mc histograms" << endl;
      if ( vhed.size() != nmc_written ) {
        cerr << "...THIS DIDN'T MATCH "
             << "' <================RWH " << endl;
      }
      // done w/ MC output file/subdir
      filemc->Write();
      filemc->Close();
      delete filemc;
      filemc   = 0;

      // clean up
      for (size_t ih=0; ih<vhmc.size(); ++ih) { delete vhmc[ih]; vhmc[ih]=0; }
      for (size_t ih=0; ih<vhed.size(); ++ih) { delete vhed[ih]; vhed[ih]=0; }

      cout << "...done with directory " << dirname << endl;
    }
    dir_list.clear();
    tfile->Close();
    tfile = 0;
    cout << "...... done with file " << filename << endl;
  }
}

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

std::vector<TH1D*> fetch_hists(TFile* f, std::string dirname, std::string sub) {

  std::vector<TH1D*> list;
  bool verbose = true;

  string infolder = dirname;
  if ( sub != "" ) infolder += ( std::string("/") + sub );
  TDirectory *d = f->GetDirectory(infolder.c_str());

  if (verbose) {
    cout << "looking in " << infolder << endl;
  }
  if ( ! d ) {
    cout << "   no such directory!" << endl;
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

  if (verbose) {
    cout << "   " << list.size() << " histograms" << endl;
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
  // /path/piminus_on_Cu_at_5GeV_Bertini_analysis_U0001-U0010.hist.root
  std::string ftmp = filename;
  size_t pslash = ftmp.find_last_of('/');
  if ( pslash != std::string::npos ) {
    ftmp.erase(0,pslash+1);
  }
  size_t p4 = find_nth(ftmp,0,"_",4);
  if ( p4 != std::string::npos ) return ftmp.substr(0,p4);  // start,n
  else return "bad_filename_exptsetup";
}
std::string dossier_to_exptsetup(const vector<TH1D*>& vhdata) {
  // do transformations to bring in alignment with
  //    piminus_on_Cu_at_5GeV
  // examples are:
  //   Production of pi- in pi- on Cu interactions at 5GeV/c, theta range
  //   Production of pi- in proton-Cu interactions at 5GeV/c
  std::string result = "no_dossier_info";
  if ( vhdata.empty() ) return result;

  // remove any leading trailing whitespace
  std::string trial = trim((vhdata[0])->GetTitle());
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
  size_t pos = find_nth(trial,0,"_",1);
  //cout << "trial is \"" << trial << "\"  pos = " << pos << endl;
  if ( pos == std::string::npos ) {
    return std::string("bad_dossier_name_") + trial;
  }
  result = trial.substr(pos+1,std::string::npos);

  return result;
}


//////////////////////////////////////////////////////////////////////////

TFile* get_output_file(const std::string& outpath,
                       const std::string& physmodel,
                       const std::string& scanid,
                       const std::string& exptname,
                       const std::string& exptsetup) {

  //  [outpath]/Bertini/scan/0000/thin_target_hist.root
  //  [outpath]/data/scan/0000/thin_target_hist.root

  //     in thin_target_hist.root
  //         HARP/piplus_on_Cu_at_5GeV/
  //               TH1D name  harp_piplus_5p0GeV_on_C_to_piplus_<anglerange>
  //                    title piplus_<anglerange>

  std::string path   = outpath + "/" + physmodel + "/scan/" + scanid;

  // make the filesystem path
  // note bizarre return value convention: FALSE if one _can_ access file
  if ( gSystem->AccessPathName(path.c_str(),kWritePermission) == true )
       gSystem->mkdir(path.c_str(),true);

  // make the ROOT file
  //     NEW or CREATE - new for writing, fail if exists
  //     RECREATE  - new overwritten
  //     UPDATE    - open existing, if no file created
  //     READ      - only read access
  const char* opt = "UPDATE";
  path   += "/thin_target_hist.root";
  if ( gSystem->AccessPathName(path.c_str(),kWritePermission) == true )
    opt = "NEW";  // not strictly necessary, could use UPDATE

  if (gVerbose)
    cout << "   get_output_file TFile::Open(" << path << "," << opt << ")" << endl;

  TFile* outfile = TFile::Open(path.c_str(),opt);
  if ( ! outfile || outfile->IsZombie() ) {
    cerr << "problem openning " << opt << " file " << path << endl;
    return 0;
  }

  // make the appropriate subdirectory _in_ the file
  outfile->cd();
  if (gVerbose)
    cout << "   // outfile = " << outfile->GetName() << endl;

  // check if <exptname>/<exptsetup> directory exists w/ GetDirectory()
  std::string infilepath = exptname + "/" + exptsetup;
  TDirectory* adir   = outfile->GetDirectory(infilepath.c_str());
  // create if necessary, but move to that directory
  if ( ! adir ) {
    adir   = outfile->mkdir(infilepath.c_str());
    if (gVerbose)
      cout << "   outfile->mkdir(" << infilepath << ")" << endl;
  }
  bool okay = outfile->cd(infilepath.c_str());
  if (gVerbose)
    cout << "   outfile->cd(" << infilepath << "); // returned " << (okay?"okay":"not-okay") << endl;

  if ( ! okay ) {
    cerr << " ... failed to cd() into subdir '" << infilepath << "' of "
         << path << endl << std::flush;
    exit(42);
  }

  if (gVerbose)
    cout << "   gDirectory->GetName() // = " << (gDirectory)->GetName() << endl;

  return outfile;
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
      cout << newname << " bin " << ibin << "/" << ibin_old
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
