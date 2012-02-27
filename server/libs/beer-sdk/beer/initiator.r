Rebol [
	Title: "BEER Session Handler"
	Date: 17-Jan-2006/16:04:58+1:00
	License: {
Copyright (C) 2005 Why Wire, Inc.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

Other commercial licenses to this program are available from Why Wire, Inc.
}
]

#include-check %iatcp-protocol.r
#include-check %session-handler.r
#include-check %aa.r
#include-check %channel.r
#include-check %authenticate.r

open-session: func [
	url [url! block!]
	callback [function!]
	/timeout t [time!]
	/local peer
] [
	; default timeout is 3 seconds
	t: any [t 0:0:3]
	if url? url [
		peer: make object! [
			host: port-id: target: user: pass: path: timeout: none
		]
		net-utils/url-parser/parse-url peer url
		url: third peer
	]
	insert tail url [scheme: 'ATCP timeout: t]
	peer: open/binary/direct/custom url reduce [
		'handler make session-handler-proto [] 'transfer-size MAXBUFLEN
	]
	peer/user-data: make session-data [
		role: 'I
		buffer: make string! MAXBUFLEN + MAXFRAME
		channels: aa/make MAXCURCHAN ; keys are channel numbers
		send-queue: make list! EXPSENDING ; round-robin queue
		free-chno: 1
		rights: rights? username
		on-open: :callback
		open?: true
		remote-ip: peer/sub-port/remote-ip
		remote-port: peer/sub-port/remote-ip
	]
	peer/locals/max-retry: 1
	peer/locals/handler/port: peer
	peer/locals/handler/session: peer/user-data
	wait-start peer
]
