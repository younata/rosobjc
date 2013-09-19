rosobjc - ROS client library for Objective-C.
***
##What is ROSObjc?

ROSObjc is a client library for ROS ([Robot Operating System](http://wiki.ros.org)) written in Objective-C. It was written to make it easier to integrate ROS with iOS and OSX applications, because it sucked trying to get it to work with C++ on iOS.

This is intended to be a simple drop-in library that you can use to communicate with ROS running on other machines. That is, no other installation of ROS is required to use this.

I'm providing it under the same BSD license that ROS is under, to encourage others to adopt and use it. There is also an example (iOS) application that I wrote, and has the [source code here](https://github.com/younata/ROSViewer/). I am working on an example osx application.

##Why should you use ROS or ROSObjc?

Ros should be used for the pre-existing software you can distribute throughout several machines on the same network. This is great in a research lab setting (and other settings) in that you can have the robot just gather sensor data, and easily offload it to other machines. Some data (e.g. camera) is expensive to send on a network for processing, so it might also be dealt with on the device. ROS works for both local and remote networking.

Of course, that's just why you should use a messaging system. ROS specifically should be used for the preexisting software that you can use - such as [Move It](http://moveit.ros.org/wiki/MoveIt!), [Gazebo](http://gazebosim.org/), [rviz](http://wiki.ros.org/rviz), or one of [the many other ros packages available to use](http://www.ros.org/browse/list.php).

ROSObjc should be used for iOS or OSX applications where it's not desireable, practical, or possible to have the full ROS stack installed, but the network communication protocols and the message passing is desireable (for example, using an iPhone's motion sensors and gps to add better/more location data to a system). The primary example here being any iOS app for interacting with a robot which uses ROS. There is also, however, room for native OSX applications which also use ROS. The goal is to enable people to easily write applications in pure objective-c which take advantage of ROS.

###Building

It is currently recommended that you just drag the entire rosobjc folder into your project. I am working on changing this, but it's not that high on the todo list.

This framework uses the ROS prefix for all classes and files, with the exception of rosobjc.h

To compile a static library under iOS, select the "rosobjc-ios" target.

To compile a framework under osx, select the "rosobjec-osx" target.

The current (known) dependencies on this are:

- Cocoa (osx) or UIKit (iOS)
- Security.framework
- CFNetwork

This may or may not compile under xcode 4, it is being developed under xcode 5.

Note that this is still very much so in development.

######TODO

The full TODO list is available in the [TODO](TODO) file.

Subscribing to topics that publish built-in messages works, and that's about it.
