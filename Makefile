ARCHS = arm64 arm64e
TARGET := iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = PayURLHook

PayURLHook_FILES = Tweak.x
PayURLHook_CFLAGS = -fobjc-arc
PayURLHook_FRAMEWORKS = UIKit
include $(THEOS_MAKE_PATH)/tweak.mk
