Rebol [
	Title: "BEER Frame Parser"
	Date: 4-Nov-2005/11:45:44+1:00
	License: {
Copyright (C) 2005 Why Wire, Inc.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

Other commercial licenses to this program are available from Why Wire, Inc.
}
]

#include-check %catch.r

; the rules below are "size-safe" - they accept only message frames
; having header + trailer maximally of MAXHT size
; with payload having at most the MAXSIZE size
; and SEQ frames having maximally MAXSEQ size

	parse-frames: func [
	    buffer [string!]
    	frame-handler [any-function!]
	    /local
    	    ; rules
			frame-rule body-rule common-rule check valid invalid
			msgtype-rule sp-rule chno-rule msgno-rule more-rule seqno-rule
			ansno-rule size-rule payload-rule digit number
			; state variables
			frame processed n
			; other
			ncvt
			; frame variables
			msgtype chno msgno more seqno size ansno payload
	] [
		ncvt: func [
			{String to integer, check against limit}
			limit /local i
		] [
			if any [error? try [i: to integer! n] i > limit] [check: invalid]
			i
		]
	
		check: valid: [
			(frame-handler msgtype chno msgno more seqno ansno payload processed)
			processed:
		]
	
		invalid: [end skip]
	
		msgtype-rule: [
			"SEQ" (body-rule: [seqno-rule "^M^/"]) | ["MSG" | "RPY" | "ERR"] (
				body-rule: [common-rule payload-rule]
			) | "ANS" (
				body-rule: [common-rule sp-rule ansno-rule payload-rule]
			) | "NUL" (
				body-rule: [
					chno-rule sp-rule msgno-rule sp-rule #"." (more: '.)
					sp-rule seqno-rule sp-rule #"0" (size: 0) payload-rule
				]
			)
		]
		common-rule: [
			chno-rule sp-rule msgno-rule sp-rule more-rule sp-rule seqno-rule
			sp-rule size-rule
		]	
		chno-rule:   [number (chno: ncvt MAXSEQNO)]
		msgno-rule:  [number (msgno: ncvt MAXSEQNO)]
		seqno-rule:  [number (seqno: ncvt MAXSEQNO)]
		ansno-rule:  [number (ansno: ncvt MAXSEQNO)]
		size-rule:   [copy n 1 4 digit (size: ncvt MAXSIZE)]
		; #"*" == more frames, #"." == final frame
		more-rule: [copy n [#"*" | #"."] (more: to word! n)]
		; bytestream starting with CR LF having a trailer
		payload-rule: [
			"^M^/"
			copy payload size skip (unless payload [payload: #{}])
			"END^M^/"
		]
		number: [copy n 1 10 digit]
		digit: charset [#"0" - #"9"]
		sp-rule: #"^(20)" ;the space character
		
		frame-rule: [
			copy n msgtype-rule (msgtype: to word! n)
			sp-rule
			body-rule
			check
		]

		catch' [
			poorly-formed: func [value] [
				log-error value
				throw' false
			]

			parse/all buffer [processed: any frame-rule]
			;unless empty? processed [debug ["processed" length? processed]]
			if  MAXFRAME < length? processed [
				poorly-formed ["Unknown frame type" mold processed]
			]
			remove/part buffer processed
			true ; OK
		]
	]

comment [
	; tests
	parse-frames {NUL 0 1 . 4 0^M^/END^M^/} func [
		msgtype chno msgno more seqno ansno payload
	] [print [msgtype chno msgno more seqno ansno payload]]
	parse-frames {MSG 0 0 . 0 3^M^/ENDEND^M^/NUL 0 1 . 4 0^M^/END^M^/} func [
		msgtype chno msgno more seqno ansno payload
	] [print [msgtype chno msgno more seqno ansno payload]]
	parse-frames {MSG 0 0 . 0 3^M^/ENDEND^M^/} func [
		msgtype chno msgno more seqno ansno payload
	] [print [msgtype chno msgno more seqno ansno payload]]
	parse-frames {SEQ 0^M^/} func [
		msgtype chno msgno more seqno ansno payload
	] [print [msgtype chno msgno more seqno ansno payload]]
	parse-frames {ANS 0 0 . 0 3 0^M^/ENDEND^M^/} func [
		msgtype chno msgno more seqno ansno payload
	] [print [msgtype chno msgno more seqno ansno payload]]
	parse-frames {ANS 0 0 * 0 3 0^M^/ENDEND^M^/} func [
		msgtype chno msgno more seqno ansno payload
	] [print [msgtype chno msgno more seqno ansno payload]]
	parse-frames {RPY 0 0 . 0 8^M^/greetingEND^M^/} func [
		msgtype chno msgno more seqno ansno payload
	] [print [msgtype chno msgno more seqno ansno payload]]
	parse-frames {NUL 0 1 . 4 0^M^/END^M} func [
		msgtype chno msgno more seqno ansno payload
	] [print [msgtype chno msgno more seqno ansno payload]]
]
