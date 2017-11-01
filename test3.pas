{
  New script template, only shows processed records
  Assigning any nonzero value to Result will terminate script
}
unit userscript;

uses mteFunctions;
uses userUtilities;

const
  target_filename = 'Angry Wenches.esp';
  num_entries_in_lvln = 1;
  no_faction_limit = True;
  
var
  target_file : IInterface;
  slMasters, slRaces, slFactions, slVampireKeywords, exemplarToFakerKey, slFactionsNoRestrictions : TStringList;
  lvlList, exemplarToFakerValue, lvlListNoFactions : TList;

  
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
  //AddMastersMine(target_file, slMasters);
end;


//---------------------------------------------------------------------------------------
// Tes5Edit Manipulation
//---------------------------------------------------------------------------------------
function getTargetFaction(npc : IInterface) : IInterface;
var
  i, j : integer;
  factions, faction : IInterface;
begin
  factions := ElementByName(npc, 'Factions');
  for i:= 0 to Pred(ElementCount(factions)) do begin
    faction := ElementByIndex(factions, i);
    faction := LinksTo(ElementByPath(faction, 'Faction'));
	for j := 0 to slFactions.Count-1 do begin
	  if EditorID(faction) = slFactions[j] then 
	    Result := slFactions[j];
	end;
  end;
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

// Checks DW's leveled list overrides and returns the winning override before DW
// i.e. skyim | dragonborn | Deadly wenches
//            returns ^
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
//---------------------------------------------------------------------------------------
// Template Selection
//---------------------------------------------------------------------------------------
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

procedure createRaceFactionLists;
begin
  if not no_faction_limit then begin
    createRaceFactionListsWithFactionRestrictions;
  end else begin
    createRaceFactionListsWithNoFactionRestrictions;
  end;
end;

procedure createRaceFactionListsWithFactionRestrictions;
var
  i, j : integer;
  lvln_rec : IInterface;
  s : string;
begin
  for i := 0 to slRaces.Count-1 do begin
    for j := 0 to slFactions.Count-1 do begin
		s := 'AW_lvln_' + slRaces[i] + '_' + slFactions[j];
		lvln_rec := createLeveledList(target_file, s);
		if not Assigned(lvln_rec) then begin
		  AddMessage('LVLN File not created: ' + slRaces[i] + ' | ' + slFactions[j]);
		  Exit;
		end;
		TList(lvlList[i]).Add(lvln_rec);
	end;
  end;
end;

procedure createRaceFactionListsWithNoFactionRestrictions;
var
  i, j : integer;
  lvln_rec : IInterface;
  s : string;
begin
  for i := 0 to slRaces.Count-1 do begin
    for j := 0 to slFactionsNoRestrictions.Count-1 do begin
	  s := 'AW_lvln_' + slRaces[i] + '_' + slFactionsNoRestrictions[j];
	  lvln_rec := createLeveledList(target_file, s);
	  if not Assigned(lvln_rec) then begin
	    AddMessage('LVLN File not created: ' + slRaces[i] + ' | ' + slFactionsNoRestrictions[j]);
	    Exit;
	  end;
	  TList(lvlList[i]).Add(lvln_rec);
	end;
  end;
end;

procedure addTemplatesToRaceFactionLists;
var
  i, race, faction : integer;
  npcs, npc, template_npc : IInterface;
  race_rec, lvln_rec : IInterface;
  template_file : IInterface;
  race_list : TList;
  vampire : integer;
begin
  template_file := getOrCreateFile('Deadly Wenches.esp');

  npcs := GroupBySignature(template_file, 'NPC_');
  for i := 0 to Pred(ElementCount(npcs)) do begin
    npc := ElementByIndex(npcs, i);
	template_npc := LinksTo(ElementByPath(npc, 'TPLT'));
	if not Assigned(template_npc) then Continue;
	//BuildRef(template_npc);
	
	// skips records not from IW
	if not SameText(Lowercase(GetFileName(GetFile(template_npc))), 'immersive wenches.esp') then
	  Continue;
	
	// skip records without valid face templates
	if not isValidFaceTemplate(template_npc) then Continue;
	
	// Ignore non-target factions
	faction := slFactions.IndexOf(getTargetFaction(npc));
	if faction = -1 then Continue;
	
	// Ignore non-target races 
	race := slRaces.IndexOf(EditorID(LinksTo(ElementBySignature(npc, 'RNAM'))));
	//if faction = slFactions.IndexOf('VampireFaction') then begin
	//  race := slRaces.IndexOf(EditorID(getBaseRaceFromVampire(npc)));
	//end;
	if race = -1 then Continue;
	
	// Get corresponding lvln record
	race_list := TList(lvlList[race]);
	
	if not no_faction_limit then begin
	  lvln_rec := ObjectToElement(race_list[faction]);
	end else begin
	  if SameText(GetTargetFaction(npc), 'VampireFaction') then vampire := 1 else vampire := 0;
	  lvln_rec := ObjectToElement(race_list[vampire])
	end;
	if not Assigned(lvln_rec) then begin
	  AddMessage('addTemplatesToRaceFactionLists: Warning! Did not retrieve lvln record');
	  Exit;
	end;
	AddLeveledListEntry(lvln_rec, 1, template_npc, 1);
	//AddMessage(EditorID(lvln_rec) + ' | ' + EditorID(npc) + ' | ' + EditorID(template_npc));
	//AddMessage(EditorID(lvln_rec));
  end;
end;


//---------------------------------------------------------------------------------------
// Exemplar Logic
//---------------------------------------------------------------------------------------

procedure getLevedListStats(lvln : IInterface);
var
  llct : IInterface;
begin
  llct := GetElementNativeValues(lvln, 'LLCT');
  if llct = 0 then AddMessage('LVLN: ' + EditorID(lvln) + ' has 0 LLCT');
end;

function getLevedListForFaker(faker : IInterface) : IInterface;
var
  faction, race, vampire : integer;
  tar_lvln : IInterface;
  race_lvlList : TList;
begin
  if not Assigned(faker) then begin
    AddMessage('Warning! Faker is unassigned.');
	Exit;
  end;
  // Ignore non-target factions
  faction := slFactions.IndexOf(getTargetFaction(faker));
  if faction = -1 then Exit;
  
  // Ignore non-target races 
  if SameText(getTargetFaction(faker), 'VampireFaction') then begin
    race := slRaces.IndexOf(EditorID(getBaseRaceFromVampire(faker)));
  end else begin
    race := slRaces.IndexOf(EditorID(LinksTo(ElementBySignature(faker, 'RNAM'))));
  end;
  if race = -1 then Exit;
  
  //getFakerStats(faker);
  
  // Get leveled list
  race_lvlList := TList(lvlList[race]);
  //tar_lvln := ObjectToElement(race_lvlList[faction]);
  if not no_faction_limit then begin
    tar_lvln := ObjectToElement(race_lvlList[faction]);
  end else begin
    if SameText(GetTargetFaction(faker), 'VampireFaction') then vampire := 1 else vampire := 0;
    tar_lvln := ObjectToElement(race_lvlList[vampire])
  end;
  if not Assigned(tar_lvln) then begin
    AddMessage('tar_lvln is not assigned.');
	Exit;
  end;
  getLevedListStats(tar_lvln);
  Result := tar_lvln;
end;

procedure getFakerStats(faker : IInterface);
begin
  AddMessage(EditorID(faker));
  AddMessage('>>Faction: ' + getTargetFaction(faker));
  AddMessage('>>RaceB: ' + EditorID(LinksTo(ElementBySignature(faker, 'RNAM'))));
  AddMessage('>>RaceV: ' + EditorID(getBaseRaceFromVampire(faker)));
end;

procedure handleVampireFakers(faker : IInterface);
var
  race_rec : IInterface;
  s : string;
begin
  if not Assigned(faker) then begin
    AddMessage('Warning! Faker is unassigned.');
	Exit;
  end;
  if not SameText(getTargetFaction(faker), 'VampireFaction') then Exit;
  
  // Set race to non-vampire race
  s := 'RNAM';
  race_rec := getBaseRaceFromVampire(faker);
  SetEditValue(ElementByPath(faker, s), Name(race_rec));
  
  // Assign keywords to handle not being a "vampire" race
  addKeyword(faker, slVampireKeywords);
end;


function getNameFromExemplarTemplate(exemplar : IInterface) : string;
var
  cur_rec : IInterface;
  hasParent : boolean;
begin
  cur_rec := exemplar;
  hasParent := false;
  repeat
    if Assigned(ElementBySignature(cur_rec, 'FULL')) then 
	  Break;
	hasParent := Assigned(ElementBySignature(cur_rec, 'TPLT'));
	cur_rec := LinksTo(ElementBySignature(cur_rec, 'TPLT'));
  until not hasParent;
  
  if Assigned(ElementBySignature(cur_rec, 'FULL')) then 
    Result := GetElementEditValues(cur_rec, 'FULL');
end;

function createFakerFromExemplar(exemplar : IInterface) : IInterface;
var
  faker, lvln : IInterface;
  s : string;
begin
  if not Assigned(exemplar) then begin
    AddMessage('Warning! Exemplar is unassigned.');
	Exit;
  end;
  faker := wbCopyElementToFile(exemplar, target_file, true, true);
  if not Assigned(faker) then begin
    AddMessage('Warning! Faker not copied from exemplar');
  end;
  
  s := 'EDID';
  SetElementEditValues(faker, 'EDID', 'AW_' + GetElementEditValues(exemplar, 'EDID'));
  
  s := 'FULL';
  //SetElementEditValues(faker, 'FULL', getNameFromExemplarTemplate(exemplar));
  SetElementEditValues(faker, 'FULL', 'AW_' + GetElementEditValues(exemplar, 'EDID'));
  
  
  // Use only the traits (i.e. appearance) from the template
  s := 'ACBS\Template Flags';
  SetElementNativeValues(faker, s, $0001); // Only use leveled lists traits
  
  // Set template to the lvln for "template" appearances
  s := 'TPLT';
  lvln := getLevedListForFaker(faker);
  SetEditValue(ElementByPath(faker, s), Name(lvln));
  
  // Handle Faction-related issues
  handleVampireFakers(faker);
  
  // Add faker to exemplarToFaker map
  exemplarToFakerKey.Add(EditorID(exemplar));
  //AddMessage('+++' + EditorID(exemplar));
  exemplarToFakerValue.Add(faker);
  Result := faker;
end;

function getFakerFromExemplar(exemplar : IInterface) : IInterface;
var
  tar_index : integer;
  faker : IInterface;
begin
  if not Assigned(exemplar) then begin
    AddMessage('Warning! Exemplar is unassigned.');
	Exit;
  end;
  
  // Retrieve existing faker or create a new one if no fakers
  tar_index := exemplarToFakerKey.IndexOf(EditorID(exemplar));
  if tar_index=-1 then begin
    //AddMessage('Creating Faker...');
    faker := createFakerFromExemplar(exemplar);
  end else begin
    //AddMessage('Retrieving Faker...');
    faker := ObjectToElement(exemplarToFakerValue[tar_index]);
  end;
  
  if not (SameText('AW_' + EditorID(exemplar), EditorID(faker))) then begin
    AddMessage('Mismatch: ');
	AddMessage('+Exemplar: ' + EditorID(exemplar));
	AddMessage('+Faker   : ' + EditorID(faker));
  end;
  Result := faker;
end;

procedure createExemplarsFromLeveledList(m : IInterface);
var
  i, j : integer;
  lvln_ents, lvln_ent, exemplar : IInterface;
  new_override, faker : IInterface;
  isEdited : boolean;
begin
  // Iterate through all leveled list entries
  isEdited := false;
  lvln_ents := ElementByName(m, 'Leveled List Entries');
  for i := 0 to Pred(ElementCount(lvln_ents)) do begin
    lvln_ent := ElementByIndex(lvln_ents, i);
    exemplar := LinksTo(ElementByPath(lvln_ent, 'LVLO\Reference'));
	//AddMessage('===' + EditorID(exemplar) + '===');
    
    // Only make exemplar from female NPCs
    if Signature(exemplar) <> 'NPC_' then Continue;
    if GetElementNativeValues(exemplar, 'ACBS\Flags') and 1 <> 1 then Continue;
    
	
    // Create lvln override for new plugin
    if not isEdited then begin
      new_override := wbCopyElementToFile(m, target_file, False, True);
  	  isEdited := true;
    end;
    
	//AddMessage('isExemplar!');
	
	// Get Faker
	faker := getFakerFromExemplar(exemplar);
	if not Assigned(faker) then begin
	  AddMessage('Faker not retrieved');
	  AddMessage('>> Exemplar: ' + EditorID(exemplar));
	  Exit;
	end;
	
    if not (SameText('AW_' + EditorID(exemplar), EditorID(faker))) then begin
      AddMessage('Mismatch: ');
  	  AddMessage('+Exemplar: ' + EditorID(exemplar));
  	  AddMessage('+Faker   : ' + EditorID(faker));
    end;
	
	
	
	// For up to global constant, add a lvln entry to the lvln with the same fields as the exemplar
    for j := 1 to num_entries_in_lvln do begin
      AddLeveledListEntry(new_override, GetElementNativeValues(lvln_ent, 'LVLO\Level'), faker, GetElementNativeValues(lvln_ent, 'LVLO\Count'));
	  //AddMessage('New Entry:');
	  //AddMessage('>> LVLN    : ' + EditorID(m));
	  //AddMessage('>> Level   : ' + IntToStr(GetElementNativeValues(lvln_ent, 'LVLO\Level')));
	  //AddMessage('>> EditorID: ' + EditorID(faker));
	  //AddMessage('>> Count   : ' + IntToStr(GetElementNativeValues(lvln_ent, 'LVLO\Count')));
	  //AddMessage('>> Exemplar: ' + EditorID(exemplar));
    end;
    
  end;
end;

procedure addFakers;
var
  i : integer;
  m_lvln, lvln, lvlns : IInterface;
begin
  // Iterate through modified leveled lists from DW
  lvlns := getFileElements('deadly wenches.esp', 'LVLN');
  for i := 0 to Pred(ElementCount(lvlns)) do begin
	lvln := ElementByIndex(lvlns, i);
	
	// Only deal with LVLN that were modified
	if IsMaster(lvln) then begin
	  //AddMessage('Skipped: ' + EditorID(lvln));
	  Continue;
	end;
	//AddMessage('Getting override');
	m_lvln := getTargetLeveledListOverride(lvln);
	
	//AddMessage('Creating exemplars');
	createExemplarsFromLeveledList(m_lvln);
  end;
end;


//---------------------------------------------------------------------------------------
// Setup
//---------------------------------------------------------------------------------------

procedure setupGlobalVariables;
var
  i : integer;
begin
  slMasters := TStringList.Create;
  slMasters.Add('Skyrim.esm');
  slMasters.Add('Update.esm');
  slMasters.Add('Dawnguard.esm');
  slMasters.Add('Dragonborn.esm');
  slMasters.Add('Unofficial Skyrim Legendary Edition Patch.esp');
  slMasters.Add('Immersive Wenches.esp');
  
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
  
  slFactions := TStringList.Create;
  slFactions.Add('VampireFaction');
  slFactions.Add('BanditFaction');
  slFactions.Add('ForswornFaction');
  slFactions.Add('VigilantOfStendarrFaction');
  slFactions.Add('CWImperialFaction');
  slFactions.Add('CWSonsFaction');
  // Dawnguard
  // 
  //slFactions.Add('');
  
  slVampireKeywords := TStringList.Create;
  slVampireKeywords.Add('00013796'); //ActorTypeUndead
  slVampireKeywords.Add('000A82BB'); //Vampire
  
  slFactionsNoRestrictions := TStringList.Create;
  slFactionsNoRestrictions.Add('NonVampire');
  slFactionsNoRestrictions.Add('Vampire');
  
  lvlList := TList.Create;
  for i := 0 to slRaces.Count-1 do begin
    lvlList.Add(TList.Create);
  end;
  
  lvlListNoFactions := TList.Create;
  for i := 0 to slRaces.Count-1 do begin
    lvlListNoFactions.Add(TList.Create);
  end;
  
  exemplarToFakerKey := TStringList.Create;
  exemplarToFakerValue := TList.Create;
end;

procedure freeGlobalVariables;
var
  i : integer;
begin
  //printStringList(exemplarToFakerKey, 'exemplarToFakerKey');

  // arrays first
  for i := 0 to slRaces.Count-1 do begin
	TList(lvlList[i]).Free;
  end;

  for i := 0 to slRaces.Count-1 do begin
    TList(lvlListNoFactions[i]).Free;
  end;
  
  // single variables last
  slMasters.Free;
  slRaces.Free;
  slFactions.Free;
  lvlList.Free;
  slVampireKeywords.Free;
  slFactionsNoRestrictions.Free;
  
  exemplarToFakerKey.Free;
  exemplarToFakerValue.Free;
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
  createRaceFactionLists;
  addTemplatesToRaceFactionLists;
  addFakers;
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
end;

end.
