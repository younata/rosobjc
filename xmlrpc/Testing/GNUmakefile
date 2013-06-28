# Tests
# $Id: GNUmakefile,v 1.4 2002/07/28 23:30:17 znek Exp $


ifeq "$(GNUSTEP_SYSTEM_ROOT)" ""
  include Makefile
else

# Install into the user root by default
GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_USER_ROOT)

include $(GNUSTEP_MAKEFILES)/common.make

ADDITIONAL_INCLUDE_DIRS = -I..


# The framework to be compiled
TOOL_NAME = server client


server_OBJC_FILES = server_main.m TestServer.m

server_OBJC_LIBS =  -lEDCommon -lEDMessage -lXMLRPC -lcrypt
ifneq "$(GUI_LIB)" "nil"
server_OBJC_LIBS += -lgnustep-gui
endif

ifeq "$(OBJC_RUNTIME_LIB)" "gnu"
ADDITIONAL_OBJCFLAGS += -DGNU_RUNTIME
endif


client_OBJC_FILES = client_main.m TestController.m TestServerProxy.m

client_OBJC_LIBS =  -lEDCommon -lEDMessage -lXMLRPC -lcrypt
ifneq "$(GUI_LIB)" "nil"
client_OBJC_LIBS += -lgnustep-gui
endif


-include Makefile.preamble

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/tool.make

-include GNUmakefile.postamble

-include Makefile.postamble

endif
