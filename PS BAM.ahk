;
; AutoHotkey Version: 1.1.30.00
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


Global PS_Arch:=(A_PtrSize=8?"x64":"x86"), PS_DirArch:=A_ScriptDir "\PS BAM (files)\" PS_Arch
Global PS_Temp:=RegExReplace(A_Temp,"\\$") "\PS BAM"
Global PS_TotalBytesSaved:=0
Global PS_Summary:=FormatStr("Name",A_Space,20,"C") A_Space FormatStr("OriginalSize",A_Space,12,"C") A_Space FormatStr("UncompressedSize",A_Space,16,"C") A_Space FormatStr("CompressedSize",A_Space,14,"C") A_Space FormatStr("%OfOriginalSize",A_Space,15,"C") A_Space FormatStr("%OfUncompressedSize",A_Space,19,"C") A_Space FormatStr("Time",A_Space,16,"C") "`r`n"
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

Global Console:=New PushLog("////////////////////////////////////////////////////////////`r`n// PS BAM v0.0.0.1a, Copyright (c) 2012-2018 Sam Schmitz ///`r`n////////////////////////////////////////////////////////////",Settings.LogFile,2)

;~ InPath:=A_ScriptDir "\mdr11207.bam"
;~ InPath:=A_ScriptDir "\CDMF4G12_orig.bam"
;~ InPath:=A_ScriptDir "\AMOOG11.bam"
;~ InPath:="D:\Program Files\Infinity Engine Modding Tools\Miloch's BAM Utility\bambatch\bam\ihelmk5.bam"
;~ InPath:=A_ScriptDir "\-zlib+RLE.bam"
;~ Outpath:=A_ScriptDir "\temp.bam"


;ProcessFile(InPath,Outpath)
ProcessCLIArgOpt()
Console.Send(PS_Summary "`r`n")
Console.Send("Total Bytes Saved=" PS_TotalBytesSaved "`r`n")
;~ ProcessFile("C:\Users\Sam\Desktop\bone.bam",A_ScriptDir "\temp2.bam")

OnExit:
Console:=""
Gdip_Shutdown(pToken)
ExitApp

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
			}
		If (OrigLog<>Settings.LogFile)
			{
			Console.SavePath:=Settings.LogFile
			FormatTime, TimeString, ,MMMM dd, yyyy 'at' h:mm.ss tt
			Console.Send("////////////////////////////////////////////////////////////`r`n// PS BAM v0.0.0.1a, Copyright (c) 2012-2018 Sam Schmitz ///`r`n////////////////////////////////////////////////////////////`r`nInitializing logging of errors and warnings on " TimeString ".`r`n","",-1)
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
	Instance:=""
}

SetCompressionProfile(){
	Arr:=StrSplit(Settings.CompressionProfile,A_Space)
	Loop, % Arr.Length()
		{
		If (Arr[A_Index]="Recommended")
			Settings.Compress:=1, Settings.FixPaletteColorErrors:=1, Settings.AutodetectPalettedBAM:=1, Settings.DropDuplicatePaletteEntries:=1, Settings.DropUnusedPaletteEntries:=1, Settings.SearchTransColor:=1, Settings.ForceTransColor:=1, Settings.ForceShadowColor:=0, Settings.AlphaCutoff:=10, Settings.AllowShortPalette:=1, Settings.TrimFrameData:=1, Settings.ExtraTrimBuffer:=2, Settings.ExtraTrimDepth:=3, Settings.ReduceFrameRowLT:=1, Settings.ReduceFrameColumnLT:=1, Settings.ReduceFramePixelLT:=1, Settings.DropDuplicateFrameData:=1, Settings.DropUnusedFrameData:=1, Settings.IntelligentRLE:=1, Settings.MaxRLERun:=255, Settings.FindBestRLEIndex:=0, Settings.DropDuplicateFrameEntries:=1, Settings.DropUnusedFrameEntries:=1, Settings.AdvancedFLTCompression:=1, Settings.FLTSanityCutoff:=720, Settings.DropEmptyCycleEntries:=1, Settings.AdvancedZlibCompress:=2, Settings.zopfliIterations:=1000
		Else If (Arr[A_Index]="Max")
			Settings.Compress:=1, Settings.FixPaletteColorErrors:=1, Settings.AutodetectPalettedBAM:=0, Settings.DropDuplicatePaletteEntries:=1, Settings.DropUnusedPaletteEntries:=1, Settings.SearchTransColor:=1, Settings.ForceTransColor:=1, Settings.AlphaCutoff:=10, Settings.AllowShortPalette:=1, Settings.TrimFrameData:=1, Settings.ExtraTrimBuffer:=2, Settings.ExtraTrimDepth:=3, Settings.ReduceFrameRowLT:=1, Settings.ReduceFrameColumnLT:=1, Settings.ReduceFramePixelLT:=1, Settings.DropDuplicateFrameData:=1, Settings.DropUnusedFrameData:=1, Settings.IntelligentRLE:=1, Settings.MaxRLERun:=255, Settings.FindBestRLEIndex:=1, Settings.DropDuplicateFrameEntries:=1, Settings.DropUnusedFrameEntries:=1, Settings.AdvancedFLTCompression:=1, Settings.FLTSanityCutoff:=5040, Settings.DropEmptyCycleEntries:=1, Settings.AdvancedZlibCompress:=2, Settings.zopfliIterations:=1000
		Else If (Arr[A_Index]="Safe")
			Settings.Compress:=1, Settings.FixPaletteColorErrors:=1, Settings.AutodetectPalettedBAM:=1, Settings.DropDuplicatePaletteEntries:=0, Settings.DropUnusedPaletteEntries:=0, Settings.SearchTransColor:=1, Settings.ForceTransColor:=0, Settings.ForceShadowColor:=0, Settings.AlphaCutoff:=10, Settings.AllowShortPalette:=0, Settings.TrimFrameData:=1, Settings.ExtraTrimBuffer:=0, Settings.ExtraTrimDepth:=0, Settings.ReduceFrameRowLT:=1, Settings.ReduceFrameColumnLT:=1, Settings.ReduceFramePixelLT:=1, Settings.DropDuplicateFrameData:=1, Settings.DropUnusedFrameData:=1, Settings.IntelligentRLE:=1, Settings.MaxRLERun:=254, Settings.FindBestRLEIndex:=0, Settings.DropDuplicateFrameEntries:=1, Settings.DropUnusedFrameEntries:=1, Settings.AdvancedFLTCompression:=1, Settings.FLTSanityCutoff:=720, Settings.AdvancedZlibCompress:=0
		Else If (Arr[A_Index]="Quick")
			Settings.Compress:=1, Settings.FixPaletteColorErrors:=1, Settings.AutodetectPalettedBAM:=1, Settings.DropDuplicatePaletteEntries:=1, Settings.DropUnusedPaletteEntries:=1, Settings.SearchTransColor:=1, Settings.ForceTransColor:=1, Settings.ForceShadowColor:=0, Settings.AlphaCutoff:=10, Settings.AllowShortPalette:=1, Settings.TrimFrameData:=1, Settings.ExtraTrimBuffer:=2, Settings.ExtraTrimDepth:=3, Settings.ReduceFrameRowLT:=1, Settings.ReduceFrameColumnLT:=1, Settings.ReduceFramePixelLT:=1, Settings.DropDuplicateFrameData:=1, Settings.DropUnusedFrameData:=1, Settings.IntelligentRLE:=1, Settings.MaxRLERun:=254, Settings.FindBestRLEIndex:=0, Settings.DropDuplicateFrameEntries:=1, Settings.DropUnusedFrameEntries:=1, Settings.AdvancedFLTCompression:=1, Settings.FLTSanityCutoff:=1, Settings.DropEmptyCycleEntries:=1, Settings.AdvancedZlibCompress:=1
		Else If (Arr[A_Index]="None")
			Settings.Compress:=0
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
		If (Settings.CompressFirst) AND !(Settings.ProcessFirst)
			{
			If (Settings.Compress)
				BAM.CompressBAM()
			If (Settings.ExportPalette)
				BAM.ExportPalette(Settings.ExportPalette,Output)
			If (Settings.ExportFrames) AND !(Settings.Compress) AND !(Settings.Save="BAMD")
				BAM.ExportFrames(Output)
			BAM.Process()
			}
		Else If !(Settings.CompressFirst) AND (Settings.ProcessFirst)
			{
			BAM.Process()
			If (Settings.ExportPalette)
				BAM.ExportPalette(Settings.ExportPalette,Output)
			If (Settings.ExportFrames) AND !(Settings.Save="BAMD")
				BAM.ExportFrames(Output)
			If (Settings.Compress)
				BAM.CompressBAM()
			}
		Else If (Settings.CompressFirst) AND (Settings.ProcessFirst)
			{
			If (Settings.Compress)
				BAM.CompressBAM()
			If !(Settings.Compress) OR !(Settings.ExportFrames)
				BAM.Process()
			If (Settings.ExportPalette)
				BAM.ExportPalette(Settings.ExportPalette,Output)
			If (Settings.ExportFrames) AND !(Settings.Compress) AND !(Settings.Save="BAMD")
				BAM.ExportFrames(Output)
			}
		Else ; !(Settings.CompressFirst) AND !(Settings.ProcessFirst)
			{
			If (Settings.ExportPalette)
				BAM.ExportPalette(Settings.ExportPalette,Output)
			If (Settings.ExportFrames) AND !(Settings.Save="BAMD")
				BAM.ExportFrames(Output)
			BAM.Process()
			If (Settings.Compress)
				BAM.CompressBAM()
			}
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
			PS_Summary.=FormatStr("N/A",A_Space,14,"C") A_Space
			PS_Summary.=FormatStr("N/A",A_Space,15,"C") A_Space
			PS_Summary.=FormatStr("N/A",A_Space,19,"C") A_Space
			}
		BAM:=""
		PS_Summary.=FormatStr((QPC(1)-tic) " sec.",A_Space,16,"C") "`r`n"
	} catch e {
		; throw { what: (IsFunc(A_ThisFunc)?"function: " A_ThisFunc "()":"") A_Tab (IsLabel(A_ThisLabel)?"label: " A_ThisLabel:""), file: A_LineFile, line: A_LineNumber, message: "", extra: ""}
		Console.Send("Exception thrown!`n`nWhat	=	" e.what "`nFile	=	" e.file "`nLine	=	" e.line "`nMessage	=	" e.message "`nExtra	=	" e.extra "`r`n","E")
		ThrowMsg(16,"Error!","Exception thrown!`n`nWhat	=	" e.what "`nFile	=	" e.file "`nLine	=	" e.line "`nMessage	=	" e.message "`nExtra	=	" e.extra)
		BAM:="", PS_Summary.="`r`n"
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
		ThrowMsg(16,"Error!","Exception thrown!`n`nWhat	=	" e.what "`nFile	=	" e.file "`nLine	=	" e.line "`nMessage	=	" e.message "`nExtra	=	" e.extra)
		}
}
GetOutPath(InPath){
	SplitPath, InPath, OutFileName, OutDir, OutExtension, OutNameNoExt, OutDrive
	If (Settings.OutPath="")
		OutPath:=RegExReplace(OutDir,"\\$") "\" OutNameNoExt "_c"
	Else
		{
		OutPath:=RegExReplace(Settings.OutPath,"\\$")
		IfNotExist, %OutPath%
			FileCreateDir, %OutPath%
		OutPath.="\" OutNameNoExt
		}
	Settings.OutPathSpecific:=OutPath
	Return OutPath
	}

class PSBAM extends ExBAMIO{	; On maximizing compression through optimization of layers of indirection within the constraints of existing file formats.
	LoadBAM(InputPath){
		tic:=QPC(1)
		Console.Send("Path='" InputPath "'`r`n")
		SplitPath, InputPath, OutFileName
		PS_Summary.=FormatStr(OutFileName,A_Space,20,"C") A_Space
		file:=FileOpen(InputPath,"r-d")
			this.Stats:={}
			this.InputPath:=InputPath
			this.Stats.OriginalFileSize:=file.Length, Console.Send("OriginalFileSize=" this.Stats.OriginalFileSize "`r`n","I")
			PS_Summary.=FormatStr(this.Stats.OriginalFileSize,A_Space,12,"C") A_Space
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
		PS_Summary.=FormatStr(OutFileName,A_Space,20,"C") A_Space
		file:=FileOpen(InputPath,"r-d")
			file.Seek(0,0)
			this.Stats:={}
			this.InputPath:=InputPath
			this.Stats.OriginalFileSize:=file.Length ;, Console.Send("OriginalFileSize=" this.Stats.OriginalFileSize "`r`n","I")
			;PS_Summary.=FormatStr(this.Stats.OriginalFileSize,A_Space,12,"C") A_Space
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
		PS_Summary.=FormatStr(BaseFileName,A_Space,20,"C") A_Space
		this.Stats:={}
		this.InputPath:=BaseFrame
		this.Stats.OriginalFileSize:=0	; Should be increased for each imported frame
		this.Stats.FileSize:=0
		this._InitializeEmptyBAM()
		IMT:=this._FindFrames(BaseFrame)
		this._ReadImages(IMT)
		PS_Summary.=FormatStr(this.Stats.FileSize,A_Space,12,"C") A_Space	; Uncompressed Size
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
		If (Settings.AdvancedZlibCompress=2) AND (Settings.Compress=1)
			this._zopfliCompressBAM(OutputPath)
		Else If (Settings.AdvancedZlibCompress=1) AND (Settings.Compress=1)
			this._zlibCompressBAM()
		file:=FileOpen(OutputPath,"w-d")
			file.RawWrite(this.GetAddress("Raw"),this.Stats.FileSize)
			file.Close()
		this.Delete("Raw"), this.DataMem:=""
		PS_TotalBytesSaved+=(this.Stats.OriginalFileSize-this.Stats.FileSize)
		Console.Send("BAM Compression saved " this.Stats.OriginalFileSize-this.Stats.FileSize " bytes.`r`n")
		PS_Summary.=FormatStr(this.Stats.FileSize,A_Space,14,"C") A_Space	; CompressedSize
		PS_Summary.=FormatStr(this.Stats.FileSize/this.Stats.OriginalFileSize*100 " %",A_Space,15,"C") A_Space	; %OfOriginalSize
		PS_Summary.=FormatStr(this.Stats.FileSize/this.Stats.FullyUncompressedSize*100 " %",A_Space,19,"C") A_Space	; %OfUncompressedSize
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
			this._ReadV2FrameEntries()
			this._ReadCycleEntries()
			this._ReadPalette()
			this._ReadV2FrameLookupTable()
			this._ReadDataBlocks()
			throw { what: (IsFunc(A_ThisFunc)?"function: " A_ThisFunc "()":"") A_Tab (IsLabel(A_ThisLabel)?"label: " A_ThisLabel:""), file: A_LineFile, line: A_LineNumber, message: "Reading PVRZ files is not yet supported...  The first file to read would be:  " this.DataBlocks[0,"PVRZFile"], extra: ""}
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
		PS_Summary.=FormatStr(this.Stats.FileSize,A_Space,16,"C") A_Space
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
				throw { what: (IsFunc(A_ThisFunc)?"function: " A_ThisFunc "()":"") A_Tab (IsLabel(A_ThisLabel)?"label: " A_ThisLabel:""), file: A_LineFile, line: A_LineNumber, message: "Frame " Index " is RLE'd but bit depths >8 can not have RLE!", extra: ""}
			ByteCount:=(UPFrames[Index].MaxIndex()=""?0:UPFrames[Index].MaxIndex()+1)
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
		this.Stats.CountOfPaletteEntries:=GetKeyCount(this.Palette)
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
		UPFrames:={}, FirstFramePath:=""
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
		Loop, % (UPFrames.MaxIndex()+1)	; Compensate for missing frames by adding frame of 1 trans pixel
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
		Loop, % (this.CycleEntries.MaxIndex()+1)	; Compensate for missing sequences by adding empty sequence
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
		If GetKeyCount(PalObj)	; We loaded a palette from somewhere
			{
			this.Palette:=PalObj
			Histo:=""
			For k,v in UPFrames
				this.FrameData[k]:=this._ConvertFrameToPaletted(v,PalObj,Histo)
			}
		Else If GetKeyCount(UPFrames)	; No palette but unpaletted data so we need to quantize
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
		
		this.Stats.CountOfPaletteEntries:=GetKeyCount(this.Palette)
		this.Stats.CountOfFrameEntries:=this.FrameEntries.Count()
		this.Stats.CountOfFrames:=this.FrameData.Count()
		this.Stats.CountOfFLTEntries:=this.FrameLookupTable.Count()
		this._UpdateStats()
		this.Stats.SizeOfFrameData:=0
		
		PS_Summary.=FormatStr(this.Stats.OriginalFileSize,A_Space,12,"C") A_Space	; OriginalSize
		this.Stats.FullyUncompressedSize:=this.Stats.FileSize
		Console.Send("this.Stats = `r`n" st_printArr(this.Stats) "`r`n","I")
		PS_Summary.=FormatStr(this.Stats.FileSize,A_Space,16,"C") A_Space
		Console.Send("BAMD read in " (QPC(1)-tic) " sec.`r`n","-I")
	}
	_ReadImages(ByRef IMT){
		UPFrames:={}, PalObjQ:={}, PalObjQ.SetCapacity(256), FrameNum:=HasPal:=0, Histo:="", HistoQ:={}
		; Load Palette
		If (Settings.ReplacePaletteMethod<>"Quant")	; Presumably we'll be given a palette
			{
			PalObj:=""
			PAL:=New PSPAL()
			If FileExist(Settings.ReplacePalette)
				PalObj:=PAL.ImportPaletteFromFile(Settings.ReplacePalette)
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
		Console.Send(st_printArr(IMT) "`r`n","-E")
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
		Loop, % (this.FrameData.MaxIndex()+1)	; Compensate for missing frames by adding frame of 1 (trans) pixel
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
		Loop, % (this.CycleEntries.MaxIndex()+1)	; Compensate for missing sequences by adding empty sequence
			{
			key:=A_Index-1
			If !IsObject(this.CycleEntries[key])
				{
				this.CycleEntries[key]:={}
				this.CycleEntries[key,"CountOfFrameIndices"]:=0
				this.CycleEntries[key,"IndexIntoFLT"]:=0
				}
			}
		this.Stats.CountOfPaletteEntries:=GetKeyCount(this.Palette)
		this.Stats.CountOfFrameEntries:=this.FrameEntries.Count()
		this.Stats.CountOfFrames:=this.FrameData.Count()
		this.Stats.CountOfFLTEntries:=this.FrameLookupTable.Count()
		this._UpdateStats()
		this.Stats.FullyUncompressedSize:=this.Stats.FileSize
		PS_Summary.=FormatStr(this.Stats.OriginalFileSize,A_Space,16,"C") A_Space	; Original Size
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
			If GetKeyCount(FrameObj) AND (Settings.ReplacePaletteMethod="Force")
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
		this.CycleEntries[Idx:=GetKeyCount(this.CycleEntries),"CountOfFrameIndices"]:=Line.Length()
		this.CycleEntries[Idx,"IndexIntoFLT"]:=GetKeyCount(this.FrameLookupTable)
		Loop, % Line.Length()
			{
			Idx:=Line[A_Index]
			Idx+=0
			this.FrameLookupTable[GetKeyCount(this.FrameLookupTable)]:=Idx
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
			throw { what: (IsFunc(A_ThisFunc)?"function: " A_ThisFunc "()":"") A_Tab (IsLabel(A_ThisLabel)?"label: " A_ThisLabel:""), file: A_LineFile, line: A_LineNumber, message: "The following file is not a supported BAM file:`r`n" this.InputPath, extra: "Signature """ this.Stats.Signature """ / Version """ this.Stats.Version """ not supported."}
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
			throw { what: (IsFunc(A_ThisFunc)?"function: " A_ThisFunc "()":"") A_Tab (IsLabel(A_ThisLabel)?"label: " A_ThisLabel:""), file: A_LineFile, line: A_LineNumber, message: "The compiled data is not a supported BAM file", extra: "Signature """ this.Stats.Signature """ / Version """ this.Stats.Version """ not supported."}
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
		this.FrameLookupTable:={},
		Loop, % this.CycleEntries.Count()
			{
			Index:=A_Index-1
			Loop, % this.CycleEntries[Index,"CountOfFrameIndices"]
				this.FrameLookupTable[this.FrameLookupTable.Count()]:=this.CycleEntries[Index,"IndexIntoFLT"]+A_Index-1
			}
		this.PrintFrameLookupTable()
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
					If (Indexi>=PixelCount)
						Break
					}
				}
			ByteCount:=(this.FrameData[Index].MaxIndex()=""?0:this.FrameData[Index].MaxIndex()+1)
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
				If (PixelCount<>(this.FrameData[Index].MaxIndex()=""?0:this.FrameData[Index].MaxIndex()+1))
					throw { what: (IsFunc(A_ThisFunc)?"function: " A_ThisFunc "()":"") A_Tab (IsLabel(A_ThisLabel)?"label: " A_ThisLabel:""), file: A_LineFile, line: A_LineNumber, message: "Frame " Index " is " (this.FrameData[Index].MaxIndex()=""?0:this.FrameData[Index].MaxIndex()+1) " bytes long but was expected to be " PixelCount " bytes!", extra: "FrameDataEntry=" FrameDataEntry}
				Loop, % PixelCount
					{
					Index2:=A_Index-1
					this.DataMem.WriteUChar(this.FrameData[Index,Index2])
					}
				}
			Else	; Frame Data IS RLE
				{
				Loop, % this.FrameData[Index].MaxIndex()+1
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
			throw { what: (IsFunc(A_ThisFunc)?"function: " A_ThisFunc "()":"") A_Tab (IsLabel(A_ThisLabel)?"label: " A_ThisLabel:""), file: A_LineFile, line: A_LineNumber, message: "ErrorLevel=" ErrorLevel A_Tab "A_LastError=" A_LastError, extra: "zlib Decompression Error"}
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
			throw { what: (IsFunc(A_ThisFunc)?"function: " A_ThisFunc "()":"") A_Tab (IsLabel(A_ThisLabel)?"label: " A_ThisLabel:""), file: A_LineFile, line: A_LineNumber, message: "ErrorLevel=" ErrorLevel A_Tab "A_LastError=" A_LastError, extra: "zlib Compression Error"}
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
			Console.Send("Palette does not have a true shadow color." "`r`n","W")
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
		this._CalcTransColorIndex()
		this._CalcShadowColorIndex()
		
		this.Stats.CountOfPaletteEntries:=GetKeyCount(this.Palette)	;this.Palette.MaxIndex()+1
		
		this.Stats.PaletteHasAlpha:=0
		Loop, % (this.Stats.CountOfPaletteEntries)
			{
			Index:=A_Index-1
			If (this.Palette[Index,"AA"]>0) AND (this.Palette[Index,"AA"]<>"")
				this.Stats.PaletteHasAlpha:=1
			}
		this.Stats.CountOfFrameEntries:=this.FrameEntries.MaxIndex()+1
		this.Stats.RLE:=0
		Loop, % this.Stats.CountOfFrameEntries
			{
			Index:=A_Index-1
			If (this.FrameEntries[Index,"RLE"]=1)
				this.Stats.RLE:=1
			}
		this.Stats.CountOfCycles:=this.CycleEntries.MaxIndex()+1
		this.Stats.CountOfFLTEntries:=this.FrameLookupTable.MaxIndex()+1
		this.Stats.CountOfFrames:=this.FrameData.MaxIndex()+1
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
			this.Stats.SizeOfFrameData+=(this.FrameData[Index].MaxIndex()+1)
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
				temp+=(this.FrameData[Index2].MaxIndex()+1)
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
					throw { what: (IsFunc(A_ThisFunc)?"function: " A_ThisFunc "()":"") A_Tab (IsLabel(A_ThisLabel)?"label: " A_ThisLabel:""), file: A_LineFile, line: A_LineNumber, message: "ErrorLevel=" Error A_Tab "A_LastError=" A_LastError, extra: "Error in Gdip_SaveBitmapToFile() trying to convert and save '" Output0 "' to file."}
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
		PS_Summary.=FormatStr("N/A",A_Space,14,"C") A_Space
		PS_Summary.=FormatStr("N/A",A_Space,15,"C") A_Space
		PS_Summary.=FormatStr("N/A",A_Space,19,"C") A_Space
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
		PS_Summary.=FormatStr(TotalSz,A_Space,14,"C") A_Space
		PS_Summary.=FormatStr(TotalSz/this.Stats.OriginalFileSize*100 " %",A_Space,15,"C") A_Space
		PS_Summary.=FormatStr(TotalSz/this.Stats.FullyUncompressedSize*100 " %",A_Space,19,"C") A_Space
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
		Else If !IsObject(PalObj) OR !GetKeyCount(PalObj) ; Load default "paletted" palette
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
			BytesRemoved:=this._TrimFrames(), Console.Send("Trimmed " BytesRemoved " Pixels from FrameData." "`r`n","I")
		If (Settings.ExtraTrimDepth>0) AND (Settings.ExtraTrimBuffer>=0)
			BytesRemoved:=this._ExtraTrimFrames(), Console.Send("Trimmed " BytesRemoved " Extra Pixels from FrameData." "`r`n","I")
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
		If (Settings.ExportFrames) AND (Settings.CompressFirst=1) AND !(Settings.Save="BAMD") ;AND (Settings.IntelligentRLE=1)
			{
			If (Settings.ProcessFirst)
				this.Process()
			this.ExportFrames(Settings.OutPathSpecific) ;, Settings.ExportFrames:=0
			}
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
		If (CountOfPaletteEntriesUsed>Count:=(Pal.MaxIndex()-Pal.MinIndex()+1))
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
			throw { what: (IsFunc(A_ThisFunc)?"function: " A_ThisFunc "()":"") A_Tab (IsLabel(A_ThisLabel)?"label: " A_ThisLabel:""), file: A_LineFile, line: A_LineNumber, message: "ErrorLevel=" ErrorLevel A_Tab "A_LastError=" A_LastError, extra: "CryptStringToBinary Error"}
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
			Loop, % this.FrameData[Index].MaxIndex()+1
				{
				Index2:=A_Index-1
				Index3:=A_Index-2
				If (this.FrameData[Index,Index2]=Entry) AND (!(this.FrameEntries[Index,"RLE"]) OR (this.FrameData[Index,Index3]<>this.Stats.TransColorIndex))
					Return 1
				}
			}
		Return 0
	}
	_DropUnusedPaletteEntries(){
		ReindexArray:={}, NumRemoved:=0, Realign:=0
		Loop, % (this.Stats.CountOfPaletteEntries)
			{
			Index:=A_Index-1
			If !(this._isPaletteEntryUsed(Index)) AND (Index<>this.Stats.TransColorIndex) AND (Index<>this.Stats.ShadowColorIndex)	; don't remove TransColorIndex or ShadowColorIndex!
				{
				Console.Send("Palette Entry " Index " is unused." "`r`n","I")
				this.Palette.RemoveAt(Index-NumRemoved), NumRemoved++
				}
			Else
				ReindexArray[Index]:=Realign++
			}
		Loop, % this.Stats.CountOfFrames
			{
			Index:=A_Index-1
			Loop, % this.FrameData[Index].MaxIndex()+1
				{
				Index2:=A_Index-1
				this.FrameData[Index,Index2]:=ReindexArray[this.FrameData[Index,Index2]]
				}
			}
		this.Stats.CountOfPaletteEntries:=GetKeyCount(this.Palette)	;this.Palette.MaxIndex()+1
		Return NumRemoved
	}
	_DropUnusedPaletteEntriesFromEnd(){
		NumRemoved:=0
		While !(this._isPaletteEntryUsed(Index:=this.Palette.MaxIndex())) AND (Index<>this.Stats.TransColorIndex) AND (Index<>this.Stats.ShadowColorIndex)	; don't remove TransColorIndex or ShadowColorIndex!
			{
			Console.Send("Palette Entry " Index " is unused." "`r`n","I")
			this.Palette.RemoveAt(Index), NumRemoved++
			}
		this.Stats.CountOfPaletteEntries:=GetKeyCount(this.Palette) ;this.Palette.MaxIndex()+1
		Return NumRemoved
	}
	_CalcPaletteEntryDuplicate(Entry:=0){
		R:=this.Palette[Entry,"RR"], G:=this.Palette[Entry,"GG"], B:=this.Palette[Entry,"BB"], A:=this.Palette[Entry,"AA"]
		Loop, % Entry
			{
			Index:=A_Index-1
			RR:=this.Palette[Index,"RR"], GG:=this.Palette[Index,"GG"], BB:=this.Palette[Index,"BB"], AA:=this.Palette[Index,"AA"]
			If (RR=R) AND (GG=G) AND (BB=B) AND (AA=A)
				{
				Console.Send("Palette Entry " Entry " is a duplicate of Entry " Index ".	(" R ", " G ", " B ", " A ")=(" RR ", " GG ", " BB ", " AA ")" "`r`n","I")
				Return Index	; If duplicate, returns value of Palette Entry it is a duplicate of.  Only lower palette entries are returned.
				}
			}
		Return Entry	; If not a duplicate, return itself.
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
		ReindexArray:={}, NumRemoved:=0
		this._SetOpaquePalette0()
		Loop, % this.Stats.CountOfPaletteEntries
			{
			Index:=A_Index-1
			Dupe:=this._CalcPaletteEntryDuplicate(Index)
			ReindexArray[Index]:=Dupe
			If (Dupe<>Index)
				NumRemoved++
			}
		Loop, % this.Stats.CountOfFrames
			{
			Index:=A_Index-1
			Loop, % this.FrameData[Index].MaxIndex()+1
				{
				Index2:=A_Index-1
				this.FrameData[Index,Index2]:=ReindexArray[this.FrameData[Index,Index2]]
				}
			}
		Return NumRemoved
	}
	_FixPaletteColorErrors(){
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
				Index:=GetKeyCount(this.Palette)	;this.Palette.MaxIndex()+1
				this._SetPaletteEntry(Index,0,0,0,0)
				this._MovePaletteEntry(Index,1)
				this.Stats.ShadowColorIndex:=1
				this.Stats.CountOfPaletteEntries:=GetKeyCount(this.Palette)	;this.Palette.MaxIndex()+1
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
			Loop, % this.FrameData[Index].MaxIndex()+1
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
				BytesFrameData:=(this.FrameData[Index].MaxIndex()=""?0:this.FrameData[Index].MaxIndex())+1
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
			ByteCount:=this.FrameData[Index].MaxIndex()+1
			If (ByteCount<>this.FrameData[Entry].MaxIndex()+1)
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
		this.Stats.CountOfFrames:=this.FrameData.MaxIndex()+1
		Return FramesDropped
		}
	_RLESize(Frame:=0, RLEColorIndex:="", Set:=0){
		RLEData:={}, compressedCharCount:=0, NewBytes:=0
		RLEColorIndex:=(RLEColorIndex=""?this.Stats.RLEColorIndex:RLEColorIndex)
		Loop, % this.FrameData[Frame].MaxIndex()+1
			{
			Index:=A_Index-1
			If (this.FrameData[Frame,Index]=RLEColorIndex)
				{
				compressedCharCount++
				If (compressedCharCount>Settings.MaxRLERun)
					{
					RLEData[NewBytes]:=RLEColorIndex, NewBytes++
					RLEData[NewBytes]:=Settings.MaxRLERun, NewBytes++
					compressedCharCount:=0
					}
				}
			Else
				{
				If (compressedCharCount>0)
					{
					RLEData[NewBytes]:=RLEColorIndex, NewBytes++
					RLEData[NewBytes]:=compressedCharCount-1, NewBytes++
					compressedCharCount:=0
					}
				RLEData[NewBytes]:=this.FrameData[Frame,Index], NewBytes++
				}
			}
		If (compressedCharCount>0)
			{
			RLEData[NewBytes]:=RLEColorIndex, NewBytes++
			RLEData[NewBytes]:=compressedCharCount-1, NewBytes++
			}
		If (Settings.MaxRLERun=255)
			{
			RLEData2:={}, compressedCharCount:=0, NewBytes:=0
			Loop, % this.FrameData[Frame].MaxIndex()+1
				{
				Index:=A_Index-1
				If (this.FrameData[Frame,Index]=RLEColorIndex)
					{
					compressedCharCount++
					If (compressedCharCount>Settings.MaxRLERun-1)
						{
						RLEData2[NewBytes]:=RLEColorIndex, NewBytes++
						RLEData2[NewBytes]:=Settings.MaxRLERun-1, NewBytes++
						compressedCharCount:=0
						}
					}
				Else
					{
					If (compressedCharCount>0)
						{
						RLEData2[NewBytes]:=RLEColorIndex, NewBytes++
						RLEData2[NewBytes]:=compressedCharCount-1, NewBytes++
						compressedCharCount:=0
						}
					RLEData2[NewBytes]:=this.FrameData[Frame,Index], NewBytes++
					}
				}
			If (compressedCharCount>0)
				{
				RLEData2[NewBytes]:=RLEColorIndex, NewBytes++
				RLEData2[NewBytes]:=compressedCharCount-1, NewBytes++
				}
			If (RLEData2.MaxIndex()+1<=RLEData.MaxIndex()+1)
				RLEData:=RLEData2
			Else If (Set=1)
				Console.Send("Frame " Frame " uses RLE runs >254.  This may cause issues for BAMWorkshop." "`r`n","W")
			}
		If (Set=1) AND (RLEData.MaxIndex()+1<this.FrameData[Frame].MaxIndex()+1)
			this.FrameData[Frame]:=RLEData
		Return RLEData.MaxIndex()+1
	}
	_FindBestRLEColorIndex(){
		Console.Send("Searching for best possible RLEColorIndex.  This could take some time...`r`n","-W")
		BestRLEColorIndex:=this.Stats.RLEColorIndex, BestTry:=9223372036854775807
		Loop, % this.Stats.CountOfPaletteEntries
			{
			CurrentColorIndex:=A_Index-1
			SizeOfTry:=0
			If (Settings.DropUnusedPaletteEntries<>1)
				If !(this._isPaletteEntryUsed(CurrentColorIndex))
					Continue
			Loop, % this.Stats.CountOfFrames
				{
				Frame:=A_Index-1
				unRLE:=this.FrameData[Frame].MaxIndex()+1
				RLE:=this._RLESize(Frame,CurrentColorIndex,0)
				SizeOfTry+=(RLE<unRLE?RLE:unRLE)
				}
			If (SizeOfTry<BestTry)
				BestTry:=SizeOfTry, BestRLEColorIndex:=CurrentColorIndex
			}
		Console.Send("BestRLEColorIndex=" BestRLEColorIndex "`r`n","I")
		Return BestRLEColorIndex
	}
	_RLE(){
		tic:=QPC(1)
		BytesSaved:=0
		If (Settings.FindBestRLEIndex=1)
			this.Stats.RLEColorIndex:=this._FindBestRLEColorIndex()
		Loop, % this.Stats.CountOfFrames
			{
			Frame:=A_Index-1
			unRLE:=this.FrameData[Frame].MaxIndex()+1
			RLE:=this._RLESize(Frame,this.Stats.RLEColorIndex,1)
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
		this.Stats.CountOfFrameEntries:=this.FrameEntries.MaxIndex()+1
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
					throw { what: (IsFunc(A_ThisFunc)?"function: " A_ThisFunc "()":"") A_Tab (IsLabel(A_ThisLabel)?"label: " A_ThisLabel:""), file: A_LineFile, line: A_LineNumber, message: "Sequence not found in FLT.", extra: "CycleEntry=" Index " | Sequence=" Sub}
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
		FLT:={}, Indexi:=1
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
	Process(){
		tic:=QPC(1)
		Console.Send("`r`n","-W")
		Console.Send("Beginning additional processing of BAM file..." "`r`n","-W")
		If (Settings.ItemIcon2EE)
			this._ItemIcon2EE()
		If (Settings.BAMProfile)
			this._SetBAMProfile(Settings.BAMProfile)
		If (Settings.Unify>0)
			this._Unify()
		If (Settings.Montage<>"")
			this._Montage()
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
			If (this.FrameEntries[Index,"CenterX"]>MaxXCoord)
				MaxXCoord:=this.FrameEntries[Index,"CenterX"]
			If (this.FrameEntries[Index,"CenterY"]>MaxYCoord)
				MaxYCoord:=this.FrameEntries[Index,"CenterY"]
			}
		MaxWidth:=0
		MaxHeight:=0
		Loop, % this.Stats.CountOfFrameEntries
			{
			Index:=A_Index-1
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
	_Montage(){ ; Combines frames into a single frame.  Should run "Unify" first.
		If (Settings.Montage="1x2")	; (rows x columns)
			{
			If (this.Stats.CountOfFrames=2)
				{
				this.FrameData[0].Push(ShiftArray(this.FrameData[1])*)
				this.FrameEntries[0,"Height"]+=this.FrameEntries[1,"Height"]
				this.FrameData[1].RemoveAt(0,1)
				this.FrameLookupTable:="", this.FrameLookupTable:={}, this.FrameLookupTable[0]:=0
				}
			}
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
				NewFrameObj.InsertAt(GetKeyCount(NewFrameObj),Line*)
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
		Console.Send(Msg "`r`n")
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
}

SetSettings(){
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;;;;    Global Settings   ;;;;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	Settings.OutPath:=A_ScriptDir "\compressed"
	Settings.OutPathSpecific:=""
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
	Settings.Compress:=1
	Settings.ExportPalette:=""			; | ACT | ALL | Bin | BMP | BMPV | PAL | Raw |
	Settings.ExportFrames:=""			; | BMP | DIB | GIF | JFIF | JPE | JPEG | JPG | PNG | RLE | TIF | TIFF || BMP,8V3 | BMP,24V3 | BMP,32V5 |
	Settings.ExportFramesAsSequences:=0
	Settings.CompressFirst:=1
	Settings.ProcessFirst:=0
	Settings.SingleGIF:=0
	Settings.ReplacePalette:=""
	Settings.ReplacePaletteMethod:="Quant"	; | Force | Remap | Quant
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;;;; Compression Settings ;;;;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	Settings.CompressionProfile:=""				; | Max | Recommended | Safe | Quick | None |	; (is position dependent!!!)
	Settings.FixPaletteColorErrors:=1
	Settings.AutodetectPalettedBAM:=0
	Settings.AutodetectPalettedThreshold:=500	; 14100 will identify vanilla off-paletted palettes as paletted.  500 will identify BW1 palette colors as paletted.
	Settings.DropDuplicatePaletteEntries:=0
	Settings.DropUnusedPaletteEntries:=0		; | 0=OFF | 1=ON | 2=only from end |
	Settings.SearchTransColor:=1				; BG1/PST TransColor might not be palette entry 0 (so you should search)
	Settings.ForceTransColor:=0
	Settings.ForceShadowColor:=0				; 0=None | 1=Force | 2=Move | 3=Insert (move will insert if fails)
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
	Settings.BAMProfile:=""				; | ItemIcon | Zero | Paperdoll | GroundIcon | DescriptionIconEE | ItemIconEE | SpellIcon | Spell |
	Settings.Unify:=0					; | 0=Off | 1=On | 2=Square |
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

ThrowMsg(Options="",Title="",Text="",Timeout=""){
	If (Title="") AND (Text="") AND (Timeout=""){
		Gui +OwnDialogs
		MsgBox % Options
		}
	Else{
		Gui +OwnDialogs
		MsgBox, % Options , % Title , % Text , % Timeout
		}
}

QPC(R:=0){ ; By SKAN, http://goo.gl/nf7O4G, CD:01/Sep/2014 | MD:01/Sep/2014
  Static P:=0, F:=0, Q:=DllCall("QueryPerformanceFrequency","Int64P",F)
  Return !DllCall("QueryPerformanceCounter","Int64P",Q)+(R?(P:=Q)/F:(Q-P)/F) 
}

GetKeyCount(Arr){
	If IsObject(Arr)
		Return NumGet(&Arr+4*A_PtrSize)
	Return 0
}

Num2Bin(n,bits=0) {     ; Return LS "bits" of binary representation of "n"
   b:=""
   IfLess bits,1, Loop  ; n < 0: leading 1's are omitted. -1 -> 1, 0 -> 0
      {
         b := n&1 b
         n := n>>1
         If (n = n>>1)
            Break
      }
   Else Loop %bits%
      {
         b := n&1 b
         n := n>>1
      }
   Return b
}

Bin2Num(bits,neg="") {  ; Return number converted from the binary "bits" string
   n = 0                ; If "neg" is not 0 or empty, 11..1 assumed on the left
   Loop Parse, bits
      n += n + A_LoopField
   Return n - !(neg<1)*(1<<StrLen(bits))
}

GetBits(num,start:=0,count:=1,bits:=8){
	bits:=Num2Bin(num,bits)
	rbits:=SubStr(bits,start+1,count)
	Return Bin2Num(rbits)
}

PackByte(Size,Bits*){
	tmp:=""
	For k,v in Bits
		tmp.=Num2Bin(v,(Size[k]=""?1:Size[k]))
	Return Bin2Num(tmp)
}

String2Array(Str){
	Arr:=StrSplit(Str)
	For k,v in Arr
		Arr[k]:=Asc(v)
	Return Arr
}

strI(str){ ; https://github.com/Masonjar13/AHK-Library/blob/master/Lib/strI.ahk
    VarSetCapacity(nStr,sLen:=strLen(str))
    Loop, %sLen%
        nStr.=SubStr(str,sLen--,1)
    Return nStr
}

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

ObjFullyClone(obj){	; https://autohotkey.com/board/topic/103411-cloned-object-modifying-original-instantiation/?p=638500
    nobj:=ObjClone(obj)
    For k,v in nobj
        If IsObject(v)
            nobj[k]:=ObjFullyClone(v)
    Return nobj
}

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
		If (Offset>=Len)
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
 ;ObjRelease(pStream)
 DllCall(NumGet(NumGet(1*pStream)+8),"Ptr",pStream) ; IStream::Release
Return pBitmap
}



;~ #Include <PushLog>
;~ #Include <getopt>
;~ #Include <MD5>
#Include %A_ScriptDir%\lib
#Include PushLog.ahk
#Include getopt.ahk
#Include MD5.ahk
#Include MemoryFileIO_v2.1.ahk
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
