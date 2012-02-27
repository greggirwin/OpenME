REBOL [
	title: "RPC profile for BEER"
	author: cyphre@whywire.com
	date: 30-May-2005/18:15:40+2:00
	License: {
Copyright (C) 2005 Why Wire, Inc.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

Other commercial licenses to this program are available from Why Wire, Inc.
}
]

#include-check %threads.r

register context [
	profile: 'rpc
	version: 1.0.0
	
	services: copy []
	callbacks: aa/make 256	
	
	; initial handler
	init: func [
		channel [object!]
	][
		random/seed now
		channel/prof-data: make object! [
			result: make binary! []
			buf: make string! []
			service-to-send: make string! []
			ans-buf: make string! []
			threads-to-kill: copy []
		]
		
		channel/read-msg: func [
			channel frame /local prof-data name commands args service result result-data current-service cmd-num start err? mark challenge response thread? id tid tresult type last? cmds task-id error rights ctx-service fname
		][
			start: now/time/precise
			prof-data: channel/prof-data
			
			result: prof-data/result
			clear result
			cmd-num: 0
			err?: false
			parse load/all frame/payload [
				some [
					'send set id string! set name string! set commands block! (
						either service: select services name [
							either not empty? commands [
								thread?: none
								;process 'service dialect' and commands
								foreach cmd commands [
									if not parse cmd [
										'service set current-service word!
										| set thread? ['after | 'schedule | 'repeat] set time [date! | time! | number! | paren!] (
											if paren? time [time: do time]

										)
									][
										if thread? [remove/part cmd 2]
										if err? [
											break
										]
										if not find service/services current-service [
											current-service: none
										]
										args: copy next cmd
										either error? error: try [
											rights: aa/get channel/port/user-data/rights 'rpc
											if all [not empty? rights not find rights cmd/1] [
												make error! "inssuficient rights"
											]
											if current-service [
												ctx-service: context bind select service/data current-service in channel 'self
												fname: to-word first parse/all form cmd/1 "/"
												if not find first ctx-service fname [
													make error! "service not found"
												]
											]
											either thread? [
												;process thread command
												either thread? = 'repeat [
													;initialize and run 'repeated type' thread
													until [
														catch' [
															tid: make-id
															if thread-exists? tid [
																throw' false
															]
															true
														]
														not thread-exists? tid: make-id
													]
													open-channel channel/port 'rpc 1.0.0 func [channel] compose/deep [
														add-thread/repeat/cid (tid) (time) [(bind cmd in ctx-service 'self)] func [id result] compose/deep [
															either all [channel/port/user-data/open? none? find prof-data/threads-to-kill (tid)][
																last?: true
																if thread-id? (id) [
																	last?: false
																]
																send-frame (to-paren 'channel) make frame-object [
																	msgtype: 'MSG
																	payload: to binary! mold/only compose/deep [thread (thread?) (tid) (id) (to-paren [to-paren 'last?]) [(to-paren [to-paren 'result])]]
																	more: '.
																]
															][
																remove find prof-data/threads-to-kill (tid)
																close-channel channel none
																kill-thread (tid)
															]
														] (id)
													]
												][
													;initialize and run all other types of thread
													until [
														tid: make-id
														do reduce [
															make path! reduce [
																'add-thread 'cid either thread? = 'after [""][thread?]
															] tid time bind cmd in ctx-service 'self 'func [id result] compose/deep [
																either channel/port/user-data/open? [
																	open-channel (channel/port) 'rpc 1.0.0 func [channel] [
																		last?: true
																		if thread-id? (id) [
																			last?: false
																		]
																		send-frame channel make frame-object [
																			msgtype: 'MSG
																			payload: to binary! mold/only compose/deep [thread (thread?) (tid) (id) (to-paren 'last?) [(to-paren 'result)]]
																			more: '.
																		]
																		close-channel channel none
																	]
																][
																	kill-thread (tid)
																]
															] (id)
														]
													]
												]
												thread?: none
												result-data: compose [thread-added (tid) (now/precise)]
											][
												;process 'immediate commands'
												if not parse cmd [
													'kill-thread set tid string! (
														task-id: cid? tid
														result-data: either (thread-type? tid) = 'repeat [
															insert tail prof-data/threads-to-kill tid
															copy [true]
														][
															reduce [kill-thread tid]
														]

														if thread-id? id [
															insert tail result-data reduce ['last task-id]
														]
														if length-threads? = 0 [
															insert tail result-data reduce ['last task-id]
														]
													)
												][
													;execute RPC command
													set/any 'result-data do bind cmd in ctx-service 'self
													if not value? 'result-data [result-data: unset!]
												]
											]
										][
											;command failed!
											err?: 'command-failed
											insert tail result mold/all/only compose/deep [
												fail [(cmd) (mold disarm error)]
											]
										][
											;command has been succesfully executed
											cmd-num: cmd-num + 1
											insert tail result mold/all/only compose/deep/only [
												ok  [(cmd/1) (either empty? args [][args]) (result-data)]
											]
										]
									]
								]
								;put 'summary message' into result
								insert result mold/all/only compose/deep either err? [
									[(id) error [(err?)]]
								][
									[(id) done [commands (cmd-num) time (now/time/precise - start)]]
								]
							][
								;no commands received
								insert result mold/all/only compose [(id) error [nothing-to-do]]
							]
						][
							;service doesn't exist
							insert result mold/all/only compose [(id) error [service-not-available]]
						]
					)
					| 'thread set type ['repeat | 'after | 'schedule] set tid string! set id string! set last? word! set tresult block! (
						send-frame channel make frame-object [
							msgtype: 'RPY
							payload: to binary! mold/only [ok]
							more: '.
						]
						do first aa/get callbacks id channel reduce ['thread tid tresult]
						if last? = 'true [
;							print ["CALLBACK REMOVED" id]
							aa/remove callbacks id channel
						]

					)
; rule 'publish was here originally
					| 'request-publish set id string! (
						send-frame/callback channel make frame-object [
							msgtype: 'RPY
							payload: to binary! mold/only compose/deep [request-publish ok (id)]
							more: '.
						] compose/deep [
							send-frame (channel) make frame-object [
								msgtype: 'MSG
								payload: to binary! mold/only compose/deep [begin-publish (id)]
								more: '.
							]
						]
					)
					| 'begin-publish  set id string! (
						send-frame channel make frame-object [
							msgtype: 'RPY
							more: '.
							payload: to binary! mold/all/only compose [
								publish (id) (prof-data/service-to-send)
							]
						]
						prof-data/service-to-send: none
					)
					| set id string! result: (
						;execute callback after services publishing
						do first aa/get callbacks id channel copy result
						aa/remove callbacks id
					)
					| skip
				]
			]
			if not empty? result [
				register-sending channel func [channel size] [
					make frame-object [
						msgtype: 'RPY
						payload: copy/part prof-data/result size
						prof-data/result: skip prof-data/result size
						more: either tail? prof-data/result ['.]['*]
					]
				]
			]
		]

		channel/read-rpy: func [channel frame /local id result prof-data challenge salt
		][
			prof-data: channel/prof-data
			insert tail prof-data/buf frame/payload
			if frame/more = '. [
				parse load/all prof-data/buf [
					'publish set id string! set service object! (
						publish-service construct/with bind third service 'system service-object
						send-frame channel make frame-object [
							msgtype: 'MSG
							payload: to binary! mold/only compose/deep [(id) ok [publish (id)]]
							more: '.
						]
					) |
					set id string! result: (
						catch' [
							do first aa/get callbacks id channel copy result
							foreach [st cmd] result [
								if any [all [block? cmd/2 find cmd/2 'thread-added] all [block? cmd/3 find cmd/3 'thread-added]] [throw']
								if all [cmd/1 = 'kill-thread block? cmd/3 cmd/3/2 = 'last][
	;								print ["CALLBACK REMOVED" cmd/3/3]
									aa/remove callbacks cmd/3/3 remove/part at cmd/3 2 5
									break
								]
							]
	;						print ["CALLBACK REMOVED" id]
							aa/remove callbacks id
						]
					)
				]
				clear prof-data/buf
			]
		]

		channel/close: func [
			{to let the profile know, that the channel is being closed}
			channel
			/ask
		][
;			print "RPC-CLOSE"
		]
	]	
	
	set 'service-object make object! [
		info: make object! [
			name: none
			summary: none
			organization: none
			version: none
			category: none
			contact: none
			website: none
		]
		services: none
		user-db: none
		data: none
	]

	set 'make-service func [blk [block!]][
		blk: make service-object blk
		blk/info: make service-object/info blk/info
		blk
	]
	
	set 'publish-service func [
		service [object!]
		/remote
			channel [object!]
			callback [function!]
		/local
			cmd
			id
	][
		either remote [
			channel/prof-data/service-to-send: service
			cmd: copy #{}
			until [
				not find callbacks/keys id: make-id
			]
			aa/set callbacks id reduce [:callback]
			insert cmd mold/all/only compose [
				request-publish (id)
			]
			send-frame channel make frame-object [
				msgtype: 'MSG
				more: '.
				payload: cmd
			]
		][
			insert services reduce [get in service/info 'name service]
		]
	]

	make-id: does [
		enbase/base checksum/secure form random/secure to-integer #{7fffffff} 16
	]

	set 'send-service func [
		channel [object!]
		service [string!]
		blk [block!]
		callback [function!]
		/local
			cmd
			id
			pass
	][
		cmd: copy #{}

		until [
			not find callbacks/keys id: make-id
		]

		aa/set callbacks id reduce [:callback to-binary pass]

		insert cmd mold/all/only compose/deep [
			send (id) (service) [(blk)]
		]
		
		send-frame channel make frame-object [
			msgtype: 'MSG
			more: '.
			payload: cmd
		]
	]
]
