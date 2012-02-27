Rebol [
	Date: 13-Mar-2007/16:10:56+1:00
	Author: "Ladislav Mecir"
	Title: "timer.r"
]

use [alarms recent-handler] [
	alarms: make list! 0
	
	add-alarm: func [
		time [date! time! number!]
		alarm [word! function!]
	] [
		if number? time [time: to time! time]
		if time? time [time: now/precise + time]
		alarms: tail alarms
		while [all [not head? alarms time < first first back alarms]] [
			alarms: back alarms
		]
		if head? alarms [
			either time? system/ports/wait-list/1 [
				system/ports/wait-list/1: difference time now/precise
			] [
				insert system/ports/wait-list difference time now/precise
			]
		]
		insert/only alarms reduce [time :alarm]
	]
	
	recent-handler: func [error [error!]] [print mold disarm error]
	
	do-events: func [
		{
			Process all events
			- a variant with error handling and timer thread support 
		}
		/on-error {specify the error handler}
		handle-error [function!] {
			error handling function
			
			arguments:
			error - the error that is being handled
		}
		/only {error handler specification only}
		/local alarm result
	] [
		recent-handler: handle-error: either on-error [:handle-error] [
			:recent-handler
		]
		
		if only [exit]
		
		while [true] [
			while [
				alarms: head alarms
				all [not tail? alarms alarms/1/1 <= now/precise]
			] [
				alarm: alarms/1
				remove alarms
				do next alarm
			]
			either empty? alarms [
				if time? system/ports/wait-list/1 [
					remove system/ports/wait-list
				]
			] [
				either time? system/ports/wait-list/1 [
					system/ports/wait-list/1: difference alarms/1/1 now/precise
				] [
					insert system/ports/wait-list difference alarms/1/1 now/precise
				]
			]
			either error? result: try [wait []] [handle-error result] [
				if result [return result]
			]
		]
	]
]
