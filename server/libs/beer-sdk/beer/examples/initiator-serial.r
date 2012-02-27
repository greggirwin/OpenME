Rebol [
	Title: "BEER Initiator Example"
	Date: 18-Jan-2006/15:06:14+1:00
	License: {
Copyright (C) 2005 Why Wire, Inc.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

Other commercial licenses to this program are available from Why Wire, Inc.
}
]

do %../../paths.r

; user database
users: load %users.r
groups: load %groups.r

do %encoding-salt.r
include/check %initiator.r
include/check %echo-profile.r

testfiles: dirize load ask "Testfiles directory (nonempty directory needed): "

open-session atcp://127.0.0.1:8000 func [port] [
	either port? port [
		peer: port
		print ["Connected to listener:" peer/sub-port/remote-ip]
		print "Evaluate ENCRYPTED after TRANSPORT is finished"
		print "Evaluate SESSION-DONE afterwards"
		ask "ready?"
		print "Starting TRANSPORT"
		transport
	] [print port]
]

transport: does [
	open-channel peer 'echo 1.0.0 func [channel] [
		either channel [
			ec: channel
			print "Channel ec open"
			print "file transport through ec (which is unencrypted)"
			send-frame ec make frame-object [
				msgtype: 'MSG
				more: '.
				payload: "get"
			]
		] [print "didn't succeed to open unsecure echo channel"]
	]
]

encrypted: does [
	speed1: transmission-speed
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
	print "file transport through ec2 (which is encrypted)"
	send-frame ec2 make frame-object [
		msgtype: 'MSG
		more: '.
		payload: "get"
	]
	session-done
	comment [
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
]

session-done: does [
	close-channel aa/get ec2/port/user-data/channels 0 func [result] [
		either result [
			print "session close successful"
			print ["Unencrypted transport speed:" speed1]
			print ["Encrypted transport speed:" transmission-speed]
		] [print "session close unsuccessful"]
	]
]

wait 25
encrypted
wait []
