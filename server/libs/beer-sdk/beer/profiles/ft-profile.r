Rebol [
	Title: "filetransfer profile"
	License: {
Copyright (C) 2005 Why Wire, Inc.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

Other commercial licenses to this program are available from Why Wire, Inc.
}
]
;query/clear system/words

register context [
	profile: 'filetransfer
	version: 1.0.0

	st: none ;temoprary value for testing of transfer speed

	post-handler: none
	get-handler: none
	destination-dir: none
			
	; initial handler
	init: func [
		channel [object!]
	] [

;		print "ftINIT"
		
		channel/prof-data: make object! [
			; receiver state
			files-to-receive: aa/make 256
			file-ids: make block! []
			ans-0-rcv: copy ""
			
			; transmitter state
			files-to-transmit: make block! []
			ans-0-tr: copy #{}
			post-callbacks: make block! []
			post-cmds: make block! []

			ans-0-post: make block! []
			ans-0-postid: make block! []
			ch: channel
			id: cid: ansno: dr: file-port: ln: file: none

			;bind parsing rule block			
			rule: bind/copy command-rule 'self
		]

		channel/read-msg: func [
			channel frame /local prof-data port files sizes file rule
		] [
;			print "ftREADMSG"
;			probe frame

			prof-data: channel/prof-data
			rule: prof-data/rule
			parse/all frame/payload [
				some [
					rule
				]
			]
			
			if not empty? prof-data/ans-0-tr [
				; multiple file transfer using ANS
;				print "SENDING ANS0"
				send-frame/callback channel make frame-object [
					msgtype: 'ANS
					ansno: 0
					more: '.
					payload: prof-data/ans-0-tr
				] compose [
					; this will be done *after* ANSNO 0 is sent,
					; it replaces the write handler
					clear (prof-data/ans-0-tr)
					register-sending (channel) :send-files
				]
			]
			
			if not empty? prof-data/ans-0-post [
				send-frame/callback channel make frame-object [
					msgtype: 'NUL
					more: '.
					payload: #{}
				] compose/only [
					get-file/cid (channel) (copy prof-data/ans-0-post) post-handler (copy prof-data/ans-0-postid)
				]				
				clear prof-data/ans-0-post
				clear prof-data/ans-0-postid
			]
		]
		
		channel/read-rpy: func [channel frame /local prof-data ansno file rule
		] [
;			print "ftREADRPY"
;			probe frame
			prof-data: channel/prof-data
			ansno: frame/ansno
;			debug ["received" ansno channel/port/user-data/in-seqno length? frame/payload]
			either ansno = 0 [
;				print "RECEIVING ANS 0"
;				probe frame
				insert tail prof-data/ans-0-rcv frame/payload
				if frame/more = '. [
					rule: prof-data/rule
					parse/all prof-data/ans-0-rcv [
						some [
							rule	
						]
					]
					clear prof-data/ans-0-rcv
				]
			] [
				if frame/msgtype <> 'NUL [
;					print "writing chunk"
;					probe frame
					file: aa/get channel/prof-data/files-to-receive select prof-data/file-ids frame/ansno
					file/6: length? frame/payload
					write-io file/2 frame/payload file/6 
					file/4 channel 'read file
	
					if frame/more = '. [
						close file/2
;						print ["file" file/1 "received in" now/time/precise - st]
						file/4 channel 'write file
						aa/remove channel/prof-data/files-to-receive file/1
						remove/part find prof-data/file-ids frame/ansno 2
					]
				]
			]
		]

		send-files: func [
			channel
			size
			/local
				prof-data
				port
				frame
				ansnum
				file
		] [
			; this transmits the contents of the files
			prof-data: channel/prof-data
			file: first prof-data/files-to-transmit
			; pick a port
			port: file/2
			ansnum: file/1
			frame: make frame-object [
				msgtype: 'ANS
				ansno: ansnum
				payload: copy/part port size
				; robin
				more: either all [payload not empty? payload][
					file/6: length? payload
					file/4 channel 'read file
					get-handler channel 'read file
					prof-data/files-to-transmit: next prof-data/files-to-transmit
					'*
				] [
					file/6: 0
					file/4 channel 'write file
					get-handler channel 'write file
					payload: #{}
					if port? port [close port]
					remove prof-data/files-to-transmit
					'.
				]
			]
			if binary? port [
			 	clear file/2
			]
			; round
			if tail? prof-data/files-to-transmit [prof-data/files-to-transmit: head prof-data/files-to-transmit]
			if empty? prof-data/files-to-transmit [
				; write NUL frame after all files have been transmitted
				send-frame channel make frame-object [
					msgtype: 'NUL
					more: '.
					payload: #{}
				]
			]
			frame
		]

		channel/close: func [
			{to let the profile know, that the channel is being closed}
			channel
		][
;			print "ftCLOSE"
		]
	]

	make-id: does [
		enbase/base checksum/secure form random/secure to-integer #{7fffffff} 16
	]

	set 'get-file func [
		{issues GET command on appropriate filetransfer channel}
		channel [object!]
		blk [block!]
		callback [block! none!]
		/dst-dir
			dst [file!]
		/cid
			callbacks [block!]
		/local
			cmd
			id
			cmd-str
			prof-data
			callback-id
	][
		prof-data: channel/prof-data
		cmd: copy #{}
		if all [dst not exists? dst][
			make-dir dst
		]
		foreach f blk [
			until [
				not exists? join any [dst destination-dir] id: make-id
			]
			if cid [
				callback-id: pick callbacks index? find blk f
			]
			cmd-str: rejoin ["get" f "*" id " cid" callback-id " "]
			if (length? cmd) + (length? cmd-str) > (MAXMSGLEN - MAXHT) [
				send-frame channel make frame-object [
					msgtype: 'MSG
					more: '.
					payload: copy cmd
				]
				clear cmd
			]
			
			insert tail cmd cmd-str

			aa/set prof-data/files-to-receive id reduce [
				id
				open/new/binary/direct join any [dst destination-dir] id
				f
				all [callback func [channel [object!] action [word!] data [block!]] callback]
				0
				0
				any [dst destination-dir]
				0
			]
		]
		st: now/time/precise
		if not empty? cmd [
			send-frame channel make frame-object [
				msgtype: 'MSG
				more: '.
				payload: cmd
			]
		]
	]

	set 'post-file func [
		channel [object!]
		blk [block!]
		callback [block! none!]
		/local
		 cmd
		cid
		cmd-str
		prof-data
	][
		prof-data: channel/prof-data
		cmd: copy #{}
		foreach f blk [
			cid: make-id
			insert tail prof-data/post-callbacks reduce [
				cid
				either callback [
					func [channel [object!] action [word!] data [block!]] callback
				][
					none
				]
			]
			cmd-str: rejoin ["post" f "*" cid " "]
			if (length? cmd) + (length? cmd-str) > (MAXMSGLEN - MAXHT) [
				send-frame channel make frame-object [
					msgtype: 'MSG
					more: '.
					payload: copy cmd
				]
				clear cmd
			]
			insert tail cmd cmd-str 
		]
		send-frame channel make frame-object [
			msgtype: 'MSG
			more: '.
			payload: cmd
		]
	]

	command-rule: [
		"get" copy file to "*" skip copy id to " " skip "cid" copy cid to " " skip (
;			print ["Start sending" file]
			ansno: length? files-to-transmit
			until [
				not find file-ids ansno: ansno + 1
			]
			either dir? file: to-file file [
				insert/only files-to-transmit file: reduce [
					ansno dr: to-binary mold/only read file file select post-callbacks cid 0 0
				]
				insert tail ans-0-tr rejoin [to-binary "init" id " " file/5: length? dr " " file/1 " "]
			][
				;ansno, port, filename, callback, total filesize, chunk size
				insert/only files-to-transmit file: reduce [
					ansno file-port: open/binary/direct/read file file select post-callbacks cid 0 0
				]
				insert tail ans-0-tr rejoin [to-binary "init" id " " file/5: file-port/size " " file/1 " "]
			]
			remove/part find post-callbacks cid 2
			file/4 ch 'init file
			get-handler ch 'init file
		)
		| "post" copy file to "*" skip copy id to " " skip (
;			print "POST"
			insert tail ans-0-post to-file file
			insert tail ans-0-postid to-file id
		)
		| "init" copy file to " " skip copy ln to " " skip copy ansno to " " skip (
;			print ["INIT" file-ids]
			insert tail file-ids reduce [to-integer ansno file]
			file: aa/get files-to-receive file
			file/5: to-integer ln
			file/4 ch 'init file
		)
	]
]
