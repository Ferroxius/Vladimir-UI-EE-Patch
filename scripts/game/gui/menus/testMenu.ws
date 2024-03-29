/***********************************************************************/
/** 	© 2015 CD PROJEKT S.A. All rights reserved.
/** 	THE WITCHER® is a trademark of CD PROJEKT S. A.
/** 	The Witcher game is based on the prose of Andrzej Sapkowski.
/***********************************************************************/
exec function reqmenu(menu:name)
{
	theGame.RequestMenu( menu );
}

class CR4TestMenu extends CR4MenuBase
{
	private var entityTemplateIndex : int;			default entityTemplateIndex = 0;
	private var appearanceIndex : int;				default appearanceIndex = 0;
	private var environmentDefinitionIndex : int;	default environmentDefinitionIndex = 0;
	private var entityTemplates : array< name >;
	private var appearances : array< name >;
	private var environmentDefinitions : array< string >;
	private var cameraRotation : EulerAngles;
	private var lookAtPos : Vector;
	private var sunRotation : EulerAngles;
	private var cameraDistance : float;
	
	private var m_fxunitToName : CScriptedFlashFunction;
	
	
	
	event  OnConfigUI()
	{
		var i							: int;
		var tempCreatures				: array<CJournalBase>;
		var creatureTemp				: CJournalCreature;
		var status						: EJournalStatus;
		super.OnConfigUI();
		
		m_initialSelectionsToIgnore = 2;
		
		m_fxunitToName = m_flashModule.GetMemberFlashFunction("convertToName");
		
		theGame.GetJournalManager().GetActivatedOfType( 'CJournalCreature', tempCreatures );
		
		for( i = 0; i < tempCreatures.Size(); i += 1 )
		{
			creatureTemp = (CJournalCreature)tempCreatures[i];
			if( creatureTemp )
			{
				entityTemplates.PushBack(creatureTemp.GetUniqueScriptTag()); 
			}
		}
		
		environmentDefinitions.PushBack( "dlc\vhud\data\environment\definitions\gui_bestiary_display\gui_bestiary_environment.env" );
		
		theGame.GetGuiManager().SetBackgroundTexture( LoadResource( "inventory_background" ) );
		
		UpdateEntityTemplate();
		UpdateEnvironmentAndSunRotation();
		UpdateItems();
	}

	event  OnClosingMenu()
	{
		var i : int;
		theInput.RestoreContext( 'EMPTY_CONTEXT', false );
		
		for( i = 0; i < stringarray.Size(); i += 1 )
		{
			LogChannel( 'VHUD', stringarray[i] );
		}
		
	}
	
	event  OnCameraUpdate( lookAtX : float, lookAtY : float, lookAtZ : float, cameraYaw : float, cameraPitch : float, _cameraDistance : float )
	{
		var fov : float;
		
		fov = 35.0f;
		
		lookAtPos.X = lookAtX;
		lookAtPos.Y = lookAtY;
		lookAtPos.Z = lookAtZ;
		
		cameraRotation.Yaw = cameraYaw;
		cameraRotation.Pitch = cameraPitch;
		cameraRotation.Roll = 0;
		
		cameraDistance = _cameraDistance;
		
		theGame.GetGuiManager().SetupSceneCamera( lookAtPos, cameraRotation, cameraDistance, fov );
	}
	
	event  OnSunUpdate( sunYaw : float, sunPitch : float )
	{
		sunRotation.Yaw = sunYaw;
		sunRotation.Pitch = sunPitch;
		UpdateEnvironmentAndSunRotation();
	}

	event  OnNextEntityTemplate()
	{
		var creature : CJournalCreature;
		
		creature = (CJournalCreature)theGame.GetJournalManager().GetEntryByTag( entityTemplates[ entityTemplateIndex ] );
		
		
		m_fxunitToName.InvokeSelfOneArg( FlashArgUInt( NameToFlashUInt( entityTemplates[entityTemplateIndex] ) ) );
		entityTemplateIndex += 1;
		entityTemplateIndex = entityTemplateIndex % entityTemplates.Size();
		
		
		UpdateEntityTemplate();
		
		if( entityTemplateIndex == 0 )
		{
			UpdateItems();
		}
		
	}

	event  OnNextAppearance()
	{
		appearanceIndex += 1;
		appearanceIndex = appearanceIndex % appearances.Size();
		
		UpdateApperance();
	}

	event  OnNextEnvironmentDefinition()
	{
		environmentDefinitionIndex += 1;
		environmentDefinitionIndex = environmentDefinitionIndex % environmentDefinitions.Size();

		UpdateEnvironmentAndSunRotation();
	}

	event  OnCloseMenu()
	{
		CloseMenu();
	}
	
	event  OnCloseMenuTemp()
	{
		CloseMenu();
	}

	protected function UpdateEntityTemplate()
	{
		var template : CEntityTemplate;
		var templatepath : string;
		var creature : CJournalCreature;
		
		creature = (CJournalCreature)theGame.GetJournalManager().GetEntryByTag( entityTemplates[ entityTemplateIndex ] );
		templatepath = creature.GetEntityTemplateFilename();
		
		template = ( CEntityTemplate )LoadResource( "dlc\bob\data\quests\main_npcs\dettlaff_van_eretein_vampire.w2ent", true );
		if ( template )
		{
			theGame.GetGuiManager().SetSceneEntityTemplate( template, 'locomotion_idle' );
		}
		m_flashValueStorage.SetFlashString("test.entityTemplate", entityTemplates[ entityTemplateIndex ] + " (" + (entityTemplateIndex+1) + "/" + entityTemplates.Size() + ")" );
	}
	
	protected function UpdateApperance()
	{
		theGame.GetGuiManager().ApplyAppearanceToSceneEntity( appearances[ appearanceIndex ] );
	}
	
	protected function UpdateItems()
	{
		var inventory : CInventoryComponent;
		var enhancements : array< SGuiEnhancementInfo >;
		var info : SGuiEnhancementInfo;
		var enhancementNames : array< name >;
		var items : array< name >;
		var witcher : W3PlayerWitcher;
		var i, j : int;
		var itemsId : array< SItemUniqueId >;
		var itemId : SItemUniqueId;
		var itemName : name;

		inventory = thePlayer.GetInventory();
		if ( inventory )
		{
			inventory.GetHeldAndMountedItems( itemsId );
			
			witcher = (W3PlayerWitcher) thePlayer;
			if ( witcher )
			{
				witcher.GetMountableItems( itemsId );
			}
			
			for ( i = 0; i < itemsId.Size(); i += 1 )
			{
				itemId = itemsId[i];
				itemName = inventory.GetItemName( itemId );
				
				items.PushBack( itemName );
				
				inventory.GetItemEnhancementItems( itemId, enhancementNames );
				for ( j = 0; j < enhancementNames.Size(); j += 1 )
				{
					info.enhancedItem = itemName;
					info.enhancement = enhancementNames[j];
					enhancements.PushBack( info );
				}
			}
			
		}
	}

	protected function UpdateEnvironmentAndSunRotation()
	{
		var environment : CEnvironmentDefinition;
		environment = ( CEnvironmentDefinition )LoadResource( environmentDefinitions[ environmentDefinitionIndex ], true );
		if ( environment )
		{
			theGame.GetGuiManager().SetSceneEnvironmentAndSunPosition( environment, sunRotation );
			m_flashValueStorage.SetFlashString("test.environmentDefinition", environmentDefinitions[ environmentDefinitionIndex ] );
		}
	}
	
	private var stringarray : array< string >;
	
	event OnGetName( tag : name )
	{
		var str : string;
		var creature : CJournalCreature;
		
		creature = (CJournalCreature)theGame.GetJournalManager().GetEntryByTag( tag );
		
		str = (string)creature.GetNameStringId() + 
		";" + NoTrailZeros( RoundTo(cameraRotation.Yaw,1) ) +
		";" + NoTrailZeros( RoundTo(cameraRotation.Pitch,1) ) +
		";" + NoTrailZeros( RoundTo(cameraDistance,1) ) +
		";" + NoTrailZeros( RoundTo(lookAtPos.X,1) ) +
		";" + NoTrailZeros( RoundTo(lookAtPos.Y,1) ) +
		";" + NoTrailZeros( RoundTo(lookAtPos.Z,1) ) +
		";" + NoTrailZeros( RoundTo(sunRotation.Yaw,1) ) +
		";" + NoTrailZeros( RoundTo(sunRotation.Pitch,1) ) +
		";" + GetLocStringById( creature.GetNameStringId() );
		
		stringarray.PushBack(str);	
	}
}

exec function testmenu()
{
	theGame.RequestMenu('TestMenu');
}

exec function testmenu_transform(x : float, y : float, z : float, scale : float)
{
	var position:Vector;
	var _scale:Vector;
	var rotation:EulerAngles;
	
	position.X = x;
	position.Y = y;
	position.Z = z;
	
	_scale.X = scale;
	_scale.Y = scale;
	_scale.Z = scale;
	
	theGame.GetGuiManager().SetEntityTransform(position, rotation, _scale);
}


exec function logenvs()
{
	var i : int;
	var envs : array< string >;
	
	GetActiveAreaEnvironmentDefinitions(envs);
	
	for( i=0;i<envs.Size();i+=1)
	{
		LogChannel( 'VHUD', envs[i] );
	}
}


exec function addentstolist()
{
	var list 			: C2dArray;
	var i, j, k 		: int;
	var tempCreatures	: array<CJournalBase>;
	var creatureTemp	: CJournalCreature;
	
	theGame.GetJournalManager().GetActivatedOfType( 'CJournalCreature', tempCreatures );
	list = LoadCSV( "dlc\vhud\data\gameplay\globals\camLogs.csv" );
	
	for( i = 0; i < list.GetNumRows(); i += 1 )
	{
		for( j = 0; j < tempCreatures.Size(); j += 1 )
		{
			creatureTemp = (CJournalCreature)tempCreatures[j];
			if( creatureTemp )
			{
				if( (string)creatureTemp.GetNameStringId() == list.GetValue( "locNameId", i ) )
				{
					LogChannel( 'VHUD',
					list.GetValue( "locNameId", i ) + ";" +
					list.GetValue( "camYaw", i ) + ";" +
					list.GetValue( "camPitch", i ) + ";" +
					list.GetValue( "camDist", i ) + ";" +
					list.GetValue( "lookX", i ) + ";" +
					list.GetValue( "lookY", i ) + ";" +
					list.GetValue( "lookZ", i ) + ";" +
					list.GetValue( "sunYaw", i ) + ";" +
					list.GetValue( "sunPitch", i ) + ";" +
					creatureTemp.GetEntityTemplateFilename() + ";" +
					list.GetValue( "appearanceName", i ) + ";" +
					list.GetValue( "effectOn", i ) + ";" +
					list.GetValue( "locName", i )
					);
				}
			}
		}
	}
}

function getbestent() : array< string >
{
	var ent : array< string >;
	ent.PushBack( "characters\npc_entities\monsters\ghoul_lvl1.w2ent" );                                                           
	ent.PushBack( "characters\npc_entities\monsters\gryphon_lvl1.w2ent" );                                                         
	ent.PushBack( "characters\npc_entities\monsters\drowner_lvl1.w2ent" );                                                         
	ent.PushBack( "characters\npc_entities\monsters\wild_dog_lvl1.w2ent" );                                                        
	ent.PushBack( "characters\npc_entities\monsters\noonwraith_lvl1.w2ent" );                                                      
	ent.PushBack( "quests\minor_quests\prologue_village\quest_files\mq0003_freshwater\characters\mq0003_noonwraith.w2ent" );       
	ent.PushBack( "characters\npc_entities\monsters\wolf_lvl1.w2ent" );                                                            
	ent.PushBack( "characters\npc_entities\monsters\nightwraith_lvl1.w2ent" );                                                     
	ent.PushBack( "characters\npc_entities\monsters\_quest__noonwright_pesta.w2ent" );                                             
	ent.PushBack( "characters\npc_entities\monsters\rotfiend_lvl1.w2ent" );                                                        
	ent.PushBack( "characters\npc_entities\monsters\nekker_lvl1.w2ent" );                                                          
	ent.PushBack( "characters\npc_entities\monsters\werewolf_lvl1.w2ent" );                                                        
	ent.PushBack( "characters\npc_entities\monsters\werewolf_lvl3__lycan.w2ent" );                                                 
	ent.PushBack( "characters\npc_entities\monsters\wraith_lvl1.w2ent" );                                                          
	ent.PushBack( "characters\npc_entities\monsters\golem_lvl1.w2ent" );                                                           
	ent.PushBack( "characters\npc_entities\monsters\gargoyle_lvl1.w2ent" );                                                        
	ent.PushBack( "characters\npc_entities\monsters\wildhunt_minion_lvl1.w2ent" );                                                 
	ent.PushBack( "characters\npc_entities\monsters\bear_berserker_lvl1.w2ent" );                                                  
	ent.PushBack( "characters\npc_entities\monsters\_quest__miscreant.w2ent" );                                                    
	ent.PushBack( "characters\npc_entities\monsters\wyvern_lvl1.w2ent" );                                                          
	ent.PushBack( "characters\npc_entities\monsters\harpy_lvl1.w2ent" );                                                           
	ent.PushBack( "characters\npc_entities\monsters\hag_water_lvl1.w2ent" );                                                       
	ent.PushBack( "characters\npc_entities\monsters\_quest__godling.w2ent" );                                                      
	ent.PushBack( "characters\npc_entities\monsters\vampire_ekima_lvl1.w2ent" );                                                   
	ent.PushBack( "quests\minor_quests\novigrad\quest_files\mq3037_sleeping_vampire\characters\mq3037_vampire_man.w2ent" );        
	ent.PushBack( "characters\npc_entities\monsters\endriaga_lvl1__worker.w2ent" );                                                
	ent.PushBack( "characters\npc_entities\monsters\_quest__witch_1.w2ent" );                                                      
	ent.PushBack( "characters\npc_entities\monsters\bear_lvl1__black.w2ent" );                                                     
	ent.PushBack( "characters\npc_entities\monsters\lessog_lvl1.w2ent" );                                                          
	ent.PushBack( "characters\npc_entities\monsters\fogling_lvl1.w2ent" );                                                         
	ent.PushBack( "quests\generic_quests\novigrad\quest_files\mh305_doppler\characters\mh305_doppler_02.w2ent" );                  
	ent.PushBack( "characters\npc_entities\monsters\vampire_katakan_lvl1.w2ent" );                                                 
	ent.PushBack( "characters\npc_entities\monsters\elemental_dao_lvl1.w2ent" );                                                   
	ent.PushBack( "characters\npc_entities\monsters\ice_giant.w2ent" );                                                            
	ent.PushBack( "characters\npc_entities\monsters\bies_lvl1.w2ent" );
	ent.PushBack( "quests\sidequests\skellige\quest_files\sq202_yen\characters\sq202_siren.w2ent" );
	ent.PushBack( "characters\npc_entities\monsters\troll_cave_lvl3__ice.w2ent" );
	ent.PushBack( "characters\npc_entities\monsters\troll_cave_lvl1.w2ent" );
	ent.PushBack( "characters\npc_entities\monsters\harpy_lvl3__erynia.w2ent" );
	ent.PushBack( "gameplay\templates\characters\npcs\test_enemies\enemy_succubus.w2ent" );
	ent.PushBack( "quests\generic_quests\novigrad\quest_files\mh303_succubus\characters\mh303_succbus_v2.w2ent" );
	ent.PushBack( "characters\npc_entities\monsters\cyclop_lvl1.w2ent" );
	ent.PushBack( "characters\npc_entities\monsters\alghoul_lvl1.w2ent" );
	ent.PushBack( "characters\npc_entities\monsters\cockatrice_lvl1.w2ent" );
	ent.PushBack( "quests\generic_quests\no_mans_land\quest_files\mh101_cockatrice\characters\mh101_cockatrice.w2ent" );
	ent.PushBack( "characters\npc_entities\monsters\_quest__him.w2ent" );
	ent.PushBack( "characters\npc_entities\monsters\golem_lvl2__ifryt.w2ent" );
	ent.PushBack( "quests\generic_quests\skellige\quest_files\mh207_wraith\characters\mh207_expationer_v2.w2ent" );
	ent.PushBack( "characters\npc_entities\monsters\czart_lvl1.w2ent" );
	ent.PushBack( "characters\npc_entities\monsters\hag_grave_lvl1.w2ent" );
	ent.PushBack( "characters\npc_entities\monsters\endriaga_lvl2__tailed.w2ent" );
	ent.PushBack( "characters\npc_entities\monsters\arachas_lvl3__poison.w2ent" );
	ent.PushBack( "characters\npc_entities\monsters\elemental_dao_lvl3__ice.w2ent" );
	ent.PushBack( "characters\npc_entities\monsters\forktail_lvl1.w2ent" );
	ent.PushBack( "dlc\ep1\data\characters\npc_entities\monsters\toad.w2ent" );
	ent.PushBack( "characters\npc_entities\monsters\basilisk_lvl1.w2ent" );
	ent.PushBack( "dlc\ep1\data\characters\npc_entities\monsters\black_spider.w2ent" );
	ent.PushBack( "dlc\ep1\data\characters\npc_entities\monsters\wild_boar_ep1.w2ent" );
	ent.PushBack( "dlc\bob\data\characters\npc_entities\monsters\wild_boar_ep2.w2ent" );
	ent.PushBack( "quests\generic_quests\novigrad\quest_files\mh306_dao\characters\mh306_dao.w2ent" );
	ent.PushBack( "dlc\ep1\data\characters\npc_entities\secondary_npc\caretaker.w2ent" );
	ent.PushBack( "dlc\ep1\data\characters\npc_entities\monsters\nightwraith_iris.w2ent" );
	ent.PushBack( "dlc\ep1\data\characters\npc_entities\monsters\ethernal.w2ent" );
	ent.PushBack( "dlc\bob\data\quests\main_npcs\dettlaff_van_eretein_vampire.w2ent" );
	ent.PushBack( "dlc\bob\data\characters\npc_entities\monsters\q701_dagonet_giant.w2ent" );
	ent.PushBack( "dlc\bob\data\characters\npc_entities\monsters\gravier.w2ent" );
	ent.PushBack( "dlc\bob\data\characters\npc_entities\monsters\echinops_normal.w2ent" );
	ent.PushBack( "dlc\bob\data\characters\npc_entities\monsters\bruxa.w2ent" );
	ent.PushBack( "dlc\bob\data\quests\main_quests\quest_files\q701_wine_festival\characters\q701_bruxa.w2ent" );
	ent.PushBack( "dlc\bob\data\characters\npc_entities\monsters\sharley.w2ent" );
	ent.PushBack( "dlc\bob\data\characters\npc_entities\monsters\sharley_q701.w2ent" );
	ent.PushBack( "dlc\bob\data\quests\main_npcs\dettlaff_van_eretein_vampire.w2ent" );
	ent.PushBack( "dlc\bob\data\quests\minor_quests\quest_files\mq7002_stubborn_knight\characters\mq7002_springgan.w2ent" );
	ent.PushBack( "dlc\bob\data\characters\npc_entities\monsters\scolopendromorph.w2ent" );
	ent.PushBack( "dlc\bob\data\characters\npc_entities\monsters\mq7023_albino_centipede.w2ent" );
	ent.PushBack( "dlc\bob\data\quests\minor_quests\quest_files\mq7018_last_one\characters\mq7018_basilisk.w2ent" );
	ent.PushBack( "dlc\bob\data\characters\npc_entities\monsters\panther_black.w2ent" );
	ent.PushBack( "dlc\bob\data\characters\npc_entities\monsters\fleder.w2ent" );
	ent.PushBack( "dlc\bob\data\characters\npc_entities\monsters\bruxa_alp.w2ent" );
	ent.PushBack( "dlc\bob\data\characters\npc_entities\monsters\kikimore_small.w2ent" );
	ent.PushBack( "dlc\bob\data\characters\npc_entities\monsters\kikimore.w2ent" );
	ent.PushBack( "dlc\bob\data\characters\npc_entities\monsters\barghest.w2ent" );
	ent.PushBack( "dlc\bob\data\characters\npc_entities\monsters\spriggan.w2ent" );
	ent.PushBack( "dlc\bob\data\quests\main_quests\quest_files\q702_hunt\characters\q702_wight.w2ent" );
	ent.PushBack( "dlc\bob\data\characters\npc_entities\monsters\wicht.w2ent" );
	ent.PushBack( "dlc\bob\data\characters\npc_entities\monsters\oszluzg.w2ent" );
	ent.PushBack( "dlc\bob\data\living_world\enemy_templates\dracolizard.w2ent" );
	ent.PushBack( "dlc\bob\data\characters\npc_entities\monsters\garkain.w2ent" );
	ent.PushBack( "dlc\bob\data\characters\npc_entities\monsters\nightwraith_banshee.w2ent" );
	ent.PushBack( "dlc\bob\data\quests\monster_hunts\quest_files\mh701_tectonic_terror\characters\mh701_sharley_matriarch.w2ent" );
	ent.PushBack( "characters\npc_entities\monsters\endriaga_lvl3__spikey.w2ent" );
	ent.PushBack( "dlc\bob\data\quests\main_quests\quest_files\q704_truth\characters\q704_garkain.w2ent" );
	ent.PushBack( "dlc\bob\data\characters\npc_entities\monsters\fairytale_witch.w2ent" );
	ent.PushBack( "dlc\bob\data\quests\main_quests\quest_files\q704b_fairy_tale\entities\imps\q704_ft_pixie_01.w2ent" );
	ent.PushBack( "dlc\bob\data\quests\main_quests\quest_files\q704b_fairy_tale\characters\q704_ft_rapunzel.w2ent" );
	ent.PushBack( "dlc\bob\data\quests\main_quests\quest_files\q704b_fairy_tale\entities\q704_ft_pigs_evil.w2ent" );
	ent.PushBack( "dlc\bob\data\characters\npc_entities\monsters\bigbadwolf.w2ent" );
	ent.PushBack( "dlc\bob\data\characters\npc_entities\monsters\q704_cloud_giant.w2ent" );
	ent.PushBack( "dlc\bob\data\characters\npc_entities\monsters\wild_boar_ep2.w2ent" );
	ent.PushBack( "dlc\bob\data\characters\npc_entities\monsters\wild_boar_ep2.w2ent" );
	ent.PushBack( "dlc\bob\data\quests\minor_quests\quest_files\mq7017_talking_horse\characters\mq7017_spirit.w2ent" );
	ent.PushBack( "dlc\bob\data\quests\main_quests\quest_files\q704_truth\characters\q704_protofleder.w2ent" );
	ent.PushBack( "dlc\dlc3\data\characters\mh201_cave_troll.w2ent" );
	ent.PushBack( "characters\npc_entities\monsters\arachas_lvl1.w2ent" );
	ent.PushBack( "characters\npc_entities\monsters\arachas_lvl2__armored.w2ent" );
	ent.PushBack( "dlc\bob\data\characters\npc_entities\monsters\mq7007_item__golem_grafitti.w2ent" );
	ent.PushBack( "quests\sidequests\skellige\quest_files\sq204_forest_spirit\characters\sq204_leshy.w2ent" );
	ent.PushBack( "dlc\bob\data\characters\npc_entities\secondary_npc\mq7004_ghost.w2ent" );
	ent.PushBack( "quests\minor_quests\no_mans_land\quest_files\mq1057_fugas\characters\mq1057_fugas.w2ent" );
	ent.PushBack( "dlc\bob\data\characters\npc_entities\monsters\black_spider_ep2.w2ent" );
	ent.PushBack( "quests\generic_quests\no_mans_land\quest_files\mh102_arachas\characters\mh102_arachas.w2ent" );
	ent.PushBack( "quests\generic_quests\no_mans_land\quest_files\mh103_nightwraith\characters\mh103_nighwraith.w2ent" );
	ent.PushBack( "quests\generic_quests\no_mans_land\quest_files\mh104_ekimma\characters\mh104_ekimma.w2ent" );
	ent.PushBack( "quests\generic_quests\no_mans_land\quest_files\mh105_wyvern\characters\mh105_wyvern_royal.w2ent" );
	ent.PushBack( "quests\generic_quests\no_mans_land\quest_files\mh106_gravehag\characters\mh106_gravehag.w2ent" );
	ent.PushBack( "quests\generic_quests\no_mans_land\quest_files\mh107_fiend\characters\mh107_czart.w2ent" );
	ent.PushBack( "quests\generic_quests\no_mans_land\quest_files\mh108_fogling\characters\mh108_ancient_fogling.w2ent" );
	ent.PushBack( "quests\generic_quests\skellige\quest_files\mh202_nekker_warrior\characters\mh202_nekker_alpha.w2ent" );
	ent.PushBack( "quests\generic_quests\skellige\quest_files\mh203_water_hag\characters\mh203_water_hag.w2ent" );
	ent.PushBack( "quests\generic_quests\skellige\quest_files\mh206_fiend_ruins\characters\mh206_bies.w2ent" );
	ent.PushBack( "quests\generic_quests\skellige\quest_files\mh208_forktail\characters\mh208_forktail.w2ent" );
	ent.PushBack( "quests\generic_quests\skellige\quest_files\mh210_lamia\characters\mh210_lamia.w2ent" );
	ent.PushBack( "quests\generic_quests\novigrad\quest_files\mh301_gryphon\characters\mh301_gryphon.w2ent" );
	ent.PushBack( "quests\generic_quests\novigrad\quest_files\mh302_leshy\characters\mh302_leshy.w2ent" );
	ent.PushBack( "quests\generic_quests\novigrad\quest_files\mh304_katakan\characters\mh304_katakan.w2ent" );
	ent.PushBack( "quests\generic_quests\novigrad\quest_files\mh305_doppler\characters\mh305_doppler_02.w2ent" );
	ent.PushBack( "quests\generic_quests\novigrad\quest_files\mh307_minion\characters\mh307_minion.w2ent" );
	ent.PushBack( "quests\generic_quests\novigrad\quest_files\mh308_noonwraith\characters\mh308_noonwraith_02.w2ent" );
	return ent;
}

exec function getentnames()
{
	var paths : array< string > = getbestent();
	var i : int;
	var template : CEntityTemplate;
	var entity : CEntity;
	var actor : CActor;
	
	for( i = 0; i < paths.Size(); i += 1 )
	{
		template = (CEntityTemplate)LoadResource(paths[i], true);
		entity = theGame.CreateEntity(template, Vector(0,0,0), EulerAngles(0,0,0));
		
		actor = (CActor)entity;
		LogChannel( 'VHUD', actor.GetAppearance() );
		
		entity.Destroy();
	}
	
	
	
	
	
	
	
	
	
	
	
	
	
}


function getbestdepotpaths() : array< string >
{
	var paths : array< string >;
	paths.PushBack("dlc\bob\journal\bestiary\alp.journal");
	paths.PushBack("dlc\bob\journal\bestiary\archespore.journal");
	paths.PushBack("dlc\bob\journal\bestiary\barghests.journal");
	paths.PushBack("dlc\bob\journal\bestiary\beanshie.journal");
	paths.PushBack("dlc\bob\journal\bestiary\bestiarymonsterhuntmh701.journal");
	paths.PushBack("dlc\bob\journal\bestiary\bestiarymonsterhuntmq7017.journal");
	paths.PushBack("dlc\bob\journal\bestiary\bestiarymq7004.journal");
	paths.PushBack("dlc\bob\journal\bestiary\bigbadwolf.journal");
	paths.PushBack("dlc\bob\journal\bestiary\bruxa.journal");
	paths.PushBack("dlc\bob\journal\bestiary\dagonet.journal");
	paths.PushBack("dlc\bob\journal\bestiary\darkpixies.journal");
	paths.PushBack("dlc\bob\journal\bestiary\dettlaffmonster.journal");
	paths.PushBack("dlc\bob\journal\bestiary\dracolizard.journal");
	paths.PushBack("dlc\bob\journal\bestiary\ep2arachnomorphs.journal");
	paths.PushBack("dlc\bob\journal\bestiary\ep2beast.journal");
	paths.PushBack("dlc\bob\journal\bestiary\ep2boar.journal");
	paths.PushBack("dlc\bob\journal\bestiary\ep2sharley.journal");
	paths.PushBack("dlc\bob\journal\bestiary\ep2virtbeasts.journal");
	paths.PushBack("dlc\bob\journal\bestiary\ep2virtconstructs.journal");
	paths.PushBack("dlc\bob\journal\bestiary\ep2virtcursed.journal");
	paths.PushBack("dlc\bob\journal\bestiary\ep2virtdraconides.journal");
	paths.PushBack("dlc\bob\journal\bestiary\ep2virtinsectoid.journal");
	paths.PushBack("dlc\bob\journal\bestiary\ep2virtnecro.journal");
	paths.PushBack("dlc\bob\journal\bestiary\ep2virtrelicts.journal");
	paths.PushBack("dlc\bob\journal\bestiary\ep2virtspectres.journal");
	paths.PushBack("dlc\bob\journal\bestiary\ep2virtvampires.journal");
	paths.PushBack("dlc\bob\journal\bestiary\fleder.journal");
	paths.PushBack("dlc\bob\journal\bestiary\garkain.journal");
	paths.PushBack("dlc\bob\journal\bestiary\kikimora.journal");
	paths.PushBack("dlc\bob\journal\bestiary\kikimoraworker.journal");
	paths.PushBack("dlc\bob\journal\bestiary\moreausgolem.journal");
	paths.PushBack("dlc\bob\journal\bestiary\mq7002grottore.journal");
	paths.PushBack("dlc\bob\journal\bestiary\mq7002spriggan.journal");
	paths.PushBack("dlc\bob\journal\bestiary\mq7010dracolizard.journal");
	paths.PushBack("dlc\bob\journal\bestiary\mq7018basilisk.journal");
	paths.PushBack("dlc\bob\journal\bestiary\palewidow.journal");
	paths.PushBack("dlc\bob\journal\bestiary\panther.journal");
	paths.PushBack("dlc\bob\journal\bestiary\parszywiec.journal");
	paths.PushBack("dlc\bob\journal\bestiary\protofleder.journal");
	paths.PushBack("dlc\bob\journal\bestiary\q701bruxa.journal");
	paths.PushBack("dlc\bob\journal\bestiary\q701sharley.journal");
	paths.PushBack("dlc\bob\journal\bestiary\q702wight.journal");
	paths.PushBack("dlc\bob\journal\bestiary\q704alphagarkain.journal");
	paths.PushBack("dlc\bob\journal\bestiary\q704bigbadwolfasbeast.journal");
	paths.PushBack("dlc\bob\journal\bestiary\q704cloudgiant.journal");
	paths.PushBack("dlc\bob\journal\bestiary\q704ftwitch.journal");
	paths.PushBack("dlc\bob\journal\bestiary\q704rapunzel.journal");
	paths.PushBack("dlc\bob\journal\bestiary\q704threelittlepigs.journal");
	paths.PushBack("dlc\bob\journal\bestiary\scolopedromorph.journal");
	paths.PushBack("dlc\bob\journal\bestiary\wicht.journal");
	paths.PushBack("dlc\bob\journal\bestiary\wp2virtogrowate.journal");
	paths.PushBack("dlc\ep1\journal\bestiary\angryiris.journal");
	paths.PushBack("dlc\ep1\journal\bestiary\arachnomorf.journal");
	paths.PushBack("dlc\ep1\journal\bestiary\boar1.journal");
	paths.PushBack("dlc\ep1\journal\bestiary\caretaker.journal");
	paths.PushBack("dlc\ep1\journal\bestiary\ep1virtualbeasts.journal");
	paths.PushBack("dlc\ep1\journal\bestiary\ep1virtualcaretaker.journal");
	paths.PushBack("dlc\ep1\journal\bestiary\ep1virtualfrogprince.journal");
	paths.PushBack("dlc\ep1\journal\bestiary\ep1virtualinsectoids.journal");
	paths.PushBack("dlc\ep1\journal\bestiary\ep1virtualspectres.journal");
	paths.PushBack("dlc\ep1\journal\bestiary\etheral.journal");
	paths.PushBack("dlc\ep1\journal\bestiary\irisfrompainting.journal");
	paths.PushBack("dlc\ep1\journal\bestiary\princefrog.journal");
	paths.PushBack("gameplay\journal\bestiary\armoredarachas.journal");
	paths.PushBack("gameplay\journal\bestiary\bear.journal");
	paths.PushBack("gameplay\journal\bestiary\beasts.journal");
	paths.PushBack("gameplay\journal\bestiary\bestiaryalghoul.journal");
	paths.PushBack("gameplay\journal\bestiary\bestiarybasilisk.journal");
	paths.PushBack("gameplay\journal\bestiary\bestiarycockatrice.journal");
	paths.PushBack("gameplay\journal\bestiary\bestiarycrabspider.journal");
	paths.PushBack("gameplay\journal\bestiary\bestiaryekkima.journal");
	paths.PushBack("gameplay\journal\bestiary\bestiaryelemental.journal");
	paths.PushBack("gameplay\journal\bestiary\bestiaryendriag.journal");
	paths.PushBack("gameplay\journal\bestiary\bestiaryforktail.journal");
	paths.PushBack("gameplay\journal\bestiary\bestiaryghoul.journal");
	paths.PushBack("gameplay\journal\bestiary\bestiarygolem.journal");
	paths.PushBack("gameplay\journal\bestiary\bestiarygreaterrotfiend.journal");
	paths.PushBack("gameplay\journal\bestiary\bestiarykatakan.journal");
	paths.PushBack("gameplay\journal\bestiary\bestiarymiscreant.journal");
	paths.PushBack("gameplay\journal\bestiary\bestiarymonsterhuntmh101.journal");
	paths.PushBack("gameplay\journal\bestiary\bestiarymonsterhuntmh102.journal");
	paths.PushBack("gameplay\journal\bestiary\bestiarymonsterhuntmh103.journal");
	paths.PushBack("gameplay\journal\bestiary\bestiarymonsterhuntmh104.journal");
	paths.PushBack("gameplay\journal\bestiary\bestiarymonsterhuntmh105.journal");
	paths.PushBack("gameplay\journal\bestiary\bestiarymonsterhuntmh106.journal");
	paths.PushBack("gameplay\journal\bestiary\bestiarymonsterhuntmh107.journal");
	paths.PushBack("gameplay\journal\bestiary\bestiarymonsterhuntmh108.journal");
	paths.PushBack("gameplay\journal\bestiary\bestiarymonsterhuntmh202.journal");
	paths.PushBack("gameplay\journal\bestiary\bestiarymonsterhuntmh203.journal");
	paths.PushBack("gameplay\journal\bestiary\bestiarymonsterhuntmh206.journal");
	paths.PushBack("gameplay\journal\bestiary\bestiarymonsterhuntmh207.journal");
	paths.PushBack("gameplay\journal\bestiary\bestiarymonsterhuntmh208.journal");
	paths.PushBack("gameplay\journal\bestiary\bestiarymonsterhuntmh210.journal");
	paths.PushBack("gameplay\journal\bestiary\bestiarymonsterhuntmh301.journal");
	paths.PushBack("gameplay\journal\bestiary\bestiarymonsterhuntmh302.journal");
	paths.PushBack("gameplay\journal\bestiary\bestiarymonsterhuntmh303.journal");
	paths.PushBack("gameplay\journal\bestiary\bestiarymonsterhuntmh304.journal");
	paths.PushBack("gameplay\journal\bestiary\bestiarymonsterhuntmh305.journal");
	paths.PushBack("gameplay\journal\bestiary\bestiarymonsterhuntmh306.journal");
	paths.PushBack("gameplay\journal\bestiary\bestiarymonsterhuntmh307.journal");
	paths.PushBack("gameplay\journal\bestiary\bestiarymonsterhuntmh308.journal");
	paths.PushBack("gameplay\journal\bestiary\bestiarymoonwright.journal");
	paths.PushBack("gameplay\journal\bestiary\bestiarynoonwright.journal");
	paths.PushBack("gameplay\journal\bestiary\bestiarypesta.journal");
	paths.PushBack("gameplay\journal\bestiary\bestiarywerebear.journal");
	paths.PushBack("gameplay\journal\bestiary\bestiarywerewolf.journal");
	paths.PushBack("gameplay\journal\bestiary\bestiarywyvern.journal");
	//paths.PushBack("gameplay\journal\bestiary\bies.journal");
	paths.PushBack("gameplay\journal\bestiary\constructs.journal");
	paths.PushBack("gameplay\journal\bestiary\cursed.journal");
	paths.PushBack("gameplay\journal\bestiary\cyclops.journal");
	//paths.PushBack("gameplay\journal\bestiary\czart.journal");
	//paths.PushBack("gameplay\journal\bestiary\czart1.journal");
	paths.PushBack("gameplay\journal\bestiary\czart2.journal");
	paths.PushBack("gameplay\journal\bestiary\dog.journal");
	paths.PushBack("gameplay\journal\bestiary\doppler.journal");
	paths.PushBack("gameplay\journal\bestiary\drowner.journal");
	paths.PushBack("gameplay\journal\bestiary\dzinn.journal");
	paths.PushBack("gameplay\journal\bestiary\endriagatruten.journal");
	paths.PushBack("gameplay\journal\bestiary\endriagaworker.journal");
	paths.PushBack("gameplay\journal\bestiary\erynia.journal");
	//paths.PushBack("gameplay\journal\bestiary\fiend.journal");
	//paths.PushBack("gameplay\journal\bestiary\fiend2.journal");
	paths.PushBack("gameplay\journal\bestiary\fiends.journal");
	paths.PushBack("gameplay\journal\bestiary\fireelemental.journal");
	paths.PushBack("gameplay\journal\bestiary\fogling.journal");
	paths.PushBack("gameplay\journal\bestiary\gargoyle.journal");
	paths.PushBack("gameplay\journal\bestiary\godling.journal");
	paths.PushBack("gameplay\journal\bestiary\gravehag.journal");
	paths.PushBack("gameplay\journal\bestiary\griffin.journal");
	paths.PushBack("gameplay\journal\bestiary\harpy.journal");
	paths.PushBack("gameplay\journal\bestiary\highervampire.journal");
	paths.PushBack("gameplay\journal\bestiary\him.journal");
	paths.PushBack("gameplay\journal\bestiary\humans.journal");
	paths.PushBack("gameplay\journal\bestiary\hybrids.journal");
	paths.PushBack("gameplay\journal\bestiary\icegiant.journal");
	paths.PushBack("gameplay\journal\bestiary\icegiant.journal");
	paths.PushBack("gameplay\journal\bestiary\icegolem.journal");
	paths.PushBack("gameplay\journal\bestiary\icetroll.journal");
	paths.PushBack("gameplay\journal\bestiary\insectoids.journal");
	//paths.PushBack("gameplay\journal\bestiary\leshy.journal");
	paths.PushBack("gameplay\journal\bestiary\leshy1.journal");
	//paths.PushBack("gameplay\journal\bestiary\leszy.journal");
	paths.PushBack("gameplay\journal\bestiary\lycanthrope.journal");
	paths.PushBack("gameplay\journal\bestiary\mq0003noonwraith.journal");
	paths.PushBack("gameplay\journal\bestiary\necrophages.journal");
	paths.PushBack("gameplay\journal\bestiary\nekker.journal");
	paths.PushBack("gameplay\journal\bestiary\ogrelike.journal");
	paths.PushBack("gameplay\journal\bestiary\ornithosaur.journal");
	paths.PushBack("gameplay\journal\bestiary\poisonousarachas.journal");
	paths.PushBack("gameplay\journal\bestiary\relicts.journal");
	paths.PushBack("gameplay\journal\bestiary\sentient.journal");
	//paths.PushBack("gameplay\journal\bestiary\silvan.journal");
	//paths.PushBack("gameplay\journal\bestiary\silvan1.journal");
	paths.PushBack("gameplay\journal\bestiary\silvan2.journal");
	paths.PushBack("gameplay\journal\bestiary\siren.journal");
	paths.PushBack("gameplay\journal\bestiary\spectre.journal");
	paths.PushBack("gameplay\journal\bestiary\sq204ancientleszen.journal");
	paths.PushBack("gameplay\journal\bestiary\succubus.journal");
	paths.PushBack("gameplay\journal\bestiary\trollcave.journal");
	paths.PushBack("gameplay\journal\bestiary\vampires.journal");
	paths.PushBack("gameplay\journal\bestiary\waterhag.journal");
	paths.PushBack("gameplay\journal\bestiary\whminion.journal");
	paths.PushBack("gameplay\journal\bestiary\witches.journal");
	paths.PushBack("gameplay\journal\bestiary\wolf.journal");
	paths.PushBack("gameplay\journal\bestiary\wraith.journal");
	paths.PushBack("dlc\dlc3\journal\bestiary\bestiarymonsterhuntmh201.journal");
	return paths;
}

exec function unlockall()
{
	var i : int;
	var paths : array < string > = getbestdepotpaths();
	
	for(i=0;i<paths.Size();i+=1)
	{
		activatebestiary(paths[i]);
	}
	
} 

function activatebestiary( entryAlias : string)
{								// literal path to the .journal file
	var i, j : int;
	var resource : CJournalResource;
	var entryBase : CJournalBase;
	var childGroups : array<CJournalBase>;
	var childEntries : array<CJournalBase>;
	var descriptionGroup : CJournalCreatureDescriptionGroup;
	var descriptionEntry : CJournalCreatureDescriptionEntry;	
	var journalManager : CWitcherJournalManager;
    
	journalManager = theGame.GetJournalManager();
	
	
	// same here... activating all of em at the same time
	resource = (CJournalResource)LoadResource( entryAlias, true  );
	if ( resource )
	{
		entryBase = resource.GetEntry();
		if ( entryBase )
		{
			journalManager.ActivateEntry( entryBase, JS_Active );
			
			journalManager.SetEntryHasAdvancedInfo( entryBase, true );
			
			
			journalManager.GetAllChildren( entryBase, childGroups );
			for ( i = 0; i < childGroups.Size(); i += 1 )
			{
				descriptionGroup = ( CJournalCreatureDescriptionGroup )childGroups[ i ];
				if ( descriptionGroup )
				{
					journalManager.GetAllChildren( descriptionGroup, childEntries );
					for ( j = 0; j < childEntries.Size(); j += 1 )
					{
						descriptionEntry = ( CJournalCreatureDescriptionEntry )childEntries[ j ];
						if ( descriptionEntry )
						{
							journalManager.ActivateEntry( descriptionEntry, JS_Active );
						}
					}
					return;
				}
			}
		}
	}
}


exec function getmissingent()
{
	var paths				: array< string > = getbestdepotpaths();
	var i, j				: int;
	var resource			: CJournalResource;
	var entryBase 			: CJournalBase;
	var creatureTemp		: CJournalCreature;
	var template			: CEntityTemplate;
	
	for( i = 0; i < paths.Size(); i += 1 )
	{
		resource = (CJournalResource)LoadResource( paths[i], true );
		if ( resource )
		{
			entryBase = resource.GetEntry();
			if ( entryBase )
			{
				creatureTemp = (CJournalCreature)entryBase;
				if( creatureTemp )
				{
					template = ( CEntityTemplate )LoadResource( creatureTemp.GetEntityTemplateFilename(), true );
					if ( !template )
					{
						LogChannel( 'VHUD', paths[i] );
					}
				}
			}
		}
	}
}