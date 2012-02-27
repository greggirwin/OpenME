Rebol [
	Title: "BEER Listener Example"
	Date: 18-Jan-2006/15:06:14+1:00
	License: {
Copyright (C) 2005 Why Wire, Inc.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

Other commercial licenses to this program are available from Why Wire, Inc.
}
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
include/check %listener.r
include/check %ft-profile.r

;set path for received files
ft-profile: profile-registry/filetransfer
if ft-profile/destination-dir: %cache-listener/ [make-dir ft-profile/destination-dir]

open-listener 8000

file-list: copy []
file-keys: make hash! []

;set callback handler for POST on server
ft-profile/post-handler: [
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

ft-profile/get-handler: func [channel action data][
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


view layout/offset [
	across
	origin 5
	backcolor sky
	clk: banner 200 rate 25 with [
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
] 400x40
;halt
