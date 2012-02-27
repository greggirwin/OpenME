Rebol [
	Title: "BEER Echo Profile"
	Date: 3-Mar-2006/16:39:51+1:00
	Purpose: {a test profile}
	License: {
Copyright (C) 2005 Why Wire, Inc.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

Other commercial licenses to this program are available from Why Wire, Inc.
}
]

; echo profile
; the Register function registers a newly created profile
register context [
	; define a name of the profile - a word
	profile: 'echo
	; define a version of the profile
	version: 1.0.0

	; this is an example profile showing some concepts of how a filetransfer
	; profile can be defined
		
	; handler used to initialize a newly created channel
	init: func [
		channel [object!]
		/local info
	] [
		debug ["This is echo profile. Initializing" channel/chno]

		; private channel data managed by the profile should be defined as
		; the channel/prof-data object
		; (do not store private data in the profile!)
		channel/prof-data: make object! [
			; state data for file transfer
			; (a peer can both receive and send files in this implementation)
		
			; receiver state
			total-sizes: none ; total sizes of the files to receive
			received-sizes: none ; really received
			
			; transmitter state
			
			; the commented line below can be used if we know in advance the files
			; we are going to transfer:
			; files: [%testfiles/ksample.bsd]
			
			; another way how to tell which files are being transferred
			; you can use a more complicated algorithm, of course:
			
			; (every file with complete path, directories excluded, this is not
			; the only possible option)
			files: read testfiles
			foreach file files [insert file testfiles]
			remove-each file files [
				info: info? file
				info/type = 'directory
			]
			
			ports: none ; ports to transmitted files
		]
		; defining the initial Read-rpy handler used to read a peer reply
		channel/read-rpy: func [channel frame /local prof-data ansno total] [
			; we will access the profile data
			prof-data: channel/prof-data
			
			; Read-rpy can (in general) obtain the following messages types:
			; RPY, ERR, ANS, NUL
			
			; here we show how to handle two message types: ANS and NUL,
			; RPY or ERR handling would need additional code
			
			; the reason why we use ANS messages to transfer the files is,
			; that we can transfer many files at once this way as shown below
			
			; the NUL message is used to finish the transfer
			
			either frame/msgtype <> 'NUL [
				ansno: frame/ansno
				;debug ["received" ansno channel/port/user-data/in-seqno length? frame/payload]
				either ansno = 0 [
					; the frame with ansno = 0 is supposed to contain
					; the total sizes of the transferred files,
					; while the other ANS frames are used to transfer
					; the contents of the files,
					; i.e. the count of ANS files is equal to
					; the number of the transferred files plus one
					either prof-data/total-sizes [
						; defragment the frame
						insert tail prof-data/total-sizes frame/payload
					] [
						; this is the first part of the frame, remember it
						prof-data/total-sizes: frame/payload
					]
					if frame/more = '. [
						; frame complete
						
						prof-data/total-sizes: load/all to string! prof-data/total-sizes
						debug ["total sizes" prof-data/total-sizes]
						
						; we may start to receive the files
						prof-data/received-sizes: head insert/dup copy [] 0
							length? prof-data/total-sizes
						start-time: now/precise
					]
				] [
					; receiving a file, take the appropriate action
					poke prof-data/received-sizes ansno prof-data/received-sizes/:ansno + length? frame/payload
					; the code below could immediately print the information, if needed
					;print [
					;	"file" ansno
					;	prof-data/received-sizes/:ansno "received from"
					;	prof-data/total-sizes/:ansno "total"
					;]
					if frame/more = '. [
						print ["file" frame/ansno "completely received"]
					]
				]
			] [
				; NUL received, reception done
				stop-time: now/precise
				; computing the total received size
				total: 0
				foreach size prof-data/total-sizes [total: total + size]
				debug [
					"received sizes" prof-data/received-sizes newline
					"stop-time:" stop-time: to decimal! difference stop-time start-time newline
					"transmission speed:"
					transmission-speed: either zero? stop-time [
						"undetermined, increase file sizes, please"
					] [
						transmission-speed: round total * 8 / stop-time * 1e-3
					]
					"[kbps]"
				]
				print "All files received"
				prof-data/total-sizes: none
			]
		]
		channel/read-msg: func [
			; this can "properly" send a couple of files
			channel frame /local prof-data port files sizes file
		] [
			; primitive example using send-frame, not very useful
			; new-frame: make frame-object [
			;	msgtype: 'RPY
			;	more: '.
			;	payload: read/binary %"/c/BEER/testfiles/Keyhole2LT-2.2.990.exe"
			; ]
			; frame/payload: to string! frame/payload
			; print "MSG:"
			; probe frame
			; send-frame channel new-frame
			
			; single file transfer variant using RPY
			;prof-data: channel/prof-data
			;prof-data/port: open/binary/direct %"/c/BEER/testfiles/Keyhole2LT-2.2.990.exe"
			;print ["Sending" %"/c/BEER/testfiles/Keyhole2LT-2.2.990.exe"]
			;register-sending channel func [channel size /local port] [
			;	port: channel/prof-data/port
			;	make frame-object [
			;		msgtype: 'RPY
			;		payload: copy/part port size
			;		more: either payload ['*] [payload: #{} close port '.]
			;	]
			;]
            
            ; this is a more sophisticated method using ANS and NUL messages
			frame/payload: to string! frame/payload
            print ["frame:" mold frame]
            
            ; the commented code below was a test variant
            comment [
            ; check if the frame says a new channel should be open
            if parse frame/payload ["open new channel"] [
                ; open a new channel and send something after the channel exists
                print "asked to create a channel"
				open-channel channel/port 'echo 1.0.0 func [channel] [
	            	new-channel: channel
					print "sending thread reply"
					send-frame channel make frame-object [
						msgtype: 'MSG
						payload: to binary! mold/only compose [ok ("id") ("result")]
						more: '.
					]
				]
				exit
			]
			]
			
			; multiple file transfer using ANS
			prof-data: channel/prof-data

			print "starting transfer"

			print ["Sending" prof-data/files]
			
			; compute file sizes
			sizes: make block! length? prof-data/files
			foreach file prof-data/files [
				file: info? file
				insert tail sizes file/size
			]
			; open file ports
			prof-data/ports: make block! length? prof-data/files
			repeat i length? prof-data/files [
				file: prof-data/files/:i
				insert/only tail prof-data/ports reduce [open/binary/direct file i sizes/:i]
			]
			; send ANSNO 0
			; the /callback refinement makes sure that
			; the write handler will be replaced *after* the ASNO 0
			; is sent (see %API.html, the Synchronization section)
			send-frame/callback channel make frame-object [
				msgtype: 'ANS
				ansno: 0
				more: '.
				payload: to binary! mold/only sizes
			] compose [
				; this will be done *after* ANSNO 0 is sent,
				; it replaces the write handler
				; it is necessary to enclose the channel variable in parens
				; due to Rebol function quirk (async code!)
				register-sending (channel) :send-files
			]
		]
		send-files: func [channel size /local prof-data port frame ansnum file-size data] [
			; this transmits the contents of the files
			; in a round-robin fashion (i.e. in a "parallel" way)
			prof-data: channel/prof-data
			; pick a port
			set [port ansnum file-size] data: first prof-data/ports
			frame: make frame-object [
				msgtype: 'ANS
				ansno: ansnum
				; this would be "real"
				; payload: copy/part port size
				; this is just a simulation eliminating file input
				(size: min size file-size)
				payload: head insert/dup copy #{} #"0" size
				(
					file-size: file-size - size
					data/3: file-size
				)
				; robin
				more: either file-size > 0 [ ;payload [
					prof-data/ports: next prof-data/ports
					'*
				] [
					;payload: #{}
					close port
					remove prof-data/ports
					'.
				]
			]
			; round
			if tail? prof-data/ports [prof-data/ports: head prof-data/ports]
			if empty? prof-data/ports [
				; write NUL frame after all files have been transmitted
				send-frame channel make frame-object [
					msgtype: 'NUL
					more: '.
					payload: #{}
				]
			]
			frame
		]
		; close handler
		channel/close: func [channel /ask] [
			; this is the smallest possible implementation,
			; it just accepts close (i.e. does not return any error)
			; (if we wanted to refuse the close request,
			; it would be best to return an ERR frame
			; specifying the problem to peer instead)
			none
		]
	]
]
