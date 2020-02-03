unit Winapi.WinBase;

{$MINENUMSIZE 4}

interface

uses
  Winapi.WinNt, Winapi.NtSecApi, DelphiApi.Reflection;

type
  [NamingStyle(nsSnakeCase, 'LOGON32_PROVIDER')]
  TLogonProvider = (
    LOGON32_PROVIDER_DEFAULT = 0,
    LOGON32_PROVIDER_WINNT35 = 1,
    LOGON32_PROVIDER_WINNT40 = 2,
    LOGON32_PROVIDER_WINNT50 = 3,
    LOGON32_PROVIDER_VIRTUAL = 4
  );

  // minwinbase.46
  TSecurityAttributes = record
    nLength: Cardinal;
    lpSecurityDescriptor: PSecurityDescriptor;
    bInheritHandle: LongBool;
  end;
  PSecurityAttributes = ^TSecurityAttributes;

// 1180
function LocalFree(hMem: Pointer): Pointer; stdcall; external kernel32;

// errhandlingapi.89
function GetLastError: Cardinal; stdcall; external kernel32;

// debugapi.62
procedure OutputDebugStringW(lpOutputString: PWideChar); stdcall;
  external kernel32;

// 7202
function LogonUserW (lpszUsername: PWideChar; lpszDomain: PWideChar;
  lpszPassword: PWideChar; dwLogonType: TSecurityLogonType; dwLogonProvider:
  TLogonProvider; out hToken: THandle): LongBool; stdcall; external advapi32;

// winbasep ?
function LogonUserExExW(lpszUsername: PWideChar; lpszDomain: PWideChar;
  lpszPassword: PWideChar; dwLogonType: TSecurityLogonType; dwLogonProvider:
  TLogonProvider; pTokenGroups: PTokenGroups; out hToken: THandle;
  ppLogonSid: PPointer; pProfileBuffer: PPointer; pdwProfileLength: PCardinal;
  QuotaLimits: Pointer): LongBool; stdcall; external advapi32;

// WinUser.10833, reverse and move to rtl
function LoadStringW(hInstance: HINST; uID: Cardinal; out pBuffer: PWideChar;
  nBufferMax: Integer = 0): Integer; stdcall; external kernelbase;

implementation

end.
