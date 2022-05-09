# PS BAM
## Copyright (c) 2012-2022 Sam Schmitz

So here goes nothing…  PS BAM is sort of my pet project.  I’ve been working on it on and off for years, and I hope it’s finally to a point where I can start sharing it with others.  Consider this an ALPHA version:  use it at your own risk!  It is still under active development and hasn’t been tested extensively in the wild yet.  As such, bugs and inconsistencies are not only possible, but likely.  The project had several ~~false~~ different starts and iterations over the years, but this version of PS BAM started out with the goal of achieving **very** good BAM compression at the cost of processing time.  I believe I have achieved this to a great extent (although a 4th level of compression is theoretically possible but as yet unimplemented), but the project has also expanded in a variety of other directions.

PS BAM is a command-line tool that can use a modified median cut algorithm I wrote which seems to produce results comparable to ImageMagick without dithering.  The quantization algorithm supports the alpha channel, but I haven't really tested how good the results are.  I built in the ability to weight the different channels differently, so some tweaking of the default settings may or may not be in order.  My tool can read BAM, BAMC, BAMU, and BAMD files and save them as BAM or BAMC files, optionally with quite extensive compression.  It can also save files as BAMDs or animated GIFs, and can export and import palettes in a variety of formats including PAL, ACT, BMP, visual BMP, visual PNG, and raw.  I natively support GIF and some BMP variants in imports and exports, and use GDIplus for the rest which means BMP, DIB, RLE, JPG, JPEG, JPE, JFIF, GIF, TIF, TIFF, and PNG are also supported, although import isn't as fast.  It can also perform a variety of other processing operations on frames and their offsets.  BAM V2 files can be read, but not saved to.

Some notes to keep in mind:  PS BAM can perform such extensive compression that some editors can’t read the resulting files properly.  Some settings BAMWorkshop can’t handle but BAMWorkshopII can and vice versa, some settings DLTCEP can’t handle, and other settings that some versions of the game engine can handle while other versions can’t.  NearInfinity can probably handle most compression techniques, but one was recently identified that it couldn’t (although a fix has been pushed to GitHub).  My point is, just because your usual editor won’t open a particular BAM that PS BAM produced doesn’t necessarily mean it is “broken”.  Ultimately the only way to know for sure it to try it in the game.  Additionally, if building BAMs from individual images/sequences of images, I must make an assumption about which colors should be treated as the special transparent and shadow colors.  Because of these assumptions, you really should use pure green as the transparent color and pure black as the shadow color in your images.  You may very well have undesired results if you don’t.

At this time, PS BAM doesn’t really have any documentation.  If you can’t figure out what a particular switch does, please ask.  If you can’t figure out how to do what you want, PS BAM can probably do it so ask and I’ll explain how.  If there is something you want it to do that it currently can’t, describe what you want in detail.  There is enough architecture there that I can probably make it do what you want without a whole lot of effort (given a detailed-enough description of what you want).  If a BAM it produces doesn’t load in a particular BAM editor, try some other ones (or better yet, try it in the game) before assuming there is a bug in PS BAM.  If you do find a bug or inconsistency, or encounter a program exception or crash, here are the steps to give me what I need to identify, reproduce, and fix it:
1. Clear your log file or start a new one.  Turn on maximum debug reporting (with the command switches --DebugLevelL 2 --DebugLevelP 2 --DebugLevelS 2), and save the debug log to file (with e.g. --LogFile "D:\Path\To\Log\File\Log.txt")
1. Rerun the same command that gave you the issue with the same settings as before, but with the debug logging turned on as noted above.  If you can rerun the same command with fewer and fewer switches to narrow down which one or combination is causing the issue, that would be very helpful.
1. When you report the issue, do so as if you were reporting a bug to Beamdog on redmine.  Please provide repo steps including the full set of commands and switches used to run the program, and include statements describing the observed behavior vs the expected behavior.  Please also send me the debug log you created (in [spoiler][/spoiler] tags if you don’t attach it as a file) as well as all input files and output files (if any were produced).  If PS BAM displays an error that doesn’t make it to the console/log, please also provide that message.

Below is an example of how to run PS BAM, either from the command prompt or from a Batch file:
"PS BAM.exe" --CompressionProfile "Recommended" --DebugLevelL 1 --DebugLevelP 2 --DebugLevelS 1 --LogFile "D:\BAMs to compress\compressed\Log.txt" --OutPath "D:\BAMs to compress\compressed" --Save "BAM" "D:\BAMs to compress\*.bam”

Here's an alternate way to set up the Batch file, with all of the possible settings listed:
```SET prefix=1CLCK07B

"D:\AutoHotkey Scripts\PS BAM\PS BAM.ahk" ^
--DebugLevelL 1 ^
--DebugLevelP 2 ^
--DebugLevelS 1 ^
--Save "BAM" ^
--ExportPalette "" ^
--ExportFrames "" ^
--ExportFramesAsSequences 1 ^
--ExportWithTransparency 1 ^
--OrderOfOperations "PCE" ^
--SingleGIF 0 ^
--ReplacePalette "" ^
--ReplacePaletteMethod "Quant" ^
--CompressionProfile "" ^
--FixPaletteColorErrors 1 ^
--AutodetectPalettedBAM 1 ^
--AutodetectPalettedThreshold 500 ^
--DropDuplicatePaletteEntries 1 ^
--DropUnusedPaletteEntries 1 ^
--SearchTransColor 1 ^
--ForceTransColor 1 ^
--ForceShadowColor 4 ^
--AlphaCutoff 10 ^
--AllowShortPalette 1 ^
--TrimFrameData 1 ^
--ExtraTrimBuffer 2 ^
--ExtraTrimDepth 3 ^
--ReduceFrameRowLT 1 ^
--ReduceFrameColumnLT 1 ^
--ReduceFramePixelLT 1 ^
--DropDuplicateFrameData 1 ^
--DropUnusedFrameData 1 ^
--IntelligentRLE 1 ^
--MaxRLERun 255 ^
--FindBestRLEIndex 0 ^
--DropDuplicateFrameEntries 1 ^
--DropUnusedFrameEntries 1 ^
--AdvancedFLTCompression 1 ^
--FLTSanityCutoff 5040 ^
--DropEmptyCycleEntries 0 ^
--AdvancedZlibCompress 2 ^
--zopfliIterations 5000 ^
--BAMProfile "" ^
--Unify 0 ^
--Fill "" ^
--Montage "" ^
--ModXOffset 0 ^
--ModYOffset 0 ^
--SetXOffset "" ^
--SetYOffset "" ^
--ItemIcon2EE 0 ^
--Flip 0 ^
--Flop 0 ^
--Rotate 0 ^
--LogFile "%~dp0Log.txt" ^
--OutPath "%~dp0compressed" ^
"%~dp0%prefix%.bam"

Pause
Exit```

Here is a full list of all possible settings, and their default values:

```;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;    Global Settings   ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
--OutPath "%A_ScriptDir%\compressed"
--DebugLevelL 1		; | -1 | 0 | 1 | 2 |
--DebugLevelP 2		; | -1 | 0 | 1 | 2 |
--DebugLevelS 1		; | -1 | 0 | 1 | 2 |
--LogFile ""
--VerifyOutput 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;     IO Settings      ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
--Save "BAM"			; | BAM | BAMD | GIF |	; (BAMD takes frame filetype from --ExportFrames)
--ExportPalette ""		; | ACT | ALL | Bin | BMP | BMPV | PAL | Raw | PNGV |
--ExportFrames ""		; | BMP | DIB | GIF | JFIF | JPE | JPEG | JPG | PNG | RLE | TIF | TIFF || BMP,8V3 | BMP,24V3 | BMP,32V5 |
--ExportFramesAsSequences 0
--ExportWithTransparency 1	; -1 = Explicitly disable transparency; 0 or 1 = Default transparency handling; 2 = Additionally enable background and shadow color transparency
--OrderOfOperations "PCE"	; P = Process; C = Compress; E = Export; in any order.  e.g. | CPE | CEP | PCE | PEC | EPC | ECP |
--SingleGIF 0
--ReplacePalette ""
--ReplacePaletteMethod "Quant"	; | Force | Remap | Quant


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; Compression Settings ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
--CompressionProfile ""		; | Max | Recommended | Safe | Quick | None |	; (is position dependent!!!)
--FixPaletteColorErrors 1
--AutodetectPalettedBAM 0
--AutodetectPalettedThreshold 500	; 14100 will identify vanilla off-paletted palettes as paletted.  500 will identify BW1 palette colors as paletted.
--DropDuplicatePaletteEntries 0
--DropUnusedPaletteEntries 0	; | 0=OFF | 1=ON | 2=only from end |
--SearchTransColor 1		; BG1/PST TransColor might not be palette entry 0 (so you should search)
--ForceTransColor 0
--ForceShadowColor 0		; -1=Ensure No Shadow color | 0=None | 1=Force | 2=Move | 3=Insert (move will insert if fails) | 4=Search
--AlphaCutoff 0 ; 10,255			; 0 to disable or "LowBound,HighBound"
--AllowShortPalette 0

--TrimFrameData 0
	--ExtraTrimBuffer 0	; 2
	--ExtraTrimDepth 0	; 3
	--ReduceFrameRowLT 0
	--ReduceFrameColumnLT 0
	--ReduceFramePixelLT 0
--DropDuplicateFrameData 0
--DropUnusedFrameData 0
--IntelligentRLE 0
	--MaxRLERun 254		; if 255 do so intelligently (only if it saves space) ; 255 causes issues with BAMWorkshop 1
	--FindBestRLEIndex 0	; May cause issues with EE engine games

--DropDuplicateFrameEntries 0
--DropUnusedFrameEntries 0	; Can cause issues with BAMWorkshop II if used alone.

--AdvancedFLTCompression 0
	--FLTSanityCutoff 720	; | 5!=120 | 6!=720 | 7!=5,040 | 8!=40,320 | 9!=362,880 | 10!=3,628,800 | 11!=39,916,800 |

--DropEmptyCycleEntries 0

--AdvancedZlibCompress 0	; | 0=None | 1=Zlib | 2=zopfli |	; BG1/PST can't handle BAMC
	--zopfliIterations 500	; 1000000


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; Additional Processing Settings ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
--BAMProfile ""			; | ItemIcon | DescriptionIcon | Zero | Paperdoll | SpellIconEE | GroundIcon | DescriptionIconEE | ItemIconPST | GroundIconPST | SpellIcon | Spell |
--Unify 0			; | 0=Off | 1=On | 2=Square |
--Fill ""			; widthXheight,orientation		Note:  EITHER width or height may be zero, indicating no change.  orientation may be any of:  | NorthWest | TopLeft | NorthEast | TopRight | SouthWest | BottomLeft | SouthEast | BottomRight | North | Top | East | Right | South | Bottom | West | Left |
--Montage ""		; | Paperdoll | DescriptionIcon | 2x2SplitCreAnim | 2x2External | 2x2ExternalIgnoreOffsets | 1x2External | 2x1External | 1x2ExternalIgnoreOffsets | 2x1ExternalIgnoreOffsets | 3x3SplitCreAnim | [or other (rows x columns) using sequences within same BAM]
--ModXOffset 0
--ModYOffset 0
--SetXOffset ""
--SetYOffset ""
--ItemIcon2EE 0
--Flip 0
--Flop 0
--Rotate 0
```

If the value or path you want to send to the program contains spaces, it must be enclosed in double quotes.  IIRC the only switch that is position dependent is CompressionProfile.  The file(s) to process should come at the very end, and support the wildcard character &#42;.  Multiple files to process can be specified in the same call to PS BAM.
