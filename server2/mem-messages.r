Interface to cache messages in memory (uses db-mem handler)

REBOL []

unless value? 'misc.r [do %libs/misc.r]
unless value? 'db-mem.r [do %libs/db-mem.r]

;---------------------
;- callback functions
;  These functions are used to save/load messages in database (files).
;  This is optional. No database means messages are only memory cached and lost when app quit.
;----------------------
defined? [ ; (set to false if not already defined)
	save-message	; save a message in database
	load-messages	; load some messages from database (initialize the cache)
]

;----------------------
;- message schema
;----------------------
mem-msg: db-mem/new "Message-table" [
		counter:	integer!		; unique, auto increment
		author-id:	integer!
		group-id:	integer!		; also called channel, thread
		type:		['G | 'P]		; G=Public, P=Private
		date: 		date!			; GMT date
		time:		time!			; GMT time
		format:		string! 		; actually the message
]

do mem-msg/bound [
;--------------------------
;- load data from database/file
;--------------------------
data: any [load-messages copy []]

;--------------------------
;- (re)build indexes 
;  must be done after database is loaded
;--------------------------
indexed-by construct [counter: type: author-id: group-id:] ;-- order does not matter

;--------------------------
;- public interface (free use anywhere in the app)
;
;-- FUNCTIONS:
;-- store-message : store a new message in cache
;-- get-first-message : get first message in cache
;-- get-last-message : get last message in cache
;-- get-message : get any message (with a global counter)
;-- get-message-user : get a message belonging to a user
;-- GLOBAL VARIABLES (READ ONLY):
;-- first-message-counter : message counter of the first message stored in cache
;-- last-message-counter : message counter of the last message stored in cache
;--------------------------

;--------------------------
;- store a message in cache
;--------------------------
store-message: func [
	author [integer!]
	group [integer!]
	msg [block!] 
	/local gmt
][
	set fields none
	
	counter: 	last-message-counter + 1 
	author-id: 	author
	group-id:	group
	type: 		select [Public G Private P] msg/2
	
	gmt: now	; transform timestamp to gmt
	gmt: gmt - gmt/zone
	
	date: gmt/date
	time: gmt/time
	
	insert insert tail msg counter gmt	; append [counter timestamp] to msg
	
	format: 	mold/flat/all/only new-line/all msg off
	
	all [
		check-syntax
		(save-message fields)	; update database (optional)
		append-fields
		last-message-counter: last-message-counter + 1 ; increment message counter only if storing ok
	]
]

;--------------------------
;- get first message in cache
;
;  Returns a field-object or false
;--------------------------
get-first-message: func [][fetch 1]

;--------------------------
;- get last message in cache (most recent)
;
;  Returns a field-object or false
;--------------------------
get-last-message: func [][fetch length? data]

;--------------------------
;- get message in cache from a global message counter
;
;  Returns a fields-object or false
;--------------------------
get-message: func [
	counter [integer!]
][
	position: 1
	fetch where 'counter counter
]

;--------------------------
;- get next message for a user.
;
;  Returns a field-object or false
;--------------------------
get-message-user: func [
	counter [integer!] {starting from a counter}
	user-id [integer!]
][
	all [
		position: 1
		position: where 'counter counter	; advance position based on a message counter
		fetch [
			where 'type 'G 				; from a public group
 			where 'author-id user-id	; or a private message the user authored
			where 'group-id user-id 	; or a private message someone else sent to user
		]
	]
]

;--------------------------
;- global message counters (never change them anywhere but in this script)
;--------------------------

LAST-MESSAGE-COUNTER: any [
	all [
		fetch length? data
		counter
	]
	0
]

FIRST-MESSAGE-COUNTER: any [	
	all [
		fetch 1
		counter
	]
	1
]
protect [first-message-counter] ;-- not modifiable

] ;-- mem-msg bounded


