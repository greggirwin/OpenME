REBOL [
	title: "prototype of universal text list style"
	author: cyphre@seznam.cz
	copyright: cyphre@seznam.cz
	history: {
		07-Apr-2004 fixed higlight color flood bug
					added horizontal dragger proportional resiszing
					added access functions:
					* delete-picked-row (deletes currently picked row)
					* get-picked-column <column> (returns specified column data from selected row)
					* delete-row <row> (deletes specified row by number)
		06-Apr-2004 fixed vertical scroller bug
					rewritten highlighting mechanism a bit so face color is preserved
		05-Apr-2004 fixed compatibility issue with new versions of View (layout/keep change)
		04-Apr-2004 added support of automatic horizontal scroller when width of table is bigger than visible area
		16-Jan-2004 added keyword ROW-HIGHLIGHT which enables the line selection code when specified
		19-Aug-2003 added support of line selection when using plain text lists - list/picked contains the data of picked row
		27-Jul-2003 added keyword LINE-COLORS [block!] specifiing a color patern for lines when using text-list type of data
		21-Jul-2003 enhanced the data dialect for DO [block!] keyword to be able to run custom code per cell on the fly during the list refresh
					changed design of the rowbar
					added sorting arrow markers on the rowbar
		02-Jul-2003 added ROWBAR-HEIGHT keyword
					added SLIDER-WIDTH keyword
		01-Jul-2003 added update-list function
					minor changes and bugfixes
		25-Jun-2003 added vertical autoscroll
					added ROWBAR keyword for definition of column names
					added COLUMNS keyword for row layout definition
					added global list ACTION support
					added SORT up/down functionality when clicking on the rowbar
					user-data now contains data dialect block of current face
					enhanced demo example (shows how to use the dialect - storing of important states or data for each cell)
		24-Jun-2003 initial release
	}
]

stylize/master [
	my-list: face with [
		size: none
		color: white
		edge: make edge [color: black size: 1x1]
		sub-lay: none
		row-size: none
		slider-width: 18
		tmp-size: 0x0
		tmp-pane: none
		cnt: 1 ;index of the first visible row
		columns: none
		rowbar: none
		row-highlight?: false
		rb-height: none
		cols: rows: none
		colors: copy []
		line-colors: none
		picked: none
		picked-line: none
		last-picked: none
		scr-h: scr-v: none
		upd?: false
		sorted-by: 0
		grid: none
		viewport: none
		rowbar-face: none
		update-data: func [/srt /local idx f w v sf][
				rows: min length? data to-integer ((size/y - any [rb-height 0]) / row-size/y)
				data: at head data cnt
				if all [srt rowbar sorted-by > 0][
					sf: pane/1/pane/:sorted-by
					sf/data: not sf/data
					sort/compare head data func [x y /local col][
						col: sf/column
						either x/:col < y/:col [sf/user-data][not sf/user-data]
					]
				]
				repeat i rows [
					repeat j cols [
						idx: (cols * (i - 1)) + j
						f: grid/pane/:idx
						either i > length? data [
							f/text: none
						][
							if object? f [
								either block? data/:i/:j [
									parse data/:i/:j [
										any [
											'do set v block! (do bind v in f 'self)
											| set w word! set v any-type! (if found? in f w [set in f w do bind reduce [v] in f 'self]) ; not all words might be available in the list face
											| skip
										]
										to end
									]
								][
									f/text: form data/:i/:j
								]
								f/user-data: data/:i/:j
							]
						]
					]
				]
				either not empty? head data [
					if picked-line <> last-picked [
						last-picked: picked-line
					]
					if all [last-picked last-picked > 0 last-picked <= length? head data][
						picked: first at head data last-picked
					]
					if all [last-picked last-picked > (length? head data)] [;removed last selected line
						last-picked: length? head data
						picked-line: last-picked
						picked: first at head data picked-line
					]
					if all [last-picked last-picked >= cnt last-picked <= (cnt + rows - 1)][
						repeat n cols [
							idx: n + (((last-picked - cnt)) * cols)
					    	grid/pane/:idx/color: yellow
						]
					]
					if all [last-picked last-picked < cnt last-picked = length? head data] [
						cnt: last-picked
						update-data
					]
				][
					picked: last-picked: picked-line: none
					colorize-lines
				]
				show grid/pane
				data: head data
		]
		update-list: does [
			upd?: true
			do bind my-init 'self
			show self
		]
		delete-picked-row: does [
			if none? picked [return false]
			remove skip data (picked-line - 1)
			update-list
			return true
		]
		delete-row: func [row][
			if (length? data) < row [return false]
			remove skip data (row - 1)
			update-list
			return true
		]
		get-picked-column: func [col][
			if none? picked [return none]
			return pick picked col
		]
		colorize-lines: has [idx clr] [
				if not line-colors [exit]
				idx: 0
				line-colors: head line-colors
				clr: first line-colors
				foreach f grid/pane [
					idx: idx + 1
					if idx > cols [
						idx: 1
						clr: first line-colors: either tail? next line-colors [
							head line-colors
						][
							next line-colors
						]
					]
					f/color: clr
				]
		]
		feel: make feel [
			detect: func [f e][
				if e/type = 'down [
					if all [
						not empty? f/data
						within? e/offset win-offset? f/viewport f/viewport/size
						(to-integer (((e/offset/y - second win-offset? f/grid) / f/row-size/y)) + f/cnt) <= (length? head f/data)
					][
						either f/row-highlight? [
							if f/picked [
								if all [not empty? f/colors f/last-picked - f/cnt + 1 > 0 f/last-picked - f/cnt < f/rows] [
									repeat n f/cols [
										idx: n + ((f/last-picked - f/cnt) * f/cols)
								    	f/grid/pane/:idx/color: f/colors/:n
									]
								]
							]
							use [curr-row idx][
								curr-row: to-integer (((e/offset/y - second win-offset? f/grid) / f/row-size/y)) + 1
								f/picked: f/data/:curr-row
								f/picked-line: curr-row + ((index? f/data) - 1) + f/cnt - 1
								either f/picked [
									f/colors: copy []
									f/last-picked: curr-row + f/cnt - 1
									repeat n f/cols [
										idx: n + ((curr-row - 1) * f/cols)
								    	;append f/grid/pane/:idx/user-data [color 255.255.0]
								    	append f/colors f/grid/pane/:idx/color
								    	f/grid/pane/:idx/color: yellow
									]
								][f/last-picked: none]
								f/update-data
								foreach face head reverse copy f/grid/pane [
									if within? e/offset win-offset? face face/size [
										if function? get in f 'action [
											do bind second get in f 'action 'face
											break
										]
									]
								]
							]
						][
							foreach face head reverse copy f/grid/pane [
								if within? e/offset win-offset? face face/size [
									if function? get in f 'action [
										do bind second get in f 'action 'face
										break
									]
								]
							]
						]
					]

				]
				return e
			]
		]
		my-init: init: [
			pane: copy []
			scr-v: scr-h: none
			sub-lay: copy [across origin 0 space 0]
			tmp-pane: get in layout/parent/origin/styles append copy sub-lay columns blank-face 0x0 copy system/view/vid/vid-styles 'pane
			row-size: second span? tmp-pane
			if all [rowbar not rb-height] [
				rb-height: row-size/y
			]
			if not size [size: as-pair row-size/x 300]
			if size/x = -1 [size/x: row-size/x]
			cols: length? tmp-pane
			rows: min length? data to-integer ((size/y - any [rb-height 0]) / row-size/y)
			tmp-size: 0x0
			either rowbar [
				use [idx rowbar-obj][
					rowbar-obj:	foreach t rowbar [
						idx: index? find rowbar t
						append [] compose/deep [
							box (as-pair tmp-pane/:idx/size/x rb-height)(t) left with [
								color: 180.180.180
								user-data: false
								column: (idx)
								font: make font [
									size: 12
									shadow: 0x0
									color: 0.0.0
									colors: [0.0.0 255.0.0]
								]
								dr-effects: [
									[draw [pen 0.0.0 fill-pen 0.0.0 polygon 0x0 10x0 5x10]]
									[draw [pen 0.0.0 fill-pen 0.0.0 polygon 5x0 10x10 0x10]]
								]
								effect: none
								para: make para [
									origin: 10x2
								]
								edge: make edge [
									size: 1x1
									color: 180.180.180
									effect: 'bevel
								]
								feel: make feel [
									over: func [f a e][
									        if all [f/font f/font/colors] [
									            f/font/color: pick f/font/colors not a
									            show f
									            f/font/color: first f/font/colors
									        ]
								    ]
								    engage: func [f a e][
								        switch a [
								            down [f/state: on]
								            up [if f/state [do-face f f/text] f/state: off]
								            over [f/state: on]
								            away [f/state: off]
								        ]
								        cue f a
								        show f
								    ]
								    redraw: func [f a o /local state][
								            if f/edge [f/edge/effect: pick [ibevel bevel] f/state]
								            state: either not f/state [f/blinker] [true]
								            if f/colors [f/color: pick f/colors not state]
								    ]
								    detect: none
								    cue: none
								    blink: none
								]
							] [
								foreach f face/parent-face/pane [
									f/effect: none
									show f
								]
								face/data: not face/data
								face/effect: pick face/dr-effects face/data
								sort/compare head data func [x y /local col][
									col: face/column
									either x/:col < y/:col [face/user-data][not face/user-data]
								]
								sorted-by: face/column
								face/user-data: not face/user-data
								picked: last-picked: none
								update-data
							]
						]
					]
					append sub-lay copy/deep compose/deep [rowbar-face: panel (as-pair row-size/x rb-height) [origin 0 space 0 across (rowbar-obj)] return]
				]
			][
				insert pane none
			]
			append sub-lay copy/deep compose [viewport: panel (as-pair size/x size/y - any [rb-height 0]) [across origin 0 space 0 grid: panel [across origin 0 space 0]]]
			while [tmp-size/y < (size/y - (any [rb-height 0]) - either size/x < row-size/x [slider-width][0])][
				append last last sub-lay join columns 'return
				tmp-size/y: tmp-size/y + row-size/y
			]
			if rows < (length? head data) [
				append sub-lay [
					at as-pair size/x - slider-width 0
					scr-v: scroller as-pair slider-width size/y - (either size/x < row-size/x [slider-width][0]) with [tmp: 0][
						face/tmp: 1 + to-integer face/data * ((length? head data) - rows + either scr-h [1][0])
						if face/tmp <> cnt [
							if all [not empty? colors picked-line - cnt + 1 > 0 last-picked - cnt < rows][
								repeat n cols [
									idx: n + ((picked-line - cnt) * cols)
							    	grid/pane/:idx/color: colors/:n
								]
							]
							cnt: face/tmp
							colors: copy []
							if all [picked-line picked-line - cnt + 1 > 0 last-picked - cnt < rows][
								repeat n cols [
									idx: n + ((picked-line - cnt) * cols)
							    	append colors grid/pane/:idx/color
								]
							]
							update-data
						]
					]
				]
				if not upd? [size/x: size/x + slider-width]
			]
			if size/x < row-size/x [
				append sub-lay [
					at as-pair 0 size/y - slider-width
					scr-h: scroller as-pair size/x - either scr-v [scr-v/size/x][0] slider-width [
						grid/changes: [offset]
						grid/offset/x: - face/data * (row-size/x - size/x + either scr-v [slider-width][0])
						if rowbar [
							rowbar-face/changes: [offset]
							rowbar-face/offset/x: grid/offset/x
						]
						show face/parent-face
					]
				]
				if not upd? [size/y: size/y - slider-width]
			]
			insert tail pane get in layout/parent/origin/styles sub-lay blank-face 0x0 copy system/view/vid/vid-styles 'pane
			colorize-lines
			if size = 1x1 [size: min system/view/screen-face/size second span? pane]
			if scr-h [
				if upd? [
					viewport/size/y: scr-h/offset/y - any [rb-height 0]
				]
				scr-h/redrag size/x / grid/size/x
				scr-h/step: 0.2
			]
			if scr-v [
				if upd? [
					viewport/size/x: scr-v/offset/x
				]
				scr-v/redrag rows / (length? head data)
				scr-v/step: 1 / max 1 ((length? head data) - rows)
			]
			update-data/srt
		]
		multi: make multi [
		]
		words: [
			data [
				new/data: second args
				next args
			]
			columns [
				new/columns: second args
				next args
			]
			rowbar [
				new/rowbar: second args
				next args
			]
			rowbar-height [
				new/rb-height: second args
				next args
			]
			slider-width [
				new/slider-width: second args
				next args
			]
			line-colors [
				new/line-colors: second args
				next args
			]
			row-highlight [
				new/row-highlight?: true
				args
			]
		]
	]
]
