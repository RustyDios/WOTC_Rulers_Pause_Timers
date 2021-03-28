//*******************************************************************************************
//  FILE:   X2Ability_RulersPauseTimers
//  
//	File created by RustyDios	10/01/20	12:00	
//	LAST UPDATED				21/01/20	14:00
//
//	Checks current status of the mission timer compared to what we want it to be
//		removed log SPAM.. it was alot!!
//
//*******************************************************************************************
class X2Condition_CheckTimer extends X2Condition config (RulerPauseTimers);

var bool bCheckSuspended;
var bool bCheckNOTSuspended;

event name CallMeetsConditionWithSource (XComGameState_BaseObject kTarget, XComGameState_BaseObject kSource)
{
	local XComGameState_UITimer UiTimer;
	//local XComGameState_Unit	TargetUnit, ShooterUnit;

	//sort the correct units
	//TargetUnit = XComGameState_Unit(kTarget);
	//ShooterUnit = XComGameState_Unit(kSource);

	//grab the current mission timer
	UiTimer = XComGameState_UITimer(`XCOMHISTORY.GetSingleGameStateObjectForClass(class 'XComGameState_UITimer', true));

	if (UiTimer != none)
	{
		if (bCheckNOTSuspended && !UiTimer.IsSuspended())
		{
			//`LOG("Timer Conditional Check Run :: Success Result",class'X2DownloadableContentInfo_WOTC_Rulers_Pause_Timers'.default.bEnableLogging,'WOTC_RulersPauseTimers');
			return 'AA_Success'; //timer exists and is NOT suspended, we're not dead and we have alive targets
		}

		if (bCheckSuspended && UiTimer.IsSuspended())
		{
			//`LOG("Timer Conditional Check Run :: Success Result",class'X2DownloadableContentInfo_WOTC_Rulers_Pause_Timers'.default.bEnableLogging,'WOTC_RulersPauseTimers');
			return 'AA_Success'; //timer exists and is suspended, we're not dead and we have alive targets
		}

	}
	
	//`LOG("Timer Conditional Check Run :: Failed Result",class'X2DownloadableContentInfo_WOTC_Rulers_Pause_Timers'.default.bEnableLogging,'WOTC_RulersPauseTimers');
	return 'AA_AbilityUnavailable';//either timer doesn't exist OR it failed the checkstate
}
