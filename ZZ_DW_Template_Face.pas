// How to install:
// 1. Navigate to your Tes5Edit folder, then to the Edit Scripts folder
// 2. Copy this file to this folder

// How to use:
// 1. Load up Tes5Edit
// 2. Select only the "Deadly Wenches.esp" box (you can right-click, select none, and then select Deadly Wenches.esp)
// 2a. (Optionally) Also select USLEP.esp to ensure the script uses USLEP changes when adding to vanilla leveled list
// 3. Wait for background loader to finish
// 4. Right click on any mod and select "Apply Script"
// 5. Select this script and select "OK"
// 6. Wait for the message in the message window [Apply Script done]...
// 6a. If there's an error, let me know
// 7. Double check bolded entries to see if script worked as intended (if you had expanded a group before, you might need to collapse and reexpand it to see new additions)
// 7a. Also let me know if something didn't go right
// 8. Exit and save/discard changes

// How to Configure
// There are three major functions that this script achieves
//   1. Creates "variations" of a template record using IW References           (see setupVariablesForVariation)
//   2. Creates leveled lists with npcs that meet certain filtering criteria    (see setupVariablesForLeveledList)
//   3. Adds existing DW leveled lists to vanilla leveled lists                 (see setupVariablesForVanillaLeveledList)
//
// Each of these functions have a "Template for ...." section that describes how configure the script to your purposes.
//

unit userscript;

var
  slRoleTemplateList, slRoleTemplateNameList, slRoleTemplateEditorIdList, slLevelListName : TStringList;
  lFaceTemplateList, lFullNameFilter, lRaceFilter, lFactionFilter, lEditorIdSubstringFilter, lVanillaLevelList, lVanillaLevelListCount, lVoiceFilter : TList;
  target_file, skyrimFile, dwFile, iwFile : IInterface;
  
  
//---------------------------------------------------------------------------------------
// To Configure
//---------------------------------------------------------------------------------------
procedure setupVariablesForVariations;
var
  i : integer;
  template_index : integer;
  cur_template_faces : TStringList;
  template_editorid, new_base_editorid, new_full_name : string;
begin
  // TStringList and TList Init
  slRoleTemplateList            := TStringList.Create;
  slRoleTemplateEditorIdList    := TStringList.Create;
  slRoleTemplateNameList        := TStringList.Create;
  lFaceTemplateList             := TList.Create;

  //-------------------------------------------------------------------------------------------------------------
  // Template for adding new variation
  //-------------------------------------------------------------------------------------------------------------
  //template_editorid := '';   // Fill in Editor ID of the template NPC record that has all of the relevant stats/traits/perks etc...
  //new_base_editorid := '';   // Fill in the desired "base" Editor ID of the new NPC records generated. New Editor ID = base + '_' + race + variation number
  //new_full_name   := '';     // Fill in the desired FULL name of the new NPC records generated
  //
  //slRoleTemplateList.Add(template_editorid);                      // Just copy this block of code
  //slRoleTemplateEditorIdList.Add(new_base_editorid);
  //slRoleTemplateNameList.Add(new_full_name);
  //lFaceTemplateList.Add(TStringList.Create);
  //template_index := slRoleTemplateList.IndexOf(template_editorid);
  //cur_template_faces := TStringList(lFaceTemplateList[template_index]);
  //
  //cur_template_faces.Add(''); // Add this line and the corresponding Immersive Wench Editor ID that you want to serve as a template (in the TPLT field)
  
  //-------------------------------------------------------------------------------------------------------------
  // Example : Vampire Template
  //-------------------------------------------------------------------------------------------------------------
  template_editorid := 'DW_EncVampire06Template';
  new_base_editorid := 'DW_EncVampire06Test';
  new_full_name     := 'Vampire';
  
  slRoleTemplateList.Add(template_editorid);
  slRoleTemplateEditorIdList.Add(new_base_editorid);
  slRoleTemplateNameList.Add(new_full_name);
  lFaceTemplateList.Add(TStringList.Create);
  template_index := slRoleTemplateList.IndexOf(template_editorid);
  cur_template_faces := TStringList(lFaceTemplateList[template_index]);
                                                                         // Generated NPC Records:
  cur_template_faces.Add('lalawenchnord01_2H_Sultry');                   // DW_EncVampire06Test_NordRace000 "Vampire"
  cur_template_faces.Add('lalawenchnord02_magic');                       // DW_EncVampire06Test_NordRace001 "Vampire"
  cur_template_faces.Add('lalawenchnord03_melee');                       // DW_EncVampire06Test_NordRace002 "Vampire"
  cur_template_faces.Add('lalawenchnord05_necro_Sultry');                // DW_EncVampire06Test_NordRace003 "Vampire"
  cur_template_faces.Add('lalawenchnord06_archer');                      // DW_EncVampire06Test_NordRace004 "Vampire"
  cur_template_faces.Add('lalawenchnord07_2H');                          // DW_EncVampire06Test_NordRace005 "Vampire"
  cur_template_faces.Add('lalawenchZZextradarkelf01_necro');             // DW_EncVampire06Test_DarkElfRace000 "Vampire"
  cur_template_faces.Add('lalawenchZZextradarkelf02_tank_Sultry');       // DW_EncVampire06Test_DarkElfRace001 "Vampire"
  
  
  //-------------------------------------------------------------------------------------------------------------
  // Example : Forsworn Template
  //-------------------------------------------------------------------------------------------------------------
  template_editorid := 'DW_EncForsworn06Melee1Hdualwield00backup';
  new_base_editorid := 'DW_EncForsworn06Melee1HdualwieldTest';
  new_full_name     := 'Forsworn Ravager';
  
  slRoleTemplateList.Add(template_editorid);
  slRoleTemplateEditorIdList.Add(new_base_editorid);
  slRoleTemplateNameList.Add(new_full_name);
  lFaceTemplateList.Add(TStringList.Create);
  template_index := slRoleTemplateList.IndexOf(template_editorid);
  cur_template_faces := TStringList(lFaceTemplateList[template_index]);
                                                                        // Generated NPC Records:
  cur_template_faces.Add('lalawenchbreton01_Melee');                    // DW_EncForsworn06Melee1HdualwieldTest_BretonRace000 "Forsworn Ravager"
  cur_template_faces.Add('lalawenchZZextrabreton05_2H_Sultry');         // DW_EncForsworn06Melee1HdualwieldTest_BretonRace001 "Forsworn Ravager"
  cur_template_faces.Add('lalawenchnord20_2H_Sultry');                  // DW_EncForsworn06Melee1HdualwieldTest_NordRace000 "Forsworn Ravager"
end; 
  
procedure setupVariablesForLeveledList;
var
  cur_full_name_filter, cur_race_filter, cur_faction_filter, cur_editorid_substring_filter, cur_voice_filter : TStringList;
  i, index : integer;
  new_level_list_name : string;
begin
  //TList and TString init
  slLevelListName           := TStringList.Create;
  lFullNameFilter           := TList.Create; 
  lRaceFilter               := TList.Create; 
  lFactionFilter            := TList.Create; 
  lEditorIdSubstringFilter  := TList.Create;  
  lVoiceFilter				:= TList.Create;
  
  // For each leveled list string in slLevelListName, creates a leveled list entry with that name and adds npcs
  // from Deadly Wenches that meet the filters set below
  //-------------------------------------------------------------------------------------------------------------
  // Template for adding new leveled list
  //-------------------------------------------------------------------------------------------------------------
  // new_level_list_name := '';                 // Name of new leveled list
  // 
  // slLevelListName.Add(new_level_list_name);  // Just copy code block
  // lFullNameFilter.Add(TStringList.Create);
  // lRaceFilter.Add(TStringList.Create);
  // lFactionFilter.Add(TStringList.Create);
  // lEditorIdSubstringFilter.Add(TStringList.Create);
  // lVoiceFilter.Add(TStringList.Create);
  // index := slLevelListName.IndexOf(new_level_list_name);                         
  // cur_full_name_filter           := TStringList(lFullNameFilter[index]);  
  // cur_race_filter                := TStringList(lRaceFilter[index]);
  // cur_faction_filter             := TStringList(lFactionFilter[index]);  
  // cur_editorid_substring_filter  := TStringList(lEditorIdSubstringFilter[index]);
  // cur_voice_filter               := TStringList(lVoiceFilter[index]);
  // 
  // cur_full_name_filter.Add('');          // Each line here tells the script to add DW NPCs with these FULL names. Comment out if not using filter.
  //            
  // cur_race_filter.Add('');               // Each line here tells the script to add DW NPCs with these races (using the race EditorID). Comment out if not using filter.
  //    
  // cur_faction_filter.Add('');            // Each line here tells the script to add DW NPCs with these factions (using the faction's Editor ID). Comment out if not using filter.
  // 
  // cur_editorid_substring_filter.Add(''); // Each line here tells the script to add DW NPCs whose EditorID has the given substring. Comment out if not using filter
  //                                        // Example: Imperial Soldiers and Guards have the same full name and faction, but different in EditorIDs (ie DW_EncSoldier vs DW_EncGuard)
  // cur_voice_filter.Add('')               // Each line here tells the script to add DW NPCs with these VTYP Editor ID references. Comment out if not using filter.
  
  //-------------------------------------------------------------------------------------------------------------
  // Example : DW_WenchSubChar_Vampires_Test
  // Setups up variables to return a leveled list containing all DW NPCs part of the Vampire Faction
  //-------------------------------------------------------------------------------------------------------------
  new_level_list_name := 'DW_WenchSubChar_Vampires_Test';   

  slLevelListName.Add(new_level_list_name);
  lFullNameFilter.Add(TStringList.Create);
  lRaceFilter.Add(TStringList.Create);
  lFactionFilter.Add(TStringList.Create);
  lEditorIdSubstringFilter.Add(TStringList.Create);
  lVoiceFilter.Add(TStringList.Create);
  index := slLevelListName.IndexOf(new_level_list_name);                            
  cur_full_name_filter          := TStringList(lFullNameFilter[index]);  
  cur_race_filter               := TStringList(lRaceFilter[index]);
  cur_faction_filter            := TStringList(lFactionFilter[index]);  
  cur_editorid_substring_filter := TStringList(lEditorIdSubstringFilter[index]);
  cur_voice_filter              := TStringList(lVoiceFilter[index]);
  
  //cur_full_name_filter.Add('');                       // No need to filter by FULL name   
            
  //cur_race_filter.Add('NordRace');                    // No need to filter by race
  //cur_race_filter.Add('BretonRace');
  //cur_race_filter.Add('ImperialRace');
  //cur_race_filter.Add('RedguardRace');
  //cur_race_filter.Add('DarkElfRace');
  //cur_race_filter.Add('WoodElfRace');
  //cur_race_filter.Add('HighElfRace');             
                                            
  cur_faction_filter.Add('VampireFaction');             // Filter by VampireFaction
  //cur_faction_filter.Add('BanditFaction');
  //cur_faction_filter.Add('ForswornFaction');
  //cur_faction_filter.Add('CWImperialFaction');
  //cur_faction_filter.Add('CWSonsFaction');
  //cur_faction_filter.Add('VigilantOfStendarrFaction');            

  //cur_editorid_substring_filter.Add('');              // No need to filter by EDID substring
  
  //cur_voice_filter.Add('FemaleCommander');			// No need to filter by VTYP
  //cur_voice_filter.Add('FemaleCommoner');
  //cur_voice_filter.Add('FemaleCondescending');
  //cur_voice_filter.Add('FemaleCoward');
  //cur_voice_filter.Add('FemaleDarkElf');
  //cur_voice_filter.Add('FemaleElfHaughty');
  //cur_voice_filter.Add('FemaleEvenToned');
  //cur_voice_filter.Add('FemaleNord');
  //cur_voice_filter.Add('FemaleSultry');
  //cur_voice_filter.Add('FemaleYoungEager');

  
  //-------------------------------------------------------------------------------------------------------------
  // Example : DW_WenchLCharForsworn_Magic_Test
  // Setups up variables to return a leveled list containing all magical DW NPCs part of the Forsworn Faction
  //-------------------------------------------------------------------------------------------------------------
  new_level_list_name := 'DW_WenchLCharForsworn_Magic_Test';    

  slLevelListName.Add(new_level_list_name);
  lFullNameFilter.Add(TStringList.Create);
  lRaceFilter.Add(TStringList.Create);
  lFactionFilter.Add(TStringList.Create);
  lEditorIdSubstringFilter.Add(TStringList.Create);
  lVoiceFilter.Add(TStringList.Create);
  index := slLevelListName.IndexOf(new_level_list_name);                            
  cur_full_name_filter          := TStringList(lFullNameFilter[index]);  
  cur_race_filter               := TStringList(lRaceFilter[index]);
  cur_faction_filter            := TStringList(lFactionFilter[index]);  
  cur_editorid_substring_filter := TStringList(lEditorIdSubstringFilter[index]);
  cur_voice_filter              := TStringList(lVoiceFilter[index]);
  
  cur_full_name_filter.Add('Forsworn Warmage');         // Add only Forsworn Warmages and Shamans
  cur_full_name_filter.Add('Forsworn Shaman');                          
            
  //cur_race_filter.Add('NordRace');                    // No need to filter by race
  //cur_race_filter.Add('BretonRace');
  //cur_race_filter.Add('ImperialRace');
  //cur_race_filter.Add('RedguardRace');
  //cur_race_filter.Add('DarkElfRace');
  //cur_race_filter.Add('WoodElfRace');
  //cur_race_filter.Add('HighElfRace');             
                                            
  //cur_faction_filter.Add('VampireFaction');           // Filter by ForswornFaction
  //cur_faction_filter.Add('BanditFaction');
  cur_faction_filter.Add('ForswornFaction');
  //cur_faction_filter.Add('CWImperialFaction');
  //cur_faction_filter.Add('CWSonsFaction');
  //cur_faction_filter.Add('VigilantOfStendarrFaction');            

  //cur_editorid_substring_filter.Add('');              // No need to filter by EDID substring
  
  //cur_voice_filter.Add('FemaleCommander');			// No need to filter by VTYP
  //cur_voice_filter.Add('FemaleCommoner');
  //cur_voice_filter.Add('FemaleCondescending');
  //cur_voice_filter.Add('FemaleCoward');
  //cur_voice_filter.Add('FemaleDarkElf');
  //cur_voice_filter.Add('FemaleElfHaughty');
  //cur_voice_filter.Add('FemaleEvenToned');
  //cur_voice_filter.Add('FemaleNord');
  //cur_voice_filter.Add('FemaleSultry');
  //cur_voice_filter.Add('FemaleYoungEager');
  
  //-------------------------------------------------------------------------------------------------------------
  // Example : DW_WenchLCharSoldierImperial_Test
  // Setups up variables to return a leveled list containing all soldier DW NPCs part of the Imperial Faction
  //-------------------------------------------------------------------------------------------------------------
  new_level_list_name := 'DW_WenchLCharSoldierImperial_Test';   

  slLevelListName.Add(new_level_list_name);
  lFullNameFilter.Add(TStringList.Create);
  lRaceFilter.Add(TStringList.Create);
  lFactionFilter.Add(TStringList.Create);
  lEditorIdSubstringFilter.Add(TStringList.Create);
  lVoiceFilter.Add(TStringList.Create);
  index := slLevelListName.IndexOf(new_level_list_name);                            
  cur_full_name_filter          := TStringList(lFullNameFilter[index]);  
  cur_race_filter               := TStringList(lRaceFilter[index]);
  cur_faction_filter            := TStringList(lFactionFilter[index]);  
  cur_editorid_substring_filter := TStringList(lEditorIdSubstringFilter[index]);
  cur_voice_filter              := TStringList(lVoiceFilter[index]);
  
  //cur_full_name_filter.Add('');                       // No need to filter by FULL name       
            
  //cur_race_filter.Add('NordRace');                    // No need to filter by race
  //cur_race_filter.Add('BretonRace');
  //cur_race_filter.Add('ImperialRace');
  //cur_race_filter.Add('RedguardRace');
  //cur_race_filter.Add('DarkElfRace');
  //cur_race_filter.Add('WoodElfRace');
  //cur_race_filter.Add('HighElfRace');             
                                            
  //cur_faction_filter.Add('VampireFaction');           // Filter by CWImperialFaction
  //cur_faction_filter.Add('BanditFaction');
  //cur_faction_filter.Add('ForswornFaction');
  cur_faction_filter.Add('CWImperialFaction');
  //cur_faction_filter.Add('CWSonsFaction');
  //cur_faction_filter.Add('VigilantOfStendarrFaction');            

  cur_editorid_substring_filter.Add('DW_EncSoldier');   // Filter on editor IDs so you don't get Imperial Guards
  
  //cur_voice_filter.Add('FemaleCommander');			// No need to filter by VTYP
  //cur_voice_filter.Add('FemaleCommoner');
  //cur_voice_filter.Add('FemaleCondescending');
  //cur_voice_filter.Add('FemaleCoward');
  //cur_voice_filter.Add('FemaleDarkElf');
  //cur_voice_filter.Add('FemaleElfHaughty');
  //cur_voice_filter.Add('FemaleEvenToned');
  //cur_voice_filter.Add('FemaleNord');
  //cur_voice_filter.Add('FemaleSultry');
  //cur_voice_filter.Add('FemaleYoungEager');
  
  //-------------------------------------------------------------------------------------------------------------
  // Example : DW_WenchSubCharBandit_FemaleNord_magic_Test
  // Setups up variables to return a leveled list containing all magic nord DW NPCs part of the Bandit Faction
  //-------------------------------------------------------------------------------------------------------------
  new_level_list_name := 'DW_WenchSubCharBandit_FemaleNord_magic_Test';     

  slLevelListName.Add(new_level_list_name);
  lFullNameFilter.Add(TStringList.Create);
  lRaceFilter.Add(TStringList.Create);
  lFactionFilter.Add(TStringList.Create);
  lEditorIdSubstringFilter.Add(TStringList.Create);
  lVoiceFilter.Add(TStringList.Create);
  index := slLevelListName.IndexOf(new_level_list_name);                            
  cur_full_name_filter          := TStringList(lFullNameFilter[index]);  
  cur_race_filter               := TStringList(lRaceFilter[index]);
  cur_faction_filter            := TStringList(lFactionFilter[index]);  
  cur_editorid_substring_filter := TStringList(lEditorIdSubstringFilter[index]);
  cur_voice_filter              := TStringList(lVoiceFilter[index]);
  
  cur_full_name_filter.Add('Bandit Mage Marauder');     // Get only mage bandits
  cur_full_name_filter.Add('Bandit Necromancer');
            
  cur_race_filter.Add('NordRace');                      // Filter only nords
  //cur_race_filter.Add('BretonRace');
  //cur_race_filter.Add('ImperialRace');
  //cur_race_filter.Add('RedguardRace');
  //cur_race_filter.Add('DarkElfRace');
  //cur_race_filter.Add('WoodElfRace');
  //cur_race_filter.Add('HighElfRace');             
                                            
  //cur_faction_filter.Add('VampireFaction');           // Filter by BanditFaction
  cur_faction_filter.Add('BanditFaction');
  //cur_faction_filter.Add('ForswornFaction');
  //cur_faction_filter.Add('CWImperialFaction');
  //cur_faction_filter.Add('CWSonsFaction');
  //cur_faction_filter.Add('VigilantOfStendarrFaction');            
  
  //cur_editorid_substring_filter.Add('');              // No need to filter by EDID substring
  
  //cur_voice_filter.Add('FemaleCommander');			// No need to filter by VTYP
  //cur_voice_filter.Add('FemaleCommoner');
  //cur_voice_filter.Add('FemaleCondescending');
  //cur_voice_filter.Add('FemaleCoward');
  //cur_voice_filter.Add('FemaleDarkElf');
  //cur_voice_filter.Add('FemaleElfHaughty');
  //cur_voice_filter.Add('FemaleEvenToned');
  //cur_voice_filter.Add('FemaleNord');
  //cur_voice_filter.Add('FemaleSultry');
  //cur_voice_filter.Add('FemaleYoungEager');
  
  //-------------------------------------------------------------------------------------------------------------
  // Example : DW_WenchSubCharBanditBoss_EventonedTest
  // Setups up variables to return a leveled list containing bandit bosses with even toned voice type
  //-------------------------------------------------------------------------------------------------------------
  new_level_list_name := 'DW_WenchSubCharBanditBoss_EventonedTest';     

  slLevelListName.Add(new_level_list_name);
  lFullNameFilter.Add(TStringList.Create);
  lRaceFilter.Add(TStringList.Create);
  lFactionFilter.Add(TStringList.Create);
  lEditorIdSubstringFilter.Add(TStringList.Create);
  lVoiceFilter.Add(TStringList.Create);
  index := slLevelListName.IndexOf(new_level_list_name);                            
  cur_full_name_filter          := TStringList(lFullNameFilter[index]);  
  cur_race_filter               := TStringList(lRaceFilter[index]);
  cur_faction_filter            := TStringList(lFactionFilter[index]);  
  cur_editorid_substring_filter := TStringList(lEditorIdSubstringFilter[index]);
  cur_voice_filter              := TStringList(lVoiceFilter[index]);
  
  cur_full_name_filter.Add('Bandit Blademaster Marauder');     // Get only mage bandits
  cur_full_name_filter.Add('Bandit Berserker Marauder');
  cur_full_name_filter.Add('Bandit Defender Marauder');
  cur_full_name_filter.Add('Bandit Ranger Marauder');
  cur_full_name_filter.Add('Bandit Warmage Marauder');
  cur_full_name_filter.Add('Bandit Necromancer Marauder');
            
  //cur_race_filter.Add('NordRace');                      // Filter only nords
  //cur_race_filter.Add('BretonRace');
  //cur_race_filter.Add('ImperialRace');
  //cur_race_filter.Add('RedguardRace');
  //cur_race_filter.Add('DarkElfRace');
  //cur_race_filter.Add('WoodElfRace');
  //cur_race_filter.Add('HighElfRace');             
                                            
  //cur_faction_filter.Add('VampireFaction');           // Filter by BanditFaction
  cur_faction_filter.Add('BanditFaction');
  //cur_faction_filter.Add('ForswornFaction');
  //cur_faction_filter.Add('CWImperialFaction');
  //cur_faction_filter.Add('CWSonsFaction');
  //cur_faction_filter.Add('VigilantOfStendarrFaction');            
  
  //cur_editorid_substring_filter.Add('');              // No need to filter by EDID substring
  
  //cur_voice_filter.Add('FemaleCommander');			// No need to filter by VTYP
  //cur_voice_filter.Add('FemaleCommoner');
  //cur_voice_filter.Add('FemaleCondescending');
  //cur_voice_filter.Add('FemaleCoward');
  //cur_voice_filter.Add('FemaleDarkElf');
  //cur_voice_filter.Add('FemaleElfHaughty');
  cur_voice_filter.Add('FemaleEvenToned');
  //cur_voice_filter.Add('FemaleNord');
  //cur_voice_filter.Add('FemaleSultry');
  //cur_voice_filter.Add('FemaleYoungEager');
end;
  
procedure setupVariablesForVanillaLeveledList;
var
  i, template_index : integer;
  dw_lvln_to_distribute : string;
  cur_vanilla_level_lists : TStringList;
  cur_vanilla_level_lists_count : TList;
begin
  lVanillaLevelList := TList.Create;
  lVanillaLevelListCount := TList.Create;
  for i := 0 to slLevelListName.Count-1 do begin
    lVanillaLevelList.Add(TStringList.Create);
    lVanillaLevelListCount.Add(TList.Create);
  end;
  
  //-------------------------------------------------------------------------------------------------------------
  // Template for distributing a dw leveled list created in previous section to vanilla leveled lists
  //-------------------------------------------------------------------------------------------------------------
  //dw_lvln_to_distribute := '';            // Name of DW leveled list to distribute. Assumes name was also used in previous section
  //
  //template_index                := slLevelListName.IndexOf(dw_lvln_to_distribute);    // Just Copy
  //cur_vanilla_level_lists       := TStringList(lVanillaLevelList[template_index]);
  //cur_vanilla_level_lists_count := TList(lVanillaLevelListCount[template_index]);
  //
  //cur_vanilla_level_lists.Add();          // For each vanilla leveled list you want to add the DW lvln to, add the vanilla lvln's editorID and an integer count
  //cur_vanilla_level_lists_count.Add();    // to tell how many times to add the lvln per level number (i.e. if lvln has entries for level 1 and level 9, a count)
  //                                        // of three tells the script to add the dw lvln ref 6 times (3 times for level 1 and 3 times for level 9).
  
  //-------------------------------------------------------------------------------------------------------------
  // Example 1: Distributes the DW_WenchLCharForsworn_Magic_Test from the previous section to three vanilla 
  // lvlns with the counts of 3, 2, and 4 respectively for each level number
  //-------------------------------------------------------------------------------------------------------------
  dw_lvln_to_distribute := 'DW_WenchLCharForsworn_Magic_Test'; 
  
  template_index                := slLevelListName.IndexOf(dw_lvln_to_distribute);
  cur_vanilla_level_lists       := TStringList(lVanillaLevelList[template_index]);
  cur_vanilla_level_lists_count := TList(lVanillaLevelListCount[template_index]);
  
  cur_vanilla_level_lists.Add('LCharDawnguardMelee1HNordF'); 
  cur_vanilla_level_lists_count.Add(3);
  
  cur_vanilla_level_lists.Add('LCharWarlockConjurerDarkElfF');
  cur_vanilla_level_lists_count.Add(2);
  
  cur_vanilla_level_lists.Add('LCharWitchFire');
  cur_vanilla_level_lists_count.Add(4);
end;
  
//--------------------------------------------------------------------------------------------
// Variation Code
//--------------------------------------------------------------------------------------------

// Main loop that iterates through each "variation" group
procedure makeWenches;
var
  i : integer;
  template_str, baseEdid_str, full_str : string;
  slFacesNPCs : TStringList;
begin
    for i := 0 to slRoleTemplateList.Count-1 do begin
        template_str    := slRoleTemplateList[i];
        baseEdid_str    := slRoleTemplateEditorIdList[i];
        full_str        := slRoleTemplateNameList[i];
        slFacesNPCs     := TStringList(lFaceTemplateList[i]);
        makeWenchesFromTemplate(template_str, baseEdid_str, full_str, slFacesNPCs);
    end;
end;

// Handles making each variation record from the template
procedure makeWenchesFromTemplate(template_str, baseEdid_str, full_str : string; slFaceNPCs : TStringList);
var
  template_rec, new_rec, iw_rec : IInterface;
  i : integer;
begin
    template_rec := MainRecordByEditorID(GroupBySignature(dwFile, 'NPC_'), template_str);
    
    for i := 0 to slFaceNPCs.Count-1 do begin
        new_rec := wbCopyElementToFile(template_rec, dwFile, True, True); // Copy as new record
        iw_rec  := MainRecordByEditorID(GroupBySignature(iwFile, 'NPC_'), slFaceNPCs[i]);
        changeRecordEntries(new_rec, iw_rec, baseEdid_str, full_str);
    end;
end;
    
// Hack to avoid counters for the variation number
function getVariationNumber(edid_str : string) : string;
var
    num : integer;
begin
    num := 0;
    while Assigned(MainRecordByEditorID(GroupBySignature(dwFile, 'NPC_'), edid_str + Format('%.*d', [3, num]))) do begin
      num := num + 1;
    end;
    Result := Format('%.*d', [3, num]); //IntToStr(num);
end;
    
// Changes the record entries as seen by the variable s
procedure changeRecordEntries(new_rec, iw_rec : IInterface; baseEdid_str, full_str : string;);
var
  s : string;
  baseEdidWithName : string;
begin

    // Change FULL name
    s := 'FULL';
    SetElementEditValues(new_rec, s, full_str);
    
    // Change Editor ID: baseEdid + '_' + race + variation_number
    s := 'EDID';
    baseEdidWithName := baseEdid_str + '_' + EditorID(LinksTo(ElementBySignature(iw_rec, 'RNAM')));
    SetElementEditValues(new_rec, s, baseEdidWithName + getVariationNumber(baseEdidWithName));

    // Adjust Template Flags to inherit Traits and Attack Data
    s := 'ACBS\Template Flags';
    SetElementNativeValues(new_rec, s, $0801);
    
    // Set template to the Immersive Wench reference
    s := 'TPLT';
    SetElementEditValues(new_rec, s, Name(iw_rec));
    
    // Should be handled by template inheritance but would bug me otherwise
    s := 'RNAM'; // Race
    SetElementEditValues(new_rec, s, GetElementEditValues(iw_rec, s));
    
    s := 'VTCK'; // Voice
    SetElementEditValues(new_rec, s, GetElementEditValues(iw_rec, s));

end;
//--------------------------------------------------------------------------------------------
// Leveled List Code
//--------------------------------------------------------------------------------------------

// Main loop that iterates over every leveled list group
procedure makeDwLevedList;
var
    full_name_filter, race_filter, faction_filter, editorid_substring_filter, voice_filter : TStringList;
    i : integer;
    lvln_name : string;
begin
    for i := 0 to slLevelListName.Count-1 do begin
        lvln_name                   := slLevelListName[i];
        full_name_filter            := TStringList(lFullNameFilter[i]);
        race_filter                 := TStringList(lRaceFilter[i]);
        faction_filter              := TStringList(lFactionFilter[i]);
        editorid_substring_filter   := TStringList(lEditorIdSubstringFilter[i]);
		voice_filter				:= TStringList(lVoiceFilter[i]);
        makeLeveledListFromFilters(lvln_name, full_name_filter, race_filter, faction_filter, editorid_substring_filter, voice_filter);
    end;
end;

function isIncludedByFullFilter(npc : IInterface; filter : TStringList) : boolean;
var
  i : integer;
  isGood : boolean;
begin
  if filter.Count = 0 then begin 
    Result := True;
    Exit;
  end;

  isGood := False;
  //AddMessage('1Next: ' + EditorID(npc));
  for i := 0 to filter.Count-1 do begin
    //AddMessage(EditorID(npc) + ' | ' + EditorID(LinksTo(ElementBySignature(npc, signature))) + ' | ' + filter[i]);
    if GetElementEditValues(npc, 'FULL') = filter[i] then
        isGood := True;
  end;
  Result := isGood;
end;

function isIncludedBySignatureFilter(npc : IInterface; filter : TStringList; signature : string) : boolean;
var
  i : integer;
  isGood : boolean;
begin
  if filter.Count = 0 then begin 
    Result := True;
    Exit;
  end;

  isGood := False;
  //AddMessage('1Next: ' + EditorID(npc));
  for i := 0 to filter.Count-1 do begin
    //AddMessage(EditorID(npc) + ' | ' + EditorID(LinksTo(ElementBySignature(npc, 'RNAM'))) + ' | ' + filter[i]);
    if EditorID(LinksTo(ElementBySignature(npc, signature))) = filter[i] then
        isGood := True;
  end;
  Result := isGood;
end;

function isIncludedByFactionFilter(npc : IInterface; filter : TStringList) : boolean;
var
  i, j : integer;
  isGood : boolean;
  factions, faction : IInterface;
begin
  if filter.Count = 0 then begin 
    Result := True;
    Exit;
  end;

  isGood := False;
  factions := ElementByName(npc, 'Factions');
  //AddMessage('2Next: ' + EditorID(npc));
  for i := 0 to filter.Count-1 do begin
    //AddMessage('Go');
    for j := 0 to Pred(ElementCount(factions)) do begin
        faction := ElementByIndex(factions, j);
        faction := LinksTo(ElementByPath(faction, 'Faction'));
        //AddMessage('>>' + EditorID(faction));
        if EditorID(faction) = filter[i] then begin
          //AddMessage('>>>> it''s good: ' + EditorID + ' | ' + filter[i]);
          isGood := True;
        end;
    end;
  end;
  Result := isGood;
end;

function isIncludedBySubstringFilter(npc : IInterface; filter : TStringList) : boolean;
var
  i : integer;
  isGood : boolean;
begin
  if filter.Count = 0 then begin 
    Result := True;
    Exit;
  end;

  isGood := False;
  //AddMessage('3Next: ' + EditorID(npc));
  for i := 0 to filter.Count-1 do begin
    //AddMessage(EditorID(npc) + ' | ' + filter[i] + ' | ' + IntToStr(pos(filter[i], EditorID(npc))));
    if pos(filter[i], EditorID(npc)) <> 0 then begin
        isGood := True;
    end;
  end;
  Result := isGood;
end;

procedure makeLeveledListFromFilters(lvln_name : string; full_name_filter, race_filter, faction_filter, editorid_substring_filter, voice_filter : TStringList);
var
  lvln_rec : IInterface;
  npcs, npc : IInterface;
  i : integer;
begin
    //AddMessage('LeveledList Name: ' + lvln_name);
    //AddMessage('>>Full Name: ');
    //for i := 0 to full_name_filter.Count-1 do begin
    //  AddMessage('>>>>' + full_name_filter[i]);
    //end;
    //AddMessage('>>Race Name: ');
    //for i := 0 to race_filter.Count-1 do begin
    //  AddMessage('>>>>' + race_filter[i]);
    //end;
    //AddMessage('>>Faction Name: ');
    //for i := 0 to faction_filter.Count-1 do begin
    //  AddMessage('>>>>' + faction_filter[i]);
    //end;
    //AddMessage('>>Substring Name: ');
    //for i := 0 to editorid_substring_filter.Count-1 do begin
    //  AddMessage('>>>>' + editorid_substring_filter[i]);
    //end;
    lvln_rec := createLeveledList(dwFile, lvln_name);
	SetElementNativeValues(lvln_rec, 'LVLF', $3);
	
    npcs := GroupBySignature(dwFile, 'NPC_');
    for i := 0 to Pred(ElementCount(npcs)) do begin
        npc := ElementByIndex(npcs, i);
        
        // Ignore npcs without FULL names (likely a template record)
        if not Assigned(ElementBySignature(npc, 'FULL')) then Continue;
        
        //AddMessage(EditorID(npc));
        // apply filters
        if not isIncludedByFullFilter(npc, full_name_filter) then Continue;
        //AddMessage('Past full filter');
        if not isIncludedBySignatureFilter(npc, race_filter, 'RNAM') then Continue;
        //AddMessage('Past race filter');
        if not isIncludedByFactionFilter(npc, faction_filter) then Continue;
        //AddMessage('Past fact filter');
        if not isIncludedBySubstringFilter(npc,  editorid_substring_filter) then Continue;
        //AddMessage('Past edid filter');
		if not isIncludedBySignatureFilter(npc, voice_filter, 'VTCK') then Continue;

        AddLeveledListEntry(lvln_rec, 1, npc, 1);
    end;
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
//--------------------------------------------------------------------------------------------
// Vanilla Leveled List Code
//--------------------------------------------------------------------------------------------

// Main loop that iterates through each "variation" group
procedure addDwLeveledListToVanilla;
var
  i : integer;
  lvln_lists : TStringList;
  lvln_to_distribute : string;
  lvln_cnts : TList;
begin
    for i := 0 to slLevelListName.Count-1 do begin
        lvln_to_distribute  := slLevelListName[i];
        lvln_lists          := TStringList(lVanillaLevelList[i]);
        lvln_cnts           := TList(lVanillaLevelListCount[i]);
        AddDwLevedListToVanillaLeveledList(lvln_to_distribute, lvln_lists, lvln_cnts);
    end;
end;

function getSignatureMasterRecordFromLoadedFiles(record_name, signature : string) : IInterface;
var
  i : integer;
  f, cur_lvln : IInterface;
  s : string;
begin
  for i := 0 to FileCount - 1 do begin
    f := FileByIndex(i);
    cur_lvln := MainRecordByEditorID(GroupBySignature(f, signature), record_name);
    if Assigned(cur_lvln) then begin
        Result := MasterOrSelf(cur_lvln);
        Exit;
    end;
  end;
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
// Handles making each variation record from the template
procedure AddDwLevedListToVanillaLeveledList(lvln_to_distribute : string; lvln_lists : TStringList; lvln_cnts : TList);
var
  target_lvln, lvln_rec, m_lvln_rec, tar_lvln_rec : IInterface;
  lvln_ents, lvln_ent : IInterface;
  i, j, k, level_num : integer;
  slLevels : TStringList;
begin
    // Get record of lvln to distribute to vanilla lvlns
    target_lvln := MainRecordByEditorID(GroupBySignature(dwFile, 'LVLN'), lvln_to_distribute);
    
    // For each vanilla lvln in the list, add the target lvln with a given count for each level number contained by the vanilla lvln entries
    for i := 0 to lvln_lists.Count-1 do begin
        lvln_rec := getSignatureMasterRecordFromLoadedFiles(lvln_lists[i], 'LVLN');
        m_lvln_rec := MasterOrSelf(lvln_rec);
        
        // If there's not already an override in DW, add one
        if not SameText(GetFileName(GetFile(m_lvln_rec)), 'deadly wenches.esp') then begin
            m_lvln_rec := wbCopyElementToFile(m_lvln_rec, dwFile, False, True);
        end;
        
        tar_lvln_rec := getTargetLeveledListOverride(m_lvln_rec); // Get winning override before DW
        
        // Extract the level numbers used in lvln (i.e. three entries at level 1, three entries at level 9, etc...)
        slLevels := TStringList.Create;
        lvln_ents := ElementByName(tar_lvln_rec, 'Leveled List Entries');
        for j := 0 to Pred(ElementCount(lvln_ents)) do begin
            lvln_ent := ElementByIndex(lvln_ents, j);
            level_num := GetElementEditValues(lvln_ent, 'LVLO\Level');
            if slLevels.IndexOf(level_num) = -1 then
                slLevels.Add(level_num)
        end;
        
        // For each of the level numbers, add a new lvln entry containing a ref to the target lvln for the user-specified number of times.
        for j := 0 to slLevels.Count-1 do begin
            for k := 0 to Integer(lvln_cnts[i])-1 do begin
                AddLeveledListEntry(m_lvln_rec, StrToInt(slLevels[j]), target_lvln, 1);
            end;
        end;
        slLevels.Free;
        //
    end;
end;

//---------------------------------------------------------------------------------------
// Global Variables
//---------------------------------------------------------------------------------------
procedure freeGlobalVariables;
var
  i : integer;
begin
  for i := 0 to slLevelListName.Count-1 do begin
    TStringList(lFullNameFilter[i]).Free;
    TStringList(lRaceFilter[i]).Free;
    TStringList(lFactionFilter[i]).Free;
    TStringList(lEditorIdSubstringFilter[i]).Free;
    TStringList(lVanillaLevelList[i]).Free;
    TList(lVanillaLevelListCount[i]).Free;
  end;
  lFullNameFilter.Free;
  lRaceFilter.Free;
  lFactionFilter.Free;
  lEditorIdSubstringFilter.Free;
  lVanillaLevelList.Free;
  lVanillaLevelListCount.Free;
  
  for i := 0 to slRoleTemplateList.Count-1 do begin
    TStringList(lFaceTemplateList[i]).Free;
  end;
  lFaceTemplateList.Free;
  
  slRoleTemplateList.Free;
  slRoleTemplateNameList.Free;
  slLevelListName.Free;
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
var
  i : integer;
  template_index : integer;
  cur_template_faces : TStringList;
  s : string;
begin

  skyrimFile := getFileObject('Skyrim.esm');
  dwFile := getFileObject('Deadly Wenches.esp');
  iwFile := GetFileObject('Immersive Wenches.esp');
end;

//---------------------------------------------------------------------------------------
// Required Tes5Edit Script Functions
//---------------------------------------------------------------------------------------

// Called before processing
// You can remove it if script doesn't require initialization code
function Initialize: integer;
begin
  setupGlobalVariables;
  setupVariablesForVariations;
  setupVariablesForLeveledList;
  setupVariablesForVanillaLeveledList;
  makeWenches;
  makeDwLevedList;
  addDwLeveledListToVanilla;
  //replaceClass;

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