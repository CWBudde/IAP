unit IAP.AudioFile.CRC;

interface

type
  TCRC16 = class
  private
    FCRC: Word;
    function GetCRC: Word;
  public
    constructor Create;
    procedure AddBits(BitString: Cardinal; Length: Cardinal);
    procedure Clear;

    property Checksum: Word read GetCRC;
  end;

implementation

const
  CPolynomial: Word = $8005;

{ TCRC16 }

constructor TCRC16.Create;
begin
  Clear;
end;

function TCRC16.GetCRC: Word;
begin
  Result := FCRC;
  Clear;
end;

// erase checksum for the next call of AddBits()
procedure TCRC16.Clear;
begin
  FCRC := $FFFF;
end;

// feed a bitstring to the crc calculation (0 < length <= 32)
procedure TCRC16.AddBits(BitString, Length: Cardinal);
var
  BitMask: Cardinal;
begin
  BitMask := 1 shl (Length - 1);
  repeat
    if ((FCRC and $8000 = 0) xor (BitString and BitMask = 0)) then
    begin
      FCRC := FCRC shl 1;
      FCRC := FCRC xor CPolynomial;
    end
    else
      FCRC := FCRC shl 1;
    BitMask := BitMask shr 1;
  until (BitMask = 0);
end;

end.
