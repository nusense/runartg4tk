#! /usr/bin/env bash

export OUTPUTTOP=/pnfs/geant4/persistent/rhatcher/genana_g4vmp
export MULTIVERSE=multiverse170208_Bertini

export DESTDIR=${OUTPUTTOP}/${MULTIVERSE}

#

for d in ${DESTDIR}/* ; do

  if [ ! -d $d ]; then continue ; fi
  dbase=`basename $d`
  echo " ===== $d"

  # look for products but missing .hist.root files
  extlist="fcl out err"
  extlist=""
  for ext in ${extlist} ; do
    for f in ${d}/*.${ext} ; do
      if [ ! -f ${f} ]; then continue ; fi
      fbase=`basename $f .${ext}`
      # echo "$f $fbase $ext "
      lookfor=$d/${fbase}.hist.root
      # echo "$lookfor"
      if [ ! -f ${lookfor} ]; then
        echo $f has no .hist.root
        rm -f ${f}
      fi
    done # files w/ ext
  done # ext

  for x in `seq 0 9` ; do
  for y in `seq 0 9` ; do
    # is there one that covers 10 universes?
    lookfor_orig=${dbase}_U0${x}${y}0_0${x}${y}9.hist.root
    if [ -f ${d}/${lookfor_orig} ]; then
      # echo found ${lookfor_orig}
      for uu in 0${x}${y}0_0${x}${y}1 \
                0${x}${y}2_0${x}${y}3 \
                0${x}${y}4_0${x}${y}5 \
                0${x}${y}6_0${x}${y}7 \
                0${x}${y}8_0${x}${y}9 ; do
        # is that one that covers 2 universes that overlaps
        lookfor_new=${dbase}_U${uu}.hist.root
        if [ -f ${d}/${lookfor_new} ]; then
          echo "${lookfor_orig} exits as does one for ${uu}"
          rm -f ${d}/${lookfor_new}
        fi
      done
    fi
  done
  done

done  # exptsetup