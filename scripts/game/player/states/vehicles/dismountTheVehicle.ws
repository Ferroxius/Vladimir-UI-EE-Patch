/***********************************************************************/
/** 	© 2015 CD PROJEKT S.A. All rights reserved.
/** 	THE WITCHER® is a trademark of CD PROJEKT S. A.
/** 	The Witcher game is based on the prose of Andrzej Sapkowski.
/***********************************************************************/


state DismountTheVehicle in CPlayer extends PostUseVehicle
{
	public var vehicle 			: CVehicleComponent;
	public var dismountType 	: EDismountType;
	
	
	
	

	event OnEnterState( prevStateName : name )
	{
		parent.AddAnimEventCallback('enable_physics',	'OnAnimEvent_enable_physics');
		parent.AddAnimEventCallback('disableFeetIK',	'OnAnimEvent_disableFeetIK');
		parent.AddAnimEventCallback('enableFeetIK',		'OnAnimEvent_enableFeetIK');
		parent.BlockAllActions( 'DismountVehicle', true,, true );
		
		HACK_DeactivatePhysicsRepresentation();
		
		thePlayer.substateManager.m_SharedDataO.ResetHeightFallen();
	}
	
	event OnLeaveState( nextStateName : name )
	{ 
		
		
		
		
		LogAssert( !vehicle, "DismountTheVehicle::OnLeaveState, 'vehicle' is still set" );
		
		vehicle = NULL;
		
		super.OnLeaveState( nextStateName );
		
		parent.RegisterCollisionEventsListener();
		
		thePlayer.ResetRawPlayerHeading();
				
		parent.BlockAllActions( 'DismountVehicle', false );
		parent.UnblockAction( EIAB_Crossbow, 'DismountVehicle2' );
		
		parent.SetUsedVehicle(NULL);
		parent.SetBehaviorVariable( 'keepSpineUpright', 0.f );	
		
		HACK_ActivatePhysicsRepresentation();
		
	}
	
	
	
	
	
	final function SetupState( v : CVehicleComponent, inDismountType : EDismountType )
	{
		LogAssert( !vehicle, "DismountTheVehicle::SetupState, 'vehicle' is already set" );
		
		vehicle 		= v;
		dismountType 	= inDismountType;
	}
	
	
	cleanup function DismountCleanup() 
	{
		vehicle = NULL;
		HACK_ActivatePhysicsRepresentation();
	}
	
	function ContinuedState()
	{	
		parent.PopState( true );
	}
	
	// ImmersiveCam++
	event OnGameCameraTick( out moveData : SCameraMovementData, dt : float )
	{	
		DampVectorSpring( moveData.cameraLocalSpaceOffset, moveData.cameraLocalSpaceOffsetVel, Vector( thePlayer.ic.expOffset, thePlayer.ic.expDepth, thePlayer.ic.expHeight), 0.60f, dt );
		return false;
	}
	// ImmersiveCam--
	
	event OnGameCameraPostTick( out moveData : SCameraMovementData, dt : float )
	{
		moveData.pivotRotationController.SetDesiredHeading( VecHeading(theCamera.GetCameraDirection()) );
	}
	
	event OnAnimEvent_enable_physics( animEventName : name, animEventType : EAnimationEventType, animInfo : SAnimationEventAnimInfo )
	{
		HACK_ActivatePhysicsRepresentation();
		parent.BreakAttachment();
		
	}
	
	event OnAnimEvent_disableFeetIK( animEventName : name, animEventType : EAnimationEventType, animInfo : SAnimationEventAnimInfo )
	{
		
	}
	
	event OnAnimEvent_enableFeetIK( animEventName : name, animEventType : EAnimationEventType, animInfo : SAnimationEventAnimInfo )
	{
		
	}
}
