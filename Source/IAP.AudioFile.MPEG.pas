unit IAP.AudioFile.MPEG;

interface

{$DEFINE SEEK_STOP}
{$DEFINE FastCalculation}

uses
  System.SysUtils, System.Classes, IAP.Types, IAP.AudioFile.Layer3;

type
  TSyncMode = (smInitialSync, imStrictSync);
  TMpegVersion = (mv2lsf, mv1);
  TSampleRates = (sr44k1, sr48k, sr32k, srUnknown);

const
  CFrequencies: array [TMpegVersion, TSampleRates] of Cardinal =
    ((22050, 24000, 16000, 1), (44100, 48000, 32000, 1));
  CmsPerFrameArray: array [0 .. 2, TSampleRates] of Single =
    ((8.707483, 8, 12, 0), (26.12245, 24, 36, 0), (26.12245, 24, 36, 0));
  CBitrates: array [TMpegVersion, 0 .. 2, 0 .. 15] of Cardinal =
    (((0, 32000, 48000, 56000, 64000, 80000, 96000, 112000, 128000, 144000,
    160000, 176000, 192000, 224000, 256000, 0), (0, 8000, 16000, 24000, 32000,
    40000, 48000, 56000, 64000, 80000, 96000, 112000, 128000, 144000, 160000,
    0), (0, 8000, 16000, 24000, 32000, 40000, 48000, 56000, 64000, 80000,
    96000, 112000, 128000, 144000, 160000, 0)), ((0, 32000, 64000, 96000,
    128000, 160000, 192000, 224000, 256000, 288000, 320000, 352000, 384000,
    416000, 448000, 0), (0, 32000, 48000, 56000, 64000, 80000, 96000, 112000,
    128000, 160000, 192000, 224000, 256000, 320000, 384000, 0), (0, 32000,
    40000, 48000, 56000, 64000, 80000, 96000, 112000, 128000, 160000, 192000,
    224000, 256000, 320000, 0)));

type
  PCardinalArray = ^TCardinalArray;
  TCardinalArray = array [0 .. 0] of Cardinal;

  TChannels = (chBoth, chLeft, chRight, chDownmix);
  TChannelMode = (cmStereo, cmJointStereo, cmDualChannel, cmSingleChannel);

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

  TBitReserve = class
  private
    FOffset: Cardinal;
    FTotalBits: Cardinal;
    FBufByteIdx: Cardinal;
    FBuffer: PCardinalArray;
    FBufBitIdx: Cardinal;
    FPutMask: PCardinalArray;
  public
    constructor Create;
    destructor Destroy; override;

    function GetBits(Bits: Cardinal): Cardinal;
    function Get1Bit: Cardinal;
    procedure WriteToBitstream(Value: Cardinal);

    procedure RewindBits(Bits: Cardinal);
    procedure RewindBytes(Bytes: Cardinal);

    property TotalBits: Cardinal read FTotalBits;
  end;

  PHuffBits = ^THuffBits;
  THuffBits = Cardinal;

  PHTArray = ^THTArray;
  THTArray = array [0 .. 1] of Byte;

  PPHTArray = ^TPHTArray;
  TPHTArray = array [0 .. 1] of THTArray;

  PHuffmanCodeTable = ^THuffmanCodeTable;

  THuffmanCodeTable = record
    TableName: array [0 .. 2] of AnsiChar;
    // string, containing table_description
    XLength: Cardinal; // max. x-index+
    YLength: Cardinal; // max. y-index+
    LinBits: Cardinal; // number of LinBits
    LinMax: Cardinal; // max number to be stored in LinBits
    Ref: Integer; // a positive value indicates a reference
    Table: PHuffBits; // pointer to array[XLength][YLength]
    HLength: PAnsiChar; // pointer to array[XLength][YLength]
    Val: PPHTArray; // decoder tree
    TreeLength: Cardinal; // length of decoder tree
  end;

  THeader = class;

  TMusicGenre = (mgBlues = 0, mgClassicRock = 1, mgCountry = 2, mgDance = 3,
    mgDisco = 4, mgFunk = 5, mgGrunge = 6, mgHipHop = 7, mgJazz = 8,
    mgMetal = 9, mgNewAge = 10, mgOldies = 11, mgOther = 12, mgPop, mgRnB,
    mgRap, mgReggae, mgRock, mgTechno, mgIndustrial, mgAlternative, mgSka,
    mgDeathMetal, mgPranks, mgSoundtrack, mgEuroTechno, mgAmbient, mgTripHop,
    mgVocal, mgJazzFunk, mgFusion, mgTrance, mgClassical, mgInstrumental,
    mgAcid, mgHouse, mgGame, mgSoundClip, mgGospel, mgNoise, mgAlternRock,
    mgBass, mgSoul, mgPunk, mgSpace, mgMeditative, mgInstrumentalPop,
    mgInstrumentalRock, mgEthnic, mgGothic, mgDarkwave, mgTechnoIndustrial,
    mgElectronic, mgPopFolk, mgEurodance, mgDream, mgSouthernRock, mgComedy,
    mgCult, mgGangsta, mgTop40, mgChristianRap, mgPopFunk, mgJungle,
    mgNativeAmerican, mgCabaret, mgNewWave, mgPsychedelic, mgRave, mgShowtunes,
    mgTrailer, mgLoFi, mgTribal, mgAcidPunk, mgAcidJazz, mgPolka, mgRetro,
    mgMusical, mgRockNRoll, mgHardRock, mgFolk, mgFolkRock, mgNationalFolk,
    mgSwing, mgFastFusion, mgBebob, mgLatin, mgRevival, mgCeltic, mgBluegrass,
    mgAvantgarde, mgGothicRock, mgProgressiveRock, mgPsychedelicRock,
    mgSymphonicRock, mgSlowRock, mgBigBand, mgChorus, mgEasyListening,
    mgAcoustic, mgHumour, mgSpeech, mgChanson, mgOpera, mgChamberMusic,
    mgSonata, mgSymphony, mgBootyBass, mgPrimus, mgPornGroove, mgSatire,
    mgSlowJam, mgClub, mgTango, mgSamba, mgFolklore, mgBallad, mgPowerBallad,
    mgRhythmicSoul, mgFreestyle, mgDuet, mgPunkRock, mgDrumSolo, mgAcapella,
    mgEuroHouse, mgDanceHall, mgGoa, mgDrumNBass, mgClubHouse, mgHardcore,
    mgTerror, mgIndie, mgBritPop, mgNegerpunk, mgPolskPunk, mgBeat,
    mgChristianGangs, mgHeavyMetal, mgBlackMetal, mgCrossover, mgContemporary,
    mgCristianRock, mgMerengue, mgSalsa, mgThrashMetal, mgAnime, mgJPop,
    mgSynthpop, mgUnknown); // 0 .. 93h

  // Class to extract bitstrings from files:
  TBitStream = class
  private
    FStream: TStream;
    FOwnedStream: Boolean;
    FBuffer: PCardinalArray; // array [0..CBufferIntSize - 1] of Cardinal;
    FFrameSize: Cardinal; // number of valid bytes in buffer
    FWordPointer: PCardinalArray;
    // position of next unsigned int for get_bits()
    FBitIndex: Cardinal;
    // number (0-31, from MSB to LSB) of next bit for get_bits()
    FSyncWord: Cardinal;
    FSingleChMode: Boolean;
    FCurrentFrameNumber: Integer;
    FLastFrameNumber: Integer;
    FNonSeekable: Boolean;
  protected
    // Set the word we want to sync the header to, in Big-Endian byte order
    procedure SetSyncWord(SyncWord: Cardinal);
  public
    constructor Create(FileName: TFileName); overload;
    constructor Create(Stream: TStream); overload;
    destructor Destroy; override;

    procedure Reset;

    // get next 32 bits from bitstream in an unsigned int,
    // returned value, false => end of stream
    function GetHeader(var HeaderString: Cardinal; SyncMode: TSyncMode): Boolean;

    // fill buffer with data from bitstream, returned value false => end of stream
    function ReadFrame(ByteSize: Cardinal): Boolean;

    // read bits (1 <= number_of_bits <= 16) from buffer into the lower bits
    // of an unsigned int. The LSB contains the latest read bit of the stream.
    function GetBits(NumberOfBits: Cardinal): Cardinal;

    // read bits (1 <= number_of_bits <= 16) from buffer into the lower bits
    // of a floating point. The LSB contains the latest read bit of the stream.
    function GetBitsFloat(NumberOfBits: Cardinal): Single;

    // Returns the size, in bytes, of the input file.
    function StreamSize: Cardinal;

    // Seeks to frames
    function Seek(Frame: Integer; FrameSize: Integer): Boolean;

    // Seeks frames for 44.1 or 22.05 kHz (padded) files
    function SeekPad(Frame: Integer; FrameSize: Integer; var Header: THeader;
      Offset: PCardinalArray): Boolean;

    property Stream: TStream read FStream;

    property CurrentFrame: Integer read FCurrentFrameNumber;
    property LastFrame: Integer read FLastFrameNumber;

    property SyncWord: Cardinal read FSyncWord write SetSyncWord;
  end;

  // Class for extraction information from a frame header:
  THeader = class
  private
    FLayer: Cardinal;
    FProtectionBit: Cardinal;
    FBitrateIndex: Cardinal;
    FPaddingBit: Cardinal;
    FModeExtension: Cardinal;
    FVersion: TMpegVersion;
    FMode: TChannelMode;
    FSampleFrequency: TSampleRates;
    FNumberOfSubbands: Cardinal;
    FIntensityStereoBound: Cardinal;
    FCopyright: Boolean;
    FOriginal: Boolean;
    FInitialSync: Boolean;
    FCRC: TCRC16;
    FOffset: PCardinalArray;
    FChecksum: Cardinal;
    FFrameSize: Cardinal;
    FNumSlots: Cardinal;
    function GetFrequency: Cardinal;
    function GetChecksums: Boolean;
    function GetChecksumOK: Boolean;
    function GetPadding: Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    function ReadHeader(Stream: TBitStream; var CRC: TCRC16): Boolean;

    // read a 32-bit header from the bitstream
    function Bitrate: Cardinal;
    function CalculateFrameSize: Cardinal;

    // seek stuff
    function StreamSeek(Stream: TBitStream; SeekPos: Cardinal): Boolean;
    function MaxNumberOfFrames(Stream: TBitStream): Integer;
    function MinNumberOfFrames(Stream: TBitStream): Integer;

    function MSPerFrame: Single; // milliseconds per frame, for time display
    function TotalMS(Stream: TBitStream): Single;

    property Version: TMpegVersion read FVersion;
    property Layer: Cardinal read FLayer;
    property BitrateIndex: Cardinal read FBitrateIndex;
    property SampleFrequency: TSampleRates read FSampleFrequency;
    property Frequency: Cardinal read GetFrequency;
    property Mode: TChannelMode read FMode;
    property Checksums: Boolean read GetChecksums;
    property Copyright: Boolean read FCopyright;
    property Original: Boolean read FOriginal;
    property ChecksumOK: Boolean read GetChecksumOK;

    // compares computed checksum with stream checksum
    property Padding: Boolean read GetPadding;
    property Slots: Cardinal read FNumSlots;
    property ModeExtension: Cardinal read FModeExtension;

    // returns the number of subbands in the current frame
    property NumberOfSubbands: Cardinal read FNumberOfSubbands;

    // (Layer II joint cmStereo only)
    // returns the number of subbands which are in cmStereo mode,
    // subbands above that limit are in intensity cmStereo mode
    property IntensityStereoBound: Cardinal read FIntensityStereoBound;
  end;

  TNewPCMSample = procedure(Sender: TObject; Sample: Single) of object;

  // A class for the synthesis filter bank:
  // This class does a fast downsampling from 32, 44.1 or 48 kHz to 8 kHz, if ULAW is defined.
  // Frequencies above 4 kHz are removed by ignoring higher subbands.
  TSynthesisFilter = class
  private
    FVector: array [0 .. 1, 0 .. 511] of Single;
    FActualVector: PIAP512SingleArray; // FVector[0] or FVector[1]
    FActualWritePos: Cardinal; // 0-15
    FSample: array [0 .. 31] of Single; // 32 new subband samples
    FOnNewPCMSample: TNewPCMSample;
    procedure ComputeNewVector;
    procedure ComputePCMSample;
  public
    constructor Create;
    procedure InputSample(Sample: Single; SubBandNumber: Cardinal);
    procedure CalculatePCMSamples; // calculate 32 PCM samples
    procedure Reset; // reset the synthesis filter

    property OnNewPCMSample: TNewPCMSample read FOnNewPCMSample
      write FOnNewPCMSample;
  end;

  TSubBand = class
  public
    procedure ReadAllocation(Stream: TBitStream; Header: THeader; CRC: TCRC16);
      virtual; abstract;
    procedure ReadScaleFactor(Stream: TBitStream; Header: THeader);
      virtual; abstract;
    function ReadSampleData(Stream: TBitStream): Boolean; virtual; abstract;
    function PutNextSample(Channels: TChannels;
      Filter1, Filter2: TSynthesisFilter): Boolean; virtual; abstract;
  end;

  // class for layer I subbands in single channel mode:
  TSubBandLayer1 = class(TSubBand)
  protected
    FSubBandNumber: Cardinal;
    FSampleNumber: Cardinal;
    FAllocation: Cardinal;
    FScaleFactor: Single;
    FSampleLength: Cardinal;
    FSample: Single;
    FFactor, FOffset: Single;
  public
    constructor Create(SubBandNumber: Cardinal); virtual;
    procedure ReadAllocation(Stream: TBitStream; Header: THeader;
      CRC: TCRC16); override;
    procedure ReadScaleFactor(Stream: TBitStream; Header: THeader); override;
    function ReadSampleData(Stream: TBitStream): Boolean; override;
    function PutNextSample(Channels: TChannels;
      Filter1, Filter2: TSynthesisFilter): Boolean; override;
  end;

  // class for layer I subbands in joint cmStereo mode:
  TSubBandLayer1IntensityStereo = class(TSubBandLayer1)
  protected
    FChannel2ScaleFactor: Single;
  public
    procedure ReadScaleFactor(Stream: TBitStream; Header: THeader); override;
    function PutNextSample(Channels: TChannels;
      Filter1, Filter2: TSynthesisFilter): Boolean; override;
  end;

  // class for layer I subbands in cmStereo mode:
  TSubBandLayer1Stereo = class(TSubBandLayer1)
  protected
    FChannel2Allocation: Cardinal;
    FChannel2ScaleFactor: Single;
    FChannel2SampleLength: Cardinal;
    FChannel2Sample: Single;
    FChannel2Factor: Single;
    FChannel2Offset: Single;
  public
    procedure ReadAllocation(Stream: TBitStream; Header: THeader;
      CRC: TCRC16); override;
    procedure ReadScaleFactor(Stream: TBitStream; Header: THeader); override;
    function ReadSampleData(Stream: TBitStream): Boolean; override;
    function PutNextSample(Channels: TChannels;
      Filter1, Filter2: TSynthesisFilter): Boolean; override;
  end;

  // class for layer II subbands in single channel mode:
  TSubBandLayer2 = class(TSubBand)
  protected
    FSubBandNumber: Cardinal;
    FAllocation: Cardinal;
    FSCFSI: Cardinal;
    FScaleFactor: array [0 .. 2] of Single;
    FCodeLength: Cardinal;
    FGroupingTable: PIAP1024SingleArray;
    FFactor: Single;
    FGroupNumber: Cardinal;
    FSampleNumber: Cardinal;
    FSamples: array [0 .. 2] of Single;
    FC, FD: Single;
    function GetAllocationLength(Header: THeader): Cardinal; virtual;
    procedure PrepareSampleReading(Header: THeader; Allocation: Cardinal;
      var GroupingTable: PIAP1024SingleArray; var Factor: Single;
      var CodeLength: Cardinal; var C, D: Single); virtual;
  public
    constructor Create(SubBandNumber: Cardinal); virtual;
    procedure ReadAllocation(Stream: TBitStream; Header: THeader;
      CRC: TCRC16); override;
    procedure ReadScaleFactorSelection(Stream: TBitStream;
      CRC: TCRC16); virtual;
    procedure ReadScaleFactor(Stream: TBitStream; Header: THeader); override;
    function ReadSampleData(Stream: TBitStream): Boolean; override;
    function PutNextSample(Channels: TChannels;
      Filter1, Filter2: TSynthesisFilter): Boolean; override;
  end;

  // class for layer II subbands in joint cmStereo mode:
  TSubbandLayer2IntensityStereo = class(TSubBandLayer2)
  protected
    FChannel2SCFSI: Cardinal;
    FChannel2ScaleFactor: array [0 .. 2] of Single;
  public
    procedure ReadScaleFactorSelection(Stream: TBitStream;
      CRC: TCRC16); override;
    procedure ReadScaleFactor(Stream: TBitStream; Header: THeader); override;
    function PutNextSample(Channels: TChannels;
      Filter1, Filter2: TSynthesisFilter): Boolean; override;
  end;

  // class for layer II subbands in cmStereo mode:
  TSubbandLayer2Stereo = class(TSubBandLayer2)
  protected
    FChannel2Allocation: Cardinal;
    FChannel2SCFSI: Cardinal;
    FChannel2ScaleFactor: array [0 .. 2] of Single;
    FChannel2Grouping: Boolean;
    FChannel2CodeLength: Cardinal;
    FChannel2GroupingTable: PIAP1024SingleArray;
    FChannel2Factor: Single;
    FChannel2Samples: array [0 .. 2] of Single;
    FChannel2C, FChannel2D: Single;
  public
    procedure ReadAllocation(Stream: TBitStream; Header: THeader;
      CRC: TCRC16); override;
    procedure ReadScaleFactorSelection(Stream: TBitStream;
      CRC: TCRC16); override;
    procedure ReadScaleFactor(Stream: TBitStream; Header: THeader); override;
    function ReadSampleData(Stream: TBitStream): Boolean; override;
    function PutNextSample(Channels: TChannels;
      Filter1, Filter2: TSynthesisFilter): Boolean; override;
  end;

const
  CSsLimit = 18;
  CSbLimit = 32;

type
  PSArray = ^TSArray;
  TSArray = array [0 .. CSbLimit - 1, 0 .. CSsLimit - 1] of Single;

  TStereoBuffer = class
  private
    FOutput: array [0 .. 1] of PIAPSingleFixedArray;
    FBufferPos: array [0 .. 1] of Integer;
    FBufferSize: Integer;
    procedure SetBufferSize(const Value: Integer);
    procedure BufferSizeChanged;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Append(Channel: Cardinal; Value: Single);
    procedure Reset;
    procedure Clear;

    property BufferSize: Integer read FBufferSize write SetBufferSize;
    property OutputLeft: PIAPSingleFixedArray read FOutput[0];
    property OutputRight: PIAPSingleFixedArray read FOutput[1];
  end;

  TLayer3Decoder = class
  private
    FRO: array [0 .. 1] of TSArray;
    FLR: array [0 .. 1] of TSArray;
    FIs1D: array [0 .. (CSbLimit * CSsLimit) - 1] of Integer;
    FOut1D: array [0 .. (CSbLimit * CSsLimit) - 1] of Single;
    FPrevBlock: array [0 .. 1, 0 .. (CSbLimit * CSsLimit) - 1] of Single;
    FK: array [0 .. 1, 0 .. (CSbLimit * CSsLimit) - 1] of Single;
    FNonZero: array [0 .. 1] of Integer;
    FBuffer: TStereoBuffer;
    FBitStream: TBitStream;
    FHeader: THeader;
    FFilter: array [0 .. 1] of TSynthesisFilter;
    FWhichChannels: TChannels;
    FBitReserve: TBitReserve;
    FSideInfo: PIIISideInfo;
    FScaleFac: TIIIScaleFactor;
    FMaxGranule: Cardinal;
    FFrameStart: Integer;
    FPart2Start: Cardinal;
    FChannels: Cardinal;
    FFirstChannel: Cardinal;
    FLastChannel: Cardinal;
    FSFreq: Cardinal;
    function GetSideInfo: Boolean;
    procedure GetScaleFactors(Channel, Granule: Cardinal);
    procedure GetLSFScaleData(Channel, Granule: Cardinal);
    procedure GetLSFScaleFactors(Channel, Granule: Cardinal);
    procedure HuffmanDecode(Channel, Granule: Cardinal);
    procedure IStereoKValues(IsPos, IOType, i: Cardinal);
    procedure DequantizeSample(var xr: TSArray; Channel, Granule: Cardinal);
    procedure Reorder(xr: PSArray; Channel, Granule: Cardinal);
  protected
    procedure Stereo(Granule: Cardinal); virtual;
    procedure Antialias(Channel, Granule: Cardinal); virtual;
    procedure Hybrid(Channel, Granule: Cardinal); virtual;
    procedure DoDownmix; virtual;
  public
    constructor Create(Stream: TBitStream; Header: THeader;
      FilterA, FilterB: TSynthesisFilter; Buffer: TStereoBuffer;
      Which_Ch: TChannels);
    destructor Destroy; override;

    // Notify decoder that a seek is being made
    procedure SeekNotify;

    // Decode one frame, filling the buffer with the output samples
    procedure Decode;
  end;

  TId3Tag = packed record
    Magic: array [1 .. 3] of AnsiChar;
    Title: array [1 .. 30] of AnsiChar;
    Artist: array [1 .. 30] of AnsiChar;
    Album: array [1 .. 30] of AnsiChar;
    Year: array [1 .. 4] of AnsiChar;
    Comment: array [1 .. 30] of AnsiChar;
    Genre: Byte;
  end;

  TCustomMpegAudio = class(TPersistent)
  private
    FBitStream: TBitStream;
    FMPEGHeader: THeader;
    FWhichC: TChannels;
    FFilter: array [0 .. 1] of TSynthesisFilter;
    FCRC: TCRC16;
    FBuffer: TStereoBuffer;
    FLayer: Cardinal;
    FLayer3: TLayer3Decoder;
    FBufferPos: Integer;
    FId3Tag: TId3Tag;
    FID3v2TagEnd: Cardinal;
    FTotalLength: Single;
    FSampleFrames: Integer;
    FCurrentPos: Integer;
    FScan: Boolean;
    FOnFrameChanged: TNotifyEvent;
    FOnEndOfFile: TNotifyEvent;
    function GetMode: TChannelMode;
    function GetChannels: TChannels;
    function GetVersion: TMpegVersion;
    function GetLayer: Integer;
    function GetSampleRate: Integer;
    function GetBitrate: Integer;
    function GetAlbum: string;
    function GetArtist: string;
    function GetComment: string;
    function GetGenre: TMusicGenre;
    function GetTitle: string;
    function GetTrackNumber: Byte;
    function GetYear: string;
    procedure DoDecode;
    procedure ScanStream;
    procedure NewPCMSample(Sender: TObject; Sample: Single);
    function GetEstimatedLength: Integer;
    function GetTotalLength: Single;
  protected
    constructor Create(Scan: Boolean = True); overload; virtual;

    procedure ReadAlbumTitle(ChunkSize: Integer); virtual;
    procedure ReadBand(ChunkSize: Integer); virtual;
    procedure ReadContentType(ChunkSize: Integer); virtual;
    procedure ReadPrivate(ChunkSize: Integer); virtual;
    procedure ReadLanguage(ChunkSize: Integer); virtual;
    procedure ReadMainArtist(ChunkSize: Integer); virtual;
    procedure ReadPublisher(ChunkSize: Integer); virtual;
    procedure ReadTrackNumber(ChunkSize: Integer); virtual;
    procedure ReadTitle(ChunkSize: Integer); virtual;
    procedure ReadYear(ChunkSize: Integer); virtual;
    procedure ParseID3v2Tag; virtual;

    property Id3Tag: TId3Tag read FId3Tag;
    property Id3Title: string read GetTitle;
    property Id3Artist: string read GetArtist;
    property Id3Album: string read GetAlbum;
    property Id3Year: string read GetYear;
    property Id3Comment: string read GetComment;
    property Id3TrackNumber: Byte read GetTrackNumber;
    property Id3Genre: TMusicGenre read GetGenre;

    property Mode: TChannelMode read GetMode;
    property Channels: TChannels read GetChannels;
    property Version: TMpegVersion read GetVersion;
    property Layer: Integer read GetLayer;
    property Bitrate: Integer read GetBitrate;
    property SampleRate: Integer read GetSampleRate;
    property SampleFrames: Integer read FSampleFrames;
    property CurrentSamplePosition: Integer read FCurrentPos;
    property EstimatedLength: Integer read GetEstimatedLength;
    property TotalLength: Single read GetTotalLength;

    property OnEndOfFile: TNotifyEvent read FOnEndOfFile write FOnEndOfFile;
    property OnFrameChanged: TNotifyEvent read FOnFrameChanged
      write FOnFrameChanged;
  public
    constructor Create(FileName: TFileName; Scan: Boolean = True);
      overload; virtual;
    constructor Create(Stream: TStream; Scan: Boolean = True);
      overload; virtual;
    destructor Destroy; override;

    procedure Reset;
    function ReadBuffer(chMono: PIAPSingleFixedArray;
      Size: Integer): Integer; overload;
    function ReadBuffer(chLeft, chRight: PIAPSingleFixedArray;
      Size: Integer): Integer; overload;
  end;

  TMpegAudio = class(TCustomMpegAudio)
  public
    property Id3Title;
    property Id3Artist;
    property Id3Album;
    property Id3Year;
    property Id3Comment;
    property Id3TrackNumber;
    property Id3Genre;

    property EstimatedLength;
    property TotalLength;
    property Mode;
    property Channels;
    property Version;
    property Layer;
    property Bitrate;
    property SampleRate;

    property OnFrameChanged;
    property OnEndOfFile;
  end;

function HuffmanDecoder(HuffmanCodeTable: PHuffmanCodeTable;
  var x, y, v, w: Integer; BitReverse: TBitReserve): Integer;
function SwapInt32(Value: Cardinal): Cardinal; inline;

implementation

uses
  Math, IAP.Math.Complex;

const
  CHuffmanCodeTableSize = 34;

  CMaxOff = 250;
  CDMask: THuffBits = THuffBits(1 shl ((SizeOf(THuffBits) * 8) - 1));

  CValTab0: array [0 .. 0] of THTArray = ((0, 0)); // dummy

  CValTab1: array [0 .. 6] of THTArray = ((2, 1), (0, 0), (2, 1), (0, 16),
    (2, 1), (0, 1), (0, 17));

  CValTab2: array [0 .. 16] of THTArray = ((2, 1), (0, 0), (4, 1), (2, 1),
    (0, 16), (0, 1), (2, 1), (0, 17), (4, 1), (2, 1), (0, 32), (0, 33), (2, 1),
    (0, 18), (2, 1), (0, 2), (0, 34));

  CValTab3: array [0 .. 16] of THTArray = ((4, 1), (2, 1), (0, 0), (0, 1),
    (2, 1), (0, 17), (2, 1), (0, 16), (4, 1), (2, 1), (0, 32), (0, 33), (2, 1),
    (0, 18), (2, 1), (0, 2), (0, 34));

  CValTab4: array [0 .. 0] of THTArray = ((0, 0)); // dummy

  CValTab5: array [0 .. 30] of THTArray = ((2, 1), (0, 0), (4, 1), (2, 1),
    (0, 16), (0, 1), (2, 1), (0, 17), (8, 1), (4, 1), (2, 1), (0, 32), (0, 2),
    (2, 1), (0, 33), (0, 18), (8, 1), (4, 1), (2, 1), (0, 34), (0, 48), (2, 1),
    (0, 3), (0, 19), (2, 1), (0, 49), (2, 1), (0, 50), (2, 1), (0, 35),
    (0, 51));

  CValTab6: array [0 .. 30] of THTArray = ((6, 1), (4, 1), (2, 1), (0, 0),
    (0, 16), (0, 17), (6, 1), (2, 1), (0, 1), (2, 1), (0, 32), (0, 33), (6, 1),
    (2, 1), (0, 18), (2, 1), (0, 2), (0, 34), (4, 1), (2, 1), (0, 49), (0, 19),
    (4, 1), (2, 1), (0, 48), (0, 50), (2, 1), (0, 35), (2, 1), (0, 3), (0, 51));

  CValTab7: array [0 .. 70] of THTArray = ((2, 1), (0, 0), (4, 1), (2, 1),
    (0, 16), (0, 1), (8, 1), (2, 1), (0, 17), (4, 1), (2, 1), (0, 32), (0, 2),
    (0, 33), (18, 1), (6, 1), (2, 1), (0, 18), (2, 1), (0, 34), (0, 48), (4, 1),
    (2, 1), (0, 49), (0, 19), (4, 1), (2, 1), (0, 3), (0, 50), (2, 1), (0, 35),
    (0, 4), (10, 1), (4, 1), (2, 1), (0, 64), (0, 65), (2, 1), (0, 20), (2, 1),
    (0, 66), (0, 36), (12, 1), (6, 1), (4, 1), (2, 1), (0, 51), (0, 67),
    (0, 80), (4, 1), (2, 1), (0, 52), (0, 5), (0, 81), (6, 1), (2, 1), (0, 21),
    (2, 1), (0, 82), (0, 37), (4, 1), (2, 1), (0, 68), (0, 53), (4, 1), (2, 1),
    (0, 83), (0, 84), (2, 1), (0, 69), (0, 85));

  CValTab8: array [0 .. 70] of THTArray = ((6, 1), (2, 1), (0, 0), (2, 1),
    (0, 16), (0, 1), (2, 1), (0, 17), (4, 1), (2, 1), (0, 33), (0, 18), (14, 1),
    (4, 1), (2, 1), (0, 32), (0, 2), (2, 1), (0, 34), (4, 1), (2, 1), (0, 48),
    (0, 3), (2, 1), (0, 49), (0, 19), (14, 1), (8, 1), (4, 1), (2, 1), (0, 50),
    (0, 35), (2, 1), (0, 64), (0, 4), (2, 1), (0, 65), (2, 1), (0, 20), (0, 66),
    (12, 1), (6, 1), (2, 1), (0, 36), (2, 1), (0, 51), (0, 80), (4, 1), (2, 1),
    (0, 67), (0, 52), (0, 81), (6, 1), (2, 1), (0, 21), (2, 1), (0, 5), (0, 82),
    (6, 1), (2, 1), (0, 37), (2, 1), (0, 68), (0, 53), (2, 1), (0, 83), (2, 1),
    (0, 69), (2, 1), (0, 84), (0, 85));

  CValTab9: array [0 .. 70] of THTArray = ((8, 1), (4, 1), (2, 1), (0, 0),
    (0, 16), (2, 1), (0, 1), (0, 17), (10, 1), (4, 1), (2, 1), (0, 32), (0, 33),
    (2, 1), (0, 18), (2, 1), (0, 2), (0, 34), (12, 1), (6, 1), (4, 1), (2, 1),
    (0, 48), (0, 3), (0, 49), (2, 1), (0, 19), (2, 1), (0, 50), (0, 35),
    (12, 1), (4, 1), (2, 1), (0, 65), (0, 20), (4, 1), (2, 1), (0, 64), (0, 51),
    (2, 1), (0, 66), (0, 36), (10, 1), (6, 1), (4, 1), (2, 1), (0, 4), (0, 80),
    (0, 67), (2, 1), (0, 52), (0, 81), (8, 1), (4, 1), (2, 1), (0, 21), (0, 82),
    (2, 1), (0, 37), (0, 68), (6, 1), (4, 1), (2, 1), (0, 5), (0, 84), (0, 83),
    (2, 1), (0, 53), (2, 1), (0, 69), (0, 85));

  CValTab10: array [0 .. 126] of THTArray = ((2, 1), (0, 0), (4, 1), (2, 1),
    (0, 16), (0, 1), (10, 1), (2, 1), (0, 17), (4, 1), (2, 1), (0, 32), (0, 2),
    (2, 1), (0, 33), (0, 18), (28, 1), (8, 1), (4, 1), (2, 1), (0, 34), (0, 48),
    (2, 1), (0, 49), (0, 19), (8, 1), (4, 1), (2, 1), (0, 3), (0, 50), (2, 1),
    (0, 35), (0, 64), (4, 1), (2, 1), (0, 65), (0, 20), (4, 1), (2, 1), (0, 4),
    (0, 51), (2, 1), (0, 66), (0, 36), (28, 1), (10, 1), (6, 1), (4, 1), (2, 1),
    (0, 80), (0, 5), (0, 96), (2, 1), (0, 97), (0, 22), (12, 1), (6, 1), (4, 1),
    (2, 1), (0, 67), (0, 52), (0, 81), (2, 1), (0, 21), (2, 1), (0, 82),
    (0, 37), (4, 1), (2, 1), (0, 38), (0, 54), (0, 113), (20, 1), (8, 1),
    (2, 1), (0, 23), (4, 1), (2, 1), (0, 68), (0, 83), (0, 6), (6, 1), (4, 1),
    (2, 1), (0, 53), (0, 69), (0, 98), (2, 1), (0, 112), (2, 1), (0, 7),
    (0, 100), (14, 1), (4, 1), (2, 1), (0, 114), (0, 39), (6, 1), (2, 1),
    (0, 99), (2, 1), (0, 84), (0, 85), (2, 1), (0, 70), (0, 115), (8, 1),
    (4, 1), (2, 1), (0, 55), (0, 101), (2, 1), (0, 86), (0, 116), (6, 1),
    (2, 1), (0, 71), (2, 1), (0, 102), (0, 117), (4, 1), (2, 1), (0, 87),
    (0, 118), (2, 1), (0, 103), (0, 119));

  CValTab11: array [0 .. 126] of THTArray = ((6, 1), (2, 1), (0, 0), (2, 1),
    (0, 16), (0, 1), (8, 1), (2, 1), (0, 17), (4, 1), (2, 1), (0, 32), (0, 2),
    (0, 18), (24, 1), (8, 1), (2, 1), (0, 33), (2, 1), (0, 34), (2, 1), (0, 48),
    (0, 3), (4, 1), (2, 1), (0, 49), (0, 19), (4, 1), (2, 1), (0, 50), (0, 35),
    (4, 1), (2, 1), (0, 64), (0, 4), (2, 1), (0, 65), (0, 20), (30, 1), (16, 1),
    (10, 1), (4, 1), (2, 1), (0, 66), (0, 36), (4, 1), (2, 1), (0, 51), (0, 67),
    (0, 80), (4, 1), (2, 1), (0, 52), (0, 81), (0, 97), (6, 1), (2, 1), (0, 22),
    (2, 1), (0, 6), (0, 38), (2, 1), (0, 98), (2, 1), (0, 21), (2, 1), (0, 5),
    (0, 82), (16, 1), (10, 1), (6, 1), (4, 1), (2, 1), (0, 37), (0, 68),
    (0, 96), (2, 1), (0, 99), (0, 54), (4, 1), (2, 1), (0, 112), (0, 23),
    (0, 113), (16, 1), (6, 1), (4, 1), (2, 1), (0, 7), (0, 100), (0, 114),
    (2, 1), (0, 39), (4, 1), (2, 1), (0, 83), (0, 53), (2, 1), (0, 84), (0, 69),
    (10, 1), (4, 1), (2, 1), (0, 70), (0, 115), (2, 1), (0, 55), (2, 1),
    (0, 101), (0, 86), (10, 1), (6, 1), (4, 1), (2, 1), (0, 85), (0, 87),
    (0, 116), (2, 1), (0, 71), (0, 102), (4, 1), (2, 1), (0, 117), (0, 118),
    (2, 1), (0, 103), (0, 119));

  CValTab12: array [0 .. 126] of THTArray = ((12, 1), (4, 1), (2, 1), (0, 16),
    (0, 1), (2, 1), (0, 17), (2, 1), (0, 0), (2, 1), (0, 32), (0, 2), (16, 1),
    (4, 1), (2, 1), (0, 33), (0, 18), (4, 1), (2, 1), (0, 34), (0, 49), (2, 1),
    (0, 19), (2, 1), (0, 48), (2, 1), (0, 3), (0, 64), (26, 1), (8, 1), (4, 1),
    (2, 1), (0, 50), (0, 35), (2, 1), (0, 65), (0, 51), (10, 1), (4, 1), (2, 1),
    (0, 20), (0, 66), (2, 1), (0, 36), (2, 1), (0, 4), (0, 80), (4, 1), (2, 1),
    (0, 67), (0, 52), (2, 1), (0, 81), (0, 21), (28, 1), (14, 1), (8, 1),
    (4, 1), (2, 1), (0, 82), (0, 37), (2, 1), (0, 83), (0, 53), (4, 1), (2, 1),
    (0, 96), (0, 22), (0, 97), (4, 1), (2, 1), (0, 98), (0, 38), (6, 1), (4, 1),
    (2, 1), (0, 5), (0, 6), (0, 68), (2, 1), (0, 84), (0, 69), (18, 1), (10, 1),
    (4, 1), (2, 1), (0, 99), (0, 54), (4, 1), (2, 1), (0, 112), (0, 7),
    (0, 113), (4, 1), (2, 1), (0, 23), (0, 100), (2, 1), (0, 70), (0, 114),
    (10, 1), (6, 1), (2, 1), (0, 39), (2, 1), (0, 85), (0, 115), (2, 1),
    (0, 55), (0, 86), (8, 1), (4, 1), (2, 1), (0, 101), (0, 116), (2, 1),
    (0, 71), (0, 102), (4, 1), (2, 1), (0, 117), (0, 87), (2, 1), (0, 118),
    (2, 1), (0, 103), (0, 119));

  CValTab13: array [0 .. 510] of THTArray = ((2, 1), (0, 0), (6, 1), (2, 1),
    (0, 16), (2, 1), (0, 1), (0, 17), (28, 1), (8, 1), (4, 1), (2, 1), (0, 32),
    (0, 2), (2, 1), (0, 33), (0, 18), (8, 1), (4, 1), (2, 1), (0, 34), (0, 48),
    (2, 1), (0, 3), (0, 49), (6, 1), (2, 1), (0, 19), (2, 1), (0, 50), (0, 35),
    (4, 1), (2, 1), (0, 64), (0, 4), (0, 65), (70, 1), (28, 1), (14, 1), (6, 1),
    (2, 1), (0, 20), (2, 1), (0, 51), (0, 66), (4, 1), (2, 1), (0, 36), (0, 80),
    (2, 1), (0, 67), (0, 52), (4, 1), (2, 1), (0, 81), (0, 21), (4, 1), (2, 1),
    (0, 5), (0, 82), (2, 1), (0, 37), (2, 1), (0, 68), (0, 83), (14, 1), (8, 1),
    (4, 1), (2, 1), (0, 96), (0, 6), (2, 1), (0, 97), (0, 22), (4, 1), (2, 1),
    (0, 128), (0, 8), (0, 129), (16, 1), (8, 1), (4, 1), (2, 1), (0, 53),
    (0, 98), (2, 1), (0, 38), (0, 84), (4, 1), (2, 1), (0, 69), (0, 99), (2, 1),
    (0, 54), (0, 112), (6, 1), (4, 1), (2, 1), (0, 7), (0, 85), (0, 113),
    (2, 1), (0, 23), (2, 1), (0, 39), (0, 55), (72, 1), (24, 1), (12, 1),
    (4, 1), (2, 1), (0, 24), (0, 130), (2, 1), (0, 40), (4, 1), (2, 1),
    (0, 100), (0, 70), (0, 114), (8, 1), (4, 1), (2, 1), (0, 132), (0, 72),
    (2, 1), (0, 144), (0, 9), (2, 1), (0, 145), (0, 25), (24, 1), (14, 1),
    (8, 1), (4, 1), (2, 1), (0, 115), (0, 101), (2, 1), (0, 86), (0, 116),
    (4, 1), (2, 1), (0, 71), (0, 102), (0, 131), (6, 1), (2, 1), (0, 56),
    (2, 1), (0, 117), (0, 87), (2, 1), (0, 146), (0, 41), (14, 1), (8, 1),
    (4, 1), (2, 1), (0, 103), (0, 133), (2, 1), (0, 88), (0, 57), (2, 1),
    (0, 147), (2, 1), (0, 73), (0, 134), (6, 1), (2, 1), (0, 160), (2, 1),
    (0, 104), (0, 10), (2, 1), (0, 161), (0, 26), (68, 1), (24, 1), (12, 1),
    (4, 1), (2, 1), (0, 162), (0, 42), (4, 1), (2, 1), (0, 149), (0, 89),
    (2, 1), (0, 163), (0, 58), (8, 1), (4, 1), (2, 1), (0, 74), (0, 150),
    (2, 1), (0, 176), (0, 11), (2, 1), (0, 177), (0, 27), (20, 1), (8, 1),
    (2, 1), (0, 178), (4, 1), (2, 1), (0, 118), (0, 119), (0, 148), (6, 1),
    (4, 1), (2, 1), (0, 135), (0, 120), (0, 164), (4, 1), (2, 1), (0, 105),
    (0, 165), (0, 43), (12, 1), (6, 1), (4, 1), (2, 1), (0, 90), (0, 136),
    (0, 179), (2, 1), (0, 59), (2, 1), (0, 121), (0, 166), (6, 1), (4, 1),
    (2, 1), (0, 106), (0, 180), (0, 192), (4, 1), (2, 1), (0, 12), (0, 152),
    (0, 193), (60, 1), (22, 1), (10, 1), (6, 1), (2, 1), (0, 28), (2, 1),
    (0, 137), (0, 181), (2, 1), (0, 91), (0, 194), (4, 1), (2, 1), (0, 44),
    (0, 60), (4, 1), (2, 1), (0, 182), (0, 107), (2, 1), (0, 196), (0, 76),
    (16, 1), (8, 1), (4, 1), (2, 1), (0, 168), (0, 138), (2, 1), (0, 208),
    (0, 13), (2, 1), (0, 209), (2, 1), (0, 75), (2, 1), (0, 151), (0, 167),
    (12, 1), (6, 1), (2, 1), (0, 195), (2, 1), (0, 122), (0, 153), (4, 1),
    (2, 1), (0, 197), (0, 92), (0, 183), (4, 1), (2, 1), (0, 29), (0, 210),
    (2, 1), (0, 45), (2, 1), (0, 123), (0, 211), (52, 1), (28, 1), (12, 1),
    (4, 1), (2, 1), (0, 61), (0, 198), (4, 1), (2, 1), (0, 108), (0, 169),
    (2, 1), (0, 154), (0, 212), (8, 1), (4, 1), (2, 1), (0, 184), (0, 139),
    (2, 1), (0, 77), (0, 199), (4, 1), (2, 1), (0, 124), (0, 213), (2, 1),
    (0, 93), (0, 224), (10, 1), (4, 1), (2, 1), (0, 225), (0, 30), (4, 1),
    (2, 1), (0, 14), (0, 46), (0, 226), (8, 1), (4, 1), (2, 1), (0, 227),
    (0, 109), (2, 1), (0, 140), (0, 228), (4, 1), (2, 1), (0, 229), (0, 186),
    (0, 240), (38, 1), (16, 1), (4, 1), (2, 1), (0, 241), (0, 31), (6, 1),
    (4, 1), (2, 1), (0, 170), (0, 155), (0, 185), (2, 1), (0, 62), (2, 1),
    (0, 214), (0, 200), (12, 1), (6, 1), (2, 1), (0, 78), (2, 1), (0, 215),
    (0, 125), (2, 1), (0, 171), (2, 1), (0, 94), (0, 201), (6, 1), (2, 1),
    (0, 15), (2, 1), (0, 156), (0, 110), (2, 1), (0, 242), (0, 47), (32, 1),
    (16, 1), (6, 1), (4, 1), (2, 1), (0, 216), (0, 141), (0, 63), (6, 1),
    (2, 1), (0, 243), (2, 1), (0, 230), (0, 202), (2, 1), (0, 244), (0, 79),
    (8, 1), (4, 1), (2, 1), (0, 187), (0, 172), (2, 1), (0, 231), (0, 245),
    (4, 1), (2, 1), (0, 217), (0, 157), (2, 1), (0, 95), (0, 232), (30, 1),
    (12, 1), (6, 1), (2, 1), (0, 111), (2, 1), (0, 246), (0, 203), (4, 1),
    (2, 1), (0, 188), (0, 173), (0, 218), (8, 1), (2, 1), (0, 247), (4, 1),
    (2, 1), (0, 126), (0, 127), (0, 142), (6, 1), (4, 1), (2, 1), (0, 158),
    (0, 174), (0, 204), (2, 1), (0, 248), (0, 143), (18, 1), (8, 1), (4, 1),
    (2, 1), (0, 219), (0, 189), (2, 1), (0, 234), (0, 249), (4, 1), (2, 1),
    (0, 159), (0, 235), (2, 1), (0, 190), (2, 1), (0, 205), (0, 250), (14, 1),
    (4, 1), (2, 1), (0, 221), (0, 236), (6, 1), (4, 1), (2, 1), (0, 233),
    (0, 175), (0, 220), (2, 1), (0, 206), (0, 251), (8, 1), (4, 1), (2, 1),
    (0, 191), (0, 222), (2, 1), (0, 207), (0, 238), (4, 1), (2, 1), (0, 223),
    (0, 239), (2, 1), (0, 255), (2, 1), (0, 237), (2, 1), (0, 253), (2, 1),
    (0, 252), (0, 254));

  CValTab14: array [0 .. 0] of THTArray = ((0, 0)); // dummy

  CValTab15: array [0 .. 510] of THTArray = ((16, 1), (6, 1), (2, 1), (0, 0),
    (2, 1), (0, 16), (0, 1), (2, 1), (0, 17), (4, 1), (2, 1), (0, 32), (0, 2),
    (2, 1), (0, 33), (0, 18), (50, 1), (16, 1), (6, 1), (2, 1), (0, 34), (2, 1),
    (0, 48), (0, 49), (6, 1), (2, 1), (0, 19), (2, 1), (0, 3), (0, 64), (2, 1),
    (0, 50), (0, 35), (14, 1), (6, 1), (4, 1), (2, 1), (0, 4), (0, 20), (0, 65),
    (4, 1), (2, 1), (0, 51), (0, 66), (2, 1), (0, 36), (0, 67), (10, 1), (6, 1),
    (2, 1), (0, 52), (2, 1), (0, 80), (0, 5), (2, 1), (0, 81), (0, 21), (4, 1),
    (2, 1), (0, 82), (0, 37), (4, 1), (2, 1), (0, 68), (0, 83), (0, 97),
    (90, 1), (36, 1), (18, 1), (10, 1), (6, 1), (2, 1), (0, 53), (2, 1),
    (0, 96), (0, 6), (2, 1), (0, 22), (0, 98), (4, 1), (2, 1), (0, 38), (0, 84),
    (2, 1), (0, 69), (0, 99), (10, 1), (6, 1), (2, 1), (0, 54), (2, 1),
    (0, 112), (0, 7), (2, 1), (0, 113), (0, 85), (4, 1), (2, 1), (0, 23),
    (0, 100), (2, 1), (0, 114), (0, 39), (24, 1), (16, 1), (8, 1), (4, 1),
    (2, 1), (0, 70), (0, 115), (2, 1), (0, 55), (0, 101), (4, 1), (2, 1),
    (0, 86), (0, 128), (2, 1), (0, 8), (0, 116), (4, 1), (2, 1), (0, 129),
    (0, 24), (2, 1), (0, 130), (0, 40), (16, 1), (8, 1), (4, 1), (2, 1),
    (0, 71), (0, 102), (2, 1), (0, 131), (0, 56), (4, 1), (2, 1), (0, 117),
    (0, 87), (2, 1), (0, 132), (0, 72), (6, 1), (4, 1), (2, 1), (0, 144),
    (0, 25), (0, 145), (4, 1), (2, 1), (0, 146), (0, 118), (2, 1), (0, 103),
    (0, 41), (92, 1), (36, 1), (18, 1), (10, 1), (4, 1), (2, 1), (0, 133),
    (0, 88), (4, 1), (2, 1), (0, 9), (0, 119), (0, 147), (4, 1), (2, 1),
    (0, 57), (0, 148), (2, 1), (0, 73), (0, 134), (10, 1), (6, 1), (2, 1),
    (0, 104), (2, 1), (0, 160), (0, 10), (2, 1), (0, 161), (0, 26), (4, 1),
    (2, 1), (0, 162), (0, 42), (2, 1), (0, 149), (0, 89), (26, 1), (14, 1),
    (6, 1), (2, 1), (0, 163), (2, 1), (0, 58), (0, 135), (4, 1), (2, 1),
    (0, 120), (0, 164), (2, 1), (0, 74), (0, 150), (6, 1), (4, 1), (2, 1),
    (0, 105), (0, 176), (0, 177), (4, 1), (2, 1), (0, 27), (0, 165), (0, 178),
    (14, 1), (8, 1), (4, 1), (2, 1), (0, 90), (0, 43), (2, 1), (0, 136),
    (0, 151), (2, 1), (0, 179), (2, 1), (0, 121), (0, 59), (8, 1), (4, 1),
    (2, 1), (0, 106), (0, 180), (2, 1), (0, 75), (0, 193), (4, 1), (2, 1),
    (0, 152), (0, 137), (2, 1), (0, 28), (0, 181), (80, 1), (34, 1), (16, 1),
    (6, 1), (4, 1), (2, 1), (0, 91), (0, 44), (0, 194), (6, 1), (4, 1), (2, 1),
    (0, 11), (0, 192), (0, 166), (2, 1), (0, 167), (0, 122), (10, 1), (4, 1),
    (2, 1), (0, 195), (0, 60), (4, 1), (2, 1), (0, 12), (0, 153), (0, 182),
    (4, 1), (2, 1), (0, 107), (0, 196), (2, 1), (0, 76), (0, 168), (20, 1),
    (10, 1), (4, 1), (2, 1), (0, 138), (0, 197), (4, 1), (2, 1), (0, 208),
    (0, 92), (0, 209), (4, 1), (2, 1), (0, 183), (0, 123), (2, 1), (0, 29),
    (2, 1), (0, 13), (0, 45), (12, 1), (4, 1), (2, 1), (0, 210), (0, 211),
    (4, 1), (2, 1), (0, 61), (0, 198), (2, 1), (0, 108), (0, 169), (6, 1),
    (4, 1), (2, 1), (0, 154), (0, 184), (0, 212), (4, 1), (2, 1), (0, 139),
    (0, 77), (2, 1), (0, 199), (0, 124), (68, 1), (34, 1), (18, 1), (10, 1),
    (4, 1), (2, 1), (0, 213), (0, 93), (4, 1), (2, 1), (0, 224), (0, 14),
    (0, 225), (4, 1), (2, 1), (0, 30), (0, 226), (2, 1), (0, 170), (0, 46),
    (8, 1), (4, 1), (2, 1), (0, 185), (0, 155), (2, 1), (0, 227), (0, 214),
    (4, 1), (2, 1), (0, 109), (0, 62), (2, 1), (0, 200), (0, 140), (16, 1),
    (8, 1), (4, 1), (2, 1), (0, 228), (0, 78), (2, 1), (0, 215), (0, 125),
    (4, 1), (2, 1), (0, 229), (0, 186), (2, 1), (0, 171), (0, 94), (8, 1),
    (4, 1), (2, 1), (0, 201), (0, 156), (2, 1), (0, 241), (0, 31), (6, 1),
    (4, 1), (2, 1), (0, 240), (0, 110), (0, 242), (2, 1), (0, 47), (0, 230),
    (38, 1), (18, 1), (8, 1), (4, 1), (2, 1), (0, 216), (0, 243), (2, 1),
    (0, 63), (0, 244), (6, 1), (2, 1), (0, 79), (2, 1), (0, 141), (0, 217),
    (2, 1), (0, 187), (0, 202), (8, 1), (4, 1), (2, 1), (0, 172), (0, 231),
    (2, 1), (0, 126), (0, 245), (8, 1), (4, 1), (2, 1), (0, 157), (0, 95),
    (2, 1), (0, 232), (0, 142), (2, 1), (0, 246), (0, 203), (34, 1), (18, 1),
    (10, 1), (6, 1), (4, 1), (2, 1), (0, 15), (0, 174), (0, 111), (2, 1),
    (0, 188), (0, 218), (4, 1), (2, 1), (0, 173), (0, 247), (2, 1), (0, 127),
    (0, 233), (8, 1), (4, 1), (2, 1), (0, 158), (0, 204), (2, 1), (0, 248),
    (0, 143), (4, 1), (2, 1), (0, 219), (0, 189), (2, 1), (0, 234), (0, 249),
    (16, 1), (8, 1), (4, 1), (2, 1), (0, 159), (0, 220), (2, 1), (0, 205),
    (0, 235), (4, 1), (2, 1), (0, 190), (0, 250), (2, 1), (0, 175), (0, 221),
    (14, 1), (6, 1), (4, 1), (2, 1), (0, 236), (0, 206), (0, 251), (4, 1),
    (2, 1), (0, 191), (0, 237), (2, 1), (0, 222), (0, 252), (6, 1), (4, 1),
    (2, 1), (0, 207), (0, 253), (0, 238), (4, 1), (2, 1), (0, 223), (0, 254),
    (2, 1), (0, 239), (0, 255));

  CValTab16: array [0 .. 510] of THTArray = ((2, 1), (0, 0), (6, 1), (2, 1),
    (0, 16), (2, 1), (0, 1), (0, 17), (42, 1), (8, 1), (4, 1), (2, 1), (0, 32),
    (0, 2), (2, 1), (0, 33), (0, 18), (10, 1), (6, 1), (2, 1), (0, 34), (2, 1),
    (0, 48), (0, 3), (2, 1), (0, 49), (0, 19), (10, 1), (4, 1), (2, 1), (0, 50),
    (0, 35), (4, 1), (2, 1), (0, 64), (0, 4), (0, 65), (6, 1), (2, 1), (0, 20),
    (2, 1), (0, 51), (0, 66), (4, 1), (2, 1), (0, 36), (0, 80), (2, 1), (0, 67),
    (0, 52), (138, 1), (40, 1), (16, 1), (6, 1), (4, 1), (2, 1), (0, 5),
    (0, 21), (0, 81), (4, 1), (2, 1), (0, 82), (0, 37), (4, 1), (2, 1), (0, 68),
    (0, 53), (0, 83), (10, 1), (6, 1), (4, 1), (2, 1), (0, 96), (0, 6), (0, 97),
    (2, 1), (0, 22), (0, 98), (8, 1), (4, 1), (2, 1), (0, 38), (0, 84), (2, 1),
    (0, 69), (0, 99), (4, 1), (2, 1), (0, 54), (0, 112), (0, 113), (40, 1),
    (18, 1), (8, 1), (2, 1), (0, 23), (2, 1), (0, 7), (2, 1), (0, 85), (0, 100),
    (4, 1), (2, 1), (0, 114), (0, 39), (4, 1), (2, 1), (0, 70), (0, 101),
    (0, 115), (10, 1), (6, 1), (2, 1), (0, 55), (2, 1), (0, 86), (0, 8), (2, 1),
    (0, 128), (0, 129), (6, 1), (2, 1), (0, 24), (2, 1), (0, 116), (0, 71),
    (2, 1), (0, 130), (2, 1), (0, 40), (0, 102), (24, 1), (14, 1), (8, 1),
    (4, 1), (2, 1), (0, 131), (0, 56), (2, 1), (0, 117), (0, 132), (4, 1),
    (2, 1), (0, 72), (0, 144), (0, 145), (6, 1), (2, 1), (0, 25), (2, 1),
    (0, 9), (0, 118), (2, 1), (0, 146), (0, 41), (14, 1), (8, 1), (4, 1),
    (2, 1), (0, 133), (0, 88), (2, 1), (0, 147), (0, 57), (4, 1), (2, 1),
    (0, 160), (0, 10), (0, 26), (8, 1), (2, 1), (0, 162), (2, 1), (0, 103),
    (2, 1), (0, 87), (0, 73), (6, 1), (2, 1), (0, 148), (2, 1), (0, 119),
    (0, 134), (2, 1), (0, 161), (2, 1), (0, 104), (0, 149), (220, 1), (126, 1),
    (50, 1), (26, 1), (12, 1), (6, 1), (2, 1), (0, 42), (2, 1), (0, 89),
    (0, 58), (2, 1), (0, 163), (2, 1), (0, 135), (0, 120), (8, 1), (4, 1),
    (2, 1), (0, 164), (0, 74), (2, 1), (0, 150), (0, 105), (4, 1), (2, 1),
    (0, 176), (0, 11), (0, 177), (10, 1), (4, 1), (2, 1), (0, 27), (0, 178),
    (2, 1), (0, 43), (2, 1), (0, 165), (0, 90), (6, 1), (2, 1), (0, 179),
    (2, 1), (0, 166), (0, 106), (4, 1), (2, 1), (0, 180), (0, 75), (2, 1),
    (0, 12), (0, 193), (30, 1), (14, 1), (6, 1), (4, 1), (2, 1), (0, 181),
    (0, 194), (0, 44), (4, 1), (2, 1), (0, 167), (0, 195), (2, 1), (0, 107),
    (0, 196), (8, 1), (2, 1), (0, 29), (4, 1), (2, 1), (0, 136), (0, 151),
    (0, 59), (4, 1), (2, 1), (0, 209), (0, 210), (2, 1), (0, 45), (0, 211),
    (18, 1), (6, 1), (4, 1), (2, 1), (0, 30), (0, 46), (0, 226), (6, 1), (4, 1),
    (2, 1), (0, 121), (0, 152), (0, 192), (2, 1), (0, 28), (2, 1), (0, 137),
    (0, 91), (14, 1), (6, 1), (2, 1), (0, 60), (2, 1), (0, 122), (0, 182),
    (4, 1), (2, 1), (0, 76), (0, 153), (2, 1), (0, 168), (0, 138), (6, 1),
    (2, 1), (0, 13), (2, 1), (0, 197), (0, 92), (4, 1), (2, 1), (0, 61),
    (0, 198), (2, 1), (0, 108), (0, 154), (88, 1), (86, 1), (36, 1), (16, 1),
    (8, 1), (4, 1), (2, 1), (0, 139), (0, 77), (2, 1), (0, 199), (0, 124),
    (4, 1), (2, 1), (0, 213), (0, 93), (2, 1), (0, 224), (0, 14), (8, 1),
    (2, 1), (0, 227), (4, 1), (2, 1), (0, 208), (0, 183), (0, 123), (6, 1),
    (4, 1), (2, 1), (0, 169), (0, 184), (0, 212), (2, 1), (0, 225), (2, 1),
    (0, 170), (0, 185), (24, 1), (10, 1), (6, 1), (4, 1), (2, 1), (0, 155),
    (0, 214), (0, 109), (2, 1), (0, 62), (0, 200), (6, 1), (4, 1), (2, 1),
    (0, 140), (0, 228), (0, 78), (4, 1), (2, 1), (0, 215), (0, 229), (2, 1),
    (0, 186), (0, 171), (12, 1), (4, 1), (2, 1), (0, 156), (0, 230), (4, 1),
    (2, 1), (0, 110), (0, 216), (2, 1), (0, 141), (0, 187), (8, 1), (4, 1),
    (2, 1), (0, 231), (0, 157), (2, 1), (0, 232), (0, 142), (4, 1), (2, 1),
    (0, 203), (0, 188), (0, 158), (0, 241), (2, 1), (0, 31), (2, 1), (0, 15),
    (0, 47), (66, 1), (56, 1), (2, 1), (0, 242), (52, 1), (50, 1), (20, 1),
    (8, 1), (2, 1), (0, 189), (2, 1), (0, 94), (2, 1), (0, 125), (0, 201),
    (6, 1), (2, 1), (0, 202), (2, 1), (0, 172), (0, 126), (4, 1), (2, 1),
    (0, 218), (0, 173), (0, 204), (10, 1), (6, 1), (2, 1), (0, 174), (2, 1),
    (0, 219), (0, 220), (2, 1), (0, 205), (0, 190), (6, 1), (4, 1), (2, 1),
    (0, 235), (0, 237), (0, 238), (6, 1), (4, 1), (2, 1), (0, 217), (0, 234),
    (0, 233), (2, 1), (0, 222), (4, 1), (2, 1), (0, 221), (0, 236), (0, 206),
    (0, 63), (0, 240), (4, 1), (2, 1), (0, 243), (0, 244), (2, 1), (0, 79),
    (2, 1), (0, 245), (0, 95), (10, 1), (2, 1), (0, 255), (4, 1), (2, 1),
    (0, 246), (0, 111), (2, 1), (0, 247), (0, 127), (12, 1), (6, 1), (2, 1),
    (0, 143), (2, 1), (0, 248), (0, 249), (4, 1), (2, 1), (0, 159), (0, 250),
    (0, 175), (8, 1), (4, 1), (2, 1), (0, 251), (0, 191), (2, 1), (0, 252),
    (0, 207), (4, 1), (2, 1), (0, 253), (0, 223), (2, 1), (0, 254), (0, 239));

  CValTab24: array [0 .. 511] of THTArray = ((60, 1), (8, 1), (4, 1), (2, 1),
    (0, 0), (0, 16), (2, 1), (0, 1), (0, 17), (14, 1), (6, 1), (4, 1), (2, 1),
    (0, 32), (0, 2), (0, 33), (2, 1), (0, 18), (2, 1), (0, 34), (2, 1), (0, 48),
    (0, 3), (14, 1), (4, 1), (2, 1), (0, 49), (0, 19), (4, 1), (2, 1), (0, 50),
    (0, 35), (4, 1), (2, 1), (0, 64), (0, 4), (0, 65), (8, 1), (4, 1), (2, 1),
    (0, 20), (0, 51), (2, 1), (0, 66), (0, 36), (6, 1), (4, 1), (2, 1), (0, 67),
    (0, 52), (0, 81), (6, 1), (4, 1), (2, 1), (0, 80), (0, 5), (0, 21), (2, 1),
    (0, 82), (0, 37), (250, 1), (98, 1), (34, 1), (18, 1), (10, 1), (4, 1),
    (2, 1), (0, 68), (0, 83), (2, 1), (0, 53), (2, 1), (0, 96), (0, 6), (4, 1),
    (2, 1), (0, 97), (0, 22), (2, 1), (0, 98), (0, 38), (8, 1), (4, 1), (2, 1),
    (0, 84), (0, 69), (2, 1), (0, 99), (0, 54), (4, 1), (2, 1), (0, 113),
    (0, 85), (2, 1), (0, 100), (0, 70), (32, 1), (14, 1), (6, 1), (2, 1),
    (0, 114), (2, 1), (0, 39), (0, 55), (2, 1), (0, 115), (4, 1), (2, 1),
    (0, 112), (0, 7), (0, 23), (10, 1), (4, 1), (2, 1), (0, 101), (0, 86),
    (4, 1), (2, 1), (0, 128), (0, 8), (0, 129), (4, 1), (2, 1), (0, 116),
    (0, 71), (2, 1), (0, 24), (0, 130), (16, 1), (8, 1), (4, 1), (2, 1),
    (0, 40), (0, 102), (2, 1), (0, 131), (0, 56), (4, 1), (2, 1), (0, 117),
    (0, 87), (2, 1), (0, 132), (0, 72), (8, 1), (4, 1), (2, 1), (0, 145),
    (0, 25), (2, 1), (0, 146), (0, 118), (4, 1), (2, 1), (0, 103), (0, 41),
    (2, 1), (0, 133), (0, 88), (92, 1), (34, 1), (16, 1), (8, 1), (4, 1),
    (2, 1), (0, 147), (0, 57), (2, 1), (0, 148), (0, 73), (4, 1), (2, 1),
    (0, 119), (0, 134), (2, 1), (0, 104), (0, 161), (8, 1), (4, 1), (2, 1),
    (0, 162), (0, 42), (2, 1), (0, 149), (0, 89), (4, 1), (2, 1), (0, 163),
    (0, 58), (2, 1), (0, 135), (2, 1), (0, 120), (0, 74), (22, 1), (12, 1),
    (4, 1), (2, 1), (0, 164), (0, 150), (4, 1), (2, 1), (0, 105), (0, 177),
    (2, 1), (0, 27), (0, 165), (6, 1), (2, 1), (0, 178), (2, 1), (0, 90),
    (0, 43), (2, 1), (0, 136), (0, 179), (16, 1), (10, 1), (6, 1), (2, 1),
    (0, 144), (2, 1), (0, 9), (0, 160), (2, 1), (0, 151), (0, 121), (4, 1),
    (2, 1), (0, 166), (0, 106), (0, 180), (12, 1), (6, 1), (2, 1), (0, 26),
    (2, 1), (0, 10), (0, 176), (2, 1), (0, 59), (2, 1), (0, 11), (0, 192),
    (4, 1), (2, 1), (0, 75), (0, 193), (2, 1), (0, 152), (0, 137), (67, 1),
    (34, 1), (16, 1), (8, 1), (4, 1), (2, 1), (0, 28), (0, 181), (2, 1),
    (0, 91), (0, 194), (4, 1), (2, 1), (0, 44), (0, 167), (2, 1), (0, 122),
    (0, 195), (10, 1), (6, 1), (2, 1), (0, 60), (2, 1), (0, 12), (0, 208),
    (2, 1), (0, 182), (0, 107), (4, 1), (2, 1), (0, 196), (0, 76), (2, 1),
    (0, 153), (0, 168), (16, 1), (8, 1), (4, 1), (2, 1), (0, 138), (0, 197),
    (2, 1), (0, 92), (0, 209), (4, 1), (2, 1), (0, 183), (0, 123), (2, 1),
    (0, 29), (0, 210), (9, 1), (4, 1), (2, 1), (0, 45), (0, 211), (2, 1),
    (0, 61), (0, 198), (85, 250), (4, 1), (2, 1), (0, 108), (0, 169), (2, 1),
    (0, 154), (0, 212), (32, 1), (16, 1), (8, 1), (4, 1), (2, 1), (0, 184),
    (0, 139), (2, 1), (0, 77), (0, 199), (4, 1), (2, 1), (0, 124), (0, 213),
    (2, 1), (0, 93), (0, 225), (8, 1), (4, 1), (2, 1), (0, 30), (0, 226),
    (2, 1), (0, 170), (0, 185), (4, 1), (2, 1), (0, 155), (0, 227), (2, 1),
    (0, 214), (0, 109), (20, 1), (10, 1), (6, 1), (2, 1), (0, 62), (2, 1),
    (0, 46), (0, 78), (2, 1), (0, 200), (0, 140), (4, 1), (2, 1), (0, 228),
    (0, 215), (4, 1), (2, 1), (0, 125), (0, 171), (0, 229), (10, 1), (4, 1),
    (2, 1), (0, 186), (0, 94), (2, 1), (0, 201), (2, 1), (0, 156), (0, 110),
    (8, 1), (2, 1), (0, 230), (2, 1), (0, 13), (2, 1), (0, 224), (0, 14),
    (4, 1), (2, 1), (0, 216), (0, 141), (2, 1), (0, 187), (0, 202), (74, 1),
    (2, 1), (0, 255), (64, 1), (58, 1), (32, 1), (16, 1), (8, 1), (4, 1),
    (2, 1), (0, 172), (0, 231), (2, 1), (0, 126), (0, 217), (4, 1), (2, 1),
    (0, 157), (0, 232), (2, 1), (0, 142), (0, 203), (8, 1), (4, 1), (2, 1),
    (0, 188), (0, 218), (2, 1), (0, 173), (0, 233), (4, 1), (2, 1), (0, 158),
    (0, 204), (2, 1), (0, 219), (0, 189), (16, 1), (8, 1), (4, 1), (2, 1),
    (0, 234), (0, 174), (2, 1), (0, 220), (0, 205), (4, 1), (2, 1), (0, 235),
    (0, 190), (2, 1), (0, 221), (0, 236), (8, 1), (4, 1), (2, 1), (0, 206),
    (0, 237), (2, 1), (0, 222), (0, 238), (0, 15), (4, 1), (2, 1), (0, 240),
    (0, 31), (0, 241), (4, 1), (2, 1), (0, 242), (0, 47), (2, 1), (0, 243),
    (0, 63), (18, 1), (8, 1), (4, 1), (2, 1), (0, 244), (0, 79), (2, 1),
    (0, 245), (0, 95), (4, 1), (2, 1), (0, 246), (0, 111), (2, 1), (0, 247),
    (2, 1), (0, 127), (0, 143), (10, 1), (4, 1), (2, 1), (0, 248), (0, 249),
    (4, 1), (2, 1), (0, 159), (0, 175), (0, 250), (8, 1), (4, 1), (2, 1),
    (0, 251), (0, 191), (2, 1), (0, 252), (0, 207), (4, 1), (2, 1), (0, 253),
    (0, 223), (2, 1), (0, 254), (0, 239));

  CValTab32: array [0 .. 30] of THTArray = ((2, 1), (0, 0), (8, 1), (4, 1),
    (2, 1), (0, 8), (0, 4), (2, 1), (0, 1), (0, 2), (8, 1), (4, 1), (2, 1),
    (0, 12), (0, 10), (2, 1), (0, 3), (0, 6), (6, 1), (2, 1), (0, 9), (2, 1),
    (0, 5), (0, 7), (4, 1), (2, 1), (0, 14), (0, 13), (2, 1), (0, 15), (0, 11));

  CValTab33: array [0 .. 30] of THTArray = ((16, 1), (8, 1), (4, 1), (2, 1),
    (0, 0), (0, 1), (2, 1), (0, 2), (0, 3), (4, 1), (2, 1), (0, 4), (0, 5),
    (2, 1), (0, 6), (0, 7), (8, 1), (4, 1), (2, 1), (0, 8), (0, 9), (2, 1),
    (0, 10), (0, 11), (4, 1), (2, 1), (0, 12), (0, 13), (2, 1),
    (0, 14), (0, 15));

  // Size of the table of whole numbers raised to 4/3 power.
  // This may be adjusted for performance without any problems.
  CNrOfSFBBlock: array [0 .. 5, 0 .. 2, 0 .. 3] of Cardinal =
    (((6, 5, 5, 5), (9, 9, 9, 9), (6, 9, 9, 9)), ((6, 5, 7, 3), (9, 9, 12, 6),
    (6, 9, 12, 6)), ((11, 10, 0, 0), (18, 18, 0, 0), (15, 18, 0, 0)),
    ((7, 7, 7, 0), (12, 12, 12, 0), (6, 15, 12, 0)),
    ((6, 6, 6, 3), (12, 9, 9, 6), (6, 12, 9, 6)), ((8, 8, 5, 0), (15, 12, 9, 0),
    (6, 18, 9, 0)));

  CBitMask: array [0 .. 17] of Cardinal = (0, $00000001, $00000003, $00000007,
    $0000000F, $0000001F, $0000003F, $0000007F, $000000FF, $000001FF, $000003FF,
    $000007FF, $00000FFF, $00001FFF, $00003FFF, $00007FFF, $0000FFFF,
    $0001FFFF);

  // factors and offsets for sample requantization:
  CTableFactor: array [0 .. 14] of Single = (0, 2 / 3, 2 / 7, 2 / 15, 2 / 31,
    2 / 63, 2 / 127, 2 / 255, 2 / 511, 2 / 1023, 2 / 2047, 2 / 4095, 2 / 8191,
    2 / 16383, 2 / 32767);

  CTableOffset: array [0 .. 14] of Single = (0, -2 / 3, -6 / 7, -14 / 15,
    -30 / 31, -62 / 63, -126 / 127, -254 / 255, -510 / 511, -1022 / 1023,
    -2046 / 2047, -4094 / 4095, -8190 / 8191, -16382 / 16383, -32766 / 32767);

  // Scalefactors for layer I and II, Annex 3-B.1 in ISO/IEC DIS 11172:
  CScaleFactors: array [0 .. 63] of Single = (2, 1.58740105196820,
    1.25992104989487, 1, 0.7937005259841, 0.62996052494744, 0.5,
    0.39685026299205, 0.31498026247372, 0.25, 0.19842513149602,
    0.15749013123686, 0.125, 0.09921256574801, 0.07874506561843, 0.0625,
    0.04960628287401, 0.03937253280921, 0.03125, 0.02480314143700,
    0.01968626640461, 0.015625, 0.0124015707185, 0.00984313320230, 0.0078125,
    0.00620078535925, 0.00492156660115, 0.00390625000000, 0.00310039267963,
    0.00246078330058, 0.001953125, 0.00155019633981, 0.00123039165029,
    0.0009765625, 0.00077509816991, 0.00061519582514, 0.00048828125,
    0.00038754908495, 0.00030759791257, 0.00024414062500, 0.00019377454248,
    0.00015379895629, 0.0001220703125, 0.00009688727124, 0.00007689947814,
    0.00006103515625, 0.00004844363562, 0.00003844973907, 0.00003051757813,
    0.00002422181781, 0.00001922486954, 0.00001525878906, 1.21109089E-5,
    9.61243477E-6, 7.62939453E-6, 6.05545445E-6, 4.80621738E-6, 3.81469727E-6,
    3.02772723E-6, 2.40310869E-6, 1.90734863E-6, 1.51386361E-6, 1.20155435E-6,
    0 { illegal scalefactor } );

  // this table contains 3 requantized samples for each legal codeword
  // when grouped in 5 bits, i.e. 3 quantizationsteps per sample
  CGrouping5Bits: array [0 .. 80] of Single = (-2 / 3, -2 / 3, -2 / 3, 0,
    -2 / 3, -2 / 3, 2 / 3, -2 / 3, -2 / 3, -2 / 3, 0, -2 / 3, 0, 0, -2 / 3,
    2 / 3, 0, -2 / 3, -2 / 3, 2 / 3, -2 / 3, 0, 2 / 3, -2 / 3, 2 / 3, 2 / 3,
    -2 / 3, -2 / 3, -2 / 3, 0, 0, -2 / 3, 0, 2 / 3, -2 / 3, 0, -2 / 3, 0, 0, 0,
    0, 0, 2 / 3, 0, 0, -2 / 3, 2 / 3, 0, 0, 2 / 3, 0, 2 / 3, 2 / 3, 0, -2 / 3,
    -2 / 3, 2 / 3, 0, -2 / 3, 2 / 3, 2 / 3, -2 / 3, 2 / 3, -2 / 3, 0, 2 / 3, 0,
    0, 2 / 3, 2 / 3, 0, 2 / 3, -2 / 3, 2 / 3, 2 / 3, 0, 2 / 3, 2 / 3, 2 / 3,
    2 / 3, 2 / 3);

  // this table contains 3 requantized samples for each legal codeword
  // when grouped in 7 bits, i.e. 5 quantizationsteps per sample
  CGrouping7Bits: array [0 .. 125 * 3 - 1] of Single = (-0.8, -0.8, -0.8, -0.4,
    -0.8, -0.8, 0.0, -0.8, -0.8, 0.4, -0.8, -0.8, 0.8, -0.8, -0.8, -0.8, -0.4,
    -0.8, -0.4, -0.4, -0.8, 0.0, -0.4, -0.8, 0.4, -0.4, -0.8, 0.8, -0.4, -0.8,
    -0.8, 0.0, -0.8, -0.4, 0.0, -0.8, 0.0, 0.0, -0.8, 0.4, 0.0, -0.8, 0.8, 0.0,
    -0.8, -0.8, 0.4, -0.8, -0.4, 0.4, -0.8, 0.0, 0.4, -0.8, 0.4, 0.4, -0.8, 0.8,
    0.4, -0.8, -0.8, 0.8, -0.8, -0.4, 0.8, -0.8, 0.0, 0.8, -0.8, 0.4, 0.8, -0.8,
    0.8, 0.8, -0.8, -0.8, -0.8, -0.4, -0.4, -0.8, -0.4, 0.0, -0.8, -0.4, 0.4,
    -0.8, -0.4, 0.8, -0.8, -0.4, -0.8, -0.4, -0.4, -0.4, -0.4, -0.4, 0.0, -0.4,
    -0.4, 0.4, -0.4, -0.4, 0.8, -0.4, -0.4, -0.8, 0.0, -0.4, -0.4, 0.0, -0.4,
    0.0, 0.0, -0.4, 0.4, 0.0, -0.4, 0.8, 0.0, -0.4, -0.8, 0.4, -0.4, -0.4, 0.4,
    -0.4, 0.0, 0.4, -0.4, 0.4, 0.4, -0.4, 0.8, 0.4, -0.4, -0.8, 0.8, -0.4, -0.4,
    0.8, -0.4, 0.0, 0.8, -0.4, 0.4, 0.8, -0.4, 0.8, 0.8, -0.4, -0.8, -0.8, 0.0,
    -0.4, -0.8, 0.0, 0.0, -0.8, 0.0, 0.4, -0.8, 0.0, 0.8, -0.8, 0.0, -0.8, -0.4,
    0.0, -0.4, -0.4, 0.0, 0.0, -0.4, 0.0, 0.4, -0.4, 0.0, 0.8, -0.4, 0.0, -0.8,
    0.0, 0.0, -0.4, 0.0, 0.0, 0.0, 0.0, 0.0, 0.4, 0.0, 0.0, 0.8, 0.0, 0.0, -0.8,
    0.4, 0.0, -0.4, 0.4, 0.0, 0.0, 0.4, 0.0, 0.4, 0.4, 0.0, 0.8, 0.4, 0.0, -0.8,
    0.8, 0.0, -0.4, 0.8, 0.0, 0.0, 0.8, 0.0, 0.4, 0.8, 0.0, 0.8, 0.8, 0.0, -0.8,
    -0.8, 0.4, -0.4, -0.8, 0.4, 0.0, -0.8, 0.4, 0.4, -0.8, 0.4, 0.8, -0.8, 0.4,
    -0.8, -0.4, 0.4, -0.4, -0.4, 0.4, 0.0, -0.4, 0.4, 0.4, -0.4, 0.4, 0.8, -0.4,
    0.4, -0.8, 0.0, 0.4, -0.4, 0.0, 0.4, 0.0, 0.0, 0.4, 0.4, 0.0, 0.4, 0.8, 0.0,
    0.4, -0.8, 0.4, 0.4, -0.4, 0.4, 0.4, 0.0, 0.4, 0.4, 0.4, 0.4, 0.4, 0.8, 0.4,
    0.4, -0.8, 0.8, 0.4, -0.4, 0.8, 0.4, 0.0, 0.8, 0.4, 0.4, 0.8, 0.4, 0.8, 0.8,
    0.4, -0.8, -0.8, 0.8, -0.4, -0.8, 0.8, 0.0, -0.8, 0.8, 0.4, -0.8, 0.8, 0.8,
    -0.8, 0.8, -0.8, -0.4, 0.8, -0.4, -0.4, 0.8, 0.0, -0.4, 0.8, 0.4, -0.4, 0.8,
    0.8, -0.4, 0.8, -0.8, 0.0, 0.8, -0.4, 0.0, 0.8, 0.0, 0.0, 0.8, 0.4, 0.0,
    0.8, 0.8, 0.0, 0.8, -0.8, 0.4, 0.8, -0.4, 0.4, 0.8, 0.0, 0.4, 0.8, 0.4, 0.4,
    0.8, 0.8, 0.4, 0.8, -0.8, 0.8, 0.8, -0.4, 0.8, 0.8, 0.0, 0.8, 0.8, 0.4, 0.8,
    0.8, 0.8, 0.8, 0.8);

  // this table contains 3 requantized samples for each legal codeword
  // when grouped in 10 bits, i.e. 9 quantizationsteps per sample
  CGrouping10Bits: array [0 .. 729 * 3 - 1] of Single = (-8 / 9, -8 / 9, -8 / 9,
    -6 / 9, -8 / 9, -8 / 9, -4 / 9, -8 / 9, -8 / 9, -2 / 9, -8 / 9, -8 / 9, 0,
    -8 / 9, -8 / 9, 2 / 9, -8 / 9, -8 / 9, 4 / 9, -8 / 9, -8 / 9, 6 / 9, -8 / 9,
    -8 / 9, 8 / 9, -8 / 9, -8 / 9, -8 / 9, -6 / 9, -8 / 9, -6 / 9, -6 / 9,
    -8 / 9, -4 / 9, -6 / 9, -8 / 9, -2 / 9, -6 / 9, -8 / 9, 0, -6 / 9, -8 / 9,
    2 / 9, -6 / 9, -8 / 9, 4 / 9, -6 / 9, -8 / 9, 6 / 9, -6 / 9, -8 / 9, 8 / 9,
    -6 / 9, -8 / 9, -8 / 9, -4 / 9, -8 / 9, -6 / 9, -4 / 9, -8 / 9, -4 / 9,
    -4 / 9, -8 / 9, -2 / 9, -4 / 9, -8 / 9, 0, -4 / 9, -8 / 9, 2 / 9, -4 / 9,
    -8 / 9, 4 / 9, -4 / 9, -8 / 9, 6 / 9, -4 / 9, -8 / 9, 8 / 9, -4 / 9, -8 / 9,
    -8 / 9, -2 / 9, -8 / 9, -6 / 9, -2 / 9, -8 / 9, -4 / 9, -2 / 9, -8 / 9,
    -2 / 9, -2 / 9, -8 / 9, 0, -2 / 9, -8 / 9, 2 / 9, -2 / 9, -8 / 9, 4 / 9,
    -2 / 9, -8 / 9, 6 / 9, -2 / 9, -8 / 9, 8 / 9, -2 / 9, -8 / 9, -8 / 9, 0,
    -8 / 9, -6 / 9, 0, -8 / 9, -4 / 9, 0, -8 / 9, -2 / 9, 0, -8 / 9, 0, 0,
    -8 / 9, 2 / 9, 0, -8 / 9, 4 / 9, 0, -8 / 9, 6 / 9, 0, -8 / 9, 8 / 9, 0,
    -8 / 9, -8 / 9, 2 / 9, -8 / 9, -6 / 9, 2 / 9, -8 / 9, -4 / 9, 2 / 9, -8 / 9,
    -2 / 9, 2 / 9, -8 / 9, 0, 2 / 9, -8 / 9, 2 / 9, 2 / 9, -8 / 9, 4 / 9, 2 / 9,
    -8 / 9, 6 / 9, 2 / 9, -8 / 9, 8 / 9, 2 / 9, -8 / 9, -8 / 9, 4 / 9, -8 / 9,
    -6 / 9, 4 / 9, -8 / 9, -4 / 9, 4 / 9, -8 / 9, -2 / 9, 4 / 9, -8 / 9, 0,
    4 / 9, -8 / 9, 2 / 9, 4 / 9, -8 / 9, 4 / 9, 4 / 9, -8 / 9, 6 / 9, 4 / 9,
    -8 / 9, 8 / 9, 4 / 9, -8 / 9, -8 / 9, 6 / 9, -8 / 9, -6 / 9, 6 / 9, -8 / 9,
    -4 / 9, 6 / 9, -8 / 9, -2 / 9, 6 / 9, -8 / 9, 0, 6 / 9, -8 / 9, 2 / 9,
    6 / 9, -8 / 9, 4 / 9, 6 / 9, -8 / 9, 6 / 9, 6 / 9, -8 / 9, 8 / 9, 6 / 9,
    -8 / 9, -8 / 9, 8 / 9, -8 / 9, -6 / 9, 8 / 9, -8 / 9, -4 / 9, 8 / 9, -8 / 9,
    -2 / 9, 8 / 9, -8 / 9, 0, 8 / 9, -8 / 9, 2 / 9, 8 / 9, -8 / 9, 4 / 9, 8 / 9,
    -8 / 9, 6 / 9, 8 / 9, -8 / 9, 8 / 9, 8 / 9, -8 / 9, -8 / 9, -8 / 9, -6 / 9,
    -6 / 9, -8 / 9, -6 / 9, -4 / 9, -8 / 9, -6 / 9, -2 / 9, -8 / 9, -6 / 9, 0,
    -8 / 9, -6 / 9, 2 / 9, -8 / 9, -6 / 9, 4 / 9, -8 / 9, -6 / 9, 6 / 9, -8 / 9,
    -6 / 9, 8 / 9, -8 / 9, -6 / 9, -8 / 9, -6 / 9, -6 / 9, -6 / 9, -6 / 9,
    -6 / 9, -4 / 9, -6 / 9, -6 / 9, -2 / 9, -6 / 9, -6 / 9, 0, -6 / 9, -6 / 9,
    2 / 9, -6 / 9, -6 / 9, 4 / 9, -6 / 9, -6 / 9, 6 / 9, -6 / 9, -6 / 9, 8 / 9,
    -6 / 9, -6 / 9, -8 / 9, -4 / 9, -6 / 9, -6 / 9, -4 / 9, -6 / 9, -4 / 9,
    -4 / 9, -6 / 9, -2 / 9, -4 / 9, -6 / 9, 0, -4 / 9, -6 / 9, 2 / 9, -4 / 9,
    -6 / 9, 4 / 9, -4 / 9, -6 / 9, 6 / 9, -4 / 9, -6 / 9, 8 / 9, -4 / 9, -6 / 9,
    -8 / 9, -2 / 9, -6 / 9, -6 / 9, -2 / 9, -6 / 9, -4 / 9, -2 / 9, -6 / 9,
    -2 / 9, -2 / 9, -6 / 9, 0, -2 / 9, -6 / 9, 2 / 9, -2 / 9, -6 / 9, 4 / 9,
    -2 / 9, -6 / 9, 6 / 9, -2 / 9, -6 / 9, 8 / 9, -2 / 9, -6 / 9, -8 / 9, 0,
    -6 / 9, -6 / 9, 0, -6 / 9, -4 / 9, 0, -6 / 9, -2 / 9, 0, -6 / 9, 0, 0,
    -6 / 9, 2 / 9, 0, -6 / 9, 4 / 9, 0, -6 / 9, 6 / 9, 0, -6 / 9, 8 / 9, 0,
    -6 / 9, -8 / 9, 2 / 9, -6 / 9, -6 / 9, 2 / 9, -6 / 9, -4 / 9, 2 / 9, -6 / 9,
    -2 / 9, 2 / 9, -6 / 9, 0, 2 / 9, -6 / 9, 2 / 9, 2 / 9, -6 / 9, 4 / 9, 2 / 9,
    -6 / 9, 6 / 9, 2 / 9, -6 / 9, 8 / 9, 2 / 9, -6 / 9, -8 / 9, 4 / 9, -6 / 9,
    -6 / 9, 4 / 9, -6 / 9, -4 / 9, 4 / 9, -6 / 9, -2 / 9, 4 / 9, -6 / 9, 0,
    4 / 9, -6 / 9, 2 / 9, 4 / 9, -6 / 9, 4 / 9, 4 / 9, -6 / 9, 6 / 9, 4 / 9,
    -6 / 9, 8 / 9, 4 / 9, -6 / 9, -8 / 9, 6 / 9, -6 / 9, -6 / 9, 6 / 9, -6 / 9,
    -4 / 9, 6 / 9, -6 / 9, -2 / 9, 6 / 9, -6 / 9, 0, 6 / 9, -6 / 9, 2 / 9,
    6 / 9, -6 / 9, 4 / 9, 6 / 9, -6 / 9, 6 / 9, 6 / 9, -6 / 9, 8 / 9, 6 / 9,
    -6 / 9, -8 / 9, 8 / 9, -6 / 9, -6 / 9, 8 / 9, -6 / 9, -4 / 9, 8 / 9, -6 / 9,
    -2 / 9, 8 / 9, -6 / 9, 0, 8 / 9, -6 / 9, 2 / 9, 8 / 9, -6 / 9, 4 / 9, 8 / 9,
    -6 / 9, 6 / 9, 8 / 9, -6 / 9, 8 / 9, 8 / 9, -6 / 9, -8 / 9, -8 / 9, -4 / 9,
    -6 / 9, -8 / 9, -4 / 9, -4 / 9, -8 / 9, -4 / 9, -2 / 9, -8 / 9, -4 / 9, 0,
    -8 / 9, -4 / 9, 2 / 9, -8 / 9, -4 / 9, 4 / 9, -8 / 9, -4 / 9, 6 / 9, -8 / 9,
    -4 / 9, 8 / 9, -8 / 9, -4 / 9, -8 / 9, -6 / 9, -4 / 9, -6 / 9, -6 / 9,
    -4 / 9, -4 / 9, -6 / 9, -4 / 9, -2 / 9, -6 / 9, -4 / 9, 0, -6 / 9, -4 / 9,
    2 / 9, -6 / 9, -4 / 9, 4 / 9, -6 / 9, -4 / 9, 6 / 9, -6 / 9, -4 / 9, 8 / 9,
    -6 / 9, -4 / 9, -8 / 9, -4 / 9, -4 / 9, -6 / 9, -4 / 9, -4 / 9, -4 / 9,
    -4 / 9, -4 / 9, -2 / 9, -4 / 9, -4 / 9, 0, -4 / 9, -4 / 9, 2 / 9, -4 / 9,
    -4 / 9, 4 / 9, -4 / 9, -4 / 9, 6 / 9, -4 / 9, -4 / 9, 8 / 9, -4 / 9, -4 / 9,
    -8 / 9, -2 / 9, -4 / 9, -6 / 9, -2 / 9, -4 / 9, -4 / 9, -2 / 9, -4 / 9,
    -2 / 9, -2 / 9, -4 / 9, 0, -2 / 9, -4 / 9, 2 / 9, -2 / 9, -4 / 9, 4 / 9,
    -2 / 9, -4 / 9, 6 / 9, -2 / 9, -4 / 9, 8 / 9, -2 / 9, -4 / 9, -8 / 9, 0,
    -4 / 9, -6 / 9, 0, -4 / 9, -4 / 9, 0, -4 / 9, -2 / 9, 0, -4 / 9, 0, 0,
    -4 / 9, 2 / 9, 0, -4 / 9, 4 / 9, 0, -4 / 9, 6 / 9, 0, -4 / 9, 8 / 9, 0,
    -4 / 9, -8 / 9, 2 / 9, -4 / 9, -6 / 9, 2 / 9, -4 / 9, -4 / 9, 2 / 9, -4 / 9,
    -2 / 9, 2 / 9, -4 / 9, 0, 2 / 9, -4 / 9, 2 / 9, 2 / 9, -4 / 9, 4 / 9, 2 / 9,
    -4 / 9, 6 / 9, 2 / 9, -4 / 9, 8 / 9, 2 / 9, -4 / 9, -8 / 9, 4 / 9, -4 / 9,
    -6 / 9, 4 / 9, -4 / 9, -4 / 9, 4 / 9, -4 / 9, -2 / 9, 4 / 9, -4 / 9, 0,
    4 / 9, -4 / 9, 2 / 9, 4 / 9, -4 / 9, 4 / 9, 4 / 9, -4 / 9, 6 / 9, 4 / 9,
    -4 / 9, 8 / 9, 4 / 9, -4 / 9, -8 / 9, 6 / 9, -4 / 9, -6 / 9, 6 / 9, -4 / 9,
    -4 / 9, 6 / 9, -4 / 9, -2 / 9, 6 / 9, -4 / 9, 0, 6 / 9, -4 / 9, 2 / 9,
    6 / 9, -4 / 9, 4 / 9, 6 / 9, -4 / 9, 6 / 9, 6 / 9, -4 / 9, 8 / 9, 6 / 9,
    -4 / 9, -8 / 9, 8 / 9, -4 / 9, -6 / 9, 8 / 9, -4 / 9, -4 / 9, 8 / 9, -4 / 9,
    -2 / 9, 8 / 9, -4 / 9, 0, 8 / 9, -4 / 9, 2 / 9, 8 / 9, -4 / 9, 4 / 9, 8 / 9,
    -4 / 9, 6 / 9, 8 / 9, -4 / 9, 8 / 9, 8 / 9, -4 / 9, -8 / 9, -8 / 9, -2 / 9,
    -6 / 9, -8 / 9, -2 / 9, -4 / 9, -8 / 9, -2 / 9, -2 / 9, -8 / 9, -2 / 9, 0,
    -8 / 9, -2 / 9, 2 / 9, -8 / 9, -2 / 9, 4 / 9, -8 / 9, -2 / 9, 6 / 9, -8 / 9,
    -2 / 9, 8 / 9, -8 / 9, -2 / 9, -8 / 9, -6 / 9, -2 / 9, -6 / 9, -6 / 9,
    -2 / 9, -4 / 9, -6 / 9, -2 / 9, -2 / 9, -6 / 9, -2 / 9, 0, -6 / 9, -2 / 9,
    2 / 9, -6 / 9, -2 / 9, 4 / 9, -6 / 9, -2 / 9, 6 / 9, -6 / 9, -2 / 9, 8 / 9,
    -6 / 9, -2 / 9, -8 / 9, -4 / 9, -2 / 9, -6 / 9, -4 / 9, -2 / 9, -4 / 9,
    -4 / 9, -2 / 9, -2 / 9, -4 / 9, -2 / 9, 0, -4 / 9, -2 / 9, 2 / 9, -4 / 9,
    -2 / 9, 4 / 9, -4 / 9, -2 / 9, 6 / 9, -4 / 9, -2 / 9, 8 / 9, -4 / 9, -2 / 9,
    -8 / 9, -2 / 9, -2 / 9, -6 / 9, -2 / 9, -2 / 9, -4 / 9, -2 / 9, -2 / 9,
    -2 / 9, -2 / 9, -2 / 9, 0, -2 / 9, -2 / 9, 2 / 9, -2 / 9, -2 / 9, 4 / 9,
    -2 / 9, -2 / 9, 6 / 9, -2 / 9, -2 / 9, 8 / 9, -2 / 9, -2 / 9, -8 / 9, 0,
    -2 / 9, -6 / 9, 0, -2 / 9, -4 / 9, 0, -2 / 9, -2 / 9, 0, -2 / 9, 0, 0,
    -2 / 9, 2 / 9, 0, -2 / 9, 4 / 9, 0, -2 / 9, 6 / 9, 0, -2 / 9, 8 / 9, 0,
    -2 / 9, -8 / 9, 2 / 9, -2 / 9, -6 / 9, 2 / 9, -2 / 9, -4 / 9, 2 / 9, -2 / 9,
    -2 / 9, 2 / 9, -2 / 9, 0, 2 / 9, -2 / 9, 2 / 9, 2 / 9, -2 / 9, 4 / 9, 2 / 9,
    -2 / 9, 6 / 9, 2 / 9, -2 / 9, 8 / 9, 2 / 9, -2 / 9, -8 / 9, 4 / 9, -2 / 9,
    -6 / 9, 4 / 9, -2 / 9, -4 / 9, 4 / 9, -2 / 9, -2 / 9, 4 / 9, -2 / 9, 0,
    4 / 9, -2 / 9, 2 / 9, 4 / 9, -2 / 9, 4 / 9, 4 / 9, -2 / 9, 6 / 9, 4 / 9,
    -2 / 9, 8 / 9, 4 / 9, -2 / 9, -8 / 9, 6 / 9, -2 / 9, -6 / 9, 6 / 9, -2 / 9,
    -4 / 9, 6 / 9, -2 / 9, -2 / 9, 6 / 9, -2 / 9, 0, 6 / 9, -2 / 9, 2 / 9,
    6 / 9, -2 / 9, 4 / 9, 6 / 9, -2 / 9, 6 / 9, 6 / 9, -2 / 9, 8 / 9, 6 / 9,
    -2 / 9, -8 / 9, 8 / 9, -2 / 9, -6 / 9, 8 / 9, -2 / 9, -4 / 9, 8 / 9, -2 / 9,
    -2 / 9, 8 / 9, -2 / 9, 0, 8 / 9, -2 / 9, 2 / 9, 8 / 9, -2 / 9, 4 / 9, 8 / 9,
    -2 / 9, 6 / 9, 8 / 9, -2 / 9, 8 / 9, 8 / 9, -2 / 9, -8 / 9, -8 / 9, 0,
    -6 / 9, -8 / 9, 0, -4 / 9, -8 / 9, 0, -2 / 9, -8 / 9, 0, 0, -8 / 9, 0,
    2 / 9, -8 / 9, 0, 4 / 9, -8 / 9, 0, 6 / 9, -8 / 9, 0, 8 / 9, -8 / 9, 0,
    -8 / 9, -6 / 9, 0, -6 / 9, -6 / 9, 0, -4 / 9, -6 / 9, 0, -2 / 9, -6 / 9, 0,
    0, -6 / 9, 0, 2 / 9, -6 / 9, 0, 4 / 9, -6 / 9, 0, 6 / 9, -6 / 9, 0, 8 / 9,
    -6 / 9, 0, -8 / 9, -4 / 9, 0, -6 / 9, -4 / 9, 0, -4 / 9, -4 / 9, 0, -2 / 9,
    -4 / 9, 0, 0, -4 / 9, 0, 2 / 9, -4 / 9, 0, 4 / 9, -4 / 9, 0, 6 / 9, -4 / 9,
    0, 8 / 9, -4 / 9, 0, -8 / 9, -2 / 9, 0, -6 / 9, -2 / 9, 0, -4 / 9, -2 / 9,
    0, -2 / 9, -2 / 9, 0, 0, -2 / 9, 0, 2 / 9, -2 / 9, 0, 4 / 9, -2 / 9, 0,
    6 / 9, -2 / 9, 0, 8 / 9, -2 / 9, 0, -8 / 9, 0, 0, -6 / 9, 0, 0, -4 / 9, 0,
    0, -2 / 9, 0, 0, 0, 0, 0, 2 / 9, 0, 0, 4 / 9, 0, 0, 6 / 9, 0, 0, 8 / 9, 0,
    0, -8 / 9, 2 / 9, 0, -6 / 9, 2 / 9, 0, -4 / 9, 2 / 9, 0, -2 / 9, 2 / 9, 0,
    0, 2 / 9, 0, 2 / 9, 2 / 9, 0, 4 / 9, 2 / 9, 0, 6 / 9, 2 / 9, 0, 8 / 9,
    2 / 9, 0, -8 / 9, 4 / 9, 0, -6 / 9, 4 / 9, 0, -4 / 9, 4 / 9, 0, -2 / 9,
    4 / 9, 0, 0, 4 / 9, 0, 2 / 9, 4 / 9, 0, 4 / 9, 4 / 9, 0, 6 / 9, 4 / 9, 0,
    8 / 9, 4 / 9, 0, -8 / 9, 6 / 9, 0, -6 / 9, 6 / 9, 0, -4 / 9, 6 / 9, 0,
    -2 / 9, 6 / 9, 0, 0, 6 / 9, 0, 2 / 9, 6 / 9, 0, 4 / 9, 6 / 9, 0, 6 / 9,
    6 / 9, 0, 8 / 9, 6 / 9, 0, -8 / 9, 8 / 9, 0, -6 / 9, 8 / 9, 0, -4 / 9,
    8 / 9, 0, -2 / 9, 8 / 9, 0, 0, 8 / 9, 0, 2 / 9, 8 / 9, 0, 4 / 9, 8 / 9, 0,
    6 / 9, 8 / 9, 0, 8 / 9, 8 / 9, 0, -8 / 9, -8 / 9, 2 / 9, -6 / 9, -8 / 9,
    2 / 9, -4 / 9, -8 / 9, 2 / 9, -2 / 9, -8 / 9, 2 / 9, 0, -8 / 9, 2 / 9,
    2 / 9, -8 / 9, 2 / 9, 4 / 9, -8 / 9, 2 / 9, 6 / 9, -8 / 9, 2 / 9, 8 / 9,
    -8 / 9, 2 / 9, -8 / 9, -6 / 9, 2 / 9, -6 / 9, -6 / 9, 2 / 9, -4 / 9, -6 / 9,
    2 / 9, -2 / 9, -6 / 9, 2 / 9, 0, -6 / 9, 2 / 9, 2 / 9, -6 / 9, 2 / 9, 4 / 9,
    -6 / 9, 2 / 9, 6 / 9, -6 / 9, 2 / 9, 8 / 9, -6 / 9, 2 / 9, -8 / 9, -4 / 9,
    2 / 9, -6 / 9, -4 / 9, 2 / 9, -4 / 9, -4 / 9, 2 / 9, -2 / 9, -4 / 9, 2 / 9,
    0, -4 / 9, 2 / 9, 2 / 9, -4 / 9, 2 / 9, 4 / 9, -4 / 9, 2 / 9, 6 / 9, -4 / 9,
    2 / 9, 8 / 9, -4 / 9, 2 / 9, -8 / 9, -2 / 9, 2 / 9, -6 / 9, -2 / 9, 2 / 9,
    -4 / 9, -2 / 9, 2 / 9, -2 / 9, -2 / 9, 2 / 9, 0, -2 / 9, 2 / 9, 2 / 9,
    -2 / 9, 2 / 9, 4 / 9, -2 / 9, 2 / 9, 6 / 9, -2 / 9, 2 / 9, 8 / 9, -2 / 9,
    2 / 9, -8 / 9, 0, 2 / 9, -6 / 9, 0, 2 / 9, -4 / 9, 0, 2 / 9, -2 / 9, 0,
    2 / 9, 0, 0, 2 / 9, 2 / 9, 0, 2 / 9, 4 / 9, 0, 2 / 9, 6 / 9, 0, 2 / 9,
    8 / 9, 0, 2 / 9, -8 / 9, 2 / 9, 2 / 9, -6 / 9, 2 / 9, 2 / 9, -4 / 9, 2 / 9,
    2 / 9, -2 / 9, 2 / 9, 2 / 9, 0, 2 / 9, 2 / 9, 2 / 9, 2 / 9, 2 / 9, 4 / 9,
    2 / 9, 2 / 9, 6 / 9, 2 / 9, 2 / 9, 8 / 9, 2 / 9, 2 / 9, -8 / 9, 4 / 9,
    2 / 9, -6 / 9, 4 / 9, 2 / 9, -4 / 9, 4 / 9, 2 / 9, -2 / 9, 4 / 9, 2 / 9, 0,
    4 / 9, 2 / 9, 2 / 9, 4 / 9, 2 / 9, 4 / 9, 4 / 9, 2 / 9, 6 / 9, 4 / 9, 2 / 9,
    8 / 9, 4 / 9, 2 / 9, -8 / 9, 6 / 9, 2 / 9, -6 / 9, 6 / 9, 2 / 9, -4 / 9,
    6 / 9, 2 / 9, -2 / 9, 6 / 9, 2 / 9, 0, 6 / 9, 2 / 9, 2 / 9, 6 / 9, 2 / 9,
    4 / 9, 6 / 9, 2 / 9, 6 / 9, 6 / 9, 2 / 9, 8 / 9, 6 / 9, 2 / 9, -8 / 9,
    8 / 9, 2 / 9, -6 / 9, 8 / 9, 2 / 9, -4 / 9, 8 / 9, 2 / 9, -2 / 9, 8 / 9,
    2 / 9, 0, 8 / 9, 2 / 9, 2 / 9, 8 / 9, 2 / 9, 4 / 9, 8 / 9, 2 / 9, 6 / 9,
    8 / 9, 2 / 9, 8 / 9, 8 / 9, 2 / 9, -8 / 9, -8 / 9, 4 / 9, -6 / 9, -8 / 9,
    4 / 9, -4 / 9, -8 / 9, 4 / 9, -2 / 9, -8 / 9, 4 / 9, 0, -8 / 9, 4 / 9,
    2 / 9, -8 / 9, 4 / 9, 4 / 9, -8 / 9, 4 / 9, 6 / 9, -8 / 9, 4 / 9, 8 / 9,
    -8 / 9, 4 / 9, -8 / 9, -6 / 9, 4 / 9, -6 / 9, -6 / 9, 4 / 9, -4 / 9, -6 / 9,
    4 / 9, -2 / 9, -6 / 9, 4 / 9, 0, -6 / 9, 4 / 9, 2 / 9, -6 / 9, 4 / 9, 4 / 9,
    -6 / 9, 4 / 9, 6 / 9, -6 / 9, 4 / 9, 8 / 9, -6 / 9, 4 / 9, -8 / 9, -4 / 9,
    4 / 9, -6 / 9, -4 / 9, 4 / 9, -4 / 9, -4 / 9, 4 / 9, -2 / 9, -4 / 9, 4 / 9,
    0, -4 / 9, 4 / 9, 2 / 9, -4 / 9, 4 / 9, 4 / 9, -4 / 9, 4 / 9, 6 / 9, -4 / 9,
    4 / 9, 8 / 9, -4 / 9, 4 / 9, -8 / 9, -2 / 9, 4 / 9, -6 / 9, -2 / 9, 4 / 9,
    -4 / 9, -2 / 9, 4 / 9, -2 / 9, -2 / 9, 4 / 9, 0, -2 / 9, 4 / 9, 2 / 9,
    -2 / 9, 4 / 9, 4 / 9, -2 / 9, 4 / 9, 6 / 9, -2 / 9, 4 / 9, 8 / 9, -2 / 9,
    4 / 9, -8 / 9, 0, 4 / 9, -6 / 9, 0, 4 / 9, -4 / 9, 0, 4 / 9, -2 / 9, 0,
    4 / 9, 0, 0, 4 / 9, 2 / 9, 0, 4 / 9, 4 / 9, 0, 4 / 9, 6 / 9, 0, 4 / 9,
    8 / 9, 0, 4 / 9, -8 / 9, 2 / 9, 4 / 9, -6 / 9, 2 / 9, 4 / 9, -4 / 9, 2 / 9,
    4 / 9, -2 / 9, 2 / 9, 4 / 9, 0, 2 / 9, 4 / 9, 2 / 9, 2 / 9, 4 / 9, 4 / 9,
    2 / 9, 4 / 9, 6 / 9, 2 / 9, 4 / 9, 8 / 9, 2 / 9, 4 / 9, -8 / 9, 4 / 9,
    4 / 9, -6 / 9, 4 / 9, 4 / 9, -4 / 9, 4 / 9, 4 / 9, -2 / 9, 4 / 9, 4 / 9, 0,
    4 / 9, 4 / 9, 2 / 9, 4 / 9, 4 / 9, 4 / 9, 4 / 9, 4 / 9, 6 / 9, 4 / 9, 4 / 9,
    8 / 9, 4 / 9, 4 / 9, -8 / 9, 6 / 9, 4 / 9, -6 / 9, 6 / 9, 4 / 9, -4 / 9,
    6 / 9, 4 / 9, -2 / 9, 6 / 9, 4 / 9, 0, 6 / 9, 4 / 9, 2 / 9, 6 / 9, 4 / 9,
    4 / 9, 6 / 9, 4 / 9, 6 / 9, 6 / 9, 4 / 9, 8 / 9, 6 / 9, 4 / 9, -8 / 9,
    8 / 9, 4 / 9, -6 / 9, 8 / 9, 4 / 9, -4 / 9, 8 / 9, 4 / 9, -2 / 9, 8 / 9,
    4 / 9, 0, 8 / 9, 4 / 9, 2 / 9, 8 / 9, 4 / 9, 4 / 9, 8 / 9, 4 / 9, 6 / 9,
    8 / 9, 4 / 9, 8 / 9, 8 / 9, 4 / 9, -8 / 9, -8 / 9, 6 / 9, -6 / 9, -8 / 9,
    6 / 9, -4 / 9, -8 / 9, 6 / 9, -2 / 9, -8 / 9, 6 / 9, 0, -8 / 9, 6 / 9,
    2 / 9, -8 / 9, 6 / 9, 4 / 9, -8 / 9, 6 / 9, 6 / 9, -8 / 9, 6 / 9, 8 / 9,
    -8 / 9, 6 / 9, -8 / 9, -6 / 9, 6 / 9, -6 / 9, -6 / 9, 6 / 9, -4 / 9, -6 / 9,
    6 / 9, -2 / 9, -6 / 9, 6 / 9, 0, -6 / 9, 6 / 9, 2 / 9, -6 / 9, 6 / 9, 4 / 9,
    -6 / 9, 6 / 9, 6 / 9, -6 / 9, 6 / 9, 8 / 9, -6 / 9, 6 / 9, -8 / 9, -4 / 9,
    6 / 9, -6 / 9, -4 / 9, 6 / 9, -4 / 9, -4 / 9, 6 / 9, -2 / 9, -4 / 9, 6 / 9,
    0, -4 / 9, 6 / 9, 2 / 9, -4 / 9, 6 / 9, 4 / 9, -4 / 9, 6 / 9, 6 / 9, -4 / 9,
    6 / 9, 8 / 9, -4 / 9, 6 / 9, -8 / 9, -2 / 9, 6 / 9, -6 / 9, -2 / 9, 6 / 9,
    -4 / 9, -2 / 9, 6 / 9, -2 / 9, -2 / 9, 6 / 9, 0, -2 / 9, 6 / 9, 2 / 9,
    -2 / 9, 6 / 9, 4 / 9, -2 / 9, 6 / 9, 6 / 9, -2 / 9, 6 / 9, 8 / 9, -2 / 9,
    6 / 9, -8 / 9, 0, 6 / 9, -6 / 9, 0, 6 / 9, -4 / 9, 0, 6 / 9, -2 / 9, 0,
    6 / 9, 0, 0, 6 / 9, 2 / 9, 0, 6 / 9, 4 / 9, 0, 6 / 9, 6 / 9, 0, 6 / 9,
    8 / 9, 0, 6 / 9, -8 / 9, 2 / 9, 6 / 9, -6 / 9, 2 / 9, 6 / 9, -4 / 9, 2 / 9,
    6 / 9, -2 / 9, 2 / 9, 6 / 9, 0, 2 / 9, 6 / 9, 2 / 9, 2 / 9, 6 / 9, 4 / 9,
    2 / 9, 6 / 9, 6 / 9, 2 / 9, 6 / 9, 8 / 9, 2 / 9, 6 / 9, -8 / 9, 4 / 9,
    6 / 9, -6 / 9, 4 / 9, 6 / 9, -4 / 9, 4 / 9, 6 / 9, -2 / 9, 4 / 9, 6 / 9, 0,
    4 / 9, 6 / 9, 2 / 9, 4 / 9, 6 / 9, 4 / 9, 4 / 9, 6 / 9, 6 / 9, 4 / 9, 6 / 9,
    8 / 9, 4 / 9, 6 / 9, -8 / 9, 6 / 9, 6 / 9, -6 / 9, 6 / 9, 6 / 9, -4 / 9,
    6 / 9, 6 / 9, -2 / 9, 6 / 9, 6 / 9, 0, 6 / 9, 6 / 9, 2 / 9, 6 / 9, 6 / 9,
    4 / 9, 6 / 9, 6 / 9, 6 / 9, 6 / 9, 6 / 9, 8 / 9, 6 / 9, 6 / 9, -8 / 9,
    8 / 9, 6 / 9, -6 / 9, 8 / 9, 6 / 9, -4 / 9, 8 / 9, 6 / 9, -2 / 9, 8 / 9,
    6 / 9, 0, 8 / 9, 6 / 9, 2 / 9, 8 / 9, 6 / 9, 4 / 9, 8 / 9, 6 / 9, 6 / 9,
    8 / 9, 6 / 9, 8 / 9, 8 / 9, 6 / 9, -8 / 9, -8 / 9, 8 / 9, -6 / 9, -8 / 9,
    8 / 9, -4 / 9, -8 / 9, 8 / 9, -2 / 9, -8 / 9, 8 / 9, 0, -8 / 9, 8 / 9,
    2 / 9, -8 / 9, 8 / 9, 4 / 9, -8 / 9, 8 / 9, 6 / 9, -8 / 9, 8 / 9, 8 / 9,
    -8 / 9, 8 / 9, -8 / 9, -6 / 9, 8 / 9, -6 / 9, -6 / 9, 8 / 9, -4 / 9, -6 / 9,
    8 / 9, -2 / 9, -6 / 9, 8 / 9, 0, -6 / 9, 8 / 9, 2 / 9, -6 / 9, 8 / 9, 4 / 9,
    -6 / 9, 8 / 9, 6 / 9, -6 / 9, 8 / 9, 8 / 9, -6 / 9, 8 / 9, -8 / 9, -4 / 9,
    8 / 9, -6 / 9, -4 / 9, 8 / 9, -4 / 9, -4 / 9, 8 / 9, -2 / 9, -4 / 9, 8 / 9,
    0, -4 / 9, 8 / 9, 2 / 9, -4 / 9, 8 / 9, 4 / 9, -4 / 9, 8 / 9, 6 / 9, -4 / 9,
    8 / 9, 8 / 9, -4 / 9, 8 / 9, -8 / 9, -2 / 9, 8 / 9, -6 / 9, -2 / 9, 8 / 9,
    -4 / 9, -2 / 9, 8 / 9, -2 / 9, -2 / 9, 8 / 9, 0, -2 / 9, 8 / 9, 2 / 9,
    -2 / 9, 8 / 9, 4 / 9, -2 / 9, 8 / 9, 6 / 9, -2 / 9, 8 / 9, 8 / 9, -2 / 9,
    8 / 9, -8 / 9, 0, 8 / 9, -6 / 9, 0, 8 / 9, -4 / 9, 0, 8 / 9, -2 / 9, 0,
    8 / 9, 0, 0, 8 / 9, 2 / 9, 0, 8 / 9, 4 / 9, 0, 8 / 9, 6 / 9, 0, 8 / 9,
    8 / 9, 0, 8 / 9, -8 / 9, 2 / 9, 8 / 9, -6 / 9, 2 / 9, 8 / 9, -4 / 9, 2 / 9,
    8 / 9, -2 / 9, 2 / 9, 8 / 9, 0, 2 / 9, 8 / 9, 2 / 9, 2 / 9, 8 / 9, 4 / 9,
    2 / 9, 8 / 9, 6 / 9, 2 / 9, 8 / 9, 8 / 9, 2 / 9, 8 / 9, -8 / 9, 4 / 9,
    8 / 9, -6 / 9, 4 / 9, 8 / 9, -4 / 9, 4 / 9, 8 / 9, -2 / 9, 4 / 9, 8 / 9, 0,
    4 / 9, 8 / 9, 2 / 9, 4 / 9, 8 / 9, 4 / 9, 4 / 9, 8 / 9, 6 / 9, 4 / 9, 8 / 9,
    8 / 9, 4 / 9, 8 / 9, -8 / 9, 6 / 9, 8 / 9, -6 / 9, 6 / 9, 8 / 9, -4 / 9,
    6 / 9, 8 / 9, -2 / 9, 6 / 9, 8 / 9, 0, 6 / 9, 8 / 9, 2 / 9, 6 / 9, 8 / 9,
    4 / 9, 6 / 9, 8 / 9, 6 / 9, 6 / 9, 8 / 9, 8 / 9, 6 / 9, 8 / 9, -8 / 9,
    8 / 9, 8 / 9, -6 / 9, 8 / 9, 8 / 9, -4 / 9, 8 / 9, 8 / 9, -2 / 9, 8 / 9,
    8 / 9, 0, 8 / 9, 8 / 9, 2 / 9, 8 / 9, 8 / 9, 4 / 9, 8 / 9, 8 / 9, 6 / 9,
    8 / 9, 8 / 9, 8 / 9, 8 / 9, 8 / 9);

  // data taken from ISO/IEC DIS 11172, Annexes 3-B.2[abcd] and 3-B.4:

  // subbands 0-2 in tables 3-B.2a and 2b: (index is allocation)
  // bits per codeword
  CTableAB1CodeLength: array [0 .. 15] of Cardinal = (0, 5, 3, 4, 5, 6, 7, 8, 9,
    10, 11, 12, 13, 14, 15, 16);

  // pointer to sample grouping table, or NULL-pointer if ungrouped
  CTableAB1GroupingTables: array [0 .. 15] of PIAP1024SingleArray = (nil,
    @CGrouping5Bits, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
    nil, nil);

  // factor for requantization: (real)sample * factor - 1.0 gives requantized sample
  CTableAB1Factor: array [0 .. 15] of Single = (0, 0.5, 0.25, 1 / 8, 1 / 16,
    1 / 32, 1 / 64, 1 / 128, 1 / 256, 1 / 512, 1 / 1024, 1 / 2048, 1 / 4096,
    1 / 8192, 1 / 16384, 1 / 32768);

  // factor c for requantization from table 3-B.4
  CTableAB1C: array [0 .. 15] of Single = (0, 1.33333333333, 1.14285714286,
    1.06666666666, 1.03225806452, 1.01587301587, 1.00787401575, 1.00392156863,
    1.00195694716, 1.00097751711, 1.00048851979, 1.00024420024, 1.00012208522,
    1.00006103888, 1.00003051851, 1.00001525902);

  // addend d for requantization from table 3-B.4
  CTableAB1D: array [0 .. 15] of Single = (0, 0.5, 0.25, 0.125, 0.0625, 0.03125,
    0.015625, 7.8125E-3, 3.90625E-3, 1.953125E-3, 9.765625E-4, 4.8828125E-4,
    2.4414063E-4, 1.2207031E-4, 6.103516E-5, 3.051758E-5);

  // subbands 3-... tables 3-B.2a and 2b:
  CTableAB234GroupingTables: array [0 .. 15] of PIAP1024SingleArray = (nil,
    @CGrouping5Bits, @CGrouping7Bits, nil, @CGrouping10Bits, nil, nil, nil, nil,
    nil, nil, nil, nil, nil, nil, nil);

  // subbands 3-10 in tables 3-B.2a and 2b:
  CTableAB2CodeLength: array [0 .. 15] of Cardinal = (0, 5, 7, 3, 10, 4, 5, 6,
    7, 8, 9, 10, 11, 12, 13, 16);

  CTableAB2Factor: array [0 .. 15] of Single = (0, 1 / 2, 1 / 4, 1 / 4, 1 / 8,
    1 / 8, 1 / 16, 1 / 32, 1 / 64, 1 / 128, 1 / 256, 1 / 512, 1 / 1024,
    1 / 2048, 1 / 4096, 1 / 32768);

  CTableAB2C: array [0 .. 15] of Single = (0, 1.33333333333, 1.6, 1.14285714286,
    1.77777777777, 1.06666666666, 1.03225806452, 1.01587301587, 1.00787401575,
    1.00392156863, 1.00195694716, 1.00097751711, 1.00048851979, 1.00024420024,
    1.00012208522, 1.00001525902);

  CTableAB2D: array [0 .. 15] of Single = (0, 0.5, 0.5, 0.25, 0.5, 0.125,
    0.0625, 0.03125, 0.015625, 0.0078125, 0.00390625, 0.001953125, 0.0009765625,
    4.8828125E-4, 2.4414063E-4, 3.051758E-5);

  // subbands 11-22 in tables 3-B.2a and 2b:
  CTableAB3CodeLength: array [0 .. 7] of Cardinal = (0, 5, 7, 3, 10, 4, 5, 16);

  CTableAB3Factor: array [0 .. 7] of Single = (0, 1 / 2, 1 / 4, 1 / 4, 1 / 8,
    1 / 8, 1 / 16, 1 / 32768);

  CTableAB3C: array [0 .. 7] of Single = (0, 1.33333333333, 1.6, 1.14285714286,
    1.77777777777, 1.06666666666, 1.03225806452, 1.00001525902);

  CTableAB3D: array [0 .. 7] of Single = (0, 0.5, 0.5, 0.25, 0.5, 0.125, 0.0625,
    3.051758E-5);

  // subbands 23-... in tables 3-B.2a and 2b:
  CTableAB4CodeLength: array [0 .. 3] of Cardinal = (0, 5, 7, 16);

  CTableAB4Factor: array [0 .. 3] of Single = (0, 1 / 2, 1 / 4, 1 / 32768);

  CTableAB4C: array [0 .. 3] of Single = (0, 1.33333333333, 1.6, 1.00001525902);

  CTableAB4D: array [0 .. 3] of Single = (0, 0.5, 0.5, 3.051758E-5);

  // subbands in tables 3-B.2c and 2d:
  CTableCDCodeLength: array [0 .. 15] of Cardinal = (0, 5, 7, 10, 4, 5, 6, 7, 8,
    9, 10, 11, 12, 13, 14, 15);

  CTableCDGroupingTables: array [0 .. 15] of PIAP1024SingleArray = (nil,
    @CGrouping5Bits, @CGrouping7Bits, @CGrouping10Bits, nil, nil, nil, nil, nil,
    nil, nil, nil, nil, nil, nil, nil);

  CTableCDFactor: array [0 .. 15] of Single = (0, 1 / 2, 1 / 4, 1 / 8, 1 / 8,
    1 / 16, 1 / 32, 1 / 64, 1 / 128, 1 / 256, 1 / 512, 1 / 1024, 1 / 2048,
    1 / 4096, 1 / 8192, 1 / 16384);

  CTableCDC: array [0 .. 15] of Single = (0, 1.33333333333, 1.6, 1.77777777777,
    1.06666666666, 1.03225806452, 1.01587301587, 1.00787401575, 1.00392156863,
    1.00195694716, 1.00097751711, 1.00048851979, 1.00024420024, 1.00012208522,
    1.00006103888, 1.00003051851);

  CTableCDD: array [0 .. 15] of Single = (0, 0.5, 0.5, 0.5, 0.125, 0.0625,
    0.03125, 0.015625, 0.0078125, 0.00390625, 0.001953125, 0.0009765625,
    0.00048828125, 0.00024414063, 0.00012207031, 0.00006103516);

  CBufferSize = 4096;

  // Note: These values are not in the same order
  // as in Annex 3-B.3 of the ISO/IEC DIS 11172-3
  CAnnex3B3Table: array [0 .. 511] of Single = (0, -0.000442505, 0.003250122,
    -0.007003784, 0.031082153, -0.078628540, 0.100311279, -0.572036743,
    1.144989014, 0.572036743, 0.100311279, 0.078628540, 0.031082153,
    0.007003784, 0.003250122, 0.000442505, -0.000015259, -0.000473022,
    0.003326416, -0.007919312, 0.030517578, -0.084182739, 0.090927124,
    -0.600219727, 1.144287109, 0.543823242, 0.108856201, 0.073059082,
    0.031478882, 0.006118774, 0.003173828, 0.000396729, -0.000015259,
    -0.000534058, 0.003387451, -0.008865356, 0.029785156, -0.089706421,
    0.080688477, -0.628295898, 1.142211914, 0.515609741, 0.116577148,
    0.067520142, 0.031738281, 0.005294800, 0.003082275, 0.000366211,
    -0.000015259, -0.000579834, 0.003433228, -0.009841919, 0.028884888,
    -0.095169067, 0.069595337, -0.656219482, 1.138763428, 0.487472534,
    0.123474121, 0.061996460, 0.031845093, 0.004486084, 0.002990723,
    0.000320435, -0.000015259, -0.000625610, 0.003463745, -0.010848999,
    0.027801514, -0.100540161, 0.057617188, -0.683914185, 1.133926392,
    0.459472656, 0.129577637, 0.056533813, 0.031814575, 0.003723145,
    0.002899170, 0.000289917, -0.000015259, -0.000686646, 0.003479004,
    -0.011886597, 0.026535034, -0.105819702, 0.044784546, -0.711318970,
    1.127746582, 0.431655884, 0.134887695, 0.051132202, 0.031661987,
    0.003005981, 0.002792358, 0.000259399, -0.000015259, -0.000747681,
    0.003479004, -0.012939453, 0.025085449, -0.110946655, 0.031082153,
    -0.738372803, 1.120223999, 0.404083252, 0.139450073, 0.045837402,
    0.031387329, 0.002334595, 0.002685547, 0.000244141, -0.000030518,
    -0.000808716, 0.003463745, -0.014022827, 0.023422241, -0.115921021,
    0.016510010, -0.765029907, 1.111373901, 0.376800537, 0.143264771,
    0.040634155, 0.031005859, 0.001693726, 0.002578735, 0.000213623,
    -0.000030518, -0.000885010, 0.003417969, -0.015121460, 0.021575928,
    -0.120697021, 0.001068115, -0.791213989, 1.101211548, 0.349868774,
    0.146362305, 0.035552979, 0.030532837, 0.001098633, 0.002456665,
    0.000198364, -0.000030518, -0.000961304, 0.003372192, -0.016235352,
    0.019531250, -0.125259399, -0.015228271, -0.816864014, 1.089782715,
    0.323318481, 0.148773193, 0.030609131, 0.029937744, 0.000549316,
    0.002349854, 0.000167847, -0.000030518, -0.001037598, 0.003280640,
    -0.017349243, 0.017257690, -0.129562378, -0.032379150, -0.841949463,
    1.077117920, 0.297210693, 0.150497437, 0.025817871, 0.029281616,
    0.000030518, 0.002243042, 0.000152588, -0.000045776, -0.001113892,
    0.003173828, -0.018463135, 0.014801025, -0.133590698, -0.050354004,
    -0.866363525, 1.063217163, 0.271591187, 0.151596069, 0.021179199,
    0.028533936, -0.000442505, 0.002120972, 0.000137329, -0.000045776,
    -0.001205444, 0.003051758, -0.019577026, 0.012115479, -0.137298584,
    -0.069168091, -0.890090942, 1.048156738, 0.246505737, 0.152069092,
    0.016708374, 0.027725220, -0.000869751, 0.002014160, 0.000122070,
    -0.000061035, -0.001296997, 0.002883911, -0.020690918, 0.009231567,
    -0.140670776, -0.088775635, -0.913055420, 1.031936646, 0.221984863,
    0.151962280, 0.012420654, 0.026840210, -0.001266479, 0.001907349,
    0.000106812, -0.000061035, -0.001388550, 0.002700806, -0.021789551,
    0.006134033, -0.143676758, -0.109161377, -0.935195923, 1.014617920,
    0.198059082, 0.151306152, 0.008316040, 0.025909424, -0.001617432,
    0.001785278, 0.000106812, -0.000076294, -0.001480103, 0.002487183,
    -0.022857666, 0.002822876, -0.146255493, -0.130310059, -0.956481934,
    0.996246338, 0.174789429, 0.150115967, 0.004394531, 0.024932861,
    -0.001937866, 0.001693726, 0.000091553, -0.000076294, -0.001586914,
    0.002227783, -0.023910522, -0.000686646, -0.148422241, -0.152206421,
    -0.976852417, 0.976852417, 0.152206421, 0.148422241, 0.000686646,
    0.023910522, -0.002227783, 0.001586914, 0.000076294, -0.000091553,
    -0.001693726, 0.001937866, -0.024932861, -0.004394531, -0.150115967,
    -0.174789429, -0.996246338, 0.956481934, 0.130310059, 0.146255493,
    -0.002822876, 0.022857666, -0.002487183, 0.001480103, 0.000076294,
    -0.000106812, -0.001785278, 0.001617432, -0.025909424, -0.008316040,
    -0.151306152, -0.198059082, -1.014617920, 0.935195923, 0.109161377,
    0.143676758, -0.006134033, 0.021789551, -0.002700806, 0.001388550,
    0.000061035, -0.000106812, -0.001907349, 0.001266479, -0.026840210,
    -0.012420654, -0.151962280, -0.221984863, -1.031936646, 0.913055420,
    0.088775635, 0.140670776, -0.009231567, 0.020690918, -0.002883911,
    0.001296997, 0.000061035, -0.000122070, -0.002014160, 0.000869751,
    -0.027725220, -0.016708374, -0.152069092, -0.246505737, -1.048156738,
    0.890090942, 0.069168091, 0.137298584, -0.012115479, 0.019577026,
    -0.003051758, 0.001205444, 0.000045776, -0.000137329, -0.002120972,
    0.000442505, -0.028533936, -0.021179199, -0.151596069, -0.271591187,
    -1.063217163, 0.866363525, 0.050354004, 0.133590698, -0.014801025,
    0.018463135, -0.003173828, 0.001113892, 0.000045776, -0.000152588,
    -0.002243042, -0.000030518, -0.029281616, -0.025817871, -0.150497437,
    -0.297210693, -1.077117920, 0.841949463, 0.032379150, 0.129562378,
    -0.017257690, 0.017349243, -0.003280640, 0.001037598, 0.000030518,
    -0.000167847, -0.002349854, -0.000549316, -0.029937744, -0.030609131,
    -0.148773193, -0.323318481, -1.089782715, 0.816864014, 0.015228271,
    0.125259399, -0.019531250, 0.016235352, -0.003372192, 0.000961304,
    0.000030518, -0.000198364, -0.002456665, -0.001098633, -0.030532837,
    -0.035552979, -0.146362305, -0.349868774, -1.101211548, 0.791213989,
    -0.001068115, 0.120697021, -0.021575928, 0.015121460, -0.003417969,
    0.000885010, 0.000030518, -0.000213623, -0.002578735, -0.001693726,
    -0.031005859, -0.040634155, -0.143264771, -0.376800537, -1.111373901,
    0.765029907, -0.016510010, 0.115921021, -0.023422241, 0.014022827,
    -0.003463745, 0.000808716, 0.000030518, -0.000244141, -0.002685547,
    -0.002334595, -0.031387329, -0.045837402, -0.139450073, -0.404083252,
    -1.120223999, 0.738372803, -0.031082153, 0.110946655, -0.025085449,
    0.012939453, -0.003479004, 0.000747681, 0.000015259, -0.000259399,
    -0.002792358, -0.003005981, -0.031661987, -0.051132202, -0.134887695,
    -0.431655884, -1.127746582, 0.711318970, -0.044784546, 0.105819702,
    -0.026535034, 0.011886597, -0.003479004, 0.000686646, 0.000015259,
    -0.000289917, -0.002899170, -0.003723145, -0.031814575, -0.056533813,
    -0.129577637, -0.459472656, -1.133926392, 0.683914185, -0.057617188,
    0.100540161, -0.027801514, 0.010848999, -0.003463745, 0.000625610,
    0.000015259, -0.000320435, -0.002990723, -0.004486084, -0.031845093,
    -0.061996460, -0.123474121, -0.487472534, -1.138763428, 0.656219482,
    -0.069595337, 0.095169067, -0.028884888, 0.009841919, -0.003433228,
    0.000579834, 0.000015259, -0.000366211, -0.003082275, -0.005294800,
    -0.031738281, -0.067520142, -0.116577148, -0.515609741, -1.142211914,
    0.628295898, -0.080688477, 0.089706421, -0.029785156, 0.008865356,
    -0.003387451, 0.000534058, 0.000015259, -0.000396729, -0.003173828,
    -0.006118774, -0.031478882, -0.073059082, -0.108856201, -0.543823242,
    -1.144287109, 0.600219727, -0.090927124, 0.084182739, -0.030517578,
    0.007919312, -0.003326416, 0.000473022, 0.000015259);

  CWin: array[0..3, 0..35] of Single = (
    (-1.6141214951E-2, -5.3603178919E-2, -1.0070713296E-1, -1.6280817573E-1,
     -4.9999999679E-1, -3.8388735032E-1, -6.2061144372E-1, -1.1659756083E+0,
     -3.8720752656E+0, -4.2256286556E+0, -1.5195289984E+0, -9.7416483388E-1,
     -7.3744074053E-1, -1.2071067773E+0, -5.1636156596E-1, -4.5426052317E-1,
     -4.0715656898E-1, -3.6969460527E-1, -3.3876269197E-1, -3.1242222492E-1,
     -2.8939587111E-1, -2.6880081906E-1, -5.0000000266E-1, -2.3251417468E-1,
     -2.1596714708E-1, -2.0004979098E-1, -1.8449493497E-1, -1.6905846094E-1,
     -1.5350360518E-1, -1.3758624925E-1, -1.2103922149E-1, -2.0710679058E-1,
     -8.4752577594E-2, -6.4157525656E-2, -4.1131172614E-2, -1.4790705759E-2),

    (-1.6141214951E-2, -5.3603178919E-2, -1.0070713296E-1, -1.6280817573E-1,
     -4.9999999679E-1, -3.8388735032E-1, -6.2061144372E-1, -1.1659756083E+0,
     -3.8720752656E+0, -4.2256286556E+0, -1.5195289984E+0, -9.7416483388E-1,
     -7.3744074053E-1, -1.2071067773E+0, -5.1636156596E-1, -4.5426052317E-1,
     -4.0715656898E-1, -3.6969460527E-1, -3.3908542600E-1, -3.1511810350E-1,
     -2.9642226150E-1, -2.8184548650E-1, -5.4119610000E-1, -2.6213228100E-1,
     -2.5387916537E-1, -2.3296291359E-1, -1.9852728987E-1, -1.5233534808E-1,
     -9.6496400054E-2, -3.3423828516E-2,  0, 0, 0, 0, 0, 0),

    (-4.8300800645E-2, -1.5715656932E-1, -2.8325045177E-1, -4.2953747763E-1,
     -1.2071067795E+0, -8.2426483178E-1, -1.1451749106E+0, -1.7695290101E+0,
     -4.5470225061E+0, -3.4890531002E+0, -7.3296292804E-1, -1.5076514758E-1,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),

    ( 0, 0, 0, 0, 0, 0, -1.5076513660E-1, -7.3296291107E-1, -3.4890530566E+0,
     -4.5470224727E+0, -1.7695290031E+0, -1.1451749092E+0, -8.3137738100E-1,
     -1.3065629650E+0, -5.4142014250E-1, -4.6528974900E-1, -4.1066990750E-1,
     -3.7004680800E-1, -3.3876269197E-1, -3.1242222492E-1, -2.8939587111E-1,
     -2.6880081906E-1, -5.0000000266E-1, -2.3251417468E-1, -2.1596714708E-1,
     -2.0004979098E-1, -1.8449493497E-1, -1.6905846094E-1, -1.5350360518E-1,
     -1.3758624925E-1, -1.2103922149E-1, -2.0710679058E-1, -8.4752577594E-2,
     -6.4157525656E-2, -4.1131172614E-2, -1.4790705759E-2));

  // max. 1730 bytes per frame: 144 * 384kbit/s / 32000 Hz + 2 Bytes CRC
  CBufferIntSize = 433;

  CPolynomial: Word = $8005;

  COutputBufferSize = 1152; // max. 2 * 1152 samples per frame

var
  GScaleFactorBuffer: array [0 .. 53] of Cardinal;

  // array of all Huffman code Table headers
  // 0..31 Huffman code Table 0..31
  // 32, 33 count1 - tables
  GHuffmanCodeTable: array [0 .. CHuffmanCodeTableSize - 1]
    of THuffmanCodeTable;

  GCosTable: array [0 .. 30] of Single;

procedure InvMDCT(Input, Output: PIAP1024SingleArray; BlockType: Integer);
var
  Temp       : array[0..17] of Single;
  WinBt      : PIAP1024SingleArray;
  i, p       : integer;
  SixInc     : Integer;
  pp         : array [0..1] of Single;
  Sum, Save  : Single;
  TmpX       : array [0..8] of Single;
  Tmp        : array [0..8] of Single;
  i0, i0p12  : Single;
  i6_, e, o  : Single;
begin
 if (BlockType = 2) then
  begin
   p := 0;
   while (p < 36) do
    begin
     Output[p    ] := 0;
     Output[p + 1] := 0;
     Output[p + 2] := 0;
     Output[p + 3] := 0;
     Output[p + 4] := 0;
     Output[p + 5] := 0;
     Output[p + 6] := 0;
     Output[p + 7] := 0;
     Output[p + 8] := 0;
     Inc(p, 9);
    end;

   SixInc := 0;
   for i := 0 to 2 do
    begin
     // 12 point IMDCT
     // Begin 12 point IDCT
     // Input aliasing for 12 pt IDCT
     Input[15 + i] := Input[15 + i] + Input[12 + i];
     Input[12 + i] := Input[12 + i] + Input[ 9 + i];
     Input[ 9 + i] := Input[ 9 + i] + Input[ 6 + i];
     Input[ 6 + i] := Input[ 6 + i] + Input[ 3 + i];
     Input[ 3 + i] := Input[ 3 + i] + Input[     i];

     // Input aliasing on odd indices (for 6 point IDCT)
     Input[15+i] := Input[15+i] + Input[9+i];
     Input[9+i]  := Input[9+i]  + Input[3+i];

     // 3 point IDCT on even indices
     pp[1] := Input[12 + i] * 0.5;
     pp[0] := Input[ 6 + i] * 0.866025403;
     Sum := Input[i] + pp[1];
     Temp[1] := Input[i] - Input[12 + i];
     Temp[0] := Sum + pp[0];
     Temp[2] := Sum - pp[0];
     // End 3 point IDCT on even indices

     // 3 point IDCT on odd indices (for 6 point IDCT)
     pp[1] := Input[15 + i] * 0.5;
     pp[0] := Input[ 9 + i] * 0.866025403;
     Sum := Input[3 + i] + pp[1];
     Temp[4] := Input[3+i] - Input[15+i];
     Temp[5] := Sum + pp[0];
     Temp[3] := Sum - pp[0];
     // End 3 point IDCT on odd indices

     // Twiddle factors on odd indices (for 6 point IDCT)
     Temp[3] := Temp[3] * 1.931851653;
     Temp[4] := Temp[4] * 0.707106781;
     Temp[5] := Temp[5] * 0.517638090;

     // Output butterflies on 2 3 point IDCT's (for 6 point IDCT)
     Save := Temp[0];
     Temp[0] := Temp[0] + Temp[5];
     Temp[5] := Save - Temp[5];
     Save := Temp[1];
     Temp[1] := Temp[1] + Temp[4];
     Temp[4] := Save - Temp[4];
     Save := Temp[2];
     Temp[2] := Temp[2] + Temp[3];
     Temp[3] := Save - Temp[3];
     // End 6 point IDCT

     // Twiddle factors on indices (for 12 point IDCT)
     Temp[0] := Temp[0] * 0.504314480;
     Temp[1] := Temp[1] * 0.541196100;
     Temp[2] := Temp[2] * 0.630236207;
     Temp[3] := Temp[3] * 0.821339815;
     Temp[4] := Temp[4] * 1.306562965;
     Temp[5] := Temp[5] * 3.830648788;
     // End 12 point IDCT

     // Shift to 12 point modified IDCT, multiply by window type 2
     Temp[8]  := -Temp[0] * 0.793353340;
     Temp[9]  := -Temp[0] * 0.608761429;
     Temp[7]  := -Temp[1] * 0.923879532;
     Temp[10] := -Temp[1] * 0.382683432;
     Temp[6]  := -Temp[2] * 0.991444861;
     Temp[11] := -Temp[2] * 0.130526192;

     Temp[0]  :=  Temp[3];
     Temp[1]  :=  Temp[4] * 0.382683432;
     Temp[2]  :=  Temp[5] * 0.608761429;

     Temp[3]  := -Temp[5] * 0.793353340;
     Temp[4]  := -Temp[4] * 0.923879532;
     Temp[5]  := -Temp[0] * 0.991444861;

     Temp[0]  :=  Temp[0] * 0.130526192;

     Output[SixInc + 6]  := Output[SixInc + 6]  + Temp[0];
     Output[SixInc + 7]  := Output[SixInc + 7]  + Temp[1];
     Output[SixInc + 8]  := Output[SixInc + 8]  + Temp[2];
     Output[SixInc + 9]  := Output[SixInc + 9]  + Temp[3];
     Output[SixInc + 10] := Output[SixInc + 10] + Temp[4];
     Output[SixInc + 11] := Output[SixInc + 11] + Temp[5];
     Output[SixInc + 12] := Output[SixInc + 12] + Temp[6];
     Output[SixInc + 13] := Output[SixInc + 13] + Temp[7];
     Output[SixInc + 14] := Output[SixInc + 14] + Temp[8];
     Output[SixInc + 15] := Output[SixInc + 15] + Temp[9];
     Output[SixInc + 16] := Output[SixInc + 16] + Temp[10];
     Output[SixInc + 17] := Output[SixInc + 17] + Temp[11];

     Inc(SixInc, 6);
    end;
  end
 else
  begin
   // 36 point IDCT
   // Input aliasing for 36 point IDCT
   Input[17] := Input[17] + Input[16];
   Input[16] := Input[16] + Input[15];
   Input[15] := Input[15] + Input[14];
   Input[14] := Input[14] + Input[13];
   Input[13] := Input[13] + Input[12];
   Input[12] := Input[12] + Input[11];
   Input[11] := Input[11] + Input[10];
   Input[10] := Input[10] + Input[9];
   Input[9]  := Input[9]  + Input[8];
   Input[8]  := Input[8]  + Input[7];
   Input[7]  := Input[7]  + Input[6];
   Input[6]  := Input[6]  + Input[5];
   Input[5]  := Input[5]  + Input[4];
   Input[4]  := Input[4]  + Input[3];
   Input[3]  := Input[3]  + Input[2];
   Input[2]  := Input[2]  + Input[1];
   Input[1]  := Input[1]  + Input[0];
   // 18 point IDCT for odd indices

   // Input aliasing for 18 point IDCT
   Input[17] := Input[17] + Input[15];
   Input[15] := Input[15] + Input[13];
   Input[13] := Input[13] + Input[11];
   Input[11] := Input[11] + Input[9];
   Input[9]  := Input[9]  + Input[7];
   Input[7]  := Input[7]  + Input[5];
   Input[5]  := Input[5]  + Input[3];
   Input[3]  := Input[3]  + Input[1];

   // Fast 9 Point Inverse Discrete Cosine Transform
   //
   // By  Francois-Raymond Boyer
   //         mailto:boyerf@iro.umontreal.ca
   //         http://www.iro.umontreal.ca/~boyerf
   //
   // The code has been optimized for Intel processors
   //  (takes a lot of time to convert float to and from iternal FPU representation)
   //
   // It is a simple "factorization" of the IDCT matrix.

   // 9 point IDCT on even indices
   // 5 points on odd indices (not realy an IDCT)
   i0 := Input[0] + Input[0];
   i0p12 := i0 + Input[12];

   TmpX[0] := i0p12 + Input[4] * 1.8793852415718  + Input[8] * 1.532088886238 + Input[16] * 0.34729635533386;
   TmpX[1] := i0    + Input[4]                    - Input[8] - Input[12] - Input[12] - Input[16];
   TmpX[2] := i0p12 - Input[4] * 0.34729635533386 - Input[8] * 1.8793852415718  + Input[16] * 1.532088886238;
   TmpX[3] := i0p12 - Input[4] * 1.532088886238   + Input[8] * 0.34729635533386 - Input[16] * 1.8793852415718;
   TmpX[4] := Input[0] - Input[4]                 + Input[8] - Input[12]          + Input[16];

   // 4 points on even indices
   i6_ := Input[6] * 1.732050808;  // Sqrt[3]

   TmpX[5] := Input[2] * 1.9696155060244  + i6_ + Input[10] * 1.2855752193731  + Input[14] * 0.68404028665134;
   TmpX[6] := (Input[2]                        - Input[10]                   - Input[14]) * 1.732050808;
   TmpX[7] := Input[2] * 1.2855752193731  - i6_ - Input[10] * 0.68404028665134 + Input[14] * 1.9696155060244;
   TmpX[8] := Input[2] * 0.68404028665134 - i6_ + Input[10] * 1.9696155060244  - Input[14] * 1.2855752193731;

   // 9 point IDCT on odd indices
   // 5 points on odd indices (not realy an IDCT)
   i0 := Input[1] + Input[1];
   i0p12 := i0 + Input[13];

   Tmp[0] := i0p12   + Input[5] * 1.8793852415718  + Input[9] * 1.532088886238 + Input[17] * 0.34729635533386;
   Tmp[1] := i0      + Input[5]                    - Input[9] - Input[13] - Input[13] - Input[17];
   Tmp[2] := i0p12   - Input[5] * 0.34729635533386 - Input[9] * 1.8793852415718 + Input[17] * 1.532088886238;
   Tmp[3] := i0p12   - Input[5] * 1.532088886238   + Input[9] * 0.34729635533386 - Input[17] * 1.8793852415718;
   Tmp[4] := (Input[1] - Input[5] + Input[9] - Input[13] + Input[17]) * 0.707106781;  // Twiddled

   // 4 points on even indices
   i6_ := Input[7] * 1.732050808;  // Sqrt[3]

   Tmp[5] := Input[3] * 1.9696155060244 + i6_ + Input[11] * 1.2855752193731  + Input[15] * 0.68404028665134;
   Tmp[6] := (Input[3]                        - Input[11]                   - Input[15]) * 1.732050808;
   Tmp[7] := Input[3] * 1.2855752193731 - i6_ - Input[11] * 0.68404028665134 + Input[15] * 1.9696155060244;
   Tmp[8] := Input[3] * 0.68404028665134 - i6_ + Input[11] * 1.9696155060244  - Input[15] * 1.2855752193731;

   // Twiddle factors on odd indices
   // and
   // Butterflies on 9 point IDCT's
   // and
   // twiddle factors for 36 point IDCT

   e := TmpX[0] + TmpX[5];
   o := (Tmp[0] + Tmp[5]) * 0.501909918;
   Temp[0] := e + o;
   Temp[17] := e - o;
   e := TmpX[1] + TmpX[6];
   o := (Tmp[1] + Tmp[6]) * 0.517638090;
   Temp[1] := e + o;
   Temp[16] := e - o;
   e := TmpX[2] + TmpX[7];
   o := (Tmp[2] + Tmp[7]) * 0.551688959;
   Temp[2] := e + o;
   Temp[15] := e - o;
   e := TmpX[3] + TmpX[8];
   o := (Tmp[3] + Tmp[8]) * 0.610387294;
   Temp[3] := e + o;
   Temp[14] := e - o;
   Temp[4] := TmpX[4] + Tmp[4];
   Temp[13] := TmpX[4] - Tmp[4];
   e := TmpX[3] - TmpX[8];
   o := (Tmp[3] - Tmp[8]) * 0.871723397;
   Temp[5] := e + o;
   Temp[12] := e - o;
   e := TmpX[2] - TmpX[7];
   o := (Tmp[2] - Tmp[7]) * 1.183100792;
   Temp[6] := e + o;
   Temp[11] := e - o;
   e := TmpX[1] - TmpX[6];
   o := (Tmp[1] - Tmp[6]) * 1.931851653;
   Temp[7] := e + o;
   Temp[10] := e - o;
   e := TmpX[0] - TmpX[5];
   o := (Tmp[0] - Tmp[5]) * 5.736856623;
   Temp[8] := e + o;
   Temp[9] := e - o;

   // end 36 point IDCT */

   // shift to modified IDCT
   WinBt := @CWin[BlockType];

   Output[0]  := -Temp[9]  * WinBt[0];
   Output[1]  := -Temp[10] * WinBt[1];
   Output[2]  := -Temp[11] * WinBt[2];
   Output[3]  := -Temp[12] * WinBt[3];
   Output[4]  := -Temp[13] * WinBt[4];
   Output[5]  := -Temp[14] * WinBt[5];
   Output[6]  := -Temp[15] * WinBt[6];
   Output[7]  := -Temp[16] * WinBt[7];
   Output[8]  := -Temp[17] * WinBt[8];

   Output[9]  :=  Temp[17] * WinBt[9];
   Output[10] :=  Temp[16] * WinBt[10];
   Output[11] :=  Temp[15] * WinBt[11];
   Output[12] :=  Temp[14] * WinBt[12];
   Output[13] :=  Temp[13] * WinBt[13];
   Output[14] :=  Temp[12] * WinBt[14];
   Output[15] :=  Temp[11] * WinBt[15];
   Output[16] :=  Temp[10] * WinBt[16];
   Output[17] :=  Temp[9]  * WinBt[17];
   Output[18] :=  Temp[8]  * WinBt[18];
   Output[19] :=  Temp[7]  * WinBt[19];
   Output[20] :=  Temp[6]  * WinBt[20];
   Output[21] :=  Temp[5]  * WinBt[21];
   Output[22] :=  Temp[4]  * WinBt[22];
   Output[23] :=  Temp[3]  * WinBt[23];
   Output[24] :=  Temp[2]  * WinBt[24];
   Output[25] :=  Temp[1]  * WinBt[25];
   Output[26] :=  Temp[0]  * WinBt[26];

   Output[27] :=  Temp[0]  * WinBt[27];
   Output[28] :=  Temp[1]  * WinBt[28];
   Output[29] :=  Temp[2]  * WinBt[29];
   Output[30] :=  Temp[3]  * WinBt[30];
   Output[31] :=  Temp[4]  * WinBt[31];
   Output[32] :=  Temp[5]  * WinBt[32];
   Output[33] :=  Temp[6]  * WinBt[33];
   Output[34] :=  Temp[7]  * WinBt[34];
   Output[35] :=  Temp[8]  * WinBt[35];
  end;
end;

function SwapInt32(Value: Cardinal): Cardinal; inline;
begin
  Result := (Value shl 24) or ((Value shl 8) and $FF0000) or
    ((Value shr 8) and $FF00) or (Value shr 24);
end;

// do the huffman-decoding
// note! for counta, countb - the 4 bit value is returned in y, discard x
function HuffmanDecoder(HuffmanCodeTable: PHuffmanCodeTable;
  var x, y, v, w: Integer; BitReverse: TBitReserve): Integer;
var
  Level: THuffBits;
  Point: Cardinal;
begin
  Point := 0;
  Result := 1; // error code
  Level := CDMask;

  if (HuffmanCodeTable.Val = nil) then
  begin
    Result := 2;
    Exit;
  end;

  // Table 0 needs no bits
  if (HuffmanCodeTable.TreeLength = 0) then
  begin
    x := 0;
    y := 0;
    Result := 0;
    Exit;
  end;

  // Lookup in Huffman Table.
  repeat
    if (HuffmanCodeTable.Val[Point, 0] = 0) then
    begin // end of tree
      x := HuffmanCodeTable.Val[Point, 1] shr 4;
      y := HuffmanCodeTable.Val[Point, 1] and $F;

      Result := 0;
      Break;
    end;

    if (BitReverse.Get1Bit <> 0) then
    begin
      while (HuffmanCodeTable.Val[Point, 1] >= CMaxOff) do
        Point := Point + HuffmanCodeTable.Val[Point, 1];
      Point := Point + HuffmanCodeTable.Val[Point, 1];
    end
    else
    begin
      while (HuffmanCodeTable.Val[Point, 0] >= CMaxOff) do
        Point := Point + HuffmanCodeTable.Val[Point, 0];
      Point := Point + HuffmanCodeTable.Val[Point, 0];
    end;

    Level := Level shr 1;
  until not((Level <> 0) or (Point < PHuffmanCodeTable(@GHuffmanCodeTable)
    .TreeLength));

  // Process sign encodings for quadruples tables.
  if (HuffmanCodeTable.TableName[0] = '3') and
    ((HuffmanCodeTable.TableName[1] = '2') or
    (HuffmanCodeTable.TableName[1] = '3')) then
  begin
    v := (y shr 3) and 1;
    w := (y shr 2) and 1;
    x := (y shr 1) and 1;
    y := y and 1;

    // v, w, x and y are reversed in the bitstream.
    // switch them around to make test bistream work.

    if (v <> 0) then
      if (BitReverse.Get1Bit <> 0) then
        v := -v;

    if (w <> 0) then
      if (BitReverse.Get1Bit <> 0) then
        w := -w;

    if (x <> 0) then
      if (BitReverse.Get1Bit <> 0) then
        x := -x;

    if (y <> 0) then
      if (BitReverse.Get1Bit <> 0) then
        y := -y;
  end
  else
  begin
    // Process sign and escape encodings for dual tables.

    // x and y are reversed in the test bitstream.
    // Reverse x and y here to make test bitstream work.

    if (HuffmanCodeTable.LinBits <> 0) then
      if (Integer(HuffmanCodeTable.XLength - 1) = x) then
        x := x + Integer(BitReverse.GetBits(HuffmanCodeTable.LinBits));

    if (x <> 0) then
      if (BitReverse.Get1Bit <> 0) then
        x := -x;

    if (HuffmanCodeTable.LinBits <> 0) then
      if (Integer(HuffmanCodeTable.YLength - 1) = y) then
        y := y + Integer(BitReverse.GetBits(HuffmanCodeTable.LinBits));

    if (y <> 0) then
      if (BitReverse.Get1Bit <> 0) then
        y := -y;
  end;
end;

procedure SetHuffTable(GHuffmanCodeTable: PHuffmanCodeTable; Name: PAnsiChar;
  XLength, YLength, LinBits, LinMax, Ref: Integer; Table: PHuffBits;
  HLength: PAnsiChar; Val: PPHTArray; TreeLength: Cardinal);
begin
  StrLCopy(GHuffmanCodeTable.TableName, Name,
    SizeOf(GHuffmanCodeTable.TableName));
  GHuffmanCodeTable.XLength := XLength;
  GHuffmanCodeTable.YLength := YLength;
  GHuffmanCodeTable.LinBits := LinBits;
  GHuffmanCodeTable.LinMax := LinMax;
  GHuffmanCodeTable.Ref := Ref;
  GHuffmanCodeTable.Table := Table;
  GHuffmanCodeTable.HLength := HLength;
  GHuffmanCodeTable.Val := Val;
  GHuffmanCodeTable.TreeLength := TreeLength;
end;


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

{ TBitReserve }

constructor TBitReserve.Create;
var
  ShiftedOne, Bit: Cardinal;
begin
  inherited Create;

  ShiftedOne := 1;
  FOffset := 0;
  FTotalBits := 0;
  FBufByteIdx := 0;
  GetMem(FBuffer, CBufferSize * SizeOf(Cardinal));
  FBufBitIdx := 8;
  GetMem(FPutMask, 32 * SizeOf(Cardinal));

  FPutMask[0] := 0;
  for Bit := 1 to 31 do
  begin
    FPutMask[Bit] := FPutMask[Bit - 1] + ShiftedOne;
    ShiftedOne := ShiftedOne shl 1;
  end;
end;

destructor TBitReserve.Destroy;
begin
  Dispose(FPutMask);
  Dispose(FBuffer);
  inherited Destroy;
end;

// read 1 bit from the bit stream
function TBitReserve.Get1Bit: Cardinal;
begin
  Inc(FTotalBits);
  if (FBufBitIdx = 0) then
  begin
    FBufBitIdx := 8;
    Inc(FBufByteIdx);
  end;

  // CBufferSize = 4096 = 2^12, so
  // FBufByteIdx mod CBufferSize = FBufByteIdx and $FFF
  Result := FBuffer[FBufByteIdx and $FFF] and FPutMask[FBufBitIdx];
  Dec(FBufBitIdx);
  Result := Result shr FBufBitIdx;
end;

// read Bits bits from the bit stream
function TBitReserve.GetBits(Bits: Cardinal): Cardinal;
var
  Bit: Cardinal;
  k, Temp: Cardinal;
begin
  Result := 0;
  if Bits = 0 then
    Exit;

  Inc(FTotalBits, Bits);
  Bit := Bits;

  while (Bit > 0) do
  begin
    if (FBufBitIdx = 0) then
    begin
      FBufBitIdx := 8;
      Inc(FBufByteIdx);
    end;

    if (Bit < FBufBitIdx) then
      k := Bit
    else
      k := FBufBitIdx;

    // CBufferSize = 4096 = 2^12, so
    // FBufByteIdx mod CBufferSize = FBufByteIdx and $FFF
    Temp := FBuffer[FBufByteIdx and $FFF] and FPutMask[FBufBitIdx];
    Dec(FBufBitIdx, k);
    Temp := Temp shr FBufBitIdx;
    Dec(Bit, k);
    Result := Result or (Temp shl Bit);
  end;
end;

// write 8 bits into the bit stream
procedure TBitReserve.WriteToBitstream(Value: Cardinal);
begin
  FBuffer[FOffset] := Value;
  FOffset := (FOffset + 1) and $FFF;
end;

procedure TBitReserve.RewindBits(Bits: Cardinal);
begin
  Dec(FTotalBits, Bits);
  Inc(FBufBitIdx, Bits);

  while (FBufBitIdx >= 8) do
  begin
    Dec(FBufBitIdx, 8);
    Dec(FBufByteIdx);
  end;
end;

procedure TBitReserve.RewindBytes(Bytes: Cardinal);
begin
  Dec(FTotalBits, (Bytes shl 3));
  Dec(FBufByteIdx, Bytes);
end;


{ TBitStream }

constructor TBitStream.Create(Stream: TStream);
begin
  // assign stream
  FStream := Stream;
  FOwnedStream := False;

  // allocate buffer memory
  GetMem(FBuffer, CBufferIntSize * SizeOf(Cardinal));

  // reset frame position
  Reset;

  // Seeking variables
  FLastFrameNumber := -1;
  FNonSeekable := False;
end;

constructor TBitStream.Create(FileName: TFileName);
begin
  Create(TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone));
  FOwnedStream := True;
end;

destructor TBitStream.Destroy;
begin
  Dispose(FBuffer);
  if FOwnedStream then
    FreeAndNil(FStream);
  inherited Destroy;
end;

function TBitStream.StreamSize: Cardinal;
begin
  Result := FStream.Size;
end;

function TBitStream.GetBits(NumberOfBits: Cardinal): Cardinal;
var
  ReturnValue: Cardinal;
  Sum: Cardinal;
begin
  Sum := FBitIndex + NumberOfBits;

  if (Sum <= 32) then
  begin
    // all bits contained in *wordpointer
    Result := (FWordPointer^[0] shr (32 - Sum)) and CBitMask[NumberOfBits];
    Inc(FBitIndex, NumberOfBits);
    if (FBitIndex = 32) then
    begin
      FBitIndex := 0;
      Inc(FWordPointer);
    end;
    Exit;
  end;

  PWord(@PByteArray(@ReturnValue)[2])^ := PWord(FWordPointer)^;
  Inc(FWordPointer);
  PWord(@ReturnValue)^ := PWord(@PByteArray(FWordPointer)[2])^;

  ReturnValue := ReturnValue shr (48 - Sum);
  Result := ReturnValue and CBitMask[NumberOfBits];
  FBitIndex := Sum - 32;
end;

function TBitStream.GetBitsFloat(NumberOfBits: Cardinal): Single;
begin
  PCardinal(@Result)^ := GetBits(NumberOfBits);
end;

function TBitStream.GetHeader(var HeaderString: Cardinal;
  SyncMode: TSyncMode): Boolean;
var
  Sync: Boolean;
  NumRead: Integer;
begin
  repeat
    // Read 4 bytes from the file, placing the number of bytes actually read in numread
    NumRead := FStream.Read(HeaderString, 4);
    Result := (NumRead = 4);
    if not Result then
      Exit;

    if (SyncMode = smInitialSync) then
      Sync := ((HeaderString and $0000F0FF) = $0000F0FF)
    else
      Sync := ((HeaderString and $000CF8FF) = FSyncWord) and
        (((HeaderString and $C0000000) = $C0000000) = FSingleChMode);

    // if ((HeaderString and $0000FFFF) = $0000FFFF) then Sync := False;

    if not Sync then
      FStream.Seek(-3, soFromCurrent);
    // rewind 3 bytes in the file so we can try to sync again, if successful set Result to True
  until Sync or (not Result);

  if not Result then
    Exit;

  HeaderString := SwapInt32(HeaderString);

  Inc(FCurrentFrameNumber);

{$IFDEF SEEK_STOP}
  if (FLastFrameNumber < FCurrentFrameNumber) then
    FLastFrameNumber := FCurrentFrameNumber;
{$ENDIF}
  Result := True;
end;

function TBitStream.ReadFrame(ByteSize: Cardinal): Boolean;
var
  NumRead: Integer;
  WordP: PCardinal;
begin
  // read bytesize bytes from the file, placing the number of bytes
  // actually read in numread and setting Result to True if
  // successful
  NumRead := FStream.Read(FBuffer^, ByteSize);

  FWordPointer := FBuffer;
  FBitIndex := 0;
  FFrameSize := ByteSize;

  WordP := @FBuffer^[(ByteSize - 1) shr 2];
  while Cardinal(WordP) >= Cardinal(FBuffer) do
  begin
    WordP^ := SwapInt32(WordP^);
    Dec(WordP);
  end;

  Result := Cardinal(NumRead) = FFrameSize;
end;

procedure TBitStream.Reset;
begin
  FStream.Seek(0, soFromBeginning);
  FWordPointer := FBuffer;
  FCurrentFrameNumber := -1;
  FBitIndex := 0;
end;

function TBitStream.Seek(Frame, FrameSize: Integer): Boolean;
begin
  FCurrentFrameNumber := Frame - 1;
  if FNonSeekable then
    Exit(False);

  FStream.Seek(Frame * (FrameSize + 4), soFromBeginning);
  Result := True;
end;

function TBitStream.SeekPad(Frame, FrameSize: Integer; var Header: THeader;
  Offset: PCardinalArray): Boolean;
var
  CRC: TCRC16;
  TotalFrameSize: Integer;
  Diff: Integer;
begin
  // base_frame_size is the frame size _without_ padding.
  if FNonSeekable then
    Exit(False);

  CRC := nil;

  TotalFrameSize := FrameSize + 4;

  if (FLastFrameNumber < Frame) then
  begin
    if (FLastFrameNumber >= 0) then
      Diff := Offset[FLastFrameNumber]
    else
      Diff := 0;

    // set the file pointer to ((LastFrameNumber + 1) * TotalFrameSize)
    // bytes after the beginning of the file
    FStream.Seek((FLastFrameNumber + 1) * TotalFrameSize + Diff,
      soFromBeginning);
    FCurrentFrameNumber := FLastFrameNumber;

    repeat
      if (not THeader(Header).ReadHeader(Self, CRC)) then
        Exit(False);
    until (FLastFrameNumber >= Frame);

    Result := True;
  end
  else
  begin
    if (Frame > 0) then
      Diff := Offset[Frame - 1]
    else
      Diff := 0;

    // set the file pointer to (frame * total_frame_size  + diff) bytes
    // after the beginning of the file
    FStream.Seek(Frame * TotalFrameSize + Diff, soFromBeginning);
    FCurrentFrameNumber := Frame - 1;
    Result := THeader(Header).ReadHeader(Self, CRC);
  end;

  if Assigned(CRC) then
    FreeAndNil(CRC);
end;

procedure TBitStream.SetSyncWord(SyncWord: Cardinal);
begin
  FSyncWord := SwapInt32(SyncWord and $FFFFFF3F);

  FSingleChMode := ((SyncWord and $000000C0) = $000000C0);
end;

{ THeader }

constructor THeader.Create;
begin
  FFrameSize := 0;
  FNumSlots := 0;
  FCRC := nil;
  FOffset := nil;
  FInitialSync := False;
end;

destructor THeader.Destroy;
begin
  if Assigned(FOffset) then
    Dispose(FOffset);
  inherited;
end;

function THeader.Bitrate: Cardinal;
begin
  Result := CBitrates[FVersion, FLayer - 1, FBitrateIndex];
end;

// calculates framesize in bytes excluding header size
function THeader.CalculateFrameSize: Cardinal;
var
  Value: array [0 .. 1] of Cardinal;
begin
  if (FLayer = 1) then
  begin
    FFrameSize := (12 * CBitrates[FVersion, 0, FBitrateIndex]) div CFrequencies
      [FVersion, FSampleFrequency];
    if (FPaddingBit <> 0) then
      Inc(FFrameSize);
    FFrameSize := FFrameSize shl 2; // one slot is 4 bytes long
    FNumSlots := 0;
  end
  else
  begin
    FFrameSize := (144 * CBitrates[FVersion, FLayer - 1, FBitrateIndex])
      div CFrequencies[FVersion, FSampleFrequency];
    if (FVersion = mv2lsf) then
      FFrameSize := FFrameSize shr 1;
    if (FPaddingBit <> 0) then
      Inc(FFrameSize);

    // Layer III slots
    if (FLayer = 3) then
    begin
      if (FVersion = mv1) then
      begin
        if (FMode = cmSingleChannel) then
          Value[0] := 17
        else
          Value[0] := 32;
        if (FProtectionBit <> 0) then
          Value[1] := 0
        else
          Value[1] := 2;
        FNumSlots := FFrameSize - Value[0] - Value[1] - 4; // header size
      end
      else
      begin // MPEG-2 LSF
        if (FMode = cmSingleChannel) then
          Value[0] := 9
        else
          Value[0] := 17;
        if (FProtectionBit <> 0) then
          Value[1] := 0
        else
          Value[1] := 2;
        FNumSlots := FFrameSize - Value[0] - Value[1] - 4; // header size
      end;
    end
    else
      FNumSlots := 0;
  end;

  Dec(FFrameSize, 4); // subtract header size
  Result := FFrameSize;
end;

function THeader.GetChecksumOK: Boolean;
begin
  Result := (FChecksum = FCRC.Checksum);
end;

function THeader.GetChecksums: Boolean;
begin
  Result := (FProtectionBit = 0);
end;

function THeader.GetFrequency: Cardinal;
begin
  Result := CFrequencies[FVersion, FSampleFrequency];
end;

function THeader.GetPadding: Boolean;
begin
  Result := (FPaddingBit <> 0);
end;

// Returns the maximum number of frames in the stream
function THeader.MaxNumberOfFrames(Stream: TBitStream): Integer;
begin
  Result := Stream.StreamSize div (FFrameSize + 4 - FPaddingBit);
end;

// Returns the minimum number of frames in the stream
function THeader.MinNumberOfFrames(Stream: TBitStream): Integer;
begin
  Result := Stream.StreamSize div (FFrameSize + 5 - FPaddingBit);
end;

function THeader.MSPerFrame: Single;
begin
  Result := CmsPerFrameArray[FLayer - 1, FSampleFrequency];
end;

function THeader.ReadHeader(Stream: TBitStream; var CRC: TCRC16): Boolean;
var
  HeaderString: Cardinal;
  ChannelBitrate: Cardinal;
  Max, Cf, Lf: Integer;
begin
  Result := False;
  if not FInitialSync then
  begin
    if (not Stream.GetHeader(HeaderString, smInitialSync)) then
      Exit;
    FVersion := TMpegVersion((HeaderString shr 19) and 1);
    FSampleFrequency := TSampleRates((HeaderString shr 10) and 3);
    if (FSampleFrequency = srUnknown) then
      raise Exception.Create('Header not supported');
    Stream.SyncWord := (HeaderString and $FFF80CC0);
    FInitialSync := True;
  end
  else if (not Stream.GetHeader(HeaderString, imStrictSync)) then
    Exit;

  FLayer := 4 - (HeaderString shr 17) and 3;
  FProtectionBit := (HeaderString shr 16) and 1;
  FBitrateIndex := (HeaderString shr 12) and $F;
  FPaddingBit := (HeaderString shr 9) and 1;
  FMode := TChannelMode((HeaderString shr 6) and 3);
  FModeExtension := (HeaderString shr 4) and 3;

  if (FMode = cmJointStereo) then
    FIntensityStereoBound := (FModeExtension shl 2) + 4
  else
    FIntensityStereoBound := 0; // should never be used

  FCopyright := ((HeaderString shr 3) and 1 <> 0);
  FOriginal := ((HeaderString shr 2) and 1 <> 0);

  // calculate number of subbands:
  if FLayer = 1 then
    FNumberOfSubbands := 32
  else
  begin
    ChannelBitrate := FBitrateIndex;
    // calculate bitrate per channel:
    if (FMode <> cmSingleChannel) then
      if (ChannelBitrate = 4) then
        ChannelBitrate := 1
      else
        Dec(ChannelBitrate, 4);
    if ((ChannelBitrate = 1) or (ChannelBitrate = 2)) then
    begin
      if (FSampleFrequency = sr32k) then
        FNumberOfSubbands := 12
      else
        FNumberOfSubbands := 8;
    end
    else if ((FSampleFrequency = sr48k) or ((ChannelBitrate >= 3) and
      (ChannelBitrate <= 5))) then
      FNumberOfSubbands := 27
    else
      FNumberOfSubbands := 30;
  end;

  if (FIntensityStereoBound > FNumberOfSubbands) then
    FIntensityStereoBound := FNumberOfSubbands;

  CalculateFrameSize; // calculate framesize and NumSlots

  // read framedata:
  if (not Stream.ReadFrame(FFrameSize)) then
    raise Exception.Create('Frame read error!');

  if (FProtectionBit = 0) then
  begin
    // frame contains a crc checksum
    FChecksum := Stream.GetBits(16);
    if (FCRC = nil) then
      FCRC := TCRC16.Create;
    FCRC.AddBits(HeaderString, 16);
    CRC := FCRC;
  end
  else
    CRC := nil;

{$IFDEF SEEK_STOP}
  if (FSampleFrequency = sr44k1) then
  begin
    if (FOffset = nil) then
    begin
      Max := MaxNumberOfFrames(Stream);
      GetMem(FOffset, Max * SizeOf(Cardinal));
      FillChar(FOffset^, Max * SizeOf(Cardinal), 0);
    end;
    Cf := Stream.CurrentFrame;
    Lf := Stream.LastFrame;
    if ((Cf > 0) and (Cf = Lf)) then
      FOffset[Cf] := FOffset[Cf - 1] + FPaddingBit
    else
      FOffset[0] := FPaddingBit;
  end;
{$ENDIF}
  Result := True;
end;

// Stream searching routines
function THeader.StreamSeek(Stream: TBitStream; SeekPos: Cardinal): Boolean;
begin
  if (FSampleFrequency = sr44k1) then
    Result := Stream.SeekPad(SeekPos, FFrameSize - FPaddingBit, Self, FOffset)
  else
    Result := Stream.Seek(SeekPos, FFrameSize);
end;

function THeader.TotalMS(Stream: TBitStream): Single;
begin
  Result := MaxNumberOfFrames(Stream) * MSPerFrame;
end;

{ TSynthesisFilter }

constructor TSynthesisFilter.Create;
begin
  Reset;
end;

procedure TSynthesisFilter.CalculatePCMSamples;
begin
  ComputeNewVector;
  ComputePCMSample;
  FActualWritePos := (FActualWritePos + 1) and $F;
  if (FActualVector = @FVector[0]) then
    FActualVector := @FVector[1]
  else
    FActualVector := @FVector[0];
  FillChar(FSample, Sizeof(FSample), 0);
end;

procedure TSynthesisFilter.ComputeNewVector;
var
  NewVec: array [0 .. 31] of Single;
  // new V[0-15] and V[33-48] of Figure 3-A.2 in ISO DIS 11172-3
  p: array [0 .. 15] of Single;
  pp: array [0 .. 15] of Single;
  x: array [0 .. 1] of PIAP512SingleArray;
  tmp: array [0 .. 1] of Single;
begin
  // compute new values via a fast cosine transform:
  x[0] := @FSample;

  p[0] := x[0, 0] + x[0, 31];
  p[1] := x[0, 1] + x[0, 30];
  p[2] := x[0, 2] + x[0, 29];
  p[3] := x[0, 3] + x[0, 28];
  p[4] := x[0, 4] + x[0, 27];
  p[5] := x[0, 5] + x[0, 26];
  p[6] := x[0, 6] + x[0, 25];
  p[7] := x[0, 7] + x[0, 24];
  p[8] := x[0, 8] + x[0, 23];
  p[9] := x[0, 9] + x[0, 22];
  p[10] := x[0, 10] + x[0, 21];
  p[11] := x[0, 11] + x[0, 20];
  p[12] := x[0, 12] + x[0, 19];
  p[13] := x[0, 13] + x[0, 18];
  p[14] := x[0, 14] + x[0, 17];
  p[15] := x[0, 15] + x[0, 16];

  pp[0] := p[0] + p[15];
  pp[1] := p[1] + p[14];
  pp[2] := p[2] + p[13];
  pp[3] := p[3] + p[12];
  pp[4] := p[4] + p[11];
  pp[5] := p[5] + p[10];
  pp[6] := p[6] + p[9];
  pp[7] := p[7] + p[8];
  pp[8] := (p[0] - p[15]) * GCosTable[14];
  pp[9] := (p[1] - p[14]) * GCosTable[13];
  pp[10] := (p[2] - p[13]) * GCosTable[12];
  pp[11] := (p[3] - p[12]) * GCosTable[11];
  pp[12] := (p[4] - p[11]) * GCosTable[10];
  pp[13] := (p[5] - p[10]) * GCosTable[9];
  pp[14] := (p[6] - p[9]) * GCosTable[8];
  pp[15] := (p[7] - p[8]) * GCosTable[7];

  p[0] := pp[0] + pp[7];
  p[1] := pp[1] + pp[6];
  p[2] := pp[2] + pp[5];
  p[3] := pp[3] + pp[4];
  p[4] := (pp[0] - pp[7]) * GCosTable[6];
  p[5] := (pp[1] - pp[6]) * GCosTable[5];
  p[6] := (pp[2] - pp[5]) * GCosTable[4];
  p[7] := (pp[3] - pp[4]) * GCosTable[3];
  p[8] := pp[8] + pp[15];
  p[9] := pp[9] + pp[14];
  p[10] := pp[10] + pp[13];
  p[11] := pp[11] + pp[12];
  p[12] := (pp[8] - pp[15]) * GCosTable[6];
  p[13] := (pp[9] - pp[14]) * GCosTable[5];
  p[14] := (pp[10] - pp[13]) * GCosTable[4];
  p[15] := (pp[11] - pp[12]) * GCosTable[3];

  pp[0] := p[0] + p[3];
  pp[1] := p[1] + p[2];
  pp[2] := (p[0] - p[3]) * GCosTable[2];
  pp[3] := (p[1] - p[2]) * GCosTable[1];
  pp[4] := p[4] + p[7];
  pp[5] := p[5] + p[6];
  pp[6] := (p[4] - p[7]) * GCosTable[2];
  pp[7] := (p[5] - p[6]) * GCosTable[1];
  pp[8] := p[8] + p[11];
  pp[9] := p[9] + p[10];
  pp[10] := (p[8] - p[11]) * GCosTable[2];
  pp[11] := (p[9] - p[10]) * GCosTable[1];
  pp[12] := p[12] + p[15];
  pp[13] := p[13] + p[14];
  pp[14] := (p[12] - p[15]) * GCosTable[2];
  pp[15] := (p[13] - p[14]) * GCosTable[1];

  p[0] := pp[0] + pp[1];
  p[1] := (pp[0] - pp[1]) * GCosTable[0];
  p[2] := pp[2] + pp[3];
  p[3] := (pp[2] - pp[3]) * GCosTable[0];
  p[4] := pp[4] + pp[5];
  p[5] := (pp[4] - pp[5]) * GCosTable[0];
  p[6] := pp[6] + pp[7];
  p[7] := (pp[6] - pp[7]) * GCosTable[0];
  p[8] := pp[8] + pp[9];
  p[9] := (pp[8] - pp[9]) * GCosTable[0];
  p[10] := pp[10] + pp[11];
  p[11] := (pp[10] - pp[11]) * GCosTable[0];
  p[12] := pp[12] + pp[13];
  p[13] := (pp[12] - pp[13]) * GCosTable[0];
  p[14] := pp[14] + pp[15];
  p[15] := (pp[14] - pp[15]) * GCosTable[0];

  NewVec[12] := p[7];
  NewVec[4] := NewVec[12] + p[5];
  NewVec[19] := -NewVec[4] - p[6];
  NewVec[27] := -p[6] - p[7] - p[4];
  NewVec[14] := p[15];
  NewVec[10] := NewVec[14] + p[11];
  NewVec[6] := NewVec[10] + p[13];
  NewVec[2] := p[15] + p[13] + p[9];
  NewVec[17] := -NewVec[2] - p[14];
  tmp[0] := -p[14] - p[15] - p[10] - p[11];
  NewVec[21] := tmp[0] - p[13];
  NewVec[29] := -p[14] - p[15] - p[12] - p[8];
  NewVec[25] := tmp[0] - p[12];
  NewVec[31] := -p[0];
  NewVec[0] := p[1];
  NewVec[8] := p[3];
  NewVec[23] := -NewVec[8] - p[2];

  p[0] := (x[0, 0] - x[0, 31]) * GCosTable[30];
  p[1] := (x[0, 1] - x[0, 30]) * GCosTable[29];
  p[2] := (x[0, 2] - x[0, 29]) * GCosTable[28];
  p[3] := (x[0, 3] - x[0, 28]) * GCosTable[27];
  p[4] := (x[0, 4] - x[0, 27]) * GCosTable[26];
  p[5] := (x[0, 5] - x[0, 26]) * GCosTable[25];
  p[6] := (x[0, 6] - x[0, 25]) * GCosTable[24];
  p[7] := (x[0, 7] - x[0, 24]) * GCosTable[23];
  p[8] := (x[0, 8] - x[0, 23]) * GCosTable[22];
  p[9] := (x[0, 9] - x[0, 22]) * GCosTable[21];
  p[10] := (x[0, 10] - x[0, 21]) * GCosTable[20];
  p[11] := (x[0, 11] - x[0, 20]) * GCosTable[19];
  p[12] := (x[0, 12] - x[0, 19]) * GCosTable[18];
  p[13] := (x[0, 13] - x[0, 18]) * GCosTable[17];
  p[14] := (x[0, 14] - x[0, 17]) * GCosTable[16];
  p[15] := (x[0, 15] - x[0, 16]) * GCosTable[15];

  pp[0] := p[0] + p[15];
  pp[1] := p[1] + p[14];
  pp[2] := p[2] + p[13];
  pp[3] := p[3] + p[12];
  pp[4] := p[4] + p[11];
  pp[5] := p[5] + p[10];
  pp[6] := p[6] + p[9];
  pp[7] := p[7] + p[8];
  pp[8] := (p[0] - p[15]) * GCosTable[14];
  pp[9] := (p[1] - p[14]) * GCosTable[13];
  pp[10] := (p[2] - p[13]) * GCosTable[12];
  pp[11] := (p[3] - p[12]) * GCosTable[11];
  pp[12] := (p[4] - p[11]) * GCosTable[10];
  pp[13] := (p[5] - p[10]) * GCosTable[9];
  pp[14] := (p[6] - p[9]) * GCosTable[8];
  pp[15] := (p[7] - p[8]) * GCosTable[7];

  p[0] := pp[0] + pp[7];
  p[1] := pp[1] + pp[6];
  p[2] := pp[2] + pp[5];
  p[3] := pp[3] + pp[4];
  p[4] := (pp[0] - pp[7]) * GCosTable[6];
  p[5] := (pp[1] - pp[6]) * GCosTable[5];
  p[6] := (pp[2] - pp[5]) * GCosTable[4];
  p[7] := (pp[3] - pp[4]) * GCosTable[3];
  p[8] := pp[8] + pp[15];
  p[9] := pp[9] + pp[14];
  p[10] := pp[10] + pp[13];
  p[11] := pp[11] + pp[12];
  p[12] := (pp[8] - pp[15]) * GCosTable[6];
  p[13] := (pp[9] - pp[14]) * GCosTable[5];
  p[14] := (pp[10] - pp[13]) * GCosTable[4];
  p[15] := (pp[11] - pp[12]) * GCosTable[3];

  pp[0] := p[0] + p[3];
  pp[1] := p[1] + p[2];
  pp[2] := (p[0] - p[3]) * GCosTable[2];
  pp[3] := (p[1] - p[2]) * GCosTable[1];
  pp[4] := p[4] + p[7];
  pp[5] := p[5] + p[6];
  pp[6] := (p[4] - p[7]) * GCosTable[2];
  pp[7] := (p[5] - p[6]) * GCosTable[1];
  pp[8] := p[8] + p[11];
  pp[9] := p[9] + p[10];
  pp[10] := (p[8] - p[11]) * GCosTable[2];
  pp[11] := (p[9] - p[10]) * GCosTable[1];
  pp[12] := p[12] + p[15];
  pp[13] := p[13] + p[14];
  pp[14] := (p[12] - p[15]) * GCosTable[2];
  pp[15] := (p[13] - p[14]) * GCosTable[1];

  p[0] := pp[0] + pp[1];
  p[1] := (pp[0] - pp[1]) * GCosTable[0];
  p[2] := pp[2] + pp[3];
  p[3] := (pp[2] - pp[3]) * GCosTable[0];
  p[4] := pp[4] + pp[5];
  p[5] := (pp[4] - pp[5]) * GCosTable[0];
  p[6] := pp[6] + pp[7];
  p[7] := (pp[6] - pp[7]) * GCosTable[0];
  p[8] := pp[8] + pp[9];
  p[9] := (pp[8] - pp[9]) * GCosTable[0];
  p[10] := pp[10] + pp[11];
  p[11] := (pp[10] - pp[11]) * GCosTable[0];
  p[12] := pp[12] + pp[13];
  p[13] := (pp[12] - pp[13]) * GCosTable[0];
  p[14] := pp[14] + pp[15];
  p[15] := (pp[14] - pp[15]) * GCosTable[0];

  NewVec[15] := p[15];
  NewVec[13] := NewVec[15] + p[7];
  NewVec[11] := NewVec[13] + p[11];
  NewVec[5] := NewVec[11] + p[5] + p[13];
  NewVec[9] := p[15] + p[11] + p[3];
  NewVec[7] := NewVec[9] + p[13];
  tmp[0] := p[13] + p[15] + p[9];
  NewVec[1] := tmp[0] + p[1];
  NewVec[16] := -NewVec[1] - p[14];
  NewVec[3] := tmp[0] + p[5] + p[7];
  NewVec[18] := -NewVec[3] - p[6] - p[14];

  tmp[0] := -p[10] - p[11] - p[14] - p[15];
  NewVec[22] := tmp[0] - p[13] - p[2] - p[3];
  NewVec[20] := tmp[0] - p[13] - p[5] - p[6] - p[7];
  NewVec[24] := tmp[0] - p[12] - p[2] - p[3];
  tmp[1] := p[4] + p[6] + p[7];
  NewVec[26] := tmp[0] - p[12] - tmp[1];
  tmp[0] := -p[8] - p[12] - p[14] - p[15];
  NewVec[30] := tmp[0] - p[0];
  NewVec[28] := tmp[0] - tmp[1];

  // insert V[0-15] (= NewVec[0-15]) into actual v:
  x[0] := @NewVec;
  x[1] := @FActualVector[FActualWritePos];
  x[1, 0] := x[0, 0];
  x[1, 16] := x[0, 1];
  x[1, 32] := x[0, 2];
  x[1, 48] := x[0, 3];
  x[1, 64] := x[0, 4];
  x[1, 80] := x[0, 5];
  x[1, 96] := x[0, 6];
  x[1, 112] := x[0, 7];
  x[1, 128] := x[0, 8];
  x[1, 144] := x[0, 9];
  x[1, 160] := x[0, 10];
  x[1, 176] := x[0, 11];
  x[1, 192] := x[0, 12];
  x[1, 208] := x[0, 13];
  x[1, 224] := x[0, 14];
  x[1, 240] := x[0, 15];

  // V[16] is always 0.0:
  x[1, 256] := 0;

  // insert V[17-31] (= -NewVec[15-1]) into actual v:
  x[1, 272] := -x[0, 15];
  x[1, 288] := -x[0, 14];
  x[1, 304] := -x[0, 13];
  x[1, 320] := -x[0, 12];
  x[1, 336] := -x[0, 11];
  x[1, 352] := -x[0, 10];
  x[1, 368] := -x[0, 9];
  x[1, 384] := -x[0, 8];
  x[1, 400] := -x[0, 7];
  x[1, 416] := -x[0, 6];
  x[1, 432] := -x[0, 5];
  x[1, 448] := -x[0, 4];
  x[1, 464] := -x[0, 3];
  x[1, 480] := -x[0, 2];
  x[1, 496] := -x[0, 1];

  // insert V[32] (= -NewVec[0]) into other v:
  if (FActualVector = @FVector[0]) then
    x[1] := @FVector[1, FActualWritePos]
  else
    x[1] := @FVector[0, FActualWritePos];

  x[1, 0] := -x[0, 0];

  // insert V[33-48] (= NewVec[16-31]) into other v:
  x[1, 16] := x[0, 16];
  x[1, 32] := x[0, 17];
  x[1, 48] := x[0, 18];
  x[1, 64] := x[0, 19];
  x[1, 80] := x[0, 20];
  x[1, 96] := x[0, 21];
  x[1, 112] := x[0, 22];
  x[1, 128] := x[0, 23];
  x[1, 144] := x[0, 24];
  x[1, 160] := x[0, 25];
  x[1, 176] := x[0, 26];
  x[1, 192] := x[0, 27];
  x[1, 208] := x[0, 28];
  x[1, 224] := x[0, 29];
  x[1, 240] := x[0, 30];
  x[1, 256] := x[0, 31];

  // insert V[49-63] (= NewVec[30-16]) into other v:
  x[1, 272] := x[0, 30];
  x[1, 288] := x[0, 29];
  x[1, 304] := x[0, 28];
  x[1, 320] := x[0, 27];
  x[1, 336] := x[0, 26];
  x[1, 352] := x[0, 25];
  x[1, 368] := x[0, 24];
  x[1, 384] := x[0, 23];
  x[1, 400] := x[0, 22];
  x[1, 416] := x[0, 21];
  x[1, 432] := x[0, 20];
  x[1, 448] := x[0, 19];
  x[1, 464] := x[0, 18];
  x[1, 480] := x[0, 17];
  x[1, 496] := x[0, 16];
end;

procedure TSynthesisFilter.ComputePCMSample;
var
  vp: PIAP512SingleArray;
  Coefficient: PIAP512SingleArray;
  PcmSample: Single;
const
  C2048 = 2048;
begin
  if not Assigned(FOnNewPCMSample) then
    exit;

  vp := FActualVector;
  case FActualWritePos of
    0:
      begin
        Coefficient := @CAnnex3B3Table;
        while (Cardinal(Coefficient) < Cardinal(@CAnnex3B3Table) + C2048) do
        begin
          PcmSample := ((vp[0] * Coefficient[0]) + (vp[15] * Coefficient[1]) +
            (vp[14] * Coefficient[2]) + (vp[13] * Coefficient[3]) +
            (vp[12] * Coefficient[4]) + (vp[11] * Coefficient[5]) +
            (vp[10] * Coefficient[6]) + (vp[9] * Coefficient[7]) +
            (vp[8] * Coefficient[8]) + (vp[7] * Coefficient[9]) +
            (vp[6] * Coefficient[10]) + (vp[5] * Coefficient[11]) +
            (vp[4] * Coefficient[12]) + (vp[3] * Coefficient[13]) +
            (vp[2] * Coefficient[14]) + (vp[1] * Coefficient[15]));
          FOnNewPCMSample(Self, PcmSample);
          Coefficient := @Coefficient[16];
          vp := @vp[16];
        end;
      end;

    1:
      begin
        Coefficient := @CAnnex3B3Table;
        while (Cardinal(Coefficient) < Cardinal(@CAnnex3B3Table) + C2048) do
        begin
          PcmSample := ((vp[1] * Coefficient[0]) + (vp[0] * Coefficient[1]) +
            (vp[15] * Coefficient[2]) + (vp[14] * Coefficient[3]) +
            (vp[13] * Coefficient[4]) + (vp[12] * Coefficient[5]) +
            (vp[11] * Coefficient[6]) + (vp[10] * Coefficient[7]) +
            (vp[9] * Coefficient[8]) + (vp[8] * Coefficient[9]) +
            (vp[7] * Coefficient[10]) + (vp[6] * Coefficient[11]) +
            (vp[5] * Coefficient[12]) + (vp[4] * Coefficient[13]) +
            (vp[3] * Coefficient[14]) + (vp[2] * Coefficient[15]));
          FOnNewPCMSample(Self, PcmSample);
          Coefficient := @Coefficient[16];
          vp := @vp[16];
        end;
      end;

    2:
      begin
        Coefficient := @CAnnex3B3Table;
        while (Cardinal(Coefficient) < Cardinal(@CAnnex3B3Table) + C2048) do
        begin
          PcmSample := ((vp[2] * Coefficient[0]) + (vp[1] * Coefficient[1]) +
            (vp[0] * Coefficient[2]) + (vp[15] * Coefficient[3]) +
            (vp[14] * Coefficient[4]) + (vp[13] * Coefficient[5]) +
            (vp[12] * Coefficient[6]) + (vp[11] * Coefficient[7]) +
            (vp[10] * Coefficient[8]) + (vp[9] * Coefficient[9]) +
            (vp[8] * Coefficient[10]) + (vp[7] * Coefficient[11]) +
            (vp[6] * Coefficient[12]) + (vp[5] * Coefficient[13]) +
            (vp[4] * Coefficient[14]) + (vp[3] * Coefficient[15]));
          FOnNewPCMSample(Self, PcmSample);
          Coefficient := @Coefficient[16];
          vp := @vp[16];
        end;
      end;

    3:
      begin
        Coefficient := @CAnnex3B3Table;
        while (Cardinal(Coefficient) < Cardinal(@CAnnex3B3Table) + C2048) do
        begin
          PcmSample := ((vp[3] * Coefficient[0]) + (vp[2] * Coefficient[1]) +
            (vp[1] * Coefficient[2]) + (vp[0] * Coefficient[3]) +
            (vp[15] * Coefficient[4]) + (vp[14] * Coefficient[5]) +
            (vp[13] * Coefficient[6]) + (vp[12] * Coefficient[7]) +
            (vp[11] * Coefficient[8]) + (vp[10] * Coefficient[9]) +
            (vp[9] * Coefficient[10]) + (vp[8] * Coefficient[11]) +
            (vp[7] * Coefficient[12]) + (vp[6] * Coefficient[13]) +
            (vp[5] * Coefficient[14]) + (vp[4] * Coefficient[15]));
          FOnNewPCMSample(Self, PcmSample);
          Coefficient := @Coefficient[16];
          vp := @vp[16];
        end;
      end;

    4:
      begin
        Coefficient := @CAnnex3B3Table;
        while (Cardinal(Coefficient) < Cardinal(@CAnnex3B3Table) + C2048) do
        begin
          PcmSample := ((vp[4] * Coefficient[0]) + (vp[3] * Coefficient[1]) +
            (vp[2] * Coefficient[2]) + (vp[1] * Coefficient[3]) +
            (vp[0] * Coefficient[4]) + (vp[15] * Coefficient[5]) +
            (vp[14] * Coefficient[6]) + (vp[13] * Coefficient[7]) +
            (vp[12] * Coefficient[8]) + (vp[11] * Coefficient[9]) +
            (vp[10] * Coefficient[10]) + (vp[9] * Coefficient[11]) +
            (vp[8] * Coefficient[12]) + (vp[7] * Coefficient[13]) +
            (vp[6] * Coefficient[14]) + (vp[5] * Coefficient[15]));
          FOnNewPCMSample(Self, PcmSample);
          Coefficient := @Coefficient[16];
          vp := @vp[16];
        end;
      end;

    5:
      begin
        Coefficient := @CAnnex3B3Table;
        while (Cardinal(Coefficient) < Cardinal(@CAnnex3B3Table) + C2048) do
        begin
          PcmSample := ((vp[5] * Coefficient[0]) + (vp[4] * Coefficient[1]) +
            (vp[3] * Coefficient[2]) + (vp[2] * Coefficient[3]) +
            (vp[1] * Coefficient[4]) + (vp[0] * Coefficient[5]) +
            (vp[15] * Coefficient[6]) + (vp[14] * Coefficient[7]) +
            (vp[13] * Coefficient[8]) + (vp[12] * Coefficient[9]) +
            (vp[11] * Coefficient[10]) + (vp[10] * Coefficient[11]) +
            (vp[9] * Coefficient[12]) + (vp[8] * Coefficient[13]) +
            (vp[7] * Coefficient[14]) + (vp[6] * Coefficient[15]));
          FOnNewPCMSample(Self, PcmSample);
          Coefficient := @Coefficient[16];
          vp := @vp[16];
        end;
      end;

    6:
      begin
        Coefficient := @CAnnex3B3Table;
        while (Cardinal(Coefficient) < Cardinal(@CAnnex3B3Table) + C2048) do
        begin
          PcmSample := ((vp[6] * Coefficient[0]) + (vp[5] * Coefficient[1]) +
            (vp[4] * Coefficient[2]) + (vp[3] * Coefficient[3]) +
            (vp[2] * Coefficient[4]) + (vp[1] * Coefficient[5]) +
            (vp[0] * Coefficient[6]) + (vp[15] * Coefficient[7]) +
            (vp[14] * Coefficient[8]) + (vp[13] * Coefficient[9]) +
            (vp[12] * Coefficient[10]) + (vp[11] * Coefficient[11]) +
            (vp[10] * Coefficient[12]) + (vp[9] * Coefficient[13]) +
            (vp[8] * Coefficient[14]) + (vp[7] * Coefficient[15]));
          FOnNewPCMSample(Self, PcmSample);
          Coefficient := @Coefficient[16];
          vp := @vp[16];
        end;
      end;

    7:
      begin
        Coefficient := @CAnnex3B3Table;
        while (Cardinal(Coefficient) < Cardinal(@CAnnex3B3Table) + C2048) do
        begin
          PcmSample := ((vp[7] * Coefficient[0]) + (vp[6] * Coefficient[1]) +
            (vp[5] * Coefficient[2]) + (vp[4] * Coefficient[3]) +
            (vp[3] * Coefficient[4]) + (vp[2] * Coefficient[5]) +
            (vp[1] * Coefficient[6]) + (vp[0] * Coefficient[7]) +
            (vp[15] * Coefficient[8]) + (vp[14] * Coefficient[9]) +
            (vp[13] * Coefficient[10]) + (vp[12] * Coefficient[11]) +
            (vp[11] * Coefficient[12]) + (vp[10] * Coefficient[13]) +
            (vp[9] * Coefficient[14]) + (vp[8] * Coefficient[15]));
          FOnNewPCMSample(Self, PcmSample);
          Coefficient := @Coefficient[16];
          vp := @vp[16];
        end;
      end;

    8:
      begin
        Coefficient := @CAnnex3B3Table;
        while (Cardinal(Coefficient) < Cardinal(@CAnnex3B3Table) + C2048) do
        begin
          PcmSample := ((vp[8] * Coefficient[0]) + (vp[7] * Coefficient[1]) +
            (vp[6] * Coefficient[2]) + (vp[5] * Coefficient[3]) +
            (vp[4] * Coefficient[4]) + (vp[3] * Coefficient[5]) +
            (vp[2] * Coefficient[6]) + (vp[1] * Coefficient[7]) +
            (vp[0] * Coefficient[8]) + (vp[15] * Coefficient[9]) +
            (vp[14] * Coefficient[10]) + (vp[13] * Coefficient[11]) +
            (vp[12] * Coefficient[12]) + (vp[11] * Coefficient[13]) +
            (vp[10] * Coefficient[14]) + (vp[9] * Coefficient[15]));
          FOnNewPCMSample(Self, PcmSample);
          Coefficient := @Coefficient[16];
          vp := @vp[16];
        end;
      end;

    9:
      begin
        Coefficient := @CAnnex3B3Table;
        while (Cardinal(Coefficient) < Cardinal(@CAnnex3B3Table) + C2048) do
        begin
          PcmSample := ((vp[9] * Coefficient[0]) + (vp[8] * Coefficient[1]) +
            (vp[7] * Coefficient[2]) + (vp[6] * Coefficient[3]) +
            (vp[5] * Coefficient[4]) + (vp[4] * Coefficient[5]) +
            (vp[3] * Coefficient[6]) + (vp[2] * Coefficient[7]) +
            (vp[1] * Coefficient[8]) + (vp[0] * Coefficient[9]) +
            (vp[15] * Coefficient[10]) + (vp[14] * Coefficient[11]) +
            (vp[13] * Coefficient[12]) + (vp[12] * Coefficient[13]) +
            (vp[11] * Coefficient[14]) + (vp[10] * Coefficient[15]));
          FOnNewPCMSample(Self, PcmSample);
          Coefficient := @Coefficient[16];
          vp := @vp[16];
        end;
      end;

    10:
      begin
        Coefficient := @CAnnex3B3Table;
        while (Cardinal(Coefficient) < Cardinal(@CAnnex3B3Table) + C2048) do
        begin
          PcmSample := ((vp[10] * Coefficient[0]) + (vp[9] * Coefficient[1]) +
            (vp[8] * Coefficient[2]) + (vp[7] * Coefficient[3]) +
            (vp[6] * Coefficient[4]) + (vp[5] * Coefficient[5]) +
            (vp[4] * Coefficient[6]) + (vp[3] * Coefficient[7]) +
            (vp[2] * Coefficient[8]) + (vp[1] * Coefficient[9]) +
            (vp[0] * Coefficient[10]) + (vp[15] * Coefficient[11]) +
            (vp[14] * Coefficient[12]) + (vp[13] * Coefficient[13]) +
            (vp[12] * Coefficient[14]) + (vp[11] * Coefficient[15]));
          FOnNewPCMSample(Self, PcmSample);
          Coefficient := @Coefficient[16];
          vp := @vp[16];
        end;
      end;

    11:
      begin
        Coefficient := @CAnnex3B3Table;
        while (Cardinal(Coefficient) < Cardinal(@CAnnex3B3Table) + C2048) do
        begin
          PcmSample := ((vp[11] * Coefficient[0]) + (vp[10] * Coefficient[1]) +
            (vp[9] * Coefficient[2]) + (vp[8] * Coefficient[3]) +
            (vp[7] * Coefficient[4]) + (vp[6] * Coefficient[5]) +
            (vp[5] * Coefficient[6]) + (vp[4] * Coefficient[7]) +
            (vp[3] * Coefficient[8]) + (vp[2] * Coefficient[9]) +
            (vp[1] * Coefficient[10]) + (vp[0] * Coefficient[11]) +
            (vp[15] * Coefficient[12]) + (vp[14] * Coefficient[13]) +
            (vp[13] * Coefficient[14]) + (vp[12] * Coefficient[15]));
          FOnNewPCMSample(Self, PcmSample);
          Coefficient := @Coefficient[16];
          vp := @vp[16];
        end;
      end;

    12:
      begin
        Coefficient := @CAnnex3B3Table;
        while (Cardinal(Coefficient) < Cardinal(@CAnnex3B3Table) + C2048) do
        begin
          PcmSample := ((vp[12] * Coefficient[0]) + (vp[11] * Coefficient[1]) +
            (vp[10] * Coefficient[2]) + (vp[9] * Coefficient[3]) +
            (vp[8] * Coefficient[4]) + (vp[7] * Coefficient[5]) +
            (vp[6] * Coefficient[6]) + (vp[5] * Coefficient[7]) +
            (vp[4] * Coefficient[8]) + (vp[3] * Coefficient[9]) +
            (vp[2] * Coefficient[10]) + (vp[1] * Coefficient[11]) +
            (vp[0] * Coefficient[12]) + (vp[15] * Coefficient[13]) +
            (vp[14] * Coefficient[14]) + (vp[13] * Coefficient[15]));
          FOnNewPCMSample(Self, PcmSample);
          Coefficient := @Coefficient[16];
          vp := @vp[16];
        end;
      end;

    13:
      begin
        Coefficient := @CAnnex3B3Table;
        while (Cardinal(Coefficient) < Cardinal(@CAnnex3B3Table) + C2048) do
        begin
          PcmSample := ((vp[13] * Coefficient[0]) + (vp[12] * Coefficient[1]) +
            (vp[11] * Coefficient[2]) + (vp[10] * Coefficient[3]) +
            (vp[9] * Coefficient[4]) + (vp[8] * Coefficient[5]) +
            (vp[7] * Coefficient[6]) + (vp[6] * Coefficient[7]) +
            (vp[5] * Coefficient[8]) + (vp[4] * Coefficient[9]) +
            (vp[3] * Coefficient[10]) + (vp[2] * Coefficient[11]) +
            (vp[1] * Coefficient[12]) + (vp[0] * Coefficient[13]) +
            (vp[15] * Coefficient[14]) + (vp[14] * Coefficient[15]));
          FOnNewPCMSample(Self, PcmSample);
          Coefficient := @Coefficient[16];
          vp := @vp[16];
        end;
      end;

    14:
      begin
        Coefficient := @CAnnex3B3Table;
        while (Cardinal(Coefficient) < Cardinal(@CAnnex3B3Table) + C2048) do
        begin
          PcmSample := ((vp[14] * Coefficient[0]) + (vp[13] * Coefficient[1]) +
            (vp[12] * Coefficient[2]) + (vp[11] * Coefficient[3]) +
            (vp[10] * Coefficient[4]) + (vp[9] * Coefficient[5]) +
            (vp[8] * Coefficient[6]) + (vp[7] * Coefficient[7]) +
            (vp[6] * Coefficient[8]) + (vp[5] * Coefficient[9]) +
            (vp[4] * Coefficient[10]) + (vp[3] * Coefficient[11]) +
            (vp[2] * Coefficient[12]) + (vp[1] * Coefficient[13]) +
            (vp[0] * Coefficient[14]) + (vp[15] * Coefficient[15]));
          FOnNewPCMSample(Self, PcmSample);
          Coefficient := @Coefficient[16];
          vp := @vp[16];
        end;
      end;

    15:
      begin
        Coefficient := @CAnnex3B3Table;
        while (Cardinal(Coefficient) < Cardinal(@CAnnex3B3Table) + C2048) do
        begin
          PcmSample := ((vp[15] * Coefficient[0]) + (vp[14] * Coefficient[1]) +
            (vp[13] * Coefficient[2]) + (vp[12] * Coefficient[3]) +
            (vp[11] * Coefficient[4]) + (vp[10] * Coefficient[5]) +
            (vp[9] * Coefficient[6]) + (vp[8] * Coefficient[7]) +
            (vp[7] * Coefficient[8]) + (vp[6] * Coefficient[9]) +
            (vp[5] * Coefficient[10]) + (vp[4] * Coefficient[11]) +
            (vp[3] * Coefficient[12]) + (vp[2] * Coefficient[13]) +
            (vp[1] * Coefficient[14]) + (vp[0] * Coefficient[15]));
          FOnNewPCMSample(Self, PcmSample);
          Coefficient := @Coefficient[16];
          vp := @vp[16];
        end;
      end;
  end;
end;

procedure TSynthesisFilter.InputSample(Sample: Single; SubBandNumber: Cardinal);
begin
  FSample[SubBandNumber] := Sample;
end;

procedure TSynthesisFilter.Reset;
begin
  FillChar(FVector[0], Sizeof(FVector[0]), 0);
  FillChar(FVector[1], Sizeof(FVector[1]), 0);
  FillChar(FSample, Sizeof(FSample), 0);
  FActualVector := @FVector[0];
  FActualWritePos := 15;
end;

procedure CalculateCosTable;
const
  COne64th = 1 / 64;
{$IFNDEF FastCalculation}
  COne32th = 1 / 32;
  COne16th = 1 / 16;
  COne8th = 1 / 8;
  COne4th = 1 / 4;
{$ELSE}
var
  Position, Offset: TComplex64;
{$ENDIF}
begin
{$IFDEF FastCalculation}
  Position.Re := 1;
  Position.Im := 0;
  SinCos(Pi * COne64th, Offset.Im, Offset.Re);

  ComplexMultiplyInplace64(Position, Offset);
  GCosTable[30] := 0.5 / Position.Re;
  GCosTable[15] := 0.5 / Position.Im;

  ComplexMultiplyInplace64(Position, Offset);
  GCosTable[14] := 0.5 / Position.Re;
  GCosTable[7] := 0.5 / Position.Im;

  ComplexMultiplyInplace64(Position, Offset);
  GCosTable[29] := 0.5 / Position.Re;
  GCosTable[16] := 0.5 / Position.Im;

  ComplexMultiplyInplace64(Position, Offset);
  GCosTable[6] := 0.5 / Position.Re;
  GCosTable[3] := 0.5 / Position.Im;

  ComplexMultiplyInplace64(Position, Offset);
  GCosTable[28] := 0.5 / Position.Re;
  GCosTable[17] := 0.5 / Position.Im;

  ComplexMultiplyInplace64(Position, Offset);
  GCosTable[13] := 0.5 / Position.Re;
  GCosTable[8] := 0.5 / Position.Im;

  ComplexMultiplyInplace64(Position, Offset);
  GCosTable[27] := 0.5 / Position.Re;
  GCosTable[18] := 0.5 / Position.Im;

  ComplexMultiplyInplace64(Position, Offset);
  GCosTable[2] := 0.5 / Position.Re;
  GCosTable[1] := 0.5 / Position.Im;

  ComplexMultiplyInplace64(Position, Offset);
  GCosTable[26] := 0.5 / Position.Re;
  GCosTable[19] := 0.5 / Position.Im;

  ComplexMultiplyInplace64(Position, Offset);
  GCosTable[12] := 0.5 / Position.Re;
  GCosTable[9] := 0.5 / Position.Im;

  ComplexMultiplyInplace64(Position, Offset);
  GCosTable[25] := 0.5 / Position.Re;
  GCosTable[20] := 0.5 / Position.Im;

  ComplexMultiplyInplace64(Position, Offset);
  GCosTable[5] := 0.5 / Position.Re;
  GCosTable[4] := 0.5 / Position.Im;

  ComplexMultiplyInplace64(Position, Offset);
  GCosTable[24] := 0.5 / Position.Re;
  GCosTable[21] := 0.5 / Position.Im;

  ComplexMultiplyInplace64(Position, Offset);
  GCosTable[11] := 0.5 / Position.Re;
  GCosTable[10] := 0.5 / Position.Im;

  ComplexMultiplyInplace64(Position, Offset);
  GCosTable[23] := 0.5 / Position.Re;
  GCosTable[22] := 0.5 / Position.Im;

  ComplexMultiplyInplace64(Position, Offset);
  GCosTable[0] := 0.5 / Position.Re;

{$ELSE}
  GCosTable[0] := 1 / (2 * cos(Pi * COne4th));
  GCosTable[1] := 1 / (2 * cos(Pi * 3 * COne8th));
  GCosTable[2] := 1 / (2 * cos(Pi * COne8th));
  GCosTable[3] := 1 / (2 * cos(Pi * 7 * COne16th));
  GCosTable[4] := 1 / (2 * cos(Pi * 5 * COne16th));
  GCosTable[5] := 1 / (2 * cos(Pi * 3 * COne16th));
  GCosTable[6] := 1 / (2 * cos(Pi * COne16th));
  GCosTable[7] := 1 / (2 * cos(Pi * 15 * COne32th));
  GCosTable[8] := 1 / (2 * cos(Pi * 13 * COne32th));
  GCosTable[9] := 1 / (2 * cos(Pi * 11 * COne32th));
  GCosTable[10] := 1 / (2 * cos(Pi * 9 * COne32th));
  GCosTable[11] := 1 / (2 * cos(Pi * 7 * COne32th));
  GCosTable[12] := 1 / (2 * cos(Pi * 5 * COne32th));
  GCosTable[13] := 1 / (2 * cos(Pi * 3 * COne32th));
  GCosTable[14] := 1 / (2 * cos(Pi * COne32th));
  GCosTable[15] := 1 / (2 * cos(Pi * 31 * COne64th));
  GCosTable[16] := 1 / (2 * cos(Pi * 29 * COne64th));
  GCosTable[17] := 1 / (2 * cos(Pi * 27 * COne64th));
  GCosTable[18] := 1 / (2 * cos(Pi * 25 * COne64th));
  GCosTable[19] := 1 / (2 * cos(Pi * 23 * COne64th));
  GCosTable[20] := 1 / (2 * cos(Pi * 21 * COne64th));
  GCosTable[21] := 1 / (2 * cos(Pi * 19 * COne64th));
  GCosTable[22] := 1 / (2 * cos(Pi * 17 * COne64th));
  GCosTable[23] := 1 / (2 * cos(Pi * 15 * COne64th));
  GCosTable[24] := 1 / (2 * cos(Pi * 13 * COne64th));
  GCosTable[25] := 1 / (2 * cos(Pi * 11 * COne64th));
  GCosTable[26] := 1 / (2 * cos(Pi * 9 * COne64th));
  GCosTable[27] := 1 / (2 * cos(Pi * 7 * COne64th));
  GCosTable[28] := 1 / (2 * cos(Pi * 5 * COne64th));
  GCosTable[29] := 1 / (2 * cos(Pi * 3 * COne64th));
  GCosTable[30] := 1 / (2 * cos(Pi * COne64th));
{$ENDIF}
end;

{ TSubBandLayer1 }

constructor TSubBandLayer1.Create(SubBandNumber: Cardinal);
begin
  FSubBandNumber := SubBandNumber;
  FSampleNumber := 0;
end;

function TSubBandLayer1.PutNextSample(Channels: TChannels;
  Filter1, Filter2: TSynthesisFilter): Boolean;
var
  ScaledSample: Single;
begin
  if (FAllocation <> 0) and (Channels <> chRight) then
  begin
    ScaledSample := (FSample * FFactor + FOffset) * FScaleFactor;
    Filter1.InputSample(ScaledSample, FSubBandNumber);
  end;
  Result := True;
end;

procedure TSubBandLayer1.ReadAllocation(Stream: TBitStream; Header: THeader;
  CRC: TCRC16);
begin
  FAllocation := Stream.GetBits(4);
  if (FAllocation = 15) then;
  // cerr << "WARNING: stream contains an illegal allocation!\n"; // MPEG-stream is corrupted!
  if (CRC <> nil) then
    CRC.AddBits(FAllocation, 4);
  if (FAllocation <> 0) then
  begin
    FSampleLength := FAllocation + 1;
    FFactor := CTableFactor[FAllocation];
    FOffset := CTableOffset[FAllocation];
  end;
end;

function TSubBandLayer1.ReadSampleData(Stream: TBitStream): Boolean;
begin
  if (FAllocation <> 0) then
    FSample := Stream.GetBitsFloat(FSampleLength);

  Inc(FSampleNumber);
  if (FSampleNumber = 12) then
  begin
    FSampleNumber := 0;
    Result := True;
  end
  else
    Result := False;
end;

procedure TSubBandLayer1.ReadScaleFactor(Stream: TBitStream; Header: THeader);
begin
  if (FAllocation <> 0) then
    FScaleFactor := CScaleFactors[Stream.GetBits(6)];
end;

{ TSubBandLayer1IntensityStereo }

function TSubBandLayer1IntensityStereo.PutNextSample(Channels: TChannels;
  Filter1, Filter2: TSynthesisFilter): Boolean;
var
  Sample: array [0 .. 1] of Single;
begin
  if (FAllocation <> 0) then
  begin
    FSample := FSample * FFactor + FOffset; // requantization
    if (Channels = chBoth) then
    begin
      Sample[0] := FSample * FScaleFactor;
      Sample[1] := FSample * FChannel2ScaleFactor;
      Filter1.InputSample(Sample[0], FSubBandNumber);
      Filter2.InputSample(Sample[1], FSubBandNumber);
    end
    else if (Channels = chLeft) then
    begin
      Sample[0] := FSample * FScaleFactor;
      Filter1.InputSample(Sample[0], FSubBandNumber);
    end
    else
    begin
      Sample[1] := FSample * FChannel2ScaleFactor;
      Filter2.InputSample(Sample[1], FSubBandNumber);
    end;
  end;
  Result := True;
end;

procedure TSubBandLayer1IntensityStereo.ReadScaleFactor(Stream: TBitStream;
  Header: THeader);
begin
  if (FAllocation <> 0) then
  begin
    FScaleFactor := CScaleFactors[Stream.GetBits(6)];
    FChannel2ScaleFactor := CScaleFactors[Stream.GetBits(6)];
  end;
end;

{ TSubBandLayer1Stereo }

function TSubBandLayer1Stereo.PutNextSample(Channels: TChannels;
  Filter1, Filter2: TSynthesisFilter): Boolean;
var
  Sample: Single;
begin
  inherited PutNextSample(Channels, Filter1, Filter2);
  if (FChannel2Allocation <> 0) and (Channels <> chLeft) then
  begin
    Sample := (FChannel2Sample * FChannel2Factor + FChannel2Offset) *
      FChannel2ScaleFactor;
    if (Channels = chBoth) then
      Filter2.InputSample(Sample, FSubBandNumber)
    else
      Filter1.InputSample(Sample, FSubBandNumber);
  end;
  Result := True;
end;

procedure TSubBandLayer1Stereo.ReadAllocation(Stream: TBitStream;
  Header: THeader; CRC: TCRC16);
begin
  FAllocation := Stream.GetBits(4);
  FChannel2Allocation := Stream.GetBits(4);
  if (CRC <> nil) then
  begin
    CRC.AddBits(FAllocation, 4);
    CRC.AddBits(FChannel2Allocation, 4);
  end;
  if (FAllocation <> 0) then
  begin
    FSampleLength := FAllocation + 1;
    FFactor := CTableFactor[FAllocation];
    FOffset := CTableOffset[FAllocation];
  end;

  if (FChannel2Allocation <> 0) then
  begin
    FChannel2SampleLength := FChannel2Allocation + 1;
    FChannel2Factor := CTableFactor[FChannel2Allocation];
    FChannel2Offset := CTableOffset[FChannel2Allocation];
  end;
end;

function TSubBandLayer1Stereo.ReadSampleData(Stream: TBitStream): Boolean;
begin
  Result := inherited ReadSampleData(Stream);
  if (FChannel2Allocation <> 0) then
    FChannel2Sample := Stream.GetBitsFloat(FChannel2SampleLength);
end;

procedure TSubBandLayer1Stereo.ReadScaleFactor(Stream: TBitStream;
  Header: THeader);
begin
  if (FAllocation <> 0) then
    FScaleFactor := CScaleFactors[Stream.GetBits(6)];
  if (FChannel2Allocation <> 0) then
    FChannel2ScaleFactor := CScaleFactors[Stream.GetBits(6)];
end;

constructor TSubBandLayer2.Create(SubBandNumber: Cardinal);
begin
  FSubBandNumber := SubBandNumber;
  FGroupNumber := 0;
  FSampleNumber := 0;
end;

function TSubBandLayer2.GetAllocationLength(Header: THeader): Cardinal;
var
  ChannelBitrate: Cardinal;
begin
  if (Header.Version = mv1) then
  begin
    ChannelBitrate := Header.BitrateIndex;

    // calculate bitrate per channel:
    if (Header.Mode <> cmSingleChannel) then
      if (ChannelBitrate = 4) then
        ChannelBitrate := 1
      else
        Dec(ChannelBitrate, 4);

    if (ChannelBitrate = 1) or (ChannelBitrate = 2) then
    begin // table 3-B.2c or 3-B.2d
      if (FSubBandNumber <= 1) then
        Exit(4)
      else
        Exit(3);
    end
    else
    begin
      // tables 3-B.2a or 3-B.2b
      if (FSubBandNumber <= 10) then
        Exit(4)
      else if (FSubBandNumber <= 22) then
        Exit(3)
      else
        Exit(2);
    end;
  end
  else
  begin // MPEG-2 LSF -- Jeff
    // table B.1 of ISO/IEC 13818-3
    if (FSubBandNumber <= 3) then
      Exit(4)
    else if (FSubBandNumber <= 10) then
      Exit(3)
    else
      Exit(2);
  end;
end;

procedure TSubBandLayer2.PrepareSampleReading(Header: THeader;
  Allocation: Cardinal; var GroupingTable: PIAP1024SingleArray;
  var Factor: Single; var CodeLength: Cardinal; var C, D: Single);
var
  ChannelBitrate: Cardinal;
begin
  ChannelBitrate := Header.BitrateIndex;
  // calculate bitrate per channel:
  if (Header.Mode <> cmSingleChannel) then
    if (ChannelBitrate = 4) then
      ChannelBitrate := 1
    else
      Dec(ChannelBitrate, 4);

  if (ChannelBitrate = 1) or (ChannelBitrate = 2) then
  begin // table 3-B.2c or 3-B.2d
    GroupingTable := CTableCDGroupingTables[Allocation];
    Factor := CTableCDFactor[Allocation];
    CodeLength := CTableCDCodeLength[Allocation];
    C := CTableCDC[Allocation];
    D := CTableCDD[Allocation];
  end
  else
  begin // tables 3-B.2a or 3-B.2b
    if (FSubBandNumber <= 2) then
    begin
      GroupingTable := CTableAB1GroupingTables[Allocation];
      Factor := CTableAB1Factor[Allocation];
      CodeLength := CTableAB1CodeLength[Allocation];
      C := CTableAB1C[Allocation];
      D := CTableAB1D[Allocation];
    end
    else
    begin
      GroupingTable := CTableAB234GroupingTables[Allocation];
      if (FSubBandNumber <= 10) then
      begin
        Factor := CTableAB2Factor[Allocation];
        CodeLength := CTableAB2CodeLength[Allocation];
        C := CTableAB2C[Allocation];
        D := CTableAB2D[Allocation];
      end
      else if (FSubBandNumber <= 22) then
      begin
        Factor := CTableAB3Factor[Allocation];
        CodeLength := CTableAB3CodeLength[Allocation];
        C := CTableAB3C[Allocation];
        D := CTableAB3D[Allocation];
      end
      else
      begin
        Factor := CTableAB4Factor[Allocation];
        CodeLength := CTableAB4CodeLength[Allocation];
        C := CTableAB4C[Allocation];
        D := CTableAB4D[Allocation];
      end;
    end;
  end;
end;

function TSubBandLayer2.PutNextSample(Channels: TChannels;
  Filter1, Filter2: TSynthesisFilter): Boolean;
var
  Sample: Single;
begin
  if (FAllocation <> 0) and (Channels <> chRight) then
  begin
    Sample := FSamples[FSampleNumber];
    if (FGroupingTable = nil) then
      Sample := (Sample + FD) * FC;
    if (FGroupNumber <= 4) then
      Sample := Sample * FScaleFactor[0]
    else if (FGroupNumber <= 8) then
      Sample := Sample * FScaleFactor[1]
    else
      Sample := Sample * FScaleFactor[2];
    Filter1.InputSample(Sample, FSubBandNumber);
  end;
  Inc(FSampleNumber);
  Result := (FSampleNumber = 3);
end;

procedure TSubBandLayer2.ReadAllocation(Stream: TBitStream; Header: THeader;
  CRC: TCRC16);
var
  Length: Cardinal;
begin
  Length := GetAllocationLength(Header);
  FAllocation := Stream.GetBits(Length);
  if (CRC <> nil) then
    CRC.AddBits(FAllocation, Length);
end;

function TSubBandLayer2.ReadSampleData(Stream: TBitStream): Boolean;
var
  SampleCode: Cardinal;
begin
  if (FAllocation <> 0) then
    if (FGroupingTable <> nil) then
    begin
      SampleCode := Stream.GetBits(FCodeLength);
      // create requantized samples:
      Inc(SampleCode, SampleCode shl 1);
      FSamples[0] := FGroupingTable[SampleCode];
      FSamples[1] := FGroupingTable[SampleCode + 1];
      FSamples[2] := FGroupingTable[SampleCode + 2];
    end
    else
    begin
      FSamples[0] := Stream.GetBits(FCodeLength) * FFactor - 1.0;
      FSamples[1] := Stream.GetBits(FCodeLength) * FFactor - 1.0;
      FSamples[2] := Stream.GetBits(FCodeLength) * FFactor - 1.0;
    end;

  FSampleNumber := 0;
  Inc(FGroupNumber);
  Result := (FGroupNumber = 12);
end;

procedure TSubBandLayer2.ReadScaleFactor(Stream: TBitStream; Header: THeader);
begin
  if (FAllocation <> 0) then
  begin
    case FSCFSI of
      0:
        begin
          FScaleFactor[0] := CScaleFactors[Stream.GetBits(6)];
          FScaleFactor[1] := CScaleFactors[Stream.GetBits(6)];
          FScaleFactor[2] := CScaleFactors[Stream.GetBits(6)];
        end;

      1:
        begin
          FScaleFactor[0] := CScaleFactors[Stream.GetBits(6)];
          FScaleFactor[1] := FScaleFactor[0];
          FScaleFactor[2] := CScaleFactors[Stream.GetBits(6)];
        end;

      2:
        begin
          FScaleFactor[0] := CScaleFactors[Stream.GetBits(6)];
          FScaleFactor[1] := FScaleFactor[0];
          FScaleFactor[2] := FScaleFactor[0];
        end;

      3:
        begin
          FScaleFactor[0] := CScaleFactors[Stream.GetBits(6)];
          FScaleFactor[1] := CScaleFactors[Stream.GetBits(6)];
          FScaleFactor[2] := FScaleFactor[1];
        end;
    end;
    PrepareSampleReading(Header, FAllocation, FGroupingTable, FFactor,
      FCodeLength, FC, FD);
  end;
end;

procedure TSubBandLayer2.ReadScaleFactorSelection(Stream: TBitStream;
  CRC: TCRC16);
begin
  if (FAllocation <> 0) then
  begin
    FSCFSI := Stream.GetBits(2);
    if (CRC <> nil) then
      CRC.AddBits(FSCFSI, 2);
  end;
end;

{ TSubbandLayer2IntensityStereo }

function TSubbandLayer2IntensityStereo.PutNextSample(Channels: TChannels;
  Filter1, Filter2: TSynthesisFilter): Boolean;
var
  Sample: array [0 .. 1] of Single;
begin
  if (FAllocation <> 0) then
  begin
    Sample[0] := FSamples[FSampleNumber];
    if (FGroupingTable = nil) then
      Sample[0] := (Sample[0] + FD) * FC;
    if (Channels = chBoth) then
    begin
      Sample[1] := Sample[0];
      if (FGroupNumber <= 4) then
      begin
        Sample[0] := Sample[0] * FScaleFactor[0];
        Sample[1] := Sample[1] * FChannel2ScaleFactor[0];
      end
      else if (FGroupNumber <= 8) then
      begin
        Sample[0] := Sample[0] * FScaleFactor[1];
        Sample[1] := Sample[1] * FChannel2ScaleFactor[1];
      end
      else
      begin
        Sample[0] := Sample[0] * FScaleFactor[2];
        Sample[1] := Sample[1] * FChannel2ScaleFactor[2];
      end;
      Filter1.InputSample(Sample[0], FSubBandNumber);
      Filter2.InputSample(Sample[1], FSubBandNumber);
    end
    else if (Channels = chLeft) then
    begin
      if (FGroupNumber <= 4) then
        Sample[0] := Sample[0] * FScaleFactor[0]
      else if (FGroupNumber <= 8) then
        Sample[0] := Sample[0] * FScaleFactor[1]
      else
        Sample[0] := Sample[0] * FScaleFactor[2];
      Filter1.InputSample(Sample[0], FSubBandNumber);
    end
    else
    begin
      if (FGroupNumber <= 4) then
        Sample[0] := Sample[0] * FChannel2ScaleFactor[0]
      else if (FGroupNumber <= 8) then
        Sample[0] := Sample[0] * FChannel2ScaleFactor[1]
      else
        Sample[0] := Sample[0] * FChannel2ScaleFactor[2];
      Filter1.InputSample(Sample[0], FSubBandNumber);
    end;
  end;
  Inc(FSampleNumber);
  Result := (FSampleNumber = 3);
end;

procedure TSubbandLayer2IntensityStereo.ReadScaleFactor(Stream: TBitStream;
  Header: THeader);
begin
  if (FAllocation <> 0) then
  begin
    inherited ReadScaleFactor(Stream, Header);
    case FChannel2SCFSI of
      0:
        begin
          FChannel2ScaleFactor[0] := CScaleFactors[Stream.GetBits(6)];
          FChannel2ScaleFactor[1] := CScaleFactors[Stream.GetBits(6)];
          FChannel2ScaleFactor[2] := CScaleFactors[Stream.GetBits(6)];
        end;

      1:
        begin
          FChannel2ScaleFactor[0] := CScaleFactors[Stream.GetBits(6)];
          FChannel2ScaleFactor[1] := FChannel2ScaleFactor[0];
          FChannel2ScaleFactor[2] := CScaleFactors[Stream.GetBits(6)];
        end;

      2:
        begin
          FChannel2ScaleFactor[0] := CScaleFactors[Stream.GetBits(6)];
          FChannel2ScaleFactor[1] := FChannel2ScaleFactor[0];
          FChannel2ScaleFactor[2] := FChannel2ScaleFactor[0];
        end;

      3:
        begin
          FChannel2ScaleFactor[0] := CScaleFactors[Stream.GetBits(6)];
          FChannel2ScaleFactor[1] := CScaleFactors[Stream.GetBits(6)];
          FChannel2ScaleFactor[2] := FChannel2ScaleFactor[1];
        end;
    end;
  end;
end;

procedure TSubbandLayer2IntensityStereo.ReadScaleFactorSelection
  (Stream: TBitStream; CRC: TCRC16);
begin
  if (FAllocation <> 0) then
  begin
    FSCFSI := Stream.GetBits(2);
    FChannel2SCFSI := Stream.GetBits(2);
    if (CRC <> nil) then
    begin
      CRC.AddBits(FSCFSI, 2);
      CRC.AddBits(FChannel2SCFSI, 2);
    end;
  end;
end;

{ TSubbandLayer2Stereo }

function TSubbandLayer2Stereo.PutNextSample(Channels: TChannels;
  Filter1, Filter2: TSynthesisFilter): Boolean;
var
  Sample: Single;
begin
  Result := inherited PutNextSample(Channels, Filter1, Filter2);

  if (FChannel2Allocation <> 0) and (Channels <> chLeft) then
  begin
    Sample := FChannel2Samples[FSampleNumber - 1];
    if (FChannel2GroupingTable = nil) then
      Sample := (Sample + FChannel2D) * FChannel2C;
    if (FGroupNumber <= 4) then
      Sample := Sample * FChannel2ScaleFactor[0]
    else if (FGroupNumber <= 8) then
      Sample := Sample * FChannel2ScaleFactor[1]
    else
      Sample := Sample * FChannel2ScaleFactor[2];
    if (Channels = chBoth) then
      Filter2.InputSample(Sample, FSubBandNumber)
    else
      Filter1.InputSample(Sample, FSubBandNumber);
  end;
end;

procedure TSubbandLayer2Stereo.ReadAllocation(Stream: TBitStream;
  Header: THeader; CRC: TCRC16);
var
  Length: Cardinal;
begin
  Length := GetAllocationLength(Header);
  FAllocation := Stream.GetBits(Length);
  FChannel2Allocation := Stream.GetBits(Length);
  if (CRC <> nil) then
  begin
    CRC.AddBits(FAllocation, Length);
    CRC.AddBits(FChannel2Allocation, Length);
  end;
end;

function TSubbandLayer2Stereo.ReadSampleData(Stream: TBitStream): Boolean;
var
  SampleCode: Cardinal;
begin
  Result := inherited ReadSampleData(Stream);
  if (FChannel2Allocation <> 0) then
    if (FChannel2GroupingTable <> nil) then
    begin
      SampleCode := Stream.GetBits(FChannel2CodeLength);
      Inc(SampleCode, SampleCode shl 1); // create requantized samples:
      FChannel2Samples[0] := FChannel2GroupingTable[SampleCode];
      FChannel2Samples[1] := FChannel2GroupingTable[SampleCode + 1];
      FChannel2Samples[2] := FChannel2GroupingTable[SampleCode + 2];
    end
    else
    begin
      FChannel2Samples[0] := Stream.GetBits(FChannel2CodeLength) *
        FChannel2Factor - 1.0;
      FChannel2Samples[1] := Stream.GetBits(FChannel2CodeLength) *
        FChannel2Factor - 1.0;
      FChannel2Samples[2] := Stream.GetBits(FChannel2CodeLength) *
        FChannel2Factor - 1.0;
    end;
end;

procedure TSubbandLayer2Stereo.ReadScaleFactor(Stream: TBitStream;
  Header: THeader);
begin
  inherited ReadScaleFactor(Stream, Header);
  if (FChannel2Allocation <> 0) then
  begin
    case FChannel2SCFSI of
      0:
        begin
          FChannel2ScaleFactor[0] := CScaleFactors[Stream.GetBits(6)];
          FChannel2ScaleFactor[1] := CScaleFactors[Stream.GetBits(6)];
          FChannel2ScaleFactor[2] := CScaleFactors[Stream.GetBits(6)];
        end;

      1:
        begin
          FChannel2ScaleFactor[0] := CScaleFactors[Stream.GetBits(6)];
          FChannel2ScaleFactor[1] := FChannel2ScaleFactor[0];
          FChannel2ScaleFactor[2] := CScaleFactors[Stream.GetBits(6)];
        end;

      2:
        begin
          FChannel2ScaleFactor[0] := CScaleFactors[Stream.GetBits(6)];
          FChannel2ScaleFactor[1] := FChannel2ScaleFactor[0];
          FChannel2ScaleFactor[2] := FChannel2ScaleFactor[0];
        end;

      3:
        begin
          FChannel2ScaleFactor[0] := CScaleFactors[Stream.GetBits(6)];
          FChannel2ScaleFactor[1] := CScaleFactors[Stream.GetBits(6)];
          FChannel2ScaleFactor[2] := FChannel2ScaleFactor[1];
        end;
    end;
    PrepareSampleReading(Header, FChannel2Allocation, FChannel2GroupingTable,
      FChannel2Factor, FChannel2CodeLength, FChannel2C, FChannel2D);
  end;
end;

procedure TSubbandLayer2Stereo.ReadScaleFactorSelection(Stream: TBitStream;
  CRC: TCRC16);
begin
  if (FAllocation <> 0) then
  begin
    FSCFSI := Stream.GetBits(2);
    if (CRC <> nil) then
      CRC.AddBits(FSCFSI, 2);
  end;
  if (FChannel2Allocation <> 0) then
  begin
    FChannel2SCFSI := Stream.GetBits(2);
    if (CRC <> nil) then
      CRC.AddBits(FChannel2SCFSI, 2);
  end;
end;


{ TStereoBuffer }

constructor TStereoBuffer.Create;
begin
  inherited;
  FBufferSize := COutputBufferSize;
  GetMem(FOutput[0], FBufferSize * SizeOf(Single));
  GetMem(FOutput[1], FBufferSize * SizeOf(Single));
  Reset;
end;

destructor TStereoBuffer.Destroy;
begin
  Dispose(FOutput[0]);
  Dispose(FOutput[1]);
  inherited;
end;

procedure TStereoBuffer.Append(Channel: Cardinal; Value: Single);
begin
  FOutput[Channel, FBufferPos[Channel]] := Value;
  FBufferPos[Channel] := FBufferPos[Channel] + 1;
  Assert(FBufferPos[Channel] <= FBufferSize);
end;

procedure TStereoBuffer.Clear;
begin
  FillChar(FOutput[0]^, FBufferSize * SizeOf(Single), 0);
  FillChar(FOutput[1]^, FBufferSize * SizeOf(Single), 0);
end;

procedure TStereoBuffer.Reset;
begin
  FBufferPos[0] := 0;
  FBufferPos[1] := 0;
end;

procedure TStereoBuffer.SetBufferSize(const Value: Integer);
begin
  if FBufferSize <> Value then
  begin
    FBufferSize := Value;
    BufferSizeChanged;
  end;
end;

procedure TStereoBuffer.BufferSizeChanged;
begin
  ReallocMem(FOutput[0], FBufferSize * SizeOf(Single));
  ReallocMem(FOutput[1], FBufferSize * SizeOf(Single));
end;


{ TLayer3Decoder }

constructor TLayer3Decoder.Create(Stream: TBitStream; Header: THeader;
  FilterA, FilterB: TSynthesisFilter; Buffer: TStereoBuffer;
  Which_Ch: TChannels);
begin
  FBitStream := Stream;
  FHeader := Header;
  FFilter[0] := FilterA;
  FFilter[1] := FilterB;
  FBuffer := Buffer;
  FWhichChannels := Which_Ch;
  FFrameStart := 0;
  if (FHeader.Mode = cmSingleChannel) then
    FChannels := 1
  else
    FChannels := 2;
  if (FHeader.Version = mv1) then
    FMaxGranule := 2
  else
    FMaxGranule := 1;
  FSFreq := Cardinal(FHeader.SampleFrequency); // FHeader.Frequency;
  if (FHeader.Version = mv1) then
    FSFreq := FSFreq + 3;
  if (FChannels = 2) then
  begin
    case FWhichChannels of
      chLeft, chDownmix:
        begin
          FFirstChannel := 0;
          FLastChannel := 0;
        end;
      chRight:
        begin
          FFirstChannel := 1;
          FLastChannel := 1;
        end;
      chBoth:
        begin
          FFirstChannel := 0;
          FLastChannel := 1;
        end;
    else
      begin
        FFirstChannel := 0;
        FLastChannel := 1;
      end;
    end;
  end
  else
  begin
    FFirstChannel := 0;
    FLastChannel := 0;
  end;

  FillChar(FPrevBlock, SizeOf(FPrevBlock), 0);
  FNonZero[0] := 576;
  FNonZero[1] := 576;
  FBitReserve := TBitReserve.Create;
  GetMem(FSideInfo, SizeOf(TIIISideInfo));
end;

destructor TLayer3Decoder.Destroy;
begin
  FreeAndNil(FBitReserve);
  if Assigned(FSideInfo) then
    Dispose(FSideInfo);
  inherited Destroy;
end;

procedure TLayer3Decoder.Antialias(Channel, Granule: Cardinal);
var
  Ss, Sb18: Cardinal;
  Ssb18lim: Cardinal;
  GranuleInfo: PGranuleInfo;
  Bu, Bd: Single;
  SrcIdx: array [0 .. 1] of Integer;
begin
  GranuleInfo := @FSideInfo.Channel[Channel].Granule[Granule];

  // 31 alias-reduction operations between each pair of sub-bands
  // with 8 butterflies between each pair
  with GranuleInfo^ do
    if (WindowSwitchingFlag <> 0) and (BlockType = 2) and (MixedBlockFlag = 0)
    then
      Exit;

  with GranuleInfo^ do
    if (WindowSwitchingFlag <> 0) and (MixedBlockFlag <> 0) and (BlockType = 2)
    then
      Ssb18lim := 18
    else
      Ssb18lim := 558;

  Sb18 := 0;
  while (Sb18 < Ssb18lim) do
  begin
    for Ss := 0 to 7 do
    begin
      SrcIdx[0] := Sb18 + 17 - Ss;
      SrcIdx[1] := Sb18 + 18 + Ss;
      Bu := FOut1D[SrcIdx[0]];
      Bd := FOut1D[SrcIdx[1]];
      FOut1D[SrcIdx[0]] := (Bu * cs[Ss]) - (Bd * ca[Ss]);
      FOut1D[SrcIdx[1]] := (Bd * cs[Ss]) + (Bu * ca[Ss]);
    end;
    Inc(Sb18, 18);
  end;
end;

procedure TLayer3Decoder.Decode;
var
  NumSlots: Cardinal;
  FlushMain: Cardinal;
  Channel, Ss: Cardinal;
  Sb, Sb18: Cardinal;
  MainDataEnd: Integer;
  BytesToDiscard: Integer;
  i, Granule: Cardinal;
begin
  NumSlots := FHeader.Slots;
  GetSideInfo;
  for i := 0 to NumSlots - 1 do
    FBitReserve.WriteToBitstream(FBitStream.GetBits(8));
  MainDataEnd := FBitReserve.TotalBits shr 3; // of previous frame
  FlushMain := (FBitReserve.TotalBits and 7);
  if (FlushMain <> 0) then
  begin
    FBitReserve.GetBits(8 - FlushMain);
    Inc(MainDataEnd);
  end;

  BytesToDiscard := FFrameStart - MainDataEnd - FSideInfo.MainDataBegin;
  Inc(FFrameStart, NumSlots);

  if (BytesToDiscard < 0) then
    Exit;

  if (MainDataEnd > 4096) then
  begin
    Dec(FFrameStart, 4096);
    FBitReserve.RewindBytes(4096);
  end;

  while (BytesToDiscard > 0) do
  begin
    FBitReserve.GetBits(8);
    Dec(BytesToDiscard);
  end;

  for Granule := 0 to FMaxGranule - 1 do
  begin
    for Channel := 0 to FChannels - 1 do
    begin
      FPart2Start := FBitReserve.TotalBits;

      if (FHeader.Version = mv1) then
        GetScaleFactors(Channel, Granule)
      else
        GetLSFScaleFactors(Channel, Granule); // MPEG-2 LSF
      HuffmanDecode(Channel, Granule);
      DequantizeSample(FRO[Channel], Channel, Granule);
    end;

    Stereo(Granule);

    if (FWhichChannels = chDownmix) and (FChannels > 1) then
      DoDownmix;

    for Channel := FFirstChannel to FLastChannel do
    begin
      Reorder(@FLR[Channel], Channel, Granule);
      Antialias(Channel, Granule);
      Hybrid(Channel, Granule);

      Sb18 := 18;
      while (Sb18 < 576) do
      begin // Frequency inversion
        Ss := 1;
        while (Ss < CSsLimit) do
        begin
          FOut1D[Sb18 + Ss] := -FOut1D[Sb18 + Ss];
          Inc(Ss, 2);
        end;

        Inc(Sb18, 36);
      end;

      if (Channel = 0) or (FWhichChannels = chRight) then
      begin
        for Ss := 0 to CSsLimit - 1 do
        begin // Polyphase synthesis
          Sb := 0;
          Sb18 := 0;
          while (Sb18 < 576) do
          begin
            FFilter[0].InputSample(FOut1D[Sb18 + Ss], Sb);
            Inc(Sb18, 18);
            Inc(Sb);
          end;

          FFilter[0].CalculatePCMSamples;
        end;
      end
      else
      begin
        for Ss := 0 to CSsLimit - 1 do
        begin // Polyphase synthesis
          Sb := 0;
          Sb18 := 0;
          while (Sb18 < 576) do
          begin
            FFilter[1].InputSample(FOut1D[Sb18 + Ss], Sb);
            Inc(Sb18, 18);
            Inc(Sb);
          end;

          FFilter[1].CalculatePCMSamples;
        end;
      end;
    end;
  end;
end;

procedure TLayer3Decoder.DequantizeSample(var xr: TSArray;
  Channel, Granule: Cardinal);
var
  GranuleInfo: PGranuleInfo;
  Cb: Integer;
  j, NextCbBoundary: Integer;
  CbBegin, CbWidth: Integer;
  Index, t_index: Integer;
  GlobalGain: Single;
  xr1d: PIAP1024SingleArray;
  abv, idx: Cardinal;
begin
  GranuleInfo := @FSideInfo.Channel[Channel].Granule[Granule];
  Cb := 0;
  Index := 0;
  CbBegin := 0;
  CbWidth := 0;
  xr1d := @xr[0, 0];

  // choose correct scalefactor band per block type, initalize boundary
  if (GranuleInfo.WindowSwitchingFlag <> 0) and (GranuleInfo.BlockType = 2) then
  begin
    if (GranuleInfo.MixedBlockFlag <> 0) then
      NextCbBoundary := sfBandIndex[FSFreq].Long[1] // LONG blocks: 0,1,3
    else
    begin
      CbWidth := sfBandIndex[FSFreq].Short[1];
      NextCbBoundary := (CbWidth shl 2) - CbWidth;
      CbBegin := 0;
    end;
  end
  else
    NextCbBoundary := sfBandIndex[FSFreq].Long[1]; // LONG blocks: 0,1,3

  // Compute overall (global) scaling.
  GlobalGain := Power(2.0, (0.25 * (GranuleInfo.GlobalGain - 210.0)));

  for j := 0 to FNonZero[Channel] - 1 do
  begin
    if (FIs1D[j] = 0) then
      xr1d[j] := 0
    else
    begin
      abv := FIs1D[j];
      if (FIs1D[j] > 0) then
        xr1d[j] := GlobalGain * t_43[abv]
      else
        xr1d[j] := -GlobalGain * t_43[-abv];
    end;
  end;

  // apply formula per block type
  for j := 0 to FNonZero[Channel] - 1 do
  begin
    if (Index = NextCbBoundary) then
    begin // Adjust critical band boundary
      if (GranuleInfo.WindowSwitchingFlag <> 0) and (GranuleInfo.BlockType = 2)
      then
      begin
        if (GranuleInfo.MixedBlockFlag <> 0) then
        begin
          if (Index = sfBandIndex[FSFreq].Long[8]) then
          begin
            NextCbBoundary := sfBandIndex[FSFreq].Short[4];
            NextCbBoundary := (NextCbBoundary shl 2) - NextCbBoundary;
            Cb := 3;
            CbWidth := sfBandIndex[FSFreq].Short[4] - sfBandIndex
              [FSFreq].Short[3];
            CbBegin := sfBandIndex[FSFreq].Short[3];
            CbBegin := (CbBegin shl 2) - CbBegin;
          end
          else if (Index < sfBandIndex[FSFreq].Long[8]) then
          begin
            Inc(Cb);
            NextCbBoundary := sfBandIndex[FSFreq].Long[Cb + 1];
          end
          else
          begin
            Inc(Cb);
            NextCbBoundary := sfBandIndex[FSFreq].Short[Cb + 1];
            NextCbBoundary := (NextCbBoundary shl 2) - NextCbBoundary;
            CbBegin := sfBandIndex[FSFreq].Short[Cb];
            CbWidth := sfBandIndex[FSFreq].Short[Cb + 1] - CbBegin;
            CbBegin := (CbBegin shl 2) - CbBegin;
          end;
        end
        else
        begin
          Inc(Cb);
          NextCbBoundary := sfBandIndex[FSFreq].Short[Cb + 1];
          NextCbBoundary := (NextCbBoundary shl 2) - NextCbBoundary;
          CbBegin := sfBandIndex[FSFreq].Short[Cb];
          CbWidth := sfBandIndex[FSFreq].Short[Cb + 1] - CbBegin;
          CbBegin := (CbBegin shl 2) - CbBegin;
        end;
      end
      else
      begin // long blocks
        Inc(Cb);
        NextCbBoundary := sfBandIndex[FSFreq].Long[Cb + 1];
      end;
    end;

    // Do long/short dependent scaling operations
    if (GranuleInfo.WindowSwitchingFlag <> 0) and
      (((GranuleInfo.BlockType = 2) and (GranuleInfo.MixedBlockFlag = 0)) or
      ((GranuleInfo.BlockType = 2) and (GranuleInfo.MixedBlockFlag <> 0) and
      (j >= 36))) then
    begin
      t_index := (Index - CbBegin) div CbWidth;
      (* xr[Sb,Ss] *= pow(2.0, ((-2.0 * GranuleInfo->subblock_gain[t_index])
        -(0.5 * (1.0 + GranuleInfo->scalefac_scale)
        * scalefac[Channel].Short[t_index,Cb]))); *)
      idx := FScaleFac[Channel].Short[t_index, Cb]
        shl GranuleInfo.ScaleFactorScale;
      idx := idx + (GranuleInfo.SubblockGain[t_index] shl 2);
      xr1d[j] := xr1d[j] * CTwoToNegativeHalfPow[idx];
    end
    else
    begin // LONG block types 0,1,3 & 1st 2 subbands of switched blocks
      (* xr[Sb,Ss] := xr[Sb,Ss] * Power(2, -0.5 * (1 + GranuleInfo.ScaleFactorScale)
        * (FScaleFac[Channel].Long[Cb] + GranuleInfo.Preflag * pretab[Cb])); *)
      idx := FScaleFac[Channel].Long[Cb];
      if (GranuleInfo.Preflag <> 0) then
        idx := idx + pretab[Cb];

      idx := idx shl GranuleInfo.ScaleFactorScale;
      xr1d[j] := xr1d[j] * CTwoToNegativeHalfPow[idx];
    end;
    Inc(Index);
  end;

  for j := FNonZero[Channel] to 575 do
    xr1d[j] := 0.0;
end;

procedure TLayer3Decoder.DoDownmix;
var
  Ss, Sb: Cardinal;
begin
  for Sb := 0 to CSbLimit - 1 do
  begin
    Ss := 0;
    while (Ss < CSsLimit) do
    begin
      FLR[0, Sb, Ss] := (FLR[0, Sb, Ss] + FLR[1, Sb, Ss]) * 0.5;
      FLR[0, Sb, Ss + 1] := (FLR[0, Sb, Ss + 1] + FLR[1, Sb, Ss + 1]) * 0.5;
      FLR[0, Sb, Ss + 2] := (FLR[0, Sb, Ss + 2] + FLR[1, Sb, Ss + 2]) * 0.5;
      Inc(Ss, 3);
    end;
  end;
end;

procedure TLayer3Decoder.GetLSFScaleData(Channel, Granule: Cardinal);
var
  NewSLength: array [0 .. 3] of Cardinal;
  ScaleFactorComp: Cardinal;
  IntScalefactorComp: Cardinal;
  ModeExt: Cardinal;
  m: Integer;
  BlockTypeNumber: Integer;
  BlockNumber: Integer;
  GranuleInfo: PGranuleInfo;
  i, j: Cardinal;
begin
  ModeExt := FHeader.ModeExtension;
  GranuleInfo := @FSideInfo.Channel[Channel].Granule[Granule];
  ScaleFactorComp := GranuleInfo.ScaleFactorCompress;
  BlockNumber := 0;

  if (GranuleInfo.BlockType = 2) then
  begin
    if (GranuleInfo.MixedBlockFlag = 0) then
      BlockTypeNumber := 1
    else if (GranuleInfo.MixedBlockFlag = 1) then
      BlockTypeNumber := 2
    else
      BlockTypeNumber := 0;
  end
  else
    BlockTypeNumber := 0;

  if (not(((ModeExt = 1) or (ModeExt = 3)) and (Channel = 1))) then
  begin
    if (ScaleFactorComp < 400) then
    begin
      NewSLength[0] := (ScaleFactorComp shr 4) div 5;
      NewSLength[1] := (ScaleFactorComp shr 4) mod 5;
      NewSLength[2] := (ScaleFactorComp and $F) shr 2;
      NewSLength[3] := (ScaleFactorComp and 3);
      FSideInfo.Channel[Channel].Granule[Granule].Preflag := 0;
      BlockNumber := 0;
    end
    else if (ScaleFactorComp < 500) then
    begin
      NewSLength[0] := ((ScaleFactorComp - 400) shr 2) div 5;
      NewSLength[1] := ((ScaleFactorComp - 400) shr 2) mod 5;
      NewSLength[2] := (ScaleFactorComp - 400) and 3;
      NewSLength[3] := 0;
      FSideInfo.Channel[Channel].Granule[Granule].Preflag := 0;
      BlockNumber := 1;
    end
    else if (ScaleFactorComp < 512) then
    begin
      NewSLength[0] := (ScaleFactorComp - 500) div 3;
      NewSLength[1] := (ScaleFactorComp - 500) mod 3;
      NewSLength[2] := 0;
      NewSLength[3] := 0;
      FSideInfo.Channel[Channel].Granule[Granule].Preflag := 1;
      BlockNumber := 2;
    end;
  end;

  if ((((ModeExt = 1) or (ModeExt = 3)) and (Channel = 1))) then
  begin
    IntScalefactorComp := ScaleFactorComp shr 1;

    if (IntScalefactorComp < 180) then
    begin
      NewSLength[0] := IntScalefactorComp div 36;
      NewSLength[1] := (IntScalefactorComp mod 36) div 6;
      NewSLength[2] := (IntScalefactorComp mod 36) mod 6;
      NewSLength[3] := 0;
      FSideInfo.Channel[Channel].Granule[Granule].Preflag := 0;
      BlockNumber := 3;
    end
    else if (IntScalefactorComp < 244) then
    begin
      NewSLength[0] := ((IntScalefactorComp - 180) and $3F) shr 4;
      NewSLength[1] := ((IntScalefactorComp - 180) and $F) shr 2;
      NewSLength[2] := (IntScalefactorComp - 180) and 3;
      NewSLength[3] := 0;
      FSideInfo.Channel[Channel].Granule[Granule].Preflag := 0;
      BlockNumber := 4;
    end
    else if (IntScalefactorComp < 255) then
    begin
      NewSLength[0] := (IntScalefactorComp - 244) div 3;
      NewSLength[1] := (IntScalefactorComp - 244) mod 3;
      NewSLength[2] := 0;
      NewSLength[3] := 0;
      FSideInfo.Channel[Channel].Granule[Granule].Preflag := 0;
      BlockNumber := 5;
    end;
  end;

  FillChar(GScaleFactorBuffer[0], 45 * SizeOf(Cardinal), 0); // why 45, not 54?

  m := 0;
  for i := 0 to 3 do
    for j := 0 to CNrOfSFBBlock[BlockNumber, BlockTypeNumber, i] do
    begin
      if (NewSLength[i] = 0) then
        GScaleFactorBuffer[m] := 0
      else
        GScaleFactorBuffer[m] := FBitReserve.GetBits(NewSLength[i]);
      Inc(m);
    end;
end;

procedure TLayer3Decoder.GetLSFScaleFactors(Channel, Granule: Cardinal);
var
  m, Sfb: Cardinal;
  Window: Cardinal;
  GranuleInfo: PGranuleInfo;
begin
  m := 0;
  GranuleInfo := @FSideInfo.Channel[Channel].Granule[Granule];
  GetLSFScaleData(Channel, Granule);

  if ((GranuleInfo.WindowSwitchingFlag <> 0) and (GranuleInfo.BlockType = 2))
  then
  begin
    if (GranuleInfo.MixedBlockFlag <> 0) then
    begin
      // MIXED
      for Sfb := 0 to 7 do
      begin
        FScaleFac[Channel].Long[Sfb] := GScaleFactorBuffer[m];
        Inc(m);
      end;
      for Sfb := 3 to 11 do
        for Window := 0 to 2 do
        begin
          FScaleFac[Channel].Short[Window, Sfb] := GScaleFactorBuffer[m];
          Inc(m);
        end;
      for Window := 0 to 2 do
        FScaleFac[Channel].Short[Window, 12] := 0;
    end
    else
    begin
      // SHORT
      for Sfb := 0 to 11 do
        for Window := 0 to 2 do
        begin
          FScaleFac[Channel].Short[Window, Sfb] := GScaleFactorBuffer[m];
          Inc(m);
        end;
      for Window := 0 to 2 do
        FScaleFac[Channel].Short[Window, 12] := 0;
    end;
  end
  else
  begin
    // LONG types 0,1,3
    for Sfb := 0 to 20 do
    begin
      FScaleFac[Channel].Long[Sfb] := GScaleFactorBuffer[m];
      Inc(m);
    end;
    FScaleFac[Channel].Long[21] := 0; // Jeff
    FScaleFac[Channel].Long[22] := 0;
  end;
end;

procedure TLayer3Decoder.GetScaleFactors(Channel, Granule: Cardinal);
var
  Sfb, Window: Integer;
  GranuleInfo: PGranuleInfo;
  scale_comp: Integer;
  length0, length1: Integer;
begin
  GranuleInfo := @FSideInfo.Channel[Channel].Granule[Granule];
  scale_comp := GranuleInfo.ScaleFactorCompress;
  length0 := slen[0, scale_comp];
  length1 := slen[1, scale_comp];

  with FScaleFac[Channel] do
    if ((GranuleInfo.WindowSwitchingFlag <> 0) and (GranuleInfo.BlockType = 2))
    then
    begin
      if (GranuleInfo.MixedBlockFlag <> 0) then
      begin
        // MIXED
        for Sfb := 0 to 7 do
          Long[Sfb] := FBitReserve.GetBits
            (slen[0, GranuleInfo.ScaleFactorCompress]);
        for Sfb := 3 to 5 do
          for Window := 0 to 2 do
            Short[Window, Sfb] := FBitReserve.GetBits
              (slen[0, GranuleInfo.ScaleFactorCompress]);
        for Sfb := 6 to 11 do
          for Window := 0 to 2 do
            Short[Window, Sfb] := FBitReserve.GetBits
              (slen[1, GranuleInfo.ScaleFactorCompress]);
        Sfb := 12;
        for Window := 0 to 2 do
          Short[Window, Sfb] := 0;
      end
      else
      begin
        // SHORT
        Short[0, 0] := FBitReserve.GetBits(length0);
        Short[1, 0] := FBitReserve.GetBits(length0);
        Short[2, 0] := FBitReserve.GetBits(length0);
        Short[0, 1] := FBitReserve.GetBits(length0);
        Short[1, 1] := FBitReserve.GetBits(length0);
        Short[2, 1] := FBitReserve.GetBits(length0);
        Short[0, 2] := FBitReserve.GetBits(length0);
        Short[1, 2] := FBitReserve.GetBits(length0);
        Short[2, 2] := FBitReserve.GetBits(length0);
        Short[0, 3] := FBitReserve.GetBits(length0);
        Short[1, 3] := FBitReserve.GetBits(length0);
        Short[2, 3] := FBitReserve.GetBits(length0);
        Short[0, 4] := FBitReserve.GetBits(length0);
        Short[1, 4] := FBitReserve.GetBits(length0);
        Short[2, 4] := FBitReserve.GetBits(length0);
        Short[0, 5] := FBitReserve.GetBits(length0);
        Short[1, 5] := FBitReserve.GetBits(length0);
        Short[2, 5] := FBitReserve.GetBits(length0);
        Short[0, 6] := FBitReserve.GetBits(length1);
        Short[1, 6] := FBitReserve.GetBits(length1);
        Short[2, 6] := FBitReserve.GetBits(length1);
        Short[0, 7] := FBitReserve.GetBits(length1);
        Short[1, 7] := FBitReserve.GetBits(length1);
        Short[2, 7] := FBitReserve.GetBits(length1);
        Short[0, 8] := FBitReserve.GetBits(length1);
        Short[1, 8] := FBitReserve.GetBits(length1);
        Short[2, 8] := FBitReserve.GetBits(length1);
        Short[0, 9] := FBitReserve.GetBits(length1);
        Short[1, 9] := FBitReserve.GetBits(length1);
        Short[2, 9] := FBitReserve.GetBits(length1);
        Short[0, 10] := FBitReserve.GetBits(length1);
        Short[1, 10] := FBitReserve.GetBits(length1);
        Short[2, 10] := FBitReserve.GetBits(length1);
        Short[0, 11] := FBitReserve.GetBits(length1);
        Short[1, 11] := FBitReserve.GetBits(length1);
        Short[2, 11] := FBitReserve.GetBits(length1);
        Short[0, 12] := 0;
        Short[1, 12] := 0;
        Short[2, 12] := 0;
      end;
    end
    else
    begin
      // LONG types 0,1,3
      if ((FSideInfo.Channel[Channel].scfsi[0] = 0) or (Granule = 0)) then
      begin
        Long[0] := FBitReserve.GetBits(length0);
        Long[1] := FBitReserve.GetBits(length0);
        Long[2] := FBitReserve.GetBits(length0);
        Long[3] := FBitReserve.GetBits(length0);
        Long[4] := FBitReserve.GetBits(length0);
        Long[5] := FBitReserve.GetBits(length0);
      end;
      if ((FSideInfo.Channel[Channel].scfsi[1] = 0) or (Granule = 0)) then
      begin
        Long[6] := FBitReserve.GetBits(length0);
        Long[7] := FBitReserve.GetBits(length0);
        Long[8] := FBitReserve.GetBits(length0);
        Long[9] := FBitReserve.GetBits(length0);
        Long[10] := FBitReserve.GetBits(length0);
      end;

      if ((FSideInfo.Channel[Channel].scfsi[2] = 0) or (Granule = 0)) then
      begin
        Long[11] := FBitReserve.GetBits(length1);
        Long[12] := FBitReserve.GetBits(length1);
        Long[13] := FBitReserve.GetBits(length1);
        Long[14] := FBitReserve.GetBits(length1);
        Long[15] := FBitReserve.GetBits(length1);
      end;

      if ((FSideInfo.Channel[Channel].scfsi[3] = 0) or (Granule = 0)) then
      begin
        Long[16] := FBitReserve.GetBits(length1);
        Long[17] := FBitReserve.GetBits(length1);
        Long[18] := FBitReserve.GetBits(length1);
        Long[19] := FBitReserve.GetBits(length1);
        Long[20] := FBitReserve.GetBits(length1);
      end;

      Long[21] := 0;
      Long[22] := 0;
    end;
end;

// Reads the side info from the stream, assuming the entire
// frame has been read already.

// Mono   : 136 bits (= 17 bytes)
// cmStereo : 256 bits (= 32 bytes)
function TLayer3Decoder.GetSideInfo: Boolean;
var
  Channel, gr: Cardinal;
begin
  if (FHeader.Version = mv1) then
  begin
    FSideInfo.MainDataBegin := FBitStream.GetBits(9);
    if (FChannels = 1) then
      FSideInfo.PrivateBits := FBitStream.GetBits(5)
    else
      FSideInfo.PrivateBits := FBitStream.GetBits(3);

    for Channel := 0 to FChannels - 1 do
      with FSideInfo.Channel[Channel] do
      begin
        scfsi[0] := FBitStream.GetBits(1);
        scfsi[1] := FBitStream.GetBits(1);
        scfsi[2] := FBitStream.GetBits(1);
        scfsi[3] := FBitStream.GetBits(1);
      end;

    for gr := 0 to 1 do
    begin
      for Channel := 0 to FChannels - 1 do
        with FSideInfo.Channel[Channel].Granule[gr] do
        begin
          part2_3_length := FBitStream.GetBits(12);
          BigValues := FBitStream.GetBits(9);
          GlobalGain := FBitStream.GetBits(8);
          ScaleFactorCompress := FBitStream.GetBits(4);
          WindowSwitchingFlag := FBitStream.GetBits(1);
          if (WindowSwitchingFlag <> 0) then
          begin
            BlockType := FBitStream.GetBits(2);
            MixedBlockFlag := FBitStream.GetBits(1);

            TableSelect[0] := FBitStream.GetBits(5);
            TableSelect[1] := FBitStream.GetBits(5);

            SubblockGain[0] := FBitStream.GetBits(3);
            SubblockGain[1] := FBitStream.GetBits(3);
            SubblockGain[2] := FBitStream.GetBits(3);

            // Set region_count parameters since they are implicit in this case.
            if (BlockType = 0) then
            begin
              // Side info bad: BlockType == 0 in split block
              Exit(False);
            end
            else if (BlockType = 2) and (MixedBlockFlag = 0) then
              RegionCount[0] := 8
            else
              RegionCount[0] := 7;

            RegionCount[1] := 20 - RegionCount[0];
          end
          else
          begin
            TableSelect[0] := FBitStream.GetBits(5);
            TableSelect[1] := FBitStream.GetBits(5);
            TableSelect[2] := FBitStream.GetBits(5);
            RegionCount[0] := FBitStream.GetBits(4);
            RegionCount[1] := FBitStream.GetBits(3);
            BlockType := 0;
          end;
          Preflag := FBitStream.GetBits(1);
          ScaleFactorScale := FBitStream.GetBits(1);
          Count1TableSelect := FBitStream.GetBits(1);
        end;
    end;
  end
  else
  begin // MPEG-2 LSF
    FSideInfo.MainDataBegin := FBitStream.GetBits(8);
    if (FChannels = 1) then
      FSideInfo.PrivateBits := FBitStream.GetBits(1)
    else
      FSideInfo.PrivateBits := FBitStream.GetBits(2);
    for Channel := 0 to FChannels - 1 do
    begin
      FSideInfo.Channel[Channel].Granule[0].part2_3_length :=
        FBitStream.GetBits(12);
      FSideInfo.Channel[Channel].Granule[0].BigValues := FBitStream.GetBits(9);
      FSideInfo.Channel[Channel].Granule[0].GlobalGain := FBitStream.GetBits(8);
      FSideInfo.Channel[Channel].Granule[0].ScaleFactorCompress :=
        FBitStream.GetBits(9);
      FSideInfo.Channel[Channel].Granule[0].WindowSwitchingFlag :=
        FBitStream.GetBits(1);

      if (FSideInfo.Channel[Channel].Granule[0].WindowSwitchingFlag <> 0) then
        with FSideInfo.Channel[Channel].Granule[0] do
        begin
          BlockType := FBitStream.GetBits(2);
          MixedBlockFlag := FBitStream.GetBits(1);
          TableSelect[0] := FBitStream.GetBits(5);
          TableSelect[1] := FBitStream.GetBits(5);

          SubblockGain[0] := FBitStream.GetBits(3);
          SubblockGain[1] := FBitStream.GetBits(3);
          SubblockGain[2] := FBitStream.GetBits(3);

          // Set region_count parameters since they are implicit in this case.
          if (BlockType = 0) then
          begin
            // Side info bad: BlockType = 0 in split block
            Exit(False);
          end
          else if (BlockType = 2) and (MixedBlockFlag = 0) then
            RegionCount[0] := 8
          else
          begin
            RegionCount[0] := 7;
            RegionCount[1] := 20 - RegionCount[0];
          end;
        end
      else
        with FSideInfo.Channel[Channel].Granule[0] do
        begin
          TableSelect[0] := FBitStream.GetBits(5);
          TableSelect[1] := FBitStream.GetBits(5);
          TableSelect[2] := FBitStream.GetBits(5);
          RegionCount[0] := FBitStream.GetBits(4);
          RegionCount[1] := FBitStream.GetBits(3);
          BlockType := 0;
        end;

      FSideInfo.Channel[Channel].Granule[0].ScaleFactorScale :=
        FBitStream.GetBits(1);
      FSideInfo.Channel[Channel].Granule[0].Count1TableSelect :=
        FBitStream.GetBits(1);
    end;
  end;
  Result := True;
end;

procedure TLayer3Decoder.HuffmanDecode(Channel, Granule: Cardinal);
var
  i: Cardinal;
  x, y, v, w: Integer;
  part2_3_end: Integer;
  NumBits: Integer;
  Region1Start: Cardinal;
  Region2Start: Cardinal;
  Index: Integer;
  h: PHuffmanCodeTable;
begin
  part2_3_end := FPart2Start + FSideInfo.Channel[Channel].Granule[Granule]
    .part2_3_length;

  // Find region boundary for short block case
  with FSideInfo.Channel[Channel].Granule[Granule] do
    if ((WindowSwitchingFlag <> 0) and (BlockType = 2)) then
    begin
      // Region2.
      Region1Start := 36; // sfb[9/3]*3=36
      Region2Start := 576; // No Region2 for short block case
    end
    else
    begin // Find region boundary for long block case
      Region1Start := sfBandIndex[FSFreq].Long[RegionCount[0] + 1];
      Region2Start := sfBandIndex[FSFreq].Long
        [RegionCount[0] + RegionCount[1] + 2]; // MI
    end;

  Index := 0;
  // Read bigvalues area
  i := 0;
  with FSideInfo.Channel[Channel].Granule[Granule] do
    while (i < (BigValues shl 1)) do
    begin
      if (i < Region1Start) then
        h := @GHuffmanCodeTable[TableSelect[0]]
      else if (i < Region2Start) then
        h := @GHuffmanCodeTable[TableSelect[1]]
      else
        h := @GHuffmanCodeTable[TableSelect[2]];

      HuffmanDecoder(h, x, y, v, w, FBitReserve);

      FIs1D[Index] := x;
      FIs1D[Index + 1] := y;

      Inc(Index, 2);
      Inc(i, 2);
    end;

  // Read count1 area
  h := @GHuffmanCodeTable[FSideInfo.Channel[Channel].Granule[Granule]
    .Count1TableSelect + 32];
  NumBits := FBitReserve.TotalBits;

  while ((NumBits < part2_3_end) and (Index < 576)) do
  begin
    HuffmanDecoder(h, x, y, v, w, FBitReserve);

    FIs1D[Index] := v;
    FIs1D[Index + 1] := w;
    FIs1D[Index + 2] := x;
    FIs1D[Index + 3] := y;

    Inc(Index, 4);
    NumBits := FBitReserve.TotalBits;
  end;

  if (NumBits > part2_3_end) then
  begin
    FBitReserve.RewindBits(NumBits - part2_3_end);
    Dec(Index, 4);
  end;

  NumBits := FBitReserve.TotalBits;

  // Dismiss stuffing bits
  if (NumBits < part2_3_end) then
    FBitReserve.GetBits(part2_3_end - NumBits);

  // Zero out rest
  if (Index < 576) then
    FNonZero[Channel] := Index
  else
    FNonZero[Channel] := 576;

  // may not be necessary
  while (Index < 576) do
  begin
    FIs1D[Index] := 0;
    Inc(Index);
  end;
end;

procedure TLayer3Decoder.Hybrid(Channel, Granule: Cardinal);
var
  rawout: array [0 .. 35] of Single;
  bt: Cardinal;
  GranuleInfo: PGranuleInfo;
  tsOut: PIAP1024SingleArray;
  prvblk: PIAP1024SingleArray;
  Sb18: Cardinal;
begin
  GranuleInfo := @FSideInfo.Channel[Channel].Granule[Granule];

  Sb18 := 0;
  while (Sb18 < 576) do
  begin
    if (GranuleInfo.WindowSwitchingFlag <> 0) and
      (GranuleInfo.MixedBlockFlag <> 0) and (Sb18 < 36) then
      bt := 0
    else
      bt := GranuleInfo.BlockType;

    tsOut := @FOut1D[Sb18];
    InvMDCT(tsOut, @rawout, bt);

    // overlap addition
    prvblk := @FPrevBlock[Channel, Sb18];

    tsOut[0] := rawout[0] + prvblk[0];
    prvblk[0] := rawout[18];
    tsOut[1] := rawout[1] + prvblk[1];
    prvblk[1] := rawout[19];
    tsOut[2] := rawout[2] + prvblk[2];
    prvblk[2] := rawout[20];
    tsOut[3] := rawout[3] + prvblk[3];
    prvblk[3] := rawout[21];
    tsOut[4] := rawout[4] + prvblk[4];
    prvblk[4] := rawout[22];
    tsOut[5] := rawout[5] + prvblk[5];
    prvblk[5] := rawout[23];
    tsOut[6] := rawout[6] + prvblk[6];
    prvblk[6] := rawout[24];
    tsOut[7] := rawout[7] + prvblk[7];
    prvblk[7] := rawout[25];
    tsOut[8] := rawout[8] + prvblk[8];
    prvblk[8] := rawout[26];
    tsOut[9] := rawout[9] + prvblk[9];
    prvblk[9] := rawout[27];
    tsOut[10] := rawout[10] + prvblk[10];
    prvblk[10] := rawout[28];
    tsOut[11] := rawout[11] + prvblk[11];
    prvblk[11] := rawout[29];
    tsOut[12] := rawout[12] + prvblk[12];
    prvblk[12] := rawout[30];
    tsOut[13] := rawout[13] + prvblk[13];
    prvblk[13] := rawout[31];
    tsOut[14] := rawout[14] + prvblk[14];
    prvblk[14] := rawout[32];
    tsOut[15] := rawout[15] + prvblk[15];
    prvblk[15] := rawout[33];
    tsOut[16] := rawout[16] + prvblk[16];
    prvblk[16] := rawout[34];
    tsOut[17] := rawout[17] + prvblk[17];
    prvblk[17] := rawout[35];

    Inc(Sb18, 18);
  end;
end;

procedure TLayer3Decoder.IStereoKValues(IsPos, IOType, i: Cardinal);
begin
  if (IsPos = 0) then
  begin
    FK[0, i] := 1.0;
    FK[1, i] := 1.0;
  end
  else if (IsPos and 1 <> 0) then
  begin
    FK[0, i] := io[IOType, (IsPos + 1) shr 1];
    FK[1, i] := 1.0;
  end
  else
  begin
    FK[0, i] := 1.0;
    FK[1, i] := io[IOType, IsPos shr 1];
  end;
end;

procedure TLayer3Decoder.Reorder(xr: PSArray; Channel, Granule: Cardinal);
var
  GranuleInfo: PGranuleInfo;
  Freq, Freq3: Cardinal;
  Sfb: Cardinal;
  SfbStart: Cardinal;
  SfbStart3: Cardinal;
  SfbLines: Cardinal;
  SrcLine: Integer;
  DestLine: Integer;
  xr1d: PIAP1024SingleArray;
  Index: Cardinal;
begin
  xr1d := @xr[0, 0];
  GranuleInfo := @FSideInfo.Channel[Channel].Granule[Granule];
  if (GranuleInfo.WindowSwitchingFlag <> 0) and (GranuleInfo.BlockType = 2) then
  begin
    for Index := 0 to 575 do
      FOut1D[Index] := 0;

    if (GranuleInfo.MixedBlockFlag <> 0) then
    begin // NO REORDER FOR LOW 2 SUBBANDS
      for Index := 0 to 36 - 1 do
        FOut1D[Index] := xr1d[Index];

      // REORDERING FOR REST SWITCHED SHORT
      SfbStart := sfBandIndex[FSFreq].Short[3];
      SfbLines := Cardinal(sfBandIndex[FSFreq].Short[4]) - SfbStart;
      for Sfb := 3 to 12 do
      begin
        SfbStart3 := (SfbStart shl 2) - SfbStart;
        Freq3 := 0;
        for Freq := 0 to SfbLines - 1 do
        begin
          SrcLine := SfbStart3 + Freq;
          DestLine := SfbStart3 + Freq3;
          FOut1D[DestLine] := xr1d[SrcLine];
          Inc(SrcLine, SfbLines);
          Inc(DestLine);
          FOut1D[DestLine] := xr1d[SrcLine];
          Inc(SrcLine, SfbLines);
          Inc(DestLine);
          FOut1D[DestLine] := xr1d[SrcLine];
          Inc(Freq3, 3);
        end;
        SfbStart := sfBandIndex[FSFreq].Short[Sfb];
        SfbLines := Cardinal(sfBandIndex[FSFreq].Short[Sfb + 1]) - SfbStart;
      end;
    end
    else
      for Index := 0 to 575 do
        FOut1D[Index] := xr1d[reorder_table[FSFreq, Index]]; // pure short
  end
  else
    for Index := 0 to 575 do
      FOut1D[Index] := xr1d[Index]; // long blocks
end;

procedure TLayer3Decoder.SeekNotify;
begin
  FFrameStart := 0;
  FillChar(FPrevBlock, SizeOf(FPrevBlock), 0);
  FreeAndNil(FBitReserve);
  FBitReserve := TBitReserve.Create;
end;

procedure TLayer3Decoder.Stereo(Granule: Cardinal);
var
  Sb, Ss: Integer;
  IsPos: array [0 .. 575] of Cardinal;
  IsRatio: array [0 .. 575] of Single;
  GranuleInfo: PGranuleInfo;
  ModeExt, IOType: Cardinal;
  i, j, Lines: Integer;
  temp, temp2: Integer;
  MSStereo, IStereo: Boolean;
  lsf: Boolean;
  MaxSfb, SfbCnt, Sfb: Integer;
begin
  if (FChannels = 1) then
  begin
    // mono , bypass xr[0,,] to lr[0,,]
    for Sb := 0 to CSbLimit - 1 do
    begin
      Ss := 0;
      while (Ss < CSsLimit) do
      begin
        FLR[0, Sb, Ss] := FRO[0, Sb, Ss];
        FLR[0, Sb, Ss + 1] := FRO[0, Sb, Ss + 1];
        FLR[0, Sb, Ss + 2] := FRO[0, Sb, Ss + 2];
        Inc(Ss, 3);
      end;
    end;
  end
  else
  begin
    GranuleInfo := @FSideInfo.Channel[0].Granule[Granule];
    ModeExt := FHeader.ModeExtension;
    MSStereo := (FHeader.Mode = cmJointStereo) and (ModeExt and $2 <> 0);
    IStereo := (FHeader.Mode = cmJointStereo) and (ModeExt and $1 <> 0);
    lsf := (FHeader.Version = mv2lsf);
    IOType := (GranuleInfo.ScaleFactorCompress and 1);

    // initialization
    for i := 0 to 575 do
      IsPos[i] := 7;

    if IStereo then
    begin
      if (GranuleInfo.WindowSwitchingFlag <> 0) and (GranuleInfo.BlockType = 2)
      then
      begin
        if (GranuleInfo.MixedBlockFlag <> 0) then
        begin
          MaxSfb := 0;

          for j := 0 to 2 do
          begin
            SfbCnt := 2;
            Sfb := 12;
            while (Sfb >= 3) do
            begin
              i := sfBandIndex[FSFreq].Short[Sfb];
              Lines := sfBandIndex[FSFreq].Short[Sfb + 1] - i;
              i := (i shl 2) - i + (j + 1) * Lines - 1;

              while (Lines > 0) do
              begin
                if (FRO[1, ss_div[i], ss_mod[i]] <> 0.0) then
                begin
                  SfbCnt := Sfb;
                  Sfb := -10;
                  Lines := -10;
                end;

                Dec(Lines);
                Dec(i);
              end;

              Dec(Sfb);
            end;
            Sfb := SfbCnt + 1;

            if (Sfb > MaxSfb) then
              MaxSfb := Sfb;

            while (Sfb < 12) do
            begin
              temp := sfBandIndex[FSFreq].Short[Sfb];
              Sb := sfBandIndex[FSFreq].Short[Sfb + 1] - temp;
              i := (temp shl 2) - temp + j * Sb;

              while (Sb > 0) do
              begin
                IsPos[i] := FScaleFac[1].Short[j, Sfb];
                if (IsPos[i] <> 7) then
                  if (lsf) then
                    IStereoKValues(IsPos[i], IOType, i)
                  else
                    IsRatio[i] := CTan12[IsPos[i]];

                Inc(i);
                Dec(Sb);
              end;
              Inc(Sfb);
            end;

            Sfb := sfBandIndex[FSFreq].Short[10];
            Sb := sfBandIndex[FSFreq].Short[11] - Sfb;
            Sfb := (Sfb shl 2) - Sfb + j * Sb;
            temp := sfBandIndex[FSFreq].Short[11];
            Sb := sfBandIndex[FSFreq].Short[12] - temp;
            i := (temp shl 2) - temp + j * Sb;

            while (Sb > 0) do
            begin
              IsPos[i] := IsPos[Sfb];

              if (lsf) then
              begin
                FK[0, i] := FK[0, Sfb];
                FK[1, i] := FK[1, Sfb];
              end
              else
                IsRatio[i] := IsRatio[Sfb];

              Inc(i);
              Dec(Sb);
            end;
          end;

          if (MaxSfb <= 3) then
          begin
            i := 2;
            Ss := 17;
            Sb := -1;
            while (i >= 0) do
            begin
              if FRO[1, i, Ss] <> 0 then
              begin
                Sb := (i shl 4) + (i shl 1) + Ss;
                i := -1;
              end
              else
              begin
                Dec(Ss);
                if (Ss < 0) then
                begin
                  Dec(i);
                  Ss := 17;
                end;
              end;
            end;

            i := 0;
            while (sfBandIndex[FSFreq].Long[i] <= Sb) do
              Inc(i);

            Sfb := i;
            i := sfBandIndex[FSFreq].Long[i];
            while (Sfb < 8) do
            begin
              Sb := sfBandIndex[FSFreq].Long[Sfb + 1] - sfBandIndex[FSFreq]
                .Long[Sfb];
              while (Sb > 0) do
              begin
                IsPos[i] := FScaleFac[1].Long[Sfb];
                if (IsPos[i] <> 7) then
                  if (lsf) then
                    IStereoKValues(IsPos[i], IOType, i)
                  else
                    IsRatio[i] := CTan12[IsPos[i]];

                Inc(i);
                Inc(Sb);
              end;
              Inc(Sfb);
            end;
          end;
        end
        else
        begin // if (GranuleInfo->MixedBlockFlag)
          for j := 0 to 2 do
          begin
            SfbCnt := -1;
            Sfb := 12;
            while (Sfb >= 0) do
            begin
              temp := sfBandIndex[FSFreq].Short[Sfb];
              Lines := sfBandIndex[FSFreq].Short[Sfb + 1] - temp;
              i := (temp shl 2) - temp + (j + 1) * Lines - 1;

              while (Lines > 0) do
              begin
                if (FRO[1, ss_div[i], ss_mod[i]] <> 0) then
                begin
                  SfbCnt := Sfb;
                  Sfb := -10;
                  Lines := -10;
                end;

                Dec(Lines);
                Dec(i);
              end;
              Dec(Sfb);
            end;

            Sfb := SfbCnt + 1;
            while (Sfb < 12) do
            begin
              temp := sfBandIndex[FSFreq].Short[Sfb];
              Sb := sfBandIndex[FSFreq].Short[Sfb + 1] - temp;
              i := (temp shl 2) - temp + j * Sb;
              while (Sb > 0) do
              begin
                // Dec(Sb);
                IsPos[i] := FScaleFac[1].Short[j, Sfb];
                if (IsPos[i] <> 7) then
                  if (lsf) then
                    IStereoKValues(IsPos[i], IOType, i)
                  else
                    IsRatio[i] := CTan12[IsPos[i]];

                Inc(i);
                Dec(Sb);
              end;

              Inc(Sfb);
            end;

            temp := sfBandIndex[FSFreq].Short[10];
            temp2 := sfBandIndex[FSFreq].Short[11];
            Sb := temp2 - temp;
            Sfb := (temp shl 2) - temp + j * Sb;
            Sb := sfBandIndex[FSFreq].Short[12] - temp2;
            i := (temp2 shl 2) - temp2 + j * Sb;

            while (Sb > 0) do
            begin
              IsPos[i] := IsPos[Sfb];

              if (lsf) then
              begin
                FK[0, i] := FK[0, Sfb];
                FK[1, i] := FK[1, Sfb];
              end
              else
                IsRatio[i] := IsRatio[Sfb];

              Inc(i);
              Dec(Sb);
            end;
          end;
        end;
      end
      else
      begin // if (GranuleInfo->WindowSwitchingFlag ...
        i := 31;
        Ss := 17;
        Sb := 0;
        while (i >= 0) do
        begin
          if (FRO[1, i, Ss] <> 0.0) then
          begin
            Sb := (i shl 4) + (i shl 1) + Ss;
            i := -1;
          end
          else
          begin
            Dec(Ss);
            if (Ss < 0) then
            begin
              Dec(i);
              Ss := 17;
            end;
          end;
        end;

        i := 0;
        while (sfBandIndex[FSFreq].Long[i] <= Sb) do
          Inc(i);

        Sfb := i;
        i := sfBandIndex[FSFreq].Long[i];
        while (Sfb < 21) do
        begin
          Sb := sfBandIndex[FSFreq].Long[Sfb + 1] - sfBandIndex[FSFreq]
            .Long[Sfb];
          while (Sb > 0) do
          begin
            IsPos[i] := FScaleFac[1].Long[Sfb];
            if (IsPos[i] <> 7) then
              if (lsf) then
                IStereoKValues(IsPos[i], IOType, i)
              else
                IsRatio[i] := CTan12[IsPos[i]];

            Inc(i);
            Dec(Sb);
          end;
          Inc(Sfb);
        end;

        Sfb := sfBandIndex[FSFreq].Long[20];
        Sb := 576 - sfBandIndex[FSFreq].Long[21];
        while (Sb > 0) and (i < 576) do
        begin
          IsPos[i] := IsPos[Sfb]; // error here : i >=576
          if (lsf) then
          begin
            FK[0, i] := FK[0, Sfb];
            FK[1, i] := FK[1, Sfb];
          end
          else
            IsRatio[i] := IsRatio[Sfb];

          Inc(i);
          Dec(Sb);
        end;
      end;
    end;

    i := 0;
    for Sb := 0 to CSbLimit - 1 do
      for Ss := 0 to CSsLimit - 1 do
      begin
        if (IsPos[i] = 7) then
        begin
          if MSStereo then
          begin
            FLR[0, Sb, Ss] := (FRO[0, Sb, Ss] + FRO[1, Sb, Ss]) * 0.707106781;
            FLR[1, Sb, Ss] := (FRO[0, Sb, Ss] - FRO[1, Sb, Ss]) * 0.707106781;
          end
          else
          begin
            FLR[0, Sb, Ss] := FRO[0, Sb, Ss];
            FLR[1, Sb, Ss] := FRO[1, Sb, Ss];
          end;
        end
        else if IStereo then
        begin
          if lsf then
          begin
            FLR[0, Sb, Ss] := FRO[0, Sb, Ss] * FK[0, i];
            FLR[1, Sb, Ss] := FRO[0, Sb, Ss] * FK[1, i];
          end
          else
          begin
            FLR[1, Sb, Ss] := FRO[0, Sb, Ss] / (1 + IsRatio[i]);
            FLR[0, Sb, Ss] := FLR[1, Sb, Ss] * IsRatio[i];
          end;
        end;
        Inc(i);
      end;
  end;
end;

{ TCustomMpegAudio }

constructor TCustomMpegAudio.Create(Scan: Boolean = True);
begin
  FMPEGHeader := THeader.Create;
  FFilter[0] := TSynthesisFilter.Create;
  FFilter[1] := TSynthesisFilter.Create;
  FFilter[0].OnNewPCMSample := NewPCMSample;
  FFilter[1].OnNewPCMSample := NewPCMSample;
  FBuffer := TStereoBuffer.Create;
  FScan := Scan;
  FCRC := nil;
  FWhichC := chBoth;
  FBufferPos := 0;
end;

constructor TCustomMpegAudio.Create(FileName: TFileName; Scan: Boolean = True);
begin
  Create(Scan);
  FBitStream := TBitStream.Create(FileName);
  if FScan then
    ScanStream;
end;

constructor TCustomMpegAudio.Create(Stream: TStream; Scan: Boolean = True);
begin
  Create(Scan);
  FSampleFrames := 0;
  FTotalLength := 0;
  FBitStream := TBitStream.Create(Stream);
  if FScan then
    ScanStream;
end;

destructor TCustomMpegAudio.Destroy;
begin
  if Assigned(FCRC) then
    FreeAndNil(FCRC);
  if Assigned(FBitStream) then
    FreeAndNil(FBitStream);
  if Assigned(FLayer3) then
    FreeAndNil(FLayer3);

  FreeAndNil(FFilter[0]);
  FreeAndNil(FFilter[1]);
  FreeAndNil(FMPEGHeader);
  FreeAndNil(FBuffer);
end;

procedure TCustomMpegAudio.NewPCMSample(Sender: TObject; Sample: Single);
begin
  if Sender = FFilter[0] then
    FBuffer.Append(0, Sample)
  else
    FBuffer.Append(1, Sample)
end;

procedure TCustomMpegAudio.DoDecode;
var
  Mode: TChannelMode;
  NumSubBands, i: Cardinal;
  SubBands: array [0 .. 31] of TSubBand;
  ReadReady: Boolean;
  WriteReady: Boolean;
begin
  // is there a change in important parameters?
  // (bitrate switching is allowed)
  if (FMPEGHeader.Layer <> FLayer) then
  begin // layer switching is allowed
    if (FMPEGHeader.Layer = 3) then
      FLayer3 := TLayer3Decoder.Create(FBitStream, FMPEGHeader, FFilter[0],
        FFilter[1], FBuffer, FWhichC)
    else if (FLayer = 3) then
      FreeAndNil(FLayer3);
    FLayer := FMPEGHeader.Layer;
  end;

  if (FLayer <> 3) then
  begin
    NumSubBands := FMPEGHeader.NumberOfSubbands;
    Mode := FMPEGHeader.Mode;

    // create subband objects
    if (FLayer = 1) then
    begin // Layer I
      if (Mode = cmSingleChannel) then
        for i := 0 to NumSubBands - 1 do
          SubBands[i] := TSubBandLayer1.Create(i)
      else if (Mode = cmJointStereo) then
      begin
        for i := 0 to FMPEGHeader.IntensityStereoBound - 1 do
          SubBands[i] := TSubBandLayer1Stereo.Create(i);
        i := FMPEGHeader.IntensityStereoBound;
        while (Cardinal(i) < NumSubBands) do
        begin
          SubBands[i] := TSubBandLayer1IntensityStereo.Create(i);
          Inc(i);
        end;
      end
      else
        for i := 0 to NumSubBands - 1 do
          SubBands[i] := TSubBandLayer1Stereo.Create(i);
    end
    else
    begin // Layer II
      if (Mode = cmSingleChannel) then
        for i := 0 to NumSubBands - 1 do
          SubBands[i] := TSubBandLayer2.Create(i)
      else if (Mode = cmJointStereo) then
      begin
        for i := 0 to FMPEGHeader.IntensityStereoBound - 1 do
          SubBands[i] := TSubbandLayer2Stereo.Create(i);
        i := FMPEGHeader.IntensityStereoBound;
        while (Cardinal(i) < NumSubBands) do
        begin
          SubBands[i] := TSubbandLayer2IntensityStereo.Create(i);
          Inc(i);
        end;
      end
      else
        for i := 0 to NumSubBands - 1 do
          SubBands[i] := TSubbandLayer2Stereo.Create(i);
    end;

    // start to read audio data:
    for i := 0 to NumSubBands - 1 do
      SubBands[i].ReadAllocation(FBitStream, FMPEGHeader, FCRC);
    if (FLayer = 2) then
      for i := 0 to NumSubBands - 1 do
        TSubBandLayer2(SubBands[i]).ReadScaleFactorSelection(FBitStream, FCRC);

    if (FCRC = nil) or (FMPEGHeader.ChecksumOK) then
    begin // no checksums or checksum ok, continue reading from stream:
      for i := 0 to NumSubBands - 1 do
        SubBands[i].ReadScaleFactor(FBitStream, FMPEGHeader);
      repeat
        ReadReady := True;
        for i := 0 to NumSubBands - 1 do
          ReadReady := SubBands[i].ReadSampleData(FBitStream);
        repeat
          WriteReady := True;
          for i := 0 to NumSubBands - 1 do
            WriteReady := SubBands[i].PutNextSample(FWhichC, FFilter[0],
              FFilter[1]);
          FFilter[0].CalculatePCMSamples;
          if ((FWhichC = chBoth) and (Mode <> cmSingleChannel)) then
            FFilter[1].CalculatePCMSamples;
        until (WriteReady);
      until (ReadReady);
    end;

    for i := 0 to NumSubBands - 1 do
      FreeAndNil(SubBands[i]);
  end
  else
    FLayer3.Decode; // Layer III
end;

function TCustomMpegAudio.GetBitrate: Integer;
begin
  Result := FMPEGHeader.Bitrate;
end;

function TCustomMpegAudio.GetChannels: TChannels;
begin
  Result := FWhichC;
end;

function TCustomMpegAudio.GetSampleRate: Integer;
begin
  Result := FMPEGHeader.Frequency;
end;

function TCustomMpegAudio.GetLayer: Integer;
begin
  Result := FMPEGHeader.Layer;
end;

function TCustomMpegAudio.GetEstimatedLength: Integer;
begin
  Result := Round(FMPEGHeader.TotalMS(FBitStream) * 0.001);
end;

function TCustomMpegAudio.GetMode: TChannelMode;
begin
  Result := FMPEGHeader.Mode;
end;

function TCustomMpegAudio.GetVersion: TMpegVersion;
begin
  Result := FMPEGHeader.Version;
end;

function TCustomMpegAudio.ReadBuffer(chLeft, chRight: PIAPSingleFixedArray;
  Size: Integer): Integer;
var
  SamplesToRead: Integer;
begin
  Result := 0;
  if not Assigned(FBitStream) then
    Exit;

  repeat
    // check if buffer is empty
    if FBufferPos = 0 then
    begin
      // read next header and decode
      if (FBitStream.CurrentFrame < FMPEGHeader.MaxNumberOfFrames(FBitStream))
        and not FMPEGHeader.ReadHeader(FBitStream, FCRC) then
      begin
        if Assigned(FOnEndOfFile) then
          FOnEndOfFile(Self);
        Exit;
      end;
      FBuffer.Reset;
      DoDecode;
    end;

    // get the number of samples to read
    if (Size - Result) > (FBuffer.BufferSize - FBufferPos) then
      SamplesToRead := (FBuffer.BufferSize - FBufferPos)
    else
      SamplesToRead := (Size - Result);

    // copy data from buffers to output
    Move(FBuffer.OutputLeft[FBufferPos], chLeft[Result],
      SamplesToRead * SizeOf(Single));
    Move(FBuffer.OutputRight[FBufferPos], chRight[Result],
      SamplesToRead * SizeOf(Single));

    // advance buffer position and output sample count
    FBufferPos := (FBufferPos + SamplesToRead) mod FBuffer.BufferSize;
    Result := Result + SamplesToRead;
  until Result = Size;
  Assert(Result <= Size);
end;

function TCustomMpegAudio.ReadBuffer(chMono: PIAPSingleFixedArray;
  Size: Integer): Integer;
var
  SamplesToRead: Integer;
begin
  Result := 0;
  if not Assigned(FBitStream) then
    Exit;

  repeat
    // check if buffer is empty
    if FBufferPos = 0 then
    begin
      // read next header and decode
      if (FBitStream.CurrentFrame < FMPEGHeader.MaxNumberOfFrames(FBitStream))
        and not FMPEGHeader.ReadHeader(FBitStream, FCRC) then
      begin
        if Assigned(FOnEndOfFile) then
          FOnEndOfFile(Self);
        Exit;
      end;
      FBuffer.Reset;
      DoDecode;
    end;

    // get the number of samples to read
    if (Size - Result) > (FBuffer.BufferSize - FBufferPos) then
      SamplesToRead := (FBuffer.BufferSize - FBufferPos)
    else
      SamplesToRead := (Size - Result);

    // copy data from buffers to output
    Move(FBuffer.OutputLeft[FBufferPos], chMono[Result],
      SamplesToRead * SizeOf(Single));

    // advance buffer position and output sample count
    FBufferPos := (FBufferPos + SamplesToRead) mod FBuffer.BufferSize;
    Result := Result + SamplesToRead;
  until Result = Size;
  Assert(Result <= Size);
end;

procedure TCustomMpegAudio.ScanStream;
var
  Magic: array [0 .. 2] of AnsiChar;
  Version: record Major, Minor: Byte end;
  Flags: Byte;
  Nibbles: array [0 .. 3] of Byte;
  TagSize: Integer;
begin
  // Scan stream for ID3 Tags
  FID3v2TagEnd := 0;

  // scan for ID3v1 tags
  if FBitStream.Stream.Size >= 128 then
  begin
    FBitStream.Stream.Seek(-128, soFromEnd);
    FBitStream.Stream.Read(Magic, SizeOf(Magic));
    if Magic = 'TAG' then
    begin
      FBitStream.Stream.Seek(-3, soFromCurrent);
      FBitStream.Stream.Read(FId3Tag, SizeOf(FId3Tag));
      Assert(FId3Tag.Magic = 'TAG')
    end;
  end;

  // scan for ID3v2 tags
  if FBitStream.Stream.Size >= 10 then
  begin
    FBitStream.Stream.Seek(0, soFromBeginning);

    FBitStream.Stream.Read(Magic, SizeOf(Magic));
    if Magic = 'ID3' then
    begin
      FBitStream.Stream.Read(Version, SizeOf(Version));
      FBitStream.Stream.Read(Flags, SizeOf(Byte));
      if (Flags and $1F <> 0) then
        raise Exception.Create('ID3v2 Tag Error!');

      FBitStream.Stream.Read(Nibbles, SizeOf(Nibbles));
      TagSize := Nibbles[0] shl 21 + Nibbles[1] shl 14 + Nibbles[2] shl 7 +
        Nibbles[3];
      FID3v2TagEnd := FBitStream.Stream.Position + TagSize;

      try
        ParseID3v2Tag;
      finally
        FBitStream.Stream.Position := FID3v2TagEnd;
      end;
    end
    else
      FBitStream.Stream.Seek(0, soFromBeginning);
  end;

  FSampleFrames := 0;
  FTotalLength := 0;
  while FMPEGHeader.ReadHeader(FBitStream, FCRC) do
  begin
    FTotalLength := FTotalLength + FMPEGHeader.MSPerFrame;
    FSampleFrames := FSampleFrames + 1152;
  end;
  FBitStream.Reset;
end;

procedure TCustomMpegAudio.ParseID3v2Tag;
var
  ChunkName: TChunkName;
  ChunkSize: Integer;
  Flags: array [0 .. 1] of Byte;
  Nibbles: array [0 .. 3] of Byte;
begin
  with FBitStream.Stream do
    while Position < FID3v2TagEnd do
      try
        Read(ChunkName, SizeOf(TChunkName));
        Read(Nibbles, SizeOf(Nibbles));
        Read(Flags, SizeOf(Word));

        if ((Flags[0] and $1F) <> 0) or (Flags[1] and $1F <> 0) then
          raise Exception.Create('ID3v2 Tag Error!');

        if ChunkName = #0#0#0#0 then
          Exit;

        ChunkSize := Nibbles[0] shl 21 + Nibbles[1] shl 14 + Nibbles[2] shl 7 +
          Nibbles[3];

        // [#sec4.20 Audio encryption]
        if ChunkName = 'AENC' then
        // [#sec4.15 Attached picture]
        else if ChunkName = 'APIC' then
         // [#sec4.11 Comments]
        else if ChunkName = 'COMM' then
         // [#sec4.25 Commercial frame]
        else if ChunkName = 'COMR' then
        // [#sec4.26 Encryption method registration]
        else if ChunkName = 'ENCR' then
        // [#sec4.13 Equalization]
        else if ChunkName = 'EQUA' then
        // [#sec4.6 Event timing codes]
        else if ChunkName = 'ETCO' then
        // [#sec4.16 General encapsulated object]
        else if ChunkName = 'GEOB' then
        // [#sec4.27 Group identification registration]
        else if ChunkName = 'GRID' then
        // [#sec4.4 Involved people list]
        else if ChunkName = 'IPLS' then
        // [#sec4.21 Linked information]
        else if ChunkName = 'LINK' then
        // [#sec4.5 Music CD identifier]
        else if ChunkName = 'MCDI' then
        // [#sec4.7 MPEG location lookup table]
        else if ChunkName = 'MLLT' then
        // [#sec4.24 Ownership frame]
        else if ChunkName = 'OWNE' then
        // [#sec4.28 Private frame]
        else if ChunkName = 'PRIV' then
          ReadPrivate(ChunkSize)
        // [#sec4.17 Play counter]
        else if ChunkName = 'PCNT' then
        // [#sec4.18 Popularimeter]
        else if ChunkName = 'POPM' then
        // [#sec4.22 Position synchronisation frame]
        else if ChunkName = 'POSS' then
        // [#sec4.19 Recommended buffer size]
        else if ChunkName = 'RBUF' then
        // [#sec4.12 Relative volume adjustment]
        else if ChunkName = 'RVAD' then
        // [#sec4.14 Reverb]
        else if ChunkName = 'RVRB' then
        // [#sec4.10 Synchronized lyric/text]
        else if ChunkName = 'SYLT' then
        // [#sec4.8 Synchronized tempo codes]
        else if ChunkName = 'SYTC' then
        // [#TALB Album/Movie/Show title]
        else if ChunkName = 'TALB' then
          ReadAlbumTitle(ChunkSize)
        // [#TBPM BPM (beats per minute)]
        else if ChunkName = 'TBPM' then
        // [#TCOM Composer]
        else if ChunkName = 'TCOM' then
        // [#TCON Content type]
        else if ChunkName = 'TCON' then
          ReadContentType(ChunkSize)
        // [#TCOP Copyright message]
        else if ChunkName = 'TCOP' then
        // [#TDAT Date]
        else if ChunkName = 'TDAT' then
        // [#TDLY Playlist delay]
        else if ChunkName = 'TDLY' then
        // [#TENC Encoded by]
        else if ChunkName = 'TENC' then
        // [#TEXT Lyricist/Text writer]
        else if ChunkName = 'TEXT' then
        // [#TFLT File type]
        else if ChunkName = 'TFLT' then
        // [#TIME Time]
        else if ChunkName = 'TIME' then
        // [#TIT1 Content group description]
        else if ChunkName = 'TIT1' then
        // [#TIT2 Title/songname/content description]
        else if ChunkName = 'TIT2' then
          ReadTitle(ChunkSize)
        // [#TIT3 Subtitle/Description refinement]
        else if ChunkName = 'TIT3' then
        // [#TKEY Initial key]
        else if ChunkName = 'TKEY' then
        // [#TLAN Language(s)]
        else if ChunkName = 'TLAN' then
          ReadLanguage(ChunkSize)
        // [#TLEN Length]
        else if ChunkName = 'TLEN' then
        // [#TMED Media type]
        else if ChunkName = 'TMED' then
        // [#TOAL Original album/movie/show title]
        else if ChunkName = 'TOAL' then
        // [#TOFN Original filename]
        else if ChunkName = 'TOFN' then
        // [#TOLY Original lyricist(s)/text writer(s)]
        else if ChunkName = 'TOLY' then
        // [#TOPE Original artist(s)/performer(s)]
        else if ChunkName = 'TOPE' then
        // [#TORY Original release year]
        else if ChunkName = 'TORY' then
        // [#TOWN File owner/licensee]
        else if ChunkName = 'TOWN' then
        // [#TPE1 Lead performer(s)/Soloist(s)]
        else if ChunkName = 'TPE1' then
          ReadMainArtist(ChunkSize)
        else if ChunkName = 'TPE2' then
          ReadBand(ChunkSize)
        // [#TPE2 Band/orchestra/accompaniment]
        // [#TPE3 Conductor/performer refinement]
        else if ChunkName = 'TPE3' then
        // [#TPE4 Interpreted, remixed, or otherwise modified by]
        else if ChunkName = 'TPE4' then
        // [#TPOS Part of a set]
        else if ChunkName = 'TPOS' then
        // [#TPUB Publisher]
        else if ChunkName = 'TPUB' then
          ReadPublisher(ChunkSize)
        // [#TRCK Track number/Position in set]
        else if ChunkName = 'TRCK' then
          ReadTrackNumber(ChunkSize)
        // [#TRDA Recording dates]
        else if ChunkName = 'TRDA' then
        // [#TRSN Internet radio station name]
        else if ChunkName = 'TRSN' then
        // [#TRSO Internet radio station owner]
        else if ChunkName = 'TRSO' then
        // [#TSIZ Size]
        else if ChunkName = 'TSIZ' then
        // [#TSRC ISRC (international standard recording code)]
        else if ChunkName = 'TSRC' then
        // [#TSEE Software/Hardware and settings used for encoding]
        else if ChunkName = 'TSSE' then
        // [#TYER Year]
        else if ChunkName = 'TYER' then
          ReadYear(ChunkSize)
        // [#TXXX User defined text information frame]
        else if ChunkName = 'TXXX' then
        // [#sec4.1 Unique file identifier]
        else if ChunkName = 'UFID' then
        // [#sec4.23 Terms of use]
        else if ChunkName = 'USER' then
        // [#sec4.9 Unsychronized lyric/text transcription]
        else if ChunkName = 'USLT' then
        // [#WCOM Commercial information]
        else if ChunkName = 'WCOM' then
        // [#WCOP Copyright/Legal information]
        else if ChunkName = 'WCOP' then
        // [#WOAF Official audio file webpage]
        else if ChunkName = 'WOAF' then
        // [#WOAR Official artist/performer webpage]
        else if ChunkName = 'WOAR' then
        // [#WOAS Official audio source webpage]
        else if ChunkName = 'WOAS' then
        // [#WORS Official internet radio station homepage]
        else if ChunkName = 'WORS' then
        // [#WPAY Payment]
        else if ChunkName = 'WPAY' then
        // [#WPUB Publishers official webpage]
        else if ChunkName = 'WPUB' then
        // [#WXXX User defined URL link frame]
        else if ChunkName = 'WXXX' then;

        if ChunkSize = 0 then
          Exit
        else
          Position := Position + ChunkSize;
      except
        Break;
      end;
end;

procedure TCustomMpegAudio.ReadAlbumTitle(ChunkSize: Integer);
var
  Encoding: Byte;
  Album: string;
begin
  with FBitStream.Stream do
  begin
    Read(Encoding, 1);
    SetLength(Album, ChunkSize);
    Read(Album[1], ChunkSize);
    // Move(Album[1], FId3Tag.Album[1], min(ChunkSize, SizeOf(FId3Tag.Album)));
    Position := Position - ChunkSize;
  end;
end;

procedure TCustomMpegAudio.ReadMainArtist(ChunkSize: Integer);
var
  Encoding: Byte;
  Artist: string;
begin
  with FBitStream.Stream do
  begin
    Read(Encoding, 1);
    SetLength(Artist, ChunkSize);
    Read(Artist[1], ChunkSize);
    // Move(Artist[1], FId3Tag.Artist[1], min(ChunkSize, SizeOf(FId3Tag.Artist)));
    Position := Position - ChunkSize;
  end;
end;

procedure TCustomMpegAudio.ReadPrivate(ChunkSize: Integer);
begin
  // do nothing yet
end;

procedure TCustomMpegAudio.ReadPublisher(ChunkSize: Integer);
begin
  // do nothing yet
end;

procedure TCustomMpegAudio.ReadBand(ChunkSize: Integer);
begin
  // do nothing yet
end;

procedure TCustomMpegAudio.ReadTrackNumber(ChunkSize: Integer);
begin
  // do nothing yet
end;

procedure TCustomMpegAudio.ReadTitle(ChunkSize: Integer);
var
  Encoding: Byte;
  Title: string;
begin
  with FBitStream.Stream do
  begin
    Read(Encoding, 1);
    SetLength(Title, ChunkSize);
    Read(Title[1], ChunkSize);
    // Move(Title[1], FId3Tag.Title[1], min(ChunkSize, SizeOf(FId3Tag.Title)));
    Position := Position - ChunkSize;
  end;
end;

procedure TCustomMpegAudio.ReadContentType(ChunkSize: Integer);
var
  Encoding: Byte;
  ContentType: string;
begin
  with FBitStream.Stream do
  begin
    Read(Encoding, 1);
    SetLength(ContentType, ChunkSize);
    Read(ContentType[1], ChunkSize);
    Position := Position - ChunkSize;
  end;
end;

procedure TCustomMpegAudio.ReadLanguage(ChunkSize: Integer);
var
  Encoding: Byte;
  Language: string;
begin
  with FBitStream.Stream do
  begin
    Read(Encoding, 1);
    SetLength(Language, ChunkSize);
    Read(Language[1], ChunkSize);
    Position := Position - ChunkSize;
  end;
end;

procedure TCustomMpegAudio.ReadYear(ChunkSize: Integer);
var
  Encoding: Byte;
  Year: string;
begin
  with FBitStream.Stream do
  begin
    Read(Encoding, 1);
    SetLength(Year, ChunkSize);
    Read(Year[1], ChunkSize);
    // Move(Year[1], FId3Tag.Year[1], min(ChunkSize, SizeOf(FId3Tag.Year)));
    Position := Position - ChunkSize;
  end;
end;

procedure TCustomMpegAudio.Reset;
begin
  FCurrentPos := 0;
  FBitStream.Reset;
end;

function TCustomMpegAudio.GetAlbum: string;
begin
  Result := string(PAnsiChar(@FId3Tag.Album[1]));
end;

function TCustomMpegAudio.GetArtist: string;
begin
  Result := string(PAnsiChar(@FId3Tag.Artist[1]));
end;

function TCustomMpegAudio.GetComment: string;
begin
  Result := string(PAnsiChar(@FId3Tag.Comment[1]));
end;

function TCustomMpegAudio.GetGenre: TMusicGenre;
begin
  Result := TMusicGenre(FId3Tag.Genre);
end;

function TCustomMpegAudio.GetTitle: string;
begin
  Result := string(PAnsiChar(@FId3Tag.Title[1]));
end;

function TCustomMpegAudio.GetTotalLength: Single;
begin
  if FTotalLength > 0 then
    Result := FTotalLength * 0.001
  else
    Result := GetEstimatedLength;
end;

function TCustomMpegAudio.GetTrackNumber: Byte;
begin
  if FId3Tag.Comment[29] = #0 then
    Result := Byte(FId3Tag.Comment[30])
  else
    Result := 0;
end;

function TCustomMpegAudio.GetYear: string;
begin
  Result := string(PAnsiChar(@FId3Tag.Year[1]));
end;

begin
  CalculateCosTable;
  SetHuffTable(@GHuffmanCodeTable[0], '0', 0, 0, 0, 0, -1, nil, nil,
    @CValTab0, 0);
  SetHuffTable(@GHuffmanCodeTable[1], '1', 2, 2, 0, 0, -1, nil, nil,
    @CValTab1, 7);
  SetHuffTable(@GHuffmanCodeTable[2], '2', 3, 2, 0, 0, -1, nil, nil,
    @CValTab2, 17);
  SetHuffTable(@GHuffmanCodeTable[3], '3', 3, 3, 0, 0, -1, nil, nil,
    @CValTab3, 17);
  SetHuffTable(@GHuffmanCodeTable[4], '4', 0, 0, 0, 0, -1, nil, nil,
    @CValTab4, 0);
  SetHuffTable(@GHuffmanCodeTable[5], '5', 4, 4, 0, 0, -1, nil, nil,
    @CValTab5, 31);
  SetHuffTable(@GHuffmanCodeTable[6], '6', 4, 4, 0, 0, -1, nil, nil,
    @CValTab6, 31);
  SetHuffTable(@GHuffmanCodeTable[7], '7', 6, 6, 0, 0, -1, nil, nil,
    @CValTab7, 71);
  SetHuffTable(@GHuffmanCodeTable[8], '8', 6, 6, 0, 0, -1, nil, nil,
    @CValTab8, 71);
  SetHuffTable(@GHuffmanCodeTable[9], '9', 6, 6, 0, 0, -1, nil, nil,
    @CValTab9, 71);

  SetHuffTable(@GHuffmanCodeTable[10], '10', 8, 8, 0, 0, -1, nil, nil,
    @CValTab10, 127);
  SetHuffTable(@GHuffmanCodeTable[11], '11', 8, 8, 0, 0, -1, nil, nil,
    @CValTab11, 127);
  SetHuffTable(@GHuffmanCodeTable[12], '12', 8, 8, 0, 0, -1, nil, nil,
    @CValTab12, 127);
  SetHuffTable(@GHuffmanCodeTable[13], '13', 16, 16, 0, 0, -1, nil, nil,
    @CValTab13, 511);
  SetHuffTable(@GHuffmanCodeTable[14], '14', 0, 0, 0, 0, -1, nil, nil,
    @CValTab14, 0);
  SetHuffTable(@GHuffmanCodeTable[15], '15', 16, 16, 0, 0, -1, nil, nil,
    @CValTab15, 511);
  SetHuffTable(@GHuffmanCodeTable[16], '16', 16, 16, 1, 1, -1, nil, nil,
    @CValTab16, 511);
  SetHuffTable(@GHuffmanCodeTable[17], '17', 16, 16, 2, 3, 16, nil, nil,
    @CValTab16, 511);
  SetHuffTable(@GHuffmanCodeTable[18], '18', 16, 16, 3, 7, 16, nil, nil,
    @CValTab16, 511);
  SetHuffTable(@GHuffmanCodeTable[19], '19', 16, 16, 4, 15, 16, nil, nil,
    @CValTab16, 511);

  SetHuffTable(@GHuffmanCodeTable[20], '20', 16, 16, 6, 63, 16, nil, nil,
    @CValTab16, 511);
  SetHuffTable(@GHuffmanCodeTable[21], '21', 16, 16, 8, 255, 16, nil, nil,
    @CValTab16, 511);
  SetHuffTable(@GHuffmanCodeTable[22], '22', 16, 16, 10, 1023, 16, nil, nil,
    @CValTab16, 511);
  SetHuffTable(@GHuffmanCodeTable[23], '23', 16, 16, 13, 8191, 16, nil, nil,
    @CValTab16, 511);
  SetHuffTable(@GHuffmanCodeTable[24], '24', 16, 16, 4, 15, -1, nil, nil,
    @CValTab24, 512);
  SetHuffTable(@GHuffmanCodeTable[25], '25', 16, 16, 5, 31, 24, nil, nil,
    @CValTab24, 512);
  SetHuffTable(@GHuffmanCodeTable[26], '26', 16, 16, 6, 63, 24, nil, nil,
    @CValTab24, 512);
  SetHuffTable(@GHuffmanCodeTable[27], '27', 16, 16, 7, 127, 24, nil, nil,
    @CValTab24, 512);
  SetHuffTable(@GHuffmanCodeTable[28], '28', 16, 16, 8, 255, 24, nil, nil,
    @CValTab24, 512);
  SetHuffTable(@GHuffmanCodeTable[29], '29', 16, 16, 9, 511, 24, nil, nil,
    @CValTab24, 512);

  SetHuffTable(@GHuffmanCodeTable[30], '30', 16, 16, 11, 2047, 24, nil, nil,
    @CValTab24, 512);
  SetHuffTable(@GHuffmanCodeTable[31], '31', 16, 16, 13, 8191, 24, nil, nil,
    @CValTab24, 512);
  SetHuffTable(@GHuffmanCodeTable[32], '32', 1, 16, 0, 0, -1, nil, nil,
    @CValTab32, 31);
  SetHuffTable(@GHuffmanCodeTable[33], '33', 1, 16, 0, 0, -1, nil, nil,
    @CValTab32, 31);
end.
