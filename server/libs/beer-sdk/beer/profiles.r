Rebol [
	Title: "BEER Profiles"
	Date: 16-Mar-2006/17:19:52+1:00
	License: {
Copyright (C) 2005 Why Wire, Inc.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

Other commercial licenses to this program are available from Why Wire, Inc.
}
]

profile-registry: make object! [] ; the profile registry, starting as empty

register: func [profile-o [object!]][
	profile-registry: make profile-registry compose [
		(to set-word! profile-o/profile) profile-o
	]
]

registered?: func [profile [word!] version [tuple!]][
	all [
		in profile-registry profile
		profile-registry/:profile/version = version
	]
]

register context [
	profile: 'channel-management
	version: 1.0.0

	; initial handler
	init: func [
		channel [object!]
	] [

		; adjust the channel state for my own and peer's dummy MSG 0
				
		channel/out-msgno: 1 ; my MSG 0 was "dummy"
		insert tail channel/out-unreplied 0 ; my MSG 0 has to be replied
		insert tail channel/out-sizes MAXHT ; my MSG 0 had the minimal size
		channel/out-msg-stored: MAXHT ; my MSG 0 had the minimal size
		
		channel/in-msgno: 1 ; peer's MSG 0 was "dummy"
		insert tail channel/in-unreplied 0 ; peer's MSG 0 has to be replied
		channel/in-msg-stored: MAXHT ; peer's MSG 0 had the minimal size
		
		; the initial reply handler
		channel/read-rpy: :read-greeting

		; the initial read-msg handler
		channel/read-msg: func [channel] [
			; unavailable until greeting received
			send-frame channel make frame-object [
				msgtype: 'ERR
				more: '.
				payload: to binary! "Greeting not received yet"
			]
		]

		channel/prof-data: make object! [
			; pending requests
			requests: make list! EXPUNREPLIED
			; reply to defragment
			rpy-to-complete: none
			channel-to-close: none
			challenge: none
			password: none ; my own password
			key: none
		]
		
		channel/close: func [channel /ask] [none]

		; send greeting
		send-frame channel make frame-object [
			msgtype: 'RPY
			more: '.
			payload: to binary! mold/only [greeting]
		]
	]
	
	read-greeting:  func [channel frame /local prof-data] [
		prof-data: channel/prof-data
		debug ["frame:" mold frame]
		
		either prof-data/rpy-to-complete [
			; defragment
			prof-data/rpy-to-complete/more: frame/more
			insert tail prof-data/rpy-to-complete/payload frame/payload
		] [
			prof-data/rpy-to-complete: frame
			if frame/msgtype <> 'RPY [poorly-formed "Peer unavailable"]
		]
		frame: prof-data/rpy-to-complete
		if MAXMSGLEN < length? frame/payload [
			poorly-formed "Short reply expected"
		]
		if frame/more = '* [exit] ; waiting for complete rpy
		prof-data/rpy-to-complete: none
		
		; RPY arrived, processing
		either all [
			not error? try [frame/payload: load/all frame/payload]
			parse frame/payload ['greeting]
		] [
			; greeting received, we can proceed further
			debug "greeting received"
			channel/read-msg: :read-further
			channel/read-rpy: :management-reply
		] [
			; peer unavailable
			poorly-formed "Peer unavailable"
		]
	]

	read-further: func [
		[catch]
		channel frame
		/local
		session chno profile-arg version-arg channel-arg port result
		err-frame prof-data response start stop login answer
	] [
		start: [
			'start set chno number!
			'with-profile
			set profile-arg word!
			set version-arg tuple!
			(
				catch' [
					if 0 < channel/closing? [
						send-frame channel make frame-object [
							msgtype: 'ERR
							more: '.
							payload: to binary! "Closing Channel 0"
						]
						throw'
					]
					
					if aa/get session/channels chno [
						send-frame channel make frame-object [
							msgtype: 'ERR
							more: '.
							payload: to binary! mold/only reduce [
								"Channel" chno "already exists"
							]
						]
						throw'
					]
		
					unless registered? profile-arg version-arg [
						send-frame channel make frame-object [
							msgtype: 'ERR
							more: '.
							payload: to binary! mold/only reduce [
								"Unsupported profile: "
								profile-arg version-arg
							]
						]
						throw'
					]
				
					if profile-arg = 'channel-management [
						send-frame channel make frame-object [
							msgtype: 'ERR
							more: '.
							payload: to binary! mold/only reduce [
								"Channel-management profile not available for channel"
								chno
							]
						]
						throw'
					]
					
					aa/get/default session/rights profile-arg [
						send-frame channel make frame-object [
							msgtype: 'ERR
							more: '.
							payload: to binary! "Insufficient rights"
						]
						throw'
					]

					if (even? chno) xor (session/role = 'I) [
						send-frame channel make frame-object [
							msgtype: 'ERR
							more: '.
							payload: to binary! mold/only reduce [
								"Wrong chno parity" chno
							]
						]
						throw'
					]
					
					; create channel
					send-frame/callback channel make frame-object [
						msgtype: 'RPY
						more: '.
						payload: to binary! mold/only [ok]
					] compose [
						create-channel (channel/port) (chno) (to lit-word! profile-arg)
					]

				]
			)
		]
		
		stop: ['stop set chno number! (
			catch' [
				if 0 < channel/closing? [
					send-frame channel make frame-object [
						msgtype: 'ERR
						more: '.
						payload: to binary! "Closing Channel 0"
					]
					throw'
				]
					
				unless channel-arg: aa/get session/channels chno [
					send-frame channel make frame-object [
						msgtype: 'ERR
						more: '.
						payload: rejoin [#{} "Channel" chno "doesn't exist"]
					]
					throw'
				]
				
				; discern channel and session close
				either chno <> 0 [
					; close channel
					; check whether the request should be refused
					either all [
						object? set/any 'err-frame close-channel? channel-arg
						in err-frame 'msgtype
						err-frame/msgtype = 'ERR
					] [
						; refuse to close
						send-frame channel err-frame
					] [
						debug ["channel" chno "close accepted"]
						channel/prof-data/channel-to-close: channel-arg
						channel-arg/closing?: channel-arg/closing? + 1
						register-sending channel :close-channel-ll
					]
				] [
					; close session
					catch' [
						; check, whether the request should be refused
						; ask all channels
						foreach channel-arg next head session/channels/values [
							if all [
								object? set/any 'err-frame close-channel?/ask channel-arg
								in err-frame 'msgtype
								err-frame/msgtype = 'ERR
							] [
								; request refused, done
								send-frame channel err-frame
								throw'
							]
						]
						; request accepted, tell every channel
						channel/closing?: channel/closing? + 1
						foreach channel-arg next head session/channels/values [
							channel-arg/closing?: channel-arg/closing? + 1
							if all [
								object? set/any 'err-frame close-channel? channel-arg
								in err-frame 'msgtype
								err-frame/msgtype = 'ERR
							] [
								throw make error! rejoin ["Channel " channel-arg/chno " refused close"]
							]
						]
						register-sending channel :close-session-ll
					]
				]
			]
		)]
	
		login: ['login (
			catch' [
				if 0 < channel/closing? [
					send-frame channel make frame-object [
						msgtype: 'ERR
						more: '.
						payload: to binary! "Closing Channel 0"
					]
					throw'
				]
				
				if prof-data/challenge [
					; peer tries login after receiving a challenge
					poorly-formed "Challenge already sent"
				]
				prof-data/challenge: make-challenge encoding-salt
				send-frame channel make frame-object [
					msgtype: 'RPY
					more: '.
					payload: to binary! mold/only head insert tail copy [
						challenge
					] prof-data/challenge
				]
			]
		)]
	
		answer: ['answer set response binary! (
			catch' [
				if 0 < channel/closing? [
					send-frame channel make frame-object [
						msgtype: 'ERR
						more: '.
						payload: to binary! "Closing Channel 0"
					]
					throw'
				]
					
				unless prof-data/challenge [
					; peer is sending an answer without receiving a challenge
					poorly-formed "Challenge not sent"
				]
				unless response: verify-challenge users prof-data/challenge response [
					log-error "Login incorrect"
					send-frame channel make frame-object [
						msgtype: 'ERR
						more: '.
						payload: to binary! "Login incorrect"
					]
					throw'
				]
				session/username: response/1
				session/key: response/2
				session/rights: rights? session/username
				debug ["user" session/username "logged in"]

				send-frame/callback channel make frame-object [
					msgtype: 'RPY
					more: '.
					payload: to binary! mold/only [ok]
				] bind [
					; start encrypted transmission
					encrypted?: true
				] in channel 'self
			]
		)]
	
		debug ["frame:" mold frame]
		prof-data: channel/prof-data

		port: channel/port
		session: port/user-data

		if any [
			error? try [
				frame/payload: load/all to string! frame/payload
			]
			not parse frame/payload [start | stop | login | answer]
		] [
			send-frame channel make frame-object [
				msgtype: 'ERR
				more: '.
				payload: to binary! "Unexpected message in channel 0"
			]
		]
	]

	management-reply: func [
		channel frame
		/local request new-channel prof-data session encoding-salt salt
	] [
		ok: ['ok (
			catch' [
				if 'stop = request/type [
					debug ["destroying channel" request/channel/chno]
					either request/channel/chno = 0 [
						destroy-session channel/port "Closing session"
					] [
						destroy-channel request/channel
					]
					request/callback-f true
					throw'
				]
				if 'start = request/type [
					new-channel: create-channel channel/port request/chno
						request/profile-name request/version-no
					request/callback-f new-channel
					throw'
				]
				if 'answer = request/type [
					debug ["login successful"]
					session: channel/port/user-data
					session/username: "listener"
					session/key: request/key
					session/rights: rights? session/username
					channel/closing?: channel/closing? - 1
					channel/encrypted?: true
					request/callback-f true
					throw'
				]
			]
		)]

		error: [
			catch' [
				if 'stop = request/type [
					either 0 = request/channel/chno [
						foreach channel-arg session/channels/values [
							channel-arg/closing?: channel-arg/closing? - 1
						]
					] [
						request/channel/closing?: request/channel/closing? - 1
					]
					throw'
				]
				if 'answer = request/type [
					channel/closing?: channel/closing? - 1
					throw'
				]
			]
			request/callback-f none
			true
		]
		
		challenge: ['challenge set encoding-salt binary! set salt binary! (
			encoding-salt: either request/encoded [request/password] [
				encode-pass request/password encoding-salt
			]
			insert tail prof-data/requests make object! [
				type: 'answer
				username: request/username
				key: encoding-salt
				callback-f: get in request 'callback-f
			]
			send-frame/callback channel make frame-object [
				msgtype: 'MSG
				more: '.
				payload: to binary! mold/only append copy [answer]
					answer-challenge request/username encoding-salt salt
			] bind [closing?: closing? + 1] in channel 'self
		)]
	
		prof-data: channel/prof-data
		debug ["frame:" mold frame]
		
		; expecting a short and complete reply
		; sanity check to make sure
		; the message is short included
		either prof-data/rpy-to-complete [
			; defragment
			prof-data/rpy-to-complete/more: frame/more
			insert tail prof-data/rpy-to-complete/payload frame/payload
		] [
			prof-data/rpy-to-complete: frame
			if frame/msgtype = 'ANS [
				poorly-formed "ANS frames not expected in channel 0"
			]
		]
		frame: prof-data/rpy-to-complete
		if MAXMSGLEN < length? frame/payload [
			poorly-formed "Short reply expected"
		]
		if frame/more = '* [exit] ; waiting for complete rpy
		prof-data/rpy-to-complete: none

		request: first head prof-data/requests
		prof-data/requests: remove head prof-data/requests
		if any [
			error? try [frame/payload: load/all to string! frame/payload]
			not either 'RPY = frame/msgtype [
				parse frame/payload [ok | challenge]
			] error
		] [
			debug mold frame
			poorly-formed "Unexpected reply in management channel"
		]
	]
		
	close-channel?: func [
		{find out whether a channel can be closed}
		channel
		/ask
		/local err-frame
	] [
		unless empty? head channel/out-msg-queue [
			return make frame-object [
				msgtype: 'ERR
				more: '.
				payload: to binary! "MSG queue not empty"
			]
		]
		if channel/out-msg-fragment [
			return make frame-object [
				msgtype: 'ERR
				more: '.
				payload: to binary! "Finishing MSG send"
			]
		]
		if all [
			channel/outgoing
			'MSG = channel/outgoing/msgtype
		] [
			return make frame-object [
				msgtype: 'ERR
				more: '.
				payload: to binary! "Just sending a MSG"
			]
		]
		if all [
			object? set/any 'err-frame either ask [
				channel/close/ask channel
			] [
				channel/close channel
			]
			in err-frame 'msgtype
			err-frame/msgtype = 'ERR
		] [
			return make frame-object [
				msgtype: 'ERR
				more: '.
				payload: to binary! "Channel profile refused close"
			]
		]
	]
	
	close-channel-ll: func [
		{close a channel, low level, write handler for channel0}
		channel0
		size
		/local channel-to-close
	] [
		channel-to-close: channel0/prof-data/channel-to-close
		either all [
			empty? head channel-to-close/in-unreplied
			empty? head channel-to-close/out-unreplied
			not get in channel-to-close 'write
			not channel-to-close/in-no
		] [
			; channel can be destroyed now
			destroy-channel channel-to-close
			send-frame channel0 make frame-object [
				msgtype: 'RPY
				more: '.
				payload: to binary! mold/only [ok]
			]
			channel0/write channel0 size
		] [
			; not yet
			0
		]
	]

	close-session-ll: func [
		{close session, low level, write handler for channel0}
		channel0
		size
		/local channel-to-close channels
	] [
		; close all channels before closing channel0
		while [true] [
			if empty? channels: next head channel0/port/user-data/channels/values [
				; all channels closed except for channel 0
				send-frame channel0 make frame-object [
					msgtype: 'RPY
					more: '.
					payload: to binary! mold/only [ok]
				]
				return channel0/write channel0 size				
			]
			channel-to-close: first channels
			either all [
				empty? head channel-to-close/in-unreplied
				empty? head channel-to-close/out-unreplied
				not get in channel-to-close 'write
				not channel-to-close/in-no
			] [
				; channel can be destroyed now
				destroy-channel channel-to-close
			] [
				; channel cannot be closed yet
				return 0
			]
		]
	]

	set 'open-channel func [
		[catch]
		port
		profile
		version
		callback
		/local session channel0 channel-no profile-o
	] [
		unless in profile-registry profile [throw make error! "nonexistent profile"]
		if profile = 'channel-management [
			throw make error! "channel-management only at channel 0"
		]
		profile-o: profile-registry/:profile
		unless profile-o/version = version [throw make error! "incorrect version"]
		session: port/user-data
		channel-no: session/free-chno
		until [
			session/free-chno: part-add session/free-chno 2
			not aa/get session/channels session/free-chno
		]
		channel0: aa/get session/channels 0
		if 0 < channel0/closing? [
			; refuse the request
			callback none
			exit
		]
		debug "Open channel"
		insert tail channel0/prof-data/requests make object! [
			type: 'start
			chno: channel-no
			profile-name: profile
			version-no: version
			callback-f: :callback
		]
		send-frame channel0 make frame-object [
			msgtype: 'MSG
			more: '.
			payload: to binary! mold/only reduce [
				'start channel-no 'with-profile profile version
			]
		]
	]
	
	set 'close-channel func [
		{Close a channel/session}
		[catch]
		channel-to-close
		callback
		/local channel0 channels err-frame
	] [
		channels: channel-to-close/port/user-data/channels
		channel0: aa/get channels 0
		channels: channels/values
		; ask the profile(s)
		either 0 = channel-to-close/chno [
			if 0 < channel0/closing? [
				; refuse the request
				callback none
				exit
			]
			; check session close locally
			foreach channel-arg channels [
				if all [
					object? set/any 'err-frame close-channel?/ask channel-arg
					in err-frame 'msgtype
					'ERR = err-frame/msgtype
				] [
					callback none
					exit
				]
			]
			; session close OK locally, tell every channel
			foreach channel-arg channels [
				if all [
					object? set/any 'err-frame channel-arg/close channel-arg
					in err-frame 'msgtype
					'ERR = err-frame/msgtype
				] [
					throw make error! rejoin ["Channel " channel-arg/chno " refused close"]
				]
			]
		] [
			; local channel close check
			if all [
				object? set/any 'err-frame close-channel? channel-to-close
				in err-frame 'msgtype
				'ERR = err-frame/msgtype
			] [
				callback none
				exit
			]
		]
		insert tail channel0/prof-data/requests make object! [
			type: 'stop
			channel: channel-to-close
			callback-f: :callback
		]
		send-frame/callback channel0 make frame-object [
			msgtype: 'MSG
			more: '.
			payload: to binary! mold/only reduce ['stop channel-to-close/chno]
		] either 0 = channel-to-close/chno [
			compose [
				foreach channel-arg (reduce [channels]) [
					channel-arg/closing?: channel-arg/closing? + 1
				]
			]
		] [
			bind [closing?: closing? + 1] in channel-to-close 'self
		]
	]

	set 'login func [
		[catch]
		channel0 [object!]
		user [string!]
		pass [string! binary!]
		callback [function!]
		/with {pass is encoded}
	] [
		unless (string? pass) xor with [throw make error! "wrong password type"]
		debug "Login"
		if 0 < channel0/closing? [
			; refuse the request
			callback none
			exit
		]
		insert tail channel0/prof-data/requests make object! [
			type: 'login
			username: user
			password: pass
			encoded: with
			callback-f: :callback
		]
		send-frame channel0 make frame-object [
			msgtype: 'MSG
			more: '.
			payload: to binary! mold/only [login]
		]
	]

]
