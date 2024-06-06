(*
 * IPWorks SFTP 2024 Delphi Edition - Sample Project
 *
 * This sample project demonstrates the usage of IPWorks SFTP in a 
 * simple, straightforward way. It is not intended to be a complete 
 * application. Error handling and other checks are simplified for clarity.
 *
 * www.nsoftware.com/ipworkssftp
 *
 * This code is subject to the terms and conditions specified in the 
 * corresponding product license agreement which outlines the authorized 
 * usage and restrictions.
 *)
unit SFTPServerf;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls, ipfcore, ipftypes,
  ipfsftpserver, ipfcertmgr, GenCertDlg;

type
  TFormsftpserver = class(TForm)
    btnStart: TButton;
    btnStop: TButton;
    StatusOutput: TPageControl;
    StatusDisplay: TTabSheet;
    ConnectionDisplay: TTabSheet;
    UserDisplay: TTabSheet;
    KeyDisplay: TTabSheet;
    txtEventLog: TMemo;
    txtPort: TEdit;
    txtRootDir: TEdit;
    portLabel: TLabel;
    rootDirLabel: TLabel;
    rootDirSelectButton: TButton;
    txtUserList: TListView;
    eventLogLabel: TLabel;
    usrAccountsLabel: TLabel;
    deleteUserButton: TButton;
    txtCreateUserName: TEdit;
    createUserNameLabel: TLabel;
    createPasswordLabel: TLabel;
    txtCreatePassword: TEdit;
    createUserButton: TButton;
    txtCertStoreType: TComboBox;
    txtCertStorePath: TEdit;
    txtCertStorePassword: TEdit;
    txtCertSubject: TEdit;
    ipfSFTPServer1: TipfSFTPServer;
    btnSelectCert: TButton;
    btnGenerateCert: TButton;
    procedure btnStartClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure createUserButtonClick(Sender: TObject);
    procedure deleteUserButtonClick(Sender: TObject);
    procedure ipfSFTPServer1ConnectionRequest(Sender: TObject;
      const Address: string; Port: Integer; var Accept: Boolean);
    procedure ipfSFTPServer1Connected(Sender: TObject; ConnectionId,
  StatusCode: Integer; const Description: string; var CertStoreType: Integer;
  var CertStore, CertPassword, CertSubject: string);
    procedure ipfSFTPServer1SSHUserAuthRequest(Sender: TObject;
      ConnectionId: Integer; const User, Service, AuthMethod, AuthParam: string;
      var Accept, PartialSuccess: Boolean; var AvailableMethods,
      HomeDir: string; const KeyAlgorithm: string);
    procedure ipfSFTPServer1Disconnected(Sender: TObject; ConnectionId,
      StatusCode: Integer; const Description: string);
    procedure ipfSFTPServer1Error(Sender: TObject; ConnectionId,
      ErrorCode: Integer; const Description: string);
    procedure rootDirSelectButtonClick(Sender: TObject);
    procedure btnSelectCertClick(Sender: TObject);
    function GetCertStoreType(selectedIndex: Integer) : TipfsftpserverSSHCertStoreTypes;
    procedure txtCertStoreTypeSelect(Sender: TObject);
    procedure ipfSFTPServer1SSHStatus(Sender: TObject; ConnectionId: Integer;
      const Message: string);
    procedure btnGenerateCertClick(Sender: TObject);
    procedure ipfSFTPServer1FileClose(Sender: TObject; ConnectionId: Integer;
      const User, Path, Handle: string; var StatusCode: Integer);
    procedure txtEventLogChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ipfSFTPServer1DirCreate(Sender: TObject; ConnectionId: Integer;
      const User, Path: string; FileType: Integer; FileSize: Int64;
      const FileOwner, FileGroup: string; FilePermissions: Integer; FileATime,
      FileCreateTime, FileMTime: Int64; FileAttribBits,
      FileAttribBitsValid: Integer; const OtherAttributes: string;
      BeforeExec: Boolean; var StatusCode: Integer);
    procedure ipfSFTPServer1DirRemove(Sender: TObject; ConnectionId: Integer;
      const User, Path: string; BeforeExec: Boolean; var StatusCode: Integer);
    procedure ipfSFTPServer1FileOpen(Sender: TObject; ConnectionId: Integer;
      const User, Path: string; DesiredAccess, Flags, FileType: Integer;
      FileSize: Int64; const FileOwner, FileGroup: string;
      FilePermissions: Integer; FileATime, FileCreateTime, FileMTime: Int64;
      FileAttribBits, FileAttribBitsValid: Integer;
      const OtherAttributes: string; var Handle: string; BeforeExec: Boolean;
      var StatusCode: Integer);
    procedure ipfSFTPServer1FileRemove(Sender: TObject; ConnectionId: Integer;
      const User, Path: string; BeforeExec: Boolean; var StatusCode: Integer);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Formsftpserver: TFormsftpserver;

implementation

{$R *.dfm}

procedure TFormsftpserver.btnGenerateCertClick(Sender: TObject);
begin
  with TFormgencertdl.Create(self) do
  begin
    if showModal = mrOk then
    begin
      txtCertStoreType.ItemIndex := 2;
      txtCertStorePath.Text := fileName;
      txtCertSubject.Text := 'CN=' + txtNewCertSubject.Text;
      txtCertStorePassword.Text := txtNewCertPass.Text;
    end;
    Free;
  end;
end;

procedure TFormsftpserver.btnSelectCertClick(Sender: TObject);
var
  openDialog: TOpenDialog;
begin
  openDialog := TOpenDialog.Create(self);
  openDialog.InitialDir := GetCurrentDir();
  openDialog.Options := [ofFileMustExist];
  if openDialog.Execute then
  begin
    txtCertStorePath.Text := openDialog.FileName;
  end
  else
  begin
    showMessage('No certificate selected.');
  end;
  openDialog.Free;
end;

procedure TFormsftpserver.btnStartClick(Sender: TObject);
begin
  ipfSFTPServer1.SSHCertStoreType := GetCertStoreType(txtCertStoreType.ItemIndex);
  ipfSFTPServer1.SSHCertStore := txtCertStorePath.Text;
  ipfSFTPServer1.SSHCertStorePassword := txtCertStorePassword.Text;
  ipfSFTPServer1.SSHCertSubject := txtCertSubject.Text;

  ipfSFTPServer1.LocalPort := strtoint(txtPort.Text);
  ipfSFTPServer1.RootDirectory := txtRootDir.Text;

  try
    ipfSFTPServer1.StartListening();
    txtEventLog.Lines.Add('Server is now listening on port ' + inttostr(ipfSFTPServer1.LocalPort));
    btnStop.Enabled := true;
    btnStart.Enabled := false;
  except on E: Exception do
    showMessage(E.Message);
  end;
end;

procedure TFormsftpserver.btnStopClick(Sender: TObject);
begin
  ipfSFTPServer1.Shutdown();
  txtEventLog.Lines.Add('Server is no longer listening');
  btnStop.Enabled := false;
  btnStart.Enabled := true;
end;

procedure TFormsftpserver.createUserButtonClick(Sender: TObject);
var
  itm: TListItem;
begin
  if not (txtCreateUserName.Text = '') and not (txtCreatePassword.Text = '') then
  begin
    itm := txtUserList.Items.Add();
    itm.Caption := txtCreateUserName.Text;
    itm.SubItems.Add(txtCreatePassword.Text);
  end
  else
  begin
    showMessage('Username and password required.');
  end;
end;

procedure TFormsftpserver.deleteUserButtonClick(Sender: TObject);
begin
  if txtUserList.ItemIndex > -1 then
  begin
    txtUserList.DeleteSelected;
  end
  else
  begin
    showMessage('No user selected.');
  end;
end;

procedure TFormsftpserver.FormCreate(Sender: TObject);
begin
  // If you are having trouble displaying the contents of a folder
  // please enable this config. This will force the component
  // to use UTF-8.
//  ipfSFTPServer1.Config('CodePage=65001');

  // If you would like to examine the contents of the SSH
  // packets transferred, please enable this setting.
  // It is very useful for debugging.
//  ipfSFTPServer1.Config('LogSSHPackets=true');
end;

procedure TFormsftpserver.ipfSFTPServer1Connected(Sender: TObject; ConnectionId,
  StatusCode: Integer; const Description: string; var CertStoreType: Integer;
  var CertStore, CertPassword, CertSubject: string);
begin
  txtEventLog.Lines.Add('[' + inttostr(ConnectionId) + '] has connected.');
end;

procedure TFormsftpserver.ipfSFTPServer1ConnectionRequest(Sender: TObject;
  const Address: string; Port: Integer; var Accept: Boolean);
begin
  txtEventLog.Lines.Add(Address + ':' + inttostr(Port) + ' is attempting to connect.');
  Accept := true;
end;

procedure TFormsftpserver.ipfSFTPServer1DirCreate(Sender: TObject;
  ConnectionId: Integer; const User, Path: string; FileType: Integer;
  FileSize: Int64; const FileOwner, FileGroup: string; FilePermissions: Integer;
  FileATime, FileCreateTime, FileMTime: Int64; FileAttribBits,
  FileAttribBitsValid: Integer; const OtherAttributes: string;
  BeforeExec: Boolean; var StatusCode: Integer);
begin
  txtEventLog.Lines.Add(User + ' has created a directory: ' + Path);
end;

procedure TFormsftpserver.ipfSFTPServer1DirRemove(Sender: TObject;
  ConnectionId: Integer; const User, Path: string; BeforeExec: Boolean;
  var StatusCode: Integer);
begin
  txtEventLog.Lines.Add(User + ' has deleted a directory: ' + Path);

end;

procedure TFormsftpserver.ipfSFTPServer1Disconnected(Sender: TObject;
  ConnectionId, StatusCode: Integer; const Description: string);
begin
  txtEventLog.Lines.Add('[' + inttostr(ConnectionId) + '] has disconnected.');
end;

procedure TFormsftpserver.ipfSFTPServer1Error(Sender: TObject; ConnectionId,
  ErrorCode: Integer; const Description: string);
begin
  txtEventLog.Lines.Add('[' + inttostr(ConnectionId) + '] There was an error: ' + Description);
end;

procedure TFormsftpserver.ipfSFTPServer1FileClose(Sender: TObject;
  ConnectionId: Integer; const User, Path, Handle: string;
  var StatusCode: Integer);
begin
  txtEventLog.Lines.Add(User + ' transferred ' + Path);
end;



procedure TFormsftpserver.ipfSFTPServer1FileOpen(Sender: TObject;
  ConnectionId: Integer; const User, Path: string; DesiredAccess, Flags,
  FileType: Integer; FileSize: Int64; const FileOwner, FileGroup: string;
  FilePermissions: Integer; FileATime, FileCreateTime, FileMTime: Int64;
  FileAttribBits, FileAttribBitsValid: Integer; const OtherAttributes: string;
  var Handle: string; BeforeExec: Boolean; var StatusCode: Integer);
var
  operation: string;
begin
  if (Flags = 1) then
  begin
    operation := 'downloading.';
  end
  else if (Flags = 42) then
  begin
    operation := 'uploading';
  end
  else
  begin
    operation := 'transferring';
  end;
  txtEventLog.Lines.Add(User + ' started ' + operation + ' ' + Path);

end;

procedure TFormsftpserver.ipfSFTPServer1FileRemove(Sender: TObject;
  ConnectionId: Integer; const User, Path: string; BeforeExec: Boolean;
  var StatusCode: Integer);
begin
  txtEventLog.Lines.Add(User + ' deleted a file: ' + Path);
end;

procedure TFormsftpserver.ipfSFTPServer1SSHStatus(Sender: TObject;
  ConnectionId: Integer; const Message: string);
begin
  txtEventLog.Lines.Add('[' + inttostr(ConnectionId) + '] ' + Message);
end;

procedure TFormsftpserver.ipfSFTPServer1SSHUserAuthRequest(Sender: TObject;
  ConnectionId: Integer; const User, Service, AuthMethod, AuthParam: string;
  var Accept, PartialSuccess: Boolean; var AvailableMethods, HomeDir: string;
  const KeyAlgorithm: string);
var
  I: Integer;
begin
  txtUserList.Enabled := true;
  for I := 0 to txtUserList.Items.Count-1 do
  begin
    if (User = txtUserList.Items[I].Caption) and (AuthParam = txtUserList.Items[I].SubItems[0]) then
    begin
      Accept := true;
      txtEventLog.Lines.Add('[' + inttostr(ConnectionId) + '] has successfully authenticated.');
      break;
    end;
  end;
end;

procedure TFormsftpserver.rootDirSelectButtonClick(Sender: TObject);
var
  openDialog: TFileOpenDialog;
begin
  openDialog := TFileOpenDialog.Create(self);
  openDialog.Options := [fdoPickFolders];
  if openDialog.Execute then
  begin
    txtRootDir.Text := openDialog.FileName;
  end
  else
  begin
    showMessage('No folder selected.');
  end;
  openDialog.Free;
end;

procedure TFormsftpserver.txtCertStoreTypeSelect(Sender: TObject);
begin
  ipfSFTPServer1.SSHCertStoreType := GetCertStoreType(txtCertStoreType.ItemIndex);
end;

procedure TFormsftpserver.txtEventLogChange(Sender: TObject);
begin
  txtEventLog.SelStart := Length(txtEventLog.Lines.Text);
end;

function TFormsftpserver.GetCertStoreType(selectedIndex: Integer) : TipfsftpserverSSHCertStoreTypes;
begin
  case selectedIndex of
    0 : Result := TipfsftpserverSSHCertStoreTypes.cstUser; // User
    1 : Result := TipfsftpserverSSHCertStoreTypes.cstMachine; // Machine
    2 : Result := TipfsftpserverSSHCertStoreTypes.cstPFXFile; // PFX File
    3 : Result := TipfsftpserverSSHCertStoreTypes.cstPEMKeyFile; // PEM File
  else
  begin
    showMessage('There was an error setting the certificate store type.');
    Result := TipfsftpserverSSHCertStoreTypes.cstPFXFile; // Defaults to PFX
  end;
  end;
end;

end.


