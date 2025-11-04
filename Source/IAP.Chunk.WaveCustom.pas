unit IAP.Chunk.WaveCustom;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  Classes, SysUtils, IAP.Types, IAP.Chunk.Classes, IAP.Chunk.WaveBasic;

type
  TWavSDA8Chunk = class(TDefinedChunk)
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create; override;
    class function GetClassChunkName: TChunkName; override;
    procedure LoadFromStream(Stream : TStream); override;
    procedure SaveToStream(Stream : TStream); override;
  end;

  TWavSDAChunk = class(TWavBinaryChunk)
  public
    class function GetClassChunkName: TChunkName; override;
  end;

  ////////////////////////////////////////////////////////////////////////////
  /////////////////////////////// AFsp Chunk /////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////

  TWavAFspChunk = class(TWavChunkText)
  public
    class function GetClassChunkName: TChunkName; override;

    property Text: AnsiString read FText write FText;
  end;

  ////////////////////////////////////////////////////////////////////////////
  //////////////////////////////// Link Chunk ////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////

  // -> see: http://www.ebu.ch/CMSimages/en/tec_doc_t3285_s4_tcm6-10484.pdf

  TBWFLinkChunk = class(TWavChunkText)
  public
    class function GetClassChunkName: TChunkName; override;

    property XMLData: AnsiString read FText write FText;
  end;

  ////////////////////////////////////////////////////////////////////////////
  //////////////////////////////// AXML Chunk ////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////

  // -> see: http://www.ebu.ch/CMSimages/en/tec_doc_t3285_s5_tcm6-10485.pdf

  TBwfAXMLChunk = class(TWavChunkText)
  public
    class function GetClassChunkName: TChunkName; override;

    property XMLData: AnsiString read FText write FText;
  end;

  ////////////////////////////////////////////////////////////////////////////
  ////////////////////////////// Display Chunk ///////////////////////////////
  ////////////////////////////////////////////////////////////////////////////

  TWavDisplayChunk = class(TWavDefinedChunk)
  private
    FData   : AnsiString;
  protected
    FTypeID : Cardinal;
    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create; override;
    class function GetClassChunkName: TChunkName; override;
    procedure LoadFromStream(Stream : TStream); override;
    procedure SaveToStream(Stream : TStream); override;

    property TypeID: Cardinal read FTypeID write FTypeID;
    property Data: AnsiString read FData write FData;
  end;

  ////////////////////////////////////////////////////////////////////////////
  /////////////////////////////// Peak Chunk /////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////

  TPeakRecord = record
    Version   : Cardinal; // version of the PEAK chunk
    TimeStamp : Cardinal; // secs since 1/1/1970
  end;

  TWavPeakChunk = class(TWavDefinedChunk)
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    Peak : TPeakRecord;
    constructor Create; override;
    class function GetClassChunkName: TChunkName; override;
    procedure LoadFromStream(Stream : TStream); override;
    procedure SaveToStream(Stream : TStream); override;
  end;

implementation

{ TWavSDA8Chunk }

constructor TWavSDA8Chunk.Create;
begin
 inherited;
 ChunkFlags := ChunkFlags + [cfPadSize, cfReversedByteOrder];
end;

class function TWavSDA8Chunk.GetClassChunkName: TChunkName;
begin
 Result := 'SDA8';
end;

procedure TWavSDA8Chunk.AssignTo(Dest: TPersistent);
begin
 inherited;
 // not yet defined
end;

procedure TWavSDA8Chunk.LoadFromStream(Stream: TStream);
begin
 inherited;
 with Stream
  do Position := Position + FChunkSize;
end;

procedure TWavSDA8Chunk.SaveToStream(Stream: TStream);
begin
 FChunkSize := 0;
 inherited;

 // check and eventually add zero pad
 CheckAddZeroPad(Stream);
end;


{ TWavSDAChunk }

class function TWavSDAChunk.GetClassChunkName: TChunkName;
begin
 Result := 'SDA ';
end;


{ TWavAFspChunk }

class function TWavAFspChunk.GetClassChunkName: TChunkName;
begin
 Result := 'afsp';
end;


{ TBWFLinkChunk }

class function TBWFLinkChunk.GetClassChunkName: TChunkName;
begin
 Result := 'link';
end;


{ TBWFAXMLChunk }

class function TBwfAXMLChunk.GetClassChunkName: TChunkName;
begin
 Result := 'axml';
end;


{ TWavDisplayChunk }

constructor TWavDisplayChunk.Create;
begin
 inherited;
 ChunkFlags := ChunkFlags + [cfPadSize];
end;

procedure TWavDisplayChunk.AssignTo(Dest: TPersistent);
begin
 inherited;
 if Dest is TWavDisplayChunk then
  begin
   TWavDisplayChunk(Dest).FTypeID := FTypeID;
   TWavDisplayChunk(Dest).FData := FData;
  end;
end;

class function TWavDisplayChunk.GetClassChunkName: TChunkName;
begin
 Result := 'DISP';
end;

procedure TWavDisplayChunk.LoadFromStream(Stream: TStream);
var
  ChunkEnd : Integer;
begin
 inherited;
 // calculate end of stream position
 ChunkEnd := Stream.Position + FChunkSize;
// assert(ChunkEnd <= Stream.Size);

 // read type ID
 Stream.Read(FTypeID, SizeOf(Cardinal));

 // set length of data and read data
 SetLength(FData, FChunkSize - SizeOf(Cardinal));
 Stream.Read(FData[1], Length(FData));

 assert(Stream.Position <= ChunkEnd);

 // goto end of this chunk
 Stream.Position := ChunkEnd;

 // eventually skip padded zeroes
 if cfPadSize in ChunkFlags
  then Stream.Position := Stream.Position + CalculateZeroPad;
end;

procedure TWavDisplayChunk.SaveToStream(Stream: TStream);
begin
 // calculate chunk size
 FChunkSize := SizeOf(Cardinal) + Length(FData);

 // write basic chunk information
 inherited;

 // write custom chunk information
 with Stream do
  begin
   Write(FTypeID, SizeOf(Cardinal));
   Write(FData[1], FChunkSize - SizeOf(Cardinal));
  end;

 // check and eventually add zero pad
 CheckAddZeroPad(Stream);
end;

{ TWavPeakChunk }

constructor TWavPeakChunk.Create;
begin
 inherited;
 ChunkFlags := ChunkFlags + [cfPadSize];
end;

procedure TWavPeakChunk.AssignTo(Dest: TPersistent);
begin
 inherited;
 if Dest is TWavPeakChunk
  then TWavPeakChunk(Dest).Peak := Peak; 
end;

class function TWavPeakChunk.GetClassChunkName: TChunkName;
begin
 Result := 'PEAK';
end;

procedure TWavPeakChunk.LoadFromStream(Stream: TStream);
var
  ChunkEnd : Integer;
begin
 inherited;
 ChunkEnd := Stream.Position + FChunkSize;
 Stream.Read(Peak, SizeOf(TPeakRecord));
 Stream.Position := ChunkEnd;
end;

procedure TWavPeakChunk.SaveToStream(Stream: TStream);
begin
 // calculate chunk size
 FChunkSize := SizeOf(TPeakRecord);

 // write basic chunk information
 inherited;

 // write custom chunk information
 Stream.Write(Peak, FChunkSize);

 // check and eventually add zero pad
 CheckAddZeroPad(Stream);
end;

initialization
  RegisterWaveChunks([TWavSDA8Chunk, TWavSDAChunk, TBWFLinkChunk,
    TBWFAXMLChunk, TWavDisplayChunk, TWavAFspChunk, TWavPeakChunk]);

end.
