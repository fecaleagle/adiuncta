include theos/makefiles/common.mk

BUNDLE_NAME = Adiuncta
Adiuncta_FILES = AdiunctaListController.mm
Adiuncta_INSTALL_PATH = /Library/PreferenceBundles
Adiuncta_FRAMEWORKS = UIKit CoreGraphics CoreImage QuartzCore
Adiuncta_PRIVATE_FRAMEWORKS = Preferences AppSupport

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/Adiuncta.plist$(ECHO_END)
