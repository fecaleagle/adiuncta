export TARGET = iphone:9.2:8.4
export ARCHS = armv7 armv7s arm64

include theos/makefiles/common.mk

TWEAK_NAME = Adiuncta
Adiuncta_FILES = Tweak.xm
Adiuncta_FRAMEWORKS = UIKit CoreGraphics CoreImage
Adiuncta_PRIVATE_FRAMEWORKS = Search

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += prefs
include $(THEOS_MAKE_PATH)/aggregate.mk
