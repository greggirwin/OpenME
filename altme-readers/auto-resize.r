REBOL [
	Author: "DocKimbel/Softinnov"
	Date: 14/10/2002
	Purpose: "Auto-resizing system for VID"
	Version: 0.9.6
	History: [
		0.9.6 - 14/10/2002 {
			- 'blank style added (use it to fill gaps and "balance" the layout)
			- 'no-resize keyword added (remove all resize flags from a face)
			- Internal fix: test changed for 'lvf from < to <=
			- 'list style now supported. (You can use resize-* flags in the list's layout)
			- Code isolation in its own context.
		}
		0.9.5 - 10/10/2002 {
			- f/flags added in all test block to avoid breaks in some cases.
			- flag-list now defined locally.
			- do-resize better handle function! panes
			- impacted face list test changed from "range/1 >..." to "range/1>=..."
			- 'extend word added to slider/dragger and scroller/dragger 
		}	
		0.9.4 - 26/08/2002 {
			- Add 'extend facet to 'blank-face. (Fixes some issues with requesters)
			- Window event handler changed. Now it supports multiple resizable windows.
		}
		0.9.3 - 19/08/2002 {
			- Added 'alone keyword to resize a face on its own layer without interfering
			  with others faces in the same pane. (usefull for bg faces, see "from-cyphre-test.r") 
			
			- Pane face blocks are now 'copy-ed, so resize won't change their z order anymore.
			
			- Patched 'layout func to set window 'extend facet to its initial size. (no more need to
			  to define global word 'prev-size)
		}
		0.9.2 - 11/08/2002 {
			- Engine now based on original faces size & offset values (instead of current ones). Give
			  much better results and is now rock solid even when resizing the window to minimal size.
			  
			- 'extend purpose changed a little. It now holds original face's size & offset ([pair! pair!])
			  Maybe should it be renamed to 'origin or 'initial or 'saved...?
			
			- Auto-spacing system removed. (No more necessary)
			
			- Round function added. Should be moved to mezz level (math general function)
			
			- Code optimized in size.
		}
		0.9.1 - 08/08/2002 {
			- Added auto-spacing system for faces that would else overlap after resizing (caused by roundings)
			  Fixes the "ChessBoard" case issue.
			  
			- Calculation bug fixed (2 resizeables having the same fixed face in their dependency list).
		}
		0.9.0 - 06/08/2002 "First release"
	]
]

;==== VID patching ====

; Add a 'resize facet to some complex styles
stylize/master [
	list: list with [
		resize: func [sz /x /y][
			any [all [x size/x: sz] all [y size/y: sz] size: sz]
			subface/size/x: size/x
			ctx-auto-resize/do-resize subface subface/extend	; hook to the auto-resize system
		]
	]
	text-list: text-list with [
		resize: func [sz /x /y][
			any [all [x size/x: sz] all [y size/y: sz] size: sz]
			do init
		]
	]
	area: area with [
		resize: func [sz /x /y][
			any [all [x size/x: sz] all [y size/y: sz] size: sz]
			do init
		]
	]
	blank: sensor feel none
]

; the static reference to the 'panel style can be removed from 'layout if required...
layout: func first :layout head change back tail second :layout [
	if new-face/style <> 'panel [new-face/extend: new-face/size] new-face
] 

repend system/view/VID/facet-words [
	'resize-all func [new args][flag-face new 'resize-all args]
	'resize-h func [new args][flag-face new 'resize-h args]
	'resize-v func [new args][flag-face new 'resize-v args]
	'alone func [new args][flag-face new 'alone args]
	'no-resize func [new args][
		deflag-face new resize-all
		deflag-face new resize-h
		deflag-face new resize-v
	]
]

;--- Adding the 'extend facet to all styles ---
styles: system/view/vid/vid-styles
forall styles [
	styles: next styles
	change styles make styles/1 [extend: none]
]
system/view/vid/vid-styles/slider/dragger: make system/view/vid/vid-styles/slider/dragger [extend: none]
system/view/vid/vid-styles/scroller/dragger: make system/view/vid/vid-styles/scroller/dragger [extend: none]

system/view/vid/vid-face: make system/view/vid/vid-face [extend: none]
blank-face: make blank-face [extend: none]
unprotect 'face face: make face [extend: none] protect 'face


;======== Auto Resize ==============

ctx-auto-resize: context [

	; This one should be globally defined
	round: func [value [number!]][to integer! .5 + value]

	resize-pane: func [
		blk po pn axis
		/local f sf dep-list flag-list range max-ext ext adjust contrib max-shift lvf word val !axis
		df tmp ofsz off sz axp !axp 
	][
		dep-list: copy flag-list: make block! 20

		!axis: pick [y x] tmp: axis = 'x
		word: pick [resize-h resize-v] tmp
		!axp: reverse axp: pick [1x0 0x1] tmp

		blk: copy blk
		forall blk [
			if all [
				f: first blk in f 'flags f/flags find f/flags 'alone remove blk 
				any [find f/flags 'resize-all find f/flags word]
			][
				any [f/extend f/extend: reduce [f/size f/offset]]
				f/size: f/size * !axp + (f/size + pn/:axis - po/:axis * axp)
			]
		]
		sort/compare blk: head blk func [a b][
			to logic! any [							
				a/offset/:axis < b/offset/:axis		; here, 'extend should be used to make the algo cleaner...
				all [a/offset/:axis = b/offset/:axis a/offset/:!axis < b/offset/:!axis]
			]
		]
		while [not tail? blk][
			if all [
				not find flag-list sf: f: first blk						; start face flagged ?
				in f 'flags f/flags
				any [find f/flags word find f/flags 'resize-all]
			][	
				if not f/extend [f/extend: reduce [f/size f/offset]]
				range: to pair! reduce [f/extend/2/:!axis f/extend/2/:!axis + f/extend/1/:!axis]
				clear dep-list
				max-ext: adjust: 0
				lvf: none
				foreach f blk [										; build dependent faces list
					set [sz off] any [f/extend f/extend: reduce [f/size f/offset]]
					if not any [
						range/1 >= (off/:!axis + sz/:!axis) 
						range/2 <= off/:!axis	
						sf/size/:axis > (off/:axis + sz/:axis)			; sf over f test
					][
						either tmp: find flag-list :f [				; already flagged, just count contribution
							adjust: adjust + to integer! first next tmp
						][
							contrib: none
							if all [in f 'flags block? f/flags any [find f/flags 'resize-all find f/flags word]][	; set as resizeable ?
								contrib: sz/:axis
								either all [lvf (lvf/extend/2/:!axis + lvf/extend/1/:!axis) <= off/:!axis][
									contrib: sz/:axis			; if overlapping, use previous contribution
								][
									max-ext: max-ext + contrib		; increase total contribution
									lvf: :f							; set last resizeable face found
								]
							]	
							repend dep-list [:f contrib]	
						]
						; increase the dependency range according to current face (if necessary)
						range/1: min range/1 off/:!axis		
						range/2: max range/2 off/:!axis + sz/:!axis
					]
				]
	; resize and reposition every face in the dependency list	
				max-shift: (pn/:axis - po/:axis) - adjust			
				foreach [f contrib] dep-list [
					ext: none
					if all [contrib not zero? max-ext][
						ext: (contrib * max-shift) / max-ext
						range: to pair! reduce [f/extend/2/:!axis f/extend/2/:!axis + f/extend/1/:!axis]
						adjust: 0
						foreach [df tmp] skip find dep-list f 2 [
							set [sz off] df/extend
							if not any [
								range/1 >= (off/:!axis + sz/:!axis) 
								range/2 <= off/:!axis
							][
								df/offset: df/offset * !axp + (axp * round df/offset/:axis + ext)	; does val: round df/offset/:axis + ext, either axis = 'x [df/offset/x: val][df/offset/y: val]
								range/1: min range/1 off/:!axis
								range/2: max range/2 off/:!axis + sz/:!axis
							]
						]
						f/old-size: f/old-size * !axp + (f/size/:axis * axp)	; does either axis = 'x [f/old-size/x: f/size/x][f/old-size/y: f/size/y]
						val: round f/extend/1/:axis + ext - adjust
						either in f 'resize [either axis = 'x [f/resize/x val][f/resize/y val]][
							f/size: f/size * !axp + (val * axp)			; does either axis = 'x [f/size/x: val][f/size/y: val]
						]
					]
					repend flag-list [:f ext]
				]
			]
			blk: next blk
		]
		blk: head blk
	]

	do-resize: func [face [object!] old-sz [pair!] /local fp pan f][
		if all [fp: get in face 'pane not function? :fp][
			pan: fp
			if object? pan [pan: reduce [pan]]
			foreach f pan [if f/extend [f/size: f/extend/1 f/offset: f/extend/2]]
			resize-pane pan old-sz face/size 'x
			resize-pane pan old-sz face/size 'y
			if block? fp [
				foreach f fp [
					if not in f 'resize [do-resize f any [all [f/extend f/extend/1] f/old-size] f/size]
				]
			]
		]
	]

	; ==== Should be executed on View startup ====
	install: does [
		insert-event-func func [face event][
			if event/type = 'resize [
				if not attempt [event/face/resize-handler][do-resize event/face event/face/extend]
				show event/face
			]
			event
		]
	]
]

ctx-auto-resize/install