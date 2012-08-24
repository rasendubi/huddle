#!/bin/bash
set -e

HuddleRoot=/huddle

tmp=/var/tmp/huddle
PackD=${HuddleRoot}/packages
IP=${HuddleRoot}/installed

dotest=true

initf()
{
  hconf(){
    ${S}/configure "$@"
  }
  hinstall(){
    make DESTDIR=${D} "$@" install
  }
  hpatch(){
    patch -Np1 -i ${PD}/files/$1
  }
  src_unpack(){
    tar xf ${PD}/files/${P}.tar* -C ${work}
  }
  src_prepare(){
    return
  }
  src_configure(){
    return
  }
  src_compile(){
    return
  }
  src_test(){
    true
  }
  install(){
    return
  }
  postinstall(){
    return
  }
  postremove(){
    return
  }
}

mkpkg(){
  if [ -e ${PackD}/${P}.tar ]; then
    echo "Using package..."
  else
    echo -n "Unpacking... "
    src_unpack
    echo "Done"
    cd ${S}
    echo -n "Preparing... "
    src_prepare
    echo "Done"
    mkdir -p ${B}
    cd ${B}
    echo -n "Configuring... "
    src_configure
    echo "Done"
    echo -n "Compiling... "
    src_compile
    echo "Done"
    if $dotest; then
      echo -n "Testing... "
      src_test
      echo "Done"
    fi
    echo -n "Installing in pkg... "
    install
    echo -n "Tarring... "
    tar -cf ${PackD}/${P}.tar -C ${D} .
    echo "Done"
    echo -n "Cleaning... "
    rm -rf ${tmp}/${P}
    echo "Done"
  fi
}

pkginstall(){
  #tar Tvf ${PackD}/${P}.tar > ${tmp}/${P}.files
  #egrep -e "/$" ${tmp}/${P}.files > ${tmp}/${P}.dirs
  #sed -e "/\/$/d" -i ${tmp}/${P}.files
  echo -n "Installing... "
  tar xvkf ${PackD}/${P}.tar -C / > ${IP}/${P}.files
  echo ${P} >> ${IP}/installed
  echo "Done"
  echo -n "Postinstall... "
  postinstall
  echo "Done"
}

cd $HuddleRoot
P=$1
if [ `echo ${P} | grep -c ^[A-Za-z-]-[0-9].*` -eq 0 ]; then
  if [ -e $HuddleRoot/$P ]; then
    P=`ls $HuddleRoot/$P/*.hd | tail -1 | xargs -I{} basename {} .hd`
    if [ "X$P" == "X" ]; then
      echo "Package does not exist..."
      exit 1
    fi
  else
    echo "Can't find package..."
    exit 1
  fi
fi

PN=`echo ${P} | sed 's/^\([A-Za-z0-9-]*\)-[0-9].*$/\1/'`
PV=`echo ${P} | sed 's/^[A-Za-z0-9-]*-\([0-9].*\)$/\1/'`
PD=$HuddleRoot/$PN
installed=`grep ^$PN-[0-9].*$ ${IP}/installed || true`
if [ "X$installed" != "X" ]; then
  up=true
else
  up=false
fi
#echo ${PN}
#echo ${PV}
cd ${PD}
work=$tmp/${P}/work
D=$work/fakeroot
S=$work/${P}
B=$work/build
mkdir -p $D

initf
source ${PD}/${P}.hd
mkpkg

if $up ; then
  initf
  source ${PD}/$installed.hd
  postremove
  sed -e "/^$installed$/d" -i ${IP}/installed

  initf 
  source ${PD}/$P.hd
fi

pkginstall

set +e
if $up && [ "$installed" != "${P}" ]; then
  set -e
  for i in `comm -2 -3 ${IP}/$installed.files ${IP}/${P}.files`; do
    rm -f /$i
  done
  rm "${IP}/$installed.files"
fi
set -e

echo "Everything seems to be fine:)"

exit 0

