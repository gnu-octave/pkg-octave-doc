## Copyright 2017 Julien Bect <jbect@users.sourceforge.net>
## Copyright 2015-2016 Carnë Draug
## Copyright 2015-2016 Oliver Heimlich
##
## Copying and distribution of this file, with or without modification,
## are permitted in any medium without royalty provided the copyright
## notice and this notice are preserved.  This file is offered as-is,
## without any warranty.

PACKAGE := $(shell grep "^Name: " DESCRIPTION | cut -f2 -d" ")
VERSION := $(shell grep "^Version: " DESCRIPTION | cut -f2 -d" ")

TARGET_DIR      := target
RELEASE_DIR     := $(TARGET_DIR)/$(PACKAGE)-$(VERSION)
RELEASE_TARBALL := $(TARGET_DIR)/$(PACKAGE)-$(VERSION).tar.gz
HTML_DIR        := $(TARGET_DIR)/$(PACKAGE)-html
HTML_TARBALL    := $(TARGET_DIR)/$(PACKAGE)-html.tar.gz

HG_ID   := $(shell hg id --id | sed -e 's/+//')
HG_DATE := $(shell hg log --rev $(HG_ID) --template {date\|isodate})

# Follows the recommendations of https://reproducible-builds.org/docs/archives
define create_tarball
$(shell cd $(dir $(1)) \
    && find $(notdir $(1)) -print0 \
    | LC_ALL=C sort -z \
    | tar c --mtime="$(HG_DATE)" \
            --owner=root --group=root --numeric-owner \
            --no-recursion --null -T - -f - \
    | gzip -9n > "$(2)")
endef

M_SOURCES   := $(wildcard inst/*.m) $(patsubst %.in,%,$(wildcard src/*.m.in))
PKG_ADD     := $(shell grep -Pho '(?<=(//|\#\#) PKG_ADD: ).*' $(M_SOURCES))

OCTAVE ?= octave --no-window-system --silent

.PHONY: help dist html release install all check run clean

help:
	@echo "Targets:"
	@echo "   dist    - Create $(RELEASE_TARBALL) for release"
	@echo "   html    - Create $(HTML_TARBALL) for release"
	@echo "   release - Create both of the above and show md5sums"
	@echo
	@echo "   install - Install the package in GNU Octave"
	@echo "   check   - Execute package tests (w/o install)"
	@echo "   run     - Run Octave with development in PATH (no install)"
	@echo
	@echo "   clean   - Remove releases, html documentation"

%.tar.gz: %
	$(call create_tarball,$*,${CURDIR}/$@)

$(RELEASE_DIR): .hg/dirstate
	@echo "Creating package version $(VERSION) release ..."
	-$(RM) -r "$@"
	hg archive --exclude ".hg*" --exclude "Makefile" --type files "$@"
	chmod -R a+rX,u+w,go-w "$@"

$(HTML_DIR): install
	@echo "Generating HTML documentation. This may take a while ..."
	-$(RM) -r "$@"
	$(OCTAVE) --no-window-system --silent \
	  --eval "pkg load generate_html; " \
	  --eval "pkg load $(PACKAGE);" \
	  --eval 'generate_package_html ("${PACKAGE}", "$@", "octave-forge");'
	chmod -R a+rX,u+w,go-w $@

dist: $(RELEASE_TARBALL)
html: $(HTML_TARBALL)

release: dist html
	md5sum $(RELEASE_TARBALL) $(HTML_TARBALL)
	@echo "Upload @ https://sourceforge.net/p/octave/package-releases/new/"
	@echo 'Execute: hg tag "release-${VERSION}"'

install: $(RELEASE_TARBALL)
	@echo "Installing package locally ..."
	$(OCTAVE) --eval 'pkg ("install", "${RELEASE_TARBALL}")'

check:
	$(OCTAVE) --path "inst/" \
	  --eval '${PKG_ADD}' \
	  --eval 'runtests ("inst");'

run:
	$(OCTAVE) --persist --path "inst/" \
	  --eval '${PKG_ADD}'

clean:
	$(RM) -r $(TARGET_DIR)
