TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = PlaticaSayTweak
PlaticaSayTweak_FILES = Tweak.x OverlayWindow.x
PlaticaSayTweak_FRAMEWORKS = AudioToolbox CoreAudio UIKit
PlaticaSayTweak_LIBRARIES = substrate

include $(THEOS_MAKE_PATH)/tweak.mk
