[
	make-service [
		info: [
			name: "test services"
		]
		services: [port]
		data: [
			port [
				port-info: func []  [
					reduce [channel/port/sub-port/remote-ip channel/port/sub-port/local-port channel/port/sub-port/remote-port]
				]
			]
		]
	]
	
	make-service [
		info: [
			name: "basic services"
		]
		services: [time info admin]
		data: [
			info [
				service-names: func [] [
					services
				]
				service-obj: func [] [
					self
				]
			]
			time [
				get-time: func [][
					now/time
				]
			]
			admin [
				add-user: func [][
				]
				remove-user: func [][
				]
			]
		]
	]	
]
