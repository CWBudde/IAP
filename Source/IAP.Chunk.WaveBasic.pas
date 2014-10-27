unit IAP.Chunk.WaveBasic;

interface

uses
  Classes, SysUtils, IAP.Types, IAP.Chunk.Classes;

type
  TWavEncoding = (etUnknown = $0, etPcm = $1, etMsAdPcm = $2, etPcmFloat = $3,
    etCompaqVSELP = $4, etIbmCVSD = $5, etALaw = $6, etMuLaw = $7,
    etMicrosoftDTS = $8, etDRM = $9, etWMA9Speech = $A, etWMRTVoice = $B,
    etOKIAdPcm = $10, etDVIAdPcm = $11, etMediaSpaceAdPcm = $12,
    etSierraAdPcm = $13, etG723AdPcm = $14, etDIGISTD = $15, etDIGIFIX = $16,
    etDiaLogicAdPcm = $17, etMVAdPcm = $18, etHPCU = $19,
    etHPDynamicVoice = $1A, etYamahaAdPcm = $20, etSONARC = $21,
    etTrueSpeech = $22, etECHOSC1 = $23, etAF36 = $24, etAPTX = $25,
    etAF10 = $26, etProsody1612 = $27, etMergingTechLRC = $28, etDolbyAC2 = $30,
    etGSM610 = $31, etMSNAudio = $32, etAntexAdPcmE = $33, etResVQLPC1 = $34,
    etResVQLPC2 = $35, etDigiAdPcm = $36, etResCR10 = $37, etVBXAdPcm = $38,
    etIMAAdPcm = $39, etECHOSC3 = $3A, etRockwellAdPcm = $3B, etDIGITALK = $3C,
    etXebecMultimedia = $3D, etG721AdPcm = $40, etAntexG728CELP = $41,
    etMicrosoftMSG723 = $42, etIBMAVCAdPcm = $43, etITU_TG726 = $45,
    etMPEG = $50, etRT23orPAC = $51, etInSoftRT24 = $52, etInSoftPAC = $53,
    etMP3 = $55, etCirrus = $59, etCirrusLogic = $60, etESSTechPCM = $61,
    etVoxwareInc = $62, CanopusATRAC = $63, etAPICOMG726AdPcm = $64,
    etAPICOMG722AdPcm = $65, etMicrosoftDSAT = $66, etMSDSATDISPLAY = $67,
    etXboxAdPcm = $69, etVoxwareAC8 = $70, etVoxwareAC10 = $71,
    etVoxwareAC16 = $72, etVoxwareAC20 = $73, etVoxwareMetaVoice = $74,
    etVoxwareMetaSound = $75, etVoxwareRT29HW = $76, etVoxwareVR12 = $77,
    etVoxwareVR18 = $78, etVoxwareTQ40 = $79, etVoxwareSC3A = $7A,
    etVoxwareSC3B = $7B, etSoundsoft = $80, etVoxwareTQ60 = $81,
    etMicrosoftMSRT24 = $82, etATandTG729A = $83, etMP_MVI_MV12 = $84,
    etDF_G726 = $85, etDF_GSM610 = $86, etItrdSystemsAudio = $88,
    etOnlive = $89, etM_FTSX20 = $8A, etITSASG721AdPcm = $8B,
    etConvediaG729 = $8C, etNSpC_Inc = $8D, etSiemensSBC24 = $91,
    etSF_DolbyAC3APDIF = $92, etMediaSonicG723 = $93, etProsody8kbps = $94,
    etZyXELAdPcm = $97, etPhilipsLPCBB = $98, etStuderProPacked = $99,
    etMaldenPhonyTalk = $A0, etRacalRecorderGSM = $A1, etRecorderG720a = $A2,
    etRacalG723_1 = $A3, etRacalTetraACELP = $A4, etNECAAC = $B0,
    etExtended = $FE, etAAC = $FF, etRhetorexAdPcm = $100, etIBMuLaw = $101,
    etIBMaLaw = $102, etIBMAdPcm = $103, etVivoG723 = $111, etVivoSiren = $112,
    etCELP = $120, etGRUNDIG = $121, etDigitalG723 = $123,
    etSanyoLD_AdPcm = $125, etSiproLabACEPLNET = $130, etSL_ACELP4800 = $131,
    etSL_ACELP8V3 = $132, etSL_G729 = $133, etSL_G729A = $134,
    etSL_Kelvin = $135, etVoiceAgeAMR = $136, etG726AdPcm = $140,
    etQC_PureVoice = $150, etQC_HalfRate = $151, etRZS_TUBGSM = $155,
    etMicrosoftAudio = $160, etWMA_DivX_AC3 = $161, etWMA_ProV9 = $162,
    etWMA_LosslessV9 = $163, etWMAProOverSPDIF = $164, etUNISYS_AdPcm = $170,
    etUNISYS_ULAW = $171, etUNISYS_ALAW = $172, etUNISYS_16K = $173,
    etSYC008_SyCom = $174, etSYC701_G726L = $175, etSYC701_CELP54 = $176,
    etSYC701_CELP68 = $177, etKA_AdPcm = $178, etIISMPEG2AAC = $180,
    etDTS_DS = $190, etCreativeAdPcm = $200, etFastSpeech8 = $202,
    etFastSpeech10 = $203, etUHERAdPcm = $210, etUleadDVACM_A = $215,
    etUleadDVACM_B = $216, etQuarterdeckCorp = $220, etILinkVC = $230,
    etAurealRawSport = $240, etESSTAC3 = $241, etIP_HSX = $250,
    etIP_RPELP = $251, etConsistentCS2 = $260, etSonySCX = $270,
    etSonySCY = $271, etSonyATRAC3 = $272, etSonySPC = $273,
    etTELUM_TelumInc = $280, etTELUMIA_TelumInc = $281, etNVS_AdPcm = $285,
    etFMTownsSND = $300, etFujitsu1 = $301, etFujitsu2 = $302,
    etFujitsu3 = $303, etFujitsu4 = $304, etFujitsu5 = $305, etFujitsu6 = $306,
    etFujitsu7 = $307, etFujitsu8 = $308, etMSIncDev = $350,
    etMSIncCELP833 = $351, etBrooktreeDigital = $400, etIntel_IMC = $401,
    etLigosIndeoAudio = $402, etQDesignMusic = $450, etOn2VP7 = $500,
    etOn2VP6 = $501, etATandT_VMPCM = $680, etATandT_TCP = $681,
    etYMPEGAlpha = $700, etClearJumpLiteWav = $8AE, etOLIGSM = $1000,
    etOLIAdPcm = $1001, etOLICELP = $1002, etOLISBC = $1003, etOLIOPR = $1004,
    etLH = $1100, etLH_CELPcodec = $1101, etLH_SBCcodecA = $1102,
    etLH_SBCcodecB = $1103, etLH_SBCcodec = $1104, etNorrisCommInc = $1400,
    etISIAudio = $1401, etATnT_Soundspace = $1500, etVoxWareRT24 = $181C,
    etLucentAX24000P = $181E, etSF_LOSSLESS = $1971, etITI_AdPcm = $1979,
    etLucentSX8300P = $1C07, etLucentSX5363S = $1C0C, // G.723 complient
    etCUseeMeDigiTalk = $1F03, etNCTSoftALF2CDACM = $1FC4,
    etFASTMultimDVM = $2000, etDolbyDTS = $2001, etRealAudio14_4 = $2002,
    etRealAudio28_8 = $2003, etRealAudioG28Cook = $2004,
    etRealAudioMusic = $2005, etRealAudio10RAAC = $2006,
    etRealAudio10RACP = $2007, etmakeAVIS = $3313, etDivioMPEG4AAC = $4143,
    etNokiaAdaptiveMR = $4201, etDivioG726 = $4243, etLEADSpeech = $434C,
    etLEADVorbis = $564C, etWavPackAudio = $5756, etOggVorbisMode1 = $674F,
    etOggVorbisMode2 = $6750, etOggVorbisMode3 = $6751,
    etOggVorbisMode1p = $676F, etOggVorbisMode2p = $6770,
    etOggVorbisMode3p = $6771, et3COM_NBX = $7000, etFAAD_AAC = $706D,
    etGSM_AMR_CBR = $7A21, etGSM_AMR_VBR = $7A22, etComInfosysG723 = $A100,
    etComInfosysAVQSBC = $A101, etComInfosysOLDSBC = $A102,
    etSymbolTec_G729A = $A103, etVoiceAgeAMRWB = $A104, etIngTech_G726 = $A105,
    etISOMPEG4_AAC = $A106, etEncoreSoft_G726 = $A107, etSpeexACMCodec = $A109,
    etSF_ACM_Codec = $DFAC, etFLAC = $F1AC, etExtensible = $FFFE,
    etExperimental = $FFFF);

  TWavFormatRecord = packed record
    FormatTag: Word; // format type
    Channels: Word; // number of channels (i.e. mono, stereo, etc.)
    SampleRate: Cardinal; // sample rate
    BytesPerSecond: Cardinal; // = SampleRate * BlockAlign
    BlockAlign: Word; // block size of data
    BitsPerSample: Word; // = 3, 4, 8, 16 or 32 Bits/sample
  end;

  PWavFormatChunkExtensible = ^TWavFormatChunkExtensible;

  TWavFormatChunkExtensible = packed record
    SamplesPerBlock: Word; // number of samples per channel per Block
    ChMask: Integer;
    GUID: TGUID; // was array [0..71] of Byte;
  end;

  TWavAdPcmCoefficientSet = packed record
    Coefficient: array [0 .. 1] of SmallInt;
  end;

  TWavAdPcmInfoEx = packed record
    SamplesPerBlock: Word;
    NumCoeff: Word;
    CoefSets: array [0 .. 35] of TWavAdPcmCoefficientSet;
  end;

  TAdPcmState = packed record
    PrevSampleLeft: SmallInt;
    IndexLeft: Byte;
    PrevSampleRight: SmallInt;
    IndexRight: Byte;
  end;

  TAdPcmMs = packed record
    Predictor: array [0 .. 1] of Byte;
    Delta: array [0 .. 1] of SmallInt;
    Samp1: array [0 .. 1] of SmallInt;
    Samp2: array [0 .. 1] of SmallInt;
  end;

  TWavDefinedChunk = class(TDefinedChunk)
  public
    constructor Create; override;
  end;

  TWavFixedDefinedChunk = class(TFixedDefinedChunk)
  public
    constructor Create; override;
  end;

  TWavChunkText = class(TCustomTextChunk)
  public
    constructor Create; override;
  end;

  TWavUnknownChunk = class(TUnknownChunk)
  public
    constructor Create; override;
  end;

  TWavBinaryChunk = class(TCustomBinaryChunk)
  public
    constructor Create; override;
  end;

  TFormatChunk = class(TWavDefinedChunk)
  private
    function GetFormatTag: TWavEncoding;
    function GetValidBitsPerSample: Word;
    procedure CalculateChunkSize;
    procedure SetBitsPerSample(const Value: Word);
    procedure SetBlockAlign(const Value: Word);
    procedure SetBytesPerSecond(const Value: Cardinal);
    procedure SetChannels(const Value: Word);
    procedure SetFormatTag(const Value: TWavEncoding);
    procedure SetSampleRate(const Value: Cardinal);
  protected
    FFormatSpecific: array of Byte;
    FFormatExtensible: PWavFormatChunkExtensible;
    FWaveFormatRecord: TWavFormatRecord;
    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
    class function GetClassChunkName: TChunkName; override;

    property FormatTag: TWavEncoding read GetFormatTag write SetFormatTag;
    property Channels: Word read FWaveFormatRecord.Channels write SetChannels;
    property SampleRate: Cardinal read FWaveFormatRecord.SampleRate
      write SetSampleRate;
    property BytesPerSecond: Cardinal read FWaveFormatRecord.BytesPerSecond
      write SetBytesPerSecond;
    property BlockAlign: Word read FWaveFormatRecord.BlockAlign
      write SetBlockAlign;
    property BitsPerSample: Word read FWaveFormatRecord.BitsPerSample
      write SetBitsPerSample;
    property ValidBitsPerSample: Word read GetValidBitsPerSample;
  end;

  TFactRecord = packed record
    SampleCount: Cardinal;
  end;

  TFactChunk = class(TWavFixedDefinedChunk)
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    FactRecord: TFactRecord;
    constructor Create; override;
    class function GetClassChunkSize: Integer; override;
    class function GetClassChunkName: TChunkName; override;

    property SampleCount: Cardinal read FactRecord.SampleCount
      write FactRecord.SampleCount;
  end;

  // -> see: http://www.ebu.ch/CMSimages/en/tec_doc_t3285_s2_tcm6-10482.pdf

  TQualityChunkRecord = packed record
    FileSecurityReport: Cardinal; // FileSecurityCode of quality report
    FileSecurityWave: Cardinal; // FileSecurityCode of BWF wave data
  end;

  TQualityChunk = class(TWavBinaryChunk)
  public
    class function GetClassChunkName: TChunkName; override;
  end;

  TInfoSoftwareNameChunk = class(TWavChunkText)
  public
    class function GetClassChunkName: TChunkName; override;

    property SoftwareName: AnsiString read FText write FText;
  end;

  TInfoCommentChunk = class(TWavChunkText)
  public
    class function GetClassChunkName: TChunkName; override;

    property Comment: AnsiString read FText write FText;
  end;

  TInfoCreationDateChunk = class(TWavChunkText)
  public
    class function GetClassChunkName: TChunkName; override;

    property CreationDate: AnsiString read FText write FText;
  end;

  TInfoCopyrightChunk = class(TWavChunkText)
  public
    class function GetClassChunkName: TChunkName; override;

    property Copyright: AnsiString read FText write FText;
  end;

  TInfoSubjectChunk = class(TWavChunkText)
  public
    class function GetClassChunkName: TChunkName; override;

    property Subject: AnsiString read FText write FText;
  end;

  TInfoArtistChunk = class(TWavChunkText)
  public
    class function GetClassChunkName: TChunkName; override;

    property Artist: AnsiString read FText write FText;
  end;

  TInfoTitleChunk = class(TWavChunkText)
  public
    class function GetClassChunkName: TChunkName; override;

    property Title: AnsiString read FText write FText;
  end;

  TCustomWavCuedTextChunk = class(TWavDefinedChunk)
  private
    procedure CalculateChunkSize;
  protected
    FText: string;
    FCueID: Cardinal;
    procedure SetText(const Value: string);
    procedure AssignTo(Dest: TPersistent); override;
  public
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
  end;

  TLabelChunk = class(TCustomWavCuedTextChunk)
  public
    class function GetClassChunkName: TChunkName; override;

    property Text: string read FText write FText;
  end;

  TNoteChunk = class(TCustomWavCuedTextChunk)
  public
    class function GetClassChunkName: TChunkName; override;

    property Note: string read FText write FText;
  end;

  TLabeledTextRecord = packed record
    CuePointID: Cardinal;
    SampleLength: Cardinal;
    PurposeID: Cardinal;
    Country: Word;
    Language: Word;
    Dialect: Word;
    CodePage: Word;
  end;

  TLabeledTextChunk = class(TWavDefinedChunk)
  private
    procedure CalculateChunkSize;
  protected
    FText: string;
    procedure SetText(const Value: string);
    procedure AssignTo(Dest: TPersistent); override;
  public
    LabeledTextRecord: TLabeledTextRecord;
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
    class function GetClassChunkName: TChunkName; override;

    property Text: string read FText write FText;
    property CuePointID: Cardinal read LabeledTextRecord.CuePointID
      write LabeledTextRecord.CuePointID;
    property SampleLength: Cardinal read LabeledTextRecord.SampleLength
      write LabeledTextRecord.SampleLength;
    property PurposeID: Cardinal read LabeledTextRecord.PurposeID
      write LabeledTextRecord.PurposeID;
    property Country: Word read LabeledTextRecord.Country
      write LabeledTextRecord.Country;
    property Language: Word read LabeledTextRecord.Language
      write LabeledTextRecord.Language;
    property Dialect: Word read LabeledTextRecord.Dialect
      write LabeledTextRecord.Dialect;
    property CodePage: Word read LabeledTextRecord.CodePage
      write LabeledTextRecord.CodePage;
  end;

  TCuedFileChunk = class(TWavDefinedChunk)
  private
    procedure CalculateChunkSize;
  protected
    FCueID: Cardinal;
    FMediaType: Cardinal;
    FBinaryData: array of Byte;
    procedure AssignTo(Dest: TPersistent); override;
  public
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
    class function GetClassChunkName: TChunkName; override;
  end;

  TAssociatedDataListRecord = packed record
    TypeID: TChunkName;
  end;

  TAssociatedDataListChunk = class(TWavDefinedChunk)
  private
    function GetSubChunk(Index: Integer): TCustomChunk;
    function GetCount: Integer;
    function GetTypeID: string;
    procedure SetTypeID(const Value: string);
  protected
    FChunkList: TChunkList;
    function GetChunkClass(ChunkName: TChunkName): TCustomChunkClass; virtual;
    function GetChunkSize: Cardinal; override;
    procedure AssignTo(Dest: TPersistent); override;
    procedure ConvertStreamToChunk(ChunkClass: TCustomChunkClass;
      Stream: TStream); virtual;
  public
    AssociatedDataListRecord: TAssociatedDataListRecord;
    constructor Create; override;
    destructor Destroy; override;
    procedure AddChunk(Chunk: TCustomChunk); virtual;
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
    class function GetClassChunkName: TChunkName; override;
    property SubChunk[Index: Integer]: TCustomChunk read GetSubChunk;
    property Count: Integer read GetCount;

    property TypeID: string read GetTypeID write SetTypeID;
  end;

  TPlaylistSegmentRecord = packed record
    CuePointID: Cardinal;
    LengthInSamples: Cardinal;
    NumberOfRepeats: Cardinal;
  end;

  TPlaylistSegmentItem = class(TCollectionItem)
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    PlaylistSegment: TPlaylistSegmentRecord;

    property CuePointID: Cardinal read PlaylistSegment.CuePointID
      write PlaylistSegment.CuePointID;
    property LengthInSamples: Cardinal read PlaylistSegment.LengthInSamples
      write PlaylistSegment.LengthInSamples;
    property NumberOfRepeats: Cardinal read PlaylistSegment.NumberOfRepeats
      write PlaylistSegment.NumberOfRepeats;
  end;

  TPlaylistChunk = class(TWavDefinedChunk)
  private
    FCount: Cardinal;
    FPlaylistSegments: TOwnedCollection;
    procedure CalculateChunkSize;
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
    class function GetClassChunkName: TChunkName; override;
  end;

  TSilentRecord = packed record
    NumberOfSilentSamples: Cardinal;
  end;

  TSilentChunk = class(TWavFixedDefinedChunk)
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    SilentRecord: TSilentRecord;
    constructor Create; override;
    class function GetClassChunkSize: Integer; override;
    class function GetClassChunkName: TChunkName; override;

    property NumberOfSilentSamples: Cardinal
      read SilentRecord.NumberOfSilentSamples
      write SilentRecord.NumberOfSilentSamples;
  end;

  TWavelistRecord = packed record
    NumberOfSilentSamples: Cardinal;
  end;

  TCustomPaddingChunk = class(TWavDefinedChunk)
  public
    procedure LoadFromStream(Stream: TStream); override;
  end;

  TJunkChunk = class(TCustomPaddingChunk)
  private
    FPadding: Integer;
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create; override;
    procedure SaveToStream(Stream: TStream); override;
    class function GetClassChunkName: TChunkName; override;

    property Padding: Integer read FPadding write FPadding default 16;
  end;

  TPadChunk = class(TCustomPaddingChunk)
  private
    FAlignSize: Integer;
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create; override;
    procedure SaveToStream(Stream: TStream); override;
    procedure LoadFromStream(Stream: TStream); override;
    class function GetClassChunkName: TChunkName; override;

    property AlignSize: Integer read FAlignSize write FAlignSize default 2048;
  end;

  TCuePointRecord = packed record
    CuePointName: Cardinal;
    CuePointPos: Cardinal;
    CuePointChunk: TChunkName;
    FilePosStart: Cardinal;
    BlockStartPos: Cardinal;
    SampleOffset: Cardinal;
  end;

  TCueItem = class(TCollectionItem)
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    CuePointRecord: TCuePointRecord;

    property CuePointName: Cardinal read CuePointRecord.CuePointName
      write CuePointRecord.CuePointName;
    property CuePointSamplePosition: Cardinal read CuePointRecord.CuePointPos
      write CuePointRecord.CuePointPos;
    property FileStartPosition: Cardinal read CuePointRecord.FilePosStart
      write CuePointRecord.FilePosStart;
    property RelativeBlockStartPosition: Cardinal
      read CuePointRecord.BlockStartPos write CuePointRecord.BlockStartPos;
    property RelativeBlockSampleOffset: Cardinal
      read CuePointRecord.SampleOffset write CuePointRecord.SampleOffset;
  end;

  TCueChunk = class(TWavDefinedChunk)
  private
    FCount: Cardinal;
    FCueCollection: TOwnedCollection;
    procedure CalculateChunkSize;
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
    class function GetClassChunkName: TChunkName; override;
  end;

  TSMPTEFormat = (soZero = 0, so24 = 24, so25 = 25, so30Drop = 29, so30 = 30);

  TMidiManufacturer = (mmUnknown = $00, mmSequentialCircuits = $01,
    mmBigBriar = $02, mmOctavePlateau = $03, mmMoog = $04,
    mmPassportDesigns = $05, mmLexicon = $06, mmKurzweil = $07, mmFender = $08,
    mmGulbransen = $09, mmDeltaLabs = $0A, mmSoundComp = $0B,
    mmGeneralElectro = $0C, mmTechmar = $0D, mmMatthewsResearch = $0E,
    mmOberheim = $10, mmPAIA = $11, mmSimmons = $12, mmDigiDesign = $13,
    mmFairlight = $14, mmJLCooper = $15, mmLowery = $16, mmLin = $17,
    mmEmu = $18, mmPeavey = $1B, mmBonTempi = $20, mmSIEL = $21,
    mmSyntheAxe = $23, mmHohner = $24, mmCrumar = $25, mmSolton = $26,
    mmJellinghausMs = $27, mmCTS = $28, mmPPG = $29, mmElka = $2F,
    mmCheetah = $36, mmWaldorf = $3E, mmKawai = $40, mmRoland = $41,
    mmKorg = $42, mmYamaha = $43, mmCasio = $44, mmKamiyaStudio = $46,
    mmAkai = $47, mmVictor = $48, mmFujitsu = $4B, mmSony = $4C, mmTeac = $4E,
    mmMatsushita1 = $50, mmFostex = $51, mmZoom = $52, mmMatsushita2 = $54,
    mmSuzuki = $55, mmFujiSound = $56, mmAcousticTecLab = $57);

  TSamplerRecord = packed record
    Manufacturer: Cardinal;
    Product: Cardinal;
    SamplePeriod: Cardinal;
    MIDIUnityNote: Cardinal;
    MIDIPitchFraction: Cardinal;
    SMPTEFormat: Cardinal; // 0, 24, 25, 29, 30
    SMPTEOffset: Cardinal;
    NumSampleLoops: Cardinal;
    SamplerData: Cardinal;
  end;

  TLoopRecord = packed record
    CuePointID: Cardinal;
    LoopType: Cardinal;
    LoopStart: Cardinal;
    LoopEnd: Cardinal;
    Fraction: Cardinal;
    PlayCount: Cardinal;
  end;

  TLoopItem = class(TCollectionItem)
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    LoopRecord: TLoopRecord;

    property CuePointID: Cardinal read LoopRecord.CuePointID
      write LoopRecord.CuePointID;
    property LoopType: Cardinal read LoopRecord.LoopType
      write LoopRecord.LoopType;
    property LoopStart: Cardinal read LoopRecord.LoopStart
      write LoopRecord.LoopStart;
    property LoopEnd: Cardinal read LoopRecord.LoopEnd write LoopRecord.LoopEnd;
    property Fraction: Cardinal read LoopRecord.Fraction
      write LoopRecord.Fraction;
    property PlayCount: Cardinal read LoopRecord.PlayCount
      write LoopRecord.PlayCount;
  end;

  TSamplerChunk = class(TWavDefinedChunk)
  private
    FLoopCollection: TOwnedCollection;
    function GetManufacturer: TMidiManufacturer;
    function GetSMPTEFormat: TSMPTEFormat;
    procedure CalculateChunkSize;
    procedure SetManufacturer(const Value: TMidiManufacturer);
    procedure SetSMPTEFormat(const Value: TSMPTEFormat);
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    SamplerRecord: TSamplerRecord;
    constructor Create; override;
    destructor Destroy; override;
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
    class function GetClassChunkName: TChunkName; override;

    property Manufacturer: TMidiManufacturer read GetManufacturer
      write SetManufacturer;
    property Product: Cardinal read SamplerRecord.Product
      write SamplerRecord.Product;
    property SamplePeriod: Cardinal read SamplerRecord.SamplePeriod
      write SamplerRecord.SamplePeriod;
    property MIDIUnityNote: Cardinal read SamplerRecord.MIDIUnityNote
      write SamplerRecord.MIDIUnityNote;
    property MIDIPitchFraction: Cardinal read SamplerRecord.MIDIPitchFraction
      write SamplerRecord.MIDIPitchFraction;
    property SMPTEFormat: TSMPTEFormat read GetSMPTEFormat write SetSMPTEFormat;
    property SMPTEOffset: Cardinal read SamplerRecord.SMPTEOffset
      write SamplerRecord.SMPTEOffset;
    property NumSampleLoops: Cardinal read SamplerRecord.NumSampleLoops;
    property SamplerData: Cardinal read SamplerRecord.SamplerData
      write SamplerRecord.SamplerData;
    property LoopCollection: TOwnedCollection read FLoopCollection;
  end;

  TInstrumentRecord = packed record
    UnshiftedNote: Byte;
    FineTune: ShortInt;
    Gain_dB: ShortInt;
    LowNote: Byte;
    HighNote: Byte;
    LowVelocity: Byte;
    HighVelocity: Byte;
  end;

  TInstrumentChunk = class(TWavFixedDefinedChunk)
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    InstrumentRecord: TInstrumentRecord;
    constructor Create; override;
    class function GetClassChunkSize: Integer; override;
    class function GetClassChunkName: TChunkName; override;
    procedure SetNoteRange(Low, High: ShortInt);
    procedure SetVelocityRange(Low, High: Byte);

    property UnshiftedNote: Byte read InstrumentRecord.UnshiftedNote
      write InstrumentRecord.UnshiftedNote;
    property FineTune: ShortInt read InstrumentRecord.FineTune
      write InstrumentRecord.FineTune;
    property Gain_dB: ShortInt read InstrumentRecord.Gain_dB
      write InstrumentRecord.Gain_dB;
    property LowNote: Byte read InstrumentRecord.LowNote
      write InstrumentRecord.LowNote;
    property HighNote: Byte read InstrumentRecord.HighNote
      write InstrumentRecord.HighNote;
    property LowVelocity: Byte read InstrumentRecord.LowVelocity
      write InstrumentRecord.LowVelocity;
    property HighVelocity: Byte read InstrumentRecord.HighVelocity
      write InstrumentRecord.HighVelocity;
  end;

  TLevelChunkRecord = packed record
    dwVersion: Cardinal; // version information
    dwFormat: Cardinal; // format of a peak point
    dwPointsPerValue: Cardinal;
    dwBlockSize: Cardinal; // frames per value
    dwPeakChannels: Cardinal; // number of channels
    dwNumPeakFrames: Cardinal; // number of peak frames
    dwPosPeakOfPeaks: Cardinal;
    dwOffsetToPeaks: Cardinal;
    StrTimestamp: array [0 .. 27] of char; // ASCII: time stamp of the peak data
    Reserved: array [0 .. 59] of char; // reserved set to 0x00
  end;

  // chunk not yet created...
  // see: http://www.ebu.ch/CMSimages/en/tec_doc_t3285_s3_tcm6-10483.pdf

  TBextRecord = packed record
    Description: array [0 .. 255] of AnsiChar;
    Originator: array [0 .. 31] of AnsiChar;
    OriginatorRef: array [0 .. 31] of AnsiChar;
    OriginationDate: array [0 .. 9] of AnsiChar;
    OriginationTime: array [0 .. 7] of AnsiChar;
    TimeRefLow: Integer;
    TimeRefHigh: Integer;
    Version: Word;
    UMID: Array [0 .. 63] of Byte;
    Reserved: Array [0 .. 189] of Byte;
  end;

  PBextRecord = ^TBextRecord;

  TCustomBextChunk = class(TWavFixedDefinedChunk)
  private
    function GetDescription: string;
    function GetOriginationDate: string;
    function GetOriginationTime: string;
    function GetOriginator: string;
    function GetOriginatorRef: string;
    procedure SetDescription(const Value: string);
    procedure SetOriginationDate(const Value: string);
    procedure SetOriginationTime(const Value: string);
    procedure SetOriginator(const Value: string);
    procedure SetOriginatorRef(const Value: string);
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    BextRecord: TBextRecord;
    constructor Create; override;
    class function GetClassChunkSize: Integer; override;

    property Description: string read GetDescription write SetDescription;
    property Originator: string read GetOriginator write SetOriginator;
    property OriginatorRef: string read GetOriginatorRef write SetOriginatorRef;
    property OriginationDate: string read GetOriginationDate
      write SetOriginationDate;
    property OriginationTime: string read GetOriginationTime
      write SetOriginationTime;
    property TimeRefLow: Integer read BextRecord.TimeRefLow
      write BextRecord.TimeRefLow;
    property TimeRefHigh: Integer read BextRecord.TimeRefHigh
      write BextRecord.TimeRefHigh;
    property Version: Word read BextRecord.Version write BextRecord.Version;
  end;

  TBextChunk = class(TCustomBextChunk)
  public
    class function GetClassChunkName: TChunkName; override;

    property Description;
    property Originator;
    property OriginatorRef;
    property OriginationDate;
    property OriginationTime;
    property TimeRefLow;
    property TimeRefHigh;
    property Version;
  end;

  TBextChunkOld = class(TCustomBextChunk)
  public
    class function GetClassChunkName: TChunkName; override;
    procedure SaveToStream(Stream: TStream); override;
  end;

  TCartRecord = packed record
    Version: Integer;
    Title: array [0 .. 63] of AnsiChar;
    Artist: array [0 .. 63] of AnsiChar;
    CutID: array [0 .. 63] of AnsiChar;
    ClientID: array [0 .. 63] of AnsiChar;
    Category: array [0 .. 63] of AnsiChar;
    Classification: array [0 .. 63] of AnsiChar;
    OutCue: array [0 .. 63] of AnsiChar;
    StartDate: array [0 .. 9] of AnsiChar;
    StartTime: array [0 .. 7] of AnsiChar;
    EndDate: array [0 .. 9] of AnsiChar;
    EndTime: array [0 .. 7] of AnsiChar;
    ProducerAppID: array [0 .. 63] of AnsiChar;
    ProducerAppVersion: array [0 .. 63] of AnsiChar;
    UserDef: array [0 .. 63] of AnsiChar;
    dbLevelReference: Integer;
  end;

  PCartRecord = ^TCartRecord;

  TCartChunk = class(TWavFixedDefinedChunk)
  private
    function GetArtist: string;
    function GetCategory: string;
    function GetClassification: string;
    function GetClientID: string;
    function GetCutID: string;
    function GetEndDate: string;
    function GetEndTime: string;
    function GetOutCue: string;
    function GetProducerAppID: string;
    function GetProducerAppVersion: string;
    function GetStartDate: string;
    function GetStartTime: string;
    function GetTitle: string;
    function GetUserDef: string;
    procedure SetArtist(const Value: string);
    procedure SetCategory(const Value: string);
    procedure SetClassification(const Value: string);
    procedure SetClientID(const Value: string);
    procedure SetCutID(const Value: string);
    procedure SetEndDate(const Value: string);
    procedure SetEndTime(const Value: string);
    procedure SetOutCue(const Value: string);
    procedure SetProducerAppID(const Value: string);
    procedure SetProducerAppVersion(const Value: string);
    procedure SetStartDate(const Value: string);
    procedure SetStartTime(const Value: string);
    procedure SetTitle(const Value: string);
    procedure SetUserDef(const Value: string);
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    CartRecord: TCartRecord;
    constructor Create; override;
    class function GetClassChunkSize: Integer; override;
    class function GetClassChunkName: TChunkName; override;

    property Version: Integer read CartRecord.Version write CartRecord.Version;
    property Title: string read GetTitle write SetTitle;
    property Artist: string read GetArtist write SetArtist;
    property CutID: string read GetCutID write SetCutID;
    property ClientID: string read GetClientID write SetClientID;
    property Category: string read GetCategory write SetCategory;
    property Classification: string read GetClassification
      write SetClassification;
    property OutCue: string read GetOutCue write SetOutCue;
    property StartDate: string read GetStartDate write SetStartDate;
    property StartTime: string read GetStartTime write SetStartTime;
    property EndDate: string read GetEndDate write SetEndDate;
    property EndTime: string read GetEndTime write SetEndTime;
    property ProducerAppID: string read GetProducerAppID write SetProducerAppID;
    property ProducerAppVersion: string read GetProducerAppVersion
      write SetProducerAppVersion;
    property UserDef: string read GetUserDef write SetUserDef;
    property dbLevelReference: Integer read CartRecord.dbLevelReference
      write CartRecord.dbLevelReference;
  end;

var
  WaveChunkClasses: array of TDefinedChunkClass;

procedure RegisterWaveChunk(AClass: TDefinedChunkClass);
procedure RegisterWaveChunks(AClasses: array of TDefinedChunkClass);
function IsWaveChunkClassRegistered(AClass: TDefinedChunkClass): Boolean;
function WaveChunkClassByName(Value: string): TDefinedChunkClass;
function WaveChunkClassByChunkName(Value: TChunkName): TDefinedChunkClass;

implementation

function WaveChunkClassByName(Value: string): TDefinedChunkClass;
var
  X: Integer;
begin
  Result := nil;
  for X := Length(WaveChunkClasses) - 1 downto 0 do
  begin
    if WaveChunkClasses[X].ClassName = Value then
    begin
      Result := WaveChunkClasses[X];
      Break;
    end;
  end;
end;

function WaveChunkClassByChunkName(Value: TChunkName): TDefinedChunkClass;
var
  X: Integer;
begin
  Result := nil;
  for X := 0 to Length(WaveChunkClasses) - 1 do
    if CompareChunkNames(WaveChunkClasses[X].GetClassChunkName, Value) then
    begin
      Result := WaveChunkClasses[X];
      Break;
    end;
end;

function IsWaveChunkClassRegistered(AClass: TDefinedChunkClass): Boolean;
var
  X: Integer;
begin
  Result := False;
  for X := Length(WaveChunkClasses) - 1 downto 0 do
  begin
    if WaveChunkClasses[X] = AClass then
    begin
      Result := True;
      Break;
    end;
  end;
end;

procedure RegisterWaveChunk(AClass: TDefinedChunkClass);
begin
  Classes.RegisterClass(AClass);
  Assert(not IsWaveChunkClassRegistered(AClass));
  SetLength(WaveChunkClasses, Length(WaveChunkClasses) + 1);
  WaveChunkClasses[Length(WaveChunkClasses) - 1] := AClass;
end;

procedure RegisterWaveChunks(AClasses: array of TDefinedChunkClass);
var
  i: Integer;
begin
  for i := 0 to Length(AClasses) - 1 do
    RegisterWaveChunk(AClasses[i]);
end;

{ TWavDefinedChunk }

constructor TWavDefinedChunk.Create;
begin
  inherited;
  ChunkFlags := ChunkFlags + [cfPadSize];
end;

{ TWavFixedDefinedChunk }

constructor TWavFixedDefinedChunk.Create;
begin
  inherited;
  ChunkFlags := ChunkFlags + [cfPadSize];
end;

{ TWavChunkText }

constructor TWavChunkText.Create;
begin
  inherited;
  ChunkFlags := ChunkFlags + [cfPadSize];
end;

{ TWavBinaryChunk }

constructor TWavBinaryChunk.Create;
begin
  inherited;
  ChunkFlags := ChunkFlags + [cfPadSize];
end;

{ TWavUnknownChunk }

constructor TWavUnknownChunk.Create;
begin
  inherited;
  ChunkFlags := ChunkFlags + [cfPadSize];
end;

{ TFormatChunk }

constructor TFormatChunk.Create;
begin
  inherited;
  with FWaveFormatRecord do
  begin
    FormatTag := 1; // PCM encoding by default
    Channels := 1; // one channel
    SampleRate := 44100; // 44.1 kHz
    BitsPerSample := 24; // 24bit
    BlockAlign := (BitsPerSample + 7) div 8 * Channels;
    BytesPerSecond := Channels * BlockAlign * SampleRate;
  end;
  SetLength(FFormatSpecific, 0);
end;

destructor TFormatChunk.Destroy;
begin
  Dispose(FFormatExtensible);
  inherited;
end;

procedure TFormatChunk.AssignTo(Dest: TPersistent);
begin
  inherited;
  if Dest is TFormatChunk then
  begin
    TFormatChunk(Dest).FWaveFormatRecord := FWaveFormatRecord;
    SetLength(TFormatChunk(Dest).FFormatSpecific, Length(FFormatSpecific));
    Move(FFormatSpecific[0], TFormatChunk(Dest).FFormatSpecific[0],
      Length(FFormatSpecific));
  end;
end;

procedure TFormatChunk.CalculateChunkSize;
begin
  FChunkSize := SizeOf(TWavFormatRecord);
  if FWaveFormatRecord.FormatTag <> 1 then
    FChunkSize := FChunkSize + SizeOf(Word) + Cardinal(Length(FFormatSpecific));
end;

procedure TFormatChunk.LoadFromStream(Stream: TStream);
var
  FormatSpecificBytes: Word;
begin
  inherited;
  with Stream do
  begin
    // make sure the chunk size is at least the header size
    Assert(FChunkSize >= SizeOf(TWavFormatRecord));
    Read(FWaveFormatRecord, SizeOf(TWavFormatRecord));

    // check whether format specific data can be found:
    if FChunkSize <= SizeOf(TWavFormatRecord) then
      Exit;
    Read(FormatSpecificBytes, SizeOf(Word));

    // read format specific bytes
    Assert(FChunkSize >= SizeOf(TWavFormatRecord) + SizeOf(Word) +
      FormatSpecificBytes);

    // check format extensible
    if FWaveFormatRecord.FormatTag = $FFFE then
    begin
      // check length
      if FormatSpecificBytes < SizeOf(TWavFormatChunkExtensible) then
        raise Exception.Create('Extensible format chunk size too small');

      // allocate memory for the extensible format
      ReallocMem(FFormatExtensible, FormatSpecificBytes);

      // read format extensible part
      Read(FFormatExtensible^, FormatSpecificBytes);
    end
    else
    begin
      // assign general format specific data
      SetLength(FFormatSpecific, FormatSpecificBytes);
      Read(FFormatSpecific[0], FormatSpecificBytes);
    end;

    // Move position to the end of this chunk
    Position := Position + FChunkSize - SizeOf(TWavFormatRecord) - SizeOf(Word)
      - FormatSpecificBytes;
  end;
end;

procedure TFormatChunk.SaveToStream(Stream: TStream);
var
  FormatSpecificBytes: Word;
begin
  CalculateChunkSize;
  inherited;
  with Stream do
  begin
    // write header
    Write(FWaveFormatRecord, SizeOf(TWavFormatRecord));

    // write format specific bytes
    if FWaveFormatRecord.FormatTag <> 1 then
    begin
      FormatSpecificBytes := Length(FFormatSpecific);
      Write(FormatSpecificBytes, SizeOf(Word));
      if FormatSpecificBytes > 0 then
        Write(FFormatSpecific[0], FormatSpecificBytes);
    end;
  end;
end;

class function TFormatChunk.GetClassChunkName: TChunkName;
begin
  Result := 'fmt ';
end;

function TFormatChunk.GetFormatTag: TWavEncoding;
begin
  // check if extensible format
  if (FWaveFormatRecord.FormatTag <> $FFFE) or not Assigned(FFormatExtensible)
  then
    Result := TWavEncoding(FWaveFormatRecord.FormatTag)
  else
    Move(FFormatExtensible^.GUID, Result, SizeOf(Word));
end;

function TFormatChunk.GetValidBitsPerSample: Word;
begin
  if (Length(FFormatSpecific) >= 2) and (FWaveFormatRecord.FormatTag = $FFFE)
  then
    Move(FFormatSpecific[0], Result, SizeOf(Word))
  else
    Result := FWaveFormatRecord.BitsPerSample;
end;

procedure TFormatChunk.SetBitsPerSample(const Value: Word);
begin
  if FWaveFormatRecord.BitsPerSample <> Value then
  begin
    if Value < 2 then
      raise Exception.Create('Value must be greater then 1!');
    FWaveFormatRecord.BitsPerSample := Value;
  end;
end;

procedure TFormatChunk.SetBlockAlign(const Value: Word);
begin
  if FWaveFormatRecord.BlockAlign <> Value then
  begin
    if Value < 1 then
      raise Exception.Create('Value must be greater then 0!');
    FWaveFormatRecord.BlockAlign := Value;
  end;
end;

procedure TFormatChunk.SetBytesPerSecond(const Value: Cardinal);
begin
  if FWaveFormatRecord.BytesPerSecond <> Value then
  begin
    if Value < 1 then
      raise Exception.Create('Value must be greater then 0!');
    FWaveFormatRecord.BytesPerSecond := Value;
  end;
end;

procedure TFormatChunk.SetChannels(const Value: Word);
begin
  if FWaveFormatRecord.Channels <> Value then
  begin
    if Value < 1 then
      raise Exception.Create('Value must be greater then 0!');
    FWaveFormatRecord.Channels := Value;
  end;
end;

procedure TFormatChunk.SetFormatTag(const Value: TWavEncoding);
begin
  // ensure that the extensible format is used correctly
  if Assigned(FFormatExtensible) then
  begin
    // Move current format tag to extensible format tag
    Move(Value, FFormatExtensible.GUID, SizeOf(Word));
  end
  else
  begin
    if Value = etExtensible then
    begin
      // allocate memory for extensible format
      ReallocMem(FFormatExtensible, SizeOf(TWavFormatChunkExtensible));

      // Move current format tag to extensible format tag
      Move(FWaveFormatRecord.FormatTag, FFormatExtensible.GUID, SizeOf(Word));
    end;
    FWaveFormatRecord.FormatTag := Word(Value);
  end;
end;

procedure TFormatChunk.SetSampleRate(const Value: Cardinal);
begin
  if FWaveFormatRecord.SampleRate <> Value then
  begin
    if Value < 1 then
      raise Exception.Create('Value must be greater then 0!');
    FWaveFormatRecord.SampleRate := Value;
  end;
end;

{ TFactChunk }

constructor TFactChunk.Create;
begin
  inherited;
  StartAddress := @FactRecord;
end;

procedure TFactChunk.AssignTo(Dest: TPersistent);
begin
  inherited;
  if Dest is TFactChunk then
    TFactChunk(Dest).FactRecord := FactRecord;
end;

class function TFactChunk.GetClassChunkName: TChunkName;
begin
  Result := 'fact';
end;

class function TFactChunk.GetClassChunkSize: Integer;
begin
  Result := SizeOf(TFactRecord);
end;

{ TInfoSoftwareNameChunk }

class function TInfoSoftwareNameChunk.GetClassChunkName: TChunkName;
begin
  Result := 'ISFT';
end;

{ TInfoCommnetChunk }

class function TInfoCommentChunk.GetClassChunkName: TChunkName;
begin
  Result := 'ICMT';
end;

{ TInfoCreationDateChunk }

class function TInfoCreationDateChunk.GetClassChunkName: TChunkName;
begin
  Result := 'ICRD';
end;

{ TInfoCopyrightChunk }

class function TInfoCopyrightChunk.GetClassChunkName: TChunkName;
begin
  Result := 'ICOP';
end;

{ TInfoSubjectChunk }

class function TInfoSubjectChunk.GetClassChunkName: TChunkName;
begin
  Result := 'ISBJ';
end;

{ TInfoTitleChunk }

class function TInfoTitleChunk.GetClassChunkName: TChunkName;
begin
  Result := 'INAM';
end;

{ TInfoArtistChunk }

class function TInfoArtistChunk.GetClassChunkName: TChunkName;
begin
  Result := 'IART';
end;

{ TQualityChunk }

class function TQualityChunk.GetClassChunkName: TChunkName;
begin
  Result := 'qlty';
end;

{ TSilentChunk }

constructor TSilentChunk.Create;
begin
  inherited;
  StartAddress := @SilentRecord;
end;

procedure TSilentChunk.AssignTo(Dest: TPersistent);
begin
  inherited;
  if Dest is TSilentChunk then
    TSilentChunk(Dest).SilentRecord := SilentRecord;
end;

class function TSilentChunk.GetClassChunkName: TChunkName;
begin
  Result := 'slnt';
end;

class function TSilentChunk.GetClassChunkSize: Integer;
begin
  Result := SizeOf(TSilentRecord);
end;

{ TCustomPaddingChunk }

procedure TCustomPaddingChunk.LoadFromStream(Stream: TStream);
begin
  inherited;
  with Stream do
  begin
    // advance position
    Position := Position + FChunkSize;

    // eventually skip padded zeroes
    if cfPadSize in ChunkFlags then
      Position := Position + CalculateZeroPad;
  end;
end;

{ TJunkChunk }

constructor TJunkChunk.Create;
begin
  inherited;
  FPadding := 16;
end;

procedure TJunkChunk.AssignTo(Dest: TPersistent);
begin
  inherited;
  if Dest is TJunkChunk then
    TJunkChunk(Dest).Padding := Padding;
end;

class function TJunkChunk.GetClassChunkName: TChunkName;
begin
  Result := 'junk';
end;

procedure TJunkChunk.SaveToStream(Stream: TStream);
begin
  // calculate chunk size
  FChunkSize := FPadding;

  // write basic chunk information
  inherited;

  // write custom chunk information
  with Stream do
    Position := Position + FChunkSize;

  // check and eventually add zero pad
  CheckAddZeroPad(Stream);
end;

{ TPadChunk }

constructor TPadChunk.Create;
begin
  inherited;
  FAlignSize := 2048;
end;

procedure TPadChunk.AssignTo(Dest: TPersistent);
begin
  inherited;
  if Dest is TCustomPaddingChunk then
  begin
    TPadChunk(Dest).FAlignSize := FAlignSize;
  end;
end;

class function TPadChunk.GetClassChunkName: TChunkName;
begin
  Result := 'PAD ';
end;

procedure TPadChunk.LoadFromStream(Stream: TStream);
begin
  inherited;
  // set align size
  // FAlignSize :=
end;

procedure TPadChunk.SaveToStream(Stream: TStream);
begin
  // calculate chunk size
  with Stream do
    FChunkSize := ((Position + FAlignSize) div FAlignSize) * FAlignSize
      - Position;

  // write basic chunk information
  inherited;

  // write custom chunk information
  with Stream do
    Position := Position + FChunkSize;

  // check and eventually add zero pad
  CheckAddZeroPad(Stream);
end;

{ TCustomWavCuedTextChunk }

procedure TCustomWavCuedTextChunk.AssignTo(Dest: TPersistent);
begin
  inherited;
  if Dest is TCustomWavCuedTextChunk then
  begin
    TCustomWavCuedTextChunk(Dest).FText := FText;
    TCustomWavCuedTextChunk(Dest).FCueID := FCueID;
  end;
end;

procedure TCustomWavCuedTextChunk.LoadFromStream(Stream: TStream);
begin
  // load basic chunk information
  inherited;

  // load custom chunk information
  with Stream do
  begin
    SetLength(FText, FChunkSize - SizeOf(Cardinal));
    Read(FCueID, SizeOf(Cardinal));
    Read(FText[1], Length(FText));

    // eventually skip padded zeroes
    if cfPadSize in ChunkFlags then
      Position := Position + CalculateZeroPad;
  end;
end;

procedure TCustomWavCuedTextChunk.SaveToStream(Stream: TStream);
begin
  // calculate chunk size
  CalculateChunkSize;

  // write basic chunk information
  inherited;

  // write custom chunk information
  with Stream do
  begin
    Write(FCueID, SizeOf(Cardinal));
    Write(FText[1], Length(FText));
  end;

  // check and eventually add zero pad
  CheckAddZeroPad(Stream);
end;

procedure TCustomWavCuedTextChunk.SetText(const Value: string);
begin
  FText := Value;
  CalculateChunkSize;
end;

procedure TCustomWavCuedTextChunk.CalculateChunkSize;
begin
  FChunkSize := Length(FText) + SizeOf(Cardinal);
end;

{ TLabelChunk }

class function TLabelChunk.GetClassChunkName: TChunkName;
begin
  Result := 'labl';
end;

{ TNoteChunk }

class function TNoteChunk.GetClassChunkName: TChunkName;
begin
  Result := 'note';
end;

{ TLabeledTextChunk }

procedure TLabeledTextChunk.CalculateChunkSize;
begin
  FChunkSize := Length(FText) + SizeOf(TLabeledTextRecord);
end;

class function TLabeledTextChunk.GetClassChunkName: TChunkName;
begin
  Result := 'ltxt';
end;

procedure TLabeledTextChunk.AssignTo(Dest: TPersistent);
begin
  inherited;
  if Dest is TLabeledTextChunk then
  begin
    TLabeledTextChunk(Dest).FText := FText;
    TLabeledTextChunk(Dest).LabeledTextRecord := LabeledTextRecord;
  end;
end;

procedure TLabeledTextChunk.LoadFromStream(Stream: TStream);
begin
  // load basic chunk information
  inherited;

  // load custom chunk information
  with Stream do
  begin
    SetLength(FText, FChunkSize - SizeOf(TLabeledTextRecord));
    Read(LabeledTextRecord, SizeOf(TLabeledTextRecord));
    Read(FText[1], Length(FText));

    // eventually skip padded zeroes
    if cfPadSize in ChunkFlags then
      Position := Position + CalculateZeroPad;
  end;
end;

procedure TLabeledTextChunk.SaveToStream(Stream: TStream);
begin
  // calculate chunk size
  CalculateChunkSize;

  // write basic chunk information
  inherited;

  // write custom chunk information
  with Stream do
  begin
    Write(LabeledTextRecord, SizeOf(TLabeledTextRecord));
    Write(FText[1], FChunkSize);
  end;

  // check and eventually add zero pad
  CheckAddZeroPad(Stream);
end;

procedure TLabeledTextChunk.SetText(const Value: string);
begin
  FText := Value;
  CalculateChunkSize;
end;

{ TCuedFileChunk }

procedure TCuedFileChunk.AssignTo(Dest: TPersistent);
begin
  inherited;
  if Dest is TCuedFileChunk then
  begin
    TCuedFileChunk(Dest).FCueID := FCueID;
    TCuedFileChunk(Dest).FMediaType := FMediaType;

    // copy binary data:
    SetLength(TCuedFileChunk(Dest).FBinaryData, Length(FBinaryData));
    Move(FBinaryData[0], TCuedFileChunk(Dest).FBinaryData[0],
      Length(FBinaryData));
  end;
end;

procedure TCuedFileChunk.CalculateChunkSize;
begin
  FChunkSize := SizeOf(FCueID) + SizeOf(FMediaType) + Length(FBinaryData);
end;

class function TCuedFileChunk.GetClassChunkName: TChunkName;
begin
  Result := 'file';
end;

procedure TCuedFileChunk.LoadFromStream(Stream: TStream);
begin
  // calculate chunk size
  inherited;

  // load custom chunk information
  with Stream do
  begin
    Read(FCueID, SizeOf(FCueID));
    Read(FMediaType, SizeOf(FMediaType));

    // read binary data
    SetLength(FBinaryData, FChunkSize - SizeOf(FCueID) - SizeOf(FMediaType));
    Read(FBinaryData[0], Length(FBinaryData));

    // eventually skip padded zeroes
    if cfPadSize in ChunkFlags then
      Position := Position + CalculateZeroPad;
  end;
end;

procedure TCuedFileChunk.SaveToStream(Stream: TStream);
begin
  // calculate chunk size
  CalculateChunkSize;

  // write basic chunk information
  inherited;

  // write custom chunk information
  with Stream do
  begin
    Write(FCueID, SizeOf(FCueID));
    Write(FMediaType, SizeOf(FMediaType));

    // write binary data:
    Write(FBinaryData[0], Length(FBinaryData));
  end;

  // check and eventually add zero pad
  CheckAddZeroPad(Stream);
end;

{ TAssociatedDataListChunk }

constructor TAssociatedDataListChunk.Create;
begin
  inherited;
  FChunkList := TChunkList.Create;
end;

destructor TAssociatedDataListChunk.Destroy;
begin
  FreeAndNil(FChunkList);
  inherited;
end;

procedure TAssociatedDataListChunk.AddChunk(Chunk: TCustomChunk);
begin
  FChunkList.Add(Chunk);
end;

procedure TAssociatedDataListChunk.AssignTo(Dest: TPersistent);
begin
  inherited;
  if Dest is TAssociatedDataListChunk then
    TAssociatedDataListChunk(Dest).AssociatedDataListRecord :=
      AssociatedDataListRecord;
end;

procedure TAssociatedDataListChunk.LoadFromStream(Stream: TStream);
var
  ChunkEnd: Integer;
  ChunkName: TChunkName;
begin
  // load basic chunk information
  inherited;

  // load custom chunk information
  with Stream do
  begin
    ChunkEnd := Position + FChunkSize;
    Assert(ChunkEnd <= Stream.Size);

    // read type ID
    Read(AssociatedDataListRecord, SizeOf(AssociatedDataListRecord));

    while Position < ChunkEnd do
    begin
      if cfSizeFirst in ChunkFlags then
      begin
        Position := Position + 4;
        Read(ChunkName, 4);
        Position := Position - 8;
      end
      else
      begin
        Read(ChunkName, 4);
        Position := Position - 4;
      end;
      ConvertStreamToChunk(GetChunkClass(ChunkName), Stream);
    end;
    if Position <> ChunkEnd then
      Position := ChunkEnd;

    // eventually skip padded zeroes
    if cfPadSize in ChunkFlags then
      Position := Position + CalculateZeroPad;
  end;
end;

procedure TAssociatedDataListChunk.SaveToStream(Stream: TStream);
var
  i: Integer;
begin
  // calculate chunk size
  FChunkSize := GetChunkSize;

  // write basic chunk information
  inherited;

  // write custom chunk information
  Stream.Write(AssociatedDataListRecord, SizeOf(AssociatedDataListRecord));

  // write sub chunks
  for i := 0 to FChunkList.Count - 1 do
    FChunkList[i].SaveToStream(Stream);

  // check and eventually add zero pad
  CheckAddZeroPad(Stream);
end;

procedure TAssociatedDataListChunk.ConvertStreamToChunk
  (ChunkClass: TCustomChunkClass; Stream: TStream);
var
  Chunk: TCustomChunk;
begin
  Chunk := ChunkClass.Create;
  Chunk.ChunkFlags := ChunkFlags;
  Chunk.LoadFromStream(Stream);
  AddChunk(Chunk);
end;

function TAssociatedDataListChunk.GetChunkClass(ChunkName: TChunkName)
  : TCustomChunkClass;
var
  X: Integer;
begin
  Result := TUnknownChunk;
  for X := 0 to Length(WaveChunkClasses) - 1 do
    if CompareChunkNames(WaveChunkClasses[X].GetClassChunkName, ChunkName) then
    begin
      Result := WaveChunkClasses[X];
      Break;
    end;
end;

function TAssociatedDataListChunk.GetChunkSize: Cardinal;
var
  i: Integer;
begin
  Result := SizeOf(AssociatedDataListRecord);
  for i := 0 to FChunkList.Count - 1 do
    inc(Result, FChunkList[i].ChunkSize + 8); // Chunk Size + Chunk Frame (8)
end;

class function TAssociatedDataListChunk.GetClassChunkName: TChunkName;
begin
  Result := 'LIST';
end;

function TAssociatedDataListChunk.GetCount: Integer;
begin
  Result := FChunkList.Count;
end;

function TAssociatedDataListChunk.GetSubChunk(Index: Integer): TCustomChunk;
begin
  if (Index >= 0) and (Index < FChunkList.Count) then
    Result := FChunkList[Index]
  else
    Result := nil;
end;

function TAssociatedDataListChunk.GetTypeID: string;
begin
  Result := string(AssociatedDataListRecord.TypeID);
end;

procedure TAssociatedDataListChunk.SetTypeID(const Value: string);
begin
  Move(Value[1], AssociatedDataListRecord.TypeID, 4);
end;

{ TPlaylistSegmentItem }

procedure TPlaylistSegmentItem.AssignTo(Dest: TPersistent);
begin
  if Dest is TPlaylistSegmentItem then
    TPlaylistSegmentItem(Dest).PlaylistSegment := PlaylistSegment
  else
    inherited;
end;

{ TPlaylistChunk }

constructor TPlaylistChunk.Create;
begin
  inherited;
  FPlaylistSegments := TOwnedCollection.Create(Self, TPlaylistSegmentItem);
end;

destructor TPlaylistChunk.Destroy;
begin
  FreeAndNil(FPlaylistSegments);
  inherited;
end;

class function TPlaylistChunk.GetClassChunkName: TChunkName;
begin
  Result := 'plst';
end;

procedure TPlaylistChunk.AssignTo(Dest: TPersistent);
begin
  inherited;
  if Dest is TPlaylistChunk then
  begin
    TPlaylistChunk(Dest).FCount := FCount;
    TPlaylistChunk(Dest).FPlaylistSegments.Assign(FPlaylistSegments);
  end;
end;

procedure TPlaylistChunk.CalculateChunkSize;
begin
  FChunkSize := SizeOf(Cardinal) + FCount * SizeOf(TPlaylistSegmentRecord);
end;

procedure TPlaylistChunk.LoadFromStream(Stream: TStream);
var
  l: Integer;
begin
  // load basic chunk information
  inherited;

  // load custom chunk information
  with Stream do
  begin
    Read(FCount, SizeOf(Cardinal));

    // clear all eventually existing playlist segments
    FPlaylistSegments.Clear;

    // load every single playlist segment and add to playlist collection
    for l := 0 to FCount - 1 do
      with TPlaylistSegmentItem(FPlaylistSegments.Add) do
        Read(PlaylistSegment, SizeOf(TPlaylistSegmentRecord));

    // eventually skip padded zeroes
    if cfPadSize in ChunkFlags then
      Position := Position + CalculateZeroPad;
  end;
end;

procedure TPlaylistChunk.SaveToStream(Stream: TStream);
var
  l: Integer;
begin
  // update FCount:
  FCount := FPlaylistSegments.Count;

  // now recalculate the chunk size:
  CalculateChunkSize;

  // write chunk name & size
  inherited;

  with Stream do
  begin
    // write sampler header
    Write(FCount, SizeOf(Cardinal));

    // write every single playlist segment and add to playlist collection
    for l := 0 to FCount - 1 do
      with TPlaylistSegmentItem(FPlaylistSegments.Items[l]) do
        Write(PlaylistSegment, SizeOf(TPlaylistSegmentRecord));
  end;

  // check and eventually add zero pad
  CheckAddZeroPad(Stream);
end;

{ TCueItem }

procedure TCueItem.AssignTo(Dest: TPersistent);
begin
  if Dest is TCueItem then
    TCueItem(Dest).CuePointRecord := CuePointRecord
  else
    inherited;
end;

{ TCueChunk }

constructor TCueChunk.Create;
begin
  inherited;
  FCueCollection := TOwnedCollection.Create(Self, TCueItem);
end;

destructor TCueChunk.Destroy;
begin
  FreeAndNil(FCueCollection);
  inherited;
end;

class function TCueChunk.GetClassChunkName: TChunkName;
begin
  Result := 'cue ';
end;

procedure TCueChunk.AssignTo(Dest: TPersistent);
begin
  inherited;
  if Dest is TCueChunk then
  begin
    TCueChunk(Dest).FCount := FCount;
    TCueChunk(Dest).FCueCollection.Assign(FCueCollection);
  end;
end;

procedure TCueChunk.CalculateChunkSize;
begin
  FChunkSize := SizeOf(Cardinal) + FCount * SizeOf(TCuePointRecord);
end;

procedure TCueChunk.LoadFromStream(Stream: TStream);
var
  CueCnt: Integer;
  ChunkEnd: Cardinal;
begin
  // load basic chunk information
  inherited;

  // load custom chunk information
  with Stream do
  begin
    // calculate end of chunk in case there are no cue items in this chunk
    ChunkEnd := Position + FChunkSize;

    // read number of cue items in this chunk
    Read(FCount, SizeOf(Cardinal));

    // clear all eventually existing cues
    FCueCollection.Clear;

    // load every single playlist segment and add to playlist collection
    for CueCnt := 0 to FCount - 1 do
      with TCueItem(FCueCollection.Add) do
        Read(CuePointRecord, SizeOf(TCuePointRecord));

    // make sure the position is still inside this chunk
    Assert(Position <= ChunkEnd);

    // jump to the end of this chunk
    Position := ChunkEnd;

    // eventually skip padded zeroes
    if cfPadSize in ChunkFlags then
      Position := Position + CalculateZeroPad;
  end;
end;

procedure TCueChunk.SaveToStream(Stream: TStream);
var
  l: Integer;
begin
  // update FCount:
  FCount := FCueCollection.Count;

  // now recalculate the chunk size:
  CalculateChunkSize;

  // write chunk name & size
  inherited;

  // write custom chunk information
  with Stream do
  begin
    // write sampler header
    Write(FCount, SizeOf(Cardinal));

    // write every single playlist segment and add to playlist collection
    for l := 0 to FCount - 1 do
      with TCueItem(FCueCollection.Items[l]) do
        Write(CuePointRecord, SizeOf(TCuePointRecord));
  end;

  // check and eventually add zero pad
  CheckAddZeroPad(Stream);
end;

{ TLoopItem }

procedure TLoopItem.AssignTo(Dest: TPersistent);
begin
  if Dest is TLoopItem then
    TLoopItem(Dest).LoopRecord := LoopRecord
  else
    inherited;
end;

{ TSamplerChunk }

constructor TSamplerChunk.Create;
begin
  inherited;
  FLoopCollection := TOwnedCollection.Create(Self, TLoopItem);
end;

destructor TSamplerChunk.Destroy;
begin
  FreeAndNil(FLoopCollection);
  inherited;
end;

procedure TSamplerChunk.AssignTo(Dest: TPersistent);
begin
  inherited;
  if Dest is TSamplerChunk then
  begin
    TSamplerChunk(Dest).SamplerRecord := SamplerRecord;
    TSamplerChunk(Dest).FLoopCollection.Assign(FLoopCollection);
  end;
end;

procedure TSamplerChunk.CalculateChunkSize;
begin
  FChunkSize := SizeOf(TSamplerRecord) + SamplerRecord.NumSampleLoops *
    SizeOf(TLoopRecord) + SamplerRecord.SamplerData;
end;

class function TSamplerChunk.GetClassChunkName: TChunkName;
begin
  Result := 'smpl';
end;

function TSamplerChunk.GetManufacturer: TMidiManufacturer;
begin
  Result := TMidiManufacturer(SamplerRecord.Manufacturer)
end;

function TSamplerChunk.GetSMPTEFormat: TSMPTEFormat;
begin
  Result := TSMPTEFormat(SamplerRecord.SMPTEFormat);
end;

procedure TSamplerChunk.LoadFromStream(Stream: TStream);
var
  l: Integer;
begin
  // load basic chunk information
  inherited;

  // load custom chunk information
  with Stream do
  begin
    Read(SamplerRecord, SizeOf(TSamplerRecord));

    // clear all eventually existing loop points
    FLoopCollection.Clear;

    // load every single loop and add to loop collection
    for l := 0 to SamplerRecord.NumSampleLoops - 1 do
      with TLoopItem(FLoopCollection.Add) do
        Read(LoopRecord, SizeOf(TLoopRecord));

    // read rest, should only be SamplerRecord.SamplerData
    Assert(FChunkSize - SizeOf(TSamplerRecord) = SamplerRecord.SamplerData);
    Position := Position + FChunkSize - SizeOf(TSamplerRecord);

    // eventually skip padded zeroes
    if cfPadSize in ChunkFlags then
      Position := Position + CalculateZeroPad;
  end;
end;

procedure TSamplerChunk.SaveToStream(Stream: TStream);
var
  l: Integer;
begin
  // make sure some entries are correct:
  SamplerRecord.NumSampleLoops := FLoopCollection.Count;
  SamplerRecord.SamplerData := 0;

  // now recalculate the chunk size:
  CalculateChunkSize;

  // write chunk name & size
  inherited;

  // write custom chunk information
  with Stream do
  begin
    // write sampler header
    Write(SamplerRecord, SizeOf(TSamplerRecord));

    // write every single loop and add to loop collection
    for l := 0 to SamplerRecord.NumSampleLoops - 1 do
      with TLoopItem(FLoopCollection.Items[l]) do
        Write(LoopRecord, SizeOf(TLoopRecord));
  end;

  // check and eventually add zero pad
  CheckAddZeroPad(Stream);
end;

procedure TSamplerChunk.SetManufacturer(const Value: TMidiManufacturer);
begin
  SamplerRecord.Manufacturer := Cardinal(Value);
end;

procedure TSamplerChunk.SetSMPTEFormat(const Value: TSMPTEFormat);
begin
  SamplerRecord.SMPTEFormat := Cardinal(Value);
end;

{ TInstrumentChunk }

constructor TInstrumentChunk.Create;
begin
  inherited;
  StartAddress := @InstrumentRecord;
end;

procedure TInstrumentChunk.AssignTo(Dest: TPersistent);
begin
  inherited;
  if Dest is TInstrumentChunk then
    TInstrumentChunk(Dest).InstrumentRecord := InstrumentRecord;
end;

class function TInstrumentChunk.GetClassChunkName: TChunkName;
begin
  Result := 'inst';
end;

class function TInstrumentChunk.GetClassChunkSize: Integer;
begin
  Result := SizeOf(TInstrumentRecord);
end;

procedure TInstrumentChunk.SetNoteRange(Low, High: ShortInt);
begin
  Assert(Low <= High);
  InstrumentRecord.LowNote := Low;
  InstrumentRecord.HighNote := High;
end;

procedure TInstrumentChunk.SetVelocityRange(Low, High: Byte);
begin
  Assert(Low <= High);
  InstrumentRecord.LowVelocity := Low;
  InstrumentRecord.HighVelocity := High;
end;

{ TCustomBextChunk }

constructor TCustomBextChunk.Create;
begin
  inherited;
  StartAddress := @BextRecord;
end;

procedure TCustomBextChunk.AssignTo(Dest: TPersistent);
begin
  inherited;
  if Dest is TCustomBextChunk then
    TCustomBextChunk(Dest).BextRecord := BextRecord;
end;

class function TCustomBextChunk.GetClassChunkSize: Integer;
begin
  Result := SizeOf(TBextRecord);
end;

// Some Wrapper Functions
function TCustomBextChunk.GetDescription: string;
begin
  Result := string(BextRecord.Description);
end;

function TCustomBextChunk.GetOriginationDate: string;
begin
  Result := string(BextRecord.OriginationDate);
end;

function TCustomBextChunk.GetOriginationTime: string;
begin
  Result := string(BextRecord.OriginationTime);
end;

function TCustomBextChunk.GetOriginator: string;
begin
  Result := string(BextRecord.Originator);
end;

function TCustomBextChunk.GetOriginatorRef: string;
begin
  Result := string(BextRecord.OriginatorRef);
end;

procedure TCustomBextChunk.SetDescription(const Value: string);
begin
  with BextRecord do
    if Length(Value) < SizeOf(Description) then
      Move(Value[1], Description, Length(Value))
    else
      Move(Value[1], Description, SizeOf(Description));
end;

procedure TCustomBextChunk.SetOriginationDate(const Value: string);
begin
  with BextRecord do
    if Length(Value) < SizeOf(OriginationDate) then
      Move(Value[1], OriginationDate, Length(Value))
    else
      Move(Value[1], OriginationDate, SizeOf(OriginationDate));
end;

procedure TCustomBextChunk.SetOriginationTime(const Value: string);
begin
  with BextRecord do
    if Length(Value) < SizeOf(OriginationTime) then
      Move(Value[1], OriginationTime, Length(Value))
    else
      Move(Value[1], OriginationTime, SizeOf(OriginationTime));
end;

procedure TCustomBextChunk.SetOriginator(const Value: string);
begin
  with BextRecord do
    if Length(Value) < SizeOf(Originator) then
      Move(Value[1], Originator, Length(Value))
    else
      Move(Value[1], Originator, SizeOf(Originator));
end;

procedure TCustomBextChunk.SetOriginatorRef(const Value: string);
begin
  with BextRecord do
    if Length(Value) < SizeOf(OriginatorRef) then
      Move(Value[1], OriginatorRef, Length(Value))
    else
      Move(Value[1], OriginatorRef, SizeOf(OriginatorRef));
end;

{ TBextChunk }

class function TBextChunk.GetClassChunkName: TChunkName;
begin
  Result := 'bext';
end;

{ TBextChunkOld }

class function TBextChunkOld.GetClassChunkName: TChunkName;
begin
  Result := 'BEXT';
end;

procedure TBextChunkOld.SaveToStream(Stream: TStream);
begin
  raise Exception.Create
    ('the uppercase version of the bext chunk should not be written anymore!'#10#13'Please use the TBextChunk version');
end;

{ TCartChunkTag }

constructor TCartChunk.Create;
begin
  inherited;
  StartAddress := @CartRecord;
end;

procedure TCartChunk.AssignTo(Dest: TPersistent);
begin
  inherited;
  if Dest is TCartChunk then
    TCartChunk(Dest).CartRecord := CartRecord;
end;

class function TCartChunk.GetClassChunkName: TChunkName;
begin
  Result := 'cart';
end;

class function TCartChunk.GetClassChunkSize: Integer;
begin
  Result := SizeOf(TCartRecord);
end;

// Some Wrapper Functions
function TCartChunk.GetArtist: string;
begin
  Result := string(CartRecord.Artist);
end;

function TCartChunk.GetCategory: string;
begin
  Result := string(CartRecord.Category);
end;

function TCartChunk.GetClassification: string;
begin
  Result := string(CartRecord.Classification);
end;

function TCartChunk.GetClientID: string;
begin
  Result := string(CartRecord.ClientID);
end;

function TCartChunk.GetCutID: string;
begin
  Result := string(CartRecord.CutID);
end;

function TCartChunk.GetEndDate: string;
begin
  Result := string(CartRecord.EndDate);
end;

function TCartChunk.GetEndTime: string;
begin
  Result := string(CartRecord.EndTime);
end;

function TCartChunk.GetOutCue: string;
begin
  Result := string(CartRecord.OutCue);
end;

function TCartChunk.GetProducerAppID: string;
begin
  Result := string(CartRecord.ProducerAppID);
end;

function TCartChunk.GetProducerAppVersion: string;
begin
  Result := string(CartRecord.ProducerAppVersion);
end;

function TCartChunk.GetStartDate: string;
begin
  Result := string(CartRecord.StartDate);
end;

function TCartChunk.GetStartTime: string;
begin
  Result := string(CartRecord.StartTime);
end;

function TCartChunk.GetTitle: string;
begin
  Result := string(CartRecord.Title);
end;

function TCartChunk.GetUserDef: string;
begin
  Result := string(CartRecord.UserDef);
end;

procedure TCartChunk.SetArtist(const Value: string);
begin
  with CartRecord do
    if Length(Value) < SizeOf(Artist) then
      Move(Value[1], Artist, Length(Value))
    else
      Move(Value[1], Artist, SizeOf(Artist));
end;

procedure TCartChunk.SetCategory(const Value: string);
begin
  with CartRecord do
    if Length(Value) < SizeOf(Category) then
      Move(Value[1], Category, Length(Value))
    else
      Move(Value[1], Category, SizeOf(Category));
end;

procedure TCartChunk.SetClassification(const Value: string);
begin
  with CartRecord do
    if Length(Value) < SizeOf(Classification) then
      Move(Value[1], Classification, Length(Value))
    else
      Move(Value[1], Classification, SizeOf(Classification));
end;

procedure TCartChunk.SetClientID(const Value: string);
begin
  with CartRecord do
    if Length(Value) < SizeOf(ClientID) then
      Move(Value[1], ClientID, Length(Value))
    else
      Move(Value[1], ClientID, SizeOf(ClientID));
end;

procedure TCartChunk.SetCutID(const Value: string);
begin
  with CartRecord do
    if Length(Value) < SizeOf(CutID) then
      Move(Value[1], CutID, Length(Value))
    else
      Move(Value[1], CutID, SizeOf(CutID));
end;

procedure TCartChunk.SetEndDate(const Value: string);
begin
  with CartRecord do
    if Length(Value) < SizeOf(EndDate) then
      Move(Value[1], EndDate, Length(Value))
    else
      Move(Value[1], EndDate, SizeOf(EndDate));
end;

procedure TCartChunk.SetEndTime(const Value: string);
begin
  with CartRecord do
    if Length(Value) < SizeOf(EndTime) then
      Move(Value[1], EndTime, Length(Value))
    else
      Move(Value[1], EndTime, SizeOf(EndTime));
end;

procedure TCartChunk.SetOutCue(const Value: string);
begin
  with CartRecord do
    if Length(Value) < SizeOf(OutCue) then
      Move(Value[1], OutCue, Length(Value))
    else
      Move(Value[1], OutCue, SizeOf(OutCue));
end;

procedure TCartChunk.SetProducerAppID(const Value: string);
begin
  with CartRecord do
    if Length(Value) < SizeOf(ProducerAppID) then
      Move(Value[1], ProducerAppID, Length(Value))
    else
      Move(Value[1], ProducerAppID, SizeOf(ProducerAppID));
end;

procedure TCartChunk.SetProducerAppVersion(const Value: string);
begin
  with CartRecord do
    if Length(Value) < SizeOf(ProducerAppVersion) then
      Move(Value[1], ProducerAppVersion, Length(Value))
    else
      Move(Value[1], ProducerAppVersion, SizeOf(ProducerAppVersion));
end;

procedure TCartChunk.SetStartDate(const Value: string);
begin
  with CartRecord do
    if Length(Value) < SizeOf(StartDate) then
      Move(Value[1], StartDate, Length(Value))
    else
      Move(Value[1], StartDate, SizeOf(StartDate));
end;

procedure TCartChunk.SetStartTime(const Value: string);
begin
  with CartRecord do
    if Length(Value) < SizeOf(StartTime) then
      Move(Value[1], StartTime, Length(Value))
    else
      Move(Value[1], StartTime, SizeOf(StartTime));
end;

procedure TCartChunk.SetTitle(const Value: string);
begin
  with CartRecord do
    if Length(Value) < SizeOf(Title) then
      Move(Value[1], Title, Length(Value))
    else
      Move(Value[1], Title, SizeOf(Title));
end;

procedure TCartChunk.SetUserDef(const Value: string);
begin
  with CartRecord do
    if Length(Value) < SizeOf(UserDef) then
      Move(Value[1], UserDef, Length(Value))
    else
      Move(Value[1], UserDef, SizeOf(UserDef));
end;

initialization

RegisterWaveChunks([TFormatChunk, TFactChunk, TQualityChunk, TLabelChunk,
  TNoteChunk, TLabeledTextChunk, TCuedFileChunk, TPlaylistChunk, TSilentChunk,
  TCueChunk, TAssociatedDataListChunk, TInfoSoftwareNameChunk,
  TInfoCommentChunk, TInfoCreationDateChunk, TInfoSubjectChunk,
  TInfoCopyrightChunk, TInfoArtistChunk, TInfoTitleChunk, TJunkChunk, TPadChunk,
  TSamplerChunk, TInstrumentChunk, TBextChunk, TCartChunk])

end.
