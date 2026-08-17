#!/bin/sh
set -e
URL_BASE="https://cdn.netbsd.org/pub/NetBSD/NetBSD-$REL/source/sets"

extract_sets()
{
	while read l
	do
		echo "$l" | grep -Eo '\(.*\)' | tr -d '(' | tr -d ')'
	done
}

do_dl()
{
	set -e

	rm -rf dl
	mkdir dl
	cd dl

	ftp -V "$URL_BASE/SHA512"

	extract_sets < SHA512 | while read name
	do
		echo ftp -V "$URL_BASE/$name" ... >&2
		ftp -V "$URL_BASE/$name"
	done
	cksum -c SHA512

	mkdir -p /usr/src
	extract_sets < SHA512 | while read name
	do
		echo tar -C / -zxf "$name" ... >&2
		tar -C / -zxf "$name"
		rm -f "$name"
	done

	echo "Download complete!" >& 2
}

set +e
for i in $(seq 3)
do
	echo "===== Download take #$i =====" >&2
	do_dl & wait $!
	ec=$?
	[ $ec -eq 0 ] && break
done
set -e
[ $ec -ne 0 ] && exit 1

# Remove all existing KERNEL_SETS and BUILD_KERNELS
sed -e '/^KERNEL_SETS/d' -e '/^BUILD_KERNELS/d' /usr/src/etc/etc.i386/Makefile.inc >\
	/usr/src/etc/etc.i386/Makefile.inc.tmp
cat << EOF >> /usr/src/etc/etc.i386/Makefile.inc.tmp
# IBM PC target overrides
KERNEL_SETS=	GENERIC
BUILD_KERNELS+=	INSTALL
EOF
mv /usr/src/etc/etc.i386/Makefile.inc.tmp /usr/src/etc/etc.i386/Makefile.inc
