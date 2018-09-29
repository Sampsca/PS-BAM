;http://www.autohotkey.com/board/topic/59576-filecrc32-filesha1-filemd5-and-md5/
MD5( V ) { ; www.autohotkey.com/forum/viewtopic.php?p=376840#376840
 MD5:="", VarSetCapacity( MD5_CTX,104,0 ), DllCall( "advapi32\MD5Init", UInt,&MD5_CTX )
 DllCall( "advapi32\MD5Update", UInt,&MD5_CTX, A_IsUnicode ? "AStr" : "Str",V, UInt,StrLen(V) )
 DllCall( "advapi32\MD5Final", UInt,&MD5_CTX )
 Loop % StrLen( Hex:="123456789ABCDEF0" )
  N := NumGet( MD5_CTX,87+A_Index,"Char"), MD5 .= SubStr(Hex,N>>4,1) . SubStr(Hex,N&15,1)
Return MD5
}

;http://www.autohotkey.com/board/topic/59576-filecrc32-filesha1-filemd5-and-md5/
FileMD5( sFile="", cSz=4 ) { ; www.autohotkey.com/forum/viewtopic.php?p=275910#275910 
 MD5:="", bytesRead:=""
 cSz  := (cSz<0||cSz>8) ? 2**22 : 2**(18+cSz), VarSetCapacity( Buffer,cSz,0 ) 
 hFil := DllCall( "CreateFile", Str,sFile,UInt,0x80000000, Int,3,Int,0,Int,3,Int,0,Int,0, "Ptr") 
 IfLess,hFil,1, Return,hFil
 DllCall( "GetFileSizeEx", Ptr,hFil, Ptr, &Buffer ),   fSz := NumGet( Buffer,0,"Int64" ) 
 VarSetCapacity( MD5_CTX,104,0 ),    DllCall( "advapi32\MD5Init", PTR, &MD5_CTX ) 
 Loop % ( fSz//cSz+!!Mod(fSz,cSz) ) 
   DllCall( "ReadFile", PTR,hFil, PTR, &Buffer, UInt,cSz, UIntP,bytesRead, UInt,0 ) 
 , DllCall( "advapi32\MD5Update", PTR, &MD5_CTX, PTR, &Buffer, UInt,bytesRead ) 
 DllCall( "advapi32\MD5Final", PTR, &MD5_CTX ), DllCall( "CloseHandle", PTR,hFil ) 
 Loop % StrLen( Hex:="123456789ABCDEF0" )
  N := NumGet( MD5_CTX,87+A_Index,"Char"), MD5 .= SubStr(Hex,N>>4,1) . SubStr(Hex,N&15,1) 
Return MD5 
}