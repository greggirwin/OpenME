Rebol [
	Title: "BEER Protocol Data"
	Date: 18-Jan-2006/15:06:14+1:00
	License: {
Copyright (C) 2005 Why Wire, Inc.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

Other commercial licenses to this program are available from Why Wire, Inc.
}
]

EXPPROFILES: 50 ; expected number of profiles

; number of currently opened sessions
sessions: 0

; maximum currently opened sessions
MAXSESSIONS: 5

; every seqno will be a number such that 0 <= seqno < MAXSEQNO
MAXSEQNO:  to integer! #{7ffffffe} ; maximal Rebol representable even integer
 
part-add: func [
	{limited range (seqno) addition}
	number1
	number2
	/local sum
] [
	either 0 > sum: number1 - MAXSEQNO + number2 [sum + MAXSEQNO] [sum]
]

MAX-DIF: MAXSEQNO / 2 ; an upper limit of difference of two seqno numbers
MIN-DIF: MAXSEQNO / -2 ; like above, the lower limit

; the result of subtraction of two seqno's will be an integer difference,
; such that MIN-DIF < difference <= MAX-DIF
part-sub: func [
	{limited range (seqno) subtraction}
	number1
	number2
	/local dif
] [
	either MIN-DIF >= dif: number1 - number2 [dif + MAXSEQNO] [
		either MAX-DIF < dif [dif - MAXSEQNO] [dif]
	]
]

; the maximum number of bytes a peer can send without receiving a SEQ
; the first value below is the minimum as well as the initial value specified
; by rfc3081, the second value is used after the first SEQ frame comes
INITBUFLEN: 4'096
MAXBUFLEN: 8'192

; maximum current channels per session
; the value below is the minimum required by rfc3080
MAXCURCHAN: 257

; maximum size of TCP and IP headers
MAXTCPIP: 120

; maximum size of frame's header plus trailer
; this limit is "enforced" by the parse-frames function
MAXHT: 61

; maximum size of a frame
; according to rfc3081 the size of a frame should be
; maximally 2 / 3 of the TCP's negotiated maximum segment size
MAXFRAME: to integer! 2 / 3 * 1'460

; maximum payload size
MAXSIZE: MAXFRAME - MAXHT

MAXSEQFRAME: 16 ; maximum length of a SEQ frame

; limit for sending a SEQ message, according to rfc3081 this value should be
; a half of MAXBUFLEN
WIN-SHIFT: to integer! MAXBUFLEN / 2

; MSG storage limit
MAXMSGLEN: MAXBUFLEN

; expected values
EXPCURCHAN: 10
EXPSENDING: 5
EXPUNREPLIED: 20

channel-data: make object! [
	
	port: none
	
	chno: none ; channel number
	profile: none ; the profile object
	prof-data: none ; profile data
	
	; state
	encrypted?: false
	closing?: 0 ; the number of closing requests
	
	; transmission state - output
	out-msgno: 0 ; number of the next outgoing MSG
	out-msg-fragment: false ; whether another fragment of a MSG is expected
	out-unreplied: none ; numbers of sent and unreplied MSGs
	out-sizes: none ; sizes of sent and unreplied MSGs
	out-msg-stored: 0 ; how many bytes are stored in peer's queue
	reply?: false ; "fair reply policy" switch
	
	; transmission state - input
	in-msgno: 0 ; number of expected incoming MSG
	in-no: none ; number of expected incoming fragment
	in-type: none ; type of expected incoming fragment
	in-unreplied: none ; numbers of received and unreplied messages
	in-msg-stored: 0 ; how many bytes are "stored" in the queue
	
	; transmitted data
	in-msg-queue: none ; incoming MSGs
	out-msg-queue: none ; outgoing MSGs
	outgoing: none ; outgoing message
	callback: none ; outgoing message callback
	
	; dynamic handlers
	write: none ; write frame handler
	read-rpy: none ; reply handler
	read-msg: none ; MSG handler
	close: none ; close handler
]

session-data: context [
	session-type: 'BEER
	role: none ; the role of the peer
	channels: none ; aa/make MAXCURCHAN ; keys are channel numbers
	free-chno: none ; a "free" channel number
	buffer: none ; the session input buffer
	username: "anonymous"
	key: none
	rights: none ; peer rights
	; flow control variables
	send-queue: none ; make list! EXPSENDING ; round-robin channel queue
	out-seqno: 0 ; sequence number for outgoing frames
	out-win: INITBUFLEN ; window for outgoing frames
	in-seqno: 0 ; sequence number for incoming frames
	in-win: INITBUFLEN ; window for incoming frames
	sending?: false ; a variable saying, whether round-robin is running
	on-open: none ; open callback
	on-close: none ; close callback
	open?: false
	remote-ip: none
	remote-port: none
]

; message frame object
frame-object: make object! [msgtype: more: ansno: payload: none]
