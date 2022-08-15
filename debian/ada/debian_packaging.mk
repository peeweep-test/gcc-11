# Common settings for Ada Debian packaging.
#
#  Copyright (C) 2012-2021 Nicolas Boulenguez <nicolas@debian.org>
#
#  This program is free software: you can redistribute it and/or
#  modify it under the terms of the GNU General Public License as
#  published by the Free Software Foundation, either version 3 of the
#  License, or (at your option) any later version.
#  This program is distributed in the hope that it will be useful, but
#  WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
#  General Public License for more details.
#  You should have received a copy of the GNU General Public License
#  along with this program. If not, see <http://www.gnu.org/licenses/>.

# Typical use:
#
# gnat_version := $(shell gnatgcc -dumpversion)
# DEB_BUILD_MAINT_OPTIONS := hardening=+all
# DEB_LDFLAGS_MAINT_APPEND := -Wl,--no-undefined -Wl,--no-copy-dt-needed-entries -Wl,--no-allow-shlib-undefined
# DEB_ADAFLAGS_MAINT_APPEND := -gnatwa -Wall
# DPKG_EXPORT_BUILDFLAGS := 1
# include /usr/share/dpkg/buildflags.mk
# include /usr/share/dpkg/buildopts.mk
# include $(wildcard /usr/share/ada/debian_packaging-$(gnat_version).mk)
# # The wilcard is useful when Build-Depends-Indep does not contain gnat-BV.

# dpkg-dev provides /usr/share/dpkg/default.mk (or the
# more specific buildflags.mk and buildopts.mk) to set standard variables like
# CFLAGS, LDFLAGS...  according to the build
# environment (DEB_BUILD_OPTIONS...) and the policy (hardening
# flags...).
# You must include it before this file.
ifneq(2,$(words $(filter /usr/share/dpkg/buildflags.mk \
                         /usr/share/dpkg/buildopts.mk,$(MAKEFILE_LIST))))
  $(error Please include /usr/share/dpkg/default.mk (or the more specific \
          buildflags.mk and buildopts.mk) before $(lastword $(MAKEFILE_LIST)))
endif

# Ada is not in dpkg-dev flag list. We add a sensible default here.

# Format checking is meaningless for Ada sources.
ADAFLAGS := $(filter-out -Wformat -Werror=format-security, $(CFLAGS))

ifdef DEB_ADAFLAGS_SET
  ADAFLAGS := $(DEB_ADAFLAGS_SET)
endif
ADAFLAGS := $(DEB_ADAFLAGS_PREPEND) \
            $(filter-out $(DEB_ADAFLAGS_STRIP),$(ADAFLAGS)) \
            $(DEB_ADAFLAGS_APPEND)

ifdef DEB_ADAFLAGS_MAINT_SET
  ADAFLAGS := $(DEB_ADAFLAGS_MAINT_SET)
endif
ADAFLAGS := $(DEB_ADAFLAGS_MAINT_PREPEND) \
            $(filter-out $(DEB_ADAFLAGS_MAINT_STRIP),$(ADAFLAGS)) \
            $(DEB_ADAFLAGS_MAINT_APPEND)

ifdef DPKG_EXPORT_BUILDFLAGS
  export ADAFLAGS
endif

######################################################################
# C compiler version

# This file was once setting CC, but this interfers with
# /usr/share/dpkg/buildtools.mk in some corner cases.
# Please set CC=gnatgcc manually when appropriate.

######################################################################
# Options for gprbuild/gnatmake.

# Let Make delegate parallelism to gnatmake/gprbuild.
.NOTPARALLEL:

# Use all processors unless parallel=n is set in DEB_BUILD_OPTIONS.
BUILDER_OPTIONS += \
  -j$(or $(DEB_BUILD_OPTION_PARALLEL),$(shell getconf _NPROCESSORS_ONLN))

BUILDER_OPTIONS += -R
# Avoid lintian warning about setting an explicit library runpath.
# http://wiki.debian.org/RpathIssue

ifeq (,$(filter terse,$(DEB_BUILD_OPTIONS) $(DEB_BUILD_MAINT_OPTIONS)))
BUILDER_OPTIONS += -v
endif
# Make exact command lines available for automatic log checkers.

BUILDER_OPTIONS += -eS
# Tell gnatmake to echo commands to stdout instead of stderr, avoiding
# buildds thinking it is inactive and killing it.
# -eS is the default on gprbuild.

# You may be interested in
# -s  recompile if compilation switches have changed
#     (bad default because of interactions between -amxs and standard library)
# -we handle warnings as errors
# -vP2 verbose when parsing projects.
