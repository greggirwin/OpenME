Rebol [
	title: "OpenME chat Server"
	authors: [
		GC  "Graham Chiu"            ; Original Synapse Chat developper
		MOA "Maxim Olivier-Adlhoch"  ; OpenME server refactoring
	]
	copyright: "© 2005-2012, Graham Chiu"
	date: 2012-02-25
	version: 0.0.7
	encap: [ title "OpenME Server v0.0.7 " quiet secure none]
	requires: [view 2.7.8 SDK 2.7.8]
	
	license: 'BSD
	
	
	changes: {
		30-Dec-2005 added chat server functions.
		3-Oct-2005 specialty
		2-Oct-2005 gps
		25-Sep-2005 appts
		23-Sep-2005 delete problem, tickler
		22-Sep-2005 add-problem, add-tickler, add-diagnosis
		21-Sep-2005 add-consult
		
		2012-02-24 - v0.0.4 - MOA
			-Start of work to adapt synapse chat server for OpenME project
			-refactored the code so it doesn't need encapping for now (it currently requires REBOL/View)
			-now depends on a formal directory structure, all paths being local to the server script.
			-Added a note for running firebird on 64 bit windows (using 32 bit FireBird and ODBC drivers).
			-Added button to start 32 bit ODBC manager, since it doesn't have any OS start menu access in 64 bit windows 7.
			
		2012-02-25 - v0.0.5 - MOA
			-Separated the DB code from the main app
			-defined DB API as functions in the db module which are prefixed with db-
			-added configuration file support and unified application config using configurator module.
			-rebuilt the database detection and user dialogs on startup.
			
		2012-02-28 - v0.0.6 - MOA
			-further db extraction
			-ZOMBIE Code identification..  will have to be tested without. (just search for zombie, you'll see everywhere its tagged)
			-A few Fixes reported by users.
			-Renamed config file to %OpenME-server.cfg
			-added error traping on running server.  We can now open up a dialog on known errors.
		
		2012-03-12 - v0.0.7 - MOA
			-db-configuration is now extended within the db layer itself.
			-
	}
	
	notes: {
		-an encap setup will be rebuilt later, for now we need this to be usable by
		 any rebol user for quick testing and multi-user collaboration.
	}
]

;-----------------------------------------------
;
;- GLOBAL VALUES
;
;-----------------------------------------------
; ALL globals are used uppercase, to clearly identify them
; within code.
;
; this should be applied in all modules used by OpenME.
;-----------------------------------------------

DEBUG?: FALSE
;DEBUG?: TRUE 

SERVER-VERSION: system/script/header/version

EXPIRY-DATE: either DEBUG? [
	now - 1 ; we just force the expiry all the time in order to show the update requestor while in dev.
][
	2013-01-01
]

CONFIG: none
CONFIG-PATH: %OpenME-server.cfg

LINES: "^/^/"




;-----------------------------------------------
;
;- LIBS 
;
;-----------------------------------------------
;#include %/d/sdk2.6/source/prot.r
;#include %/d/sdk2.6/source/view.r
;-----------------------------------------------

do %libs/slim.r

cfg-lib:  slim/open/expose 'configurator	none	[configure]
db-lib:   slim/open/expose 'OpenME-db		none	[
	; low-level functions
	db-connect db-stop db-connected? db-error? db-do db-get
	
	; OpenME high-level abstractions
	db-get-user-count
	
	; configuration stuff
	db-configured? db-set-config db-interactive-setup db-extend-configuration db-reset-configuration db-user-setup 
]



; do not show verbosity by default. uncomment to show library verbosity on startup
;db-lib/von
;cfg-lib/von
slim/vexpose
von



do %libs/beer-sdk/libs/aa.r
do %libs/beer-sdk/libs/catch.r
do %libs/beer-sdk/libs/iatcp-protocol.r

do %encoding-salt.r  ; we now use the salt which is local to the OpenME server script.

do %libs/beer-sdk/beer/channel.r
do %libs/beer-sdk/beer/frameparser.r
do %libs/beer-sdk/beer/frameread.r
do %libs/beer-sdk/beer/framesend.r
do %libs/beer-sdk/beer/session-handler.r
do %libs/beer-sdk/beer/authenticate.r
do %libs/beer-sdk/beer/profiles.r


do %libs/beer-sdk/beer/examples/echo-profile.r
do %libs/beer-sdk/beer/initiator.r
do %libs/beer-sdk/beer/listener.r
do %libs/beer-sdk/beer/profiles/rpc-profile.r

do %libs/beer-sdk/beer/profiles/ft-server-profile.r  ; custom profile to upload from %chat-uploads/

;do %libs/beer-sdk/beer/profiles/pubtalk-profile-new.r
do %pubtalk-profile-new.r

do %libs/shrink.r ; (for now, this is just for fun) we will probably review this decision and improve it to make it actually helpful.

do %libs/beer-sdk/beer/authenticate.r

;-----------------------------------------------
;
;- CONFIGURATION
;
;-----------------------------------------------
; we use the configurator module to build a managed object which has
; a lot of integrated power like file i/o, defaults, save points.
;-----------------------------------------------
CONFIG: configure compose [
	root-dir:	(clean-path what-dir)	"Path the application is launched from."
	unattended?: #[false]				"is this server running without any user attention?^/when true, will fail on errors instead of trying to get user attention."
]

CONFIG/app-label: rejoin ["OpenME/server v" system/script/header/version]

; if the db stuff was setup before, it will allow the server to startup directly,
; otherwise, the server will open up setup panes.
db-set-config CONFIG

; this will add db library configurations to the default configs.
; if we have a config on disk, these items will be reloaded from disk.
;
; even though they aren't part of the application configs!  This is one 
; of the powerful uses of the configurator module.
db-extend-configuration

; load all configuration from disk (if it really exists).
CONFIG/from-disk/using CONFIG-PATH




;----------------------------------------------------------------------------------------------
;
;- VID Stylesheet
;
;----------------------------------------------------------------------------------------------
; all the GUI stuff should eventually be externalized into a separate application which is used
; to control the server.
;----------------------------------------------------------------------------------------------
STYLIZE/master [
	Banner: BOX edge none 600x85 %libs/images/OpenME-banner_server.png effect none
	field: field edge [color: gray effect: 'ibevel size: 1x1]  with [size/y: 20]
	info: info left wrap 580  edge none
] 


	





;-----------------------------------------------
;
;- FUNCTIONS (Utilities)
;
;-----------------------------------------------

;--------------------------
;-     calcMD5()
;--------------------------
; notes:    seems like this is zombie code
;--------------------------
calcMD5: func [ binData ] [
	return enbase/base checksum/method binData 'md5 16
]


;--------------------------
;-     newer-OpenME-version?()
;--------------------------
; purpose:  check if there is an stable release update to the OpenME project
;
; notes:    This is a temporary functionality, inherited from Synapse chat, we will
;           revise how this works, probably by adding a config option to allow user and auto-updates.
;
;           we will probably have a file on the OpenME web site which stores the latest version
;           so it can be compared and this function return something more accurate.
;
;			for now we just see if its old or not, yeah crappy I know.
;--------------------------

newer-OpenME-version?: func [][
	now/date > EXPIRY-DATE
]





;-----------------------------------------------
;
;- FUNCTIONS (OS analysis)
;
;-----------------------------------------------

;--------------------------
;-     is64BitWindows?()
;--------------------------
; purpose:  quick and dirty way to detect if the current OS is running in 32 or 64 bits.
;
; returns:  true/false
;
; notes:    may be flawed, but seems to work so far.
;           can be hacked if system setup is deeply altered
;
;--------------------------
is64BitWindows?: func [][
	;found? get-env "CommonProgramFiles(x86)"
	exists? to-rebol-file rejoin [get-env "%windir%" "\SysWOW64\"]
]





;-----------------------------------------------
;
;- FUNCTIONS (User Interface, text or graphical)
;
;-----------------------------------------------

;--------------------------
;-     request-update()
;--------------------------
; purpose:  popup a dialog to ask for an application update
;
; notes:    This is a temporary functionality, inherited from Synapse chat, we will
;           revise how this works, probably by adding a config option to allow user and auto-updates.
;
;			In this prototypish release, when DEBUG? is enabled, it always shows the requester... just to
;           test it.
;--------------------------
request-update: funcl [
][
	continue?: false
	vin "request-update()"
	
	if all [
		not CONFIG/get 'unattended?
		newer-OpenME-version? 
	][
		view center-face layout compose [
			across
			origin 0x0
			
			backdrop white
			banner 300
			return
			
			origin 10x10
			pad 0x100
			
			text 280 "New version of OpenME released! Check the website for release nots and download links:" bold font [ size: 14 shadow: none ] wrap
			return
			
			(
				; compose is handy to have VID items conditionally.
				either DEBUG? [
					[
						return
						;pad 30
						text 280 red font [size: 10] "Note: this was opened automatically because we are in DEBUG mode, your version might actually be up to date"
						return
					]
				][
					; compose strips empty blocks, so we just return an empty block and nothing is added to the VID block.
					[]
				]
			)
			
			pad 0x20
			btn 280 "Check OpenME Website" [ browse https://github.com/greggirwin/OpenME ]
			
			return
			pad 70x30
			btn "Continue" 70 [ unview continue?: true]
			btn "quit" 70 [quit]
			
			origin 0x20
		]
		unless continue? [
		   quit
		]
	]
	vout
]



;--------------------------
;-     display()  <ZOMBIE?>
;--------------------------
display: func[v][
	print ["display:" mold v]
]


;
;;--------------------------
;;-     first-time-setup-dialog()
;;--------------------------
;first-time-setup-dialog: funct [][
;	continue?: false
;	; probe mold disarm err
;	; print "Fatal error - unable to open odbc connection to remr database"
;	; halt
;	view center-face layout [
;		across
;		h1 "Synapse Chat Server" red return
;		h2 "First Time Install?" return
;		info 350x160 wrap (rejoin [
;			"This screen has appeared as we can not open a connection to the database."
;			LINES
;			"This could be because another copy of the program is running, or you have yet to install the Synapse Chat Server."
;			LINES
;			"If the latter is correct, you need to download the Firebird Database software, the Firebird ODBC connector, and the chat database."
;		])
;		return
;		pad 250 
;		btn "Proceed" [ continue?: true unview ] 
;		btn "Quit" [ quit ]
;		
;		unless continue? [
;		   quit
;		]
;	]
;]







;--------------------------
;-     add-user-dialog()
;--------------------------
; purpose:  create users
;
; inputs:   
;
; returns:  true on success false otherwise
;
; notes:    
;
; tests:    
;--------------------------
add-user-dialog: funcl [
	/admin "add an admin user"
	/quit-mode "when set the cancel button is replaced by a quit button."
][
	vin "add-user-dialog()"
	success?: false
	error: none
	either debug? [
		fld-default:  "12345678"
	][
		fld-default: ""
	]
	
	either admin [
		usr-lvl: 5
		query: {insert into USERS (userid, rights, fname, surname, reminder, answer, email, gender, pass, activ ) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)}
		ACTIV: "T"
		gui-title: "Create Admin user"
	][
		usr-lvl: 0
		query: {insert into USERS (userid, rights, fname, surname, reminder, answer, email, gender, pass, pwd ) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)}
		ACTIV: none
		gui-title: "Add new user"
	]
	
	gui: layout compose [
		style text text 100 right
		
		backdrop white
		across
		
		origin 0x0
		banner 450
		
		origin 30x10
		pad 0x90
		
		h2 gui-title
		return

			
		pad 0x20
		text "Username" 
		adminfld: field (copy fld-default)
		return
		
		text "Password"
		passfld: field (copy fld-default)
		text {(Min. 8 characters)} left font [size: 10]
		return
		
		text "Given Name" 
		fnamefld: field (copy fld-default)
		return
		
		text "SurName"
		snamefld: field  (copy fld-default)
		return 
		
		
		text "Gender" 
		genderfld: field "M" 20 
		return
		
		text "Email" 
		emailfld: field  (copy fld-default)
		return
		
		text "Secret Question" 
		secretfld: field  (copy fld-default)
		return
		
		text "Answer" 
		answerfld: field  (copy fld-default)
		return
		
		pad 150x20
		btn "Create" [
			either all [
				not empty? adminfld/text 
				not empty? passfld/text 
				not empty? fnamefld/text 
				not empty? snamefld/text 
				not empty? genderfld/text 
				not empty? secretfld/text 
				not empty? answerfld/text 
				(length? passfld/text) > 7 
			][
				; should be abstracted as db-add-user()
				either db-do reduce [
					(query)
					adminfld/text 
					usr-lvl
					fnamefld/text 
					snamefld/text 
					secretfld/text 
					answerfld/text 
					emailfld/text 
					genderfld/text 
					form encode-pass passfld/text encoding-salt 
					any [
						activ ; ACTIV is only setup for admin
						passfld/text
					] 
				][
					;---------------------------
					; no errors all went well
					hide-popup
				][
					;---------------------------
					; report error
					error: db-error?
					v?? error

					if find error "violation of PRIMARY or UNIQUE KEY" [
						alert "This username is already in use"
					]
					vprint "A sql error occurred - see console for explanation"				
				]
			  	
			][
				alert "All fields need to be filled in and password must be 8 characters or more"
			]
		]
		
		(
			either quit-mode [
				[btn "Quit" [ quit ]]
			][
				[btn "Cancel" [hide-popup]]
			]
		)
		origin 0x20
		
		do [ focus adminfld ]
	]
	
	show-popup gui
	
	do-events ; block until the popup closes
	

	vout
	
	success?
]

		
		
		





;set path for received files


profile-registry

ft-profile: profile-registry/filetransfer
if ft-profile/destination-dir: %chat-uploads/ [make-dir ft-profile/destination-dir]


file-list: copy []
file-keys: make hash! []

debug: :none





;-----------------------------------------------
;
;- FILE TRANSFER HANDLER
;
; set callback handler for POST on server
;-----------------------------------------------
ft-profile/post-handler: [
	switch action [
		init [
		]
		read [
		]
		write [
			;renaming/filexists? routine
			if not exists? join data/7 channel/port/user-data/username [
				attempt [
					make-dir/deep join data/7 channel/port/user-data/username
				]
			]

					new-name: second split-path data/3
			either  exists? to-file rejoin [ data/7 channel/port/user-data/username "/" new-name ][
				print "file exists! changing name..."
				nr: 0
				until [
					nr: nr + 1
					either find tmp-name: copy new-name "." [
						insert find/reverse tail tmp-name "." rejoin ["[" nr "]"]
					][
						insert tail tmp-name rejoin ["[" nr "]"]
					]
					tmp-name: replace/all tmp-name "/" ""
					not exists? to-file rejoin [ data/7 channel/port/user-data/username "/" tmp-name ]
				]
				new-name: to-file rejoin [ channel/port/user-data/username "/" tmp-name ]
			][
				new-name: to-file rejoin [ channel/port/user-data/username "/" new-name ]
			]

			print ["rename" join data/7 data/1 "to" new-name ]
			if error? set/any 'err try [
				change-dir data/7
				; PROBE (to-file DATA/1)
				; PROBE  NEW-NAME
				rename (to-file data/1) new-name
				change-dir %../
			][
				print "Renaming failed"
				probe mold disarm err
			]

			msg-to-all mold/all reduce [
				'gchat
				["Files"]
				reduce ["Hal4000" red
				rejoin [ form last split-path new-name " has just been uploaded by " channel/port/user-data/username]
				black white [] now
				]
			]
			attempt [
				probe channel/port/user-data/username
			]

			;; save into database
			]
			error []
		]
	]
	ft-profile/get-handler: func [channel action data][
		switch action [
			init [
 ;               print ["start sending file" data/3 "of size" data/5 "to listener."]
			]
			read [
 ;               print ["sending datachunk of file" data/3 "of size" data/6 "bytes"]
			]
			write [
				print ["file" data/3 "has been completely sent to initiator"]
			]
		]
	]




;-----------------------------------------------
;
;- <ZOMBIE CODE ALERT> (MOA)
;
; don't know why the original chat included files midway into the app, 
; possibly irrelevant.
;
; <deprecated> waiting for a few releases to make sure this really wasn't needed
;-----------------------------------------------
;do %libs/beer-sdk/beer/authenticate.r

;-------------
; <NOTES: MOA>
;
; don't know why the following file is executed a second time, but it seems like its required (removing it broke logins).
; seems like it was just a bogus problem ... it seems to work now.
;
; <deprecated> waiting for a few releases to make sure this really wasn't needed
;-------------
;do %encoding-salt.r





;-----------------------------------------------
;
;- SERVER STARTUP
;
;-----------------------------------------------

; check if the server is really up to date
request-update









;-----------------------------------------
;-     -database initialisation
;-----------------------------------------
until [
	unless db-configured? [
		vprint "Not configured yet"
		either CONFIG/get 'unattended? [
			print [
				"OpenME server - ERROR: DB connection not properly setup"
				LINES
				"server is running in unattended mode, sysadmin must setup the " to-local-path CONFIG-PATH " file before starting server."
			]
			CONFIG/to-disk
			quit
		][
			; we have to configure the server, it has not been done yet
			db-interactive-setup
			CONFIG/to-disk
		]
	]
	
	unless db-connect [
		; if we where not able to connect, reset the config so that we don't attempt it again.
		; in this loop, it will cause the user-configuration to popup (again?) or the server to quit when unattended.
		db-reset-configuration
	]
		
	; don't try to start the server, until we know the ODBC connection is properly setup.
	db-connected?
]

;-----------------------------------------
;-     -build admin user if none exist
;-----------------------------------------
if all [
	users: db-get-user-count 
	users = 0
][
	; create the new admin user.
	add-user-dialog/admin/quit-mode
]


;--------------------------------------------------------------------------------
;
;  DB ABSTRACTION WILL RESUME HERE 
;
;--------------------------------------------------------------------------------
; the following is just to get the server working for now...
; 

db-port: db-lib/DB-PORT
dbase: db-lib/DBASE

;--------------------------------------------------------------------------------
; load user groups rights

groups: load %user-rights.r





;--------------------------
;-     build-userfile()
;--------------------------
; purpose:  really have no clue.  <ZOMBIE?>
;
; inputs:   none
;
; returns:  the user list
;
; notes:    it seems that this function sets a global value called USERS 
;           but its not used ANYWHERE in the server... is this used deep within BEER?
;
; tests:    
;--------------------------
build-userfile: funcl [
	/extern users
][
;	users: load {"anonymous" #{} nologin [anonymous]
;	"listener" #{} nologin [monitor]
;	"root" #{F71C2F645E81504EB9CC7AFC35C7777993957B4D} login [root]
;	}
	USERS: copy/deep [
		"anonymous" #{} nologin [anonymous]
		"listener" #{} nologin [monitor]
		"root" #{F71C2F645E81504EB9CC7AFC35C7777993957B4D} login [root]
	]

	;usrs: db-user-list
	
	insert db-port {select userid, pass, rights from users where activ = 'T'}

	foreach record copy db-port [

		switch/default record/3 [
			0 [ security: to-word "anonymous" ]
			1 [ security: to-word "chatuser" ]
			5 [ security: to-word "root" ]
		][ security: to-word "root" ]
		repend USERS compose/deep [ record/1 load record/2 'login [ (security) ]  ]

	]
	vout
]


;-----------------------------------------------
;
;- MAIN CONTROL PANEL
;
;-----------------------------------------------
build-userfile


attempt [
	view/new layout [
		backdrop white
		across
		
		origin 0x0
		banner 300
		
		origin 30x10
		pad 0x90

		h2 "OpenME Chat control panel"  
		return
		
		btn "Shut down" [ db-stop quit ] 
		btn "Add User" [ add-user-dialog ]
		btn "Reload Users" [build-userfile]
		
		return
		btn "Toggle Console Verbosity" [
			either slim/verbose [
				print "----------------------------------------"
				print "Console verbosity disabled"
				print "----------------------------------------"
				
				voff
				db-lib/voff
			][
				print "----------------------------------------"
				print "Console verbosity enabled"
				print "----------------------------------------"
				von
				db-lib/von
			]
		] 
		return
		
		pad 0x20
		text 230 wrap as-is (
			rejoin [
				{Be sure to use the "Shut down" button in this control panel to avoid database corruption.  }
				LINES
				{Closing this window, or the console, in any other way may have unpredictable effects on the database.}
				LINES
				{Both will shut the server down.} 
			]
		)
		
		origin 0x20
	]
	
]





; sessions: copy []
timeout: 00:20:00 ; 20 mins
ftimeout: 00:05:00 ; 5 mins
invalid-session: "Logged out due to inactivity"

fileCache: copy []

session-object: make object! [ sessionid: userid: timestamp: ipaddress: security: lastmsg:  none ]

default-user: make object! [
	name: "Portal Administrator"
	email: no-one@nowhere.com
	smtp: none
	timezone: now/zone
	port: 8012
]

userobj: default-user

; enterLog "Restart" "Admin" "Normal start" <ZOMBIE?>

basic-service: make-service [
	info: [
		name: "basic services"
	]
	services: [time info registration maintenance]
	data: [
		info [
			service-names: func []	[
				services
			]
		]
		time [
			get-time: func []	[
					now/time
			]
		]
		registration [
			register-user: func [ userid pass fname sname gender email secret answer 
				/local err result 
			][
				print [ userid pass fname sname gender email secret answer  ]
				if error? set/any 'err try [
					pwd: form encode-pass pass encoding-salt
					activ: "F"
					insert db-port [{insert into USERS (userid, rights, fname, surname, reminder, answer, email, gender, pass, activ, pwd ) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)} userid 1 fname sname secret answer email gender pwd  "F" pass]
					attempt [
							send compkarori@gmail.com join "New user registration on OpenME Chat: " userid
					]
					attempt [
						send/subject to-email email 
							rejoin [ "You registered with the chat server as follows - user: " userid " password: " pass "^/both if which are case sensitive. ^/You will be contacted once your account is enabled." ] {Chat registration details}
					]
					return reduce [ true ]
				][ 
					probe mold err: disarm err

					if find err/arg2 "violation of PRIMARY or UNIQUE KEY" [
						return [ -1 "This username is in use" ]
					]
					return [ -1 "sql error in add-user" ]
				]
			]

		]

		maintenance [
			show-users: func [/local result][
				result: copy []
				insert db-port {select uid, userid, fname, surname, email, activ from users}
				foreach record copy db-port [
					append/only result record
				]
				return result
			]

			delete-user: func [ uid [integer!] ][
				insert db-port [{delete from users where uid = (?)} uid ]
				return true
			]
			disable-user: func [ uid [integer!] ][
				insert db-port [{update users set activ = 'F' where uid = (?)} uid ]
				return true
			]
			enable-user: func [ uid [integer!] ][
				insert db-port [{update users set activ = 'T' where uid = (?)} uid ]
				return true
			]
			update-password: func [ uid password ][
				insert db-port [{update users set pass = (?), pwd = (?) where uid = (?)} encode-pass password encoding-salt password uid ]
				return true
			]
			rebuild-users: does [
				build-userfile
				return true
			]

			restart-server: does [
				print "Client requesting a server restart"
				db-stop
				; quit
				launch/quit ""
			]
			get-dir: func [ dir [file!] /local files filedata][
				probe dir
				either dir = %./
				[ files: read dir: ft-profile/destination-dir]
				[
					if error? try [
						probe  join ft-profile/destination-dir second split-path clean-path dir
						files: read dir: join ft-profile/destination-dir second split-path clean-path dir
					][
						files: copy []
					]
				]
				filedata: copy []
				foreach file files [
					inf: info? join dir  file
					repend/only filedata [file inf/size inf/date]
				]
				return filedata
			]
			file-exists?: func [ file ][
				return either exists? to-file join %chat-uploads/ file [ true ] [ false ]
			]
			delete-file: func [filename][
				either exists? join %chat-uploads/ filename [
					 if error? try [
						delete join %chat-uploads/ filename
						return "File deleted"
					 ][
						return "Unable to delete file"
					 ]

				][
					return "File does not exist"
				]
			]
		]
	]
]

publish-service basic-service

; This is for the 'L side:

; chat-users: copy []

if error? server-error: try [
	open-listener/callback userobj/port func [peer] [
		use [remote-ip remote-port peer-port ip-port] [
	
			print ["New mate on the bar" peer/sub-port/remote-ip peer/sub-port/remote-port]
			peer-port: :peer
			peer/user-data/on-close: func [msg /local channel] [
				print ["Mate left" peer-port/user-data/username peer-port/user-data/remote-ip peer-port/user-data/remote-port "reason:" msg]
				; clean up by removing disconnected clients
				msg-to-all mold/all reduce ['gchat
											["lobby"]
											reduce
											["Hal4000" red rejoin [peer-port/user-data/username " has just left the building"] black white [] now]
										]
				if error? set/any 'err try [                       
					insert db-port [ {update USERS set laston = 'NOW' where userid = (?)} peer-port/user-data/username ]            
				][
					probe mold disarm err
				]            
				print ["before removal users: " length? chatroom-peers]
					use [chat-users temp-table] [
					; first remove disconnected clients 
					forall chatroom-peers [
						if chatroom-peers/1/port/locals/peer-close [
							remove chatroom-peers
						]
					]
					rebuild-user-table
				]
			]
		]
	]
	print [ "OpenME chat Server " server-version " serving .... on port " userobj/port ]

	
	do-events

][
	;-------------------------------------------------------------------
	;
	;- SERVER FAILURES REPORTING
	;
	;-------------------------------------------------------------------
	server-error: mold disarm server-error
	error-msg: none
	
	;--------------------
	;-     Identify Known errors
	;--------------------
	CASE [
		;-----------------------------------
		; Can't open BEER listening port
		all [
			find server-error "listener: open/binary/direct/no-wait"
			find server-error "port-id: beer-port-id"
		][
			error-msg: "Another server application is already listening on TCP Port 8012, maybe you already launched OpenME/server ?"
		]
		
		;-----------------------------------
		; Trap other errors here:
		;-----------------------------------
		
	]
	
	;--------------------
	;-     Report errors
	;--------------------
	either error-msg [
		;--------------------
		;-         -Known errors
		;--------------------
		either CONFIG/get 'unattended?  [
			vprint/always "-------------------------------"
			vprint/always "ERROR in OpenME Server :"
			vprint/always "-------------------------------"
			vprint/always error-msg
		][
			show-popup center-face layout [
			
				backdrop white
				across
				
				origin 0x0
				banner 300
				
				origin 30x10
				pad 0x90
				
				h2 "ERROR!"
				return
			
				pad 15x0
				text 250 as-is error-msg
				return
				
				pad 100x20
				btn "Quit" [quit]
				
				origin 0x20
			]
			do-events ; makes the popup modal and makes sure the event loop wasn't mangled by the error itself.
			quit
		]
	][
		;--------------------
		;-         -Unknown errors
		;--------------------
		vprint/always "-------------------------------"
		vprint/always "ERROR in OpenME Server :"
		vprint/always "-------------------------------"
		vprobe/always server-error
		if not CONFIG/get 'unattended? [
			ask "^/^/press Enter to Quit..."
		]
		quit
	]
]


quit





