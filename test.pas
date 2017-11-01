{
  New script template, only shows processed records
  Assigning any nonzero value to Result will terminate script
}
unit userscript;

var
  slRaces, classes: TStringList;
  raceTemplates: TList;
  base_records, new_record_map: TStringList;
  base_records_ents, new_records_ents: TList;
  test_file: IInterface;
  test_filename: string;
  race_count : TList;
  total_var : integer;

// Initialize variables
procedure initVar;
var
  i, j : integer;
begin
  total_var := 5;
  test_filename := 'test wenches.esp';
  slRaces := TStringList.Create;
  slRaces.Add('DarkElfRace');
  //slRaces.Add('ArgonianRace');
  slRaces.Add('BretonRace');
  slRaces.Add('HighElfRace');
  slRaces.Add('ImperialRace');
  //slRaces.Add('KhajiitRace');
  slRaces.Add('NordRace');
  //slRaces.Add('OrcRace');
  slRaces.Add('RedguardRace');
  slRaces.Add('WoodElfRace');
  //slRaces.Add('NordRaceVampire');
  
  classes := TStringList.Create;
  classes.Add('lalawench_CombatTank');
  classes.Add('lalawench_CombatRogue');
  classes.Add('lalawench_Combat2H');
  classes.Add('lalawench_CombatArcher');
  classes.Add('lalawench_CombatMage');
  classes.Add('lalawench_CombatNecro');
  
  raceTemplates := TList.Create;
  for i := 1 to slRaces.Count do begin
    raceTemplates.Add(TList.Create);
  end;
  
  race_count := TList.Create;
  for i := 0 to slRaces.Count do race_count.Add(TList.Create);
end;
  
// Check if valid template (NPC must have all facegen entries to be a template)
function isValidFaceTemplate(npc : IInterface): boolean;
var
  temp : boolean;
begin
  temp := ElementExists(npc, 'Head Parts');
  temp := ElementExists(npc, 'QNAM - Texture lighting') and temp;
  temp := ElementExists(npc, 'NAM9 - Face morph') and temp;
  temp := ElementExists(npc, 'NAMA - Face parts') and temp;
  temp := ElementExists(npc, 'Tint Layers') and temp;
  Result := temp;
end;
  
// Print statistics
procedure printStats;
var
  i, j: integer;
  lst: TList;
begin
  AddMessage('Print Race Statistics');
  for i := 0 to slRaces.Count-1 do begin
    lst := TList(raceTemplates[i]);
    AddMessage(Format('Race: %s (%d)',[slRaces[i], lst.Count]));
  end;
  
  AddMessage('Base Race Statistics');
end;
  
// Saves references to DW's npc records that have facegen information of the target races
procedure getValidTemplates;
var
  i, j : integer;
  race : integer;
  npc, npcs, f: IInterface;
  lst: TList;
  female : integer;
begin
  for i := 0 to Pred(FileCount) do begin
    f := FileByIndex(i);
    if not (SameText(GetFileName(f), 'deadly wenches.esp')) then
      Continue;
	  
    AddMessage('Scanning ' + GetFileName(f));
    npcs := GroupBySignature(f, 'NPC_');
    for j := 0 to Pred(ElementCount(npcs)) do begin
      npc := ElementByIndex(npcs, j);
	  
      // only not overridden records count to avoid additions from overrides
      if not IsMaster(npc) then Continue;
	  
	  // skip male faces
	  female := GetElementNativeValues(npc, 'ACBS\Flags') and 1;
	  if female <> 1 then Continue;
	  
      // skip unknown races
      race := slRaces.IndexOf(EditorID(LinksTo(ElementBySignature(npc, 'RNAM'))));
      if race = -1 then Continue;
	  
	  // skip records without templates
	  if not ElementExists(npc, 'TPLT') then Continue;

	  if not isValidFaceTemplate(npc) then Continue;

      // adding to list
      lst := TList(raceTemplates[race]);
      lst.Add(npc);
    end;
  end;
end;

procedure getUserFile;
var
  i: integer;
  f: IInterface;
begin
  for i := 0 to Pred(FileCount) do begin
    f := FileByIndex(i);
    if (SameText(GetFileName(f), test_filename)) then test_file := f;
  end;
	
  if not Assigned(test_file) then begin
  test_file := AddNewFile;
    if not Assigned(test_file) then begin
      Result := 1;
  	Exit;
    end;
  end;
  
  // Hack to add KS Hairdo's as a master file
  for i := 0 to Pred(FileCount) do begin
    f := FileByIndex(i);
    if (SameText(GetFileName(f), 'update.esm')) then begin
	  AddRequiredElementMasters(f, test_file, False);
	end;
    if (SameText(GetFileName(f), 'dawnguard.esm')) then begin
	  AddRequiredElementMasters(f, test_file, False);
	end;
    if (SameText(GetFileName(f), 'dragonborn.esm')) then begin
	  AddRequiredElementMasters(f, test_file, False);
	end;
    //if (SameText(GetFileName(f), 'immersive wenches.esp')) then begin
	//  AddRequiredElementMasters(f, test_file, False);
	//end;
    if (SameText(GetFileName(f), 'ks hairdo''s.esp')) then begin
	  AddRequiredElementMasters(f, test_file, False);
	end;
	
  end;
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
  entry := NewArrayElement(rec, 'Leveled List Entries');
  SetElementNativeValues(entry, 'LVLO\Level', level);
  SetElementNativeValues(entry, 'LVLO\Reference', GetLoadOrderFormID(reference));
  SetElementNativeValues(entry, 'LVLO\Count', count);
end;
//---------------------------------------------------------------------------------------


// Creates a blank leveled npc record with the given name
function createLeveledList(new_filename : string): IInterface;
var
  template, new_file : IInterface;
begin
  if not Assigned(GroupBySignature(test_file, 'LVLN')) then begin
    Add(test_file, 'LVLN', True);
  end;
  new_file := Add(GroupBySignature(test_file, 'LVLN'), 'LVLN', True);
  SetEditorID(new_file, new_filename);
  RemoveElement(new_file, 'Leveled List Entries');
  Result := new_file;
end;

// Checks DW's leveled list overrides and returns the winning override before DW
// i.e. skyim | dragonborn | Deadly wenches
//            returns ^
function getTargetLeveledListOverride(elem : IInterface): IInterface;
var
  i : integer;
  cur_ovr, next_ovr, m : IInterface;
  s : string;
begin
	m := MasterOrSelf(elem);
	cur_ovr := m;
	for i := 0 to Pred(OverrideCount(m)) do begin
	  next_ovr := OverrideByIndex(m, i);
	  s := Name(GetFile(next_ovr));
	  if SameText(GetFileName(GetFile(next_ovr)), 'deadly wenches.esp') then
	    Break;
      cur_ovr := next_ovr;
	end;
	Result := cur_ovr;
end;

procedure collectDwRecords;
var
  i, j: integer;
  ent, ents: IInterface;
  m, elem, elems : IInterface;
  isDuplicate : integer;
begin
  elems := getFileElements('deadly wenches.esp', 'LVLN');
  for i := 0 to Pred(ElementCount(elems)) do begin 
	elem := ElementByIndex(elems, i);
	
	// Only deal with LVLN that were modified
	if IsMaster(elem) then
	  Continue;
	  
	m := getTargetLeveledListOverride(elem);
	// Get the master record (not the override)
	//m := MasterOrSelf(elem);
	//AddMessage('>>' + Name(m));
	
	// Grab the element that was referenced by the LVLO
	ents := ElementByName(m, 'Leveled List Entries');
	for j:= 0 to Pred(ElementCount(ents)) do begin
      ent := ElementByIndex(ents, j);
      ent := LinksTo(ElementByPath(ent, 'LVLO\Reference'));
	  if Signature(ent) <> 'NPC_' then Continue;
	  
	  // Check if female
	  if GetElementNativeValues(ent, 'ACBS\Flags') and 1 <> 1 then Continue;
	  
	  isDuplicate := base_records.IndexOf(EditorID(ent));
	  if isDuplicate <> -1 then Continue;
	  base_records.Add(EditorID(ent));
	  base_records_ents.Add(ent);
	  
	  //template := getLeveledListTemplate;
	  //AddLeveledListEntry(template, 1, ent, 1);
	  //***newLeveledListEntry := createLeveledList('DW_' + EditorID(ent));
	  //Add(blah, 'DW_' + EditorID(ent), false);
	  //wbCopyElementToFile(ent, test_file, true, true);
      //AddMessage('>>>>' + Name(ent));
	  
	  //fact_ents := ElementByName(ent, 'Factions');
	  //for k:= 0 to Pred(ElementCount(fact_ents)) do begin
	  //  fact_ent := ElementByIndex(fact_ents, k);
		//fact_ent := LinksTo(ElementByPath(fact_ent, 'Faction'));
	  //  //AddMessage('2>>>>>' + EditorID(fact_ent));
	  //end;
	end;
  end;
end;

procedure distributeTwRecords;
var
  i, j, k: integer;
  ent_ref, ent, ents: IInterface;
  m, elem, elems : IInterface;
  new_over, lvl_ref : IInterace;
  new_index, race : integer;
  isEdited : boolean;
begin
  elems := getFileElements('deadly wenches.esp', 'LVLN');
  for i := 0 to Pred(ElementCount(elems)) do begin
	elem := ElementByIndex(elems, i);
	
	// Only deal with LVLN that were modified
	if IsMaster(elem) then
	  Continue;
	  
	m := getTargetLeveledListOverride(elem);
	//AddMessage('>>' + Name(m));

	// Grab the element that was referenced by the LVLO
	isEdited := false;
	ents := ElementByName(m, 'Leveled List Entries');
	for j:= 0 to Pred(ElementCount(ents)) do begin
      ent_ref := ElementByIndex(ents, j);
      ent := LinksTo(ElementByPath(ent_ref, 'LVLO\Reference'));
	  if Signature(ent) <> 'NPC_' then Continue;
	  if GetElementNativeValues(ent, 'ACBS\Flags') and 1 <> 1 then Continue; //female check
	  //race := slRaces.IndexOf(EditorID(LinksTo(ElementBySignature(ent, 'RNAM'))));
	  //if race = -1 then Continue;
	  
	  if not isEdited then begin
	    // Create override for new plugin
	    new_over := wbCopyElementToFile(m, test_file, False, True);
		isEdited := true;
	  end;
	  
	  //AddMessage('>> ' + EditorID(ent) + ' : ' + EditorID(LinksTo(ElementBySignature(ent, 'RNAM'))));
	  new_index := new_record_map.IndexOf(EditorID(ent));
	  lvl_ref := ObjectToElement(new_records_ents[new_index]);
	  for k := 1 to 3 do begin
	  AddLeveledListEntry(new_over, GetElementNativeValues(ent_ref, 'LVLO\Level'), lvl_ref, GetElementNativeValues(ent_ref, 'LVLO\Count'))
	  end;
	  
	end;
  end;
end;

procedure createTwRecords;
var
  i, j, k : integer;
  npc : IInterface;
  race : integer;
  lst : TList;
  base_lst, temp_lst : TList;
  base_npc : IInterface;
  lvl_file : IInterface;
  
  cur_index : integer;
  cur_lst : TList;
  cur_npc, iw_npc, tar_npc : IInterface;
begin
  // Organize the base records by race
  for i := 0 to base_records.Count-1 do begin
    npc := ObjectToElement(base_records_ents[i]);
	race := slRaces.IndexOf(EditorID(LinksTo(ElementBySignature(npc, 'RNAM'))));
	if race = -1 then begin
	  race := slRaces.IndexOf(EditorID(getBaseRaceFromVampire(npc))); // Handle vampires
	  if race = -1 then Continue;
	end;
    lst := TList(race_count[race]);
    lst.Add(npc);
  end;
  
  // Iterate the base records by race
  for i := 0 to slRaces.Count-1 do begin
    cur_index := 0;
	cur_lst := TList(raceTemplates[i]);
    base_lst := TList(race_count[i]);
	temp_lst := TList(raceTemplates[i]);
	
	// For each base record in the list, transfers a "random" template face
	for j := 0 to base_lst.Count-1 do begin
	  base_npc := ObjectToElement(base_lst[j]);
	  //AddMessage(EditorID(base_npc) + ' | ' + Name(base_npc));
	  lvl_file := createLeveledList('TW_l' + EditorID(base_npc));
	  
	  new_record_map.Add(EditorID(base_npc));
	  new_records_ents.Add(lvl_file);
	  
	  for k := 0 to total_var-1 do begin
	    cur_npc := ObjectToElement(cur_lst[cur_index]);	
		iw_npc := LinksTo(ElementByPath(cur_npc, 'TPLT'));
		if not Assigned(cur_npc) then AddMessage('cur_npc t not assigned');
		if not Assigned(iw_npc) then AddMessage('iw_npc not assigned');
		
        if cur_index = cur_lst.Count-1 then	cur_index := 0 else 
		  cur_index := cur_index + 1;
		//AddMessage(EditorID(cur_npc) + ' | ' + Name(cur_npc));
		tar_npc := wbCopyElementToFile(base_npc, test_file, true, true);
		//AddMessage(Name(cur_npc) + ' | ' + Name(tar_npc));
		copyFaceData(tar_npc, iw_npc);
		// Needs to be after copyFaceData to change vampire eyes
		transferNpcData(base_npc, tar_npc, k);
		//SetEditValue(ElementByPath(tar_npc, 'TPLT'), Name(iw_npc));
	    AddLeveledListEntry(lvl_file, 1, tar_npc, 1);
		//if checkEyes(tar_npc) then AddMessage('createTwRecords: ' + Name(tar_npc));
	  end;
	  
	  // Get random index
	  // Iterate over them
	  //for k := 0 to 
	  //AddLeveledListEntry(lvl_file, 1, ent, 1);
	end;
  end;
end;

// Transfers Editor ID, template, and template flags to target npc record
procedure transferNpcData(src, dest : IInterace; variation : integer);
var
  s : string;
begin
  s := 'EDID';
  SetElementEditValues(dest, 'EDID', 'TW_' + GetElementEditValues(src, 'EDID') + '_' + IntToStr(variation));
  //ElementAssign(ElementByPath(dest, s), LowInteger, 'TW_' + ElementByPath(src, s), False);

  s := 'TPLT';
  SetEditValue(ElementByPath(dest, s), Name(src));
  //ElementAssign(ElementByPath(dest, s), LowInteger, src, False);
  
  // Use src npc as template for everything but traits (i.e. race, gender, h/w, face gen)
  s := 'ACBS\Template Flags';
  //SetElementNativeValues(dest, s, (GetElementNativeValues(src, s) or $1FFE));
  //SetElementNativeValues(dest, s, (GetElementNativeValues(src, s) and $1FFE));
  SetElementNativeValues(dest, s, $1FFE);
  //ElementAssign(ElementByPath(dest, s), LowInteger, (ElementByPath(src, s) or $41), False);  
  
  addFactionData(src, dest);

end;

function checkVampireFaction(e : IInterface): boolean;
var
  i : integer;
  fact_ents, fact_ent : IInterface;
  isVampire : boolean;
begin
  fact_ents := ElementByName(e, 'Factions');
  isVampire := False;
  for i:= 0 to Pred(ElementCount(fact_ents)) do begin
    fact_ent := ElementByIndex(fact_ents, i);
    fact_ent := LinksTo(ElementByPath(fact_ent, 'Faction'));
	if EditorID(fact_ent) = 'VampireFaction' then
	  isVampire := True;
  end;
  Result := isVampire;
end;

procedure addFactionData(src, dest : IInterface);
var
  sourceIsVampire, destIsVampire : boolean;
begin
  //Handle faction-related issues
  sourceIsVampire := checkVampireFaction(src);
  destIsVampire := checkVampireFaction(dest);
  
  // Add adapted vampire data from source to dest if the source is a vampire record
  if sourceIsVampire then begin
	addVampireFactionData(src, dest);
  end else begin 
    // Change dest's eyes if IW template used vampire eyes and dest isn't a vampire
    if not destIsVampire then begin
      addNonVampireEyes(dest);
	end;
  end;
end;

procedure addNonVampireEyes(e : IInterface);
var
  i, j : integer;
  elfList, nonElfList : TStringList;
  hdpt, hdpt_ent, hdpt_elem : IInterface;
  new_elem : IInterface;
  hdpt_index : integer;
  race : integer;
  race_rec : IInterface;
  eye_string : string;
  count : integer;
  
  vamp_eye_lst, eye_races, eye_lst : TStringList;
  eyeTemplates : TList;
  
  exists : boolean;
begin

  // List of Vampire Eyes
  vamp_eye_lst := TStringList.Create;
  vamp_eye_lst.Add('0007291E'); //FemaleEyesHumanVampire
  vamp_eye_lst.Add('02006F90'); //FemaleEyesHumanVampire01
  vamp_eye_lst.Add('0200D6D4'); //FemaleEyesHumanVampire01Nord
  vamp_eye_lst.Add('0200D6D3'); //FemaleEyesHumanVampireNord
  
  // Finds if any of the head parts are vampire eyes
  hdpt := ElementByName(e, 'Head Parts');
  exists := false;
  hdpt_index := -1;
  for i := 0 to ElementCount(hdpt)-1 do begin
    for j := 0 to vamp_eye_lst.Count-1 do begin
	  if IntToHex(GetNativeValue(ElementByIndex(hdpt, i)), 8) = vamp_eye_lst[j] then begin
	    exists := true;
		Break;
	  end
	end;
	if exists then begin
	  hdpt_index := i;
	  Break;
    end;
  end;
  vamp_eye_lst.Free;
  
  
  // Removes vampire eye headparts
  if hdpt_index=-1 then begin
    //AddMessage('Warning: NPC doesn''t have vampire eyes when they are assumed to.' );
	Exit;
  end else begin 
    AddMessage('Note: NPC' + EditorID(e) + ' replacing eyes.' );
    RemoveByIndex(hdpt, hdpt_index, True);
  end;
  
  // Create list of races with specific eye parts
  eye_races := TStringList.Create;  
  eye_races.Add('ArgonianRace');   // 0
  eye_races.Add('DarkElfRace');    // 1
  eye_races.Add('HighElfRace');    // 2
  eye_races.Add('KhajiitRace');    // 3
  eye_races.Add('OrcRace');        // 4
  eye_races.Add('WoodElfRace');    // 5
  eye_races.Add('NordRace');       // 6 <-- starting from here all use human eyes 
  eye_races.Add('BretonRace');     // 7
  eye_races.Add('ImperialRace');   // 8
  eye_races.Add('RedguardRace');   // 9
  
  // Create list of races' eye parts
  eyeTemplates := TList.Create;
  for i := 0 to eye_races.Count do begin
    eyeTemplates.Add(TStringList.Create);
  end;
 
  eye_lst := TStringList(eyeTemplates[0]);
  eye_lst.Add('0009250C'); //FemaleEyesArgonian
  eye_lst.Add('000A2D84'); //FemaleEyesArgonianBrown
  eye_lst.Add('000A2D85'); //FemaleEyesArgonianBrownR
  eye_lst.Add('000A2EAF'); //FemaleEyesArgonianOlive
  eye_lst.Add('000A2EB0'); //FemaleEyesArgonianOliveR
  eye_lst.Add('000A2ED7'); //FemaleEyesArgonianR
  eye_lst.Add('000A2EB1'); //FemaleEyesArgonianRed
  eye_lst.Add('000A2EB2'); //FemaleEyesArgonianRedR
  eye_lst.Add('000A2F12'); //FemaleEyesArgonianVampire
  eye_lst.Add('000A2F13'); //FemaleEyesArgonianYellow
  eye_lst.Add('000A2F14'); //FemaleEyesArgonianYellowR
  
  eye_lst := TStringList(eyeTemplates[1]);
  eye_lst.Add('0005392A'); //FemaleEyesDarkElfDeepRed
  eye_lst.Add('0005392B'); //FemaleEyesDarkElfDeepRed2
  eye_lst.Add('00051540'); //FemaleEyesDarkElfRed
  eye_lst.Add('001010B7'); //FemaleEyesDarkElfUnique
  
  eye_lst := TStringList(eyeTemplates[2]);
  eye_lst.Add('0004021C'); //FemaleEyesHighElfDarkYellow
  eye_lst.Add('0005153F'); //FemaleEyesHighElfOrange
  eye_lst.Add('00040209'); //FemaleEyesHighElfYellow

  eye_lst := TStringList(eyeTemplates[6]);
  eye_lst.Add('0007291B'); //FemaleEyesHumanAmber
  eye_lst.Add('0007291A'); //FemaleEyesHumanBrightGreen
  eye_lst.Add('00072917'); //FemaleEyesHumanBrown
  eye_lst.Add('000F81D4'); //FemaleEyesHumanBrownBloodShot
  eye_lst.Add('00040208'); //FemaleEyesHumanDarkBlue
  eye_lst.Add('000401A7'); //FemaleEyesHumanDemon
  eye_lst.Add('00040210'); //FemaleEyesHumanGreenHazel
  eye_lst.Add('00040211'); //FemaleEyesHumanGrey
  eye_lst.Add('00040225'); //FemaleEyesHumanHazel
  eye_lst.Add('00051548'); //FemaleEyesHumanHazelBrown
  eye_lst.Add('00040228'); //FemaleEyesHumanIceBlue
  eye_lst.Add('0007291C'); //FemaleEyesHumanLightBlue
  eye_lst.Add('000F81D5'); //FemaleEyesHumanLightBlueBloodShot
  eye_lst.Add('00040227'); //FemaleEyesHumanLightGrey
  eye_lst.Add('00040224'); //FemaleEyesHumanYellow
  
  eye_lst := TStringList(eyeTemplates[3]);
  eye_lst.Add('0002DDC1'); //FemaleEyesKhajiitBase
  eye_lst.Add('000EE876'); //FemaleEyesKhajiitBaseNarrow
  eye_lst.Add('000EE877'); //FemaleEyesKhajiitBlue
  eye_lst.Add('000EE878'); //FemaleEyesKhajiitBlueNarrow
  eye_lst.Add('000EE879'); //FemaleEyesKhajiitIce
  eye_lst.Add('000EE87A'); //FemaleEyesKhajiitIceNarrow
  eye_lst.Add('000EE87B'); //FemaleEyesKhajiitOrange
  eye_lst.Add('000EE87C'); //FemaleEyesKhajiitOrangeNarrow
  eye_lst.Add('000EE87F'); //FemaleEyesKhajiitVampire
  eye_lst.Add('000EE87D'); //FemaleEyesKhajiitYellow
  eye_lst.Add('000EE87E'); //FemaleEyesKhajiitYellowNarrow
  
  eye_lst := TStringList(eyeTemplates[4]);
  eye_lst.Add('0004021F'); //FemaleEyesOrcDarkGrey
  eye_lst.Add('00040220'); //FemaleEyesOrcIceBlue
  eye_lst.Add('00040221'); //FemaleEyesOrcRed
  eye_lst.Add('00107B98'); //FemaleEyesOrcVampire
  eye_lst.Add('00040222'); //FemaleEyesOrcYellow
  
  eye_lst := TStringList(eyeTemplates[5]);
  eye_lst.Add('00051510'); //FemaleEyesWoodElfBrown
  eye_lst.Add('0005392C'); //FemaleEyesWoodElfDeepBrown
  eye_lst.Add('0005392D'); //FemaleEyesWoodElfDeepViolet
  eye_lst.Add('00053959'); //FemaleEyesWoodElfLightBrown
  
  race_rec := LinksTo(ElementBySignature(e, 'RNAM'));
  race := eye_races.IndexOf(EditorID(race_rec));
  if race=-1 then begin
    AddMessage('Warning: NPC does not appear to be a standard player race');
	Exit;
  end;
  if race >= 6 then race := 6; //Set all human races to same "race" index
  
  // Create new headpart element with given eye string
  hdpt := ElementByName(e, 'Head Parts');
  new_elem := ElementAssign(hdpt, HighInteger, nil, False);
  if not Assigned(new_elem) then begin
    AddMessage('Can''t add new hdpt to ' + Name(e));
	Exit;
  end;
  eye_lst := TStringList(eyeTemplates[race]);
  SetEditValue(new_elem, eye_lst[Random(eye_lst.Count)]);
  
  // Free
  for i := 0 to eye_races.Count do begin
    TStringList(eyeTemplates[i]).Free;
  end;
  eyeTemplates.Free;
  eye_races.Free;
end;

function checkEyes(e : IInterface) : boolean;
var
  count : integer;
  hdpt, hdpt_ent, hdpt_elem : IInterface;
  i : integer;
begin
  count := 0;
  hdpt := ElementByName(e, 'Head Parts');
  for i := 0 to ElementCount(hdpt)-1 do begin
    hdpt_ent := ElementByIndex(hdpt, i);
    hdpt_elem := LinksTo(hdpt_ent);
    if pos('femaleeyes', LowerCase(EditorID(hdpt_elem))) <> 0 then begin
	  count := count + 1;
	end;
  end;
  Result := (count > 1);
end;

function checkEyesOne(e : IInterface) : boolean;
var
  count : integer;
  hdpt, hdpt_ent, hdpt_elem : IInterface;
  i : integer;
begin
  count := 0;
  hdpt := ElementByName(e, 'Head Parts');
  for i := 0 to ElementCount(hdpt)-1 do begin
    hdpt_ent := ElementByIndex(hdpt, i);
    hdpt_elem := LinksTo(hdpt_ent);
    if pos('femaleeyes', LowerCase(EditorID(hdpt_elem))) <> 0 then begin
	  count := count + 1;
	end;
  end;
  Result := (count = 1);
end;

procedure printCheckEyesOne(e : IInterface);
var
  count : integer;
  hdpt, hdpt_ent, hdpt_elem : IInterface;
  i : integer;
begin
  AddMessage(Name(e));
  hdpt := ElementByName(e, 'Head Parts');
  for i := 0 to ElementCount(hdpt)-1 do begin
    hdpt_ent := ElementByIndex(hdpt, i);
    hdpt_elem := LinksTo(hdpt_ent);
	AddMessage(' > ' + LowerCase(EditorID(hdpt_elem)));
  end;
end;

procedure addVampireEyes(e : IInterface);
var
  i : integer;
  elfList, nonElfList : TStringList;
  hdpt, hdpt_ent, hdpt_elem : IInterface;
  new_elem : IInterface;
  tar_index : integer;
  race : integer;
  race_rec : IInterface;
  eye_string : string;
  count : integer;
begin
  //----------------------------------------------------------------------------------
  // Adding the Vampire Eyes
  //----------------------------------------------------------------------------------
  // Find the eye headpart in the existing npc record and remove it
  //AddMessage('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
  count := 0;
  hdpt := ElementByName(e, 'Head Parts');
  tar_index := -1;
  for i := 0 to ElementCount(hdpt)-1 do begin
    hdpt_ent := ElementByIndex(hdpt, i);
    hdpt_elem := LinksTo(hdpt_ent);
	//AddMessage(LowerCase(EditorID(hdpt_elem)));
    if pos('femaleeyes', LowerCase(EditorID(hdpt_elem))) <> 0 then begin
	  //AddMessage('Target!!!!!!!!!!!!!!!!!!!! :');
	  tar_index := i;
	  //Break;
	  count := count + 1;
	end;
	//AddMessage(' >> ' + LowerCase(EditorID(hdpt_elem)));
  end;
  
  // Not all entries have eyes (relies on race to provide head parts)
  if tar_index <> -1 then begin
	RemoveByIndex(hdpt, tar_index, True);
	//AddMessage(' Eyes removed!');
	count := 0;
	hdpt := ElementByName(e, 'Head Parts');
    for i := 0 to ElementCount(hdpt)-1 do begin
      hdpt_ent := ElementByIndex(hdpt, i);
      hdpt_elem := LinksTo(hdpt_ent);
  	//AddMessage(LowerCase(EditorID(hdpt_elem)));
      if pos('femaleeyes', LowerCase(EditorID(hdpt_elem))) <> 0 then begin
  	    count := count + 1;
  	  end;
  	//AddMessage(' >> ' + LowerCase(EditorID(hdpt_elem)));
    end;
	if (count <> 0) then AddMessage('Removed but didn''t');
  end; 
  
  if checkEyesOne(e) then begin 
    AddMessage('Eyes detected, but not removed');
	printCheckEyesOne(e);
  end;

  hdpt := ElementByName(e, 'Head Parts');
  for i := 0 to ElementCount(hdpt)-1 do begin
    hdpt_ent := ElementByIndex(hdpt, i);
    hdpt_elem := LinksTo(hdpt_ent);
	//AddMessage(' >> ' + LowerCase(EditorID(hdpt_elem)));
  end;
  //AddMessage('==========================================');
  
  // Create strings for elf and non-elf race (notice not mer and non-mer!)
  elfList := TStringList.Create;
  elfList.Add('DarkElfRace');
  elfList.Add('HighElfRace');
  elfList.Add('WoodElfRace');
  
  nonElfList := TStringList.Create;
  nonElfList.Add('NordRace');
  nonElfList.Add('BretonRace');
  nonElfList.Add('ImperialRace');
  nonElfList.Add('RedguardRace');
  nonElfList.Add('OrcRace');
  
  // Determine eye string based on race
  race_rec := LinksTo(ElementBySignature(e, 'RNAM'));
  race := elfList.IndexOf(EditorID(race_rec));
  if race <> -1 then eye_string := '0007291E'; //"FemaleEyesHumanVampire" [HDPT:0007291E]
  race := nonElfList.IndexOf(EditorID(race_rec));
  if race <> -1 then eye_string := '02006F90'; //"FemaleEyesHumanVampire01" [HDPT:02006F90]
  
  if not Assigned(eye_string) then begin
    AddMessage('Warning! eye_string not set.');
    Exit;
  end;
  
  //if checkEyesOne(e) then AddMessage('AddVampireEyes1: ' + Name(e));
  
  // Create new headpart element with given eye string
  hdpt := ElementByName(e, 'Head Parts');
  new_elem := ElementAssign(hdpt, HighInteger, nil, False);
  if not Assigned(new_elem) then begin
    AddMessage('Can''t add new hdpt to ' + Name(e));
	Exit;
  end;
  SetEditValue(new_elem, eye_string);
  
  //if checkEyes(e) then AddMessage('AddVampireEyes2: ' + Name(e));
  
  // Free
  elfList.Free;
  nonElfList.Free;
end;

function getBaseRaceFromVampire(src: IInterface) : IInterface;
var
  race_rec, race_rec2 : IInterface;
  race, race2 : integer;
begin
  // Sets npc's race to non-vampire race. Using keywords instead like Alva's record
  race_rec: = LinksTo(ElementBySignature(src, 'RNAM'));
  race := slRaces.IndexOf(EditorID(race_rec));
  if race <> -1 then begin
    AddMessage('Standard race: ' + EditorID(race_rec));
	Exit;
  end;
    // Get non-vampire race record from morph race attribute
  race_rec2 := LinksTo(ElementBySignature(race_rec, 'NAM8'));
  race2 := slRaces.IndexOf(EditorID(race_rec2));
  if race2 = -1 then begin
	AddMessage('Not a vampire: '+ EditorID(race_rec) + ' : ' + EditorID(race_rec2));
	Exit;
  end;
  Result := race_rec2;
end;

procedure addVampireFactionData(src, e: IInterface);
var
  slKeywords : TStringList;
  race_rec : IInterface;
  s : string;
begin

  // Get non-vampire race from vampire race (i.e. BretonRace from BretonVampireRace)
  s := 'RNAM';
  race_rec := getBaseRaceFromVampire(src);
  SetEditValue(ElementByPath(e, s), Name(race_rec));
  
  // Vampires don't inherit keywords and we want to add "Vampire" and "ActorTypeUndead"
  // to avoid dealing with texture issues related to (*)VampireRace
  s := 'ACBS\Template Flags';
  SetElementNativeValues(e, s, (GetElementNativeValues(src, s) and $0FFE));

  //if checkEyes(e) then AddMessage('addVampireFactionData1: ' + Name(e));
  // Add Vampire Eyes
  addVampireEyes(e);
  //if checkEyes(e) then AddMessage('addVampireFactionData2: ' + Name(e));
  
  // Assign keywords
  slKeywords := TStringList.Create;
  slKeywords.Add('00013796'); //ActorTypeUndead
  slKeywords.Add('000A82BB'); //Vampire
  addKeyword(e, slKeywords);
  slKeywords.Free;
  //if checkEyes(e) then AddMessage('addVampireFactionData3: ' + Name(e));
end;

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

//=========================================================================
// Snippet from https://github.com/TES5Edit/TES5Edit/blob/sharlikran-fo4dump/Edit%20Scripts/Skyrim%20-%20Reuse%20faces.pas
procedure copyFaceData(e, npc : IInterface);
var
  s : string;
  morphs, m : IInterface;
begin
  if not Assigned(e) then AddMessage('input arg e not assigned!');
  if not Assigned(npc) then AddMessage('input arg npc not assigned!');
  //AddMessage('Generating face for ' + Name(e) + ' from ' + Name(npc));
	  
	  
  // Modification: Get record with KS Hairdo's Patch override
  s := 'Head Parts';
  //RemoveElement(e, s);
  Add(e, s, True);
  ElementAssign(ElementByPath(e, s), LowInteger, ElementByPath(WinningOverride(npc), s), False);
  
  s := 'HCLF';
  if ElementExists(npc, s) then begin
    if GetElementNativeValues(npc, s) shr 24 = 0 then begin
      Add(e, s, True);
      ElementAssign(ElementByPath(e, s), LowInteger, ElementByPath(npc, s), False);
    end;
  end else
    RemoveElement(e, s);
  
  s := 'FTST';
  if ElementExists(npc, s) then begin
    if GetElementNativeValues(npc, s) shr 24 = 0 then begin
      Add(e, s, True);
      ElementAssign(ElementByPath(e, s), LowInteger, ElementByPath(npc, s), False);
    end;
  end else
    RemoveElement(e, s);

  s := 'QNAM';
  Add(e, s, True);
  ElementAssign(ElementByPath(e, s), LowInteger, ElementByPath(npc, s), False);

  s := 'NAM9';
  Add(e, s, True);
  ElementAssign(ElementByPath(e, s), LowInteger, ElementByPath(npc, s), False);
  // slightly adjust face morphs
  //morphs := ElementByPath(e, s);
  //for i := 0 to ElementCount(morphs) - 2 do begin
  //  morph := ElementByIndex(morphs, i);
  //  m := GetNativeValue(morph);
  //  m := m + random(11)/100 - 0.05;
  //  if m > 1 then m := 1
  //    else if m < -1 then m := -1;
  //  SetNativeValue(morph, m);
  //end;
  
  s := 'NAMA';
  Add(e, s, True);
  ElementAssign(ElementByPath(e, s), LowInteger, ElementByPath(npc, s), False);

  s := 'Tint Layers';
  Add(e, s, True);
  ElementAssign(ElementByPath(e, s), LowInteger, ElementByPath(npc, s), False);
end;

//=========================================================================

procedure makeVariations;
//var
//  faction_lst : TStringList;
//  template : IInterface;
begin
  //faction_lst := TStringList.Create;
  //faction_lst.Add('VigilantOfStendarrFaction');
  //faction_lst.Add('VampireFaction');
  //faction_lst.Add('ForswornFaction');
  //faction_lst.Add('CWSonsFaction');
  //faction_lst.Add('CWImperialFaction');
  //template := getLeveledListTemplate;
  
  base_records := TStringList.Create;
  base_records_ents := TList.Create;
  new_record_map := TStringList.Create;
  new_records_ents := TList.Create;
  collectDwRecords;
  createTwRecords;
  distributeTwRecords;
end;

procedure printBaseRecordsStats;
var
  i : integer;
  lst : TList;
  npc : IInterface;
  race : integer;
begin
//  AddMessage('Debug');
//  for i := 0 to base_records.Count-1 do begin
//    npc := ObjectToElement(base_records_ents[i]);
//	AddMessage('===================================');
//	AddMessage('>> ' + EditorID(npc));
//	AddMessage('>> ' + EditorID(LinksTo(ElementBySignature(npc, 'RNAM'))));
//  end;
  AddMessage('Base Record Statistics');
  for i := 0 to slRaces.Count-1 do begin
    lst := TList(race_count[i]);
    AddMessage(Format('Race: %s (%d)',[slRaces[i], lst.Count]));
  end;
end;
  
//=========================================================================
// Called before processing
// You can remove it if script doesn't require initialization code
function Initialize: integer;
begin
  initVar;
  getUserFile;
  getValidTemplates;
  makeVariations;

  printStats;
  printBaseRecordsStats;

  Result := 0;
end;

// called for every record selected in xEdit
function Process(e: IInterface): integer;
var
  race: integer;
  template: TList;

begin
  //if Signature(e) <> 'NPC_' then
  //  Exit;

  //race := slRaces.IndexOf(EditorID(LinksTo(ElementBySignature(e, 'RNAM'))));
  //if race = -1 then
  //  Exit;
  //TList(raceTemplates[race]).add(e);

  Result := 1;

  // comment this out if you don't want those messages
  //AddMessage('Processing: ' + slRaces[race]);
  //AddMessage('Processing: ' + Name(e));
  //AddMessage('  Compare: ' + Name(raceTemplates[race][0]));

  // processing code goes here

end;

// Called after processing
// You can remove it if script doesn't require finalization code
function Finalize: integer;
var
  i, j : integer;
  template : TList;
  npc : IInterface;
begin
//  for i := 0 to raceTemplates.Count-1 do begin
//    template := TList(raceTemplates[i]);
//    AddMessage('Race: ' + slRaces[i]);
//    for j := 0 to template.Count-1 do begin
//      npc := template[j];
//      AddMessage('  ' + Name(npc));
//    end;
//  end;

  for i := 0 to slRaces.Count -1 do begin
    TList(raceTemplates[i]).Free;
	TList(race_count[i]).Free;
  end;
  race_count.Free;
  raceTemplates.Free;
  slRaces.Free;
  base_records.Free;
  base_records_ents.Free;
  Result := 0;
end;

end.
