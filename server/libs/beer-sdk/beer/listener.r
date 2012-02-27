Rebol [
	Title: "BEER Listener Handler"
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

listener-handler: func [
	{BEER listener handler}
	port
	/local peer
] [
    
    #if [all [value? 'spfix spfix]] [
		if port/locals/flag [
			;false-awake-event
			return port/locals/flag: false
	    ]
	]
	     
	unless error? try [peer: pick port 1] [
		debug ["Initiator" peer/remote-ip "connected"]
		peer: open/custom make port! [scheme: 'atcp sub-port: peer] reduce [
			'handler make session-handler-proto [] 'transfer-size MAXBUFLEN
		]     
		set-modes peer [binary: true lines: false]
		peer/user-data: make session-data [
			role: 'L
			buffer: make string! MAXBUFLEN + MAXFRAME
			; associative array, keys are channel numbers
			channels: aa/make EXPCURCHAN
			; round-robin queue of transmitting channels
			send-queue: make list! EXPSENDING
			free-chno: 2
			rights: rights? username
			open?: true
			remote-ip: peer/sub-port/remote-ip
			remote-port: peer/sub-port/remote-port
		]
		peer/locals/handler/port: peer
		peer/locals/handler/session: peer/user-data
		sessions: sessions + 1
		create-channel peer 0 'channel-management
		port/user-data/on-open peer
		wait-start peer
	]
    false
]

open-listener: func [
	beer-port-id [integer!]
	/callback call-back [function!]
	/local listener
] [
	listener: open/binary/direct/no-wait [
		scheme: 'TCP
		port-id: beer-port-id
	]
	listener/user-data: make object! [on-open: :call-back]
	
	#if [all [value? 'spfix spfix]] [
		listener/locals: make object! [flag: false]
	]
	
	listener/awake: :listener-handler
	wait-start listener
	listener
]
