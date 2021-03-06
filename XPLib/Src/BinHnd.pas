{$IFDEF BinHnd}
{$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I XPLib.inc}
unit BinHnd;

interface

uses SysUtils, StrHnd;

const
  HEX_DIGITS: array [0 .. 15] of char = '0123456789ABCDEF';

  { Verifica se caracter e digito hexa }
function __CharHexa(const C: char): boolean;
{ Verifica se a string pode ser considerada como representacao de um unico byte }
function __StrByte(const Str: string): boolean;
{ Verifica se a string passada e um numero hexadecimal de qualquer comprimento }
function __StrHexa(const Str: string): boolean;
{ Retorna a string hexa correspondente ao valor de um byte dado }
function Byte2Hexa(const B: Byte): string;
{ Retorna a string hexa correspondente ao valor de um inteiro longo dado }
function Long2Hexa(const Long: longInt): string;
{ Retorna uma word criado a partir dos bits da string }
function StrBin2Word(Str: string): word;
{ Retorna um byte criado a partir de dois digitos Hexa }
function StrHex2Byte(const Str: string): Byte;
{ Retorna um longint correspondendo a conversão de um string com representação
  em hexadecimal }
function StrHex2Long(Str: string): longInt;
{ Retorna a string hexa correspondente ao valor de um inteiro sem sinal dado }
function Word2Hexa(const w: word): string;
{ Gera string com a representação binaria da word }
function Word2StrBin(w: word): string;

implementation

uses Super;

{ ----------------------------------------------------------------------------- }
{ Retorna um inteiro criado a partir dos bits da string }
function StrBin2Word(Str: string): word;
var
  i: Byte;
begin
  Result := 0;
  for i := 1 to length(Str) do begin
	if not CharInSet(Str[i], ['0' .. '1']) { (Str[i] in ['0'..'1']) } then begin
	  Result := 0;
	  Exit;
	end;
  end;
  while Str > '' do begin
	Result := Result * 2 + ord(Str[1]) - 48;
	Delete(Str, 1, 1);
  end;
end;

{ ----------------------------------------------------------------------------- }
{$F+}

{ Retorna um byte criado a partir de dois digitos Hexa }
function StrHex2Byte(const Str: string): Byte;
var
  l, h: Byte;
begin
  h := Pos(UpCase(Str[1]), HEX_DIGITS);
  l := Pos(UpCase(Str[2]), HEX_DIGITS);
  if (h = 0) or (l = 0) then begin
	Result := 0;
  end else begin
	Result := (h - 1) * 16 + l - 1;
  end;
end;

{$F-}

{ ----------------------------------------------------------------------------- }
{ Gera string com a representação binaria da word }
function Word2StrBin(w: word): string;
begin
  Result := '';
  while w > 0 do begin
	Result := Chr(w mod 2 + 48) + Result;
	w := w div 2;
  end;
  if Result = '' then begin
	Result := '0';
  end;
end;

{ ----------------------------------------------------------------------------- }
{ Verifica se caracter e digito hexa }
function __CharHexa(const C: char): boolean;
begin
  if Pos(UpCase(C), '0123456789ABCDEF') > 0 then begin
	Result := TRUE;
  end else begin
	Result := FALSE;
  end;
end;

{ ----------------------------------------------------------------------------- }
{ Verifica se a string pode ser considerada como a representacao de um unico byte }
function __StrByte(const Str: string): boolean;
begin
  Result := (length(Str) = 2) and (__CharHexa(Str[1])) and (__CharHexa(Str[2]));
end;

{ ----------------------------------------------------------------------------- }
function Byte2Hexa(const B: Byte): string;
begin
  Result := HEX_DIGITS[B shr 4] + HEX_DIGITS[B and 15];
end;

{ ----------------------------------------------------------------------------- }
{ Retorna a string hexa correspondente ao valor de um inteiro sem sinal dado }
function Word2Hexa(const w: word): string { [4] };
begin
  {$WARN UNSAFE_CODE OFF}
  Result := Byte2Hexa(hi(w)) + Byte2Hexa(lo(w));
  {$WARN UNSAFE_CODE ON}
end;

{ ----------------------------------------------------------------------------- }
{ Retorna a string hexa correspondente ao valor de um inteiro longo dado }
function Long2Hexa(const Long: longInt): string;
begin
  Result := Word2Hexa(Long shr 16) + Word2Hexa(Long and $FFFF);
end;

{ ----------------------------------------------------------------------------- }
{ Verifica se a string passada e um numero hexadecimal de qualquer comprimento }
function __StrHexa(const Str: string): boolean;
var
  i: Byte;
begin
  Result := FALSE;
  for i := 1 to length(Str) do begin
	if not(__CharHexa(Str[i])) then begin
	  Exit;
	end;
  end;
  Result := TRUE;
end;

{ ----------------------------------------------------------------------------- }
{ Retorna a string hexa correspondente ao valor de um inteiro longo dado }
function StrHex2Long(Str: string): longInt;
begin
  Result := 0;
  if not __StrHexa(Str) then begin
	Exit;
  end;
  if length(Str) > 8 then begin
	Str := copy(Str, length(Str) - 7, 8);
  end;
  while Str > '' do begin
	Result := Result * 16 + ord(UpCase(Str[1])) - IIfInt(UpCase(Str[1]) <= '9', 48, 55);
	Delete(Str, 1, 1);
  end;
end;

{ ----------------------------------------------------------------------------- }

end.
