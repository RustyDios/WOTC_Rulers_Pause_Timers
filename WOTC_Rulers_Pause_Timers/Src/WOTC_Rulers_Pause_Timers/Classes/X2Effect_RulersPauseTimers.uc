//*******************************************************************************************
//  FILE:   X2Effect_RulersPauseTimers
//  
//	File created by RustyDios	10/01/20	12:00	
//	LAST UPDATED				21/01/20	14:00
//
//	basically a copy X2Effect_SuspendMissionTimer, but with a couple of extra checks 
//		and some logging for debug purposes .... 
//
//*******************************************************************************************

class X2Effect_RulersPauseTimers extends X2Effect_Persistent;

var bool bResumeMissionTimer;
var bool bIsDeathSwitch;

//************************
//	Effect ADDED
//************************

//On Effect Added ... pause on sight .. resume on death ..  and effect removed is the turn-reset
simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_UITimer UiTimer;
	local XComGameState_Unit	SourceUnit;

	//SUPER important line that adds the gamestates etc correctly ... see what I did there.... crack myself up sometimes :)
	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);

	//grab the current mission timer !!
	UiTimer = XComGameState_UITimer(`XCOMHISTORY.GetSingleGameStateObjectForClass(class 'XComGameState_UITimer', true));

	//grab the unit.. shooter
	SourceUnit = XComGameState_Unit(kNewTargetState);

	// ensure a source unit exists
	if (SourceUnit == none)
	{
		`LOG("Ability Effect Attempted with no Source Unit !!",class'X2DownloadableContentInfo_WOTC_Rulers_Pause_Timers'.default.bEnableLogging,'WOTC_RulersPauseTimers');
		return;
	}

	// ensure a timer exists - was crashing for missions that didn't have a timer without this
	if (UiTimer == none )
	{
		`LOG(SourceUnit.GetMyTemplateName() @" :: Attempted to change a Mission Timer which does not exist",class'X2DownloadableContentInfo_WOTC_Rulers_Pause_Timers'.default.bEnableLogging,'WOTC_RulersPauseTimers');
		return;
	}
	
	// only change timer if it's being shown (shouldshow = true for shown, so NOT should show = true for hidden)
	if (!UiTimer.ShouldShow)
	{
		`LOG(SourceUnit.GetMyTemplateName() @" :: Attempted to change a Mission Timer which is hidden",class'X2DownloadableContentInfo_WOTC_Rulers_Pause_Timers'.default.bEnableLogging,'WOTC_RulersPauseTimers');
		return;
	}

	// ensure that if we're resuming the timer.. it was actually suspended (NOT isSuspended = true for unsuspended)
	if (bResumeMissionTimer && !UiTimer.IsSuspended() )
	{
		`LOG(SourceUnit.GetMyTemplateName() @" :: Attempted to Resume a Mission Timer which isn't suspended",class'X2DownloadableContentInfo_WOTC_Rulers_Pause_Timers'.default.bEnableLogging,'WOTC_RulersPauseTimers');
		return;
	}

	//timer exists, we can change it either suspend or resume	//bResumeMissionTimer false is paused	//bResumeMissionTimer true is continue

	UiTimer.SuspendTimer(bResumeMissionTimer, NewGameState);
	`LOG(SourceUnit.GetMyTemplateName() @" :: Revealed Unit Suspend Mission Timer ::" @!bResumeMissionTimer,class'X2DownloadableContentInfo_WOTC_Rulers_Pause_Timers'.default.bEnableLogging,'WOTC_RulersPauseTimers');

	//forceswitch is an extra check on unit death to ensure timer switches
	if (bIsDeathSwitch)
	{
		UiTimer.SuspendTimer(bResumeMissionTimer, NewGameState);
		`LOG(SourceUnit.GetMyTemplateName() @" :: Death Switched Suspended Mission Timer :: ResumeMissionTimer is :: " @bResumeMissionTimer,class'X2DownloadableContentInfo_WOTC_Rulers_Pause_Timers'.default.bEnableLogging,'WOTC_RulersPauseTimers');
	}

}

//************************
//	Effect REMOVED
//************************

simulated function OnEffectRemoved(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed, XComGameState_Effect RemovedEffectState)
{
	local XComGameState_UITimer UiTimer;

	NewGameState.ModifyStateObject(class'XComGameState_Unit', ApplyEffectParameters.SourceStateObjectRef.ObjectID);

	//SUPER important line that adds the gamestates etc correctly ... see what I did again
	super.OnEffectRemoved(ApplyEffectParameters, NewGameState, bCleansed, RemovedEffectState);

	//grab the current mission timer !!
	UiTimer = XComGameState_UITimer(`XCOMHISTORY.GetSingleGameStateObjectForClass(class 'XComGameState_UITimer', true));

	// ensure a timer exists - was crashing for missions that didn't have a timer without this
	if (UiTimer == none )
	{
		`LOG("Turn Reset attempted to change a Mission Timer which does not exist",class'X2DownloadableContentInfo_WOTC_Rulers_Pause_Timers'.default.bEnableLogging,'WOTC_RulersPauseTimers');
		return;
	}

	// only resume timer if it's being shown (shouldshow = true for shown, so NOT should show = true for hidden)
	if (!UiTimer.ShouldShow)
	{
		`LOG("Turn Reset attempted to change a Mission Timer which is hidden",class'X2DownloadableContentInfo_WOTC_Rulers_Pause_Timers'.default.bEnableLogging,'WOTC_RulersPauseTimers');
		return;
	}

	// ensure that as we're resuming the timer.. it was actually suspended (NOT isSuspended = true for unsuspended)
	if (!UiTimer.IsSuspended() )
	{
		`LOG("Turn Reset attempted to Resume a Mission Timer which isn't suspended",class'X2DownloadableContentInfo_WOTC_Rulers_Pause_Timers'.default.bEnableLogging,'WOTC_RulersPauseTimers');
		return;
	}

	//timer exists, we can change it either suspend or resume	//bResumeMissionTimer false is paused	//bResumeMissionTimer true is continue
	UiTimer.SuspendTimer(true, NewGameState);
	`LOG("Effect Removed :: Either OnDeath or NewRound :: Timer Resumed",class'X2DownloadableContentInfo_WOTC_Rulers_Pause_Timers'.default.bEnableLogging,'WOTC_RulersPauseTimers');

}

