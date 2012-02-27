Rebol [
	Date: 18-Jan-2006/10:34:43+1:00
	title: "default paths definitions"
]

root-path: system/script/path
libs-path: root-path/libs
beer-path: root-path/BEER
do libs-path/include.r
append include-path reduce [
	root-path/libs
	root-path/BEER
	root-path/BEER/examples
	root-path/BEER/profiles
]
