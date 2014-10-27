unit IAP.AudioFile.MPEG;

interface

{$DEFINE SEEK_STOP}

uses
  SysUtils, Classes, IAP.Types, IAP.AudioFile.CRC, IAP.AudioFile.SynthFilter,
  IAP.AudioFile.BitReserve, IAP.AudioFile.StereoBuffer, IAP.AudioFile.Layer3;

type
  TSyncMode = (smInitialSync, imStrictSync);
  TChannels = (chBoth, chLeft, chRight, chDownmix);
  TMpegVersion = (mv2lsf, mv1);
  TChannelMode = (cmStereo, cmJointStereo, cmDualChannel, cmSingleChannel);
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

function SwapInt32(Value: Cardinal): Cardinal; inline;

implementation

uses
  Math, IAP.AudioFile.Huffman, IAP.AudioFile.InvMDCT;

var
  GScaleFactorBuffer: array [0 .. 53] of Cardinal;

const
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

function SwapInt32(Value: Cardinal): Cardinal; inline;
begin
  Result := (Value shl 24) or ((Value shl 8) and $FF0000) or
    ((Value shr 8) and $FF00) or (Value shr 24);
end;

{ TBitStream }

const
  CBufferIntSize = 433;
  // max. 1730 bytes per frame: 144 * 384kbit/s / 32000 Hz + 2 Bytes CRC

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

end.
