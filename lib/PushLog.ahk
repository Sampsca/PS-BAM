;
; AutoHotkey Version: 1.1.22.04
; Language:       English
; Platform:       Optimized for Windows 7
; Author:         Sam.
;

/*
Usage syntax is as follows:
Console:=New PushLog("Blank v0.00a, Copyright (c) 2015 me")
Console.Send("Some Text`r`nHere...`r`n")
Console:=""
*/

/* Debug Levels:
 * -1 = very silent (no log)
 * 0 = Silent  (errors only)
 * 1 = Normal  (errors and warnings)
 * 2 = Verbose (errors, warnings, extra info)
 */

class PushLog{	; Updated 20170124 by Sam.
	__New(_AboutInfo:="Blank v0.00a, Copyright (c) 2015 me", _SavePath:="", _Debug:=1){
		this.DebugLevel:=_Debug
		If (this.DebugLevel<0)
			Return
		this.SavePath:=_SavePath	; A_ScriptDir "\log.txt"
		DllCall("AttachConsole", "UInt", -1)
		; Open a console window:
		this.PushLogNewConsole:=DllCall("AllocConsole")
		; Open the application's stdin/stdout streams in newline-translated mode.
		this.stdin  := FileOpen("*", "r `n")  ; Requires v1.1.17+
		this.stdout := FileOpen("*", "w `n")
		; Push initial info ;
		FormatTime, TimeString, ,MMMM dd, yyyy 'at' h:mm.ss tt
		this.Send("`r`n" _AboutInfo "`r`nInitializing logging of errors and warnings on " TimeString ".`r`n")
	}
	Send(data:="`r`n",_DebugClass:="",_WriteToFile:=1){
		If (this.DebugLevel<0)
			Return
		Else If (_DebugClass="")
			data:=(this.DebugLevel<>0?data:"")
		Else If InStr(_DebugClass,"E")
			data:=(this.DebugLevel>=0?(!InStr(_DebugClass,"-")?A_Space A_Space "E:" A_Space data:data):"")
		Else If InStr(_DebugClass,"W")
			data:=(this.DebugLevel>=1?(!InStr(_DebugClass,"-")?A_Space A_Space "W:" A_Space data:data):"")
		Else If InStr(_DebugClass,"I")
			data:=(this.DebugLevel>=2?(!InStr(_DebugClass,"-")?A_Space A_Space "I:" A_Space data:data):"")
		Else
			data:=(this.DebugLevel>=2?(!InStr(_DebugClass,"-")?A_Space A_Space _DebugClass ":" A_Space data:data):"")
		If (data<>"")
			{
			If (_WriteToFile>=0)
				{
				this.stdout.Write(data)
				this.stdout.Read(0) ; Flush the write buffer.
				}
			If (this.SavePath<>"") AND (_WriteToFile<>0)
				FileAppend, %data%, % (this.SavePath)
			}
	}
	__Delete(){ ;doesn't close console window...
		If (this.DebugLevel<0)
			this.DebugLevel:=2 ;Return
		A_Quote=`"
		FormatTime, TimeString, ,MMMM dd, yyyy 'at' h:mm.ss tt
		Log:="Logging terminated on " TimeString ".`r`n"
		If (this.SavePath<>"")
			Log.="A copy of this information has been saved to " A_Quote (this.SavePath) A_Quote "."
		Log.="`r`n`r`n"
		this.Send(Log)
		this.Send("Press Enter to continue . . .","",0)
		;~ If (this.PushLogNewConsole=1)
			;~ query:=RTrim(this.stdin.ReadLine(), "`n")
		this.stdout.Read(0) ; Flush the write buffer.
		this.Send("`r`n`r`n","",0)
		this.stdin.Close()
		this.stdout.Close()
		;~ Sleep, 10000
		DllCall("FreeConsole")
	}
}