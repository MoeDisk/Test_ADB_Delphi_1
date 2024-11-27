unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons;

type
  TForm2 = class(TForm)
    btnRefresh: TBitBtn;
    memoDeviceInfo: TMemo;
    cmbDevices: TComboBox;
    btnCaptureScreen: TButton;
    procedure btnRefreshClick(Sender: TObject);
    procedure lbDevicesClick(Sender: TObject);
    procedure cmbDevicesChange(Sender: TObject);
    procedure btnCaptureScreenClick(Sender: TObject);
  private
    function ExecuteCommand(const Command: string): string;
    function GetConnectedDevices: TArray<string>;
    function GetDeviceInfo(const DeviceID: string): TStringList;
  public
  end;

var
  Form2: TForm2;

implementation

{$R *.dfm}

{ 执行外部命令并返回输出 }
function TForm2.ExecuteCommand(const Command: string): string;
var
  SecurityAttr: TSecurityAttributes;
  ReadPipe, WritePipe: THandle;
  StartInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
  Buffer: array [0..255] of AnsiChar;
  BytesRead: DWORD;
  CommandStr: string;
  Output: TStringStream;
begin
  Result := '';
  SecurityAttr.nLength := SizeOf(TSecurityAttributes);
  SecurityAttr.bInheritHandle := True;
  SecurityAttr.lpSecurityDescriptor := nil;

  if not CreatePipe(ReadPipe, WritePipe, @SecurityAttr, 0) then
    Exit;

  try
    FillChar(StartInfo, SizeOf(TStartupInfo), 0);
    StartInfo.cb := SizeOf(TStartupInfo);
    StartInfo.hStdOutput := WritePipe;
    StartInfo.hStdError := WritePipe;
    StartInfo.dwFlags := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;
    StartInfo.wShowWindow := SW_HIDE;

    CommandStr := 'cmd.exe /C ' + Command;

    if not CreateProcess(nil, PChar(CommandStr), nil, nil, True, 0, nil, nil, StartInfo, ProcessInfo) then
      Exit;

    CloseHandle(WritePipe);

    Output := TStringStream.Create;
    try
      repeat
        if ReadFile(ReadPipe, Buffer, SizeOf(Buffer) - 1, BytesRead, nil) then
        begin
          Buffer[BytesRead] := #0;
          Output.WriteString(Buffer);
        end;
      until BytesRead = 0;

      Result := Output.DataString;
    finally
      Output.Free;
    end;

    WaitForSingleObject(ProcessInfo.hProcess, INFINITE);
    CloseHandle(ProcessInfo.hProcess);
    CloseHandle(ProcessInfo.hThread);
  finally
    CloseHandle(ReadPipe);
  end;
end;

{ 获取已连接设备列表 }
function TForm2.GetConnectedDevices: TArray<string>;
var
  Output: string;
  Lines: TStringList;
  i: Integer;
begin
  Output := ExecuteCommand('adb devices');
  Lines := TStringList.Create;
  try
    Lines.Text := Output;
    SetLength(Result, 0);

    // 跳过第一行标题，遍历设备列表
    for i := 1 to Lines.Count - 1 do
    begin
      // 如果这一行包含 "device" 字符，表示是一个有效设备
      if Pos('device', Lines[i]) > 0 then
      begin
        SetLength(Result, Length(Result) + 1);
        Result[High(Result)] := Trim(Copy(Lines[i], 1, Pos(#9, Lines[i]) - 1));
      end;
    end;
  finally
    Lines.Free;
  end;
end;

{ 获取设备详细信息 }
function TForm2.GetDeviceInfo(const DeviceID: string): TStringList;
  function RunCommand(const Cmd: string): string;
  begin
    Result := ExecuteCommand(Format('adb -s %s %s', [DeviceID, Cmd]));
  end;

begin
  Result := TStringList.Create;
  Result.Add('设备品牌: ' + RunCommand('shell getprop ro.product.brand'));
  Result.Add('CPU 架构: ' + RunCommand('shell getprop ro.product.cpu.abi'));
  Result.Add('设备型号: ' + RunCommand('shell getprop ro.product.model'));
  Result.Add('分辨率: ' + RunCommand('shell wm size'));
  Result.Add('系统代号: ' + RunCommand('shell getprop ro.build.version.codename'));
  Result.Add('显示密度: ' + RunCommand('shell wm density'));
  Result.Add('系统版本: ' + RunCommand('shell getprop ro.build.version.release'));
  Result.Add('已开机时间: ' + RunCommand('shell uptime'));
  Result.Add('电池信息: ' + RunCommand('shell dumpsys battery'));
  Result.Add('系统编译版本: ' + RunCommand('shell getprop ro.build.version.incremental'));
  Result.Add('内核版本: ' + RunCommand('shell uname -r'));
end;

{ 刷新设备列表 }

procedure TForm2.btnRefreshClick(Sender: TObject);
var
  Devices: TArray<string>;
  i: Integer;
begin
  cmbDevices.Clear;  // 清空设备列表

  // 获取连接的设备
  Devices := GetConnectedDevices;

  // 如果没有设备，提示用户
  if Length(Devices) = 0 then
  begin
    ShowMessage('没有设备连接！');
  end
  else
  begin
    // 将设备添加到 ComboBox
    for i := 0 to High(Devices) do
      cmbDevices.Items.Add(Devices[i]);
  end;
end;

procedure TForm2.cmbDevicesChange(Sender: TObject);
var
  DeviceInfo: TStringList;
begin
  if cmbDevices.ItemIndex >= 0 then
  begin
    // 获取选中的设备的详细信息
    DeviceInfo := GetDeviceInfo(cmbDevices.Items[cmbDevices.ItemIndex]);
    try
      memoDeviceInfo.Lines := DeviceInfo;  // 显示设备信息
    finally
      DeviceInfo.Free;
    end;
  end;
end;

{ 选择设备后显示详细信息 }
procedure TForm2.lbDevicesClick(Sender: TObject);
var
  DeviceInfo: TStringList;
begin
  // 检查 ComboBox 是否有选中项
  if cmbDevices.ItemIndex >= 0 then
  begin
    // 获取选中的设备的 ID
    DeviceInfo := GetDeviceInfo(cmbDevices.Items[cmbDevices.ItemIndex]);

    // 显示设备信息
    try
      memoDeviceInfo.Lines := DeviceInfo;
    finally
      DeviceInfo.Free;
    end;
  end;
end;

procedure TForm2.btnCaptureScreenClick(Sender: TObject);
var
  Command: string;
  Output: string;
  ScreenshotDir: string;
  DateTimeString: string;
  ScreenshotFilePath: string;
begin
  // 检查是否有连接的设备
  Command := 'adb devices';
  Output := ExecuteCommand(Command);  // 执行 ADB devices 命令

  // 如果没有设备连接，提示用户并退出
  if Pos('device', Output) = 0 then
  begin
    ShowMessage('没有连接的设备，请确保设备已连接并启用了调试模式。');
    Exit;  // 退出函数，避免执行后续操作
  end;

  // 获取当前日期和时间，并格式化为文件名（精确到秒）
  DateTimeString := FormatDateTime('yyyy-mm-dd_hh-nn-ss', Now);

  // 设置设备截图保存路径
  ScreenshotFilePath := '/sdcard/Pictures/screenshot_' + DateTimeString + '.png';

  // 执行截屏命令并保存到设备的 Pictures 目录
  Command := 'adb shell screencap -p ' + ScreenshotFilePath;
  Output := ExecuteCommand(Command);  // 执行 ADB 截屏命令

  // 如果命令执行失败，输出错误信息
  if Pos('error', Output) > 0 then
  begin
    ShowMessage('截屏命令失败，可能是设备没有连接或发生了其他错误。');
    Exit;
  end;

  // 提示用户截图已保存
  ShowMessage('截图已保存到设备相册: ' + ScreenshotFilePath);
end;




end.
