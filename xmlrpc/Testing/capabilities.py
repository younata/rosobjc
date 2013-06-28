#!/usr/bin/env python

import xmlrpclib

server = xmlrpclib.Server("http://localhost:2333")
#server = xmlrpclib.Server("http://xmlrpc-c.sourceforge.net/api/sample.php")

for method in server.system.listMethods():
	print method
	print server.system.methodHelp(method)
	print "signature:", server.system.methodSignature(method)
	print

#print server.system.methodHelp("sample.doStuff")
#print server.sample.doStuff([{ "key" : "name" , "value" : "bla" }, [ 1, 2 , 3], (0 == 0), (0 != 1)])
#b = server.sample.testIfTrue(1)
#print b
#if b:
#	print "server returned true."
#else:
#	print "server returned false!"

#arg = "sample.doStuff"
#print "Getting signature of ", arg, " = ", server.system.methodSignature(arg)
