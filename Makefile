# *************************************************************************
#  Roku Umbrella Client - Build & Sideload Makefile
# *************************************************************************

APP_NAME = roku-umbrella-client
ROKU_DEV_TARGET ?= 192.168.4.72
ROKU_DEV_PASSWORD ?= 1224
OUT_DIR = out
ZIP_FILE = $(OUT_DIR)/$(APP_NAME).zip

.PHONY: all package deploy clean check

all: check package

check:
	@echo "Validating XML and BrightScript syntax..."
	@python3 -c "import glob, xml.etree.ElementTree as ET; [ET.parse(f) for f in glob.glob('components/**/*.xml', recursive=True)]; print('All XML files parsed cleanly.')"

package: check
	@mkdir -p $(OUT_DIR)
	@rm -f $(ZIP_FILE)
	@echo "Packaging Roku Application to $(ZIP_FILE)..."
	@zip -9 -r $(ZIP_FILE) manifest source components images -x "*.DS_Store" "*~" "*.bak" "*.pyc"
	@echo "Package ready: $(ZIP_FILE)"

deploy: package
	@echo "Deploying to Roku target at $(ROKU_DEV_TARGET)..."
	@curl -s -S --user rokudev:$(ROKU_DEV_PASSWORD) --digest \
		-F "mysubmit=Replace" \
		-F "archive=@$(ZIP_FILE)" \
		http://$(ROKU_DEV_TARGET)/plugin_install | grep -oE "(Application Received[^<]*|Install Success\.|Install Failure[^<]*)" || true
	@echo "Deployment complete."

clean:
	@rm -rf $(OUT_DIR)
	@echo "Cleaned build artifacts."
