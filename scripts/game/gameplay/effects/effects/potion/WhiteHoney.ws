/***********************************************************************/
/** 	© 2015 CD PROJEKT S.A. All rights reserved.
/** 	THE WITCHER® is a trademark of CD PROJEKT S. A.
/** 	The Witcher game is based on the prose of Andrzej Sapkowski.
/***********************************************************************/




class W3Potion_WhiteHoney extends CBaseGameplayEffect
{
	default effectType = EET_WhiteHoney;
	
	
	event OnEffectAdded(optional customParams : W3BuffCustomParams)
	{
		var exceptions : array<CBaseGameplayEffect>;
		var activeReduction, dormantReduction, temp : SAbilityAttributeValue;
		
		super.OnEffectAdded(customParams);
		
		exceptions.PushBack(this);
		thePlayer.RemoveAllPotionEffects(exceptions);
		thePlayer.RemoveBuff(EET_AlbedoDominance, true, "AlbedoDominanceEffect");
		thePlayer.RemoveBuff(EET_RubedoDominance, true, "RubedoDominanceEffect");
		thePlayer.RemoveBuff(EET_NigredoDominance, true, "NigredoDominanceEffect");
		
		theGame.GetDefinitionsManager().GetAbilityAttributeValue(GetAbilityName(), 'active_toxicity_drain', activeReduction, temp);
		theGame.GetDefinitionsManager().GetAbilityAttributeValue(GetAbilityName(), 'dormant_toxicity_drain', dormantReduction, temp);
		
		((W3Effect_Toxicity)target.GetBuff(EET_Toxicity)).ClearToxicityHoney(activeReduction.valueMultiplicative, dormantReduction.valueMultiplicative);
		
		((W3Effect_ToxicityFever)target.GetBuff(EET_ToxicityFever)).CureFever();
	}
}