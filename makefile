TEMPORARY_FOLDER?=/tmp/JiraTools.dst
PREFIX?=/usr/local
BUILD_TOOL?=xcodebuild

XCODEFLAGS=-workspace 'JiraTools.xcworkspace' -scheme 'jiraupdater' DSTROOT=$(TEMPORARY_FOLDER) 
#CONFIGURATION_BUILD_DIR=$(TEMPORARY_FOLDER) CONFIGURATION_TEMP_DIR=$(TEMPORARY_FOLDER)


BUILT_BUNDLE=$(TEMPORARY_FOLDER)/Applications/jiraupdater.app
FRAMEWORK_BUNDLE=$(BUILT_BUNDLE)/Contents/Frameworks
EXECUTABLE=$(BUILT_BUNDLE)/Contents/MacOS/jiraupdater

FRAMEWORKS_FOLDER=/Library
BINARIES_FOLDER=/usr/local/bin

OUTPUT_PACKAGE=jiraupdater.pkg
OUTPUT_FRAMEWORK=JiraToolsKit.framework
VERSION_STRING=$(shell cd jiraupdater && agvtool what-marketing-version -terse1)
COMPONENTS_PLIST=jiraupdater/jiraUpdater/Components.plist

.PHONY: all bootstrap clean build install package test uninstall carthage

all: bootstrap
	$(BUILD_TOOL) $(XCODEFLAGS) build| egrep '^(/.+:[0-9+:[0-9]+:.(error|warning):|fatal|===)' -

carthage:
	carthage update

bootstrap:
	carthage bootstrap --platform macOS --no-use-binaries

# xcodebuild -workspace JiraTools.xcworkspace -scheme jiraupdater CONFIGURATION_BUILD_DIR='build'
build:
	$(BUILD_TOOL) $(XCODEFLAGS) build

buildVerbose:
	$(BUILD_TOOL) $(XCODEFLAGS) build -verbose

test: clean bootstrap
	$(BUILD_TOOL) $(XCODEFLAGS) test

clean:
	rm -f "$(OUTPUT_PACKAGE)"
	rm -f "$(OUTPUT_FRAMEWORK_ZIP)"
	rm -rf "$(TEMPORARY_FOLDER)"
	$(BUILD_TOOL) $(XCODEFLAGS) clean

install: package
	sudo installer -pkg jiraupdater.pkg -target /

uninstall:
	rm -rf "$(FRAMEWORKS_FOLDER)/$(OUTPUT_FRAMEWORK)"
	rm -rf "$(PREFIX)/Frameworks/$(OUTPUT_FRAMEWORK)"
	rm -f "$(BINARIES_FOLDER)/jiraupdater"

installables: clean bootstrap
	$(BUILD_TOOL) $(XCODEFLAGS) install

	mkdir -p "$(TEMPORARY_FOLDER)$(FRAMEWORKS_FOLDER)" "$(TEMPORARY_FOLDER)$(BINARIES_FOLDER)"
	
	rsync -a --prune-empty-dirs --include '*/'  --exclude '/libswift*.dylib' "$(FRAMEWORK_BUNDLE)/JiraToolsKit.framework" "$(TEMPORARY_FOLDER)$(FRAMEWORKS_FOLDER)/Frameworks"

	# copy the app's frameworks
	rsync -a --prune-empty-dirs --include '*/'  --exclude '/libswift*.dylib /JiraToolsKit.framework' "$(FRAMEWORK_BUNDLE)/" "$(TEMPORARY_FOLDER)$(FRAMEWORKS_FOLDER)/Frameworks/$(OUTPUT_FRAMEWORK)/Versions/Current/Frameworks"
	
	

	mv -fv "$(EXECUTABLE)" "$(TEMPORARY_FOLDER)$(BINARIES_FOLDER)/jiraupdater"
	rm -rf "$(BUILT_BUNDLE)"

prefix_install: installables
	mkdir -p "$(PREFIX)/Frameworks" "$(PREFIX)/bin"
	cp -f "$(TEMPORARY_FOLDER)$(BINARIES_FOLDER)/jiraupdater" "$(PREFIX)/bin/"
	install_name_tool -add_rpath "@executable_path/../Frameworks/JiraToolsKit.framework/Versions/Current/Frameworks/" "$(PREFIX)/bin/jiraupdater"


package: installables
	pkgbuild \
		--component-plist "$(COMPONENTS_PLIST)" \
		--identifier "com.lottadot.jira.jiraupdater" \
		--install-location "/" \
		--root "$(TEMPORARY_FOLDER)" \
		--version "$(VERSION_STRING)" \
		"$(OUTPUT_PACKAGE)"
