;
; AutoHotkey Version: 1.1.30.03
; Language:       English
; Platform:       Optimized for Windows 10
; Author:         Sam.
;

/*
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn All, StdOut  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance Force  ; Skips the dialog box and replaces the old instance automatically, which is similar in effect to the Reload command.
*/

;;;;;	Reference Documents	;;;;;
; http://gibberlings3.net/forums/index.php?showtopic=26065
; http://gibberlings3.net/forums/index.php?showtopic=26039
; https://github.com/Argent77/NearInfinity/blob/devel/src/org/infinity/resource/graphics/PvrDecoder.java
; https://github.com/SickheadGames/ManagedPVRTC/tree/master/PVRTexLibWrapper/source
; https://github.com/nico/demumble/releases
; https://www.autohotkey.com/boards/viewtopic.php?f=76&t=61719&p=261923
; https://www.autohotkey.com/boards/viewtopic.php?f=76&t=60442
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;             PS_PVR             ;;;;;
;;;;;  Copyright (c) 2018-2019 Sam.  ;;;;;
;;;;;      Last Updated 20190507     ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

/* ; Usage Example:
;Global A_Quote:=Chr(34)
Global PS_Arch:=(A_PtrSize=8?"x64":"x86"), PS_DirArch:=A_ScriptDir "\PS_PVR (files)\" PS_Arch

Global Console:=New PushLog("////////////////////////////////////////////////////////`r`n///// PS_PVR v0.0.1a, Copyright (c) 2018-2019 Sam. /////`r`n////////////////////////////////////////////////////////","",2)


try {

	;~ hPVR:=New PSPVR()
	;~ hPVR.LoadPVRFromFile("C:\Programs\AutoHotkey Scripts\PS_PVR\MOS0000.pvrz")
	;~ hPVR.ExportPVRasBMPviaDLL("C:\Programs\AutoHotkey Scripts\PS_PVR\MOS0000")
	;~ hPVR.ExportSubTexture(A_ScriptDir "\MOS0000_SubTex1.bmp",hPVR.ExtractSubTexture(0,0,0,1024,768),1024,768)
	
	;~ hPVR:=""
	
	Loop, %A_ScriptDir%\test files\*.pvrz, 0, 0
		{
		hPVR:=New PSPVR()
		hPVR.LoadPVRFromFile(A_LoopFileLongPath)
		SplitPath, A_LoopFileLongPath, OutFileName, OutDir, OutExtension, OutNameNoExt, OutDrive
		hPVR.ExportPVRasBMPviaDLL(OutDir "\" OutNameNoExt)
		
		hPVR:=""
		}
	
	

} catch e {
	; throw { what: (IsFunc(A_ThisFunc)?"function: " A_ThisFunc "()":"") A_Tab (IsLabel(A_ThisLabel)?"label: " A_ThisLabel:""), file: A_LineFile, line: A_LineNumber, message: "", extra: ""}
	Console.Send("Exception thrown!`n`nWhat	=	" e.what "`nFile	=	" e.file "`nLine	=	" e.line "`nMessage	=	" e.message "`nExtra	=	" e.extra "`r`n","E")
	;ThrowMsg(16,"Error!","Exception thrown!`n`nWhat	=	" e.what "`nFile	=	" e.file "`nLine	=	" e.line "`nMessage	=	" e.message "`nExtra	=	" e.extra)
	ExceptionErrorDlg(e)
	}



OnExit:
	hPVR:=""
	Console:=""
ExitApp
*/

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;             WARNING!           ;;;;;
;;;;;   this class only works with   ;;;;;
;;;;;      x64 AHK_L (for now)       ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
class PSPVR{
	__New(){
		this._MapPVRTexLibDLL()
		this.hModulePVRTexLib:=DllCall("LoadLibrary","Str",PS_DirArch "\PVRTexLib.dll","Ptr")
	}
	__Delete(){
		DllCall("FreeLibrary","Ptr",this.hModulePVRTexLib)
	}
	LoadPVRFromFile(InputPath){
		tic:=this._QPC(1)
		Console.Send("Loading texture from '" InputPath "'`r`n","-W")
		file:=FileOpen(InputPath,"r-d")
			this.Stats:={}
			this.InputPath:=InputPath
			SplitPath, InputPath, InFileName
			this.Stats.FileName:=InFileName
			this.Stats.OriginalFileSize:=file.Length, Console.Send("OriginalFileSize=" this.Stats.OriginalFileSize "`r`n","I")
			this.Stats.FileSize:=file.Length, Console.Send("FileSize=" this.Stats.FileSize "`r`n","I")
			this.Raw:=" ", this.SetCapacity("Raw",this.Stats.FileSize), DllCall("RtlFillMemory","Ptr",this.GetAddress("Raw"),"UInt",this.Stats.FileSize,"UChar",0)
			file.RawRead(this.GetAddress("Raw"),this.Stats.FileSize)
			file.Close()
		this.DataMem:=New MemoryFileIO(this.GetAddress("Raw"),this.Stats.FileSize)
		Console.Send("Texture loaded into memory in " (this._QPC(1)-tic) " sec.`r`n","-I")
		this._ReadPVR()
		;~ this.Raw:="", this.Delete("Raw"), this.DataMem:=""
		Console.Send("Finished loading texture in " (this._QPC(1)-tic) " sec.`r`n`r`n","-I")
	}
	LoadPVRFromMemory(Address,Size){
		tic:=this._QPC(1)
		this.Stats:={}
		;this.InputPath:=InputPath
		this.Stats.OriginalFileSize:=Size, Console.Send("OriginalFileSize=" this.Stats.OriginalFileSize "`r`n","I")
		this.Stats.FileSize:=Size, Console.Send("FileSize=" this.Stats.FileSize "`r`n","I")
		this.Raw:=" ", this.SetCapacity("Raw",this.Stats.FileSize), DllCall("RtlFillMemory","Ptr",this.GetAddress("Raw"),"UInt",this.Stats.FileSize,"UChar",0)
		tmp:=New MemoryFileIO(Address+0,Size)
		tmp.RawRead(this.GetAddress("Raw"),this.Stats.FileSize)
		tmp:=""
		this.DataMem:=New MemoryFileIO(this.GetAddress("Raw"),this.Stats.FileSize)
		Console.Send("Texture loaded into memory in " (this._QPC(1)-tic) " sec.`r`n","-I")
		this._ReadPVR()
		;~ this.Raw:="", this.Delete("Raw"), this.DataMem:=""
		Console.Send("Finished loading texture in " (this._QPC(1)-tic) " sec.`r`n","-I")
	}
	_ReadPVR(){
		tic:=this._QPC(1)
		Global PixelFormat:={}, Flags:={}, ColorSpace:={}, ChannelType:={}
		this._InitializeEnums(Flags,PixelFormat,ColorSpace,ChannelType)
		this.Stats.WasPVRZ:=0
		this._ReadPVRHeader()
		If (this.Stats.UncompressedSize)	; Appears to be a PVRZ
			{
			this._DecompressPVRZ()
			this._ReadPVRHeader()
			}
		this._ReadPVRMetadata()
		this._ReadPVRTextures()
		;~ Data:=""
		;~ For key, val in this.Stats
			;~ Data.=key A_Tab
		;~ Data.="`r`n"
		;~ For key, val in this.Stats
			;~ Data.=val A_Tab
		;~ Data.="`r`n"
		;~ FileAppend, %Data%, %A_ScriptDir%\Profile.txt
		Console.Send("PVR read in " (this._QPC(1)-tic) " sec.`r`n","-I")
	}
	_ReadPVRHeader(){
		tic:=this._QPC(1)
		Global PixelFormat, Flags, ColorSpace, ChannelType
		this.DataMem.Seek(0,0)
		this.Stats.OffsetToHeader:=0, Console.Send("OffsetToHeader=" this.Stats.OffsetToHeader "`r`n","I")
		this.Stats.Version:=this.DataMem.ReadDWORD(), Console.Send("Version=" this.Stats.Version "`r`n","I")
		If (this.Stats.Version=0x50565203)	; endianness does not match!
			{
			this.DataMem.Seek(0,0)
			this.Stats.Signature:=this.DataMem.Read(3), Console.Send("Signature='" this.Stats.Signature "'`r`n","I")
			this.Stats.FormatVersion:=this.DataMem.ReadUChar(), Console.Send("FormatVersion=" this.Stats.FormatVersion "`r`n","I")
			throw { what: (IsFunc(A_ThisFunc)?"function: " A_ThisFunc "()":"") A_Tab (IsLabel(A_ThisLabel)?"label: " A_ThisLabel:""), file: A_LineFile, line: A_LineNumber, message: "The endianness is incorrect for reading the following file:`r`n" this.InputPath, extra: "Version " Chr(34) this.Stats.Version Chr(34)}
			}
		Else If (this.Stats.Version=0x03525650)	; endianness does match!
			{
			this.DataMem.Seek(0,0)
			this.Stats.Signature:=this.DataMem.Read(3), Console.Send("Signature='" this.Stats.Signature "'`r`n","I")
			this.Stats.FormatVersion:=this.DataMem.ReadUChar(), Console.Send("FormatVersion=" this.Stats.FormatVersion "`r`n","I")
			this.Stats.Flags:=this.DataMem.ReadDWORD(), Console.Send("Flags=" this.Stats.Flags " => " Flags[this.Stats.Flags] "`r`n","I")
			this.Stats.PixelFormatA:=this.Datamem.ReadDWORD()
			this.Stats.PixelFormatB:=this.Datamem.ReadDWORD()
			If (this.Stats.PixelFormatB=0)	; Enumerated pixel format
				this.Stats.PixelFormat:=this.Stats.PixelFormatA, Console.Send("PixelFormat=" this.Stats.PixelFormat " => " PixelFormat[this.Stats.PixelFormat] "`r`n","I")
			Else
				{
				this.Datamem.Seek(-8,1)
				this.Stats.PixelFormatC:=this.Datamem.Read(4)
				this.Stats.PixelFormatD:=this.Datamem.ReadByte()
				this.Stats.PixelFormatE:=this.Datamem.ReadByte()
				this.Stats.PixelFormatF:=this.Datamem.ReadByte()
				this.Stats.PixelFormatG:=this.Datamem.ReadByte()
				this.Stats.PixelFormat:=this.Stats.PixelFormatC this.Stats.PixelFormatD this.Stats.PixelFormatE this.Stats.PixelFormatF this.Stats.PixelFormatG, Console.Send("PixelFormat='" this.Stats.PixelFormat "'`r`n","I")
				}
			this.Stats.ColorSpace:=this.Datamem.ReadDWORD(), Console.Send("ColorSpace=" this.Stats.ColorSpace " => " ColorSpace[this.Stats.ColorSpace] "`r`n","I")
			this.Stats.ChannelType:=this.Datamem.ReadDWORD(), Console.Send("ChannelType=" this.Stats.ChannelType " => " ChannelType[this.Stats.ChannelType] "`r`n","I")
			this.Stats.Height:=this.Datamem.ReadDWORD(), Console.Send("Height=" this.Stats.Height "`r`n","I")
			this.Stats.Width:=this.Datamem.ReadDWORD(), Console.Send("Width=" this.Stats.Width "`r`n","I")
			this.Stats.Depth:=this.Datamem.ReadDWORD(), Console.Send("Depth=" this.Stats.Depth "`r`n","I")
			this.Stats.SurfaceCount:=this.Datamem.ReadDWORD(), Console.Send("SurfaceCount=" this.Stats.SurfaceCount "`r`n","I")
			this.Stats.FaceCount:=this.Datamem.ReadDWORD(), Console.Send("FaceCount=" this.Stats.FaceCount "`r`n","I")
			this.Stats.MIPMapCount:=this.Datamem.ReadDWORD(), Console.Send("MIPMapCount=" this.Stats.MIPMapCount "`r`n","I")
			this.Stats.MetadataSize:=this.Datamem.ReadDWORD(), Console.Send("MetadataSize=" this.Stats.MetadataSize "`r`n","I")
			this.Stats.CountOfTextures:=this.Stats.MIPMapCount*this.Stats.SurfaceCount*this.Stats.FaceCount*this.Stats.Depth, Console.Send("CountOfTextures=" this.Stats.CountOfTextures "`r`n","I")
			;~ If this.Stats.MetadataSize
				;~ Console.Send("MetadataSize is non-zero: " this.Stats.MetadataSize "`r`n","W")
			Console.Send("PVR Header read in " (this._QPC(1)-tic) " sec.`r`n","-I")
			}
		Else	; appears to be PVRZ (or not a PVR file at all?)
			{
			this.Stats.UncompressedSize:=this.Stats.Version, Console.Send("UncompressedSize=" this.Stats.UncompressedSize "`r`n","I")
			this.Stats.Version:=""
			this.Stats.WasPVRZ:=1
			Console.Send("PVRZ Header read in " (this._QPC(1)-tic) " sec.`r`n","-I")
			}
	}
	_DecompressPVRZ(){
		tic:=this._QPC(1)
		OriginalSize:=this.Stats.UncompressedSize
		VarSetCapacity(Decompressed,OriginalSize)
		ErrorLevel:=DllCall(PS_DirArch "\zlib1.dll\uncompress","Ptr",&Decompressed,"UIntP",OriginalSize,"Ptr",this.GetAddress("Raw")+4,"UInt",this.Stats.FileSize-4,"Cdecl")
		If (ErrorLevel<0)
			throw { what: (IsFunc(A_ThisFunc)?"function: " A_ThisFunc "()":"") A_Tab (IsLabel(A_ThisLabel)?"label: " A_ThisLabel:""), file: A_LineFile, line: A_LineNumber, message: "ErrorLevel=" ErrorLevel A_Tab "A_LastError=" A_LastError, extra: "zlib Decompression Error"}
		this.Stats.FileSize:=OriginalSize, Console.Send("FileSize=" this.Stats.FileSize "`r`n","I")
		this.Delete("Raw"), this.Raw:=" ", this.SetCapacity("Raw",OriginalSize), this.DataMem:=""
		DllCall("RtlMoveMemory","Ptr",this.GetAddress("Raw"),"Ptr",&Decompressed,"UInt",OriginalSize)
		this.DataMem:=New MemoryFileIO(this.GetAddress("Raw"),OriginalSize)
		this.Stats.Delete("UncompressedSize"), OriginalSize:="", VarSetCapacity(Decompressed,0) ; memory cleanup
		Console.Send("PVRZ Decompressed in " (this._QPC(1)-tic) " sec.`r`n","-I")
	}
	_ReadPVRMetadata(){
		this.Stats.OffsetToMetadata:=this.Datamem.Tell()
		this.Metadata:={}
		If this.Stats.MetadataSize
			{
			Console.Send("MetadataSize is non-zero: " this.Stats.MetadataSize "`r`n  Skipping Metadata...`r`n","W")
			this.Datamem.Seek(this.Stats.MetadataSize,1)
			}
	}
	_ReadPVRTextures(){
		tic:=this._QPC(1)
		this.Stats.OffsetToTextures:=52+this.Stats.MetadataSize
		this.Stats.SizeOfTextures:=this.Stats.Filesize-52-this.Stats.MetadataSize
		;this.Datamem.Seek(this.Stats.OffsetToTextures,0)
		this.Textures:={}
		;;;;; use PVRTexTool (or dll?) to decompress texture into image ;;;;;
		;hModule:=DllCall("LoadLibrary","Str",PS_DirArch "\PVRTexLib.dll","Ptr")
		;;;;; Load the Texture ;;;;;
		VarSetCapacity(Texture,1024,0)
		DllCall("PVRTexLib\" this.PVRTexLibDLL[19],"Ptr",&Texture,"Ptr",this.GetAddress("Raw"),(A_PtrSize=8?"Cdecl":"thiscall") "Ptr")
		;;;;; Create the PixelType (PVRStandard8PixelType) ;;;;;
		VarSetCapacity(ptFormat,8,0)
		DllCall("PVRTexLib\" this.PVRTexLibDLL[28],"Ptr",&ptFormat,"UChar",Asc("r"),"UChar",Asc("g"),"UChar",Asc("b"),"UChar",Asc("a"),"UChar",8,"UChar",8,"UChar",8,"UChar",8,(A_PtrSize=8?"Cdecl":"thiscall"))
		;;;;; Set Other Parameters ;;;;;
		eChannelType:=2	; eChannelType = ePVRTVarTypeUnsignedByteNorm = 0 | ePVRTVarTypeUnsignedByte = 2
		eColourspace:=0	; eColourspace = ePVRTCSpacelRGB = 0
		eQuality:=3		; eQuality = ePVRTCNormal = 1 | ePVRTCBest = 3
		bDoDither:=0	; bDoDither = false = 0
		;;;;; Transcode the Texture to a Usable Format ;;;;;
		DllCall("PVRTexLib\" this.PVRTexLibDLL[128],"Ptr",&Texture,"Int64",NumGet(&ptFormat,"Int64"),"UInt",eChannelType,"UInt",eColourspace,"UInt",eQuality,"UChar",bDoDither,"Cdecl")
		;DllCall("PVRTexLib\?Flip@pvrtexture@@YA_NAEAVCPVRTexture@1@W4EPVRTAxis@@@Z","Ptr",&Texture,"UInt",1,"Cdecl Char")	; Flips vertically
		
		;;;;; Get All Pixel Data ;;;;;
		DataPointer:=DllCall("PVRTexLib\" this.PVRTexLibDLL[196],"Ptr",&Texture,"UInt",0,"UInt",0,"UInt",0,(A_PtrSize=8?"Cdecl":"thiscall") "Ptr")
		DataSize:=DllCall("PVRTexLib\" this.PVRTexLibDLL[197],"Ptr",&Texture,"Int",-1,"UChar",1,"UChar",1,(A_PtrSize=8?"Cdecl":"thiscall") "Int")
		;~ MsgBox % NumGet(DataPointer+0,0,"UChar") "`n" NumGet(DataPointer+0,1,"UChar") "`n" NumGet(DataPointer+0,2,"UChar") "`n" NumGet(DataPointer+0,3,"UChar")	
		;VarSetCapacity(Header,52,0)
		;DllCall("PVRTexLib\?getFileHeader@CPVRTextureHeader@pvrtexture@@QEBA?AUPVRTextureHeaderV3@@XZ","Ptr",&Texture,"Ptr",&Header,"Cdecl Ptr")
		;;;;; Load Individual Textures (could be more than 1) ;;;;;
		this.Textures.SetCapacity(TexCnt:=this.Stats.CountOfTextures)
		Sz:=this.Stats.Width*this.Stats.Height
		Loop, % TexCnt
			{
			this.Textures[Index:=A_Index-1].SetCapacity(Sz)
			Loop, % Sz
				{
				Idx:=A_Index-1, DataPtr:=DataPointer+Idx*4
				this.Textures[Index,Idx,"RR"]:=NumGet(DataPtr+0,0,"UChar")
				this.Textures[Index,Idx,"GG"]:=NumGet(DataPtr+0,1,"UChar")
				this.Textures[Index,Idx,"BB"]:=NumGet(DataPtr+0,2,"UChar")
				this.Textures[Index,Idx,"AA"]:=NumGet(DataPtr+0,3,"UChar")
				}
			}
		;;;;; Deconstruct Texture Classes ;;;;;
		DllCall("PVRTexLib\" this.PVRTexLibDLL[37],"Ptr",&Texture,(A_PtrSize=8?"Cdecl":"thiscall")) ; ~CPVRTexture();
		;DllCall("PVRTexLib\??1CPVRTextureHeader@pvrtexture@@QEAA@XZ","Ptr",&Texture,"Cdecl") ; ~CPVRTextureHeader();
		;DllCall("FreeLibrary","Ptr",hModule)
		Console.Send("Read " TexCnt " PVR texture(s) each containing " Sz " pixels in " (this._QPC(1)-tic) " sec.`r`n","-I")
	}
	ExportPVRasBMP(OutPath:=""){	; OutPath should include File Name but no Extension!!
		tic:=this._QPC(1)
		If !OutPath
			{
			SplitPath, % (this.InputPath), , OutDir, OutExtension, OutNameNoExt
			OutPath:=OutDir "\" OutNameNoExt
			}
		;;;;;	32-bit Windows 5.x BMP	;;;;;
		Width:=this.Stats.Width, Height:=this.Stats.Height
		FileSize:=(138+Width*Height*4)
		VarSetCapacity(Bitmap,FileSize,0)
		BMP:=New MemoryFileIO(&Bitmap,FileSize)
		BMP.Seek(0,0)
		BMP.Write("BM",2)
		BMP.WriteUInt(FileSize)
		BMP.WriteUShort(0)
		BMP.WriteUShort(0)
		BMP.WriteUInt(138)
		BMP.WriteUInt(124)
		BMP.WriteInt(Width)
		BMP.WriteInt(Height)
		BMP.WriteUShort(1)
		BMP.WriteUShort(32)
		BMP.WriteUInt(3)
		BMP.WriteUInt(Width*Height*4)
		BMP.WriteInt(0)
		BMP.WriteInt(0)
		BMP.WriteUInt(0)
		BMP.WriteUInt(0) ; ColorsImportant
		BMP.WriteUInt(16711680)
		BMP.WriteUInt(65280)
		BMP.WriteUInt(255)
		BMP.WriteUInt(4278190080)
		BMP.WriteUInt(1934772034) ; (sRGB)
		For TexIndex, Texture in this.Textures
			{
			BMP.Seek(138,0)
			If (Height>0)
				Output:=this._Flip(Texture,Width,Height)	; Bitmaps store pixel rows bottom to top
			Else
				Output:=Texture
			For key, value in Output
				{
				BMP.WriteUChar(value["BB"])
				BMP.WriteUChar(value["GG"])
				BMP.WriteUChar(value["RR"])
				BMP.WriteUChar(value["AA"])
				}
			file:=FileOpen(OutPath (this.Stats.CountOfTextures>1?"_" SubStr("0000" TexIndex,-3):"") ".bmp","w-d")
				file.Seek(0,0)
				file.RawWrite(&Bitmap,FileSize)
			file.Close()
			}
		BMP:=""
		Console.Send("Exported " TexIndex+1 " texture(s) as BMPs in " (this._QPC(1)-tic) " sec.`r`n","-I")
	}
	ExportPVRasBMPviaDLL(OutPath:=""){	; OutPath should include File Name but no Extension!!
		tic:=this._QPC(1)
		If !OutPath
			{
			SplitPath, % (this.InputPath), , OutDir, OutExtension, OutNameNoExt
			OutPath:=OutDir "\" OutNameNoExt
			}
		;hModule:=DllCall("LoadLibrary","Str",PS_DirArch "\PVRTexLib.dll","Ptr")
		VarSetCapacity(Texture,1024,0), DllCall("PVRTexLib\" this.PVRTexLibDLL[19],"Ptr",&Texture,"Ptr",this.GetAddress("Raw"),(A_PtrSize=8?"Cdecl":"thiscall") "Ptr")
		VarSetCapacity(ptFormat,8,0), DllCall("PVRTexLib\" this.PVRTexLibDLL[28],"Ptr",&ptFormat,"UChar",Asc("r"),"UChar",Asc("g"),"UChar",Asc("b"),"UChar",Asc("a"),"UChar",8,"UChar",8,"UChar",8,"UChar",8,(A_PtrSize=8?"Cdecl":"thiscall"))
		eChannelType:=0	; eChannelType = ePVRTVarTypeUnsignedByteNorm = 0 | ePVRTVarTypeUnsignedByte = 2
		eColourspace:=0	; eColourspace = ePVRTCSpacelRGB = 0
		eQuality:=3		; eQuality = ePVRTCNormal = 1 | ePVRTCBest = 3
		bDoDither:=0	; bDoDither = false = 0
		DllCall("PVRTexLib\" this.PVRTexLibDLL[128],"Ptr",&Texture,"Int64",NumGet(&ptFormat,"Int64"),"UInt",eChannelType,"UInt",eColourspace,"UInt",eQuality,"UChar",bDoDither,"Cdecl")
		DllCall("PVRTexLib\" this.PVRTexLibDLL[93],"Ptr",&Texture,"UInt",1,"Cdecl Char")	; Flips vertically
		VarSetCapacity(ptFormat,8,0), DllCall("PVRTexLib\" this.PVRTexLibDLL[28],"Ptr",&ptFormat,"UChar",Asc("b"),"UChar",Asc("g"),"UChar",Asc("r"),"UChar",Asc("a"),"UChar",8,"UChar",8,"UChar",8,"UChar",8,(A_PtrSize=8?"Cdecl":"thiscall"))
		eChannelType:=2	; eChannelType = ePVRTVarTypeUnsignedByteNorm = 0 | ePVRTVarTypeUnsignedByte = 2
		DllCall("PVRTexLib\" this.PVRTexLibDLL[128],"Ptr",&Texture,"Int64",NumGet(&ptFormat,"Int64"),"UInt",eChannelType,"UInt",eColourspace,"UInt",eQuality,"UChar",bDoDither,"Cdecl")
		DataPointer:=DllCall("PVRTexLib\" this.PVRTexLibDLL[196],"Ptr",&Texture,"UInt",0,"UInt",0,"UInt",0,(A_PtrSize=8?"Cdecl":"thiscall") "Ptr")
		DataSize:=DllCall("PVRTexLib\" this.PVRTexLibDLL[197],"Ptr",&Texture,"Int",-1,"UChar",1,"UChar",1,(A_PtrSize=8?"Cdecl":"thiscall") "Int")
		Width:=this.Stats.Width, Height:=this.Stats.Height, FileSize:=(138+Width*Height*4)
		VarSetCapacity(Bitmap,FileSize,0)
		BMP:=New MemoryFileIO(&Bitmap,FileSize)
		BMP.Seek(0,0)
		BMP.Write("BM",2)
		BMP.WriteUInt(FileSize)
		BMP.WriteUShort(0)
		BMP.WriteUShort(0)
		BMP.WriteUInt(138)
		BMP.WriteUInt(124)
		BMP.WriteInt(Width)
		BMP.WriteInt(Height)
		BMP.WriteUShort(1)
		BMP.WriteUShort(32)
		BMP.WriteUInt(3)
		BMP.WriteUInt(Width*Height*4)
		BMP.WriteInt(0)
		BMP.WriteInt(0)
		BMP.WriteUInt(0)
		BMP.WriteUInt(0) ; ColorsImportant
		BMP.WriteUInt(16711680)
		BMP.WriteUInt(65280)
		BMP.WriteUInt(255)
		BMP.WriteUInt(4278190080)
		BMP.WriteUInt(1934772034) ; (sRGB)
		Loop, % this.Stats.CountOfTextures
			{
			BMP.Seek(138,0)
			BMP.RawWrite(DataPointer+0,Width*Height*4)
			file:=FileOpen(OutPath (this.Stats.CountOfTextures>1?"_" SubStr("0000" TexIndex,-3):"") ".bmp","w-d")
				file.Seek(0,0)
				file.RawWrite(&Bitmap,FileSize)
			file.Close()
			}
		BMP:=""
		;;;;; Deconstruct Texture Classes ;;;;;
		DllCall("PVRTexLib\" this.PVRTexLibDLL[37],"Ptr",&Texture,(A_PtrSize=8?"Cdecl":"thiscall")) ; ~CPVRTexture();
		;DllCall("PVRTexLib\??1CPVRTextureHeader@pvrtexture@@QEAA@XZ","Ptr",&Texture,"Cdecl") ; ~CPVRTextureHeader();
		;DllCall("FreeLibrary","Ptr",hModule)
		Console.Send("Exported " this.Stats.CountOfTextures " texture(s) as BMPs in " (this._QPC(1)-tic) " sec.`r`n","-I")
	}
	_InitializeEnums(ByRef Flags, ByRef PixelFormat, ByRef ColorSpace, ByRef ChannelType){
		;;;;; Flags ;;;;;
		If !IsObject(Flags)
			Flags:={}
		Flags[0]:="No Flag"
		Flags[1]:="Pre-multiplied"
		;;;;; Pixel Formats ;;;;;
		If !IsObject(PixelFormat)
			PixelFormat:={}
		PixelFormat[0]:="PVRTC 2bpp RGB"
		PixelFormat[1]:="PVRTC 2bpp RGBA"
		PixelFormat[2]:="PVRTC 4bpp RGB"
		PixelFormat[3]:="PVRTC 4bpp RGBA"
		PixelFormat[4]:="PVRTC-II 2bpp"
		PixelFormat[5]:="PVRTC-II 4bpp"
		PixelFormat[6]:="ETC1"
		PixelFormat[7]:="DXT1 (BC1)"
		PixelFormat[8]:="DXT2"
		PixelFormat[9]:="DXT3 (BC2)"
		PixelFormat[10]:="DXT4"
		PixelFormat[11]:="DXT5 (BC3)"
		PixelFormat[12]:="BC4"
		PixelFormat[13]:="BC5"
		PixelFormat[14]:="BC6"
		PixelFormat[15]:="BC7"
		PixelFormat[16]:="UYVY"
		PixelFormat[17]:="YUY2"
		PixelFormat[18]:="BW1bpp"
		PixelFormat[19]:="R9G9B9E5 Shared Exponent"
		PixelFormat[20]:="RGBG8888"
		PixelFormat[21]:="GRGB8888"
		PixelFormat[22]:="ETC2 RGB"
		PixelFormat[23]:="ETC2 RGBA"
		PixelFormat[24]:="ETC2 RGB A1"
		PixelFormat[25]:="EAC R11"
		PixelFormat[26]:="EAC RG11"
		PixelFormat[27]:="ASTC_4x4"
		PixelFormat[28]:="ASTC_5x4"
		PixelFormat[29]:="ASTC_5x5"
		;;;;; Color Space ;;;;;
		If !IsObject(ColorSpace)
			ColorSpace:={}
		ColorSpace[0]:="Linear RGB"
		ColorSpace[1]:="sRGB"
		;;;;; Channel Type ;;;;;
		If !IsObject(ChannelType)
			ChannelType:={}
		ChannelType[0]:="Unsigned Byte Normalised"
		ChannelType[1]:="Signed Byte Normalised"
		ChannelType[2]:="Unsigned Byte"
		ChannelType[3]:="Signed Byte"
		ChannelType[4]:="Unsigned Short Normalised"
		ChannelType[5]:="Signed Short Normalised"
		ChannelType[6]:="Unsigned Short"
		ChannelType[7]:="Signed Short"
		ChannelType[8]:="Unsigned Integer Normalised"
		ChannelType[9]:="Signed Integer Normalised"
		ChannelType[10]:="Unsigned Integer"
		ChannelType[11]:="Signed Integer"
		ChannelType[12]:="Float"
	}
	_Flip(ByRef FrameObj,Width,Height){	; Width (in bytes) should include any scanline padding if present
		NewFrameobj:={}, Origin:=FrameObj.MinIndex(), NewFrameObj.SetCapacity(FrameObj.MaxIndex()-Origin+1)
		Loop, % Abs(Height)
			{
			Idx:=A_Index-1, Line:={}
			Loop, %Width%
				Line.Push(FrameObj[Origin+A_Index-1+Idx*Width])
			NewFrameObj.InsertAt(Origin,Line*)
			}
		Return NewFrameObj
	}
	ExtractSubTexture(TextureNo,X,Y,W,H){
		tic:=this._QPC(1)
		Array:={}, Idx:=0, Width:=this.Stats.Width, Height:=this.Stats.Height
		If (X+W>Width) OR (Y+H>Height)
			throw { what: (IsFunc(A_ThisFunc)?"function: " A_ThisFunc "()":"") A_Tab (IsLabel(A_ThisLabel)?"label: " A_ThisLabel:""), file: A_LineFile, line: A_LineNumber, message: "ErrorLevel=" ErrorLevel A_Tab "A_LastError=" A_LastError, extra: "Unable to extract subtexture.  Texture dimensions were exceeded."}
		Loop, %H%
			{
			Pointer:=Width*Y+X+Width*(A_Index-1)
			Loop, %W%
				{
				Array[Idx,"RR"]:=this.Textures[TextureNo,Pointer,"RR"]
				Array[Idx,"GG"]:=this.Textures[TextureNo,Pointer,"GG"]
				Array[Idx,"BB"]:=this.Textures[TextureNo,Pointer,"BB"]
				Array[Idx,"AA"]:=this.Textures[TextureNo,Pointer,"AA"]
				Idx++
				Pointer++
				}
			}
		Console.Send("Extracted SubTexture in " (this._QPC(1)-tic) " sec.`r`n","-I")
		Return Array
	}
	ExportSubTexture(OutPath,TexArray,Width,Height){
		tic:=this._QPC(1)
		;;;;;	32-bit Windows 5.x BMP	;;;;;
		FileSize:=(138+Width*Height*4)
		VarSetCapacity(Bitmap,FileSize,0)
		BMP:=New MemoryFileIO(&Bitmap,FileSize)
		BMP.Seek(0,0)
		BMP.Write("BM",2)
		BMP.WriteUInt(FileSize)
		BMP.WriteUShort(0)
		BMP.WriteUShort(0)
		BMP.WriteUInt(138)
		BMP.WriteUInt(124)
		BMP.WriteInt(Width)
		BMP.WriteInt(Height)
		BMP.WriteUShort(1)
		BMP.WriteUShort(32)
		BMP.WriteUInt(3)
		BMP.WriteUInt(Width*Height*4)
		BMP.WriteInt(0)
		BMP.WriteInt(0)
		BMP.WriteUInt(0)
		BMP.WriteUInt(0) ; ColorsImportant
		BMP.WriteUInt(16711680)
		BMP.WriteUInt(65280)
		BMP.WriteUInt(255)
		BMP.WriteUInt(4278190080)
		BMP.WriteUInt(1934772034) ; (sRGB)
		BMP.Seek(138,0)
		If (Height>0)
			Output:=this._Flip(TexArray,Width,Height)	; Bitmaps store pixel rows bottom to top
		Else
			Output:=TexArray
		For key, value in Output
			{
			BMP.WriteUChar(value["BB"])
			BMP.WriteUChar(value["GG"])
			BMP.WriteUChar(value["RR"])
			BMP.WriteUChar(value["AA"])
			}
		file:=FileOpen(OutPath,"w-d")
			file.Seek(0,0)
			file.RawWrite(&Bitmap,FileSize)
		file.Close()
		BMP:=""
		Console.Send("Exported SubTexture in BMP format in " (this._QPC(1)-tic) " sec.`r`n","-I")
	}
	AlphaCutoff(Val:=0,RR:=0,GG:=255,BB:=0,AA:=255){
		For TexIndex, Texture in this.Textures
			{
			For k,v in Texture
				{
				If (v["AA"]<=Val)
					v["RR"]:=RR, v["GG"]:=GG, v["BB"]:=BB, v["AA"]:=AA
				}
			}
	}
	_MapPVRTexLibDLL(){
		PVRTexLibDLL:={}, PVRTexLibDLL.SetCapacity(269)
		If (A_PtrSize=8) ; Is x64 (64-bit)
			{
			PVRTexLibDLL[1]:="??0?$CPVRTArray@I@@QEAA@AEBV0@@Z" ; public: __cdecl CPVRTArray<unsigned int>::CPVRTArray<unsigned int>(class CPVRTArray<unsigned int> const &)
			PVRTexLibDLL[2]:="??0?$CPVRTArray@I@@QEAA@XZ" ; public: __cdecl CPVRTArray<unsigned int>::CPVRTArray<unsigned int>(void)
			PVRTexLibDLL[3]:="??0?$CPVRTArray@UMetaDataBlock@@@@QEAA@AEBV0@@Z" ; public: __cdecl CPVRTArray<struct MetaDataBlock>::CPVRTArray<struct MetaDataBlock>(class CPVRTArray<struct MetaDataBlock> const &)
			PVRTexLibDLL[4]:="??0?$CPVRTArray@UMetaDataBlock@@@@QEAA@XZ" ; public: __cdecl CPVRTArray<struct MetaDataBlock>::CPVRTArray<struct MetaDataBlock>(void)
			PVRTexLibDLL[5]:="??0?$CPVRTArray@V?$CPVRTMap@IUMetaDataBlock@@@@@@QEAA@AEBV0@@Z" ; public: __cdecl CPVRTArray<class CPVRTMap<unsigned int, struct MetaDataBlock>>::CPVRTArray<class CPVRTMap<unsigned int, struct MetaDataBlock>>(class CPVRTArray<class CPVRTMap<unsigned int, struct MetaDataBlock>> const &)
			PVRTexLibDLL[6]:="??0?$CPVRTArray@V?$CPVRTMap@IUMetaDataBlock@@@@@@QEAA@XZ" ; public: __cdecl CPVRTArray<class CPVRTMap<unsigned int, struct MetaDataBlock>>::CPVRTArray<class CPVRTMap<unsigned int, struct MetaDataBlock>>(void)
			PVRTexLibDLL[7]:="??0?$CPVRTMap@IUMetaDataBlock@@@@QEAA@AEBV0@@Z" ; public: __cdecl CPVRTMap<unsigned int, struct MetaDataBlock>::CPVRTMap<unsigned int, struct MetaDataBlock>(class CPVRTMap<unsigned int, struct MetaDataBlock> const &)
			PVRTexLibDLL[8]:="??0?$CPVRTMap@IUMetaDataBlock@@@@QEAA@XZ" ; public: __cdecl CPVRTMap<unsigned int, struct MetaDataBlock>::CPVRTMap<unsigned int, struct MetaDataBlock>(void)
			PVRTexLibDLL[9]:="??0?$CPVRTMap@IV?$CPVRTMap@IUMetaDataBlock@@@@@@QEAA@AEBV0@@Z" ; public: __cdecl CPVRTMap<unsigned int, class CPVRTMap<unsigned int, struct MetaDataBlock>>::CPVRTMap<unsigned int, class CPVRTMap<unsigned int, struct MetaDataBlock>>(class CPVRTMap<unsigned int, class CPVRTMap<unsigned int, struct MetaDataBlock>> const &)
			PVRTexLibDLL[10]:="??0?$CPVRTMap@IV?$CPVRTMap@IUMetaDataBlock@@@@@@QEAA@XZ" ; public: __cdecl CPVRTMap<unsigned int, class CPVRTMap<unsigned int, struct MetaDataBlock>>::CPVRTMap<unsigned int, class CPVRTMap<unsigned int, struct MetaDataBlock>>(void)
			PVRTexLibDLL[11]:="??0CPVRTString@@QEAA@AEBV0@_K1@Z" ; public: __cdecl CPVRTString::CPVRTString(class CPVRTString const &, unsigned __int64, unsigned __int64)
			PVRTexLibDLL[12]:="??0CPVRTString@@QEAA@D@Z" ; public: __cdecl CPVRTString::CPVRTString(char)
			PVRTexLibDLL[13]:="??0CPVRTString@@QEAA@PEBD_K@Z" ; public: __cdecl CPVRTString::CPVRTString(char const *, unsigned __int64)
			PVRTexLibDLL[14]:="??0CPVRTString@@QEAA@XZ" ; public: __cdecl CPVRTString::CPVRTString(void)
			PVRTexLibDLL[15]:="??0CPVRTString@@QEAA@_KD@Z" ; public: __cdecl CPVRTString::CPVRTString(unsigned __int64, char)
			PVRTexLibDLL[16]:="??0CPVRTexture@pvrtexture@@QEAA@AEBV01@@Z" ; public: __cdecl pvrtexture::CPVRTexture::CPVRTexture(class pvrtexture::CPVRTexture const &)
			PVRTexLibDLL[17]:="??0CPVRTexture@pvrtexture@@QEAA@AEBVCPVRTextureHeader@1@PEBX@Z" ; public: __cdecl pvrtexture::CPVRTexture::CPVRTexture(class pvrtexture::CPVRTextureHeader const &, void const *)
			PVRTexLibDLL[18]:="??0CPVRTexture@pvrtexture@@QEAA@PEBD@Z" ; public: __cdecl pvrtexture::CPVRTexture::CPVRTexture(char const *)
			PVRTexLibDLL[19]:="??0CPVRTexture@pvrtexture@@QEAA@PEBX@Z" ; public: __cdecl pvrtexture::CPVRTexture::CPVRTexture(void const *)
			PVRTexLibDLL[20]:="??0CPVRTexture@pvrtexture@@QEAA@XZ" ; public: __cdecl pvrtexture::CPVRTexture::CPVRTexture(void)
			PVRTexLibDLL[21]:="??0CPVRTextureHeader@pvrtexture@@QEAA@AEBV01@@Z" ; public: __cdecl pvrtexture::CPVRTextureHeader::CPVRTextureHeader(class pvrtexture::CPVRTextureHeader const &)
			PVRTexLibDLL[22]:="??0CPVRTextureHeader@pvrtexture@@QEAA@UPVRTextureHeaderV3@@IPEAUMetaDataBlock@@@Z" ; public: __cdecl pvrtexture::CPVRTextureHeader::CPVRTextureHeader(struct PVRTextureHeaderV3, unsigned int, struct MetaDataBlock *)
			PVRTexLibDLL[23]:="??0CPVRTextureHeader@pvrtexture@@QEAA@XZ" ; public: __cdecl pvrtexture::CPVRTextureHeader::CPVRTextureHeader(void)
			PVRTexLibDLL[24]:="??0CPVRTextureHeader@pvrtexture@@QEAA@_KIIIIIIW4EPVRTColourSpace@@W4EPVRTVariableType@@_N@Z" ; public: __cdecl pvrtexture::CPVRTextureHeader::CPVRTextureHeader(unsigned __int64, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, enum EPVRTColourSpace, enum EPVRTVariableType, bool)
			PVRTexLibDLL[25]:="??0MetaDataBlock@@QEAA@AEBU0@@Z" ; public: __cdecl MetaDataBlock::MetaDataBlock(struct MetaDataBlock const &)
			PVRTexLibDLL[26]:="??0MetaDataBlock@@QEAA@XZ" ; public: __cdecl MetaDataBlock::MetaDataBlock(void)
			PVRTexLibDLL[27]:="??0PVRTextureHeaderV3@@QEAA@XZ" ; public: __cdecl PVRTextureHeaderV3::PVRTextureHeaderV3(void)
			PVRTexLibDLL[28]:="??0PixelType@pvrtexture@@QEAA@EEEEEEEE@Z" ; public: __cdecl pvrtexture::PixelType::PixelType(unsigned char, unsigned char, unsigned char, unsigned char, unsigned char, unsigned char, unsigned char, unsigned char)
			PVRTexLibDLL[29]:="??0PixelType@pvrtexture@@QEAA@XZ" ; public: __cdecl pvrtexture::PixelType::PixelType(void)
			PVRTexLibDLL[30]:="??0PixelType@pvrtexture@@QEAA@_K@Z" ; public: __cdecl pvrtexture::PixelType::PixelType(unsigned __int64)
			PVRTexLibDLL[31]:="??1?$CPVRTArray@I@@UEAA@XZ" ; public: virtual __cdecl CPVRTArray<unsigned int>::~CPVRTArray<unsigned int>(void)
			PVRTexLibDLL[32]:="??1?$CPVRTArray@UMetaDataBlock@@@@UEAA@XZ" ; public: virtual __cdecl CPVRTArray<struct MetaDataBlock>::~CPVRTArray<struct MetaDataBlock>(void)
			PVRTexLibDLL[33]:="??1?$CPVRTArray@V?$CPVRTMap@IUMetaDataBlock@@@@@@UEAA@XZ" ; public: virtual __cdecl CPVRTArray<class CPVRTMap<unsigned int, struct MetaDataBlock>>::~CPVRTArray<class CPVRTMap<unsigned int, struct MetaDataBlock>>(void)
			PVRTexLibDLL[34]:="??1?$CPVRTMap@IUMetaDataBlock@@@@QEAA@XZ" ; public: __cdecl CPVRTMap<unsigned int, struct MetaDataBlock>::~CPVRTMap<unsigned int, struct MetaDataBlock>(void)
			PVRTexLibDLL[35]:="??1?$CPVRTMap@IV?$CPVRTMap@IUMetaDataBlock@@@@@@QEAA@XZ" ; public: __cdecl CPVRTMap<unsigned int, class CPVRTMap<unsigned int, struct MetaDataBlock>>::~CPVRTMap<unsigned int, class CPVRTMap<unsigned int, struct MetaDataBlock>>(void)
			PVRTexLibDLL[36]:="??1CPVRTString@@UEAA@XZ" ; public: virtual __cdecl CPVRTString::~CPVRTString(void)
			PVRTexLibDLL[37]:="??1CPVRTexture@pvrtexture@@QEAA@XZ" ; public: __cdecl pvrtexture::CPVRTexture::~CPVRTexture(void)
			PVRTexLibDLL[38]:="??1CPVRTextureHeader@pvrtexture@@QEAA@XZ" ; public: __cdecl pvrtexture::CPVRTextureHeader::~CPVRTextureHeader(void)
			PVRTexLibDLL[39]:="??1MetaDataBlock@@QEAA@XZ" ; public: __cdecl MetaDataBlock::~MetaDataBlock(void)
			PVRTexLibDLL[40]:="??4?$CPVRTArray@I@@QEAAAEAV0@AEBV0@@Z" ; public: class CPVRTArray<unsigned int> & __cdecl CPVRTArray<unsigned int>::operator=(class CPVRTArray<unsigned int> const &)
			PVRTexLibDLL[41]:="??4?$CPVRTArray@UMetaDataBlock@@@@QEAAAEAV0@AEBV0@@Z" ; public: class CPVRTArray<struct MetaDataBlock> & __cdecl CPVRTArray<struct MetaDataBlock>::operator=(class CPVRTArray<struct MetaDataBlock> const &)
			PVRTexLibDLL[42]:="??4?$CPVRTArray@V?$CPVRTMap@IUMetaDataBlock@@@@@@QEAAAEAV0@AEBV0@@Z" ; public: class CPVRTArray<class CPVRTMap<unsigned int, struct MetaDataBlock>> & __cdecl CPVRTArray<class CPVRTMap<unsigned int, struct MetaDataBlock>>::operator=(class CPVRTArray<class CPVRTMap<unsigned int, struct MetaDataBlock>> const &)
			PVRTexLibDLL[43]:="??4?$CPVRTMap@IUMetaDataBlock@@@@QEAAAEAV0@AEBV0@@Z" ; public: class CPVRTMap<unsigned int, struct MetaDataBlock> & __cdecl CPVRTMap<unsigned int, struct MetaDataBlock>::operator=(class CPVRTMap<unsigned int, struct MetaDataBlock> const &)
			PVRTexLibDLL[44]:="??4?$CPVRTMap@IV?$CPVRTMap@IUMetaDataBlock@@@@@@QEAAAEAV0@AEBV0@@Z" ; public: class CPVRTMap<unsigned int, class CPVRTMap<unsigned int, struct MetaDataBlock>> & __cdecl CPVRTMap<unsigned int, class CPVRTMap<unsigned int, struct MetaDataBlock>>::operator=(class CPVRTMap<unsigned int, class CPVRTMap<unsigned int, struct MetaDataBlock>> const &)
			PVRTexLibDLL[45]:="??4CPVRTString@@QEAAAEAV0@AEBV0@@Z" ; public: class CPVRTString & __cdecl CPVRTString::operator=(class CPVRTString const &)
			PVRTexLibDLL[46]:="??4CPVRTString@@QEAAAEAV0@D@Z" ; public: class CPVRTString & __cdecl CPVRTString::operator=(char)
			PVRTexLibDLL[47]:="??4CPVRTString@@QEAAAEAV0@PEBD@Z" ; public: class CPVRTString & __cdecl CPVRTString::operator=(char const *)
			PVRTexLibDLL[48]:="??4CPVRTexture@pvrtexture@@QEAAAEAV01@AEBV01@@Z" ; public: class pvrtexture::CPVRTexture & __cdecl pvrtexture::CPVRTexture::operator=(class pvrtexture::CPVRTexture const &)
			PVRTexLibDLL[49]:="??4CPVRTextureHeader@pvrtexture@@QEAAAEAV01@AEBV01@@Z" ; public: class pvrtexture::CPVRTextureHeader & __cdecl pvrtexture::CPVRTextureHeader::operator=(class pvrtexture::CPVRTextureHeader const &)
			PVRTexLibDLL[50]:="??4LowHigh@PixelType@pvrtexture@@QEAAAEAU012@AEBU012@@Z" ; public: struct pvrtexture::PixelType::LowHigh & __cdecl pvrtexture::PixelType::LowHigh::operator=(struct pvrtexture::PixelType::LowHigh const &)
			PVRTexLibDLL[51]:="??4MetaDataBlock@@QEAAAEAU0@AEBU0@@Z" ; public: struct MetaDataBlock & __cdecl MetaDataBlock::operator=(struct MetaDataBlock const &)
			PVRTexLibDLL[52]:="??4PVRTextureHeaderV3@@QEAAAEAU0@AEBU0@@Z" ; public: struct PVRTextureHeaderV3 & __cdecl PVRTextureHeaderV3::operator=(struct PVRTextureHeaderV3 const &)
			PVRTexLibDLL[53]:="??4PixelType@pvrtexture@@QEAAAEAT01@AEBT01@@Z" ; public: union pvrtexture::PixelType & __cdecl pvrtexture::PixelType::operator=(union pvrtexture::PixelType const &)
			PVRTexLibDLL[54]:="??8CPVRTString@@QEBA_NAEBV0@@Z" ; public: bool __cdecl CPVRTString::operator==(class CPVRTString const &) const
			PVRTexLibDLL[55]:="??8CPVRTString@@QEBA_NQEBD@Z" ; public: bool __cdecl CPVRTString::operator==(char const *const) const
			PVRTexLibDLL[56]:="??9CPVRTString@@QEBA_NAEBV0@@Z" ; public: bool __cdecl CPVRTString::operator!=(class CPVRTString const &) const
			PVRTexLibDLL[57]:="??9CPVRTString@@QEBA_NQEBD@Z" ; public: bool __cdecl CPVRTString::operator!=(char const *const) const
			PVRTexLibDLL[58]:="??A?$CPVRTArray@I@@QEAAAEAII@Z" ; public: unsigned int & __cdecl CPVRTArray<unsigned int>::operator[](unsigned int)
			PVRTexLibDLL[59]:="??A?$CPVRTArray@I@@QEBAAEBII@Z" ; public: unsigned int const & __cdecl CPVRTArray<unsigned int>::operator[](unsigned int) const
			PVRTexLibDLL[60]:="??A?$CPVRTArray@UMetaDataBlock@@@@QEAAAEAUMetaDataBlock@@I@Z" ; public: struct MetaDataBlock & __cdecl CPVRTArray<struct MetaDataBlock>::operator[](unsigned int)
			PVRTexLibDLL[61]:="??A?$CPVRTArray@UMetaDataBlock@@@@QEBAAEBUMetaDataBlock@@I@Z" ; public: struct MetaDataBlock const & __cdecl CPVRTArray<struct MetaDataBlock>::operator[](unsigned int) const
			PVRTexLibDLL[62]:="??A?$CPVRTArray@V?$CPVRTMap@IUMetaDataBlock@@@@@@QEAAAEAV?$CPVRTMap@IUMetaDataBlock@@@@I@Z" ; public: class CPVRTMap<unsigned int, struct MetaDataBlock> & __cdecl CPVRTArray<class CPVRTMap<unsigned int, struct MetaDataBlock>>::operator[](unsigned int)
			PVRTexLibDLL[63]:="??A?$CPVRTArray@V?$CPVRTMap@IUMetaDataBlock@@@@@@QEBAAEBV?$CPVRTMap@IUMetaDataBlock@@@@I@Z" ; public: class CPVRTMap<unsigned int, struct MetaDataBlock> const & __cdecl CPVRTArray<class CPVRTMap<unsigned int, struct MetaDataBlock>>::operator[](unsigned int) const
			PVRTexLibDLL[64]:="??A?$CPVRTMap@IUMetaDataBlock@@@@QEAAAEAUMetaDataBlock@@I@Z" ; public: struct MetaDataBlock & __cdecl CPVRTMap<unsigned int, struct MetaDataBlock>::operator[](unsigned int)
			PVRTexLibDLL[65]:="??A?$CPVRTMap@IV?$CPVRTMap@IUMetaDataBlock@@@@@@QEAAAEAV?$CPVRTMap@IUMetaDataBlock@@@@I@Z" ; public: class CPVRTMap<unsigned int, struct MetaDataBlock> & __cdecl CPVRTMap<unsigned int, class CPVRTMap<unsigned int, struct MetaDataBlock>>::operator[](unsigned int)
			PVRTexLibDLL[66]:="??ACPVRTString@@QEAAAEAD_K@Z" ; public: char & __cdecl CPVRTString::operator[](unsigned __int64)
			PVRTexLibDLL[67]:="??ACPVRTString@@QEBAAEBD_K@Z" ; public: char const & __cdecl CPVRTString::operator[](unsigned __int64) const
			PVRTexLibDLL[68]:="??MCPVRTString@@QEBA_NAEBV0@@Z" ; public: bool __cdecl CPVRTString::operator<(class CPVRTString const &) const
			PVRTexLibDLL[69]:="??YCPVRTString@@QEAAAEAV0@AEBV0@@Z" ; public: class CPVRTString & __cdecl CPVRTString::operator+=(class CPVRTString const &)
			PVRTexLibDLL[70]:="??YCPVRTString@@QEAAAEAV0@D@Z" ; public: class CPVRTString & __cdecl CPVRTString::operator+=(char)
			PVRTexLibDLL[71]:="??YCPVRTString@@QEAAAEAV0@PEBD@Z" ; public: class CPVRTString & __cdecl CPVRTString::operator+=(char const *)
			PVRTexLibDLL[72]:="??_7?$CPVRTArray@I@@6B@" ; const CPVRTArray<unsigned int>::`vftable'
			PVRTexLibDLL[73]:="??_7?$CPVRTArray@UMetaDataBlock@@@@6B@" ; const CPVRTArray<struct MetaDataBlock>::`vftable'
			PVRTexLibDLL[74]:="??_7?$CPVRTArray@V?$CPVRTMap@IUMetaDataBlock@@@@@@6B@" ; const CPVRTArray<class CPVRTMap<unsigned int, struct MetaDataBlock>>::`vftable'
			PVRTexLibDLL[75]:="??_7CPVRTString@@6B@" ; const CPVRTString::`vftable'
			PVRTexLibDLL[76]:="??_OCPVRTString@@QEAAXAEAV0@@Z" ; public: void __cdecl CPVRTString::`copy ctor closure'(class CPVRTString &)
			PVRTexLibDLL[77]:="?Append@?$CPVRTArray@I@@QEAAIAEBI@Z" ; public: unsigned int __cdecl CPVRTArray<unsigned int>::Append(unsigned int const &)
			PVRTexLibDLL[78]:="?Append@?$CPVRTArray@I@@QEAAIXZ" ; public: unsigned int __cdecl CPVRTArray<unsigned int>::Append(void)
			PVRTexLibDLL[79]:="?Append@?$CPVRTArray@UMetaDataBlock@@@@QEAAIAEBUMetaDataBlock@@@Z" ; public: unsigned int __cdecl CPVRTArray<struct MetaDataBlock>::Append(struct MetaDataBlock const &)
			PVRTexLibDLL[80]:="?Append@?$CPVRTArray@UMetaDataBlock@@@@QEAAIXZ" ; public: unsigned int __cdecl CPVRTArray<struct MetaDataBlock>::Append(void)
			PVRTexLibDLL[81]:="?Append@?$CPVRTArray@V?$CPVRTMap@IUMetaDataBlock@@@@@@QEAAIAEBV?$CPVRTMap@IUMetaDataBlock@@@@@Z" ; public: unsigned int __cdecl CPVRTArray<class CPVRTMap<unsigned int, struct MetaDataBlock>>::Append(class CPVRTMap<unsigned int, struct MetaDataBlock> const &)
			PVRTexLibDLL[82]:="?Append@?$CPVRTArray@V?$CPVRTMap@IUMetaDataBlock@@@@@@QEAAIXZ" ; public: unsigned int __cdecl CPVRTArray<class CPVRTMap<unsigned int, struct MetaDataBlock>>::Append(void)
			PVRTexLibDLL[83]:="?Bleed@pvrtexture@@YA_NAEAVCPVRTexture@1@@Z" ; bool __cdecl pvrtexture::Bleed(class pvrtexture::CPVRTexture &)
			PVRTexLibDLL[84]:="?Border@pvrtexture@@YA_NAEAVCPVRTexture@1@III@Z" ; bool __cdecl pvrtexture::Border(class pvrtexture::CPVRTexture &, unsigned int, unsigned int, unsigned int)
			PVRTexLibDLL[85]:="?Clear@?$CPVRTArray@I@@QEAAXXZ" ; public: void __cdecl CPVRTArray<unsigned int>::Clear(void)
			PVRTexLibDLL[86]:="?Clear@?$CPVRTArray@UMetaDataBlock@@@@QEAAXXZ" ; public: void __cdecl CPVRTArray<struct MetaDataBlock>::Clear(void)
			PVRTexLibDLL[87]:="?Clear@?$CPVRTArray@V?$CPVRTMap@IUMetaDataBlock@@@@@@QEAAXXZ" ; public: void __cdecl CPVRTArray<class CPVRTMap<unsigned int, struct MetaDataBlock>>::Clear(void)
			PVRTexLibDLL[88]:="?Clear@?$CPVRTMap@IUMetaDataBlock@@@@QEAAXXZ" ; public: void __cdecl CPVRTMap<unsigned int, struct MetaDataBlock>::Clear(void)
			PVRTexLibDLL[89]:="?Clear@?$CPVRTMap@IV?$CPVRTMap@IUMetaDataBlock@@@@@@QEAAXXZ" ; public: void __cdecl CPVRTMap<unsigned int, class CPVRTMap<unsigned int, struct MetaDataBlock>>::Clear(void)
			PVRTexLibDLL[90]:="?ColourMIPMaps@pvrtexture@@YA_NAEAVCPVRTexture@1@@Z" ; bool __cdecl pvrtexture::ColourMIPMaps(class pvrtexture::CPVRTexture &)
			PVRTexLibDLL[91]:="?CopyChannels@pvrtexture@@YA_NAEAVCPVRTexture@1@AEBV21@IPEAW4EChannelName@1@2@Z" ; bool __cdecl pvrtexture::CopyChannels(class pvrtexture::CPVRTexture &, class pvrtexture::CPVRTexture const &, unsigned int, enum pvrtexture::EChannelName *, enum pvrtexture::EChannelName *)
			PVRTexLibDLL[92]:="?Exists@?$CPVRTMap@IUMetaDataBlock@@@@QEBA_NI@Z" ; public: bool __cdecl CPVRTMap<unsigned int, struct MetaDataBlock>::Exists(unsigned int) const
			PVRTexLibDLL[93]:="?Flip@pvrtexture@@YA_NAEAVCPVRTexture@1@W4EPVRTAxis@@@Z" ; bool __cdecl pvrtexture::Flip(class pvrtexture::CPVRTexture &, enum EPVRTAxis)
			PVRTexLibDLL[94]:="?GenerateMIPMaps@pvrtexture@@YA_NAEAVCPVRTexture@1@W4EResizeMode@1@I@Z" ; bool __cdecl pvrtexture::GenerateMIPMaps(class pvrtexture::CPVRTexture &, enum pvrtexture::EResizeMode, unsigned int)
			PVRTexLibDLL[95]:="?GenerateNormalMap@pvrtexture@@YA_NAEAVCPVRTexture@1@MVCPVRTString@@@Z" ; bool __cdecl pvrtexture::GenerateNormalMap(class pvrtexture::CPVRTexture &, float, class CPVRTString)
			PVRTexLibDLL[96]:="?GetCapacity@?$CPVRTArray@I@@QEBAIXZ" ; public: unsigned int __cdecl CPVRTArray<unsigned int>::GetCapacity(void) const
			PVRTexLibDLL[97]:="?GetCapacity@?$CPVRTArray@UMetaDataBlock@@@@QEBAIXZ" ; public: unsigned int __cdecl CPVRTArray<struct MetaDataBlock>::GetCapacity(void) const
			PVRTexLibDLL[98]:="?GetCapacity@?$CPVRTArray@V?$CPVRTMap@IUMetaDataBlock@@@@@@QEBAIXZ" ; public: unsigned int __cdecl CPVRTArray<class CPVRTMap<unsigned int, struct MetaDataBlock>>::GetCapacity(void) const
			PVRTexLibDLL[99]:="?GetDataAtIndex@?$CPVRTMap@IUMetaDataBlock@@@@QEBAPEBUMetaDataBlock@@I@Z" ; public: struct MetaDataBlock const * __cdecl CPVRTMap<unsigned int, struct MetaDataBlock>::GetDataAtIndex(unsigned int) const
			PVRTexLibDLL[100]:="?GetDataAtIndex@?$CPVRTMap@IV?$CPVRTMap@IUMetaDataBlock@@@@@@QEBAPEBV?$CPVRTMap@IUMetaDataBlock@@@@I@Z" ; public: class CPVRTMap<unsigned int, struct MetaDataBlock> const * __cdecl CPVRTMap<unsigned int, class CPVRTMap<unsigned int, struct MetaDataBlock>>::GetDataAtIndex(unsigned int) const
			PVRTexLibDLL[101]:="?GetDefaultSize@?$CPVRTArray@I@@SAIXZ" ; public: static unsigned int __cdecl CPVRTArray<unsigned int>::GetDefaultSize(void)
			PVRTexLibDLL[102]:="?GetDefaultSize@?$CPVRTArray@UMetaDataBlock@@@@SAIXZ" ; public: static unsigned int __cdecl CPVRTArray<struct MetaDataBlock>::GetDefaultSize(void)
			PVRTexLibDLL[103]:="?GetDefaultSize@?$CPVRTArray@V?$CPVRTMap@IUMetaDataBlock@@@@@@SAIXZ" ; public: static unsigned int __cdecl CPVRTArray<class CPVRTMap<unsigned int, struct MetaDataBlock>>::GetDefaultSize(void)
			PVRTexLibDLL[104]:="?GetIndexOf@?$CPVRTMap@IUMetaDataBlock@@@@QEBAII@Z" ; public: unsigned int __cdecl CPVRTMap<unsigned int, struct MetaDataBlock>::GetIndexOf(unsigned int) const
			PVRTexLibDLL[105]:="?GetIndexOf@?$CPVRTMap@IV?$CPVRTMap@IUMetaDataBlock@@@@@@QEBAII@Z" ; public: unsigned int __cdecl CPVRTMap<unsigned int, class CPVRTMap<unsigned int, struct MetaDataBlock>>::GetIndexOf(unsigned int) const
			PVRTexLibDLL[106]:="?GetSize@?$CPVRTArray@I@@QEBAIXZ" ; public: unsigned int __cdecl CPVRTArray<unsigned int>::GetSize(void) const
			PVRTexLibDLL[107]:="?GetSize@?$CPVRTArray@UMetaDataBlock@@@@QEBAIXZ" ; public: unsigned int __cdecl CPVRTArray<struct MetaDataBlock>::GetSize(void) const
			PVRTexLibDLL[108]:="?GetSize@?$CPVRTArray@V?$CPVRTMap@IUMetaDataBlock@@@@@@QEBAIXZ" ; public: unsigned int __cdecl CPVRTArray<class CPVRTMap<unsigned int, struct MetaDataBlock>>::GetSize(void) const
			PVRTexLibDLL[109]:="?GetSize@?$CPVRTMap@IUMetaDataBlock@@@@QEBAIXZ" ; public: unsigned int __cdecl CPVRTMap<unsigned int, struct MetaDataBlock>::GetSize(void) const
			PVRTexLibDLL[110]:="?GetSize@?$CPVRTMap@IV?$CPVRTMap@IUMetaDataBlock@@@@@@QEBAIXZ" ; public: unsigned int __cdecl CPVRTMap<unsigned int, class CPVRTMap<unsigned int, struct MetaDataBlock>>::GetSize(void) const
			PVRTexLibDLL[111]:="?PreMultiplyAlpha@pvrtexture@@YA_NAEAVCPVRTexture@1@@Z" ; bool __cdecl pvrtexture::PreMultiplyAlpha(class pvrtexture::CPVRTexture &)
			PVRTexLibDLL[112]:="?Remove@?$CPVRTArray@I@@UEAA?AW4EPVRTError@@I@Z" ; public: virtual enum EPVRTError __cdecl CPVRTArray<unsigned int>::Remove(unsigned int)
			PVRTexLibDLL[113]:="?Remove@?$CPVRTArray@UMetaDataBlock@@@@UEAA?AW4EPVRTError@@I@Z" ; public: virtual enum EPVRTError __cdecl CPVRTArray<struct MetaDataBlock>::Remove(unsigned int)
			PVRTexLibDLL[114]:="?Remove@?$CPVRTArray@V?$CPVRTMap@IUMetaDataBlock@@@@@@UEAA?AW4EPVRTError@@I@Z" ; public: virtual enum EPVRTError __cdecl CPVRTArray<class CPVRTMap<unsigned int, struct MetaDataBlock>>::Remove(unsigned int)
			PVRTexLibDLL[115]:="?Remove@?$CPVRTMap@IUMetaDataBlock@@@@QEAA?AW4EPVRTError@@I@Z" ; public: enum EPVRTError __cdecl CPVRTMap<unsigned int, struct MetaDataBlock>::Remove(unsigned int)
			PVRTexLibDLL[116]:="?RemoveLast@?$CPVRTArray@I@@UEAA?AW4EPVRTError@@XZ" ; public: virtual enum EPVRTError __cdecl CPVRTArray<unsigned int>::RemoveLast(void)
			PVRTexLibDLL[117]:="?RemoveLast@?$CPVRTArray@UMetaDataBlock@@@@UEAA?AW4EPVRTError@@XZ" ; public: virtual enum EPVRTError __cdecl CPVRTArray<struct MetaDataBlock>::RemoveLast(void)
			PVRTexLibDLL[118]:="?RemoveLast@?$CPVRTArray@V?$CPVRTMap@IUMetaDataBlock@@@@@@UEAA?AW4EPVRTError@@XZ" ; public: virtual enum EPVRTError __cdecl CPVRTArray<class CPVRTMap<unsigned int, struct MetaDataBlock>>::RemoveLast(void)
			PVRTexLibDLL[119]:="?Resize@pvrtexture@@YA_NAEAVCPVRTexture@1@AEBI11W4EResizeMode@1@@Z" ; bool __cdecl pvrtexture::Resize(class pvrtexture::CPVRTexture &, unsigned int const &, unsigned int const &, unsigned int const &, enum pvrtexture::EResizeMode)
			PVRTexLibDLL[120]:="?ResizeCanvas@pvrtexture@@YA_NAEAVCPVRTexture@1@AEBI11AEBH22@Z" ; bool __cdecl pvrtexture::ResizeCanvas(class pvrtexture::CPVRTexture &, unsigned int const &, unsigned int const &, unsigned int const &, int const &, int const &, int const &)
			PVRTexLibDLL[121]:="?Rotate90@pvrtexture@@YA_NAEAVCPVRTexture@1@W4EPVRTAxis@@_N@Z" ; bool __cdecl pvrtexture::Rotate90(class pvrtexture::CPVRTexture &, enum EPVRTAxis, bool)
			PVRTexLibDLL[122]:="?SetCapacity@?$CPVRTArray@I@@QEAA?AW4EPVRTError@@I@Z" ; public: enum EPVRTError __cdecl CPVRTArray<unsigned int>::SetCapacity(unsigned int)
			PVRTexLibDLL[123]:="?SetCapacity@?$CPVRTArray@UMetaDataBlock@@@@QEAA?AW4EPVRTError@@I@Z" ; public: enum EPVRTError __cdecl CPVRTArray<struct MetaDataBlock>::SetCapacity(unsigned int)
			PVRTexLibDLL[124]:="?SetCapacity@?$CPVRTArray@V?$CPVRTMap@IUMetaDataBlock@@@@@@QEAA?AW4EPVRTError@@I@Z" ; public: enum EPVRTError __cdecl CPVRTArray<class CPVRTMap<unsigned int, struct MetaDataBlock>>::SetCapacity(unsigned int)
			PVRTexLibDLL[125]:="?SetChannels@pvrtexture@@YA_NAEAVCPVRTexture@1@IPEAW4EChannelName@1@PEAI@Z" ; bool __cdecl pvrtexture::SetChannels(class pvrtexture::CPVRTexture &, unsigned int, enum pvrtexture::EChannelName *, unsigned int *)
			PVRTexLibDLL[126]:="?SetChannelsFloat@pvrtexture@@YA_NAEAVCPVRTexture@1@IPEAW4EChannelName@1@PEAM@Z" ; bool __cdecl pvrtexture::SetChannelsFloat(class pvrtexture::CPVRTexture &, unsigned int, enum pvrtexture::EChannelName *, float *)
			PVRTexLibDLL[127]:="?SizeOfBlock@MetaDataBlock@@QEBA_KXZ" ; public: unsigned __int64 __cdecl MetaDataBlock::SizeOfBlock(void) const
			PVRTexLibDLL[128]:="?Transcode@pvrtexture@@YA_NAEAVCPVRTexture@1@TPixelType@1@W4EPVRTVariableType@@W4EPVRTColourSpace@@W4ECompressorQuality@1@_N@Z" ; bool __cdecl pvrtexture::Transcode(class pvrtexture::CPVRTexture &, union pvrtexture::PixelType, enum EPVRTVariableType, enum EPVRTColourSpace, enum pvrtexture::ECompressorQuality, bool)
			PVRTexLibDLL[129]:="?addMetaData@CPVRTextureHeader@pvrtexture@@QEAAXAEBUMetaDataBlock@@@Z" ; public: void __cdecl pvrtexture::CPVRTextureHeader::addMetaData(struct MetaDataBlock const &)
			PVRTexLibDLL[130]:="?addPaddingMetaData@CPVRTexture@pvrtexture@@QEAAXI@Z" ; public: void __cdecl pvrtexture::CPVRTexture::addPaddingMetaData(unsigned int)
			PVRTexLibDLL[131]:="?append@CPVRTString@@QEAAAEAV1@AEBV1@@Z" ; public: class CPVRTString & __cdecl CPVRTString::append(class CPVRTString const &)
			PVRTexLibDLL[132]:="?append@CPVRTString@@QEAAAEAV1@AEBV1@_K1@Z" ; public: class CPVRTString & __cdecl CPVRTString::append(class CPVRTString const &, unsigned __int64, unsigned __int64)
			PVRTexLibDLL[133]:="?append@CPVRTString@@QEAAAEAV1@PEBD@Z" ; public: class CPVRTString & __cdecl CPVRTString::append(char const *)
			PVRTexLibDLL[134]:="?append@CPVRTString@@QEAAAEAV1@PEBD_K@Z" ; public: class CPVRTString & __cdecl CPVRTString::append(char const *, unsigned __int64)
			PVRTexLibDLL[135]:="?append@CPVRTString@@QEAAAEAV1@_KD@Z" ; public: class CPVRTString & __cdecl CPVRTString::append(unsigned __int64, char)
			PVRTexLibDLL[136]:="?assign@CPVRTString@@QEAAAEAV1@AEBV1@@Z" ; public: class CPVRTString & __cdecl CPVRTString::assign(class CPVRTString const &)
			PVRTexLibDLL[137]:="?assign@CPVRTString@@QEAAAEAV1@AEBV1@_K1@Z" ; public: class CPVRTString & __cdecl CPVRTString::assign(class CPVRTString const &, unsigned __int64, unsigned __int64)
			PVRTexLibDLL[138]:="?assign@CPVRTString@@QEAAAEAV1@PEBD@Z" ; public: class CPVRTString & __cdecl CPVRTString::assign(char const *)
			PVRTexLibDLL[139]:="?assign@CPVRTString@@QEAAAEAV1@PEBD_K@Z" ; public: class CPVRTString & __cdecl CPVRTString::assign(char const *, unsigned __int64)
			PVRTexLibDLL[140]:="?assign@CPVRTString@@QEAAAEAV1@_KD@Z" ; public: class CPVRTString & __cdecl CPVRTString::assign(unsigned __int64, char)
			PVRTexLibDLL[141]:="?c_str@CPVRTString@@QEBAPEBDXZ" ; public: char const * __cdecl CPVRTString::c_str(void) const
			PVRTexLibDLL[142]:="?capacity@CPVRTString@@QEBA_KXZ" ; public: unsigned __int64 __cdecl CPVRTString::capacity(void) const
			PVRTexLibDLL[143]:="?clear@CPVRTString@@QEAAXXZ" ; public: void __cdecl CPVRTString::clear(void)
			PVRTexLibDLL[144]:="?compare@CPVRTString@@QEBAHAEBV1@@Z" ; public: int __cdecl CPVRTString::compare(class CPVRTString const &) const
			PVRTexLibDLL[145]:="?compare@CPVRTString@@QEBAHPEBD@Z" ; public: int __cdecl CPVRTString::compare(char const *) const
			PVRTexLibDLL[146]:="?compare@CPVRTString@@QEBAH_K0AEBV1@00@Z" ; public: int __cdecl CPVRTString::compare(unsigned __int64, unsigned __int64, class CPVRTString const &, unsigned __int64, unsigned __int64) const
			PVRTexLibDLL[147]:="?compare@CPVRTString@@QEBAH_K0AEBV1@@Z" ; public: int __cdecl CPVRTString::compare(unsigned __int64, unsigned __int64, class CPVRTString const &) const
			PVRTexLibDLL[148]:="?compare@CPVRTString@@QEBAH_K0PEBD0@Z" ; public: int __cdecl CPVRTString::compare(unsigned __int64, unsigned __int64, char const *, unsigned __int64) const
			PVRTexLibDLL[149]:="?compare@CPVRTString@@QEBAH_K0PEBD@Z" ; public: int __cdecl CPVRTString::compare(unsigned __int64, unsigned __int64, char const *) const
			PVRTexLibDLL[150]:="?copy@CPVRTString@@QEBA_KPEAD_K1@Z" ; public: unsigned __int64 __cdecl CPVRTString::copy(char *, unsigned __int64, unsigned __int64) const
			PVRTexLibDLL[151]:="?data@CPVRTString@@QEBAPEBDXZ" ; public: char const * __cdecl CPVRTString::data(void) const
			PVRTexLibDLL[152]:="?empty@CPVRTString@@QEBA_NXZ" ; public: bool __cdecl CPVRTString::empty(void) const
			PVRTexLibDLL[153]:="?erase@CPVRTString@@QEAAAEAV1@_K0@Z" ; public: class CPVRTString & __cdecl CPVRTString::erase(unsigned __int64, unsigned __int64)
			PVRTexLibDLL[154]:="?find@CPVRTString@@QEBA_KAEBV1@_K@Z" ; public: unsigned __int64 __cdecl CPVRTString::find(class CPVRTString const &, unsigned __int64) const
			PVRTexLibDLL[155]:="?find@CPVRTString@@QEBA_KPEBD_K1@Z" ; public: unsigned __int64 __cdecl CPVRTString::find(char const *, unsigned __int64, unsigned __int64) const
			PVRTexLibDLL[156]:="?find_first_not_of@CPVRTString@@QEBA_KAEBV1@_K@Z" ; public: unsigned __int64 __cdecl CPVRTString::find_first_not_of(class CPVRTString const &, unsigned __int64) const
			PVRTexLibDLL[157]:="?find_first_not_of@CPVRTString@@QEBA_KD_K@Z" ; public: unsigned __int64 __cdecl CPVRTString::find_first_not_of(char, unsigned __int64) const
			PVRTexLibDLL[158]:="?find_first_not_of@CPVRTString@@QEBA_KPEBD_K1@Z" ; public: unsigned __int64 __cdecl CPVRTString::find_first_not_of(char const *, unsigned __int64, unsigned __int64) const
			PVRTexLibDLL[159]:="?find_first_not_of@CPVRTString@@QEBA_KPEBD_K@Z" ; public: unsigned __int64 __cdecl CPVRTString::find_first_not_of(char const *, unsigned __int64) const
			PVRTexLibDLL[160]:="?find_first_of@CPVRTString@@QEBA_KAEBV1@_K@Z" ; public: unsigned __int64 __cdecl CPVRTString::find_first_of(class CPVRTString const &, unsigned __int64) const
			PVRTexLibDLL[161]:="?find_first_of@CPVRTString@@QEBA_KD_K@Z" ; public: unsigned __int64 __cdecl CPVRTString::find_first_of(char, unsigned __int64) const
			PVRTexLibDLL[162]:="?find_first_of@CPVRTString@@QEBA_KPEBD_K1@Z" ; public: unsigned __int64 __cdecl CPVRTString::find_first_of(char const *, unsigned __int64, unsigned __int64) const
			PVRTexLibDLL[163]:="?find_first_of@CPVRTString@@QEBA_KPEBD_K@Z" ; public: unsigned __int64 __cdecl CPVRTString::find_first_of(char const *, unsigned __int64) const
			PVRTexLibDLL[164]:="?find_first_ofn@CPVRTString@@QEBA_KPEBD_K1@Z" ; public: unsigned __int64 __cdecl CPVRTString::find_first_ofn(char const *, unsigned __int64, unsigned __int64) const
			PVRTexLibDLL[165]:="?find_last_not_of@CPVRTString@@QEBA_KAEBV1@_K@Z" ; public: unsigned __int64 __cdecl CPVRTString::find_last_not_of(class CPVRTString const &, unsigned __int64) const
			PVRTexLibDLL[166]:="?find_last_not_of@CPVRTString@@QEBA_KD_K@Z" ; public: unsigned __int64 __cdecl CPVRTString::find_last_not_of(char, unsigned __int64) const
			PVRTexLibDLL[167]:="?find_last_not_of@CPVRTString@@QEBA_KPEBD_K1@Z" ; public: unsigned __int64 __cdecl CPVRTString::find_last_not_of(char const *, unsigned __int64, unsigned __int64) const
			PVRTexLibDLL[168]:="?find_last_not_of@CPVRTString@@QEBA_KPEBD_K@Z" ; public: unsigned __int64 __cdecl CPVRTString::find_last_not_of(char const *, unsigned __int64) const
			PVRTexLibDLL[169]:="?find_last_of@CPVRTString@@QEBA_KAEBV1@_K@Z" ; public: unsigned __int64 __cdecl CPVRTString::find_last_of(class CPVRTString const &, unsigned __int64) const
			PVRTexLibDLL[170]:="?find_last_of@CPVRTString@@QEBA_KD_K@Z" ; public: unsigned __int64 __cdecl CPVRTString::find_last_of(char, unsigned __int64) const
			PVRTexLibDLL[171]:="?find_last_of@CPVRTString@@QEBA_KPEBD_K1@Z" ; public: unsigned __int64 __cdecl CPVRTString::find_last_of(char const *, unsigned __int64, unsigned __int64) const
			PVRTexLibDLL[172]:="?find_last_of@CPVRTString@@QEBA_KPEBD_K@Z" ; public: unsigned __int64 __cdecl CPVRTString::find_last_of(char const *, unsigned __int64) const
			PVRTexLibDLL[173]:="?find_next_occurance_of@CPVRTString@@QEBAHAEBV1@_K@Z" ; public: int __cdecl CPVRTString::find_next_occurance_of(class CPVRTString const &, unsigned __int64) const
			PVRTexLibDLL[174]:="?find_next_occurance_of@CPVRTString@@QEBAHD_K@Z" ; public: int __cdecl CPVRTString::find_next_occurance_of(char, unsigned __int64) const
			PVRTexLibDLL[175]:="?find_next_occurance_of@CPVRTString@@QEBAHPEBD_K1@Z" ; public: int __cdecl CPVRTString::find_next_occurance_of(char const *, unsigned __int64, unsigned __int64) const
			PVRTexLibDLL[176]:="?find_next_occurance_of@CPVRTString@@QEBAHPEBD_K@Z" ; public: int __cdecl CPVRTString::find_next_occurance_of(char const *, unsigned __int64) const
			PVRTexLibDLL[177]:="?find_number_of@CPVRTString@@QEBA_KAEBV1@_K@Z" ; public: unsigned __int64 __cdecl CPVRTString::find_number_of(class CPVRTString const &, unsigned __int64) const
			PVRTexLibDLL[178]:="?find_number_of@CPVRTString@@QEBA_KD_K@Z" ; public: unsigned __int64 __cdecl CPVRTString::find_number_of(char, unsigned __int64) const
			PVRTexLibDLL[179]:="?find_number_of@CPVRTString@@QEBA_KPEBD_K1@Z" ; public: unsigned __int64 __cdecl CPVRTString::find_number_of(char const *, unsigned __int64, unsigned __int64) const
			PVRTexLibDLL[180]:="?find_number_of@CPVRTString@@QEBA_KPEBD_K@Z" ; public: unsigned __int64 __cdecl CPVRTString::find_number_of(char const *, unsigned __int64) const
			PVRTexLibDLL[181]:="?find_previous_occurance_of@CPVRTString@@QEBAHAEBV1@_K@Z" ; public: int __cdecl CPVRTString::find_previous_occurance_of(class CPVRTString const &, unsigned __int64) const
			PVRTexLibDLL[182]:="?find_previous_occurance_of@CPVRTString@@QEBAHD_K@Z" ; public: int __cdecl CPVRTString::find_previous_occurance_of(char, unsigned __int64) const
			PVRTexLibDLL[183]:="?find_previous_occurance_of@CPVRTString@@QEBAHPEBD_K1@Z" ; public: int __cdecl CPVRTString::find_previous_occurance_of(char const *, unsigned __int64, unsigned __int64) const
			PVRTexLibDLL[184]:="?find_previous_occurance_of@CPVRTString@@QEBAHPEBD_K@Z" ; public: int __cdecl CPVRTString::find_previous_occurance_of(char const *, unsigned __int64) const
			PVRTexLibDLL[185]:="?format@CPVRTString@@QEAA?AV1@PEBDZZ" ; public: class CPVRTString __cdecl CPVRTString::format(char const *)
			PVRTexLibDLL[186]:="?formatPositional@CPVRTString@@QEAA?AV1@PEBDZZ" ; public: class CPVRTString __cdecl CPVRTString::formatPositional(char const *)
			PVRTexLibDLL[187]:="?getBitsPerPixel@CPVRTextureHeader@pvrtexture@@QEBAIXZ" ; public: unsigned int __cdecl pvrtexture::CPVRTextureHeader::getBitsPerPixel(void) const
			PVRTexLibDLL[188]:="?getBorder@CPVRTextureHeader@pvrtexture@@QEBAXAEAI00@Z" ; public: void __cdecl pvrtexture::CPVRTextureHeader::getBorder(unsigned int &, unsigned int &, unsigned int &) const
			PVRTexLibDLL[189]:="?getBumpMapOrder@CPVRTextureHeader@pvrtexture@@QEBA?AVCPVRTString@@XZ" ; public: class CPVRTString __cdecl pvrtexture::CPVRTextureHeader::getBumpMapOrder(void) const
			PVRTexLibDLL[190]:="?getBumpMapScale@CPVRTextureHeader@pvrtexture@@QEBAMXZ" ; public: float __cdecl pvrtexture::CPVRTextureHeader::getBumpMapScale(void) const
			PVRTexLibDLL[191]:="?getChannelType@CPVRTextureHeader@pvrtexture@@QEBA?AW4EPVRTVariableType@@XZ" ; public: enum EPVRTVariableType __cdecl pvrtexture::CPVRTextureHeader::getChannelType(void) const
			PVRTexLibDLL[192]:="?getColourSpace@CPVRTextureHeader@pvrtexture@@QEBA?AW4EPVRTColourSpace@@XZ" ; public: enum EPVRTColourSpace __cdecl pvrtexture::CPVRTextureHeader::getColourSpace(void) const
			PVRTexLibDLL[193]:="?getCubeMapOrder@CPVRTextureHeader@pvrtexture@@QEBA?AVCPVRTString@@XZ" ; public: class CPVRTString __cdecl pvrtexture::CPVRTextureHeader::getCubeMapOrder(void) const
			PVRTexLibDLL[194]:="?getD3DFormat@CPVRTextureHeader@pvrtexture@@QEBAIXZ" ; public: unsigned int __cdecl pvrtexture::CPVRTextureHeader::getD3DFormat(void) const
			PVRTexLibDLL[195]:="?getDXGIFormat@CPVRTextureHeader@pvrtexture@@QEBAIXZ" ; public: unsigned int __cdecl pvrtexture::CPVRTextureHeader::getDXGIFormat(void) const
			PVRTexLibDLL[196]:="?getDataPtr@CPVRTexture@pvrtexture@@QEBAPEAXIII@Z" ; public: void * __cdecl pvrtexture::CPVRTexture::getDataPtr(unsigned int, unsigned int, unsigned int) const
			PVRTexLibDLL[197]:="?getDataSize@CPVRTextureHeader@pvrtexture@@QEBAIH_N0@Z" ; public: unsigned int __cdecl pvrtexture::CPVRTextureHeader::getDataSize(int, bool, bool) const
			PVRTexLibDLL[198]:="?getDepth@CPVRTextureHeader@pvrtexture@@QEBAII@Z" ; public: unsigned int __cdecl pvrtexture::CPVRTextureHeader::getDepth(unsigned int) const
			PVRTexLibDLL[199]:="?getFileHeader@CPVRTextureHeader@pvrtexture@@QEBA?AUPVRTextureHeaderV3@@XZ" ; public: struct PVRTextureHeaderV3 __cdecl pvrtexture::CPVRTextureHeader::getFileHeader(void) const
			PVRTexLibDLL[200]:="?getHeader@CPVRTexture@pvrtexture@@QEBAAEBVCPVRTextureHeader@2@XZ" ; public: class pvrtexture::CPVRTextureHeader const & __cdecl pvrtexture::CPVRTexture::getHeader(void) const
			PVRTexLibDLL[201]:="?getHeight@CPVRTextureHeader@pvrtexture@@QEBAII@Z" ; public: unsigned int __cdecl pvrtexture::CPVRTextureHeader::getHeight(unsigned int) const
			PVRTexLibDLL[202]:="?getMetaData@CPVRTextureHeader@pvrtexture@@QEBA?AUMetaDataBlock@@II@Z" ; public: struct MetaDataBlock __cdecl pvrtexture::CPVRTextureHeader::getMetaData(unsigned int, unsigned int) const
			PVRTexLibDLL[203]:="?getMetaDataMap@CPVRTextureHeader@pvrtexture@@QEBAPEBV?$CPVRTMap@IV?$CPVRTMap@IUMetaDataBlock@@@@@@XZ" ; public: class CPVRTMap<unsigned int, class CPVRTMap<unsigned int, struct MetaDataBlock>> const * __cdecl pvrtexture::CPVRTextureHeader::getMetaDataMap(void) const
			PVRTexLibDLL[204]:="?getMetaDataSize@CPVRTextureHeader@pvrtexture@@QEBAIXZ" ; public: unsigned int __cdecl pvrtexture::CPVRTextureHeader::getMetaDataSize(void) const
			PVRTexLibDLL[205]:="?getNumArrayMembers@CPVRTextureHeader@pvrtexture@@QEBAIXZ" ; public: unsigned int __cdecl pvrtexture::CPVRTextureHeader::getNumArrayMembers(void) const
			PVRTexLibDLL[206]:="?getNumFaces@CPVRTextureHeader@pvrtexture@@QEBAIXZ" ; public: unsigned int __cdecl pvrtexture::CPVRTextureHeader::getNumFaces(void) const
			PVRTexLibDLL[207]:="?getNumMIPLevels@CPVRTextureHeader@pvrtexture@@QEBAIXZ" ; public: unsigned int __cdecl pvrtexture::CPVRTextureHeader::getNumMIPLevels(void) const
			PVRTexLibDLL[208]:="?getNumTextureAtlasMembers@CPVRTextureHeader@pvrtexture@@QEBAHXZ" ; public: int __cdecl pvrtexture::CPVRTextureHeader::getNumTextureAtlasMembers(void) const
			PVRTexLibDLL[209]:="?getOGLESFormat@CPVRTextureHeader@pvrtexture@@QEBAXAEAI00@Z" ; public: void __cdecl pvrtexture::CPVRTextureHeader::getOGLESFormat(unsigned int &, unsigned int &, unsigned int &) const
			PVRTexLibDLL[210]:="?getOGLFormat@CPVRTextureHeader@pvrtexture@@QEBAXAEAI00@Z" ; public: void __cdecl pvrtexture::CPVRTextureHeader::getOGLFormat(unsigned int &, unsigned int &, unsigned int &) const
			PVRTexLibDLL[211]:="?getOrientation@CPVRTextureHeader@pvrtexture@@QEBA?AW4EPVRTOrientation@@W4EPVRTAxis@@@Z" ; public: enum EPVRTOrientation __cdecl pvrtexture::CPVRTextureHeader::getOrientation(enum EPVRTAxis) const
			PVRTexLibDLL[212]:="?getPixelType@CPVRTextureHeader@pvrtexture@@QEBA?ATPixelType@2@XZ" ; public: union pvrtexture::PixelType __cdecl pvrtexture::CPVRTextureHeader::getPixelType(void) const
			PVRTexLibDLL[213]:="?getTextureAtlasData@CPVRTextureHeader@pvrtexture@@QEBAPEBMXZ" ; public: float const * __cdecl pvrtexture::CPVRTextureHeader::getTextureAtlasData(void) const
			PVRTexLibDLL[214]:="?getTextureSize@CPVRTextureHeader@pvrtexture@@QEBAIH_N0@Z" ; public: unsigned int __cdecl pvrtexture::CPVRTextureHeader::getTextureSize(int, bool, bool) const
			PVRTexLibDLL[215]:="?getVulkanFormat@CPVRTextureHeader@pvrtexture@@QEBAIXZ" ; public: unsigned int __cdecl pvrtexture::CPVRTextureHeader::getVulkanFormat(void) const
			PVRTexLibDLL[216]:="?getWidth@CPVRTextureHeader@pvrtexture@@QEBAII@Z" ; public: unsigned int __cdecl pvrtexture::CPVRTextureHeader::getWidth(unsigned int) const
			PVRTexLibDLL[217]:="?hasMetaData@CPVRTextureHeader@pvrtexture@@QEBA_NII@Z" ; public: bool __cdecl pvrtexture::CPVRTextureHeader::hasMetaData(unsigned int, unsigned int) const
			PVRTexLibDLL[218]:="?isBumpMap@CPVRTextureHeader@pvrtexture@@QEBA_NXZ" ; public: bool __cdecl pvrtexture::CPVRTextureHeader::isBumpMap(void) const
			PVRTexLibDLL[219]:="?isFileCompressed@CPVRTextureHeader@pvrtexture@@QEBA_NXZ" ; public: bool __cdecl pvrtexture::CPVRTextureHeader::isFileCompressed(void) const
			PVRTexLibDLL[220]:="?isPreMultiplied@CPVRTextureHeader@pvrtexture@@QEBA_NXZ" ; public: bool __cdecl pvrtexture::CPVRTextureHeader::isPreMultiplied(void) const
			PVRTexLibDLL[221]:="?left@CPVRTString@@QEBA?AV1@_K@Z" ; public: class CPVRTString __cdecl CPVRTString::left(unsigned __int64) const
			PVRTexLibDLL[222]:="?length@CPVRTString@@QEBA_KXZ" ; public: unsigned __int64 __cdecl CPVRTString::length(void) const
			PVRTexLibDLL[223]:="?max_size@CPVRTString@@QEBA_KXZ" ; public: unsigned __int64 __cdecl CPVRTString::max_size(void) const
			PVRTexLibDLL[224]:="?npos@CPVRTString@@2_KB" ; public: static unsigned __int64 const CPVRTString::npos
			PVRTexLibDLL[225]:="?privateLoadASTCFile@CPVRTexture@pvrtexture@@AEAA_NPEAU_iobuf@@@Z" ; private: bool __cdecl pvrtexture::CPVRTexture::privateLoadASTCFile(struct _iobuf *)
			PVRTexLibDLL[226]:="?privateLoadDDSFile@CPVRTexture@pvrtexture@@AEAA_NPEAU_iobuf@@@Z" ; private: bool __cdecl pvrtexture::CPVRTexture::privateLoadDDSFile(struct _iobuf *)
			PVRTexLibDLL[227]:="?privateLoadKTXFile@CPVRTexture@pvrtexture@@AEAA_NPEAU_iobuf@@@Z" ; private: bool __cdecl pvrtexture::CPVRTexture::privateLoadKTXFile(struct _iobuf *)
			PVRTexLibDLL[228]:="?privateLoadPVRFile@CPVRTexture@pvrtexture@@AEAA_NPEAU_iobuf@@@Z" ; private: bool __cdecl pvrtexture::CPVRTexture::privateLoadPVRFile(struct _iobuf *)
			PVRTexLibDLL[229]:="?privateSaveASTCFile@CPVRTexture@pvrtexture@@AEBA_NPEAU_iobuf@@@Z" ; private: bool __cdecl pvrtexture::CPVRTexture::privateSaveASTCFile(struct _iobuf *) const
			PVRTexLibDLL[230]:="?privateSaveCHeaderFile@CPVRTexture@pvrtexture@@AEBA_NPEAU_iobuf@@VCPVRTString@@@Z" ; private: bool __cdecl pvrtexture::CPVRTexture::privateSaveCHeaderFile(struct _iobuf *, class CPVRTString) const
			PVRTexLibDLL[231]:="?privateSaveDDSFile@CPVRTexture@pvrtexture@@AEBA_NPEAU_iobuf@@@Z" ; private: bool __cdecl pvrtexture::CPVRTexture::privateSaveDDSFile(struct _iobuf *) const
			PVRTexLibDLL[232]:="?privateSaveKTXFile@CPVRTexture@pvrtexture@@AEBA_NPEAU_iobuf@@@Z" ; private: bool __cdecl pvrtexture::CPVRTexture::privateSaveKTXFile(struct _iobuf *) const
			PVRTexLibDLL[233]:="?privateSaveLegacyPVRFile@CPVRTexture@pvrtexture@@AEBA_NPEAU_iobuf@@W4ELegacyApi@2@@Z" ; private: bool __cdecl pvrtexture::CPVRTexture::privateSaveLegacyPVRFile(struct _iobuf *, enum pvrtexture::ELegacyApi) const
			PVRTexLibDLL[234]:="?privateSavePVRFile@CPVRTexture@pvrtexture@@AEBA_NPEAU_iobuf@@@Z" ; private: bool __cdecl pvrtexture::CPVRTexture::privateSavePVRFile(struct _iobuf *) const
			PVRTexLibDLL[235]:="?push_back@CPVRTString@@QEAAXD@Z" ; public: void __cdecl CPVRTString::push_back(char)
			PVRTexLibDLL[236]:="?removeMetaData@CPVRTextureHeader@pvrtexture@@QEAAXAEBI0@Z" ; public: void __cdecl pvrtexture::CPVRTextureHeader::removeMetaData(unsigned int const &, unsigned int const &)
			PVRTexLibDLL[237]:="?reserve@CPVRTString@@QEAAX_K@Z" ; public: void __cdecl CPVRTString::reserve(unsigned __int64)
			PVRTexLibDLL[238]:="?resize@CPVRTString@@QEAAX_KD@Z" ; public: void __cdecl CPVRTString::resize(unsigned __int64, char)
			PVRTexLibDLL[239]:="?right@CPVRTString@@QEBA?AV1@_K@Z" ; public: class CPVRTString __cdecl CPVRTString::right(unsigned __int64) const
			PVRTexLibDLL[240]:="?saveASTCFile@CPVRTexture@pvrtexture@@QEBA_NAEBVCPVRTString@@@Z" ; public: bool __cdecl pvrtexture::CPVRTexture::saveASTCFile(class CPVRTString const &) const
			PVRTexLibDLL[241]:="?saveFile@CPVRTexture@pvrtexture@@QEBA_NAEBVCPVRTString@@@Z" ; public: bool __cdecl pvrtexture::CPVRTexture::saveFile(class CPVRTString const &) const
			PVRTexLibDLL[242]:="?saveFileLegacyPVR@CPVRTexture@pvrtexture@@QEBA_NAEBVCPVRTString@@W4ELegacyApi@2@@Z" ; public: bool __cdecl pvrtexture::CPVRTexture::saveFileLegacyPVR(class CPVRTString const &, enum pvrtexture::ELegacyApi) const
			PVRTexLibDLL[243]:="?setBorder@CPVRTextureHeader@pvrtexture@@QEAAXIII@Z" ; public: void __cdecl pvrtexture::CPVRTextureHeader::setBorder(unsigned int, unsigned int, unsigned int)
			PVRTexLibDLL[244]:="?setBumpMap@CPVRTextureHeader@pvrtexture@@QEAAXMVCPVRTString@@@Z" ; public: void __cdecl pvrtexture::CPVRTextureHeader::setBumpMap(float, class CPVRTString)
			PVRTexLibDLL[245]:="?setChannelType@CPVRTextureHeader@pvrtexture@@QEAAXW4EPVRTVariableType@@@Z" ; public: void __cdecl pvrtexture::CPVRTextureHeader::setChannelType(enum EPVRTVariableType)
			PVRTexLibDLL[246]:="?setColourSpace@CPVRTextureHeader@pvrtexture@@QEAAXW4EPVRTColourSpace@@@Z" ; public: void __cdecl pvrtexture::CPVRTextureHeader::setColourSpace(enum EPVRTColourSpace)
			PVRTexLibDLL[247]:="?setCubeMapOrder@CPVRTextureHeader@pvrtexture@@QEAAXVCPVRTString@@@Z" ; public: void __cdecl pvrtexture::CPVRTextureHeader::setCubeMapOrder(class CPVRTString)
			PVRTexLibDLL[248]:="?setD3DFormat@CPVRTextureHeader@pvrtexture@@QEAA_NAEBI@Z" ; public: bool __cdecl pvrtexture::CPVRTextureHeader::setD3DFormat(unsigned int const &)
			PVRTexLibDLL[249]:="?setDXGIFormat@CPVRTextureHeader@pvrtexture@@QEAA_NAEBI@Z" ; public: bool __cdecl pvrtexture::CPVRTextureHeader::setDXGIFormat(unsigned int const &)
			PVRTexLibDLL[250]:="?setDepth@CPVRTextureHeader@pvrtexture@@QEAAXI@Z" ; public: void __cdecl pvrtexture::CPVRTextureHeader::setDepth(unsigned int)
			PVRTexLibDLL[251]:="?setHeight@CPVRTextureHeader@pvrtexture@@QEAAXI@Z" ; public: void __cdecl pvrtexture::CPVRTextureHeader::setHeight(unsigned int)
			PVRTexLibDLL[252]:="?setIsFileCompressed@CPVRTextureHeader@pvrtexture@@QEAAX_N@Z" ; public: void __cdecl pvrtexture::CPVRTextureHeader::setIsFileCompressed(bool)
			PVRTexLibDLL[253]:="?setIsPreMultiplied@CPVRTextureHeader@pvrtexture@@QEAAX_N@Z" ; public: void __cdecl pvrtexture::CPVRTextureHeader::setIsPreMultiplied(bool)
			PVRTexLibDLL[254]:="?setNumArrayMembers@CPVRTextureHeader@pvrtexture@@QEAAXI@Z" ; public: void __cdecl pvrtexture::CPVRTextureHeader::setNumArrayMembers(unsigned int)
			PVRTexLibDLL[255]:="?setNumFaces@CPVRTextureHeader@pvrtexture@@QEAAXI@Z" ; public: void __cdecl pvrtexture::CPVRTextureHeader::setNumFaces(unsigned int)
			PVRTexLibDLL[256]:="?setNumMIPLevels@CPVRTextureHeader@pvrtexture@@QEAAXI@Z" ; public: void __cdecl pvrtexture::CPVRTextureHeader::setNumMIPLevels(unsigned int)
			PVRTexLibDLL[257]:="?setOGLESFormat@CPVRTextureHeader@pvrtexture@@QEAA_NAEBI00@Z" ; public: bool __cdecl pvrtexture::CPVRTextureHeader::setOGLESFormat(unsigned int const &, unsigned int const &, unsigned int const &)
			PVRTexLibDLL[258]:="?setOGLFormat@CPVRTextureHeader@pvrtexture@@QEAA_NAEBI00@Z" ; public: bool __cdecl pvrtexture::CPVRTextureHeader::setOGLFormat(unsigned int const &, unsigned int const &, unsigned int const &)
			PVRTexLibDLL[259]:="?setOrientation@CPVRTextureHeader@pvrtexture@@QEAAXW4EPVRTOrientation@@@Z" ; public: void __cdecl pvrtexture::CPVRTextureHeader::setOrientation(enum EPVRTOrientation)
			PVRTexLibDLL[260]:="?setPixelFormat@CPVRTextureHeader@pvrtexture@@QEAAXTPixelType@2@@Z" ; public: void __cdecl pvrtexture::CPVRTextureHeader::setPixelFormat(union pvrtexture::PixelType)
			PVRTexLibDLL[261]:="?setTextureAtlas@CPVRTextureHeader@pvrtexture@@QEAAXPEAMI@Z" ; public: void __cdecl pvrtexture::CPVRTextureHeader::setTextureAtlas(float *, unsigned int)
			PVRTexLibDLL[262]:="?setWidth@CPVRTextureHeader@pvrtexture@@QEAAXI@Z" ; public: void __cdecl pvrtexture::CPVRTextureHeader::setWidth(unsigned int)
			PVRTexLibDLL[263]:="?size@CPVRTString@@QEBA_KXZ" ; public: unsigned __int64 __cdecl CPVRTString::size(void) const
			PVRTexLibDLL[264]:="?substitute@CPVRTString@@QEAAAEAV1@DD_N@Z" ; public: class CPVRTString & __cdecl CPVRTString::substitute(char, char, bool)
			PVRTexLibDLL[265]:="?substitute@CPVRTString@@QEAAAEAV1@PEBD0_N@Z" ; public: class CPVRTString & __cdecl CPVRTString::substitute(char const *, char const *, bool)
			PVRTexLibDLL[266]:="?substr@CPVRTString@@QEBA?AV1@_K0@Z" ; public: class CPVRTString __cdecl CPVRTString::substr(unsigned __int64, unsigned __int64) const
			PVRTexLibDLL[267]:="?swap@CPVRTString@@QEAAXAEAV1@@Z" ; public: void __cdecl CPVRTString::swap(class CPVRTString &)
			PVRTexLibDLL[268]:="?toLower@CPVRTString@@QEAAAEAV1@XZ" ; public: class CPVRTString & __cdecl CPVRTString::toLower(void)
			PVRTexLibDLL[269]:="?toUpper@CPVRTString@@QEAAAEAV1@XZ" ; public: class CPVRTString & __cdecl CPVRTString::toUpper(void)
			}
		Else ; Is x86 (32-bit)
			{
			PVRTexLibDLL[1]:="??0?$CPVRTArray@I@@QAE@ABV0@@Z" ; public: __thiscall CPVRTArray<unsigned int>::CPVRTArray<unsigned int>(class CPVRTArray<unsigned int> const &)
			PVRTexLibDLL[2]:="??0?$CPVRTArray@I@@QAE@XZ" ; public: __thiscall CPVRTArray<unsigned int>::CPVRTArray<unsigned int>(void)
			PVRTexLibDLL[3]:="??0?$CPVRTArray@UMetaDataBlock@@@@QAE@ABV0@@Z" ; public: __thiscall CPVRTArray<struct MetaDataBlock>::CPVRTArray<struct MetaDataBlock>(class CPVRTArray<struct MetaDataBlock> const &)
			PVRTexLibDLL[4]:="??0?$CPVRTArray@UMetaDataBlock@@@@QAE@XZ" ; public: __thiscall CPVRTArray<struct MetaDataBlock>::CPVRTArray<struct MetaDataBlock>(void)
			PVRTexLibDLL[5]:="??0?$CPVRTArray@V?$CPVRTMap@IUMetaDataBlock@@@@@@QAE@ABV0@@Z" ; public: __thiscall CPVRTArray<class CPVRTMap<unsigned int, struct MetaDataBlock>>::CPVRTArray<class CPVRTMap<unsigned int, struct MetaDataBlock>>(class CPVRTArray<class CPVRTMap<unsigned int, struct MetaDataBlock>> const &)
			PVRTexLibDLL[6]:="??0?$CPVRTArray@V?$CPVRTMap@IUMetaDataBlock@@@@@@QAE@XZ" ; public: __thiscall CPVRTArray<class CPVRTMap<unsigned int, struct MetaDataBlock>>::CPVRTArray<class CPVRTMap<unsigned int, struct MetaDataBlock>>(void)
			PVRTexLibDLL[7]:="??0?$CPVRTMap@IUMetaDataBlock@@@@QAE@ABV0@@Z" ; public: __thiscall CPVRTMap<unsigned int, struct MetaDataBlock>::CPVRTMap<unsigned int, struct MetaDataBlock>(class CPVRTMap<unsigned int, struct MetaDataBlock> const &)
			PVRTexLibDLL[8]:="??0?$CPVRTMap@IUMetaDataBlock@@@@QAE@XZ" ; public: __thiscall CPVRTMap<unsigned int, struct MetaDataBlock>::CPVRTMap<unsigned int, struct MetaDataBlock>(void)
			PVRTexLibDLL[9]:="??0?$CPVRTMap@IV?$CPVRTMap@IUMetaDataBlock@@@@@@QAE@ABV0@@Z" ; public: __thiscall CPVRTMap<unsigned int, class CPVRTMap<unsigned int, struct MetaDataBlock>>::CPVRTMap<unsigned int, class CPVRTMap<unsigned int, struct MetaDataBlock>>(class CPVRTMap<unsigned int, class CPVRTMap<unsigned int, struct MetaDataBlock>> const &)
			PVRTexLibDLL[10]:="??0?$CPVRTMap@IV?$CPVRTMap@IUMetaDataBlock@@@@@@QAE@XZ" ; public: __thiscall CPVRTMap<unsigned int, class CPVRTMap<unsigned int, struct MetaDataBlock>>::CPVRTMap<unsigned int, class CPVRTMap<unsigned int, struct MetaDataBlock>>(void)
			PVRTexLibDLL[11]:="??0CPVRTString@@QAE@ABV0@II@Z" ; public: __thiscall CPVRTString::CPVRTString(class CPVRTString const &, unsigned int, unsigned int)
			PVRTexLibDLL[12]:="??0CPVRTString@@QAE@D@Z" ; public: __thiscall CPVRTString::CPVRTString(char)
			PVRTexLibDLL[13]:="??0CPVRTString@@QAE@ID@Z" ; public: __thiscall CPVRTString::CPVRTString(unsigned int, char)
			PVRTexLibDLL[14]:="??0CPVRTString@@QAE@PBDI@Z" ; public: __thiscall CPVRTString::CPVRTString(char const *, unsigned int)
			PVRTexLibDLL[15]:="??0CPVRTString@@QAE@XZ" ; public: __thiscall CPVRTString::CPVRTString(void)
			PVRTexLibDLL[16]:="??0CPVRTexture@pvrtexture@@QAE@ABV01@@Z" ; public: __thiscall pvrtexture::CPVRTexture::CPVRTexture(class pvrtexture::CPVRTexture const &)
			PVRTexLibDLL[17]:="??0CPVRTexture@pvrtexture@@QAE@ABVCPVRTextureHeader@1@PBX@Z" ; public: __thiscall pvrtexture::CPVRTexture::CPVRTexture(class pvrtexture::CPVRTextureHeader const &, void const *)
			PVRTexLibDLL[18]:="??0CPVRTexture@pvrtexture@@QAE@PBD@Z" ; public: __thiscall pvrtexture::CPVRTexture::CPVRTexture(char const *)
			PVRTexLibDLL[19]:="??0CPVRTexture@pvrtexture@@QAE@PBX@Z" ; public: __thiscall pvrtexture::CPVRTexture::CPVRTexture(void const *)
			PVRTexLibDLL[20]:="??0CPVRTexture@pvrtexture@@QAE@XZ" ; public: __thiscall pvrtexture::CPVRTexture::CPVRTexture(void)
			PVRTexLibDLL[21]:="??0CPVRTextureHeader@pvrtexture@@QAE@ABV01@@Z" ; public: __thiscall pvrtexture::CPVRTextureHeader::CPVRTextureHeader(class pvrtexture::CPVRTextureHeader const &)
			PVRTexLibDLL[22]:="??0CPVRTextureHeader@pvrtexture@@QAE@UPVRTextureHeaderV3@@IPAUMetaDataBlock@@@Z" ; public: __thiscall pvrtexture::CPVRTextureHeader::CPVRTextureHeader(struct PVRTextureHeaderV3, unsigned int, struct MetaDataBlock *)
			PVRTexLibDLL[23]:="??0CPVRTextureHeader@pvrtexture@@QAE@XZ" ; public: __thiscall pvrtexture::CPVRTextureHeader::CPVRTextureHeader(void)
			PVRTexLibDLL[24]:="??0CPVRTextureHeader@pvrtexture@@QAE@_KIIIIIIW4EPVRTColourSpace@@W4EPVRTVariableType@@_N@Z" ; public: __thiscall pvrtexture::CPVRTextureHeader::CPVRTextureHeader(unsigned __int64, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, enum EPVRTColourSpace, enum EPVRTVariableType, bool)
			PVRTexLibDLL[25]:="??0MetaDataBlock@@QAE@ABU0@@Z" ; public: __thiscall MetaDataBlock::MetaDataBlock(struct MetaDataBlock const &)
			PVRTexLibDLL[26]:="??0MetaDataBlock@@QAE@XZ" ; public: __thiscall MetaDataBlock::MetaDataBlock(void)
			PVRTexLibDLL[27]:="??0PVRTextureHeaderV3@@QAE@XZ" ; public: __thiscall PVRTextureHeaderV3::PVRTextureHeaderV3(void)
			PVRTexLibDLL[28]:="??0PixelType@pvrtexture@@QAE@EEEEEEEE@Z" ; public: __thiscall pvrtexture::PixelType::PixelType(unsigned char, unsigned char, unsigned char, unsigned char, unsigned char, unsigned char, unsigned char, unsigned char)
			PVRTexLibDLL[29]:="??0PixelType@pvrtexture@@QAE@XZ" ; public: __thiscall pvrtexture::PixelType::PixelType(void)
			PVRTexLibDLL[30]:="??0PixelType@pvrtexture@@QAE@_K@Z" ; public: __thiscall pvrtexture::PixelType::PixelType(unsigned __int64)
			PVRTexLibDLL[31]:="??1?$CPVRTArray@I@@UAE@XZ" ; public: virtual __thiscall CPVRTArray<unsigned int>::~CPVRTArray<unsigned int>(void)
			PVRTexLibDLL[32]:="??1?$CPVRTArray@UMetaDataBlock@@@@UAE@XZ" ; public: virtual __thiscall CPVRTArray<struct MetaDataBlock>::~CPVRTArray<struct MetaDataBlock>(void)
			PVRTexLibDLL[33]:="??1?$CPVRTArray@V?$CPVRTMap@IUMetaDataBlock@@@@@@UAE@XZ" ; public: virtual __thiscall CPVRTArray<class CPVRTMap<unsigned int, struct MetaDataBlock>>::~CPVRTArray<class CPVRTMap<unsigned int, struct MetaDataBlock>>(void)
			PVRTexLibDLL[34]:="??1?$CPVRTMap@IUMetaDataBlock@@@@QAE@XZ" ; public: __thiscall CPVRTMap<unsigned int, struct MetaDataBlock>::~CPVRTMap<unsigned int, struct MetaDataBlock>(void)
			PVRTexLibDLL[35]:="??1?$CPVRTMap@IV?$CPVRTMap@IUMetaDataBlock@@@@@@QAE@XZ" ; public: __thiscall CPVRTMap<unsigned int, class CPVRTMap<unsigned int, struct MetaDataBlock>>::~CPVRTMap<unsigned int, class CPVRTMap<unsigned int, struct MetaDataBlock>>(void)
			PVRTexLibDLL[36]:="??1CPVRTString@@UAE@XZ" ; public: virtual __thiscall CPVRTString::~CPVRTString(void)
			PVRTexLibDLL[37]:="??1CPVRTexture@pvrtexture@@QAE@XZ" ; public: __thiscall pvrtexture::CPVRTexture::~CPVRTexture(void)
			PVRTexLibDLL[38]:="??1CPVRTextureHeader@pvrtexture@@QAE@XZ" ; public: __thiscall pvrtexture::CPVRTextureHeader::~CPVRTextureHeader(void)
			PVRTexLibDLL[39]:="??1MetaDataBlock@@QAE@XZ" ; public: __thiscall MetaDataBlock::~MetaDataBlock(void)
			PVRTexLibDLL[40]:="??4?$CPVRTArray@I@@QAEAAV0@ABV0@@Z" ; public: class CPVRTArray<unsigned int> & __thiscall CPVRTArray<unsigned int>::operator=(class CPVRTArray<unsigned int> const &)
			PVRTexLibDLL[41]:="??4?$CPVRTArray@UMetaDataBlock@@@@QAEAAV0@ABV0@@Z" ; public: class CPVRTArray<struct MetaDataBlock> & __thiscall CPVRTArray<struct MetaDataBlock>::operator=(class CPVRTArray<struct MetaDataBlock> const &)
			PVRTexLibDLL[42]:="??4?$CPVRTArray@V?$CPVRTMap@IUMetaDataBlock@@@@@@QAEAAV0@ABV0@@Z" ; public: class CPVRTArray<class CPVRTMap<unsigned int, struct MetaDataBlock>> & __thiscall CPVRTArray<class CPVRTMap<unsigned int, struct MetaDataBlock>>::operator=(class CPVRTArray<class CPVRTMap<unsigned int, struct MetaDataBlock>> const &)
			PVRTexLibDLL[43]:="??4?$CPVRTMap@IUMetaDataBlock@@@@QAEAAV0@ABV0@@Z" ; public: class CPVRTMap<unsigned int, struct MetaDataBlock> & __thiscall CPVRTMap<unsigned int, struct MetaDataBlock>::operator=(class CPVRTMap<unsigned int, struct MetaDataBlock> const &)
			PVRTexLibDLL[44]:="??4?$CPVRTMap@IV?$CPVRTMap@IUMetaDataBlock@@@@@@QAEAAV0@ABV0@@Z" ; public: class CPVRTMap<unsigned int, class CPVRTMap<unsigned int, struct MetaDataBlock>> & __thiscall CPVRTMap<unsigned int, class CPVRTMap<unsigned int, struct MetaDataBlock>>::operator=(class CPVRTMap<unsigned int, class CPVRTMap<unsigned int, struct MetaDataBlock>> const &)
			PVRTexLibDLL[45]:="??4CPVRTString@@QAEAAV0@ABV0@@Z" ; public: class CPVRTString & __thiscall CPVRTString::operator=(class CPVRTString const &)
			PVRTexLibDLL[46]:="??4CPVRTString@@QAEAAV0@D@Z" ; public: class CPVRTString & __thiscall CPVRTString::operator=(char)
			PVRTexLibDLL[47]:="??4CPVRTString@@QAEAAV0@PBD@Z" ; public: class CPVRTString & __thiscall CPVRTString::operator=(char const *)
			PVRTexLibDLL[48]:="??4CPVRTexture@pvrtexture@@QAEAAV01@ABV01@@Z" ; public: class pvrtexture::CPVRTexture & __thiscall pvrtexture::CPVRTexture::operator=(class pvrtexture::CPVRTexture const &)
			PVRTexLibDLL[49]:="??4CPVRTextureHeader@pvrtexture@@QAEAAV01@ABV01@@Z" ; public: class pvrtexture::CPVRTextureHeader & __thiscall pvrtexture::CPVRTextureHeader::operator=(class pvrtexture::CPVRTextureHeader const &)
			PVRTexLibDLL[50]:="??4LowHigh@PixelType@pvrtexture@@QAEAAU012@ABU012@@Z" ; public: struct pvrtexture::PixelType::LowHigh & __thiscall pvrtexture::PixelType::LowHigh::operator=(struct pvrtexture::PixelType::LowHigh const &)
			PVRTexLibDLL[51]:="??4MetaDataBlock@@QAEAAU0@ABU0@@Z" ; public: struct MetaDataBlock & __thiscall MetaDataBlock::operator=(struct MetaDataBlock const &)
			PVRTexLibDLL[52]:="??4PVRTextureHeaderV3@@QAEAAU0@ABU0@@Z" ; public: struct PVRTextureHeaderV3 & __thiscall PVRTextureHeaderV3::operator=(struct PVRTextureHeaderV3 const &)
			PVRTexLibDLL[53]:="??4PixelType@pvrtexture@@QAEAAT01@ABT01@@Z" ; public: union pvrtexture::PixelType & __thiscall pvrtexture::PixelType::operator=(union pvrtexture::PixelType const &)
			PVRTexLibDLL[54]:="??8CPVRTString@@QBE_NABV0@@Z" ; public: bool __thiscall CPVRTString::operator==(class CPVRTString const &) const
			PVRTexLibDLL[55]:="??8CPVRTString@@QBE_NQBD@Z" ; public: bool __thiscall CPVRTString::operator==(char const *const) const
			PVRTexLibDLL[56]:="??9CPVRTString@@QBE_NABV0@@Z" ; public: bool __thiscall CPVRTString::operator!=(class CPVRTString const &) const
			PVRTexLibDLL[57]:="??9CPVRTString@@QBE_NQBD@Z" ; public: bool __thiscall CPVRTString::operator!=(char const *const) const
			PVRTexLibDLL[58]:="??A?$CPVRTArray@I@@QAEAAII@Z" ; public: unsigned int & __thiscall CPVRTArray<unsigned int>::operator[](unsigned int)
			PVRTexLibDLL[59]:="??A?$CPVRTArray@I@@QBEABII@Z" ; public: unsigned int const & __thiscall CPVRTArray<unsigned int>::operator[](unsigned int) const
			PVRTexLibDLL[60]:="??A?$CPVRTArray@UMetaDataBlock@@@@QAEAAUMetaDataBlock@@I@Z" ; public: struct MetaDataBlock & __thiscall CPVRTArray<struct MetaDataBlock>::operator[](unsigned int)
			PVRTexLibDLL[61]:="??A?$CPVRTArray@UMetaDataBlock@@@@QBEABUMetaDataBlock@@I@Z" ; public: struct MetaDataBlock const & __thiscall CPVRTArray<struct MetaDataBlock>::operator[](unsigned int) const
			PVRTexLibDLL[62]:="??A?$CPVRTArray@V?$CPVRTMap@IUMetaDataBlock@@@@@@QAEAAV?$CPVRTMap@IUMetaDataBlock@@@@I@Z" ; public: class CPVRTMap<unsigned int, struct MetaDataBlock> & __thiscall CPVRTArray<class CPVRTMap<unsigned int, struct MetaDataBlock>>::operator[](unsigned int)
			PVRTexLibDLL[63]:="??A?$CPVRTArray@V?$CPVRTMap@IUMetaDataBlock@@@@@@QBEABV?$CPVRTMap@IUMetaDataBlock@@@@I@Z" ; public: class CPVRTMap<unsigned int, struct MetaDataBlock> const & __thiscall CPVRTArray<class CPVRTMap<unsigned int, struct MetaDataBlock>>::operator[](unsigned int) const
			PVRTexLibDLL[64]:="??A?$CPVRTMap@IUMetaDataBlock@@@@QAEAAUMetaDataBlock@@I@Z" ; public: struct MetaDataBlock & __thiscall CPVRTMap<unsigned int, struct MetaDataBlock>::operator[](unsigned int)
			PVRTexLibDLL[65]:="??A?$CPVRTMap@IV?$CPVRTMap@IUMetaDataBlock@@@@@@QAEAAV?$CPVRTMap@IUMetaDataBlock@@@@I@Z" ; public: class CPVRTMap<unsigned int, struct MetaDataBlock> & __thiscall CPVRTMap<unsigned int, class CPVRTMap<unsigned int, struct MetaDataBlock>>::operator[](unsigned int)
			PVRTexLibDLL[66]:="??ACPVRTString@@QAEAADI@Z" ; public: char & __thiscall CPVRTString::operator[](unsigned int)
			PVRTexLibDLL[67]:="??ACPVRTString@@QBEABDI@Z" ; public: char const & __thiscall CPVRTString::operator[](unsigned int) const
			PVRTexLibDLL[68]:="??MCPVRTString@@QBE_NABV0@@Z" ; public: bool __thiscall CPVRTString::operator<(class CPVRTString const &) const
			PVRTexLibDLL[69]:="??YCPVRTString@@QAEAAV0@ABV0@@Z" ; public: class CPVRTString & __thiscall CPVRTString::operator+=(class CPVRTString const &)
			PVRTexLibDLL[70]:="??YCPVRTString@@QAEAAV0@D@Z" ; public: class CPVRTString & __thiscall CPVRTString::operator+=(char)
			PVRTexLibDLL[71]:="??YCPVRTString@@QAEAAV0@PBD@Z" ; public: class CPVRTString & __thiscall CPVRTString::operator+=(char const *)
			PVRTexLibDLL[72]:="??_7?$CPVRTArray@I@@6B@" ; const CPVRTArray<unsigned int>::`vftable'
			PVRTexLibDLL[73]:="??_7?$CPVRTArray@UMetaDataBlock@@@@6B@" ; const CPVRTArray<struct MetaDataBlock>::`vftable'
			PVRTexLibDLL[74]:="??_7?$CPVRTArray@V?$CPVRTMap@IUMetaDataBlock@@@@@@6B@" ; const CPVRTArray<class CPVRTMap<unsigned int, struct MetaDataBlock>>::`vftable'
			PVRTexLibDLL[75]:="??_7CPVRTString@@6B@" ; const CPVRTString::`vftable'
			PVRTexLibDLL[76]:="??_OCPVRTString@@QAEXAAV0@@Z" ; public: void __thiscall CPVRTString::`copy ctor closure'(class CPVRTString &)
			PVRTexLibDLL[77]:="?Append@?$CPVRTArray@I@@QAEIABI@Z" ; public: unsigned int __thiscall CPVRTArray<unsigned int>::Append(unsigned int const &)
			PVRTexLibDLL[78]:="?Append@?$CPVRTArray@I@@QAEIXZ" ; public: unsigned int __thiscall CPVRTArray<unsigned int>::Append(void)
			PVRTexLibDLL[79]:="?Append@?$CPVRTArray@UMetaDataBlock@@@@QAEIABUMetaDataBlock@@@Z" ; public: unsigned int __thiscall CPVRTArray<struct MetaDataBlock>::Append(struct MetaDataBlock const &)
			PVRTexLibDLL[80]:="?Append@?$CPVRTArray@UMetaDataBlock@@@@QAEIXZ" ; public: unsigned int __thiscall CPVRTArray<struct MetaDataBlock>::Append(void)
			PVRTexLibDLL[81]:="?Append@?$CPVRTArray@V?$CPVRTMap@IUMetaDataBlock@@@@@@QAEIABV?$CPVRTMap@IUMetaDataBlock@@@@@Z" ; public: unsigned int __thiscall CPVRTArray<class CPVRTMap<unsigned int, struct MetaDataBlock>>::Append(class CPVRTMap<unsigned int, struct MetaDataBlock> const &)
			PVRTexLibDLL[82]:="?Append@?$CPVRTArray@V?$CPVRTMap@IUMetaDataBlock@@@@@@QAEIXZ" ; public: unsigned int __thiscall CPVRTArray<class CPVRTMap<unsigned int, struct MetaDataBlock>>::Append(void)
			PVRTexLibDLL[83]:="?Bleed@pvrtexture@@YA_NAAVCPVRTexture@1@@Z" ; bool __cdecl pvrtexture::Bleed(class pvrtexture::CPVRTexture &)
			PVRTexLibDLL[84]:="?Border@pvrtexture@@YA_NAAVCPVRTexture@1@III@Z" ; bool __cdecl pvrtexture::Border(class pvrtexture::CPVRTexture &, unsigned int, unsigned int, unsigned int)
			PVRTexLibDLL[85]:="?Clear@?$CPVRTArray@I@@QAEXXZ" ; public: void __thiscall CPVRTArray<unsigned int>::Clear(void)
			PVRTexLibDLL[86]:="?Clear@?$CPVRTArray@UMetaDataBlock@@@@QAEXXZ" ; public: void __thiscall CPVRTArray<struct MetaDataBlock>::Clear(void)
			PVRTexLibDLL[87]:="?Clear@?$CPVRTArray@V?$CPVRTMap@IUMetaDataBlock@@@@@@QAEXXZ" ; public: void __thiscall CPVRTArray<class CPVRTMap<unsigned int, struct MetaDataBlock>>::Clear(void)
			PVRTexLibDLL[88]:="?Clear@?$CPVRTMap@IUMetaDataBlock@@@@QAEXXZ" ; public: void __thiscall CPVRTMap<unsigned int, struct MetaDataBlock>::Clear(void)
			PVRTexLibDLL[89]:="?Clear@?$CPVRTMap@IV?$CPVRTMap@IUMetaDataBlock@@@@@@QAEXXZ" ; public: void __thiscall CPVRTMap<unsigned int, class CPVRTMap<unsigned int, struct MetaDataBlock>>::Clear(void)
			PVRTexLibDLL[90]:="?ColourMIPMaps@pvrtexture@@YA_NAAVCPVRTexture@1@@Z" ; bool __cdecl pvrtexture::ColourMIPMaps(class pvrtexture::CPVRTexture &)
			PVRTexLibDLL[91]:="?CopyChannels@pvrtexture@@YA_NAAVCPVRTexture@1@ABV21@IPAW4EChannelName@1@2@Z" ; bool __cdecl pvrtexture::CopyChannels(class pvrtexture::CPVRTexture &, class pvrtexture::CPVRTexture const &, unsigned int, enum pvrtexture::EChannelName *, enum pvrtexture::EChannelName *)
			PVRTexLibDLL[92]:="?Exists@?$CPVRTMap@IUMetaDataBlock@@@@QBE_NI@Z" ; public: bool __thiscall CPVRTMap<unsigned int, struct MetaDataBlock>::Exists(unsigned int) const
			PVRTexLibDLL[93]:="?Flip@pvrtexture@@YA_NAAVCPVRTexture@1@W4EPVRTAxis@@@Z" ; bool __cdecl pvrtexture::Flip(class pvrtexture::CPVRTexture &, enum EPVRTAxis)
			PVRTexLibDLL[94]:="?GenerateMIPMaps@pvrtexture@@YA_NAAVCPVRTexture@1@W4EResizeMode@1@I@Z" ; bool __cdecl pvrtexture::GenerateMIPMaps(class pvrtexture::CPVRTexture &, enum pvrtexture::EResizeMode, unsigned int)
			PVRTexLibDLL[95]:="?GenerateNormalMap@pvrtexture@@YA_NAAVCPVRTexture@1@MVCPVRTString@@@Z" ; bool __cdecl pvrtexture::GenerateNormalMap(class pvrtexture::CPVRTexture &, float, class CPVRTString)
			PVRTexLibDLL[96]:="?GetCapacity@?$CPVRTArray@I@@QBEIXZ" ; public: unsigned int __thiscall CPVRTArray<unsigned int>::GetCapacity(void) const
			PVRTexLibDLL[97]:="?GetCapacity@?$CPVRTArray@UMetaDataBlock@@@@QBEIXZ" ; public: unsigned int __thiscall CPVRTArray<struct MetaDataBlock>::GetCapacity(void) const
			PVRTexLibDLL[98]:="?GetCapacity@?$CPVRTArray@V?$CPVRTMap@IUMetaDataBlock@@@@@@QBEIXZ" ; public: unsigned int __thiscall CPVRTArray<class CPVRTMap<unsigned int, struct MetaDataBlock>>::GetCapacity(void) const
			PVRTexLibDLL[99]:="?GetDataAtIndex@?$CPVRTMap@IUMetaDataBlock@@@@QBEPBUMetaDataBlock@@I@Z" ; public: struct MetaDataBlock const * __thiscall CPVRTMap<unsigned int, struct MetaDataBlock>::GetDataAtIndex(unsigned int) const
			PVRTexLibDLL[100]:="?GetDataAtIndex@?$CPVRTMap@IV?$CPVRTMap@IUMetaDataBlock@@@@@@QBEPBV?$CPVRTMap@IUMetaDataBlock@@@@I@Z" ; public: class CPVRTMap<unsigned int, struct MetaDataBlock> const * __thiscall CPVRTMap<unsigned int, class CPVRTMap<unsigned int, struct MetaDataBlock>>::GetDataAtIndex(unsigned int) const
			PVRTexLibDLL[101]:="?GetDefaultSize@?$CPVRTArray@I@@SAIXZ" ; public: static unsigned int __cdecl CPVRTArray<unsigned int>::GetDefaultSize(void)
			PVRTexLibDLL[102]:="?GetDefaultSize@?$CPVRTArray@UMetaDataBlock@@@@SAIXZ" ; public: static unsigned int __cdecl CPVRTArray<struct MetaDataBlock>::GetDefaultSize(void)
			PVRTexLibDLL[103]:="?GetDefaultSize@?$CPVRTArray@V?$CPVRTMap@IUMetaDataBlock@@@@@@SAIXZ" ; public: static unsigned int __cdecl CPVRTArray<class CPVRTMap<unsigned int, struct MetaDataBlock>>::GetDefaultSize(void)
			PVRTexLibDLL[104]:="?GetIndexOf@?$CPVRTMap@IUMetaDataBlock@@@@QBEII@Z" ; public: unsigned int __thiscall CPVRTMap<unsigned int, struct MetaDataBlock>::GetIndexOf(unsigned int) const
			PVRTexLibDLL[105]:="?GetIndexOf@?$CPVRTMap@IV?$CPVRTMap@IUMetaDataBlock@@@@@@QBEII@Z" ; public: unsigned int __thiscall CPVRTMap<unsigned int, class CPVRTMap<unsigned int, struct MetaDataBlock>>::GetIndexOf(unsigned int) const
			PVRTexLibDLL[106]:="?GetSize@?$CPVRTArray@I@@QBEIXZ" ; public: unsigned int __thiscall CPVRTArray<unsigned int>::GetSize(void) const
			PVRTexLibDLL[107]:="?GetSize@?$CPVRTArray@UMetaDataBlock@@@@QBEIXZ" ; public: unsigned int __thiscall CPVRTArray<struct MetaDataBlock>::GetSize(void) const
			PVRTexLibDLL[108]:="?GetSize@?$CPVRTArray@V?$CPVRTMap@IUMetaDataBlock@@@@@@QBEIXZ" ; public: unsigned int __thiscall CPVRTArray<class CPVRTMap<unsigned int, struct MetaDataBlock>>::GetSize(void) const
			PVRTexLibDLL[109]:="?GetSize@?$CPVRTMap@IUMetaDataBlock@@@@QBEIXZ" ; public: unsigned int __thiscall CPVRTMap<unsigned int, struct MetaDataBlock>::GetSize(void) const
			PVRTexLibDLL[110]:="?GetSize@?$CPVRTMap@IV?$CPVRTMap@IUMetaDataBlock@@@@@@QBEIXZ" ; public: unsigned int __thiscall CPVRTMap<unsigned int, class CPVRTMap<unsigned int, struct MetaDataBlock>>::GetSize(void) const
			PVRTexLibDLL[111]:="?PreMultiplyAlpha@pvrtexture@@YA_NAAVCPVRTexture@1@@Z" ; bool __cdecl pvrtexture::PreMultiplyAlpha(class pvrtexture::CPVRTexture &)
			PVRTexLibDLL[112]:="?Remove@?$CPVRTArray@I@@UAE?AW4EPVRTError@@I@Z" ; public: virtual enum EPVRTError __thiscall CPVRTArray<unsigned int>::Remove(unsigned int)
			PVRTexLibDLL[113]:="?Remove@?$CPVRTArray@UMetaDataBlock@@@@UAE?AW4EPVRTError@@I@Z" ; public: virtual enum EPVRTError __thiscall CPVRTArray<struct MetaDataBlock>::Remove(unsigned int)
			PVRTexLibDLL[114]:="?Remove@?$CPVRTArray@V?$CPVRTMap@IUMetaDataBlock@@@@@@UAE?AW4EPVRTError@@I@Z" ; public: virtual enum EPVRTError __thiscall CPVRTArray<class CPVRTMap<unsigned int, struct MetaDataBlock>>::Remove(unsigned int)
			PVRTexLibDLL[115]:="?Remove@?$CPVRTMap@IUMetaDataBlock@@@@QAE?AW4EPVRTError@@I@Z" ; public: enum EPVRTError __thiscall CPVRTMap<unsigned int, struct MetaDataBlock>::Remove(unsigned int)
			PVRTexLibDLL[116]:="?RemoveLast@?$CPVRTArray@I@@UAE?AW4EPVRTError@@XZ" ; public: virtual enum EPVRTError __thiscall CPVRTArray<unsigned int>::RemoveLast(void)
			PVRTexLibDLL[117]:="?RemoveLast@?$CPVRTArray@UMetaDataBlock@@@@UAE?AW4EPVRTError@@XZ" ; public: virtual enum EPVRTError __thiscall CPVRTArray<struct MetaDataBlock>::RemoveLast(void)
			PVRTexLibDLL[118]:="?RemoveLast@?$CPVRTArray@V?$CPVRTMap@IUMetaDataBlock@@@@@@UAE?AW4EPVRTError@@XZ" ; public: virtual enum EPVRTError __thiscall CPVRTArray<class CPVRTMap<unsigned int, struct MetaDataBlock>>::RemoveLast(void)
			PVRTexLibDLL[119]:="?Resize@pvrtexture@@YA_NAAVCPVRTexture@1@ABI11W4EResizeMode@1@@Z" ; bool __cdecl pvrtexture::Resize(class pvrtexture::CPVRTexture &, unsigned int const &, unsigned int const &, unsigned int const &, enum pvrtexture::EResizeMode)
			PVRTexLibDLL[120]:="?ResizeCanvas@pvrtexture@@YA_NAAVCPVRTexture@1@ABI11ABH22@Z" ; bool __cdecl pvrtexture::ResizeCanvas(class pvrtexture::CPVRTexture &, unsigned int const &, unsigned int const &, unsigned int const &, int const &, int const &, int const &)
			PVRTexLibDLL[121]:="?Rotate90@pvrtexture@@YA_NAAVCPVRTexture@1@W4EPVRTAxis@@_N@Z" ; bool __cdecl pvrtexture::Rotate90(class pvrtexture::CPVRTexture &, enum EPVRTAxis, bool)
			PVRTexLibDLL[122]:="?SetCapacity@?$CPVRTArray@I@@QAE?AW4EPVRTError@@I@Z" ; public: enum EPVRTError __thiscall CPVRTArray<unsigned int>::SetCapacity(unsigned int)
			PVRTexLibDLL[123]:="?SetCapacity@?$CPVRTArray@UMetaDataBlock@@@@QAE?AW4EPVRTError@@I@Z" ; public: enum EPVRTError __thiscall CPVRTArray<struct MetaDataBlock>::SetCapacity(unsigned int)
			PVRTexLibDLL[124]:="?SetCapacity@?$CPVRTArray@V?$CPVRTMap@IUMetaDataBlock@@@@@@QAE?AW4EPVRTError@@I@Z" ; public: enum EPVRTError __thiscall CPVRTArray<class CPVRTMap<unsigned int, struct MetaDataBlock>>::SetCapacity(unsigned int)
			PVRTexLibDLL[125]:="?SetChannels@pvrtexture@@YA_NAAVCPVRTexture@1@IPAW4EChannelName@1@PAI@Z" ; bool __cdecl pvrtexture::SetChannels(class pvrtexture::CPVRTexture &, unsigned int, enum pvrtexture::EChannelName *, unsigned int *)
			PVRTexLibDLL[126]:="?SetChannelsFloat@pvrtexture@@YA_NAAVCPVRTexture@1@IPAW4EChannelName@1@PAM@Z" ; bool __cdecl pvrtexture::SetChannelsFloat(class pvrtexture::CPVRTexture &, unsigned int, enum pvrtexture::EChannelName *, float *)
			PVRTexLibDLL[127]:="?SizeOfBlock@MetaDataBlock@@QBEIXZ" ; public: unsigned int __thiscall MetaDataBlock::SizeOfBlock(void) const
			PVRTexLibDLL[128]:="?Transcode@pvrtexture@@YA_NAAVCPVRTexture@1@TPixelType@1@W4EPVRTVariableType@@W4EPVRTColourSpace@@W4ECompressorQuality@1@_N@Z" ; bool __cdecl pvrtexture::Transcode(class pvrtexture::CPVRTexture &, union pvrtexture::PixelType, enum EPVRTVariableType, enum EPVRTColourSpace, enum pvrtexture::ECompressorQuality, bool)
			PVRTexLibDLL[129]:="?addMetaData@CPVRTextureHeader@pvrtexture@@QAEXABUMetaDataBlock@@@Z" ; public: void __thiscall pvrtexture::CPVRTextureHeader::addMetaData(struct MetaDataBlock const &)
			PVRTexLibDLL[130]:="?addPaddingMetaData@CPVRTexture@pvrtexture@@QAEXI@Z" ; public: void __thiscall pvrtexture::CPVRTexture::addPaddingMetaData(unsigned int)
			PVRTexLibDLL[131]:="?append@CPVRTString@@QAEAAV1@ABV1@@Z" ; public: class CPVRTString & __thiscall CPVRTString::append(class CPVRTString const &)
			PVRTexLibDLL[132]:="?append@CPVRTString@@QAEAAV1@ABV1@II@Z" ; public: class CPVRTString & __thiscall CPVRTString::append(class CPVRTString const &, unsigned int, unsigned int)
			PVRTexLibDLL[133]:="?append@CPVRTString@@QAEAAV1@ID@Z" ; public: class CPVRTString & __thiscall CPVRTString::append(unsigned int, char)
			PVRTexLibDLL[134]:="?append@CPVRTString@@QAEAAV1@PBD@Z" ; public: class CPVRTString & __thiscall CPVRTString::append(char const *)
			PVRTexLibDLL[135]:="?append@CPVRTString@@QAEAAV1@PBDI@Z" ; public: class CPVRTString & __thiscall CPVRTString::append(char const *, unsigned int)
			PVRTexLibDLL[136]:="?assign@CPVRTString@@QAEAAV1@ABV1@@Z" ; public: class CPVRTString & __thiscall CPVRTString::assign(class CPVRTString const &)
			PVRTexLibDLL[137]:="?assign@CPVRTString@@QAEAAV1@ABV1@II@Z" ; public: class CPVRTString & __thiscall CPVRTString::assign(class CPVRTString const &, unsigned int, unsigned int)
			PVRTexLibDLL[138]:="?assign@CPVRTString@@QAEAAV1@ID@Z" ; public: class CPVRTString & __thiscall CPVRTString::assign(unsigned int, char)
			PVRTexLibDLL[139]:="?assign@CPVRTString@@QAEAAV1@PBD@Z" ; public: class CPVRTString & __thiscall CPVRTString::assign(char const *)
			PVRTexLibDLL[140]:="?assign@CPVRTString@@QAEAAV1@PBDI@Z" ; public: class CPVRTString & __thiscall CPVRTString::assign(char const *, unsigned int)
			PVRTexLibDLL[141]:="?c_str@CPVRTString@@QBEPBDXZ" ; public: char const * __thiscall CPVRTString::c_str(void) const
			PVRTexLibDLL[142]:="?capacity@CPVRTString@@QBEIXZ" ; public: unsigned int __thiscall CPVRTString::capacity(void) const
			PVRTexLibDLL[143]:="?clear@CPVRTString@@QAEXXZ" ; public: void __thiscall CPVRTString::clear(void)
			PVRTexLibDLL[144]:="?compare@CPVRTString@@QBEHABV1@@Z" ; public: int __thiscall CPVRTString::compare(class CPVRTString const &) const
			PVRTexLibDLL[145]:="?compare@CPVRTString@@QBEHIIABV1@@Z" ; public: int __thiscall CPVRTString::compare(unsigned int, unsigned int, class CPVRTString const &) const
			PVRTexLibDLL[146]:="?compare@CPVRTString@@QBEHIIABV1@II@Z" ; public: int __thiscall CPVRTString::compare(unsigned int, unsigned int, class CPVRTString const &, unsigned int, unsigned int) const
			PVRTexLibDLL[147]:="?compare@CPVRTString@@QBEHIIPBD@Z" ; public: int __thiscall CPVRTString::compare(unsigned int, unsigned int, char const *) const
			PVRTexLibDLL[148]:="?compare@CPVRTString@@QBEHIIPBDI@Z" ; public: int __thiscall CPVRTString::compare(unsigned int, unsigned int, char const *, unsigned int) const
			PVRTexLibDLL[149]:="?compare@CPVRTString@@QBEHPBD@Z" ; public: int __thiscall CPVRTString::compare(char const *) const
			PVRTexLibDLL[150]:="?copy@CPVRTString@@QBEIPADII@Z" ; public: unsigned int __thiscall CPVRTString::copy(char *, unsigned int, unsigned int) const
			PVRTexLibDLL[151]:="?data@CPVRTString@@QBEPBDXZ" ; public: char const * __thiscall CPVRTString::data(void) const
			PVRTexLibDLL[152]:="?empty@CPVRTString@@QBE_NXZ" ; public: bool __thiscall CPVRTString::empty(void) const
			PVRTexLibDLL[153]:="?erase@CPVRTString@@QAEAAV1@II@Z" ; public: class CPVRTString & __thiscall CPVRTString::erase(unsigned int, unsigned int)
			PVRTexLibDLL[154]:="?find@CPVRTString@@QBEIABV1@I@Z" ; public: unsigned int __thiscall CPVRTString::find(class CPVRTString const &, unsigned int) const
			PVRTexLibDLL[155]:="?find@CPVRTString@@QBEIPBDII@Z" ; public: unsigned int __thiscall CPVRTString::find(char const *, unsigned int, unsigned int) const
			PVRTexLibDLL[156]:="?find_first_not_of@CPVRTString@@QBEIABV1@I@Z" ; public: unsigned int __thiscall CPVRTString::find_first_not_of(class CPVRTString const &, unsigned int) const
			PVRTexLibDLL[157]:="?find_first_not_of@CPVRTString@@QBEIDI@Z" ; public: unsigned int __thiscall CPVRTString::find_first_not_of(char, unsigned int) const
			PVRTexLibDLL[158]:="?find_first_not_of@CPVRTString@@QBEIPBDI@Z" ; public: unsigned int __thiscall CPVRTString::find_first_not_of(char const *, unsigned int) const
			PVRTexLibDLL[159]:="?find_first_not_of@CPVRTString@@QBEIPBDII@Z" ; public: unsigned int __thiscall CPVRTString::find_first_not_of(char const *, unsigned int, unsigned int) const
			PVRTexLibDLL[160]:="?find_first_of@CPVRTString@@QBEIABV1@I@Z" ; public: unsigned int __thiscall CPVRTString::find_first_of(class CPVRTString const &, unsigned int) const
			PVRTexLibDLL[161]:="?find_first_of@CPVRTString@@QBEIDI@Z" ; public: unsigned int __thiscall CPVRTString::find_first_of(char, unsigned int) const
			PVRTexLibDLL[162]:="?find_first_of@CPVRTString@@QBEIPBDI@Z" ; public: unsigned int __thiscall CPVRTString::find_first_of(char const *, unsigned int) const
			PVRTexLibDLL[163]:="?find_first_of@CPVRTString@@QBEIPBDII@Z" ; public: unsigned int __thiscall CPVRTString::find_first_of(char const *, unsigned int, unsigned int) const
			PVRTexLibDLL[164]:="?find_first_ofn@CPVRTString@@QBEIPBDII@Z" ; public: unsigned int __thiscall CPVRTString::find_first_ofn(char const *, unsigned int, unsigned int) const
			PVRTexLibDLL[165]:="?find_last_not_of@CPVRTString@@QBEIABV1@I@Z" ; public: unsigned int __thiscall CPVRTString::find_last_not_of(class CPVRTString const &, unsigned int) const
			PVRTexLibDLL[166]:="?find_last_not_of@CPVRTString@@QBEIDI@Z" ; public: unsigned int __thiscall CPVRTString::find_last_not_of(char, unsigned int) const
			PVRTexLibDLL[167]:="?find_last_not_of@CPVRTString@@QBEIPBDI@Z" ; public: unsigned int __thiscall CPVRTString::find_last_not_of(char const *, unsigned int) const
			PVRTexLibDLL[168]:="?find_last_not_of@CPVRTString@@QBEIPBDII@Z" ; public: unsigned int __thiscall CPVRTString::find_last_not_of(char const *, unsigned int, unsigned int) const
			PVRTexLibDLL[169]:="?find_last_of@CPVRTString@@QBEIABV1@I@Z" ; public: unsigned int __thiscall CPVRTString::find_last_of(class CPVRTString const &, unsigned int) const
			PVRTexLibDLL[170]:="?find_last_of@CPVRTString@@QBEIDI@Z" ; public: unsigned int __thiscall CPVRTString::find_last_of(char, unsigned int) const
			PVRTexLibDLL[171]:="?find_last_of@CPVRTString@@QBEIPBDI@Z" ; public: unsigned int __thiscall CPVRTString::find_last_of(char const *, unsigned int) const
			PVRTexLibDLL[172]:="?find_last_of@CPVRTString@@QBEIPBDII@Z" ; public: unsigned int __thiscall CPVRTString::find_last_of(char const *, unsigned int, unsigned int) const
			PVRTexLibDLL[173]:="?find_next_occurance_of@CPVRTString@@QBEHABV1@I@Z" ; public: int __thiscall CPVRTString::find_next_occurance_of(class CPVRTString const &, unsigned int) const
			PVRTexLibDLL[174]:="?find_next_occurance_of@CPVRTString@@QBEHDI@Z" ; public: int __thiscall CPVRTString::find_next_occurance_of(char, unsigned int) const
			PVRTexLibDLL[175]:="?find_next_occurance_of@CPVRTString@@QBEHPBDI@Z" ; public: int __thiscall CPVRTString::find_next_occurance_of(char const *, unsigned int) const
			PVRTexLibDLL[176]:="?find_next_occurance_of@CPVRTString@@QBEHPBDII@Z" ; public: int __thiscall CPVRTString::find_next_occurance_of(char const *, unsigned int, unsigned int) const
			PVRTexLibDLL[177]:="?find_number_of@CPVRTString@@QBEIABV1@I@Z" ; public: unsigned int __thiscall CPVRTString::find_number_of(class CPVRTString const &, unsigned int) const
			PVRTexLibDLL[178]:="?find_number_of@CPVRTString@@QBEIDI@Z" ; public: unsigned int __thiscall CPVRTString::find_number_of(char, unsigned int) const
			PVRTexLibDLL[179]:="?find_number_of@CPVRTString@@QBEIPBDI@Z" ; public: unsigned int __thiscall CPVRTString::find_number_of(char const *, unsigned int) const
			PVRTexLibDLL[180]:="?find_number_of@CPVRTString@@QBEIPBDII@Z" ; public: unsigned int __thiscall CPVRTString::find_number_of(char const *, unsigned int, unsigned int) const
			PVRTexLibDLL[181]:="?find_previous_occurance_of@CPVRTString@@QBEHABV1@I@Z" ; public: int __thiscall CPVRTString::find_previous_occurance_of(class CPVRTString const &, unsigned int) const
			PVRTexLibDLL[182]:="?find_previous_occurance_of@CPVRTString@@QBEHDI@Z" ; public: int __thiscall CPVRTString::find_previous_occurance_of(char, unsigned int) const
			PVRTexLibDLL[183]:="?find_previous_occurance_of@CPVRTString@@QBEHPBDI@Z" ; public: int __thiscall CPVRTString::find_previous_occurance_of(char const *, unsigned int) const
			PVRTexLibDLL[184]:="?find_previous_occurance_of@CPVRTString@@QBEHPBDII@Z" ; public: int __thiscall CPVRTString::find_previous_occurance_of(char const *, unsigned int, unsigned int) const
			PVRTexLibDLL[185]:="?format@CPVRTString@@QAA?AV1@PBDZZ" ; public: class CPVRTString __cdecl CPVRTString::format(char const *)
			PVRTexLibDLL[186]:="?formatPositional@CPVRTString@@QAA?AV1@PBDZZ" ; public: class CPVRTString __cdecl CPVRTString::formatPositional(char const *)
			PVRTexLibDLL[187]:="?getBitsPerPixel@CPVRTextureHeader@pvrtexture@@QBEIXZ" ; public: unsigned int __thiscall pvrtexture::CPVRTextureHeader::getBitsPerPixel(void) const
			PVRTexLibDLL[188]:="?getBorder@CPVRTextureHeader@pvrtexture@@QBEXAAI00@Z" ; public: void __thiscall pvrtexture::CPVRTextureHeader::getBorder(unsigned int &, unsigned int &, unsigned int &) const
			PVRTexLibDLL[189]:="?getBumpMapOrder@CPVRTextureHeader@pvrtexture@@QBE?AVCPVRTString@@XZ" ; public: class CPVRTString __thiscall pvrtexture::CPVRTextureHeader::getBumpMapOrder(void) const
			PVRTexLibDLL[190]:="?getBumpMapScale@CPVRTextureHeader@pvrtexture@@QBEMXZ" ; public: float __thiscall pvrtexture::CPVRTextureHeader::getBumpMapScale(void) const
			PVRTexLibDLL[191]:="?getChannelType@CPVRTextureHeader@pvrtexture@@QBE?AW4EPVRTVariableType@@XZ" ; public: enum EPVRTVariableType __thiscall pvrtexture::CPVRTextureHeader::getChannelType(void) const
			PVRTexLibDLL[192]:="?getColourSpace@CPVRTextureHeader@pvrtexture@@QBE?AW4EPVRTColourSpace@@XZ" ; public: enum EPVRTColourSpace __thiscall pvrtexture::CPVRTextureHeader::getColourSpace(void) const
			PVRTexLibDLL[193]:="?getCubeMapOrder@CPVRTextureHeader@pvrtexture@@QBE?AVCPVRTString@@XZ" ; public: class CPVRTString __thiscall pvrtexture::CPVRTextureHeader::getCubeMapOrder(void) const
			PVRTexLibDLL[194]:="?getD3DFormat@CPVRTextureHeader@pvrtexture@@QBEIXZ" ; public: unsigned int __thiscall pvrtexture::CPVRTextureHeader::getD3DFormat(void) const
			PVRTexLibDLL[195]:="?getDXGIFormat@CPVRTextureHeader@pvrtexture@@QBEIXZ" ; public: unsigned int __thiscall pvrtexture::CPVRTextureHeader::getDXGIFormat(void) const
			PVRTexLibDLL[196]:="?getDataPtr@CPVRTexture@pvrtexture@@QBEPAXIII@Z" ; public: void * __thiscall pvrtexture::CPVRTexture::getDataPtr(unsigned int, unsigned int, unsigned int) const
			PVRTexLibDLL[197]:="?getDataSize@CPVRTextureHeader@pvrtexture@@QBEIH_N0@Z" ; public: unsigned int __thiscall pvrtexture::CPVRTextureHeader::getDataSize(int, bool, bool) const
			PVRTexLibDLL[198]:="?getDepth@CPVRTextureHeader@pvrtexture@@QBEII@Z" ; public: unsigned int __thiscall pvrtexture::CPVRTextureHeader::getDepth(unsigned int) const
			PVRTexLibDLL[199]:="?getFileHeader@CPVRTextureHeader@pvrtexture@@QBE?AUPVRTextureHeaderV3@@XZ" ; public: struct PVRTextureHeaderV3 __thiscall pvrtexture::CPVRTextureHeader::getFileHeader(void) const
			PVRTexLibDLL[200]:="?getHeader@CPVRTexture@pvrtexture@@QBEABVCPVRTextureHeader@2@XZ" ; public: class pvrtexture::CPVRTextureHeader const & __thiscall pvrtexture::CPVRTexture::getHeader(void) const
			PVRTexLibDLL[201]:="?getHeight@CPVRTextureHeader@pvrtexture@@QBEII@Z" ; public: unsigned int __thiscall pvrtexture::CPVRTextureHeader::getHeight(unsigned int) const
			PVRTexLibDLL[202]:="?getMetaData@CPVRTextureHeader@pvrtexture@@QBE?AUMetaDataBlock@@II@Z" ; public: struct MetaDataBlock __thiscall pvrtexture::CPVRTextureHeader::getMetaData(unsigned int, unsigned int) const
			PVRTexLibDLL[203]:="?getMetaDataMap@CPVRTextureHeader@pvrtexture@@QBEPBV?$CPVRTMap@IV?$CPVRTMap@IUMetaDataBlock@@@@@@XZ" ; public: class CPVRTMap<unsigned int, class CPVRTMap<unsigned int, struct MetaDataBlock>> const * __thiscall pvrtexture::CPVRTextureHeader::getMetaDataMap(void) const
			PVRTexLibDLL[204]:="?getMetaDataSize@CPVRTextureHeader@pvrtexture@@QBEIXZ" ; public: unsigned int __thiscall pvrtexture::CPVRTextureHeader::getMetaDataSize(void) const
			PVRTexLibDLL[205]:="?getNumArrayMembers@CPVRTextureHeader@pvrtexture@@QBEIXZ" ; public: unsigned int __thiscall pvrtexture::CPVRTextureHeader::getNumArrayMembers(void) const
			PVRTexLibDLL[206]:="?getNumFaces@CPVRTextureHeader@pvrtexture@@QBEIXZ" ; public: unsigned int __thiscall pvrtexture::CPVRTextureHeader::getNumFaces(void) const
			PVRTexLibDLL[207]:="?getNumMIPLevels@CPVRTextureHeader@pvrtexture@@QBEIXZ" ; public: unsigned int __thiscall pvrtexture::CPVRTextureHeader::getNumMIPLevels(void) const
			PVRTexLibDLL[208]:="?getNumTextureAtlasMembers@CPVRTextureHeader@pvrtexture@@QBEHXZ" ; public: int __thiscall pvrtexture::CPVRTextureHeader::getNumTextureAtlasMembers(void) const
			PVRTexLibDLL[209]:="?getOGLESFormat@CPVRTextureHeader@pvrtexture@@QBEXAAI00@Z" ; public: void __thiscall pvrtexture::CPVRTextureHeader::getOGLESFormat(unsigned int &, unsigned int &, unsigned int &) const
			PVRTexLibDLL[210]:="?getOGLFormat@CPVRTextureHeader@pvrtexture@@QBEXAAI00@Z" ; public: void __thiscall pvrtexture::CPVRTextureHeader::getOGLFormat(unsigned int &, unsigned int &, unsigned int &) const
			PVRTexLibDLL[211]:="?getOrientation@CPVRTextureHeader@pvrtexture@@QBE?AW4EPVRTOrientation@@W4EPVRTAxis@@@Z" ; public: enum EPVRTOrientation __thiscall pvrtexture::CPVRTextureHeader::getOrientation(enum EPVRTAxis) const
			PVRTexLibDLL[212]:="?getPixelType@CPVRTextureHeader@pvrtexture@@QBE?ATPixelType@2@XZ" ; public: union pvrtexture::PixelType __thiscall pvrtexture::CPVRTextureHeader::getPixelType(void) const
			PVRTexLibDLL[213]:="?getTextureAtlasData@CPVRTextureHeader@pvrtexture@@QBEPBMXZ" ; public: float const * __thiscall pvrtexture::CPVRTextureHeader::getTextureAtlasData(void) const
			PVRTexLibDLL[214]:="?getTextureSize@CPVRTextureHeader@pvrtexture@@QBEIH_N0@Z" ; public: unsigned int __thiscall pvrtexture::CPVRTextureHeader::getTextureSize(int, bool, bool) const
			PVRTexLibDLL[215]:="?getVulkanFormat@CPVRTextureHeader@pvrtexture@@QBEIXZ" ; public: unsigned int __thiscall pvrtexture::CPVRTextureHeader::getVulkanFormat(void) const
			PVRTexLibDLL[216]:="?getWidth@CPVRTextureHeader@pvrtexture@@QBEII@Z" ; public: unsigned int __thiscall pvrtexture::CPVRTextureHeader::getWidth(unsigned int) const
			PVRTexLibDLL[217]:="?hasMetaData@CPVRTextureHeader@pvrtexture@@QBE_NII@Z" ; public: bool __thiscall pvrtexture::CPVRTextureHeader::hasMetaData(unsigned int, unsigned int) const
			PVRTexLibDLL[218]:="?isBumpMap@CPVRTextureHeader@pvrtexture@@QBE_NXZ" ; public: bool __thiscall pvrtexture::CPVRTextureHeader::isBumpMap(void) const
			PVRTexLibDLL[219]:="?isFileCompressed@CPVRTextureHeader@pvrtexture@@QBE_NXZ" ; public: bool __thiscall pvrtexture::CPVRTextureHeader::isFileCompressed(void) const
			PVRTexLibDLL[220]:="?isPreMultiplied@CPVRTextureHeader@pvrtexture@@QBE_NXZ" ; public: bool __thiscall pvrtexture::CPVRTextureHeader::isPreMultiplied(void) const
			PVRTexLibDLL[221]:="?left@CPVRTString@@QBE?AV1@I@Z" ; public: class CPVRTString __thiscall CPVRTString::left(unsigned int) const
			PVRTexLibDLL[222]:="?length@CPVRTString@@QBEIXZ" ; public: unsigned int __thiscall CPVRTString::length(void) const
			PVRTexLibDLL[223]:="?max_size@CPVRTString@@QBEIXZ" ; public: unsigned int __thiscall CPVRTString::max_size(void) const
			PVRTexLibDLL[224]:="?npos@CPVRTString@@2IB" ; public: static unsigned int const CPVRTString::npos
			PVRTexLibDLL[225]:="?privateLoadASTCFile@CPVRTexture@pvrtexture@@AAE_NPAU_iobuf@@@Z" ; private: bool __thiscall pvrtexture::CPVRTexture::privateLoadASTCFile(struct _iobuf *)
			PVRTexLibDLL[226]:="?privateLoadDDSFile@CPVRTexture@pvrtexture@@AAE_NPAU_iobuf@@@Z" ; private: bool __thiscall pvrtexture::CPVRTexture::privateLoadDDSFile(struct _iobuf *)
			PVRTexLibDLL[227]:="?privateLoadKTXFile@CPVRTexture@pvrtexture@@AAE_NPAU_iobuf@@@Z" ; private: bool __thiscall pvrtexture::CPVRTexture::privateLoadKTXFile(struct _iobuf *)
			PVRTexLibDLL[228]:="?privateLoadPVRFile@CPVRTexture@pvrtexture@@AAE_NPAU_iobuf@@@Z" ; private: bool __thiscall pvrtexture::CPVRTexture::privateLoadPVRFile(struct _iobuf *)
			PVRTexLibDLL[229]:="?privateSaveASTCFile@CPVRTexture@pvrtexture@@ABE_NPAU_iobuf@@@Z" ; private: bool __thiscall pvrtexture::CPVRTexture::privateSaveASTCFile(struct _iobuf *) const
			PVRTexLibDLL[230]:="?privateSaveCHeaderFile@CPVRTexture@pvrtexture@@ABE_NPAU_iobuf@@VCPVRTString@@@Z" ; private: bool __thiscall pvrtexture::CPVRTexture::privateSaveCHeaderFile(struct _iobuf *, class CPVRTString) const
			PVRTexLibDLL[231]:="?privateSaveDDSFile@CPVRTexture@pvrtexture@@ABE_NPAU_iobuf@@@Z" ; private: bool __thiscall pvrtexture::CPVRTexture::privateSaveDDSFile(struct _iobuf *) const
			PVRTexLibDLL[232]:="?privateSaveKTXFile@CPVRTexture@pvrtexture@@ABE_NPAU_iobuf@@@Z" ; private: bool __thiscall pvrtexture::CPVRTexture::privateSaveKTXFile(struct _iobuf *) const
			PVRTexLibDLL[233]:="?privateSaveLegacyPVRFile@CPVRTexture@pvrtexture@@ABE_NPAU_iobuf@@W4ELegacyApi@2@@Z" ; private: bool __thiscall pvrtexture::CPVRTexture::privateSaveLegacyPVRFile(struct _iobuf *, enum pvrtexture::ELegacyApi) const
			PVRTexLibDLL[234]:="?privateSavePVRFile@CPVRTexture@pvrtexture@@ABE_NPAU_iobuf@@@Z" ; private: bool __thiscall pvrtexture::CPVRTexture::privateSavePVRFile(struct _iobuf *) const
			PVRTexLibDLL[235]:="?push_back@CPVRTString@@QAEXD@Z" ; public: void __thiscall CPVRTString::push_back(char)
			PVRTexLibDLL[236]:="?removeMetaData@CPVRTextureHeader@pvrtexture@@QAEXABI0@Z" ; public: void __thiscall pvrtexture::CPVRTextureHeader::removeMetaData(unsigned int const &, unsigned int const &)
			PVRTexLibDLL[237]:="?reserve@CPVRTString@@QAEXI@Z" ; public: void __thiscall CPVRTString::reserve(unsigned int)
			PVRTexLibDLL[238]:="?resize@CPVRTString@@QAEXID@Z" ; public: void __thiscall CPVRTString::resize(unsigned int, char)
			PVRTexLibDLL[239]:="?right@CPVRTString@@QBE?AV1@I@Z" ; public: class CPVRTString __thiscall CPVRTString::right(unsigned int) const
			PVRTexLibDLL[240]:="?saveASTCFile@CPVRTexture@pvrtexture@@QBE_NABVCPVRTString@@@Z" ; public: bool __thiscall pvrtexture::CPVRTexture::saveASTCFile(class CPVRTString const &) const
			PVRTexLibDLL[241]:="?saveFile@CPVRTexture@pvrtexture@@QBE_NABVCPVRTString@@@Z" ; public: bool __thiscall pvrtexture::CPVRTexture::saveFile(class CPVRTString const &) const
			PVRTexLibDLL[242]:="?saveFileLegacyPVR@CPVRTexture@pvrtexture@@QBE_NABVCPVRTString@@W4ELegacyApi@2@@Z" ; public: bool __thiscall pvrtexture::CPVRTexture::saveFileLegacyPVR(class CPVRTString const &, enum pvrtexture::ELegacyApi) const
			PVRTexLibDLL[243]:="?setBorder@CPVRTextureHeader@pvrtexture@@QAEXIII@Z" ; public: void __thiscall pvrtexture::CPVRTextureHeader::setBorder(unsigned int, unsigned int, unsigned int)
			PVRTexLibDLL[244]:="?setBumpMap@CPVRTextureHeader@pvrtexture@@QAEXMVCPVRTString@@@Z" ; public: void __thiscall pvrtexture::CPVRTextureHeader::setBumpMap(float, class CPVRTString)
			PVRTexLibDLL[245]:="?setChannelType@CPVRTextureHeader@pvrtexture@@QAEXW4EPVRTVariableType@@@Z" ; public: void __thiscall pvrtexture::CPVRTextureHeader::setChannelType(enum EPVRTVariableType)
			PVRTexLibDLL[246]:="?setColourSpace@CPVRTextureHeader@pvrtexture@@QAEXW4EPVRTColourSpace@@@Z" ; public: void __thiscall pvrtexture::CPVRTextureHeader::setColourSpace(enum EPVRTColourSpace)
			PVRTexLibDLL[247]:="?setCubeMapOrder@CPVRTextureHeader@pvrtexture@@QAEXVCPVRTString@@@Z" ; public: void __thiscall pvrtexture::CPVRTextureHeader::setCubeMapOrder(class CPVRTString)
			PVRTexLibDLL[248]:="?setD3DFormat@CPVRTextureHeader@pvrtexture@@QAE_NABI@Z" ; public: bool __thiscall pvrtexture::CPVRTextureHeader::setD3DFormat(unsigned int const &)
			PVRTexLibDLL[249]:="?setDXGIFormat@CPVRTextureHeader@pvrtexture@@QAE_NABI@Z" ; public: bool __thiscall pvrtexture::CPVRTextureHeader::setDXGIFormat(unsigned int const &)
			PVRTexLibDLL[250]:="?setDepth@CPVRTextureHeader@pvrtexture@@QAEXI@Z" ; public: void __thiscall pvrtexture::CPVRTextureHeader::setDepth(unsigned int)
			PVRTexLibDLL[251]:="?setHeight@CPVRTextureHeader@pvrtexture@@QAEXI@Z" ; public: void __thiscall pvrtexture::CPVRTextureHeader::setHeight(unsigned int)
			PVRTexLibDLL[252]:="?setIsFileCompressed@CPVRTextureHeader@pvrtexture@@QAEX_N@Z" ; public: void __thiscall pvrtexture::CPVRTextureHeader::setIsFileCompressed(bool)
			PVRTexLibDLL[253]:="?setIsPreMultiplied@CPVRTextureHeader@pvrtexture@@QAEX_N@Z" ; public: void __thiscall pvrtexture::CPVRTextureHeader::setIsPreMultiplied(bool)
			PVRTexLibDLL[254]:="?setNumArrayMembers@CPVRTextureHeader@pvrtexture@@QAEXI@Z" ; public: void __thiscall pvrtexture::CPVRTextureHeader::setNumArrayMembers(unsigned int)
			PVRTexLibDLL[255]:="?setNumFaces@CPVRTextureHeader@pvrtexture@@QAEXI@Z" ; public: void __thiscall pvrtexture::CPVRTextureHeader::setNumFaces(unsigned int)
			PVRTexLibDLL[256]:="?setNumMIPLevels@CPVRTextureHeader@pvrtexture@@QAEXI@Z" ; public: void __thiscall pvrtexture::CPVRTextureHeader::setNumMIPLevels(unsigned int)
			PVRTexLibDLL[257]:="?setOGLESFormat@CPVRTextureHeader@pvrtexture@@QAE_NABI00@Z" ; public: bool __thiscall pvrtexture::CPVRTextureHeader::setOGLESFormat(unsigned int const &, unsigned int const &, unsigned int const &)
			PVRTexLibDLL[258]:="?setOGLFormat@CPVRTextureHeader@pvrtexture@@QAE_NABI00@Z" ; public: bool __thiscall pvrtexture::CPVRTextureHeader::setOGLFormat(unsigned int const &, unsigned int const &, unsigned int const &)
			PVRTexLibDLL[259]:="?setOrientation@CPVRTextureHeader@pvrtexture@@QAEXW4EPVRTOrientation@@@Z" ; public: void __thiscall pvrtexture::CPVRTextureHeader::setOrientation(enum EPVRTOrientation)
			PVRTexLibDLL[260]:="?setPixelFormat@CPVRTextureHeader@pvrtexture@@QAEXTPixelType@2@@Z" ; public: void __thiscall pvrtexture::CPVRTextureHeader::setPixelFormat(union pvrtexture::PixelType)
			PVRTexLibDLL[261]:="?setTextureAtlas@CPVRTextureHeader@pvrtexture@@QAEXPAMI@Z" ; public: void __thiscall pvrtexture::CPVRTextureHeader::setTextureAtlas(float *, unsigned int)
			PVRTexLibDLL[262]:="?setWidth@CPVRTextureHeader@pvrtexture@@QAEXI@Z" ; public: void __thiscall pvrtexture::CPVRTextureHeader::setWidth(unsigned int)
			PVRTexLibDLL[263]:="?size@CPVRTString@@QBEIXZ" ; public: unsigned int __thiscall CPVRTString::size(void) const
			PVRTexLibDLL[264]:="?substitute@CPVRTString@@QAEAAV1@DD_N@Z" ; public: class CPVRTString & __thiscall CPVRTString::substitute(char, char, bool)
			PVRTexLibDLL[265]:="?substitute@CPVRTString@@QAEAAV1@PBD0_N@Z" ; public: class CPVRTString & __thiscall CPVRTString::substitute(char const *, char const *, bool)
			PVRTexLibDLL[266]:="?substr@CPVRTString@@QBE?AV1@II@Z" ; public: class CPVRTString __thiscall CPVRTString::substr(unsigned int, unsigned int) const
			PVRTexLibDLL[267]:="?swap@CPVRTString@@QAEXAAV1@@Z" ; public: void __thiscall CPVRTString::swap(class CPVRTString &)
			PVRTexLibDLL[268]:="?toLower@CPVRTString@@QAEAAV1@XZ" ; public: class CPVRTString & __thiscall CPVRTString::toLower(void)
			PVRTexLibDLL[269]:="?toUpper@CPVRTString@@QAEAAV1@XZ" ; public: class CPVRTString & __thiscall CPVRTString::toUpper(void)
			}
		Return this.PVRTexLibDLL:=PVRTexLibDLL
	}
	;;;;; Helper Functions ;;;;;
	_QPC(R:=0){ ; By SKAN, http://goo.gl/nf7O4G, CD:01/Sep/2014 | MD:01/Sep/2014
	  Static P:=0, F:=0, Q:=DllCall("QueryPerformanceFrequency","Int64P",F)
	  Return !DllCall("QueryPerformanceCounter","Int64P",Q)+(R?(P:=Q)/F:(Q-P)/F) 
	}
}







;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
#Include PS_ExceptionHandler.ahk	; https://github.com/Sampsca/PS_ExceptionHandler
#Include PushLog.ahk
#Include MemoryFileIO.ahk
