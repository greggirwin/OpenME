REBOL [
	Date: 18-Jan-2006/10:11:31+1:00
	title: "simple time based threading"
	author: [cyphre@whywire.com ladislav@whywire.com]
	License: {
Copyright (C) 2005 Why Wire, Inc.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

Other commercial licenses to this program are available from Why Wire, Inc.
}
]

#include-check %timer.r

use [threads alarms cids] [
	
	threads: make hash! 10
	cids: make hash! 10
	alarms: make block! 10
	
	add-thread: func [
		thread-id [string!]
		time [time! date! number!]
		action [block!]
		callback [function! none!]
		/cid
			callback-id [string!]
		/repeat
		/schedule
		/local
			type
			next-time
			a
	][
	;	print ["add thread" thread-id]
		unless find threads thread-id [
			type: 'do-in
			either repeat [
				if number? time [time: to-time 1 / time]
				type: 'repeat
			][
				if number? time [time: to-time time]
			]
			unless date? time [
				next-time: now/precise + time
				a: now
				a/time: time
				time: a
			]
			if schedule [
				type: 'schedule
				next-time: time
			]
			use [alarm t id] [
				t: reduce [next-time time type action :callback callback-id]
				id: thread-id
				alarm: has [result err] either repeat [
					[
					 	if error? set/any 'err try [set/any 'result do t/4] [
							result: mold disarm err
						]
						t/5 id get/any 'result
						t/1: now/precise + t/2/time
						add-alarm t/1 'alarm
					]
				] [
					[
					 	if error? set/any 'err try [set/any 'result do t/4] [
							result: mold disarm err
						]
						t/5 id get/any 'result
						t: find threads id
						remove at alarms index? t
						remove at cids index? t
						remove t
					]
				]
				insert tail threads thread-id
				insert tail cids callback-id
				insert tail alarms 'alarm
				add-alarm next-time 'alarm
			]
			true
		]
	]
	
	; just for the backward compatibility, otherwise unnecessary
	check-next-trigger: none
	
	kill-thread: func [
		thread-id [string!]
		/local
			thread
	][
		if thread: find threads thread-id [
			set pick alarms index? thread none
			remove at alarms index? thread
			remove at cids index? thread
			remove thread
	;		print ["thread" thread-id "killed"]
			true
		]
	]
	
	thread-exists?: func [
		thread-id [string!]
	] [
		find threads thread-id
	]
	
	cid?: func [thread-id [string!]] [
		either thread-id: find threads thread-id [
			pick cids index? thread-id
		] [false]
	]
	
	thread-id?: func [cid [string!]] [
		if cid: find cids cid [pick threads index? cid]
	]

 	length-threads?: does [
 		length? threads
 	]
 	
 	thread-type?: func [thread-id [string!]] [
 		if thread-id: find threads thread-id [
 			thread-id: pick alarms index? thread-id
 			thread-id: bind 't thread-id
 			third get thread-id 
		]
 	]
 	
]
