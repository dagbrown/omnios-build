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
# Copyright 2015 OmniTI Computer Consulting, Inc.  All rights reserved.
# Copyright 2019 OmniOS Community Edition (OmniOSce) Association.

. ../../lib/functions.sh

PROG=openssh
VER=8.0p1
PKG=network/openssh
SUMMARY="OpenSSH Client and utilities"
DESC="OpenSSH Secure Shell protocol Client and associated Utilities"

set_arch 64

SKIP_LICENCES=OpenSSH

CONFIGURE_OPTS_64+="
    --sysconfdir=/etc/ssh
"

CONFIGURE_OPTS="
    --with-audit=solaris
    --with-kerberos5=$PREFIX
    --with-libedit=$PREFIX
    --with-pam
    --with-sandbox=solaris
    --with-solaris-contracts
    --with-solaris-privs
    --with-tcp-wrappers
    --with-4in6
    --enable-strip=no
    --without-rpath
    --disable-lastlog
    --with-privsep-user=daemon
    --with-ssl-engine
    --with-solaris-projects
"

CFLAGS+=" -fstack-check "
CFLAGS+="-DPAM_ENHANCEMENT -DSET_USE_PAM -DPAM_BUGFIX -DDTRACE_SFTP "
CFLAGS+="-I/usr/include/kerberosv5 -DKRB5_BUILD_FIX -DDISABLE_BANNER "
CFLAGS+="-DDEPRECATE_SUNSSH_OPT -DOPTION_DEFAULT_VALUE -DSANDBOX_SOLARIS"

move_manpage() {
    local page=$1
    local old=$2
    local new=$3

    logmsg "-- Move manpage $page.$old -> $page.$new"
    if [ -f $page.$old ]; then
        mv $page.$old $page.$new
        # change manpage header
        uc=`echo $new | tr '[:lower:]' '[:upper:]'`
        sed -E -i "s/^(\.Dt +[^ ]+).*$/\1 $uc/" $page.$new
    elif [ -f $page.$new ]; then
        logmsg "---- Was already moved"
    else
        logerr "---- Not found"
    fi
}

move_manpages() {
    pushd $TMPDIR/$BUILDDIR >/dev/null

    move_manpage moduli             5 4
    move_manpage ssh_config         5 4
    move_manpage sshd_config        5 4

    move_manpage sshd               8 1m
    move_manpage sftp-server        8 1m
    move_manpage ssh-keysign        8 1m
    move_manpage ssh-pkcs11-helper  8 1m

    popd
}

init
download_source $PROG $PROG $VER
move_manpages
patch_source
run_inbuild autoreconf -fi
prep_build
run_autoconf
build
install_smf network ssh.xml sshd

export TESTSUITE_FILTER='^ok |^test_|failed|^all tests'
(
    # The test SSH daemon needs root privileges to properly access PAM
    # on OmniOS. Sudo does not work well enough so use pfexec here.
    if [ `pfexec id -u` != "0" ]; then
        logerr "Your account is not set up for pfexec, cannot run testsuite"
    else
        export SUDO=pfexec
        run_testsuite tests
    fi
)

# Remove the letter from VER for packaging
VER=${VER//p/.}

# Client package
make_package client.mog

# Server package
PKG=network/openssh-server
PKGE=$(url_encode $PKG)
SUMMARY="OpenSSH Server"
DESC="OpenSSH Secure Shell protocol Server"
RUN_DEPENDS_IPS="pkg:/network/openssh@$VER"
make_package server.mog

clean_up

# Vim hints
# vim:ts=4:sw=4:et:fdm=marker
