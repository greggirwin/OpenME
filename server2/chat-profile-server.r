REBOL [
	Description: "Implements the application protocol for PubTalk (aha the profiles)"

]

;;
;; The 'L will echo back text to all initiators channels in the chatrom-peers structure
;; An 'I PUBTALK-ETIQUETTE channel is added the chatroom-peer at chanel creation 


register context [

profile: 'CHAT
version: 1.0.0
init: func [
	{Initialize channel specific data and dynamic handlers - called by any new connection}
	channel [object!] ; the channel to be initialized
][
	
	; create the private profile data
	channel/prof-data: context [
		username: channel/port/user-data/username
		;user-id: get-user-id username
		counter: false			; current syncing message counter
		state: #unknown-counter	; #unknown-counter | #ok | #syncing | #failure
		count-error: 0			; number of errors sent back
		count-synced-msg: 0		; number of messages sent back 
		request: []				; last request received
		response: [] 			; last response emitted
	]
	
	; set the read-msg handler
	channel/read-msg: func [
		{handle incoming MSGs}
		channel frame
		/local my msg request response state author group
	] [
		my: channel/prof-data
		state: my/state
		
		if error? try [request: to block! frame/payload][request: [wat!]]
		
		;-- state machine
		; First, the current state is inserted in the request block,
		;  so that one can parse the server's state and client request together.
		; Then, the response of the server is parsed again to take actions. 
		insert request state
		response: [no-response]
		
		parse request [
			[#ok | #syncing] 'sync end (
				response: case [
					my/counter = last-message-counter [
						; up-to-date
						[#ok ok]
					]
					not msg: get-message-user my/counter + 1 my/user-id [
						; finished syncing, up-to-date
						my/counter: last-message-counter
						[#ok your-counter last-message-counter]
					]
					true [
						; send back new message to client
						my/counter: msg/counter
						[#syncing new-message msg/format]
				]
			)
			| #ok 'chat [
				['group | 'private] string! into [string! to end] end (
					;-- New message
					response: case [
						not author: get-author request/5/1	[[client-error "Author not found:" request/5/1]]
						not group: get-group request/4		[[client-error "Group not found:" request/4]]
						; try to create
						not store-message author/id group/id next command 
															[[#failure server-error "Message not added."]]
						true 								[[#syncing Ok "New message added:" last-message-counter]]
					]
				)
				| (response: [client-error "Poorly formed chat request: " mold next request])
			]
			| #syncing 'chat (
				response: [wait "You can't chat until you're synced."]
			)
			| #unknown-counter 'my-counter integer! end (
				response: case [
					request/3 < (first-message-counter - 1) [
						; out of range: the server does not have this first message anymore
						; client must send a valid counter again
						; state not modified
						[out-of-range first-message-counter last-message-counter]
					]
					request/3 >= last-message-counter [
						; client database up-to-date
						my/counter: last-message-counter
						[#ok ok]
					]
					true [
						my/counter: command/3
						[#syncing ok]	; syncing requested
					]
				]
			)
			| issue! 'infos end ; send infos on my state (whatever is my state)
					(response: [infos mold my])
			
			| issue! 'wat! end	; unloadable rebol value
					(response: [client-error "Can't load this:" lf msg/payload])
					
			| [#ok | #syncing | #unknown-counter] 	; don't know what to do with this request
					(response: [client-error "Protocol violation: " lf mold request])
			
			| 		(response: [server-error "Sorry, I'm in bad state: " request/1]) 
		]
		
		;-- send back answer to the client
		parse copy response [
			opt [set state issue!]	; modify server state
			response: 
			word! opt [skip (clear change next response reduce next response)] ; reduce some opional parameters
			:response
			[
				  ['ok | 'new-message | 'wait | 'infos | 'out-of-range | 'your-counter] 
				  		(post-reply channel response)
				| ['server-error | 'client-error]
						(post-error channel response)
			]
			|	(	; Know your own protocol stupid server!
					state: #failure
					post-error channel compose [server-error "I'm stupid!" (mold head response)]]
			)
		]
		
		;-- save back state
		my/state: state
		my/request: request
		my/response: head response
	]

	; set the read-rpy handler
	channel/read-rpy: func [
		{handle incoming replies}
		channel frame
	][

	]

	; set the close handler
	channel/close: func [
		{to let the profile know, that the channel is being closed}
		channel
	][

	]
]	;-- end init function
]	;-- end register

;------------------------
;- helper functions
;------------------------

post-error:  func [channel msg][post- channel 'err msg]

post-reply:  func [channel msg][post- channel 'rpy msg]

post-: func [channel type msg][
	if block? msg [msg: mold/only msg]
	send-frame channel make frame-object [
		msgtype: type
		more: '.
		payload: msg
]


