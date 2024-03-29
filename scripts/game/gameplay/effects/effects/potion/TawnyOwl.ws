/***********************************************************************/
/** 	© 2015 CD PROJEKT S.A. All rights reserved.
/** 	THE WITCHER® is a trademark of CD PROJEKT S. A.
/** 	The Witcher game is based on the prose of Andrzej Sapkowski.
/***********************************************************************/




class W3Potion_TawnyOwl extends W3RegenEffect
{
	default effectType = EET_TawnyOwl;
	
	// W3EE - Begin
	public function OnTimeUpdated(deltaTime : float)
	{
		var currentHour, level : int;
		
		if( isActive )
		{
			timeActive += deltaTime;	
			if( duration != -1 )
			{
				level = GetBuffLevel();				
				currentHour = GameTimeHours(theGame.GetGameTime());
				if(level < 3 || (currentHour > GetHourForDayPart(EDP_Dawn) && currentHour < GetHourForDayPart(EDP_Dusk)) )
					timeLeft -= deltaTime;
					
				if( timeLeft <= 0 )
					isActive = false;
			}
			
			OnUpdate(deltaTime);	
		}
	}
	// W3EE - End
}