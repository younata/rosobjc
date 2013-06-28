# XMLRPC.framework
# $Id: GNUmakefile,v 1.12 2003/10/21 16:54:12 znek Exp $


ifeq "$(GNUSTEP_SYSTEM_ROOT)" ""
  include Makefile
else

# Install into the local root by default
GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_LOCAL_ROOT)

include $(GNUSTEP_MAKEFILES)/common.make


# The framework to be compiled
FRAMEWORK_NAME = XMLRPC


XMLRPC_HEADER_FILES = \
XMLRPC.h				XRDefines.h \
XRConstants.h				XRProtocols.h \
XRConnection.h				XRHTTPMessage.h \
XRHTTPRequest.h				XRHTTPResponse.h \
XRHTTPRequest+HTTPAuthentication.h	XRHTTPResponse+HTTPAuthentication.h \
XRHTTPConnection.h \
XRHTTPAuthenticationCredentials.h \
XRHTTPAuthenticationHandler.h		XRHTTPBasicAuthenticationHandler.h \
XRMethodSignature.h			XRInvocation.h \
XRGenericInvocation.h			XRInvocationStorage.h \
XRProxy.h \
XRCoder.h \
XREncoder.h				XRDecoder.h \
XRXMLParser.h				XRXMLTagProcessor.h \
NSCalendarDate+ISO8601.h		NSString+XMLExtensions.h \


XMLRPC_OBJC_FILES = \
XREStruct.m \
MXAutoContentContainerElement.m         XREValue.m \
MXContainerElement.m                    XREncoder.m \
MXElement.m                             XRGenericInvocation.m \
MXStringElement.m                       XRHTTPAuthenticationCredentials.m \
MXTextContainerElement.m                XRHTTPBasicAuthenticationHandler.m \
NSCalendarDate+ISO8601.m                XRHTTPConnection.m \
NSString+XMLExtensions.m                XRHTTPMessage.m \
Objects+XRCoding.m                      XRHTTPRequest+HTTPAuthentication.m \
XMLRPCFramework.m                       XRHTTPRequest.m \
XRCoder.m                               XRHTTPResponse+HTTPAuthentication.m \
XRConnection.m                          XRHTTPResponse.m \
XRConstants.m                           XRInvocation.m \
XRDecoder.m                             XRInvocationStorage.m \
XREArray.m                              XRMethodSignature.m \
XREMethodCall.m                         XRProxy.m \
XREMethodResponse.m                     XRXMLParser.m \
XRXMLTagProcessor.m


XMLRPC_LIBRARIES_DEPEND_UPON += -lEDMessage


#XMLRPC_SUBPROJECTS = Future.subproj


XMLRPC_RESOURCE_FILES = \
Entity2String.plist String2Entity.plist \
String2XMLEntity.plist XMLRPCTags.plist \


include Version

# This seems odd, but on Mach the dyld supports
# major/compatibility, thus you just need a single number.
# On UNIX things are different, hence we use the
# CURRENT_PROJECT_VERSION as the MAJOR_VERSION.

MAJOR_VERSION = $(CURRENT_PROJECT_VERSION)
MINOR_VERSION = 0
SUBMINOR_VERSION = 0


-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/framework.make

-include GNUmakefile.postamble

endif
