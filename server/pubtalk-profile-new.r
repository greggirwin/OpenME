REBOL [
	Description: "Implements the application protocol for PubTalk (aha the profiles)"

]

do %db-firebird-interface.r

;; Profile summary
;;
;;    BEER profile PUBTALK-ETIQUETTE
;;
;;    role        MSG        RPY        ERR
;;    ====        ===        ===        ===
;;    I or L      text       ok         text
;;
;; The 'L will echo back text to all initiators channels in the chatrom-peers structure
;; An 'I PUBTALK-ETIQUETTE channel is added the chatroom-peer at chanel creation 


prefs-obj: make object! [
	username: language: tz: status: email: city: none
]

Eliza-obj: make prefs-obj [username: "Eliza" language: "EN" status: "present" email: "compkarori@gmail.com" tz: now/zone city: "Wellington"]


chatroom-peers: make block! [] ;maintains the list of active peers in a conversation
eliza-on: false
; user-table: copy ["0.0.0.0:0" "Eliza" "present"] ; [ ipaddress:port username state ]
; user-table: copy/deep [ "0.0.0.0:0" Eliza-obj ] 

user-table: copy []
repend user-table ["0.0.0.0:0" Eliza-obj]
chat-links: copy []
if exists? %chat-links.r [
	attempt [
		chat-links: load %chat-links.r
	]
]

comment {
@
prefs-obj: make object! [
	username: language: tz: status: email: city: none
]

Eliza-obj: make prefs-obj [username: "Eliza" language: "EN" status: "present" email: "compkarori@gmail.com" tz: now/zone city: "Wellington"]

@c                
}

;;; rebuild user table

rebuild-user-table: func [/local temp-table state t] [
	; now rebuild the user-table, and the chat-users list
	temp-table: copy user-table
	; user-table: copy [ "0.0.0.0:0" "Eliza" "present" ]

	user-table: copy []
	repend user-table ["0.0.0.0:0" Eliza-obj]
	;; now should get all the registered users and add them
	cnt: 1
	foreach record get-users [
		probe record/5
		state: copy "-"
		
		if found? record/5 [
			state: now/zone + difference now record/5
			?? state
			either state > 24:00 [
				state: rejoin [ record/5/day "-" record/5/month ] 
			][
				t: form state
				state: copy/part t find/last t ":"
			]	
		]
		; ?? state
		repend user-table [join "0.0.0.0:" cnt make prefs-obj [username: record/1 tz: record/4 city: record/2 email: record/3 status: state]]
		cnt: cnt + 1
	]
	; probe user-table


	; chat-users: copy reduce ["Eliza" "present" "0.0.0.0" "0"]
	; should now rebuild the user-table of ip-port, username, state
	foreach channel chatroom-peers [
		attempt [
			ip-port: form rejoin [channel/port/user-data/remote-ip ":" channel/port/user-data/remote-port]
			either found? ndx: find temp-table ip-port [
				; user was here before
				; repend user-table [ ndx/1 ndx/2 ]
				; need to change the existing table.
				; get the userid out

				forskip user-table 2 [
					; if we find the user in the chatroom-peers, we take their ip-port and status, and overwrite the one in the user-table
					; print ["Looking at " user-table/2/username]
					if user-table/2/username = channel/port/user-data/username [
						user-table/1: ip-port
						user-table/2: ndx/2
						break
					]
				]
				user-table: head user-table
				; repend chat-users [ ndx/2 ndx/3 channel/port/sub-port/remote-ip channel/port/sub-port/remote-port ]
			][	
				; not in the old user-table, so must be new arrivee
				; or duplicate?  To prevent two users, let's overwrite the existing one
				forskip user-table 2 [
					; print ["Looking at " user-table/2/username]
					if user-table/2/username = channel/port/user-data/username [
						user-table/1: ip-port
						; user-table/2: ndx/2
						user-table/2/status: "arrived"
						break
					]				
				]
				user-table: head user-table
			]
		]
	]
	print ["after removal users: " length? chatroom-peers]
	print "user table"
	probe user-table
	; print "chat-users"
	; probe chat-users
	; msg-to-all mold/all reduce ['cmd reduce ['set-userstate chat-users]]
	update-room-status
]
                
;;; end of rebuild user table




register context [
	profile: 'PUBTALK-ETIQUETTE ; profile name
	version: 1.0.0 ; version of the profile
	init: func [
		{Initialize channel specific data and dynamic handlers - called by any new connection}
		channel [object!] ; the channel to be initialized
	] [; new channel created register the peer into the chatroom-peers 
		; this is only required in the server, so that it can replicate 
		; the posted messages.
		if channel/port/user-data/role = 'L [
			append chatroom-peers :channel
			print [" New user has arrived. Number of channels in room = " length? chatroom-peers]

			; let's see what's in the port
			; write %port.r mold channel/port
			rebuild-user-table
		]

		; create the private profile data
		channel/prof-data: make object! [
			; we don't require any private data for this profile
		]

		; set the read-msg handler
		channel/read-msg: func [
			{handle incoming MSGs}
			channel
			msg
		] [
			; display msg/payload
			; probe msg/payload
			ack-msg channel
			clientmsg: load msg/payload

			print "raw message"
			probe clientmsg


			comment {
[ chat [ ] [ user color msg color color date font ]]

; chat message to some 
[ chat [ u1 u2 .. ] [ user color msg color color date font ] ]

; cmd message to server

[ cmd [ set-users ]] ; get the users
[ cmd [ set-state "away" ]] ; set user state

; cmd message to client

[ cmd [ set-users ]] ; set the users and status

[ action [ user ] [ the action ]]

[ action [ "guest" ] [ 'nudge ]]

}

			case [
				parse clientmsg ['pchat set userblock block! set clientmsg block! to end] [
					print "private message - check for Eliza"
					probe userblock

					;					msg-to-all msg/payload
					; return the message to the sender but with a timestamp
					insert tail clientmsg now ;; first time insert
					post-msg1 channel mold/all reduce [
						'pchat
						reduce [userblock/1]
						clientmsg
					]
					; check to see if message is for Eliza ie. userblock/1 = "0.0.0:0"
					comment {
chat-links: [[gchat ["lobby"] ["Graham" 128.128.128 "this is a link http://www.rebol.com" 0.0.0 240.240.240
 []]] [gchat ["lobby"] ["Graham" 128.128.128 "http://www.compkarori.com/reb/pluginchat40.r" 0.0.0 240.240.2
40 []]]]
}

					either any [userblock/1 = "Eliza" userblock/1 = "0.0.0.0:0" userblock/1 = "0:0" userblock/1 = "0.0.0:0"] [
						print "message for Eliza"
						case [
							find/part clientmsg/3 "search " 7 [
								use [terms msg ok] [

									if not empty? msg: trim find/tail clientmsg/3 #" " [
										terms: parse/all msg " "
										foreach msgblock chat-links [
											msg: msgblock/3/3
											ok: true
											foreach term terms [
												if not find msg term [
													ok: false
													break
												]
											]
											if ok [
												msgblock/1: 'pchat
												msgblock/2/1: "Eliza"
												post-msg1 channel mold/all msgblock

											]
										]
									]

								]
							]
							any [
								find/part clientmsg/3 "help" 4
								find/part clientmsg/3 "aide" 4


							] [
								print "found help message"
								use [ip-port ndx] [
									ip-port: form rejoin [channel/port/user-data/remote-ip ":" channel/port/user-data/remote-port]
									if found? ndx: find user-table ip-port [
										lang: ndx/2/language
									]
									; now update everyone
									update-room-status
								]
								if none? lang [
									case [
										find/part clientmsg/3 "aide" 4 [lang: "FR"]
									]
								]


								help-msg:
								switch/default lang [
									"FR" [
										{Les commandes suivantes sont disponibles dans tous les channels (salons)
'/cmd 'status word! ex: /cmd status sleeping (Change le statut de connexion)
'/cmd 'new date! ex: /cmd new 18-Jan-2006/9:00 (nouveaux messages à partir de date! GMT+13:00 sauf indication contraire)
'/cmd 'new date! ex: /cmd new 18-Jan-2006/9:00+0:00 (GMT)
'/cmd 'new time! (heure = 0:00 + 13:00)
'/cmd 'new date! 'by "userid" 'in "room"
'/cmd 'city Paris
'/cmd 'email email@address.com
'cmd 'language FR (Langue) 
'cmd 'show 'groups (Affiche tous les groupes et le nombre de messages)
     
 Les commandes suivantes sont disponibles dans mon salon :
 'help ex: help (donne ce message d'aide)
 'search word1 ... wordn ex: search whywire (recherches du texte dans toutes les URL archivées.)
     
Le bouton "Stylo" est utilisé pour faire apparaître l'éditeur de texte. Il éditera un fichier ou une URL valide trouvé dans la zone de saisie du chat. S'il n'y a aucun fichier ou URL valide, il essayera d'exécuter le contenu comme du code Rebol. 
     
Les messages sont sauvés automatiquement s'ils contiennent http, ftp:// et le mailto : 
     
 Le passage de la souris sur les boutons fait apparaître un texte d'aide dans la partie inférieure gauche de la fenêtre.
     
Un click de souris sur le texte rouge de la barre de boutons fait glisser la barre de bouton à gauche. }
									]

								] [
									{The following commands are available in any channel
'/cmd 'status word! eg: /cmd status sleeping ( changes online status )
'/cmd 'new date! eg: /cmd new 18-Jan-2006/9:00 ( new messages from date! assuming timezone GMT+13:00 unless otherwise specified )
'/cmd 'new date! eg /cmd new 18-Jan-2006/9:00+0:00 ( from GMT )
'/cmd 'new date! 'by "userid" 'in "room"
'/cmd 'new today ( from time 0:00+13:00 )
'/cmd 'timezone time! ( set time zone )
'/cmd 'city CityName
'/cmd 'email email@address.now
'/cmd 'language EN ( set language to english )
'/cmd 'show 'groups ( show all groups that have existed)

The following commands are available in my channel
'help eg. help ( gives this help message )
'search word1 ... wordn eg. search whywire ( searches for the text in any saved url )

The Pen button is used to bring up an editor.  It will edit a valid file or url found in the chatbox area.
If there is no valid file or url there, it will attempt to execute the contents as Rebol code.

Messages are saved automatically if they contain http, ftp:// and mailto:

The buttons contain mouseover help which appears bottom left.

Clicking on the red text on the button bar slides the button bar left.
}

								]




								post-msg1 channel mold/all reduce [
									'pchat
									["Eliza"]
									reduce ["Eliza" red help-msg black white [] now]
								]
							]

							true [; not a command to Eliza, so must be chatting to her
								if error? try [
									eliza-says: copy match clientmsg/3
								] [
									eliza-says: "Oops, I just had a little petit mal aka parse error."
								]
								post-msg1 channel mold/all reduce ['pchat
									["Eliza"]
									reduce
									["Eliza" red rejoin [clientmsg/1 ", " eliza-says] black white [] now]
								]
							]
						]
						return
					] [
						; not for Eliza, lets save it
						;;; remove this for no database storage
						;; save private messages

						use [private-msg err2 txt] [
							if error? set/any 'err2 try [
								private-msg: load msg/payload

								insert tail private-msg/3 now
								?? private-msg
								; need to remove the text and save that separately so that can be searched on
								txt: copy private-msg/3/3
								; and now we remove the txt from the message
								private-msg/3/3: copy ""
								; write-chat (author, CHANNEL, msg, format, ctype)
								write-chat private-msg/3/1 private-msg/2/1 txt private-msg "P"
								print "Private message saved into chat table"
							] [
								print "Insert chat message failed because..."
								probe mold disarm err2
								msg-to-all mold/all reduce ['gchat
									["lobby"]
									reduce ["Hal4000" red rejoin ["Server error on insert: " mold disarm err2] black white [bold] now]
								]
							]
						]



					]

					; now to send it on to the right person !

					; don't do anything else if the sender is also the origin
					;; need to change this to send to name of recipient instead of ip address.

					use [from-ip-port ip-port] [
						; don't send to sender if also origin
						if error? set/any 'err try [; in case username disappears?
							if userblock/1 = channel/port/user-data/username [return]
						] [
							print "Error checking if recipient is sender"
							probe disarm err
						]
						; from-ip-port: form rejoin [channel/port/sub-port/remote-ip ":" channel/port/sub-port/remote-port]
						; if from-ip-port = userblock/1 [return] ; don't send to sender if also origin
						; ip-port: parse/all userblock/1 ":"

						print ["sending private message to " userblock/1]
						foreach chan chatroom-peers [
							if error? set/any 'err try [; in case username disappears
								probe chan/port/user-data/username
								if chan/port/user-data/username = userblock/1 [
									print "found addressee"
									post-msg1 chan mold/all reduce [
										'pchat
										reduce [channel/port/user-data/username]
										clientmsg
									]

									break

								]
							] [
								print "Error sending private message to user"
								probe disarm err
							]
						]
					]

				]

				parse clientmsg ['cmd set usercmd block!] [
					print "cmd coming"
					?? clientmsg
					author: group: none
					case [
						parse usercmd ['get 'groups to end ][
							print "get groups command received"
							post-msg1 channel mold/all reduce [
										'cmd
										reduce ['groups get-channels]
							]
						]
						parse usercmd ['show 'groups to end] [
							use [group-list out] [
								group-list: get-channels-cnt
								out: copy "Unique Groups and Message counts^/"
								foreach [group cnt] group-list [
									repend out [group " " cnt newline]
								]
								post-msg1 channel mold/all reduce [
									'gchat
									["lobby"]
									reduce ["Hal4000" red
										out
										black white [] now
									]
								]

								; post-msg1 channel out

							]
						]

						; [cmd [timezone 13:00]]
						parse usercmd ['timezone set timezone [ string! | time! ]] [
							print "Timezone command received"
							use [status ip-port ndx] [
								; ip-port: form rejoin [channel/port/sub-port/remote-ip ":" channel/port/sub-port/remote-port]
								ip-port: form rejoin [channel/port/user-data/remote-ip ":" channel/port/user-data/remote-port]
								if found? ndx: find user-table ip-port [
									; ndx/3: copy userstate
									ndx/2/tz: form timezone
								]
								; update timezone for the user
								set-timezone form timezone channel/port/user-data/username
								; now update everyone
								update-room-status
							]
						]

						parse usercmd ['city set city string!] [
							use [status ip-port ndx] [
								; ip-port: form rejoin [channel/port/sub-port/remote-ip ":" channel/port/sub-port/remote-port]
								ip-port: form rejoin [channel/port/user-data/remote-ip ":" channel/port/user-data/remote-port]
								if found? ndx: find user-table ip-port [
									; ndx/3: copy userstate
									ndx/2/city: copy city
								]
								; update city
								set-city city channel/port/user-data/username
								; now update everyone
								update-room-status
							]
						]
						parse usercmd ['language set language string!] [
							use [status ip-port ndx] [
								; ip-port: form rejoin [channel/port/sub-port/remote-ip ":" channel/port/sub-port/remote-port]
								ip-port: form rejoin [channel/port/user-data/remote-ip ":" channel/port/user-data/remote-port]
								if found? ndx: find user-table ip-port [
									; ndx/3: copy userstate
									ndx/2/language: copy language
								]
								; now update everyone
								update-room-status
							]
						]
						parse usercmd ['email set email string!] [
							use [status ip-port ndx] [
								; ip-port: form rejoin [channel/port/sub-port/remote-ip ":" channel/port/sub-port/remote-port]
								ip-port: form rejoin [channel/port/user-data/remote-ip ":" channel/port/user-data/remote-port]
								if found? ndx: find user-table ip-port [
									; ndx/3: copy userstate
									ndx/2/email: copy email
									; update email
									set-email email channel/port/user-data/username
								]
								; now update everyone
								update-room-status
							]
						]
						parse usercmd ['sync set msgs-from date!] [
							?? msgs-from
							cnt: count-messages msgs-from
							if cnt = 0 [
								reply-query channel "Eliza" rejoin ["There are no messages waiting for syncing from " msgs-from]
							]
							if (cnt >= 30) [
								print ["cnt is > 30 " cnt]
								reply-query channel "Eliza" rejoin ["There are " cnt " messages waiting for syncing from " msgs-from ". Use the Quote button (next to Pen button) to paste into console"]
							]
							if all [cnt > 0 cnt < 30] [
								use [err3 err4] [
									post-msg1 channel mold/all [cmd [downloading started]]
									
									if error? set/any 'err3 try [
										foreach record get-messages msgs-from [
											;; send all the messages to the requester
											?? record
											if record/1 [
												rec: first to-block record/2
												rec/3/3: record/1
												?? rec
												; rec: [gchat ["lobby"] ["Graham" 0.0.156 "lobby message" 0.0.0 240.240.240 [] 11-Feb-2006/16:11:44+13:00]]
												either record/3 = "G" [
													post-msg1 channel mold/all rec
												] [
													; a private message - only send it if recipient is the requester
													; or origin is the requester
													; if the recipient of the private message is the requester, then change
													; so that the recipient is the sender
													if any [
														channel/port/user-data/username = rec/2/1
														channel/port/user-data/username = rec/3/1
													][
														if channel/port/user-data/username = rec/2/1 [
															rec/2/1: copy rec/3/1
														]
														post-msg1 channel mold/all rec
													]
												]
											]
										]
									] [
										print "Database retrieve error"
										probe mold disarm err3
									]
									post-msg1 channel mold/all [cmd [downloading finished]]
								] ;; end of message downlaod
							]
						]

						parse usercmd
						['new set msgs-from date! opt ['by set author [string! | word!]] opt ['in set group [string! | word!]] end] [

							; parse usercmd ['new set msgs-from date!] [
							;; retrieve all old messages
							print "New message received"
							?? msgs-from
							use [err2] [
								post-msg1 channel mold/all reduce [
									'cmd
									reduce ['downloading 'started]
								]
								if error? set/any 'err2 try [
									foreach record (get-messages-with msgs-from author group) [
										;; send all the messages to the requester
										?? record
										if found? record/1 [
											rec: to-block record/2
											rec/1/3/3: record/1
											?? rec
											; rec: [[gchat ["lobby"] ["Graham" 0.0.156 "lobby message" 0.0.0 240.240.240 [] 11-Feb-2006/16:11:44+13:00]]]
											either record/3 = "G" [
												post-msg1 channel mold/all rec/1
											] [
												; a private message - only send it if recipient is the requester
												; or origin is the requester
												; if the recipient of the private message is the requester, then change
												; so that the recipient is the sender
												if any [channel/port/user-data/username = rec/1/2/1
													channel/port/user-data/username = rec/1/3/1] [
													if channel/port/user-data/username = rec/1/2/1 [
														rec/1/2/1: copy rec/1/3/1
													]
													post-msg1 channel mold/all rec/1
												]
											]
										]
									]
								] [
									print "Database retrieve error"
									probe mold disarm err2
								]
								post-msg1 channel mold/all reduce [
									'cmd
									reduce ['downloading 'finished]
								]
							] ;; end of message downlaod
						]
						;; end of database to fetch old messages

						;; set time zone


						parse usercmd ['timezone set tzone time!] [
							use [status ip-port ndx] [
								; ip-port: form rejoin [channel/port/sub-port/remote-ip ":" channel/port/sub-port/remote-port]
								ip-port: form rejoin [channel/port/user-data/remote-ip ":" channel/port/user-data/remote-port]
								if found? ndx: find user-table ip-port [
									ndx/2/tz: form tzone
								]
								; now update everyone
								update-room-status
							]
						]

						parse usercmd ['language set lang [word!|string!]] [
							use [status ip-port ndx] [
								; ip-port: form rejoin [channel/port/user-data/remote-ip ":" channel/port/user-data/remote-port]
								ip-port: form rejoin [channel/port/sub-port/remote-ip ":" channel/port/sub-port/remote-port]
								if found? ndx: find user-table ip-port [
									ndx/2/language: form lang
								]
								; now update everyone
								update-room-status
							]
						]

						parse usercmd ['status set userstate string!] [
							; user is altering their online status
							use [status ip-port ndx] [
								; ip-port: form rejoin [channel/port/sub-port/remote-ip ":" channel/port/sub-port/remote-port]
								ip-port: form rejoin [channel/port/user-data/remote-ip ":" channel/port/user-data/remote-port]
								if found? ndx: find user-table ip-port [
									; ndx/3: copy userstate
									ndx/2/status: copy userstate
								]
								; now update everyone
								update-room-status
							]
						]
						parse usercmd ['login set nickname string!] [
							?? nickname
							; each user sends a login command with their username
							; we build up the list of active users that way
							use [ip-port username ndx chat-users tmp] [
								ip-port: form rejoin [channel/port/user-data/remote-ip ":" channel/port/user-data/remote-port]
								username: channel/port/user-data/username
								; now find the new user in the user-table
								forskip user-table 2 [
									if user-table/2/username = channel/port/user-data/username [
										user-table/1: ip-port
										user-table/2/username: channel/port/user-data/username
										user-table/2/status: "login"
										break
									]
								]

								user-table: head user-table
								comment {								
								; ip-port: form rejoin [channel/port/sub-port/remote-ip ":" channel/port/sub-port/remote-port]
								if found? ndx: find user-table ip-port [
									remove/part ndx 2
								]
								; repend user-table [ip-port nickname "active"]
								tmp: make prefs-obj [
									username: nickname
									status: "login"
								]
								repend user-table [
									ip-port tmp
								]
}
								; send a message to notify the lobby of new message
								msg-to-all mold/all reduce [
									'gchat
									["lobby"]
									reduce ["Hal4000" red
										rejoin [channel/port/user-data/username " has just entered the building."]
										black white [] now
									]
								]
								; now send an update to everyone
								update-room-status
								; now send a command to notify of new user
								msg-to-all mold/all reduce [
									'cmd
									reduce ['arrived channel/port/user-data/username]
								]

							]
							; get Eliza to acknowledge the login
							post-msg1 channel mold/all reduce [
								'gchat
								["lobby"]
								reduce ["Eliza" red
									rejoin ["Welcome " channel/port/user-data/username ". If you want to chat to me, address me by name."]
									black white [] now
								]
							]
							?? user-table
						]
					]

				]

				parse clientmsg ['action set ip-ports block! set cmdblock block!] [
					; origin-ip-port: form rejoin [channel/port/sub-port/remote-ip ":" channel/port/sub-port/remote-port]
					origin-ip-port: form rejoin [channel/port/user-data/remote-ip ":" channel/port/user-data/remote-port]
					print ["cmd: " clientmsg]
					; case [
					; cmdblock/1 = "nudge" [
					; send a nudge to all the ip-ports
					; ?? ip-ports
					foreach ip-port ip-ports [
						if 2 = length? ip-port: parse/all ip-port ":" [
							foreach channel chatroom-peers [
								if all [ip-port/1 = form channel/port/user-data/remote-ip
									ip-port/2 = form channel/port/user-data/remote-port
								] [
									; only send the action to those ip-ports listed
									post-msg1 channel mold/all reduce [
										'action
										reduce [cmdblock origin-ip-port]
									]
									print ["Sending action to" ip-port]
									;?? origin-ip-port

									; should be a unique ip-port
									break
								]
							]
						]
					]
					; ]			
					; ]
				]

				parse clientmsg ['gchat (ctype: "G") set userblock block! set clientmsg block!] [

					;chatroom-peers is empty for the initiator
					;this is only executed in the listener side
					; post-msg channel msg/payload

					; send the message immediately to all initiators
					insert back back tail msg/payload now
					msg-to-all msg/payload

					;; now save the message on the database.  not going to save Eliza's comments!
					comment {
CREATE TABLE "CHAT"
(
  "MSGDATE"	 timestamp default 'NOW',
  "AUTHOR" varchar(80),
  "GROUP" varchar(80),
  "MSG"	 VARCHAR(8192) NOT NULL
);
SET TERM ^ ;
}

					; print "Want to insert this"
					; probe msg/payload

					comment {
Want to insert this
{[gchat ["lobby"] ["Graham" 128.128.128 "this message is to be saved." 0.0.0 240.240.240 []17-Jan-2006/13:36:10+13:0
0]]}
}

					;;; remove this for no database storage

					use [public-msg err2 txt] [
						if error? set/any 'err2 try [
							public-msg: load msg/payload
							; need to remove the text and save that separately so that can be searched on
							txt: copy public-msg/3/3
							; and now we remove the txt from the message
							public-msg/3/3: copy ""
							write-chat public-msg/3/1 public-msg/2/1 txt public-msg ctype
							print "Public message saved into chat table"
						] [
							print "Insert chat message failed because..."
							probe mold disarm err2
							msg-to-all mold/all reduce ['gchat
								["lobby"]
								reduce ["Hal4000" red rejoin ["Server error on insert: " mold disarm err2] black white [bold] now]
							]
						]
					]
					;; end remove of database storage					

					print "stored .. now doing case"
					?? userblock
					?? clientmsg

					if error? set/any 'err3 try [
						case [
							all [userblock/1 = "lobby" find/part clientmsg/3 "who is here" 11] [
								use [chat-users] [
									chat-users: copy []
									foreach [ip-port name status] user-table [
										repend chat-users [name ip-port status]
										; repend chat-users [chan/port/user-data/username chan/port/user-data/remote-ip chan/port/sub-port/remote-port]
									]

									msg-to-all mold/all reduce ['gchat
										["lobby"]
										reduce
										["Hal4000" red rejoin ["Currently we have: " chat-users] black white [bold] now]
									]
								]
							]

							all [userblock/1 = "lobby" find/part clientmsg/3 "version?" 8] [
								msg-to-all mold/all reduce ['gchat
									["lobby"]
									reduce
									["Hal4000" red "Message server version 0.0.19" black white [bold] now]
								]
							]

							all [userblock/1 = "lobby" find/part clientmsg/3 "wakeup Eliza" 12] [
								eliza-on: true
								msg-to-all mold/all reduce ['gchat
									["lobby"]
									reduce
									["Eliza" red "Thanks for inviting me back." black white [] now]
								]
							]

							all [userblock/1 = "lobby" find/part clientmsg/3 "sleep Eliza" 11] [
								eliza-on: false
								msg-to-all mold/all reduce ['gchat
									["lobby"]
									reduce
									["Eliza" red "I'm off for a nap.  Just wake me if you want to chat." black white [] now]
								]
							]

							all [userblock/1 = "lobby" find/part clientmsg/3 "help Eliza" 11] [
								eliza-on: false
								msg-to-all mold/all reduce ['gchat
									["lobby"]
									reduce
									["Eliza" red "I respond to these commands: wakeup Eliza, and sleep Eliza.^/Type Help in my channel for more help!" black white [] now]
								]
							]

							all [userblock/1 = "lobby" any [eliza-on find/part clientmsg/3 "Eliza" 5]] [
								if find/part clientmsg/3 "Eliza" 5 [
									if found? msg-to-eliza: find/tail clientmsg/3 " " [
										clientmsg/3: msg-to-eliza
									]
								]

								if error? try [
									eliza-says: copy match clientmsg/3
								] [
									eliza-says: "Oops, I just had a little petit mal aka parse error."
								]
								msg-to-all mold/all reduce ['gchat
									["lobby"]
									reduce
									["Eliza" red rejoin [clientmsg/1 ", " eliza-says] black white [] now]
								]
							]

							; check to see if url hiding inside message, or, being asked to explicitly save the 
							; message.


							any [
								find clientmsg/3 "http"
								find/part clientmsg/3 "save" 4
								find clientmsg/3 "ftp://"
								find clientmsg/3 "mailto:"
							] [
								print "saving message"
								append/only chat-links load msg/payload
								attempt [
									save/all %chat-links.r chat-links
								]
							]

						]
					] [
						msg-to-all mold/all reduce ['gchat
							["Bugs"]
							reduce
							["Hal4000" red rejoin [mold disarm err3] black snow [bold] now]
						]
					]

					true [
						; unrecognised message format from client

					]
				]
			]

		]

		; set the read-rpy handler
		channel/read-rpy: func [
			{handle incoming replies}
			channel
			rpy
		] [
			;print "read-rpy handler of PUBTALK-ETIQUETTE" print mold rpy
			;display rpy
			;if rpy/payload <> 'ok [display/lost rpy]
		]

		; set the close handler
		channel/close: func [
			{to let the profile know, that the channel is being closed}
			channel
		] [
			cleanup-chatroom channel
		]
	]
	; profile helper functions
	ack-msg: func [channel] [
		send-frame/callback channel make frame-object [
			msgtype: 'RPY
			more: '.
			payload: to binary! "ok"
		] [; print "RPY sent"
		]
	]

	reply-query: func [channel from msg] [
		post-msg1 channel mold/all reduce ['gchat ["lobby"] reduce [from red msg black white [] now]]
	]

	set 'post-msg func [channel msg] [
		send-frame/callback channel make frame-object [
			msgtype: 'MSG
			more: '.
			payload: to binary! :msg
		] [; print "call to callback"
		]
	]

	set 'post-msg1 func [channel msg] [
		send-frame channel make frame-object [
			msgtype: 'MSG
			more: '.
			payload: to binary! :msg
		]
	]

	set 'cleanup-chatroom func [channel] [
		;keep the house clean, erase peer from chatroom-peers 
		remove-each peer chatroom-peers [:peer = :channel]
	]

	set 'cmd-to-all func [instruction data] [
		; send a command message to everyone in the chatroom-peers
		foreach chan chatroom-peers [
			post-msg1 chan mold/all reduce ['cmd reduce [instruction data]]
		]
	]

	set 'msg-to-all func [msg] [
		; send a text messaget to everyone in the chatroom-peers
		foreach channel chatroom-peers [
			post-msg1 channel msg
		]
	]



	set 'update-room-status func [/local chat-users tmp] [
		chat-users: copy []
		; ?? user-table
		foreach [ip-port prefsobj] user-table [
			ip-port: form ip-port
			; print ["ip-port" ip-port]
			tmp: make object! [city: prefsobj/city tz: prefsobj/tz email: prefsobj/email]
			either find ip-port ":" [
				ip-port: parse/all ip-port ":"
				repend chat-users [
					prefsobj/username
					prefsobj/status
					ip-port/1 ip-port/2
					tmp
				]
				; print "Added name and object"
			] [
				print ["bad ip port" ip-port]
			]
		]
		cmd-to-all 'set-userstate chat-users
	]

]