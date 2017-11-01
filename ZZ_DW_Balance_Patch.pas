unit userscript;

uses mteFunctions;
uses userUtilities;

const
  target_filename = 'Deadly Wenches - Less Deadly Patch.esp';
  
var
  dw_npc_names, template_npc_names, inventory_rec, slMasters, slSignatures, slExclusions, slVampireKeywords : TStringList;
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

// For each npc in npcs
	// Create override
	// Get corresponding template_npc_names and element
	// Copy respective elements from template to override
	// Copy respective FULL name
	//

procedure replaceClass;
var
  i : integer;
  target : integer;
  new_override : IInterface;
  npc, npcs : IInterface;
  template_rec, inven_rec : IInterface;
begin
  npcs := getFileElements('deadly wenches.esp', 'NPC_');
  for i := 0 to Pred(ElementCount(npcs)) do begin
    npc := ElementByIndex(npcs, i);
	
	// Check names
	target := dw_npc_names.IndexOf(GetElementEditValues(npc, 'FULL'));
	//AddMessage(GetElementEditValues(npc, 'FULL'));
	if target = -1 then
	  Continue;
	
	//AddMessage('Passed check!');
	new_override 	:= wbCopyElementToFile(npc, target_file, False, True);
	template_rec 	:= MasterOrSelf(MainRecordByEditorID(GroupBySignature(skyrimFile, 'NPC_'), template_npc_names[target]));
	inven_rec   	:= MainRecordByEditorID(GroupBySignature(dwFile, 'OTFT'), inventory_rec[target]);
	
	if not Assigned(template_rec) then begin
		AddMessage('Template record not assigned! ' + template_npc_names[target]);
		Exit;
	end;
	if not Assigned(inven_rec) then begin
		AddMessage('Inventory record not assigned!' + inventory_rec[target]);
		if not Assigned(dwFile) then AddMessage('DW file not assigned!');
		Exit;
	end;
	
	replaceAttributes(new_override, template_rec, inven_rec);
	handleNonTemplateIssues(new_override);
	
  end;
end;
	
procedure handleNonTemplateIssues(e : IInterface);
var
  s : string;
begin
  if pos('DW_EncSoldier', EditorID(e)) <> 0 then begin
  
	// Adjust ACBS Fields
	s := 'ACBS\Calc min level';
	SetElementEditValues(e, s, '1');
	s := 'ACBS\Calc max level';
	SetElementEditValues(e, s, '50');
  end;
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
	
procedure replaceAttributes(src, target, inven : IInterface);
var
  i : integer;
  elem, elem_tar, elem_src : IInterface;
  s : string;
  s_index : integer;
begin
	// Remove all target elements from record
	for i := Pred(ElementCount(src)) downto 0 do begin
	  elem := ElementByIndex(src, i);
	  s := Name(elem);
	  s_index := slExclusions.IndexOf(s);
	  if s_index <> -1 then Continue;
	  Remove(elem);
	end;
	
	// Add all target elements using the target record
	for i := 0 to Pred(ElementCount(target)) do begin
      elem_tar := ElementByIndex(target, i);
	  s := Name(elem_tar);
	  s_index := slExclusions.IndexOf(s);
	  if s_index <> -1 then Continue;

	  if not Assigned(Signature(elem_tar)) then begin
		elem_src := Add(src, s, False);
	  end else begin
		elem_src := Add(src, Signature(elem_tar), False);
	  end;
	  ElementAssign(elem_src, LowInteger, elem_tar, False);
    end;
    Add(src, 'EDID', False);	
	
	// Mark Inventory
	SetEditValue(ElementByPath(src, 'DOFT'), Name(inven));
	
	// Figure out FULL Name
	SetElementEditValues(src, 'FULL', getNameFromExemplarTemplate(target));
	
	// Handle Vampire keywords
	if isVampire(src) then addKeyword(src, slVampireKeywords);
	
	// Adjust ACBS Fields
	s := 'ACBS\Calc min level';
	SetElementEditValues(src, s, GetElementEditValues(target, s));
	s := 'ACBS\Calc max level';
	SetElementEditValues(src, s, GetElementEditValues(target, s));
	s := 'ACBS\Speed Multiplier';
	SetElementEditValues(src, s, GetElementEditValues(target, s));
	
	// Adjust Template Flags
	s := 'ACBS\Template Flags';
	SetElementNativeValues(src, s, $0801);
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
  dw_npc_names.Free;
  template_npc_names.Free;
  inventory_rec.Free;
  slMasters.Free;
  slSignatures.Free;
  slExclusions.Free;
  slVampireKeywords.Free;
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

  dw_npc_names := TStringList.Create;
  template_npc_names := TStringList.Create;
  inventory_rec := TStringList.Create;
  slSignatures := TStringList.Create;
  
  // Used closes
  dw_npc_names.Add('Bandit Blademaster Marauder');     // 0   Boss 1H
  dw_npc_names.Add('Bandit Berserker Marauder');       // 1   Boss 2H
  dw_npc_names.Add('Bandit Defender Marauder');        // 2   Boss 1H + Shield
  dw_npc_names.Add('Bandit Ranger Marauder');          // 3   Boss Missile
  dw_npc_names.Add('Bandit Warmage Marauder');         // 4   Boss Mage
  dw_npc_names.Add('Bandit Necromancer Marauder');     // 5   Boss Mage
  dw_npc_names.Add('Bandit Crusher Marauder');         // 6   Boss 2H
  dw_npc_names.Add('Bandit Mage Marauder');            // 7   Mage
  dw_npc_names.Add('Bandit Necromancer');              // 8   Mage
  dw_npc_names.Add('Bandit Blademaster');              // 9   1H
  dw_npc_names.Add('Bandit Defender');                 // 10  1H + Shield
  dw_npc_names.Add('Bandit Berserker');                // 11  2H
  dw_npc_names.Add('Bandit Ranger');                   // 12  Missile
  dw_npc_names.Add('Forsworn Ravager');                // 13  1H Dualwield
  dw_npc_names.Add('Forsworn Defender');               // 14  1H Tank
  dw_npc_names.Add('Forsworn Warlord');                // 15  1H Tank (Forsworn Defender Mistake)
  dw_npc_names.Add('Forsworn Crusher');                // 16  2H
  dw_npc_names.Add('Forsworn Ranger');                 // 17  Missile
  dw_npc_names.Add('Forsworn Warmage');                // 18  Mage
  dw_npc_names.Add('Forsworn Shaman');                 // 19 Mage
  dw_npc_names.Add('Imperial Soldier');                // 20
  dw_npc_names.Add('Stormcloak Soldier');              // 21
  dw_npc_names.Add('Vampire');                         // 22
  dw_npc_names.Add('Vigilant of Stendarr');            // 23
  
  // If don't have FULL, need to grab from template's template recursively
  template_npc_names.Add('EncBandit06Boss1HNordF');               // 0 
  template_npc_names.Add('EncBandit06Boss2HNordM');               // 1 
  template_npc_names.Add('EncBandit06Boss1HNordF');               // 2 
  template_npc_names.Add('EncBandit06MissileNordF');              // 3 
  template_npc_names.Add('EncBandit06MagicNordF');    			  // 4 
  template_npc_names.Add('EncBandit06MagicNordF');    			  // 5 
  template_npc_names.Add('EncBandit06Boss2HNordM');               // 6 
  template_npc_names.Add('EncBandit06MagicNordF');    			  // 7 
  template_npc_names.Add('EncBandit06MagicNordF');    			  // 8 
  template_npc_names.Add('EncBandit06Melee1HNordF');    		  // 9 
  template_npc_names.Add('EncBandit06Melee1HTankNordF');          // 10 
  template_npc_names.Add('EncBandit06Melee2HNordF');              // 11
  template_npc_names.Add('EncBandit06MissileNordF');              // 12
  template_npc_names.Add('EncForsworn06Melee1HBretonF01');        // 13
  template_npc_names.Add('EncForsworn06Melee1HBretonF01');        // 14
  template_npc_names.Add('EncForsworn06Melee1HBretonF01');        // 15 
  template_npc_names.Add('EncForsworn06Melee1HBretonF01');        // 16
  template_npc_names.Add('EncForsworn06MissileBretonF01');        // 17
  template_npc_names.Add('EncForsworn06MagicBretonF01');          // 18
  template_npc_names.Add('EncForsworn06MagicBretonF01');          // 19
  template_npc_names.Add('EncGuardImperialM01MaleNordCommander'); // 20
  template_npc_names.Add('EncGuardSonsF01FemaleNord');            // 21
  template_npc_names.Add('EncVampire06NordF');                    // 22
  template_npc_names.Add('EncVigilantOfStendarr05NordF');         // 23
  
  inventory_rec.Add('DW_BanditBossOutfit_2wench_Light'); // 0 
  inventory_rec.Add('DW_BanditBossOutfit_3wench_heavy'); // 1 
  inventory_rec.Add('DW_BanditBossOutfit_2wench_Light'); // 2 
  inventory_rec.Add('DW_BanditBossOutfit_2wench_Light'); // 3 
  inventory_rec.Add('DW_BanditBossOutfit_1wench_Clothes'); // 4 
  inventory_rec.Add('DW_BanditBossOutfit_1wench_Clothes'); // 5 
  inventory_rec.Add('DW_BanditBossOutfit_3wench_heavy'); // 6 
  inventory_rec.Add('DW_BanditMageOutfit_1wench_Clothes'); // 7 
  inventory_rec.Add('DW_BanditMageOutfit_1wench_Clothes'); // 8 
  inventory_rec.Add('DW_BanditMeleeLightOutfit_2wench_Light'); // 9 
  inventory_rec.Add('DW_BanditHTankOutfit_3wench_Heavy'); // 10
  inventory_rec.Add('DW_BanditHMelee2HOutfit_3wench_Heavy'); // 11
  inventory_rec.Add('DW_BanditMissileOutfit_2wench_Light'); // 12
  inventory_rec.Add('DW_ForswornArmorOutfit_2wench_Light'); // 13
  inventory_rec.Add('DW_ForswornArmorOutfit_3wench_Heavy'); // 14
  inventory_rec.Add('DW_ForswornArmorOutfit_3wench_Heavy'); // 15
  inventory_rec.Add('DW_ForswornArmorOutfit_3wench_Heavy'); // 16
  inventory_rec.Add('DW_ForswornArmorOutfit_2wench_Light'); // 17
  inventory_rec.Add('DW_ForswornArmorOutfit_1wench_Clothes'); // 18
  inventory_rec.Add('DW_ForswornArmorOutfit_1wench_Clothes'); // 19
  inventory_rec.Add('DW_GuardImperialOutfit_2wench_Light'); // 20
  inventory_rec.Add('DW_GuardSonsOutfit_2wench_Light'); // 21
  inventory_rec.Add('DW_vampireOutfit_1wench_Clothes'); // 22
  inventory_rec.Add('DW_StendarrOutfit_3wench_Heavy'); // 23
  
  slExclusions := TStringList.Create;
  slExclusions.Add('Record Header');
  slExclusions.Add('EDID - Editor ID');
  slExclusions.Add('OBND - Object Bounds');
  slExclusions.Add('ACBS - Configuration');
  slExclusions.Add('ATKR - Attack Race');
  slExclusions.Add('VTCK - Voice');
  slExclusions.Add('TPLT - Template');
  slExclusions.Add('RNAM - Race');
  slExclusions.Add('DNAM - Player SKills');
  slExclusions.Add('Head Parts');
  slExclusions.Add('HCLF - Hair Color');
  slExclusions.Add('DOFT - Default outfit');
  slExclusions.Add('QNAM - Texture lighting');
  slExclusions.Add('NAM9 - Face morph');
  slExclusions.Add('NAMA - Face parts');
  slExclusions.Add('Tint Layers');
  slExclusions.Add('FTST - Head texture');
  slExclusions.Add('Packages');
  slExclusions.Add('KWDA - Keywords');
  
  slVampireKeywords := TStringList.Create;
  slVampireKeywords.Add('00013794'); //ActorTypeNPC
  slVampireKeywords.Add('00013796'); //ActorTypeUndead
  slVampireKeywords.Add('000A82BB'); //Vampire
  
 //slSignatures.Add
 //EDID
 //OBND
 //ACBS
 //Fa
  
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
  replaceClass;

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

//template_npc_names.Add('EncBandit06Boss1HNordF [NPC_:0003DF08]');                                  // 0 
//template_npc_names.Add('EncBandit06Boss2HNordM [NPC_:0003DF0C]');                                  // 1 
//template_npc_names.Add('EncBandit06Boss1HNordF [NPC_:0003DF08]');                                  // 2 
//template_npc_names.Add('EncBandit06MissileNordF [NPC_:00037C46]');                                 // 3 
//template_npc_names.Add('EncBandit06MagicNordF [NPC_:00039D5D]');    					             // 4 
//template_npc_names.Add('EncBandit06MagicNordF [NPC_:00039D5D]');    					             // 5 
//template_npc_names.Add('EncBandit06Boss2HNordM [NPC_:0003DF0C]');                                  // 6 
//template_npc_names.Add('EncBandit06MagicNordF [NPC_:00039D5D]');    					             // 7 
//template_npc_names.Add('EncBandit06MagicNordF [NPC_:00039D5D]');    					             // 8 
//template_npc_names.Add('EncBandit06Melee1HNordF [NPC_:00039D20]');    				             // 9 
//template_npc_names.Add('EncBandit06Melee1HTankNordF [NPC_:0003DEB2]');                             // 10 
//template_npc_names.Add('EncBandit06Melee2HNordF [NPC_:0003DE69]');                                 // 11
//template_npc_names.Add('EncBandit06MissileNordF [NPC_:00037C46]');                                 // 12
//template_npc_names.Add('EncForsworn06Melee1HBretonF01 [NPC_:0004429E]');                           // 13
//template_npc_names.Add('EncForsworn06Melee1HBretonF01 [NPC_:0004429E]');                           // 14
//template_npc_names.Add('EncForsworn06Melee1HBretonF01 [NPC_:0004429E]');                           // 15 
//template_npc_names.Add('EncForsworn06Melee1HBretonF01 [NPC_:0004429E]');                           // 16
//template_npc_names.Add('EncForsworn06MissileBretonF01 [NPC_:000442A4]');                           // 17
//template_npc_names.Add('EncForsworn06MagicBretonF01 [NPC_:0004429B]');                             // 18
//template_npc_names.Add('EncForsworn06MagicBretonF01 [NPC_:0004429B]');                             // 19
//template_npc_names.Add('EncGuardImperialM01MaleNordCommander "Imperial Soldier" [NPC_:000AA8D4]'); // 20
//template_npc_names.Add('EncGuardSonsF01FemaleNord "Stormcloak Soldier" [NPC_:000AA922]');          // 21
//template_npc_names.Add('EncVampire06NordF [NPC_:0003392F]');                                       // 22
//template_npc_names.Add('EncVigilantOfStendarr05NordF [NPC_:0010C484]');                            // 23

end.