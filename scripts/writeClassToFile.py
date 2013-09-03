import string

def writeImplementation(className, fn):
    f = open(fn, "a")
    a = string.join(className.split("/"), "")
    f.write("@interface ROSMsg%s : ROSMsg\n" % a)
    

    f.write("@end\n")
    f.close()

if __name__ == "__main__":
    import sys
    className = sys.argv[1]
    s = sys.stdin
    packageName = s.readline()
    md5sum = s.readline()
    definition = ""
    while True:
        b = s.readline
        definition += b
        if b == "\n":
            break
    
