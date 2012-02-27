Rebol [
	Title: "BEER Frame Read"
	Date: 4-Nov-2005/11:45:44+1:00
	License: {
Copyright (C) 2005 Why Wire, Inc.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

Other commercial licenses to this program are available from Why Wire, Inc.
}
]

	read-frame: func [
		port
		msgtype chno msgno more seqno ansno payload processed
		/local session channel in-no msg-no frame make-frame
	] [
		make-frame: [
			frame: make frame-object []
			frame/msgtype: msgtype
			frame/more: more
			frame/ansno: ansno
			frame/payload: payload
			frame
		]
		session: port/user-data
		either msgtype = 'SEQ [
			if MAXSEQFRAME >= part-sub seqno session/out-win [
				poorly-formed "SEQ frame trying to shrink the window"
			]
			; update output window
			session/out-win: seqno
			; update input seqno
			session/in-seqno: part-add session/in-seqno MAXSEQFRAME
			; we may be able to send something
			send-seq port length? processed ; enforce SEQ priority
			round-robin port ; "normal transmission"
		] [
			; get channel
			channel: aa/get/default session/channels chno [
				debug [msgtype chno msgno more seqno ansno payload]
				poorly-formed ["Channel" chno "non existent"]
			]
			; check input seqno
			if seqno <> session/in-seqno [
				poorly-formed [
					"Sync lost. Expected seqno" session/in-seqno
					"received" seqno
				]
			]
			; update in-seqno
			session/in-seqno: part-add session/in-seqno MAXHT + length? payload
			; check fragment
			if in-no: channel/in-no [
				if in-no <> msgno [
					poorly-formed ["Expected msgno" in-no "received" msgno]
				]
				if channel/in-type <> msgtype [
					unless all [
						msgtype = 'NUL
						channel/in-type = 'ANS
					] [
						poorly-formed [
							"Expected msgtype" channel/in-type
							"received" msgtype
						]
					]
				]
			]
			if channel/encrypted? [payload: decloak/with payload session/key]
			if msgtype = 'MSG [
				if 0 < channel/closing? [poorly-formed "Channel closing"]
				either in-no [
					; defragment MSG
					frame: last channel/in-msg-queue
					frame/more: more
					insert tail frame/payload payload
					channel/in-msg-stored: channel/in-msg-stored +
						length? payload
				] [
					; new MSG, check msgno
					if channel/in-msgno <> msgno [
						poorly-formed [
							"Expected MSG no" channel/in-msgno "received" msgno
						]
					]
					; adjust in-msgno
					channel/in-msgno: part-add channel/in-msgno 1
					; enlist the MSG as unreplied
					insert tail channel/in-unreplied msgno
					; store the MSG
					insert tail channel/in-msg-queue do make-frame
					channel/in-msg-stored: channel/in-msg-stored + MAXHT +
						length? payload
				]
				; check the storage
				if channel/in-msg-stored > MAXMSGLEN [
					poorly-formed "MSG storage overflow"
				]
			]
			either all [more = '. msgtype <> 'ANS] [
				; adjust for complete message
				channel/in-no: none
				channel/in-type: none
			] [
				; adjust for incomplete message
				channel/in-no: msgno
				channel/in-type: msgtype
			]
			; check new reply
			if all [not in-no msgtype <> 'MSG] [
				if empty? head channel/out-unreplied [
					poorly-formed ["Unexpected reply" msgno "received"]
				]
				if msgno <> msg-no: first head channel/out-unreplied [
					poorly-formed ["Expected reply" ex-rpy "received" msgno]
				]
				; remember the message was replied
				channel/out-unreplied: remove head channel/out-unreplied
				channel/out-msg-stored: channel/out-msg-stored - first head
					channel/out-sizes
				channel/out-sizes: remove head channel/out-sizes
			]
			; let the profile handle the input
			if msgtype <> 'MSG [channel/read-rpy channel do make-frame]
			send-reply? channel
		]
	]
