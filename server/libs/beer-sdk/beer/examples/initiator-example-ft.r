Rebol [
	Title: "BEER Initiator Example"
	Date: 18-Jan-2006/15:06:14+1:00
]

do %styles/my-list.r
stylize/master [
	progress: progress with [
		edge: make edge [size: 0x0 effect: none color: black]
		feel/redraw: func [face act pos][
            face/data: max 0 min 1 face/data
            if face/data <> face/state [
                either face/size/x > face/size/y [
                    face/pane/size/x: max 0 face/data * face/size/x] [
                    face/pane/size/y: max 0 face/data * face/size/y
                    face/pane/offset: face/size - face/pane/size]
                face/state: face/data
                show face/pane]]
	]
]

do %../../paths.r

; user database
users: load %users.r
groups: load %groups.r

do %encoding-salt.r
include/check %initiator.r
include/check %ft-profile.r

;set path for received files
ft-profile: profile-registry/filetransfer
if ft-profile/destination-dir: %cache-initiator/ [make-dir ft-profile/destination-dir]

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
			open-get
		] [print "login unsuccessful"]
	]
]

open-get: does [
	open-channel peer 'filetransfer 1.0.0 func [channel] [
		either channel [
			ft-get: channel
			print "Channel GET open"
			open-post
		] [print "didn't succeed to open unsecure echo channel"]
	]
]

open-post: does [
	open-channel peer 'filetransfer 1.0.0 func [channel] [
		either channel [
			ft-post: channel
			print "Channel POST open"
			do-test
		] [print "didn't succeed to open unsecure echo channel"]
	]
]


do-test: does [

	file-list: copy []
	file-keys: make hash! []
	
	comment {
	callback handler passes ACTION and DATA as an input arguments
	ACTION can be:
		INIT - when the filetransfer is initiated (client gets also filesize info if possible)
		READ - called on each received data chunk
		WRITE - all data are sent (file is fully cached on client side)
		ERROR - triggered due to any error during the transfer
	DATA is a block:
		DATA/1 - unique filename in cache [string!]
		DATA/2 - port! of cached file (used for writing during the transfer) [port!]
		DATA/3 - real filename [string!]
		DATA/4 - the calback function itself [func!]
		DATA/5 - total filesize
		DATA/6 - size of actual received file chunk
		DATA/7 - optional transfer destination directory (%cache/ by default)
	}
	callback-handler: [
		switch action [
			init [
				insert/only tail lst/data compose/deep [(data/3) [data 0 do [edge: make edge [size: 1x1] pane/color: 180.209.238]] (data/5)]
				insert tail file-keys data/1
				lst/update-list
			]
			read [
				ln: 3 * ((idx: index? find file-keys data/1) - (lst/cnt - 1)) - 1
				if bar: lst/grid/pane/:ln [
					bar/data: either data/5 = 0 [
						1
					][
						bar/data + (data/6 / data/5)
					]
					show bar
				]
				ln: pick file-list idx
				either data/5 = 0 [
					ln/2/2: 1
				][
					ln/2/2: ln/2/2 + (data/6 / data/5)
				]
			]
			write [
				;renaming/filexists? routine
				new-name: second split-path data/3
				if  exists? join data/7 new-name [
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
						not exists? join data/7 tmp-name
					]
					new-name: tmp-name
				]
				print ["rename" join data/7 data/1 "to" join data/7 new-name]
				rename join data/7 data/1 new-name
	
				;remove file from gui list
				remove at file-list idx: index? find file-keys data/1
				remove at file-keys idx
				lst/update-list
				
				;remove the all file data from handler's registry(should be done by handler automatically?)
	;			remove/part data 7
	;			ft-profile/files/remove data/1
				
			]
			error []
		]
	]
	
	post-callback-handler: [
		switch action [
			init [
				insert/only tail lst/data compose/deep [(data/3) [data 0 do [edge: make edge [size: 1x1] pane/color: red]] (data/5)]
				insert tail file-keys data/1
				lst/update-list
			]
			read [
				ln: 3 * ((idx: index? find file-keys data/1) - (lst/cnt - 1)) - 1
				if bar: lst/grid/pane/:ln [
					bar/data: either data/5 = 0 [
						1
					][
						bar/data + (data/6 / data/5)
					]
					show bar
				]
				ln: pick file-list idx
				either data/5 = 0 [
					ln/2/2: 1
				][
					ln/2/2: ln/2/2 + (data/6 / data/5)
				]
			]
			write [
				;remove file from gui list
				remove at file-list idx: index? find file-keys data/1
				remove at file-keys idx
				lst/update-list
			]
			error []
		]
	]
	
	view/new layout [
		across
		origin 5
		backcolor 0.164.158
		button "get file(s)" [
			lst/update-list
			get-file/dst-dir ft-get request-file callback-handler dirize to-rebol-file dst-dir/text
		]
		button 150 "get ALL in script dir" [
			lst/update-list
			get-file/dst-dir ft-get read %. callback-handler dirize to-rebol-file dst-dir/text
		]
		text "dest. dir:"
		dst-dir: field 120 "cache-initiator/"
		return
		button "post file(s)" [
			post-file ft-post request-file post-callback-handler
		]
		button 150 "post ALL in script dir" [
			post-file ft-post read %. post-callback-handler
		]
		clk: banner 150 rate 25 with [
			feel: make feel [
				engage: func [f a e][
					if e/type = 'time [
						clk/text: now/time/precise
						show clk
					]
				]
			]
		]
		return
		lst: my-list -1x400 columns [
			text 150x16
			progress 200x16
			text 100x16
		]
		line-colors reduce [white 232.236.241]
		data file-list
		rowbar ["file" "progress" "total size"]
	]
]

do-events
halt
