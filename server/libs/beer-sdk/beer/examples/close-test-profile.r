Rebol [
	Title: "BEER close-test Profile"
	Date: 21-Apr-2006/16:24:26+2:00
	Purpose: {a test profile}
	License: {
Copyright (C) 2005 Why Wire, Inc.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

Other commercial licenses to this program are available from Why Wire, Inc.
}
]

; close-test profile
register context [
	profile: 'close-test
	version: 1.0.0

	; initial handler
	init: func [
		channel [object!]
		/local info
	] [
		debug ["This is close-test profile. Initializing" channel/chno]
		channel/prof-data: make object! [
			oc: func [arg] [
				print ["channel closed"]
			]
			rpy-to-complete: none
		]
		channel/read-rpy: func [channel frame /local prof-data ansno total] [
			prof-data: channel/prof-data
			debug ["close test, reply frame:" mold frame]
			
			either prof-data/rpy-to-complete [
				; defragment
				prof-data/rpy-to-complete/more: frame/more
				insert tail prof-data/rpy-to-complete/payload frame/payload
			] [
				prof-data/rpy-to-complete: frame
				if frame/msgtype <> 'RPY [poorly-formed "close test: RPY reply expected"]
			]
			frame: prof-data/rpy-to-complete
			
			if MAXMSGLEN < length? frame/payload [
				poorly-formed "close test: Short reply expected"
			]
			if frame/more = '* [exit] ; waiting for complete rpy
			prof-data/rpy-to-complete: none
			
			; RPY arrived, processing
			unless all [
				not error? try [frame/payload: load/all frame/payload]
				parse frame/payload [
					'ask-ok
					| 'close-me (close-channel channel get in prof-data 'oc)
				]
			] [
				poorly-formed "close test: unexpected reply"
			]
		]
		channel/read-msg: func [
			channel frame /local prof-data port files sizes file
		] [
            frame/payload: to string! frame/payload
            print ["close test, frame:" mold frame]
            
			prof-data: channel/prof-data

			if any [
				error? try [
					frame/payload: load/all to string! frame/payload
				]
				not parse frame/payload [
					'ask-me (
						print "close test: replying ASK-ME"						
						send-frame channel make frame-object [
							msgtype: 'RPY
							more: '.
							payload: to binary! mold/only [ask-ok]
						]
						send-frame channel make frame-object [
							msgtype: 'MSG
							more: '.
							payload: to binary! mold/only [asking]
						]
					)
					| 'asking (						
						send-frame channel make frame-object [
							msgtype: 'RPY
							more: '.
							payload: to binary! mold/only [close-me]
						]
					)
				]
			] [
				send-frame channel make frame-object [
					msgtype: 'ERR
					more: '.
					payload: to binary! "Unexpected message"
				]
			]
		]
		; close handler
		channel/close: func [channel /ask] [
			either ask [print "channel close asked"] [print "channel close processing"]
		]
	]
]
