unit Ntapi.UserEnv;

{
  This file defines functions for working with user and AppContainer profiles.
}

interface

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.ntseapi, Ntapi.ntregapi, Ntapi.Versions,
  DelphiApi.Reflection;

const
  userenv = 'userenv.dll';

const
  // SDK::UserEnv.h - profile flags
  PT_TEMPORARY = $00000001;
  PT_ROAMING = $00000002;
  PT_MANDATORY = $00000004;
  PT_ROAMING_PREEXISTING = $00000008;

  // For annotations
  TOKEN_LOAD_PROFILE = TOKEN_QUERY or TOKEN_IMPERSONATE or TOKEN_DUPLICATE;

type
  [FlagName(PT_TEMPORARY, 'Temporary')]
  [FlagName(PT_ROAMING, 'Roaming')]
  [FlagName(PT_MANDATORY, 'Mandatory')]
  [FlagName(PT_ROAMING_PREEXISTING, 'Roaming Pre-existing')]
  TProfileType = type Cardinal;

  // SDK::ProfInfo.h
  [SDKName('PROFILEINFOW')]
  TProfileInfoW = record
    [Bytes, Unlisted] Size: Cardinal;
    Flags: TProfileType;
    UserName: PWideChar;
    ProfilePath: PWideChar;
    DefaultPath: PWideChar;
    ServerName: PWideChar;
    PolicyPath: PWideChar;
    hProfile: THandle;
  end;
  PProfileInfoW = ^TProfileInfoW;

// SDK::UserEnv.h
[SetsLastError]
[Result: ReleaseWith('UnloadUserProfile')]
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpAlways)]
function LoadUserProfileW(
  [in, Access(TOKEN_LOAD_PROFILE)] hToken: THandle;
  [in, out] var ProfileInfo: TProfileInfoW
): LongBool; stdcall; external userenv delayed;

// SDK::UserEnv.h
[SetsLastError]
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpAlways)]
function UnloadUserProfile(
  [in, Access(TOKEN_LOAD_PROFILE)] hToken: THandle;
  [in] hProfile: THandle
): LongBool; stdcall; external userenv delayed;

// SDK::UserEnv.h
[SetsLastError]
function GetProfilesDirectoryW(
  [out, WritesTo] ProfileDir: PWideChar;
  [in, out, NumberOfElements] var Size: Cardinal
): LongBool; stdcall; external userenv delayed;

// SDK::UserEnv.h
[SetsLastError]
function GetProfileType(
  [out] out Flags: TProfileType
): LongBool; stdcall; external userenv delayed;

// SDK::UserEnv.h
[SetsLastError]
function CreateEnvironmentBlock(
  [out, ReleaseWith('RtlDestroyEnvironment')] out Environment: PEnvironment;
  [in, opt] hToken: THandle;
  [in] bInherit: LongBool
): LongBool; stdcall; external userenv delayed;

// SDK::UserEnv.h
[MinOSVersion(OsWin8)]
[Result: ReleaseWith('DeleteAppContainerProfile')]
function CreateAppContainerProfile(
  [in] AppContainerName: PWideChar;
  [in] DisplayName: PWideChar;
  [in] Description: PWideChar;
  [in, opt, ReadsFrom] const Capabilities: TArray<TSidAndAttributes>;
  [in, opt, NumberOfElements] CapabilityCount: Integer;
  [out, ReleaseWith('RtlFreeSid')] out SidAppContainerSid: PSid
): HResult; stdcall; external userenv delayed;

// SDK::UserEnv.h
[MinOSVersion(OsWin8)]
function DeleteAppContainerProfile(
  [in] AppContainerName: PWideChar
): HResult; stdcall; external userenv delayed;

// SDK::UserEnv.h
[MinOSVersion(OsWin8)]
function GetAppContainerRegistryLocation(
  [in] DesiredAccess: TRegKeyAccessMask;
  [out, ReleaseWith('NtClose')] out hAppContainerKey: THandle
): HResult; stdcall; external userenv delayed;

// SDK::UserEnv.h
[MinOSVersion(OsWin8)]
function GetAppContainerFolderPath(
  [in] AppContainerSid: PWideChar;
  [out, ReleaseWith('CoTaskMemFree')] out Path: PWideChar
): HResult; stdcall; external userenv delayed;

// MSDN
[MinOSVersion(OsWin8)]
function AppContainerDeriveSidFromMoniker(
  [in] Moniker: PWideChar;
  [out, ReleaseWith('RtlFreeSid')] out AppContainerSid: PSid
): HResult; stdcall; external kernelbase delayed;

// rev
[MinOSVersion(OsWin8)]
function AppContainerFreeMemory(
  [in] Memory: Pointer
): Boolean; stdcall; external kernelbase delayed;

// rev
[MinOSVersion(OsWin8)]
function AppContainerLookupMoniker(
  [in] Sid: PSid;
  [out, ReleaseWith('AppContainerFreeMemory')] out Moniker: PWideChar
): HResult; stdcall; external kernelbase delayed;

// SDK::UserEnv.h
[MinOSVersion(OsWin81)]
function DeriveRestrictedAppContainerSidFromAppContainerSidAndRestrictedName(
  [in] AppContainerSid: PSid;
  [in] RestrictedAppContainerName: PWideChar;
  [out, ReleaseWith('RtlFreeSid')] out RestrictedAppContainerSid: PSid
): HResult; stdcall; external userenv delayed;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
