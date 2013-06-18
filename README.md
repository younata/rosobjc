rosobjc - ROS client library for Objective-C.
***
##What is this?

This is a client library for ROS written in Objective-C. It was written to make it easier to integrate ROS with iOS and OSX applications, because it sucked trying to get it to work with C++.

I'm providing it under the same BSD license that ROS is under, to encourage others to adopt and use it. There is also an example (iOS) application that I wrote, which you can download on the app store, and has the source code here, it basically behaves like rostopic.

This framework uses the RO (RosObjc) prefix for all classes and files, with the exception of rosobjc.h

To compile a static library under iOS, select the "rosobjc-ios" target.

To compile a framework under osx, select the "rosobjec-osx" target.

Note that this is still very much so in development. It is not even usable at this point.
