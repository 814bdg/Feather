TARGET_CODESIGN = $(shell which ldid)

PLATFORM = iphoneos
NAME = feather
SCHEME ?= 'feather (Release)'  # Changed to Release for consistency with optimization level
RELEASE = Release-iphoneos
CONFIGURATION = Release

MACOSX_SYSROOT = $(shell xcrun -sdk macosx --show-sdk-path)
TARGET_SYSROOT = $(shell xcrun -sdk $(PLATFORM) --show-sdk-path)

APP_TMP         = $(TMPDIR)/$(NAME)
STAGE_DIR   = $(APP_TMP)/stage
APP_DIR 	   = $(APP_TMP)/Build/Products/$(RELEASE)/$(NAME).app

OPTIMIZATION_LEVEL ?= -Onone  # Set default optimization level to -Onone

all: package

package:
	@rm -rf $(APP_TMP)
	@rm -rf ~/Library/Developer/Xcode/DerivedData  # Clean Swift environment
	@xcodebuild clean  # Clean Xcode build
	
	@set -o pipefail; \
		xcodebuild \
		-jobs $(shell sysctl -n hw.ncpu) \
		-project '$(NAME).xcodeproj' \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-arch arm64 -sdk $(PLATFORM) \
		-derivedDataPath $(APP_TMP) \
		CODE_SIGNING_ALLOWED=NO \
		DSTROOT=$(APP_TMP)/install \
		ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES=NO \
		OTHER_CFLAGS="$(OPTIMIZATION_LEVEL)" \
		OTHER_SWIFT_FLAGS="$(OPTIMIZATION_LEVEL)"
		
	@rm -rf Payload
	@rm -rf $(STAGE_DIR)/
	@mkdir -p $(STAGE_DIR)/Payload
	@mv $(APP_DIR) $(STAGE_DIR)/Payload/$(NAME).app
	@echo $(APP_TMP)
	@echo $(STAGE_DIR)
	
	@rm -rf $(STAGE_DIR)/Payload/$(NAME).app/_CodeSignature
	@ln -sf $(STAGE_DIR)/Payload Payload
	@rm -rf packages
	@mkdir -p packages

ifeq ($(TIPA),1)
	@zip -r9 packages/$(NAME)-ts.tipa Payload
else
	@zip -r9 packages/$(NAME).ipa Payload
endif

clean:
	@rm -rf $(STAGE_DIR)
	@rm -rf packages
	@rm -rf out.dmg
	@rm -rf Payload
	@rm -rf apple-include
	@rm -rf $(APP_TMP)
	@rm -rf ~/Library/Developer/Xcode/DerivedData  # Clean Swift environment
	@xcodebuild clean  # Clean Xcode build

.PHONY: apple-include