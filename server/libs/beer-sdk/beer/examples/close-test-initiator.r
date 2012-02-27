Rebol [
	Title: "BEER close profile Example"
	Date: 18-Jan-2006/14:38:20+1:00
]

do %../../paths.r

; user database
users: load %users.r
groups: load %groups.r

do %encoding-salt.r

include/check %initiator.r
include/check %close-test-profile.r

open-session atcp://127.0.0.1:8000 func [port] [
	either port? port [
		peer: port
		print ["Connected to listener:" peer/sub-port/remote-ip]
		login-adm
	] [print port]
]

open-cl: does [
	open-channel peer 'close-test 1.0.0 func [channel] [
		either channel [
			cl: channel
			print "Close test channel open"
			send-frame channel make frame-object [
				msgtype: 'MSG
				more: '.
				payload: to binary! mold/only [ask-me]
			]
		] [print "didn't succeed to open close test channel"]
	]
]

login-adm: does [
	login aa/get peer/user-data/channels 0 "admin" "b" func [result] [
		either result [
			print "logged in as Admin"
			open-cl
		] [print "login unsuccessful"]
	]
]

open-cl2: does [
	open-channel peer 'close-test 1.0.0 func [channel] [
		either channel [
			cl2: channel
			print "channel cl2 open"
		] [print "didn't succeed to open secure cl2 channel"]
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

wait []
