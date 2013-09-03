#!/usr/bin/env python2.7

def main(classList):
    r = "@["
    for i,x in enumerate(classList):
        r += "[%s class]" % x
        if i != len(classList) - 1:
            r += ", "
    r += "]"
    return r

if __name__ == "__main__":
    a = raw_input()
    classList = a.split(" ")
    print main(classList)
