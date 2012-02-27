Rebol [
	Title: "BEER Initiator Example"
	Date: 18-Jan-2006/15:06:14+1:00
]

do %../../paths.r

; user database
users: load %users.r
groups: load %groups.r

do %encoding-salt.r
include/check %initiator.r
include/check %rpc-profile.r

open-session atcp://127.0.0.1:8000 func [port] [
	either port? port [
		peer: port
		print ["Connected to listener:" peer/sub-port/remote-ip now]
		do-login
	] [print port]
]

do-login: does [
	login aa/get peer/user-data/channels 0 "root" "d" func [result] [
		either result [
			print "logged in as Root"
			open-rpc
		] [print "login unsuccessful"]
	]
]

open-rpc: does [
	open-channel peer 'rpc 1.0.0 func [channel] [
		either channel [
			rpc: channel
			print "Channel rpc open"
			do-test
		] [print "didn't succeed to open unsecure echo channel"]
	]
]


do-test: does [
	my-services: make-service [
		info: [
			name: "my services"
		]
		services: [calc]
		data: [
			calc [
				calc-result: func [input][
					do input
				]
			]
		]
	]

	init?: true

	send-service rpc "basic services" [
		[service time]
		[repeat 1 get-time]
		[after 00:00:05 get-time]
		[schedule (now + 0:0:15) get-time] ;by specifying the time value in paren you force to evaluate it on the listener side(useful when times on both machines differs)
		[service info]
		[service-names]
	] func [channel result /local services id rslt][
		;just some testing callback function
		
		print "RPC CALL RETURNED"
		print "Result:"
		probe result 

		if 'error = first result [
			print "request failed!"
			exit
		]
	;	st: now/time - 500
		if init? [; do this only once
			;get the returned 'thread id' from the first thread request and get the 'listener time' when the thread has been started
			tid: result/4/2/2
			st: result/4/2/3
			init?: false
		]
		
		;check if result is from thread running on the listener
		if parse result ['thread set id string! set rslt block!][
	;		if rslt/1 >= (st + 30) [
			if all [id = tid rslt/1 >= (st/time + 30)][
				;kill the repeating thread after 30 seconds
				send-service rpc "basic services" compose/deep [
					[kill-thread (id)]
				] func [channel result][probe result]
			]
			exit
		]
		
		;check the available services	
		foreach i extract/index result 2 2 [
			if services: select i 'service-names [
				break
			]
		]
		print "adding CALC service..."
		if not find services 'calc [
			publish-service/remote my-services rpc func [channel result][
				probe "REMOTE PUBLISHING DONE"
				print ["result:" result]
				print "calling CALC service..."
				send-service rpc "my services" [
					[service calc]
					[calc-result 1 + 2 + 5 / 2]
				] func [channel result][
					probe result
				]
	
			]
		]
	]
]

do-events
halt

