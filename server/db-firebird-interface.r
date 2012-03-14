Define wrappers for data access (firebird compliant)

REBOL []

;--------------------------
;- get all channels (also called "groups" in Altme)
;--------------------------
get-channels: has [list][
	list: make block! 15
	insert db-port [{select distinct channel from chat where ctype = (?)} "G"]
	foreach record copy db-port [
		if found? record/1 [append list record/1]
	]
	also list list: none
]

;--------------------------
;- get all channels + their message counter
;--------------------------
get-channels-cnt: has [list][
	list: get-channels
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

;--------------------------
;- set email for a user
;--------------------------
set-email: func [
	email [string!]
	username [string!]
][
	insert db-port [ {update users set email = (?) where userid = (?)} email username]
]

;--------------------------
;- get all users
;--------------------------
get-users: does [
 	insert db-port {select userid, city, email, tz, laston from users where activ = 'T'}
 	copy db-port
]

;--------------------------
;- write chat message
;--------------------------
write-chat: func [
	author channel msg format c-type
][
	insert db-port [
		{insert into CHAT ( author, CHANNEL, msg, format, ctype ) values (?, ?, ?, ?, ?) } 
		author channel msg format c-type
	]
]

;--------------------------
;- count messages created after a date
;--------------------------
count-messages: func [
	date [date!]
][
	insert db-port [{select count(msg) from chat where msgdate >  (?)} date]
	either pick db-port 1 [cnt/1][0]
]

;--------------------------
;- get messages created after a date
;--------------------------
get-messages: func [
	date [date!]
][
	insert db-port [{select msg, format from chat where msgdate > (?) order by msgdate asc} date]
	copy db-port
]

;--------------------------
;- get messages created after a date, with optionnal author and channel
;--------------------------
get-messages-with: func [
	date [date!]
	author [string! none!]
	channel [string! none!]
][
	case [
		all [none? author none? channel] [
			insert db-port [{select msg, format, ctype from chat where msgdate > (?) order by msgdate asc} date]
		]
		all [none? author channel] [
			; lowercase group
			insert db-port [{select msg, format, ctype from chat where msgdate > (?) and channel = (?) order by msgdate asc} date channel]
		]
		all [author none? channel] [
			; lowercase author
			insert db-port [{select msg, format, ctype from chat where msgdate > (?) and author = (?) order by msgdate asc} date author]
		]
		all [author group] [
			; lowercase author lowercase group
			insert db-port [{select msg from, format, ctype chat where msgdate > (?) and author =(?) and CHANNEL = (?) order by msgdate asc} date author channel]
		]
	]
	copy db-port
]