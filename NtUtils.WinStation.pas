unit NtUtils.WinStation;

{
  The module provides access to the Window Station (aka Terminal Server) API.
}

interface

uses
  Ntapi.WinNt, Ntapi.winsta, Ntapi.WinUser, NtUtils, NtUtils.Objects;

type
  TSessionIdW = Ntapi.winsta.TSessionIdW;
  TWinStationInformation = Ntapi.winsta.TWinStationInformation;
  TWinStaHandle = Ntapi.winsta.TWinStaHandle;
  IWinStaHandle = NtUtils.IHandle;

// Connect to a remote computer
function WsxOpenServer(
  out hxServer: IWinStaHandle;
  const Name: String
): TNtxStatus;

// Enumerate all session on the server for which we have Query access
function WsxEnumerateSessions(
  out Sessions: TArray<TSessionIdW>;
  [opt] hServer: TWinStaHandle = SERVER_CURRENT
): TNtxStatus;

type
  WsxWinStation = class abstract
    // Query fixed-size information
    class function Query<T>(
      SessionId: TSessionId;
      InfoClass: TWinStationInfoClass;
      out Buffer: T;
      [opt] hServer: TWinStaHandle = SERVER_CURRENT
    ): TNtxStatus; static;
  end;

// Query variable-size information
function WsxQuery(
  SessionId: TSessionId;
  InfoClass: TWinStationInfoClass;
  out xMemory: IMemory;
  hServer: TWinStaHandle = SERVER_CURRENT;
  InitialBuffer: Cardinal = 0;
  [opt] GrowthMethod: TBufferGrowthMethod = nil
): TNtxStatus;

// Open session token
function WsxQueryToken(
  out hxToken: IHandle;
  SessionId: TSessionId;
  [opt] hServer: TWinStaHandle = SERVER_CURRENT
): TNtxStatus;

// Send a message to a session
function WsxSendMessage(
  SessionId: TSessionId;
  const Title: String;
  const MessageStr: String;
  Style: TMessageStyle;
  Timeout: Cardinal;
  WaitForResponse: Boolean = False;
  [out, opt] pResponse: PMessageResponse = nil;
  [opt] ServerHandle: TWinStaHandle = SERVER_CURRENT
): TNtxStatus;

// Connect one session to another
function WsxConnect(
  SessionId: TSessionId;
  TargetSessionId: TSessionId = LOGONID_CURRENT;
  [in, opt] Password: PWideChar = nil;
  Wait: Boolean = True;
  hServer: TWinStaHandle = SERVER_CURRENT
): TNtxStatus;

// Disconnect a session
function WsxDisconnect(
  SessionId: TSessionId;
  Wait: Boolean;
  hServer: TWinStaHandle = SERVER_CURRENT
): TNtxStatus;

// Remote control (shadow) an active remote session
function WsxRemoteControl(
  TargetSessionId: TSessionId;
  HotKeyVk: Byte;
  HotkeyModifiers: Word;
  hServer: TWinStaHandle = SERVER_CURRENT;
  [opt] const TargetServer: String = ''
): TNtxStatus;

// Stop controlling (shadowing) a session
function WsxRemoteControlStop(
  hServer: TWinStaHandle;
  SessionId: TSessionId;
  Wait: Boolean
): TNtxStatus;

implementation

uses
  NtUtils.SysUtils, DelphiUtils.AutoObjects;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

type
  TWinStaAutoHandle = class(TCustomAutoHandle, IWinStaHandle)
    procedure Release; override;
  end;

procedure TWinStaAutoHandle.Release;
begin
  if FHandle <> 0 then
    WinStationCloseServer(FHandle);

  FHandle := 0;
  inherited;
end;

function WsxDelayFreeMemory(
  [in] Buffer: Pointer
): IAutoReleasable;
begin
  Result := Auto.Delay(
    procedure
    begin
      WinStationFreeMemory(Buffer);
    end
  );
end;

function WsxOpenServer;
var
  hServer: TWinStaHandle;
begin
  Result.Location := 'WinStationOpenServerW';
  hServer := WinStationOpenServerW(PWideChar(Name));
  Result.Win32Result := hServer <> 0;

  if Result.IsSuccess then
    hxServer := Auto.CaptureHandle(hServer);
end;

function WsxEnumerateSessions;
var
  Buffer: PSessionIdArrayW;
  Count, i: Integer;
begin
  Result.Location := 'WinStationEnumerateW';
  Result.Win32Result := WinStationEnumerateW(hServer, Buffer, Count);

  if not Result.IsSuccess then
    Exit;

  WsxDelayFreeMemory(Buffer);
  SetLength(Sessions, Count);

  for i := 0 to High(Sessions) do
    Sessions[i] := Buffer{$R-}[i]{$IFDEF R+}{$IFDEF R+}{$R+}{$ENDIF}{$ENDIF};
 end;

class function WsxWinStation.Query<T>;
var
  Returned: Cardinal;
begin
  Result.Location := 'WinStationQueryInformationW';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);

  Result.Win32Result := WinStationQueryInformationW(hServer, SessionId,
    InfoClass, @Buffer, SizeOf(Buffer), Returned);
end;

function GrowWxsDefault(
  const Memory: IMemory;
  Required: NativeUInt
): NativeUInt;
begin
  Result := Memory.Size + (Memory.Size shr 2) + 64; // + 25% + 64 B
end;

function WsxQuery;
var
  Required: Cardinal;
begin
  Result.Location := 'WinStationQueryInformationW';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);

  // WinStationQueryInformationW might not return the required buffer size,
  // we need to guess it
  if not Assigned(GrowthMethod) then
    GrowthMethod := GrowWxsDefault;

  xMemory := Auto.AllocateDynamic(InitialBuffer);
  repeat
    Required := 0;
    Result.Win32Result := WinStationQueryInformationW(hServer, SessionId,
      InfoClass, xMemory.Data, xMemory.Size, Required);
  until not NtxExpandBufferEx(Result, xMemory, Required, GrowthMethod);
end;

function WsxQueryToken;
var
  UserToken: TWinStationUserToken;
begin
  UserToken := Default(TWinStationUserToken);

  Result := WsxWinStation.Query(SessionId, WinStationUserToken, UserToken,
    hServer);

  if Result.IsSuccess then
    hxToken := Auto.CaptureHandle(UserToken.UserToken);
end;

function WsxSendMessage;
var
  Response: TMessageResponse;
begin
  Result.Location := 'WinStationSendMessageW';
  Result.Win32Result := WinStationSendMessageW(ServerHandle, SessionId,
    PWideChar(Title), Length(Title) * SizeOf(WideChar),
    PWideChar(MessageStr), Length(MessageStr) * SizeOf(WideChar),
    Style, Timeout, Response, WaitForResponse);

  if Result.IsSuccess and Assigned(pResponse) then
    pResponse^ := Response;
end;

function WsxConnect;
begin
  // It fails with null pointer
  if not Assigned(Password) then
    Password := '';

  Result.Location := 'WinStationConnectW';
  Result.Win32Result := WinStationConnectW(hServer, SessionId, TargetSessionId,
    Password, Wait);
end;

function WsxDisconnect;
begin
  Result.Location := 'WinStationDisconnect';
  Result.Win32Result := WinStationDisconnect(hServer, SessionId, Wait);
end;

function WsxRemoteControl;
begin
  Result.Location := 'WinStationShadow';
  Result.Win32Result := WinStationShadow(hServer, RefStrOrNil(TargetServer),
    TargetSessionId, HotKeyVk, HotkeyModifiers);
end;

function WsxRemoteControlStop;
begin
  Result.Location := 'WinStationShadowStop';
  Result.Win32Result := WinStationShadowStop(hServer, SessionId, Wait);
end;

end.
