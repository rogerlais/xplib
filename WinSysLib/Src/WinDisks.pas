{$IFDEF WinDisks}
{$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I WinSysLib.inc}
unit WinDisks;

interface

uses Windows, SysUtils;

type
	//TDriveType= (dtUnknown, dtNoDrive, dt3Floppy, dt5Floppy, dtFixed, dtRFixed, dtNetwork, dtCDROM, dtTape); Servicos extendidos requeridos para uso deste tipo foram removidos com WIN32

	PDeviceParams = ^TDeviceParams;

	TDeviceParams = record
		bSpecFunc: byte; { Special functions }
		bDevType: byte; { Device type }
		wDevAttr: Word; { Device attributes }
		wCylinders: Word; { Number of cylinders }
		bMediaType: byte; { Media type }
		{ Beginning of BIOS parameter block (BPB) }
		wBytesPerSec: Word; { Bytes per sector }
		bSecPerClust: byte; { Sectors per cluster }
		wResSectors: Word; { Number of reserved sectors }
		bFATs: byte; { Number of FATs }
		wRootDirEnts: Word; { Number of root-directory entries }
		wSectors: Word; { Total number of sectors }
		bMedia: byte; { Media descriptor }
		wFATsecs: Word; { Number of sectors per FAT }
		wSecPerTrack: Word; { Number of sectors per track }
		wHeads: Word; { Number of heads }
		dwHiddenSecs: longint; { Number of hidden sectors }
		dwHugeSectors: longint; { Number of sectors if wSectors == 0 }
		reserved: array[0 .. 10] of char;
		{ End of BIOS parameter block (BPB) }
	end;

	{ Retorna o espaco livre de uma unidade de disco }
function _DiskFree(Drive: byte): int64;
{ Retorna a capacidade total de uma unidade de disco }
function _DiskSize(Drive: byte): int64;
{ Tests to see if a drive is ready.  (floppy there and door closed) }
function DriveReady(wDrive: Word): boolean;
{ Returns current default drive }
function GetDefaultDrive: Word;
{ Gets drive label }
function GetDriveLabel(wDrive: Word): string; platform; deprecated;
{ Leitura do volume do disco }
function GetVolumeLabel(Value: char): string;
//Retorna string contendo as letras presentes na maquina segundo os tipos passados
function GetDrivesStringChain(DesiredDriveType: UINT): string;
{ Identify a CD-ROM drive }
function IsCDROMDrive(wDrive: Word): boolean;
//Salva todo o cache do disco. Funciona apenas para Win9.x
procedure SaveWin9xOSDiskCache(Drive: Word);

implementation

{ ------------------------------------------------------------------------------ }
{ Retorna o espaco livre de uma unidade de disco }
function _DiskFree(Drive: byte): int64;
var
	RootPath: array[0 .. 4] of char;
	RootPtr:  PChar;
	SectorsPerCluster, BytesPerSector, FreeClusters, TotalClusters: cardinal;
	OS:                       OSVERSIONINFO;
	TotalFree, TotalExisting: int64;
begin
	RootPtr := nil;
	if Drive > 0 then begin
		StrCopy(RootPath, 'A:\');
		RootPath[0] := char(Drive + $40);
		RootPtr := RootPath;
	end;
	OS.dwOSVersionInfoSize := SizeOf(OSVERSIONINFO);
	GetVersionEx(OS);
	if (OS.dwMajorVersion = 4) and (OS.dwBuildNumber < 1000) and (OS.dwPlatformId = 1) then begin //Usar modo do OSR1
		if GetDiskFreeSpace(RootPtr, SectorsPerCluster, BytesPerSector, FreeClusters, TotalClusters) then begin
			Result := (SectorsPerCluster * BytesPerSector * FreeClusters);
		end else begin
			Result := -1;
		end;
	end else begin //Usar os servicos do NT ou Win95B ou superior
		{$WARN UNSAFE_CODE OFF}
		if not GetDiskFreeSpaceEx(RootPtr, Result, TotalExisting, @TotalFree) then begin
			Result := -1;
		end;
		{$WARN UNSAFE_CODE ON}
	end;
end;

{ ------------------------------------------------------------------------------ }
function _DiskSize(Drive: byte): int64;
var
	RootPath: array[0 .. 4] of char;
	RootPtr:  PChar;
	SectorsPerCluster, BytesPerSector, FreeClusters, TotalClusters: cardinal;
	OS:                      OSVERSIONINFO;
	TotalFree, FreeAvailble: int64;
begin
	RootPtr := nil;
	if Drive > 0 then begin
		StrCopy(RootPath, 'A:\');
		RootPath[0] := char(Drive + $40);
		RootPtr := RootPath;
	end;
	OS.dwOSVersionInfoSize := SizeOf(OSVERSIONINFO);
	GetVersionEx(OS);
	if (OS.dwMajorVersion = 4) and (OS.dwBuildNumber < 1000) and (OS.dwPlatformId = 1) then begin //Usar modo do OSR1
		if GetDiskFreeSpace(RootPtr, SectorsPerCluster, BytesPerSector, FreeClusters, TotalClusters) then begin
			Result := (SectorsPerCluster * BytesPerSector * TotalClusters);
		end else begin
			Result := -1;
		end;
	end else begin //Usar os servicos do NT ou Win95B ou superior
		{$WARN UNSAFE_CODE OFF}
		if not GetDiskFreeSpaceEx(RootPtr, FreeAvailble, Result, @TotalFree) then begin
			Result := -1;
		end;
		{$WARN UNSAFE_CODE ON}
	end;
end;

{ ------------------------------------------------------------------------------ }
{ determins if the drive is ready w/o critical errors enabled }
function DriveReady(wDrive: Word): boolean;
var
	OldErrorMode: Word;
begin
	{ turn off errors }
	OldErrorMode := SetErrorMode(SEM_FAILCRITICALERRORS);
	try
		if DiskSize(wDrive) = -1 then begin
			Result := False;
		end else begin
			Result := True;
		end;
	finally
		{ turn on errors }
		SetErrorMode(OldErrorMode);
	end;
end;

{ ------------------------------------------------------------------------------ }

function GetDefaultDrive: Word; assembler;
begin
	{$WARN UNSAFE_CODE OFF}  {$WARN NO_RETVAL OFF} //apelado pelo compilador n�o interpretar AX como retorno
	asm
		mov     ah, 19h               { convert default to real }
		int     21h                      { int    21h }
		xor     ah, ah                { clear hi byte, where is made the return of function }
	end;
end; {$WARN UNSAFE_CODE ON}  {$WARN NO_RETVAL ON}

function GetDriveLabel(wDrive: Word): string; platform; deprecated;
//IMPORTANTE - Rotina passou a falhar com o WinXP SP2 ou superior, Usar GetVolumeLabel() pelo momento

{ ------------------------------------------------------------------------------ }
//Get label from drive.  0=default, 1=A...
//return string of 11 character or "NO NAME" if not found
var
	sr:           TsearchRec;
	OldErrorMode: Word;
	DotPos:       byte;
	pattern:      AnsiString;
begin
	{ TODO -oroger -clib : Corrigir este c�digo para funcionar com Win XP SP2 ou superior }
	//VALOR Original = pattern:= 'c:\*.';
	pattern := 'c:\*.*';
	{ get default drive }
	if wDrive = 0 then begin
		wDrive := GetDefaultDrive;
	end else begin
		Dec(wDrive);
	end;

	{ switch out drive letter }
	{$WARN UNSAFE_CODE OFF}   	{$WARN IMMUTABLE_STRINGS OFF}
	pattern[1] := AnsiChar(65 + wDrive);
	{$WARN UNSAFE_CODE ON}  	{$WARN IMMUTABLE_STRINGS ON}
	{ stop errors and try }
	OldErrorMode := SetErrorMode(SEM_FAILCRITICALERRORS);
	try
		{$WARN EXPLICIT_STRING_CAST OFF}
		if FindFirst(string(pattern), faVolumeID, sr) = 0 then begin
			Result := sr.Name;
			DotPos := Pos('.', Result);
			if DotPos <> 0 then begin
				Delete(Result, DotPos, 1);
			end;
		end else begin
			Result := 'NO NAME';
		end;
		{$WARN EXPLICIT_STRING_CAST ON}
	finally
		{ restore errorsa }
		SetErrorMode(OldErrorMode);
		{$IFDEF WIN32}
		FindClose(sr);
		{$ENDIF}
	end;
end;

function GetVolumeLabel(Value: char): string;
var
	VolumeLabel, FileSystem:    array[0 .. MAX_PATH] of char;
	SerialNumber, DW, SysFlags: DWord;
begin
	Value := UpCase(Value);
	if (Value >= 'A') and (Value <= 'Z') then begin
		{$WARN UNSAFE_CODE OFF}
		GetVolumeInformation(PChar(Value + ':\'), VolumeLabel, Length(VolumeLabel), PDWord(@SerialNumber), DW, SysFlags, FileSystem,
			Length(FileSystem));
		{$WARN UNSAFE_CODE ON}
		Result := VolumeLabel;
	end;
end;

function GetDrivesStringChain(DesiredDriveType: UINT): string;
//----------------------------------------------------------------------------------------------------------------------------------
//Retorna string contendo as letras presentes na maquina segundo os tipos passados
{
  **** Tipos validos  *****
  DRIVE_UNKNOWN = 0;
  DRIVE_NO_ROOT_DIR = 1;
  DRIVE_REMOVABLE = 2;
  DRIVE_FIXED = 3;
  DRIVE_REMOTE = 4;
  DRIVE_CDROM = 5;
  DRIVE_RAMDISK = 6;
}
var
	DriveNum:  Integer;
	DriveChar: char;
	DriveBits: set of 0 .. 25;
begin
	Result := EmptyStr;
	Integer(DriveBits) := GetLogicalDrives;
	for DriveNum := 0 to 25 do begin
		if not(DriveNum in DriveBits) then begin //Letra nao existe na maquina
			Continue;
		end;
		DriveChar := char(DriveNum + Ord('a'));
		if GetDriveType(PChar(DriveChar + ':\')) = DesiredDriveType then begin
			Result := Result + UpCase(DriveChar);
		end;
	end;
end;

function IsCDROMDrive(wDrive: Word): boolean; assembler;
//----------------------------------------------------------------------------------------------------------------------------------
//Determine id drive is a CDROM, 0=default, 1=A ...
var
	wTempDrive: Word;
begin {$WARN NO_RETVAL OFF}  {$WARN UNSAFE_CODE OFF}  //apelando por ser rotina ultrapassada, mas sem substituta ainda
	asm
		mov     AX, wDrive
		or      AX, AX
		jnz     @not_default
		mov     AH, 19h             { convert default to drive }
		int     21h                    { int    21h }
		xor     AH, AH
		mov     wTempDrive, AX
		jmp     @test_it
	@not_default:
		{ zero base it }
		dec     AX
		mov     wTempDrive, AX
	@test_it:

		mov     AX, 1500h             { first test for presence of MSCDEX }
		xor     BX, BX
		int     2fh
		mov     AX, BX                { MSCDEX is not there if BX is zero }
		or      AX, AX                { so return FALSE }
		jz      @no_mscdex
		mov     AX, 150bh             { MSCDEX driver check API }
		mov     CX, wTempDrive        { ...cx is drive index }
		int     2Fh
		or      AX, AX
	@no_mscdex:
	end;
	{$WARN UNSAFE_CODE ON}
end; {$WARN NO_RETVAL ON}

procedure SaveWin9xOSDiskCache(Drive: Word);
//----------------------------------------------------------------------------------------------------------------------
//Salva todo o cache do disco. Funciona apenas para Win9.x
begin
	//NOTAS : As flags podem ser
	//0000h
	//Resets the drive and flushes the file system buffers for the given drive.
	//0001h
	//Resets the drive, flushes the file system buffers, and flushes and invalidates the cache for the specified drive.
	//0002h
	//Remounts the drivespace volume
	{$WARN UNSAFE_CODE OFF}
	asm
		mov     ax, 710Dh;      //Reset Drive
		mov     cx, 0000h;      //see above para os valores da flag
		mov     dx, Drive;      //see belowint 21h
	end;
	{$WARN UNSAFE_CODE ON}
end;

end.
