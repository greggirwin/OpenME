Rebol [
	Title: "BEER Session Handler"
	Date: 19-Jan-2006/11:41:15+1:00
	License: {
Copyright (C) 2005 Why Wire, Inc.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

Other commercial licenses to this program are available from Why Wire, Inc.
}
]

#include-check %frameparser.r
#include-check %frameread.r
#include-check %framesend.r
#include-check %profiles.r

debug: :print
log-error: :print

destroy-session: func [port msg /local session callback] [
	session: port/user-data
	if session/open? [
		session/open?: false
		log-error msg
		sessions: sessions - 1
		clear head session/send-queue
		close-iatcp port
		callback: get in session 'on-close
		callback form reduce msg
	]
]

create-channel: func [
	[catch]
	port
	channel-number
	profile-name
	/local channel session
] [
	debug ["Creating channel" channel-number "using profile" profile-name]
	session: port/user-data
	if aa/get session/channels channel-number [
		throw make error! "channel already exists"
	]
	if all [profile-name = 'channel-management channel-number <> 0] [
		throw make error! rejoin [
			"Channel management profile not allowed for channel " channel-number
		]
	]
	channel: make channel-data [
		unless profile: in profile-registry profile-name [
			throw make error! "Unsupported profile"
		]
		profile: get profile
		chno: channel-number
		out-unreplied: make list! EXPUNREPLIED
		out-sizes: make list! EXPUNREPLIED
		in-unreplied: make list! EXPUNREPLIED
		in-msg-queue: make list! EXPUNREPLIED
		out-msg-queue: make list! EXPUNREPLIED
		encrypted?: found? session/key
	]
	channel/port: port
	aa/set session/channels channel-number channel
	channel/profile/init channel
	; debug "Channel created"
	channel
]

destroy-channel: func [
	[catch]
	channel
	/local session
] [
	channel/write: none
	session: channel/port/user-data
	aa/get/default session/channels channel/chno [
		throw make error! "Destroying nonexistent channel"
	]
	aa/remove session/channels channel/chno
]

session-handler-proto: make atcp-handler-proto [
	session: none
	
	error: does [destroy-session port "Error event"]
    dns-failure: does [destroy-session port "DNS failure"]
    dns: does [
		debug [
			"dns success:" port/host ":" port/sub-port/port-id
		]
    ]
    max-retry: does [destroy-session port "Can't connect to listener"]
    connect: does [
		sessions: sessions + 1
		create-channel port 0 'channel-management
		callback: get in session 'on-open
		callback port
    ]
    read: does [
   		data: copy port
   		insert tail session/buffer data
		; check whether the data fit into the input window
		excess: (part-sub session/in-seqno session/in-win) +
			length? session/buffer
		if 0 < excess [
			destroy-session port [
				"Input window exceeded by" excess
				"in-seqno" session/in-seqno
				"in-win" session/in-win
				"data" length? data
			]
		]

		; debug length? data

		; new input expected
		send-seq port length? session/buffer

		; process data
		unless parse-frames session/buffer func [
			msgtype chno msgno more seqno ansno payload processed
		] [
			read-frame port msgtype chno msgno more seqno ansno payload processed
		] [
			; poorly formed frame handling
			destroy-session port "Poorly formed frame"
		]

		; new input expected
		send-seq port length? session/buffer
	]
    write: none
    close: does [
		debug stats
		destroy-session port "Peer closed the connection."
    ]
	unknown: func [event] [       
        destroy-session port [
			"Unexpected event" event "should not happen"
		]
    ]
]
