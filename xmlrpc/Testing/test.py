#!/usr/bin/env python

import xmlrpclib
    
server_url = 'http://localhost:2333/RPC2';
server = xmlrpclib.Server(server_url);
    
result = server.sample.doStuff([ "<&uuml;>", "quote \" unquote \"", { "key" : "value" } ])
print "Result:", result
