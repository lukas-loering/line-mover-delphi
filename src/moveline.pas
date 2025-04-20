unit moveline;

interface

uses
  ToolsAPI,
  SysUtils,
  System.Generics.Collections,
  Classes,
  Windows,
  Vcl.Menus;

type
  TLineMover = class(TNotifierObject, IOTAKeyboardBinding)
    public
      function GetBindingType: TBindingType;
      function GetDisplayName: string;
      function GetName: string;
      procedure BindKeyboard(const BindingServices: IOTAKeyBindingServices);
      procedure DoKeyBinding(const Context: IOTAKeyContext; KeyCode: TShortCut; var BindingResult: TKeyBindingResult);
      procedure MoveLineBlockText(EditBuffer: IOTAEditBuffer; Down: Boolean);
      procedure DuplicateLineBlockText(EditBuffer: IOTAEditBuffer; Down: Boolean);
  end;

procedure Register;

implementation

function SkipToNextLine(P: PAnsiChar): PAnsiChar;
begin
  Result := P;
  while True do
  begin
    case Result^ of
      #0:
        Break;
      #10:
        Inc(Result);
      #13:
        begin
          Inc(Result);
          if Result^ = #10 then
            Inc(Result);
          Break;
        end;
    end;
    Inc(Result);
  end;
end;

function GetEditorSource(EditBuffer: IOTAEditBuffer): UTF8String;
const
  MaxBufSize = 15872; // The C++ compiler uses this number of bytes for read operations and the IDE requires this
var
  Readn, Len: Integer;
  Buf       : array [0 .. MaxBufSize] of AnsiChar;
  Reader    : IOTAEditReader;
begin
  Result := '';
  if EditBuffer <> nil then
  begin
    Reader := EditBuffer.CreateReader;
    repeat
      Readn      := Reader.GetText(Length(Result), Buf, MaxBufSize);
      Buf[Readn] := #0;
      if Readn > 0 then
      begin
        Len := Length(Result);
        SetLength(Result, Len + Readn);
        Move(Buf[0], Result[Len + 1], Readn);
      end;
      // Result := Result + Buf;
    until Readn < MaxBufSize;
  end;
end;


procedure Register;
begin
  (BorlandIDEServices as IOTAKeyboardServices).AddKeyboardBinding(TLineMover.Create);
end;


{ TLineMover }

procedure TLineMover.BindKeyboard(const BindingServices: IOTAKeyBindingServices);
begin
  BindingServices.AddKeyBinding([ShortCut(VK_UP, [ssAlt])], DoKeyBinding, nil);
  BindingServices.AddKeyBinding([ShortCut(VK_Down, [ssAlt])], DoKeyBinding, nil);
  BindingServices.AddKeyBinding([ShortCut(VK_UP, [ssAlt, ssShift])], DoKeyBinding, nil);
  BindingServices.AddKeyBinding([ShortCut(VK_Down, [ssAlt, ssShift])], DoKeyBinding, nil);
end;

function TLineMover.GetBindingType: TBindingType;
begin
  Result := btPartial;
end;

function TLineMover.GetDisplayName: string;
begin
  Result := 'Line Mover';
end;

function TLineMover.GetName: string;
begin
  Result := 'line-mover-590F1C54-BE9F-4574-83C1-CF2E54C3F42F';
end;

procedure TLineMover.MoveLineBlockText(EditBuffer: IOTAEditBuffer; Down: Boolean);
type
  TBlock = record
    Row: Integer;
    Col: Integer;
    StartingRow: Integer;
    EndingRow: Integer;
    StartingColumn: Integer;
    EndingColumn: Integer;
  end;
var
  StartRow, EndRow, LastRow, Row, RowOffset             : Integer;
  BlockSize                                             : Integer;
  EditBlock                                             : IOTAEditBlock;
  EditPosition                                          : IOTAEditPosition;
  Source                                                : UTF8String;
  Start, UnchangedP, BlockStart, BlockEnd, AffectedLineP: PAnsiChar;
  Writer                                                : IOTAEditWriter;
  S                                                     : UTF8String;
  LastUnchangedRow                                      : Integer;
  Block                                                 : TBlock;
  PersistentBlocks, InvertedBlock                       : Boolean;
begin
  EditPosition := EditBuffer.EditPosition;
  EditBlock    := EditBuffer.EditBlock;
  StartRow     := EditPosition.Row;
  BlockSize    := EditBlock.Size;

  Block.Row            := EditPosition.Row;
  Block.Col            := EditPosition.Column;
  Block.StartingRow    := EditBlock.StartingRow;
  Block.EndingRow      := EditBlock.EndingRow;
  Block.StartingColumn := EditBlock.StartingColumn;
  Block.EndingColumn   := EditBlock.EndingColumn;

  InvertedBlock := Block.StartingRow = Block.Row;

  if (BlockSize <> 0) and (EditBlock.Style = btColumn) then
  begin
    // EditBlock.Starting*/Ending* are wrong in this mode, stick to moving one line
    Block.StartingRow := Block.Row;
    Block.EndingRow   := Block.Row;
    BlockSize         := 0;
  end;
  // If only the caret is in the last line and first column than ignore that line.
  if (BlockSize > 0) and (Block.EndingRow > Block.StartingRow) and (Block.EndingColumn = 1) then
  begin
    if Block.Row = Block.EndingRow then
      Dec(Block.Row);
    Dec(Block.EndingRow);
  end;

  LastRow := EditBuffer.GetLinesInBuffer;
  if BlockSize = 0 then
    EndRow := StartRow
  else
  begin
    StartRow := Block.StartingRow;
    EndRow   := Block.EndingRow;
  end;

  // MoveUp on first line is not allowed. MoveUp/Down is not allowed on the last line because it doesn't work and Delphi inserts #13#10 where it wants
  if (not Down and ((StartRow <= 1) or (EndRow >= LastRow))) or (Down and (EndRow >= LastRow - 1)) then
    Exit;

  Source           := GetEditorSource(EditBuffer);
  UnchangedP       := PAnsiChar(Source);
  Start            := UnchangedP;
  LastUnchangedRow := StartRow;
  if not Down then
    Dec(LastUnchangedRow);
  Row := 1;
  while (UnchangedP^ <> #0) and (Row < LastUnchangedRow) do
  begin
    UnchangedP := SkipToNextLine(UnchangedP);
    Inc(Row);
  end;

  if Row = LastUnchangedRow then
  begin
    BlockStart := UnchangedP;
    if not Down then // we skipped the unchanged line
    begin
      BlockStart := SkipToNextLine(BlockStart);
      Inc(Row);
    end;
    BlockEnd := BlockStart;
    while (BlockEnd^ <> #0) and (Row <= EndRow) do
    begin
      BlockEnd := SkipToNextLine(BlockEnd);
      Inc(Row);
    end;

    AffectedLineP := nil;
    if Down then
      AffectedLineP := SkipToNextLine(BlockEnd);

    SetString(S, BlockStart, BlockEnd - BlockStart);

    Writer := EditBuffer.CreateUndoableWriter;

    // Copy unaffected part
    Writer.CopyTo(UnchangedP - Start);
    if Down then
    begin
      // Delete moved block
      Writer.DeleteTo(BlockEnd - Start);
      // Copy line that was moved up due to the moved block
      Writer.CopyTo(AffectedLineP - Start);
    end;

    // Insert moved block
    Writer.Insert(PAnsiChar(S));

    if not Down then
    begin
      // Copy line that was moved down due to the moved block
      Writer.CopyTo(BlockStart - Start);
      // Delete moved block
      Writer.DeleteTo(BlockEnd - Start);
    end;
    // Copy unaffected part
    Writer.CopyTo(Length(Source));
    Writer := nil; // end undo group

    if Down then
      RowOffset := 1
    else
      RowOffset := -1;

    if BlockSize = 0 then
      EditPosition.Move(Block.Row + RowOffset, 0)
    else
    begin
      EditBlock.Reset;
      EditBlock.Style := btNonInclusive;

      PersistentBlocks := EditBuffer.BufferOptions.PersistentBlocks;
      try
        EditBuffer.BufferOptions.PersistentBlocks := True;
        EditPosition.Move(Block.StartingRow + RowOffset, 1);
        EditBlock.BeginBlock;
        try
          EditPosition.Move(Block.EndingRow + 1 + RowOffset, 1);
        finally
          EditBlock.EndBlock;
        end;
        if InvertedBlock then
          EditPosition.Move(Block.StartingRow + RowOffset, 1);
      finally
        EditBuffer.BufferOptions.PersistentBlocks := PersistentBlocks;
      end;
    end;
  end;

end;

procedure TLineMover.DuplicateLineBlockText(EditBuffer: IOTAEditBuffer; Down: Boolean);
type
  TBlock = record
    Row, Col: Integer;
    StartingRow, EndingRow: Integer;
    StartingColumn, EndingColumn: Integer;
  end;
var
  StartRow, EndRow, LastRow, Row: Integer;
  BlockSize: Integer;
  EditBlock: IOTAEditBlock;
  EditPosition: IOTAEditPosition;
  Source: UTF8String;
  P, BlockStart, BlockEnd: PAnsiChar;
  Writer: IOTAEditWriter;
  S: UTF8String;
  Block: TBlock;
  PersistentBlocks, InvertedBlock: Boolean;
begin
  EditPosition := EditBuffer.EditPosition;
  EditBlock    := EditBuffer.EditBlock;
  StartRow     := EditPosition.Row;
  BlockSize    := EditBlock.Size;

  // capture block bounds
  Block.Row            := StartRow;
  Block.Col            := EditPosition.Column;
  Block.StartingRow    := EditBlock.StartingRow;
  Block.EndingRow      := EditBlock.EndingRow;
  Block.StartingColumn := EditBlock.StartingColumn;
  Block.EndingColumn   := EditBlock.EndingColumn;

  InvertedBlock := Block.StartingRow = Block.Row;

  // normalize column‑mode to a single line
  if (BlockSize <> 0) and (EditBlock.Style = btColumn) then
  begin
    Block.StartingRow := StartRow;
    Block.EndingRow   := StartRow;
    BlockSize         := 0;
  end;

  // strip trailing empty last line if the block ends at col 1
  if (BlockSize > 0) and (Block.EndingRow > Block.StartingRow) and (Block.EndingColumn = 1) then
    Dec(Block.EndingRow);

  // figure out the rows we actually want
  if BlockSize = 0 then
    EndRow := StartRow
  else
  begin
    StartRow := Block.StartingRow;
    EndRow   := Block.EndingRow;
  end;

  LastRow := EditBuffer.GetLinesInBuffer;
  // bail out if we would go outside the buffer
  if (StartRow < 1) or (EndRow > LastRow) then
    Exit;

  // grab everything as one big string
  Source := GetEditorSource(EditBuffer);
  P      := PAnsiChar(Source);
  Row    := 1;

  // seek to the start of the block
  while (P^ <> #0) and (Row < StartRow) do
  begin
    P := SkipToNextLine(P);
    Inc(Row);
  end;
  BlockStart := P;

  // now seek to the end of the block
  while (P^ <> #0) and (Row <= EndRow) do
  begin
    P := SkipToNextLine(P);
    Inc(Row);
  end;
  BlockEnd := P;

  // capture the block text
  SetString(S, BlockStart, BlockEnd - BlockStart);

  // prepare to rewrite
  Writer := EditBuffer.CreateUndoableWriter;

  // copy up to insertion point
  if Down then
  begin
    // insertion is *after* the original block
    Writer.CopyTo(BlockEnd - PAnsiChar(Source));
    Writer.Insert(PAnsiChar(S));
    Writer.CopyTo(Length(Source)); // rest
  end
  else
  begin
    // insertion is *before* the original block
    Writer.CopyTo(BlockStart - PAnsiChar(Source));
    Writer.Insert(PAnsiChar(S));
    Writer.CopyTo(Length(Source)); // rest
  end;

  Writer := nil; // commit undo

  // restore selection: select the newly inserted copy
  PersistentBlocks := EditBuffer.BufferOptions.PersistentBlocks;
  try
    EditBlock.Reset;
    EditBlock.Style := btNonInclusive;
    EditBuffer.BufferOptions.PersistentBlocks := True;
    if Down then
    begin
      // new copy starts at old EndingRow+1
      EditPosition.Move(EndRow + 1, 1);
      EditBlock.BeginBlock;
      EditPosition.Move(EndRow + 1 + (BlockSize > 0).ToInteger * (EndRow - StartRow + 1), 1);
      EditBlock.EndBlock;
      if InvertedBlock then
        EditPosition.Move(EndRow + 1, 1);
    end
    else
    begin
      // new copy starts at old StartingRow
      EditPosition.Move(StartRow, 1);
      EditBlock.BeginBlock;
      EditPosition.Move(StartRow + (BlockSize > 0).ToInteger * (EndRow - StartRow + 1), 1);
      EditBlock.EndBlock;
      if InvertedBlock then
        EditPosition.Move(StartRow, 1);
    end;
  finally
    // restore whatever PersistentBlocks was before
    EditBuffer.BufferOptions.PersistentBlocks := PersistentBlocks;
  end;
end;


procedure TLineMover.DoKeyBinding(const Context: IOTAKeyContext; KeyCode: TShortCut; var BindingResult: TKeyBindingResult);
begin
  if KeyCode = ShortCut(VK_UP, [ssAlt]) then
  begin
    Self.MoveLineBlockText(Context.EditBuffer, False);
    BindingResult := krHandled;
  end
  else if KeyCode = ShortCut(VK_Down, [ssAlt]) then
  begin
    Self.MoveLineBlockText(Context.EditBuffer, True);
    BindingResult := krHandled;
  end
  else if KeyCode = ShortCut(VK_UP, [ssAlt, ssShift]) then
  begin
    Self.DuplicateLineBlockText(Context.EditBuffer, False);
    BindingResult := krHandled;
  end
  else if KeyCode = ShortCut(VK_Down, [ssAlt, ssShift]) then
  begin
    Self.DuplicateLineBlockText(Context.EditBuffer, True);
    BindingResult := krHandled;
  end
end;

end.
