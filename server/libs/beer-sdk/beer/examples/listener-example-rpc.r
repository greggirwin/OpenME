Rebol [
	Title: "BEER Listener Example"
	Date: 18-Jan-2006/15:06:14+1:00
	License: {
Copyright (C) 2005 Why Wire, Inc.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

Other commercial licenses to this program are available from Why Wire, Inc.
}
]

do %../../paths.r

; user database
users: load %users.r
groups: load %groups.r

do %encoding-salt.r
include/check %listener.r
include/check %rpc-profile.r

;load and publish all services available
foreach s reduce load %listener-services.r [
	publish-service s
]

open-listener 8000

print ["RPC listener is up!" now]

do-events
halt
