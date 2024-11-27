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

{ ִ���ⲿ���������� }
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

{ ��ȡ�������豸�б� }
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

    // ������һ�б��⣬�����豸�б�
    for i := 1 to Lines.Count - 1 do
    begin
      // �����һ�а��� "device" �ַ�����ʾ��һ����Ч�豸
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

{ ��ȡ�豸��ϸ��Ϣ }
function TForm2.GetDeviceInfo(const DeviceID: string): TStringList;
  function RunCommand(const Cmd: string): string;
  begin
    Result := ExecuteCommand(Format('adb -s %s %s', [DeviceID, Cmd]));
  end;

begin
  Result := TStringList.Create;
  Result.Add('�豸Ʒ��: ' + RunCommand('shell getprop ro.product.brand'));
  Result.Add('CPU �ܹ�: ' + RunCommand('shell getprop ro.product.cpu.abi'));
  Result.Add('�豸�ͺ�: ' + RunCommand('shell getprop ro.product.model'));
  Result.Add('�ֱ���: ' + RunCommand('shell wm size'));
  Result.Add('ϵͳ����: ' + RunCommand('shell getprop ro.build.version.codename'));
  Result.Add('��ʾ�ܶ�: ' + RunCommand('shell wm density'));
  Result.Add('ϵͳ�汾: ' + RunCommand('shell getprop ro.build.version.release'));
  Result.Add('�ѿ���ʱ��: ' + RunCommand('shell uptime'));
  Result.Add('�����Ϣ: ' + RunCommand('shell dumpsys battery'));
  Result.Add('ϵͳ����汾: ' + RunCommand('shell getprop ro.build.version.incremental'));
  Result.Add('�ں˰汾: ' + RunCommand('shell uname -r'));
end;

{ ˢ���豸�б� }

procedure TForm2.btnRefreshClick(Sender: TObject);
var
  Devices: TArray<string>;
  i: Integer;
begin
  cmbDevices.Clear;  // ����豸�б�

  // ��ȡ���ӵ��豸
  Devices := GetConnectedDevices;

  // ���û���豸����ʾ�û�
  if Length(Devices) = 0 then
  begin
    ShowMessage('û���豸���ӣ�');
  end
  else
  begin
    // ���豸��ӵ� ComboBox
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
    // ��ȡѡ�е��豸����ϸ��Ϣ
    DeviceInfo := GetDeviceInfo(cmbDevices.Items[cmbDevices.ItemIndex]);
    try
      memoDeviceInfo.Lines := DeviceInfo;  // ��ʾ�豸��Ϣ
    finally
      DeviceInfo.Free;
    end;
  end;
end;

{ ѡ���豸����ʾ��ϸ��Ϣ }
procedure TForm2.lbDevicesClick(Sender: TObject);
var
  DeviceInfo: TStringList;
begin
  // ��� ComboBox �Ƿ���ѡ����
  if cmbDevices.ItemIndex >= 0 then
  begin
    // ��ȡѡ�е��豸�� ID
    DeviceInfo := GetDeviceInfo(cmbDevices.Items[cmbDevices.ItemIndex]);

    // ��ʾ�豸��Ϣ
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
  // ����Ƿ������ӵ��豸
  Command := 'adb devices';
  Output := ExecuteCommand(Command);  // ִ�� ADB devices ����

  // ���û���豸���ӣ���ʾ�û����˳�
  if Pos('device', Output) = 0 then
  begin
    ShowMessage('û�����ӵ��豸����ȷ���豸�����Ӳ������˵���ģʽ��');
    Exit;  // �˳�����������ִ�к�������
  end;

  // ��ȡ��ǰ���ں�ʱ�䣬����ʽ��Ϊ�ļ�������ȷ���룩
  DateTimeString := FormatDateTime('yyyy-mm-dd_hh-nn-ss', Now);

  // �����豸��ͼ����·��
  ScreenshotFilePath := '/sdcard/Pictures/screenshot_' + DateTimeString + '.png';

  // ִ�н���������浽�豸�� Pictures Ŀ¼
  Command := 'adb shell screencap -p ' + ScreenshotFilePath;
  Output := ExecuteCommand(Command);  // ִ�� ADB ��������

  // �������ִ��ʧ�ܣ����������Ϣ
  if Pos('error', Output) > 0 then
  begin
    ShowMessage('��������ʧ�ܣ��������豸û�����ӻ�������������');
    Exit;
  end;

  // ��ʾ�û���ͼ�ѱ���
  ShowMessage('��ͼ�ѱ��浽�豸���: ' + ScreenshotFilePath);
end;




end.
