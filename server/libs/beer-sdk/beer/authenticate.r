Rebol [
	Title: "BEER Authentication"
	Date: 4-May-2005/13:13:24+2:00
	License: {
Copyright (C) 2005 Why Wire, Inc.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

Other commercial licenses to this program are available from Why Wire, Inc.
}

]

;authentication functions
make-salt: does [
    checksum/secure form random/secure to-integer #{7fffffff}
]

encode-pass: func [
	pass [string!]
	salt [binary!]
] [
	checksum/secure append to binary! pass salt
]

make-user: func [
	users [block!]
	user [string!]
	encoded-pass [binary!]
	login [word!]
	groups [block!]
] [
    if find/skip users user 4 [debug "User already exists" return false]
    insert tail users reduce [user encoded-pass login groups]
    true
]

change-pass: func [
	users [block!]
	user [string!]
	encoded-pass [binary!]
	/local user-data
] [
    unless user-data: find/skip users user 4 [
		debug "User does not exist!"
		return false
	]
	user-data/2: encoded-pass
    true
]

make-group: func [
	groups [block!]
	group [word!]
	rights [block!]
] [
	if find/skip groups group 2 [
		debug "Group already exists" return false
	]
	insert tail groups reduce [group rights]
	save %groups.r groups
	true
]

rights?: func [
	[catch]
	username [string!]
	/local rights group-rights user-groups
] [
	unless user-groups: find/skip users username 4 [
		throw make error! "Unknown user"
	]
	user-groups: fourth user-groups
	rights: aa/make EXPPROFILES
	foreach group user-groups [
		if group-rights: select groups group [
			foreach [profile profile-services] group-rights [
				aa/set rights profile union
					aa/get/default rights profile [make block! 0]
					profile-services
			]
		]
	]
	rights
]

make-challenge: func [salt [binary!]] [
    reduce [salt make-salt] ; salt and challenge
]

answer-challenge: func [
	user [string!]
	encoded-pass [binary!]
	salt [binary!]
] [
	checksum/secure append append to binary! user encoded-pass salt
]    	

verify-challenge: func [
	users [block!]
	challenge [block!]
	answer [binary!]
] [
    foreach [user pass login user-groups] users [
    	if all [
    		login = 'login
			answer = checksum/secure rejoin [#{} user pass challenge/2]
		] [return reduce [user pass user-groups]]
	]
	false
]
