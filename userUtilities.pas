unit userUtilities;


function getOrCreateFile(filename : string) : IInterface;
var
  i : integer;
  f, target : IInterface;
begin
  for i := 0 to Pred(FileCount) do begin
    f := FileByIndex(i);
    if (SameText(GetFileName(f), filename)) then target := f;
  end;
  
  if not Assigned(target) then begin
    target := AddNewFile;
    if not Assigned(target) then begin
      Result := 1;
  	  Exit;
    end;
  end;
  Result := target;
end;


function getFileElements(filename, record_name: string): IInterface;
var
  i : integer;
  f, npcs: IInterface;
begin
  for i := 0 to Pred(FileCount) do begin
    f := FileByIndex(i);
	if not (SameText(GetFileName(f), filename)) then
      Continue;
	npcs := GroupBySignature(f, record_name);
  end;
  Result := npcs;
end;


procedure removeGroup(tar_file : IInterface; group_string : string);
var
  ents, ent : IInterface;
  i : integer;
begin
  ents := getFileElements(GetFileName(tar_file), group_string);
  for i := 0 to Pred(ElementCount(ents)) do begin
    ent := ElementByIndex(ents, i);
	RemoveElement(ents, ent);
  end;
  RemoveElement(tar_file, ents);
end;

// Creates a blank leveled npc record with the given name
function createLeveledList(tar_file : IInterface; tar_filename : string): IInterface;
var
  new_rec : IInterface;
begin
  if not Assigned(tar_file) then begin
    AddMessage('createLevedList: Warning! Null file provided.');
	Exit;
  end;

  // Create LVLN Group Signature if group isn't in file
  if not Assigned(GroupBySignature(tar_file, 'LVLN')) then begin
    Add(tar_file, 'LVLN', True);
	if not Assigned(GroupBySignature(tar_file, 'LVLN')) then begin
	  AddMessage('createLevedList: Warning! LVLN group was not created.');
	  Exit;
	end;
  end;
  
  // Creates new LVLN in LVLN Group
  new_rec := Add(GroupBySignature(tar_file, 'LVLN'), 'LVLN', True);
  if not Assigned(new_rec) then begin
    AddMessage('createLevedList: Warning! LVLN record not created.');
	Exit;
  end;
  SetEditorID(new_rec, tar_filename);
  RemoveElement(new_rec, 'Leveled List Entries');
  Result := new_rec;
end;

//---------------------------------------------------------------------------------------
// https://www.reddit.com/r/skyrimmods/comments/5jkfz5/tes5edit_script_for_adding_to_leveled_lists/
function NewArrayElement(rec: IInterface; path: String): IInterface;
var
  a: IInterface;
begin
  a := ElementByPath(rec, path);
  if Assigned(a) then begin
    Result := ElementAssign(a, HighInteger, nil, false);
  end
  else begin
    a := Add(rec, path, true);
    Result := ElementByIndex(a, 0);
  end;
end;

procedure AddLeveledListEntry(rec: IInterface; level: Integer;
  reference: IInterface; count: Integer);
var
  entry: IInterface;
begin
  if not Assigned(rec) then begin
    AddMessage('AddLeveledListEntry: input "rec" not assigned.');
	Exit;
  end;
  if not Assigned(reference) then begin
    AddMessage('AddLeveledListEntry: input "reference" not assigned.');
	Exit;
  end;
  entry := NewArrayElement(rec, 'Leveled List Entries');
  SetElementEditValues(entry, 'LVLO\Level', level);
  SetElementEditValues(entry, 'LVLO\Reference', IntToHex(GetLoadOrderFormID(reference), 8));
  SetElementEditValues(entry, 'LVLO\Count', count);
end;
//---------------------------------------------------------------------------------------

  // https://github.com/TES5Edit/TES5Edit/blob/baca31dc5e4fe8d23a204f00e25216a5a0572f66/Edit%20Scripts/Skyrim%20-%20Add%20keywords.pas
procedure addKeyword(e : IInterface; slKeywords : TStringList);
var
  kwda, elem : IInterface;
  i, j : integer;
  exists : boolean;
begin
  kwda := ElementBySignature(e, 'KWDA');
  if not Assigned(kwda) then
  kwda := Add(e, 'KWDA', True);
  
  // no keywords subrecord (it must exist) - terminate script
  if not Assigned(kwda) then begin
    AddMessage('No keywords subrecord in ' + Name(e));
    Result := 1;
    Exit;
  end;

  // iterate through additional keywords
  for i := 0 to slKeywords.Count - 1 do begin
  
    // check if our keyword already exists
    exists := false;
    for j := 0 to ElementCount(kwda) - 1 do
      if IntToHex(GetNativeValue(ElementByIndex(kwda, j)), 8) = slKeywords[i] then begin
        exists := true;
        Break;
      end;
    
      // skip the rest of code in loop if keyword exists
      if exists then Continue;
      
      // CK likes to save empty KWDA with only a single NULL form, use it if so
      if (ElementCount(kwda) = 1) and (GetNativeValue(ElementByIndex(kwda, 0)) = 0) then
        SetEditValue(ElementByIndex(kwda, 0), slKeywords[i])
      else begin
      // add a new keyword at the end of list
      // container, index, element, aOnlySK
      elem := ElementAssign(kwda, HighInteger, nil, False);
      if not Assigned(elem) then begin
        AddMessage('Can''t add keyword to ' + Name(e));
        Exit;
      end;
      SetEditValue(elem, slKeywords[i]);
    end;
  
  end;
end;

procedure printStringList(sl : TStringList; name : string);
var
  i : integer;
begin
  AddMessage('printing contents of ' + name);
  for i := 0 to Pred(sl.Count) do begin
    AddMessage('>>' + sl[i]);
  end;
end;

end.

