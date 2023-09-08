#pragma rtGlobals=3		// Use modern global access method and strict wave access.

menu "Macros"
	"Graph for talk/2column 17 cm", BigSize()
	"Graph for single colum 8.5 cm", SmallSize()
end

function SmallSize()
ModifyGraph width=161.575,height=150.236,gfSize=12
ModifyGraph margin(left)=45,margin(bottom)=34
ModifyGraph lsize=1.2
ModifyGraph mirror=2
ModifyGraph fSize=0, standoff = 0, axThick=1
ModifyGraph fStyle=0
ModifyGraph tick=2,btLen=4
end

function BigSize()
ModifyGraph width=283.465, height=255.118, gfSize=16
ModifyGraph margin=0
ModifyGraph lsize=1.5
ModifyGraph mirror=2
ModifyGraph fSize=0, standoff = 0, axThick=1.5
ModifyGraph fStyle=0
ModifyGraph tick=2,btLen=4
end