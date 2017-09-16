#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance force
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

;This is used for restoring cursor position after spell is canceled or cast
global restorePos:={"x":0,"y":0,"alreadyRestored": true}

;END No use changing these variables:

Init()

Esc::
	ExitApp
Return


Init() {
	CoordMode, Mouse, Screen
	
	cancelButton:= cancelKey.keyName
	cancelFunc:= func("CancelButton").bind( )
	
	Hotkey,%cancelButton%, %cancelFunc%, On
	
	Loop,4{
		;
		;Check Button Presses
		;
		key:= keyMap[A_Index]
		buttonKey:= key.keyName
		pressedFunc:= func("ButtonIsPressed").bind( A_Index)
		Hotkey,%buttonKey%, %pressedFunc%, On
		
		buttonUpKey:= % buttonKey . " Up"
		
		cancelFunc:= func("ButtonIsReleased").bind( A_Index)
		Hotkey,%buttonUpKey%, %cancelFunc%, On
	}
}

CancelButton(){
	Loop,4{
					if(keyMap[A_Index].state != 0){
							MouseGetPos, nx, ny
							lastSpellPos.x:= nx-keyMap[A_Index].x
							lastSpellPos.y:= ny-keyMap[A_Index].y
							lastSpellTime:= A_TickCount
							keyMap[A_Index].state:= 3
					}
				}
				if(restorePos.alreadyRestored){
					saveRestoreMousePos()
				}
				pressCancelButton()
				
				restoreMousePos()
				return
}

ButtonIsPressed(keyIndex){
		;
		;Check Button Presses
		;
		key:= keyMap[keyIndex]
		pressed:= key.pressed
		
		if(pressed = 0){
				ButtonDown(keyIndex)
		}
}

ButtonIsReleased(keyIndex){
		key:= keyMap[keyIndex]
		pressed:= key.pressed
		
		ButtonUp(keyIndex)
		
}

pressCancelButton(){
				if(USE_HOOK){
					EndCircleClip()
				}
				x:= cancelKey.x
				y:= cancelKey.y
				MouseMove, x, y
				sleep 60
				Click up
}

;Restore Mouse
saveRestoreMousePos(){
		MouseGetPos, nx, ny
		restorePos.x:= nx
		restorePos.y:= ny
		restorePos.alreadyRestored:= false
	}
restoreMousePos(){
		restorePos.alreadyRestored:= true
		Sleep 50
		x:= restorePos.x
		y:= restorePos.y
		MouseMove, x, y
}
; End Restore Mouse


;Spell Restriction
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
						keyMap[A_Index].state:= 3
					}
			}
	}
	if(restrictingOther ){
		pressCancelButton()
		sleep 10
	}
	else{
		saveRestoreMousePos()
	}
	
	;  Set state and Click at the central position of our restriction
	keyMap[key].state:= 1
	x:= keyMap[key].x
	y:= keyMap[key].y
	MouseMove, x, y
	sleep 10
	Click down
	
	if(USE_HOOK){
		CircleClip(radius, x,y)
	}

	
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
	
	if(USE_HOOK){
		EndCircleClip()
	}
	
	if(useLastSpellPos){
			MouseGetPos, nx, ny
			lastSpellPos.x:= nx-keyMap[key].x
			lastSpellPos.y:= ny-keyMap[key].y
			lastSpellTime:= A_TickCount
	}
	
	if(!restorePos.alreadyRestored){
		restoreMousePos()
	}
}
;End Spell Restriction

;Button handling
ButtonUp(key){
	; Called on Button Up
	keyMap[key].pressed:= 0
	if (keyMap[key].state = 1 ) {
		endRestriction(key)
	}
	keyMap[key].state:= 0
}
ButtonDown(key){
	; Called on Button Down
    keyMap[key].pressed:= 1
	if(keyMap[key].state = 0) {
		startRestriction(key)
	}
}
;End Button handling	

EndCircleClip() {
		CircleClip()
		Sleep 10
}
;global circleClipCall:= 0
CircleClip(radius=0, x:="", y:=""){
	
	global CircleClipRadius, CircleClipX, CircleClipY
	static hHookMouse, _:={base:{__Delete: "CircleClip"}}
	If (radius>0){
		CircleClipRadius:=radius
		, CircleClipX:=x
		, CircleClipY:=y
		, hHookMouse := DllCall("SetWindowsHookEx", "int", 14, "Uint", RegisterCallback("CircleClip_WH_MOUSE_LL", "Fast"), "Uint", 0, "Uint", 0)
	}
	Else If (!radius && hHookMouse){
		DllCall("UnhookWindowsHookEx", "Uint", hHookMouse)
		CircleClipX:=CircleClipY:=""
		
		;MsgBox, 16, %circleClipCall%, CircleKey was called!
	}
}

CircleClip_WH_MOUSE_LL(nCode, wParam, lParam){
	global CircleClipRadius, CircleClipX, CircleClipY
	Critical

	if !nCode && (wParam = 0x200){ ; WM_MOUSEMOVE 
		nx := NumGet(lParam+0, 0, "Int") ; x-coord
		ny := NumGet(lParam+0, 4, "Int") ; y-coord

		If (CircleClipX="" || CircleClipY="")
			CircleClipX:=nx, CircleClipY:=ny
		  
		dx := nx - CircleClipX
		dy := ny - CircleClipY
		dist := sqrt( (dx ** 2) + (dy ** 2) )

		if ( dist > CircleClipRadius ) {
			dist := CircleClipRadius / dist
			dx *= dist
			dy *= dist
			
			nx := CircleClipX + dx
			ny := CircleClipY + dy
		}
		DllCall("SetCursorPos", "Int", nx, "Int", ny)
		
		Return 1
		
	}else Return DllCall("CallNextHookEx", "Uint", 0, "int", nCode, "Uint", wParam, "Uint", lParam) 
} 
 ~#q::ExitApp