REBOL [
	Title: "AltMe Reader"
	Author: ["Allen Kamp" "Carl Sassenrath"]
	Version: 1.0.16
	Type: 'link-app
	Copyright: "2001 REBOL Technologies"
	History: [1-Dec-2002 "Sent in bulldozers and rebuilt upon Messenger.r foundations" "Allen"]
	Notes: {
		Slow and locks up on some reads. Something in the msg object creation is far too expensive.
		Still quite messy, lots of old messenger code floating around. Users don't work yet only groups
	}
]

unprotect 'cc

;--- ALTME READER 
world: 'rebol

groups: copy []
msgs:   copy []

; Prefs - AK
prefs-file: %reader-prefs.r
;default prefs
prefs: context [offset: 100x100 font-size: 12 size: 600x400 altme_path: %/d/altme/worlds/] 
load-prefs: does [error? try [prefs: make prefs load/all prefs-file]]
save-prefs: does [error? try [save prefs-file third prefs]]

prefs-face: layout [
	origin 8 space 4x4
	backcolor 230.230.230
	h3 "Set AltMe Preferences"
	at 74x34
	panel 300x148 [
		across
		origin 10
		txt "Message text font size:" ck5: field 32x22 center
	] bevel
	at 8x58
	btn-enter 60 "Save" [save-checks]
	btn-cancel 60 "Cancel" [unview/only prefs-face]
]

view-prefs: does [
	ck5/text: form fontsize 
	view/new/title center-face/with prefs-face m1/main-lay "Preferences"
]

save-checks: does [
	n: fontsize
	error? try [n: to-integer ck5/text]
	prefs/font-size: max 8 min 24 n
	save-prefs
	notify "Restart AltMe Reader to View Changes."
	quit
]

load-prefs
;if not exists? prefs-file [save-prefs]
fontsize: any [prefs/font-size 11]
altme_path: prefs/altme_path

; get rid of the first item in the list; it's special.
groups: remove load/all rejoin [altme_path world "/users.set"] [
    append/only either find item/6 'group [groups][users] item
]

group-names: copy []
user-names: copy []

lookup-names: copy []
lookup-id: copy []
all-msgs: copy []

;-- example msg
altme: [2978 29-Nov-2002/11:29:26-8:00 2 31 53.166.0 0 [] "but maybe now i can be back to red..."]
msg-obj: context [to: from: when: group: color: content: fx: file: none]


foreach item groups [
	; build a look number and name pairs
    append lookup-names compose [(item/1) (item/3)]
	append lookup-id compose [(item/3) (item/1)]
	append either find item/6 'group [group-names][user-names] item/3
]

sort group-names
sort user-names

load-user-list: does [
	user-list: copy []
	foreach name user-names [
		uppercase/part name 1
		append user-list compose [(name) [0 0]]
	]
]

load-group-list: does [
	user-list: copy []
	foreach name group-names [
		uppercase/part name 1
		append group-list compose [(name) [0 0]]
	]
]


load-msgs: func [msg-set /local msg file files][

	msgs: copy []
	msg-set: select lookup-id msg-set
	file: rejoin [altme_path world "/chat/" msg-set ".set"]
    ; get rid of the first item in the list; it's special.
    files: either exists? file [remove load/all file][copy []]
	foreach file files [
		if not error? err: try [
			msg: make msg-obj compose [
				when: (file/2)
				from: (select lookup-names file/4)
				to: (u-name)
				group: (select lookup-names msg-set)
				color: (file/5)
				content: (file/8)
			]
		][
			append msgs msg
		]
	]
	msgs
]

; ---- / READER


shut: func [face] [unview/only face]

user-here: []
group-list: []
u-name: g-name: none
msg-files: []
;all-msgs: []
my-name: uppercase/part user-prefs/name 1


load-group-list: does [
	;if error? try [
	;	group-list: first load/all link-root/system/groups.r
	;][
	;group-list: copy []
	group-list: group-names
	;]
]

load-user-list
load-group-list

;------ Message Window:

ctx-msgr: [

spacer: 2
spacer-color: coal

fontsize: any [prefs/font-size 11]

the-files: copy []
tp1: tp2: tp3: tp1w: tp3s:
lb: bx: bb: cx: s1: tb: sb: cb: ax: s2: gr: ng: none
high: 0

send-lay: layout [
	across
	origin 4x2 space 4
	tb: text "Pick a User or Group" font-size 11 200x22 middle bold
	sb: btn "????"  50 250.220.100 [notify "Function Disabled"]
	cc: btn "????" 50 [notify "Function Disabled"]
	cb: btn "????" 50 [notify "Function Disabled"]
]

l1: l2: u-lst: u-sld: g-lst: g-sld: u-item: u-blk: none

pick-user: func [user /local db][
	if none? user [exit]
	s1/data: 1.0  ; put scroller back to bottom
	filter-msgs u-name: user
	tb/text: rejoin ["Messaging with " uppercase/part copy user 1]
	show tb
]

pick-group: func [group /local db][
	if none? group [exit]
	s1/data: 1.0  ; put scroller back to bottom
	filter-msgs g-name: group
	tb/text: rejoin ["Messaging with " uppercase/part copy group 1]
	show tb
]


htmlize: has [html emit fl] [
	html: make string! 50000
	emit: func [data] [append html reduce data]
	emit {<HTML><BODY>}
	emit ["<H2>Message List as of " now/date " " now/time </H2><P>]
	emit <TABLE BORDER=1 CELLSPACING=0 CELLPADDING=2 WIDTH="100%">
	foreach msg message-list [
		emit [
			<TR>
			<TD WIDTH="8%" ALIGN="CENTER"><B> msg/from </B></TD>
			<TD> msg/content </TD>
			<TD WIDTH="10%" ALIGN="CENTER"><FONT SIZE=1> msg/when/date <BR> msg/when/time </FONT></TD>
			</TR>
		]
	]
	emit {</TABLE></BODY></HTML>}
	write %tmp-html.html html
	browse %tmp-html.html
]

main-lay: layout [
	style lab text 120x16 snow black font-size 11 bold
	origin 0x0 space 0x0
	lb: logo-bar
	at 2x2 btn-help
	at 2x25 btn-help "P" olive [view-prefs]
	at 2x48 btn-help "H" gold - 40 [
		if confirm "Show this message list as printable HTML?" [htmlize]
	]
	across origin 24x0
	return
	l1: lab "Users" return
	u-lst: list 104x200 [
		origin 0
		text 104x15 feel none font-size 11 [pick-user value]
	] supply [
		count: count + ucnt
		face/color: snow
		face/font/color: black
		face/text: none
		if not tail? u-item: skip user-list count - 1 * 2 [
			u-blk: u-item/2
			if u-blk/1 > u-blk/2 [face/font/color: red - 80]
			if u-name = (face/text: u-item/1) [face/color: yellow + 100]
			face/font/style: either find user-here face/text ['bold][none]
		]
	]
	u-sld: scroller 16x200 [
		nn: max 0 to-integer (length? user-list) / 2 - ulst-high * value
		if ucnt <> nn [ucnt: nn show u-lst]
	]
	return


	l2: lab "Groups"
	return
	g-lst: list 104x200 [
		origin 0 text 104x15 font-size 11 [pick-group value]
	] supply [
		count: count + gcnt
		face/color: snow
		face/font/color: black
		face/text: none
		if not tail? g-item: skip group-list count - 1 * 2 [
			g-blk: g-item/2
			if g-blk/1 > g-blk/2 [face/font/color: red - 80]
			if g-name = (face/text: g-item/1) [face/color: yellow + 100]
			face/font/style: either find user-here face/text ['bold][none]
		]
	]
	g-sld: scroller 16x200 [
		gnn: max 0 to-integer (length? group-list) / 2 - glst-high * value
		if gcnt <> gnn [gcnt: gnn show g-lst]
	]

	return	
	at l1/offset + 120x0
	cx: box 420x300 coal edge [size: 2x2 color: coal]
	s1: scroller 16x300 [scroll-msg/only value]
	return
	bb: box 420x26 230.230.230
	return
	ax: area 420x56 wrap snow snow [send-msg]
	s2: slider 16x56
	origin
]

deflag-face ax 'tabbed
deflag-face ax 'on-unfocus

ulst-high: u-lst/size/y / u-lst/subface/size/y
u-sld/step: 2 / max 1 (length? user-list) / 2
u-sld/redrag ulst-high / max 1 (length? user-list) / 2

glst-high: g-lst/size/y / g-lst/subface/size/y
g-sld/step: 2 / max 1 (length? group-list) / 2
g-sld/redrag glst-high / max 1 (length? group-list) / 2


bb/pane: send-lay/pane
s2/redrag 1
clr: none
base-x: cx/offset/x
ucnt: gcnt: 0

resize: has [w h] [
	w: first  main-lay/size
	h: second main-lay/size
	lb/size/y: h + 1
	lb/update

	; User and group boxes:
	u-sld/resize/y u-lst/size/y: h - l1/size/y - l2/size/y / 2
	l2/offset/y: u-lst/offset/y + u-lst/size/y
	g-sld/offset/y: g-lst/offset/y: l2/offset/y + l2/size/y
	g-sld/resize/y g-lst/size/y: h - g-lst/offset/y
	ulst-high: u-lst/size/y / u-lst/subface/size/y
	u-sld/redrag ulst-high / max 1 (length? user-list) / 2

	; New message box and scroller:
	ax/offset/x: base-x
	ax/offset/y: s2/offset/y: h - ax/size/y
	s2/offset/x: w - s2/size/x
	ax/size/x: s2/offset/x - base-x

	; Icon box:
	bb/offset/x: base-x
	bb/offset/y: ax/offset/y - bb/size/y
	bb/size/x: w - base-x
	cb/offset/x: w - base-x - cb/size/x - 16
	cc/offset/x: cb/offset/x - cc/size/x - 3
	tb/size/x:
	sb/offset/x: cc/offset/x - sb/size/x - 3

	; Message list and scroller:
	cx/offset/x: ax/offset/x
	cx/size/y: s1/size/y: bb/offset/y
	s1/resize s1/size
	s1/offset/x: s2/offset/x
	cx/size/x: ax/size/x

	; Message sizes:
	tp2/offset/x: tp1/size/x: tp1w * min 1 w / 400
	tp3/size: either w < 400 [1x10][either w < 700 [tp3s][tp3s * 2x1 / 1x2]] ;>
;	tp1/font/valign: pick [top middle] tp3/size/y < tp3s/y
	tp2/size/x: cx/size/x - tp1/size/x - tp3/size/x

	tp3/offset/x: tp2/offset/x + tp2/size/x
	high: 0
	foreach msg bx/pane [
		msg/size/x: cx/size/x
		msg/pane/1/size/x: tp1/size/x
		msg/pane/2/offset/x: tp2/offset/x
		msg/pane/2/size/x: tp2/size/x
		msg/pane/3/offset/x: tp3/offset/x
		msg/pane/3/size: tp3/size
		msg/pane/2/line-list: none
		clear head msg/pane/2/pane ; hyperlinks
		msg/size/y: h: max tp3/size/y second any [size-text msg/pane/2 0x0]
		foreach p msg/pane [p/size/y: h]
		msg/offset/y: high
		make-links msg/pane/2
		high: high + h + spacer
	]
	bx/size/y: high
	bx/size/x: cx/size/x
	s1/redrag s1/size/y / max 1 high
	reset-scroll
]

template: layout [
	origin 0 space 0 across
	tp1: text 98 "name" bold middle center font-size fontsize white para [origin: margin: 0x0]
	tp2: txt wrap middle black snow 470 font-size fontsize "msg" with [pane: copy []]
	tp3: txt 64 gray snow font-size 9 "00-XXX-2000 00:00:00" middle center
]

tp1/color: tp3/color: snow
tp1/font/color: black
tp1/font/align: 'right

make-new: func [n txt] [
	n: make template/pane/:n [text: txt line-list: none]
	n/size/y: second n/para/origin + n/para/margin + size-text n
	n
]

trim-face: func [face] [
	if block? face [foreach f face [trim-face get f] exit]
	face/init: face/facets: face/styles: face/multi: none
]

new-msg: func [msg /local dat grp a b c d y] [
	; Anti-recycle error.  - AK
	msg: make msg-obj third msg	;-- Don't ask me why, but this line stops the Recycle Error - AK
	a: make-new 1 join msg/from #":"
	a/font: make a/font [color: any [msg/color black]]
	a/para/wrap?: no
	if (first size-text a) > a/size/x [a/font/align: 'left]
	b: make-new 2 msg/content
	dat: msg/when - msg/when/zone + now/zone
	c: make-new 3 reform [dat/date dat/time]
	c/font: make c/font []
	d: make-face 'box
	d/pane: reduce [a b c]
	trim-face [a b c d]
	d/offset: 0x0
	d/size/x: c/offset/x + c/size/x
	y: max max a/size/y b/size/y c/size/y
	d/user-data: max a/size/y c/size/y 
	a/size/y: b/size/y: c/size/y: d/size/y: y
	make-links b
	d/offset/y: high
	high: high + y + spacer
	bx/size/y: high
	append bx/pane d
]

hyper-link: stylize [
	link: txt 0.0.200 400x20 font-size fontsize as-is para [origin: margin: 0x0] [
		error? try either url? face/data [[browse face/data]][[do face/data]]
	][
		write clipboard:// mold face/data
	]
] 

make-link: func [
	offset {Offset to place link}
	url {url to perform action on}
	txt {display text}
	col {set a color for this link}

	/local f
][
	f: make-face hyper-link/link
	f/data: url
	f/text: txt
	f/color: snow
	f/offset: offset ; - 2x0
	f/size: size-text f
	if col [set-font f 'color col set-font f 'colors reduce [col f/font/colors/2]]
	f/saved-area: true
	f
]

link-parser: context [
	non-white-space: complement white-space: charset reduce [#" " newline tab cr #"<" #">"]
	to-space: [some non-white-space | end]
	skip-to-next-word: [some non-white-space some white-space]
	msg-face: none

	match-pattern: func [pattern url color] [
		 compose [
			mark: 
			(pattern) (either string? pattern [[to-space end-mark:]] []) 
			(to-paren compose [
				text: copy/part mark end-mark
				offset: caret-to-offset msg-face mark
				insert tail msg-face/pane 
					make-link offset (any [url [pick load/all text 1]]) text (color)
			])
			any white-space
		]
	]

	link-rule: clear []

	foreach [pattern url color] reduce [
		"http://" none none
		"www." [join http:// text] none
		"ftp://" none  none
		"ftp." [join ftp:// text] none
		"do http://" none brick
		"do %" none brick
		["do [" (end-mark: second load/next skip mark 3) :end-mark]
			[first reduce [load text text: copy/part text 2]] brick
	][
		insert insert tail link-rule match-pattern pattern url color '|
	]
	insert tail link-rule 'skip-to-next-word

	use [mark end-mark text offset] [bind link-rule 'mark]

	set 'make-links func [face] [
		msg-face: face
		error? try [parse/all face/text [any link-rule]]
	]
]

make-scroll-pane: does [
	bx: make-face 'box
	bx/color: if find first bx 'changes [spacer-color]
	bx/size: cx/size - 4x4
	bx/offset: 0x0
	bx/pane: []
	cx/pane: bx
]

scroll-msg: func [val /only /local m] [
	if zero? high [exit]
	m: max 2 high - cx/size/y + spacer
	bx/offset/y: negate min m to-integer val * m
	s1/state: none
	if only [bx/changes: 'offset]
	show [bx s1]
]

rescroll: does [
	s1/redrag s1/size/y / max 1 high
	if s1/data = 1.0 [reset-scroll]
	show s1
]

reset-scroll: does [scroll-msg 1 s1/data: 1.0]


page-msg: func [dir][
	s1/data: min 1 max 0 (dir / (max 1 high) + s1/data)
	scroll-msg/only s1/data
]

cb/font: make cb/font []

tp1w: tp1/size/x
tp3s: tp3/size

init-AltMe: func [xy size] [
	make-scroll-pane
	main-lay/size: size
	main-lay/offset: xy
	resize
	view/new/options/title main-lay [resize min-size 300x160] reform ["AltMe Reader -" user-prefs/express] 
		;--- does view fry all feels? !!!
	new-msgs []
	main-lay/feel: make main-lay/feel [
		detect: func [face event] [
			switch event/type [
				resize [
					resize
					prefs/size: main-lay/size
					save-prefs
					show main-lay
					scroll-msg 1
					return true
				]
				offset [
					prefs/offset: main-lay/offset
					save-prefs
					return true
				]
				key [
					switch event/key [
						#"^Q" [shut main-lay]
						page-up   [page-msg negate cx/size/y]
						page-down [page-msg cx/size/y]
					]
				]
				scroll-line [page-msg event/offset/y * 32]
				scroll-page [page-msg event/offset/y * cx/size/y]
				close [shut main-lay]
			]
			event
		]
	]
	resize
	;load-msgs "All"
	show main-lay
]

message-list: []

new-msgs: func [mes] [
	message-list: mes
	clear bx/pane
	high: 0
	foreach ms mes [new-msg ms]
	rescroll
	show main-lay
]

; Modified to do by groups
filter-msgs: func [filter /local cm] [
	cm: load-msgs filter
	m1/new-msgs cm
	m1/resize ; patch to new-msgs sizing bug for small windowsize.
]



]

;-- File handling:

m1: context ctx-msgr
m1/init-AltMe prefs/offset prefs/size

do-events

