Rebol [
	Title: "BEER Initiator Example"
	Date: 9-May-2006/18:34:21+2:00
]

#do [
	do %../../paths.r
	[]
]

; user database
users: load %users.r
groups: load %groups.r

do %encoding-salt.r
include/check %initiator.r
include/check %echo-profile.r

testfiles: either empty? testfiles: ask "test files directory: (%/c/stazeno/AVSDC/):" [
	%/c/stazeno/AVSDC/
] [dirize load testfiles]

open-session atcp://127.0.0.1:8000 func [port] [
	either port? port [
		peer: port
		print ["Connected to listener:" peer/sub-port/remote-ip]
		open-ec
	] [print port]
]

open-ec: does [
	open-channel peer 'echo 1.0.0 func [channel] [
		either channel [
			ec: channel
			print "Channel ec open"
			;login-lad
			ec2: none
			file-transport
		] [print "didn't succeed to open unsecure echo channel"]
	]
]

login-lad: does [
	;login/with aa/get peer/user-data/channels 0 "admin" #{C7AF6C89E8DACE19D861F245B9503324E12C01AE} func [result] [
	login aa/get peer/user-data/channels 0 "admin" "b" func [result] [
		either result [
			print "logged in as Admin"
			open-ec2
		] [print "login unsuccessful"]
	]
]

open-ec2: does [
	open-channel peer 'echo 1.0.0 func [channel] [
		either channel [
			ec2: channel
			print "channel ec2 open"
			file-transport
		] [print "didn't succeed to open secure echo channel"]
	]
]

file-transport: does [
	if ec [
		print "file transport through ec (which is unencrypted)"
		send-frame ec make frame-object [
			msgtype: 'MSG
			more: '.
			payload: "get"
		]
	]
	if ec2 [
		print "file transport through ec2 (which is encrypted)"
		send-frame ec2 make frame-object [
			msgtype: 'MSG
			more: '.
			payload: "get"
		]
	]
	if ec [
		print "closing the ec channel"
		close-channel ec func [result] [
			either result [
				print "channel ec closed"
				session-done
			] [
				print "failed to close the ec channel"
			]
		]
	]
]

session-done: does [
	comment [
	close-channel aa/get ec2/port/user-data/channels 0 func [result] [
		either result [
			print "session close successful"
			new-session
		] [print "session close unsuccessful"]
	]
	]
	destroy-session peer "koncim session"
	peer: ec: ec2: none
	new-session
]

new-session: does [
    print "New session"

	open-session atcp://127.0.0.1:8000 func [port] [
		either port? port [
			peer: port
			print ["Connected to listener:" peer/sub-port/remote-ip]
			login-adm
		] [print port]
	]
]

login-adm: does [
	login aa/get peer/user-data/channels 0 "admin" "b" func [result] [
		either result [
			print "logged in as Admin"
		] [print "login unsuccessful"]
	]
]

wait []
