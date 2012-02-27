Rebol [
	Title: "BEER Protocol Sending"
	Date: 22-Apr-2005/10:49:42+2:00
	License: {
Copyright (C) 2005 Why Wire, Inc.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

Other commercial licenses to this program are available from Why Wire, Inc.
}
]

round-robin: func [
	{asynchronous transmission for all channels}
	port
	/local frame session queue size channel final final? callback leave
] [
	session: port/user-data
	if session/sending? [exit] ; round-robin already working
	session/sending?: true
	queue: session/send-queue
	leave: [
		session/send-queue: queue
		session/sending?: false
		exit
	]
	final: back either head? queue [tail queue] [queue] ; the last position
	; possible payload size
	size: min MAXSIZE (part-sub session/out-win session/out-seqno) - MAXHT
	if 0 >= size leave ; output window full
	while [true] [
		if tail? queue [queue: head queue] ; round
		if empty? queue leave
		final?: same? queue final
		channel: first queue
		; debug ["rr-channel:" channel/chno]
		; ask the handler to supply a frame or a sync block
		set/any 'frame channel/write channel size
		; probe type? get/any 'frame
		either any [object? get/any 'frame block? get/any 'frame] [
			; debug "round-robin"
			; probe frame
			either block? frame [
				set [frame callback] frame ; a sync block
			] [callback: none]
			send-ll channel frame
			session/send-queue: queue: either all [
				frame/more = '.
				frame/msgtype <> 'ANS
			] [
				; handler has done its job - unregistration (robin)
				channel/write: none
				remove queue
			] [next queue]
			do callback ; synchronize
			; check whether the channel waits for another transmission
			send-reply? channel
			; update size
			size: min MAXSIZE
				(part-sub session/out-win session/out-seqno) - MAXHT
			if 0 >= size leave ; output window full
			; successful write, reset the final position
			final: back either head? queue [tail queue] [queue]
			final?: false
		] [
			queue: either get in channel 'write [next queue] [remove queue]
		]
		if final? leave
	]
]

send-seq: func [
	{Send a seq frame, if useful, high priority, low level}
	port free /local session shift frame new-window
] [
	session: port/user-data
	new-window: part-add session/in-seqno MAXBUFLEN + free
	shift: part-sub new-window session/in-win
	if WIN-SHIFT <= shift [
		if MAXSEQFRAME > part-sub session/out-win session/out-seqno [
			; debug "send-seq: Output window full"
			exit
		]
		session/in-win: new-window
		frame: [#{} "SEQ " new-window "^M^/"]
		; update the out-seqno
		session/out-seqno: part-add session/out-seqno MAXSEQFRAME
		if error? try [insert port rejoin frame] [
			; peer probably closed the session
			destroy-session port "Cannot transmit SEQ"
		]
	]
]

; low level frame send
send-ll: func [
	[catch]
	channel frame /local format-block msgno session size
] [
	session: channel/port/user-data
	if none? frame/payload [frame/payload: #{}]
	size: length? frame/payload
	; check the continuation indicator
	unless any [frame/more = '. frame/more = '*] [
		; probe frame
		throw make error! "wrong continuation indicator"
	]
	either frame/msgtype = 'MSG [
		msgno: channel/out-msgno
		either channel/out-msg-fragment [
			; update the sent and unreplied message size
			change back tail channel/out-sizes (last channel/out-sizes) +
				(length? frame/payload)
			channel/out-msg-stored: channel/out-msg-stored +
				length? frame/payload
		] [
			; update the sent and unreplied message
			insert tail channel/out-unreplied msgno
			insert tail channel/out-sizes MAXHT + length? frame/payload
			channel/out-msg-stored: channel/out-msg-stored + MAXHT +
				length? frame/payload
		]
		if frame/more = '. [
			; update out-msgno
			channel/out-msgno: part-add channel/out-msgno 1
		]
		; change the fragment indicator
		channel/out-msg-fragment: frame/more = '*
	] [
		if empty? head channel/in-unreplied [
			;debug mold frame
			throw make error! "No reply expected"
		]
		msgno: first head channel/in-unreplied
		if all [
			frame/more = '.
			frame/msgtype <> 'ANS
		] [
			; update the list of received and unreplied messages
			channel/in-unreplied: remove head channel/in-unreplied
		]
	]
	if channel/encrypted? [
		frame/payload: encloak/with frame/payload session/key
	]
	; create format block
	format-block: either frame/msgtype = 'ANS [
		[#{} msgtype " " channel/chno " " msgno " " more " " session/out-seqno " " size " " ansno "^M^/" payload "END^M^/"]
	] [
		[#{} msgtype " " channel/chno " " msgno " " more " " session/out-seqno " " size "^M^/" payload "END^M^/"]
	]
	; format the frame
	frame: rejoin bind format-block in frame 'self
	; update out-seqno
	session/out-seqno: part-add session/out-seqno size + MAXHT
	; debug ["outseqno:" session/out-seqno]
	if error? try [insert channel/port frame] [
		; peer probably closed the session
		destroy-session channel/port "Cannot transmit message"
	]
]

send-reply?: func [
	{check whether a MSG can be sent or replied and do the appropriate action}
	[catch]
	channel
	/local out-queue out-frame m-size in-frame can-send?
] [
	if get in channel 'write [exit] ; already writing
	can-send?: all [
		0 = channel/closing?
		out-queue: head channel/out-msg-queue
		not empty? out-queue
		(
			out-frame: first out-queue
			unless object? :out-frame [
				debug type? :out-frame
				;probe :out-frame
				throw make error!
					"wrong frame type in out-msg-queue - shouldn't happen"
			]
			m-size: MAXMSGLEN - channel/out-msg-stored - MAXHT
			; "lock condition"
			m-size >= length? out-frame/payload
		)
	]
	; debug ["can-send?" can-send?]
	if all [
		; can reply a msg?
		not empty? head channel/in-msg-queue
		(
			in-frame: first head channel/in-msg-queue
			in-frame/more = '.
		)
		any [
			not can-send?
			; in-msg/out-msg race, use the reply? switch to be fair
			channel/reply?: not channel/reply?
		]
	] [
		; debug "reply"
		; reply in-frame
		channel/in-msg-queue: remove head channel/in-msg-queue
		channel/in-msg-stored: channel/in-msg-stored - MAXHT -
			length? in-frame/payload
		channel/read-msg channel in-frame
		exit
	]
	unless can-send? [exit]
	channel/out-msg-queue: remove head channel/out-msg-queue
	channel/outgoing: out-frame
	channel/callback: all [
		not empty? head channel/out-msg-queue
		block? set/any 'out-frame first head channel/out-msg-queue
		channel/out-msg-queue: remove head channel/out-msg-queue
		out-frame
	]
	register-sending channel :simple-write
]

register-sending: func [
	{register a write handler for the channel}
	channel [object!]
	write-handler [any-function!]
	/local session
] [
	either get in channel 'write [
		; just replace a handler
		channel/write: :write-handler
	] [
		channel/write: :write-handler
		session: channel/port/user-data
		; round-robin registration
		insert session/send-queue channel
	]
	; trigger transmission
	round-robin channel/port
]

send-frame: func [
	{send a frame}
	[catch]
	channel
	frame
	/callback call-back [block!]
] [
	either frame/msgtype = 'MSG [
		insert tail channel/out-msg-queue frame
		; debug ["out-msg-queue" mold head channel/out-msg-queue]
		if callback [insert/only tail channel/out-msg-queue call-back]
		send-reply? channel
	] [
		channel/outgoing: frame
		channel/callback: call-back
		register-sending channel :simple-write
	]
]

simple-write: func [
	{simple message write handler - unsuitable for file transfer}
	[catch]
	channel
	siz
	/local callback message
] [
	unless message: channel/outgoing [throw make error! "Nothing to send"]
	callback: channel/callback
	either siz >= length? message/payload [
		; the whole reply can be sent
		channel/outgoing: channel/callback: none
		either block? get/any 'callback [reduce [message callback]] [message]
	] [
		; send a fragment
		make frame-object [
			msgtype: message/msgtype
			more: '*
			ansno: message/ansno
			payload: copy/part message/payload siz
			message/payload: skip message/payload siz
		]
	]
]
