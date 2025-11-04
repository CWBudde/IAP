unit IAP.PortAudio.BindingStatic;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  Types, IAP.PortAudio.Types;

const
{$IF Defined(MSWINDOWS)}
  LibName = 'portaudio.dll';
{$ELSEIF Defined(MACOS)}
  // this is for portaudio version 19
  LibName = 'libportaudio.2.dylib';
{$ELSEIF Defined(UNIX)}
  LibName = 'libportaudio.so';
{$IFEND}
{$IFDEF MACOS}

function Pa_GetVersion: LongInt; cdecl; external LibName name '_Pa_GetVersion';
function Pa_GetVersionText: PAnsiChar; cdecl;
  external LibName name '_Pa_GetVersionText';
function Pa_GetErrorText(ErrorCode: TPaError): PAnsiChar; cdecl;
  external LibName name '_Pa_GetErrorText';
function Pa_Initialize: TPaError; cdecl; external LibName name '_Pa_Initialize';
function Pa_Terminate: TPaError; cdecl; external LibName name '_Pa_Terminate';
function Pa_GetHostApiCount: TPaHostApiIndex; cdecl;
  external LibName name '_Pa_GetHostApiCount';
function Pa_GetDefaultHostApi: TPaHostApiIndex; cdecl;
  external LibName name '_Pa_GetDefaultHostApi';
function Pa_GetHostApiInfo(HostApi: TPaHostApiIndex): PPaHostApiInfo; cdecl;
  external LibName name '_Pa_GetHostApiInfo';
function Pa_HostApiTypeIdToHostApiIndex(HostApiTypeId: TPaHostApiTypeId)
  : TPaHostApiIndex; cdecl;
  external LibName name '_Pa_HostApiTypeIdToHostApiIndex';
function Pa_HostApiDeviceIndexToDeviceIndex(HostApi: TPaHostApiIndex;
  HostApiDeviceIndex: LongInt): TPaDeviceIndex; cdecl;
  external LibName name '_Pa_HostApiDeviceIndexToDeviceIndex';
function Pa_GetLastHostErrorInfo: PPaHostErrorInfo; cdecl;
  external LibName name '_Pa_GetLastHostErrorInfo';
function Pa_GetDeviceCount: TPaDeviceIndex; cdecl;
  external LibName name '_Pa_GetDeviceCount';
function Pa_GetDefaultInputDevice: TPaDeviceIndex; cdecl;
  external LibName name '_Pa_GetDefaultInputDevice';
function Pa_GetDefaultOutputDevice: TPaDeviceIndex; cdecl;
  external LibName name '_Pa_GetDefaultOutputDevice';
function Pa_GetDeviceInfo(Device: TPaDeviceIndex): PPaDeviceInfo; cdecl;
  external LibName name '_Pa_GetDeviceInfo';
function Pa_IsFormatSupported(InputParameters: PPaStreamParameters;
  OutputParameters: PPaStreamParameters; SampleRate: Double): TPaError; cdecl;
  external LibName name '_Pa_IsFormatSupported';
function Pa_OpenStream(var Stream: PPaStream;
  InputParameters: PPaStreamParameters; OutputParameters: PPaStreamParameters;
  SampleRate: Double; FramesPerBuffer: NativeUInt; StreamFlags: TPaStreamFlags;
  StreamCallback: PPaStreamCallback; UserData: Pointer): TPaError; cdecl;
  external LibName name '_Pa_OpenStream';
function Pa_OpenDefaultStream(var Stream: PPaStream; NumInputChannels: LongInt;
  NumOutputChannels: LongInt; SampleFormat: TPaSampleFormat; SampleRate: Double;
  FramesPerBuffer: NativeUInt; StreamCallback: PPaStreamCallback;
  UserData: Pointer): TPaError; cdecl;
  external LibName name '_Pa_OpenDefaultStream';
function Pa_CloseStream(Stream: PPaStream): TPaError; cdecl;
  external LibName name '_Pa_CloseStream ';
function Pa_SetStreamFinishedCallback(Stream: PPaStream;
  StreamFinishedCallback: PPaStreamFinishedCallback): TPaError; cdecl;
  external LibName name '_Pa_SetStreamFinishedCallback ';
function Pa_StartStream(Stream: PPaStream): TPaError; cdecl;
  external LibName name '_Pa_StartStream';
function Pa_StopStream(Stream: PPaStream): TPaError; cdecl;
  external LibName name '_Pa_StopStream';
function Pa_AbortStream(Stream: PPaStream): TPaError; cdecl;
  external LibName name '_Pa_AbortStream';
function Pa_IsStreamStopped(Stream: PPaStream): TPaError; cdecl;
  external LibName name '_Pa_IsStreamStopped';
function Pa_IsStreamActive(Stream: PPaStream): TPaError; cdecl;
  external LibName name '_Pa_IsStreamActive';
function Pa_GetStreamInfo(Stream: PPaStream): PPaStreamInfo; cdecl;
  external LibName name '_Pa_GetStreamInfo';
function Pa_GetStreamTime(Stream: PPaStream): TPaTime; cdecl;
  external LibName name '_Pa_GetStreamTime';
function Pa_GetStreamCpuLoad(Stream: PPaStream): Double; cdecl;
  external LibName name '_Pa_GetStreamCpuLoad';
function Pa_ReadStream(Stream: PPaStream; Buffer: Pointer; Frames: NativeUInt)
  : TPaError; cdecl; external LibName name '_Pa_ReadStream';
function Pa_WriteStream(Stream: PPaStream; Buffer: Pointer; Frames: NativeUInt)
  : TPaError; cdecl; external LibName name '_Pa_WriteStream';
function Pa_GetStreamReadAvailable(Stream: PPaStream): NativeInt; cdecl;
  external LibName name '_Pa_GetStreamReadAvailable';
function Pa_GetStreamWriteAvailable(Stream: PPaStream): NativeInt; cdecl;
  external LibName name '_Pa_GetStreamWriteAvailable';
function Pa_GetStreamHostApiType(Stream: PPaStream): TPaHostApiTypeId; cdecl;
  external LibName name '_Pa_GetStreamHostApiType';
function Pa_GetSampleSize(Format: TPaSampleFormat): TPaError; cdecl;
  external LibName name '_Pa_GetSampleSize';
procedure Pa_Sleep(MSec: Int64); cdecl; external LibName name '_Pa_Sleep';
{$ELSE}
function Pa_GetVersion: LongInt; cdecl; external LibName;
function Pa_GetVersionText: PAnsiChar; cdecl; external LibName;
function Pa_GetErrorText(ErrorCode: TPaError): PAnsiChar; cdecl;
  external LibName;
function Pa_Initialize: TPaError; cdecl; external LibName;
function Pa_Terminate: TPaError; cdecl; external LibName;
function Pa_GetHostApiCount: TPaHostApiIndex; cdecl; external LibName;
function Pa_GetDefaultHostApi: TPaHostApiIndex; cdecl; external LibName;
function Pa_GetHostApiInfo(HostApi: TPaHostApiIndex): PPaHostApiInfo; cdecl;
  external LibName;
function Pa_HostApiTypeIdToHostApiIndex(HostApiTypeId: TPaHostApiTypeId)
  : TPaHostApiIndex; cdecl; external LibName;
function Pa_HostApiDeviceIndexToDeviceIndex(HostApi: TPaHostApiIndex;
  HostApiDeviceIndex: LongInt): TPaDeviceIndex; cdecl; external LibName;
function Pa_GetLastHostErrorInfo: PPaHostErrorInfo; cdecl; external LibName;
function Pa_GetDeviceCount: TPaDeviceIndex; cdecl; external LibName;
function Pa_GetDefaultInputDevice: TPaDeviceIndex; cdecl; external LibName;
function Pa_GetDefaultOutputDevice: TPaDeviceIndex; cdecl; external LibName;
function Pa_GetDeviceInfo(Device: TPaDeviceIndex): PPaDeviceInfo; cdecl;
  external LibName;
function Pa_IsFormatSupported(InputParameters: PPaStreamParameters;
  OutputParameters: PPaStreamParameters; SampleRate: Double): TPaError; cdecl;
  external LibName;
function Pa_OpenStream(var Stream: PPaStream;
  InputParameters: PPaStreamParameters; OutputParameters: PPaStreamParameters;
  SampleRate: Double; FramesPerBuffer: NativeUInt; StreamFlags: TPaStreamFlags;
  StreamCallback: PPaStreamCallback; UserData: Pointer): TPaError; cdecl;
  external LibName;
function Pa_OpenDefaultStream(var Stream: PPaStream; NumInputChannels: LongInt;
  NumOutputChannels: LongInt; SampleFormat: TPaSampleFormat; SampleRate: Double;
  FramesPerBuffer: NativeUInt; StreamCallback: PPaStreamCallback;
  UserData: Pointer): TPaError; cdecl; external LibName;
function Pa_CloseStream(Stream: PPaStream): TPaError; cdecl; external LibName;
function Pa_SetStreamFinishedCallback(Stream: PPaStream;
  StreamFinishedCallback: PPaStreamFinishedCallback): TPaError; cdecl;
  external LibName;
function Pa_StartStream(Stream: PPaStream): TPaError; cdecl; external LibName;
function Pa_StopStream(Stream: PPaStream): TPaError; cdecl; external LibName;
function Pa_AbortStream(Stream: PPaStream): TPaError; cdecl; external LibName;
function Pa_IsStreamStopped(Stream: PPaStream): TPaError; cdecl;
  external LibName;
function Pa_IsStreamActive(Stream: PPaStream): TPaError; cdecl;
  external LibName;
function Pa_GetStreamInfo(Stream: PPaStream): PPaStreamInfo; cdecl;
  external LibName;
function Pa_GetStreamTime(Stream: PPaStream): TPaTime; cdecl; external LibName;
function Pa_GetStreamCpuLoad(Stream: PPaStream): Double; cdecl;
  external LibName;
function Pa_ReadStream(Stream: PPaStream; Buffer: Pointer; Frames: NativeUInt)
  : TPaError; cdecl; external LibName;
function Pa_WriteStream(Stream: PPaStream; Buffer: Pointer; Frames: NativeUInt)
  : TPaError; cdecl; external LibName;
function Pa_GetStreamReadAvailable(Stream: PPaStream): NativeInt; cdecl;
  external LibName;
function Pa_GetStreamWriteAvailable(Stream: PPaStream): NativeInt; cdecl;
  external LibName;
function Pa_GetStreamHostApiType(Stream: PPaStream): TPaHostApiTypeId; cdecl;
  external LibName;
function Pa_GetSampleSize(Format: TPaSampleFormat): TPaError; cdecl;
  external LibName;
procedure Pa_Sleep(MSec: Int64); cdecl; external LibName;
{$ENDIF}

implementation

end.
