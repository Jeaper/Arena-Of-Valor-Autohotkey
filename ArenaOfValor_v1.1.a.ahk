﻿#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; CONFIG VARIABLES:

	; If true, useLastSpellPos will make the spell you use target the same location as the last spell
	global useLastSpellPos:= true
	; The time after you have used a spell, which the last spell position will be tracked  (in milliseconds (1000 = 1 second)) (-1 = never forget)
	global lastSpellForgetTime:= 2500

	; Restriction smoothness when targeting spells
	global smoothness := 0 ;should be between 0 and 1
	; Radius of the mouse restriction on spells
	global radius := 150

	;   cancelKey consist of info for the cancel button:
	;   keyName is what key you will use to "cancel"
	; 	x/y : position of  the Cancel Button
	global cancelKey:={"keyName":"9", "x":1694,"y":280}

	;   keyMap consist of info for each button (1-4):
	; 	x/y : central position of  the Restriction
	;	state: 0-2 used to determine the toggle
	; 	pressed: 0-1 pressed state.
	;   keyName is what key you will use to "to use the spell"
	;   Standard is, 1: spell 1 (bottom left), 2: spell 2 (middle). 3: spell 3 (Ulti (top right)),   4: ability (such as execute or blink (Not really useful unless you are using a targeted ability))
	global keyMap:=[{"keyName":"1", "x":1432,"y":902, "state":0, "pressed":0}, {"keyName":"2", "x":1550, "y":740, "state":0, "pressed":0}, {"keyName":"3", "x":1707, "y":627, "state":0, "pressed":0}, {"keyName":"4", "x":1270, "y":970, "state":0, "pressed":0}]

; END CONFIG VARIABLES:

;No use changing these variables:
;These two are used for tracking the last spell position, no use  changing them
global lastSpellPos:={"x":0,"y":0}
global lastSpellTime:= 0


Init()
Init() {
  while(true){ 
		mainUpdate()
		
		GetKeyState,curKeyState,Esc,P
		if( curKeyState = "D"){
				return
		}
	}
}

pressCancelButton(){
	CoordMode, Mouse, Screen
				x:= cancelKey.x
				y:= cancelKey.y
				MouseMove, x, y
				sleep 60
				Click up
}

mainUpdate(){
	cancelButton:= cancelKey.keyName
	
	GetKeyState, cancelKeyState, %cancelButton%
		if( cancelKeyState = "D"){
				Loop,4{
					if(keyMap[A_Index].state != 0){
							MouseGetPos, nx, ny
							lastSpellPos.x:= nx-keyMap[A_Index].x
							lastSpellPos.y:= ny-keyMap[A_Index].y
							lastSpellTime:= A_TickCount
					}
					keyMap[A_Index].pressed:= 0
					keyMap[A_Index].state:= 0
				}
				pressCancelButton()
				return
		}
	
	Loop,4{
		;
		;Check Button Presses
		;
		key:= keyMap[A_Index]
		buttonKey:= key.keyName
		GetKeyState, curKeyState, %buttonKey% 
		
		pressed:= key.pressed
		if( pressed = 1 && curKeyState = "U"){
				ButtonUp(A_Index)
		}
		else if(pressed = 0 && curKeyState = "D"){
				ButtonDown(A_Index)
		}
		
		if(key.state>0){
			; If key is 'active', restrict the mouse position2
			x:= key.x
			y:= key.y
			
			MouseGetPos, nx, ny
			dx := nx - x
			dy := ny - y
			dist := sqrt( (dx ** 2) + (dy ** 2) )

			if ( dist > radius ) {
				dist := radius / dist
				dx *= dist
				dy *= dist
				
				a := smoothness
				b := 1 - smoothness
				nx := a*nx + b*(x + dx)
				ny := a*ny + b*(y + dy)
				MouseMove, nx, ny, 0
			}
		}
	}
}

startRestriction(key){
	
	;Abort old keys
	restrictingOther:= false
	
	Loop,4{
			if(A_Index != key){
				
					if(keyMap[A_Index].state != 0){
						restrictingOther:= true
						MouseGetPos, nx, ny
						dx:= nx-keyMap[A_Index].x
						dy:= ny-keyMap[A_Index].y
					}
					keyMap[A_Index].pressed:= 0
					keyMap[A_Index].state:= 0
			}
	}
	if(restrictingOther ){
			pressCancelButton()
			sleep 10
	}
	
	;  Set state and Click at the central position of our restriction
	keyMap[key].state:= 1
	CoordMode, Mouse, Screen
	x:= keyMap[key].x
	y:= keyMap[key].y
	MouseMove, x, y
	sleep 10
	Click down
	
	if(restrictingOther ){
			sleep 50
			MouseMove, keyMap[key].x+dx, keyMap[key].y+dy
	}
	else if(useLastSpellPos && (((A_TickCount-lastSpellTime) <= lastSpellForgetTime) || lastSpellForgetTime = -1)){
			sleep 50
			MouseMove, keyMap[key].x+lastSpellPos.x, keyMap[key].y+lastSpellPos.y
	}
}
endRestriction(key){
	; Stop clicking, reset state.
	Click up
	keyMap[key].state:= 0
	
	if(useLastSpellPos){
			MouseGetPos, nx, ny
			lastSpellPos.x:= nx-keyMap[key].x
			lastSpellPos.y:= ny-keyMap[key].y
			
			lastSpellTime:= A_TickCount
	}
}
ButtonUp(key){
	; Called on Button Up
	keyMap[key].pressed:= 0
	if (keyMap[key].state = 1 ) {
		keyMap[key].state:= 2
	}
}
ButtonDown(key){
	; Called on Button Down
	keyMap[key].pressed:= 1
	if(keyMap[key].state = 0) {
		startRestriction(key)
	}
	else if (keyMap[key].state = 2 ) {
		endRestriction(key)
	}
}
	


 ~#q::ExitApp