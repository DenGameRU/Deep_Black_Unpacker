unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Memo1: TMemo;
    Label8: TLabel;
    OpenDialog1: TOpenDialog;
    procedure Button1Click(Sender: TObject);

  private
    { Private declarations }
  public

    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}



procedure TForm1.Button1Click(Sender: TObject);
var
  RFile, WFile  : File;
  Long          : LongInt;
  DataBuff, FileName, ExtName : String;
  SizeDataBuff  : Integer;
  NUMBERS       : Integer;
  NumbOfExt, i, j, NumbOfFiles, NumbOfExtFiles : Integer;
  FileSize, FileOffset : Integer;
  
  // Переменные для автоматического распределения расширений
  ExtList       : array of String;
  ExtCounts     : array of Integer;
  CurrentExtIdx : Integer;
  FilesProcessedForCurrentExt : Integer;

  // Переменные для распаковки
  FileBuffer    : array of Byte;
  SavePath      : String;
  CleanName     : String;
  FullFileName  : String;
  CurrentPos    : Int64;
begin
  OpenDialog1.Filter := 'Pack Files (*.pack)|*.pack|All Files (*.*)|*.*';
  if not OpenDialog1.Execute then Exit;

  AssignFile(RFile, OpenDialog1.FileName);
  FileMode := fmOpenRead;
  Reset(RFile, 1);

  // 1. Читаем основной заголовок
  SizeDataBuff := 8;
  SetLength(DataBuff, SizeDataBuff);
  BlockRead(RFile, PChar(DataBuff)^, SizeDataBuff);
  Label1.Caption := 'ID = ' + DataBuff;

  BlockRead(RFile, NumbOfExt, 4);
  Label2.Caption := 'Number of File Types = ' + IntToStr(NumbOfExt);

  BlockRead(RFile, NUMBERS, 4);
  Label3.Caption := 'UNK = ' + IntToStr(NUMBERS);

  BlockRead(RFile, NumbOfFiles, 4);
  Label4.Caption := 'Total Number of Files = ' + IntToStr(NumbOfFiles);

  BlockRead(RFile, NUMBERS, 4);
  Label5.Caption := 'UNK3 = ' + IntToStr(NUMBERS);

  Memo1.Lines.Clear;
  Memo1.Lines.Add('--- ТИПЫ ФАЙЛОВ ---');

  // Выделяем память под массивы типов файлов
  SetLength(ExtList, NumbOfExt);
  SetLength(ExtCounts, NumbOfExt);

  // 2. Читаем таблицу расширений и запоминаем, сколько файлов принадлежит каждому типу
  for i := 0 to NumbOfExt - 1 do
  begin
    SizeDataBuff := 4;
    SetLength(ExtName, SizeDataBuff);
    BlockRead(RFile, PChar(ExtName)^, SizeDataBuff);
    BlockRead(RFile, Long, 4); 
    BlockRead(RFile, NumbOfExtFiles, 4);
    
    // Сохраняем расширение и количество (убирая лишние нулевые байты)
    ExtList[i] := Trim(String(PChar(ExtName)));
    ExtCounts[i] := NumbOfExtFiles;

    Memo1.Lines.Add('*.' + ExtList[i] + ' (Количество: ' + IntToStr(NumbOfExtFiles) + ')');
  end;

  Memo1.Lines.Add('');
  Memo1.Lines.Add('--- РАСПАКОВКА ФАЙЛОВ ---');

  SavePath := ExtractFilePath(ParamStr(0)) + 'Extracted\';
  ForceDirectories(SavePath);

  CurrentExtIdx := 0;
  FilesProcessedForCurrentExt := 0;

  // 3. Цикл чтения и распаковки всех файлов
  for i := 0 to NumbOfFiles - 1 do
  begin
    // Читаем имя (32 байта)
    SizeDataBuff := 32;
    SetLength(FileName, SizeDataBuff);
    BlockRead(RFile, PChar(FileName)^, SizeDataBuff);

    CleanName := Trim(String(PChar(FileName)));

    // Читаем смещение и размер
    BlockRead(RFile, FileOffset, 4);
    BlockRead(RFile, FileSize, 4);

    // Автоматически определяем расширение для текущего файла
    if (CurrentExtIdx < NumbOfExt) then
    begin
      FullFileName := CleanName + '.' + ExtList[CurrentExtIdx];
      Inc(FilesProcessedForCurrentExt);
      
      // Если обработали все файлы текущего типа — переходим к следующему типу расширения
      if (FilesProcessedForCurrentExt >= ExtCounts[CurrentExtIdx]) then
      begin
        Inc(CurrentExtIdx);
        FilesProcessedForCurrentExt := 0;
      end;
    end else
    begin
      FullFileName := CleanName; // На всякий случай, если структура выйдет за пределы
    end;

    Memo1.Lines.Add(FullFileName + ' [Смещение: ' + IntToStr(FileOffset) + ', Размер: ' + IntToStr(FileSize) + ' байт]');

    // Экстракт данных на диск
    if FileSize > 0 then
    begin
      CurrentPos := FilePos(RFile); // Запоминаем позицию в таблице

      Seek(RFile, FileOffset); // Переходим к данным
      SetLength(FileBuffer, FileSize); // Выделяем память
      
      // ВАЖНОЕ ИСПРАВЛЕНИЕ: Передаем FileBuffer[0] вместо FileBuffer
      BlockRead(RFile, FileBuffer[0], FileSize); 

      // Записываем файл с правильным расширением
      AssignFile(WFile, SavePath + FullFileName);
      Rewrite(WFile, 1);
      
      // ВАЖНОЕ ИСПРАВЛЕНИЕ: Для записи также используем FileBuffer[0]
      BlockWrite(WFile, FileBuffer[0], FileSize); 
      CloseFile(WFile);

      Seek(RFile, CurrentPos); // Возвращаемся в таблицу
    end;

  end;

  CloseFile(RFile);
  Memo1.Lines.Add('');
  Memo1.Lines.Add('Успешно распаковано в: ' + SavePath);
end;


end.
