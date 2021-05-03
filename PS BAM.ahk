;
; AutoHotkey Version: 1.1.33.08
; Language:       English
; Platform:       Optimized for Windows 10
; Author:         Sam.
;

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn All, StdOut  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance OFF ;Force  ; Skips the dialog box and replaces the old instance automatically, which is similar in effect to the Reload command.
#MaxMem 1024	; Consider turning this back off before release...
Process, Priority, , A
SetBatchLines, -1
OnError("Traceback")

try {

Global PS_Version:="v0.0.0.21a"
Global PS_Arch:=(A_PtrSize=8?"x64":"x86"), PS_DirArch:=A_ScriptDir "\PS BAM (files)\" PS_Arch
Global PS_Temp:=RegExReplace(A_Temp,"\\$") "\PS BAM"
Global PS_TotalBytesSaved:=0
Global PS_SummaryA:=[]
Global Settings:={}
	SetSettings()
Global A_Quote:=Chr(34)
Global PS_Settings:=A_Quote A_ScriptFullPath A_Quote A_Space
Global pToken
	pToken:=Gdip_Startup()

If (Settings.MaxThreads>1)
	{
	Settings.DebugLevelL:=-1
	Settings.DebugLevelP:=-1
	Settings.DebugLevelS:=-1
	Settings.LogFile:=""
	}

Global Console:=New PushLog("////////////////////////////////////////////////////////////`r`n// PS BAM " PS_Version ", Copyright (c) 2012-2021 Sam Schmitz //`r`n////////////////////////////////////////////////////////////",Settings.LogFile,2)

;~ InPath:=A_ScriptDir "\mdr11207.bam"
;~ InPath:=A_ScriptDir "\CDMF4G12_orig.bam"
;~ InPath:=A_ScriptDir "\AMOOG11.bam"
;~ InPath:="D:\Program Files\Infinity Engine Modding Tools\Miloch's BAM Utility\bambatch\bam\ihelmk5.bam"
;~ InPath:=A_ScriptDir "\-zlib+RLE.bam"
;~ Outpath:=A_ScriptDir "\temp.bam"


;ProcessFile(InPath,Outpath)
ProcessCLIArgOpt()
Console.Send(FormatPS_SummaryA())
Console.Send("Total Bytes Saved=" PS_TotalBytesSaved "`r`n")
;~ ProcessFile("C:\Users\Sam\Desktop\bone.bam",A_ScriptDir "\temp2.bam")

OnExit:
Console:=""
Gdip_Shutdown(pToken)
ExitApp

	} catch e {
		; throw { what: (IsFunc(A_ThisFunc)?"function: " A_ThisFunc "()":"") A_Tab (IsLabel(A_ThisLabel)?"label: " A_ThisLabel:""), file: A_LineFile, line: A_LineNumber, message: "", extra: ""}
		Console.Send("Exception thrown!`n`nWhat	=	" e.what "`nFile	=	" e.file "`nLine	=	" e.line "`nMessage	=	" e.message "`nExtra	=	" e.extra "`r`n","E")
		;ThrowMsg(16,"Error!","Exception thrown!`n`nWhat	=	" e.what "`nFile	=	" e.file "`nLine	=	" e.line "`nMessage	=	" e.message "`nExtra	=	" e.extra)
		ExceptionErrorDlg(e)
		Console:=""
		Gdip_Shutdown(pToken)
		ExitApp
		}

FormatPS_SummaryA(){
	_PS_SummaryTxt:=FormatStr("Name",A_Space,20,"C") A_Space FormatStr("OriginalSize",A_Space,12,"C") A_Space FormatStr("UncompressedSize",A_Space,16,"C") A_Space FormatStr("CompressedSize",A_Space,14,"C") A_Space FormatStr("%OfOriginalSize",A_Space,15,"C") A_Space FormatStr("%OfUncompressedSize",A_Space,19,"C") A_Space FormatStr("Time",A_Space,16,"C") "`r`n"
	For k,v in PS_SummaryA
		_PS_SummaryTxt.=FormatStr(v["Name"],A_Space,20,"C") A_Space FormatStr(v["OriginalSize"],A_Space,12,"C") A_Space FormatStr(v["UncompressedSize"],A_Space,16,"C") A_Space FormatStr(v["CompressedSize"],A_Space,14,"C") A_Space FormatStr(v["%OfOriginalSize"],A_Space,15,"C") A_Space FormatStr(v["%OfUncompressedSize"],A_Space,19,"C") A_Space FormatStr(v["Time"],A_Space,16,"C") "`r`n"
	Return _PS_SummaryTxt "`r`n"
}

ProcessCLIArgOpt(){
	Options:={}, OrigLog:=Settings.LogFile
	For k, v in Settings
		Options.Push(k "=")
	Instance:=New getopt("",Options,1)
		For key, val in Instance["opts"]	; Option(s)
			{
			option:=val[1], parameter:=val[2]
			While (SubStr(option,1,1)="-") OR (((SubStr(option,1,1)="\") OR (SubStr(option,1,1)="/")) AND (Instance.supportslash=1))
				StringTrimLeft, option, option, 1
			Settings[option]:=parameter
			If (option="CompressionProfile") AND (parameter<>"")
				SetCompressionProfile()
			Else If (option="OutPath")
				Settings[option]:=RegExReplace(parameter,"\\$") ; Settings.OutPath must not end in a "\" 20201212
			}
		If (OrigLog<>Settings.LogFile)
			{
			Console.ModifySavePath(Settings.LogFile) ; was Console.SavePath:=Settings.LogFile
			FormatTime, TimeString, ,MMMM dd, yyyy 'at' h:mm.ss tt
			Console.Send("////////////////////////////////////////////////////////////`r`n// PS BAM " PS_Version ", Copyright (c) 2012-2021 Sam Schmitz //`r`n////////////////////////////////////////////////////////////`r`nInitializing logging of errors and warnings on " TimeString ".`r`n","",-1)
			}
		Console.Send("//////////////////// Settings ////////////////////`r`n","-I")
		
		;~ If (Settings.CompressionProfile<>"")
			;~ SetCompressionProfile()
		For key, val in Settings
			{
			If (val="") OR InStr(val,A_Space) OR InStr(val,"-")
				val:= A_Quote val A_Quote
			Console.Send("--" key A_Space val A_Space,"-I")
			If (key="MaxThreads")
				PS_Settings.="--" key A_Space 1 A_Space
			Else
				PS_Settings.="--" key A_Space val A_Space
			}
		Console.Send("`r`n//////////////////////////////////////////////////`r`n","-I")
		For key, val in Instance["args"]	; filename(s)
			{
			;val:="D:\AutoHotkey Scripts\BAMs\ToSC\CEFF1W2.BAM"
			If (Settings.MaxThreads>1)
				{
				If (GetThreadCount() < Settings.MaxThreads)
					{
					LogFile:=Settings.LogFile
					SplitPath, LogFile, OutFileName, OutDir, OutExtension, OutNameNoExt, OutDrive
					Unique:=A_TickCount
					UniqueBAT:=A_Temp "\PS BAM_" Unique ".bat"
					StringReplace, PS_Settings, PS_Settings, --LogFile %A_Quote%%OutDir%\%OutFileName%%A_Quote%, --LogFile %A_Quote%%OutDir%\%OutNameNoExt%_%Unique%.%OutExtension%%A_Quote%, All
					FileAppend, %PS_Settings% %A_Quote%%val%%A_Quote%`n(goto) 2>nul & del "`%~f0", %UniqueBAT%
					Run, %UniqueBAT%
					Continue
					}
				Else
					{
					While (GetThreadCount()=Settings.MaxThreads)
						Sleep, 1000
					Continue
					}
				}
			Else
				{
				ProcessFile(val,GetOutPath(val))
				If (Settings.VerifyOutput)
					VerifyOutput(GetOutPath(val) "." Settings.Save)
				Console.Send("`r`n`r`n","-W")
				Console.Send("//////////////////////////////////////////////////`r`n","-E")
				}
			}
		If !Instance["args"].Count() ; No input files found (20201231)
			Console.Send("No input files were found.  Double check the directory, filename, and file extension.  If a wildcard was used in the input, ensure you are properly matching the desired files.`r`n","W")
	Instance:=""
}

SetCompressionProfile(){
	Arr:=StrSplit(Settings.CompressionProfile,A_Space)
	Loop, % Arr.Length()
		{
		If (Arr[A_Index]="Recommended")
			Settings.FixPaletteColorErrors:=1, Settings.AutodetectPalettedBAM:=1, Settings.DropDuplicatePaletteEntries:=1, Settings.DropUnusedPaletteEntries:=1, Settings.SearchTransColor:=1, Settings.ForceTransColor:=1, Settings.ForceShadowColor:=0, Settings.AlphaCutoff:=10, Settings.AllowShortPalette:=1, Settings.TrimFrameData:=1, Settings.ExtraTrimBuffer:=2, Settings.ExtraTrimDepth:=3, Settings.ReduceFrameRowLT:=1, Settings.ReduceFrameColumnLT:=1, Settings.ReduceFramePixelLT:=1, Settings.DropDuplicateFrameData:=1, Settings.DropUnusedFrameData:=1, Settings.IntelligentRLE:=1, Settings.MaxRLERun:=255, Settings.FindBestRLEIndex:=0, Settings.DropDuplicateFrameEntries:=1, Settings.DropUnusedFrameEntries:=1, Settings.AdvancedFLTCompression:=1, Settings.FLTSanityCutoff:=720, Settings.DropEmptyCycleEntries:=1, Settings.AdvancedZlibCompress:=2, Settings.zopfliIterations:=1000
		Else If (Arr[A_Index]="Max")
			Settings.FixPaletteColorErrors:=1, Settings.AutodetectPalettedBAM:=0, Settings.DropDuplicatePaletteEntries:=1, Settings.DropUnusedPaletteEntries:=1, Settings.SearchTransColor:=1, Settings.ForceTransColor:=1, Settings.AlphaCutoff:=10, Settings.AllowShortPalette:=1, Settings.TrimFrameData:=1, Settings.ExtraTrimBuffer:=2, Settings.ExtraTrimDepth:=3, Settings.ReduceFrameRowLT:=1, Settings.ReduceFrameColumnLT:=1, Settings.ReduceFramePixelLT:=1, Settings.DropDuplicateFrameData:=1, Settings.DropUnusedFrameData:=1, Settings.IntelligentRLE:=1, Settings.MaxRLERun:=255, Settings.FindBestRLEIndex:=1, Settings.DropDuplicateFrameEntries:=1, Settings.DropUnusedFrameEntries:=1, Settings.AdvancedFLTCompression:=1, Settings.FLTSanityCutoff:=5040, Settings.DropEmptyCycleEntries:=1, Settings.AdvancedZlibCompress:=2, Settings.zopfliIterations:=1000
		Else If (Arr[A_Index]="Safe")
			Settings.FixPaletteColorErrors:=1, Settings.AutodetectPalettedBAM:=1, Settings.DropDuplicatePaletteEntries:=0, Settings.DropUnusedPaletteEntries:=0, Settings.SearchTransColor:=1, Settings.ForceTransColor:=0, Settings.ForceShadowColor:=0, Settings.AlphaCutoff:=10, Settings.AllowShortPalette:=0, Settings.TrimFrameData:=1, Settings.ExtraTrimBuffer:=0, Settings.ExtraTrimDepth:=0, Settings.ReduceFrameRowLT:=1, Settings.ReduceFrameColumnLT:=1, Settings.ReduceFramePixelLT:=1, Settings.DropDuplicateFrameData:=1, Settings.DropUnusedFrameData:=1, Settings.IntelligentRLE:=1, Settings.MaxRLERun:=254, Settings.FindBestRLEIndex:=0, Settings.DropDuplicateFrameEntries:=1, Settings.DropUnusedFrameEntries:=1, Settings.AdvancedFLTCompression:=1, Settings.FLTSanityCutoff:=720, Settings.AdvancedZlibCompress:=0
		Else If (Arr[A_Index]="Quick") OR (Arr[A_Index]="Fast")
			Settings.FixPaletteColorErrors:=1, Settings.AutodetectPalettedBAM:=1, Settings.DropDuplicatePaletteEntries:=1, Settings.DropUnusedPaletteEntries:=1, Settings.SearchTransColor:=1, Settings.ForceTransColor:=1, Settings.ForceShadowColor:=0, Settings.AlphaCutoff:=10, Settings.AllowShortPalette:=1, Settings.TrimFrameData:=1, Settings.ExtraTrimBuffer:=2, Settings.ExtraTrimDepth:=3, Settings.ReduceFrameRowLT:=1, Settings.ReduceFrameColumnLT:=1, Settings.ReduceFramePixelLT:=1, Settings.DropDuplicateFrameData:=1, Settings.DropUnusedFrameData:=1, Settings.IntelligentRLE:=1, Settings.MaxRLERun:=254, Settings.FindBestRLEIndex:=0, Settings.DropDuplicateFrameEntries:=1, Settings.DropUnusedFrameEntries:=1, Settings.AdvancedFLTCompression:=1, Settings.FLTSanityCutoff:=1, Settings.DropEmptyCycleEntries:=1, Settings.AdvancedZlibCompress:=1
		Else If (Arr[A_Index]="None")
			Settings.OrderOfOperations:=StrReplace(Settings.OrderOfOperations,"C")
		; BG1 | PST | IWD | BG2 | IWD2 | EE
		Else If (Arr[A_Index]="BG1") OR (Arr[A_Index]="PST")
			{
			Settings.AdvancedZlibCompress:=0
			Settings.ForceTransColor:=1	; May also want to include Settings.SearchTransColor:=1 here.
			}
		Else If (Arr[A_Index]="EE")
			Settings.FindBestRLEIndex:=0
		}
}

GetThreadCount(){
	DetectHiddenWindows, On
	SetTitleMatchMode, 2
	WinGet, ThreadCount, list, PS BAM ahk_class AutoHotkey
	Return ThreadCount
}

ProcessFile(Input,Output){
	try {
		tic:=QPC(1)
		If InStr(Input,A_Quote)
			throw Exception("The input filename " A_Quote Input A_Quote " contains invalid characters.  Because Windows is stupid, OutPath must NOT end in a slash (" A_Quote "\" A_Quote ") when passed to PS BAM as a parameter, so check that.  Otherwise, check your use of double quotes.",,"`n`n" Traceback())
		BAM:=New PSBAM()
		Console.DebugLevel:=Settings.DebugLevelL
		SplitPath, Input, , , OutExtension
		If (OutExtension="BAMD")
			BAM.LoadBAMD(Input)
		Else If InStr(OutExtension,"bam")
			BAM.LoadBAM(Input)
		Else
			{
			BaseFileName:=BAM.LoadImages(Input)
			SplitPath, Output, OutFileName, OutDir, OutExtension, OutNameNoExt, OutDrive
			Output:=OutDir "\" BaseFileName
			;~ Console.Send(st_printArr(BAM))
			; _SplitFrameName(BaseFrame,ByRef FileName,ByRef Sequence,ByRef Frame)
			}
		Console.DebugLevel:=Settings.DebugLevelP
		If FileExist(Settings.ReplacePalette)
			BAM.ReplacePalette(Settings.ReplacePalette,"","",Settings.ReplacePaletteMethod)
		If !(Settings.OrderOfOperations)
			Settings.OrderOfOperations:="PCE"
		Order:=StrSplit(Settings.OrderOfOperations,"",A_Space A_Tab)
		RLE:=Settings.IntelligentRLE, Settings.IntelligentRLE:=0
		For Index,Char in Order
			{
			If (Char="C")	; Compress
				{
				BAM.CompressBAM()
				}
			Else If (Char="P")	; Process
				{
				BAM.Process(Input)
				}
			Else If (Char="E")	; Export
				{
				If (Settings.ExportPalette)
					BAM.ExportPalette(Settings.ExportPalette,Output)
				If (Settings.ExportFrames) AND !(Settings.Save="BAMD") AND (Settings.Save<>"GIF")
					BAM.ExportFrames(Output)
				}
			}
		Settings.IntelligentRLE:=RLE
		If InStr(Settings.OrderOfOperations,"C") AND (Settings.IntelligentRLE=1) AND (Settings.Save<>"BAMD") AND (Settings.Save<>"GIF")
			BytesSaved:=BAM._RLE(), Console.Send(BytesSaved " bytes were saved by applying Intelligent RLE." "`r`n","I")
		BAM._UpdateStats()
		;~ BAM.PrintBAM()
		;~ If (Settings.CompressFirst) AND !(Settings.ProcessFirst)
			;~ {
			;~ If (Settings.Compress)
				;~ BAM.CompressBAM()
			;~ If (Settings.ExportPalette)
				;~ BAM.ExportPalette(Settings.ExportPalette,Output)
			;~ If (Settings.ExportFrames) AND !(Settings.Compress) AND !(Settings.Save="BAMD")
				;~ BAM.ExportFrames(Output)
			;~ BAM.Process()
			;~ }
		;~ Else If !(Settings.CompressFirst) AND (Settings.ProcessFirst)
			;~ {
			;~ BAM.Process()
			;~ If (Settings.ExportPalette)
				;~ BAM.ExportPalette(Settings.ExportPalette,Output)
			;~ If (Settings.ExportFrames) AND !(Settings.Save="BAMD")
				;~ BAM.ExportFrames(Output)
			;~ If (Settings.Compress)
				;~ BAM.CompressBAM()
			;~ }
		;~ Else If (Settings.CompressFirst) AND (Settings.ProcessFirst)
			;~ {
			;~ If (Settings.Compress)
				;~ BAM.CompressBAM()
			;~ If !(Settings.Compress) OR !(Settings.ExportFrames)
				;~ BAM.Process()
			;~ If (Settings.ExportPalette)
				;~ BAM.ExportPalette(Settings.ExportPalette,Output)
			;~ If (Settings.ExportFrames) AND !(Settings.Compress) AND !(Settings.Save="BAMD")
				;~ BAM.ExportFrames(Output)
			;~ }
		;~ Else ; !(Settings.CompressFirst) AND !(Settings.ProcessFirst)
			;~ {
			;~ If (Settings.ExportPalette)
				;~ BAM.ExportPalette(Settings.ExportPalette,Output)
			;~ If (Settings.ExportFrames) AND !(Settings.Save="BAMD")
				;~ BAM.ExportFrames(Output)
			;~ BAM.Process()
			;~ If (Settings.Compress)
				;~ BAM.CompressBAM()
			;~ }
		;~ If (Settings.ProcessFirst>0)
			;~ BAM.Process()
		;~ If (Settings.Compress=1) AND (Settings.CompressFirst=1)
			;~ BAM.CompressBAM()
		;~ If (Settings.ExportPalette<>"")
			;~ BAM.ExportPalette(Settings.ExportPalette,Output)
		;~ If (Settings.ExportFrames) AND ((Settings.CompressFirst<>1) OR ((Settings.Compress<>1) AND (Settings.CompressFirst=1)) ) AND !(Settings.Save="BAMD")
			;~ BAM.ExportFrames(Output)
		;~ If (Settings.Compress=1) AND (Settings.CompressFirst<>1)
			;~ BAM.CompressBAM()
		;~ If (Settings.ProcessFirst=0)
			;~ BAM.Process()
		If (Settings.Save="BAM")
			{
			Console.DebugLevel:=Settings.DebugLevelS
			BAM.SaveBAM(Output ".bam")
			}
		Else IF (Settings.Save="BAMD")
			{
			Console.DebugLevel:=Settings.DebugLevelS
			BAM.SaveBAMD((Settings.ExportFrames?Settings.ExportFrames:"bmp"),Output)
			}
		Else IF (Settings.Save="GIF")
			{
			Console.DebugLevel:=Settings.DebugLevelS
			BAM.SaveGIF(Output,Settings.SingleGIF)
			}
		Else
			{
			PS_SummaryA[PS_SummaryA.MaxIndex(),"CompressedSize"]:="N/A"
			PS_SummaryA[PS_SummaryA.MaxIndex(),"%OfOriginalSize"]:="N/A"
			PS_SummaryA[PS_SummaryA.MaxIndex(),"%OfUncompressedSize"]:="N/A"
			}
		BAM:=""
		PS_SummaryA[PS_SummaryA.MaxIndex(),"Time"]:=(QPC(1)-tic) " sec."
	} catch e {
		; throw { what: (IsFunc(A_ThisFunc)?"function: " A_ThisFunc "()":"") A_Tab (IsLabel(A_ThisLabel)?"label: " A_ThisLabel:""), file: A_LineFile, line: A_LineNumber, message: "", extra: ""}
		Console.Send("Exception thrown!`n`nWhat	=	" e.what "`nFile	=	" e.file "`nLine	=	" e.line "`nMessage	=	" e.message "`nExtra	=	" e.extra "`r`n","E")
		;ThrowMsg(16,"Error!","Exception thrown!`n`nWhat	=	" e.what "`nFile	=	" e.file "`nLine	=	" e.line "`nMessage	=	" e.message "`nExtra	=	" e.extra)
		ExceptionErrorDlg(e)
		BAM:=""
		}
}
VerifyOutput(OriginalOutput){	; Saving files to the same folder and sometimes deleting them has potential for collisions
	try {
		Console.Send("Attempting to verify processing integrity of '" OriginalOutput "'.`r`n","-W")
		If (Settings.Save="BAM") || (Settings.Save="BAMD")
			{
			tmpVer:=Settings.VerifyOutput
				Settings.VerifyOutput:=0
			OriginalMD5:=FileMD5(OriginalOutput,7)
			FileCreateDir, %PS_Temp%
			If !InStr(FileExist(PS_Temp),"D")
				throw Exception("The output directory " A_Quote PS_Temp A_Quote " could not be created.`n`nFileExist() returned '" FileExist(PS_Temp) "'.`nErrorLevel=" ErrorLevel "`nA_LastError=" A_LastError,,"`n`n" Traceback())
				;~ FileDelete, %PS_Temp%\*.*
			SplitPath, OriginalOutput, OutFileName
			SplitPath, OriginalOutput, OutFileName, OutDir, OutExtension, OutNameNoExt
			NewOutput:=PS_Temp "\" OutNameNoExt	; This includes old extension
			;MsgBox % A_Quote NewOutput A_Quote
			ProcessFile(OriginalOutput,NewOutput)
			Settings.VerifyOutput:=tmpVer
			NewMD5:=FileMD5(NewOutput "." Settings.Save,7)
			If (OriginalMD5=NewMD5)
				{
				Console.Send("Original output verified.  MD5s match: " OriginalMD5 "`r`n","-W")
				FileDelete, %PS_Temp%\*.*
				;~ FileRemoveDir, %PS_Temp%, 1
				}
			Else
				Console.Send("Original output verification failed!  MD5s do not match: " OriginalMD5 " <> " NewMD5 ".`r`nFor analysis, the doubly reprocessed version has been saved to '" NewOutput "'`r`n","E")
			}
		Else
			Console.Send("Processing integrity of output format '" Settings.Save "' cannot be verified." "`r`n","W")
	} catch e {
		; throw { what: (IsFunc(A_ThisFunc)?"function: " A_ThisFunc "()":"") A_Tab (IsLabel(A_ThisLabel)?"label: " A_ThisLabel:""), file: A_LineFile, line: A_LineNumber, message: "", extra: ""}
		Console.Send("Exception thrown!`n`nWhat	=	" e.what "`nFile	=	" e.file "`nLine	=	" e.line "`nMessage	=	" e.message "`nExtra	=	" e.extra "`r`n","E")
		;ThrowMsg(16,"Error!","Exception thrown!`n`nWhat	=	" e.what "`nFile	=	" e.file "`nLine	=	" e.line "`nMessage	=	" e.message "`nExtra	=	" e.extra)
		ExceptionErrorDlg(e)
		}
}
GetOutPath(InPath){
	InPath:=RegExReplace(InPath,"\\$") ; InPath must not end in a "\" 20201212
	SplitPath, InPath, OutFileName, OutDir, OutExtension, OutNameNoExt, OutDrive
	If (Settings.OutPath="")
		OutPath:=RegExReplace(OutDir,"\\$") "\" OutNameNoExt "_c"
	Else
		{
		OutPath:=RegExReplace(Settings.OutPath,"\\$")
		If InStr(OutPath,A_Quote)
			throw Exception("The output directory " A_Quote OutPath A_Quote " contains invalid characters.  Because Windows is stupid, OutPath must NOT end in a slash (" A_Quote "\" A_Quote ") when passed to PS BAM as a parameter (--OutPath), so check that.  Otherwise, check your use of double quotes.",,"`n`n" Traceback())
		IfNotExist, %OutPath%
			FileCreateDir, %OutPath%
		If !InStr(FileExist(OutPath),"D")
			throw Exception("The output directory " A_Quote OutPath A_Quote " could not be created.  Verify --OutPath is valid and does NOT end in a slash (" A_Quote "\" A_Quote ").`n`nFileExist() returned '" FileExist(OutPath) "'.`nErrorLevel=" ErrorLevel "`nA_LastError=" A_LastError,,"`n`n" Traceback())
		; 20201213 Need to verify OutPath really exists.  Done 20201231
		OutPath.="\" OutNameNoExt
		}
	;~ Settings.OutPathSpecific:=OutPath
	Return OutPath
	}

class PSBAM extends ExBAMIO{	; On maximizing compression through optimization of layers of indirection within the constraints of existing file formats.
	LoadBAM(InputPath){
		tic:=QPC(1)
		Console.Send("Path='" InputPath "'`r`n")
		SplitPath, InputPath, OutFileName
		PS_SummaryA[PS_SummaryA.Count()+1,"Name"]:=OutFileName
		file:=FileOpen(InputPath,"r-d")
			If !IsObject(file)
				throw Exception("The file " A_Quote InputPath A_Quote " could not be opened.`n`nA_LastError=" A_LastError,,"`n`n" Traceback())
			this.Stats:={}
			this.InputPath:=InputPath
			this.Stats.OriginalFileSize:=file.Length, Console.Send("OriginalFileSize=" this.Stats.OriginalFileSize "`r`n","I")
			PS_SummaryA[PS_SummaryA.MaxIndex(),"OriginalSize"]:=this.Stats.OriginalFileSize
			this.Stats.FileSize:=file.Length, Console.Send("FileSize=" this.Stats.FileSize "`r`n","I")
			this.Raw:=" "
			this.SetCapacity("Raw",this.Stats.FileSize)
			file.RawRead(this.GetAddress("Raw"),this.Stats.FileSize)
			file.Close()
		this.DataMem:=New MemoryFileIO(this.GetAddress("Raw"),this.Stats.FileSize)
		Console.Send("BAM loaded into memory in " (QPC(1)-tic) " sec.`r`n","-I")
		
		this._ReadBAM()
		this.Raw:="", this.Delete("Raw"), this.DataMem:=""
		Console.Send("Finished Loading BAM in " (QPC(1)-tic) " sec.`r`n","-I")
	}
	LoadBAMD(InputPath){
		tic:=QPC(1)
		Console.Send("Path='" InputPath "'`r`n")
		SplitPath, InputPath, OutFileName
		PS_SummaryA[PS_SummaryA.Count()+1,"Name"]:=OutFileName
		file:=FileOpen(InputPath,"r-d")
			If !IsObject(file)
				throw Exception("The file " A_Quote InputPath A_Quote " could not be opened.`n`nA_LastError=" A_LastError,,"`n`n" Traceback())
			file.Seek(0,0)
			this.Stats:={}
			this.InputPath:=InputPath
			this.Stats.OriginalFileSize:=file.Length ;, Console.Send("OriginalFileSize=" this.Stats.OriginalFileSize "`r`n","I")
			this.Stats.FileSize:=file.Length, Console.Send("FileSize=" this.Stats.FileSize "`r`n","I")
			this.Raw:=" "
			this.SetCapacity("Raw",this.Stats.FileSize)
			this.Raw:=file.Read()
			file.Close()
		this.DataMem:=New MemoryFileIO(this.GetAddress("Raw"),this.Stats.FileSize)
		Console.Send("BAM loaded into memory in " (QPC(1)-tic) " sec.`r`n","-I")
		this._InitializeEmptyBAM()
		this._ReadBAMD()
		this.Raw:="", this.Delete("Raw"), this.DataMem:=""
		Console.Send("Finished Loading BAMD in " (QPC(1)-tic) " sec.`r`n","-I")
	}
	LoadImages(BaseFrame){
		tic:=QPC(1)
		SplitPath, BaseFrame, OutFileName, OutDir, OutExtension, OutNameNoExt, OutDrive
		BaseFileName:="", Sequence:=Frame:=0
		this._SplitFrameName(BaseFrame,BaseFileName,Sequence,Frame)
		Console.Send("Path='" OutDir "\" BaseFileName "*'`r`n")
		PS_SummaryA[PS_SummaryA.Count()+1,"Name"]:=BaseFileName
		this.Stats:={}
		this.InputPath:=BaseFrame
		this.Stats.OriginalFileSize:=0	; Should be increased for each imported frame
		this.Stats.FileSize:=0
		this._InitializeEmptyBAM()
		IMT:=this._FindFrames(BaseFrame)
		this._ReadImages(IMT)
		PS_SummaryA[PS_SummaryA.MaxIndex(),"OriginalSize"]:=this.Stats.FileSize
		Console.Send("Finished Loading Images into BAM in " (QPC(1)-tic) " sec.`r`n","-I")
		Return BaseFileName
	}
	SaveBAM(OutputPath){
		tic:=QPC(1)
		Console.Send("`r`n","-W")
		Console.Send("SavePath='" OutputPath "'`r`n","-E")
		this._UpdateStats()
		If (this.Stats.FileSize<this.Stats.OffsetToPalette+1024)	; Prevents game from crashing from trying to read more bytes than are in the file.  Better solution would be to move Palette immediately after Header.
			{
			Console.Send("Increasing filesize beyond theoretical minimum to maintain compatibility with game engines.`r`n","W")
			this.Stats.FileSize:=this.Stats.OffsetToPalette+1024	; Force minimum required filesize ;;; Possibility for improvement
			}
		this.Delete("Raw")
		this.Raw:=" "
		this.SetCapacity("Raw",this.Stats.FileSize)
		this.DataMem:=""
		this.DataMem:=New MemoryFileIO(this.GetAddress("Raw"),this.Stats.FileSize)
		this.DataMem.Seek(0,0)
		DllCall("RtlFillMemory","Ptr",this.GetAddress("Raw"),"UInt",this.Stats.FileSize,"UChar",0)
		this._WriteBAM()
		If (Settings.AdvancedZlibCompress=2) AND InStr(Settings.OrderOfOperations,"C")
			this._zopfliCompressBAM(OutputPath)
		Else If (Settings.AdvancedZlibCompress=1) AND InStr(Settings.OrderOfOperations,"C")
			this._zlibCompressBAM()
		file:=FileOpen(OutputPath,"w-d")
			If !IsObject(file)
				throw Exception("The file " A_Quote OutputPath A_Quote " could not be opened.`n`nA_LastError=" A_LastError,,"`n`n" Traceback())
			file.RawWrite(this.GetAddress("Raw"),this.Stats.FileSize)
			file.Close()
		this.Delete("Raw"), this.DataMem:=""
		PS_TotalBytesSaved+=(this.Stats.OriginalFileSize-this.Stats.FileSize)
		Console.Send("BAM Compression saved " this.Stats.OriginalFileSize-this.Stats.FileSize " bytes.`r`n")
		PS_SummaryA[PS_SummaryA.MaxIndex(),"CompressedSize"]:=this.Stats.FileSize
		PS_SummaryA[PS_SummaryA.MaxIndex(),"%OfOriginalSize"]:=this.Stats.FileSize/this.Stats.OriginalFileSize*100 " %"
		PS_SummaryA[PS_SummaryA.MaxIndex(),"%OfUncompressedSize"]:=this.Stats.FileSize/this.Stats.FullyUncompressedSize*100 " %"
		Console.Send("BAM Saved in " (QPC(1)-tic) " sec.`r`n","-I")
		;~ Console.Send("Finished processing in " (QPC(1)-tic) " sec.`r`n")
	}
	_ReadBAM(){
		tic:=QPC(1)
		this.Stats.WasBAMC:=0
		this._ReadBAMHeader()
		If (this.Stats.Signature="BAMC") AND (this.Stats.Version="V1  ")
			{
			this._DecompressBAM()
			this._ReadBAMHeader(DataMem)
			}
		If (this.Stats.Signature="BAM ") AND (this.Stats.Version="V2  ")
			{
			this.Stats.RLEColorIndex:=0
			this._ReadV2FrameEntries()
			this._ReadCycleEntries()
			this._ReadPalette()
			this._ReadV2FrameLookupTable()
			this._ReadDataBlocks()
			this._ReadPVRZPages()
			this._ConvertPVRSubBlocksToFrames()
			this.Stats.Version:="V1  "
			this._UpdateStats()
			;throw Exception("Reading PVRZ files is not yet supported...  The first file to read would be:  " this.DataBlocks[0,"PVRZFile"],,"`n`n" Traceback())
			}
		Else
			{
			this._ReadFrameEntries()
			this._ReadCycleEntries()
			this._ReadPalette()
			this._ReadFrameLookupTable()
			If (this.Stats.Signature="BAMU")
				this._ReadBAMUFrameData(24)
			Else
				this._ReadFrameData()
			}
		this._UpdateStats()
		PS_SummaryA[PS_SummaryA.MaxIndex(),"UncompressedSize"]:=this.Stats.FileSize
		this.Stats.FullyUncompressedSize:=this.Stats.FileSize
		Console.Send("BAM read in " (QPC(1)-tic) " sec.`r`n","-I")
	}
	_ReadBAMUFrameData(bpp:=24){
		tic:=QPC(1)
		this.Stats.CountOfFrames:=this.Stats.CountOfFrameEntries, Console.Send("CountOfFrames=" this.Stats.CountOfFrames "`r`n","I")
		UPFrames:={}, BytesRead:=0, UPFrames.SetCapacity(this.Stats.CountOfFrames)
		Loop, % this.Stats.CountOfFrames
			{
			Index:=A_Index-1, PixelCount:=this.FrameEntries[Index,"Width"]*this.FrameEntries[Index,"Height"], UPFrames[Index].SetCapacity(PixelCount)
			this.FrameEntries[Index,"FramePointer"]:=Index
			this.DataMem.Seek(this.FrameEntries[Index,"OffsetToFrameData"],0)
			If !(this.FrameEntries[Index,"RLE"])	; Frame Data is NOT RLE
				{
				Loop, % PixelCount
					{
					Index2:=A_Index-1
					UPFrames[Index,Index2,"RR"]:=this.DataMem.ReadUChar(), BytesRead++
					UPFrames[Index,Index2,"GG"]:=this.DataMem.ReadUChar(), BytesRead++
					UPFrames[Index,Index2,"BB"]:=this.DataMem.ReadUChar(), BytesRead++
					If (bpp=32)
						UPFrames[Index,Index2,"AA"]:=this.DataMem.ReadUChar(), BytesRead++
					Else
						UPFrames[Index,Index2,"AA"]:=0
					}
				}
			Else	; Frame Data IS RLE
				throw Exception("Frame " Index " is RLE'd but bit depths >8 can not have RLE!",,"`n`n" Traceback())
			ByteCount:=UPFrames[Index].Count()  ;ByteCount:=(UPFrames[Index].MaxIndex()=""?0:UPFrames[Index].MaxIndex()+1)
			If (ByteCount<>PixelCount)
				Console.Send("Frame " Index " is " ByteCount " pixels long but was expected to be " PixelCount " pixels!`r`n","W")
			}
		
		this.FrameData:={}, this.FrameData.SetCapacity(this.Stats.CountOfFrames)
		Quant:=New PS_Quantization()
		Quant.AddReservedColor(0,255,0,0)
		Quant.AddReservedColor(0,0,0,0)
		For k,v in UPFrames
			For k2,v2 in v
				Quant.AddColor(v2["RR"],v2["GG"],v2["BB"],v2["AA"])
		Console.Send("ColorCount = " Quant.GetColorCount() "`r`n","I")
		Quant.Quantize(256)
		this.Palette:=PalObj:=Quant.GetPaletteObj()
		For k,v in UPFrames
			{
			this.FrameData[k].SetCapacity(v.Count())
			For k2,v2 in v
				this.FrameData[k,k2]:=Quant.GetQuantizedColorIndex(v2["RR"],v2["GG"],v2["BB"],v2["AA"])
			}
		Quant:=""
		this.Stats.Signature:="BAM " ; It is no longer an unpaletted BAM!
		this.Stats.CountOfPaletteEntries:=this.Palette.Count()
		this._CalcSizeOfFrameData(this.DataMem.Position)
		If (this.Stats.SizeOfFrameData>BytesRead)
			Console.Send("SizeOfFrameData>BytesReadFrameData (" this.Stats.SizeOfFrameData ">" BytesRead ")`r`n","W")
		Console.Send("BAM Frame Data read in " (QPC(1)-tic) " sec.`r`n","-I")
	}
	_InitializeEmptyBAM(){
		this.Stats.Signature:="BAM "
		this.Stats.Version:="V1  "
		this.Stats.OffsetToHeader:=0
		this.Stats.WasBAMC:=0
		this.Stats.CountOfFrameEntries:=0
		this.Stats.CountOfCycles:=0
		this.Stats.RLEColorIndex:=0
		this.Stats.OffsetToFrameEntries:=0
		this.Stats.OffsetToPalette:=0
		this.Stats.OffsetToFLT:=0
		this.FrameEntries:={}, this.Stats.RLE:=0
		this.Stats.OffsetToFrameData:=0
		this.Stats.OffsetToCycleEntries:=0
		this.CycleEntries:={}, this.Stats.CountOfFLTEntries:=0
		this.Stats.CountOfPaletteEntries
		this.Palette:={}, this.Stats.PaletteHasAlpha:=0
		this.Stats.OffsetToFLT:=0
		this.FrameLookupTable:={}, this.Stats.CountOfFLTEntries:=0
		this.Stats.CountOfFrames:=0
		this.FrameData:={}
		this.Stats.TransColorIndex:=0
		this.Stats.ShadowColorIndex:=1
	}
	_ReadBAMD(){
		tic:=QPC(1)
		BAMD:=this.Raw
		StringReplace, BAMD, BAMD, /, \, All	; Convert to Windows file separators
		StringReplace, BAMD, BAMD, %A_Tab%, %A_Space%, All	; Convert TABs to SPACES
		UPFrames:={}, FirstFramePath:=PalObj:=""
		Loop, Parse, BAMD, `n, `r%A_Space%%A_Tab%
			{
			If A_LoopField	; Line is not blank
				{
				If (SubStr(A_LoopField,1,7)="palette")
					{
					PalObj:=this._ReadBAMDPalette(A_LoopField)
					}
				Else If (SubStr(A_LoopField,1,5)="frame")
					{
					If !FirstFramePath
						FirstFramePath:=this._ReadBAMDFrame(UPFrames,A_LoopField)
					Else
						this._ReadBAMDFrame(UPFrames,A_LoopField)
					}
				Else If (SubStr(A_LoopField,1,8)="sequence")
					{
					this._ReadBAMDSequence(A_LoopField)
					}
				}
			}
		Loop, % UPFrames.Count() ;(UPFrames.MaxIndex()+1)	; Compensate for missing frames by adding frame of 1 trans pixel
			{
			key:=A_Index-1
			If !IsObject(UPFrames[key])
				{
				UPFrames[key]:={}
				UPFrames[key,0,"RR"]:=0, UPFrames[key,0,"GG"]:=255, UPFrames[key,0,"BB"]:=0, UPFrames[key,0,"AA"]:=0
				this.FrameEntries[key,"CenterX"]:=0
				this.FrameEntries[key,"CenterY"]:=0
				this.FrameEntries[key,"Width"]:=1
				this.FrameEntries[key,"Height"]:=1
				this.FrameEntries[key,"RLE"]:=0
				this.FrameEntries[key,"FramePointer"]:=key
				}
			}
		Loop, % this.CycleEntries.Count() ;(this.CycleEntries.MaxIndex()+1)	; Compensate for missing sequences by adding empty sequence
			{
			key:=A_Index-1
			If !IsObject(this.CycleEntries[key])
				{
				this.CycleEntries[key]:={}
				this.CycleEntries[key,"CountOfFrameIndices"]:=0
				this.CycleEntries[key,"IndexIntoFLT"]:=0
				}
			}
		If !IsObject(PalObj) AND (Settings.ReplacePaletteMethod<>"Quant")
			PalObj:=this._ReadBAMDPalette("",FirstFramePath)
		If PalObj.Count()	; We loaded a palette from somewhere
			{
			this.Palette:=PalObj
			Histo:=""
			For k,v in UPFrames
				this.FrameData[k]:=this._ConvertFrameToPaletted(v,PalObj,Histo)
			}
		Else If UPFrames.Count()	; No palette but unpaletted data so we need to quantize
			{
			Quant:=New PS_Quantization()
			Quant.AddReservedColor(0,255,0,0)
			Quant.AddReservedColor(0,0,0,0)
			For k,v in UPFrames
				For k2,v2 in v
					Quant.AddColor(v2["RR"],v2["GG"],v2["BB"],v2["AA"])
			Console.Send("ColorCount = " Quant.GetColorCount() "`r`n","I")
			Quant.Quantize(256)
			this.Palette:=PalObj:=Quant.GetPaletteObj()
			For k,v in UPFrames
				{
				If ! (v.Count())
					Console.Send("UpFrame = " k " is empty." "`r`n","W")
				For k2,v2 in v
					{
					this.FrameData[k,k2]:=Quant.GetQuantizedColorIndex(v2["RR"],v2["GG"],v2["BB"],v2["AA"])
					}
				}
			Quant:=""
			}
		
		this.Stats.CountOfPaletteEntries:=this.Palette.Count()
		this.Stats.CountOfFrameEntries:=this.FrameEntries.Count()
		this.Stats.CountOfFrames:=this.FrameData.Count()
		this.Stats.CountOfFLTEntries:=this.FrameLookupTable.Count()
		this._UpdateStats()
		this.Stats.SizeOfFrameData:=0
		PS_SummaryA[PS_SummaryA.MaxIndex(),"OriginalSize"]:=this.Stats.OriginalFileSize
		this.Stats.FullyUncompressedSize:=this.Stats.FileSize
		Console.Send("this.Stats = `r`n" st_printArr(this.Stats) "`r`n","I")
		PS_SummaryA[PS_SummaryA.MaxIndex(),"UncompressedSize"]:=this.Stats.FileSize
		Console.Send("BAMD read in " (QPC(1)-tic) " sec.`r`n","-I")
	}
	_ReadImages(ByRef IMT){
		UPFrames:={}, PalObjQ:={}, PalObjQ.SetCapacity(256), FrameNum:=HasPal:=0, Histo:="", HistoQ:={}
		Console.Send(st_printArr(IMT) "`r`n","-E")
		; Load Palette
		If (Settings.ReplacePaletteMethod<>"Quant")	; Presumably we'll be given a palette
			{
			PalObj:=""
			PAL:=New PSPAL()
			If FileExist(Settings.ReplacePalette)
				{
				PalObj:=PAL.ImportPaletteFromFile(Settings.ReplacePalette)
				Settings.ReplacePalette:="" ; Edited 20210203
				}
			If !IsObject(PalObj) AND IMT.HasKey("Palette")
				PalObj:=PAL.ImportPaletteFromFile(IMT["Palette"]), IMT.Delete("Palette")
			If !IsObject(PalObj)
				PalObj:=PAL.ImportPaletteFromFile(IMT[0,0])
			PAL.TransformTransparency(255,0)
			PalObj:=Pal.GetPaletteObj()
			If PalObj.Count()	; If we actually loaded a palette
				this.Palette:=PalObj, HasPal:=1
			PAL:=""
			}
		; Load Frames and Sequences
		Quant:=New PS_Quantization()
		Quant.AddReservedColor(0,255,0,0)
		Key:=this._FormatHash(0,255,0,0)
		If !HistoQ.HasKey(Key)
			HistoQ[Key]:=Idx:=PalObjQ.Count()
		PalObjQ[Idx,"RR"]:=0, PalObjQ[Idx,"GG"]:=255, PalObjQ[Idx,"BB"]:=0, PalObjQ[Idx,"AA"]:=0
		Quant.AddReservedColor(0,0,0,0)
		Key:=this._FormatHash(0,0,0,0)
		If !HistoQ.HasKey(Key)
			HistoQ[Key]:=Idx:=PalObjQ.Count()
		PalObjQ[Idx,"RR"]:=0, PalObjQ[Idx,"GG"]:=0, PalObjQ[Idx,"BB"]:=0, PalObjQ[Idx,"AA"]:=0
		For Sequence, SequenceObj in IMT	; For each Sequence
			{
			this.CycleEntries[Index:=this.CycleEntries.Count(),"CountOfFrameIndices"]:=0
			this.CycleEntries[Index,"IndexIntoFLT"]:=this.FrameLookupTable.Count()
			For Frame, FramePath in SequenceObj	; For each Frame
				{
				If (SubStr(FramePath,-2)="gif")
					{
					FrameObj:=PalObj:=FrameObjUP:=Width:=Height:=CenterX:=CenterY:=""
					GIF:=new PSGIF()
					GIF.LoadGIFFromFile(FramePath)
					GIF.TransformBackgroundColor(0,255,0,0)
					GIF.TransformTransColor(0,255,0,0)
					this.Stats.OriginalFileSize+=GIF.GetFileSize()
					Loop, % GIF.GetCountOfFrames()
						{
						GIF.GetGIFObjects(A_Index,FrameObj,PalObj,FrameObjUP,Width,Height,CenterX,CenterY)
						this.FrameEntries[FrameNum,"Width"]:=Width, this.FrameEntries[FrameNum,"Height"]:=Height
						this.FrameEntries[FrameNum,"CenterX"]:=CenterX, this.FrameEntries[FrameNum,"CenterY"]:=CenterY
						this.FrameEntries[FrameNum,"RLE"]:=0, this.FrameEntries[FrameNum,"FramePointer"]:=FrameNum
						;~ If HasPal	; We have a palette
							;~ this.FrameData[FrameNum]:=this._ConvertFrameToPaletted(FrameObjUP,this.Palette,Histo)	; this could cover everything else and save code length and conditionals.
						If HasPal	; We have a palette
							{
							If FrameObj.Count() AND (Settings.ReplacePaletteMethod="Force")	; We have paletted data and are forcing frame data to loaded palette
								this.FrameData[FrameNum]:=FrameObj
							Else	; We will be remaping data or only have unpaletted data
								this.FrameData[FrameNum]:=this._ConvertFrameToPaletted(FrameObjUP,this.Palette,Histo)	; this could cover everything else and save code length and conditionals. - not true
							}
						Else	; We are Quantizing or do not have a palette
							{
							For k,v in FrameObjUP
								{
								Key:=this._FormatHash(R:=v["RR"],G:=v["GG"],B:=v["BB"],A:=v["AA"])
								If !HistoQ.HasKey(Key)
									HistoQ[Key]:=Idx:=PalObjQ.Count()
								Else
									Idx:=HistoQ[Key]
								PalObjQ[Idx,"RR"]:=R, PalObjQ[Idx,"GG"]:=G, PalObjQ[Idx,"BB"]:=B, PalObjQ[Idx,"AA"]:=A
								Quant.AddColor(R,G,B,A)
								UPFrames[FrameNum,k]:=Idx
								}
							}
						this.CycleEntries[Index,"CountOfFrameIndices"]+=1
						this.FrameLookupTable[this.FrameLookupTable.Count()]:=FrameNum
						FrameNum++
						}
					GIF:=""
					}
				Else	; BMP or use GDI
					{
					FrameObj:=PalObj:=FrameObjUP:=Width:=Height:=""
					BMP:=new PSBMP()
					BMP.LoadBMPFromFile(FramePath)
					BMP.SetColorTransparency(0,255,0,0)
					BMP.SetColorTransparency(0,0,0,0)
					BMP.TransformTransparency(255,0)
					this.Stats.OriginalFileSize+=BMP.GetFileSize()
					BMP.GetBMPObjects(FrameObj,PalObj,FrameObjUP,Width,Height)
					this.FrameEntries[FrameNum,"Width"]:=Width, this.FrameEntries[FrameNum,"Height"]:=Height
					this.FrameEntries[FrameNum,"CenterX"]:=0, this.FrameEntries[FrameNum,"CenterY"]:=0
					this.FrameEntries[FrameNum,"RLE"]:=0, this.FrameEntries[FrameNum,"FramePointer"]:=FrameNum
					;~ If HasPal	; We have a palette
						;~ this.FrameData[FrameNum]:=this._ConvertFrameToPaletted(FrameObjUP,this.Palette,Histo)	; this could cover everything else and save code length and conditionals.
					If HasPal	; We have a palette
						{
						If FrameObj.Count() AND (Settings.ReplacePaletteMethod="Force")	; We have paletted data and are forcing frame data to loaded palette
							this.FrameData[FrameNum]:=FrameObj
						Else	; We will be remaping data or only have unpaletted data
							this.FrameData[FrameNum]:=this._ConvertFrameToPaletted(FrameObjUP,this.Palette,Histo)	; this could cover everything else and save code length and conditionals. - not true
						}
					Else	; We are Quantizing or do not have a palette
						{
						;UPFrames.SetCapacity(UPFrames.Count()+SequenceObj.Count())
						For k,v in FrameObjUP
							{
							;~ Console.Send(st_printArr(FrameObjUP) "`r`n")
							Key:=this._FormatHash(R:=v["RR"],G:=v["GG"],B:=v["BB"],A:=v["AA"])
							;~ Console.Send(R "|" G "|" B "|" A "`r`n")
							If !HistoQ.HasKey(Key)
								HistoQ[Key]:=Idx:=PalObjQ.Count()
							Else
								Idx:=HistoQ[Key]
							PalObjQ[Idx,"RR"]:=R, PalObjQ[Idx,"GG"]:=G, PalObjQ[Idx,"BB"]:=B, PalObjQ[Idx,"AA"]:=A
							Quant.AddColor(R,G,B,A)
							UPFrames[FrameNum,k]:=Idx
							}
						}
					this.CycleEntries[Index,"CountOfFrameIndices"]+=1
					this.FrameLookupTable[this.FrameLookupTable.Count()]:=FrameNum
					FrameNum++
					BMP:=""
					}
				;~ Console.Send("ColorCount = " Quant.GetColorCount() "`r`n","E")
				;~ Console.Send("HistoQCount = " HistoQ.Count() "`r`n","E")
				;~ Console.Send("UPFramesCount = " UPFrames.Count() "`r`n","E")
				}
			;~ Console.Send(st_printArr(PalObjQ) "`r`n")
			}
			;~ Console.Send(st_printArr(UPFrames) "`r`n","E")
			this.PrintFrameEntries()	; These will forewarn of any frames missing from input images that will be filled with single (transparent) pixel frames
			this.PrintCycleEntries()	; These will forewarn of any sequences missing from input images that will be filled with blank sequences
		; Apply palette or Quantize if necessary
		If UPFrames.Count()	; We have unpaletted data so we need to quantize
			{
			Console.Send("ColorCount = " Quant.GetColorCount() "`r`n","I")
			Quant.Quantize(256)
			this.Palette:=PalObj:=Quant.GetPaletteObj(256)
			For k,v in UPFrames
				{
				For k2,v2 in v
					this.FrameData[k,k2]:=Quant.GetQuantizedColorIndex(PalObjQ[v2,"RR"],PalObjQ[v2,"GG"],PalObjQ[v2,"BB"],PalObjQ[v2,"AA"])
				}
			}
		Quant:=""
		Loop, % this.FrameData.Count() ;(this.FrameData.MaxIndex()+1)	; Compensate for missing frames by adding frame of 1 (trans) pixel
			{
			key:=A_Index-1
			If !IsObject(this.FrameData[key])
				{
				this.FrameData[key]:={}
				this.FrameData[key,0]:=0
				this.FrameEntries[key,"CenterX"]:=0
				this.FrameEntries[key,"CenterY"]:=0
				this.FrameEntries[key,"Width"]:=1
				this.FrameEntries[key,"Height"]:=1
				this.FrameEntries[key,"RLE"]:=0
				this.FrameEntries[key,"FramePointer"]:=key
				}
			}
		Loop, % this.CycleEntries.Count() ;(this.CycleEntries.MaxIndex()+1)	; Compensate for missing sequences by adding empty sequence
			{
			key:=A_Index-1
			If !IsObject(this.CycleEntries[key])
				{
				this.CycleEntries[key]:={}
				this.CycleEntries[key,"CountOfFrameIndices"]:=0
				this.CycleEntries[key,"IndexIntoFLT"]:=0
				}
			}
		this.Stats.CountOfPaletteEntries:=this.Palette.Count()
		this.Stats.CountOfFrameEntries:=this.FrameEntries.Count()
		this.Stats.CountOfFrames:=this.FrameData.Count()
		this.Stats.CountOfFLTEntries:=this.FrameLookupTable.Count()
		this._UpdateStats()
		this.Stats.FullyUncompressedSize:=this.Stats.FileSize
		PS_SummaryA[PS_SummaryA.MaxIndex(),"OriginalSize"]:=this.Stats.OriginalFileSize
		this.PrintPalette()
		;~ Console.Send("Frames read in " (QPC(1)-tic) " sec.`r`n","-I")
	}
	_ReadBAMDPalette(PaletteLine:="",Path:=""){
		PalObj:=""
		If FileExist(Path)
			{
			PAL:=New PSPAL()
			PalObj:=PAL.ImportPaletteFromFile(Path)
			PAL:=""
			}
		If StrLen(PaletteLine) AND !IsObject(PalObj)
			{
			Line:=StrSplit(PaletteLine,A_Space,A_Quote)
			Path:=""
			Loop, % Line.Length()-1
				Path.=Line[A_Index+1] A_Space
			Path=%Path%
			If !FileExist(Path)
				{
				tmp:=this.InputPath
				SplitPath, tmp, OutFileName, OutDir, OutExtension, NotNameNoExt, OutDrive
				If FileExist(A_ScriptDir "\" Path)
					Path:=A_ScriptDir "\" Path
				Else If FileExist(A_ScriptDir Path)
					Path:=A_ScriptDir Path
				Else If FileExist(OutDir "\" NotNameNoExt "\" Path)
					Path:=OutDir "\" NotNameNoExt "\" Path
				}
			If FileExist(Path)
				{
				PAL:=New PSPAL()
				PalObj:=PAL.ImportPaletteFromFile(Path)
				PAL:=""
				}
			}
		Return PalObj
	}
	_ReadBAMDFrame(ByRef UPFrames,FrameLine){
		Line:=StrSplit(FrameLine,A_Space,A_Quote)
		;~ Console.Send("Line = `r`n" st_printArr(Line) "`r`n","I")
		FrameNum:=Line[2]
		StringReplace, FrameNum, FrameNum, f, , All
		;~ Console.Send("FrameNum = " FrameNum "`r`n")
		FrameNum+=0
		;~ Console.Send("FrameNum = " FrameNum "`r`n")
		Path:=FinalPath:=""
		Loop, % Line.Length()-4
			Path.=Line[A_Index+2] A_Space
		Path=%Path%
		CenterX:=Line[Line.MaxIndex()-1]
		CenterX+=0
		this.FrameEntries[FrameNum,"CenterX"]:=CenterX
		CenterY:=Line[Line.MaxIndex()]
		CenterY+=0
		this.FrameEntries[FrameNum,"CenterY"]:=CenterY
		If !FileExist(Path)
			{
			tmp:=this.InputPath
			SplitPath, tmp, OutFileName, OutDir, OutExtension, NotNameNoExt, OutDrive
			If FileExist(OutDir "\" Path)
				Path:=OutDir "\" Path
			Else If FileExist(OutDir Path)
				Path:=OutDir Path
			Else If FileExist(OutDir "\" NotNameNoExt "\" Path)
				Path:=OutDir "\" NotNameNoExt "\" Path
			}
		If FileExist(Path)
			{
			FinalPath:=Path
			FileGetSize, Sz, %FinalPath%
			this.Stats.OriginalFileSize+=Sz
			BMP:=New PSBMP()
			;Verbose:=Console.DebugLevel
			;Console.DebugLevel:=1
			BMP.LoadBMPFromFile(Path)
			BMP.SetColorTransparency(0,255,0,0)
			BMP.SetColorTransparency(0,0,0,0)
			BMP.TransformTransparency(255,0)
			;Console.DebugLevel:=Verbose
			FrameObj:=PalObj:=FrameObjUP:=Width:=Height:=""
			BMP.GetBMPObjects(FrameObj,PalObj,FrameObjUP,Width,Height)
			this.FrameEntries[FrameNum,"Width"]:=Width, this.FrameEntries[FrameNum,"Height"]:=Height
			this.FrameEntries[FrameNum,"RLE"]:=0, this.FrameEntries[FrameNum,"FramePointer"]:=FrameNum
			If (FrameObj.Count()) AND (Settings.ReplacePaletteMethod="Force")
				this.FrameData[FrameNum]:=FrameObj
			Else
				UPFrames[FrameNum]:=FrameObjUP
			BMP:=""
			}
		Else
			{
			Console.Send("Frame " FrameNum " not found at '" Path "'.  A blank frame will be loaded." "`r`n","W")
			this.FrameEntries[FrameNum,"Width"]:=1, this.FrameEntries[FrameNum,"Height"]:=1
			this.FrameEntries[FrameNum,"RLE"]:=0, this.FrameEntries[FrameNum,"FramePointer"]:=FrameNum
			UPFrames[FrameNum,0,"RR"]:=0, UPFrames[FrameNum,0,"GG"]:=255, UPFrames[FrameNum,0,"BB"]:=0, UPFrames[FrameNum,0,"AA"]:=0, 
			}
		;~ Console.Send("frame f" FrameNum A_Space A_Quote Path A_Quote A_Space CenterX A_Space CenterY "`r`n","I")
		Return FinalPath
	}
	_ReadBAMDSequence(SequenceLine){
		;~ Console.Send(SequenceLine "`r`n","-W")
		If Loc:=InStr(SequenceLine,"\\")
			SequenceLine:=SubStr(SequenceLine,1,Loc-1)
		StringReplace, SequenceLine, SequenceLine, sequence%A_Space%
		SequenceLine:=Trim(SequenceLine)
		;~ Console.Send(SequenceLine "`r`n","-W")
		Line:=StrSplit(SequenceLine,A_Space,"f")
		;Console.Send("bla " st_printArr(Line) "`r`n","-W")
		this.CycleEntries[(Idx:=this.CycleEntries.Count()),"CountOfFrameIndices"]:=Line.Length()
		this.CycleEntries[Idx,"IndexIntoFLT"]:=this.FrameLookupTable.Count()
		Loop, % Line.Length()
			{
			Idx:=Line[A_Index]
			Idx+=0
			this.FrameLookupTable[this.FrameLookupTable.Count()]:=Idx
			}
	}
	_WriteBAM(){
		tic:=QPC(1)
		this._WriteBAMHeader()
		this._WriteFrameEntries()
		this._WriteCycleEntries()
		this._WritePalette()
		this._WriteFrameLookupTable()
		this._WriteFrameData()
		Console.Send("BAM written in " (QPC(1)-tic) " sec.`r`n","-I")
	}
	_ReadBAMHeader(){
		tic:=QPC(1)
		this.DataMem.Seek(0,0)
		this.Stats.Signature:=this.DataMem.Read(4), Console.Send("Signature='" this.Stats.Signature "'`r`n","I")
		this.Stats.Version:=this.DataMem.Read(4), Console.Send("Version='" this.Stats.Version "'`r`n","I")
		If (this.Stats.Signature="BAMC") AND (this.Stats.Version="V1  ")   ;;;;; BAMC V1 Header ;;;;;
			{
			this.Stats.OffsetToHeader:=0, Console.Send("OffsetToHeader=" this.Stats.OffsetToHeader "`r`n","I")
			this.Stats.UncompressedSize:=this.DataMem.ReadDWORD(), Console.Send("UncompressedSize=" this.Stats.UncompressedSize "`r`n","I")
			this.Stats.WasBAMC:=1
			}
		Else If (this.Stats.Signature="BAM ") AND (this.Stats.Version="V1  ")   ;;;;; BAM V1 Header ;;;;;
			{
			this.Stats.OffsetToHeader:=0, Console.Send("OffsetToHeader=" this.Stats.OffsetToHeader "`r`n","I")
			this.Stats.CountOfFrameEntries:=this.DataMem.ReadWORD(), Console.Send("CountOfFrameEntries=" this.Stats.CountOfFrameEntries "`r`n","I")
			this.Stats.CountOfCycles:=this.DataMem.ReadUChar(), Console.Send("CountOfCycles=" this.Stats.CountOfCycles "`r`n","I")
			this.Stats.RLEColorIndex:=this.DataMem.ReadUChar(), Console.Send("RLEColorIndex=" this.Stats.RLEColorIndex "`r`n","I")
			this.Stats.OffsetToFrameEntries:=this.DataMem.ReadDWORD(), Console.Send("OffsetToFrameEntries=" this.Stats.OffsetToFrameEntries "`r`n","I")
			this.Stats.OffsetToPalette:=this.DataMem.ReadDWORD(), Console.Send("OffsetToPalette=" this.Stats.OffsetToPalette "`r`n","I")
			this.Stats.OffsetToFLT:=this.DataMem.ReadDWORD(), Console.Send("OffsetToFLT=" this.Stats.OffsetToFLT "`r`n","I")
			}
		Else If (this.Stats.Signature="BAM ") AND (this.Stats.Version="V2  ")   ;;;;; BAM V2 Header ;;;;;
			{
			this.Stats.OffsetToHeader:=0, Console.Send("OffsetToHeader=" this.Stats.OffsetToHeader "`r`n","I")
			this.Stats.CountOfFrameEntries:=this.DataMem.ReadDWORD(), Console.Send("CountOfFrameEntries=" this.Stats.CountOfFrameEntries "`r`n","I")
			this.Stats.CountOfCycles:=this.DataMem.ReadDWORD(), Console.Send("CountOfCycles=" this.Stats.CountOfCycles "`r`n","I")
			this.Stats.CountOfDataBlocks:=this.DataMem.ReadDWORD(), Console.Send("CountOfDataBlocks=" this.Stats.CountOfDataBlocks "`r`n","I")
			this.Stats.OffsetToFrameEntries:=this.DataMem.ReadDWORD(), Console.Send("OffsetToFrameEntries=" this.Stats.OffsetToFrameEntries "`r`n","I")
			this.Stats.OffsetToCycleEntries:=this.DataMem.ReadDWORD(), Console.Send("OffsetToCycleEntries=" this.Stats.OffsetToCycleEntries "`r`n","I")
			this.Stats.OffsetToDataBlocks:=this.DataMem.ReadDWORD(), Console.Send("OffsetToDataBlocks=" this.Stats.OffsetToDataBlocks "`r`n","I")
			}
		Else If (this.Stats.Signature="BAMU") AND (this.Stats.Version="V1  ")   ;;;;; BAMU V1 Header ;;;;;
			{
			this.Stats.OffsetToHeader:=0, Console.Send("OffsetToHeader=" this.Stats.OffsetToHeader "`r`n","I")
			this.Stats.CountOfFrameEntries:=this.DataMem.ReadWORD(), Console.Send("CountOfFrameEntries=" this.Stats.CountOfFrameEntries "`r`n","I")
			this.Stats.CountOfCycles:=this.DataMem.ReadUChar(), Console.Send("CountOfCycles=" this.Stats.CountOfCycles "`r`n","I")
			this.Stats.RLEColorIndex:=this.DataMem.ReadUChar(), Console.Send("RLEColorIndex=" this.Stats.RLEColorIndex "`r`n","I")
			this.DataMem.Seek(4,1) ; Not sure what this field is...  one value is 0xFF0000FF
			this.Stats.OffsetToPalette:=this.DataMem.ReadDWORD(), Console.Send("OffsetToPalette=" this.Stats.OffsetToPalette "`r`n","I")
			this.Stats.OffsetToFrameEntries:=this.DataMem.ReadDWORD(), Console.Send("OffsetToFrameEntries=" this.Stats.OffsetToFrameEntries "`r`n","I")
			this.Stats.OffsetToFLT:=this.DataMem.ReadDWORD(), Console.Send("OffsetToFLT=" this.Stats.OffsetToFLT "`r`n","I")
			}
		Else
			throw Exception("The following file is not a supported BAM file:`r`n" this.InputPath,,"Signature """ this.Stats.Signature """ / Version """ this.Stats.Version """ not supported.`n`n" Traceback())
		Console.Send("BAM Header read in " (QPC(1)-tic) " sec.`r`n","-I")
	}
	_WriteBAMHeader(){
		tic:=QPC(1)
		If (Settings.DebugLevelS>=2)
			this.PrintStats()
		this.DataMem.Seek(this.Stats.OffsetToHeader,0)
		this.DataMem.Write(this.Stats.Signature,4)
		this.DataMem.Write(this.Stats.Version,4)
		If (this.Stats.Signature="BAMC") AND (this.Stats.Version="V1  ")   ;;;;; BAMC V1 Header ;;;;;
			{
			this.DataMem.WriteDWORD(this.Stats.UncompressedSize)
			}
		Else If (this.Stats.Signature="BAM ") AND (this.Stats.Version="V1  ")   ;;;;; BAM V1 Header ;;;;;
			{
			this.DataMem.WriteWORD(this.Stats.CountOfFrameEntries)
			this.DataMem.WriteUChar(this.Stats.CountOfCycles)
			this.DataMem.WriteUChar(this.Stats.RLEColorIndex)
			this.DataMem.WriteDWORD(this.Stats.OffsetToFrameEntries)
			this.DataMem.WriteDWORD(this.Stats.OffsetToPalette)
			this.DataMem.WriteDWORD(this.Stats.OffsetToFLT)
			}
		Else
			throw Exception("The compiled data is not a supported BAM file",,"Signature """ this.Stats.Signature """ / Version """ this.Stats.Version """ not supported.`n`n" Traceback())
		Console.Send("BAM Header written in " (QPC(1)-tic) " sec.`r`n","-I")
	}
	_ReadFrameEntries(){ ;;;;; BAM V1 Frame Entries ;;;;;
		tic:=QPC(1)
		this.DataMem.Seek(this.Stats.OffsetToFrameEntries,0)
		this.FrameEntries:={}, this.Stats.RLE:=0
		this.Stats.OffsetToFrameData:=0xFFFFFFFE
		Console.Send(FormatStr("FrameEntry",A_Space,11,"C") FormatStr("Width",A_Space,8,"C") FormatStr("Height",A_Space,8,"C") FormatStr("PixelCount",A_Space,11,"C") FormatStr("CenterX",A_Space,8,"C") FormatStr("CenterY",A_Space,8,"C") FormatStr("Offset&RLE",A_Space,11,"C") FormatStr("RLE",A_Space,4,"C") RTrim(FormatStr("OffsetToFrameData",A_Space,17,"C"),A_Space) "`r`n","I")
		Loop, % this.Stats.CountOfFrameEntries
			{
			Index:=A_Index-1, Console.Send("     " FormatStr(Index,A_Space,11,"C"),"-I")
			this.FrameEntries[Index,"Width"]:=this.DataMem.ReadWORD(), Console.Send(FormatStr(this.FrameEntries[Index,"Width"],A_Space,8,"C"),"-I")
			If (this.FrameEntries[Index,"Width"]>255)
				Console.Send("Frame " Index " Width>255: " this.FrameEntries[Index,"Width"] "`r`n","W")
			Else If (this.FrameEntries[Index,"Width"]<1)
				Console.Send("Frame " Index " Width<1: " this.FrameEntries[Index,"Width"] "`r`n","W")
			this.FrameEntries[Index,"Height"]:=this.DataMem.ReadWORD(), Console.Send(FormatStr(this.FrameEntries[Index,"Height"],A_Space,8,"C"),"-I")
			If (this.FrameEntries[Index,"Height"]>255)
				Console.Send("Frame " Index " Height>255: " this.FrameEntries[Index,"Height"] "`r`n","W")
			Else If (this.FrameEntries[Index,"Height"]<1)
				Console.Send("Frame " Index " Height<1: " this.FrameEntries[Index,"Height"] "`r`n","W")
			Console.Send(FormatStr(this.FrameEntries[Index,"Width"]*this.FrameEntries[Index,"Height"],A_Space,11,"C"),"-I")
			this.FrameEntries[Index,"CenterX"]:=this.DataMem.ReadShort(), Console.Send(FormatStr(this.FrameEntries[Index,"CenterX"],A_Space,8,"C"),"-I")
			If (this.FrameEntries[Index,"CenterX"]>255) OR (this.FrameEntries[Index,"CenterX"]<-255)
				Console.Send("Frame " Index " CenterX is unusually large or small: " this.FrameEntries[Index,"CenterX"] "`r`n","W")
			this.FrameEntries[Index,"CenterY"]:=this.DataMem.ReadShort(), Console.Send(FormatStr(this.FrameEntries[Index,"CenterY"],A_Space,8,"C"),"-I")
			If (this.FrameEntries[Index,"CenterY"]>255) OR (this.FrameEntries[Index,"CenterY"]<-255)
				Console.Send("Frame " Index " CenterY is unusually large or small: " this.FrameEntries[Index,"CenterY"] "`r`n","W")
			temp:=this.DataMem.ReadDWORD(), Console.Send(FormatStr(temp,A_Space,11,"C"),"-I")
			If (temp&0x80000000 <> 0)
				{
				this.FrameEntries[Index,"RLE"]:=0, Console.Send(FormatStr(this.FrameEntries[Index,"RLE"],A_Space,4,"C"),"-I")
				this.FrameEntries[Index,"OffsetToFrameData"]:=temp&0x7FFFFFFF, Console.Send(RTrim(FormatStr(this.FrameEntries[Index,"OffsetToFrameData"],A_Space,17,"C"),A_Space) "`r`n","-I")
				}
			Else
				{
				this.FrameEntries[Index,"RLE"]:=1, Console.Send(FormatStr(this.FrameEntries[Index,"RLE"],A_Space,4,"C"),"-I")
				this.FrameEntries[Index,"OffsetToFrameData"]:=temp, Console.Send(RTrim(FormatStr(this.FrameEntries[Index,"OffsetToFrameData"],A_Space,17,"C"),A_Space) "`r`n","-I")
				this.Stats.RLE:=1
				}
			temp:=""
			If (this.FrameEntries[Index,"OffsetToFrameData"]<this.Stats.OffsetToFrameData) AND (this.FrameEntries[Index,"Width"]>0) AND (this.FrameEntries[Index,"Height"]>0)
				this.Stats.OffsetToFrameData:=this.FrameEntries[Index,"OffsetToFrameData"]
			}
		If (this.Stats.OffsetToFrameData=0xFFFFFFFE)
			this.Stats.OffsetToFrameData:=""
		Console.Send("OffsetToFrameData (begin)=" this.Stats.OffsetToFrameData "`r`n","I")
		Console.Send("RLE in Frame Data? " this.Stats.RLE "`r`n","I")
		Console.Send("BAM Frame Entries read in " (QPC(1)-tic) " sec.`r`n","-I")
		this.Stats.OffsetToCycleEntries:=this.DataMem.Position, Console.Send("OffsetToCycleEntries=" this.Stats.OffsetToCycleEntries "`r`n","I")
	}
	_ReadV2FrameEntries(){
		tic:=QPC(1)
		this.DataMem.Seek(this.Stats.OffsetToFrameEntries,0)
		this.FrameEntries:={}, this.Stats.RLE:=0
		Console.Send(FormatStr("FrameEntry",A_Space,11,"C") FormatStr("Width",A_Space,8,"C") FormatStr("Height",A_Space,8,"C") FormatStr("PixelCount",A_Space,11,"C") FormatStr("CenterX",A_Space,8,"C") FormatStr("CenterY",A_Space,8,"C") FormatStr("IndexIntoDataBlocks",A_Space,20,"C") RTrim(FormatStr("CountOfDataBlocks",A_Space,18,"C"),A_Space) "`r`n","I")
		Loop, % this.Stats.CountOfFrameEntries
			{
			Index:=A_Index-1, Console.Send("     " FormatStr(Index,A_Space,11,"C"),"-I")
			this.FrameEntries[Index,"Width"]:=this.DataMem.ReadWORD(), Console.Send(FormatStr(this.FrameEntries[Index,"Width"],A_Space,8,"C"),"-I")
			this.FrameEntries[Index,"Height"]:=this.DataMem.ReadWORD(), Console.Send(FormatStr(this.FrameEntries[Index,"Height"],A_Space,8,"C"),"-I")
			Console.Send(FormatStr(this.FrameEntries[Index,"Width"]*this.FrameEntries[Index,"Height"],A_Space,11,"C"),"-I")
			this.FrameEntries[Index,"CenterX"]:=this.DataMem.ReadShort(), Console.Send(FormatStr(this.FrameEntries[Index,"CenterX"],A_Space,8,"C"),"-I")
			this.FrameEntries[Index,"CenterY"]:=this.DataMem.ReadShort(), Console.Send(FormatStr(this.FrameEntries[Index,"CenterY"],A_Space,8,"C"),"-I")
			this.FrameEntries[Index,"IndexIntoDataBlocks"]:=this.DataMem.ReadWORD(), Console.Send(FormatStr(this.FrameEntries[Index,"IndexIntoDataBlocks"],A_Space,20,"C"),"-I")
			this.FrameEntries[Index,"CountOfDataBlocks"]:=this.DataMem.ReadWORD(), Console.Send(RTrim(FormatStr(this.FrameEntries[Index,"CountOfDataBlocks"],A_Space,18,"C")) "`r`n","-I")
			this.FrameEntries[Index,"FramePointer"]:=Index
			If (this.FrameEntries[Index,"Width"]>255)
				Console.Send("Frame " Index " Width>255: " this.FrameEntries[Index,"Width"] "`r`n","W")
			Else If (this.FrameEntries[Index,"Width"]<1)
				Console.Send("Frame " Index " Width<1: " this.FrameEntries[Index,"Width"] "`r`n","W")
			If (this.FrameEntries[Index,"Height"]>255)
				Console.Send("Frame " Index " Height>255: " this.FrameEntries[Index,"Height"] "`r`n","W")
			Else If (this.FrameEntries[Index,"Height"]<1)
				Console.Send("Frame " Index " Height<1: " this.FrameEntries[Index,"Height"] "`r`n","W")
			If (this.FrameEntries[Index,"CenterX"]>255) OR (this.FrameEntries[Index,"CenterX"]<-255)
				Console.Send("Frame " Index " CenterX is unusually large or small: " this.FrameEntries[Index,"CenterX"] "`r`n","W")
			If (this.FrameEntries[Index,"CenterY"]>255) OR (this.FrameEntries[Index,"CenterY"]<-255)
				Console.Send("Frame " Index " CenterY is unusually large or small: " this.FrameEntries[Index,"CenterY"] "`r`n","W")
			this.FrameEntries[Index,"RLE"]:=0
			}
		this.Stats.OffsetToFrameData:=""
		Console.Send("RLE in Frame Data? " this.Stats.RLE "`r`n","I")
		Console.Send("BAM Frame Entries read in " (QPC(1)-tic) " sec.`r`n","-I")
	}
	_WriteFrameEntries(){ ;;;;; BAM V1 Frame Entries ;;;;;
		tic:=QPC(1)
		If (Settings.DebugLevelS>=2)
			this.PrintFrameEntries()
		this.DataMem.Seek(this.Stats.OffsetToFrameEntries,0)
		Loop, % this.Stats.CountOfFrameEntries
			{
			Index:=A_Index-1
			;~ For key, val in this.FrameEntries[Index]
				;~ Console.Send(Index ": " key "=" val "`r`n")
			this.DataMem.WriteWORD(this.FrameEntries[Index,"Width"])
			this.DataMem.WriteWORD(this.FrameEntries[Index,"Height"])
			this.DataMem.WriteShort(this.FrameEntries[Index,"CenterX"])
			this.DataMem.WriteShort(this.FrameEntries[Index,"CenterY"])
			;~ this.DataMem.WriteDWORD((this.FrameEntries[Index,"RLE"]=0?this.FrameEntries[Index,"OffsetToFrameData"]|0x80000000:this.FrameEntries[Index,"OffsetToFrameData"]))
			If (this.FrameEntries[Index,"RLE"]=0)
				this.DataMem.WriteDWORD(this.FrameEntries[Index,"OffsetToFrameData"]|0x80000000)
			Else
				this.DataMem.WriteDWORD(this.FrameEntries[Index,"OffsetToFrameData"])
			}
		Console.Send("BAM Frame Entries written in " (QPC(1)-tic) " sec.`r`n","-I")
		}
	_ReadCycleEntries(){ ;;;;; BAM V1 Cycle Entries ;;;;;
		tic:=QPC(1)
		this.DataMem.Seek(this.Stats.OffsetToCycleEntries,0)
		this.CycleEntries:={}, this.Stats.CountOfFLTEntries:=0
		Console.Send(FormatStr("CycleEntry",A_Space,11,"C") FormatStr("CountOfFrameIndices",A_Space,20,"C") RTrim(FormatStr("IndexIntoFLT",A_Space,13,"C"),A_Space) "`r`n","I")
		Loop, % this.Stats.CountOfCycles
			{
			Index:=A_Index-1, Console.Send("     " FormatStr(Index,A_Space,11,"C"),"-I")
			this.CycleEntries[Index,"CountOfFrameIndices"]:=this.DataMem.ReadWORD(), Console.Send(FormatStr(this.CycleEntries[Index,"CountOfFrameIndices"],A_Space,20,"C"),"-I")
			this.CycleEntries[Index,"IndexIntoFLT"]:=this.DataMem.ReadWORD(), Console.Send(RTrim(FormatStr(this.CycleEntries[Index,"IndexIntoFLT"],A_Space,13,"C"),A_Space) "`r`n","-I")
			If (this.CycleEntries[Index,"CountOfFrameIndices"]+this.CycleEntries[Index,"IndexIntoFLT"]>this.Stats.CountOfFLTEntries)
				this.Stats.CountOfFLTEntries:=this.CycleEntries[Index,"CountOfFrameIndices"]+this.CycleEntries[Index,"IndexIntoFLT"]
			}
		Console.Send("CountOfFLTEntries=" this.Stats.CountOfFLTEntries "`r`n","I")
		Console.Send("BAM Cycle Entries read in " (QPC(1)-tic) " sec.`r`n","-I")
	}
	_WriteCycleEntries(){ ;;;;; BAM V1 Cycle Entries ;;;;;
		tic:=QPC(1)
		If (Settings.DebugLevelS>=2)
			this.PrintCycleEntries()
		this.DataMem.Seek(this.Stats.OffsetToCycleEntries,0)
		Loop, % this.Stats.CountOfCycles
			{
			Index:=A_Index-1
			this.DataMem.WriteWORD(this.CycleEntries[Index,"CountOfFrameIndices"])
			this.DataMem.WriteWORD(this.CycleEntries[Index,"IndexIntoFLT"])
			}
		Console.Send("BAM Cycle Entries written in " (QPC(1)-tic) " sec.`r`n","-I")
	}
	_ReadPalette(){ ;;;;; BAM V1 Palette ;;;;;
		tic:=QPC(1)
		this.DataMem.Seek(this.Stats.OffsetToPalette,0)
		this._CalcSizeOfPalette(), Console.Send("CountOfPaletteEntries=" this.Stats.CountOfPaletteEntries "`r`n","I")
		this.Palette:={}, this.Stats.PaletteHasAlpha:=0, this.Palette.SetCapacity(this.Stats.CountOfPaletteEntries)
		If (this.Stats.CountOfPaletteEntries)
			Console.Send("PaletteEntry " FormatStr("#",A_Space,3,"R") ": " FormatStr("BB",A_Space,3,"R") " " FormatStr("GG",A_Space,3,"R") " " FormatStr("RR",A_Space,3,"R") " " FormatStr("AA",A_Space,3,"R") "`r`n" "  ---------------------------------`r`n","I")
		Loop, % this.Stats.CountOfPaletteEntries
			{
			Index:=A_Index-1, Console.Send("PaletteEntry " FormatStr(Index,A_Space,3,"R") ": ","I")
			this.Palette[Index,"BB"]:=this.DataMem.ReadUChar(), Console.Send(FormatStr(this.Palette[Index,"BB"],A_Space,3,"R") " ","-I")
			this.Palette[Index,"GG"]:=this.DataMem.ReadUChar(), Console.Send(FormatStr(this.Palette[Index,"GG"],A_Space,3,"R") " ","-I")
			this.Palette[Index,"RR"]:=this.DataMem.ReadUChar(), Console.Send(FormatStr(this.Palette[Index,"RR"],A_Space,3,"R") " ","-I")
			this.Palette[Index,"AA"]:=this.DataMem.ReadUChar(), Console.Send(FormatStr(this.Palette[Index,"AA"],A_Space,3,"R") "`r`n","-I")
			If (this.Palette[Index,"AA"]>0) AND (this.Palette[Index,"AA"]<>"")
				this.Stats["PaletteHasAlpha"]:=1
			}
		If (this.Stats.CountOfPaletteEntries)
			{
			Console.Send("PaletteHasAlpha=" this.Stats.PaletteHasAlpha "`r`n","I")
			this._CalcTransColorIndex(), Console.Send("TransColorIndex=" this.Stats.TransColorIndex "`r`n","I")
			this._CalcShadowColorIndex(), Console.Send("ShadowColorIndex=" this.Stats.ShadowColorIndex "`r`n","I")
			Console.Send("BAM Palette read in " (QPC(1)-tic) " sec.`r`n","-I")
			}
	}
	_WritePalette(){ ;;;;; BAM V1 Palette ;;;;;
		tic:=QPC(1)
		If (Settings.DebugLevelS>=2)
			this.PrintPalette()
		this.DataMem.Seek(this.Stats.OffsetToPalette,0)
		Loop, % this.Stats.CountOfPaletteEntries
			{
			Index:=A_Index-1
			this.DataMem.WriteUChar(this.Palette[Index,"BB"])
			this.DataMem.WriteUChar(this.Palette[Index,"GG"])
			this.DataMem.WriteUChar(this.Palette[Index,"RR"])
			this.DataMem.WriteUChar(this.Palette[Index,"AA"])
			}
		Console.Send("BAM Palette written in " (QPC(1)-tic) " sec.`r`n","-I")
	}
	_ReadFrameLookupTable(){ ;;;;; BAM V1 Frame Lookup Table ;;;;;
		tic:=QPC(1)
		this.DataMem.Seek(this.Stats.OffsetToFLT,0)
		this.FrameLookupTable:={}, Console.Send("FrameLookupTable:","I")
		Loop, % this.Stats.CountOfFLTEntries
			{
			Index:=A_Index-1
			this.FrameLookupTable[Index]:=this.DataMem.ReadUShort(), Console.Send(FormatStr(this.FrameLookupTable[Index],A_Space,3,"R") " ","-I")
			}
		Console.Send("`r`n","-I")
		Console.Send("BAM Frame Lookup Table read in " (QPC(1)-tic) " sec.`r`n","-I")
	}
	_ReadV2FrameLookupTable(){ ;;;;; BAM V2 Frame Lookup Table ;;;;;
		tic:=QPC(1)
		this.FrameLookupTable:={}
		Loop, % this.CycleEntries.Count()
			{
			Index:=A_Index-1
			Loop, % this.CycleEntries[Index,"CountOfFrameIndices"]
				this.FrameLookupTable[this.FrameLookupTable.Count()]:=this.CycleEntries[Index,"IndexIntoFLT"]+A_Index-1
			}
		Console.Send("BAM Frame Lookup Table generated in " (QPC(1)-tic) " sec.`r`n","-I")
	}
	_WriteFrameLookupTable(){ ;;;;; BAM V1 Frame Lookup Table ;;;;;
		tic:=QPC(1)
		If (Settings.DebugLevelS>=2)
			this.PrintFrameLookupTable()
		this.DataMem.Seek(this.Stats.OffsetToFLT,0)
		Loop, % this.Stats.CountOfFLTEntries
			{
			Index:=A_Index-1
			this.DataMem.WriteUShort(this.FrameLookupTable[Index])
			}
		Console.Send("BAM Frame Lookup Table written in " (QPC(1)-tic) " sec.`r`n","-I")
	}
	_ReadFrameData(){ ;;;;; BAM V1 Frame Data ;;;;;
		tic:=QPC(1)
		this.Stats.CountOfFrames:=this.Stats.CountOfFrameEntries, Console.Send("CountOfFrames=" this.Stats.CountOfFrames "`r`n","I")
		this.FrameData:={}, BytesRead:=0, this.FrameData.SetCapacity(this.Stats.CountOfFrames)
		Loop, % this.Stats.CountOfFrames
			{
			Index:=A_Index-1, PixelCount:=this.FrameEntries[Index,"Width"]*this.FrameEntries[Index,"Height"], this.FrameData[Index].SetCapacity(PixelCount)
			this.FrameEntries[Index,"FramePointer"]:=Index
			this.DataMem.Seek(this.FrameEntries[Index,"OffsetToFrameData"],0)
			If !(this.FrameEntries[Index,"RLE"])	; Frame Data is NOT RLE
				{
				Loop, % PixelCount
					{
					Index2:=A_Index-1
					this.FrameData[Index,Index2]:=this.DataMem.ReadUChar(), BytesRead++
					}
				}
			Else	; Frame Data IS RLE
				{
				this.FrameEntries[Index,"RLE"]:=0, Indexi:=0
				Loop, % PixelCount
					{
					byte:=this.DataMem.ReadUChar(), BytesRead++
					If (byte<>this.Stats["RLEColorIndex"])
						this.FrameData[Index,Indexi]:=byte, Indexi++
					Else
						{
						count:=this.DataMem.ReadUChar(), BytesRead++
						If (count>254)
							Console.Send("Frame " Index " count of compressed chars at Byte " BytesRead-1 " is >254.  This may cause issues for BAMWorkshop: count=" count "`r`n","W")
						Loop, % (count+1)
							this.FrameData[Index,Indexi]:=byte, Indexi++
						}
					;Console.Send("Tell=" this.DataMem.Tell() A_Tab "Length=" this.DataMem.Length A_Tab "Indexi=" Indexi A_Tab "PixelCount=" PixelCount "`r`n")
					If (Indexi>=PixelCount)
						Break
					Else If (this.DataMem.Tell()>=this.DataMem.Length-1) ; 20191217 - Bytes have been truncated from the end of the last frame!  There are not enough pixels to reach PixelCount.
						{
						Console.Send("FrameData of Frame " Index " is too short to fill all " PixelCount " pixels. Remaining " PixelCount-Indexi " pixels will be filled with RLEColorIndex (" this.Stats["RLEColorIndex"] ").`r`n","W")
						Loop, % PixelCount-Indexi
							this.FrameData[Index,Indexi]:=this.Stats["RLEColorIndex"], Indexi++
						;MsgBox % "End of file reached with " PixelCount-Indexi " pixels remaining."
						Break
						}
					}
				}
			ByteCount:=this.FrameData[Index].Count() ;(this.FrameData[Index].MaxIndex()=""?0:this.FrameData[Index].MaxIndex()+1)
			If (ByteCount<>PixelCount)
				Console.Send("Frame " Index " is " ByteCount " bytes long but was expected to be " PixelCount " bytes!`r`n","W")
			}
		this._CalcSizeOfFrameData(this.DataMem.Position)
		If (this.Stats.SizeOfFrameData>BytesRead)
			Console.Send("SizeOfFrameData>BytesReadFrameData (" this.Stats.SizeOfFrameData ">" BytesRead ")`r`n","W")
		Console.Send("BAM Frame Data read in " (QPC(1)-tic) " sec.`r`n","-I")
	}
	_ReadDataBlocks(){
		tic:=QPC(1)
		this.DataMem.Seek(this.Stats.OffsetToDataBlocks,0)
		this.DataBlocks:={}
		Console.Send(FormatStr("DataBlock",A_Space,10,"C") FormatStr("PVRZpage",A_Space,9,"C") FormatStr("PVRZFile",A_Space,13,"C") FormatStr("SourceX",A_Space,8,"C") FormatStr("SourceY",A_Space,8,"C") FormatStr("Width",A_Space,6,"C") FormatStr("Height",A_Space,7,"C") FormatStr("TargetX",A_Space,8,"C") RTrim(FormatStr("TargetY",A_Space,8,"C"),A_Space) "`r`n","I")
		Loop, % this.Stats.CountOfDataBlocks
			{
			Index:=A_Index-1, Console.Send("     " FormatStr(Index,A_Space,10,"C"),"-I")
			this.DataBlocks[Index,"PVRZpage"]:=SubStr("0000" this.DataMem.ReadDWORD(),-3), Console.Send(FormatStr(this.DataBlocks[Index,"PVRZpage"],A_Space,9,"C"),"-I")
			this.DataBlocks[Index,"PVRZFile"]:="MOS" this.DataBlocks[Index,"PVRZpage"] ".PVRZ", Console.Send(FormatStr(this.DataBlocks[Index,"PVRZFile"],A_Space,13,"C"),"-I")
			this.DataBlocks[Index,"SourceX"]:=this.DataMem.ReadDWORD(), Console.Send(FormatStr(this.DataBlocks[Index,"SourceX"],A_Space,8,"C"),"-I")
			this.DataBlocks[Index,"SourceY"]:=this.DataMem.ReadDWORD(), Console.Send(FormatStr(this.DataBlocks[Index,"SourceY"],A_Space,8,"C"),"-I")
			this.DataBlocks[Index,"Width"]:=this.DataMem.ReadDWORD(), Console.Send(FormatStr(this.DataBlocks[Index,"Width"],A_Space,6,"C"),"-I")
			this.DataBlocks[Index,"Height"]:=this.DataMem.ReadDWORD(), Console.Send(FormatStr(this.DataBlocks[Index,"Height"],A_Space,7,"C"),"-I")
			this.DataBlocks[Index,"TargetX"]:=this.DataMem.ReadDWORD(), Console.Send(FormatStr(this.DataBlocks[Index,"TargetX"],A_Space,8,"C"),"-I")
			this.DataBlocks[Index,"TargetY"]:=this.DataMem.ReadDWORD(), Console.Send(FormatStr(this.DataBlocks[Index,"TargetY"],A_Space,8,"C") "`r`n","-I")
			}
		Console.Send("BAM Data Blocks read in " (QPC(1)-tic) " sec.`r`n","-I")
	}
	_ReadPVRZPages(){
		tic:=QPC(1)
		PVR:={}
		SplitPath, % (this.InputPath), , InDir
		Path:=RegExReplace(InDir,"\\$")
		Loop, % this.Stats.CountOfDataBlocks
			{
			Index:=A_Index-1
			file:=this.DataBlocks[Index,"PVRZFile"]
			If !PVR.HasKey(file)
				{
				If !FileExist(Path "\" file)
					throw Exception(file " was referenced but could not be found in '" Path "\'.",,"All relevant PVRZ files should be placed in the same directory as the the BAM V2 file.`n`n" Traceback())
				PVR[file]:=New PSPVR()
				PVR[file].LoadPVRFromFile(Path "\" file)
				PVR[file].AlphaCutoff(0)
				}
			this.DataBlocks[Index,"SubTexture"]:=PVR[file].ExtractSubTexture(0,this.DataBlocks[Index,"SourceX"],this.DataBlocks[Index,"SourceY"],this.DataBlocks[Index,"Width"],this.DataBlocks[Index,"Height"])
			}
		Console.Send("PVR SubBlocks read in " (QPC(1)-tic) " sec.`r`n","-I")
	}
	;~ _ConvertPVRSubBlocksToFrames(){
		;~ tic:=QPC(1)
		;~ ; Initialize space to store paletted and unpaletted frame data
		;~ this.FrameData:={}, this.FrameData.SetCapacity(this.Stats.CountOfFrameEntries)
		;~ UPFrames:={}, UPFrames.SetCapacity(this.Stats.CountOfFrameEntries)
		;~ ; Initialize Quantizer
		;~ Quant:=New PS_Quantization()
		;~ Quant.AddReservedColor(0,255,0,0)
		;~ Quant.AddReservedColor(0,0,0,0)
		;~ Loop, % this.Stats.CountOfFrameEntries
			;~ {
			;~ Index:=A_Index-1
			;~ W:=this.FrameEntries[Index,"Width"]
			;~ H:=this.FrameEntries[Index,"Height"]
			;~ X:=this.FrameEntries[Index,"CenterX"]
			;~ Y:=this.FrameEntries[Index,"CenterY"]
			;~ Idx:=this.FrameEntries[Index,"IndexIntoDataBlocks"]
			;~ Cnt:=this.FrameEntries[Index,"CountOfDataBlocks"]
			;~ If (Cnt=0)
				;~ this.FrameData[Index]:=[]
			;~ Else
				;~ {
				;~ ; Determine true canvas size if there is a mismatch btwn dimensions in FrameEntries and DataBlocks
				;~ CanvasWidth:=CanvasHeight:=1
				;~ Loop, % Cnt
					;~ {
					;~ CanvasWidth:=(this.DataBlocks[Idx+A_Index-1,"Width"]+this.DataBlocks[Idx+A_Index-1,"TargetX"]>CanvasWidth?this.DataBlocks[Idx+A_Index-1,"Width"]+this.DataBlocks[Idx+A_Index-1,"TargetX"]:CanvasWidth)
					;~ CanvasHeight:=(this.DataBlocks[Idx+A_Index-1,"Height"]+this.DataBlocks[Idx+A_Index-1,"TargetY"]>CanvasHeight?this.DataBlocks[Idx+A_Index-1,"Height"]+this.DataBlocks[Idx+A_Index-1,"TargetY"]:CanvasHeight)
					;~ }
				;~ If (CanvasWidth<>W) OR (CanvasHeight<>H)
					;~ {
					;~ Console.Send("Calculated canvas dimensions (" CanvasWidth "x" CanvasHeight ") do not match frame dimensions (" W "x" H  ") for FrameEntry " Index ".`r`n","W")
					;~ W:=this.FrameEntries[Index,"Width"]:=CanvasWidth:=(CanvasWidth<W?W:CanvasWidth)
					;~ H:=this.FrameEntries[Index,"Height"]:=CanvasHeight:=(CanvasHeight<H?H:CanvasHeight)
					;~ }
				;~ ; Create virtual canvas
				;~ Canvas:={}, Canvas.SetCapacity(Px:=CanvasWidth*CanvasHeight)
				;~ Loop, %Px% ; Initialize virtual canvas to transparent green
					;~ Canvas[A_Index-1,"RR"]:=0, Canvas[A_Index-1,"GG"]:=255, Canvas[A_Index-1,"BB"]:=0, Canvas[A_Index-1,"AA"]:=0
				;~ ; Composite PVR SubTextures onto Canvas
				;~ Loop, % Cnt
					;~ {
					;~ Idxi:=Idx+A_Index-1
					;~ FrameUP:=this.DataBlocks[Idxi,"SubTexture"]
					;~ sX:=this.DataBlocks[Idxi,"TargetX"]
					;~ sY:=this.DataBlocks[Idxi,"TargetY"]
					;~ sW:=this.DataBlocks[Idxi,"Width"]
					;~ sH:=this.DataBlocks[Idxi,"Height"]
					;~ this._CompositeUC(FrameUP,sX,sY,sW,sH,Canvas,CanvasWidth,CanvasHeight)
					;~ }
				;~ UPFrames[UPFrames.Count()]:=Canvas ; Store Canvas as an unpaletted frame for later use
				;~ ; Start feeding pixels from Canvas into quantizer
				;~ For k,v in Canvas
					;~ Quant.AddColor(v["RR"],v["GG"],v["BB"],v["AA"])
				;~ }
			;~ }
		;~ ; Quantize colors
		;~ Console.Send("ColorCount = " Quant.GetColorCount() "`r`n","I")
		;~ Quant.Quantize(256)
		;~ Console.Send("Total Error: " Quant.GetTotalError() "`r`n","I")
		;~ ; Store generated palette
		;~ this.Palette:=PalObj:=Quant.GetPaletteObj()
		;~ ; Convert unpaletted frames to paletted
		;~ For k,v in UPFrames
			;~ {
			;~ this.FrameData[k].SetCapacity(v.Count())
			;~ For k2,v2 in v
				;~ this.FrameData[k,k2]:=Quant.GetQuantizedColorIndex(v2["RR"],v2["GG"],v2["BB"],v2["AA"])
			;~ }
		;~ Quant:=""
		;~ this.Stats.TransColorIndex:=0
		;~ this.Stats.ShadowColorIndex:=1
		;~ Console.Send("PVR SubBlocks converted to frames in " (QPC(1)-tic) " sec.`r`n","-I")
	;~ }
	_MakeV2FrameEntriesLUT(){
		FrameEntriesLUT:={}
		Loop, % this.Stats.CountOfFrameEntries
			{
			Index:=A_Index-1
			Key:="_" this.FrameEntries[Index,"Width"] this.FrameEntries[Index,"Height"] this.FrameEntries[Index,"CenterX"] this.FrameEntries[Index,"CenterY"] this.FrameEntries[Index,"IndexIntoDataBlocks"] this.FrameEntries[Index,"CountOfDataBlocks"]
			If !FrameEntriesLUT.HasKey(Key)
				{
				FrameEntriesLUT[Key]:=Index
				FrameEntriesLUT[Index]:=Index
				}
			Else
				FrameEntriesLUT[Index]:=FrameEntriesLUT[Key]
			}
		Return FrameEntriesLUT
	}
	_ConvertPVRSubBlocksToFrames(){
		tic:=QPC(1)
		; Initialize space to store paletted frame data
		this.FrameData:={}, this.FrameData.SetCapacity(this.Stats.CountOfFrameEntries)
		; Load an external palette if directed to do so
		If FileExist(Settings.ReplacePalette) AND (Settings.ReplacePaletteMethod<>"Quant")
			PalObj:=this._ReadBAMDPalette("",Settings.ReplacePalette)
		If PalObj.Count()	; We loaded a palette from somewhere
			{
			this.Palette:=PalObj
			Histo:=""
			}
		Else
			{
			; Initialize space to store unpaletted frame data
			UPFrames:={}, UPFrames.SetCapacity(this.Stats.CountOfFrameEntries)
			; Initialize Quantizer
			Quant:=New PS_Quantization()
			Quant.AddReservedColor(0,255,0,0)
			Quant.AddReservedColor(0,0,0,0)
			}
		; Initialize LUT to speed up generating frames for BAMs with duplicate frames
		;~ FrameEntriesLUT:=this._MakeV2FrameEntriesLUT()
		Loop, % this.Stats.CountOfFrameEntries
			{
			Index:=A_Index-1
			;~ If (FrameEntriesLUT[Index]<>Index)
				;~ Continue ; This will be a duplicate frame
			Console.Send("Generating FrameData for Frame " Index ".`r`n","I")
			W:=this.FrameEntries[Index,"Width"], H:=this.FrameEntries[Index,"Height"]
			Idx:=this.FrameEntries[Index,"IndexIntoDataBlocks"], Cnt:=this.FrameEntries[Index,"CountOfDataBlocks"]
			If !Cnt
				this.FrameData[Index]:=[]
			Else
				{
				; Determine true canvas size if there is a mismatch btwn dimensions in FrameEntries and DataBlocks
				CanvasWidth:=CanvasHeight:=0
				Loop, % Cnt
					{
					Idxi:=Idx+A_Index-1
					CanvasWidth:=((DBWX:=this.DataBlocks[Idxi,"Width"]+this.DataBlocks[Idxi,"TargetX"])>CanvasWidth?DBWX:CanvasWidth)
					CanvasHeight:=((DBHY:=this.DataBlocks[Idxi,"Height"]+this.DataBlocks[Idxi,"TargetY"])>CanvasHeight?DBHY:CanvasHeight)
					}
				If (CanvasWidth<>W) OR (CanvasHeight<>H)
					{
					Console.Send("Calculated canvas dimensions (" CanvasWidth "x" CanvasHeight ") do not match frame dimensions (" W "x" H  ") for FrameEntry " Index ".`r`n","W")
					W:=this.FrameEntries[Index,"Width"]:=CanvasWidth:=(CanvasWidth<W?W:CanvasWidth)
					H:=this.FrameEntries[Index,"Height"]:=CanvasHeight:=(CanvasHeight<H?H:CanvasHeight)
					}
				If (Cnt=1) AND (this.DataBlocks[Idx,"TargetX"]=0) AND (this.DataBlocks[Idx,"TargetY"]=0) AND (this.DataBlocks[Idx,"Width"]=W) AND (this.DataBlocks[Idx,"Height"]=H) ; If 1 frame that is entire canvas
					{
					If PalObj.Count() ; We already have a palette
						{
						this.FrameData[Index]:=this._ConvertFrameToPaletted(this.DataBlocks[Idx,"SubTexture"],this.Palette,Histo)
						;Console.Send("Histogram contains " Histo.Count() " colors.`r`n","-I")
						}
					Else ; We will need to quantize the frame
						UPFrames[Index]:=this.DataBlocks[Idx,"SubTexture"] ; Store Canvas as an unpaletted frame for later use
					}
				Else ; More than one frame or frame doesn't take up entire canvas, so we need to composite it/them onto background
					{
					; Create virtual canvas
					Canvas:={}, Canvas.SetCapacity(Px:=CanvasWidth*CanvasHeight)
					Loop, %Px% ; Initialize virtual canvas to transparent green
						Canvas[A_Index-1,"RR"]:=0, Canvas[A_Index-1,"GG"]:=255, Canvas[A_Index-1,"BB"]:=0, Canvas[A_Index-1,"AA"]:=0
					; Composite PVR SubTextures onto Canvas
					Loop, % Cnt
						{
						Idxi:=Idx+A_Index-1
						this._CompositeUP(this.DataBlocks[Idxi,"SubTexture"],this.DataBlocks[Idxi,"TargetX"],this.DataBlocks[Idxi,"TargetY"],this.DataBlocks[Idxi,"Width"],this.DataBlocks[Idxi,"Height"],Canvas,CanvasWidth,CanvasHeight)
						}
					If PalObj.Count() ; We already have a palette
						this.FrameData[Index]:=this._ConvertFrameToPaletted(Canvas,this.Palette,Histo)
					Else ; We will need to quantize the frame
						{
						UPFrames[Index]:=Canvas ; Store Canvas as an unpaletted frame for later use
						; Start feeding pixels from Canvas into quantizer
						For k,v in Canvas
							Quant.AddColor(v["RR"],v["GG"],v["BB"],v["AA"])
						}
					}
				}
			}
		If !PalObj.Count() ; If we are quantizing the frames
			{
			; Quantize colors
			Console.Send("ColorCount = " Quant.GetColorCount() "`r`n","I")
			Quant.Quantize(256)
			Console.Send("Total Error: " Quant.GetTotalError() "`r`n","I")
			; Store generated palette
			this.Palette:=PalObj:=Quant.GetPaletteObj()
			; Convert unpaletted frames to paletted
			For k,v in UPFrames
				{
				this.FrameData[k].SetCapacity(v.Count())
				For k2,v2 in v
					this.FrameData[k,k2]:=Quant.GetQuantizedColorIndex(v2["RR"],v2["GG"],v2["BB"],v2["AA"])
				}
			Quant:=""
			}
		Else ; We have already applied the specified palette.
			Settins.ReplacePalette:=""
		;~ Loop, % this.Stats.CountOfFrameEntries
			;~ {
			;~ Index:=A_Index-1
			;~ If !IsObject(this.FrameData[Index])
				;~ {
				;~ Console.Send("Generating FrameData for Frame " Index ".`r`n","I")
				;~ this.FrameData[Index]:=ObjFullyClone(this.FrameData[FrameEntriesLUT[Index]])
				;~ }
			;~ }
		this.Stats.TransColorIndex:=0
		this.Stats.ShadowColorIndex:=1
		Console.Send("PVR SubBlocks converted to frames in " (QPC(1)-tic) " sec.`r`n","-I")
	}
	_WriteFrameData(){ ;;;;; BAM V1 Frame Data ;;;;;
		tic:=QPC(1)
		If (Settings.DebugLevelS>=2)
			this.PrintFrameData()
		this.DataMem.Seek(this.Stats.OffsetToFrameData,0)
		Loop, % this.Stats.CountOfFrames
			{
			Index:=A_Index-1, FrameDataEntry:=this._GetFrameData1stFrameEntry(Index), PixelCount:=this.FrameEntries[FrameDataEntry,"Width"]*this.FrameEntries[FrameDataEntry,"Height"]
			;~ this.DataMem.Seek(this.FrameEntries[Index,"OffsetToFrameData"],0)
			If !(this.FrameEntries[FrameDataEntry,"RLE"]) AND (FrameDataEntry<>"")	; Frame Data is NOT RLE and has an associated Frame Entry
				{
				If (PixelCount<>(Cnt:=this.FrameData[Index].Count())) ;(this.FrameData[Index].MaxIndex()=""?0:this.FrameData[Index].MaxIndex()+1))
					throw Exception("Frame " Index " is " Cnt " bytes long but was expected to be " PixelCount " bytes!",,"FrameDataEntry=" FrameDataEntry "`n`n" Traceback())
				Loop, % PixelCount
					{
					Index2:=A_Index-1
					this.DataMem.WriteUChar(this.FrameData[Index,Index2])
					}
				}
			Else	; Frame Data IS RLE
				{
				Loop, % this.FrameData[Index].Count() ;MaxIndex()+1
					{
					Index2:=A_Index-1
					this.DataMem.WriteUChar(this.FrameData[Index,Index2])
					}
				}
			}
		Console.Send("BAM Frame Data written in " (QPC(1)-tic) " sec.`r`n","-I")
	}
	_DecompressBAM(){
		tic:=QPC(1)
		OriginalSize:=this.Stats.UncompressedSize
		VarSetCapacity(Decompressed,OriginalSize)
		ErrorLevel:=DllCall(PS_DirArch "\zlib1.dll\uncompress","Ptr",&Decompressed,"UIntP",OriginalSize,"Ptr",this.GetAddress("Raw")+12,"UInt",this.Stats.FileSize-12,"Cdecl")
		If (ErrorLevel<0)
			throw Exception("ErrorLevel=" ErrorLevel A_Tab "A_LastError=" A_LastError,,"zlib Decompression Error`n`n" Traceback())
		this.Stats.FileSize:=OriginalSize, Console.Send("FileSize=" this.Stats.FileSize "`r`n","I")
		this.Delete("Raw"), this.Raw:=" ", this.SetCapacity("Raw",OriginalSize), this.DataMem:=""
		DllCall("RtlMoveMemory","Ptr",this.GetAddress("Raw"),"Ptr",&Decompressed,"UInt",OriginalSize)
		this.DataMem:=New MemoryFileIO(this.GetAddress("Raw"),OriginalSize)
		this.Stats.Delete("UncompressedSize"), OriginalSize:="", VarSetCapacity(Decompressed,0) ; memory cleanup
		Console.Send("BAMC Decompressed in " (QPC(1)-tic) " sec.`r`n","-I")
	}
	_zlibCompressBAM(){
		tic:=QPC(1)
		DataLen:=this.Stats.FileSize
		nSize:=DllCall(PS_DirArch "\zlib1.dll\compressBound","UInt",DataLen,"Cdecl")
		VarSetCapacity(Compressed,nSize)
		ErrorLevel:=DllCall(PS_DirArch "\zlib1.dll\compress2","ptr",&Compressed,"UIntP",nSize,"ptr",this.GetAddress("Raw"),"UInt",DataLen,"Int",9,"Cdecl")
		If (ErrorLevel<0)
			throw Exception("ErrorLevel=" ErrorLevel A_Tab "A_LastError=" A_LastError,,"zlib Compression Error`n`n" Traceback())
		this.Delete("Raw"), this.Raw:=" ", this.SetCapacity("Raw",nSize+12), this.DataMem:="", this.DataMem:=New MemoryFileIO(this.GetAddress("Raw"),nSize+12)
		this.DataMem.Write("BAMCV1" A_Space A_Space), this.DataMem.WriteUInt(DataLen)
		DllCall("RtlMoveMemory","Ptr",this.GetAddress("Raw")+12,"Ptr",&Compressed,"UInt",nSize)
		VarSetCapacity(Compressed,0) ; memory cleanup
		this.Stats.UncompressedSize:=DataLen, this.Stats.FileSize:=nSize+12, this.Stats.Signature:="BAMC"
		Console.Send("BAM zlib Compressed in " (QPC(1)-tic) " sec.`r`n","-I")
	}
	_zopfliCompressBAM(OutputPath){
		tic:=QPC(1), Console.Send("Beginning zlib-compliant zopfli compression with " Settings.zopfliIterations " iterations.  This could take a while...`r`n","-W")
		VarSetCapacity(options,24,0)
			NumPut(0,&options,0,"Int")							; verbose
			NumPut(0,&options,4,"Int")							; verbose_more
			NumPut(Settings.zopfliIterations,&options,8,"Int")	; numiterations
			NumPut(1,&options,12,"Int")							; blocksplitting
			NumPut(0,&options,16,"Int")							; blocksplittinglast
			NumPut(15,&options,20,"Int")						; blocksplittingmax
		insize:=this.Stats.FileSize
		VarSetCapacity(out,DllCall(PS_DirArch "\zlib1.dll\compressBound","UInt",insize,"Cdecl"))
		out:=0
		outsize:=0
		VarSetCapacity(outptr,A_PtrSize)	; ZopfliZlibCompress function wants a pointer to a pointer to the first byte of the "out" variable.
		NumPut(&out,outptr,0,"ptr")
		DllCall(PS_DirArch "\libzopfli.dll\ZopfliZlibCompress","ptr",&options,"ptr",this.GetAddress("Raw"),"UInt",insize,"ptr",&outptr,"UIntP",outsize,"Cdecl")
		OffsetToOut:=NumGet(outptr,0,"ptr")
		
		this.Delete("Raw"), this.Raw:=" ", this.SetCapacity("Raw",outsize+12), this.DataMem:="", this.DataMem:=New MemoryFileIO(this.GetAddress("Raw"),outsize+12)
		this.DataMem.Write("BAMCV1" A_Space A_Space), this.DataMem.WriteUInt(this.Stats.FileSize)
		DllCall("RtlMoveMemory","Ptr",this.GetAddress("Raw")+12,"Ptr",OffsetToOut,"UInt",outsize)
		DllCall("msvcrt.dll\free","ptr",OffsetToOut,"Cdecl")
		VarSetCapacity(OffsetToOut,0) ; memory cleanup
		this.Stats.UncompressedSize:=insize, this.Stats.FileSize:=outsize+12, this.Stats.Signature:="BAMC"
		Console.Send("BAM zopfli Compressed in " (QPC(1)-tic) " sec.`r`n","-I")
	}
	_CalcSizeOfPalette(){
		If (this.Stats.Signature="BAMU") OR ((this.Stats.Signature="BAM ") AND (this.Stats.Version="V2  "))
			this.Stats.CountOfPaletteEntries:=0
		Else
			{
			SizeOfPalette:=256*4
			If (this.Stats.OffsetToFrameEntries-this.Stats.OffsetToPalette>0) AND (this.Stats.OffsetToFrameEntries-this.Stats.OffsetToPalette<SizeOfPalette)
				SizeOfPalette:=(this.Stats.OffsetToFrameEntries-this.Stats.OffsetToPalette)
			If (this.Stats.OffsetToCycleEntries-this.Stats.OffsetToPalette>0) AND (this.Stats.OffsetToCycleEntries-this.Stats.OffsetToPalette<SizeOfPalette)
				SizeOfPalette:=(this.Stats.OffsetToCycleEntries-this.Stats.OffsetToPalette)
			If (this.Stats.OffsetToFLT-this.Stats.OffsetToPalette>0) AND (this.Stats.OffsetToFLT-this.Stats.OffsetToPalette<SizeOfPalette)
				SizeOfPalette:=(this.Stats.OffsetToFLT-this.Stats.OffsetToPalette)
			If (this.Stats.OffsetToFrameData-this.Stats.OffsetToPalette>0) AND (this.Stats.OffsetToFrameData-this.Stats.OffsetToPalette<SizeOfPalette)
				SizeOfPalette:=(this.Stats.OffsetToFrameData-this.Stats.OffsetToPalette)
			While (Mod(SizeOfPalette,4)>0)
				SizeOfPalette+=1
			this.Stats.CountOfPaletteEntries:=SizeOfPalette//4
			}
	}
	_CalcTransColorIndex(){	; this.Stats.WasBAMC=1
		this.Stats.TransColorIndex:=0, isGreen:=0
		Loop, % (Settings.SearchTransColor=1?this.Stats.CountOfPaletteEntries:1)
			{
			Index:=A_Index-1
			If (this.Palette[Index,"RR"]=0) AND (this.Palette[Index,"GG"]=255) AND (this.Palette[Index,"BB"]=0) AND (this.Palette[Index,"AA"]=0)
				{
				this.Stats.TransColorIndex:=Index, isGreen:=1
				If (Index<>0)
					Console.Send("TransColorIndex is " Index " but is usually 0." "`r`n","W")
				Break
				}
			}
		If !(isGreen)
			Console.Send("TransColor is (" this.Palette[0,"RR"] A_Space this.Palette[0,"GG"] A_Space this.Palette[0,"BB"] A_Space this.Palette[0,"AA"] ") but is usually Green (0 255 0 0)" "`r`n","W")
	}
	_CalcShadowColorIndex(){
		this.Stats.ShadowColorIndex:=-1
		If (this.Palette[1,"RR"]=0) AND (this.Palette[1,"GG"]=0) AND (this.Palette[1,"BB"]=0) AND (this.Palette[1,"AA"]=0)
			this.Stats.ShadowColorIndex:=1
		Else
			Console.Send("Palette does not have a true shadow color.  The color in palette entry 1 is RGBA(" this.Palette[1,"RR"] "," this.Palette[1,"GG"] "," this.Palette[1,"BB"] "," this.Palette[1,"AA"] ").`r`n","W")
		}
	_CalcSizeOfFrameData(LastFrameDataByte){
		;~ this.Stats.SizeOfFrameData:=this.Stats.FileSize-this.Stats.OffsetToFrameData	; assumption!
		Return this.Stats.SizeOfFrameData:=LastFrameDataByte-this.Stats.OffsetToFrameData
	}
	_UpdateStats(){
		;~ this.Stats.OriginalSignature:=this.Stats.OriginalSignature
		;~ this.Stats.OriginalVersion:=this.Stats.OriginalVersion
		;~ this.Stats.OriginalFileSize:=this.Stats.OriginalFileSize
		;~ this.Stats.Signature:=this.Stats.Signature
		;~ this.Stats.Version:=this.Stats.Version
		;~ this.Stats.FileSize:=this.Stats.FileSize
		;~ this.Stats.RLEColorIndex:=this.Stats.RLEColorIndex
		this.Stats.CountOfPaletteEntries:=this.Palette.Count()	;this.Palette.MaxIndex()+1
		this._CalcTransColorIndex()
		this._CalcShadowColorIndex()
		If (this.Stats.RLEColorIndex="")
			this.Stats.RLEColorIndex:=0
		
		this.Stats.PaletteHasAlpha:=0
		Loop, % (this.Stats.CountOfPaletteEntries)
			{
			Index:=A_Index-1
			If (this.Palette[Index,"AA"]>0) AND (this.Palette[Index,"AA"]<>"")
				this.Stats.PaletteHasAlpha:=1
			}
		this.Stats.CountOfFrameEntries:=this.FrameEntries.Count() ;MaxIndex()+1
		this.Stats.RLE:=0
		Loop, % this.Stats.CountOfFrameEntries
			{
			Index:=A_Index-1
			If (this.FrameEntries[Index,"RLE"]=1)
				this.Stats.RLE:=1
			}
		this.Stats.CountOfCycles:=this.CycleEntries.Count() ;MaxIndex()+1
		this.Stats.CountOfFLTEntries:=this.FrameLookupTable.Count() ;MaxIndex()+1
		this.Stats.CountOfFrames:=this.FrameData.Count() ;MaxIndex()+1
		this.Stats.OffsetToHeader:=0
		this.Stats.SizeOfHeader:=24
		this.Stats.OffsetToFrameEntries:=this.Stats.SizeOfHeader
		this.Stats.SizeOfFrameEntries:=12*this.Stats.CountOfFrameEntries
		this.Stats.OffsetToCycleEntries:=this.Stats.OffsetToFrameEntries+this.Stats.SizeOfFrameEntries
		this.Stats.SizeOfCycleEntries:=4*this.Stats.CountOfCycles
		this.Stats.OffsetToPalette:=this.Stats.OffsetToCycleEntries+this.Stats.SizeOfCycleEntries
		this.Stats.SizeOfPalette:=(Settings.AllowShortPalette=1?4*this.Stats.CountOfPaletteEntries:1024)
		this.Stats.OffsetToFLT:=this.Stats.OffsetToPalette+this.Stats.SizeOfPalette
		this.Stats.SizeOfFLT:=2*this.Stats.CountOfFLTEntries
		this.Stats.OffsetToFrameData:=this.Stats.OffsetToFLT+this.Stats.SizeOfFLT
		this.Stats.SizeOfFrameData:=0
		Loop, % (this.Stats.CountOfFrames)
			{
			Index:=A_Index-1
			this.Stats.SizeOfFrameData+=(this.FrameData[Index].Count()) ;MaxIndex()+1
			}
		this.Stats.FileSize:=this.Stats.SizeOfHeader+this.Stats.SizeOfFrameEntries+this.Stats.SizeOfCycleEntries+this.Stats.SizeOfPalette+this.Stats.SizeOfFLT+this.Stats.SizeOfFrameData
		this._UpdateFrameEntriesOffsets()
		
		;~ Data:=""	; Delete this later
		;~ For key, value in this.Stats
			;~ Data.= key "=" value "`r`n"
		;~ Console.Send("`r`n" Data "`r`n","I")
		;~ MsgBox % Data
		;~ Data:=""
		}
	_UpdateFrameEntriesOffsets(){
		Loop, % this.Stats.CountOfFrameEntries
			{
			Index:=A_Index-1
			temp:=this.Stats.OffsetToFrameData
			Loop, % (this.FrameEntries[Index,"FramePointer"])
				{
				Index2:=A_Index-1
				temp+=(this.FrameData[Index2].Count()) ;MaxIndex()+1
				}
			this.FrameEntries[Index,"OffsetToFrameData"]:=temp
			;~ Console.Send("Frame Entry: " Index ", FramePointer: " this.FrameEntries[Index,"FramePointer"] ", Start Offset: " this.Stats.OffsetToFrameData ", TotalOffset: " temp "`r`n","I")
			}
	}
}

class ExBAMIO extends ImBAMIO{
	ExportFrames(Output){
		If (Settings.ExportFramesAsSequences)
			this.ExportSequences(Output)
		Else
			{
			tic:=QPC(1)
			Fmt:=StrSplit(Settings.ExportFrames,","), DV:=[8,3]
			If (Fmt.Length()>1)
				DV:=StrSplit(Fmt[2],["V","v"])
			Ext:=(Fmt[1]?Fmt[1]:"bmp")
			StringLower, Ext, Ext
			BitDepth:=DV[1], Version:=DV[2]
			Loop, % this.Stats.CountOfFrames
				{
				Index:=A_Index-1
				this.ExportFrame(Output "_Frame_" SubStr("0000" Index,-3) "." Ext,Index,BitDepth,Version)
				}
			Console.Send(Index+1 " Frames exported to the '" Ext "' format in " (QPC(1)-tic) " sec.`r`n","-I")
			}
	}
	ExportSequences(Output){	; This isn't working properly!! 20180531
		tic:=QPC(1)
		Fmt:=StrSplit(Settings.ExportFrames,","), DV:=[8,3]
		If (Fmt.Length()>1)
			DV:=StrSplit(Fmt[2],["V","v"])
		Ext:=(Fmt[1]?Fmt[1]:"bmp")
		StringLower, Ext, Ext
		BitDepth:=DV[1], Version:=DV[2]
		Loop, % this.Stats.CountOfCycles
			{
			Index:=A_Index-1
			Idx:=this.CycleEntries[Index,"IndexIntoFLT"]
			Loop, % this.CycleEntries[Index,"CountOfFrameIndices"]
				{
				Indexi:=A_Index-1
				Entry:=this.FrameLookupTable[Idx+Indexi]
				Val:=this.FrameEntries[Entry,"FramePointer"]
				this.ExportFrame(Output "_Sequence_" SubStr("0000" Index,-3) "_Frame_" SubStr("0000" Indexi,-3) "." Ext,Val,BitDepth,Version)
				}
			}
		Console.Send(Index+1 " Sequences exported to the '" Ext "' format in " (QPC(1)-tic) " sec.`r`n","-I")
	}
	ExportFrame(Output0,FrameNum,BitDepth:=8,Version:=3){
		SplitPath, Output0, OutFileName, OutDir, OutExtension, OutNameNoExt, OutDrive
		Fmt:=StrSplit(OutExtension,","), DV:=[BitDepth,Version]
		If (Fmt.Length()>1)
			DV:=StrSplit(Fmt[2],["V","v"])
		OutExtension:=(Fmt[1]?Fmt[1]:"bmp")
		If !BitDepth
			BitDepth:=DV[1]
		If !Version
			Version:=DV[2]
		Output0:=OutDir "\" OutNameNoExt "." OutExtension
		If (OutExtension="GIF")
			{
			Verbose:=Console.DebugLevel
			Console.DebugLevel:=(IsObject(Settings)?(Settings.DebugLevelP<1?Settings.DebugLevelP:1):1)
			FrameArray:=[FrameNum]
			this._CompileGIF(Output0,FrameArray,0)
			Console.DebugLevel:=Verbose
			}
		Else
			{
			Entry:=this._GetFrameData1stFrameEntry(FrameNum)
			Width:=this.FrameEntries[Entry,"Width"], Height:=this.FrameEntries[Entry,"Height"]
			BMP:=New PSBMP()
			BMP.LoadBMPFromFrameObj(this.FrameData[FrameNum],this.Palette,"",Width,Height)
			If (BitDepth=32)
				BMP.TransformTransparency(0,255)
			If (OutExtension="BMP")
				{
				BMP.SaveBMPToFile(Output0,BitDepth,Version)
				}
			Else
				{
				Raw:=""
				FileSize:=BMP.SaveBMPToVar(Raw,BitDepth,Version)
				pBitmap_F:=GDIPlus_pBitmapFromBuffer(Raw,FileSize)
				Error:=Gdip_SaveBitmapToFile(pBitmap_F,Output0)
				If (Error<0)
					throw Exception("ErrorLevel=" Error A_Tab "A_LastError=" A_LastError,,"Error in Gdip_SaveBitmapToFile() trying to convert and save '" Output0 "' to file.`n`n" Traceback())
				Gdip_DisposeImage(pBitmap_F)
				VarSetCapacity(Raw,0)
				}
			BMP:=""
			}
		}
	ExportPalette(Type,OutPath){
		tic:=QPC(1)
		PAL:=New PSPAL()
		PAL.ExportPalette(this.Palette,Type,OutPath,"",this.Stats.TransColorIndex)
		PAL:=""
		Console.Send("Palette exported in '" Type "' format in " (QPC(1)-tic) " sec.`r`n","-I")
	}
	_GetSequenceCanvasDimensions(Sequence,ByRef MinCenterX,ByRef MinCenterY,ByRef MaxWidth,ByRef MaxHeight,ByRef MaxCenterX,ByRef MaxCenterY,ByRef CanvasWidth,ByRef CanvasHeight){
		;;; Before calling the 1st time, set "MinCenterX:=MinCenterY:=1000000" AND "MaxWidth:=MaxHeight:=MaxCenterX:=MaxCenterY:=CanvasWidth:=CanvasHeight:=0"
		If (cCE:=this.CycleEntries[Sequence,"CountOfFrameIndices"])	; Skip Cycle Entries with zero frame indices
			{
			FrameArray:=GetSubArray(this.FrameLookupTable,this.CycleEntries[Sequence,"IndexIntoFLT"],cCE,1)
			;MinCenterX:=MinCenterY:=1000000
			OldShiftX:=(MinCenterX<0?0-MinCenterX:0), OldShiftY:=(MinCenterY<0?0-MinCenterY:0)
			For k,Entry in FrameArray
				{
				CenterX:=this.FrameEntries[Entry,"CenterX"]*-1, CenterY:=this.FrameEntries[Entry,"CenterY"]*-1
				MinCenterX:=(CenterX<MinCenterX?CenterX:MinCenterX), MinCenterY:=(CenterY<MinCenterY?CenterY:MinCenterY)
				}
			ShiftX:=(MinCenterX<0?0-MinCenterX:0), ShiftY:=(MinCenterY<0?0-MinCenterY:0)
			CanvasWidth+=ShiftX-OldShiftX, CanvasHeight+=ShiftY-OldShiftY
			;MaxWidth:=MaxHeight:=MaxCenterX:=MaxCenterY:=CanvasWidth:=CanvasHeight:=0
			For k,Entry in FrameArray
				{
				Width:=this.FrameEntries[Entry,"Width"], Height:=this.FrameEntries[Entry,"Height"]
				MaxWidth:=(Width>MaxWidth?Width:MaxWidth), MaxHeight:=(Height>MaxHeight?Height:MaxHeight)
				CenterX:=this.FrameEntries[Entry,"CenterX"]*-1+ShiftX, CenterY:=this.FrameEntries[Entry,"CenterY"]*-1+ShiftY
				MaxCenterX:=(CenterX>MaxCenterX?CenterX:MaxCenterX), MaxCenterY:=(CenterY>MaxCenterY?CenterY:MaxCenterY)
				CanvasWidth:=(CenterX+Width>CanvasWidth?CenterX+Width:CanvasWidth), CanvasHeight:=(CenterY+Height>CanvasHeight?CenterY+Height:CanvasHeight)
				}
			If (Settings.Unify=2)
				CanvasWidth:=(CanvasHeight>CanvasWidth?CanvasHeight:CanvasWidth), CanvasHeight:=(CanvasWidth>CanvasHeight?CanvasWidth:CanvasHeight)
			}
		Else
			ShiftX:=ShiftY:=0
		;	MinCenterX:=MinCenterY:=ShiftX:=ShiftY:=MaxWidth:=MaxHeight:=MaxCenterX:=MaxCenterY:=CanvasWidth:=CanvasHeight:=0
		CanvasDimensions:=[]
		CanvasDimensions["MinCenterX"]:=MinCenterX
		CanvasDimensions["MinCenterY"]:=MinCenterY
		CanvasDimensions["ShiftX"]:=ShiftX
		CanvasDimensions["ShiftY"]:=ShiftY
		CanvasDimensions["MaxWidth"]:=MaxWidth
		CanvasDimensions["MaxHeight"]:=MaxHeight
		CanvasDimensions["MaxCenterX"]:=MaxCenterX
		CanvasDimensions["MaxCenterY"]:=MaxCenterY
		CanvasDimensions["CanvasWidth"]:=CanvasWidth
		CanvasDimensions["CanvasHeight"]:=CanvasHeight
		;MsgBox % st_printArr(CanvasDimensions)
		Return CanvasDimensions
	}
	GetPaletteStats(OutPath,PaletteOutPath){
		SplitPath, OutPath, , , , OutNameNoExt
		SplitPath, PaletteOutPath, , OutDir
		
		Data:= OutNameNoExt A_Tab FileMD5(PaletteOutPath) A_Tab "(" this.Palette[this.Stats.TransColorIndex,"RR"] A_Space this.Palette[this.Stats.TransColorIndex,"GG"] A_Space this.Palette[this.Stats.TransColorIndex,"BB"] A_Space this.Palette[this.Stats.TransColorIndex,"AA"] ")" A_Tab "(" this.Palette[1,"RR"] A_Space this.Palette[1,"GG"] A_Space this.Palette[1,"BB"] A_Space this.Palette[1,"AA"] ")" "`r`n"
		FileAppend, %Data%, % RegExReplace(OutDir,"\\$") "\!Palette.txt"
	}
	SaveBAMD(Type,OutPath){
		Console.Send("`r`n","-W")
		Console.Send("SavePath='" OutPath ".bamd'`r`n","-E")
		tic:=QPC(1), BAMD:=""
		SplitPath, OutPath, , , , OutNameNoExt
		FramePath:=OutPath "\" OutNameNoExt
		FileCreateDir, %OutPath%
		If !InStr(FileExist(OutPath),"D")
			throw Exception("The output directory " A_Quote OutPath A_Quote " could not be created.  Verify --OutPath and input filename are valid, and that --OutPath does NOT end in a slash (" A_Quote "\" A_Quote ").`n`nFileExist() returned '" FileExist(OutPath) "'.`nErrorLevel=" ErrorLevel "`nA_LastError=" A_LastError,,"`n`n" Traceback())
		Fmt:=StrSplit(Type,",")
		OutExtension:=(Fmt[1]?Fmt[1]:"bmp")
		Loop, % this.Stats.CountOfFrames
			{
			Index:=A_Index-1
			BAMD.="frame f" SubStr("00000" Index,-4) A_Space A_Quote OutNameNoExt "/" OutNameNoExt SubStr("00000" Index,-4) "." OutExtension A_Quote A_Space this.FrameEntries[Index,"CenterX"] A_Space this.FrameEntries[Index,"CenterY"] "`r`n"
			this.ExportFrame(FramePath SubStr("00000" Index,-4) "." Type,Index)
			}
		Loop, % this.Stats.CountOfCycles
			{
			Index:=A_Index-1
			BAMD.="`r`nsequence"
			Loop, % this.CycleEntries[Index,"CountOfFrameIndices"]
				{
				Val:=this.FrameLookupTable[this.CycleEntries[Index,"IndexIntoFLT"]+A_Index-1]
				BAMD.=" f" SubStr("00000" Val,-4)
				}
			BAMD.="  // SEQ " Index
			}
		BAMD.="`r`n"
		StringReplace, BAMD, BAMD, \, /, All
		Console.Send("`r`n" BAMD "`r`n","I")
		IfExist, %OutPath%.bamd
			FileDelete, %OutPath%.bamd
		FileAppend, %BAMD%, %OutPath%.bamd
		PS_SummaryA[PS_SummaryA.MaxIndex(),"CompressedSize"]:="N/A"
		PS_SummaryA[PS_SummaryA.MaxIndex(),"%OfOriginalSize"]:="N/A"
		PS_SummaryA[PS_SummaryA.MaxIndex(),"%OfUncompressedSize"]:="N/A"
		Console.Send("BAMD Saved in " (QPC(1)-tic) " sec.`r`n","-I")
	}
	SaveGIF(OutPath,Single:=0){
		tic:=QPC(1)
		Console.Send("`r`n","-W")
		Console.Send("SavePath='" OutPath (Single?"":"*") ".gif'`r`n","-E")
		TotalSz:=0
		If (Single=1)
			{
			FrameArray:={}, FrameArray.SetCapacity(this.Stats.CountOfFrames)
			Loop, % this.Stats.CountOfFrameEntries
				FrameArray[A_Index-1]:=A_Index-1
			TotalSz+=this._CompileGIF(OutPath ".gif",FrameArray)
			PS_TotalBytesSaved+=(this.Stats.OriginalFileSize-TotalSz)
			}
		Else
			{
			Loop, % this.Stats.CountOfCycles	; Build FLT Array of Arrays that we will use to compute shortest possible FLT.
				{
				Index:=A_Index-1
				If (cCE:=this.CycleEntries[Index,"CountOfFrameIndices"])	; Skip Cycle Entries with zero frame indices
					{
					FrameArray:=GetSubArray(this.FrameLookupTable,this.CycleEntries[Index,"IndexIntoFLT"],cCE,1)
					TotalSz+=this._CompileGIF(OutPath "_Sequence_" SubStr("0000" Index,-3) ".gif",FrameArray)
					PS_TotalBytesSaved+=(this.Stats.OriginalFileSize-TotalSz)
					}
				}
			}
		PS_SummaryA[PS_SummaryA.MaxIndex(),"CompressedSize"]:=TotalSz
		PS_SummaryA[PS_SummaryA.MaxIndex(),"%OfOriginalSize"]:=TotalSz/this.Stats.OriginalFileSize*100 " %"
		PS_SummaryA[PS_SummaryA.MaxIndex(),"%OfUncompressedSize"]:=TotalSz/this.Stats.FullyUncompressedSize*100 " %"
		Console.Send("GIF Saved in " (QPC(1)-tic) " sec.`r`n","-I")
	}
	_CompileGIF(OutPath,FrameArray,Animated:=1){
		hGIF:=New PSGIF()
		hGIF.NewGif()
		If Animated
			hGIF.AddApplicationExtension()
		MinCenterX:=MinCenterY:=1000000
		For k,Entry in FrameArray
			{
			CenterX:=this.FrameEntries[Entry,"CenterX"]*-1, CenterY:=this.FrameEntries[Entry,"CenterY"]*-1
			MinCenterX:=(CenterX<MinCenterX?CenterX:MinCenterX), MinCenterY:=(CenterY<MinCenterY?CenterY:MinCenterY)
			}
		ShiftX:=(MinCenterX<0?0-MinCenterX:0), ShiftY:=(MinCenterY<0?0-MinCenterY:0)
		MaxWidth:=MaxHeight:=MaxCenterX:=MaxCenterY:=PageWidth:=PageHeight:=0
		For k,Entry in FrameArray
			{
			Width:=this.FrameEntries[Entry,"Width"], Height:=this.FrameEntries[Entry,"Height"]
			MaxWidth:=(Width>MaxWidth?Width:MaxWidth), MaxHeight:=(Height>MaxHeight?Height:MaxHeight)
			CenterX:=this.FrameEntries[Entry,"CenterX"]*-1+ShiftX, CenterY:=this.FrameEntries[Entry,"CenterY"]*-1+ShiftY
			MaxCenterX:=(CenterX>MaxCenterX?CenterX:MaxCenterX), MaxCenterY:=(CenterY>MaxCenterY?CenterY:MaxCenterY)
			PageWidth:=(CenterX+Width>PageWidth?CenterX+Width:PageWidth), PageHeight:=(CenterY+Height>PageHeight?CenterY+Height:PageHeight)
			
			Idx:=hGIF.AddFrame(this.FrameData[this.FrameEntries[Entry,"FramePointer"]])	; Was v
			
			hGIF.SetImageDescriptor(Idx,CenterX,CenterY,Width,Height)
			hGIF.AddGraphicsControlExtension(Idx,"Frame",2,0,1,10,this.Stats.TransColorIndex)
			}
		If (Settings.Unify=2)
			PageWidth:=(PageHeight>PageWidth?PageHeight:PageWidth), PageHeight:=(PageWidth>PageHeight?PageWidth:PageHeight)
		hGIF.ReplaceLogicalScreenDescriptor(PageWidth,PageHeight,1,7,0,0,this.Stats.TransColorIndex,0)
		hGIF.AddGlobalColorTable(this.Palette)
		;~ If Settings.Unify
			;~ hGIF.Unify(Settings.Unify)
		hGIF.SaveGIFToFile(OutPath)
		TotalSz:=hGIF.Stats.FileSize
		hGIF:=""
		Return TotalSz
	}
}

class ImBAMIO extends CompressBAM{
	ReplacePalette(InputFile:="",Address:="",Bytes:="",Method:="Force",PalObj:=""){		; | Force | Remap |
		tic:=QPC(1)
		PAL:=New PSPAL()
		If FileExist(InputFile)	; If we are loading palette from a file
			PalObj:=PAL.ImportPaletteFromFile(InputFile)
		Else If (Address) AND (Bytes)	; If we are loading palette from memory
			PalObj:=PAL.ImportPaletteFromMem(Address,Bytes)
		Else If !IsObject(PalObj) OR !(PalObj.Count()) ; Load default "paletted" palette
			PalObj:=this._GetRefPal()
		; Otherwise PalObj has been given and is to be used as the palette
		If (Method="Force")
			this.Palette:=PalObj
		Else	; Method="Remap"
			{
			Histo:=""
			Loop, % this.Stats.CountOfFrames
				Histo:=this._RemapPalette(this.Palette,PalObj,this.FrameData[A_Index-1],Histo)
			this.Palette:=PalObj
			}
		PAL:=""
		Console.Send("Palette replaced using '" Method "' method in " (QPC(1)-tic) " sec.`r`n","-I")
	}
	ImportFrame(InputFile,Address,Size,ByRef Quant,ByRef FrameObj,ByRef PalObj,SourceFrame:=1,PalMethod:="Force"){	; Force, Remap, Quant
		; Not yet implemented
	}
	_RemapPalette(ByRef OldPalette,ByRef NewPalette,ByRef FrameData,Histo:=""){
		If !IsObject(Histo) OR !(Histo.Count())
			{
			Histo:={}, Histo.SetCapacity(OldPalette.Count())
			Loop, % OldPalette.Count()
				{
				Index:=A_Index-1
				Dist:=0xFFFFFFFE ;0xFFFFFFFFFFFFFFF0
				Idx:=0
				Loop, % NewPalette.Count()
					{
					Indexi:=A_Index-1
					nDist:=(NewPalette[Indexi,"RR"]-OldPalette[Index,"RR"])**2+(NewPalette[Indexi,"GG"]-OldPalette[Index,"GG"])**2+(NewPalette[Indexi,"BB"]-OldPalette[Index,"BB"])**2+(NewPalette[Indexi,"AA"]-OldPalette[Index,"AA"])**2
					If (nDist<Dist)
						{
						Dist:=nDist
						Idx:=Indexi
						If (Dist=0)
							Break
						}
					}
				Histo[Index]:=Idx
				}
			}
		For k,v in FrameData
			FrameData[k]:=Histo[v]
		Return Histo
	}
	_ConvertFrameToUnpaletted(ByRef FrameObj,ByRef PalObj){
		FrameObjUP:={}, FrameObjUP.SetCapacity(FrameObj.Count())
		For k,v in FrameObj
			{
			FrameObjUP[k,"RR"]:=PalObj[v,"RR"]
			FrameObjUP[k,"GG"]:=PalObj[v,"GG"]
			FrameObjUP[k,"BB"]:=PalObj[v,"BB"]
			FrameObjUP[k,"AA"]:=PalObj[v,"AA"]
			}
		Return FrameObjUP
	}
	_ConvertFrameToPaletted(ByRef FrameObjUP,ByRef PalObj,ByRef Histo){	; Does not quantize.  Quantize 1st and send Quant Palette here...
		FrameObj:={}, FrameObj.SetCapacity(FrameObjUP.Count())
		If !IsObject(Histo)
			Histo:={}, Histo.SetCapacity(PalObj.Count())
		For k,v in FrameObjUP
			{
			R:=v["RR"], G:=v["GG"], B:=v["BB"], A:=v["AA"]
			Key:=this._FormatHash(R,G,B,A)
			If Histo.HasKey(Key)
				FrameObj[k]:=Histo[Key]
			Else
				{
				Dist:=0xFFFFFFFE ;0xFFFFFFFFFFFFFFF0
				Idx:=0
				Loop, % PalObj.Count()
					{
					Indexi:=A_Index-1
					nDist:=(PalObj[Indexi,"RR"]-R)**2+(PalObj[Indexi,"GG"]-G)**2+(PalObj[Indexi,"BB"]-B)**2+(PalObj[Indexi,"AA"]-A)**2
					If (nDist<Dist)
						{
						Dist:=nDist
						Idx:=Indexi
						If (Dist=0)
							Break
						}
					}
				Histo[Key]:=Idx
				FrameObj[k]:=Idx
				}
			}
		Return FrameObj
	}
	_ReplacePaletteColor(ByRef PalObj,FromRR:=0,FromGG:=0,FromBB:=0,FromAA:=0,ToRR:=1,ToGG:=1,ToBB:=1,ToAA:=0){
		For k,v in PalObj
			{
			If (v["RR"]=FromRR) AND (v["GG"]=FromGG) AND (v["BB"]=FromBB) AND (v["AA"]=FromAA)
				v["RR"]:=ToRR, v["GG"]:=ToGG, v["BB"]:=ToBB, v["AA"]:=ToAA
			}
	}
	_AddBAMToQuant(ByRef BAMObj,ByRef Quant){
		For FrameNum,v1 in BAMObj.FrameData
			{
			For k2,PalIdx in v1
				{
				Quant.AddColor(BAMObj.Palette[PalIdx,"RR"], BAMObj.Palette[PalIdx,"GG"], BAMObj.Palette[PalIdx,"BB"], BAMObj.Palette[PalIdx,"AA"])
				}
			}
	}
	_FindFrames(BaseFrame){
		IMT:={}
		SplitPath, BaseFrame, OutFileName, OutDir, OutExtension, OutNameNoExt, OutDrive
		BaseFileName:="", Sequence:=Frame:=0
		this._SplitFrameName(BaseFrame,BaseFileName,Sequence,Frame)
		Loop, %OutDir%\%BaseFileName%_Palette*.*, 0, 0
			{
			IMT["Palette"]:=A_LoopFileLongPath
			Break
			}
		If InStr(OutNameNoExt,"Sequence_") AND !InStr(OutNameNoExt,"Frame_")
			{
			Loop, %OutDir%\%BaseFileName%_Sequence*.%OutExtension%, 0 , 0
				{
				If !InStr(A_LoopFileLongPath,"Frame_")
					{
					FileName:="", Sequence:=Frame:=0
					this._SplitFrameName(A_LoopFileLongPath,FileName,Sequence,Frame)
					IMT[Sequence,Frame]:=A_LoopFileLongPath
					}
				}
			}
		Else If InStr(OutNameNoExt,"Sequence_")
			{
			Loop, %OutDir%\%BaseFileName%_Sequence*.%OutExtension%, 0 , 0
				{
				FileName:="", Sequence:=Frame:=0
				this._SplitFrameName(A_LoopFileLongPath,FileName,Sequence,Frame)
				IMT[Sequence,Frame]:=A_LoopFileLongPath
				}
			}
		Else If InStr(OutNameNoExt,"Frame_")
			{
			Loop, %OutDir%\%BaseFileName%_Frame*.%OutExtension%, 0 , 0
				{
				FileName:="", Sequence:=Frame:=0
				this._SplitFrameName(A_LoopFileLongPath,FileName,Sequence,Frame)
				IMT[Sequence,Frame]:=A_LoopFileLongPath
				}
			}
		Else IF FileExist(OutDir "\" SubStr(OutNameNoExt,1,StrLen(OutNameNoExt)-1) "L." OutExtension) AND FileExist(OutDir "\" SubStr(OutNameNoExt,1,StrLen(OutNameNoExt)-1) "S." OutExtension)
			{
			tmp:=SubStr(OutNameNoExt,1,StrLen(OutNameNoExt)-1)
			Loop, %OutDir%\%tmp%*.%OutExtension%, 0 , 0
				{
				FileName:="", Sequence:=Frame:=0
				this._SplitFrameName(A_LoopFileLongPath,FileName,Sequence,Frame)
				IMT[Sequence,Frame]:=A_LoopFileLongPath
				}
			}
		Else
			{
			Loop, %BaseFrame%, 0 , 0
				{
				IMT[0,0]:=A_LoopFileLongPath
				Break
				}
			}
		;MsgBox % st_printArr(IMT)
		Return IMT
	}
	_SplitFrameName(BaseFrame,ByRef FileName,ByRef Sequence,ByRef Frame){
		SplitPath, BaseFrame, OutFileName, OutDir, OutExtension, OutNameNoExt, OutDrive
		If InStr(OutNameNoExt,"Frame_") AND InStr(BaseFrame,"Sequence_")	; Multiple Sequences specified and is in the form "filename_Sequence#_Frame#"
			{
			tmp:=StrSplit(OutNameNoExt,"Frame_")
			Frame:=tmp[tmp.MaxIndex()]
			Frame+=0
			tmp:=StrSplit(tmp[tmp.MinIndex()],"Sequence_")
			Sequence:=tmp[tmp.MaxIndex()]
			Sequence+=0
			FileName:=tmp[tmp.MinIndex()]
			If SubStr(FileName,0,1)="_"
				StringTrimRight, FileName, FileName, 1
			}
		Else If InStr(OutNameNoExt,"Frame_")	; Is in the form "filename_Frame#" (only 1 sequence)
			{
			tmp:=StrSplit(OutNameNoExt,"Frame_")
			Frame:=tmp[tmp.MaxIndex()]
			Frame+=0
			FileName:=tmp[tmp.MinIndex()]
			Sequence:=0
			If SubStr(FileName,0,1)="_"
				StringTrimRight, FileName, FileName, 1
			}
		Else If InStr(BaseFrame,"Sequence_")	; Is in the form "filename_Sequence#" and should be an animated GIF
			{
			tmp:=StrSplit(OutNameNoExt,"Sequence_")
			Sequence:=tmp[tmp.MaxIndex()]
			Sequence+=0
			FileName:=tmp[tmp.MinIndex()]
			If SubStr(FileName,0,1)="_"
				StringTrimRight, FileName, FileName, 1
			}
		Else If FileExist(OutDir "\" SubStr(OutNameNoExt,1,StrLen(OutNameNoExt)-1) "L." OutExtension) AND FileExist(OutDir "\" SubStr(OutNameNoExt,1,StrLen(OutNameNoExt)-1) "S." OutExtension)	; L and S as in BAM Batcher
			{
			If (SubStr(OutNameNoExt,0,1)="L")
				Sequence:=0, Frame:=0
			Else If (SubStr(OutNameNoExt,0,1)="S")
				Sequence:=1, Frame:=0
			FileName:=OutNameNoExt
			StringTrimRight, FileName, FileName, 1
			}
		Else	; Only one-frame-BAM
			Sequence:=0, Frame:=0, FileName:=OutNameNoExt
	}
	_FormatHash(r:=0,g:=0,b:=0,a:=0){
		Return "#" ((r&0xFF)<<24)|((g&0xFF)<<16)|((b&0xFF)<<8)|(a&0xFF)
	}
}

class CompressBAM extends ProcessBAM{
	CompressBAM(){
		tic:=QPC(1)
		Console.Send("`r`n","-W")
		Console.Send("Beginning compression of BAM file..." "`r`n","-W")
		;~ this._SetPaletteToAlpha()
		;~ this._MovePaletteEntry(100,0)
		;~ this._MovePaletteEntry(200,1)
		;~ this.Palette[0,"RR"]:=0, this.Palette[0,"GG"]:=255, this.Palette[0,"BB"]:=0, this.Palette[0,"AA"]=255
		this._NormalizeFrameDataPixelCount()
		If (Settings.FixPaletteColorErrors>=1)
			this._FixPaletteColorErrors()
		If (Settings.AutodetectPalettedBAM>=1)
			this._AutodetectPalettedBAM()
		If (Settings.TrimFrameData=1)
			{
			BytesRemoved:=this._TrimFrames(), Console.Send("Trimmed " BytesRemoved " Pixels from FrameData." "`r`n","I")
			If (Settings.ExtraTrimDepth>0) AND (Settings.ExtraTrimBuffer>=0)
				BytesRemoved:=this._ExtraTrimFrames(), Console.Send("Trimmed " BytesRemoved " Extra Pixels from FrameData." "`r`n","I")
			}
		If (Settings.ReduceFrameRowLT>0)
			Reduced:=this._ReduceFrameRowCount(Settings.ReduceFrameRowLT), Console.Send("Setting " Reduced " frames to 1x1 Trans pixel because RowCount<=" Settings.ReduceFrameRowLT "`r`n","I")
		If (Settings.ReduceFrameColumnLT>0)
			Reduced:=this._ReduceFrameColumnCount(Settings.ReduceFrameColumnLT), Console.Send("Setting " Reduced " frames to 1x1 Trans pixel because ColumnCount<=" Settings.ReduceFrameColumnLT "`r`n","I")
		If (Settings.ReduceFramePixelLT)
			Reduced:=this._ReduceFramePixelCount(Settings.ReduceFramePixelLT), Console.Send("Setting " Reduced " frames to 1x1 Trans pixel because PixelCount<=" Settings.ReduceFramePixelLT "`r`n","I")
		If (Settings.AlphaCutoff>0)
			this._AlphaCutoff(Settings.AlphaCutoff), Console.Send("Setting pixels with transparency between 1 and " Settings.AlphaCutoff " (inclusive) to TransColor." "`r`n","I")
		If (Settings.ForceTransColor=1)
			this._ForceTransColor(), Console.Send("Transparent color set to Green and Palette Entry 0" "`r`n","I")
		If (Settings.ForceShadowColor>=1)
			(this._ForceShadowColor()=1?Console.Send("Shadow color set to Black and Palette Entry 1." "`r`n","I"):"")
		If (Settings.DropDuplicatePaletteEntries=1)
			NumRemoved:=this._DropDuplicatePaletteEntries(), Console.Send("Dereferenced " NumRemoved " duplicate Palette Entries." "`r`n","I")
		If (Settings.DropUnusedPaletteEntries=1)
			NumRemoved:=this._DropUnusedPaletteEntries(), Console.Send("Removed " NumRemoved " unused Palette Entries." "`r`n","I")
		If (Settings.DropUnusedPaletteEntries=2)
			NumRemoved:=this._DropUnusedPaletteEntriesFromEnd(), Console.Send("Removed " NumRemoved " unused Palette Entries from end of Palette." "`r`n","I")
		If (Settings.DropEmptyCycleEntries=1)
			NumRemoved:=this._DropEmptyCycleEntries(), Console.Send("Removed " NumRemoved " empty Cycle Entries." "`r`n","I")
		If (Settings.DropDuplicateFrameData=1)
			NumRemoved:=this._DropDuplicateFrameData(), Console.Send("Dereferenced " NumRemoved " duplicate Frames." "`r`n","I")
		If (Settings.DropDuplicateFrameEntries=1)
			NumRemoved:=this._DropDuplicateFrameEntries(), Console.Send("Dereferenced " NumRemoved " duplicate Frame Entries." "`r`n","I")
		If (Settings.DropUnusedFrameEntries=1)
			NumRemoved:=this._DropUnreferencedFrameEntries(), Console.Send(NumRemoved " unused Frame Entries were dropped." "`r`n","I")
		If (Settings.DropUnusedFrameData=1)
			NumRemoved:=this._DropUnreferencedFrames(), Console.Send(NumRemoved " unused Frames were dropped." "`r`n","I")
		;;;;; Clean palette again ;;;;;
		If (Settings.DropUnusedPaletteEntries=1)
			NumRemoved:=this._DropUnusedPaletteEntries(), Console.Send("Removed " NumRemoved " unused Palette Entries." "`r`n","I")
		If (Settings.DropUnusedPaletteEntries=2)
			NumRemoved:=this._DropUnusedPaletteEntriesFromEnd(), Console.Send("Removed " NumRemoved " unused Palette Entries from end of Palette." "`r`n","I")
		;;;;; End clean palette again ;;;;;
		;~ If (Settings.ExportFrames) AND (Settings.CompressFirst=1) AND !(Settings.Save="BAMD") ;AND (Settings.IntelligentRLE=1)
			;~ {
			;~ If (Settings.ProcessFirst)
				;~ this.Process()
			;~ this.ExportFrames(Settings.OutPathSpecific) ;, Settings.ExportFrames:=0
			;~ }
		If (Settings.IntelligentRLE=1) AND (Settings.Save<>"BAMD") AND (Settings.Save<>"GIF")
			BytesSaved:=this._RLE(), Console.Send(BytesSaved " bytes were saved by applying Intelligent RLE." "`r`n","I")
		
		If (Settings.AdvancedFLTCompression=1) AND (Settings.Save<>"BAMD") AND (Settings.Save<>"GIF")
			this._AdvancedFLTCompression()
		
		Console.Send("BAM compressed in " (QPC(1)-tic) " sec.`r`n","-I")
	}
	_AutodetectPalettedBAM(){
		; Find last used palette entry
		Entry:=0
		Loop, % this.Stats.CountOfPaletteEntries
			{
			Index:=this.Stats.CountOfPaletteEntries-A_Index
			If (this._isPaletteEntryUsed(Index))
				{
				Entry:=Index
				Break
				}
			}
		IsPaletted:=this._IsPalettePaletted(this.Palette,Entry,Settings.AutodetectPalettedThreshold)		; 14100 will identify vanilla off-paletted palettes as paletted.  500 will identify BW1 palette colors as paletted.
		Console.Send("Paletted BAM" (IsPaletted?"":" not") " detected." "`r`n","I")
		If IsPaletted
			{
			Settings.DropDuplicatePaletteEntries:=0, Settings.DropUnusedPaletteEntries:=0
			Console.Send("The following settings will be used: --DropDuplicatePaletteEntries 0 --DropUnusedPaletteEntries 0`r`n","I")
			}
	}
	_IsPalettePaletted(ByRef Pal,CountOfPaletteEntriesUsed:=256,Threshold:=0){
		RefPalObj:=this._GetRefPal()
		If (CountOfPaletteEntriesUsed>(Count:=Pal.Count())) ;If (CountOfPaletteEntriesUsed>Count:=(Pal.MaxIndex()-Pal.MinIndex()+1))
			CountOfPaletteEntriesUsed:=Count
		Dist:=0
		Loop, % CountOfPaletteEntriesUsed
			{
			Index:=A_Index-1
			Dist+=Sqrt((RefPalObj[Index,"R"]-Pal[Index,"RR"])**2+(RefPalObj[Index,"G"]-Pal[Index,"GG"])**2+(RefPalObj[Index,"B"]-Pal[Index,"BB"])**2+(RefPalObj[Index,"A"]-Pal[Index,"AA"])**2)
			}
		Console.Send("Palette Difference: " Dist " & Threshold: " Threshold "`r`n","I")
		Return (Dist-Threshold<=0?1:0)
	}
	_GetRefPal(){
		TD:="AP8AAAAAAAD/gAAA/4AAAP///wDh4eEA0NDQAL+/vwCdnZ0AjIyMAHx8fABra2sAWlpaAElJSQA4ODgAHh4eAPb//wDR//8Asf//AHH//wAR//8AAPDwAADR0QAAsLAAAJCQAABwcAAAUFAAAEBAAP/2/wD/0f8A/7H/AP9x/wD/Ef8A8ADwANEA0QCwALAAkACQAHAAcABQAFAAQABAAP//9gD//9EA//+xAP//kQD//xEA8PAAANHRAACwsAAAkJAAAHBwAABQUAAAQEAAAP/29gD/0dEA/5GRAP9xcQD/MTEA8AAAANEAAACwAAAAkAAAAHAAAABQAAAAQAAAAPb2/wDR0f8AsbH/AHFx/wAREf8AAADwAAAA0QAAALAAAACQAAAAcAAAAFAAAABAAPb/9gDR/9EAsf+xAHH/cQAR/xEAAPAAAADRAAAAsAAAAJAAAABwAAAAUAAAAEAAAMDn5wCX398AVs7OAEW+vgA9pqYANY2NACx1dQAkXFwA58DnAN6Y3gDNV80AvUa9AKY+pgCNNY0AdC10AFwkXADn58AA3t6oAM3NVwC9vUYApqY+AI2NNQB0dC0AXFwkAOewsADemJgAzWdnAL1GRgCmPj4AjTU1AHQtLQBcJCQAwMDnAJiY3gBXV80ARka9AD4+pgA1NY0ALS10ACQkXADA58AAmN6YAFfNVwBGvUYAPqY+ADWNNQAtdC0AJFwkANfY/wC3uP8Ah4j/AHd48ABoaNEAV1iwAEdIkAA3OHAA1//YALf/yACH/4gAd/B4AGjRaABXsFgAR5BIADdwOADXyMgAt7i4AIeYmAB3eHgAaGhoAFdYWABHSEgANzg4ALHY/wBxuP8AEYj/AAB48AAAaNEAAFiwAABIkAAAOHAAsf/YAHH/uAAR/4gAAPB4AADRaAAAsFgAAJBIAABwOAD/19gA/7fIAP+HiADwd3gA0WhoALBXWACQR0gAcDc4AP+hyAD/cbgA/yCYAPAAeADRAGgAsABYAJAASABwADgA2LH/ALhx/wCIEf8AeADwAGgA0QBYALAASACQADgAcADY19gAuLe4AIiHiAB4d3gAaGhoAFhXWABIR0gAODc4AP/IoQD/uIEA/5ggAPB4AADRaAAAsFgAAJBIAABwOAAA2NjXALi4xwCIiIcAeHh3AGhoaABYWFcASEhHADg4NwDY/7EAuP+BAIj/EQB48AAAaNEAAFiwAABIkAAAOHAAANigxwC4cbcAiCGXAHgAdwBoAGgAWABXAEgARwA4ADcA2MegALi3cQCIlyEAeHcAAGhoAABYVwAASEcAADg3AACx19gAcbe4ABGHiAAAd3gAAGhoAABXWAAAR0gAADc4AA=="
		VarSetCapacity(Out_Data,Bytes:=1024,0)
		ErrorLevel:=DllCall("Crypt32.dll\CryptStringToBinary","Ptr",&TD,"UInt",0,"UInt",1,"Ptr",&Out_Data,"UIntP",Bytes,"Int",0,"Int",0,"CDECL Int")
		If !(ErrorLevel)
			throw Exception("ErrorLevel=" ErrorLevel A_Tab "A_LastError=" A_LastError,,"CryptStringToBinary Error`n`n" Traceback())
		TD:=""
		RefPalBIN:=New MemoryFileIO(Out_Data,Bytes)
		RefPalBIN.Seek(0,0)

		RefPal:={}
		Loop, 256
			{
			Idx:=A_Index-1
			RefPal[Idx,"R"]:=RefPalBIN.ReadUChar()
			RefPal[Idx,"G"]:=RefPalBIN.ReadUChar()
			RefPal[Idx,"B"]:=RefPalBIN.ReadUChar()
			RefPal[Idx,"A"]:=RefPalBIN.ReadUChar()
			}
		Return RefPal
	}
	_isPaletteEntryUsed(Entry){
		Loop, % this.Stats.CountOfFrames
			{
			Index:=A_Index-1
			Loop, % this.FrameData[Index].Count()
				{
				If (this.FrameData[Index,A_Index-1]=Entry) AND (!(this.FrameEntries[Index,"RLE"]) OR (this.FrameData[Index,A_Index-2]<>this.Stats.TransColorIndex))
					Return 1
				}
			}
		Return 0
	}
	_DropUnusedPaletteEntries(){
		; Determine which palette entries are used
		PalUsageLUT:={}, PalUsageLUT.SetCapacity(this.Stats.CountOfPaletteEntries)
		Loop, % this.Stats.CountOfPaletteEntries
			PalUsageLUT[A_Index-1]:=0
		Loop, % this.Stats.CountOfFrames
			{
			Index:=A_Index-1
			Loop, % this.FrameData[Index].Count()
				{
				If !(this.FrameEntries[Index,"RLE"]) OR (this.FrameData[Index,A_Index-2]<>this.Stats.TransColorIndex)
					PalUsageLUT[this.FrameData[Index,A_Index-1]]:=1
				}
			}
		; Drop unused palette entries from Palette
		NumRemoved:=Realign:=0, ReindexArray:={}, ReindexArray.SetCapacity(this.Stats.CountOfPaletteEntries)
		For Index,val in PalUsageLUT
			{
			If !val AND (Index<>this.Stats.TransColorIndex) AND (Index<>this.Stats.ShadowColorIndex)	; don't remove TransColorIndex or ShadowColorIndex!
				{
				Console.Send("Palette Entry " Index " is unused." "`r`n","I")
				this.Palette.RemoveAt(Index-NumRemoved), NumRemoved++
				}
			Else
				ReindexArray[Index]:=Realign++
			}
		; Remap FrameData to point to adjusted Palette Entries
		Loop, % this.Stats.CountOfFrames
			{
			Index:=A_Index-1
			Loop, % this.FrameData[Index].Count()
				{
				Index2:=A_Index-1
				this.FrameData[Index,Index2]:=ReindexArray[this.FrameData[Index,Index2]]
				}
			}
		this.Stats.CountOfPaletteEntries:=this.Palette.Count()
		Return NumRemoved
	}
	_DropUnusedPaletteEntriesFromEnd(){
		; Determine which palette entries are used
		PalUsageLUT:={}, PalUsageLUT.SetCapacity(this.Stats.CountOfPaletteEntries)
		Loop, % this.Stats.CountOfPaletteEntries
			PalUsageLUT[A_Index-1]:=0
		Loop, % this.Stats.CountOfFrames
			{
			Index:=A_Index-1
			Loop, % this.FrameData[Index].Count()
				{
				If !(this.FrameEntries[Index,"RLE"]) OR (this.FrameData[Index,A_Index-2]<>this.Stats.TransColorIndex)
					PalUsageLUT[this.FrameData[Index,A_Index-1]]:=1
				}
			}
		; Drop unused palette entries from end of Palette
		NumRemoved:=0
		While !(PalUsageLUT[Index:=this.Palette.MaxIndex()]) AND (Index<>this.Stats.TransColorIndex) AND (Index<>this.Stats.ShadowColorIndex)	; don't remove TransColorIndex or ShadowColorIndex!
			{
			Console.Send("Palette Entry " Index " is unused." "`r`n","I")
			this.Palette.RemoveAt(Index), NumRemoved++
			}
		this.Stats.CountOfPaletteEntries:=this.Palette.Count()
		Return NumRemoved
	}
	_SetOpaquePalette0(){
		Loop, % this.Stats.CountOfPaletteEntries
			{
			Index:=A_Index-1
			If (this.Palette[Index,"AA"]=255)
				this.Palette[Index,"AA"]:=0
			}
	}
	_DropDuplicatePaletteEntries(){
		; Set palette entries with Alapha=255 to Alpha=0 b/c of how alpha in BAM files are handled
		this._SetOpaquePalette0()
		; Determine which palette entries are duplicates
		NumRemoved:=0, PalUsageLUT:={}, PalUsageLUT.SetCapacity(this.Stats.CountOfPaletteEntries*2)
		For Index,v in this.Palette
			{
			Key:="_" v["RR"] v["GG"] v["BB"] v["AA"]
			If !PalUsageLUT.HasKey(Key) ; Is NOT a duplicate
				{
				PalUsageLUT[Key]:=Index
				PalUsageLUT[Index]:=Index
				}
			Else ; Is a duplicate
				{
				PalUsageLUT[Index]:=PalUsageLUT[Key]
				Console.Send("Palette Entry " Index " is a duplicate of Entry " PalUsageLUT[Key] ".	(" v["RR"] ", " v["GG"] ", " v["BB"] ", " v["A"] ")=(" v["RR"] ", " v["GG"] ", " v["BB"] ", " v["AA"] ")" "`r`n","I")
				NumRemoved++
				}
			}
		; Remove duplicate palette entries
		Loop, % this.Stats.CountOfFrames
			{
			Index:=A_Index-1
			Loop, % this.FrameData[Index].Count()
				{
				Index2:=A_Index-1
				this.FrameData[Index,Index2]:=PalUsageLUT[this.FrameData[Index,Index2]]
				}
			}
		Return NumRemoved
	}
	_FixPaletteColorErrors(){
		this._SetOpaquePalette0()
		;;;;; TransColorIndex ;;;;;
		If (this._IsPaletteEntry(0,0,151,151,0))	; Fix BW1 cyan transparency to green
			this.Stats.TransColorIndex:=this._SetPaletteEntry(0,0,255,0,0), Console.Send("Fixed BW1 cyan transparency to green" "`r`n","I")
		Else If (this._IsPaletteEntry(0,53,46,33,0))	; Fix brown background to green
			this.Stats.TransColorIndex:=this._SetPaletteEntry(0,0,255,0,0), Console.Send("Fixed brown background to green" "`r`n","I")
		;;;;; ShadowColorIndex ;;;;;
		If (this._IsPaletteEntry(1,255,101,151,0))	; Fix BW1 pink shadow to black
			this.Stats.ShadowColorIndex:=this._SetPaletteEntry(1,0,0,0,0), Console.Send("Fixed BW1 pink shadow to black" "`r`n","I")
		Else If (this._IsPaletteEntry(1,8,8,8,0))	; Fix dark grey shadow to black
			this.Stats.ShadowColorIndex:=this._SetPaletteEntry(1,0,0,0,0), Console.Send("Fixed dark grey shadow to black" "`r`n","I")
	}
	_SetPaletteEntry(Entry:=0,Red:=0,Green:=0,Blue:=0,Alpha:=0){
		this.Palette[Entry,"RR"]:=Red, this.Palette[Entry,"GG"]:=Green, this.Palette[Entry,"BB"]:=Blue, this.Palette[Entry,"AA"]:=Alpha
		Return Entry
	}
	_IsPaletteEntry(Entry:=0,Red:=0,Green:=0,Blue:=0,Alpha:=0){
		If (this.Palette[Entry,"RR"]=Red) AND (this.Palette[Entry,"GG"]=Green) AND (this.Palette[Entry,"BB"]=Blue) AND (this.Palette[Entry,"AA"]=Alpha)
			Return 1
		Return 0
		}
	_ForceTransColor(){
		this.Stats.TransColorIndex:=0, isGreen:=0
		Loop, % (Settings.SearchTransColor=1?this.Stats.CountOfPaletteEntries:1)
			{
			Index:=A_Index-1
			If (this._IsPaletteEntry(Index,0,255,0,0)) ; Green
				{
				this.Stats.TransColorIndex:=Index, isGreen:=1, Swap:=(Index<>0?1:0)
				Break
				}
			}
		If !(isGreen)
			{
			this._SetPaletteEntry(this.Stats.TransColorIndex,0,255,0,0) ; Green
			}
		this.Stats.TransColorIndex:=this._MovePaletteEntry(this.Stats.TransColorIndex,0)
	}
	_ForceShadowColor(Method:=1){	; 0=None | 1=Force | 2=Move | 3=Insert
		If (Method=0)
			Return 0
		If (Method=1)
			{
			this.Stats.ShadowColorIndex:=this._SetPaletteEntry(1,0,0,0,0)
			Return 1
			}
		If (this._IsPaletteEntry(1,0,0,0,0)) ; Black
			{
			this.Stats.ShadowColorIndex:=1
			Return 1
			}
		If (Method=2)
			{
			Loop, % this.Stats.CountOfPaletteEntries
				{
				Index:=A_Index-1
				If (Index<=1)
					Continue
				If (this._IsPaletteEntry(Index,0,0,0,0)) ; Black
					{
					this._MovePaletteEntry(Index,1)
					this.Stats.ShadowColorIndex:=1
					Return 1
					}
				}
			}
		If (Method>=2)
			{
			If (this.Stats.CountOfPaletteEntries<256)
				{
				Index:=this.Palette.Count()	;this.Palette.MaxIndex()+1
				this._SetPaletteEntry(Index,0,0,0,0)
				this._MovePaletteEntry(Index,1)
				this.Stats.ShadowColorIndex:=1
				this.Stats.CountOfPaletteEntries:=this.Palette.Count()	;this.Palette.MaxIndex()+1
				Return 1
				}
			Loop, % this.Stats.CountOfPaletteEntries
				{
				Index:=this.Stats.CountOfPaletteEntries-A_Index
				If (Index<=1)
					Continue
				If !(this._isPaletteEntryUsed(Index))
					{
					this._MovePaletteEntry(Index,1)
					this.Stats.ShadowColorIndex:=this._SetPaletteEntry(1,0,0,0,0)
					Return 1
					}
				}
			Return this._ForceShadowColor(1)
			}
		Return 0
	}
	_MovePaletteEntry(Entry,Location:=0){
		If (Location=Entry)
			Return Location
		ReindexArray:={}
		R:=this.Palette[Entry,"RR"], G:=this.Palette[Entry,"GG"], B:=this.Palette[Entry,"BB"], A:=this.Palette[Entry,"AA"]
		this.Palette.InsertAt(Location,{})
		this.Palette[Location,"RR"]:=R, this.Palette[Location,"GG"]:=G, this.Palette[Location,"BB"]:=B, this.Palette[Location,"AA"]:=A
		this.Palette.RemoveAt((Location<Entry?Entry+1:Entry))
		If (Location<Entry)
			{
			Loop, % (this.Stats.CountOfPaletteEntries)
				{
				Index:=A_Index-1
				If Index not between %Location% and %Entry%
					ReindexArray[Index]:=Index
				Else If (Index=Entry)
					ReindexArray[Index]:=Location
				Else
					ReindexArray[Index]:=Index+1
				}
			}
		Else
			{
			Loop, % (this.Stats.CountOfPaletteEntries)
				{
				Index:=A_Index-1
				If Index not between %Entry% and %Location%
					ReindexArray[Index]:=Index
				Else If (Index=Entry)
					ReindexArray[Index]:=Location
				Else
					ReindexArray[Index]:=Index-1
				}
			}
		Loop, % this.Stats.CountOfFrames
			{
			Index:=A_Index-1
			Loop, % this.FrameData[Index].Count() ;MaxIndex()+1
				{
				Index2:=A_Index-1
				this.FrameData[Index,Index2]:=ReindexArray[this.FrameData[Index,Index2]]
				}
			}
		Return Location
	}
	_AlphaCutoff(Val:=0){
		Loop, % (this.Stats.CountOfPaletteEntries)
			{
			Index:=A_Index-1
			If (this.Palette[Index,"AA"]<>0) AND (this.Palette[Index,"AA"]<=Val) ; 1st condition might should be this.Stats.PaletteHasAlpha=1
				{
				this.Palette[Index,"RR"]:=this.Palette[this.Stats.TransColorIndex,"RR"]
				this.Palette[Index,"GG"]:=this.Palette[this.Stats.TransColorIndex,"GG"]
				this.Palette[Index,"BB"]:=this.Palette[this.Stats.TransColorIndex,"BB"]
				this.Palette[Index,"AA"]:=this.Palette[this.Stats.TransColorIndex,"AA"]
				}
			}
	}
	_GetFrameData1stFrameEntry(Num){
		Loop, % this.Stats.CountOfFrameEntries
			{
			Index:=A_Index-1
			If (this.FrameEntries[Index,"FramePointer"]=Num)
				{
				Return Index
				}
			}
		Return ""
	}
	_GetFrameDataFrameEntries(Num){
		Entry:={}
		Loop, % this.Stats.CountOfFrameEntries
			{
			Index:=A_Index-1
			If (this.FrameEntries[Index,"FramePointer"]=Num)
				{
				Entry.Push(Index)
				}
			}
		Return (Entry.Count()>=1?Entry:"")
	}
	_NormalizeFrameDataPixelCount(){
		BytesRemoved:=0
		Loop, % this.Stats.CountOfFrames
			{
			Index:=A_Index-1
			Entry:=this._GetFrameData1stFrameEntry(Index)
			If (this.FrameEntries[Entry,"RLE"]=0)
				{
				BytesFrameData:=this.FrameData[Index].Count() ;(this.FrameData[Index].MaxIndex()=""?0:this.FrameData[Index].MaxIndex())+1
				SizeFrameData:=this.FrameEntries[Entry,"Width"]*this.FrameEntries[Entry,"Height"]
				If (BytesFrameData>SizeFrameData)
					BytesRemoved+=this.FrameData[Index].RemoveAt(SizeFrameData,BytesFrameData-SizeFrameData), Console.Send(BytesRemoved " extra bytes were dropped from Frame " Index "." "`r`n","I")
				Else If (BytesFrameData<SizeFrameData)
					{
					Loop, % (BytesAdded:=SizeFrameData-BytesFrameData)
						this.FrameData[Index].Push(this.Stats.TransColorIndex)
					Console.Send(BytesAdded " bytes had to be added to Frame " Index " in order to reach Width*Height pixels!" "`r`n","E")
					}
				}
			Else
				Console.Send("Frame " Index " can't be searched for extra bytes because it is RLE'd." "`r`n","W")
			}
	}
	_DeleteRow(FrameNum,Row:=0){
		Entry:=this._GetFrameData1stFrameEntry(FrameNum) ; More than 1 FrameEntry could be pointing to this frame...
		Width:=this.FrameEntries[Entry,"Width"], Height:=this.FrameEntries[Entry,"Height"]
		BytesRemoved:=this.FrameData[FrameNum].RemoveAt(Width*Row,Width)
		If (BytesRemoved>0)
			{
			this.FrameEntries[Entry,"Height"]-=1
			If (Row<Height/2)
				this.FrameEntries[Entry,"CenterY"]-=1
			}
		Return BytesRemoved
	}
	_DeleteColumn(FrameNum,Column:=0){
		BytesRemoved:=0
		Entry:=this._GetFrameData1stFrameEntry(FrameNum) ; More than 1 FrameEntry could be pointing to this frame...
		Width:=this.FrameEntries[Entry,"Width"], Height:=this.FrameEntries[Entry,"Height"]
		Loop, % Height
			{
			Index:=A_Index-1
			BytesRemoved+=this.FrameData[FrameNum].RemoveAt(Column+(Width*(Index))-BytesRemoved,1)
			}
		If (BytesRemoved>0)
			{
			this.FrameEntries[Entry,"Width"]-=1
			If (Column<Width/2)
				this.FrameEntries[Entry,"CenterX"]-=1
			}
		Return BytesRemoved
	}
	_IsRowTrans(FrameNum,Row,Width){ ; Trans could also mean Alpha channel
		transCount:=0
		Loop, % Width
			{
			Index:=A_Index-1
			transCount+=(this.FrameData[FrameNum,Width*Row+Index]=this.Stats.TransColorIndex?1:0)
			}
		Return (transCount=Width?1:0)
	}
	_IsColumnTrans(FrameNum,Column,Width,Height){ ; Trans could also mean Alpha channel
		transCount:=0
		Loop, % Height
			{
			Index:=A_Index-1
			transCount+=(this.FrameData[FrameNum,Column+Width*(Index)]=this.Stats.TransColorIndex?1:0)
			}
		Return (transCount=Height?1:0)
	}
	_IsFrameTrans(FrameNum){
		IsTrans:=1
		Entry:=this._GetFrameData1stFrameEntry(FrameNum) ; More than 1 FrameEntry could be pointing to this frame...
		Loop, % this.FrameEntries[Entry,"Height"]	; For each row
			{
			If !(this._IsRowTrans(FrameNum,A_Index-1,this.FrameEntries[Entry,"Width"]))
				{
				IsTrans:=0
				Break
				}
			}
		Return IsTrans
	}
	_TrimFrames(){
		tic:=QPC(1)
		BytesRemoved:=0, Done:=0
		Loop, % this.Stats.CountOfFrames
			{
			Index:=A_Index-1
			Entry:=this._GetFrameData1stFrameEntry(Index) ; More than 1 FrameEntry could be pointing to this frame...
			Loop, % this.FrameEntries[Entry,"Height"]	; Top & Bottom
				{
				If (this._IsRowTrans(Index,0,this.FrameEntries[Entry,"Width"]))
					BytesRemoved+=this._DeleteRow(Index,0), Done++
				If (this._IsRowTrans(Index,this.FrameEntries[Entry,"Height"]-1,this.FrameEntries[Entry,"Width"]))
					BytesRemoved+=this._DeleteRow(Index,this.FrameEntries[Entry,"Height"]-1), Done++
				If (Done=0)
					Break
				Done:=0
				}
			Loop, % this.FrameEntries[Entry,"Width"]	; Left & Right
				{
				If (this._IsColumnTrans(Index,0,this.FrameEntries[Entry,"Width"],this.FrameEntries[Entry,"Height"]))
					BytesRemoved+=this._DeleteColumn(Index,0), Done++
				If (this._IsColumnTrans(Index,this.FrameEntries[Entry,"Width"]-1,this.FrameEntries[Entry,"Width"],this.FrameEntries[Entry,"Height"]))
					BytesRemoved+=this._DeleteColumn(Index,this.FrameEntries[Entry,"Width"]-1), Done++
				If (Done=0)
					Break
				Done:=0
				}
			If (this.FrameEntries[Entry,"Width"]<1) OR (this.FrameEntries[Entry,"Height"]<1)
				{
				this.FrameEntries[Entry,"Width"]:=1, this.FrameEntries[Entry,"Height"]:=1
				this.FrameEntries[Entry,"CenterX"]:=0, this.FrameEntries[Entry,"CenterY"]:=0
				this.FrameData[Index]:="", this.FrameData[Index]:={}, this.FrameData[Index,0]:=this.Stats.TransColorIndex
				}
			}
		Console.Send("Trimmed Frames in " (QPC(1)-tic) " sec.`r`n","-I")
		Return BytesRemoved
	}
	_ExtraTrimFrames(){
		tic:=QPC(1)
		BytesRemoved:=0, Done:=0
		Loop, % this.Stats.CountOfFrames
			{
			Index:=A_Index-1
			Entry:=this._GetFrameData1stFrameEntry(Index) ; More than 1 FrameEntry could be pointing to this frame...
			Loop, % this.FrameEntries[Entry,"Height"]	; Top & Bottom
				{
				If (this._IsRowTrans(Index,0,this.FrameEntries[Entry,"Width"]))
					BytesRemoved+=this._DeleteRow(Index,0), Done++
				Else
					Done:=BytesRemoved+=this._ExtraTrimRow(Index,Entry,0)
				If (this._IsRowTrans(Index,this.FrameEntries[Entry,"Height"]-1,this.FrameEntries[Entry,"Width"]))
					BytesRemoved+=this._DeleteRow(Index,this.FrameEntries[Entry,"Height"]-1), Done++
				Else
					Done:=BytesRemoved+=this._ExtraTrimRow(Index,Entry,this.FrameEntries[Entry,"Height"]-1)
				If (Done=0)
					Break
				Done:=0
				}
			Loop, % this.FrameEntries[Entry,"Width"]	; Left & Right
				{
				If (this._IsColumnTrans(Index,0,this.FrameEntries[Entry,"Width"],this.FrameEntries[Entry,"Height"]))
					BytesRemoved+=this._DeleteColumn(Index,0), Done++
				Else
					Done:=BytesRemoved+=this._ExtraTrimColumn(Index,Entry,0)
				If (this._IsColumnTrans(Index,this.FrameEntries[Entry,"Width"]-1,this.FrameEntries[Entry,"Width"],this.FrameEntries[Entry,"Height"]))
					BytesRemoved+=this._DeleteColumn(Index,this.FrameEntries[Entry,"Width"]-1), Done++
				Else
					Done:=BytesRemoved+=this._ExtraTrimColumn(Index,Entry,this.FrameEntries[Entry,"Width"]-1)
				If (Done=0)
					Break
				Done:=0
				}
			If (this.FrameEntries[Entry,"Width"]<1) OR (this.FrameEntries[Entry,"Height"]<1)
				this._SetFrame1Trans(Index,Entry), BytesRemoved--
			}
		Console.Send("Trimmed Frames (Extra) in " (QPC(1)-tic) " sec.`r`n","-I")
		Return BytesRemoved
	}
	_ExtraTrimRow(FrameNum,Entry,Row:=0){
		BytesRemoved:=0, Depth:=0, Buffer:=0
		Width:=this.FrameEntries[Entry,"Width"]
		If (this._IsRowTrans(FrameNum,Row,Width))
			Return this._DeleteRow(FrameNum,Row)
		Else
			{
			Loop, % (Settings.ExtraTrimDepth>this.FrameEntries[Entry,"Height"]?this.FrameEntries[Entry,"Height"]:Settings.ExtraTrimDepth)
				{
				If !(this._IsRowTrans(FrameNum,(Row<this.FrameEntries[Entry,"Height"]/2?Row+A_Index-1:Row-A_Index+1),Width))
					Depth++
				Else
					Break
				}
			Loop, % (Settings.ExtraTrimBuffer>this.FrameEntries[Entry,"Height"]?this.FrameEntries[Entry,"Height"]:Settings.ExtraTrimBuffer)
				{
				If (this._IsRowTrans(FrameNum,(Row<this.FrameEntries[Entry,"Height"]/2?Row+Depth+A_Index-1:Row-Depth-A_Index+1),Width))
					Buffer++
				Else
					Break
				}
			If (Depth<=Settings.ExtraTrimDepth) AND (Buffer>=Settings.ExtraTrimBuffer)
				Loop, % Depth+Buffer
					BytesRemoved+=this._DeleteRow(FrameNum,(Row<this.FrameEntries[Entry,"Height"]/2?Row:Row-Depth-Buffer+1))
			}
		Return BytesRemoved
	}
	_ExtraTrimColumn(FrameNum,Entry,Column:=0){
		BytesRemoved:=0, Depth:=0, Buffer:=0
		Height:=this.FrameEntries[Entry,"Height"]
		If (this._IsColumnTrans(FrameNum,Column,this.FrameEntries[Entry,"Width"],Height))
			Return this._DeleteColumn(FrameNum,Column)
		Else
			{
			Loop, % (Settings.ExtraTrimDepth>this.FrameEntries[Entry,"Width"]?this.FrameEntries[Entry,"Width"]:Settings.ExtraTrimDepth)
				{
				If !(this._IsColumnTrans(FrameNum,(Column<this.FrameEntries[Entry,"Width"]/2?Column+A_Index-1:Column-A_Index+1),this.FrameEntries[Entry,"Width"],Height))
					Depth++
				Else
					Break
				}
			Loop, % (Settings.ExtraTrimBuffer>this.FrameEntries[Entry,"Width"]?this.FrameEntries[Entry,"Width"]:Settings.ExtraTrimBuffer)
				{
				If (this._IsColumnTrans(FrameNum,(Column<this.FrameEntries[Entry,"Width"]/2?Column+Depth+A_Index-1:Column-Depth-A_Index+1),this.FrameEntries[Entry,"Width"],Height))
					Buffer++
				Else
					Break
				}
			If (Depth<=Settings.ExtraTrimDepth) AND (Buffer>=Settings.ExtraTrimBuffer)
				Loop, % Depth+Buffer
					BytesRemoved+=this._DeleteColumn(FrameNum,(Column<this.FrameEntries[Entry,"Width"]/2?Column:Column-Depth-Buffer+1))
			}
		Return BytesRemoved
	}
	_SetFrame1Trans(Frame,Entry){
		this.FrameEntries[Entry,"Width"]:=1, this.FrameEntries[Entry,"Height"]:=1
		this.FrameEntries[Entry,"CenterX"]:=0, this.FrameEntries[Entry,"CenterY"]:=0
		this.FrameData[Frame]:="", this.FrameData[Frame]:={}, this.FrameData[Frame,0]:=this.Stats.TransColorIndex
	}
	_ReduceFramePixelCount(Count){
		Reduced:=0
		Loop, % this.Stats.CountOfFrames
			{
			Index:=A_Index-1
			Entry:=this._GetFrameData1stFrameEntry(Index)
			If (this.FrameEntries[Entry,"Width"]*this.FrameEntries[Entry,"Height"]<=Count)
				this._SetFrame1Trans(Index,Entry), Reduced++
			}
		Return Reduced
	}
	_ReduceFrameRowCount(Count){
		Reduced:=0
		Loop, % this.Stats.CountOfFrames
			{
			Index:=A_Index-1
			Entry:=this._GetFrameData1stFrameEntry(Index)
			If (this.FrameEntries[Entry,"Height"]<=Count)
				this._SetFrame1Trans(Index,Entry), Reduced++
			}
		Return Reduced
	}
	_ReduceFrameColumnCount(Count){
		Reduced:=0
		Loop, % this.Stats.CountOfFrames
			{
			Index:=A_Index-1
			Entry:=this._GetFrameData1stFrameEntry(Index)
			If (this.FrameEntries[Entry,"Width"]<=Count)
				this._SetFrame1Trans(Index,Entry), Reduced++
			}
		Return Reduced
	}
	;~ _SetPaletteToAlpha(){
		;~ Loop, % (this.Stats.CountOfPaletteEntries)
			;~ {
			;~ this.Palette[A_Index-1,"RR"]:=0
			;~ this.Palette[A_Index-1,"GG"]:=0
			;~ this.Palette[A_Index-1,"BB"]:=0
			;~ this.Palette[A_Index-1,"AA"]:=0
			;~ }
		;~ this.Palette[25,"AA"]:=254
	;~ }
	_CalcFrameDataDuplicate(Entry:=0){
		Loop, % Entry
			{
			Index:=A_Index-1
			ByteCount:=this.FrameData[Index].Count() ;MaxIndex()+1
			If (ByteCount<>this.FrameData[Entry].Count()) ;(ByteCount<>this.FrameData[Entry].MaxIndex()+1)
				Continue
			Loop, % ByteCount
				{
				Index2:=A_Index-1
				Different:=(this.FrameData[Entry,Index2]<>this.FrameData[Index,Index2]?1:0)
				If (Different<>0)
					Break
				}
			If (Different=0)
				{
				Console.Send("Frame " Entry " is a duplicate of Frame " Index "." "`r`n","I")
				Return Index
				}
			}
		Return Entry	; If not a duplicate, return itself.
	}
	_DropDuplicateFrameData(){
		ReindexArray:={}, NumRemoved:=0
		Loop, % this.Stats.CountOfFrames
			{
			Index:=A_Index-1
			Dupe:=this._CalcFrameDataDuplicate(Index)
			ReindexArray[Index]:=Dupe
			If (Dupe<>Index)
				NumRemoved++
			}
		Loop, % this.Stats.CountOfFrameEntries
			{
			Index:=A_Index-1
			this.FrameEntries[Index,"FramePointer"]:=ReindexArray[this.FrameEntries[Index,"FramePointer"]]
			}
		Return NumRemoved
	}
	_DropUnreferencedFrames(){
		FramesDropped:=0, Realign:=0, ReindexArray:={}
		Loop, % this.Stats.CountOfFrames
			{
			Index:=A_Index-1
			Entry:=this._GetFrameData1stFrameEntry(Index) ; If Entry="", delete entire FrameData
			If (Settings.DropUnusedFrameEntries=1) AND (Entry<>"") AND (this._CalcFrameEntryUsed(Entry)=0)	; Edit 20170509
				Entry:=""	; Edit 20170509
			If (Entry="")
				FramesDropped+=this.FrameData.RemoveAt(Index-FramesDropped,1), Console.Send("Frame " Index " is unused." "`r`n","I")
			Else
				ReindexArray[Index]:=Realign++
			}
		Loop, % this.Stats.CountOfFrameEntries
			{
			Index:=A_Index-1
			this.FrameEntries[Index,"FramePointer"]:=ReindexArray[this.FrameEntries[Index,"FramePointer"]]
			}
		this.Stats.CountOfFrames:=this.FrameData.Count() ;MaxIndex()+1
		Return FramesDropped
		}
	_RLESize(ByRef Frame,RLEColorIndex:=""){ ;;; Calculates the size of RLE'd data, even if it >= size of unRLE'd data ;;;
		RLEColorIndex:=(RLEColorIndex=""?this.Stats.RLEColorIndex:RLEColorIndex)
		Size:=compressedCharCount:=0, MaxRLERun:=Settings.MaxRLERun
		For Index,val in Frame
			{
			If (val=RLEColorIndex)
				{
				compressedCharCount++
				If (compressedCharCount>MaxRLERun)
					compressedCharCount:=0, Size+=2
				}
			Else
				{
				If compressedCharCount
					compressedCharCount:=0, Size+=2
				Size++
				}
			}
		If compressedCharCount
			Size+=2
		Return Size
	}
	_FindBestRLEColorIndex(){ ;;; Find the RLE Color index that achieves the best compression ;;;
		Console.Send("Searching for best possible RLEColorIndex.  This could take some time...`r`n","-W")
		; Determine which palette entries are used
		PalUsageLUT:={}, PalUsageLUT.SetCapacity(this.Stats.CountOfPaletteEntries)
		Loop, % this.Stats.CountOfPaletteEntries
			PalUsageLUT[A_Index-1]:=0
		Loop, % this.Stats.CountOfFrames
			{
			Index:=A_Index-1
			Loop, % this.FrameData[Index].Count()
				{
				If !(this.FrameEntries[Index,"RLE"]) OR (this.FrameData[Index,A_Index-2]<>this.Stats.TransColorIndex)
					PalUsageLUT[this.FrameData[Index,A_Index-1]]:=1
				}
			}
		; Find the best RLE color index
		BestRLEColorIndex:=this.Stats.RLEColorIndex, BestTry:=4294967294 ; 4 gigs 
		Loop, % this.Stats.CountOfPaletteEntries
			{
			SizeOfTry:=0, CurrentColorIndex:=A_Index-1
			If !PalUsageLUT[CurrentColorIndex] ; If palette entry is not used
				Continue
			Loop, % this.Stats.CountOfFrames
				{
				Frame:=A_Index-1
				unRLE:=this.FrameData[Frame].Count()
				RLE:=this._RLESize(this.FrameData[Frame],CurrentColorIndex)
				SizeOfTry+=(RLE<unRLE?RLE:unRLE)
				}
			If (SizeOfTry<BestTry)
				BestTry:=SizeOfTry, BestRLEColorIndex:=CurrentColorIndex
			}
		Console.Send("BestRLEColorIndex=" BestRLEColorIndex "`r`n","I")
		Return BestRLEColorIndex
	}
	_RLEFrame(Frame,RLEColorIndex:="",MaxRLERun:=""){
		RLEColorIndex:=(RLEColorIndex=""?this.Stats.RLEColorIndex:RLEColorIndex)
		MaxRLERun:=(MaxRLERun=""?Settings.MaxRLERun:MaxRLERun)
		; RLE frame using MaxRLERun
		RLEData:={}, RLEData.SetCapacity(this.FrameData[Frame].Count()), NewBytes:=compressedCharCount:=0
		For Index,val in this.FrameData[Frame]
			{
			If (val=RLEColorIndex)
				{
				compressedCharCount++
				If (compressedCharCount>MaxRLERun)
					{
					RLEData[NewBytes]:=RLEColorIndex, NewBytes++
					RLEData[NewBytes]:=MaxRLERun, NewBytes++
					compressedCharCount:=0
					}
				}
			Else
				{
				If compressedCharCount
					{
					RLEData[NewBytes]:=RLEColorIndex, NewBytes++
					RLEData[NewBytes]:=compressedCharCount-1, NewBytes++
					compressedCharCount:=0
					}
				RLEData[NewBytes]:=val, NewBytes++
				}
			}
		If compressedCharCount
			{
			RLEData[NewBytes]:=RLEColorIndex, NewBytes++
			RLEData[NewBytes]:=compressedCharCount-1, NewBytes++
			}
		; RLE frame using MaxRLERun-1 if MaxRLERun=255 to see if 255 was any better
		If (MaxRLERun=255)
			{
			RLEData2:={}, RLEData.SetCapacity(this.FrameData[Frame].Count()), NewBytes:=compressedCharCount:=0
			For Index,val in this.FrameData[Frame]
				{
				If (val=RLEColorIndex)
					{
					compressedCharCount++
					If (compressedCharCount>MaxRLERun-1)
						{
						RLEData2[NewBytes]:=RLEColorIndex, NewBytes++
						RLEData2[NewBytes]:=MaxRLERun-1, NewBytes++
						compressedCharCount:=0
						}
					}
				Else
					{
					If compressedCharCount
						{
						RLEData2[NewBytes]:=RLEColorIndex, NewBytes++
						RLEData2[NewBytes]:=compressedCharCount-1, NewBytes++
						compressedCharCount:=0
						}
					RLEData2[NewBytes]:=val, NewBytes++
					}
				}
			If compressedCharCount
				{
				RLEData2[NewBytes]:=RLEColorIndex, NewBytes++
				RLEData2[NewBytes]:=compressedCharCount-1, NewBytes++
				}
			If (RLEData2.Count()<=RLEData.Count()) ; MaxRLERun of 254 was at least as good as 255, so use it to be safer
				RLEData:=RLEData2
			Else
				Console.Send("Frame " Frame " uses RLE runs >254.  This may cause issues for BAMWorkshop." "`r`n","W")
			}
		If (RLEData.Count()<this.FrameData[Frame].Count()) ; RLE improved compression
			this.FrameData[Frame]:=RLEData
		Return RLEData.Count()
	}
	_RLE(){
		tic:=QPC(1)
		BytesSaved:=0
		If (Settings.FindBestRLEIndex=1)
			this.Stats.RLEColorIndex:=this._FindBestRLEColorIndex()
		Loop, % this.Stats.CountOfFrames
			{
			Frame:=A_Index-1
			unRLE:=this.FrameData[Frame].Count()
			RLE:=this._RLEFrame(Frame,this.Stats.RLEColorIndex,Settings.MaxRLERun)
			If (RLE<unRLE)
				{
				For key, val in (this._GetFrameDataFrameEntries(Frame))
					this.FrameEntries[val,"RLE"]:=1
				BytesSaved+=unRLE-RLE
				}
			}
		Console.Send("Frame Data RLEd in " (QPC(1)-tic) " sec.`r`n","-I")
		Return BytesSaved
	}
	_CalcFrameEntryDuplicate(Entry:=0){
		Width:=this.FrameEntries[Entry,"Width"], Height:=this.FrameEntries[Entry,"Height"]
		CenterX:=this.FrameEntries[Entry,"CenterX"], CenterY:=this.FrameEntries[Entry,"CenterY"]
		FramePointer:=this.FrameEntries[Entry,"FramePointer"]
		Loop, % Entry
			{
			Index:=A_Index-1
			If (Width=this.FrameEntries[Index,"Width"]) AND (Height=this.FrameEntries[Index,"Height"]) AND (CenterX=this.FrameEntries[Index,"CenterX"]) AND (CenterY=this.FrameEntries[Index,"CenterY"]) AND (FramePointer=this.FrameEntries[Index,"FramePointer"])
				{
				Console.Send("Frame Entry " Entry " is a duplicate of Frame Entry " Index "." "`r`n","I")
				Return Index
				}
			}
		Return Entry	; If not a duplicate, return itself.
	}
	_DropDuplicateFrameEntries(){
		ReindexArray:={}, NumRemoved:=0
		Loop, % this.Stats.CountOfFrameEntries
			{
			Index:=A_Index-1
			Dupe:=this._CalcFrameEntryDuplicate(Index)
			ReindexArray[Index]:=Dupe
			If (Dupe<>Index)
				NumRemoved++
			}
		Loop, % this.Stats.CountOfFLTEntries
			{
			Index:=A_Index-1
			this.FrameLookupTable[Index]:=ReindexArray[this.FrameLookupTable[Index]]
			}
		Return NumRemoved
	}
	_CalcFrameEntryUsed(Entry:=0){
		Loop, % this.Stats.CountOfCycles
			{
			Index:=A_Index-1
			Loop, % this.CycleEntries[Index,"CountOfFrameIndices"]
				{
				Index2:=A_Index-1
				If (this.FrameLookupTable[this.CycleEntries[Index,"IndexIntoFLT"]+Index2]=Entry)
					Return 1
				}
			}
		Return 0
	}
	_DropUnreferencedFrameEntries(){
		EntriesDropped:=0, Realign:=0, ReindexArray:={}
		Loop, % this.Stats.CountOfFrameEntries
			{
			Index:=A_Index-1
			If (this._CalcFrameEntryUsed(Index)=0)
				EntriesDropped+=this.FrameEntries.RemoveAt(Index-EntriesDropped,1), Console.Send("Frame Entry " Index " is unused." "`r`n","I")
			Else
				ReindexArray[Index]:=Realign++
			}
		Loop, % this.Stats.CountOfFLTEntries
			{
			Index:=A_Index-1
			this.FrameLookupTable[Index]:=ReindexArray[this.FrameLookupTable[Index]]
			}
		this.Stats.CountOfFrameEntries:=this.FrameEntries.Count() ;MaxIndex()+1
		Return EntriesDropped
		}
	_DropEmptyCycleEntries(){
		DropList:={}
		Loop, % this.Stats.CountOfCycles
			{
			Index:=A_Index-1
			If !(this.CycleEntries[Index,"CountOfFrameIndices"])	; Cycle has no FrameIndices
				DropList.InsertAt(1,Index)
			}
		For k,v in DropList
			this.CycleEntries.RemoveAt(v,1)
		this.Stats.CountOfCycles-=(NumRemoved:=DropList.Count())
		Return NumRemoved
	}
	_UpdateCycleEntries(ByRef Array){
		Loop, % this.Stats.CountOfCycles
			{
			Index:=A_Index-1
			If this.CycleEntries[Index,"CountOfFrameIndices"]	; Edit 20170518 - Better handle Cycle Entries with no Frames
				{
				Idx:=ArrayContainsArray(Array,Sub:=GetSubArray(this.FrameLookupTable,this.CycleEntries[Index,"IndexIntoFLT"],this.CycleEntries[Index,"CountOfFrameIndices"],1))-1
				If (Idx="")
					throw Exception("Sequence not found in FLT.",,"CycleEntry=" Index " | Sequence=" Sub "`n`n" Traceback())
				this.CycleEntries[Index,"IndexIntoFLT"]:=Idx
				}
			Else
				this.CycleEntries[Index,"IndexIntoFLT"]:=0
			}
		Array.RemoveAt(0,1)
		this.FrameLookupTable:=Array, this.Stats.CountOfFLTEntries:=Array.Count()
	}
	_GenerateFLTCandidates(ByRef Array1){
		PermIndex:={}, Final:={}, FL:=0
		Loop, % Array1.Count()
			PermIndex[A_Index]:=A_Index
		Loop
			{
			Output:="", Output:={}
			For k, v in PermIndex
				Output:=CombineArrays(Output,Array1[v])
			If (Output.Length()<FL) OR !FL
				Final:=Output, FL:=Final.Length()
			PermIndex:=perm_NextObj(PermIndex)
			If !PermIndex OR (A_Index>Settings.FLTSanityCutoff)
				Break
			}
		Return Final
	}
	_AdvancedFLTCompression(){
		FLT:={}, Indexi:=1, OrigFLTLen:=this.FrameLookupTable.Count()
		Loop, % this.Stats.CountOfCycles	; Build FLT Array of Arrays that we will use to compute shortest possible FLT.
			{
			Index:=A_Index-1
			If (cCE:=this.CycleEntries[Index,"CountOfFrameIndices"])	; Edit 20170518 - Skip Cycle Entries with zero frame indices
				{
				FLT[Indexi]:=GetSubArray(this.FrameLookupTable,this.CycleEntries[Index,"IndexIntoFLT"],cCE,1)	; FLT[Index] must account for skipped Cycles
				FLT[Indexi,"Avg"]:=GetArrAvg(FLT[Indexi])
				Indexi++
				}
			}
		ArrayDropDuplicates(FLT)	; Drop arrays contained within other arrays.
		NoOverlap:={}, Offset:=1
		Loop, % FLT.Length()	; Sort out arrays that have no overlap with other arrays.
			{
			Overlap:=0
			Loop, % FLT.Length()
				If (A_Index<>Offset) AND (Overlap+=ArrayHasCommonValue(FLT[A_Index],FLT[Offset]))
					Break
			If !Overlap
				{
				NoOverlap.Push(FLT[Offset]*)
				FLT.RemoveAt(Offset,1)
				}
			Else
				Offset++
			}
		If !(FLT.Length())
			this._UpdateCycleEntries(NoOverlap)
		Else	; Start trying all possible combinations of remaining runs in FLT
			{
			tic:=QPC(1), Console.Send("Searching all " FLT.Length() "! possible permutations (up to " Settings.FLTSanityCutoff " iterations) of pre-filtered FLT arrays.  This could take a while...`r`n","-W")
			q_sort(FLT,"Avg")
			FLT:=this._GenerateFLTCandidates(FLT)
			If (NoOverlap.Length())
				{
				If (NoOverlap[NoOverlap.MaxIndex()]<FLT[1])
					FLT.InsertAt(1,NoOverlap*)
				Else
					FLT.Push(NoOverlap*)
				}
			this._UpdateCycleEntries(FLT)
			}
		Console.Send("Advanced FLT Compression saved " OrigFLTLen-this.FrameLookupTable.Count() " bytes.`r`n","I")
		;~ Console.Send("CycleEntries=`r`n" st_printArr(this.CycleEntries) "`r`n")
		;~ Console.Send("FrameLookupTable=`r`n" st_printArr(this.FrameLookupTable) "`r`n")
		;~ this.__PrintCycleFLTHoriz(this.FrameLookupTable)
	}
	__PrintCycleFLTHoriz(ByRef Array){
		Lines:="FrameLookupTable Length = " Array.Count() "`r`n"
		Loop, % this.Stats.CountOfCycles
			{
			Index:=A_Index-1
			Sub:=GetSubArray(Array,this.CycleEntries[Index,"IndexIntoFLT"],this.CycleEntries[Index,"CountOfFrameIndices"],1)
			Lines.="[" Index "]=" A_Space
			For k,v in Sub
				Lines.=v A_Space
			Lines.="`r`n"
			}
		Console.Send(Lines "`r`n")
	}
}

class ProcessBAM extends DebugBAM{
	Process(Input){
		tic:=QPC(1)
		Console.Send("`r`n","-W")
		Console.Send("Beginning additional processing of BAM file..." "`r`n","-W")
		If (Settings.ItemIcon2EE)
			this._ItemIcon2EE()
		If (Settings.BAMProfile)
			this._SetBAMProfile(Settings.BAMProfile)
		If (Settings.Unify>0)
			this._Unify()
		If (Settings.Fill<>"")
			this._Fill()
		If (Settings.Montage<>"")
			this._Montage(Input)
		If Settings.ModXOffset
			this._ModXOffset()
		If Settings.ModYOffset
			this._ModYOffset()
		If (Settings.SetXOffset<>"")
			this._SetXOffset()
		If (Settings.SetYOffset<>"")
			this._SetYOffset()
		If (Settings.Flip)
			this._Flip()
		If (Settings.Flop)
			this._Flop()
		If (Settings.Rotate)
			this._Rotate()
		Console.Send("Additional processing completed in " (QPC(1)-tic) " sec.`r`n","-I")
	}
	_ItemIcon2EE(){
		Idx0:=this.CycleEntries[0,"IndexIntoFLT"]
		Cnt0:=this.CycleEntries[0,"CountOfFrameIndices"]
		Entry0:=this.FrameLookupTable[Idx0]
		Idx1:=this.CycleEntries[1,"IndexIntoFLT"]
		Cnt1:=this.CycleEntries[1,"CountOfFrameIndices"]
		Entry1:=this.FrameLookupTable[Idx1]
		If (this.Stats.CountOfCycles=2) AND (Cnt0<2) AND (Cnt1>=1)	; Looks like an Item Icon that has not already been transformed into EE format
			{
			this.CycleEntries[0,"IndexIntoFLT"]:=0
			this.CycleEntries[0,"CountOfFrameIndices"]:=2
			this.CycleEntries[1,"IndexIntoFLT"]:=1
			this.FrameLookupTable[0]:=Entry0
			this.FrameLookupTable[1]:=Entry1
			this._SetBAMProfile("ItemIcon")
			Console.Send("Set Item Icon BAM to EE format.`r`n","I")
			}
		Else
			Console.Send("BAM does not look like a non-EE Item Icon.  No changes made.`r`n","W")
	}
	_SetBAMProfile(Profile){
		Console.Send("Setting BAM Profile to " Profile ".`r`n","I")
		If (Profile="ItemIcon")
			{
			Idx:=this.CycleEntries[0,"IndexIntoFLT"]
			Cnt:=this.CycleEntries[0,"CountOfFrameIndices"]
			Entry:=this.FrameLookupTable[Idx]
			If (Entry<>"")
				{
				this.FrameEntries[Entry,"CenterX"]:=this.FrameEntries[Entry,"Width"]//2
				this.FrameEntries[Entry,"CenterY"]:=this.FrameEntries[Entry,"Height"]//2
				}
			Entry:=this.FrameLookupTable[Idx+1]
			If (Cnt>1) AND (Entry<>"")
				{
				this.FrameEntries[Entry,"CenterX"]:=(this.FrameEntries[Entry,"Width"]-32)//2
				this.FrameEntries[Entry,"CenterY"]:=(this.FrameEntries[Entry,"Height"]-32)//2
				}
			Entry:=this.FrameLookupTable[this.CycleEntries[1,"IndexIntoFLT"]]
			If (Entry<>"")
				{
				this.FrameEntries[Entry,"CenterX"]:=(this.FrameEntries[Entry,"Width"]-32)//2
				this.FrameEntries[Entry,"CenterY"]:=(this.FrameEntries[Entry,"Height"]-32)//2
				}
			}
		Else If (Profile="DescriptionIcon")
			{
			Idx:=this.CycleEntries[0,"IndexIntoFLT"]
			Cnt:=this.CycleEntries[0,"CountOfFrameIndices"]
			If (Cnt>1)
				{
				If ((Entry:=this.FrameLookupTable[Idx])<>"")
					this.FrameEntries[Entry,"CenterX"]:=this.FrameEntries[Entry,"Width"], this.FrameEntries[Entry,"CenterY"]:=this.FrameEntries[Entry,"Height"]
				If ((Entry:=this.FrameLookupTable[Idx+1])<>"")
					this.FrameEntries[Entry,"CenterX"]:=0, this.FrameEntries[Entry,"CenterY"]:=this.FrameEntries[Entry,"Height"]
				If ((Entry:=this.FrameLookupTable[Idx+2])<>"")
					this.FrameEntries[Entry,"CenterX"]:=this.FrameEntries[Entry,"Width"], this.FrameEntries[Entry,"CenterY"]:=0
				If ((Entry:=this.FrameLookupTable[Idx+3])<>"")
					this.FrameEntries[Entry,"CenterX"]:=0, this.FrameEntries[Entry,"CenterY"]:=0
				}
			Else
				{
				Entry:=this.FrameLookupTable[Idx]
				If (Entry<>"")
					{
					this.FrameEntries[Entry,"CenterX"]:=this.FrameEntries[Entry,"Width"]//2
					this.FrameEntries[Entry,"CenterY"]:=this.FrameEntries[Entry,"Height"]//2
					}
				}
			}
		Else If (Profile="Zero") OR (Profile="Paperdoll") OR (Profile="SpellIconEE")
			{
			Loop, % this.Stats.CountOfFrameEntries
				{
				Entry:=A_Index-1
				this.FrameEntries[Entry,"CenterX"]:=0
				this.FrameEntries[Entry,"CenterY"]:=0
				}
			}
		Else If (Profile="GroundIcon") OR (Profile="DescriptionIconEE") OR (Profile="ItemIconPST")
			{
			Loop, % this.Stats.CountOfFrameEntries
				{
				Entry:=A_Index-1
				this.FrameEntries[Entry,"CenterX"]:=this.FrameEntries[Entry,"Width"]//2
				this.FrameEntries[Entry,"CenterY"]:=this.FrameEntries[Entry,"Height"]//2
				}
			}
		Else If (Profile="GroundIconPST")
			{
			Loop, % this.Stats.CountOfFrameEntries
				{
				Entry:=A_Index-1
				this.FrameEntries[Entry,"CenterX"]:=this.FrameEntries[Entry,"Width"]//2
				this.FrameEntries[Entry,"CenterY"]:=this.FrameEntries[Entry,"Height"]//2
				}
			Entry:=this.FrameLookupTable[this.CycleEntries[1,"IndexIntoFLT"]]
			If (Entry<>"")
				{
				this.FrameEntries[Entry,"CenterX"]:=0
				this.FrameEntries[Entry,"CenterY"]:=0
				}
			}
		Else If (Profile="SpellIcon")
			{
			Loop, % this.Stats.CountOfFrameEntries
				{
				Entry:=A_Index-1
				this.FrameEntries[Entry,"CenterX"]:=(this.FrameEntries[Entry,"Width"]-32)//2
				this.FrameEntries[Entry,"CenterY"]:=(this.FrameEntries[Entry,"Height"]-32)//2
				}
			}
		Else If (Profile="Spell")
			{
			Loop, % this.Stats.CountOfFrameEntries
				{
				Entry:=A_Index-1
				this.FrameEntries[Entry,"CenterX"]:=Round(this.FrameEntries[Entry,"Width"]*0.5)
				this.FrameEntries[Entry,"CenterY"]:=Round(this.FrameEntries[Entry,"Height"]*0.75)
				}
			}
	}
	_Unify(){
		tic:=QPC(1)
		MaxXCoord:=0
		MaxYCoord:=0
		Loop, % this.Stats.CountOfFrameEntries
			{
			Index:=A_Index-1
			;IsTrans:=this._IsFrameTrans(Index)
			If (this.FrameEntries[Index,"CenterX"]>MaxXCoord) ;AND !IsTrans
				MaxXCoord:=this.FrameEntries[Index,"CenterX"]
			If (this.FrameEntries[Index,"CenterY"]>MaxYCoord) ;AND !IsTrans
				MaxYCoord:=this.FrameEntries[Index,"CenterY"]
			}
		MaxWidth:=0
		MaxHeight:=0
		Loop, % this.Stats.CountOfFrameEntries
			{
			Index:=A_Index-1
			If (IsTrans:=this._IsFrameTrans(Index))
				Continue
			InsertLeft:=(MaxXCoord - this.FrameEntries[Index,"CenterX"])
			InsertTop:=(MaxYCoord - this.FrameEntries[Index,"CenterY"])
			;Console.Send("FrameEntry=" Index ", InsertLeft= " InsertLeft ", InsertTop=" InsertTop "`r`n","I")
			this._InsertRC(Index,InsertTop,0,InsertLeft,0)
			this.FrameEntries[Index,"Width"]:=this.FrameEntries[Index,"Width"]+InsertLeft
			this.FrameEntries[Index,"Height"]:=this.FrameEntries[Index,"Height"]+InsertTop
			If (this.FrameEntries[Index,"Width"]>MaxWidth)
				MaxWidth:=this.FrameEntries[Index,"Width"]
			If (this.FrameEntries[Index,"Height"]>MaxHeight)
				MaxHeight:=this.FrameEntries[Index,"Height"]
			If (Settings.Unify=2)
				{
				If (MaxWidth>MaxHeight)
					MaxHeight:=MaxWidth
				If (MaxHeight>MaxWidth)
					MaxWidth:=MaxHeight
				}
			}
		Loop, % this.Stats.CountOfFrameEntries
			{
			Index:=A_Index-1
			InsertRight:=(MaxWidth-this.FrameEntries[Index,"Width"])
			InsertBottom:=(MaxHeight-this.FrameEntries[Index,"Height"])
			;Console.Send("FrameEntry=" Index ", InsertRight= " InsertRight ", InsertBottom=" InsertBottom "`r`n","I")
			this._InsertRC(Index,0,InsertBottom,0,InsertRight)
			this.FrameEntries[Index,"Width"]:=MaxWidth
			this.FrameEntries[Index,"Height"]:=MaxHeight
			this.FrameEntries[Index,"CenterX"]:=MaxXCoord
			this.FrameEntries[Index,"CenterY"]:=MaxYCoord
			;Console.Send("FrameEntry=" Index ", Width= " MaxWidth ", Height=" MaxHeight ", MaxXCoord=" MaxXCoord ", MaxYCoord=" MaxYCoord "`r`n","I")
			}
		Console.Send("Unified frames in " (QPC(1)-tic) " sec.`r`n","-I")
	}
	_InsertRC(Entry,Top,Bottom,Left,Right){
		Width:=this.FrameEntries[Entry,"Width"]
		Height:=this.FrameEntries[Entry,"Height"]
		CenterX:=this.FrameEntries[Entry,"CenterX"]
		CenterY:=this.FrameEntries[Entry,"CenterY"]
		FramePointer:=this.FrameEntries[Entry,"FramePointer"]
		RLE:=this.FrameEntries[Entry,"RLE"]
		;Entries:=_GetFrameDataFrameEntries(FramePointer)
		If (RLE=0) ; Can't insert rows and columns into RLEd Frame Data
			{
			If (Top>0) AND (Width*Top>0)
				{
				Loop, % (Width*Top)
					this.FrameData[FramePointer].InsertAt(0,this.Stats.TransColorIndex)
				Height+=Top
				}
			If (Bottom>0) AND (Width*Bottom>0)
				Loop % (Width*Bottom)
					this.FrameData[FramePointer].Push(this.Stats.TransColorIndex)
				Height+=Bottom
			If (Left>0) AND (Height>0)
				{
				Loop, %Height%
					{
					Index:=(A_Index-1)*Width+(A_Index-1)*Left
					Loop, %Left%
						{
						this.FrameData[FramePointer].InsertAt(Index,this.Stats.TransColorIndex)
						}
					}
				Width+=Left
				}
			If (Right>0) AND (Height>0)
				{
				Loop, %Height%
					{
					Index:=(A_Index)*Width+(A_Index-1)*Right
					Loop, %Right%
						{
						this.FrameData[FramePointer].InsertAt(Index,this.Stats.TransColorIndex)
						}
					}
				Width+=Right
				}
			}
	}
	_SplitFillSettings(){
		; widthXheight,orientation
		FillSettings:={}
		Arr:=StrSplit(Trim(Settings.Fill),["x",","])
		FillSettings["width"]:=(Arr[1]?Arr[1]:0)
		FillSettings["height"]:=(Arr[2]?Arr[2]:0)
		FillSettings["orientation"]:=(Arr[3]?Arr[3]:"NorthWest")
		orientation:=FillSettings["orientation"]
		If (orientation="North") OR (orientation="Top") OR (orientation="South") OR (orientation="Bottom")
			FillSettings["width"]:=0
		Else If (orientation="East") OR (orientation="Right") OR (orientation="West") OR (orientation="Left")
			FillSettings["height"]:=0
		Else If !(orientation="NorthWest") AND !(orientation="TopLeft") AND !(orientation="NorthEast") AND !(orientation="TopRight") AND !(orientation="SouthWest") AND !(orientation="BottomLeft") AND !(orientation="SouthEast") AND !(orientation="BottomRight")
			{
			Console.Send("Orientation passed to --Settings.Fill is an unknown value:  '" orientation "'.`r`n","E")
			throw Exception("Orientation passed to --Settings.Fill is an unknown value:  '" orientation "'.",,"`n`n" Traceback())
			}
		;MsgBox % "Width=" FillSettings["width"] "`r`nHeight=" FillSettings["height"] "`r`nOrientation=" FillSettings["orientation"]
		Console.Send("--Fill resolved to '" FillSettings["width"] "x" FillSettings["height"] "," FillSettings["orientation"] "'`r`n","I")
		Return FillSettings
	}
	_Fill(){
		tic:=QPC(1)
		FillSettings:=this._SplitFillSettings()
		fw:=FillSettings["width"]
		fh:=FillSettings["height"]
		fo:=FillSettings["orientation"]
		; this.FrameEntries[Index,"CenterX"]+=MaxXCoord, this.FrameEntries[Index,"CenterY"]+=MaxYCoord
		Loop, % this.Stats.CountOfFrameEntries
			{
			Index:=A_Index-1
			InsertWidth:=(fw-this.FrameEntries[Index,"Width"]), InsertWidth:=(InsertWidth<0?0:InsertWidth)
			InsertHeight:=(fh-this.FrameEntries[Index,"Height"]), InsertHeight:=(InsertHeight<0?0:InsertHeight)
			If (fo="NorthWest") OR (fo="TopLeft")
				InsertTop:=InsertHeight, InsertBottom:=0, InsertLeft:=InsertWidth, InsertRight:=0
			Else If (fo="NorthEast") OR (fo="TopRight")
				InsertTop:=InsertHeight, InsertBottom:=0, InsertLeft:=0, InsertRight:=InsertWidth
			Else If (fo="SouthWest") OR (fo="BottomLeft")
				InsertTop:=0, InsertBottom:=InsertHeight, InsertLeft:=InsertWidth, InsertRight:=0
			Else If (fo="SouthEast") OR (fo="BottomRight")
				InsertTop:=0, InsertBottom:=InsertHeight, InsertLeft:=0, InsertRight:=InsertWidth
			Else If (fo="North") OR (fo="Top")
				InsertTop:=InsertHeight, InsertBottom:=0, InsertLeft:=0, InsertRight:=0
			Else If (fo="South") OR (fo="Bottom")
				InsertTop:=0, InsertBottom:=InsertHeight, InsertLeft:=0, InsertRight:=0
			Else If (fo="East") OR (fo="Right")
				InsertTop:=0, InsertBottom:=0, InsertLeft:=0, InsertRight:=InsertWidth
			Else If (fo="West") OR (fo="Left")
				InsertTop:=0, InsertBottom:=0, InsertLeft:=InsertWidth, InsertRight:=0
			this._InsertRC(Index,InsertTop,InsertBottom,InsertLeft,InsertRight)
			this.FrameEntries[Index,"Width"]+=InsertWidth ; These only works b/c we zeroed unused dimensions in _SplitFillSettings()
			this.FrameEntries[Index,"Height"]+=InsertHeight ; ; These only works b/c we zeroed unused dimensions in _SplitFillSettings()
			this.FrameEntries[Index,"CenterX"]+=(InsertLeft>0?InsertLeft:0)
			this.FrameEntries[Index,"CenterY"]+=(InsertTop>0?InsertTop:0)
			}
		Console.Send("Filled frames in " (QPC(1)-tic) " sec.`r`n","-I")
	}
	_Composite(ByRef Frame,X,Y,W,H,ByRef Canvas,CanvasWidth,CanvasHeight,ShiftRight,ShiftDown,TransColor){
		Col:=0, ShiftRight+=X*-1, ShiftDown+=Y*-1
		;MsgBox X=%X%`nY=%Y%`nW=%W%`nH=%H%`nCanvasWidth=%CanvasWidth%`nCanvasHeight=%CanvasHeight%`nShiftRight=%ShiftRight%`nShiftDown=%ShiftDown%`nTransColor=%TransColor%
		For k,Px in Frame
			{
			;Console.Send(ShiftDown*CanvasWidth+ShiftRight+Col A_Space,"")
			If (ShiftDown*CanvasWidth+ShiftRight+Col>Canvas.Count()-1)
				throw Exception("Attempted to Composite a pixel outside of canvas bounds.",,"`n`n" Traceback())
			If (Px<>TransColor)	; Don't overwrite potentially real pixels with transparent
				Canvas[ShiftDown*CanvasWidth+ShiftRight+Col]:=Px
			Col++
			If (Col=W)
				{
				Col:=0
				ShiftDown+=1
				}
			}
		;~ Console.Send("`r`n")
	}
	_CompositeUP(ByRef Frame,X,Y,W,H,ByRef Canvas,CanvasWidth,CanvasHeight){
		Col:=0, ShiftDown:=Y
		For k,Px in Frame
			{
			Canvas[ShiftDown*CanvasWidth+X+Col]:=Px
			Col++
			If (Col=W)
				{
				Col:=0
				ShiftDown+=1
				}
			}
	}
	_PadFrameToDims(Frame,Width,Height){
		InsertRight:=(Width-this.FrameEntries[Frame,"Width"]), InsertRight:=(InsertRight<0?0:InsertRight)
		InsertBottom:=(Height-this.FrameEntries[Frame,"Height"]), InsertBottom:=(InsertBottom<0?0:InsertBottom)
		this._InsertRC(Frame,0,InsertBottom,0,InsertRight)
		If (InsertRight>0)
			this.FrameEntries[Frame,"Width"]:=Width
		If (InsertBottom>0)
			this.FrameEntries[Frame,"Height"]:=Height
	}
	_Montage(Input){ ; Combines frames into a single frame.
		tic:=QPC(1)
		this._TrimFrames()
		If (Settings.Montage="Paperdoll")	; (rows x columns) ; Inventory Paperdoll Specific
			{
			; Dimension calculations:
			MinX:=MinY:=MinWidth:=MinHeight:=2000, MaxX:=MaxY:=MaxWidth:=MaxHeight:=0, CanvasWidth:=CanvasHeight:=1
			For Frame,v in this.FrameEntries
				{
				X:=v["CenterX"], Y:=v["CenterY"], W:=v["Width"], H:=v["Height"]
				If (Frame>0) ; AND (Y<>0)
					Y-=80	; Warning, only for 1x2!!!
				MinX:=(X<MinX?X:MinX), MinY:=(Y<MinY?Y:MinY), MaxX:=(X>MaxX?X:MaxX), MaxY:=(Y>MaxY?Y:MaxY), MaxWidth:=(W>MaxWidth?W:MaxWidth), MaxHeight:=(H>MaxHeight?H:MaxHeight)	; MinWidth:=(W<MinWidth?W:MinWidth), MinHeight:=(H<MinHeight?H:MinHeight), 
				CanvasWidth:=(W+Abs(X)>CanvasWidth?W+Abs(X):CanvasWidth)
				CanvasHeight:=(H+Abs(Y)>CanvasHeight?H+Abs(Y):CanvasHeight)
				}
			; Create virtual canvas
			Canvas:={}, Canvas.SetCapacity(Px:=CanvasWidth*CanvasHeight)
			Loop, %Px%
				Canvas[A_Index-1]:=this.Stats.TransColorIndex
			; Determine parameters to shift actual frames onto virtual canvas
			ShiftRight:=MaxX, ShiftDown:=MaxY
			; Start compositing frames onto virtual canvas
			For Frame,v in this.FrameEntries
				{
				X:=v["CenterX"], Y:=v["CenterY"], W:=v["Width"], H:=v["Height"], FramePointer:=v["FramePointer"]
				If (Frame>0) ; AND (Y<>0)
					Y-=80
				this._Composite(this.FrameData[FramePointer],X,Y,W,H,Canvas,CanvasWidth,CanvasHeight,ShiftRight,ShiftDown,this.Stats.TransColorIndex)
				}
			; Attempt to trim/shift virtual canvas back down to real dimensions.  Edit:  Trimming not practical so just report it.
			If (ShiftRight<>0) OR (ShiftDown<>0)
				Console.Send("Montaged frames extend into negative coordinates on virtual canvas.  Compensating by shifting image right " ShiftRight "px and shifting image down by " ShiftDown "px.  BAM Frame coordinates will be correct but exported frame will be falsely offset.`r`n","W")
			;~ tmp=X=%X%`nY=%Y%`nW=%W%`nH=%H%`nCanvasWidth=%CanvasWidth%`nCanvasHeight=%CanvasHeight%`nShiftRight=%ShiftRight%`nShiftDown=%ShiftDown%`nTransColor=%TransColor%`nMaxX=%MaxX%`nMaxY=%MaxY%
			;~ Console.Send(tmp "`r`n","I")
			; Clear all FrameData and FrameEntries
			this.FrameData:="", this.FrameData:={}, this.FrameEntries:="", this.FrameEntries:={}, this.FrameLookupTable:="", this.FrameLookupTable:={}, this.CycleEntries:="", this.CycleEntries:={}
			; Save composited frame back into BAM
			this.FrameData[0]:=Canvas
			this.FrameEntries[0,"Width"]:=CanvasWidth
			this.FrameEntries[0,"Height"]:=CanvasHeight
			this.FrameEntries[0,"CenterX"]:=MaxX
			this.FrameEntries[0,"CenterY"]:=MaxY
			this.FrameEntries[0,"FramePointer"]:=0
			this.FrameEntries[0,"RLE"]:=0
			this.FrameLookupTable[0]:=0
			this.CycleEntries[0,"CountOfFrameIndices"]:=1, this.CycleEntries[0,"IndexIntoFLT"]:=0
			; Expand dimensions to desired values if smaller
			this._PadFrameToDims(0,128,160)
			; If virtual canvas > real canvas, try to trim it back down to appropriate sizes! 20181012
			; Update Stats
			this._UpdateStats()
			
			/*
			If (this.Stats.CountOfFrames=2)	; Need to InsertRC on Top and Left to remove negative offsets, then pad width to be equal.  Combine frames, then pad to 128*160.  If frames have +Offset, they appear to always be transparent so this is okay. Also, CountOfSequences may be >2.  Account for all of them.  Add Method to zero offset trans frame.
				{
				;this._TrimFrames()
				this._Unify()
				this.FrameData[0].Push(ShiftArray(this.FrameData[1])*)
				this.FrameEntries[0,"Height"]+=this.FrameEntries[1,"Height"]
				;~ this.FrameData[1].RemoveAt(0,1)
				this.FrameLookupTable:="", this.FrameLookupTable:={}, this.FrameLookupTable[0]:=0
				this.CycleEntries[0,"CountOfFrameIndices"]:=1, this.CycleEntries[0,"IndexIntoFLT"]:=0
				this.CycleEntries[1]:=""
				; Pad Combined frame to user-friendly dimensions for INV paperdolls
				Index:=0
				InsertRight:=(128-this.FrameEntries[Index,"Width"])
				InsertBottom:=(160-this.FrameEntries[Index,"Height"])
				this._InsertRC(Index,0,InsertBottom,0,InsertRight)
				If (InsertRight>0)
					this.FrameEntries[Index,"Width"]:=128
				If (InsertBottom>0)
					this.FrameEntries[Index,"Height"]:=160
				If (this.FrameEntries[Index,"CenterX"]<>0) OR (this.FrameEntries[Index,"CenterY"]<>0)
					MsgBox % "CenterX=" this.FrameEntries[Index,"CenterX"] A_Tab "CenterY=" this.FrameEntries[Index,"CenterY"]
				this._UpdateStats()
				}
			*/
			}
		Else If (Settings.Montage="2x2SplitCreAnim") OR (Settings.Montage="2x2External") OR (Settings.Montage="2x2ExternalIgnoreOffsets")	; (rows x columns)
			{
			SplitPath, Input, InFileName, InDir, InExtension, Animation, InDrive
			AnimationArr:={}
			If (Settings.Montage="2x2SplitCreAnim")
				{
				AnimationPrefix:=SubStr(Animation,1,4) ; Get 1st 4 characters (animation ID)
				AnimationArr.Push(["g11","g12","g13","g14"])
				AnimationArr.Push(["g21","g22","g23","g24"])
				AnimationArr.Push(["g31","g32","g33","g34"])
				AnimationArr.Push(["g11E","g12E","g13E","g14E"])
				AnimationArr.Push(["g21E","g22E","g23E","g24E"])
				AnimationArr.Push(["g31E","g32E","g33E","g34E"])
				AnimationArr.Push(["g111","g121","g131","g141"])
				AnimationArr.Push(["g112","g122","g132","g142"])
				AnimationArr.Push(["g113","g123","g133","g143"])
				AnimationArr.Push(["g114","g124","g134","g144"])
				AnimationArr.Push(["g115","g125","g135","g145"])
				AnimationArr.Push(["g211","g221","g231","g241"])
				AnimationArr.Push(["g212","g222","g232","g242"])
				AnimationArr.Push(["g213","g223","g233","g243"])
				AnimationArr.Push(["g214","g224","g234","g244"])
				AnimationArr.Push(["g215","g225","g235","g245"])
				AnimationArr.Push(["g216","g226","g236","g246"])
				}
			Else ; If (Settings.Montage="2x2External") OR (Settings.Montage="2x2ExternalIgnoreOffsets")
				{
				AnimationPrefix:=SubStr(Animation,1,StrLen(Animation)-1) ; Get all but the last character (animation ID)
				AnimationArr.Push(["1","2","3","4"])
				AnimationArr.Push(["A","B","C","D"])
				}
			AnimationArrIdx:=""
			For k,v in AnimationArr
				{
				If (AnimationPrefix v[1] = Animation)
					{
					AnimationArrIdx:=k
					Break
					}
				}
			Console.DebugLevel:=Settings.DebugLevelL
			Part2:=New PSBAM()
				Part2.LoadBAM(InDir "\" AnimationPrefix AnimationArr[AnimationArrIdx,2] ".bam")
			Part3:=New PSBAM()
				Part3.LoadBAM(InDir "\" AnimationPrefix AnimationArr[AnimationArrIdx,3] ".bam")
			Part4:=New PSBAM()
				Part4.LoadBAM(InDir "\" AnimationPrefix AnimationArr[AnimationArrIdx,4] ".bam")
			Console.DebugLevel:=Settings.DebugLevelP
			;;; Handle Palettes ;;;
			If (Settings.ReplacePaletteMethod="Quant")
				{
				Quant:=New PS_Quantization()
				Quant.AddReservedColor(0,255,0,0)
				Quant.AddReservedColor(0,0,0,0)
				If (Settings.ForceShadowColor=-1)
					{
					this._ReplacePaletteColor(this.Palette)  ; Defaults to Black->RGBA(1,1,1,0)
					this._ReplacePaletteColor(Part2.Palette) ; Defaults to Black->RGBA(1,1,1,0)
					this._ReplacePaletteColor(Part3.Palette) ; Defaults to Black->RGBA(1,1,1,0)
					this._ReplacePaletteColor(Part4.Palette) ; Defaults to Black->RGBA(1,1,1,0)
					}
				this._AddBAMToQuant(this,Quant)
				this._AddBAMToQuant(Part2,Quant)
				this._AddBAMToQuant(Part3,Quant)
				this._AddBAMToQuant(Part4,Quant)
				Console.Send("ColorCount = " Quant.GetColorCount() "`r`n","I")
				Quant.Quantize(256)
				Console.Send("Total Error: " Quant.GetTotalError() "`r`n","I")
				PalObj:=Quant.GetPaletteObj()
				this.ReplacePalette("","","","Remap",PalObj)
				Part2.ReplacePalette("","","","Remap",PalObj)
				Part3.ReplacePalette("","","","Remap",PalObj)
				Part4.ReplacePalette("","","","Remap",PalObj)
				Quant:=""
				}
			;;; Recalculate Offsets ;;;
			If (Settings.Montage="2x2ExternalIgnoreOffsets")
				{
				Loop, % this.Stats.CountOfCycles
					{
					Sequence:=A_Index-1
					Idx:=this.CycleEntries[Sequence,"IndexIntoFLT"]
					Loop, % this.CycleEntries[Sequence,"CountOfFrameIndices"]
						{
						Indexi:=A_Index-1
						; Get Part 1 ;
						Entry:=this.FrameLookupTable[Idx+Indexi]
						W1:=this.FrameEntries[Entry,"Width"], H1:=this.FrameEntries[Entry,"Height"]
						X1:=this.FrameEntries[Entry,"CenterX"], Y1:=this.FrameEntries[Entry,"CenterY"]
						; Set Part 2 ;
						Entry2:=Part2.FrameLookupTable[Part2.CycleEntries[Sequence,"IndexIntoFLT"]+Indexi]
						Part2.FrameEntries[Entry2,"CenterX"]:=-W1+X1, Part2.FrameEntries[Entry2,"CenterY"]:=Y1+(Part2.FrameEntries[Entry2,"Height"]-H1)
						; Set Part 3 ;
						Entry3:=Part3.FrameLookupTable[Part3.CycleEntries[Sequence,"IndexIntoFLT"]+Indexi]
						Part3.FrameEntries[Entry3,"CenterX"]:=X1+(Part3.FrameEntries[Entry3,"Width"]-W1), Part3.FrameEntries[Entry3,"CenterY"]:=-H1+Y1
						; Set Part 4 ;
						Entry4:=Part4.FrameLookupTable[Part4.CycleEntries[Sequence,"IndexIntoFLT"]+Indexi]
						Part4.FrameEntries[Entry4,"CenterX"]:=-W1+X1, Part4.FrameEntries[Entry4,"CenterY"]:=-H1+Y1
						}
					}
				}
			; Dimension calculations:
			Loop, % this.Stats.CountOfCycles
				{
				Sequence:=A_Index-1
				MinCenterX:=MinCenterY:=1000000, MaxWidth:=MaxHeight:=MaxCenterX:=MaxCenterY:=CanvasWidth:=CanvasHeight:=0
				
				SzArr:=this._GetSequenceCanvasDimensions(Sequence,MinCenterX,MinCenterY,MaxWidth,MaxHeight,MaxCenterX,MaxCenterY,CanvasWidth,CanvasHeight)
				SzArr:=Part2._GetSequenceCanvasDimensions(Sequence,MinCenterX,MinCenterY,MaxWidth,MaxHeight,MaxCenterX,MaxCenterY,CanvasWidth,CanvasHeight)
				SzArr:=Part3._GetSequenceCanvasDimensions(Sequence,MinCenterX,MinCenterY,MaxWidth,MaxHeight,MaxCenterX,MaxCenterY,CanvasWidth,CanvasHeight)
				SzArr:=Part4._GetSequenceCanvasDimensions(Sequence,MinCenterX,MinCenterY,MaxWidth,MaxHeight,MaxCenterX,MaxCenterY,CanvasWidth,CanvasHeight)
				ShiftX:=(MinCenterX<0?0-MinCenterX:0), ShiftY:=(MinCenterY<0?0-MinCenterY:0)
				
				Idx:=this.CycleEntries[Sequence,"IndexIntoFLT"]
				Loop, % this.CycleEntries[Sequence,"CountOfFrameIndices"]
					{
					; Create virtual canvas
					Canvas:="", Canvas:={}, Canvas.SetCapacity(Px:=CanvasWidth*CanvasHeight)
					Loop, %Px%
						Canvas[A_Index-1]:=this.Stats.TransColorIndex
					Indexi:=A_Index-1
					;;; Part 1 (this BAM) ;;;
					Entry:=this.FrameLookupTable[Idx+Indexi]
					W:=this.FrameEntries[Entry,"Width"], H:=this.FrameEntries[Entry,"Height"]
					X:=this.FrameEntries[Entry,"CenterX"], Y:=this.FrameEntries[Entry,"CenterY"]
					FramePointer:=this.FrameEntries[Entry,"FramePointer"]
					this._Composite(this.FrameData[FramePointer],X,Y,W,H,Canvas,CanvasWidth,CanvasHeight,ShiftX,ShiftY,this.Stats.TransColorIndex)
					;;; Part 2 ;;;
					Entry:=Part2.FrameLookupTable[Idx+Indexi]
					W:=Part2.FrameEntries[Entry,"Width"], H:=Part2.FrameEntries[Entry,"Height"]
					X:=Part2.FrameEntries[Entry,"CenterX"], Y:=Part2.FrameEntries[Entry,"CenterY"]
					FramePointer:=Part2.FrameEntries[Entry,"FramePointer"]
					this._Composite(Part2.FrameData[FramePointer],X,Y,W,H,Canvas,CanvasWidth,CanvasHeight,ShiftX,ShiftY,this.Stats.TransColorIndex)
					;;; Part 3 ;;;
					Entry:=Part3.FrameLookupTable[Idx+Indexi]
					W:=Part3.FrameEntries[Entry,"Width"], H:=Part3.FrameEntries[Entry,"Height"]
					X:=Part3.FrameEntries[Entry,"CenterX"], Y:=Part3.FrameEntries[Entry,"CenterY"]
					FramePointer:=Part3.FrameEntries[Entry,"FramePointer"]
					this._Composite(Part3.FrameData[FramePointer],X,Y,W,H,Canvas,CanvasWidth,CanvasHeight,ShiftX,ShiftY,this.Stats.TransColorIndex)
					;;; Part 4 ;;;
					Entry:=Part4.FrameLookupTable[Idx+Indexi]
					W:=Part4.FrameEntries[Entry,"Width"], H:=Part4.FrameEntries[Entry,"Height"]
					X:=Part4.FrameEntries[Entry,"CenterX"], Y:=Part4.FrameEntries[Entry,"CenterY"]
					FramePointer:=Part4.FrameEntries[Entry,"FramePointer"]
					this._Composite(Part4.FrameData[FramePointer],X,Y,W,H,Canvas,CanvasWidth,CanvasHeight,ShiftX,ShiftY,this.Stats.TransColorIndex)
					;;; Set Canvas to Frame ;;;
					Entry:=this.FrameLookupTable[Idx+Indexi]
					FramePointer:=this.FrameEntries[Entry,"FramePointer"]
					this.FrameData[FramePointer]:=Canvas
					this.FrameEntries[Entry,"Width"]:=CanvasWidth
					this.FrameEntries[Entry,"Height"]:=CanvasHeight
					this.FrameEntries[Entry,"CenterX"]:=ShiftX
					this.FrameEntries[Entry,"CenterY"]:=ShiftY
					;this.FrameEntries[Entry,"FramePointer"]:=FramePointer
					this.FrameEntries[Entry,"RLE"]:=0
					}
				}
			Part2:=""
			Part3:=""
			Part4:=""
			this._UpdateStats()
			}
		Else If (Settings.Montage="1x2External") OR (Settings.Montage="2x1External") OR (Settings.Montage="1x2ExternalIgnoreOffsets") OR (Settings.Montage="2x1ExternalIgnoreOffsets") ; (rows x columns)
			{
			SplitPath, Input, InFileName, InDir, InExtension, Animation, InDrive
			AnimationArr:={}
			AnimationPrefix:=SubStr(Animation,1,StrLen(Animation)-1) ; Get all but the last character (animation ID)
			AnimationArr.Push(["1","2"])
			AnimationArr.Push(["A","B"])
			AnimationArr.Push(["L","R"])
			AnimationArr.Push(["B","C"])
			AnimationArr.Push(["C","D"])
			AnimationArr.Push(["2","3"])
			AnimationArr.Push(["3","4"])
			AnimationArrIdx:=""
			For k,v in AnimationArr
				{
				If (AnimationPrefix v[1] = Animation)
					{
					AnimationArrIdx:=k
					Break
					}
				}
			Console.DebugLevel:=Settings.DebugLevelL
			Part2:=New PSBAM()
				Part2.LoadBAM(InDir "\" AnimationPrefix AnimationArr[AnimationArrIdx,2] ".bam")
			Console.DebugLevel:=Settings.DebugLevelP
			;;; Handle Palettes ;;;
			If (Settings.ReplacePaletteMethod="Quant")
				{
				Quant:=New PS_Quantization()
				Quant.AddReservedColor(0,255,0,0)
				Quant.AddReservedColor(0,0,0,0)
				If (Settings.ForceShadowColor=-1)
					{
					this._ReplacePaletteColor(this.Palette)  ; Defaults to Black->RGBA(1,1,1,0)
					this._ReplacePaletteColor(Part2.Palette) ; Defaults to Black->RGBA(1,1,1,0)
					}
				this._AddBAMToQuant(this,Quant)
				this._AddBAMToQuant(Part2,Quant)
				Console.Send("ColorCount = " Quant.GetColorCount() "`r`n","I")
				Quant.Quantize(256)
				Console.Send("Total Error: " Quant.GetTotalError() "`r`n","I")
				PalObj:=Quant.GetPaletteObj()
				this.ReplacePalette("","","","Remap",PalObj)
				Part2.ReplacePalette("","","","Remap",PalObj)
				Quant:=""
				}
			;;; Recalculate Offsets ;;;
			If InStr(Settings.Montage,"IgnoreOffsets")
				{
				Loop, % this.Stats.CountOfCycles
					{
					Sequence:=A_Index-1
					Idx:=this.CycleEntries[Sequence,"IndexIntoFLT"]
					Loop, % this.CycleEntries[Sequence,"CountOfFrameIndices"]
						{
						Indexi:=A_Index-1
						; Get Part 1 ;
						Entry:=this.FrameLookupTable[Idx+Indexi]
						W1:=this.FrameEntries[Entry,"Width"], H1:=this.FrameEntries[Entry,"Height"]
						X1:=this.FrameEntries[Entry,"CenterX"], Y1:=this.FrameEntries[Entry,"CenterY"]
						; Set Part 2 ;
						If InStr(Settings.Montage,"1x2")
							{
							Entry2:=Part2.FrameLookupTable[Part2.CycleEntries[Sequence,"IndexIntoFLT"]+Indexi]
							Part2.FrameEntries[Entry2,"CenterX"]:=-W1+X1, Part2.FrameEntries[Entry2,"CenterY"]:=Y1+(Part2.FrameEntries[Entry2,"Height"]-H1)
							}
						Else If InStr(Settings.Montage,"2x1")
							{
							Entry2:=Part2.FrameLookupTable[Part2.CycleEntries[Sequence,"IndexIntoFLT"]+Indexi]
							Part2.FrameEntries[Entry2,"CenterX"]:=X1+(Part2.FrameEntries[Entry2,"Width"]-W1), Part2.FrameEntries[Entry2,"CenterY"]:=-H1+Y1
							}
						}
					}
				}
			; Dimension calculations:
			Loop, % this.Stats.CountOfCycles
				{
				Sequence:=A_Index-1
				MinCenterX:=MinCenterY:=1000000, MaxWidth:=MaxHeight:=MaxCenterX:=MaxCenterY:=CanvasWidth:=CanvasHeight:=0
				
				SzArr:=this._GetSequenceCanvasDimensions(Sequence,MinCenterX,MinCenterY,MaxWidth,MaxHeight,MaxCenterX,MaxCenterY,CanvasWidth,CanvasHeight)
				SzArr:=Part2._GetSequenceCanvasDimensions(Sequence,MinCenterX,MinCenterY,MaxWidth,MaxHeight,MaxCenterX,MaxCenterY,CanvasWidth,CanvasHeight)
				ShiftX:=(MinCenterX<0?0-MinCenterX:0), ShiftY:=(MinCenterY<0?0-MinCenterY:0)
				
				Idx:=this.CycleEntries[Sequence,"IndexIntoFLT"]
				Loop, % this.CycleEntries[Sequence,"CountOfFrameIndices"]
					{
					; Create virtual canvas
					Canvas:="", Canvas:={}, Canvas.SetCapacity(Px:=CanvasWidth*CanvasHeight)
					Loop, %Px%
						Canvas[A_Index-1]:=this.Stats.TransColorIndex
					Indexi:=A_Index-1
					;;; Part 1 (this BAM) ;;;
					Entry:=this.FrameLookupTable[Idx+Indexi]
					W:=this.FrameEntries[Entry,"Width"], H:=this.FrameEntries[Entry,"Height"]
					X:=this.FrameEntries[Entry,"CenterX"], Y:=this.FrameEntries[Entry,"CenterY"]
					FramePointer:=this.FrameEntries[Entry,"FramePointer"]
					this._Composite(this.FrameData[FramePointer],X,Y,W,H,Canvas,CanvasWidth,CanvasHeight,ShiftX,ShiftY,this.Stats.TransColorIndex)
					;;; Part 2 ;;;
					Entry:=Part2.FrameLookupTable[Idx+Indexi]
					W:=Part2.FrameEntries[Entry,"Width"], H:=Part2.FrameEntries[Entry,"Height"]
					X:=Part2.FrameEntries[Entry,"CenterX"], Y:=Part2.FrameEntries[Entry,"CenterY"]
					FramePointer:=Part2.FrameEntries[Entry,"FramePointer"]
					this._Composite(Part2.FrameData[FramePointer],X,Y,W,H,Canvas,CanvasWidth,CanvasHeight,ShiftX,ShiftY,this.Stats.TransColorIndex)
					;;; Set Canvas to Frame ;;;
					Entry:=this.FrameLookupTable[Idx+Indexi]
					FramePointer:=this.FrameEntries[Entry,"FramePointer"]
					this.FrameData[FramePointer]:=Canvas
					this.FrameEntries[Entry,"Width"]:=CanvasWidth
					this.FrameEntries[Entry,"Height"]:=CanvasHeight
					this.FrameEntries[Entry,"CenterX"]:=ShiftX
					this.FrameEntries[Entry,"CenterY"]:=ShiftY
					;this.FrameEntries[Entry,"FramePointer"]:=FramePointer
					this.FrameEntries[Entry,"RLE"]:=0
					}
				}
			Part2:=""
			this._UpdateStats()
			}
		Else If (Settings.Montage="3x3SplitCreAnim")	; (rows x columns)
			{
			;SplitPath, Output, Animation, OutputDir
			SplitPath, Input, InFileName, InDir, InExtension, Animation, InDrive
			AnimationPrefix:=SubStr(Animation,1,4) ; Get 1st 4 characters (animation ID)
			AnimationArr:={}
			AnimationArr.Push(["1100","1200","1300","1400","1500","1600","1700","1800","1900"])
			AnimationArr.Push(["1101","1201","1301","1401","1501","1601","1701","1801","1901"])
			AnimationArr.Push(["1102","1202","1302","1402","1502","1602","1702","1802","1902"])
			AnimationArr.Push(["1103","1203","1303","1403","1503","1603","1703","1803","1903"])
			AnimationArr.Push(["1104","1204","1304","1404","1504","1604","1704","1804","1904"])
			AnimationArr.Push(["1105","1205","1305","1405","1505","1605","1705","1805","1905"])
			AnimationArr.Push(["1106","1206","1306","1406","1506","1606","1706","1806","1906"])
			AnimationArr.Push(["1107","1207","1307","1407","1507","1607","1707","1807","1907"])
			AnimationArr.Push(["1108","1208","1308","1408","1508","1608","1708","1808","1908"])
			AnimationArr.Push(["2100","2200","2300","2400","2500","2600","2700","2800","2900"])
			AnimationArr.Push(["2101","2201","2301","2401","2501","2601","2701","2801","2901"])
			AnimationArr.Push(["2102","2202","2302","2402","2502","2602","2702","2802","2902"])
			AnimationArr.Push(["2103","2203","2303","2403","2503","2603","2703","2803","2903"])
			AnimationArr.Push(["2104","2204","2304","2404","2504","2604","2704","2804","2904"])
			AnimationArr.Push(["2105","2205","2305","2405","2505","2605","2705","2805","2905"])
			AnimationArr.Push(["2106","2206","2306","2406","2506","2606","2706","2806","2906"])
			AnimationArr.Push(["2107","2207","2307","2407","2507","2607","2707","2807","2907"])
			AnimationArr.Push(["2108","2208","2308","2408","2508","2608","2708","2808","2908"])
			AnimationArr.Push(["3100","3200","3300","3400","3500","3600","3700","3800","3900"])
			AnimationArr.Push(["3101","3201","3301","3401","3501","3601","3701","3801","3901"])
			AnimationArr.Push(["3102","3202","3302","3402","3502","3602","3702","3802","3902"])
			AnimationArr.Push(["3103","3203","3303","3403","3503","3603","3703","3803","3903"])
			AnimationArr.Push(["3104","3204","3304","3404","3504","3604","3704","3804","3904"])
			AnimationArr.Push(["3105","3205","3305","3405","3505","3605","3705","3805","3905"])
			AnimationArr.Push(["3106","3206","3306","3406","3506","3606","3706","3806","3906"])
			AnimationArr.Push(["3107","3207","3307","3407","3507","3607","3707","3807","3907"])
			AnimationArr.Push(["3108","3208","3308","3408","3508","3608","3708","3808","3908"])
			AnimationArr.Push(["4100","4200","4300","4400","4500","4600","4700","4800","4900"])
			AnimationArr.Push(["4101","4201","4301","4401","4501","4601","4701","4801","4901"])
			AnimationArr.Push(["4102","4202","4302","4402","4502","4602","4702","4802","4902"])
			AnimationArr.Push(["4103","4203","4303","4403","4503","4603","4703","4803","4903"])
			AnimationArr.Push(["4104","4204","4304","4404","4504","4604","4704","4804","4904"])
			AnimationArr.Push(["4105","4205","4305","4405","4505","4605","4705","4805","4905"])
			AnimationArr.Push(["4106","4206","4306","4406","4506","4606","4706","4806","4906"])
			AnimationArr.Push(["4107","4207","4307","4407","4507","4607","4707","4807","4907"])
			AnimationArr.Push(["4108","4208","4308","4408","4508","4608","4708","4808","4908"])
			AnimationArr.Push(["4110","4210","4310","4410","4510","4610","4710","4810","4910"])
			AnimationArr.Push(["4111","4211","4311","4411","4511","4611","4711","4811","4911"])
			AnimationArr.Push(["4112","4212","4312","4412","4512","4612","4712","4812","4912"])
			AnimationArr.Push(["4113","4213","4313","4413","4513","4613","4713","4813","4913"])
			AnimationArr.Push(["4114","4214","4314","4414","4514","4614","4714","4814","4914"])
			AnimationArr.Push(["4115","4215","4315","4415","4515","4615","4715","4815","4915"])
			AnimationArr.Push(["4116","4216","4316","4416","4516","4616","4716","4816","4916"])
			AnimationArr.Push(["4117","4217","4317","4417","4517","4617","4717","4817","4917"])
			AnimationArr.Push(["4118","4218","4318","4418","4518","4618","4718","4818","4918"])
			AnimationArr.Push(["4120","4220","4320","4420","4520","4620","4720","4820","4920"])
			AnimationArr.Push(["4121","4221","4321","4421","4521","4621","4721","4821","4921"])
			AnimationArr.Push(["4122","4222","4322","4422","4522","4622","4722","4822","4922"])
			AnimationArr.Push(["4123","4223","4323","4423","4523","4623","4723","4823","4923"])
			AnimationArr.Push(["4124","4224","4324","4424","4524","4624","4724","4824","4924"])
			AnimationArr.Push(["4125","4225","4325","4425","4525","4625","4725","4825","4925"])
			AnimationArr.Push(["4126","4226","4326","4426","4526","4626","4726","4826","4926"])
			AnimationArr.Push(["4127","4227","4327","4427","4527","4627","4727","4827","4927"])
			AnimationArr.Push(["4128","4228","4328","4428","4528","4628","4728","4828","4928"])
			AnimationArr.Push(["5110","5210","5310","5410","5510","5610","5710","5810","5910"])
			AnimationArr.Push(["5111","5211","5311","5411","5511","5611","5711","5811","5911"])
			AnimationArr.Push(["5112","5212","5312","5412","5512","5612","5712","5812","5912"])
			AnimationArr.Push(["5113","5213","5313","5413","5513","5613","5713","5813","5913"])
			AnimationArr.Push(["5114","5214","5314","5414","5514","5614","5714","5814","5914"])
			AnimationArr.Push(["5115","5215","5315","5415","5515","5615","5715","5815","5915"])
			AnimationArr.Push(["5116","5216","5316","5416","5516","5616","5716","5816","5916"])
			AnimationArr.Push(["5117","5217","5317","5417","5517","5617","5717","5817","5917"])
			AnimationArr.Push(["5118","5218","5318","5418","5518","5618","5718","5818","5918"])
			AnimationArrIdx:=""
			For k,v in AnimationArr
				{
				If (AnimationPrefix v[1] = Animation)
					{
					AnimationArrIdx:=k
					Break
					}
				}
			Console.DebugLevel:=Settings.DebugLevelL
			Part2:=New PSBAM()
				Part2.LoadBAM(InDir "\" AnimationPrefix AnimationArr[AnimationArrIdx,2] ".bam")
			Part3:=New PSBAM()
				Part3.LoadBAM(InDir "\" AnimationPrefix AnimationArr[AnimationArrIdx,3] ".bam")
			Part4:=New PSBAM()
				Part4.LoadBAM(InDir "\" AnimationPrefix AnimationArr[AnimationArrIdx,4] ".bam")
			Part5:=New PSBAM()
				Part5.LoadBAM(InDir "\" AnimationPrefix AnimationArr[AnimationArrIdx,5] ".bam")
			Part6:=New PSBAM()
				Part6.LoadBAM(InDir "\" AnimationPrefix AnimationArr[AnimationArrIdx,6] ".bam")
			Part7:=New PSBAM()
				Part7.LoadBAM(InDir "\" AnimationPrefix AnimationArr[AnimationArrIdx,7] ".bam")
			Part8:=New PSBAM()
				Part8.LoadBAM(InDir "\" AnimationPrefix AnimationArr[AnimationArrIdx,8] ".bam")
			Part9:=New PSBAM()
				Part9.LoadBAM(InDir "\" AnimationPrefix AnimationArr[AnimationArrIdx,9] ".bam")
			Console.DebugLevel:=Settings.DebugLevelP
			; Dimension calculations:
			Loop, % this.Stats.CountOfCycles
				{
				Sequence:=A_Index-1
				MinCenterX:=MinCenterY:=1000000, MaxWidth:=MaxHeight:=MaxCenterX:=MaxCenterY:=CanvasWidth:=CanvasHeight:=0
				
				SzArr:=this._GetSequenceCanvasDimensions(Sequence,MinCenterX,MinCenterY,MaxWidth,MaxHeight,MaxCenterX,MaxCenterY,CanvasWidth,CanvasHeight)
				SzArr:=Part2._GetSequenceCanvasDimensions(Sequence,MinCenterX,MinCenterY,MaxWidth,MaxHeight,MaxCenterX,MaxCenterY,CanvasWidth,CanvasHeight)
				SzArr:=Part3._GetSequenceCanvasDimensions(Sequence,MinCenterX,MinCenterY,MaxWidth,MaxHeight,MaxCenterX,MaxCenterY,CanvasWidth,CanvasHeight)
				SzArr:=Part4._GetSequenceCanvasDimensions(Sequence,MinCenterX,MinCenterY,MaxWidth,MaxHeight,MaxCenterX,MaxCenterY,CanvasWidth,CanvasHeight)
				SzArr:=Part5._GetSequenceCanvasDimensions(Sequence,MinCenterX,MinCenterY,MaxWidth,MaxHeight,MaxCenterX,MaxCenterY,CanvasWidth,CanvasHeight)
				SzArr:=Part6._GetSequenceCanvasDimensions(Sequence,MinCenterX,MinCenterY,MaxWidth,MaxHeight,MaxCenterX,MaxCenterY,CanvasWidth,CanvasHeight)
				SzArr:=Part7._GetSequenceCanvasDimensions(Sequence,MinCenterX,MinCenterY,MaxWidth,MaxHeight,MaxCenterX,MaxCenterY,CanvasWidth,CanvasHeight)
				SzArr:=Part8._GetSequenceCanvasDimensions(Sequence,MinCenterX,MinCenterY,MaxWidth,MaxHeight,MaxCenterX,MaxCenterY,CanvasWidth,CanvasHeight)
				SzArr:=Part9._GetSequenceCanvasDimensions(Sequence,MinCenterX,MinCenterY,MaxWidth,MaxHeight,MaxCenterX,MaxCenterY,CanvasWidth,CanvasHeight)
				ShiftX:=(MinCenterX<0?0-MinCenterX:0), ShiftY:=(MinCenterY<0?0-MinCenterY:0)
				
				Idx:=this.CycleEntries[Sequence,"IndexIntoFLT"]
				Loop, % this.CycleEntries[Sequence,"CountOfFrameIndices"]
					{
					; Create virtual canvas
					Canvas:="", Canvas:={}, Canvas.SetCapacity(Px:=CanvasWidth*CanvasHeight)
					Loop, %Px%
						Canvas[A_Index-1]:=this.Stats.TransColorIndex
					Indexi:=A_Index-1
					;;; Part 1 (this BAM) ;;;
					Entry:=this.FrameLookupTable[Idx+Indexi]
					W:=this.FrameEntries[Entry,"Width"], H:=this.FrameEntries[Entry,"Height"]
					X:=this.FrameEntries[Entry,"CenterX"], Y:=this.FrameEntries[Entry,"CenterY"]
					FramePointer:=this.FrameEntries[Entry,"FramePointer"]
					this._Composite(this.FrameData[FramePointer],X,Y,W,H,Canvas,CanvasWidth,CanvasHeight,ShiftX,ShiftY,this.Stats.TransColorIndex)
					;;; Part 2 ;;;
					Entry:=Part2.FrameLookupTable[Idx+Indexi]
					W:=Part2.FrameEntries[Entry,"Width"], H:=Part2.FrameEntries[Entry,"Height"]
					X:=Part2.FrameEntries[Entry,"CenterX"], Y:=Part2.FrameEntries[Entry,"CenterY"]
					FramePointer:=Part2.FrameEntries[Entry,"FramePointer"]
					this._Composite(Part2.FrameData[FramePointer],X,Y,W,H,Canvas,CanvasWidth,CanvasHeight,ShiftX,ShiftY,this.Stats.TransColorIndex)
					;;; Part 3 ;;;
					Entry:=Part3.FrameLookupTable[Idx+Indexi]
					W:=Part3.FrameEntries[Entry,"Width"], H:=Part3.FrameEntries[Entry,"Height"]
					X:=Part3.FrameEntries[Entry,"CenterX"], Y:=Part3.FrameEntries[Entry,"CenterY"]
					FramePointer:=Part3.FrameEntries[Entry,"FramePointer"]
					this._Composite(Part3.FrameData[FramePointer],X,Y,W,H,Canvas,CanvasWidth,CanvasHeight,ShiftX,ShiftY,this.Stats.TransColorIndex)
					;;; Part 4 ;;;
					Entry:=Part4.FrameLookupTable[Idx+Indexi]
					W:=Part4.FrameEntries[Entry,"Width"], H:=Part4.FrameEntries[Entry,"Height"]
					X:=Part4.FrameEntries[Entry,"CenterX"], Y:=Part4.FrameEntries[Entry,"CenterY"]
					FramePointer:=Part4.FrameEntries[Entry,"FramePointer"]
					this._Composite(Part4.FrameData[FramePointer],X,Y,W,H,Canvas,CanvasWidth,CanvasHeight,ShiftX,ShiftY,this.Stats.TransColorIndex)
					;;; Part 5 ;;;
					Entry:=Part5.FrameLookupTable[Idx+Indexi]
					W:=Part5.FrameEntries[Entry,"Width"], H:=Part5.FrameEntries[Entry,"Height"]
					X:=Part5.FrameEntries[Entry,"CenterX"], Y:=Part5.FrameEntries[Entry,"CenterY"]
					FramePointer:=Part5.FrameEntries[Entry,"FramePointer"]
					this._Composite(Part5.FrameData[FramePointer],X,Y,W,H,Canvas,CanvasWidth,CanvasHeight,ShiftX,ShiftY,this.Stats.TransColorIndex)
					;;; Part 6 ;;;
					Entry:=Part6.FrameLookupTable[Idx+Indexi]
					W:=Part6.FrameEntries[Entry,"Width"], H:=Part6.FrameEntries[Entry,"Height"]
					X:=Part6.FrameEntries[Entry,"CenterX"], Y:=Part6.FrameEntries[Entry,"CenterY"]
					FramePointer:=Part6.FrameEntries[Entry,"FramePointer"]
					this._Composite(Part6.FrameData[FramePointer],X,Y,W,H,Canvas,CanvasWidth,CanvasHeight,ShiftX,ShiftY,this.Stats.TransColorIndex)
					;;; Part 7 ;;;
					Entry:=Part7.FrameLookupTable[Idx+Indexi]
					W:=Part7.FrameEntries[Entry,"Width"], H:=Part7.FrameEntries[Entry,"Height"]
					X:=Part7.FrameEntries[Entry,"CenterX"], Y:=Part7.FrameEntries[Entry,"CenterY"]
					FramePointer:=Part7.FrameEntries[Entry,"FramePointer"]
					this._Composite(Part7.FrameData[FramePointer],X,Y,W,H,Canvas,CanvasWidth,CanvasHeight,ShiftX,ShiftY,this.Stats.TransColorIndex)
					;;; Part 8 ;;;
					Entry:=Part8.FrameLookupTable[Idx+Indexi]
					W:=Part8.FrameEntries[Entry,"Width"], H:=Part8.FrameEntries[Entry,"Height"]
					X:=Part8.FrameEntries[Entry,"CenterX"], Y:=Part8.FrameEntries[Entry,"CenterY"]
					FramePointer:=Part8.FrameEntries[Entry,"FramePointer"]
					this._Composite(Part8.FrameData[FramePointer],X,Y,W,H,Canvas,CanvasWidth,CanvasHeight,ShiftX,ShiftY,this.Stats.TransColorIndex)
					;;; Part 9 ;;;
					Entry:=Part9.FrameLookupTable[Idx+Indexi]
					W:=Part9.FrameEntries[Entry,"Width"], H:=Part9.FrameEntries[Entry,"Height"]
					X:=Part9.FrameEntries[Entry,"CenterX"], Y:=Part9.FrameEntries[Entry,"CenterY"]
					FramePointer:=Part9.FrameEntries[Entry,"FramePointer"]
					this._Composite(Part9.FrameData[FramePointer],X,Y,W,H,Canvas,CanvasWidth,CanvasHeight,ShiftX,ShiftY,this.Stats.TransColorIndex)
					;;; Set Canvas to Frame ;;;
					Entry:=this.FrameLookupTable[Idx+Indexi]
					FramePointer:=this.FrameEntries[Entry,"FramePointer"]
					this.FrameData[FramePointer]:=Canvas
					this.FrameEntries[Entry,"Width"]:=CanvasWidth
					this.FrameEntries[Entry,"Height"]:=CanvasHeight
					this.FrameEntries[Entry,"CenterX"]:=ShiftX
					this.FrameEntries[Entry,"CenterY"]:=ShiftY
					;this.FrameEntries[Entry,"FramePointer"]:=FramePointer
					this.FrameEntries[Entry,"RLE"]:=0
					}
				}
			Part2:=""
			Part3:=""
			Part4:=""
			Part5:=""
			Part6:=""
			Part7:=""
			Part8:=""
			Part9:=""
			this._UpdateStats()
			}
		Else If InStr(Settings.Montage,"x") ;(Settings.Montage="1x2")	; (rows x columns)
			{
			tmp:=StrSplit(Settings.Montage,"x")
			Rows:=tmp[1], Columns:=tmp[2]
			Columns+=0 ; Truncate anything not a number
			Count:=Rows*Columns
			Count:=(Count>this.Stats.CountOfCycles?this.Stats.CountOfCycles:Count)
			;;; Recalculate Offsets ;;;
			If InStr(Settings.Montage,"IgnoreOffsets")
				{
				Row:=Column:=0
				Sequence:=-1
				Loop, % this.Stats.CountOfCycles
					{
					Sequence+=1
					If (Sequence=0)
						{
						Column+=1
						If (Column>Columns-1)
							Row+=1, Column:=0
						Continue
						}
					Idx:=this.CycleEntries[Sequence,"IndexIntoFLT"]
					Loop, % this.CycleEntries[Sequence,"CountOfFrameIndices"]
						{
						Indexi:=A_Index-1
						Entry:=this.FrameLookupTable[Idx+Indexi]
						; Get Previous ;
						If (Column=0) ; Just started a new row
							{
							Idx0:=this.CycleEntries[Sequence-Columns,"IndexIntoFLT"]
							Entry0:=this.FrameLookupTable[Idx0+Indexi]
							this.FrameEntries[Entry,"CenterX"]:=this.FrameEntries[Entry0,"CenterX"]+(this.FrameEntries[Entry,"Width"]-this.FrameEntries[Entry0,"Width"]), this.FrameEntries[Entry,"CenterY"]:=-(this.FrameEntries[Entry0,"Height"])+this.FrameEntries[Entry0,"CenterY"]
							;If (Row=1)
							;	this.FrameEntries[Entry,"CenterX"]+=10
							;If (Row=2)
							;	this.FrameEntries[Entry,"CenterX"]+=4
							}
						Else ; Use previous sequence
							{
							Idx0:=this.CycleEntries[Sequence-1,"IndexIntoFLT"]
							Entry0:=this.FrameLookupTable[Idx0+Indexi]
							this.FrameEntries[Entry,"CenterX"]:=-(this.FrameEntries[Entry0,"Width"])+this.FrameEntries[Entry0,"CenterX"] ; Was this.FrameEntries[Entry,"CenterY"]:=this.FrameEntries[Entry0,"CenterY"]+(this.FrameEntries[Entry,"Height"]-this.FrameEntries[Entry0,"Height"])
							If (Row=0)
								this.FrameEntries[Entry,"CenterY"]:=this.FrameEntries[Entry0,"CenterY"]+(this.FrameEntries[Entry,"Height"]-this.FrameEntries[Entry0,"Height"]) 
							Else
								this.FrameEntries[Entry,"CenterY"]:=this.FrameEntries[Entry0,"CenterY"] ;+(this.FrameEntries[Entry,"Height"]-this.FrameEntries[Entry0,"Height"]) 
							;this.FrameEntries[Entry,"CenterY"]+=7
							;this.FrameEntries[Entry0,"Width"]
							;this.FrameEntries[Entry0,"Height"]
							;this.FrameEntries[Entry0,"CenterX"]
							;this.FrameEntries[Entry0,"CenterY"]
							}
						}
					Column+=1
					If (Column>Columns-1)
						Row+=1, Column:=0
					If (Row=Rows) ; Starting on Next Set
						{
						Sequence+=1
						Row:=Column:=0
						Column+=1
						If (Column>Columns-1)
							Row+=1, Column:=0
						}
					}
				}
			;;; Dimension calculations ;;;
			Loop, % Ceil(this.Stats.CountOfCycles/Count)
				{
				StartSequence:=(A_Index-1)*Count
				MinCenterX:=MinCenterY:=1000000, MaxWidth:=MaxHeight:=MaxCenterX:=MaxCenterY:=CanvasWidth:=CanvasHeight:=0
				Loop, % Count
					{
					Sequence:=StartSequence+A_Index-1
					SzArr:=this._GetSequenceCanvasDimensions(Sequence,MinCenterX,MinCenterY,MaxWidth,MaxHeight,MaxCenterX,MaxCenterY,CanvasWidth,CanvasHeight)
					ShiftX:=(MinCenterX<0?0-MinCenterX:0), ShiftY:=(MinCenterY<0?0-MinCenterY:0)
					}
				;Sequence:=0
				Idx:=this.CycleEntries[StartSequence,"IndexIntoFLT"]
				Loop, % this.CycleEntries[StartSequence,"CountOfFrameIndices"]
					{
					Indexi:=A_Index-1
					;;; Create virtual canvas ;;;
					Canvas:="", Canvas:={}, Canvas.SetCapacity(Px:=CanvasWidth*CanvasHeight)
					Loop, %Px%
						Canvas[A_Index-1]:=this.Stats.TransColorIndex
					Loop, % Count
						{
						Sequence:=StartSequence+A_Index-1, Entry:=this.FrameLookupTable[(this.CycleEntries[Sequence,"IndexIntoFLT"])+Indexi]
						W:=this.FrameEntries[Entry,"Width"], H:=this.FrameEntries[Entry,"Height"]
						X:=this.FrameEntries[Entry,"CenterX"], Y:=this.FrameEntries[Entry,"CenterY"]
						FramePointer:=this.FrameEntries[Entry,"FramePointer"]
						this._Composite(this.FrameData[FramePointer],X,Y,W,H,Canvas,CanvasWidth,CanvasHeight,ShiftX,ShiftY,this.Stats.TransColorIndex)
						If (Sequence>StartSequence)
							this._SetFrame1Trans(FramePointer,Entry)
						}
					;;; Set Canvas to Frame ;;;
					Entry:=this.FrameLookupTable[Idx+Indexi]
					FramePointer:=this.FrameEntries[Entry,"FramePointer"]
					this.FrameData[FramePointer]:=Canvas
					this.FrameEntries[Entry,"Width"]:=CanvasWidth
					this.FrameEntries[Entry,"Height"]:=CanvasHeight
					this.FrameEntries[Entry,"CenterX"]:=ShiftX
					this.FrameEntries[Entry,"CenterY"]:=ShiftY
					this.FrameEntries[Entry,"RLE"]:=0
					}
				}
			}
		Else If InStr(Settings.Montage,"DescriptionIcon")
			{
			;;; Recalculate Offsets ;;;
			If InStr(Settings.Montage,"IgnoreOffsets")
				this._SetBAMProfile("DescriptionIcon")
			;;; Dimension calculations ;;;
			MinCenterX:=MinCenterY:=1000000, MaxWidth:=MaxHeight:=MaxCenterX:=MaxCenterY:=CanvasWidth:=CanvasHeight:=0
			Loop, % this.Stats.CountOfCycles
				{
				Sequence:=A_Index-1
				SzArr:=this._GetSequenceCanvasDimensions(Sequence,MinCenterX,MinCenterY,MaxWidth,MaxHeight,MaxCenterX,MaxCenterY,CanvasWidth,CanvasHeight)
				ShiftX:=(MinCenterX<0?0-MinCenterX:0), ShiftY:=(MinCenterY<0?0-MinCenterY:0)
				}
			;;; Create virtual canvas ;;;
			Canvas:="", Canvas:={}, Canvas.SetCapacity(Px:=CanvasWidth*CanvasHeight)
			Loop, %Px%
				Canvas[A_Index-1]:=this.Stats.TransColorIndex
			;;; Add all frames to canvas ;;;
			Loop, % this.Stats.CountOfCycles
				{
				Sequence:=A_Index-1
				Idx:=this.CycleEntries[Sequence,"IndexIntoFLT"]
					Loop, % this.CycleEntries[Sequence,"CountOfFrameIndices"]
						{
						Indexi:=A_Index-1
						Entry:=this.FrameLookupTable[Idx+Indexi]
						W:=this.FrameEntries[Entry,"Width"], H:=this.FrameEntries[Entry,"Height"]
						X:=this.FrameEntries[Entry,"CenterX"], Y:=this.FrameEntries[Entry,"CenterY"]
						FramePointer:=this.FrameEntries[Entry,"FramePointer"]
						this._Composite(this.FrameData[FramePointer],X,Y,W,H,Canvas,CanvasWidth,CanvasHeight,ShiftX,ShiftY,this.Stats.TransColorIndex)
						}
				}
			;;; Set Canvas to Frame ;;;
			; Clear all FrameData and FrameEntries ;
			this.FrameData:="", this.FrameData:={}, this.FrameEntries:="", this.FrameEntries:={}, this.FrameLookupTable:="", this.FrameLookupTable:={}, this.CycleEntries:="", this.CycleEntries:={}
			; Save composited frame back into BAM ;
			this.FrameData[0]:=Canvas
			this.FrameEntries[0,"Width"]:=CanvasWidth
			this.FrameEntries[0,"Height"]:=CanvasHeight
			this.FrameEntries[0,"CenterX"]:=CanvasWidth//2
			this.FrameEntries[0,"CenterY"]:=CanvasHeight//2
			this.FrameEntries[0,"FramePointer"]:=0
			this.FrameEntries[0,"RLE"]:=0
			this.FrameLookupTable[0]:=0
			this.CycleEntries[0,"CountOfFrameIndices"]:=1, this.CycleEntries[0,"IndexIntoFLT"]:=0
			}
		this._UpdateStats()
		Console.Send("Montaged Frames in " (QPC(1)-tic) " sec.`r`n","-I")
	}
	_ModXOffset(Val:=""){
		If (Val="")
			Val:=Settings.ModXOffset
		Console.Send((Val<0?"Dec":"Inc") "rementing X-Offsets by " Val "`r`n","I")
		Loop, % this.Stats.CountOfFrameEntries
			this.FrameEntries[A_Index-1,"CenterX"]+=Val
	}
	_ModYOffset(Val:=""){
		If (Val="")
			Val:=Settings.ModYOffset
		Console.Send((Val<0?"Dec":"Inc") "rementing Y-Offsets by " Val "`r`n","I")
		Loop, % this.Stats.CountOfFrameEntries
			this.FrameEntries[A_Index-1,"CenterY"]+=Val
	}
	_SetXOffset(Val:=""){
		If (Val="")
			Val:=Settings.SetXOffset
		Console.Send("Setting X-Offsets to " Val "`r`n","I")
		Loop, % this.Stats.CountOfFrameEntries
			this.FrameEntries[A_Index-1,"CenterX"]:=Val
	}
	_SetYOffset(Val:=""){
		If (Val="")
			Val:=Settings.SetYOffset
		Console.Send("Setting Y-Offsets to " Val "`r`n","I")
		Loop, % this.Stats.CountOfFrameEntries
			this.FrameEntries[A_Index-1,"CenterY"]:=Val
	}
	_Flip(){
		Loop, % this.Stats.CountOfFrames
			{
			Index:=A_Index-1
			Entry:=this._GetFrameData1stFrameEntry(Index)
			Width:=this.FrameEntries[Entry,"Width"], Height:=this.FrameEntries[Entry,"Height"]
			NewFrameobj:={}, NewFrameObj.SetCapacity(this.FrameData[Index].Count())
			Loop, % Abs(Height)
				{
				Idx:=A_Index-1, Line:={}
				Loop, %Width%
					Line.Push(this.FrameData[Index,A_Index-1+Idx*Width])
				NewFrameObj.InsertAt(0,Line*)
				}
			this.FrameData[Index]:=NewFrameObj
			}
	}
	_Flop(){
		Loop, % this.Stats.CountOfFrames
			{
			Index:=A_Index-1
			Entry:=this._GetFrameData1stFrameEntry(Index)
			Width:=this.FrameEntries[Entry,"Width"], Height:=this.FrameEntries[Entry,"Height"]
			NewFrameobj:={}, NewFrameObj.SetCapacity(this.FrameData[Index].Count())
			Loop, % Abs(Height)
				{
				Idx:=A_Index-1, Line:={}
				Loop, %Width%
					Line.InsertAt(1,this.FrameData[Index,A_Index-1+Idx*Width])
				NewFrameObj.InsertAt(NewFrameObj.Count(),Line*)
				}
			this.FrameData[Index]:=NewFrameObj
			}
	}
	_Rotate(){
		Histo:=""
		Loop, % this.Stats.CountOfFrames
			{
			FrameNum:=A_Index-1
			Console.Send("Rotating Frame " FrameNum " by " Settings.Rotate " deg.`r`n","I")
			Entry:=this._GetFrameData1stFrameEntry(FrameNum)
			Width:=this.FrameEntries[Entry,"Width"], Height:=this.FrameEntries[Entry,"Height"]
			BMP:=New PSBMP()
			BMP.LoadBMPFromFrameObj(this.FrameData[FrameNum],this.Palette,"",Width,Height)
			BMP.TransformTransparency(0,255)
			Raw:=""
			Sz:=BMP.SaveBMPToVar(Raw,32,5)
			
			;;; GDI ;;;
			pBitmap:=GDIPlus_pBitmapFromBuffer(Raw,Sz)
			w:=h:=0
			Gdip_GetImageDimensions(pBitmap,w,h)
			Gdip_GetRotatedDimensions(w,h,Settings.Rotate,rw,rh)
			rw:=(rw>w?rw:w), rh:=(rh>h?rh:h)
			hbm:=CreateDIBSection(rw,rh), hdc:=CreateCompatibleDC(), obm:=SelectObject(hdc,hbm), G:=Gdip_GraphicsFromHDC(hdc)
			Gdip_GraphicsClear(G,Gdip_ToARGB((this.Palette[this.Stats.TransColorIndex,"AA"]=0?255:this.Palette[this.Stats.TransColorIndex,"AA"]),this.Palette[this.Stats.TransColorIndex,"RR"],this.Palette[this.Stats.TransColorIndex,"GG"],this.Palette[this.Stats.TransColorIndex,"BB"]))
			Gdip_TranslateWorldTransform(G,rw//2,rh//2)
			Gdip_RotateWorldTransform(G,Settings.Rotate)
			Gdip_TranslateWorldTransform(G,-rw//2,-rh//2)
			Gdip_DrawImage(G,pBitmap,(rw-w)//2,(rh-h)//2,w,h)
			
			; new 'canvas' 
			pBitmapRotated:=Gdip_CreateBitmap(rw,rh)
			pGraphicsRotated:=Gdip_GraphicsFromImage(pBitmapRotated)
			Gdip_GraphicsClear(pGraphicsRotated,Gdip_ToARGB((this.Palette[this.Stats.TransColorIndex,"AA"]=0?255:this.Palette[this.Stats.TransColorIndex,"AA"]),this.Palette[this.Stats.TransColorIndex,"RR"],this.Palette[this.Stats.TransColorIndex,"GG"],this.Palette[this.Stats.TransColorIndex,"BB"]))
			Gdip_SetInterpolationMode(pGraphicsRotated,5)
			
			; reapply tranformations and save it
			Gdip_TranslateWorldTransform(pGraphicsRotated,rw//2,rh//2)
			Gdip_RotateWorldTransform(pGraphicsRotated,Settings.Rotate)
			Gdip_TranslateWorldTransform(pGraphicsRotated,-rw//2,-rh//2)
			Gdip_DrawImage(pGraphicsRotated,pBitmap,(rw-w)//2,(rh-h)//2,w,h)
			
			Width:=this.FrameEntries[Entry,"Width"]:=Gdip_GetImageWidth(pBitmapRotated)
			Height:=this.FrameEntries[Entry,"Height"]:=Gdip_GetImageHeight(pBitmapRotated)
			FrameUP:={}, FrameUP.SetCapacity(Width*Height)
			Index:=A:=R:=G:=B:=0
			Loop, % Abs(Height)
				{
				Idx:=A_Index-1
				Loop, %Width%
					{
					ARGB:=Gdip_GetPixel(pBitmapRotated,A_Index-1,Idx)
					Gdip_FromARGB(ARGB,A,R,G,B)
					FrameUP[Index,"RR"]:=R
					FrameUP[Index,"GG"]:=G
					FrameUP[Index,"BB"]:=B
					A:=(A=255?0:A)
					FrameUP[Index,"AA"]:=A
					Index++
					}
				}
			SelectObject(hdc,obm)
			DeleteObject(hbm)
			DeleteDC(hdc)
			Gdip_DeleteGraphics(pGraphicsRotated)
			;~ Gdip_DeleteGraphics(G)	; Don't know why this throws an exception, but commented out.
			Gdip_DisposeImage(pBitmap)
			;;; end GDI ;;;
			this.FrameData[FrameNum]:=this._ConvertFrameToPaletted(FrameUP,this.Palette,Histo)	; Does not quantize!
			}
	}
}

class DebugBAM{
	PrintBAM(){
		this.PrintStats()
		this.PrintFrameEntries()
		this.PrintCycleEntries()
		this.PrintPalette()
		this.PrintFrameLookupTable()
		this.PrintFrameData()
		If this.HasKey("DataBlocks")
			this.PrintDataBlocks()
	}
	PrintStats(){
		Msg:="[Stats]`r`n"
		For key,val in this.Stats
			Msg.="  "  key " = " val "`r`n"
		Console.Send(Msg "`r`n")
	}
	PrintFrameEntries(){
		Msg:="[Frame Entries]`r`n"
		Msg.="  " FormatStr("FrameEntry",A_Space,11,"C") FormatStr("FramePointer",A_Space,13,"C") FormatStr("Width",A_Space,8,"C") FormatStr("Height",A_Space,8,"C") FormatStr("PixelCount",A_Space,11,"C") FormatStr("CenterX",A_Space,8,"C") FormatStr("CenterY",A_Space,8,"C") FormatStr("RLE",A_Space,4,"C") RTrim(FormatStr("OffsetToFrameData",A_Space,17,"C"),A_Space) "`r`n"
		For key,val in this.FrameEntries
			Msg.="  " FormatStr(key,A_Space,11,"C") FormatStr(this.FrameEntries[key,"FramePointer"],A_Space,13,"C") FormatStr(this.FrameEntries[key,"Width"],A_Space,8,"C") FormatStr(this.FrameEntries[key,"Height"],A_Space,8,"C") FormatStr(this.FrameEntries[key,"Width"]*this.FrameEntries[key,"Height"],A_Space,11,"C") FormatStr(this.FrameEntries[key,"CenterX"],A_Space,8,"C") FormatStr(this.FrameEntries[key,"CenterY"],A_Space,8,"C") FormatStr(this.FrameEntries[key,"RLE"],A_Space,4,"C") RTrim(FormatStr(this.FrameEntries[key,"OffsetToFrameData"],A_Space,17,"C")) "`r`n"
		Console.Send(Msg "`r`n","")
	}
	PrintCycleEntries(){
		Msg:="[Cycle Entries]`r`n"
		Msg.="  " FormatStr("CycleEntry",A_Space,11,"C") FormatStr("CountOfFrameIndices",A_Space,20,"C") RTrim(FormatStr("IndexIntoFLT",A_Space,13,"C"),A_Space) "`r`n"
		For key,val in this.CycleEntries
			Msg.="  " FormatStr(key,A_Space,11,"C") FormatStr(this.CycleEntries[key,"CountOfFrameIndices"],A_Space,20,"C") RTrim(FormatStr(this.CycleEntries[key,"IndexIntoFLT"],A_Space,13,"C"),A_Space) "`r`n"
		Console.Send(Msg "`r`n")
	}
	PrintPalette(PalObj:=""){
		If !IsObject(PalObj)	; Print the BAM Palette
			PalObj:=this.Palette
		Msg:="[Palette]`r`n"
		Msg.="  PaletteEntry " FormatStr("#",A_Space,3,"R") ": " FormatStr("BB",A_Space,3,"R") " " FormatStr("GG",A_Space,3,"R") " " FormatStr("RR",A_Space,3,"R") " " FormatStr("AA",A_Space,3,"R") "`r`n" "  ---------------------------------`r`n"
		For key,val in PalObj
			Msg.="  PaletteEntry " FormatStr(key,A_Space,3,"R") ": " FormatStr(PalObj[key,"BB"],A_Space,3,"R") " " FormatStr(PalObj[key,"GG"],A_Space,3,"R") " " FormatStr(PalObj[key,"RR"],A_Space,3,"R") " " FormatStr(PalObj[key,"AA"],A_Space,3,"R") "`r`n"
		Console.Send(Msg "`r`n")
	}
	PrintFrameLookupTable(){
		Msg:="[Frame Lookup Table]`r`n"
		Msg.="  "
		For key,val in this.FrameLookupTable
			Msg.=FormatStr(val,A_Space,3,"R") " "
		Console.Send(Msg "`r`n`r`n")
	}
	PrintFrameData(Frm:="",Width:=""){
		If (Frm="")	; Print all frames in BAM
			{
			Msg:="[Frame Data]`r`n"
			For key,val in this.FrameData
				{
				Width:=this.FrameEntries[this._GetFrameData1stFrameEntry(key),"Width"], EndOfRow:=0
				Msg.="  [Frame " key "]`r`n"
				For k2,v2 in val
					{
					Msg.=(EndOfRow=0?"    ":"") FormatStr(v2,A_Space,3,"R") " "
					EndOfRow++
					If (EndOfRow=Width)
						Msg.="`r`n", EndOfRow:=0
					}
				}
			Console.Send(Msg "`r`n")
			}
		Else If IsObject(Frm)	; Print FrameObj
			{
			Width:=(!Width?Frm.Count():Width)
			Msg:="[Frame Data]`r`n"
			EndOfRow:=0
			Msg.="  [Frame 0]`r`n"
			For k2,v2 in Frm
				{
				Msg.=(EndOfRow=0?"    ":"") FormatStr(v2,A_Space,3,"R") " "
				EndOfRow++
				If (EndOfRow=Width)
					Msg.="`r`n", EndOfRow:=0
				}
			Console.Send(Msg "`r`n")
			}
		Else	; Print Frame# specified by the integer Frm
			{
			Msg:="[Frame Data]`r`n"
			Width:=(!Width?this.FrameEntries[this._GetFrameData1stFrameEntry(key),"Width"]:Width), EndOfRow:=0
			Msg.="  [Frame " Frm "]`r`n"
			For k2,v2 in this.FrameData[Frm]
				{
				Msg.=(EndOfRow=0?"    ":"") FormatStr(v2,A_Space,3,"R") " "
				EndOfRow++
				If (EndOfRow=Width)
					Msg.="`r`n", EndOfRow:=0
				}
			Console.Send(Msg "`r`n")
			}
	}
	PrintDataBlocks(){
		Msg:="[Data Blocks]`r`n"
		Msg.="  " FormatStr("DataBlock",A_Space,10,"C") FormatStr("PVRZpage",A_Space,9,"C") FormatStr("PVRZFile",A_Space,13,"C") FormatStr("SourceX",A_Space,8,"C") FormatStr("SourceY",A_Space,8,"C") FormatStr("Width",A_Space,6,"C") FormatStr("Height",A_Space,7,"C") FormatStr("TargetX",A_Space,8,"C") RTrim(FormatStr("TargetY",A_Space,8,"C"),A_Space) "`r`n"
		Loop, % this.Stats.CountOfDataBlocks
			{
			Index:=A_Index-1
			Msg.="  " FormatStr(Index,A_Space,10,"C")
			Msg.=FormatStr(this.DataBlocks[Index,"PVRZpage"],A_Space,9,"C")
			Msg.=FormatStr(this.DataBlocks[Index,"PVRZFile"],A_Space,13,"C")
			Msg.=FormatStr(this.DataBlocks[Index,"SourceX"],A_Space,8,"C")
			Msg.=FormatStr(this.DataBlocks[Index,"SourceY"],A_Space,8,"C")
			Msg.=FormatStr(this.DataBlocks[Index,"Width"],A_Space,6,"C")
			Msg.=FormatStr(this.DataBlocks[Index,"Height"],A_Space,7,"C")
			Msg.=FormatStr(this.DataBlocks[Index,"TargetX"],A_Space,8,"C")
			Msg.=FormatStr(this.DataBlocks[Index,"TargetY"],A_Space,8,"C") "`r`n"
			}
		Console.Send(Msg "`r`n")
	}
}

SetSettings(){
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;;;;    Global Settings   ;;;;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	Settings.OutPath:=A_ScriptDir "\compressed" ; Because Windows is stupid, OutPath must NOT end in a "\" when passed to PS BAM as a parameter.
	;~ Settings.OutPathSpecific:=""
	Settings.DebugLevelL:=1
	Settings.DebugLevelP:=2
	Settings.DebugLevelS:=1
	Settings.LogFile:=""
	Settings.VerifyOutput:=0
	;Settings.MaxThreads:=4
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;;;;     IO Settings      ;;;;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	Settings.Save:="BAM"				; | BAM | BAMD | GIF |	; (BAMD takes frame filetype from Settings.ExportFrames)
	;Settings.Compress:=1				; Depreciated
	Settings.ExportPalette:=""			; | ACT | ALL | Bin | BMP | BMPV | PAL | Raw |
	Settings.ExportFrames:=""			; | BMP | DIB | GIF | JFIF | JPE | JPEG | JPG | PNG | RLE | TIF | TIFF || BMP,8V3 | BMP,24V3 | BMP,32V5 |
	Settings.ExportFramesAsSequences:=0
	;~ Settings.CompressFirst:=1		; Depreciated
	;~ Settings.ProcessFirst:=0			; Depreciated
	Settings.OrderOfOperations:="PCE"	; P = Process; C = Compress; E = Export; in any order.  e.g. | CPE | CEP | PCE | PEC | EPC | ECP |
	Settings.SingleGIF:=0
	Settings.ReplacePalette:=""
	Settings.ReplacePaletteMethod:="Quant"	; | Force | Remap | Quant
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;;;; Compression Settings ;;;;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	Settings.CompressionProfile:=""				; | Max | Recommended | Safe | Quick | Fast | None |	; (is position dependent!!!)
	Settings.FixPaletteColorErrors:=1
	Settings.AutodetectPalettedBAM:=0
	Settings.AutodetectPalettedThreshold:=500	; 14100 will identify vanilla off-paletted palettes as paletted.  500 will identify BW1 palette colors as paletted.
	Settings.DropDuplicatePaletteEntries:=0
	Settings.DropUnusedPaletteEntries:=0		; | 0=OFF | 1=ON | 2=only from end |
	Settings.SearchTransColor:=1				; BG1/PST TransColor might not be palette entry 0 (so you should search)
	Settings.ForceTransColor:=0
	Settings.ForceShadowColor:=0				; 0=None | 1=Force | 2=Move | 3=Insert (move will insert if fails) | -1=Ensure No Shadow color
	Settings.AlphaCutoff:=0 ;10
	Settings.AllowShortPalette:=0
	
	Settings.TrimFrameData:=0
		Settings.ExtraTrimBuffer:=2		; 2
		Settings.ExtraTrimDepth:=3		; 3
		Settings.ReduceFrameRowLT:=0
		Settings.ReduceFrameColumnLT:=0
		Settings.ReduceFramePixelLT:=0
	Settings.DropDuplicateFrameData:=0
	Settings.DropUnusedFrameData:=0
	Settings.IntelligentRLE:=0
		Settings.MaxRLERun:=254			; if 255 do so intelligently (only if it saves space) ; 255 causes issues with BAMWorkshop 1
		Settings.FindBestRLEIndex:=0	; May cause issues with EE engine games
	
	Settings.DropDuplicateFrameEntries:=0
	Settings.DropUnusedFrameEntries:=0	; Can cause issues with BAMWorkshop II if used alone.
	
	Settings.AdvancedFLTCompression:=0
		Settings.FLTSanityCutoff:=720	; | 5!=120 | 6!=720 | 7!=5,040 | 8!=40,320 | 9!=362,880 | 10!=3,628,800 | 11!=39,916,800 |
	
	Settings.DropEmptyCycleEntries:=0
	
	Settings.AdvancedZlibCompress:=0	; | 0=None | 1=Zlib | 2=zopfli |	; BG1/PST can't handle BAMC
		Settings.zopfliIterations:=500	; 1000000
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;;;; Additional Processing Settings ;;;;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	Settings.BAMProfile:=""				; | ItemIcon | DescriptionIcon | Zero | Paperdoll | SpellIconEE | GroundIcon | DescriptionIconEE | ItemIconPST | GroundIconPST | SpellIcon | Spell |
	Settings.Unify:=0					; | 0=Off | 1=On | 2=Square |
	Settings.Fill:=""					; widthXheight,orientation		Note:  EITHER width or height may be zero, indicating no change.  orientation may be any of:  | NorthWest | TopLeft | NorthEast | TopRight | SouthWest | BottomLeft | SouthEast | BottomRight | North | Top | East | Right | South | Bottom | West | Left |
	;Settings.UnifyTransFrameAlt		; Not implemented.  Could be used to toggle "this._IsFrameTrans()" in Unify.
	Settings.Montage:=""
	Settings.ModXOffset:=0
	Settings.ModYOffset:=0
	Settings.SetXOffset:=""
	Settings.SetYOffset:=""
	Settings.ItemIcon2EE:=0
	Settings.Flip:=0
	Settings.Flop:=0
	Settings.Rotate:=0
}



;;;;; Core Background Functions ;;;;;

;~ ThrowMsg(Options="",Title="",Text="",Timeout=""){
	;~ If (Title="") AND (Text="") AND (Timeout=""){
		;~ Gui +OwnDialogs
		;~ MsgBox % Options
		;~ }
	;~ Else{
		;~ Gui +OwnDialogs
		;~ MsgBox, % Options , % Title , % Text , % Timeout
		;~ }
;~ }

QPC(R:=0){ ; By SKAN, http://goo.gl/nf7O4G, CD:01/Sep/2014 | MD:01/Sep/2014
  Static P:=0, F:=0, Q:=DllCall("QueryPerformanceFrequency","Int64P",F)
  Return !DllCall("QueryPerformanceCounter","Int64P",Q)+(R?(P:=Q)/F:(Q-P)/F) 
}

;~ GetKeyCount(Arr){
	;~ If IsObject(Arr)
		;~ Return NumGet(&Arr+4*A_PtrSize)
	;~ Return 0
;~ }

;~ Num2Bin(n,bits=0) {     ; Return LS "bits" of binary representation of "n"
   ;~ b:=""
   ;~ IfLess bits,1, Loop  ; n < 0: leading 1's are omitted. -1 -> 1, 0 -> 0
      ;~ {
         ;~ b := n&1 b
         ;~ n := n>>1
         ;~ If (n = n>>1)
            ;~ Break
      ;~ }
   ;~ Else Loop %bits%
      ;~ {
         ;~ b := n&1 b
         ;~ n := n>>1
      ;~ }
   ;~ Return b
;~ }

;~ Bin2Num(bits,neg="") {  ; Return number converted from the binary "bits" string
   ;~ n = 0                ; If "neg" is not 0 or empty, 11..1 assumed on the left
   ;~ Loop Parse, bits
      ;~ n += n + A_LoopField
   ;~ Return n - !(neg<1)*(1<<StrLen(bits))
;~ }

;~ GetBits(num,start:=0,count:=1,bits:=8){
	;~ bits:=Num2Bin(num,bits)
	;~ rbits:=SubStr(bits,start+1,count)
	;~ Return Bin2Num(rbits)
;~ }

;~ PackByte(Size,Bits*){
	;~ tmp:=""
	;~ For k,v in Bits
		;~ tmp.=Num2Bin(v,(Size[k]=""?1:Size[k]))
	;~ Return Bin2Num(tmp)
;~ }

;~ String2Array(Str){
	;~ Arr:=StrSplit(Str)
	;~ For k,v in Arr
		;~ Arr[k]:=Asc(v)
	;~ Return Arr
;~ }

;~ strI(str){ ; https://github.com/Masonjar13/AHK-Library/blob/master/Lib/strI.ahk
    ;~ VarSetCapacity(nStr,sLen:=strLen(str))
    ;~ Loop, %sLen%
        ;~ nStr.=SubStr(str,sLen--,1)
    ;~ Return nStr
;~ }

st_printArr(array, depth=5, indentLevel=""){
	list:=""
   for k,v in Array
   {
      list.= indentLevel "[" k "]"
      if (IsObject(v) && depth>1)
         list.="`r`n" st_printArr(v, depth-1, indentLevel . "    ")
      Else
         list.=" => " v
      list.="`r`n"
   }
   return rtrim(list)
}

;~ ObjFullyClone(obj){	; https://autohotkey.com/board/topic/103411-cloned-object-modifying-original-instantiation/?p=638500
    ;~ nobj:=ObjClone(obj)
    ;~ For k,v in nobj
        ;~ If IsObject(v)
            ;~ nobj[k]:=ObjFullyClone(v)
    ;~ Return nobj
;~ }

FormatStr(String:="",Filler:="",Length:=0,Justify:="R"){
	tmp:=""
	Loop, % Length
		tmp.=Filler
	If (Justify="R")
		Return SubStr(tmp String,(Length-1)*-1)
	Else If (Justify="C")
		Return (StrLen(String)>=Length?SubStr(String tmp,1,Length):SubStr(SubStr(tmp,1,(Length-StrLen(String))//2) String tmp,1,Length))
	Else ;If (Justify="L")
		Return SubStr(String tmp,1,Length)
}

ArrayEqualsArray(ByRef Array1,ByRef Array2){
	If ((Length1:=Array1.Count())<>Array2.Count())
		Return 0
	Loop, %Length1%
		If (Array1[A_Index]<>Array2[A_Index])
			Return 0
	Return 1
}
ArrayDropDuplicates(ByRef Array){	; Drop arrays contained within other arrays.
	Dropped:=0, Offset:=1
	Loop, % (Len:=Array.Count())
		{
		If (Offset>Len)
			Break
		Loop, %Len%
			If (A_Index<>Offset) AND ArrayContainsArray(Array[A_Index],Array[Offset])
				Dropped+=Array.RemoveAt(Offset,1)
		If !Dropped
			Offset++
		Else
			Dropped:=0
		}
}
ArrayHasCommonValue(ByRef Array1,ByRef Array2){ ; array must be a Simple, linear or non-linear array -- keys are integers
	If !(Len1:=Array1.Count()) OR !(Len2:=Array2.Count()) ; Either array has no keys
		Return 0
	If (Len1<Len2)
		Short:=Array1, Long:=Array2
	Else
		Long:=Array1, Short:=Array2
	For key1, val1 in Short
		For key2, val2 in Long
			If (val1=val2)
				Return 1
	Return 0
}
ShiftArray(Arr){  ; Converts a <1-based linear array to 1-based
	While Arr.MinIndex()<1
		I:=Arr.MinIndex(), Arr.InsertAt(I,""), Arr.Delete(I)
	Return Arr
}
GetSubArray(ByRef Array,Start,Count,Origin){ ; ORIGIN = start key of output array
	Start:=(Start=""?Array.MinIndex():Start), Count:=(Count=""?Array.MaxIndex()-Start+1:Count)
	Origin:=(Origin=""?Array.MinIndex():Origin), OutArray:={}, OutArray.SetCapacity(Count)
	Loop, % Count
		OutArray[Origin+A_Index-1]:=Array[Start+A_Index-1]
	Return OutArray
}
ArrayContainsArray(ByRef Haystack,Byref Needle){ ; Returns blank if not found, otherwise key representing starting Pos of Needle within Haystack
	LengthH:=Haystack.Count(), LengthN:=Needle.Count()
	If (LengthN>LengthH) OR !LengthH OR !LengthN	; Haystack can't contain Needle if Needle is longer
		Return
	Loop, %LengthH%
		{
		HIndex:=A_Index, NIndex:=1
		While (Haystack[HIndex]=Needle[NIndex])
			{
			If (NIndex=LengthN)
				Return (HIndex-LengthN+1)
			NIndex++, HIndex++
			}
		}
	Return
	}
CombineArrays(ByRef Array1, ByRef Array2){
	Output:={}
	Length1:=Array1.Length(), Length2:=Array2.Length()
	If !Length1
		Return Array2
	If !Length2
		Return Array1
	Output.Push(Array1*)
	Output.Push(Array2*)
	;~ If !ArrayHasCommonValue(Array1,Array2)	; No Overlap (already separated out at this point)
		;~ Return Output
	If ArrayContainsArray(Array1,Array2)	; Full Overlaps
		Return Array1
	If ArrayContainsArray(Array2,Array1)	; Full Overlaps
		Return Array2
	Loop, % (Length1<Length2?Length1:Length2)	; Begin Possible Overlaps
		{
		Sub1L:=GetSubArray(Array1,Length1-A_Index+1,A_Index,1)
		Sub2F:=GetSubArray(Array2,1,A_Index,1)
		If ArrayEqualsArray(Sub1L,Sub2F)
			{
			Output:="", Output:={}
			Output.Push(Array1*)
			Output.Push(GetSubArray(Array2,A_Index+1,Length2-A_Index,1)*)
			}
		}
	Return Output
}
GetArrAvg(ByRef Arr){
	Sum:=0, Len:=Arr.Length()
	Loop, %Len%
		Sum+=Arr[A_Index]
	Return (Sum/Len)
}

;;;;;;;;;;;;;;;;;;;;;;;;;	Gdip	;;;;;;;;;;;;;;;;;;;;;;;;;
GDIPlus_pBitmapFromBuffer(ByRef Buffer,nSize,BufferAddress:="") {
 pStream:=pBitmap:=""
 hData:=DllCall("GlobalAlloc","UInt",2,"UInt",nSize,"Ptr"), pData:=DllCall("GlobalLock","Ptr",hData,"Ptr")
 DllCall("RtlMoveMemory","Ptr",pData,"Ptr",(BufferAddress?BufferAddress:&Buffer),"UInt",nSize)
 DllCall("GlobalUnlock","Ptr",hData)
 DllCall("ole32\CreateStreamOnHGlobal","Ptr",hData,"Int",True,"PtrP",pStream)
 DllCall("gdiplus\GdipCreateBitmapFromStream","Ptr",pStream,"PtrP",pBitmap)
 ObjRelease(pStream) ;DllCall(NumGet(NumGet(1*pStream)+8),"Ptr",pStream) ; IStream::Release
Return pBitmap
}



;~ #Include <PushLog>
;~ #Include <getopt>
;~ #Include <MD5>
#Include <PS_ExceptionHandler>	; https://github.com/Sampsca/PS_ExceptionHandler
#Include %A_ScriptDir%\lib
#Include PushLog.ahk
#Include getopt.ahk
#Include MD5.ahk
#Include MemoryFileIO.ahk
#Include Permutation.ahk
#Include ImageLibraryImports.ahk
;#Include, quick_sort_array_no_recursion.ahk

;~ 0x0000 	4 (char array) 		Signature ('BAMU')
;~ 0x0004 	4 (char array) 		Version ('V1  ')
;~ 0x0008 	2 (word) 		Count of frame entries
;~ 0x000a 	1 (unsigned byte) 	Count of cycles
;~ 0x000b 	1 (unsigned byte) 	The compressed colour index for RLE encoded bams (ie. this is the colour that is compressed)
;~ skip 4
;~ 0x0010 	4 (dword) 		Offset (from start of file) to palette
;~ 0x0014 	4 (dword) 		Offset (from start of file) to frame entries (which are immediately followed by cycle entries)
;~ 0x0018 	4 (dword) 		Offset (from start of file) to frame lookup table
