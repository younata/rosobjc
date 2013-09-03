#!/usr/bin/env python2.7

import rospkg.rospack
import sys
import os
import string

import roslib.gentools
import genmsg.msgs as msgs

def testConfirm(fn):
    l = ['bool', 'int8', 'uint8', 'int16', 'uint16', 'int32', 'uint32', 'int64', 'uint64', 'float32', 'float64', 'string', 'time', 'duration']
    b = os.path.basename(fn)[:-4].lower()
    return b in l

def cat(fileDeps):
    return roslib.gentools.compute_full_text(fileDeps)

def md5(fileDeps):
    return roslib.gentools.compute_md5(fileDeps)

def getFileDeps(fileName):
    return roslib.gentools.get_file_dependencies(fileName)

def packageName(fileName):
    a = rospkg.rospack.get_package_name(fileName)
    b = os.path.basename(fileName)
    return "%s/%s" % (a, b[:-4])

def convertBaseToObjc(baseType, context):
    base_type, is_array, array_length = msgs.parse_type(baseType)
    if is_array:
        return "NSArray"
    if msgs.is_header_type(base_type):
        return "ROSMsgstd_msgsHeader"
    baseType = baseType.lower()
    nums = ['bool', 'int8', 'uint8', 'int16', 'uint16', 'int32', 'uint32', 'int64', 'uint64', 'float32', 'float64']
    if baseType in nums:
        return "NSNumber"
    if baseType == "string":
        return "NSString"
    times = ['time', 'duration']
    if baseType in times:
        return "ROSTime"
    return "NSObject"

def writeHeader(className, fn, msgFileLoc):
    f = open(fn+".h", "a")
    a = string.join(className.split("/"), "")
    f.write("@interface ROSMsg%s : ROSMsg\n" % a)
    j = open(msgFileLoc)
    c = j.read()
    j.close()
    for line in c.split("\n"):
        line = line.strip()
        line = line.split("#")[0]
        l = line.split(" ")
        if len(l) == 2:
            t = l[0]
            n = l[1]
            f.write("@property (nonatomic, retain) %s *%s;\n" % (convertBaseToObjc(t), n))
        elif len(l) == 3:
            t = l[0]
            n = l[1]
            d = l[2]
            f.write("@property (nonatomic, retain, readonly) %s *%s;\n" % (convertBaseToObjc(t), n))
    f.write("@end\n")
    f.write("\n\n");
    f.close()

def writeImpl(className, fn, msgFileLoc, classDef, md5):
    f = open(fn+".m", "a")
    a = string.join(className.split("/"), "")
    f.write("@implementation ROSMsg%s\n" % a)
    f.write("-(NSString *)md5sum { return @\"%s\"; }\n" % md5)
    j = open(msgFileLoc)
    c = j.read();
    j.close()
    blah = str(c)
    argle = string.join(blah.split("\n"), "\\n")
    f.write("-(NSString *)_messageDefinition { return @\"%s\"; }\n" % argle)

    argle = string.join(classDef.split("\n"), "\\n")
    f.write("-(NSString *)definition { return @\"%s\"; }\n" % argle)
    f.write("-(NSString *)type { return @\"%s\"; }\n" % className)
    fields = []
    for line in c.split("\n"):
        line = line.strip()
        line = line.split("#")[0]
        l = line.split()
        if len(l) == 2:
            t = l[0].lower()
            n = l[1]
            #t = convertBaseToObjc(t)
            fields.append([t, n])
        if len(l) == 3:
            t = l[0]
            n = l[1]
            d = l[2]
            blah = convertBaseToObjc(t)
            if blah == "NSNumber":
                f.write("-(NSNumber *)%s { return @(%s); }\n" % (n, d))
            elif blah == "NSString":
                f.write("-(NSString *)%s { return @\"%s\"; }\n" % (n, d))
            elif blah == "NSArray":
                f.write("-(NSArray *)%s { return @%s; }\n" % (n, d))
            #elif blah == "ROSTime":
            #    f.write("-(ROSTime *)%s { ROSTime *r = [[ROSTime alloc] init]; r.secs = %s; r.nsecs = %s" % (n, 
    f.write("-(NSArray *)fields { return @[");
    for i in fields:
        f.write("@[@\"%s\", @\"%s\"], " % (i[0], i[1])) 
    f.write("]; }\n")

    f.write("-(NSData *)serialize { return serialize(self, @selector(serialize)); }\n")
    f.write("-(NSArray *)deserialize:(NSData *)d { return deserialize(self, @selector(deserialize:), d); }\n")
    f.write("@end\n")
    f.write("\n\n");
    f.close()
    
def generateSingleMsg(f, classFile, knownRosMsgs):
    if not testConfirm(f):
        return
    a = packageName(f)
    b = getFileDeps(f)
    c = cat(b)
    m = md5(b)
    writeImpl(a, classFile, f, c, m)
    writeHeader(a, classFile, f)
    ret = "ROSMsg" + string.join(a.split("/"), "")
    print ret
    return (ret, a.split("/")[0], a.split("/")[1])
    #print a
    #print m
    #print c

def main()
    classFile = "ROSGenMsg"
    knownRosLibraries = []
    for root, dirs, files in os.walk("/opt/ros/groovy"):
        for i in files:
            if i.endswith(".msg"):
                knownRosLibraries.append(generateSingleMsg(root + "/" + i, classFile))
                

if __name__ == "__main__":
    main()
