//*******************************************************************************************
//  FILE:   X2DownloadableContentInfo_WOTC_Rulers_Pause_Timers
//  
//	File created by RustyDios	10/01/20	12:00	
//	LAST UPDATED				14/01/20	23:00
//
//	OPTC script to add the extra abilities to any template on the config list
//	Contains extra command for use in the console
//
//*******************************************************************************************

class X2DownloadableContentInfo_WOTC_Rulers_Pause_Timers extends X2DownloadableContentInfo config (RulersPauseTimers);

//var config stuffs
var config array<name> RulerTemplates;
var config bool bCreatePassiveIcon;

var config bool bEnableLogging;

static event OnLoadedSavedGame(){}

static event InstallNewCampaign(XComGameState StartState){}

//************************
//	OPTC Code
//************************

static event OnPostTemplatesCreated()
{
	local X2CharacterTemplate			Template;
	local X2CharacterTemplateManager	AllCharacters;

	local array<name>					ChosenTemplates;

	local int r, c;

	//list of all character templates
	AllCharacters = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();

	//for each item on the list
	for (r = 0; r <= default.RulerTemplates.Length ; ++r )
	{
		//find the template
		Template = AllCharacters.FindCharacterTemplate(default.RulerTemplates[r]);

		//ensure the template exists
		if (Template != none)
		{
			//add the abilities	//RulerEngaged adds RulerDefeatedEscape
			Template.Abilities.AddItem('RulerEngaged');
				
			if (default.bCreatePassiveIcon)
			{
				Template.Abilities.AddItem('RulersPauseTimersPassive');
			}

			//output patch to log
			`LOG("Template Patched With Timer Suspend --Abilities-- :: " @Template.DataName ,default.bEnableLogging,'WOTC_RulersPauseTimers');
		}

	}//end for loop
	
	//create the chosen templates array
	//hardcode list that recieve ONLY the passive icon, if passive icons are on.. as they already have timer suspend abilities
	ChosenTemplates.AddItem('ChosenAssassin');
	ChosenTemplates.AddItem('ChosenAssassinM2');
	ChosenTemplates.AddItem('ChosenAssassinM3');
	ChosenTemplates.AddItem('ChosenAssassinM4');
	
	ChosenTemplates.AddItem('ChosenWarlock');
	ChosenTemplates.AddItem('ChosenWarlockM2');
	ChosenTemplates.AddItem('ChosenWarlockM3');
	ChosenTemplates.AddItem('ChosenWarlockM4');
	
	ChosenTemplates.AddItem('ChosenSniper');
	ChosenTemplates.AddItem('ChosenSniperM2');
	ChosenTemplates.AddItem('ChosenSniperM3');
	ChosenTemplates.AddItem('ChosenSniperM4');

	//for each item on the list
	for (c = 0; c <= ChosenTemplates.Length ; ++c )
	{
		//find the template
		Template = AllCharacters.FindCharacterTemplate(ChosenTemplates[c]);

		//ensure the template exists
		if (Template != none)
		{
			//if passive icons for the rulers were switched on, do so for the chosen too
			if (default.bCreatePassiveIcon)
			{
				Template.Abilities.AddItem('RulersPauseTimersPassive');

			//output patch to log
			`LOG("Template Patched With Timer Suspend -- Passive -- :: " @Template.DataName ,default.bEnableLogging,'WOTC_RulersPauseTimers');
			}
		}

	}//end for loop
	
}

//************************
//	NEW Console Command
//************************

//new console command for controlling the mission timer
exec function Timer_Suspend(bool bResumeMissionTimer = false)
{
	local XComGameState_UITimer UiTimer;
	local XComGameState			NewGameState;

	//grab the current mission timer
	UiTimer = XComGameState_UITimer(`XCOMHISTORY.GetSingleGameStateObjectForClass(class 'XComGameState_UITimer', true));

	//create a gamestate detailing this change
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(string(GetFuncName()));

	// ensure a timer exists - it kept crashing the game on missions without a timer
	if (UiTimer == none)
	{
		`LOG("CONSOLE :: Attempted to Suspend Mission Timer which does not exist",default.bEnableLogging,'WOTC_RulersPauseTimers');
		return;
	}
	
	//change the timer
	UiTimer.SuspendTimer(bResumeMissionTimer, NewGameState);

	//output to the log
	`LOG("CONSOLE :: Resume Mission Timer is :: " @bResumeMissionTimer,default.bEnableLogging,'WOTC_RulersPauseTimers');

	//ensure to submit the new gamestate
	SubmitNewGameState(NewGameState);

}

//***************
//	HELPER Funcs
//***************

//helper function to submit new game states        
protected static function SubmitNewGameState(out XComGameState NewGameState)
{
    local X2TacticalGameRuleset		TacticalRules;
    local XComGameStateHistory		History;
 
    if (NewGameState.GetNumGameStateObjects() > 0)
    {
        TacticalRules = `TACTICALRULES;
        TacticalRules.SubmitGameState(NewGameState);
    }
    else
    {
        History = `XCOMHISTORY;
        History.CleanupPendingGameState(NewGameState);
    }
}

//************************
//	End of file
//************************
