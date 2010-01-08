;Program written for Bot Board II, Basic Atom Pro 28, Studio Ver. 1.0.0.14
;Written by Eric Hokanson & Darrell Taylor based on code by Nathan Scherdin, Jim and James Frye
;Copyright (C) 2010 Eric Hokanson & Darrell Taylor
;
;This program is free software: you can redistribute it and/or modify
;it under the terms of the GNU Lesser General Public License as published by
;the Free Software Foundation, either version 3 of the License, or
;(at your option) any later version.
;
;This program is distributed in the hope that it will be useful,
;but WITHOUT ANY WARRANTY; without even the implied warranty of
;MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;GNU Lesser General Public License for more details.
;
;You should have received a copy of the GNU Lesser General Public License
;along with this program.  If not, see <http://www.gnu.org/licenses/>.

;System variables 
TRUE con 1
FALSE con 0

CONTROLLER con FALSE

righthip	con p5
rightknee	con p4
rightankle	con p3
lefthip		con p2
leftknee	con p1
leftankle	con p0

turret	con p6
Laser   con p18
LAMP    con p19
RGUN	con p16
LGUN	con p17

NUMSERVOS		con 7
aServoOffsets	var	sword(NUMSERVOS)				
ServoTable		bytetable RightHip,rightknee, rightankle,lefthip, leftknee, leftankle, turret

#IF CONTROLLER
;[PS2 Controller]
PS2DAT 		con P12		;PS2 Controller DAT (Brown)
PS2CMD 		con P13		;PS2 controller CMD (Orange)
PS2SEL 		con P14		;PS2 Controller SEL (Blue)
PS2CLK 		con P15		;PS2 Controller CLK (White)
PadMode 	con $79

TravelDeadZone	con 4	;The deadzone for the analog input from the remote

DualShock 	var Byte(7)
LastButton 	var Byte(2)
DS2Mode 	var Byte
PS2Index	var byte
PS2Thrust	var float
PS2Turn	    var float
PS2Yaw 		var sbyte

high PS2CLK
LastButton(0) = 255
LastButton(1) = 255
#ELSE
;[Hardware Serial Port]
ENABLEHSERIAL
sethserial h9600,h8databits,hnoparity,h1stopbits

#ENDIF

;calibrate steps per degree. 
stepsperdegree fcon 166.6 

;You must calibrate the servos to "zero". Each robot will be different! 
;When homed in and servos are at 0 degrees the robot should be standing 
;straight with the AtomPro chip pointing backward. If you know the number 
;of degrees the servo is off, you can calculate the value. 166.6 steps
;per degree. The values for our test robot were found by running the 
;program bratosf.bas written by James Frye. 

;Interrupt init 
ENABLEHSERVO 

command 	var byte  ;the currenty executing movement sequence

idle var byte
ServoWait var bit
ServoWait = FALSE
TurrentAngle var sword ;the current angle of the turrent
TurrentAngle = 0
TurrentMode var bit  ;relative or absloute control
TurrentMode = 0
MAX_TURRENT_YAW con 6000
MAX_TURRENT_PITCH con 6000
TurrentSpeed var word
TurrentSpeed = 600
LHipAngle	var sword ;up down angle of turrent
RHipAngle	var sword ;up down angle of turrent

MoveSpeed   var float
MoveSpeed   = 300.0

WalkSpeed	var float ;
WalkAngle	var float ;

StrideConst var float
StrideConst = 25.0
StrideLengthLeft	var float ;
StrideLengthRight	var float ;

IdleBot 	var word
IdleBot = 0
TravLength	var float
TravLength = 6.0
LastStep	var byte
LastStep = 0
AnkleAdj	var float
AnkleAdj = 0.0

LaserOn var bit
LaserOn = FALSE
BotActive var bit
BotActive = FALSE
BotWalking var bit
BotWalking = FALSE


;==============================================================================
; Complete initialization
;==============================================================================

; Gun/Laser Initialization
low Laser
low LAMP
low LGUN
low RGUN

aServoOffsets = rep 0\NUMSERVOS		; Use the rep so if size changes we should properly init

; try to retrieve the offsets from EEPROM:
	
; OVERRIDE
aServoOffsets(0) = 600      ; RH
aServoOffsets(1) = -120     ; RK
aServoOffsets(2) = 1700     ; RA
aServoOffsets(3) = 540      ; LH
aServoOffsets(4) = 120      ; LN
aServoOffsets(5) = -1080    ; LA
aServoOffsets(6) = 0        ; TURRET
	
; Let's do gradual zeroing for safety and surge protection

hservo [rightankle\aServoOffsets(2)\0,leftankle\aServoOffsets(5)\0]
pause 500
hservo [rightknee\aServoOffsets(1)\0,leftknee\aServoOffsets(4)\0]
pause 500
hservo [righthip\aServoOffsets(0)\0,lefthip\aServoOffsets(3)\0]
pause 500
hservo [Turret\aServoOffsets(6)\0]

;---------------------------------------;
;--------Command Quick Reference--------;
;---------------------------------------;
;- Command 0 = Home Position           -;
;- Command 1 = Walk Forward            -;
;- Command 2 = Walk Backward           -;
;- Command 3 = Rest Position           -;
;- Command 4 = Turn Left               -;
;- Command 5 = Turn Right              -;
;---------------------------------------;
CMD_READY 	con 0
CMD_WALK  con 1
CMD_REST 	con 3
CMD_TURN_LEFT 	con 4
CMD_TURN_RIGHT 	con 5

;play startup sound 
sound 9,[50\4000,40\3500,40\3200,50\3900]

;==========================================
; Main loop - Read inputs and call movement
;==========================================
main
	gosub CommandInput command  ; Read PS2
#IF CONTROLLER
	LastButton(0) = DualShock(1)
	LastButton(1) = DualShock(2)
#ENDIF

	; if bot is idle for 15 sec, go into rest mode
	if (IdleBot = 1000 AND BotActive) then
		gosub toggleStandby command
	;elseif(IdleBot = 50)
	;  AnkleAdj = 0
	else
		IdleBot = IdleBot + 1
		pause 15
	endif

	gosub isWalking BotWalking  ; Check if we are midstride
	
	if(command = CMD_READY)	then						; Home Position 
		gosub movement [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, MoveSpeed] 
		hservo [Turret\(TurrentAngle + aServoOffsets(6))\500]
	elseif (command = CMD_WALK AND NOT BotWalking)		; Walk
		if LastStep = 0 then
			gosub movement [  WalkAngle, StrideLengthLeft, StrideLengthLeft, -WalkAngle,-StrideLengthRight,-StrideLengthRight,MoveSpeed] 
			LastStep = 1
		elseif LastStep = 1
			gosub movement [ -WalkAngle, StrideLengthLeft, StrideLengthLeft,  WalkAngle,-StrideLengthRight,-StrideLengthRight,MoveSpeed]
			LastStep = 2
		elseif LastStep = 2
			gosub movement [ -WalkAngle,-StrideLengthLeft,-StrideLengthLeft,  WalkAngle, StrideLengthRight, StrideLengthRight,MoveSpeed] 
			LastStep = 3
		elseif LastStep = 3
			gosub movement [  WalkAngle,-StrideLengthLeft,-StrideLengthLeft, -WalkAngle, StrideLengthRight, StrideLengthRight,MoveSpeed] 
			LastStep = 0
        endif  
		;AnkleAdj = AnkleAdj + 1
		;if (AnkleAdj > 8) then
		;	AnkleAdj = 8
		;endif
	elseif(command = CMD_REST)							          ; Rest Position 
	    gosub movement [  0.0, 35.0, 40.0,  0.0, 35.0, 40.0,MoveSpeed]
	elseif(command = CMD_TURN_LEFT )							      ; Turn left
		ServoWait = TRUE
		gosub movement [ 20.0,  0.0,  0.0,-14.0,  0.0,  0.0,MoveSpeed] 
		gosub movement [ 20.0,-35.0,-35.0,-14.0, 35.0, 35.0,MoveSpeed] 
		gosub movement [  0.0,-35.0,-35.0,  0.0, 35.0, 35.0,MoveSpeed] 
		gosub movement [  0.0, 35.0, 35.0,  0.0,-35.0,-35.0,MoveSpeed] 
		gosub movement [ 20.0, 35.0, 35.0,-14.0,-35.0,-35.0,MoveSpeed] 
		gosub movement [ 20.0,  0.0,  0.0,-14.0,-35.0,-35.0,MoveSpeed]
		gosub movement [-18.0,  0.0,  0.0, 16.0,-35.0,-35.0,MoveSpeed]
		gosub movement [-18.0,  0.0,  0.0, 16.0,  0.0,  0.0,MoveSpeed]
		gosub movement [  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,MoveSpeed]
		ServoWait = FALSE
	elseif(command = CMD_TURN_RIGHT)							; Turn right
		ServoWait = TRUE
		gosub movement [-14.0,  0.0,  0.0, 20.0,  0.0,  0.0,MoveSpeed] 
		gosub movement [-14.0, 35.0, 35.0, 20.0,-35.0,-35.0,MoveSpeed] 
		gosub movement [  0.0, 35.0, 35.0,  0.0,-35.0,-35.0,MoveSpeed] 
		gosub movement [  0.0,-35.0,-35.0,  0.0, 35.0, 35.0,MoveSpeed] 
		gosub movement [-14.0,-35.0,-35.0, 20.0, 35.0, 35.0,MoveSpeed] 
		gosub movement [-14.0,-35.0,-35.0, 20.0,  0.0,  0.0,MoveSpeed]
		gosub movement [ 16.0,-35.0,-35.0,-18.0,  0.0,  0.0,MoveSpeed]
		gosub movement [ 16.0,  0.0,  0.0,-18.0,  0.0,  0.0,MoveSpeed]
		gosub movement [  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,MoveSpeed]
		ServoWait = FALSE
	endif
	goto main 


#IF CONTROLLER
;--------------------------------------------------------------------
;[CommandInput] reads the input data from the PS2 controller and processes the
;data to the parameters.
CommandInput:
	low PS2SEL
	shiftout PS2CMD,PS2CLK,FASTLSBPRE,[$1\8]
	shiftin PS2DAT,PS2CLK,FASTLSBPOST,[DS2Mode\8]
	high PS2SEL
	pause 1
	
	low PS2SEL
	shiftout PS2CMD,PS2CLK,FASTLSBPRE,[$1\8,$42\8]	
	shiftin PS2DAT,PS2CLK,FASTLSBPOST,[DualShock(0)\8, DualShock(1)\8, DualShock(2)\8, DualShock(3)\8, |
	DualShock(4)\8, DualShock(5)\8, DualShock(6)\8]
	high PS2SEL
	pause 1	
	
	;serout s_out,i14400,[dec DS2Mode, 13]
	DS2Mode = DS2Mode & 0x7F
	if DS2Mode <> PadMode THEN
		low PS2SEL
		shiftout PS2CMD,PS2CLK,FASTLSBPRE,[$1\8,$43\8,$0\8,$1\8,$0\8] ;CONFIG_MODE_ENTER
		high PS2SEL
		pause 1
		
		low PS2SEL
		shiftout PS2CMD,PS2CLK,FASTLSBPRE,[$01\8,$44\8,$00\8,$01\8,$03\8,$00\8,$00\8,$00\8,$00\8] ;SET_MODE_AND_LOCK
		high PS2SEL
		pause 1
		
		low PS2SEL
		shiftout PS2CMD,PS2CLK,FASTLSBPRE,[$01\8,$4F\8,$00\8,$FF\8,$FF\8,$03\8,$00\8,$00\8,$00\8] ;SET_DS2_NATIVE_MODE
		high PS2SEL
		pause 1
		
		low PS2SEL
		shiftout PS2CMD,PS2CLK,FASTLSBPRE,[$01\8,$43\8,$00\8,$00\8,$5A\8,$5A\8,$5A\8,$5A\8,$5A\8] ;CONFIG_MODE_EXIT_DS2_NATIVE
		high PS2SEL
		pause 1
		
		low PS2SEL
		shiftout PS2CMD,PS2CLK,FASTLSBPRE,[$01\8,$43\8,$00\8,$00\8,$00\8,$00\8,$00\8,$00\8,$00\8] ;CONFIG_MODE_EXIT
		high PS2SEL
		pause 100
			
		sound P9,[100\3000, 100\3500, 100\4000]
		return
	ENDIF
	
	IF (DualShock(1).bit3 = 0) and LastButton(0).bit3 THEN	;Start Button
		gosub toggleStandby command
		return command
	ENDIF	

	;we only listen to the controller if the bot is in active mode. 
	IF BotActive THEN  
	
		IF (DualShock(1).bit0 = 0) and LastButton(0).bit0 THEN ;Select Button
			gosub toggleLaser
			IdleBot = 0
		ENDIF
				
				
		IF (DualShock(1).bit4 = 0) THEN;and LastButton(0).bit4 THEN	;Up Button
			sound P9,[100\4000]
			MoveSpeed = MoveSpeed -10.0
		ENDIF
		
		IF (DualShock(1).bit5 = 0) THEN;and LastButton(0).bit4 THEN	;Right Button
			sound P9,[100\5000]
			AnkleAdj = AnkleAdj + 0.5
			
		ENDIF
		
		IF (DualShock(1).bit6 = 0) THEN;and LastButton(0).bit4 THEN	;Down Button
			sound P9,[100\6000]
			MoveSpeed = MoveSpeed +10.0
		ENDIF
		
		IF (DualShock(1).bit7 = 0) THEN;and LastButton(0).bit6 THEN	;Left Button 
		    sound P9,[100\7000]
		    AnkleAdj = AnkleAdj - 0.5
		ENDIF
		
		IF (DualShock(2).bit4 = 0) and LastButton(1).bit4 THEN	;Triangle Button 
			sound 9,[500\3000]
			;if (TMRW.bit1) then
			;	TMRW.bit1=0
			;else
			;	HPWM LAMP, 2000, 1000
			;	low LAMP
			;endif
			high LAMP
			IdleBot = 0
		ENDIF
		
		IF (DualShock(2).bit5 = 0) and (LastButton(1).bit5) THEN	;Circle Button 
			IdleBot = 0
			return  CMD_TURN_RIGHT
		ENDIF	
		
		IF (DualShock(2).bit6 = 0) and (LastButton(1).bit6) THEN	;Cross Button 
			TurrentAngle = 0
			IdleBot = 0
			return CMD_READY
		ENDIF	
		
		IF (DualShock(2).bit7 = 0) and LastButton(1).bit7 THEN	;Square 
			IdleBot = 0
			return CMD_TURN_LEFT
		ENDIF			
		
		IF (DualShock(2).bit2 = 0) THEN  ;L1 Button Down
			high LGUN
			IdleBot = 0	
		ELSEIF (DualShock(2).bit2)  ;L1 Up
			low LGUN
		ENDIF

		IF (DualShock(2).bit3 = 0) THEN  ;R1 Button Down
			high RGUN
			IdleBot = 0	
		ELSEIF (DualShock(2).bit3)  ;R1 Up
			low RGUN
		ENDIF
		
		IF (DualShock(2).bit0 = 0) THEN  ;L2 Button test
			sound P9,[100\3000]
		ENDIF
		
		IF (DualShock(2).bit1 = 0) THEN  ;R2 Button test
			sound P9,[100\3000]
		ENDIF

			
		IF (DualShock(1).bit1 = 0) THEN;and LastButton(0).bit1 THEN	;L3 Button (Left Analog Click)
			;sound P9,[100\4000]
			TurrentMode = 0
		ENDIF
		
		IF (DualShock(1).bit2 = 0) and LastButton(0).bit2 THEN	;R3 Button (Right Analog Click)
			sound P9,[100\1000]
			TurrentMode = NOT TurrentMode ;invert bit
		ENDIF
		
		IF TurrentMode = 0	THEN ;relative mode
		    PS2Yaw = (Dualshock(3) - 128) 
			IF ( ABS(PS2Yaw)> TravelDeadZone) THEN  ; Right Analog (L/R)
			    
				IF PS2Yaw > 0 THEN
					TurrentAngle = MAX_TURRENT_YAW
				ELSE 
					TurrentAngle = -MAX_TURRENT_YAW
				ENDIF
				hservo [Turret\(TurrentAngle + aServoOffsets(6))\ABS(PS2Yaw)]
				IdleBot = 0	
			ELSE
				gethservo Turret,TurrentAngle,idle
				hservo [Turret\(TurrentAngle)\(0)]			
			ENDIF
			
			IF (ABS(Dualshock(4)-128) > TravelDeadZone) THEN  ; Right Analog (U/D)					
				RHipAngle = RHipAngle + ((Dualshock(4) -128) / 2)
				IF RHipAngle > MAX_TURRENT_PITCH THEN
					RHipAngle = MAX_TURRENT_PITCH
				ELSEIF RHipAngle < -MAX_TURRENT_PITCH 
					RHipAngle = -MAX_TURRENT_PITCH
				ENDIF		
				LHipAngle = LHipAngle - ((Dualshock(4) -128) / 2)
				IF LHipAngle > MAX_TURRENT_PITCH THEN
					LHipAngle = MAX_TURRENT_PITCH
				ELSEIF LHipAngle < -MAX_TURRENT_PITCH 
					LHipAngle = -MAX_TURRENT_PITCH
				ENDIF
				hservo [righthip\(RHipAngle + aServoOffsets(0))\(TurrentSpeed / 8),lefthip\(LHipAngle + aServoOffsets(3))\(TurrentSpeed / 8)]
				IdleBot = 0	
			ENDIF
		ENDIF
		
		IF TurrentMode = 1 THEN;absloute mode
			IF (ABS(DualShock(3)-128) > TravelDeadZone) THEN  ; Right Analog (L/R)
				IdleBot = 0	
			ENDIF 
			TurrentAngle = (Dualshock(3) - 128) * (MAX_TURRENT_YAW/128)
			hservo [Turret\(TurrentAngle + aServoOffsets(6))\TurrentSpeed]

			IF (ABS(Dualshock(4)-128) > TravelDeadZone) THEN  ; Right Analog (U/D)								
				IdleBot = 0	
			ENDIF
			RHipAngle = (Dualshock(4) - 128) * (MAX_TURRENT_PITCH/128)
			LHipAngle = -RHipAngle
			hservo [righthip\(RHipAngle + aServoOffsets(0))\(TurrentSpeed / 2),lefthip\(LHipAngle + aServoOffsets(3))\(TurrentSpeed / 2)]
		ENDIF
		
		IF (ABS(Dualshock(6)-128) > TravelDeadZone) THEN  ; Left Analog
			PS2Thrust = TOFLOAT(Dualshock(6) - 128) / 128.0  ; +- 1.0
			WalkSpeed = StrideConst * PS2Thrust
			WalkAngle = 12.0 + AnkleAdj	
			StrideLengthLeft = WalkSpeed
			StrideLengthRight = WalkSpeed
			IF (ABS(Dualshock(5)-128) > TravelDeadZone) THEN
				PS2Turn = TOFLOAT(Dualshock(5) - 128) / 512.0  ; +- 0.25
				StrideLengthLeft = StrideLengthLeft + (StrideLengthLeft * PS2Turn)
				StrideLengthRight = StrideLengthRight + (StrideLengthRight * -PS2Turn)
			ENDIF
			IdleBot = 0
			return  CMD_WALK
		ENDIF
	ENDIF
	return 99
#ELSE
in var byte
CommandInput:
	hserin 10, nomore, [in]
	hserstat 2 ; clear in & out buffer
	IdleBot = 0
	if in = "o" then
		gosub toggleStandby command
		return command
	endif
	if NOT BotActive then
		hserout ["E"]
		hserstat 2 ; clear in & out buffer
		return 99
	endif
	if in = "l" then
		gosub toggleLaser
	elseif in = "w"
		WalkAngle = 12.0 + AnkleAdj	
		StrideLengthLeft = -StrideConst
		StrideLengthRight = -StrideConst
		return  CMD_WALK
	elseif in = "s"
		WalkAngle = 12.0 + AnkleAdj	
		StrideLengthLeft = StrideConst
		StrideLengthRight = StrideConst
		return  CMD_WALK
	elseif in = "a"
		return CMD_TURN_LEFT
	elseif in = "d"
		return CMD_TURN_RIGHT
	endif
	;hserout ["K"]
	nomore:
	return 99
#ENDIF


;=========================================
; Walk subroutine
;=========================================
lefthippos var float 
leftkneepos var float 
leftanklepos var float 
righthippos var float 
rightkneepos var float 
rightanklepos var float
last_lefthippos var float 
last_leftkneepos var float 
last_leftanklepos var float 
last_righthippos var float 
last_rightkneepos var float 
last_rightanklepos var float
lhspeed var float 
lkspeed var float 
laspeed var float 
rhspeed var float 
rkspeed var float 
raspeed var float 
speed var float 
longestmove var float 
movement [rightanklepos,rightkneepos,righthippos,leftanklepos,leftkneepos,lefthippos,speed]
	if(speed<>0.0)then 
	  gosub getlongest[lefthippos-last_lefthippos, | 
	               leftkneepos-last_leftkneepos, | 
	               leftanklepos-last_leftanklepos, | 
	               righthippos-last_righthippos, | 
	               rightkneepos-last_rightkneepos, | 
	               rightanklepos-last_rightanklepos],longestmove
	  speed = ((longestmove*stepsperdegree)/(speed/20.0)) 
	  gosub getspeed[lefthippos,last_lefthippos,longestmove,speed],lhspeed 
	  gosub getspeed[leftkneepos,last_leftkneepos,longestmove,speed],lkspeed 
	  gosub getspeed[leftanklepos,last_leftanklepos,longestmove,speed],laspeed 
	  gosub getspeed[righthippos,last_righthippos,longestmove,speed],rhspeed 
	  gosub getspeed[rightkneepos,last_rightkneepos,longestmove,speed],rkspeed 
	  gosub getspeed[rightanklepos,last_rightanklepos,longestmove,speed],raspeed
	else 
	  lhspeed=0.0; 
	  lkspeed=0.0; 
	  laspeed=0.0; 
	  rhspeed=0.0; 
	  rkspeed=0.0; 
	  raspeed=0.0; 
	endif 
	hservo [lefthip\TOINT (-lefthippos*stepsperdegree) + aServoOffsets(3)\TOINT lhspeed, | 
	     righthip\TOINT (righthippos*stepsperdegree) + aServoOffsets(0)\TOINT rhspeed, | 
	     leftknee\TOINT (-leftkneepos*stepsperdegree) + aServoOffsets(4)\TOINT lkspeed, | 
	     rightknee\TOINT (rightkneepos*stepsperdegree) + aServoOffsets(1)\TOINT rkspeed, | 
	     leftankle\TOINT (-leftanklepos*stepsperdegree) + aServoOffsets(5)\TOINT laspeed, | 
	     rightankle\TOINT (rightanklepos*stepsperdegree) + aServoOffsets(2)\TOINT raspeed]
	if ServoWait then
		hservowait [lefthip,righthip,leftknee,rightknee,leftankle,rightankle]
	endif
	last_lefthippos = lefthippos 
	last_leftkneepos = leftkneepos 
	last_leftanklepos = leftanklepos 
	last_righthippos = righthippos 
	last_rightkneepos = rightkneepos 
	last_rightanklepos = rightanklepos 
	return 


;=========================================
; Returns the largest value
;=========================================
one var float 
two var float 
three var float 
four var float 
five var float 
six var float 
getlongest[one,two,three,four,five,six]
	if(one<0.0)then 
	  one=-1.0*one 
	endif 
	if(two<0.0)then 
	  two=-1.0*two 
	endif 
	if(three<0.0)then 
	  three=-1.0*three 
	endif 
	if(four<0.0)then 
	  four=-1.0*four 
	endif 
	if(five<0.0)then 
	  five=-1.0*five 
	endif 
	if(six<0.0)then 
	  six=-1.0*six 
	endif
	if(one<two)then 
	  one=two 
	endif 
	if(one<three)then 
	  one=three 
	endif 
	if(one<four)then 
	  one=four 
	endif 
	if(one<five)then 
	  one=five 
	endif 
	if(one<six)then 
	  one=six 
	endif
	;debug["Longest: ",one,13,10]
	return one 

   
;=========================================
; Returns the speed needed to move from oldpos to new pos in the alloted time. 
;=========================================
newpos var float
oldpos var float 
longest var float 
maxval var float 
getspeed[newpos,oldpos,longest,maxval] 
	if(newpos>oldpos)then 
		return ((newpos-oldpos)/longest)*maxval 
	endif 
	return ((oldpos-newpos)/longest)*maxval


;=========================================
; See if we are walking
;=========================================
junk var word
isWalking:
	gethservo lefthip,junk,idle
	;LHipAngle = junk
	if (NOT idle) then
		return TRUE
	endif
	
	gethservo righthip,junk,idle
	;RHipAngle = junk
	if (NOT idle) then
		return TRUE
	endif
	
	gethservo leftknee,junk,idle
	if (NOT idle) then
		return TRUE
	endif
	
	gethservo rightknee,junk,idle
	if (NOT idle) then
		return TRUE
	endif

	gethservo leftankle,junk,idle
	if (NOT idle) then
		return TRUE
	endif
	
	gethservo rightankle,junk,idle
	if (NOT idle) then
		return TRUE
	endif

	return FALSE


;=========================================
; Toggles standby on or off
;=========================================
toggleStandby:
	if (BotActive) then
		'Turn off
		Sound P9,[100\4400,80\3800,60\3200]
		BotActive = FALSE
		if (LaserOn) then
			gosub toggleLaser
		endif
		return CMD_REST
	else
		'Turn on
		Sound P9,[60\3200,80\3800,100\4400]
		BotActive = TRUE
		IdleBot = 0
		return CMD_READY
	endif
	return


;=========================================
; Toggles laser on or off
;=========================================
toggleLaser:
	if (LaserOn) then
		LaserOn = FALSE
		low Laser
		Sound P9,[40\3500,80\3200]
	else
		LaserOn = TRUE
		high Laser
		Sound P9,[40\3200,80\3500]
	endif
	return


;=========================================
; Operate our Ping))
;=========================================
InConstant con 148  ; Conversion constants for room temperature measurements.
Sonar var word
Ping:
	;do
		pulsout	P19, 5
		input P19
		pulsin P19, 0, Sonar
		low P19
		
		sound 9,[100\(2000 + (Sonar / InConstant) * 100)]
		;debug["Sonar: ",dec(Sonar * InConstant),13,10]
		
		pause 100
	;while 1
	return


;=========================================
; Operate our IR sensor
;=========================================
volts var word
IR:
	;do
		adin P18,volts
		
		sound 9,[100\(2000 + (volts * 100))]
		;debug["Sonar: ",dec(Sonar * InConstant),13,10]
		
		pause 100
	;while 1
	return


