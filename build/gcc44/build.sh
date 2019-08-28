#!/usr/bin/bash
#
# {{{ CDDL HEADER START
#
# The contents of this file are subject to the terms of the
# Common Development and Distribution License, Version 1.0 only
# (the "License").  You may not use this file except in compliance
# with the License.
#
# You can obtain a copy of the license at usr/src/OPENSOLARIS.LICENSE
# or http://www.opensolaris.org/os/licensing.
# See the License for the specific language governing permissions
# and limitations under the License.
#
# When distributing Covered Code, include this CDDL HEADER in each
# file and include the License file at usr/src/OPENSOLARIS.LICENSE.
# If applicable, add the following below this CDDL HEADER, with the
# fields enclosed by brackets "[]" replaced with your own identifying
# information: Portions Copyright [yyyy] [name of copyright owner]
#
# CDDL HEADER END }}}
#
# Copyright 2017 OmniTI Computer Consulting, Inc.  All rights reserved.
# Copyright 2019 OmniOS Community Edition (OmniOSce) Association.
# Use is subject to license terms.
#
. ../../lib/functions.sh

PROG=gcc
VER=4.4.4
#
# The ILLUMOSVER is the suffix of the tag gcc-4.4.4-<ILLUMOSVER>.
# It takes the form "il-N" for some number N.  These are announced to the
# illumos developer's list, and it is expected that OmniOSce will keep a
# copy at mirrors.omniosce.org, or local maintainers keep it whereever they
# keep their local mirrors.
#
ILLUMOSVER=il-4
VERHUMAN="${VER}-${ILLUMOSVER}"
PKG=developer/gcc44
SUMMARY="gcc ${VER} (illumos il-4_4_4 branch, tag gcc-4.4.4-${ILLUMOSVER})"
DESC="GCC with the patches from Codesourcery/Sun Microsystems used in the "
DESC+="3.4.3 and 4.3.3 shipped with Solaris."

set_builddir "${PROG}-gcc-4.4.4-${ILLUMOSVER}"

# Build gcc44 with itself...
set_gccver 4.4.4
set_arch 32

BUILD_DEPENDS_IPS="
    developer/gcc44/libgmp-gcc44
    developer/gcc44/libmpfr-gcc44
    developer/gcc44/libmpc-gcc44
    developer/gnu-binutils
    developer/linker
    system/library/gcc-runtime
"
RUN_DEPENDS_IPS="
    $BUILD_DEPENDS_IPS
    system/library/c-runtime
"

PREFIX=/opt/gcc-${VER}
reset_configure_opts

HSTRING=i386-pc-solaris2.11

HARDLINK_TARGETS="
    ${PREFIX/#\/}/bin/$HSTRING-gcc-$VER
    ${PREFIX/#\/}/bin/$HSTRING-c++
    ${PREFIX/#\/}/bin/$HSTRING-g++
    ${PREFIX/#\/}/bin/$HSTRING-gfortran
"

export LD=/bin/ld
export LD_FOR_TARGET=$LD
export LD_FOR_HOST=$LD

CONFIGURE_OPTS_32="--prefix=/opt/gcc-${VER}"
CONFIGURE_OPTS="
    --host ${HSTRING}
    --build ${HSTRING}
    --target ${HSTRING}
    --with-boot-ldflags=-R/opt/gcc-${VER}/lib
    --with-gmp=/opt/gcc-${VER}
    --with-mpfr=/opt/gcc-${VER}
    --with-mpc=/opt/gcc-${VER}
    --enable-languages=c,c++,fortran
    --without-gnu-ld --with-ld=/bin/ld
    --with-as=/usr/bin/gas --with-gnu-as
    --with-build-time-tools=/usr/gnu/${HSTRING}/bin
"
LDFLAGS32="-R/opt/gcc-${VER}/lib"
export LD_OPTIONS="-zignore -zcombreloc -Bdirect -i"

# If the selected compiler is the same version as the one we're building
# then the three-stage bootstrap is unecessary and some build time can be
# saved.
[ -z "$FORCE_BOOTSTRAP" ] \
    && [ "`gcc -v 2>&1 | nawk '/^gcc version/ { print $3 }'`" = "$VER" ] \
    && CONFIGURE_OPTS+=" --disable-bootstrap" \
    && logmsg "--- disabling bootstrap"

init
download_source gcc44 ${PROG}-gcc-4.4.4-${ILLUMOSVER}
patch_source
prep_build
build

# For some reason, this gcc44 package doesn't properly push the LDFLAGS shown
# above into various subdirectories.  Use elfedit to fix it.
ESTRING="dyn:runpath /opt/gcc-${VER}/lib:%o"
elfedit -e "${ESTRING}" ${TMPDIR}/${BUILDDIR}/host-${HSTRING}/gcc/cc1
elfedit -e "${ESTRING}" ${TMPDIR}/${BUILDDIR}/host-${HSTRING}/gcc/cc1plus
elfedit -e "${ESTRING}" ${TMPDIR}/${BUILDDIR}/host-${HSTRING}/gcc/f951

make_package gcc.mog depends.mog
clean_up

# Vim hints
# vim:ts=4:sw=4:et:fdm=marker
