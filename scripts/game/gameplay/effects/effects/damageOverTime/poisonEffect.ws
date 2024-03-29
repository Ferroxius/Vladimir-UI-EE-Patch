/***********************************************************************/
/** 	© 2015 CD PROJEKT S.A. All rights reserved.
/** 	THE WITCHER® is a trademark of CD PROJEKT S. A.
/** 	The Witcher game is based on the prose of Andrzej Sapkowski.
/***********************************************************************/

class W3Effect_Poison extends W3DamageOverTimeEffect
{
	// W3EE - Begin
	default effectType = EET_Poison;
	default resistStat = CDS_PoisonRes;
	
	private saved var immobilize : SCustomEffectParams;
	private saved var playerViperBonus : bool;
	private saved var curStacks : int;
	private var speedMultID : int;
	private var stackTimer : float;
	private var waitTime : float;
	private var immobilizeTimer : float;
	
	private const var MAX_STACKS : int;
	private const var UPDATE_TIMER : float;
	private const var IMMOBILIZE_COOLDOWN : float;
	
	default MAX_STACKS = 5;
	default UPDATE_TIMER = 1.f;
	default IMMOBILIZE_COOLDOWN = 15.f;
	
	event OnEffectAdded( optional customParams : W3BuffCustomParams )
	{
		super.OnEffectAdded(customParams);
		curStacks = (int)MaxF(1, effectValue.valueMultiplicative);
		CalculateDuration(true);
		ResetStackTimer();
		
		SetImmobilize();
		if( playerViperBonus && (immobilizeTimer <= 0 || !target.IsHuge()) )
			target.AddEffectCustom(immobilize);
			
		if( (CR4Player)target )
			theGame.GetTutorialSystem().uiHandler.GotoState('Poisoning');
	}
	
	event OnEffectRemoved()
	{
		super.OnEffectRemoved();
		target.RemoveAbilityAll('PoisoningStatDebuff');
		target.ResetAnimationSpeedMultiplier(speedMultID);
	}
	
	event OnUpdate( dt : float )
	{	
		var buildupReduction : SAbilityAttributeValue;
		var dmg, maxVit, maxEss : float;
		var i : int;
		
		waitTime += dt;
		stackTimer -= dt * curStacks;
		
		if( immobilizeTimer > 0 )
			immobilizeTimer -= dt;
			
		if( stackTimer <= 0 )
			RemoveStack();
			
		if( waitTime < UPDATE_TIMER )
			return true;
			
		if( !target.IsAlive() )
			return true;
			
		if( target.IsQuestActor() )
			return false;
			
		waitTime = 0.f;
		for(i=0; i<damages.Size(); i+=1)
		{
			if( (W3PlayerWitcher)target )
			{
				dmg = 0.f;
				buildupReduction = target.GetAttributeValue('poison_buildup_resist');
				((W3PlayerWitcher)target).AddToxicityOffset(1.f * curStacks * (1.f - buildupReduction.valueMultiplicative));
				if( target.HasBuff(EET_Decoction10) )
					target.RemoveAbilityAll('PoisoningStatDebuff');
			}
			else
				dmg = 12.f * curStacks;
				
			if( dmg > 0 )
				effectManager.CacheDamage(damages[i].damageTypeName, dmg, GetCreator(), this, 1.f, true, powerStatType, isEnvironment);		
		}
	}
	
	private function SetImmobilize()
	{
		playerViperBonus = ((W3PlayerWitcher)GetCreator()).IsSetBonusActive(EISB_Viper2);
		immobilize.effectType = EET_Immobilized;
		immobilize.creator = GetCreator();
		immobilize.sourceName = "ViperSetBonus";
		immobilize.duration = 5.f;
		immobilizeTimer = IMMOBILIZE_COOLDOWN;
	}
	
	public function ResetStackTimer()
	{
		var timeReduction : SAbilityAttributeValue;
		
		timeReduction = target.GetAttributeValue('poison_stack_timer_reduction');
		stackTimer = 60.f * (1.f - timeReduction.valueMultiplicative);
	}
	
	private function RemoveStack()
	{
		curStacks -= 1;
		target.RemoveAbility('PoisoningStatDebuff');
		if( !((W3PlayerWitcher)target) )
			speedMultID = target.SetAnimationSpeedMultiplier(1.f - 0.02f * curStacks, speedMultID);
		
		if( curStacks <= 0 )
			target.RemoveEffect(this);
		ResetStackTimer();
	}
	
	protected function CalculateDuration( optional setInitialDuration : bool )
	{
		if( setInitialDuration )
			initialDuration = -1;
		duration = -1;
	}
	
	public function OnDamageDealt( dealtDamage : bool )
	{
		if( playerViperBonus )
		{
			target.DrainStamina(ESAT_FixedValue, target.GetStat(BCS_Stamina) * 0.1f, 0.f);
		}
	}
	
	public function IncreaseStacks( optional val : int )
	{
		if( target.IsQuestActor() )
			return;
			
		ResetStackTimer();
		
		val = Max(1, val);
		if( curStacks + val > MAX_STACKS )
			val = MAX_STACKS - curStacks;
			
		curStacks += val;
		
		if( !target.HasBuff(EET_Decoction10) )
			target.AddAbilityMultiple('PoisoningStatDebuff', val);
			
		if( !((W3PlayerWitcher)target) )
			speedMultID = target.SetAnimationSpeedMultiplier(1.f - 0.02f * curStacks, speedMultID);
			
		if( playerViperBonus )
			target.AddEffectCustom(immobilize);
	}
	
	public function GetStacks() : int
	{
		return curStacks;
	}
	
	public function GetMaxStacks() : int
	{
		return MAX_STACKS;
	}
	// W3EE - End
}