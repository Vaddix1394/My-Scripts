unit userscript;

uses mteFunctions;
uses userUtilities;

const
  target_filename = 'Deadly Wenches - Less Wenches Patch.esp';
  lvln_entries = 2;
  
var
  slMasters : TStringList;
  target_file, skyrimFile, dwFile : IInterface;
  
//---------------------------------------------------------------------------------------
// File IO
//---------------------------------------------------------------------------------------
procedure getUserFile;
begin
  target_file := getOrCreateFile(target_filename);
  if not Assigned(target_file) then begin
	AddMessage('File not created or retrieved!');
	Exit;
  end;
  
  AddMastersToFile(target_file, slMasters, True);
end;

function getTargetLeveledListOverride(elem : IInterface): IInterface;
var
  i : integer;
  cur_ovr, next_ovr, m : IInterface;
  s : string;
begin
  if not Assigned(elem) then begin
    AddMessage('getTargetLeveledListOverride: input "elem" not assigned.');
	Exit;
  end;

  m := MasterOrSelf(elem);
  cur_ovr := m;
  //AddMessage(EditorID(elem));
  
  for i := 0 to Pred(OverrideCount(m)) do begin
    next_ovr := OverrideByIndex(m, i);
    s := Name(GetFile(next_ovr));
    if SameText(GetFileName(GetFile(next_ovr)), 'deadly wenches.esp') then
      Break;
    cur_ovr := next_ovr;
  end;
  Result := cur_ovr;
end;

procedure removeWenchesInLevelList(lvln : IInterface);
var
  i, wench_index : integer;
  lvln_ents, lvln_ent, lvln_ref, m_lvln_ref : IInterface;
  s, target, file_str : string;
  sl_wench : TStringList;
  l_wench_cnt : TList;
begin
  sl_wench := TStringList.Create;
  l_wench_cnt := TList.Create;
  
  lvln_ents := ElementByName(lvln, 'Leveled List Entries');
  for i := Pred(ElementCount(lvln_ents)) downto 0 do begin
    lvln_ent := ElementByIndex(lvln_ents, i);
    lvln_ref := LinksTo(ElementByPath(lvln_ent, 'LVLO\Reference'));
	s := GetElementEditValues(lvln_ent, 'LVLO\Level');
	m_lvln_ref := getTargetLeveledListOverride(lvln_ref);
	
	target := s + EditorID(m_lvln_ref);
	
	if pos('DW_', EditorID(m_lvln_ref))=0 then Continue;
	
	//AddMessage('Before check: ' + BaseName(GetFile(lvln_ref)) + ' | ' + target);
	//file_str := LowerCase(BaseName(GetFile(m_lvln_ref)));
	//if CompareStr(file_str, LowerCase('Deadly Wenches.esp')) <> 0 then begin
	//	AddMessage(IntToStr(CompareText(file_str, LowerCase('Deadly Wenches.esp'))));
	//end;
	//if CompareStr(file_str, LowerCase('Deadly Wenches.esp')) <> 0 then Continue;
	
	
	
	//AddMessage('Found target: ' + target);
	wench_index := sl_wench.IndexOf(target);
	if wench_index = -1 then begin
	  //AddMessage('>>Adding');
	  sl_wench.Add(target);
	  l_wench_cnt.Add(1);
	end else begin
	  if Integer(l_wench_cnt[wench_index]) >= lvln_entries then begin 
		//AddMessage('>>Revoving. Count ' + IntToStr(l_wench_cnt[wench_index]) + ' >= ' + IntToStr(lvln_entries));
		RemoveElement(lvln_ents, lvln_ent)
	  end else begin
		//AddMessage('>>Incrementing.  Count ' + IntToStr(l_wench_cnt[wench_index]) + ' < ' + IntToStr(lvln_entries));
		l_wench_cnt[wench_index] := Integer(l_wench_cnt[wench_index]) + 1;
	  end;
	end;
  end;
  sl_wench.Free;
  l_wench_cnt.Free;
end;

procedure getWenchRefFromLevelList(lvln : IInterface; sl_wench : TStringList; l_wench, l_wench_cnt : TList);
var
  i, wench_index : integer;
  lvln_ents, lvln_ent, lvln_ref, m_lvln_ref : IInterface;
  s, target, file_str : string;
begin
  lvln_ents := ElementByName(lvln, 'Leveled List Entries');
  for i := 0 to Pred(ElementCount(lvln_ents)) do begin
    lvln_ent := ElementByIndex(lvln_ents, i);
    lvln_ref := LinksTo(ElementByPath(lvln_ent, 'LVLO\Reference'));
	s := GetElementEditValues(lvln_ent, 'LVLO\Level');
	m_lvln_ref := getTargetLeveledListOverride(lvln_ref);
	
	target := s + EditorID(m_lvln_ref);
	//AddMessage('Before check: ' + BaseName(GetFile(lvln_ref)) + ' | ' + target);
	file_str := BaseName(GetFile(m_lvln_ref));
	if not SameText(file_str, 'Deadly Wenches.esp') then Continue;
	
	//AddMessage('Found target: ' + target);
	wench_index := sl_wench.IndexOf(target);
	if wench_index = -1 then begin
	  sl_wench.Add(target);
	  l_wench.Add(m_lvln_ref);
	  l_wench_cnt.Add(1);
	end else begin
	  l_wench_cnt[wench_index] := Integer(l_wench_cnt[wench_index]) + 1;
	end;
	
  end;
end;

procedure reduceWenches;
var
  i : integer;
  lvlns, lvln, m_lvln, new_override : IInterface;
  sl_wench : TStringList;
  l_wench, l_wench_cnt : TList;
begin
  lvlns := GetFileElements('deadly wenches.esp', 'LVLN');
  for i := 0 to Pred(ElementCount(lvlns)) do begin
	lvln := ElementByIndex(lvlns, i);
	if IsMaster(lvln) then Continue;
	
	//m_lvln := getTargetLeveledListOverride(lvln);
	//new_override := wbCopyElementToFile(m_lvln, target_file, False, True);
	new_override := wbCopyElementToFile(lvln, target_file, False, True);
	removeWenchesInLevelList(new_override);
	//sl_wench := TStringList.Create;
	//l_wench := TList.Create;
	//l_wench_cnt := TList.Create;
	//getWenchRefFromLevelList(lvln, sl_wench, l_wench, l_wench_cnt);
	//decreaseWenchesInLevelList(new_override, sl_wench, l_wench, l_wench_cnt);
	//sl_wench.Free;
	//l_wench.Free;
	//l_wench_cnt.Free;
  end;
end;

procedure decreaseWenchesInLevelList(lvln : IInterface; sl_wench : TStringList; l_wench, l_wench_cnt : TList);
var
  i, j : integer;
  target_additions : integer;
begin
	for i := 0 to sl_wench.Count-1 do begin
	  target_additions := Min(l_wench_cnt[i], lvln_entries);
	  for j := 0 to target_additions-1 do begin
		//AddMessage(EditorID(ObjectToElement(l_wench[i])));
		AddLeveledListEntry(lvln, 1, ObjectToElement(l_wench[i]), 1);
	  end;
	end;
end;

function isVampire(npc : IInterface) : boolean;
var
  i, j : integer;
  factions, faction : IInterface;
begin
  factions := ElementByName(npc, 'Factions');
  for i:= 0 to Pred(ElementCount(factions)) do begin
    faction := ElementByIndex(factions, i);
    faction := LinksTo(ElementByPath(faction, 'Faction'));
	if EditorID(faction) = 'VampireFaction' then 
	  Result := true;
	  Exit;
  end;
  Result := false;
end;
	
//---------------------------------------------------------------------------------------
// Global Variables
//---------------------------------------------------------------------------------------
procedure freeGlobalVariables;
begin
  slMasters.Free;
end;
  
function getFileObject(filename : string): IInterface;
var
  i : integer;
  f : IInterface;
  s : string;
begin
  for i := 0 to FileCount - 1 do begin
    f := FileByIndex(i);
	s := GetFileName(f);
	
	if SameText(s, filename) then begin
		Result := f;
		Exit;
	end;
  end;
end;
  
procedure setupGlobalVariables;
begin

  skyrimFile := getFileObject('Skyrim.esm');
  dwFile := getFileObject('Deadly Wenches.esp');
  slMasters := TStringList.Create;
  slMasters.Add('Skyrim.esm');
  slMasters.Add('Update.esm');
  slMasters.Add('Dawnguard.esm');
  slMasters.Add('Dragonborn.esm');
  //slMasters.Add('Unofficial Skyrim Legendary Edition Patch.esp');
  slMasters.Add('Immersive Wenches.esp');
  slMasters.Add('Deadly Wenches.esp');
  
end;

//---------------------------------------------------------------------------------------
// Required Tes5Edit Script Functions
//---------------------------------------------------------------------------------------

// Called before processing
// You can remove it if script doesn't require initialization code
function Initialize: integer;
begin
  setupGlobalVariables;
  getUserFile;
  reduceWenches;

  Result := 0;
end;

// called for every record selected in xEdit
function Process(e: IInterface): integer;
begin
  Result := 0;

  // comment this out if you don't want those messages
  //AddMessage('Processing: ' + FullPath(e));

  // processing code goes here

end;

// Called after processing
// You can remove it if script doesn't require finalization code
function Finalize: integer;
begin
  freeGlobalVariables;
  Result := 0;
end;                          // 23

end.