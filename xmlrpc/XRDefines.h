//
//  XRDefines.h
//  XMLRPC
//
//  Created by znek on Tue Aug 14 2001.
//  $Id: XRDefines.h,v 1.6 2002/07/18 01:24:32 znek Exp $
//
//  Copyright (c) 2001 by Marcus MŸller <znek@mulle-kybernetik.com>.
//  All rights reserved.
//
//  Permission to use, copy, modify and distribute this software and its documentation
//  is hereby granted under the terms of the GNU Lesser General Public License, version 2.1
//  as published by the Free Software Foundation, provided that both the copyright notice
//  and this permission notice appear in all copies of the software, derivative works or
//  modified versions, and any portions thereof, and that both notices appear in supporting
//  documentation, and that credit is given to Marcus MŸller in all documents and publicity
//  pertaining to direct or indirect use of this code or its derivatives.
//
//  This is free software; you can redistribute and/or modify it under
//  the terms of the GNU Lesser General Public License, version 2.1 as published by the Free
//  Software Foundation. Further information can be found on the project's web pages
//  at http://www.mulle-kybernetik.com/software/XMLRPC
//
//  THIS IS EXPERIMENTAL SOFTWARE AND IT IS KNOWN TO HAVE BUGS, SOME OF WHICH MAY HAVE
//  SERIOUS CONSEQUENCES. THE COPYRIGHT HOLDER ALLOWS FREE USE OF THIS SOFTWARE IN ITS
//  "AS IS" CONDITION. THE COPYRIGHT HOLDER DISCLAIMS ANY LIABILITY OF ANY KIND FOR ANY
//  DAMAGES WHATSOEVER RESULTING DIRECTLY OR INDIRECTLY FROM THE USE OF THIS SOFTWARE
//  OR OF ANY DERIVATIVE WORK.
//---------------------------------------------------------------------------------------


#ifndef	__XRDefines_h_INCLUDE
#define	__XRDefines_h_INCLUDE


#define XRLogWarning		0x0100
#define XRLogInfo			0x0200
#define XRLogDebug			0x0400
#define XRLogConnection		0x0800
#define XRLogMessage		0x1000
#define XRLogXML			0x2000
#define XRLogXRE			0x4000
#define XRLogObjReg		0x8000


// Defines to handle extern declarations on different platforms

/*" Ignore this stuff. It is needed thanks to Microsoft's great DLL implementation. "*/

#if defined(__MACH__)

#ifdef __cplusplus
// This isnt extern "C" because the compiler will not allow this if it has
// seen an extern "Objective-C"
#  define XMLRPC_EXTERN		extern
#else
#  define XMLRPC_EXTERN		extern
#endif


#elif defined(WIN32)

#ifdef _BUILDING_XMLRPC_DLL
#  define XMLRPC_DLL_GOOP		__declspec(dllexport)
#else
#  define XMLRPC_DLL_GOOP		__declspec(dllimport)
#endif

#ifdef __cplusplus
#  define XMLRPC_EXTERN		extern "C" XMLRPC_DLL_GOOP
#else
#  define XMLRPC_EXTERN		XMLRPC_DLL_GOOP extern
#endif


#else

#ifdef __cplusplus
#  define XMLRPC_EXTERN		extern "C"
#else
#  define XMLRPC_EXTERN		extern
#endif


#endif

#endif	/* __XRDefines_h_INCLUDE */
