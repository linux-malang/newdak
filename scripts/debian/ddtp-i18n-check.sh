#!/bin/bash
#
# $Id: ddtp_i18n_check.sh 2535 2011-02-19 14:20:52Z nekral-guest $
# 
# Copyright (C) 2008, 2011 Felipe Augusto van de Wiel <faw@funlabs.org>
# Copyright (C) 2008, 2009 Nicolas François <nicolas.francois@centraliens.net>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# On Debian systems, you can find the full text of the license in
# /usr/share/common-licenses/GPL-2

set -eu
export LC_ALL=C

# This must be defined to either 0 or 1
# When DEBUG=0, fail after the first error.
# Otherwise, list all the errors.
DEBUG=0

# When DRY_RUN=0, generate the compressed version of the Translation-*
# files.
DRY_RUN=0

# When GEN_IDX=1, we create the Index files.  There is a runtime option
# to not create/generate the Index file.
GEN_IDX=1

dists_parent_dir=""
# If no argument indicates the PACKAGES_LISTS_DIR then use '.'
PACKAGES_LISTS_DIR=""

usage () {
	echo "Usage: $0 [options] <dists_parent_dir> [<packages_lists_directory>]" >&2
	echo "" >&2
	echo "    --debug      Debug mode: do not stop after the first error" >&2
	echo "    --dry-run    Do not generate the compressed version of the " >&2
	echo "                 Translation files">&2
	echo "    --no-index   Do not generate the Index files" >&2
	exit 1
}

# Parse options
for opt; do
	case "$opt" in
		"--debug")
			DEBUG=1
			;;
		"--dry-run")
			DRY_RUN=1
			;;
		"--no-index")
			GEN_IDX=0
			;;
		"-*")
			usage
			;;
		"")
			echo "Empty parameter" >&2
			echo "" >&2
			usage
			;;
		*)
			if [ -z "$dists_parent_dir" ]; then
				# Removing trailing /
				dists_parent_dir=${opt%/}
			elif [ -z "$PACKAGES_LISTS_DIR" ]; then
				PACKAGES_LISTS_DIR=$opt
			else
				echo "$0: Invalid option: $opt" >&2
				usage
			fi
			;;
	esac
done
PACKAGES_LISTS_DIR=${opt:-.}

if [ ! -d "$dists_parent_dir" ]; then
	echo "missing dists_parent_dir, or not a directory" >&2
	echo "" >&2
	usage
elif [ ! -d "$PACKAGES_LISTS_DIR" ]; then
	echo "missing packages_lists_directory, or not a directory" >&2
	echo "" >&2
	usage
fi

#STABLE="squeeze"
TESTING="wheezy"
UNSTABLE="sid"

# Original SHA256SUMS, generated by i18n.debian.net
CHECKSUMS="SHA256SUMS"

# DAK Timestamp
TIMESTAMP="timestamp"

# These special files must exist on the top of dists_parent_dir
SPECIAL_FILES="$CHECKSUMS $TIMESTAMP $TIMESTAMP.gpg"

# Temporary working directory. We need a full path to reduce the
# complexity of checking CHECKSUMS and cleaning/removing TMPDIR
TEMP_WORK_DIR=$(mktemp -d -t ddtp_dinstall_tmpdir.XXXXXX)
cd "$TEMP_WORK_DIR"
TMP_WORK_DIR=$(pwd)
cd "$OLDPWD"
unset TEMP_WORK_DIR

# If it's trapped, something bad happened.
trap_exit () {
	rm -rf "$TMP_WORK_DIR"
	rm -f "$dists_parent_dir"/dists/*/main/i18n/Translation-*.bz2
	rm -f "$dists_parent_dir"/dists/*/main/i18n/Index
	exit 1
}
trap trap_exit EXIT HUP INT QUIT TERM

is_filename_okay () {
	ifo_file="$1"

	# Check that the file in on an "i18n" directory
	# This ensures that the Translation-$lang files are not e.g. in
	# dists/etch/ or dists/etch/main/
	ifo_d=$(basename $(dirname "$ifo_file"))
	if [ "x$ifo_d" = "xi18n" ]; then

		# Check that the file is named Translation-$lang
		ifo_f=$(basename "$ifo_file")
		case "$ifo_f" in
			Translation-[a-z][a-z][a-z]_[A-Z][A-Z]) return 0;;
			Translation-[a-z][a-z]_[A-Z][A-Z])      return 0;;
			Translation-[a-z][a-z][a-z])            return 0;;
			Translation-[a-z][a-z])                 return 0;;
		esac
	fi

	return 1
}

# Check a directory name against a directory whitelist 
is_dirname_okay () {
	ido_dir="$1"

	case "$ido_dir" in
		"$dists_parent_dir")                               return 0;;
		"$dists_parent_dir/dists")                         return 0;;
# TODO/FIXME: It is undecided how to update at stable/point-releases, so we
#             don't allow files to $STABLE.
#		"$dists_parent_dir/dists/$STABLE")                 return 0;;
#		"$dists_parent_dir/dists/$STABLE/main")            return 0;;
#		"$dists_parent_dir/dists/$STABLE/main/i18n")       return 0;;
#		"$dists_parent_dir/dists/$STABLE/contrib")         return 0;;
#		"$dists_parent_dir/dists/$STABLE/contrib/i18n")    return 0;;
#		"$dists_parent_dir/dists/$STABLE/non-free")        return 0;;
#		"$dists_parent_dir/dists/$STABLE/non-free/i18n")   return 0;;
		"$dists_parent_dir/dists/$TESTING")                return 0;;
		"$dists_parent_dir/dists/$TESTING/main")           return 0;;
		"$dists_parent_dir/dists/$TESTING/main/i18n")      return 0;;
		"$dists_parent_dir/dists/$TESTING/contrib")        return 0;;
		"$dists_parent_dir/dists/$TESTING/contrib/i18n")   return 0;;
		"$dists_parent_dir/dists/$TESTING/non-free")       return 0;;
		"$dists_parent_dir/dists/$TESTING/non-free/i18n")  return 0;;
		"$dists_parent_dir/dists/$UNSTABLE")               return 0;;
		"$dists_parent_dir/dists/$UNSTABLE/main")          return 0;;
		"$dists_parent_dir/dists/$UNSTABLE/main/i18n")     return 0;;
		"$dists_parent_dir/dists/$UNSTABLE/contrib")       return 0;;
		"$dists_parent_dir/dists/$UNSTABLE/contrib/i18n")  return 0;;
		"$dists_parent_dir/dists/$UNSTABLE/non-free")      return 0;;
		"$dists_parent_dir/dists/$UNSTABLE/non-free/i18n") return 0;;
	esac

	return 1
}

has_valid_fields () {
	hvf_file="$1"
	hvf_lang=${hvf_file/*-}

awk "
function print_status () {
	printf (\"p: %d, m: %d, s: %d, l: %d\n\", package, md5, s_description, l_description)
}
BEGIN {
	package       = 0 # Indicates if a Package field was found
	md5           = 0 # Indicates if a Description-md5 field was found
	s_description = 0 # Indicates if a short description was found
	l_description = 0 # Indicates if a long description was found

	failures      = 0 # Number of failures (debug only)
	failed        = 0 # Failure already reported for the block
}

/^Package: / {
	if (0 == failed) {
		if (   (0 != package)       \
		    || (0 != md5)           \
		    || (0 != s_description) \
		    || (0 != l_description)) {
			printf (\"Package field unexpected in $hvf_file (line %d)\n\", NR)
			print_status()
			failed = 1
			if ($DEBUG) { failures++ } else { exit 1 }
		}
		package++
	}
	# Next input line
	next
}

/^Description-md5: / {
	if (0 == failed) {
		if (   (1 != package)       \
		    || (0 != md5)           \
		    || (0 != s_description) \
		    || (0 != l_description)) {
			printf (\"Description-md5 field unexpected in $hvf_file (line %d)\n\", NR)
			print_status()
			failed = 1
			if ($DEBUG) { failures++ } else { exit 1 }
		}
		md5++
	}
	# Next input line
	next
}

/^Description-$hvf_lang: / {
	if (0 == failed) {
		if (   (1 != package)       \
		    || (1 != md5)           \
		    || (0 != s_description) \
		    || (0 != l_description)) {
			printf (\"Description-$hvf_lang field unexpected in $hvf_file (line %d)\n\", NR)
			print_status()
			failed = 1
			if ($DEBUG) { failures++ } else { exit 1 }
		}
		s_description++
	}
	# Next input line
	next
}

/^ / {
	if (0 == failed) {
		if (   (1 != package)       \
		    || (1 != md5)           \
		    || (1 != s_description)) {
			printf (\"Long description unexpected in $hvf_file (line %d)\n\", NR)
			print_status()
			failed = 1
			if ($DEBUG) { failures++ } else { exit 1 }
		}
		l_description = 1 # There can be any number of long description
		                  # lines. Do not count.
	}
	# Next line
	next
}

/^$/ {
	if (0 == failed) {
		if (   (1 != package)       \
		    || (1 != md5)           \
		    || (1 != s_description) \
		    || (1 != l_description)) {
			printf (\"End of block unexpected in $hvf_file (line %d)\n\", NR)
			print_status()
			failed = 1
			if ($DEBUG) { failures++ } else { exit 1 }
		}
	}

	# Next package
	package = 0; md5 = 0; s_description = 0; l_description = 0
	failed = 0

	# Next input line
	next
}

# Anything else: fail
{
	printf (\"Unexpected line '\$0' in $hvf_file (line %d)\n\", NR)
	print_status()
	failed = 1
	if ($DEBUG) { failures++ } else { exit 1 }
}

END {
	if (0 == failed) {
		# They must be all set to 0 or all set to 1
		if (   (   (0 == package)        \
		        || (0 == md5)            \
		        || (0 == s_description)  \
		        || (0 == l_description)) \
		    && (   (0 != package)        \
		        || (0 != md5)            \
		        || (0 != s_description)  \
		        || (0 != l_description))) {
			printf (\"End of file unexpected in $hvf_file (line %d)\n\", NR)
			print_status()
			exit 1
		}
	}

	if (failures > 0) {
		exit 1
	}
}
" "$hvf_file" || return 1

	return 0
}

# $SPECIAL_FILES must exist
for sf in $SPECIAL_FILES; do
	if [ ! -f "$dists_parent_dir/$sf" ]; then
		echo "Special file ($sf) doesn't exist"
		exit 1;
	fi
done

# Comparing CHECKSUMS
# We don't use -c because a file could exist in the directory tree and not in
# the CHECKSUMS, so we sort the existing CHECKSUMS and we create a new one
# already sorted, if cmp fails then files are different and we don't want to
# continue.
cd "$dists_parent_dir"
find dists -type f -print0 |xargs --null sha256sum > "$TMP_WORK_DIR/$CHECKSUMS.new"
sort "$CHECKSUMS" > "$TMP_WORK_DIR/$CHECKSUMS.sorted"
sort "$TMP_WORK_DIR/$CHECKSUMS.new" > "$TMP_WORK_DIR/$CHECKSUMS.new.sorted"
if ! cmp --quiet "$TMP_WORK_DIR/$CHECKSUMS.sorted" "$TMP_WORK_DIR/$CHECKSUMS.new.sorted"; then
	echo "Failed to compare the $CHECKSUMS, they are not identical!" >&2
	diff -au "$TMP_WORK_DIR/$CHECKSUMS.sorted" "$TMP_WORK_DIR/$CHECKSUMS.new.sorted" >&2
	exit 1
fi
cd "$OLDPWD"

# Get the list of valid packages (sorted, uniq)
for t in "$TESTING" "$UNSTABLE"; do
	if [ ! -f "$PACKAGES_LISTS_DIR/$t" ]; then
		echo "Missing $PACKAGES_LISTS_DIR/$t" >&2
		exit 1
	fi
	cut -d' ' -f 1 "$PACKAGES_LISTS_DIR/$t" | sort -u > "$TMP_WORK_DIR/$t.pkgs"
done

/usr/bin/find "$dists_parent_dir" |
while read f; do
	if   [ -d "$f" ]; then
		if ! is_dirname_okay "$f"; then
			echo "Wrong directory name: $f" >&2
			exit 1
		else
			# If the directory name is OK, and if it's name is i18n
			# and GEN_IDX is enabled, we generate the header of the
			# Index file
			if [ "$(basename $f)" = "i18n" -a "$GEN_IDX" = "1" ];
			then
				echo "SHA1:" > "$f/Index"
			fi
		fi
	elif [ -f "$f" ]; then
		# If $f is in $SPECIAL_FILES, we skip to the next loop because
		# we won't check it for format, fields and encoding.
		for sf in $SPECIAL_FILES; do
			if [ "$f" = "$dists_parent_dir/$sf" ]; then
				continue 2
			fi
		done

		if ! is_filename_okay "$f"; then
			echo "Wrong file: $f" >&2
			exit 1
		fi

		# Check that all entries contains the right fields
		if ! has_valid_fields "$f"; then
			echo "File $f has an invalid format" >&2
			exit 1
		fi

		# Check that every packages in Translation-$lang exists
		TPKGS=$(basename "$f").pkgs
		grep "^Package: " "$f" | cut -d' ' -f 2 | sort -u > "$TMP_WORK_DIR/$TPKGS"
		case "$f" in
			*/$TESTING/*)  t="$TESTING";;
			*/$UNSTABLE/*) t="$UNSTABLE";;
		esac
		if diff "$TMP_WORK_DIR/$t.pkgs" "$TMP_WORK_DIR/$TPKGS" | grep -q "^>"; then
			diff -au "$TMP_WORK_DIR/$t.pkgs" "$TMP_WORK_DIR/$TPKGS" |grep "^+"
			echo "$f contains packages which are not in $t" >&2
			exit 1
		fi

		# Check encoding
		iconv -f utf-8 -t utf-8 < "$f" > /dev/null 2>&1 || {
			echo "$f is not an UTF-8 file" >&2
			exit 1
		}

		# We do not check if the md5 in Translation-$lang are
		# correct.

		if [ "$DRY_RUN" = "0" ]; then
			# Now generate the compressed files
			bzip2 "$f"
		fi

		# Create Index
		if [ "$GEN_IDX" = "1" ]; then
			fbz=${f}.bz2
			IDX=$(dirname $f)
			tf_name=$(basename $fbz)
			tf_sha1=$(sha1sum $fbz)
			tf_size=$(du --bytes $fbz)
			printf ' %s % 7s %s\n' "${tf_sha1% *}" \
				"${tf_size%	*}" "${tf_name}" >> "$IDX/Index"
		fi
	else
		echo "Neither a file or directory: $f" >&2
		exit 1
	fi
done || false
# The while will just fail if an internal check "exit 1", but the script
# is not exited. "|| false" makes the script fail (and exit) in that case.

echo "$dists_parent_dir structure validated successfully ($(date +%c))"

# If we reach this point, everything went fine.
trap - EXIT
rm -rf "$TMP_WORK_DIR"

