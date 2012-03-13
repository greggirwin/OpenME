Define wrappers for data access (firebird compliant)

REBOL []

;--------------------------
;- get all channels (also called "groups" in Altme)
;--------------------------
get-channels: has [list][
	list: make block! 15
	insert db-port [{select distinct channel from chat where ctype = (?)} "G"]
	foreach record copy db-port [
		if found? record/1 [
			append list record/1
		]
	;; got all the groups, now get all the messages in each group
	foreach group copy list [
		insert db-port [{select count(msg) from chat where channel = (?)} group]
		cnt: pick db-port 1
		insert find/tail list group cnt
	]
	
	also list list: none
]

;--------------------------
;- set time zone for a user
;--------------------------
set-timezone: func [
	timezone [string!]
	username [string!]
][
	insert db-port [{update users set tz = (?) where userid = (?)} timezone username]
]

;--------------------------
;- set city for a user
;--------------------------
set-city: func [
	city [string!]
	username [string!]
][
	insert db-port [{update users set city = (?) where userid = (?)} city username]
]

