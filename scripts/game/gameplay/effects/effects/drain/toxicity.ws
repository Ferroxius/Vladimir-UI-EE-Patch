/***********************************************************************/
/** 	© 2015 CD PROJEKT S.A. All rights reserved.
/** 	THE WITCHER® is a trademark of CD PROJEKT S. A.
/** 	The Witcher game is based on the prose of Andrzej Sapkowski.
/***********************************************************************/

struct SToxicityEntry
{
	var effectType : EEffectType;
	var activeTox : float;
	var dormantTox : float;
	var totalTox : float;
	var duration : float;
}

class W3Effect_Toxicity extends CBaseGameplayEffect
{
	private saved var toxThresholdEffect	: int;
	private var delayToNextVFXUpdate		: float;
	
	public var isUnsafe						: bool;
	private var witcher 					: W3PlayerWitcher;
	private var updateInterval				: float;
	private var maxStat						: float;
	
	private var updateCounter				: float;
	private var feverActive					: bool;
	private var feverMinimumInterval		: int;
	private var offset						: float;
	private var safeThreshold				: float;
	private var maxChance					: float;
	
	default effectType = EET_Toxicity;
	default attributeName = 'toxicityRegen';
	default isPositive = false;
	default isNeutral = true;
	default isNegative = false;
	
	default feverMinimumInterval = 0;
	default safeThreshold = 0.25f;
	default maxChance = 20.f;
	
	
	public function CacheSettings()
	{
		super.CacheSettings();
	}
	
	public function OnLoad(t : CActor, eff : W3EffectManager)
	{
		super.OnLoad(t, eff);
		
		toxThresholdEffect = -1;
		witcher = (W3PlayerWitcher)t;
	}
	
	private function PlayHeadEffect( effect : name, optional stop : bool )
	{
		var inv : CInventoryComponent;
		var headIds : array<SItemUniqueId>;
		var headId : SItemUniqueId;
		var head : CItemEntity;
		var i : int;
		
		inv = target.GetInventory();
		headIds = inv.GetItemsByCategory('head');
		for(i=0; i<headIds.Size(); i+=1)
		{
			if( !inv.IsItemMounted(headIds[i]) )
				continue;
				
			headId = headIds[i];
			if( !inv.IsIdValid(headId) )
				return;
				
			head = inv.GetItemEntityUnsafe(headId);
			if( !head )
				return;
				
			if( stop )
				head.StopEffect(effect);
			else
				head.PlayEffectSingle(effect);
		}
	}
	
	private function CalculateFeverChance( toxicityPerc : float ) : float
	{
		//forumla for fever chance: f(a,b,c) = (a - (1 - a * b ^ d)) * c ^ d + (1 - a * b ^ d) with a = max chance, b = threshold%, c = current toxicity %, d = power
		var pow, ret, chance : float;
		
		chance = maxChance;
		chance *= 1.f - (thePlayer.GetSkillLevel(S_Alchemy_s01) * 0.05f);
		pow = 3.f;
		
		offset = 1.f - chance * PowF(safeThreshold, pow);
		ret = (chance - offset) * PowF(toxicityPerc, pow) + offset;
		ret *= Options().GetFeverChanceMult();
		
		return ret;
	}
	
	public function StartFever()
	{
		var effectParams	: SCustomEffectParams;
		var duration 		: float;
		
		duration = 60.f + RandRangeF(60.f);
		duration *= Options().GetFeverDurationMult();
		
		effectParams.effectType = EET_ToxicityFever;
		effectParams.sourceName = "ToxicityFeverEffect";
		effectParams.duration = duration;
		
		target.AddEffectCustom(effectParams);
	}
	
	private saved var toxicityEntries : array<SToxicityEntry>;
	public function AddToxicityEntry( effect : EEffectType, toxicity: float, duration : float )
	{
		toxicityEntries.PushBack(SToxicityEntry(effect, toxicity * 0.75f, toxicity * 0.25f, toxicity, duration));
	}
	
	public function ClearToxicityHoney( activeReduction : float, dormantReduction : float )
	{
		var i : int;
		var drainVal : float;
		
		for(i=0; i<toxicityEntries.Size(); i+=1)
		{
			drainVal += toxicityEntries[i].activeTox * activeReduction + toxicityEntries[i].dormantTox * dormantReduction;
			toxicityEntries[i].activeTox -= toxicityEntries[i].activeTox * activeReduction;
			toxicityEntries[i].dormantTox -= toxicityEntries[i].dormantTox * dormantReduction;
		}
		
		effectManager.CacheStatUpdate(BCS_Toxicity, -1 * drainVal);
	}
	
	public function ClearToxicityFever()
	{
		var i : int;
		var drainVal, reductionVal, sum : float;
		
		reductionVal = 15.f;
		for(i=0; i<toxicityEntries.Size(); i+=1)
		{
			if( toxicityEntries[i].dormantTox <= reductionVal )
			{
				reductionVal -= toxicityEntries[i].dormantTox;
				drainVal += toxicityEntries[i].dormantTox;
				toxicityEntries[i].dormantTox = 0.f;
			}
			else
			{
				drainVal += reductionVal;
				toxicityEntries[i].dormantTox -= reductionVal;
				break;
			}
		}
		
		effectManager.CacheStatUpdate(BCS_Toxicity, -1 * drainVal);
	}
	
	private function RemoveAllEntries()
	{
		var i, size : int;
		var drainVal : float;
		
		size = toxicityEntries.Size();
		for(i=0; i<size; i+=1)
		{
			drainVal = toxicityEntries[0].activeTox + toxicityEntries[0].dormantTox;
			effectManager.CacheStatUpdate(BCS_Toxicity, -1 * drainVal);
			toxicityEntries.Erase(0);
		}
	}
	
	private function FindInertElement() : int
	{
		var i : int;
		
		for(i=0; i<toxicityEntries.Size(); i+=1)
		{
			if( toxicityEntries[i].activeTox <= 0 && toxicityEntries[i].dormantTox <= 0 )
				return i;
		}
		
		return -1;
	}
	
	private function UpdateEntries( dt : float )
	{
		var idx : int;
		
		do
		{
			idx = FindInertElement();
			if( idx > -1 )
				toxicityEntries.Erase(idx);
		}
		while(idx > -1)
	}
	
	private function GetResidualToxicityDegen( toxicityOffset : float ) : float
	{
		var i : int;
		var drainVal, toxicity : float;
		
		toxicity = witcher.GetStat(BCS_Toxicity, true);
		for(i=0; i<toxicityEntries.Size(); i+=1)
			toxicity -= toxicityEntries[i].activeTox + toxicityEntries[i].dormantTox;
			
		drainVal = toxicity / 10.f;
		effectManager.CacheStatUpdate(BCS_Toxicity, -1 * drainVal);
		
		drainVal = toxicityOffset / 10.f;
		drainVal *= 1.f + witcher.GetMasterMutationStage() * 0.1f;
		drainVal *= Options().GetToxicityResidualDegenMult();
		
		return drainVal;
	}
	
	private function GetToxicityDegen() : float
	{
		var i : int;
		var toxDegen, degenVal : float;
		
		for(i=0; i<toxicityEntries.Size(); i+=1)
		{
			if( toxicityEntries[i].activeTox > 0 )
			{
				degenVal = toxicityEntries[i].totalTox * 0.75f / (toxicityEntries[i].duration * 2.0f);
				degenVal *= Options().GetToxicityActiveDegenMult();
				toxicityEntries[i].activeTox -= degenVal;
			}
			else
			{
				degenVal = toxicityEntries[i].totalTox * 0.25f / (toxicityEntries[i].duration * 3.0f);
				degenVal *= Options().GetToxicityDormantDegenMult();
				toxicityEntries[i].dormantTox -= degenVal;
			}
			if( target.HasBuff(EET_AlbedoDominance) )
				degenVal *= 1.25f;
			toxDegen += degenVal;
		}
		
		return (-1 * toxDegen);
	}
	
	event OnEffectAdded(optional customParams : W3BuffCustomParams)
	{	
		if( !((W3PlayerWitcher)target) )
		{
			LogAssert(false, "W3Effect_Toxicity.OnEffectAdded: effect added on non-CR4Player object - aborting!");
			return false;
		}
		
		super.OnEffectAdded(customParams);
		
		witcher = (W3PlayerWitcher)target;
		switchCameraEffect = witcher.HasBuff(EET_ToxicityFever);
	}
	
	event OnUpdate(deltaTime : float)
	{
		var toxicity, toxicityOffset, toxicityPerc, threshold, drainVal : float;
		var currentThreshold : int;
		
		super.OnUpdate(deltaTime);
		
		updateInterval += deltaTime;
		if( updateInterval >= 1.0f )
		{
			UpdateEntries(updateInterval);
			updateCounter += updateInterval;
			updateInterval = 0;
			
			toxicity = witcher.GetStat(BCS_Toxicity, false);
			toxicityOffset = witcher.GetToxicityOffset();
			if( !toxicity )
				return false;
				
			threshold = witcher.GetToxicityDamageThreshold();
			toxicityPerc = toxicity / witcher.GetStatMax(BCS_Toxicity);
			
			if( delayToNextVFXUpdate <= 0 )
			{		
				if( toxicityPerc < 0.50 )		currentThreshold = 0;
				else
				if( toxicityPerc < 0.75f )		currentThreshold = 1;
				else
				if( toxicityPerc <= 1.0f )		currentThreshold = 2;
				
				if( target.HasBuff(EET_ToxicityFever) )
					currentThreshold += 1;
					
				if( witcher.ShouldRefreshFace() || toxThresholdEffect != currentThreshold && !target.IsEffectActive('invisible') )
				{
					toxThresholdEffect = currentThreshold;
					switch ( toxThresholdEffect )
					{
						case 0: PlayHeadEffect('toxic_000_025'); break;
						case 1: PlayHeadEffect('toxic_025_050'); break;
						case 2: PlayHeadEffect('toxic_050_075'); break;
						case 3: PlayHeadEffect('toxic_075_100'); break;
					}
					delayToNextVFXUpdate = 2;
					witcher.ResetRefreshFace();
				}			
			}
			else delayToNextVFXUpdate -= 1.0f;
			
			isUnsafe = toxicity > threshold;
			drainVal = GetToxicityDegen() * (1.f + witcher.GetMasterMutationStage() * 0.1);
			
			if( updateCounter >= 10.f && updateCounter >= feverMinimumInterval )
			{
				updateCounter = 0;
				feverMinimumInterval = 0;
				if( !target.HasBuff(EET_ToxicityFever) && toxicityPerc >= safeThreshold )
				{
					if( RandRangeF(180.f) < CalculateFeverChance(toxicityPerc) )
					{
						StartFever();
						feverMinimumInterval = 60;
					}
				}
			}
			
			effectManager.CacheStatUpdate(BCS_Toxicity, drainVal);
			witcher.RemoveToxicityOffset(GetResidualToxicityDegen(toxicityOffset));
		}
	}
	
	event OnEffectRemoved()
	{
		RemoveAllEntries();
		super.OnEffectRemoved();
		
		PlayHeadEffect('toxic_000_025', true);
		PlayHeadEffect('toxic_025_050', true);
		PlayHeadEffect('toxic_050_075', true);
		PlayHeadEffect('toxic_075_100', true);
		
		PlayHeadEffect('toxic_025_000', true);
		PlayHeadEffect('toxic_050_025', true);
		PlayHeadEffect('toxic_075_050', true);
		PlayHeadEffect('toxic_100_075', true);
		
		toxThresholdEffect = 0;
		if( theSound.SoundIsBankLoaded("fever02a.bnk") )
			theSound.SoundUnloadBank("fever02a.bnk");
	}
	
	public function DisplayToxicity()
	{
		var i : int;
		var str : string;
		
		var messageData 	: W3MessagePopupData;
		var messagePopupRef : CR4MessagePopup;
		
		for(i=0; i<toxicityEntries.Size(); i+=1)
		{
			str += "effect: " + toxicityEntries[i].effectType + "<br>total tox: " + toxicityEntries[i].totalTox + "<br>active tox: " + toxicityEntries[i].activeTox + "<br>dormant tox: " + toxicityEntries[i].dormantTox + "<br><br>";
		}
		
		theGame.GetGuiManager().ShowUserDialogAdv( 0, "Toxicity info", str, false, UDB_Ok );
		//theGame.GetGuiManager().ShowNotification( str, 8.f );
	}
}