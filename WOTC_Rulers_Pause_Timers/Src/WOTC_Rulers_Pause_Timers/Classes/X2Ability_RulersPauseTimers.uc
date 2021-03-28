//*******************************************************************************************
//  FILE:   X2Ability_RulersPauseTimers
//  
//	File created by RustyDios	10/01/20	12:00	
//	LAST UPDATED				20/01/20	08:45
//
//	creates and contains the abilities for the timer pause auto-functions
//
//*******************************************************************************************

class X2Ability_RulersPauseTimers extends X2Ability config (RulersPauseTimers);

//var config stuffs
var config bool bTriggerOnXCOMSpotting;

//add the templates
static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	//create the enemy pause and resume abilities
	Templates.AddItem(CreateRulerEngaged());
	Templates.AddItem(CreateRulerDefeatedEscape());

	//adds the passive for display UI on enemies (YetAnotherF1)
	Templates.AddItem(PurePassive('RulersPauseTimersPassive', "img:///UILibrary_PerkIcons.UIPerk_timeshift", true, 'eAbilitySource_Commander') );

	return Templates;
}

//create the templates
// Unit is Engaged ... when the unit has LoS to a non-concealed XCOM unit
static function X2AbilityTemplate CreateRulerEngaged()
{
	local X2AbilityTemplate					Template;
	local X2AbilityTrigger_EventListener	Trigger;

	local X2Condition_UnitProperty			ShooterProperty, TargetProperty;
	local X2Condition_CheckTimer			TimerCheck;

	local X2Condition_Visibility			VisibilityCondition;
	local X2Effect_RulerspauseTimers		MissionTimerEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'RulerEngaged');

	// setup
	Template.AbilitySourceName = 'eAbilitySource_Commander';
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_timeshift";
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;

	Template.Hostility = eHostility_Neutral;

	Template.bDisplayInUITooltip = false;
	Template.bDisplayInUITacticalText = false;
	Template.bDontDisplayInAbilitySummary = true;

	// targeting
	Template.AbilityToHitCalc = default.DeadEye;

	// Single Target Style
	//Template.AbilityTargetStyle = default.SimpleSingleTarget; //< this thing has OnlyIncludeTargetsInsideWeaponRange=true which we don't want, we have no weapon range!
	Template.AbilityTargetStyle = new class'X2AbilityTarget_Single';

	// trigger when the source unit 'sees' a target unit
	// creates an 'instant' effect of pausing the timer
	Trigger = new class'X2AbilityTrigger_EventListener';
    Trigger.ListenerData.EventID = 'UnitSeesUnit';
	Trigger.ListenerData.Priority = 42;
    Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
    Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.SolaceCleanseListener;//class'XComGameState_Ability'.static.AbilityTriggerEventListener_UnitSeesUnit
    Template.AbilityTriggers.AddItem(Trigger);

	// also trigger again at the end of the 'players turn', just in case anyone is still alive and the timer isn't suspended and it should be
	// so basically this trigger catches any units with RPT still in play, after a death has resumed it
	Trigger = new class'X2AbilityTrigger_EventListener';
    Trigger.ListenerData.EventID = 'PlayerTurnEnded';
	Trigger.ListenerData.Priority = 42;
    Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
    Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.SolaceCleanseListener;//class'XComGameState_Ability'.static.AbilityTriggerEventListener_UnitSeesUnit
    Template.AbilityTriggers.AddItem(Trigger);

	// SHOOTER conditions :: Only apply ability when source unit is alive, 
	ShooterProperty = new class'X2Condition_UnitProperty';
	ShooterProperty.ExcludeAlive = false;
	ShooterProperty.ExcludeDead = true;
	ShooterProperty.ExcludeUnrevealedAI = !default.bTriggerOnXCOMSpotting;
	Template.AbilityShooterConditions.AddItem(ShooterProperty);

	// TARGET conditions :: ensure target is alive and player controlled, is alive and Hostile
	TargetProperty = new class'X2Condition_UnitProperty';
	TargetProperty.TreatMindControlledSquadmateAsHostile = true;
	TargetProperty.ExcludeFriendlyToSource = true;
	TargetProperty.ExcludeHostileToSource = false;
	TargetProperty.ExcludeDead = true;
	TargetProperty.IsPlayerControlled = true;
	TargetProperty.ExcludeConcealed = false;
	Template.AbilityTargetConditions.AddItem(TargetProperty);

	// check the timer is not already suspended
	TimerCheck = new class'X2Condition_CheckTimer';//returns AA_Success if not suspended.. AA_AbilityUnavailable if it is
	TimerCheck.bCheckNOTSuspended = true;
	Template.AbilityTargetConditions.AddItem(TimerCheck);

	// Can only apply this to targets we can 'see' 
	VisibilityCondition = new class'X2Condition_Visibility';
	VisibilityCondition.bRequireBasicVisibility = true;
	Template.AbilityTargetConditions.AddItem(VisibilityCondition);

	// suspend the mission timer !!
	// MissionTimerEffect = new class'X2Effect_SuspendMissionTimer';
	MissionTimerEffect = new class'X2Effect_RulersPauseTimers';
	MissionTimerEffect.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnBegin);//iNumTurns, bInfiniteDuration, bRemoveWhenSourceDies, bIgnorePlayerCheckOnTick, watchrule
	MissionTimerEffect.bResumeMissionTimer = false;
	MissionTimerEffect.EffectName = 'RulersPauseTimers';
		// remove effect when source dies
	MissionTimerEffect.bIsDeathSwitch = false;
	MissionTimerEffect.bRemoveWhenSourceDies = true;
		// refresh the effect instead of making a new one
	MissionTimerEffect.DuplicateResponse = eDupe_Refresh;
		// keep tabs on the effect... its a highlander !! THERE CAN BE ONLY ONE !!
		// also no display bonus, players just need to know it switches sources correctly 
		// if there is at least one left in 'visual range'
	MissionTimerEffect.bUniqueTarget = true;
	MissionTimerEffect.bDupeForSameSourceOnly = false;
	//MissionTimerEffect.SetDisplayInfo(ePerkBuff_Bonus,"RPT TESTING ENGAGED","This unit is the cause of the current time suspension",Template.IconImage,true,,Template.AbilitySourceName);
	Template.AddShooterEffect(MissionTimerEffect);

	// visualization and stuffs
	Template.bSkipFireAction = true;
	Template.FrameAbilityCameraType = eCameraFraming_Never;
	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = none;       //  NOTE: no visualization on purpose!

	Template.AssociatedPlayTiming = SPT_AfterSequential;

	// add the resume abilities by default 
	Template.AdditionalAbilities.AddItem('RulerDefeatedEscape');

	return Template;
}


// create the resume timer ability on 'death' of the unit
static function X2AbilityTemplate CreateRulerDefeatedEscape()
{
	local X2AbilityTemplate					Template;
	local X2AbilityTrigger_EventListener	Trigger;

	local X2Condition_CheckTimer			TimerCheck;

	local X2Effect_RulersPauseTimers		MissionTimerEffect;
	local X2Effect_RemoveEffects			RemoveEffects;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'RulerDefeatedEscape');

	// setup
	Template.AbilitySourceName = 'eAbilitySource_Commander';
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_timeshift";
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;

	Template.Hostility = eHostility_Neutral;

	Template.bDisplayInUITooltip = false;
	Template.bDisplayInUITacticalText = false;
	Template.bDontDisplayInAbilitySummary = true;

	// targeting
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityMultiTargetStyle = new class'X2AbilityMultiTarget_AllUnits';

	// listen for my own 'death' .. escape.. end of play .. whatever..
	// this 'works' fine because even after death any units still in play with RPT will 'reset' the effect for any unit they see 
	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.Filter = eFilter_Unit;
	Trigger.ListenerData.EventID = 'UnitDied';
	Trigger.ListenerData.Priority = 69;
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	Template.AbilityTriggers.AddItem(Trigger);

	// check the timer is already suspended
	TimerCheck = new class'X2Condition_CheckTimer';//returns AA_Success if suspended.. AA_AbilityUnavailable if it isn't
	TimerCheck.bCheckSuspended = true;
	Template.AbilityTargetConditions.AddItem(TimerCheck);

	// resume the timer!
	// MissionTimerEffect = new class'X2Effect_SuspendMissionTimer';
	MissionTimerEffect = new class'X2Effect_RulersPauseTimers';
	MissionTimerEffect.bResumeMissionTimer = true;
	MissionTimerEffect.EffectName = 'RulersPauseTimers';
		// remove effect when source dies
	MissionTimerEffect.bIsDeathSwitch = true;
	MissionTimerEffect.bRemoveWhenSourceDies = true;
		// don't refresh.. we want this to override
	//MissionTimerEffect.DuplicateResponse = eDupe_Refresh;
		// keep tabs on the effect... its a highlander !! THERE CAN BE ONLY ONE !!
	MissionTimerEffect.bUniqueTarget = true;
	MissionTimerEffect.bDupeForSameSourceOnly = false;
	//MissionTimerEffect.SetDisplayInfo(ePerkBuff_Bonus,"RPT TESTING DEATH","This unit is the cause of the current time suspension",Template.IconImage,true,,Template.AbilitySourceName);
	Template.AddShooterEffect(MissionTimerEffect);

	// REMOVE the effect!!
	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.EffectNamesToRemove.AddItem('RulersPauseTimers');
	RemoveEffects.bCleanse = true;
	Template.AddMultiTargetEffect(RemoveEffects);

	// visualization and stuffs
	Template.bSkipFireAction = true;
	Template.FrameAbilityCameraType = eCameraFraming_Never;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = none;       //  NOTE: no visualization on purpose!

	return Template;
}

//*************
//*************
