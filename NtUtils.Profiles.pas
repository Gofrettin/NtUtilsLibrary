unit NtUtils.Profiles;

{
  The module provides support for working with normal (user) and AppContainer
  profiles.
}

interface

uses
  Ntapi.WinNt, Ntapi.UserEnv, Ntapi.ntseapi, NtUtils, DelphiApi.Reflection;

type
  TProfileInfo = record
    [Hex] Flags: Cardinal;
    FullProfile: LongBool;
    ProfilePath: String;
  end;

  TAppContainerInfo = record
    User: ISid;
    Package: ISid;
    [opt] ParentPackage: ISid;
    Name: String;
    DisplayName: String;
    ParentName: String;
    function FullName: String;
  end;

{ User profiles }

// Load a profile using a token
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpAlways)]
function UnvxLoadProfile(
  out hxKey: IHandle;
  [Access(TOKEN_LOAD_PROFILE)] hxToken: IHandle
): TNtxStatus;

// Unload a profile using a token
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpAlways)]
function UnvxUnloadProfile(
  [Access(0)] hProfileKey: THandle;
  [Access(TOKEN_LOAD_PROFILE)] hxToken: IHandle
): TNtxStatus;

// Enumerate existing profiles on the system
function UnvxEnumerateProfiles(
  out Profiles: TArray<ISid>
): TNtxStatus;

// Enumerate loaded profiles on the system
function UnvxEnumerateLoadedProfiles(
  out Profiles: TArray<ISid>
): TNtxStatus;

// Query profile information
function UnvxQueryProfile(
  const Sid: ISid;
  out Info: TProfileInfo
): TNtxStatus;

{ AppContainer profiles }

// Create an AppContainer profile
function UnvxCreateAppContainer(
  out Sid: ISid;
  const AppContainerName: String;
  [opt] DisplayName: String = '';
  [opt] Description: String = '';
  [opt] const Capabilities: TArray<TGroup> = nil
): TNtxStatus;

// Create an AppContainer profile or open an existing one
function UnvxCreateDeriveAppContainer(
  out Sid: ISid;
  const AppContainerName: String;
  [opt] const DisplayName: String = '';
  [opt] const Description: String = '';
  [opt] const Capabilities: TArray<TGroup> = nil
): TNtxStatus;

// Delete an AppContainer profile
function UnvxDeleteAppContainer(
  const AppContainerName: String
): TNtxStatus;

// Query AppContainer information
function UnvxQueryAppContainer(
  out Info: TAppContainerInfo;
  const AppContainer: ISid;
  [opt] const User: ISid = nil
): TNtxStatus;

// Get a name or an SID of an AppContainer
function UnvxAppContainerToString(
  const AppContainer: ISid;
  [opt] const User: ISid = nil
): String;

// Query AppContainer folder location
function UnvxQueryFolderAppContainer(
  const AppContainerSid: ISid;
  out Path: String
): TNtxStatus;

// Enumerate AppContainer profiles
function UnvxEnumerateAppContainers(
  out AppContainers: TArray<ISid>;
  [opt] const User: ISid = nil
): TNtxStatus;

// Enumerate children of AppContainer profile
function UnvxEnumerateChildrenAppContainer(
  out Children: TArray<ISid>;
  const AppContainer: ISid;
  [opt] const User: ISid = nil
): TNtxStatus;

implementation

uses
  Ntapi.ntregapi, Ntapi.ntdef, Ntapi.ntstatus, Ntapi.ntrtl, Ntapi.WinError,
  Ntapi.ObjBase, NtUtils.Registry, NtUtils.Errors, NtUtils.Ldr, NtUtils.Tokens,
  NtUtils.Security.AppContainer, DelphiUtils.Arrays, NtUtils.Security.Sid,
  NtUtils.Registry.HKCU, NtUtils.Objects, NtUtils.Tokens.Info, NtUtils.Lsa.Sid;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

const
  PROFILE_PATH = REG_PATH_MACHINE + '\SOFTWARE\Microsoft\Windows NT\' +
    'CurrentVersion\ProfileList';

  APPCONTAINER_MAPPING_PATH = '\Software\Classes\Local Settings\Software\' +
    'Microsoft\Windows\CurrentVersion\AppContainer\Mappings';
  APPCONTAINER_NAME = 'Moniker';
  APPCONTAINER_PARENT_NAME = 'ParentMoniker';
  APPCONTAINER_DISPLAY_NAME = 'DisplayName';
  APPCONTAINER_CHILDREN = '\Children';

{ User profiles }

function UnvxLoadProfile;
var
  Sid: ISid;
  UserName: String;
  Profile: TProfileInfoW;
begin
  // Expand pseudo-handles
  Result := NtxExpandToken(hxToken, TOKEN_LOAD_PROFILE);

  if not Result.IsSuccess then
    Exit;

  // Determine the SID
  Result := NtxQuerySidToken(hxToken, TokenUser, Sid);

  if not Result.IsSuccess then
    Exit;

  UserName := LsaxSidToString(Sid);

  FillChar(Profile, SizeOf(Profile), 0);
  Profile.Size := SizeOf(Profile);
  Profile.UserName := PWideChar(UserName);

  Result.Location := 'LoadUserProfileW';
  Result.LastCall.ExpectedPrivilege := SE_RESTORE_PRIVILEGE;
  Result.LastCall.Expects<TTokenAccessMask>(TOKEN_LOAD_PROFILE);

  Result.Win32Result := LoadUserProfileW(hxToken.Handle, Profile);

  if Result.IsSuccess then
     hxKey := Auto.CaptureHandle(Profile.hProfile);
end;

function UnvxUnloadProfile;
begin
  // Expand pseudo-handles
  Result := NtxExpandToken(hxToken, TOKEN_LOAD_PROFILE);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'UnloadUserProfile';
  Result.LastCall.ExpectedPrivilege := SE_RESTORE_PRIVILEGE;
  Result.LastCall.Expects<TTokenAccessMask>(TOKEN_LOAD_PROFILE);

  Result.Win32Result := UnloadUserProfile(hxToken.Handle, hProfileKey);
end;

function UnvxEnumerateProfiles;
var
  hxKey: IHandle;
  ProfileStrings: TArray<String>;
begin
  // Lookup the profile list in the registry
  Result := NtxOpenKey(hxKey, PROFILE_PATH, KEY_ENUMERATE_SUB_KEYS);

  // Each sub-key is a profile SID
  if Result.IsSuccess then
    Result := NtxEnumerateSubKeys(hxKey.Handle, ProfileStrings);

  // Convert strings to SIDs ignoring irrelevant entries
  if Result.IsSuccess then
    Profiles := TArray.Convert<String, ISid>(ProfileStrings,
      RtlxStringToSidConverter);
end;

function UnvxEnumerateLoadedProfiles;
var
  hxKey: IHandle;
  ProfileStrings: TArray<String>;
begin
  // Each loaded profile is a sub-key in HKU
  Result := NtxOpenKey(hxKey, REG_PATH_USER, KEY_ENUMERATE_SUB_KEYS);

  if Result.IsSuccess then
    Result := NtxEnumerateSubKeys(hxKey.Handle, ProfileStrings);

  // Convert strings to SIDs ignoring irrelevant entries
  if Result.IsSuccess then
    Profiles := TArray.Convert<String, ISid>(ProfileStrings,
      RtlxStringToSidConverter);
end;

function UnvxQueryProfile;
var
  hxKey: IHandle;
begin
  // Retrieve the information from the registry
  Result := NtxOpenKey(hxKey, PROFILE_PATH + '\' + RtlxSidToString(Sid),
    KEY_QUERY_VALUE);

  if not Result.IsSuccess then
    Exit;

  Info := Default(TProfileInfo);

  // The only necessary value
  Result := NtxQueryValueKeyString(hxKey.Handle, 'ProfileImagePath',
    Info.ProfilePath);

  if Result.IsSuccess then
  begin
    NtxQueryValueKeyUInt(hxKey.Handle, 'Flags', Info.Flags);
    NtxQueryValueKeyUInt(hxKey.Handle, 'FullProfile',
      Cardinal(Info.FullProfile));
  end;
end;

{ AppContainer profiles }

function UnvxCreateAppContainer;
var
  CapArray: TArray<TSidAndAttributes>;
  i: Integer;
  Buffer: PSid;
begin
  Result := LdrxCheckModuleDelayedImport(userenv, 'CreateAppContainerProfile');

  if not Result.IsSuccess then
    Exit;

  SetLength(CapArray, Length(Capabilities));

  for i := 0 to High(CapArray) do
  begin
    CapArray[i].Sid := Capabilities[i].Sid.Data;
    CapArray[i].Attributes := Capabilities[i].Attributes;
  end;

  // The function does not like empty strings
  if DisplayName = '' then
    DisplayName := AppContainerName;

  if Description = '' then
    Description := DisplayName;

  Result.Location := 'CreateAppContainerProfile';
  Result.HResult := CreateAppContainerProfile(PWideChar(AppContainerName),
    PWideChar(DisplayName), PWideChar(Description), CapArray, Length(CapArray),
    Buffer);

  if not Result.IsSuccess then
    Exit;

  RtlxDelayFreeSid(Buffer);
  Result := RtlxCopySid(Buffer, Sid);
end;

function UnvxCreateDeriveAppContainer;
begin
  Result := UnvxCreateAppContainer(Sid, AppContainerName, DisplayName,
    Description, Capabilities);

  if Result.Matches(TWin32Error(ERROR_ALREADY_EXISTS).ToNtStatus,
    'CreateAppContainerProfile') then
    Result := RtlxAppContainerNameToSid(AppContainerName, Sid);
end;

function UnvxDeleteAppContainer;
begin
  Result := LdrxCheckModuleDelayedImport(userenv, 'DeleteAppContainerProfile');

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DeleteAppContainerProfile';
  Result.HResult := DeleteAppContainerProfile(PWideChar(AppContainerName));
end;

function UnvxDelayCoTaskMemFree(
  [in] Buffer: Pointer
): IAutoReleasable;
begin
  Result := Auto.Delay(
    procedure
    begin
      CoTaskMemFree(Buffer);
    end
  );
end;

function UnvxQueryFolderAppContainer;
var
  Buffer: PWideChar;
begin
  Result := LdrxCheckModuleDelayedImport(userenv, 'GetAppContainerFolderPath');

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'GetAppContainerFolderPath';
  Result.HResult := GetAppContainerFolderPath(PWideChar(RtlxSidToString(
    AppContainerSid)), Buffer);

  if not Result.IsSuccess then
    Exit;

  UnvxDelayCoTaskMemFree(Buffer);
  Path := String(Buffer);
end;

// Functions with custom implementation

function RtlxpAppContainerRegPath(
  [opt] const User: ISid;
  [opt] const AppContainer: ISid;
  out Path: String
): TNtxStatus;
begin
  if not Assigned(User) then
  begin
    // Use HKCU of the effective user
    Result := RtlxFormatUserKeyPath(Path, NtxCurrentEffectiveToken);

    if not Result.IsSuccess then
      Exit;
  end
  else
  begin
    Result.Status := STATUS_SUCCESS;
    Path := REG_PATH_USER + '\' + RtlxSidToString(User);
  end;

  Path := Path + APPCONTAINER_MAPPING_PATH;

  if Assigned(AppContainer) then
    Path := Path + '\' + RtlxSidToString(AppContainer);
end;

function UnvxQueryAppContainer;
var
  hxKey: IHandle;
  Path: String;
begin
  Info.Package := AppContainer;

  // AppContainers are per-user
  if not Assigned(User) then
  begin
    // Allow querying info relative to the impersonated user
    Result := NtxQuerySidToken(NtxCurrentEffectiveToken, TokenUser, Info.User);

    if not Result.IsSuccess then
      Exit;
  end
  else
    Info.User := User;

  // Determine the type the AppContainer
  if RtlxAppContainerType(AppContainer) = ChildAppContainerSidType then
  begin
    // This is a child; save parent's SID
    Result := RtlxAppContainerParent(AppContainer, Info.ParentPackage);

    if not Result.IsSuccess then
      Exit;

    // For child AppContainers, the path to the profile contains both the
    // child's and the parent'd SIDs:
    // HKU\<user-SID>\...\<parent-SID>\Children\<child-SID>

    // Prepare the parent part of the path
    Result := RtlxpAppContainerRegPath(Info.User, Info.ParentPackage, Path);

    if not Result.IsSuccess then
      Exit;

    // Append the child part
    Path := Path + APPCONTAINER_CHILDREN + '\' + RtlxSidToString(AppContainer);
  end
  else
  begin
    Info.ParentPackage := nil;

    // Prepare the path
    Result := RtlxpAppContainerRegPath(Info.User, Info.Package, Path);

    if not Result.IsSuccess then
      Exit;
  end;

  // Open the profile key
  Result := NtxOpenKey(hxKey, Path, KEY_QUERY_VALUE);

  if not Result.IsSuccess then
    Exit;

  // Read the name (aka moniker)
  Result := NtxQueryValueKeyString(hxKey.Handle, APPCONTAINER_NAME, Info.Name);

  if not Result.IsSuccess then
    Exit;

  // Read the Display Name
  Result := NtxQueryValueKeyString(hxKey.Handle, APPCONTAINER_DISPLAY_NAME,
    Info.DisplayName);

  if not Result.IsSuccess then
    Exit;

  if Assigned(Info.ParentPackage) then
  begin
    // Read the parent's name
    Result := NtxQueryValueKeyString(hxKey.Handle, APPCONTAINER_PARENT_NAME,
      Info.ParentName);

    if not Result.IsSuccess then
      Exit;
  end
  else
    Info.ParentName := '';
end;

function UnvxAppContainerToString;
var
  Info: TAppContainerInfo;
begin
  if UnvxQueryAppContainer(Info, AppContainer, User).IsSuccess then
    Result := Info.FullName
  else
    Result := RtlxSidToString(AppContainer);
end;

function UnvxEnumerateAppContainers;
var
  hxKey: IHandle;
  Path: String;
  AppContainerStrings: TArray<String>;
begin
  // All registered AppContainers are stored as registry keys

  Result := RtlxpAppContainerRegPath(User, nil, Path);

  if Result.IsSuccess then
    Result := NtxOpenKey(hxKey, Path, KEY_ENUMERATE_SUB_KEYS);

  if Result.IsSuccess then
    Result := NtxEnumerateSubKeys(hxKey.Handle, AppContainerStrings);

  // Convert strings to SIDs ignoring irrelevant entries
  if Result.IsSuccess then
    AppContainers := TArray.Convert<String, ISid>(AppContainerStrings,
      RtlxStringToSidConverter);
end;

function UnvxEnumerateChildrenAppContainer;
var
  hxKey: IHandle;
  Path: String;
  ChildrenStrings: TArray<String>;
begin
  // All registered children are stored as subkeys of a parent profile

  Result := RtlxpAppContainerRegPath(User, AppContainer, Path);

  if Result.IsSuccess then
    Result := NtxOpenKey(hxKey, Path + APPCONTAINER_CHILDREN,
      KEY_ENUMERATE_SUB_KEYS);

  if Result.IsSuccess then
    Result := NtxEnumerateSubKeys(hxKey.Handle, ChildrenStrings);

  // Convert strings to SIDs ignoring irrelevant entries
  if Result.IsSuccess then
    Children := TArray.Convert<String, ISid>(ChildrenStrings,
      RtlxStringToSidConverter);
end;

{ TAppContainerInfo }

function TAppContainerInfo.FullName;
begin
  Result := Name;

  if Assigned(ParentPackage) then
    Result := ParentName + '/' + Result;
end;

end.
