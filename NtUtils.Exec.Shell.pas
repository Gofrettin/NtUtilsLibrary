unit NtUtils.Exec.Shell;

interface

uses
  NtUtils.Exec;

type
  TExecShellExecute = class(TInterfacedObject, IExecMethod)
    function Supports(Parameter: TExecParam): Boolean;
    function Execute(ParamSet: IExecProvider): TProcessInfo;
  end;

implementation

uses
  Winapi.Shell, Winapi.WinUser, NtUtils.Exceptions, NtUtils.Exec.Win32;

{ TExecShellExecute }

function TExecShellExecute.Execute(ParamSet: IExecProvider): TProcessInfo;
var
  ShellExecInfo: TShellExecuteInfoW;
  RunAsInvoker: IInterface;
begin
  FillChar(ShellExecInfo, SizeOf(ShellExecInfo), 0);
  ShellExecInfo.cbSize := SizeOf(ShellExecInfo);
  ShellExecInfo.fMask := SEE_MASK_NOASYNC or SEE_MASK_UNICODE or
    SEE_MASK_NOCLOSEPROCESS or SEE_MASK_FLAG_NO_UI;

  // SEE_MASK_NO_CONSOLE is opposite to CREATE_NEW_CONSOLE
  if ParamSet.Provides(ppNewConsole) and not ParamSet.NewConsole then
    ShellExecInfo.fMask := ShellExecInfo.fMask or SEE_MASK_NO_CONSOLE;

  ShellExecInfo.lpFile := PWideChar(ParamSet.Application);

  if ParamSet.Provides(ppParameters) then
    ShellExecInfo.lpParameters := PWideChar(ParamSet.Parameters);

  if ParamSet.Provides(ppCurrentDirectory) then
    ShellExecInfo.lpDirectory := PWideChar(ParamSet.CurrentDircetory);

  if ParamSet.Provides(ppRequireElevation) and ParamSet.RequireElevation then
    ShellExecInfo.lpVerb := 'runas';

  if ParamSet.Provides(ppShowWindowMode) then
    ShellExecInfo.nShow := ParamSet.ShowWindowMode
  else
    ShellExecInfo.nShow := SW_SHOWNORMAL;

  // Set RunAsInvoker compatibility mode. It will be reverted
  // after exiting from the current function.
  if ParamSet.Provides(ppRunAsInvoker) then
    RunAsInvoker := TRunAsInvoker.SetCompatState(ParamSet.RunAsInvoker);

  WinCheck(ShellExecuteExW(ShellExecInfo), 'ShellExecuteExW');

  // We use SEE_MASK_NOCLOSEPROCESS to get a handle to the process.
  // The caller must close it after use.
  FillChar(Result, SizeOf(Result), 0);
  Result.hProcess := ShellExecInfo.hProcess;
end;

function TExecShellExecute.Supports(Parameter: TExecParam): Boolean;
begin
  case Parameter of
    ppParameters, ppCurrentDirectory, ppNewConsole, ppRequireElevation,
    ppShowWindowMode, ppRunAsInvoker:
      Result := True;
  else
    Result := False;
  end;
end;

end.
