/***********************************************************************/
/** 	© 2015 CD PROJEKT S.A. All rights reserved.
/** 	THE WITCHER® is a trademark of CD PROJEKT S. A.
/** 	The Witcher game is based on the prose of Andrzej Sapkowski.
/***********************************************************************/




class W3Effect_AutoStaminaRegen extends W3AutoRegenEffect
{
	private var regenModeIsCombat : bool;		
	private var cachedPlayer : CR4Player;
	private var wasLoaded : bool;
	
		default regenStat = CRS_Stamina;	
		default effectType = EET_AutoStaminaRegen;
		default regenModeIsCombat = true;		
	
	event OnEffectAdded(optional customParams : W3BuffCustomParams)
	{
		super.OnEffectAdded(customParams);
		
		regenModeIsCombat = true;
		
		if(isOnPlayer)
			cachedPlayer = (CR4Player)target;
	}
	
	public function OnLoad(t : CActor, eff : W3EffectManager)
	{
		super.OnLoad(t, eff);
		if(isOnPlayer)
			cachedPlayer = (CR4Player)target;
		wasLoaded = true;
	}
	
	event OnUpdate(dt : float)
	{
        if( wasLoaded )
        {
            SetEffectValue();
            wasLoaded = false;
        }
        
		if(isOnPlayer)
		{
			// W3EE - Begin
			/*if ( regenModeIsCombat != cachedPlayer.IsInCombat() )
			{
				regenModeIsCombat = !regenModeIsCombat;
				
				attributeName = RegenStatEnumToName(regenStat);
				
				SetEffectValue();
			}
			
			if ( cachedPlayer.IsInCombat() )
			{*/
				regenModeIsCombat = true;
				if ( thePlayer.IsGuarded() )
					effectValue = target.GetAttributeValue( 'staminaRegenGuarded' );
				else
				{
					attributeName = RegenStatEnumToName(regenStat);
					SetEffectValue();
				}
			//}
			// W3EE - End
		}

		super.OnUpdate( dt );
		
		if( target.GetStatPercents( BCS_Stamina ) >= 1.0f )
		{
			target.StopStaminaRegen();
		}
	}
	
	protected function SetEffectValue()
	{
		effectValue = target.GetAttributeValue(attributeName);
		// W3EE - Begin
		if( target.CountEffectsOfType(EET_SlowdownFrost) > 0 )
			effectValue = effectValue * 0.5f;
		// W3EE - End
	}
}
