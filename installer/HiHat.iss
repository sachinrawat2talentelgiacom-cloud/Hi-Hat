#define AppName "Hi Hat"
#define AppVersion "1.0.0"
#define AppPublisher "Hi Hat"
#define AppExeName "hi_hat.exe"

[Setup]
AppId={{D2A53B82-2468-47E4-A960-BF7E8477A5F0}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
DefaultDirName={localappdata}\Programs\Hi Hat
DefaultGroupName=Hi Hat
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=..\dist
OutputBaseFilename=HiHat-Setup-{#AppVersion}-windows-x64
SetupIconFile=..\client\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#AppExeName}
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern dynamic
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
CloseApplications=yes
RestartApplications=no

[Files]
Source: "..\client\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Hi Hat"; Filename: "{app}\{#AppExeName}"
Name: "{autodesktop}\Hi Hat"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Shortcuts:"; Flags: unchecked

[Run]
Filename: "{app}\{#AppExeName}"; Description: "Launch Hi Hat"; Flags: nowait postinstall skipifsilent
