# Tests
# $Id: GNUmakefile,v 1.4 2003/09/04 14:33:55 znek Exp $


ifeq "$(GNUSTEP_SYSTEM_ROOT)" ""
  include Makefile
else

# Install into the user root by default
GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_USER_ROOT)

include $(GNUSTEP_MAKEFILES)/common.make

ADDITIONAL_INCLUDE_DIRS = -I..


# The projects to be compiled
TOOL_NAME = xrcall


xrcall_OBJC_FILES = xrcall_main.m

xrcall_OBJC_LIBS =  -lXMLRPC
ifneq "$(GUI_LIB)" "nil"
xrcall_OBJC_LIBS += -lgnustep-gui
endif

ifeq "$(OBJC_RUNTIME_LIB)" "gnu"
ADDITIONAL_OBJCFLAGS += -DGNU_RUNTIME
endif


-include Makefile.preamble

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/tool.make

-include GNUmakefile.postamble

-include Makefile.postamble

endif
