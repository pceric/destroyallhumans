#color conversion lib
LOCAL_PATH := $(call my-dir)
$(info $(LOCAL_PATH))

include $(CLEAR_VARS)

LOCAL_MODULE    := yuv420sp2rgb
LOCAL_SRC_FILES := yuv420sp2rgb.c

include $(BUILD_SHARED_LIBRARY)

# image processing lib
#
include $(CLEAR_VARS)

LOCAL_MODULE    := imageprocessing
LOCAL_SRC_FILES := image_processing.c

#LOCAL_STATIC_LIBRARIES := libyuv420sp2rgb

include $(BUILD_SHARED_LIBRARY)


include $(CLEAR_VARS)

DEBUG_LOGGING := true

LOCAL_MODULE    := framebuffet
LOCAL_C_INCLUDES := \
        $(LOCAL_PATH)/../jpeg
LOCAL_CFLAGS := $(LOCAL_C_INCLUDES:%=-I%)
LOCAL_LDLIBS := -L$(SYSROOT)/usr/lib -ldl -llog  #\
            #    -L$(NDK_APP_OUT)/Netcat -ljpeg 

LOCAL_SRC_FILES := framebuffet.c

LOCAL_STATIC_LIBRARIES := jpeg


include $(BUILD_SHARED_LIBRARY)
