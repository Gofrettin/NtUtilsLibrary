unit NtUtils.Lsa;

{
  This module allows interoperation with Local Security Authority for managing
  privilege and logon rights assignment.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntlsa, Ntapi.ntseapi, NtUtils;

const
  POLICY_ENUMERATE_ACCOUNTS_WITH_RIGHT = POLICY_LOOKUP_NAMES or
    POLICY_VIEW_LOCAL_INFORMATION;

type
  TLsaHandle = Ntapi.ntlsa.TLsaHandle;
  ILsaHandle = NtUtils.IHandle;

  TPrivilegeDefinition = record
    Name: String;
    LocalValue: TLuid;
  end;

  TLogonRightRec = record
    Value: TSystemAccess;
    IsAllowedType: Boolean;
    Name, Description: String;
  end;

{ --------------------------------- Policy ---------------------------------- }

// Open LSA for desired access
function LsaxOpenPolicy(
  out hxPolicy: ILsaHandle;
  DesiredAccess: TLsaPolicyAccessMask;
  [opt] const SystemName: String = ''
): TNtxStatus;

// Make sure the policy handle is provided
function LsaxpEnsureConnected(
  var hxPolicy: ILsaHandle;
  DesiredAccess: TLsaPolicyAccessMask
): TNtxStatus;

// Query policy information
function LsaxQueryPolicy(
  [Access(POLICY_VIEW_LOCAL_INFORMATION or
    POLICY_VIEW_AUDIT_INFORMATION)] hPolicy: TLsaHandle;
  InfoClass: TPolicyInformationClass;
  out xBuffer: IAutoPointer
): TNtxStatus;

// Set policy information
function LsaxSetPolicy(
  [Access(POLICY_TRUST_ADMIN or POLICY_AUDIT_LOG_ADMIN or
    POLICY_SET_AUDIT_REQUIREMENTS or POLICY_SERVER_ADMIN or
    POLICY_SET_DEFAULT_QUOTA_LIMITS)] hPolicy: TLsaHandle;
  InfoClass: TPolicyInformationClass;
  [in] Buffer: Pointer
): TNtxStatus;

{ --------------------------------- Accounts -------------------------------- }

// Open an account from LSA database
function LsaxOpenAccount(
  out hxAccount: ILsaHandle;
  const AccountSid: ISid;
  DesiredAccess: TLsaAccountAccessMask;
  [opt, Access(POLICY_VIEW_LOCAL_INFORMATION)] hxPolicy: ILsaHandle = nil
): TNtxStatus;

// Add an account to LSA database
function LsaxCreateAccount(
  out hxAccount: ILsaHandle;
  const AccountSid: ISid;
  [opt, Access(POLICY_CREATE_ACCOUNT)] hxPolicy: ILsaHandle = nil;
  DesiredAccess: TLsaAccountAccessMask = ACCOUNT_ALL_ACCESS
): TNtxStatus;

// Delete account from LSA database
function LsaxDeleteAccount(
  [Access(_DELETE)] hAccount: TLsaHandle
): TNtxStatus;

// Enumerate account in the LSA database
function LsaxEnumerateAccounts(
  out Accounts: TArray<ISid>;
  [opt, Access(POLICY_VIEW_LOCAL_INFORMATION)] hxPolicy: ILsaHandle = nil
): TNtxStatus;

// Enumerate privileges assigned to an account
function LsaxEnumeratePrivilegesAccount(
  [Access(ACCOUNT_VIEW)] hAccount: TLsaHandle;
  out Privileges: TArray<TPrivilege>
): TNtxStatus;

// Enumerate privileges assigned to an account using its SID
function LsaxEnumeratePrivilegesAccountBySid(
  const AccountSid: ISid;
  out Privileges: TArray<TPrivilege>
): TNtxStatus;

// Assign privileges to an account
function LsaxAddPrivilegesAccount(
  [Access(ACCOUNT_ADJUST_PRIVILEGES)] hAccount: TLsaHandle;
  const Privileges: TArray<TPrivilege>
): TNtxStatus;

// Revoke privileges to an account
function LsaxRemovePrivilegesAccount(
  [Access(ACCOUNT_ADJUST_PRIVILEGES)] hAccount: TLsaHandle;
  RemoveAll: Boolean;
  [opt] const Privileges: TArray<TPrivilege>
): TNtxStatus;

// Assign & revoke privileges from an account in a single operation
function LsaxManagePrivilegesAccount(
  const AccountSid: ISid;
  RemoveAll: Boolean;
  [opt] const Add: TArray<TPrivilege>;
  [opt] const Remove: TArray<TPrivilege>
): TNtxStatus;

// Query logon rights of an account
function LsaxQueryRightsAccount(
  [Access(ACCOUNT_VIEW)] hAccount: TLsaHandle;
  out SystemAccess: TSystemAccess
): TNtxStatus;

// Query logon rights of an account using its SID
function LsaxQueryRightsAccountBySid(
  const AccountSid: ISid;
  out SystemAccess: TSystemAccess
): TNtxStatus;

// Set logon rights of an account
function LsaxSetRightsAccount(
  [Access(ACCOUNT_ADJUST_SYSTEM_ACCESS)] hAccount: TLsaHandle;
  SystemAccess: TSystemAccess
): TNtxStatus;

// Set logon rights of an account using its SID
function LsaxSetRightsAccountBySid(
  const AccountSid: ISid;
  SystemAccess: TSystemAccess
): TNtxStatus;

// Retrieve the list accounts that have a logon right or a privileges
[RequiresAdmin]
function LsaxEnumerateAccountsWithRightOrPrivilege(
  out Accounts: TArray<ISid>;
  const RightOrPrivilegeName: String;
  [opt, Access(POLICY_ENUMERATE_ACCOUNTS_WITH_RIGHT)] hxPolicy: ILsaHandle = nil
): TNtxStatus;

{ -------------------------------- Privileges ------------------------------- }

// Enumerate all privileges on the system
function LsaxEnumeratePrivileges(
  out Privileges: TArray<TPrivilegeDefinition>;
  [opt, Access(POLICY_VIEW_LOCAL_INFORMATION)] hxPolicy: ILsaHandle = nil
): TNtxStatus;

// Convert a numerical privilege value to internal name
function LsaxQueryPrivilege(
  const Luid: TLuid;
  out Name: String;
  out DisplayName: String;
  [opt, Access(POLICY_LOOKUP_NAMES)] hxPolicy: ILsaHandle = nil
): TNtxStatus;

// Get the minimal integrity level required to use a specific privilege
function LsaxQueryIntegrityPrivilege(
  const Luid: TLuid
): TIntegrityRid;

{ ------------------------------- Logon Process ----------------------------- }

// Establish a connection to LSA without verification
function LsaxConnectUntrusted(
  out hxLsaConnection: ILsaHandle
): TNtxStatus;

// Establish a connection to LSA with verification
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpAlways)]
function LsaxRegisterLogonProcess(
  out hxLsaConnection: ILsaHandle;
  const Name: AnsiString
): TNtxStatus;

// Find an authentication package by name
function LsaxLookupAuthPackage(
  out PackageId: Cardinal;
  const PackageName: AnsiString;
  [opt] hxLsaConnection: ILsaHandle = nil
): TNtxStatus;

{ --------------------------------- Security -------------------------------- }

// Query security descriptor of a LSA object
function LsaxQuerySecurityObject(
  [Access(OBJECT_READ_SECURITY)] LsaHandle: TLsaHandle;
  Info: TSecurityInformation;
  out SD: ISecurityDescriptor
): TNtxStatus;

// Set security descriptor on a LSA object
function LsaxSetSecurityObject(
  [Access(OBJECT_WRITE_SECURITY)] LsaHandle: TLsaHandle;
  Info: TSecurityInformation;
  [in] SD: PSecurityDescriptor
): TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntstatus, Ntapi.NtSecApi, Ntapi.ntrtl, NtUtils.Tokens.Misc,
  NtUtils.Security.Sid, DelphiUtils.AutoObjects;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

type
  TLsaAutoHandle = class(TCustomAutoHandle, ILsaHandle)
    procedure Release; override;
  end;

  TLsaAutoPointer = class(TCustomAutoPointer, IAutoPointer)
    procedure Release; override;
  end;

  TLsaAutoMemory = class(TCustomAutoMemory, IMemory)
    procedure Release; override;
  end;

{ Common & Policy }

procedure TLsaAutoHandle.Release;
begin
  if FHandle <> 0 then
    LsaClose(FHandle);

  FHandle := 0;
  inherited;
end;

procedure TLsaAutoPointer.Release;
begin
  if Assigned(FData) then
    LsaFreeMemory(FData);

  FData := nil;
  inherited;
end;

procedure TLsaAutoMemory.Release;
begin
  if Assigned(FData) then
    LsaFreeMemory(FData);

  FData := nil;
  inherited;
end;

function LsaxDelayFreeMemory(
  [in] Buffer: Pointer
):  IAutoReleasable;
begin
  Result := Auto.Delay(
    procedure
    begin
      LsaFreeMemory(Buffer);
    end
  );
end;

function LsaxOpenPolicy;
var
  ObjAttr: TObjectAttributes;
  hPolicy: TLsaHandle;
begin
  InitializeObjectAttributes(ObjAttr);

  Result.Location := 'LsaOpenPolicy';
  Result.LastCall.OpensForAccess(DesiredAccess);
  Result.Status := LsaOpenPolicy(TLsaUnicodeString.From(SystemName).RefOrNil,
    ObjAttr, DesiredAccess, hPolicy);

  if Result.IsSuccess then
    hxPolicy := TLsaAutoHandle.Capture(hPolicy);
end;

function LsaxpEnsureConnected;
begin
  if not Assigned(hxPolicy) then
    Result := LsaxOpenPolicy(hxPolicy, DesiredAccess)
  else
    Result.Status := STATUS_SUCCESS
end;

function LsaxQueryPolicy;
var
  Buffer: Pointer;
begin
  Result.Location := 'LsaQueryInformationPolicy';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.LastCall.Expects(ExpectedPolicyQueryAccess(InfoClass));
  Result.Status := LsaQueryInformationPolicy(hPolicy, InfoClass, Buffer);

  if Result.IsSuccess then
    xBuffer := TLsaAutoPointer.Capture(Buffer);
end;

function LsaxSetPolicy;
begin
  Result.Location := 'LsaSetInformationPolicy';
  Result.LastCall.UsesInfoClass(InfoClass, icSet);
  Result.LastCall.Expects(ExpectedPolicySetAccess(InfoClass));
  Result.Status := LsaSetInformationPolicy(hPolicy, InfoClass, Buffer);
end;

{ Accounts }

function LsaxOpenAccount;
var
  hAccount: TLsaHandle;
begin
  Result := LsaxpEnsureConnected(hxPolicy, POLICY_VIEW_LOCAL_INFORMATION);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'LsaOpenAccount';
  Result.LastCall.OpensForAccess(DesiredAccess);
  Result.LastCall.Expects<TLsaPolicyAccessMask>(POLICY_VIEW_LOCAL_INFORMATION);

  Result.Status := LsaOpenAccount(hxPolicy.Handle, AccountSid.Data,
    DesiredAccess, hAccount);

  if Result.IsSuccess then
    hxAccount := TLsaAutoHandle.Capture(hAccount);
end;

function LsaxCreateAccount;
var
  hAccount: TLsaHandle;
begin
  Result := LsaxpEnsureConnected(hxPolicy, POLICY_CREATE_ACCOUNT);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'LsaCreateAccount';
  Result.LastCall.OpensForAccess(DesiredAccess);
  Result.LastCall.Expects<TLsaPolicyAccessMask>(POLICY_CREATE_ACCOUNT);

  Result.Status := LsaCreateAccount(hxPolicy.Handle, AccountSid.Data,
    DesiredAccess, hAccount);

  if Result.IsSuccess then
    hxAccount := TLsaAutoHandle.Capture(hAccount);
end;

function LsaxDeleteAccount;
begin
  Result.Location := 'LsaDelete';
  Result.LastCall.Expects<TLsaAccountAccessMask>(_DELETE);
  Result.Status := LsaDelete(hAccount);
end;

function LsaxEnumerateAccounts;
var
  EnumContext: TLsaEnumerationHandle;
  Buffer: PSidArray;
  Count, i: Integer;
begin
  Result := LsaxpEnsureConnected(hxPolicy, POLICY_VIEW_LOCAL_INFORMATION);

  if not Result.IsSuccess then
    Exit;

  EnumContext := 0;
  Result.Location := 'LsaEnumerateAccounts';
  Result.LastCall.Expects<TLsaPolicyAccessMask>(POLICY_VIEW_LOCAL_INFORMATION);

  Result.Status := LsaEnumerateAccounts(hxPolicy.Handle, EnumContext, Buffer,
    MAX_PREFERRED_LENGTH, Count);

  if not Result.IsSuccess then
    Exit;

  LsaxDelayFreeMemory(Buffer);
  SetLength(Accounts, Count);

  for i := 0 to High(Accounts) do
  begin
    Result := RtlxCopySid(Buffer{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF}, Accounts[i]);

    if not Result.IsSuccess then
      Break;
  end;
end;

function LsaxEnumeratePrivilegesAccount;
var
  PrivilegeSet: PPrivilegeSet;
  i: Integer;
begin
  Result.Location := 'LsaEnumeratePrivilegesOfAccount';
  Result.LastCall.Expects<TLsaAccountAccessMask>(ACCOUNT_VIEW);

  Result.Status := LsaEnumeratePrivilegesOfAccount(hAccount, PrivilegeSet);

  if not Result.IsSuccess then
    Exit;

  LsaxDelayFreeMemory(PrivilegeSet);
  SetLength(Privileges, PrivilegeSet.PrivilegeCount);

  for i := 0 to High(Privileges) do
    Privileges[i] := PrivilegeSet.Privilege{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF};
end;

function LsaxEnumeratePrivilegesAccountBySid;
var
  hxAccount: ILsaHandle;
begin
  Result := LsaxOpenAccount(hxAccount, AccountSid, ACCOUNT_VIEW);

  if Result.IsSuccess then
    Result := LsaxEnumeratePrivilegesAccount(hxAccount.Handle, Privileges);
end;

function LsaxAddPrivilegesAccount;
begin
  Result.Location := 'LsaAddPrivilegesToAccount';
  Result.LastCall.Expects<TLsaAccountAccessMask>(ACCOUNT_ADJUST_PRIVILEGES);

  Result.Status := LsaAddPrivilegesToAccount(hAccount,
    NtxpAllocPrivilegeSet(Privileges).Data);
end;

function LsaxRemovePrivilegesAccount;
begin
  Result.Location := 'LsaRemovePrivilegesFromAccount';
  Result.LastCall.Expects<TLsaAccountAccessMask>(ACCOUNT_ADJUST_PRIVILEGES);

  Result.Status := LsaRemovePrivilegesFromAccount(hAccount, RemoveAll,
    NtxpAllocPrivilegeSet(Privileges).Data);
end;

function LsaxManagePrivilegesAccount;
var
  hxAccount: ILsaHandle;
begin
  if (Length(Add) = 0) and (Length(Remove) = 0) and not RemoveAll then
  begin
    Result.Status := STATUS_SUCCESS;
    Exit;
  end;

  // Try to open the account
  Result := LsaxOpenAccount(hxAccount, AccountSid, ACCOUNT_ADJUST_PRIVILEGES);

  // If there is no such account
  if Result.Matches(STATUS_OBJECT_NAME_NOT_FOUND, 'LsaOpenAccount') then
  begin
    if Length(Add) = 0 then
    begin
      // No account - no privileges - nothing to remove
      Result.Status := STATUS_SUCCESS;
      Exit;
    end;

    // We need to add the account to LSA database in order to assign privileges
    Result := LsaxCreateAccount(hxAccount, AccountSid, nil,
      ACCOUNT_ADJUST_PRIVILEGES);
  end;

  // Add privileges
  if Result.IsSuccess and (Length(Add) > 0) then
    Result := LsaxAddPrivilegesAccount(hxAccount.Handle, Add);

  // Remove privileges
  if Result.IsSuccess and (RemoveAll or (Length(Remove) > 0)) then
    Result := LsaxRemovePrivilegesAccount(hxAccount.Handle, RemoveAll, Remove);
end;

function LsaxQueryRightsAccount;
begin
  Result.Location := 'LsaGetSystemAccessAccount';
  Result.LastCall.Expects<TLsaAccountAccessMask>(ACCOUNT_VIEW);

  Result.Status := LsaGetSystemAccessAccount(hAccount, SystemAccess);
end;

function LsaxQueryRightsAccountBySid;
var
  hxAccount: ILsaHandle;
begin
  Result := LsaxOpenAccount(hxAccount, AccountSid, ACCOUNT_VIEW);

  if Result.IsSuccess then
    Result := LsaxQueryRightsAccount(hxAccount.Handle, SystemAccess);
end;

function LsaxSetRightsAccount;
begin
  Result.Location := 'LsaSetSystemAccessAccount';
  Result.LastCall.Expects<TLsaAccountAccessMask>(ACCOUNT_ADJUST_SYSTEM_ACCESS);

  Result.Status := LsaSetSystemAccessAccount(hAccount, SystemAccess);
end;

function LsaxSetRightsAccountBySid;
var
  hxAccount: ILsaHandle;
begin
  Result := LsaxOpenAccount(hxAccount, AccountSid,
    ACCOUNT_ADJUST_SYSTEM_ACCESS);

  // Add the account to the LSA database if necessary
  if Result.Matches(STATUS_OBJECT_NAME_NOT_FOUND, 'LsaOpenAccount') then
  begin
    if SystemAccess = 0 then
    begin
      // Nothing to revoke
      Result.Status := STATUS_SUCCESS;
      Exit;
    end;

    Result := LsaxCreateAccount(hxAccount, AccountSid, nil,
      ACCOUNT_ADJUST_SYSTEM_ACCESS);

    if Result.IsSuccess then
      Result := LsaxSetRightsAccount(hxAccount.Handle, SystemAccess);
  end;
end;

function LsaxEnumerateAccountsWithRightOrPrivilege;
var
  Buffer: PLsaEnumerationInformation;
  Count: Cardinal;
  i: Integer;
begin
  Result := LsaxpEnsureConnected(hxPolicy, POLICY_ENUMERATE_ACCOUNTS_WITH_RIGHT);

  if not Result.IsSuccess then
    Exit;

  // Retrieve the list of accounts
  Result.Location := 'LsaEnumerateAccountsWithUserRight';
  Result.LastCall.Expects<TLsaPolicyAccessMask>(
    POLICY_ENUMERATE_ACCOUNTS_WITH_RIGHT);

  Result.Status := LsaEnumerateAccountsWithUserRight(hxPolicy.Handle,
    TLsaUnicodeString.From(RightOrPrivilegeName), Buffer, Count);

  if Result.Status = STATUS_NO_MORE_ENTRIES then
  begin
    // No accounts
    Accounts := nil;
    Result.Status := STATUS_SUCCESS;
    Exit;
  end;

  if not Result.IsSuccess then
    Exit;

  LsaxDelayFreeMemory(Buffer);

  // Save account SIDs
  SetLength(Accounts, Count);

  for i := 0 to High(Accounts) do
  begin
    Result := RtlxCopySid(Buffer{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF}, Accounts[i]);

    if not Result.IsSuccess then
      Exit;
  end;
end;

{ Privileges }

function LsaxEnumeratePrivileges;
var
  EnumContext: TLsaEnumerationHandle;
  Count, i: Integer;
  Buffer: PPolicyPrivilegeDefinitionArray;
begin
  Result := LsaxpEnsureConnected(hxPolicy, POLICY_VIEW_LOCAL_INFORMATION);

  if not Result.IsSuccess then
    Exit;

  EnumContext := 0;
  Result.Location := 'LsaEnumeratePrivileges';
  Result.LastCall.Expects<TLsaPolicyAccessMask>(POLICY_VIEW_LOCAL_INFORMATION);

  Result.Status := LsaEnumeratePrivileges(hxPolicy.Handle, EnumContext, Buffer,
    MAX_PREFERRED_LENGTH, Count);

  if not Result.IsSuccess then
    Exit;

  LsaxDelayFreeMemory(Buffer);
  SetLength(Privileges, Count);

  for i := 0 to High(Privileges) do
  begin
    Privileges[i].Name := Buffer{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF}.Name.ToString;
    Privileges[i].LocalValue := Buffer{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF}.LocalValue;
  end;
end;

function LsaxQueryPrivilege;
var
  NameBuffer, DisplayNameBuffer: PLsaUnicodeString;
  LangId: SmallInt;
begin
  Result := LsaxpEnsureConnected(hxPolicy, POLICY_LOOKUP_NAMES);

  if not Result.IsSuccess then
    Exit;

  // Get name based on LUID
  Result.Location := 'LsaLookupPrivilegeName';
  Result.LastCall.Expects<TLsaPolicyAccessMask>(POLICY_LOOKUP_NAMES);
  Result.Status := LsaLookupPrivilegeName(hxPolicy.Handle, Luid, NameBuffer);

  if not Result.IsSuccess then
    Exit;

  LsaxDelayFreeMemory(NameBuffer);
  Name := NameBuffer.ToString;

  // Get description based on name
  Result.Location := 'LsaLookupPrivilegeDisplayName';
  Result.LastCall.Expects<TLsaPolicyAccessMask>(POLICY_LOOKUP_NAMES);

  Result.Status := LsaLookupPrivilegeDisplayName(hxPolicy.Handle,
    TLsaUnicodeString.From(Name), DisplayNameBuffer, LangId);

  if not Result.IsSuccess then
    Exit;

  LsaxDelayFreeMemory(DisplayNameBuffer);
  DisplayName := DisplayNameBuffer.ToString;
end;

function LsaxQueryIntegrityPrivilege;
begin
  // Some privileges require a specific integrity level to be enabled.
  // The ones that require more than Medium also trigger UAC to split logon
  // sessions. The following data is gathered by experimenting and should be
  // maintained in sync with Windows behavior when new privileges are
  // introduced.

  case TSeWellKnownPrivilege(Luid) of
    // Ten of them require High
    SE_CREATE_TOKEN_PRIVILEGE,
    SE_TCB_PRIVILEGE,
    SE_TAKE_OWNERSHIP_PRIVILEGE,
    SE_LOAD_DRIVER_PRIVILEGE,
    SE_BACKUP_PRIVILEGE,
    SE_RESTORE_PRIVILEGE,
    SE_DEBUG_PRIVILEGE,
    SE_IMPERSONATE_PRIVILEGE,
    SE_RELABEL_PRIVILEGE,
    SE_DELEGATE_SESSION_USER_IMPERSONATE_PRIVILEGE:
      Result := SECURITY_MANDATORY_HIGH_RID;

    // Three of them does not require anything
    SE_CHANGE_NOTIFY_PRIVILEGE,
    SE_UNDOCK_PRIVILEGE,
    SE_INCREASE_WORKING_SET_PRIVILEGE:
      Result := SECURITY_MANDATORY_UNTRUSTED_RID;

  else
    // All other require Medium
    Result := SECURITY_MANDATORY_MEDIUM_RID;
  end;
end;

{ Logon process }

type
  TLsaAutoConnection = class(TCustomAutoHandle, ILsaHandle)
    procedure Release; override;
  end;

procedure TLsaAutoConnection.Release;
begin
  if FHandle <> 0 then
    LsaDeregisterLogonProcess(FHandle);

  FHandle := 0;
  inherited;
end;

function LsaxConnectUntrusted;
var
  hLsaConnection: TLsaHandle;
begin
  Result.Location := 'LsaConnectUntrusted';
  Result.Status := LsaConnectUntrusted(hLsaConnection);

  if Result.IsSuccess then
    hxLsaConnection := TLsaAutoConnection.Capture(hLsaConnection);
end;

function LsaxRegisterLogonProcess;
var
  hLsaConnection: TLsaHandle;
  Reserved: Cardinal;
begin
  Result.Location := 'LsaRegisterLogonProcess';
  Result.LastCall.ExpectedPrivilege := SE_TCB_PRIVILEGE;

  Result.Status := LsaRegisterLogonProcess(TLsaAnsiString.From(Name),
    hLsaConnection, Reserved);

  if Result.IsSuccess then
    hxLsaConnection := TLsaAutoConnection.Capture(hLsaConnection);
end;

function LsaxLookupAuthPackage;
begin
  if not Assigned(hxLsaConnection) then
  begin
    Result := LsaxConnectUntrusted(hxLsaConnection);

    if not Result.IsSuccess then
      Exit;
  end;

  Result.Location := 'LsaLookupAuthenticationPackage("' + String(PackageName) +
    '")';
  Result.Status := LsaLookupAuthenticationPackage(hxLsaConnection.Handle,
    TLsaAnsiString.From(PackageName), PackageId);
end;

function LsaxQuerySecurityObject;
var
  Buffer: PSecurityDescriptor;
begin
  Result.Location := 'LsaQuerySecurityObject';
  Result.LastCall.Expects(SecurityReadAccess(Info));
  Result.Status := LsaQuerySecurityObject(LsaHandle, Info, Buffer);

  if Result.IsSuccess then
    IMemory(SD) := TLsaAutoMemory.Capture(Buffer,
      RtlLengthSecurityDescriptor(Buffer));
end;

function LsaxSetSecurityObject;
begin
  Result.Location := 'LsaSetSecurityObject';
  Result.LastCall.Expects(SecurityWriteAccess(Info));
  Result.Status := LsaSetSecurityObject(LsaHandle, Info, SD);
end;

end.
