/*
 * Copyright (c) 2005 Apple Computer, Inc. All rights reserved.
 *
 * @APPLE_LICENSE_HEADER_START@
 * 
 * This file contains Original Code and/or Modifications of Original Code
 * as defined in and that are subject to the Apple Public Source License
 * Version 2.0 (the 'License'). You may not use this file except in
 * compliance with the License. Please obtain a copy of the License at
 * http://www.opensource.apple.com/apsl/ and read it before using this
 * file.
 * 
 * The Original Code and all software distributed under the License are
 * distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR NON-INFRINGEMENT.
 * Please see the License for the specific language governing rights and
 * limitations under the License.
 * 
 * @APPLE_LICENSE_HEADER_END@
 */

#ifndef __XLOCALE_H_
#define __XLOCALE_H_

#include <sys/cdefs.h>
#include <_bounds.h>
#include <_mb_cur_max.h>
#include <_types/_locale_t.h>

_LIBC_SINGLE_BY_DEFAULT()

__BEGIN_DECLS
int		___mb_cur_max_l(locale_t);
__END_DECLS

#undef MB_CUR_MAX_L
#define MB_CUR_MAX_L(x)			(___mb_cur_max_l(x))

#endif /* __XLOCALE_H_ */
