statemachine abstract import class CR4Player extends CPlayer
{ 
	// BEHAVIOR INITIALIZATION
	protected 		var pcGamePlayInitialized			: bool;					// MS: hack variable to fix Tpose when initially spawning Geralt (Consult Tomsin)

	// PC Controls
	private 		var pcMode							: bool;					// MS: Use control/camera modifications for keyboard/mouse
	default pcMode = true;

	// COMBAT MECHANICS	
	protected saved	var weaponHolster					: WeaponHolster;		// Makes Geralt holster and unholster the swords
	public			var rangedWeapon					: Crossbow;				// Handles ranged weapons
	public			var crossbowDontPopStateHack		: bool; 				default crossbowDontPopStateHack = false;
	
	private			var hitReactTransScale				: float;  				//dynamic scale for npc's hitreaction animation translation to force CloseCombat
	
	private			var bIsCombatActionAllowed			: bool;
	private			var currentCombatAction				: EBufferActionType;
	
	private			var uninterruptedHitsCount 			: int;					//amount of uninterrupted hints performed by the player (gets reset when we get hit or stop attacking etc.)
	private 		var uninterruptedHitsCameraStarted 	: bool;					//set to true once we enable the uninterrupted hits camera effect
	private 		var uninterruptedHitsCurrentCameraEffect : name;			//currently used camera blurr effect for uninterrupted hits
	
	private 		var counterTimestamps				: array<EngineTime>;	//times when player pressed counter attack button - we check it later to prevent spamming
	
	private 		var hitReactionEffect 				: bool;					//blurr
	
	private			var lookAtPosition					: Vector; 				//Position that Geralt is looking at, also where he will shoot
	private			var orientationTarget				: EOrientationTarget;
	private			var customOrientationTarget			: EOrientationTarget;
	protected 		var customOrientationStack 			: array<SCustomOrientationParams>;
	
	public 			var delayOrientationChange 			: bool;
	protected 		var delayCameraOrientationChange 	: bool;
	private 		var actionType	 					: int; // 0 = sign, 1 = guard, 2 = specialAttack, 3 = throwItem
	private 		var customOrientationStackIndex		: int; //Used by Player only: will disable the previous combat action's orientation target and add to the stack everytime he performs a new combat action 
	
	private 		var emptyMoveTargetTimer			: float;
	
	private 		var onlyOneEnemyLeft 				: bool;
	
	public	 		var isInFinisher 					: bool;
	private 		var finisherTarget 					: CGameplayEntity;

	private			var combatStance					: EPlayerCombatStance;	

	public			var approachAttack					: int;					//Enable/Disable approach attack prototype, 0 = enabled, 1 = disabled with no far attack limit, 2 = disabled with far attack limit
					default approachAttack 				= 1;
	protected		var specialAttackCamera 			: bool;
	
	private			var specialAttackTimeRatio		 	: float;
		
	public saved	var itemsPerLevel					: array<name>; 	
	public   		var itemsPerLevelGiven				: array<bool>; 	
	
	private			var	playerTickTimerPhase			: int;
		default playerTickTimerPhase = 0;
		
	protected 		var evadeHeading					: float;

	public			var vehicleCbtMgrAiming				: bool;		//MS: hack variable to pass vehicleCbtMgr aiming variable to UseGenericVehicle
	
	public			var specialHeavyChargeDuration		: float;				//duration of charge-up event 
	public 			var specialHeavyStartEngineTime 	: EngineTime;			//timestamp of when the charge-up started
	public 			var playedSpecialAttackMissingResourceSound : bool;			//if missing resource sound was played or not (used in loop)
	public function SetPlayedSpecialAttackMissingResourceSound(b : bool) {playedSpecialAttackMissingResourceSound = b;}
	
	public var counterCollisionGroupNames : array<name>;
	
	public saved	var lastInstantKillTime				: GameTime;
	
	// Save locks
	private 		var noSaveLockCombatActionName		: string;		default	noSaveLockCombatActionName	= 'combat_action';	
	private 		var noSaveLockCombatAction			: int;	
	private 		var deathNoSaveLock					: int;	
	private			var noSaveLock						: int;
	
	//new game plus
	protected saved var newGamePlusInitialized			: bool;
		default newGamePlusInitialized = false;
	
	//  action buffer
	protected			var BufferAllSteps					: bool;
	protected			var BufferCombatAction				: EBufferActionType;
	protected			var BufferButtonStage				: EButtonStage;	
	
		default BufferAllSteps = false;	
		default	customOrientationTarget = OT_None;	
		default hitReactionEffect = true;	
		default uninterruptedHitsCount = 0;
		default uninterruptedHitsCameraStarted = false;	
		default customOrientationStackIndex = -1;
			
	// CRITICAL STATES
	private var keepRequestingCriticalAnimStart : bool;				//set to true while we are trying to start critical anim
	
		default keepRequestingCriticalAnimStart = false;
	
	// EXPLORATION
	private		var currentCustomAction		: EPlayerExplorationAction;
	public		var substateManager			: CExplorationStateManager;
	protected	var isOnBoat				: bool;							//set to true if player is on boat (but not necessarily sailing, but e.g. standing)
	protected	var isInShallowWater 		: bool;
	public		var medallion				: W3MedallionFX;
	protected	var lastMedallionEffect 	: float;
	private		var isInRunAnimation		: bool;
	public		var	interiorTracker			:CPlayerInteriorTracker;
	public		var m_SettlementBlockCanter : int;
	
	
	// FISTFIGHT MINIGAME
	private var fistFightMinigameEnabled	: bool;
	private var isFFMinigameToTheDeath		: bool;
	private var FFMinigameEndsithBS			: bool;
	public 	var fistFightTeleportNode		: CNode;
	public  var isStartingFistFightMinigame : bool;
	public  var GeraltMaxHealth 			: float;
	public  var fistsItems					: array< SItemUniqueId >;
	
		default FFMinigameEndsithBS = false;
		default fistFightMinigameEnabled = false;
		default isFFMinigameToTheDeath = false;
	
	// GWINT MINIGAME
	private var gwintAiDifficulty			: EGwintDifficultyMode;	default gwintAiDifficulty = EGDM_Easy;
	private var gwintAiAggression			: EGwintAggressionMode;	default gwintAiAggression = EGAM_Defensive;
	private var gwintMinigameState			: EMinigameState;		default gwintMinigameState  = EMS_None;

	// HORSE
	import private 	var horseWithInventory 		: EntityHandle;			// if spawned handle is valid ( horse with inventory )
	private 		var currentlyMountedHorse	: CNewNPC;	
	private			var horseSummonTimeStamp	: float;
	private saved	var isHorseRacing			: bool;
	private 		var horseCombatSlowMo		: bool;
	default isHorseRacing = false;
	default horseCombatSlowMo = true;
	
	// HUD	FIXME - shouldn't this all be in hud / ui rather than player?
	private var HudMessages : array <string>; //#B change to struct with message type, message duration etc
	protected var fShowToLowStaminaIndication	: float;
	public var showTooLowAdrenaline : bool;
	private var HAXE3Container : W3Container; //#B temp for E3
	private var HAXE3bAutoLoot: bool; //#B temp for E3
	private var bShowHud : bool;
	private var dodgeFeedbackTarget : CActor;
	
		default HAXE3bAutoLoot = false;
		default fShowToLowStaminaIndication	= 0.0f;	
		default bShowHud = true;
		
	saved var displayedQuestsGUID : array< CGUID >; // #B moved here because saved in journal doesn't work.
	saved var rewardsMultiplier : array< SRewardMultiplier >; // #B moved here because saved in journal doesn't work.s
	saved var glossaryImageOverride : array< SGlossaryImageOverride >; // #B moved here because saved in journal doesn't work.s
	
	// INPUT
	private 			var prevRawLeftJoyRot 			: float;
	protected 			var explorationInputContext		: name;
	protected			var combatInputContext 			: name;
	protected			var combatFistsInputContext		: name;

	// INTERACTIONS
	private var isInsideInteraction 		: bool;							//set to true when player is inside any interaction range, used to prioritize input 
	private var isInsideHorseInteraction 	: bool;							
	public	var horseInteractionSource 		: CEntity;
	public 	var nearbyLockedContainersNoKey : array<W3LockableEntity>;		//to update tooltip if player is close to a locked container and is THEN given a key
	
	// MOVEMENT
	private	var bMoveTargetChangeAllowed	: bool;		default bMoveTargetChangeAllowed = true;
	private var moveAdj 					: CMovementAdjustor;
	private var defaultLocomotionController	: CR4LocomotionPlayerControllerScript;
	//private var isFollowing					: bool;
	//private var followingStartTime			: float;
	private var canFollowNpc 				: bool;
	private var actorToFollow 				: CActor;
	public var terrainPitch					: float;
	public var steepSlopeNormalPitch		: float; 	default steepSlopeNormalPitch = 65.f;
	public var disableSprintTerrainPitch	: float; 	default disableSprintTerrainPitch = 54.f;
	private var submergeDepth			: float;
	
	private var m_useSelectedItemIfSpawned 	: bool; default m_useSelectedItemIfSpawned = false; // Used only in WaitForItemSpawnAndProccesTask
	
	
	var navQuery : CNavigationReachabilityQueryInterface;
	
	// BARBER
	public saved var rememberedCustomHead : name;

	// WEATHER DISPLAY
	public saved var disableWeatherDisplay : bool;
	
	// EPISODE1
	public saved var proudWalk : bool;
	private var etherealCount : int; 
	default etherealCount = 0;
	
	// EPISODE2
	public saved var injuredWalk : bool;
	public saved var tiedWalk : bool;
	private var insideDiveAttackArea : bool;
	default insideDiveAttackArea = false;
	private var diveAreaNumber : int;
	default diveAreaNumber = -1;
	
	// CAMERA
	private var flyingBossCamera : bool;
	default flyingBossCamera = false;
	
	public function SetFlyingBossCamera( val : bool ) { flyingBossCamera = val; }
	public function GetFlyingBossCamera() : bool { return flyingBossCamera; }
	
	// TOOLTIP
	public saved var upscaledTooltipState : bool;
	default upscaledTooltipState = false;
	
	// PHANTOM WEAPON
	private var phantomWeaponMgr : CPhantomWeaponManager;
	
	/*public var	bonePositionCam 	: Vector;
	
	public function SetBonePositionCam( pos : Vector )
	{
		bonePositionCam	= pos;
	}*/

	function EnablePCMode( flag : bool )
	{
		pcMode = flag;
	}
	
	public function IsPCModeEnabled() : bool
	{
		return pcMode && theInput.LastUsedPCInput();
	}	
	
	public function ShouldUsePCModeTargeting() : bool
	{
		return IsPCModeEnabled() && !lastAxisInputIsMovement;
	}		
	
	public function SetDodgeFeedbackTarget( target : CActor )
	{
		dodgeFeedbackTarget = target;
	}

	public function GetDodgeFeedbackTarget() : CActor
	{
		return dodgeFeedbackTarget;
	}
	
	public function SetSubmergeDepth( depth : float )
	{
		submergeDepth = depth;
	}

	public function GetSubmergeDepth() : float
	{
		return submergeDepth;
	}	
	
	// ONELINERS
	editable var delayBetweenIllusionOneliners : float;
		
		hint delayBetweenIllusionOneliners = "delay in secs between oneliners about illusionary objects";
		
		default delayBetweenIllusionOneliners = 5;
	
	// Battlecry
	private			var battlecry_timeForNext			: float;
	private 		var battlecry_delayMin				: float;	default battlecry_delayMin = 15;
	private 		var battlecry_delayMax				: float;	default battlecry_delayMax = 60;
	private			var battlecry_lastTry				: name;
	
	// Weather	
	private 		var previousWeather 				: name;
	private 		var previousRainStrength			: float;
	
	//OTHER
	protected var receivedDamageInCombat	: bool;			//set when you got hit
	protected var prevDayNightIsNight		: bool;			//Day-Night cycle check - value of previous check
	public	var failedFundamentalsFirstAchievementCondition : bool;		//achievement
	
	private var spawnedTime					: float;

	public	var currentMonsterHuntInvestigationArea : W3MonsterHuntInvestigationArea;		

	private var isPerformingPhaseChangeAnimation : bool;	// flag for suppressing game camera update during synced animation in eredin fight
	default isPerformingPhaseChangeAnimation = false;
	
		default receivedDamageInCombat = false;
		
	// PLAYER MODE
	public 			 	var playerMode					: W3PlayerMode;	
		
	// QUICKSLOTS
	protected saved	var selectedItemId					: SItemUniqueId;	//id of item selected from quickslots
	protected saved var blockedRadialSlots				: array < SRadialSlotDef >; // radial menu slots blocked by different sources
	
	// SOFT LOCK TARGETING
	public				var enemyCollectionDist			: float;
	public  			var findMoveTargetDistMin		: float;			//distance from player to get softlocked targets
	public 				var findMoveTargetDistMax		: float;			//distance from player that target gets disengaged from soft lock
	private				var findMoveTargetScaledFrame	: float;			//xaxis scale to find non-hostile targets when stationary
	public 				var interactDist				: float;			//distance from player to attack or interact with a non-hostile npc
	protected			var bCanFindTarget				: bool;
	private				var bIsConfirmingEmptyTarget	: bool;
	private 			var displayTarget				: CGameplayEntity;	//entity to show health bar on hud;
	private				var isShootingFriendly			: bool;
	
		default findMoveTargetDistMax = 18.f;
		default findMoveTargetScaledFrame = 0.5f;
		default interactDist = 3.5f;
	
	//Target Selection
	private var currentSelectedTarget			: CActor; 
	private var selectedTargetToConfirm			: CActor;
	private var bConfirmTargetTimerIsEnabled 	: bool;
		
	// THROWABLES	
	public saved 		var thrownEntityHandle			: EntityHandle;		//entity of currently thrown item (in aiming)	
	private 			var isThrowingItemWithAim 		: bool;
	private	saved		var isThrowingItem				: bool;				//used for aim mode to check if we're in throwing logic
	private 			var isThrowHoldPressed			: bool;
	
	// CROSSBOW
	private				var isAimingCrossbow			: bool;
	
		default isThrowingItemWithAim = false;
		
	// AIMING MODE
	public				var playerAiming				: PlayerAiming;
			
	// DISMEMBERMENT
	public var forceDismember 			: bool;
	public var forceDismemberName 		: name;
	public var forceDismemberChance 	: int;
	public var forceDismemberExplosion 	: bool;
	
	// FINISHER
	private var finisherVictim 			: CActor;
	public var forceFinisher 			: bool;
	public var forceFinisherAnimName 	: name;
	public var forceFinisherChance 		: int;	
	public var forcedStance		 		: bool;	

	// WEAPON COLLISION FX
	private var m_WeaponFXCollisionGroupNames 	: array <name>;
	private var m_CollisionEffect 				: CEntity;
	private var m_LastWeaponTipPos				: Vector;
	private var m_CollisionFxTemplate 			: CEntityTemplate;
	private var m_RefreshWeaponFXType			: bool;
	private var m_PlayWoodenFX					: bool;
	
	// POSTERS
	private var m_activePoster					: W3Poster;
	
	public function SetActivePoster ( poster :  W3Poster )
	{
		m_activePoster = poster;
	}
	
	public function RemoveActivePoster () 
	{
		m_activePoster = NULL;
	}
	
	public function GetActivePoster () : W3Poster
	{
		return m_activePoster;
	}
	// SAVE / LOAD
	//private saved var safePositionStored: bool;			default safePositionStored = false;
	//private saved var lastSafePosition	: Vector;
	//private saved var lastSafeRotation	: EulerAngles;
	
	public var horseOnNavMesh : bool;
	default horseOnNavMesh = true;
	
	public function SetHorseNav( val : bool ) { horseOnNavMesh = val; }
	
	// TEST
	public var testAdjustRequestedMovementDirection : bool; // TEST
		default testAdjustRequestedMovementDirection = false;
		
	// State
	default	autoState	= 'Exploration';
	
	///////////////////////////////////////////////////////////////////////////
	///////////////////  IMPORTED C++ FUNCTIONS  //////////////////////////////
	///////////////////////////////////////////////////////////////////////////
	
	// All following functions give cached data from previous frame
	import final function GetEnemiesInRange( out enemies : array< CActor > );
	import final function GetVisibleEnemies( out enemies : array< CActor > );
	import final function IsEnemyVisible( enemy : CActor ) : bool;
	
	// Set this up in order to use above functions and get the proper data
	import final function SetupEnemiesCollection(	range, heightTolerance	: float,
													maxEnemies				: int,
													optional tag			: name,
													optional flags			: int ); // please combine EScriptQueryFlags - FLAG_ExcludePlayer is always on

	import final function IsInInterior() : bool;
	import final function IsInSettlement() : bool;
	import final function EnterSettlement( isEntering : bool );
	import final function ActionDirectControl( controller : CR4LocomotionDirectController ) : bool;
	import final function SetPlayerTarget( target : CActor );
	import final function SetPlayerCombatTarget( target : CActor );
	import final function ObtainTicketFromCombatTarget( ticketName : CName, ticketsCount : int );
	import final function FreeTicketAtCombatTarget();
	import final function SetScriptMoveTarget( target : CActor );
	import final function GetRiderData() : CAIStorageRiderData;
	import final function SetIsInCombat( inCombat : bool );
	import final function SaveLastMountedHorse( mountedHorse : CActor );
	
	import final function SetBacklightFromHealth( healthPercentage : float );
	import private final function SetBacklightColor( color : Vector );
	
	import final function GetCombatDataComponent() : CCombatDataComponent;
	
	import final function GetTemplatePathAndAppearance( out templatePath : string, out appearance : name );
	
	import final function HACK_BoatDismountPositionCorrection( slotPos : Vector );
	
	import final function HACK_ForceGetBonePosition( boneIndex : int ) : Vector;
	
	
	public function GetLevel() : int
	{
		return 0;
	}
	
	///////////////////////////////////////////////////////////////////////////
	// (new) targeting
	
	var targeting				: CR4PlayerTargeting;
	var targetingPrecalcs		: SR4PlayerTargetingPrecalcs;
	var targetingIn				: SR4PlayerTargetingIn;
	var targetingOut			: SR4PlayerTargetingOut;	
	var useNativeTargeting		: bool;
	default useNativeTargeting	= true;
	
	var visibleActors			: array< CActor >;
	var visibleActorsTime		: array< float >;
	
	///////////////////////////////////////////////////////////////////////////
		
	event OnSpawned( spawnData : SEntitySpawnData )
	{
		var atts : array<name>;
		var skill : ESkill;
		var i : int;
		var item : SItemUniqueId;
		
		AddAnimEventCallback('ThrowHoldTest',			'OnAnimEvent_ThrowHoldTest');
		AddAnimEventCallback('OnWeaponDrawReady',		'OnAnimEvent_OnWeaponDrawReady');
		AddAnimEventCallback('OnWeaponHolsterReady',	'OnAnimEvent_OnWeaponHolsterReady');
		AddAnimEventCallback('AllowTempLookAt',			'OnAnimEvent_AllowTempLookAt');
		AddAnimEventCallback('SlideToTarget',			'OnAnimEvent_SlideToTarget');
		AddAnimEventCallback('PlayFinisherBlood',		'OnAnimEvent_PlayFinisherBlood');
		AddAnimEventCallback('SlowMo',					'OnAnimEvent_SlowMo');
		AddAnimEventCallback('BloodTrailForced',		'OnAnimEvent_BloodTrailForced');
		AddAnimEventCallback('FadeOut',					'OnAnimEvent_FadeOut');
		AddAnimEventCallback('FadeIn',					'OnAnimEvent_FadeIn');
		AddAnimEventCallback('DisallowHitAnim',			'OnAnimEvent_DisallowHitAnim');
		AddAnimEventCallback('AllowFall',				'OnAnimEvent_AllowFall');
		AddAnimEventCallback('AllowFall2',				'OnAnimEvent_AllowFall2');	
		AddAnimEventCallback('DettachGround',			'OnAnimEvent_DettachGround');	
		AddAnimEventCallback('KillWithRagdoll',			'OnAnimEvent_KillWithRagdoll');	
		AddAnimEventCallback('pad_vibration',			'OnAnimEvent_pad_vibration');	
		AddAnimEventCallback('pad_vibration_light',		'OnAnimEvent_pad_vibration_light');
		AddAnimEventCallback('RemoveBurning',			'OnAnimEvent_RemoveBurning');
		AddAnimEventCallback('RemoveTangled',			'OnAnimEvent_RemoveTangled');
		AddAnimEventCallback('MoveNoise',				'OnAnimEvent_MoveNoise');
		
		AddItemPerLevelList();
		
		enemyCollectionDist = findMoveTargetDistMax;
		
		//retrofix - removing saved timescale
		theGame.RemoveTimeScale('horse_melee');
		
		//give items
		if(!spawnData.restored && !((W3ReplacerCiri)this) )
		{
			AddTimer('GiveStartingItems', 0.00001, true, , , true);
			
			if(!theGame.IsFinalBuild())
			{
				//unlock skills for testing purposes
				AddAbility('GeraltSkills_Testing');				
				AddTimer('Debug_GiveTestingItems',0.0001,true);			
			}
			
			//disable retro-stash-tutorial on fresh playthroughs
			FactsAdd("tut_stash_fresh_playthrough");
		}
		
		InitTargeting();
		
		// After load
		if( spawnData.restored )
		{
			// ED this line was not called before, because of extra if conditions regarding "safe position stored"  but it was uncommented
			//OnUseSelectedItem();	
			
			theGame.GameplayFactsRemove( "in_combat" );
		}
		
		
		// Create the sword holster (it is a saved property, there is no need of re-creating it when playing from save)
		if ( !weaponHolster )
		{
			weaponHolster = new WeaponHolster in this;
		}		
		// temp workaround of not saving states:
		weaponHolster.Initialize( this, spawnData.restored );
		
		if ( !interiorTracker )
		{
			interiorTracker = new CPlayerInteriorTracker in this;
		}
		interiorTracker.Init( spawnData.restored );
		
		
		super.OnSpawned( spawnData );

		// Create medallion
		medallion = new W3MedallionFX in this;
		
		playerMode = new W3PlayerMode in this;
		playerMode.Initialize( this );
		
		// Initialize Aiming Mode
		playerAiming = new PlayerAiming in this;
		playerAiming.Initialize( this );
		
		// Initialize reachability query
		navQuery = new CNavigationReachabilityQueryInterface in this;
		
		// Start looking for soft-lock targets
		EnableFindTarget( true );
		AddTimer( 'CombatCheck', 0.2f, true );
		
		// Get the exploration state manager component
		substateManager	= ( CExplorationStateManager ) GetComponentByClassName( 'CExplorationStateManager' );
		
		findMoveTargetDist = findMoveTargetDistMax;
		
		SetupEnemiesCollection( enemyCollectionDist, findMoveTargetDist, 10, 'None', FLAG_Attitude_Neutral + FLAG_Attitude_Hostile + FLAG_Attitude_Friendly + FLAG_OnlyAliveActors );
		
		//for geralt-replacer switching
		inputHandler.RemoveLocksOnSpawn();
		
		// Player has the lowest push priority
		((CActor) this ).SetInteractionPriority( IP_Prio_0 );
		
		prevDayNightIsNight = theGame.envMgr.IsNight();
		CheckDayNightCycle();
		
		// Debug
		EnableVisualDebug( SHOW_AI, true );
		
		//oneliners delay
		FactsRemove("blocked_illusion_oneliner");	
		
		SetFailedFundamentalsFirstAchievementCondition(false);
		m_CollisionFxTemplate 	= (CEntityTemplate) LoadResource( 'sword_colision_fx' );
		if( m_WeaponFXCollisionGroupNames.Size() == 0 )
		{
			m_WeaponFXCollisionGroupNames.PushBack('Static');
			m_WeaponFXCollisionGroupNames.PushBack('Foliage');
			m_WeaponFXCollisionGroupNames.PushBack('Fence');
			m_WeaponFXCollisionGroupNames.PushBack('BoatSide');
			m_WeaponFXCollisionGroupNames.PushBack('Door');
			m_WeaponFXCollisionGroupNames.PushBack('RigidBody');
			m_WeaponFXCollisionGroupNames.PushBack('Dynamic');
			m_WeaponFXCollisionGroupNames.PushBack('Destructible');
		}
		
		if ( counterCollisionGroupNames.Size() == 0 ) 
		{
			counterCollisionGroupNames.PushBack('Static');
			counterCollisionGroupNames.PushBack('Foliage');
			counterCollisionGroupNames.PushBack('Fence');
			counterCollisionGroupNames.PushBack('Terrain');
			counterCollisionGroupNames.PushBack('Door');
			counterCollisionGroupNames.PushBack('RigidBody');
			counterCollisionGroupNames.PushBack('Dynamic');
			counterCollisionGroupNames.PushBack('Destructible');
		}
		
		//ps4 pad backlight color
		ResetPadBacklightColor();
		
		if( spawnData.restored )
		{
			if (IsCurrentlyUsingItemL())
			{
				if (inv.HasItemById( currentlyEquipedItemL ))
				{
					OnUseSelectedItem();
				}
				else
				{
					HideUsableItem(true);
				}
			}
			if ( GetCurrentMeleeWeaponType() == PW_Steel || GetCurrentMeleeWeaponType() == PW_Silver )
			{
				OnEquipMeleeWeapon(GetCurrentMeleeWeaponType(), true, true);
			}
			
			AddTimer( 'UnmountCrossbowTimer', 0.01, true );
			
			ClearBlockedSlots();
		}
		
		((CR4PlayerStateSwimming)this.GetState('Swimming')).OnParentSpawned();
		
		//hack for possible immortality from finishers
		SetImmortalityMode( AIM_None, AIC_SyncedAnim );
		
		//disable Dimeritium Bomb skill locks after load
		theGame.GetDefinitionsManager().GetContainedAbilities('DwimeritiumBomb_3', atts);
		for(i=0; i<atts.Size(); i+=1)
		{
			skill = SkillNameToEnum(atts[i]);
			if(skill != S_SUndefined)
				BlockSkill(skill, false);		
		}
		
		// phantom weapon manager
		this.GetInventory().GetItemEquippedOnSlot( EES_SteelSword, item );
		if( this.GetInventory().ItemHasTag( item, 'PhantomWeapon' ) )
		{
			this.InitPhantomWeaponMgr();
		}

		//retoractive fix
		if(FactsQuerySum("mq3036_fact_done") > 0)
			BlockAllActions('mq3036', false);
		
		spawnedTime = theGame.GetEngineTimeAsSeconds();
		
		if ( theGame.GetInGameConfigWrapper().GetVarValue('Gameplay', 'EnableUberMovement' ) == "1" )
			theGame.EnableUberMovement( true );
		else
			theGame.EnableUberMovement( false );
		
		// Initial level for Gwint Difficulty (Normal)
		if ( !FactsDoesExist("gwent_difficulty") )
			FactsAdd("gwent_difficulty", 2);
			
		//NG+
		if(!newGamePlusInitialized && FactsQuerySum("NewGamePlus") > 0)
		{
			NewGamePlusInitialize();
		}
		
		//fix wrapped instant kill time stamp
		if( lastInstantKillTime > theGame.GetGameTime() )
		{
			SetLastInstantKillTime( GameTimeCreate(0) );
		}
	}
	
	public function NewGamePlusInitialize()
	{
		//reset instant kill cooldown
		SetLastInstantKillTime( GameTimeCreate(0) );
	}
	
	public function GetTimeSinceSpawned() : float
	{
		return theGame.GetEngineTimeAsSeconds() - spawnedTime;
	}
	
	timer function UnmountCrossbowTimer( dt : float, id : int )
	{
		var itemId : SItemUniqueId;
		
		itemId = this.inv.GetItemFromSlot( 'l_weapon' );
		if ( inv.IsIdValid( itemId ) && inv.IsItemCrossbow( itemId ) )
		{
			rangedWeapon = (Crossbow)( inv.GetItemEntityUnsafe( itemId ) );
			
			if (rangedWeapon)
			{	
				rangedWeapon.Initialize( (CActor)( rangedWeapon.GetParentEntity() ) );
				OnRangedForceHolster( true, true );
				RemoveTimer( 'UnmountCrossbowTimer' );
			}
		}
		else
			RemoveTimer( 'UnmountCrossbowTimer' );
	}
	
	event OnDestroyed()
	{
		playerAiming.RemoveAimingSloMo();
		
		if(rangedWeapon)
			rangedWeapon.ClearDeployedEntity(true);
			
		ResetPadBacklightColor();
		
		//remove combat mode no-save lock
		theGame.ReleaseNoSaveLock( noSaveLock );
	}
	
	/////////////////////////////////////////////////////////////////////
	////////////////////////Radial Menu//////////////////////////////////
	////////////////////////////////////////////////////////////////////
	
	public function GetBlockedSlots () : array < SRadialSlotDef >
	{
		return blockedRadialSlots;
	}
	
	public function  ClearBlockedSlots()
	{
		var i 				 : int;
		//var blockedSigns 	 : array<ESignType>;
		//var playerWitcher	 : W3PlayerWitcher;
		
		for ( i = 0; i < blockedRadialSlots.Size(); i+=1 )
		{
			if( !IsSwimming() )
			{
				if ( EnableRadialSlot(blockedRadialSlots[i].slotName, 'swimming'))
				{
					i-=1;
					continue;
				}
			}
			if (!IsUsingVehicle())
			{
				if ( EnableRadialSlot(blockedRadialSlots[i].slotName, 'useVehicle'))
				{
					i-=1;
					continue;
				}
			}
			if ( !IsCurrentlyUsingItemL() || !IsUsableItemLBlocked() )
			{
				if ( EnableRadialSlot(blockedRadialSlots[i].slotName, 'usableItemL'))
				{
					i-=1;
					continue;
				}
			}
			if ( !IsThrowingItem() )
			{
				if ( EnableRadialSlot(blockedRadialSlots[i].slotName, 'throwBomb'))
				{
					i-=1;
					continue;
				}
			}
		}
		// this is a hack that had to be added because someone ignored existing functionality of blocking radial slots propely and created BlockSignSelection. Unfortunately to keep the backwawrd compatibility I had to hack it.
		/*playerWitcher = (W3PlayerWitcher)this;
		
		if ( playerWitcher )
		{
			blockedSigns = playerWitcher.GetBlockedSigns();
			
			i = 0;
			for ( i = 0; i < blockedSigns.Size(); i+=1 )
			{
				switch( blockedSigns[i] )
				{
					case ST_Aard :
						if ( !IsRadialSlotBlocked ( 'Aard') )
						{
							playerWitcher.BlockSignSelection(ST_Aard, false);
						}
						break;
					case ST_Axii :
						if ( !IsRadialSlotBlocked ( 'Axii') )
						{
							playerWitcher.BlockSignSelection(ST_Axii, false );
						}
						break;
					case ST_Igni :
						if ( !IsRadialSlotBlocked ( 'Igni') )
						{
							playerWitcher.BlockSignSelection(ST_Igni, false );
						}
						break;
					case ST_Quen :
						if ( !IsRadialSlotBlocked ( 'Quen') )
						{
							playerWitcher.BlockSignSelection(ST_Quen, false );
						}
						break;
					case ST_Yrden :
						if ( !IsRadialSlotBlocked ( 'Yrden') )
						{
							playerWitcher.BlockSignSelection(ST_Yrden, false );
						}
						break;
					default:
						break;
				}
			}
		}*/	
		
	}
	
	public function RestoreBlockedSlots ()
	{
		var i : int;
		var slotsToBlock : array<name>;
		
		for ( i = 0; i < blockedRadialSlots.Size(); i+=1 )
		{
			slotsToBlock.PushBack ( blockedRadialSlots[i].slotName );
		}
		if ( slotsToBlock.Size() > 0 ) 
		{
			EnableRadialSlots ( false, slotsToBlock );
		}
	}
	private function DisableRadialSlot ( slotName : name, sourceName : name ) : bool
	{
		var i : int;
		var k : int;
		var slotsToBlock : array<name>;
		
		var blockedRadialSlotEntry : SRadialSlotDef;
		
		slotsToBlock.PushBack ( slotName );
		
		for ( i = 0; i < blockedRadialSlots.Size(); i+=1 )
		{
			if ( blockedRadialSlots[i].slotName == slotName )
			{
				if ( sourceName != '' )
				{
					for ( k = 0; k < blockedRadialSlots[i].disabledBySources.Size(); k += 1 )
					{
						if ( blockedRadialSlots[i].disabledBySources[k] == sourceName )
						{
							return false;
						}
					}
					blockedRadialSlots[i].disabledBySources.PushBack ( sourceName );
					return false;
				}
				
				return false;
			}
		}
		
		blockedRadialSlotEntry = InitBlockedRadialSlotEntry ( slotName );
		
		if ( sourceName != '' )
		{
			blockedRadialSlotEntry.disabledBySources.PushBack ( sourceName );
		}
		blockedRadialSlots.PushBack ( blockedRadialSlotEntry );
		EnableRadialSlots ( false, slotsToBlock );
		return true;
	}
	
	public function EnableRadialSlot ( slotName : name, sourceName : name ) : bool
	{
		var i : int;
		var k : int;
		
		var slotsToBlock : array<name>;
		
		slotsToBlock.PushBack ( slotName );
		
		for ( i = 0; i < blockedRadialSlots.Size(); i+=1 )
		{
			if ( blockedRadialSlots[i].slotName == slotName )
			{
			
				if ( sourceName != '' )
				{
					for ( k = 0; k < blockedRadialSlots[i].disabledBySources.Size(); k += 1 )
					{
						if ( blockedRadialSlots[i].disabledBySources[k] == sourceName  )
						{							
							blockedRadialSlots[i].disabledBySources.Remove ( blockedRadialSlots[i].disabledBySources[k] );							
						}
					}
				}
				if ( blockedRadialSlots[i].disabledBySources.Size() <= 0  )
				{
					blockedRadialSlots.Remove( blockedRadialSlots[i] );
					EnableRadialSlots ( true, slotsToBlock );
					return true;
				}
				return false;
			}
		}
		return false;
		
	}
	
	private function InitBlockedRadialSlotEntry ( slotName : name ) : SRadialSlotDef
	{
		var blockedRadialSlotEntry : SRadialSlotDef;
		
		blockedRadialSlotEntry.slotName = slotName;
		
		return blockedRadialSlotEntry;
		
	}
	
	public function EnableRadialSlotsWithSource ( enable : bool, slotsToBlock : array < name >, sourceName : name )
	{
		var i : int;
		
		for ( i = 0; i < slotsToBlock.Size(); i+=1 )
		{
			if ( enable )
			{
				EnableRadialSlot ( slotsToBlock[i], sourceName );
			}
			else
			{
				DisableRadialSlot ( slotsToBlock[i], sourceName );
			}
		}
		if ( blockedRadialSlots.Size() <= 0 ) 
		{
			blockedRadialSlots.Clear();
		}
	}
	
	public function IsRadialSlotBlocked ( slotName : name ) : bool
	{
		var i : int;
		
		for ( i = 0; i < blockedRadialSlots.Size(); i+=1 )
		{
			if ( blockedRadialSlots[i].slotName == slotName )
			{
				return true;
			}
		}
		return false;
	}
	
	
	/////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////
	///////////////////////  @Reapir Kits  ////////////////////////////////////
	////////////////////////////////////////////////////////////////////
	public function RepairItem (  rapairKitId : SItemUniqueId, usedOnItem : SItemUniqueId );
	public function HasRepairAbleGearEquiped () : bool;
	public function HasRepairAbleWaponEquiped () : bool;
	public function IsItemRepairAble ( item : SItemUniqueId ) : bool;
	
	/////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////
	///////////////////////  @OILS  ////////////////////////////////////
	////////////////////////////////////////////////////////////////////
	
	public final function ReduceAllOilsAmmo( id : SItemUniqueId )
	{
		var i : int;
		var oils : array< W3Effect_Oil >;
		
		oils = inv.GetOilsAppliedOnItem( id );
		
		for( i=0; i<oils.Size(); i+=1 )
		{
			oils[ i ].ReduceAmmo();
		}
	}
	
	public final function ResumeOilBuffs( steel : bool )
	{
		var item : SItemUniqueId;
		var oils : array< CBaseGameplayEffect >;
		var buff, recentOil : W3Effect_Oil;
		var i : int;
		
		item = GetEquippedSword( steel );
		oils = GetBuffs( EET_Oil );
		
		if( oils.Size() > 1 )
		{
			//if we have more than 1 oil applied on sword, we need to resume most recent one as the last one
			//in order to show proper oil color on the blade
			recentOil = inv.GetNewestOilAppliedOnItem( item, false );
		}
		
		for( i=0; i<oils.Size(); i+=1 )
		{
			buff = ( W3Effect_Oil ) oils[ i ];
			
			if( recentOil && recentOil == buff )
			{
				continue;
			}
			
			if(buff && buff.GetSwordItemId() == item )
			{
				buff.Resume( '' );
			}
		}
		
		if( recentOil )
		{
			recentOil.Resume( '' );
		}
	}
	
	protected final function PauseOilBuffs( isSteel : bool )
	{
		var item : SItemUniqueId;
		var oils : array< CBaseGameplayEffect >;
		var buff : W3Effect_Oil;
		var i : int;
		
		item = GetEquippedSword( isSteel );
		oils = GetBuffs( EET_Oil );
		
		for( i=0; i<oils.Size(); i+=1 )
		{
			buff = ( W3Effect_Oil ) oils[ i ];
			if(buff && buff.GetSwordItemId() == item )
			{
				buff.Pause( '', true );
			}
		}
	}
	
	public final function ManageAerondightBuff( apply : bool )
	{
		var aerondight		: W3Effect_Aerondight;
		var item			: SItemUniqueId;
		
		item = inv.GetCurrentlyHeldSword();
		
		if( inv.ItemHasTag( item, 'Aerondight' ) )
		{
			aerondight = (W3Effect_Aerondight)GetBuff( EET_Aerondight );
			
			if( apply )
			{
				if( !aerondight )
				{
					AddEffectDefault( EET_Aerondight, this, "Aerondight" );
				}
				else
				{
					aerondight.Resume( 'ManageAerondightBuff' );
				}
			}
			else
			{
				aerondight.Pause( 'ManageAerondightBuff' );
			}
		}
	}
	
	//applies oil on given player item
	public function ApplyOil( oilId : SItemUniqueId, usedOnItem : SItemUniqueId ) : bool
	{
		var oilAbilities : array< name >;
		var ammo, ammoBonus : float;
		var dm : CDefinitionsManagerAccessor;		
		var buffParams : SCustomEffectParams;
		var oilParams : W3OilBuffParams;
		var oilName : name;
		var min, max : SAbilityAttributeValue;
		var i : int;
		var oils : array< W3Effect_Oil >;
		var existingOil : W3Effect_Oil;
				
		if( !CanApplyOilOnItem( oilId, usedOnItem ) )
		{
			return false;
		}
		
		dm = theGame.GetDefinitionsManager();
		inv.GetItemAbilitiesWithTag( oilId, theGame.params.OIL_ABILITY_TAG, oilAbilities );
		oilName = inv.GetItemName( oilId );
		oils = inv.GetOilsAppliedOnItem( usedOnItem );
		
		//check if oil is already applied
		for( i=0; i<oils.Size(); i+=1 )
		{
			if( oils[ i ].GetOilItemName() == oilName )
			{
				existingOil = oils[ i ];
				break;
			}
		}
		
		//remove previous oil
		if( !existingOil )
		{
			if( !GetWitcherPlayer() || !GetWitcherPlayer().IsSetBonusActive( EISB_Wolf_1 ) )
			{
				inv.RemoveAllOilsFromItem( usedOnItem );
			}
			else
			{
				dm.GetAbilityAttributeValue( GetSetBonusAbility( EISB_Wolf_1 ), 'max_oils_count', min, max );
				if( inv.GetActiveOilsAppliedOnItemCount( usedOnItem ) >= CalculateAttributeValue( max ) )
				{
					inv.RemoveOldestOilFromItem( usedOnItem );
				}
			}
		}
		
		//set charges
		ammo = CalculateAttributeValue(inv.GetItemAttributeValue(oilId, 'ammo'));
		if(CanUseSkill(S_Alchemy_s06))
		{
			ammoBonus = CalculateAttributeValue(GetSkillAttributeValue(S_Alchemy_s06, 'ammo_bonus', false, false));
			ammo *= 1 + ammoBonus * GetSkillLevel(S_Alchemy_s06);
		}
		
		//add new oil
		if( existingOil )
		{
			existingOil.Reapply( RoundMath( ammo ) );
		}
		else
		{
			buffParams.effectType = EET_Oil;
			buffParams.creator = this;
			oilParams = new W3OilBuffParams in this;
			oilParams.iconPath = dm.GetItemIconPath( oilName );
			oilParams.localizedName = dm.GetItemLocalisationKeyName( oilName );
			oilParams.localizedDescription = dm.GetItemLocalisationKeyName( oilName );
			oilParams.sword = usedOnItem;
			oilParams.maxCount = RoundMath( ammo );
			oilParams.currCount = RoundMath( ammo );
			oilParams.oilAbilityName = oilAbilities[ 0 ];
			oilParams.oilItemName = oilName;
			buffParams.buffSpecificParams = oilParams;
			
			AddEffectCustom( buffParams );
			
			delete oilParams;
		}
		
		LogOils("Added oil <<" + oilName + ">> to <<" + inv.GetItemName( usedOnItem ) + ">>");
		
		//fundamentals first achievement
		SetFailedFundamentalsFirstAchievementCondition( true );		
		
		theGame.GetGlobalEventsManager().OnScriptedEvent( SEC_OnOilApplied );
		
		if( !inv.IsItemHeld( usedOnItem ) )
		{
			PauseOilBuffs( inv.IsItemSteelSwordUsableByPlayer( usedOnItem ) );
		}
		
		return true;
	}
	
	// Returns true if given sword type is upgraded with given oil
	public final function IsEquippedSwordUpgradedWithOil(steel : bool, optional oilName : name) : bool
	{
		var sword : SItemUniqueId;
		var i : int;
		var oils : array< W3Effect_Oil >;
	
		sword = GetEquippedSword( steel );				
		if( !inv.IsIdValid( sword ) )
		{
			return false;
		}
	
		if( oilName == '' )
		{
			return inv.ItemHasAnyActiveOilApplied( sword );
		}
		
		oils = inv.GetOilsAppliedOnItem( sword );
		for( i=0; i<oils.Size(); i+=1 )
		{
			if( oils[ i ].GetOilItemName() == oilName )
			{
				return true;
			}
		}
		
		return false;
	}
	
	public function CanApplyOilOnItem(oilId : SItemUniqueId, usedOnItem : SItemUniqueId) : bool
	{
		if(inv.ItemHasTag(oilId, theGame.params.TAG_STEEL_OIL) && inv.IsItemSteelSwordUsableByPlayer(usedOnItem))
			return true;
			
		if(inv.ItemHasTag(oilId, theGame.params.TAG_SILVER_OIL) && inv.IsItemSilverSwordUsableByPlayer(usedOnItem))
			return true;
			
		return false;
	}
	////////////////////////////////////////////////////////////////////
	
	public final function DidFailFundamentalsFirstAchievementCondition() : bool
	{
		return failedFundamentalsFirstAchievementCondition;
	}
	
	public final function SetFailedFundamentalsFirstAchievementCondition(b : bool)
	{
		var i : int;
		var npc : CNewNPC;
		
		failedFundamentalsFirstAchievementCondition = b;
		
		//save info in enemy since we might run away from combat and return, triggering new combat encounter
		if(failedFundamentalsFirstAchievementCondition)
		{
			for(i=0; i<hostileEnemies.Size(); i+=1)
			{
				if(hostileEnemies[i].HasTag(theGame.params.MONSTER_HUNT_ACTOR_TAG))
				{
					npc = (CNewNPC)hostileEnemies[i];
					npc.AddTag('failedFundamentalsAchievement');
					npc.AddTimer('FundamentalsAchFailTimer', 30*60, , , , true, true);
				}
			}
		}
	}
	
	public function IsInCombatFist() : bool
	{
		return this.GetCurrentStateName() == 'CombatFists';
	}
	
	public function IsInitialized() : bool;
	
	public function IsCiri() : bool
	{
		return ((W3ReplacerCiri)this);
	}
	
	protected function WouldLikeToMove() : bool
	{
		var speedVec : Vector;
		var speed, speedMult : float;

		// Get speed from input
		speedVec.X = theInput.GetActionValue( 'GI_AxisLeftX' ); //player.mainInput.aLeftJoyX;
		speedVec.Y = theInput.GetActionValue( 'GI_AxisLeftY' );//player.mainInput.aLeftJoyY;
		speed = VecLength2D( speedVec );
		
		return speed > 0.1f;
	}

	function HandleMovement( deltaTime : float )
	{
		// just to see if player would like to move if there would be possibility
		// example of use: movement is blocked when in critical state, but it can end earlier only if it would be desired by player
		// and this is nothing but desire to move
		// note: for some reason, when doing WouldLikeToMove()? 1.0f : 0.0f it just doesn't care and gives 0.0f
		if (WouldLikeToMove())
			SetBehaviorVariable( 'playerWouldLikeToMove', 1.0f);
		else
			SetBehaviorVariable( 'playerWouldLikeToMove', 0.0f);

		super.HandleMovement( deltaTime );
	}
	
	function BattleCryIsReady( ) : bool
	{
		var l_currentTime : float;
		
		l_currentTime = theGame.GetEngineTimeAsSeconds();
		
		if( l_currentTime >= battlecry_timeForNext )
		{
			return true;
		}		
		return false;
	}
	
	function PlayBattleCry( _BattleCry : name , _Chance : float, optional _IgnoreDelay, ignoreRepeatCheck : bool )
	{	
		var l_randValue			: float;
		var fact				: int;
		
		fact = FactsQuerySum("force_stance_normal");
		
		if( IsSwimming()
			|| theGame.IsDialogOrCutscenePlaying() 
			|| IsInNonGameplayCutscene()
			|| IsInGameplayScene()
			|| theGame.IsCurrentlyPlayingNonGameplayScene()
			|| theGame.IsFading()
			|| theGame.IsBlackscreen()
			|| FactsQuerySum("force_stance_normal") > 0 ) 
		{
			return;
		}
		
		// To avoid calling too often the same type of battle cry
		if ( !ignoreRepeatCheck )
		{
			if( battlecry_lastTry == _BattleCry )
				return;
		}
		
		battlecry_lastTry = _BattleCry;
		
		l_randValue = RandF();
		
		// Either use delay or chance
		if( l_randValue < _Chance && ( _IgnoreDelay || BattleCryIsReady() )  )
		{
			thePlayer.PlayVoiceset( 90, _BattleCry );			
			// Restart counter
			battlecry_timeForNext = theGame.GetEngineTimeAsSeconds() + RandRangeF( battlecry_delayMax, battlecry_delayMin );
		}
		
	}
	
	public final function OnWeatherChanged()
	{
		if( IsInInterior()
			|| GetCurrentStateName() != 'Exploration'
			|| theGame.IsDialogOrCutscenePlaying() 
			|| IsInNonGameplayCutscene()
			|| IsInGameplayScene()
			|| theGame.IsCurrentlyPlayingNonGameplayScene()
			|| theGame.IsFading()
			|| theGame.IsBlackscreen()
			|| GetTimeSinceSpawned() < 60 ) 
		{
			return;
		}
		
		AddTimer( 'CommentOnWeather', 1 );
	}
	
	public final timer function CommentOnWeather( _Delta : float, _Id : int )
	{
		var l_weather 				: name;
		var l_currentArea 			: EAreaName;
		var l_rand					: float;
		
		l_weather 			= GetWeatherConditionName();
		
		l_currentArea = theGame.GetCommonMapManager().GetCurrentArea();
		
		switch ( l_weather )
		{
			case 'WT_Clear':
			
				l_rand = RandF();
				
				if( l_rand > 0.66f && !AreaIsCold() && theGame.envMgr.IsDay() )
				{
					thePlayer.PlayVoiceset( 90, 'WeatherHot' );
				}
				else if ( l_rand > 0.33f )
				{
					thePlayer.PlayVoiceset( 90, 'WeatherClearingUp' );
				}				
			break;
			
			case 'WT_Rain_Storm':
				thePlayer.PlayVoiceset( 90, 'WeatherStormy' );
			break;
			
			case 'WT_Light_Clouds':
				if( previousRainStrength < GetRainStrength() )
				{
					thePlayer.PlayVoiceset( 90, 'WeatherLooksLikeRain' );
				}
				else if( AreaIsCold() && previousWeather == 'WT_Clear' )
				{
					thePlayer.PlayVoiceset( 90, 'WeatherCold' );
				}
			break;
			
			case 'WT_Mid_Clouds':
				if( previousRainStrength < GetRainStrength() )
				{
					thePlayer.PlayVoiceset( 90, 'WeatherRaining' );
				}
				else if( AreaIsCold() && previousWeather == 'WT_Clear' )
				{
					thePlayer.PlayVoiceset( 90, 'WeatherCold' );
				}
			break;
			
			case 'WT_Mid_Clouds_Dark':
				if( previousWeather != 'WT_Heavy_Clouds' && previousWeather != 'WT_Heavy_Clouds_Dark' )
					thePlayer.PlayVoiceset( 90, 'WeatherWindy' );
			break;
			
			case 'WT_Heavy_Clouds':
				if( previousWeather != 'WT_Mid_Clouds_Dark' && previousWeather != 'WT_Heavy_Clouds_Dark' )
					thePlayer.PlayVoiceset( 90, 'WeatherWindy' );
			break;
			
			case 'WT_Heavy_Clouds_Dark':
				if( thePlayer.IsOnBoat() )
				{
					thePlayer.PlayVoiceset( 90, 'WeatherSeaWillStorm' );
				}
				else if( previousRainStrength < GetRainStrength() )
				{
					thePlayer.PlayVoiceset( 90, 'WeatherLooksLikeRain' );
				}
				else
				{
					thePlayer.PlayVoiceset( 90, 'WeatherWindy' );
				}
			break;
			
			case 'WT_Snow':
				if( RandF() > 0.5f )
					thePlayer.PlayVoiceset( 90, 'WeatherSnowy' );
				else
					thePlayer.PlayVoiceset( 90, 'WeatherCold' );
			break;
		}	
		
		previousRainStrength 	= GetRainStrength();
		previousWeather 		= l_weather;
	}
	
	function CanUpdateMovement() : bool
	{
		if ( rangedWeapon 
			&& GetBehaviorVariable( 'fullBodyAnimWeight' ) >= 1.f
			&& rangedWeapon.GetCurrentStateName() != 'State_WeaponWait' )
			return false;
			
		return true;
	}
	
	public function SetDefaultLocomotionController()
	{
		if( !defaultLocomotionController )
		{
			defaultLocomotionController	= new CR4LocomotionPlayerControllerScript in this;
		}
		
		ActionDirectControl( defaultLocomotionController );
	}
		
	event OnPlayerTickTimer( deltaTime : float )
	{
		var focusModeController : CFocusModeController;
		var cnt : int;
		
		super.OnPlayerTickTimer( deltaTime );
			
		HandleMovement( deltaTime );
		
		if ( playerAiming.GetCurrentStateName() == 'Aiming' )
		{
			FindTarget();
			FindNonActorTarget( false );
			UpdateDisplayTarget();
			UpdateLookAtTarget();			
		}
		else
		{
			if( playerTickTimerPhase == 0 )
			{
				FindTarget();
			}
			else if( playerTickTimerPhase == 1 )
			{
				FindNonActorTarget( false );
			}
			else if ( playerTickTimerPhase == 2 )
			{
				UpdateDisplayTarget();
				UpdateLookAtTarget();
			}
		}
		
		//CombatModeDebug();
		
		playerTickTimerPhase = ( playerTickTimerPhase + 1 ) % 3;
		
		focusModeController = theGame.GetFocusModeController();
		focusModeController.UpdateFocusInteractions( deltaTime );
		
		//some behavior hack for critical states, moved from effectsManager.PerformUpdate() since it does not tick continuously anymore
		cnt = (int)( effectManager.GetCriticalBuffsCount() > 0 );		
		SetBehaviorVariable('hasCriticalBuff', cnt);
	}	
	
	event OnDeath( damageAction : W3DamageAction )
	{
		super.OnDeath( damageAction );
		
		RemoveTimer('RequestCriticalAnimStart');
		//theInput.SetContext('Death');		
		EnableFindTarget( false );
		BlockAllActions('Death', true);
		
		EnableHardLock( false );
		
		theGame.CreateNoSaveLock( 'player_death', deathNoSaveLock, false, false );
		theGame.SetDeathSaveLockId( deathNoSaveLock );
		
		ClearHostileEnemiesList();
		RemoveReactions();
		SetPlayerCombatTarget(NULL);
		OnEnableAimingMode( false );	
		
		theGame.EnableFreeCamera( false );
	}
	
	// Called when the actor gets out of unconscious state
	function OnRevived()
	{
		super.OnRevived();
		BlockAllActions('Death', false);
		
		theGame.ReleaseNoSaveLock(deathNoSaveLock);
		
		this.RestartReactionsIfNeeded();
	}
	
	public function CanStartTalk() : bool
	{
		if ( beingWarnedBy.Size() > 0 )
			return false;
		
		return super.CanStartTalk();
	}
	
	///////////////////////////////////////////////////////////////////////////
	// @Counters
	///////////////////////////////////////////////////////////////////////////
	
	//caches timestamp of counter use (button press)
	public function AddCounterTimeStamp(time : EngineTime)		{counterTimestamps.PushBack(time);}	
	
	/*
		This function checks if we have performed a counter
		It checks timestamps of moments when we pressed the parry/counter button in order
		to determine if the player was spamming the button. If so then this is not a counter.
		
		Returns true if the counter is valid
	*/
	public function CheckCounterSpamming(attacker : CActor) : bool
	{
		var counterWindowStartTime : EngineTime;		//the time when the counter window (in anim) started 
		var i, spamCounter : int;
		var reflexAction : bool;
		var testEngineTime : EngineTime;
		
		if(!attacker)
			return false;
		
		counterWindowStartTime = ((CNewNPC)attacker).GetCounterWindowStartTime();
		spamCounter = 0;
		reflexAction = false;
		
		//if counterWindowStartTime was never set return false - PF
		if ( counterWindowStartTime == testEngineTime )
		{
			return false;
		}
		
		for(i = counterTimestamps.Size() - 1; i>=0; i-=1)
		{
			//log number of button presses since 0.4 seconds before the counter timewindow
			if(counterTimestamps[i] >= (counterWindowStartTime - EngineTimeFromFloat(0.4)) )
			{
				spamCounter += 1;
			}
			//and at the same time remove all outdated data on the fly
			else
			{
				counterTimestamps.Remove(counterTimestamps[i]);
				continue;
			}
			
			//set info that we have a potential parry if this press was after the counter timewindow started
			if(!reflexAction && (counterTimestamps[i] >= counterWindowStartTime))
				reflexAction = true;
		}
		
		/*
			If reflexAction is set then we have at least 1 button press within the counter timewindow.
			
			As for the spam counter:
			0 means no button was pressed - no counter
			1 means exactly one button press - a potential counter (if reflexAction is set as well)
			>1 means spamming
		*/
		if(spamCounter == 1 && reflexAction)
			return true;
			
		return false;
	}
	
	protected function PerformCounterCheck(parryInfo: SParryInfo) : bool
	{
		var mult 						: float;
		var parryType					: EParryType;
		var validCounter, useKnockdown 	: bool;
		var slideDistance, duration 	: float;
		var playerToTargetRot			: EulerAngles;
		var zDifference, mutation8TriggerHP : float;
		var effectType 					: EEffectType;
		var repelType					: EPlayerRepelType = PRT_Random;
		var params						: SCustomEffectParams;
		var thisPos, attackerPos 		: Vector;
		var fistFightCheck, isMutation8 : bool;
		var fistFightCounter 			: bool;
		var attackerInventory			: CInventoryComponent;
		var weaponId					: SItemUniqueId;
		var weaponTags					: array<name>;
		var playerToAttackerVector 		: Vector;
		var tracePosStart				: Vector;
		var tracePosEnd					: Vector;
		var hitPos						: Vector;
		var hitNormal					: Vector;
		var min, max					: SAbilityAttributeValue;
		var npc 						: CNewNPC;
		
		if(ShouldProcessTutorial('TutorialDodge') || ShouldProcessTutorial('TutorialCounter'))
		{
			theGame.RemoveTimeScale( theGame.GetTimescaleSource(ETS_TutorialFight) );
			FactsRemove("tut_fight_slomo_ON");
		}
		
		if ( !parryInfo.canBeParried || parryInfo.attacker.HasAbility( 'CannotBeCountered' ) )
			return false;
		
		fistFightCheck = FistFightCheck( parryInfo.target, parryInfo.attacker, fistFightCounter );
		
		if( ParryCounterCheck() && parryInfo.targetToAttackerAngleAbs < theGame.params.PARRY_HALF_ANGLE && fistFightCheck )
		{
			//check if this is a valid counter
			validCounter = CheckCounterSpamming(parryInfo.attacker);
			
			if(validCounter)
			{
				if ( IsInCombatActionFriendly() )
					RaiseEvent('CombatActionFriendlyEnd');
				
				SetBehaviorVariable( 'parryType', ChooseParryTypeIndex( parryInfo ) );
				SetBehaviorVariable( 'counter', (float)validCounter);			//1/true when the parry is a counter/reflex_parry			
				
				//PPPP counter success sound
				//SoundEvent("global_machines_lift_wood1_mechanism_stop" );
				SetBehaviorVariable( 'parryType', ChooseParryTypeIndex( parryInfo ) );
				SetBehaviorVariable( 'counter', (float)validCounter);			//1/true when the parry is a counter/reflex_parry		
				this.SetBehaviorVariable( 'combatActionType', (int)CAT_Parry );
				
				
				if ( !fistFightCounter )
				{
					attackerInventory = parryInfo.attacker.GetInventory();
					weaponId = attackerInventory.GetItemFromSlot('r_weapon');
					attackerInventory.GetItemTags( weaponId , weaponTags );
					
					if( GetWitcherPlayer().IsMutationActive( EPMT_Mutation8 ) )
					{
						isMutation8 = true;
						theGame.GetDefinitionsManager().GetAbilityAttributeValue( 'Mutation8', 'hp_perc_trigger', min, max );
						mutation8TriggerHP = min.valueMultiplicative;
					}
					
					/*if( parryInfo.attacker.HasTag( 'olgierd_gpl' ) && parryInfo.attackActionName == 'attack_heavy' )
					{
						//DealCounterDamageToOlgierd();
						GetTarget().AddAbility( 'HitCounterEnabled', false );
						GetTarget().AddTimer( 'DisableHitCounterAfter', 3.0 );
					}*/
					
					npc = (CNewNPC)parryInfo.attacker;
					
					//don't look at me like that. It is NOT a hack... follow the white rabbit...
					if ( parryInfo.attacker.HasAbility('mon_gravehag') )
					{
						repelType = PRT_Slash;
						parryInfo.attacker.AddEffectDefault(EET_CounterStrikeHit, this, 'ReflexParryPerformed');
						//parryInfo.attacker.RemoveAbility('TongueAttack');
					}
					else if ( npc && !npc.IsHuman() && !npc.HasTag( 'dettlaff_vampire' ) )
					{
						repelType = PRT_SideStepSlash;
					}
					else if ( weaponTags.Contains('spear2h') )
					{
						repelType = PRT_SideStepSlash;
						parryInfo.attacker.AddEffectDefault(EET_CounterStrikeHit, this, "ReflexParryPerformed");
						parryInfo.attacker.SignalGameplayEvent( 'SpearDestruction');
					}
					else if( isMutation8 && npc && !npc.IsImmuneToMutation8Finisher() )
					{
						repelType = PRT_RepelToFinisher;
						npc.AddEffectDefault( EET_CounterStrikeHit, this, "ReflexParryPerformed" );
						
						//finishers are performed on current target
						SetTarget( npc, true );
						
						PerformFinisher( 0.f, 0 );
					}
					else
					{
						//-----pitch check------
						thisPos = this.GetWorldPosition();
						attackerPos = parryInfo.attacker.GetWorldPosition();
						playerToTargetRot = VecToRotation( thisPos - attackerPos );
						zDifference = thisPos.Z - attackerPos.Z;
						
						if ( playerToTargetRot.Pitch < -5.f && zDifference > 0.35 )
						{
							repelType = PRT_Kick;
							//Pass attacker to the timer so that he ragdolls after a delay
							ragdollTarget = parryInfo.attacker;
							AddTimer( 'ApplyCounterRagdollTimer', 0.3 );
						}
						else
						{
							useKnockdown = false;
							if ( CanUseSkill(S_Sword_s11) )
							{
								if( GetSkillLevel(S_Sword_s11) > 1 && RandRangeF(3,0) < GetWitcherPlayer().GetStat(BCS_Focus) )//CalculateAttributeValue(GetSkillAttributeValue(S_Sword_s11, 'chance', false, true)) )
								{
									duration = CalculateAttributeValue(GetSkillAttributeValue(S_Sword_s11, 'duration', false, true));
									useKnockdown = true;
								}
							}
							else if ( parryInfo.attacker.IsHuman() )
							{ 
								//Apply knockdown if npc is countered on ledge
								tracePosStart = parryInfo.attacker.GetWorldPosition();
								tracePosStart.Z += 1.f;
								playerToAttackerVector = VecNormalize( parryInfo.attacker.GetWorldPosition() -  parryInfo.target.GetWorldPosition() );
								tracePosEnd = ( playerToAttackerVector * 0.75f ) + ( playerToAttackerVector * parryInfo.attacker.GetRadius() ) + parryInfo.attacker.GetWorldPosition();
								tracePosEnd.Z += 1.f;

								if ( !theGame.GetWorld().StaticTrace( tracePosStart, tracePosEnd, hitPos, hitNormal, counterCollisionGroupNames ) )
								{
									tracePosStart = tracePosEnd;
									tracePosEnd -= 3.f;
									
									if ( !theGame.GetWorld().StaticTrace( tracePosStart, tracePosEnd, hitPos, hitNormal, counterCollisionGroupNames ) )
										useKnockdown = true;
								}
							}
							
							if(useKnockdown && (!parryInfo.attacker.IsImmuneToBuff(EET_HeavyKnockdown) || !parryInfo.attacker.IsImmuneToBuff(EET_Knockdown)))
							{
								if(!parryInfo.attacker.IsImmuneToBuff(EET_HeavyKnockdown))
								{
									params.effectType = EET_HeavyKnockdown;
								}
								else
								{
									params.effectType = EET_Knockdown;
								}
								
								repelType = PRT_Kick;
								params.creator = this;
								params.sourceName = "ReflexParryPerformed";
								params.duration = duration;
								
								parryInfo.attacker.AddEffectCustom(params);
							}
							else
							{
								parryInfo.attacker.AddEffectDefault(EET_CounterStrikeHit, this, "ReflexParryPerformed");
							}
						}
					}
					
					parryInfo.attacker.GetInventory().PlayItemEffect(parryInfo.attackerWeaponId, 'counterattack');
					
					//by default repelType is PRT_Random
					if ( repelType == PRT_Random )
						if ( RandRange(100) > 50 )
							repelType = PRT_Bash;
						else
							repelType = PRT_Kick;
					
					this.SetBehaviorVariable( 'repelType', (int)repelType );
					parryInfo.attacker.SetBehaviorVariable( 'repelType', (int)repelType );
				}
				else
				{
					parryInfo.attacker.AddEffectDefault(EET_CounterStrikeHit, this, "ReflexParryPerformed");
				}
				
				//SetCustomOrientationTargetForCombatActions( OT_None );
				SetParryTarget ( parryInfo.attacker );
				SetSlideTarget( parryInfo.attacker );
				if ( !IsActorLockedToTarget() )
					SetMoveTarget( parryInfo.attacker );
				
				if ( RaiseForceEvent( 'PerformCounter' ) )
					OnCombatActionStart();
				
				SetCustomRotation( 'Counter', VecHeading( parryInfo.attacker.GetWorldPosition() - this.GetWorldPosition() ), 0.0f, 0.2f, false );
				AddTimer( 'UpdateCounterRotation', 0.4f, true );
				AddTimer( 'SetCounterRotation', 0.2f );
				
				IncreaseUninterruptedHitsCount();	//counters also count as uninterrupted hits
				
				//drain stamina
				if(IsHeavyAttack(parryInfo.attackActionName))
					mult = theGame.params.HEAVY_STRIKE_COST_MULTIPLIER;
					
				DrainStamina(ESAT_Counterattack, 0, 0, '', 0, mult);
				
				theGame.GetGamerProfile().IncStat(ES_CounterattackChain);
				
			}
			else
			{
				ResetUninterruptedHitsCount();
			}
			return validCounter;
		}			
		
		return false;
	}
	
	timer function UpdateCounterRotation( dt : float, id : int )
	{
		UpdateCustomRotationHeading( 'Counter', VecHeading( parryTarget.GetWorldPosition() - this.GetWorldPosition() ) );
	}
	
	timer function SetCounterRotation( dt : float, id : int )
	{
		SetCustomRotation( 'Counter', VecHeading( parryTarget.GetWorldPosition() - this.GetWorldPosition() ), 360.f, 0.2f, false );
	}	
	
	private var parryTarget : CActor;
	private function SetParryTarget( t : CActor )
	{
		parryTarget = t;
	}
	
	private var ragdollTarget : CActor;
	timer function ApplyCounterRagdollTimer( time : float , id : int)
	{
		var actor : CActor;
				
		actor = (CActor)ragdollTarget;
		
		if(actor)
		{
			actor.AddEffectDefault(EET_HeavyKnockdown, this, 'ReflexParryPerformed');
		}
	}
	
	///////////////////////////////////////////////////////////////////////////
	// Player Mode
	
	public function EnableMode( mode : EPlayerMode, enable : bool )
	{
		playerMode.EnableMode( mode, enable );	
	}
	
	public function GetPlayerMode() : W3PlayerMode
	{
		return playerMode;
	}
	
	private function GetClosestIncomingAttacker() : CActor
	{
		var i, size 					: int;
		var attackerToPlayerDistances 	: array< float >;
		var closestAttackerIndex		: int;
		var incomingAttackers 			: array<CActor>;
			
		//incomingAttackers = this.combatManager.SendTicketOwners( CTT_Attack );
		if(playerMode && playerMode.combatDataComponent)
		{
			if ( incomingAttackers.Size() <= 0 )
				this.playerMode.combatDataComponent.GetTicketSourceOwners( incomingAttackers, 'TICKET_Charge' );
			
			if ( incomingAttackers.Size() <= 0 )
				this.playerMode.combatDataComponent.GetTicketSourceOwners( incomingAttackers, 'TICKET_Melee' );
				
			if ( incomingAttackers.Size() <= 0 )
				this.playerMode.combatDataComponent.GetTicketSourceOwners( incomingAttackers, 'TICKET_Range' );
		}
			
		size = incomingAttackers.Size();
		attackerToPlayerDistances.Resize( size );

		if ( size > 0 )
		{
			for ( i = incomingAttackers.Size()-1; i >= 0; i -= 1)
			{
				if ( !IsEnemyVisible( incomingAttackers[i] ) )
				{
					incomingAttackers.EraseFast( i );
				}
			}			
		}
	
		if ( size > 0 )
		{
			for ( i = 0; i < size; i += 1 )
			{
				attackerToPlayerDistances[i] = VecDistance( incomingAttackers[i].GetWorldPosition(), this.GetWorldPosition() );
			}
			closestAttackerIndex = ArrayFindMinF( attackerToPlayerDistances );
			return incomingAttackers[ closestAttackerIndex ];
		}
		else
		{
			return NULL;
		}
	}
	
	// Combat Timer
	timer function CombatCheck( time : float , id : int) 
	{
		var i : int;
		var strLevel, temp : string;
		var enemies : array<CActor>;
				
		UpdateFinishableEnemyList();
		FindMoveTarget(); 
		playerMode.UpdateCombatMode();
		
		if( GetPlayerCombatStance() == PCS_Guarded )
		{
			if( GetTarget().GetHealthPercents() > 0.25f )
			{
				PlayBattleCry( 'BattleCryTaunt', 0.2f );
			}
			else
			{
				if( GetTarget().IsHuman() )
					PlayBattleCry( 'BattleCryHumansEnd', 0.3f );
				else
					PlayBattleCry( 'BattleCryMonstersEnd', 0.3f );
			}
		}
		
		if(IsThreatened() && ShouldProcessTutorial('TutorialMonsterThreatLevels') && FactsQuerySum("q001_nightmare_ended") > 0)
		{
			GetEnemiesInRange(enemies);
			for(i=0; i<enemies.Size(); i+=1)
			{
				strLevel = ((CNewNPC)enemies[i]).GetExperienceDifferenceLevelName(temp);
				if(strLevel == "deadlyLevel" || strLevel == "highLevel")
				{
					FactsAdd("tut_high_threat_monster");
					break;
				}
			}
		}		
	}
	
	public function ReceivedDamageInCombat() : bool
	{
		return receivedDamageInCombat;
	}
	
	//called when combat starts
	event OnCombatStart()
	{
		var weaponType : EPlayerWeapon;
		
		theGame.CreateNoSaveLock( 'combat', noSaveLock );
		
		theGame.GameplayFactsAdd( "in_combat" );
		
		//cerberus achievement
		FactsRemove("statistics_cerberus_sign");
		FactsRemove("statistics_cerberus_petard");
		FactsRemove("statistics_cerberus_bolt");
		FactsRemove("statistics_cerberus_fists");
		FactsRemove("statistics_cerberus_melee");
		FactsRemove("statistics_cerberus_environment");
			
		BlockAction(EIAB_OpenMeditation, 'InCombat');
		BlockAction(EIAB_HighlightObjective, 'InCombat');
		
		if ( !this.IsUsingBoat() && GetTarget().GetAttitude(this) == AIA_Hostile )
		{
			weaponType = GetMostConvenientMeleeWeapon( GetTarget() );
			
			if ( weaponType == PW_Steel || weaponType == PW_Silver )
				this.OnEquipMeleeWeapon( weaponType, false );
		}
	}
		
	//called when combat finishes
	event OnCombatFinished()
	{
		var cnt : int;
		
		reevaluateCurrentWeapon = false;
		
		thePlayer.HardLockToTarget( false );
	
		receivedDamageInCombat = false;
		
		theGame.GameplayFactsRemove( "in_combat" );
			
		//cerberus achievement
		cnt = 0;
		if(FactsQuerySum("statistics_cerberus_sign") > 0)
			cnt += 1;
		if(FactsQuerySum("statistics_cerberus_petard") > 0)
			cnt += 1;
		if(FactsQuerySum("statistics_cerberus_bolt") > 0)
			cnt += 1;
		if(FactsQuerySum("statistics_cerberus_fists") > 0)
			cnt += 1;
		if(FactsQuerySum("statistics_cerberus_melee") > 0)
			cnt += 1;
		if(FactsQuerySum("statistics_cerberus_environment") > 0)
			cnt += 1;
		
		//failsafe
		FactsRemove("statistics_cerberus_sign");
		FactsRemove("statistics_cerberus_petard");
		FactsRemove("statistics_cerberus_bolt");
		FactsRemove("statistics_cerberus_fists");
		FactsRemove("statistics_cerberus_melee");
		FactsRemove("statistics_cerberus_environment");
		
		if(cnt >= 3)
			theGame.GetGamerProfile().AddAchievement(EA_Cerberus);
		//end of cerberus
		
		if(theGame.GetTutorialSystem() && FactsQuerySum("TutorialShowSilver") > 0)
		{
			FactsAdd("tut_show_silver_sword", 1);
			FactsRemove("TutorialShowSilver");
		}
		this.SetBehaviorVariable('isInCombatForOverlay',0.f);
		GoToExplorationIfNeeded();
		theGame.ReleaseNoSaveLock( noSaveLock );
		LogChannel( 'OnCombatFinished', "OnCombatFinished: ReleaseNoSaveLock" ); 
		
		SetFailedFundamentalsFirstAchievementCondition(false);
		
		UnblockAction(EIAB_OpenMeditation, 'InCombat');
		UnblockAction(EIAB_HighlightObjective, 'InCombat');
	}
	
	event OnReactToBeingHit( damageAction : W3DamageAction )
	{
		var weaponType : EPlayerWeapon;
		
		super.OnReactToBeingHit(damageAction);
		IncHitCounter();
		
		if ( IsInCombat() && damageAction.attacker && damageAction.attacker == GetTarget() && !( this.IsUsingVehicle() && this.IsOnBoat() ) )
		{
			weaponType = GetMostConvenientMeleeWeapon( GetTarget() );
			if ( weaponType != PW_Fists && weaponType != PW_None && weaponType != this.GetCurrentMeleeWeaponType() )
				OnEquipMeleeWeapon( weaponType, false );
		}
	}
	
	//called when player receives damage in combat(except for toxicity)
	public function ReceivedCombatDamage()
	{
		receivedDamageInCombat = true;
	}
	
	///////////////////////////////////////////////////////////////////////////
	// @Uninterrupted hits
	///////////////////////////////////////////////////////////////////////////
	
	
	timer function UninterruptedHitsResetOnIdle(dt : float, id : int)
	{
		ResetUninterruptedHitsCount();
	}
	
	public function ResetUninterruptedHitsCount()
	{
		uninterruptedHitsCount = 0;
		LogUnitAtt("Uninterrupted attacks reset!!!!");
	}
	
	public function IncreaseUninterruptedHitsCount()
	{
		uninterruptedHitsCount += 1;
		LogUnitAtt("Uninterrupted attacks count increased to " + uninterruptedHitsCount);
		
		if(uninterruptedHitsCount == 4)
			AddTimer('StartUninterruptedBlurr', 1, false);
		
		//idle turn off timer
		AddTimer('UninterruptedHitsResetOnIdle', 4.f, false);
	}
	
	timer function StartUninterruptedBlurr(dt : float, id : int)
	{
		var changed : bool;
		var movingAgent : CMovingPhysicalAgentComponent;
		var target : CActor;
		
		//check if the timer is to be turned off
		if(uninterruptedHitsCount < 4)
		{
			LogUnitAtt("Stopping camera effect");
			thePlayer.StopEffect(uninterruptedHitsCurrentCameraEffect);
			uninterruptedHitsCurrentCameraEffect = '';
			uninterruptedHitsCameraStarted = false;			
			RemoveTimer('StartUninterruptedBlurr');
		}
		else	//still valid
		{
			target = GetTarget();
			
			if( target )
			{
				movingAgent = ( (CMovingPhysicalAgentComponent) (target.GetMovingAgentComponent()) );
			}
				
			if(!uninterruptedHitsCameraStarted)
			{
				LogUnitAtt("Starting camera effect");
				AddTimer('StartUninterruptedBlurr', 0.001, true);	//need to update per tick
				if(movingAgent && movingAgent.GetCapsuleHeight() > 2)
					uninterruptedHitsCurrentCameraEffect = theGame.params.UNINTERRUPTED_HITS_CAMERA_EFFECT_BIG_ENEMY;
				else
					uninterruptedHitsCurrentCameraEffect = theGame.params.UNINTERRUPTED_HITS_CAMERA_EFFECT_REGULAR_ENEMY;
				thePlayer.PlayEffect(uninterruptedHitsCurrentCameraEffect);
				uninterruptedHitsCameraStarted = true;
			}
			else
			{
				changed = false;
				if(movingAgent && movingAgent.GetCapsuleHeight() > 2 && uninterruptedHitsCurrentCameraEffect != theGame.params.UNINTERRUPTED_HITS_CAMERA_EFFECT_BIG_ENEMY)
					changed = true;
				else if(!movingAgent || ( movingAgent.GetCapsuleHeight() <= 2 && uninterruptedHitsCurrentCameraEffect != theGame.params.UNINTERRUPTED_HITS_CAMERA_EFFECT_REGULAR_ENEMY) )
					changed = true;
				
				//if the target's height has changed then swap the camera effect
				if(changed)
				{
					//stop current effect
					thePlayer.StopEffect(uninterruptedHitsCurrentCameraEffect);
					
					//change mode
					if(uninterruptedHitsCurrentCameraEffect == theGame.params.UNINTERRUPTED_HITS_CAMERA_EFFECT_BIG_ENEMY)
						uninterruptedHitsCurrentCameraEffect = theGame.params.UNINTERRUPTED_HITS_CAMERA_EFFECT_REGULAR_ENEMY;
					else
						uninterruptedHitsCurrentCameraEffect = theGame.params.UNINTERRUPTED_HITS_CAMERA_EFFECT_BIG_ENEMY;
						
					//turn new camera effect on
					thePlayer.PlayEffect(uninterruptedHitsCurrentCameraEffect);
				}
			}
		}
	}
	
	///////////////////////////////////////////////////////////////////////////
	// Exploration Actions
	///////////////////////////////////////////////////////////////////////////
	
	private var playerActionEventListeners 			: array<CGameplayEntity>;
	private var playerActionEventBlockingListeners 	: array<CGameplayEntity>;
	
	private function PlayerActionBlockGameplayActions( sourceName : name, lock : bool, isFromPlace : bool )
	{
		if ( lock )
		{
			thePlayer.BlockAction( EIAB_Signs, sourceName, false, false, isFromPlace );
			thePlayer.BlockAction( EIAB_DrawWeapon, sourceName, false, false, isFromPlace );
			thePlayer.BlockAction( EIAB_CallHorse, sourceName, false, false, isFromPlace );
			thePlayer.BlockAction( EIAB_FastTravel, sourceName, false, false, isFromPlace );
			thePlayer.BlockAction( EIAB_Fists, sourceName, false, false, isFromPlace );
			thePlayer.BlockAction( EIAB_InteractionAction, sourceName, false, false, isFromPlace );
			thePlayer.DisableCombatState();
		}
		else
		{
			thePlayer.UnblockAction( EIAB_Signs, sourceName );
			thePlayer.UnblockAction( EIAB_DrawWeapon, sourceName );
			thePlayer.UnblockAction( EIAB_CallHorse, sourceName );
			thePlayer.UnblockAction( EIAB_FastTravel, sourceName );
			thePlayer.UnblockAction( EIAB_Fists, sourceName );
			thePlayer.UnblockAction( EIAB_InteractionAction, sourceName );
		}
	}
	
	public function GetPlayerActionEventListeners() : array<CGameplayEntity>
	{
		return playerActionEventListeners;
	}
	
	//Registers for event + blocks GameplayActions
	public function RegisterForPlayerAction( listener : CGameplayEntity, isLockedByPlace : bool )
	{
		if ( !playerActionEventListeners.Contains( listener ) )
		{
			playerActionEventListeners.PushBack( listener );
		}
		if ( listener.ShouldBlockGameplayActionsOnInteraction() )
		{
			if ( !playerActionEventBlockingListeners.Contains( listener ) )
			{
				playerActionEventBlockingListeners.PushBack( listener );
			}
			if ( playerActionEventBlockingListeners.Size() == 1 )
			{
				PlayerActionBlockGameplayActions( 'PlayerAction', true, isLockedByPlace );
			}
		}
	}
	
	//Unregisters for event + unblocks GameplayActions
	public function UnregisterForPlayerAction( listener : CGameplayEntity, isLockedByPlace : bool )
	{
		playerActionEventListeners.Remove( listener );
		playerActionEventBlockingListeners.Remove( listener );
		if ( playerActionEventBlockingListeners.Size() == 0 )
		{
			PlayerActionBlockGameplayActions( 'PlayerAction', false, isLockedByPlace );
		}	
	}
	
	event OnPlayerActionStart()
	{
		//MS: Only used for ProudWalk
		thePlayer.SetBehaviorVariable( 'inJumpState', 1.f );
	}
	
	event OnPlayerActionEnd()
	{
		var i : int;		
		for ( i = playerActionEventListeners.Size() - 1; i >= 0; i-=1 )
		{
			playerActionEventListeners[i].OnPlayerActionEnd();
		}
		currentCustomAction = PEA_None;
		
		//MS: Only used for ProudWalk
		thePlayer.SetBehaviorVariable( 'inJumpState', 0.f );
	}
	
	event OnPlayerActionStartFinished()
	{
		var i : int;		
		for ( i = playerActionEventListeners.Size() - 1; i >= 0; i-=1 )
		{
			playerActionEventListeners[i].OnPlayerActionStartFinished();
		}
	}
	
	function PlayerStartAction( playerAction : EPlayerExplorationAction, optional animName : name ) : bool
	{
		if ( playerAction == PEA_SlotAnimation && !IsNameValid(animName) )
		{
			return false;
		}
			
		SetBehaviorVariable( 'playerStopAction', 0.0);
		SetBehaviorVariable( 'playerExplorationAction', (float)(int)playerAction);
		
		/*if ( playerAction == PEA_SlotAnimation )
		{ 
			if ( !this.ActionPlaySlotAnimationAsync('PLAYER_ACTION_SLOT',animName) )
				return false;
		}*/
		
		if ( RaiseForceEvent('playerActionStart') )
		{
			currentCustomAction = playerAction;
			if ( playerAction == PEA_SlotAnimation )
			{ 
				playerActionSlotAnimName = animName;
				AddTimer('PlayActionAnimWorkaround',0,false);
			}
			return true;
		}
		return false;
	}
	
	private var playerActionSlotAnimName : name;
	
	timer function PlayActionAnimWorkaround( dt : float , id : int)
	{
		this.ActionPlaySlotAnimationAsync('PLAYER_ACTION_SLOT',playerActionSlotAnimName, 0.2, 0.2, true);
	}
	
	function PlayerStopAction( playerAction : EPlayerExplorationAction )
	{
		SetBehaviorVariable( 'playerExplorationAction', (float)(int)playerAction);
		SetBehaviorVariable( 'playerStopAction', 1.0);
		currentCustomAction = PEA_None;
	}
	
	function GetPlayerAction() : EPlayerExplorationAction
	{
		return currentCustomAction;
	}
	
	function MedallionPing()
	{
		var currTime 		: float = theGame.GetEngineTimeAsSeconds();
		
		if ( lastMedallionEffect < currTime )
		{
			lastMedallionEffect = theGame.GetEngineTimeAsSeconds() + medallion.effectDuration;
			medallion.TriggerMedallionFX();
		}
	}
	
	///////////////////////////////////////////////////////////////////////////
	// @INTERACTIONS
	///////////////////////////////////////////////////////////////////////////
	
	public function CanPerformPlayerAction(optional alsoOutsideExplorationState : bool) : bool
	{
		//if in exploration or in any state and flag set
		if(!alsoOutsideExplorationState && GetCurrentStateName() != 'Exploration')
			return false;
		
		if( isInAir || (substateManager && !substateManager.CanInteract()) || IsInCombatAction() || GetCriticalBuffsCount() > 0)
			return false;
			
		return true;
	}
	
	//called when we receive an item
	event OnItemGiven(data : SItemChangedData)
	{
		var keyName : name;
		var i : int;
		var hud : CR4ScriptedHud;
		var message : string;
		var inve : CInventoryComponent;

		if(data.informGui)
		{			
			hud = (CR4ScriptedHud)theGame.GetHud();
			if(hud)
			{
				message = GetLocStringByKeyExt("panel_common_item_received") + ": " + GetLocStringByKeyExt(inv.GetItemLocalizedNameByUniqueID(data.ids[0]));
				if(data.quantity > 1)
					message += " x" + data.quantity;
				hud.HudConsoleMsg(message);
			}
		}
		
		inve = GetInventory();	//OnItemGiven can be called before we cache inventory component
		
		//key - check if we're next to a lock that uses this key and update interaction if needed
		if(inve.ItemHasTag(data.ids[0], 'key'))
		{
			keyName = inve.GetItemName(data.ids[0]);
			for(i=nearbyLockedContainersNoKey.Size()-1; i>=0; i-=1)
			{
				if(nearbyLockedContainersNoKey[i].GetKeyName() == keyName && nearbyLockedContainersNoKey[i].IsEnabled())
				{
					nearbyLockedContainersNoKey[i].UpdateComponents("Unlock");
					nearbyLockedContainersNoKey.Remove(nearbyLockedContainersNoKey[i]);
				}
			}
		}

		//alchemy level 3 items
		if(inve.IsItemAlchemyItem(data.ids[0]))
		{
			UpgradeAlchemyItem(data.ids[0], CanUseSkill(S_Perk_08));			
		}
		
		if(inve.ItemHasTag(data.ids[0], theGame.params.TAG_OFIR_SET))
			CheckOfirSetAchievement();
	}
	
	private final function CheckOfirSetAchievement()
	{
		var hasArmor, hasBoots, hasGloves, hasPants, hasSword, hasSaddle, hasBag, hasBlinders : bool;
		
		//check player items
		CheckOfirItems(GetInventory(), hasArmor, hasBoots, hasGloves, hasPants, hasSword, hasSaddle, hasBag, hasBlinders);

		//check stash items
		CheckOfirItems(GetWitcherPlayer().GetHorseManager().GetInventoryComponent(), hasArmor, hasBoots, hasGloves, hasPants, hasSword, hasSaddle, hasBag, hasBlinders);
		
		if(hasArmor && hasBoots && hasGloves && hasPants && hasSword && hasSaddle && hasBag && hasBlinders)
			theGame.GetGamerProfile().AddAchievement(EA_LatestFashion);
	}
	
	private final function CheckOfirItems(inv : CInventoryComponent, out hasArmor : bool, out hasBoots : bool, out hasGloves : bool, out hasPants : bool, out hasSword : bool, out hasSaddle : bool, out hasBag : bool, out hasBlinders : bool)
	{
		var ofirs : array<SItemUniqueId>;
		var i : int;
		
		ofirs = inv.GetItemsByTag(theGame.params.TAG_OFIR_SET);
		for(i=0; i<ofirs.Size(); i+=1)
		{
			if(inv.IsItemChestArmor(ofirs[i]))
			{
				hasArmor = true;
				continue;
			}
			else if(inv.IsItemBoots(ofirs[i]))
			{
				hasBoots = true;
				continue;
			}
			else if(inv.IsItemGloves(ofirs[i]))
			{
				hasGloves = true;
				continue;
			}
			else if(inv.IsItemPants(ofirs[i]))
			{
				hasPants = true;
				continue;
			}
			else if(inv.IsItemSteelSwordUsableByPlayer(ofirs[i]))
			{
				hasSword = true;
				continue;
			}
			else if(inv.IsItemSilverSwordUsableByPlayer(ofirs[i]))
			{
				hasSword = true;
				continue;
			}
			else if(inv.IsItemSaddle(ofirs[i]))
			{
				hasSaddle = true;
				continue;
			}
			else if(inv.IsItemHorseBag(ofirs[i]))
			{
				hasBag = true;
				continue;
			}
			else if(inv.IsItemBlinders(ofirs[i]))
			{
				hasBlinders = true;
				continue;
			}
		}
	}
	
	//changes all alchemy items of level 3 abilities from level 2 to 3 (if upgrade) or from 3 to 2 (if not upgrading)
	public function ChangeAlchemyItemsAbilities(upgrade : bool)
	{
		var i : int;
		var dm : CDefinitionsManagerAccessor;
		var items : array<SItemUniqueId>;
	
		inv.GetAllItems(items);
		dm = theGame.GetDefinitionsManager();
		
		for(i=0; i<items.Size(); i+=1)
			if(inv.IsItemAlchemyItem(items[i]))
				UpgradeAlchemyItem(items[i], upgrade);
	}
	
	//changes all alchemy items of level 3 abilities from level 2 to 3 (if upgrade) or from 3 to 2 (if not upgrading)
	public function UpgradeAlchemyItem(itemID : SItemUniqueId, upgrade : bool)
	{
		var j, currLevel, otherLevel : int;
		var dm : CDefinitionsManagerAccessor;
		var abs, currAbilities, otherAbilities : array<name>;
		var min, max : SAbilityAttributeValue;
	
		if(!inv.IsItemAlchemyItem(itemID))
			return;
			
		//get current level
		currLevel = (int)CalculateAttributeValue(inv.GetItemAttributeValue(itemID, 'level'));
		
		//if level ok then exit
		if(currLevel == 3 || currLevel == 2 || currLevel < 2 || currLevel > 3)
			return;
	
		//get current ability name
		currAbilities = inv.GetItemAbilitiesWithAttribute(itemID, 'level', currLevel);
					
		//get other ability name
		inv.GetItemContainedAbilities(itemID, abs);
		dm = theGame.GetDefinitionsManager();
		for(j=0; j<abs.Size(); j+=1)
		{
			dm.GetAbilityAttributeValue(abs[j], 'level', min, max);
			otherLevel = (int)CalculateAttributeValue(GetAttributeRandomizedValue(min, max));
			if( (otherLevel == 2 || otherLevel == 3) && otherLevel != currLevel)
				otherAbilities.PushBack(abs[j]);
		}
		
		//swap abilities
		if(otherAbilities.Size() == 0)
		{
			LogAssert(false, "CR4Player.UpgradeAlchemyItem: cannot find ability to swap to from <<" + currAbilities[0] + ">> on item <<" + inv.GetItemName(itemID) + ">> !!!");
		}
		else
		{
			for(j=0; j<currAbilities.Size(); j+=1)
				inv.RemoveItemBaseAbility(itemID, currAbilities[j]);
				
			for(j=0; j<otherAbilities.Size(); j+=1)
				inv.AddItemBaseAbility(itemID, otherAbilities[j]);
		}
	}
	
	///////////////////////////////////////////////////////////////////////////
	// Movement adjustment helper functions
	///////////////////////////////////////////////////////////////////////////

	public function MovAdjRotateToTarget( ticket : SMovementAdjustmentRequestTicket )
	{
		var movementAdjustor : CMovementAdjustor = GetMovingAgentComponent().GetMovementAdjustor();
		var localOrientationTarget : EOrientationTarget = GetOrientationTarget();

		if ( localOrientationTarget == OT_CustomHeading )
		{
			movementAdjustor.RotateTo( ticket, GetOrientationTargetCustomHeading() );					
		}
		else if ( localOrientationTarget == OT_Actor )
		{
			/*if  ( parryTarget && IsGuarded() )
				movementAdjustor.RotateTowards( ticket, parryTarget );
			else*/ if ( slideTarget )
				movementAdjustor.RotateTowards( ticket, slideTarget );
			else if ( lAxisReleasedAfterCounter )
				movementAdjustor.RotateTo( ticket, GetHeading() );
			else
				movementAdjustor.RotateTo( ticket, GetCombatActionHeading() );//rawPlayerHeading );
		}
		else if ( localOrientationTarget == OT_Player )
		{
			if ( bLAxisReleased )
				movementAdjustor.RotateTo( ticket, GetHeading() );
			else 
				movementAdjustor.RotateTo( ticket, rawPlayerHeading );//GetCombatActionHeading() );
		}
		else if ( localOrientationTarget == OT_CameraOffset )
		{
			//movementAdjustor.RotateTo( ticket, VecHeading( cachedCameraVector ) );//rawCameraHeading - oTCameraOffset );
			movementAdjustor.RotateTo( ticket, VecHeading( theCamera.GetCameraDirection() ) );//rawCameraHeading );
		}		
		else
		{
			// default to camera
			movementAdjustor.RotateTo( ticket, rawCameraHeading );
		}
		// never rotate to player
	}

	////////////////////////////////////////////////////////////////////////////////////
	// Look at targets - moved here from movables
	////////////////////////////////////////////////////////////////////////////////////
	//var cachedCameraVector : Vector;
	public function UpdateLookAtTarget()
	{
		var localOrientationTarget	: EOrientationTarget;
		var playerRot			: EulerAngles;
		var lookAtActive		: Float;
		var lookAtTarget		: Vector;
		var headBoneIdx			: int;
		var tempComponent		: CDrawableComponent;
		var entityHeight		: float;
		var useTorsoBone		: bool;
		
		var angles				: EulerAngles;
		var dir 				: Vector;
		var camZ 				: float;
		
		var target				: CActor;
		
		lookAtActive = 0.0f;
	
		localOrientationTarget = GetOrientationTarget();
		
		if ( localOrientationTarget == OT_Player || localOrientationTarget == OT_CustomHeading )
		{
			/*headBoneIdx = GetTorsoBoneIndex();
			if ( headBoneIdx >= 0 )
			{
				lookAtTarget = MatrixGetTranslation( GetBoneWorldMatrixByIndex( headBoneIdx ) );
			}*/		
			
			//lookAtTarget = GetHeadingVector() * 30.f + this.GetWorldPosition();// + lookAtTarget;
			
			if ( localOrientationTarget == OT_Player  )
				angles = VecToRotation( GetHeadingVector() );
			else if ( customOrientationInfoStack.Size() > 0 )
				angles = VecToRotation( VecFromHeading( customOrientationInfoStack[ customOrientationInfoStack.Size() - 1 ].customHeading ) );
			else
				angles = VecToRotation( GetHeadingVector() );
			
			//angles.Pitch = oTCameraPitchOffset;	
			dir = RotForward( angles );
			lookAtTarget = dir * 30.f + this.GetWorldPosition();// + lookAtTarget;
			lookAtTarget.Z += 1.6f;
			lookAtActive = 1.0f;		
		}
		else if ( localOrientationTarget == OT_Camera )
		{
			headBoneIdx = GetHeadBoneIndex();
			if ( headBoneIdx >= 0 )
			{
				lookAtTarget = MatrixGetTranslation( GetBoneWorldMatrixByIndex( headBoneIdx ) );
			}
			else
			{
				lookAtTarget = GetWorldPosition();
				lookAtTarget.Z += 1.6f; // fake head?
			}
			lookAtTarget += theCamera.GetCameraDirection() * 100.f;
			lookAtActive = 1.0f;
		}
		else if ( localOrientationTarget == OT_CameraOffset )
		{
			/*lookAtTarget = GetWorldPosition();
			lookAtTarget.Z += 1.6f; // fake head?			
			camDir = theCamera.GetCameraDirection();			
			camZ = camDir.Z;// + 0.1;
			camDir = VecFromHeading( VecHeading( theCamera.GetCameraDirection() ) - oTCameraOffset ) * VecLength2D( camDir );
			camDir.Z = camZ;*/
					
			dir = theCamera.GetCameraDirection();
			angles = VecToRotation( dir );
			angles.Pitch = -angles.Pitch + oTCameraPitchOffset;
			angles.Yaw -= oTCameraOffset;
			dir = RotForward( angles );
	
			lookAtTarget = dir * 30.f + this.GetWorldPosition();// + lookAtTarget;
			lookAtTarget.Z += 1.6f;
			lookAtActive = 1.0f;
		}		
		else if ( localOrientationTarget == OT_Actor )
		{
			if ( IsInCombatAction() )
			{ 
				if ( ( ( ( W3PlayerWitcher )this ).GetCurrentlyCastSign() != ST_None && GetBehaviorVariable( 'combatActionType' ) == (int)CAT_CastSign )
					|| GetBehaviorVariable( 'combatActionType' ) == (int)CAT_ItemThrow )
					//|| GetBehaviorVariable( 'combatActionType' ) == (int)CAT_Crossbow )
				useTorsoBone = true;
			}
		
			if ( rangedWeapon && rangedWeapon.GetCurrentStateName() != 'State_WeaponWait' )
				useTorsoBone = true;
		
			if ( tempLookAtTarget && (CActor)(tempLookAtTarget) )
			{
				lookAtTarget = ProcessLookAtTargetPosition( tempLookAtTarget, useTorsoBone );
				lookAtActive = 1.0f;
			}
			
			if ( GetDisplayTarget() && IsDisplayTargetTargetable() )
			{
				lookAtTarget = ProcessLookAtTargetPosition( GetDisplayTarget(), useTorsoBone );
				lookAtActive = 1.0f;
			}
			else
			{
				//FAIL SAFE in case the displayTarget disappears for some reason
				
				if ( slideTarget )
				{
					lookAtTarget = ProcessLookAtTargetPosition( slideTarget, useTorsoBone );
				}
				else
				{
					target = GetTarget();
					if ( target )
					{
						lookAtTarget = ProcessLookAtTargetPosition( target, useTorsoBone );
					}
				}
					
				lookAtActive = 1.0f;	
			}
			
			if ( !slideTarget && !IsUsingVehicle() )
			{
				// TODO maybe just get axis from head?
				playerRot = GetWorldRotation();
				lookAtTarget = GetWorldPosition() + VecFromHeading( playerRot.Yaw ) * 100.0f;
				lookAtActive = 0.0f;
			}
			
			if ( useTorsoBone )
				lookAtTarget.Z += 0.2f;	
		}
		
		
		//lookAtTarget = player.GetHeadingVector() * 30.f + this.GetWorldPosition();// + lookAtTarget; 
		//lookAtActive = 1.0f;	
		GetVisualDebug().AddSphere('lookAtTarget', 1.f, lookAtTarget, true, Color(255,0,0), 3.0f );
		SetLookAtPosition( lookAtTarget );
		UpdateLookAtVariables( lookAtActive, lookAtTarget );
	}

	private function ProcessLookAtTargetPosition( ent : CGameplayEntity, useTorsoBone : bool ) : Vector
	{
		var boneIdx 		: int;
		var actor			: CActor;
		var lookAtTarget	: Vector;
		var tempComponent 	: CDrawableComponent;
		var box				: Box;
		var entityHeight	: float;
		var entityPos		: Vector;
		var predictedPos	: Vector;
		var z				: float;
		var entMat			: Matrix;
	
		actor = (CActor)(ent);
		entityPos = ent.GetWorldPosition();
		lookAtTarget = entityPos;
		
		if ( actor )
		{
			if ( useTorsoBone )
				boneIdx = actor.GetTorsoBoneIndex();
			else				
				boneIdx = actor.GetHeadBoneIndex();
		}
		else
			boneIdx = -1;
	
		if ( !( ent.aimVector.X == 0 && ent.aimVector.Y == 0 && ent.aimVector.Z == 0 ) )
		{
			entMat = ent.GetLocalToWorld();
			lookAtTarget = VecTransform( entMat, ent.aimVector );
		}	
		else if ( boneIdx >= 0 )
		{
			lookAtTarget = MatrixGetTranslation( ent.GetBoneWorldMatrixByIndex( boneIdx ) );	
		}	
		else
		{
			if ( actor )
				lookAtTarget.Z += ( ((CMovingPhysicalAgentComponent)actor.GetMovingAgentComponent()).GetCapsuleHeight() * 0.5 ); // fake head?
			else
			{
				tempComponent = (CDrawableComponent)( ent.GetComponentByClassName('CDrawableComponent') );
				if ( tempComponent.GetObjectBoundingVolume( box ) )
				{
					entityHeight = box.Max.Z - box.Min.Z;
					lookAtTarget = lookAtTarget + Vector(0,0,entityHeight/2);
				}		
			}
		}
		z = ((CMovingPhysicalAgentComponent)actor.GetMovingAgentComponent()).GetCapsuleHeight();
		if ( actor )
		{
			if ( PredictLookAtTargetPosition( actor, lookAtTarget.Z - entityPos.Z, predictedPos ) )
				lookAtTarget = predictedPos;
		}
			
		return lookAtTarget;
	}
	
	
	private function PredictLookAtTargetPosition( targetActor : CActor, zOffSet : float, out predictedPos : Vector ) : bool
	{
		var virtualPos		: Vector;
		var i 				: int;
		var dist			: float;
		var deltaTime		: float;
		var projSpeed		: float;
		var projSpeedInt	: Vector;
		var projAngle		: float;	
		
		var e3Hack				: bool;
		var currentTimeInCurve : float;
		e3Hack = false;		
		
		if ( rangedWeapon
			&& rangedWeapon.GetDeployedEntity()
			&& ( rangedWeapon.GetCurrentStateName() == 'State_WeaponAim' || rangedWeapon.GetCurrentStateName() == 'State_WeaponShoot' ) )
		{	
			projSpeed = rangedWeapon.GetDeployedEntity().projSpeed;

			virtualPos = targetActor.GetWorldPosition();
			
			if ( e3Hack && targetActor.HasTag( 'e3_griffin' ) )
			{
				for ( i = 0; i < 10; i += 1 )
				{
					dist = VecDistance( rangedWeapon.GetDeployedEntity().GetWorldPosition(), virtualPos );
					deltaTime = dist/projSpeed;
					virtualPos = targetActor.PredictWorldPosition( deltaTime );
				}
			}
			else
				return false;

			virtualPos.Z += zOffSet;
			predictedPos = virtualPos;
			GetVisualDebug().AddSphere('CrossbowPredictedPos', 1.0f, virtualPos , true, Color(255,50,50), 5.0f );
			return true;
		}
		return false;
	}
	
	public function SetLookAtPosition( vec : Vector )
	{
		lookAtPosition = vec;
	}

	public function GetLookAtPosition() : Vector
	{
		return lookAtPosition;
	}
	
	////////////////////////////////////////////////////////////////////////////////////
	// Scene
	////////////////////////////////////////////////////////////////////////////////////
	
	event OnBlockingSceneEnded( optional output : CStorySceneOutput)
	{
		//hack for possible immortality from finishers
		SetImmortalityMode( AIM_None, AIC_SyncedAnim );
		super.OnBlockingSceneEnded(output);
	}
	
	////////////////////////////////////////////////////////////////////////////////////
	// New combat / exploration and weapon drawing
	////////////////////////////////////////////////////////////////////////////////////
	
	function GetCurrentMeleeWeaponName() : name
	{
		return weaponHolster.GetCurrentMeleeWeaponName();
	}
	
	public function GetCurrentMeleeWeaponType() : EPlayerWeapon
	{
		return weaponHolster.GetCurrentMeleeWeapon();
	}
	
	public function OnMeleeForceHolster(ignoreActionLock : bool)
	{
		weaponHolster.HolsterWeapon(ignoreActionLock, true);
	}
	
	event OnForcedHolsterWeapon()
	{
		weaponHolster.OnForcedHolsterWeapon();
	}
	
	event OnEquippedItem( category : name, slotName : name )
	{
		var weaponType : EPlayerWeapon;
		
		if ( slotName == 'r_weapon' )
		{
			switch ( category )
			{
				case 'None' :
					weaponType = PW_None;
					break;
				case 'fist' :
					weaponType = PW_Fists;
					break;
				case 'steelsword' :
					weaponType = PW_Steel;
					break;
				case 'silversword' :
					weaponType = PW_Silver;
					break;
				default :
					return true;
			}
			
			weaponHolster.OnEquippedMeleeWeapon( weaponType );
		}
	}
	
	private var isHoldingDeadlySword : bool;
	public function ProcessIsHoldingDeadlySword() 
	{
		isHoldingDeadlySword = IsDeadlySwordHeld();
	}
	
	public function IsHoldingDeadlySword() : bool
	{
		return isHoldingDeadlySword;
	}
	
	event OnHolsteredItem( category :  name, slotName : name )
	{
		var weaponType : EPlayerWeapon;
		
		//hide HUD buff icon
		if ( slotName == 'r_weapon' && (category == 'steelsword' || category == 'silversword') )
		{
			if( category == 'silversword' )
			{
				ManageAerondightBuff( false );
			}
			
			GetBuff( EET_LynxSetBonus ).Pause( 'drawing weapon' );
			
			PauseOilBuffs( category == 'steelsword' );
		}
		
		if ( slotName == 'r_weapon' )
		{
			weaponType = weaponHolster.GetCurrentMeleeWeapon();
			switch ( category )
			{
				case 'fist' :
					if ( weaponType == PW_Fists )
						weaponHolster.OnEquippedMeleeWeapon( PW_None );
					return true;
				case 'steelsword' :
					if ( weaponType == PW_Steel )
						weaponHolster.OnEquippedMeleeWeapon( PW_None );
					return true;
				case 'silversword' :
					if ( weaponType == PW_Silver )
						weaponHolster.OnEquippedMeleeWeapon( PW_None );
					return true;
				default :
					return true;
			}
		}
	}
	
	event OnEquipMeleeWeapon( weaponType : EPlayerWeapon, ignoreActionLock : bool, optional sheatheIfAlreadyEquipped : bool )
	{	
		RemoveTimer( 'DelayedSheathSword' );
				
		weaponHolster.OnEquipMeleeWeapon( weaponType, ignoreActionLock, sheatheIfAlreadyEquipped );
		
		/*// Check if we want to go to combat or exploration
		if( weaponHolster.GetCurrentMeleeWeapon() == PW_None )
		{		
			GoToExplorationIfNeeded( );
		}
		else
		{
			GoToCombatIfNeeded( );
		}*/
		
		m_RefreshWeaponFXType = true;
	}
	
	event OnHolsterLeftHandItem()
	{
		weaponHolster.OnHolsterLeftHandItem();
	}
	
	timer function DelayedTryToReequipWeapon( dt: float, id : int )
	{
		var weaponType : EPlayerWeapon;
		
		if( IsInCombat() && GetTarget() )
		{
			weaponType = GetMostConvenientMeleeWeapon( GetTarget() );
			
			if ( weaponType == PW_Steel || weaponType == PW_Silver )
				weaponHolster.OnEquipMeleeWeapon( weaponType, false );
		}	
	}
	
	timer function DelayedSheathSword( dt: float, id : int )
	{
		if ( !IsCombatMusicEnabled() )
		{
			if ( IsInCombatAction() || !IsActionAllowed( EIAB_DrawWeapon ) )
			{
				LogChannel( 'OnCombatFinished', "DelayedSheathSword: Sheath pushed to buffer" ); 
				PushCombatActionOnBuffer(EBAT_Sheathe_Sword,BS_Pressed);
			}
			else
			{
				LogChannel( 'OnCombatFinished', "DelayedSheathSword: Sheath successful" ); 
				OnEquipMeleeWeapon( PW_None, false );
			}
		}	
	}
	
	protected function ShouldAutoSheathSwordInstantly() : bool
	{
		var enemies : array<CActor>;
		var i : int;
		
		GetEnemiesInRange( enemies );
		
		for ( i = 0; i < enemies.Size(); i += 1 )
		{
			if ( IsThreat( enemies[i] ) && 
				VecDistance( enemies[i].GetWorldPosition(), this.GetWorldPosition() ) <= findMoveTargetDist )
			{
				return false;
			}
		}
		
		return true;
	}
	
	public function PrepareToAttack( optional target : CActor, optional action : EBufferActionType )
	{
		var  weaponType 		: EPlayerWeapon;
		
		if( IsInAir() || !GetBIsCombatActionAllowed() )
		{
			return ;
		}
		
		if( !target )
		{
			target	= (CActor)displayTarget;
		}
		if( !target && IsCombatMusicEnabled() )
		{
			target	= moveTarget;
		}
		if( !target )
		{
			if ( this.GetCurrentStateName() == 'Exploration' )
			{
				SetCombatActionHeading( ProcessCombatActionHeading( action ) );
				thePlayer.CanAttackWhenNotInCombat( action, false, target );
			}
		}
		
		weaponHolster.TryToPrepareMeleeWeaponToAttack();
		
		//if ( this.GetCurrentStateName() == 'Exploration' ) //PF - commenting this because Geralt won't switch to proper state when you sheathe sword while mashing attack
		{
			weaponType = GetCurrentMeleeWeaponType();
			
			if ( weaponType == PW_None )
			{
				// Get the weapon we have to use
				weaponType = GetMostConvenientMeleeWeapon( target );
			}
			
			// Can't go to combat if we are in not a proper state
			if( !OnStateCanGoToCombat() )
			{
				return;
			}
			
			GoToCombat( weaponType );
		}
	}
	
	public function DisplayCannotAttackMessage( actor : CActor ) : bool
	{
		if ( actor && ( actor.GetMovingAgentComponent().GetName() == "child_base" || ((CNewNPC)actor).GetNPCType() == ENGT_Quest ) )
		{
			DisplayHudMessage(GetLocStringByKeyExt("panel_hud_message_cant_attack_this_target"));
			return true;
		}	
		
		return false;
	}
	
	public function GetMostConvenientMeleeWeapon( targetToDrawAgainst : CActor, optional ignoreActionLock : bool ) : EPlayerWeapon
	{
		return weaponHolster.GetMostConvenientMeleeWeapon( targetToDrawAgainst, ignoreActionLock );
	}
	
	private var reevaluateCurrentWeapon : bool;
	
	event OnTargetWeaponDrawn()
	{
		var  weaponType : EPlayerWeapon = this.GetCurrentMeleeWeaponType();
		if ( weaponType == PW_Fists )
			reevaluateCurrentWeapon = true;
	}
	
	public function GoToCombatIfNeeded( optional enemy : CActor ) : bool
	{
		var  weaponType : EPlayerWeapon;
		var	 target 	: CActor;
		
		if( !enemy && IsInCombat() )
		{
			target = GetTarget();
			
			if ( target )
				enemy = target;
			else
				enemy = moveTarget;
		}
		
		// Should we fight
		if( !ShouldGoToCombat( enemy ) )
		{
			return false;
		}
		
		weaponType = this.GetCurrentMeleeWeaponType();
		
		if ( weaponType == PW_None || ( reevaluateCurrentWeapon && weaponType == PW_Fists ) || ( !IsInCombat() && weaponHolster.IsOnTheMiddleOfHolstering() ) )
		{
			// Get the weapon we have to use
			weaponType = weaponHolster.GetMostConvenientMeleeWeapon( enemy );
			reevaluateCurrentWeapon = false;
		}
		
		// Change the state+
		GoToCombat( weaponType );
		
		
		return true;
	}
	
	public function GoToCombatIfWanted( ) : bool
	{
		var weaponType	: EPlayerWeapon;
		var	target 		: CActor;
		var	enemy 		: CActor;
		
		
		if( !IsInCombat() )
		{
			return false;
		}
		
		target = GetTarget();
		
		if ( target )
			enemy = target;
		else
			enemy = moveTarget;
		
		weaponType = this.GetCurrentMeleeWeaponType();
		
		if ( weaponType == PW_None || ( !IsInCombat() && weaponHolster.IsOnTheMiddleOfHolstering() ) )
		{
			// Get the weapon we have to use
			weaponType = weaponHolster.GetMostConvenientMeleeWeapon( enemy );
		}
		
		// Change the state+
		GoToCombat( weaponType );
		
		
		return true;
	}
	
	public function GoToExplorationIfNeeded() : bool
	{
		/*
		if( GetCurrentStateName() == 'Exploration' )
		{
			return false;
		}
		*/
		
		if( ! IsInCombatState() )
		{
			return false;
		}
		
		if( !ShouldGoToExploration() )
		{
			return false;
		}
		
		// Change fists weapon to none
		weaponHolster.EndedCombat();
		
		// Change the state
		GotoState( 'Exploration' );
		return true;
	}
	
	event OnStateCanGoToCombat()
	{
		return false;
	}
	
	event OnStateCanUpdateExplorationSubstates()
	{
		return false;
	}
	
	private function ShouldGoToCombat( optional enemy : CActor ) : bool
	{
		var currentStateName : name;
		
		// Can't go to combat if we are in not a proper state
		if( !OnStateCanGoToCombat() )
		{
			return false;
		}
		
		currentStateName = GetCurrentStateName();
		
		if( currentStateName == 'AimThrow' )
		{
			return false;
		}
		
		if( currentStateName == 'Swimming' )
		{
			return false;
		}

		if( currentStateName == 'TraverseExploration' )
		{
			return false;
		}
		
		// TODO: Reenable or find somethingbetter
		// Temporaryly disabled cause it does not work on some terrain
		/*
		if ( !theGame.GetWorld().NavigationLineTest( GetWorldPosition(), enemy.GetWorldPosition(), 0.4 ) )
		{ 
			return false;
		}
		*/
		
		// if there is no enemy, check if combat is forced
		if ( !enemy )
		{ 
			return playerMode.combatMode;
		}
		
		// See if we should be fighting this enemy
		/*if ( !IsEnemyVisible( enemy ) )
		{ 
			return false;
		}*/
		/*if ( !WasVisibleInScaledFrame( enemy, 1.f, 1.f )  )
		{ 
			return false;
		}*/
		
		return true;
	}
	
	private function ShouldGoToExploration() : bool
	{
		if ( IsInCombat() )//moveTarget && IsThreat( moveTarget ) )
		{
			return false;
		}
		/*if( IsGuarded() )
		{
			return false;
		}*/
		if ( rangedWeapon && rangedWeapon.GetCurrentStateName() != 'State_WeaponWait' )
		{
			return false;
		}
		if( IsFistFightMinigameEnabled() )
		{
			return false;
		}
		if( IsKnockedUnconscious() )
		{
			return false;
		}
		if( IsInCombatAction() )
		{
			return false;
		}
		if( GetCriticalBuffsCount() > 0 )
		{
			return false;
		}
		
		return true;
	}
	
	private function GoToCombat( weaponType : EPlayerWeapon, optional initialAction : EInitialAction )
	{			
		// Set up and change state
		switch( weaponType )
		{
			case PW_Silver:
				((W3PlayerWitcherStateCombatSilver) GetState('CombatSilver')).SetupState( initialAction );
				GoToStateIfNew( 'CombatSilver' );
				break;
			case PW_Steel:
				((W3PlayerWitcherStateCombatSteel) GetState('CombatSteel')).SetupState( initialAction );
				GoToStateIfNew( 'CombatSteel' );
				break;
			case PW_Fists:
			case PW_None:
			default :
				((W3PlayerWitcherStateCombatFists) GetState('CombatFists')).SetupState( initialAction );
				GoToStateIfNew( 'CombatFists' );
			break;
		}	
	}
	
	public function GoToStateIfNew( newState : name, optional keepStack : bool, optional forceEvents : bool  )
	{
		if( newState != GetCurrentStateName() )
		{
			GotoState( newState, keepStack, forceEvents );
		}
	}
	
	// So we can debug and control what is changing the state
	public function GotoState( newState : name, optional keepStack : bool, optional forceEvents : bool  )
	{
		/*if( newState == 'Exploration' )
		{
			newState = newState;
		}*/
		
		super.GotoState( newState, keepStack, forceEvents );
		//PushState( newState );
	}
	/*
	public function PushState( newState : name )
	{
		if( newState == 'Exploration' )
		{
			newState = newState;
		}
		super.PushState( newState );
	}
	
	public function PopState( optional popAll : bool )
	{
		super.PopState( popAll );
	}
	*/
	public function IsThisACombatSuperState( stateName : name ) : bool
	{
		return stateName == 'Combat' || stateName == 'CombatSteel' || stateName == 'CombatSilver' || stateName == 'CombatFists';
	}
	
	public function GetWeaponHolster() : WeaponHolster
	{
		return weaponHolster;
	}
	
	public function AbortSign()
	{
		var playerWitcher : W3PlayerWitcher;
		var sign : W3SignEntity;
		
		playerWitcher = (W3PlayerWitcher)this;
		
		if(playerWitcher)
		{
			sign = (W3SignEntity)playerWitcher.GetCurrentSignEntity();
			if (sign)
			{
				sign.OnSignAborted();
			}
		}
	}

	///////////////////////////////////////////////////////////////////////////
	// Animation event handlers
	///////////////////////////////////////////////////////////////////////////
	protected var disableActionBlend : bool;
	
		//KonradSuperDodgeHACK: To make dodge more responsive during NORMAL ATTACKS, dodge will fire immediately when hit animation can be played.
		//When hit anim is disabled, then the action will be cached and will be processed at the END of DisallowHitAnim event.
		//During all other actions, however, it will use the normal check of inputAllowed and combatActionAllowed. This is a super hack. And we will all go to hell for this.	
	event OnAnimEvent_DisallowHitAnim( animEventName : name, animEventType : EAnimationEventType, animInfo : SAnimationEventAnimInfo )
	{
		if ( animEventType == AET_DurationEnd )
		{	
			if ( ( BufferCombatAction == EBAT_Dodge || BufferCombatAction == EBAT_Roll )
					&&  IsInCombatAction() 
					&& GetBehaviorVariable( 'combatActionType' ) == (int)CAT_Attack )
			{
				//LogChannel('combatActionAllowed',"BufferCombatAction != EBAT_EMPTY");
				( (CR4Player)this ).ProcessCombatActionBuffer();
				disableActionBlend = true;
			}
		}
		else if ( IsInCombatAction() && GetBehaviorVariable( 'combatActionType' ) == (int)CAT_Dodge && animEventType == AET_DurationStart )
		{
			disableActionBlend = false;
		}
		
		super.OnAnimEvent_DisallowHitAnim( animEventName, animEventType, animInfo );
	}
	
	
	event OnAnimEvent_FadeOut( animEventName : name, animEventType : EAnimationEventType, animInfo : SAnimationEventAnimInfo )
	{
		theGame.FadeOutAsync( 0.2, Color( 0, 0, 0, 1 ) );
	}
	
	event OnAnimEvent_FadeIn( animEventName : name, animEventType : EAnimationEventType, animInfo : SAnimationEventAnimInfo )
	{
		theGame.FadeInAsync( 0.4 );
	}
	
	event OnAnimEvent_BloodTrailForced( animEventName : name, animEventType : EAnimationEventType, animInfo : SAnimationEventAnimInfo )
	{
		var bloodTrailParam 	: CBloodTrailEffect;
		var weaponId			: SItemUniqueId;
		
		if ( isInFinisher )
		{
			bloodTrailParam = (CBloodTrailEffect)(GetFinisherVictim()).GetGameplayEntityParam( 'CBloodTrailEffect' );
			weaponId = this.inv.GetItemFromSlot('r_weapon');
			if ( bloodTrailParam )
				thePlayer.inv.PlayItemEffect( weaponId, bloodTrailParam.GetEffectName() );
		}
	}
	
	event OnAnimEvent_SlowMo( animEventName : name, animEventType : EAnimationEventType, animInfo : SAnimationEventAnimInfo )
	{
		if ( isInFinisher && DisableManualCameraControlStackHasSource( 'Finisher' ) )
		{
			if( animEventType != AET_DurationEnd  )
				theGame.SetTimeScale( 0.1f, 'AnimEventSlomoMo', 1000, true );
			else 
				theGame.RemoveTimeScale( 'AnimEventSlomoMo' );	
		}
	}
	
	event OnAnimEvent_PlayFinisherBlood( animEventName : name, animEventType : EAnimationEventType, animInfo : SAnimationEventAnimInfo )
	{
		if ( isInFinisher ) 
		{
			SpawnFinisherBlood();
		}
	}
	
	event OnAnimEvent_OnWeaponDrawReady( animEventName : name, animEventType : EAnimationEventType, animInfo : SAnimationEventAnimInfo )
	{
		weaponHolster.OnWeaponDrawReady();
	}
	
	event OnAnimEvent_OnWeaponHolsterReady( animEventName : name, animEventType : EAnimationEventType, animInfo : SAnimationEventAnimInfo )
	{
		weaponHolster.OnWeaponHolsterReady();
	}
	
	event OnAnimEvent_ThrowHoldTest( animEventName : name, animEventType : EAnimationEventType, animInfo : SAnimationEventAnimInfo )
	{
		var thrownEntity		: CThrowable;
		
		thrownEntity = (CThrowable)EntityHandleGet( thrownEntityHandle );
		
		if( IsThrowHold() )
		{
			SetBehaviorVariable( 'throwStage', (int)TS_Loop );
			PushState( 'AimThrow' );
			thrownEntity.StartAiming();
		}
		else
		{
			BombThrowRelease();
			SetCombatIdleStance( 1.f );
		}
	}
	
	event OnAnimEvent_AllowTempLookAt( animEventName : name, animEventType : EAnimationEventType, animInfo : SAnimationEventAnimInfo )
	{
		if( animEventType == AET_DurationStart )
			SetTempLookAtTarget( slideTarget );
		else if( animEventType == AET_DurationEnd )
			SetTempLookAtTarget( NULL );
	}
	
	protected var slideNPC			: CNewNPC;
	protected var minSlideDistance	: float;
	protected var maxSlideDistance	: float;
	protected var slideTicket 		: SMovementAdjustmentRequestTicket;
	
	event OnAnimEvent_SlideToTarget( animEventName : name, animEventType : EAnimationEventType, animInfo : SAnimationEventAnimInfo )
	{
		var movementAdjustor	: CMovementAdjustor;
		
		if( animEventType == AET_DurationStart )
		{
			slideNPC = (CNewNPC)slideTarget;
		}
			
		if( !slideNPC )
		{
			return false;
		}
			
		if( animEventType == AET_DurationStart && slideNPC.GetGameplayVisibility() )
		{
			movementAdjustor = GetMovingAgentComponent().GetMovementAdjustor();
			slideTicket = movementAdjustor.GetRequest( 'SlideToTarget' );
			movementAdjustor.CancelByName( 'SlideToTarget' );
			slideTicket = movementAdjustor.CreateNewRequest( 'SlideToTarget' );
			movementAdjustor.BindToEventAnimInfo( slideTicket, animInfo );
			//movementAdjustor.Continuous(slideTicket);
			movementAdjustor.MaxLocationAdjustmentSpeed( slideTicket, 1000000 );
			movementAdjustor.ScaleAnimation( slideTicket );
			minSlideDistance = ((CMovingPhysicalAgentComponent)this.GetMovingAgentComponent()).GetCapsuleRadius()+((CMovingPhysicalAgentComponent)slideNPC.GetMovingAgentComponent()).GetCapsuleRadius();
			if( IsInCombatFist() )
			{
				maxSlideDistance = 1000.0f;	
			}
			else
			{
				maxSlideDistance = minSlideDistance;
			}
			movementAdjustor.SlideTowards( slideTicket, slideTarget, minSlideDistance, maxSlideDistance );	
		}
		else if( !slideNPC.GetGameplayVisibility() )
		{
			movementAdjustor = GetMovingAgentComponent().GetMovementAdjustor();
			movementAdjustor.CancelByName( 'SlideToTarget' );
			slideNPC = NULL;
		}
		else 
		{
			movementAdjustor = GetMovingAgentComponent().GetMovementAdjustor();
			movementAdjustor.SlideTowards( slideTicket, slideTarget, minSlideDistance, maxSlideDistance );				
		}
	}
	
	event OnAnimEvent_ActionBlend( animEventName : name, animEventType : EAnimationEventType, animInfo : SAnimationEventAnimInfo )
	{
	}
	/*
	event OnAnimEvent_Throwable( animEventName : name, animEventType : EAnimationEventType, animInfo : SAnimationEventAnimInfo )
	{
		var thrownEntity		: CThrowable;	
		
		thrownEntity = (CThrowable)EntityHandleGet( thrownEntityHandle );
			
		if ( inv.IsItemCrossbow( inv.GetItemFromSlot('l_weapon') ) &&  rangedWeapon.OnProcessThrowEvent( animEventName ) )
		{		
			return true;
		}
		else if( thrownEntity && IsThrowingItem() && thrownEntity.OnProcessThrowEvent( animEventName ) )
		{
			return true;
		}	
	}*/
	
	event OnAnimEvent_SubstateManager( animEventName : name, animEventType : EAnimationEventType, animInfo : SAnimationEventAnimInfo )
	{
		// Notify the exploration manager
		substateManager.OnAnimEvent( animEventName, animEventType, animInfo );
	}
	
	event OnAnimEvent_AllowFall( animEventName : name, animEventType : EAnimationEventType, animInfo : SAnimationEventAnimInfo )
	{
		if ( !substateManager.m_OwnerMAC.IsOnGround() )
		{
			substateManager.m_SharedDataO.SetFallFromCritical( true );
			substateManager.m_MoverO.SetVelocity( -6.0f * GetWorldForward() );
			substateManager.QueueStateExternal( 'Jump' );
			RemoveBuff( EET_Knockdown, true );
			RemoveBuff( EET_HeavyKnockdown, true );
			return true;
		}
		return false;
	}
	
	event OnAnimEvent_AllowFall2( animEventName : name, animEventType : EAnimationEventType, animInfo : SAnimationEventAnimInfo )
	{
		if ( !substateManager.m_OwnerMAC.IsOnGround() )
		{
			//substateManager.m_SharedDataO.m_FromCriticalB	= true;
			//substateManager.m_MoverO.SetVelocity( -6.0f * GetWorldForward() );
			substateManager.QueueStateExternal( 'Jump' );
			RemoveBuff( EET_Knockdown, true );
			RemoveBuff( EET_HeavyKnockdown, true );
		}
		if( substateManager.StateWantsAndCanEnter( 'Slide' ) )
		{
			substateManager.QueueStateExternal( 'Slide' );
		}
	}
	
	event OnAnimEvent_DettachGround( animEventName : name, animEventType : EAnimationEventType, animInfo : SAnimationEventAnimInfo )
	{
		//substateManager.m_MoverO.SetManualMovement( true );
	}
	
	//pad vibration for finishers
	event OnAnimEvent_pad_vibration( animEventName : name, animEventType : EAnimationEventType, animInfo : SAnimationEventAnimInfo )
	{
		var witcher : W3PlayerWitcher;
		
		theGame.VibrateControllerHard();
		
		//delayed FX for runeword 10 & 12
		witcher = GetWitcherPlayer();
		if(isInFinisher && witcher)
		{
			if(HasAbility('Runeword 10 _Stats', true) && !witcher.runeword10TriggerredOnFinisher && ((bool)theGame.GetInGameConfigWrapper().GetVarValue('Gameplay', 'AutomaticFinishersEnabled')) == true)
			{				
				witcher.Runeword10Triggerred();
				witcher.runeword10TriggerredOnFinisher = true;
			}
			else if(HasAbility('Runeword 12 _Stats', true) && !witcher.runeword12TriggerredOnFinisher)
			{
				witcher.Runeword12Triggerred();
				witcher.runeword12TriggerredOnFinisher = true;
			}
		}
	}
	
	//pad vibration light
	event OnAnimEvent_pad_vibration_light( animEventName : name, animEventType : EAnimationEventType, animInfo : SAnimationEventAnimInfo )
	{
		//theGame.VibrateControllerLight();	//draw & sheathe weapon
	}
	
	event OnAnimEvent_KillWithRagdoll( animEventName : name, animEventType : EAnimationEventType, animInfo : SAnimationEventAnimInfo )
	{
		//thePlayer.SetKinematic( false );
		//thePlayer.Kill();
	}
	
	event OnAnimEvent_RemoveBurning( animEventName : name, animEventType : EAnimationEventType, animInfo : SAnimationEventAnimInfo )
	{	
		thePlayer.AddBuffImmunity(EET_Burning, 'AnimEvent_RemoveBurning', true);
	}
	
	event OnAnimEvent_RemoveTangled( animEventName : name, animEventType : EAnimationEventType, animInfo : SAnimationEventAnimInfo )
	{
		if ( this.HasBuff( EET_Tangled ) )
		{
			this.StopEffect('black_spider_web');
			this.PlayEffectSingle('black_spider_web_break');		
		}
	}
	
	// sound generation for creatures following noise instead of just finding combat target
	event OnAnimEvent_MoveNoise( animEventName : name, animEventType : EAnimationEventType, animInfo : SAnimationEventAnimInfo )
	{
		theGame.GetBehTreeReactionManager().CreateReactionEventIfPossible( this, 'MoveNoise', -1, 30.0f, -1.f, -1, true );
	}
///////////////////////////////////////////////////////////////////////////
	
	event OnBehaviorGraphNotification( notificationName : name, stateName : name )
	{
		substateManager.OnBehaviorGraphNotification( notificationName, stateName );
		
		if( notificationName == 'PlayerRunActivate' )
		{
			isInRunAnimation = true;
		}
		else if( notificationName == 'PlayerRunDeactivate' )
		{
			isInRunAnimation = false;
		}
	}

	event OnEnumAnimEvent( animEventName : name, variant : SEnumVariant, animEventType : EAnimationEventType, animEventDuration : float, animInfo : SAnimationEventAnimInfo )
	{
		var movementAdjustor : CMovementAdjustor;
		var ticket : SMovementAdjustmentRequestTicket;
		var rotationRate : ERotationRate;
		
		if ( animEventName == 'RotateToTarget' )
		{
			/**
			 *	Rotate player to target
			 */
			rotationRate = GetRotationRateFromAnimEvent( variant.enumValue );

			movementAdjustor = GetMovingAgentComponent().GetMovementAdjustor();
			if ( animEventType == AET_DurationStart || animEventType == AET_DurationStartInTheMiddle )
			{
				// when it starts (also in the middle - it may mean that we switch between events)
				// create request if there isn't any and always setup rotation rate
				if (! movementAdjustor.IsRequestActive( movementAdjustor.GetRequest( 'RotateToTarget' ) ) )
				{
					// start rotation adjustment
					ticket = movementAdjustor.CreateNewRequest( 'RotateToTarget' );
					
					// use adjustment duration only when RR_0 is selected, otherwise use continuous to match desired rotation as fast as possible
					if ((int)rotationRate == 0)
						movementAdjustor.AdjustmentDuration( ticket, animEventDuration );
					else
					{
						movementAdjustor.Continuous( ticket );
						movementAdjustor.BindToEvent( ticket, 'RotateToTarget' );
					}	
					
					movementAdjustor.DontUseSourceAnimation( ticket ); // do not use source anim as it will use delta seconds from event
					movementAdjustor.ReplaceRotation( ticket );
				}
				else
				{
					// get existing ticket to update rotation rate
					ticket = movementAdjustor.GetRequest( 'RotateToTarget' );
				}
				MovAdjRotateToTarget( ticket );
				// update rotationRate
				if ((int)rotationRate > 0)
				{
					movementAdjustor.MaxRotationAdjustmentSpeed( ticket, (float)((int)rotationRate) );
				}
			}
			else if ( animEventType == AET_DurationEnd )
			{
				// it will end if there's no event, but sometimes one event could end and be followed by another
				// and we want to have that continuity kept, that's why we won't end request manually
			}
			else
			{
				// continuous update (makes more sense when there is no target and we want to rotate towards camera)
				ticket = movementAdjustor.GetRequest( 'RotateToTarget' );
				MovAdjRotateToTarget( ticket );
			}
		}
		super.OnEnumAnimEvent(animEventName, variant, animEventType, animEventDuration, animInfo);
	}
		
	event OnTeleported()
	{
		if( substateManager )
		{
			substateManager.OnTeleported();
		}
	}
	
	/*public function CaptureSafePosition()
	{
		lastSafePosition	= GetWorldPosition();
		lastSafeRotation	= GetWorldRotation();
		safePositionStored	= true;
	}*/

	///////////////////////////////////////////////////////////////////////////
	// FISTFIGHT
	///////////////////////////////////////////////////////////////////////////
	event OnStartFistfightMinigame()
	{
		super.OnStartFistfightMinigame();
		
		//Goto state CombatFist		
		SetFistFightMinigameEnabled( true );
		FistFightHealthChange( true );
		thePlayer.GetPlayerMode().ForceCombatMode( FCMR_QuestFunction );
		SetImmortalityMode(AIM_Unconscious, AIC_Fistfight);
		thePlayer.SetBehaviorVariable( 'playerWeaponLatent', (int)PW_Fists );
		GotoCombatStateWithAction( IA_None );
		((CMovingAgentComponent)this.GetMovingAgentComponent()).SnapToNavigableSpace( true );
		EquipGeraltFistfightWeapon( true );	
		BlockAction( EIAB_RadialMenu, 	'FistfightMinigame' ,,true);
		BlockAction( EIAB_Signs, 		'FistfightMinigame' ,,true);
		BlockAction( EIAB_ThrowBomb, 	'FistfightMinigame' ,,true);
		BlockAction( EIAB_UsableItem, 	'FistfightMinigame' ,,true);
		BlockAction( EIAB_Crossbow, 	'FistfightMinigame' ,,true);
		BlockAction( EIAB_DrawWeapon, 	'FistfightMinigame' ,,true);
		BlockAction( EIAB_RunAndSprint,	'FistfightMinigame' ,,true);
		BlockAction( EIAB_SwordAttack, 	'FistfightMinigame' ,,true);
		BlockAction( EIAB_CallHorse, 	'FistfightMinigame' ,,true);
		BlockAction( EIAB_Roll, 		'FistfightMinigame' ,,true);
		BlockAction( EIAB_Interactions, 'FistfightMinigame' ,,true);
		BlockAction( EIAB_Explorations, 'FistfightMinigame' ,,true);
		BlockAction( EIAB_OpenInventory, 'FistfightMinigame' ,,true);
		BlockAction( EIAB_QuickSlots, 	 'FistfightMinigame' ,,true);
		BlockAction( EIAB_OpenCharacterPanel, 'FistfightMinigame' ,,true);
	}
	
	event OnEndFistfightMinigame()
	{
		((CMovingAgentComponent)this.GetMovingAgentComponent()).SnapToNavigableSpace( false );
		FistFightHealthChange( false );
		thePlayer.GetPlayerMode().ReleaseForceCombatMode( FCMR_QuestFunction );
		EquipGeraltFistfightWeapon( false );
		SetFistFightMinigameEnabled( false );
		SetImmortalityMode(AIM_None, AIC_Fistfight);
		BlockAllActions('FistfightMinigame',false);
		
		super.OnEndFistfightMinigame();
	}
	
	public function GetFistFightFinisher( out masterAnimName, slaveAnimIndex : name )
	{
		var index : int;
	
		index = RandRange(1);
		switch ( index )
		{
			case 0 : masterAnimName = 'man_fistfight_finisher_1_win'; slaveAnimIndex = 'man_fistfight_finisher_1_looser';
		}
	}
	
	public function SetFistFightMinigameEnabled( flag : bool )
	{
		fistFightMinigameEnabled = flag;
	}
	
	public function SetFistFightParams( toDeath : bool, endsWithBS : bool )
	{
		isFFMinigameToTheDeath = toDeath;
		FFMinigameEndsithBS = endsWithBS;
	}
	
	public function IsFistFightMinigameEnabled() : bool
	{
		return fistFightMinigameEnabled;
	}

	public function IsFistFightMinigameToTheDeath() : bool
	{
		return isFFMinigameToTheDeath;
	}

	public function FistFightHealthChange( val : bool )
	{
		if( val == true )
		{
			GeraltMaxHealth = thePlayer.GetStatMax(BCS_Vitality);
			ClampGeraltMaxHealth( 2000 );
			SetHealthPerc( 100 );
		}
		else
		{
			ClampGeraltMaxHealth( GeraltMaxHealth );
			SetHealthPerc( 100 );
		}
		
	}
	
	function ClampGeraltMaxHealth( val : float )
	{
		thePlayer.abilityManager.SetStatPointMax( BCS_Vitality, val );
	}
	
	function EquipGeraltFistfightWeapon( val : bool )
	{
		if ( val )
		{
			fistsItems = thePlayer.GetInventory().AddAnItem( 'Geralt Fistfight Fists', 1, true, true );
			thePlayer.GetInventory().MountItem( fistsItems[0] , true );
		}
		else
		{
			thePlayer.GetInventory().DropItem( fistsItems[0], true );
		}
	}

	///////////////////////////////////////////////////////////////////////////
	// GWINT
	///////////////////////////////////////////////////////////////////////////
	public function GetGwintAiDifficulty() : EGwintDifficultyMode
	{
		return gwintAiDifficulty;
	}

	public function SetGwintAiDifficulty( difficulty : EGwintDifficultyMode )
	{
		gwintAiDifficulty = difficulty;
	}

	public function GetGwintAiAggression() : EGwintAggressionMode
	{
		return gwintAiAggression;
	}

	public function SetGwintAiAggression( aggression : EGwintAggressionMode )
	{
		gwintAiAggression = aggression;
	}

	public function GetGwintMinigameState() : EMinigameState	
	{
		return gwintMinigameState;
	}
	
	public function SetGwintMinigameState( minigameState : EMinigameState )
	{
		gwintMinigameState = minigameState;
	}
	
	public function OnGwintGameRequested( deckName : name, forceFaction : eGwintFaction )
	{
		var gwintManager:CR4GwintManager;
		gwintManager = theGame.GetGwintManager();
		
		gwintMinigameState = EMS_None;
		
		gwintManager.SetEnemyDeckByName(deckName);
		gwintManager.SetForcedFaction(forceFaction);
		
		if (gwintManager.GetHasDoneTutorial() || !theGame.GetTutorialSystem().AreMessagesEnabled())
		{
			gwintManager.gameRequested = true;
			theGame.RequestMenu( 'DeckBuilder' );
		}
		else
		{
			theGame.GetGuiManager().ShowUserDialog( UMID_SkipGwintTutorial, "gwint_tutorial_play_query_title", "gwint_tutorial_play_query", UDB_YesNo );
		}
	}
	
	public function StartGwint_TutorialOrSkip( skipTutorial : bool )
	{
		var gwintManager : CR4GwintManager;
		
		if( skipTutorial )
		{
			gwintManager = theGame.GetGwintManager();
			gwintManager.gameRequested = true;
			gwintManager.SetHasDoneTutorial(true);
			gwintManager.SetHasDoneDeckTutorial(true);
			theGame.RequestMenu( 'DeckBuilder' );
		}
		else
		{
			theGame.RequestMenu( 'GwintGame' );
		}
	}
	
	private var gwintCardNumbersArray : array<int>;
	
	public function InitGwintCardNumbersArray( arr : array<int> )
	{
		gwintCardNumbersArray.Clear();
		gwintCardNumbersArray = arr;
	}
	
	public function GetCardNumbersArray() : array<int>
	{
		return gwintCardNumbersArray;
	}
	///////////////////////////////////////////////////////////////////////////
	// COMBAT CAMERA
	///////////////////////////////////////////////////////////////////////////
	
	protected var customCameraStack : array<SCustomCameraParams>;
	
	public function AddCustomCamToStack( customCameraParams : SCustomCameraParams ) : int
	{
		if( customCameraParams.useCustomCamera )
		{
			if ( customCameraParams.cameraParams.enums[0].enumType != 'ECustomCameraType' )
			{
				LogChannel( 'CustomCamera', "ERROR: Selected enum is not a custom camera!!!" );
				return -1;
			}
			else
			{			
				customCameraStack.PushBack( customCameraParams );
				return ( customCameraStack.Size() - 1 );
			}
		}
		
		return 0;
	}
	
	public function DisableCustomCamInStack( customCameraStackIndex : int )
	{
		if ( customCameraStackIndex != -1 )
			customCameraStack[customCameraStackIndex].useCustomCamera = false;
		else
			LogChannel( 'CustomCamera', "ERROR: Custom camera to disable does not exist!!!" );
	}
	
	event OnInteriorStateChanged( inInterior : bool )
	{
		interiorCamera = inInterior;
	}
	
	event OnModifyPlayerSpeed( flag : bool )
	{
		modifyPlayerSpeed = flag;
		SetBehaviorVariable( 'modifyPlayerSpeed', (float)modifyPlayerSpeed );
	}
		
	event OnGameCameraTick( out moveData : SCameraMovementData, dt : float )
	{
		var targetRotation	: EulerAngles;
		var dist : float;
		
		if( thePlayer.IsInCombat() )
		{
			dist = VecDistance2D( thePlayer.GetWorldPosition(), thePlayer.GetTarget().GetWorldPosition() );
			thePlayer.GetVisualDebug().AddText( 'dbg', dist, thePlayer.GetWorldPosition() + Vector( 0.f,0.f,2.f ), true, , Color( 0, 255, 0 ) );
		}
		
		if ( isStartingFistFightMinigame )
		{
			moveData.pivotRotationValue = fistFightTeleportNode.GetWorldRotation();
			isStartingFistFightMinigame = false;
		}
		
		// Specific substate
		if( substateManager.UpdateCameraIfNeeded( moveData, dt ) )
		{
			return true;
		}
		
		// focusMode camera
		if ( theGame.IsFocusModeActive() )
		{
			theGame.GetGameCamera().ChangePivotRotationController( 'Exploration' );
			theGame.GetGameCamera().ChangePivotDistanceController( 'Default' );
			theGame.GetGameCamera().ChangePivotPositionController( 'Default' );
		
			// HACK
			moveData.pivotRotationController = theGame.GetGameCamera().GetActivePivotRotationController();
			moveData.pivotDistanceController = theGame.GetGameCamera().GetActivePivotDistanceController();
			moveData.pivotPositionController = theGame.GetGameCamera().GetActivePivotPositionController();
			// END HACK		
		
		
			moveData.pivotPositionController.SetDesiredPosition( thePlayer.GetWorldPosition() );

			moveData.pivotRotationController.SetDesiredPitch( -10.0f );
			moveData.pivotRotationController.maxPitch = 50.0;

			moveData.pivotDistanceController.SetDesiredDistance( 3.5f );

			if ( !interiorCamera )
			{
				moveData.pivotPositionController.offsetZ = 1.5f;
				DampVectorSpring( moveData.cameraLocalSpaceOffset, moveData.cameraLocalSpaceOffsetVel, Vector( 0.5f, 2.0f, 0.3f ), 0.20f, dt );
			}
			else
			{
				moveData.pivotPositionController.offsetZ = 1.3f;
				DampVectorSpring( moveData.cameraLocalSpaceOffset, moveData.cameraLocalSpaceOffsetVel, Vector( 0.5f, 2.3f, 0.5f ), 0.3f, dt );
			}
			
			return true;
		}
		
		
		
		// HACK: Target heading ( Made for ladder )
		if( substateManager.m_SharedDataO.IsForceHeading( targetRotation ) )
		{
			moveData.pivotRotationController.SetDesiredHeading( targetRotation.Yaw );
			moveData.pivotRotationController.SetDesiredPitch( targetRotation.Pitch );
			moveData.pivotRotationValue.Yaw		= LerpAngleF( 2.1f * dt, moveData.pivotRotationValue.Yaw, targetRotation.Yaw );
			moveData.pivotRotationValue.Pitch	= LerpAngleF( 1.0f * dt, moveData.pivotRotationValue.Pitch, targetRotation.Pitch );
			//return true;
		}
		
		
		if( customCameraStack.Size() > 0 )
		{
			// HANDLE CUSTOM CAMERAS HERE
			// IF HANDLED - RETURN TRUE
		}
		
		return false;
	}
	
	private var questCameraRequest : SQuestCameraRequest;
	private var cameraRequestTimeStamp : float;
	
	public function RequestQuestCamera( camera : SQuestCameraRequest )
	{
		questCameraRequest = camera;
		questCameraRequest.requestTimeStamp = theGame.GetEngineTimeAsSeconds();
	}
	
	public function ResetQuestCameraRequest()
	{
		var cameraRequest : SQuestCameraRequest;
		
		questCameraRequest = cameraRequest;
	}
	
	event OnGameCameraPostTick( out moveData : SCameraMovementData, dt : float )
	{
		var ent : CEntity;
		var playerPos : Vector;
		var angles : EulerAngles;
		
		var distance : float;
		
		/*if( thePlayer.IsInCombat() )
		{
			distance = VecDistance2D( thePlayer.GetWorldPosition(), thePlayer.GetTarget().GetWorldPosition() );
		}
		
		thePlayer.GetVisualDebug().AddText( 'Distance', "Distance form target: " + distance, thePlayer.GetWorldPosition() + Vector( 0.f,0.f,2.f ), true, , Color( 0, 255, 0 ) );
		*/
		
		if ( questCameraRequest.requestTimeStamp > 0 )
		{
			if ( questCameraRequest.duration > 0 && questCameraRequest.requestTimeStamp + questCameraRequest.duration < theGame.GetEngineTimeAsSeconds() )
			{
				ResetQuestCameraRequest();
				return false;
			}
				
			if( questCameraRequest.lookAtTag )
			{
				ent = theGame.GetEntityByTag( questCameraRequest.lookAtTag );
				playerPos = GetWorldPosition();
				playerPos.Z += 1.8f;
				
				angles = VecToRotation( ent.GetWorldPosition() - playerPos );
				
				moveData.pivotRotationController.SetDesiredHeading( angles.Yaw );
				moveData.pivotRotationController.SetDesiredPitch( -angles.Pitch );
			}
			else
			{
				if( questCameraRequest.requestYaw )
				{
					angles = GetWorldRotation();
					moveData.pivotRotationController.SetDesiredHeading( angles.Yaw + questCameraRequest.yaw );
				}
				
				if( questCameraRequest.requestPitch )
				{
					moveData.pivotRotationController.SetDesiredPitch( questCameraRequest.pitch );
				}
			}
		}
	}
	
	var wasRunning : bool;
	var vel : float;
	var smoothTime	: float;
	
	var constDamper : ConstDamper;
	var rotMultVel	: float;
	
	public function UpdateCameraInterior( out moveData : SCameraMovementData, timeDelta : float )
	{	
		var camDist 	: float;
		var camOffset 	: float;
		var rotMultDest	: float;
		var rotMult	: float;
		var angles		: EulerAngles;
			
		theGame.GetGameCamera().ChangePivotRotationController( 'ExplorationInterior' );
		theGame.GetGameCamera().ChangePivotDistanceController( 'Default' );
		theGame.GetGameCamera().ChangePivotPositionController( 'Default' );
	
		// HACK
		moveData.pivotRotationController = theGame.GetGameCamera().GetActivePivotRotationController();
		moveData.pivotDistanceController = theGame.GetGameCamera().GetActivePivotDistanceController();
		moveData.pivotPositionController = theGame.GetGameCamera().GetActivePivotPositionController();
		// END HACK

		moveData.pivotPositionController.SetDesiredPosition( GetWorldPosition(), 15.f );

		if ( !constDamper )
		{
			constDamper = new ConstDamper in this;
			constDamper.SetDamp( 0.35f );
		}		
		
		if ( rawPlayerSpeed <= 0 || AbsF( AngleDistance( rawPlayerHeading, GetHeading() ) ) > 135 )
			constDamper.Reset();
		else if ( theGame.IsUberMovementEnabled() )
			rotMult = 0.5f;
		else
			rotMult = 1.f;

		rotMult = constDamper.UpdateAndGet( timeDelta, rotMult );
		
		//DampFloatSpring( rotMult, rotMultVel, rotMultDest, 4.f, timeDelta );
		
		if ( AbsF( AngleDistance( GetHeading(), moveData.pivotRotationValue.Yaw ) ) < 135.f && rawPlayerSpeed > 0 )
			moveData.pivotRotationController.SetDesiredHeading( GetHeading(), rotMult );
		else 
			moveData.pivotRotationController.SetDesiredHeading( moveData.pivotRotationValue.Yaw );
		
		moveData.pivotDistanceController.SetDesiredDistance( 1.5f );
		
		angles = VecToRotation( GetMovingAgentComponent().GetVelocity() );		
		if ( AbsF( angles.Pitch ) < 8.f || bLAxisReleased )
			moveData.pivotRotationController.SetDesiredPitch( -10.f );
		else
			moveData.pivotRotationController.SetDesiredPitch( -angles.Pitch - 18.f );	
		
		if ( IsGuarded() )
			moveData.pivotPositionController.offsetZ = 1.0f;
		else 
			moveData.pivotPositionController.offsetZ = 1.3f;
		
		//if ( movementLockType == PMLT_NoSprint  )
		//{			
			if ( playerMoveType >= PMT_Run )
			{		
				//camDist = 0.3f;
				camDist = -0.5f;
				camOffset = 0.25;
				
				if ( !wasRunning )
				{
					smoothTime = 1.f;
					wasRunning = true;
				}				
				DampFloatSpring( smoothTime, vel, 0.1, 0.5, timeDelta );
			}
			else
			{
				//camDist = -0.6f;
				camDist = 0.f;			
				camOffset = 0.4f;
				smoothTime = 0.2f;
				wasRunning = false;
			}
			
			//camDist = theGame.GetGameplayConfigFloatValue( 'debugA' );

			DampVectorSpring( moveData.cameraLocalSpaceOffset, moveData.cameraLocalSpaceOffsetVel, Vector( 0.3f, camDist, 0.3f ), smoothTime, timeDelta );	
			//DampVectorSpring( moveData.cameraLocalSpaceOffset, moveData.cameraLocalSpaceOffsetVel, Vector( 0.5, camDist, camOffset ), smoothTime, timeDelta );
		//}
		//else
		//	DampVectorSpring( moveData.cameraLocalSpaceOffset, moveData.cameraLocalSpaceOffsetVel, Vector( theGame.GetGameplayConfigFloatValue( 'debugA' ),theGame.GetGameplayConfigFloatValue( 'debugB' ),theGame.GetGameplayConfigFloatValue( 'debugC' ) ), 0.4f, timeDelta );
			//DampVectorSpring( moveData.cameraLocalSpaceOffset, moveData.cameraLocalSpaceOffsetVel, Vector( 0.7f, 0.f, 0.3 ), 0.4f, timeDelta );	
	}
	
	
	var wasBRAxisPushed 					: bool;
	protected function UpdateCameraChanneledSign( out moveData : SCameraMovementData, timeDelta : float ) : bool
	{	
		var screenSpaceOffset	: float;
		var screenSpaceOffsetFwd : float;
		var screenSpaceOffsetUp	: float;
		var heading				: float;
		var pitch				: float;
		var playerToTargetRot 	: EulerAngles;
		var rightOffset			: float = -20.f;
		var leftOffset			: float = 15.f;
		var angles				: EulerAngles;
		
		var vec					: Vector;
		
		if( this.IsCurrentSignChanneled() && this.GetCurrentlyCastSign() != ST_Quen && this.GetCurrentlyCastSign() != ST_Yrden )
		{
			theGame.GetGameCamera().ChangePivotRotationController( 'SignChannel' );
			theGame.GetGameCamera().ChangePivotDistanceController( 'SignChannel' );
			// HACK
			moveData.pivotRotationController = theGame.GetGameCamera().GetActivePivotRotationController();
			moveData.pivotDistanceController = theGame.GetGameCamera().GetActivePivotDistanceController();
			// END HACK

			if ( GetCurrentlyCastSign() == ST_Axii )
				leftOffset = 32.f;

			if ( oTCameraOffset != leftOffset && oTCameraOffset != rightOffset  )
			{
				if( ( interiorCamera && !moveTarget )
					|| ( AngleDistance( GetHeading(), moveData.pivotRotationValue.Yaw ) < 0 ) )
					oTCameraOffset = leftOffset;				
				else
					oTCameraOffset = rightOffset;
			}
			
			if ( oTCameraOffset == leftOffset )
			{
				screenSpaceOffset = 0.65f;
				oTCameraPitchOffset = 13.f; 
				//moveData.pivotDistanceController.SetDesiredDistance( 0.5f, 3.f );
			}
			else if ( oTCameraOffset == rightOffset )
			{
				screenSpaceOffset = -0.65f;
				oTCameraPitchOffset = 13.f; 
				//moveData.pivotDistanceController.SetDesiredDistance( 0.5f, 3.f );
			}
		
			moveData.pivotPositionController.offsetZ = 1.3f;
			
			if ( !delayCameraOrientationChange )
			{
				if ( GetOrientationTarget() == OT_Camera || GetOrientationTarget() == OT_CameraOffset )
				{
					if ( bRAxisReleased )
					{
						heading = moveData.pivotRotationValue.Yaw;
						pitch = moveData.pivotRotationValue.Pitch;
					}
					else
					{
						heading = moveData.pivotRotationValue.Yaw + oTCameraOffset;
						pitch = moveData.pivotRotationValue.Pitch; //+ oTCameraPitchOffset;
					}
				}
				else if ( GetOrientationTarget() == OT_Actor )
				{
					if ( GetDisplayTarget() )
						vec = GetDisplayTarget().GetWorldPosition() - GetWorldPosition();
					else if ( slideTarget )	
						vec = slideTarget.GetWorldPosition() - GetWorldPosition();
					else if ( GetTarget() )
						vec = GetTarget().GetWorldPosition() - GetWorldPosition();
					else
						vec = GetHeadingVector();
						
					angles = VecToRotation( vec );
					heading = angles.Yaw + oTCameraOffset;
					pitch = -angles.Pitch - oTCameraPitchOffset;//-angles.Pitch;				
				}
				else
				{
					angles = VecToRotation( GetHeadingVector() );
					heading = angles.Yaw + oTCameraOffset;
					pitch = -angles.Pitch - oTCameraPitchOffset;//-angles.Pitch;				
				}
			
				if ( !wasBRAxisPushed && ( !bRAxisReleased ) )//|| !lastAxisInputIsMovement ) )
					wasBRAxisPushed = true;

				moveData.pivotRotationController.SetDesiredHeading( heading , 2.f );
				moveData.pivotRotationController.SetDesiredPitch( pitch );
			}
			else
			{
				moveData.pivotRotationController.SetDesiredHeading( moveData.pivotRotationValue.Yaw, 1.f );
				moveData.pivotRotationController.SetDesiredPitch( -oTCameraPitchOffset );
			}
			
			if ( moveData.pivotRotationValue.Pitch <= 5.f && moveData.pivotRotationValue.Pitch >= -15.f )
			{
				screenSpaceOffsetFwd = 1.8;
				screenSpaceOffsetUp = 0.4;
			}
			else if ( moveData.pivotRotationValue.Pitch > 0 )
			{
				screenSpaceOffsetFwd = moveData.pivotRotationValue.Pitch*0.00727 + 1.275f;
				screenSpaceOffsetFwd = ClampF( screenSpaceOffsetFwd, 1.5, 2.2 );
				
				screenSpaceOffsetUp = -moveData.pivotRotationValue.Pitch*0.00727 + 0.4363f;
				screenSpaceOffsetUp = ClampF( screenSpaceOffsetUp, 0, 0.3 );		
			}
			else	
			{
				if ( GetCurrentlyCastSign() == ST_Axii )
				{
					screenSpaceOffsetFwd = -moveData.pivotRotationValue.Pitch*0.0425 + 0.8625f;		
					screenSpaceOffsetFwd = ClampF( screenSpaceOffsetFwd, 1.5, 2.3 );
				}
				else
				{
					screenSpaceOffsetFwd = -moveData.pivotRotationValue.Pitch*0.035 + 0.75f;
					screenSpaceOffsetFwd = ClampF( screenSpaceOffsetFwd, 1.5, 2.6 );
				}
				screenSpaceOffsetUp = -moveData.pivotRotationValue.Pitch*0.005 + 0.325f;
				screenSpaceOffsetUp = ClampF( screenSpaceOffsetUp, 0.4, 0.5 );				
			}
				
			DampVectorSpring( moveData.cameraLocalSpaceOffset, moveData.cameraLocalSpaceOffsetVel, Vector( screenSpaceOffset, screenSpaceOffsetFwd, screenSpaceOffsetUp ), 0.25f, timeDelta );//1.5,0.4		
			moveData.pivotDistanceController.SetDesiredDistance( 2.8f, 5.f );	
			moveData.pivotPositionController.SetDesiredPosition( GetWorldPosition() );		
		
			return true;
		}
		else
		{
			this.wasBRAxisPushed = false;
			
			return false;
		}
	}	

	protected function UpdateCameraForSpecialAttack( out moveData : SCameraMovementData, timeDelta : float ) : bool
	{	
		var screenSpaceOffset	: float;
		var tempHeading			: float;
		var cameraOffsetLeft	: float;
		var cameraOffsetRight	: float;
		
		if ( !specialAttackCamera )
			return false;
				
		theGame.GetGameCamera().ForceManualControlHorTimeout();
		theGame.GetGameCamera().ForceManualControlVerTimeout();	
		//if ( parent.delayCameraOrientationChange || parent.delayOrientationChange )
		//{
			cameraOffsetLeft = 30.f;
			cameraOffsetRight = -30.f;
		//}
		//else
		//{
		//	cameraOffsetLeft = 2.f;
		//	cameraOffsetRight = -2.f;
		//}
		
		theGame.GetGameCamera().ChangePivotRotationController( 'SignChannel' );
		theGame.GetGameCamera().ChangePivotDistanceController( 'SignChannel' );
		// HACK
		moveData.pivotRotationController = theGame.GetGameCamera().GetActivePivotRotationController();
		moveData.pivotDistanceController = theGame.GetGameCamera().GetActivePivotDistanceController();

		if ( slideTarget )
			tempHeading = VecHeading( slideTarget.GetWorldPosition() - GetWorldPosition() );
		else
			tempHeading = GetHeading();
			
		oTCameraPitchOffset = 0.f;		
			
		if( ( interiorCamera && !moveTarget )
			|| ( AngleDistance( tempHeading, moveData.pivotRotationValue.Yaw ) < 0 ) )
			oTCameraOffset = cameraOffsetLeft;				
		else
			oTCameraOffset = cameraOffsetRight;
		
		if ( oTCameraOffset == cameraOffsetLeft )
		{
			if ( delayCameraOrientationChange || delayOrientationChange )
			{
				screenSpaceOffset = 0.75f;
				moveData.pivotDistanceController.SetDesiredDistance( 1.6f, 3.f );
				moveData.pivotPositionController.offsetZ = 1.4f;
				moveData.pivotRotationController.SetDesiredPitch( -15.f );
			}
			else
			{
				screenSpaceOffset = 0.7f;
				moveData.pivotDistanceController.SetDesiredDistance( 3.25f );
				moveData.pivotPositionController.offsetZ = 1.2f;
				moveData.pivotRotationController.SetDesiredPitch( -10.f );			
			}
		}
		else if ( oTCameraOffset == cameraOffsetRight )
		{
			if ( delayCameraOrientationChange || delayOrientationChange )
			{
				screenSpaceOffset = -0.85f;
				moveData.pivotDistanceController.SetDesiredDistance( 1.6f, 3.f );
				moveData.pivotPositionController.offsetZ = 1.4f;
				moveData.pivotRotationController.SetDesiredPitch( -15.f );
			}
			else
			{
				screenSpaceOffset = -0.8f;
				moveData.pivotDistanceController.SetDesiredDistance( 3.25f );
				moveData.pivotPositionController.offsetZ = 1.2f;
				moveData.pivotRotationController.SetDesiredPitch( -10.f );			
			}		
		}
		else 
		{
			moveData.pivotDistanceController.SetDesiredDistance( 1.25f, 3.f );
			moveData.pivotPositionController.offsetZ = 1.3f;
			moveData.pivotRotationController.SetDesiredPitch( -5.5f );			
		}
		
		DampVectorSpring( moveData.cameraLocalSpaceOffset, moveData.cameraLocalSpaceOffsetVel, Vector( screenSpaceOffset, 0.f, 0.f ), 1.f, timeDelta );
		
		if ( !delayCameraOrientationChange )
		{
			if ( moveTarget )
				moveData.pivotRotationController.SetDesiredHeading( GetHeading() + oTCameraOffset, 0.5f );
			else
				moveData.pivotRotationController.SetDesiredHeading( GetHeading() + oTCameraOffset, 1.f );
		}
		else
			moveData.pivotRotationController.SetDesiredHeading( moveData.pivotRotationValue.Yaw, 1.f );
		
		moveData.pivotPositionController.SetDesiredPosition( GetWorldPosition() );
		
		return true;
	}


	private var fovVel : float;
	private var sprintOffset : Vector;
	private var previousOffset : bool;
	private var previousRotationVelocity : float;
	private var pivotRotationTimeStamp 	: float;
	protected function UpdateCameraSprint( out moveData : SCameraMovementData, timeDelta : float )
	{
		var angleDiff : float;
		var camOffsetVector : Vector;
		var smoothSpeed : float;
		var camera : CCustomCamera;
		var camAngularSpeed : float;
		
		var playerToCamAngle : float;
		var useExplorationSprintCam	: bool;
		
		camera = theGame.GetGameCamera();
		if( camera )
		{
			if ( sprintingCamera )
			{
				//theGame.GetGameCamera().ForceManualControlHorTimeout();
				if( thePlayer.GetAutoCameraCenter() )
				{
					theGame.GetGameCamera().ForceManualControlVerTimeout();
				}
				
				playerToCamAngle =  AbsF( AngleDistance( GetHeading(), moveData.pivotRotationValue.Yaw ) );
				
				/*if ( theGame.GetGameplayConfigFloatValue( 'debugE' ) > 0.1f )
					useExplorationSprintCam = !IsInCombat() || ( moveTarget && VecDistance( moveTarget.GetWorldPosition(), GetWorldPosition() ) > findMoveTargetDistMax );
				else*/
					useExplorationSprintCam = false;// !IsInCombat() || ( moveTarget && VecDistance( moveTarget.GetWorldPosition(), GetWorldPosition() ) > findMoveTargetDistMax );
				
				if ( useExplorationSprintCam )
				{
					if ( playerToCamAngle <= 45  )
					{
						theGame.GetGameCamera().ChangePivotRotationController( 'Sprint' );
						// HACK
						moveData.pivotRotationController = theGame.GetGameCamera().GetActivePivotRotationController();	

						moveData.pivotRotationController.SetDesiredHeading( GetHeading(), 0.25f );
						moveData.pivotRotationController.SetDesiredPitch( -3.5f, 0.5f );
						thePlayer.EnableManualCameraControl( true, 'Sprint' );			
					}
					else
					{			
						thePlayer.EnableManualCameraControl( false, 'Sprint' );
					}
				}
				else
				{
					if ( theGame.IsUberMovementEnabled() )
						moveData.pivotRotationController.SetDesiredHeading( GetHeading(), 0.35f );

					thePlayer.EnableManualCameraControl( true, 'Sprint' );		
				}
				
				if ( bRAxisReleased )
				{
					if ( AbsF( rawLeftJoyRot ) > 25 )
						angleDiff = AngleDistance( GetHeading(), moveData.pivotRotationValue.Yaw );
					
					pivotRotationTimeStamp = theGame.GetEngineTimeAsSeconds();
					previousRotationVelocity = 0.f;	
				}
				else
				{
					if ( previousRotationVelocity <= 0 && AbsF( moveData.pivotRotationVelocity.Yaw ) > 250 )
					{
						pivotRotationTimeStamp = theGame.GetEngineTimeAsSeconds();
						previousRotationVelocity = AbsF( moveData.pivotRotationVelocity.Yaw );
					}
				}
				
				if ( pivotRotationTimeStamp + 0.4f <= theGame.GetEngineTimeAsSeconds() && AbsF( moveData.pivotRotationVelocity.Yaw ) > 250 )
					angleDiff = VecHeading( rawRightJoyVec );
	
				if ( useExplorationSprintCam )
				{
					if ( playerToCamAngle > 90 )
					{
						camOffsetVector.X = 0.f;
						smoothSpeed = 1.f;						
					}
					else if ( angleDiff > 15.f )
					{
						camOffsetVector.X = -0.8;
						smoothSpeed = 1.f;
						previousOffset = true;
					}
					else if ( angleDiff < -15.f )
					{
						camOffsetVector.X = 0.475f;
						smoothSpeed = 1.5f;
						previousOffset = false;
					}
					else
					{
						if ( previousOffset )
						{
							camOffsetVector.X = -0.8;
							smoothSpeed = 1.5f;
						}
						else
						{
							camOffsetVector.X = 0.475f;
							smoothSpeed = 1.5f;						
						}
					}
				
					camOffsetVector.Y = 1.4f;
					camOffsetVector.Z = 0.275f;
				}
				else 
				{	
					/*camOffsetVector.X = 0.f;
					camOffsetVector.Y = 0.4f;
					camOffsetVector.Z = 0.2f;*/
					smoothSpeed = 0.75f;
					
					camOffsetVector.X = 0.f;
					camOffsetVector.Y = 1.f;
					camOffsetVector.Z = 0.2f;
					moveData.pivotRotationController.SetDesiredPitch( -10.f, 0.5f );
				}
				
				DampVectorConst( sprintOffset, camOffsetVector, smoothSpeed, timeDelta );
				
				moveData.cameraLocalSpaceOffset = sprintOffset;
				
				DampFloatSpring( camera.fov, fovVel, 70.f, 1.0, timeDelta );
			}
			else
			{
				sprintOffset = moveData.cameraLocalSpaceOffset;
				DampFloatSpring( camera.fov, fovVel, 60.f, 1.0, timeDelta );
				previousOffset = false;
			}
		}
	}
	
	function EnableSprintingCamera( flag : bool )
	{	
		if( !theGame.IsUberMovementEnabled() && !useSprintingCameraAnim )
		{
			return;
		}	
	
		super.EnableSprintingCamera( flag );
		
		if ( !flag )
		{
			thePlayer.EnableManualCameraControl( true, 'Sprint' );
		}
	}	

	protected function UpdateCameraCombatActionButNotInCombat( out moveData : SCameraMovementData, timeDelta : float )
	{	
		var vel			: Vector;
		var heading 	: float;
		var pitch		: float;
		var headingMult : float;
		var pitchMult	: float;
		var camOffset	: Vector;
		var buff 		: CBaseGameplayEffect;
		var runningAndAlertNear		: bool;
		var desiredDist				: float;
	
		if ( ( !IsCurrentSignChanneled() || GetCurrentlyCastSign() == ST_Quen || GetCurrentlyCastSign() == ST_Yrden ) && !specialAttackCamera && !IsInCombatActionFriendly() )
		{
			buff = GetCurrentlyAnimatedCS();
			runningAndAlertNear = GetPlayerCombatStance() == PCS_AlertNear && playerMoveType == PMT_Run && !GetDisplayTarget();
			if ( runningAndAlertNear ||
				( GetPlayerCombatStance() == PCS_AlertFar && !IsInCombatAction() && !buff ) )
			{
				camOffset.X = 0.f;
				camOffset.Y = 0.f;
				camOffset.Z = -0.1f;
				
				if ( runningAndAlertNear )
				{
					moveData.pivotDistanceController.SetDesiredDistance( 4.f );
					moveData.pivotPositionController.offsetZ = 1.5f;
				}
			}
			else
			{
				camOffset.X = 0.f;
				camOffset.Y = -1.5f;
				camOffset.Z = -0.2f;
			}
				
			DampVectorSpring( moveData.cameraLocalSpaceOffset, moveData.cameraLocalSpaceOffsetVel, Vector( camOffset.X, camOffset.Y, camOffset.Z ), 0.4f, timeDelta );
			sprintOffset = moveData.cameraLocalSpaceOffset;
			heading = moveData.pivotRotationValue.Yaw;
			
			if ( GetOrientationTarget() == OT_Camera || GetOrientationTarget() == OT_CameraOffset )
				pitch = moveData.pivotRotationValue.Pitch;
			else if ( lastAxisInputIsMovement 
					|| GetBehaviorVariable( 'combatActionType' ) == (int)CAT_Attack 
					|| GetBehaviorVariable( 'combatActionType' ) == (int)CAT_SpecialAttack
					|| ( GetBehaviorVariable( 'combatActionType' ) == (int)CAT_CastSign && !IsCurrentSignChanneled() && GetCurrentlyCastSign() == ST_Quen ) )
			{
				theGame.GetGameCamera().ForceManualControlVerTimeout();	
				pitch = -20.f;
			}
			else
				pitch = moveData.pivotRotationValue.Pitch;
				
			headingMult = 1.f;
			pitchMult = 1.f;
		
			//if( GetBehaviorVariable( 'combatActionType' ) == (int)CAT_Attack )
			if( GetBehaviorVariable( 'combatActionType' ) == (int)CAT_CastSign 
				&& ( GetEquippedSign() == ST_Aard || GetEquippedSign() == ST_Yrden ) 
				&& GetBehaviorVariable( 'alternateSignCast' ) == 1 )
			{
				//theGame.GetGameCamera().ForceManualControlHorTimeout();
				theGame.GetGameCamera().ForceManualControlVerTimeout();			
				pitch = -20.f;
				
				//DampVectorSpring( moveData.cameraLocalSpaceOffset, moveData.cameraLocalSpaceOffsetVel, Vector( theGame.GetGameplayConfigFloatValue( 'debugA' ), theGame.GetGameplayConfigFloatValue( 'debugB' ), theGame.GetGameplayConfigFloatValue( 'debugC' ) ), 0.4f, timeDelta );
			}		
			
			//vel = GetMovingAgentComponent().GetVelocity();
			//if ( VecLength( vel ) > 0 && GetBehaviorVariable( 'combatActionType' ) == (int)CAT_Dodge )
			//{
				/*theGame.GetGameCamera().ForceManualControlHorTimeout();
				heading = GetHeading();
				headingMult = 0.5f;*/
			//}
			
			if ( IsCurrentSignChanneled() && GetCurrentlyCastSign() == ST_Quen )
			{
				pitch = moveData.pivotRotationValue.Pitch;
			}
			
			moveData.pivotRotationController.SetDesiredHeading( heading, );
			moveData.pivotRotationController.SetDesiredPitch( pitch );
		}
	}
	
	/*public function UpdateCameraForSpecialAttack( out moveData : SCameraMovementData, timeDelta : float ) : bool
	{
		return false;
	}*/
	//------------------------------------------------------------------------------------------------------------------
	event OnGameCameraExplorationRotCtrlChange()
	{
		if( substateManager )
		{
			return substateManager.OnGameCameraExplorationRotCtrlChange( );
		}
		
		return false;
	}
	
	///////////////////////////////////////////////////////////////////////////
	// COMBAT MOVEMENT ORIENTATION
	///////////////////////////////////////////////////////////////////////////	

	//Rotation
	function SetCustomRotation( customRotationName : name, rotHeading : float, rotSpeed : float, activeTime : float, rotateExistingDeltaLocation : bool )
	{
		var movementAdjustor	: CMovementAdjustor;
		var ticket 				: SMovementAdjustmentRequestTicket;
	
		movementAdjustor = GetMovingAgentComponent().GetMovementAdjustor();
		ticket = movementAdjustor.GetRequest( customRotationName );
		movementAdjustor.Cancel( ticket );
		ticket = movementAdjustor.CreateNewRequest( customRotationName );
		movementAdjustor.Continuous( ticket );
		movementAdjustor.ReplaceRotation( ticket );
		movementAdjustor.RotateTo( ticket, rotHeading );
		movementAdjustor.MaxRotationAdjustmentSpeed( ticket, rotSpeed );
		if (rotSpeed == 0.0f)
		{
			movementAdjustor.AdjustmentDuration( ticket, activeTime );	
		}
		movementAdjustor.KeepActiveFor( ticket, activeTime );	
		movementAdjustor.RotateExistingDeltaLocation( ticket, rotateExistingDeltaLocation );
	}
	
	function UpdateCustomRotationHeading( customRotationName : name, rotHeading : float )
	{
		var movementAdjustor	: CMovementAdjustor;
		var ticket 				: SMovementAdjustmentRequestTicket;
		
		movementAdjustor = GetMovingAgentComponent().GetMovementAdjustor();
		ticket = movementAdjustor.GetRequest( customRotationName );
		movementAdjustor.RotateTo( ticket, rotHeading );
	}
	
	function SetCustomRotationTowards( customRotationName : name, target : CActor, rotSpeed : float, optional activeTime : float )
	{
		var movementAdjustor	: CMovementAdjustor;
		var ticket 				: SMovementAdjustmentRequestTicket;
	
		movementAdjustor = GetMovingAgentComponent().GetMovementAdjustor();
		ticket = movementAdjustor.GetRequest( customRotationName );
		movementAdjustor.Cancel( ticket );
		ticket = movementAdjustor.CreateNewRequest( customRotationName );
		movementAdjustor.Continuous( ticket );
		movementAdjustor.ReplaceRotation( ticket );
		movementAdjustor.RotateTowards( ticket, target );
		movementAdjustor.MaxRotationAdjustmentSpeed( ticket, rotSpeed );
		if (activeTime > 0.0f)
		{
			movementAdjustor.KeepActiveFor( ticket, activeTime );
		}
		else
		{
			movementAdjustor.DontEnd( ticket );
		}
	}
	
	//lock movement in dir
	function CustomLockMovement( customMovementName : name, heading : float )
	{
		var movementAdjustor	: CMovementAdjustor;
		var ticket 				: SMovementAdjustmentRequestTicket;
	
		movementAdjustor = GetMovingAgentComponent().GetMovementAdjustor();
		ticket = movementAdjustor.GetRequest( customMovementName );
		movementAdjustor.Cancel( ticket );
		ticket = movementAdjustor.CreateNewRequest( customMovementName );
		movementAdjustor.Continuous( ticket );
		movementAdjustor.DontEnd( ticket );
		movementAdjustor.LockMovementInDirection( ticket, heading );
	}
	
	function BindMovementAdjustmentToEvent( customRotationName : name, eventName : CName )
	{
		var movementAdjustor	: CMovementAdjustor;
		var ticket 				: SMovementAdjustmentRequestTicket;
		
		movementAdjustor = GetMovingAgentComponent().GetMovementAdjustor();
		ticket = movementAdjustor.GetRequest( customRotationName );
		movementAdjustor.BindToEvent( ticket, eventName );
	}
	
	function UpdateCustomLockMovementHeading( customMovementName : name, heading : float )
	{
		var movementAdjustor	: CMovementAdjustor;
		var ticket 				: SMovementAdjustmentRequestTicket;
		
		movementAdjustor = GetMovingAgentComponent().GetMovementAdjustor();
		ticket = movementAdjustor.GetRequest( customMovementName );
		movementAdjustor.LockMovementInDirection( ticket, heading );
	}	
	
	function CustomLockDistance( customMovementName : name, maintainDistanceTo : CNode, minDist, maxDist : float )
	{
		var movementAdjustor	: CMovementAdjustor;
		var ticket 				: SMovementAdjustmentRequestTicket;
	
		movementAdjustor = GetMovingAgentComponent().GetMovementAdjustor();
		ticket = movementAdjustor.GetRequest( customMovementName );
		movementAdjustor.Cancel( ticket );
		ticket = movementAdjustor.CreateNewRequest( customMovementName );
		movementAdjustor.Continuous( ticket );	
		movementAdjustor.SlideTowards( ticket, maintainDistanceTo, minDist, maxDist );	
	}

	function UpdateCustomLockDistance( customMovementName : name, maintainDistanceTo : CNode, minDist, maxDist : float  )
	{
		var movementAdjustor	: CMovementAdjustor;
		var ticket 				: SMovementAdjustmentRequestTicket;
		
		movementAdjustor = GetMovingAgentComponent().GetMovementAdjustor();
		ticket = movementAdjustor.GetRequest( customMovementName );
		movementAdjustor.SlideTowards( ticket, maintainDistanceTo, minDist, maxDist );
	}		

	private var disableManualCameraControlStack : array<name>;
	public function EnableManualCameraControl( enable : bool, sourceName : name )
	{
		if ( !enable )
		{
			if ( !disableManualCameraControlStack.Contains( sourceName ) )
			{
				disableManualCameraControlStack.PushBack( sourceName );
			}
		}
		else
		{
			disableManualCameraControlStack.Remove( sourceName );
		}
		
		if ( disableManualCameraControlStack.Size() > 0 ) 
			theGame.GetGameCamera().EnableManualControl( false );
		else
			theGame.GetGameCamera().EnableManualControl( true );
	}

	public function IsCameraControlDisabled( optional disabledBySourceName : name ) : bool
	{
		if ( disabledBySourceName )
			return disableManualCameraControlStack.Contains( disabledBySourceName );
		else
			return disableManualCameraControlStack.Size() > 0;	
	}

	public function DisableManualCameraControlStackHasSource( sourceName : name ) : bool
	{
		return disableManualCameraControlStack.Contains( sourceName );
	}

	public function ClearDisableManualCameraControlStack()
	{
		disableManualCameraControlStack.Clear();
		theGame.GetGameCamera().EnableManualControl( true );
	}	
	
	function SetOrientationTarget( target : EOrientationTarget )
	{
		if ( IsPCModeEnabled() && target == OT_Player )
		{
			target = OT_Camera;
		}
	
		orientationTarget = target;
	}
	
	function GetOrientationTarget() : EOrientationTarget
	{
		return orientationTarget;
	}
	
	var customOrientationInfoStack : array<SCustomOrientationInfo>;
	public function AddCustomOrientationTarget( orientationTarget : EOrientationTarget, sourceName : name )
	{
		var customOrientationInfo  	: SCustomOrientationInfo;
		var i						: int;
		
		if ( customOrientationInfoStack.Size() > 0 )
		{
			for( i = customOrientationInfoStack.Size()-1; i>=0; i-=1 )
			{
				if ( customOrientationInfoStack[i].sourceName == sourceName )
					customOrientationInfoStack.Erase(i);	
			}
		}
		
		customOrientationInfo.sourceName = sourceName;
		customOrientationInfo.orientationTarget = orientationTarget;
		customOrientationInfoStack.PushBack( customOrientationInfo );
		SetOrientationTarget( orientationTarget );
	}	
	
	public function RemoveCustomOrientationTarget( sourceName : name )
	{
		var customOrientationInfo  	: SCustomOrientationInfo;
		var i						: int;
		
		if ( customOrientationInfoStack.Size() > 0 )
		{
			for( i = customOrientationInfoStack.Size()-1; i>=0; i-=1 )
			{
				if ( customOrientationInfoStack[i].sourceName == sourceName )
					customOrientationInfoStack.Erase(i);	
			}
		}
		else 
			LogChannel( 'CustomOrienatation', "ERROR: Custom orientation cannot be removed, stack is already empty!!!" );
	}

	protected function ClearCustomOrientationInfoStack()
	{
		customOrientationInfoStack.Clear();
	}

	protected function GetCustomOrientationTarget( out infoStack : SCustomOrientationInfo ) : bool 
	{
		var size : int;
		
		size = customOrientationInfoStack.Size();
		
		if ( size <= 0 )
			return false;
		else
		{
			infoStack = customOrientationInfoStack[ size - 1 ];
			return true;
		}
	}		
	
	public function SetOrientationTargetCustomHeading( heading : float, sourceName : name  ) : bool
	{	
		var  i : int;
		if ( customOrientationInfoStack.Size() > 0 )
		{
			for( i = customOrientationInfoStack.Size()-1; i>=0; i-=1 )
			{
				if ( customOrientationInfoStack[i].sourceName == sourceName )
				{
					customOrientationInfoStack[i].customHeading = heading;
					return true;
				}
			}
		}
	
		LogChannel( 'SetOrientationTargetCustomHeading', "ERROR: Cannot set customHeading because stack is empty or sourceName is not found!!!" );
		return false;
	}

	// returns the topmost OT_CustomHeading in stack
	public function GetOrientationTargetCustomHeading() : float
	{
		var i : int;
		if ( customOrientationInfoStack.Size() > 0 )
		{
			for( i = customOrientationInfoStack.Size()-1; i>=0; i-=1 )
			{
				if ( customOrientationInfoStack[i].orientationTarget == OT_CustomHeading )
				{
					return customOrientationInfoStack[i].customHeading;
				}
			}
		}

		LogChannel( 'SetOrientationTargetCustomHeading', "ERROR: Cannot get customHeading because stack is empty or no OT_CustomHeading in stack!!!" );
		return -1.f;
	}	

	public function	GetCombatActionOrientationTarget( combatActionType : ECombatActionType ) : EOrientationTarget
	{
		var newCustomOrientationTarget : EOrientationTarget;
		var targetEnt		: CGameplayEntity;
		var targetActor		: CActor;
	
		if ( GetCurrentStateName() == 'AimThrow' )
			newCustomOrientationTarget = OT_CameraOffset;
		else
		{
			targetEnt = GetDisplayTarget();
			targetActor = (CActor)targetEnt;		
		
			if ( targetEnt )
			{
				if ( targetActor )
				{
					if ( moveTarget )
						newCustomOrientationTarget = OT_Actor;
					else
					{	
						if ( this.IsSwimming() )
							newCustomOrientationTarget = OT_Camera;
						else if ( lastAxisInputIsMovement )
							newCustomOrientationTarget = OT_Player;
						else
							newCustomOrientationTarget = OT_Actor;
					}
				}
				else
				{
					if ( combatActionType == CAT_Crossbow && targetEnt.HasTag( 'softLock_Bolt' ) )
						newCustomOrientationTarget = OT_Actor;
					else
					{
						if ( this.IsSwimming() )
							newCustomOrientationTarget = OT_Camera;					
						else if ( lastAxisInputIsMovement )
							newCustomOrientationTarget = OT_Player;
						else
							newCustomOrientationTarget = OT_Camera;
						
					}
				}
			}
			else
			{
				if ( IsUsingVehicle() )// || this.IsSwimming() )
					newCustomOrientationTarget = OT_Camera;
				else if ( lastAxisInputIsMovement )
				{
					if ( this.IsSwimming() )
					{
						//if ( !bRAxisReleased
						//	|| ( GetOrientationTarget() == OT_Camera && ( this.rangedWeapon.GetCurrentStateName() == 'State_WeaponAim' || this.rangedWeapon.GetCurrentStateName() == 'State_WeaponShoot'  ) ) )
							newCustomOrientationTarget = OT_Camera;
						//else
						//	newCustomOrientationTarget = OT_CustomHeading;
					}
					else
						newCustomOrientationTarget = OT_Player;
					
				}
				else
					newCustomOrientationTarget = OT_Camera;
			}
		}
		
		return newCustomOrientationTarget;
	}

	public function	GetOrientationTargetHeading( orientationTarget : EOrientationTarget ) : float
	{	
		var heading : float;
	
		if( orientationTarget == OT_Camera )
			heading = VecHeading( theCamera.GetCameraDirection() );
		else if( orientationTarget == OT_CameraOffset )
			heading = VecHeading( theCamera.GetCameraDirection() ) - oTCameraOffset;	
		else if( orientationTarget == OT_CustomHeading )
			heading = GetOrientationTargetCustomHeading();
		else if ( GetDisplayTarget() && orientationTarget == OT_Actor )
		{
			if ( (CActor)( GetDisplayTarget() ) )
			{
				//if ( GetPlayerCombatStance() == PCS_AlertNear )
					heading = VecHeading( GetDisplayTarget().GetWorldPosition() - GetWorldPosition() );
				//else
				//	heading = GetHeading();
			}
			else
			{
				if ( GetDisplayTarget().HasTag( 'softLock_Bolt' ) )
					heading = VecHeading( GetDisplayTarget().GetWorldPosition() - GetWorldPosition() );
				else
					heading = GetHeading();
			}
		}
		else
			heading = GetHeading();
			
		return heading;		
	}
		
	event OnDelayOrientationChange()
	{
		var delayOrientation 	: bool;
		var delayCameraRotation	: bool;
		var moveData 			: SCameraMovementData;
		var time				: float;
		
		time = 0.01f;
	
		if ( theInput.GetActionValue( 'CastSignHold' ) == 1.f )
		{
			actionType = 0;
			if ( moveTarget )
				delayOrientation = true;
			else
			{
				if ( !GetBIsCombatActionAllowed() )
					delayOrientation = true;
			}
			

		}
		else if ( theInput.GetActionValue( 'ThrowItemHold' ) == 1.f )
		{
			actionType = 3;
			delayOrientation = true;		
		}
		else if ( theInput.GetActionValue( 'SpecialAttackHeavy' ) == 1.f )
		{
			actionType = 2;
			if ( !slideTarget )
				delayOrientation = true;
			else
				delayOrientation = true;
		}
		else if ( IsGuarded() && !moveTarget )
		{
			actionType = 1;
			delayOrientation = true;
		}
		
		if ( delayOrientation )
		{ 
			delayOrientationChange = true;
			theGame.GetGameCamera().ForceManualControlHorTimeout();
			theGame.GetGameCamera().ForceManualControlVerTimeout();
			AddTimer( 'DelayOrientationChangeTimer', time, true );
		}
		
		if ( delayCameraRotation )
		{
			delayCameraOrientationChange = true;
			theGame.GetGameCamera().ForceManualControlHorTimeout();
			theGame.GetGameCamera().ForceManualControlVerTimeout();
			AddTimer( 'DelayOrientationChangeTimer', time, true );			
		}
	}

	//This is also called from behgraph (e.g. SpecialHeavyAttack)
	event OnDelayOrientationChangeOff()
	{
		delayOrientationChange = false;
		delayCameraOrientationChange = false;
		RemoveTimer( 'DelayOrientationChangeTimer' );

		//if ( !IsCameraLockedToTarget() )
		//	theGame.GetGameCamera().EnableManualControl( true );
	}
	
	timer function DelayOrientationChangeTimer( time : float , id : int)
	{	
		if ( ( actionType == 0 && theInput.GetActionValue( 'CastSignHold' ) == 0.f ) 
			|| ( actionType == 2 && theInput.GetActionValue( 'SpecialAttackHeavy' ) == 0.f )
			|| ( actionType == 3 && theInput.GetActionValue( 'ThrowItemHold' ) == 0.f )
			|| ( actionType == 1 && !IsGuarded() )
			|| ( VecLength( rawRightJoyVec ) > 0.f ) )//&& !( slideTarget && IsInCombatAction() && GetBehaviorVariable( 'combatActionType') == (int)CAT_CastSign && GetCurrentlyCastSign() == ST_Axii ) ) )
		{
			OnDelayOrientationChangeOff();
		}
	}	
	
	public function SetCombatActionHeading( heading : float )
	{
		combatActionHeading = heading;
	}
	
	public function GetCombatActionHeading() : float
	{
		return combatActionHeading;
	}
	
	protected function EnableCloseCombatCharacterRadius( flag : bool )
	{
		var actor : CActor;
	
		actor = (CActor)slideTarget;
		if ( flag )
		{
			this.GetMovingAgentComponent().SetVirtualRadius( 'CloseCombatCharacterRadius' );
			if(actor)
				actor.GetMovingAgentComponent().SetVirtualRadius( 'CloseCombatCharacterRadius' );
		}
		else 
		{
			if  ( this.IsInCombat() )
			{
				GetMovingAgentComponent().SetVirtualRadius( 'CombatCharacterRadius' );				
				if(actor)
					actor.GetMovingAgentComponent().SetVirtualRadius( 'CombatCharacterRadius' );
			}
			else
			{
				this.GetMovingAgentComponent().ResetVirtualRadius();
				if(actor)
					actor.GetMovingAgentComponent().ResetVirtualRadius();			
			}
		}
	}		
	
	///////////////////////////////////////////////////////////////////////////
	// Soft Lock Logic
	

	
	private var isSnappedToNavMesh : bool;
	private var snapToNavMeshCachedFlag : bool;
	public function SnapToNavMesh( flag : bool )	
	{
		var comp 	: CMovingAgentComponent;

		comp = (CMovingAgentComponent)this.GetMovingAgentComponent();
	
		if ( comp )
		{
			comp.SnapToNavigableSpace( flag );
			isSnappedToNavMesh = flag;
		}
		else
		{
			snapToNavMeshCachedFlag = flag;
			AddTimer( 'DelayedSnapToNavMesh', 0.2f );
		}
	}
	
	public final function PlayRuneword4FX(optional weaponType : EPlayerWeapon)
	{
		var hasSwordDrawn : bool;
		var sword : SItemUniqueId;
		
		//we show fx only if overheal is greater than 1% - otherwise if we have a DoT and regen at the same time the health
		//jumps back and forth between 100% and 99.99% stating and stopping the fx over and over
		//needs to have sword drawn
		if(abilityManager.GetOverhealBonus() > (0.005 * GetStatMax(BCS_Vitality)))
		{
			hasSwordDrawn = HasAbility('Runeword 4 _Stats', true);
			
			if(!hasSwordDrawn && GetWitcherPlayer())			
			{
				if(weaponType == PW_Steel)
				{
					if(GetWitcherPlayer().GetItemEquippedOnSlot(EES_SteelSword, sword))
						hasSwordDrawn = inv.ItemHasAbility(sword, 'Runeword 4 _Stats');
				}
				else if(weaponType == PW_Silver)
				{
					if(GetWitcherPlayer().GetItemEquippedOnSlot(EES_SilverSword, sword))
						hasSwordDrawn = inv.ItemHasAbility(sword, 'Runeword 4 _Stats');
				}
			}
			
			if(hasSwordDrawn)
			{
				if(!IsEffectActive('runeword_4', true))
					PlayEffect('runeword_4');
			}
		}
	}
	
	timer function DelayedSnapToNavMesh( dt : float, id : int)
	{
		SnapToNavMesh( snapToNavMeshCachedFlag );
	}
	
	saved var navMeshSnapInfoStack : array<name>;
	public function EnableSnapToNavMesh( source : name, enable : bool )
	{
		if ( enable )
		{
			if ( !navMeshSnapInfoStack.Contains( source ) )
				navMeshSnapInfoStack.PushBack( source );
		}
		else
		{
			if ( navMeshSnapInfoStack.Contains( source ) )
				navMeshSnapInfoStack.Remove( source );	
		}
		
		if ( navMeshSnapInfoStack.Size() > 0 )
			SnapToNavMesh( true );
		else
			SnapToNavMesh( false );
	}	
	
	public function ForceRemoveAllNavMeshSnaps()
	{
		navMeshSnapInfoStack.Clear();
		SnapToNavMesh( false );
	}

	public function CanSprint( speed : float ) : bool
	{
		if( speed <= 0.8f )
		{
			return false;
		}
		
		if ( thePlayer.GetIsSprintToggled() )
		{
		}
		else if ( !sprintActionPressed )
		{
			return false;
		}
		else if( !theInput.IsActionPressed('Sprint') || ( theInput.LastUsedGamepad() && IsInsideInteraction() && GetHowLongSprintButtonWasPressed() < 0.12 ) )
		{
			return false;
		}
		
		if ( thePlayer.HasBuff( EET_OverEncumbered ) )
		{
			return false;
		}
		if ( !IsSwimming() )
		{
			if ( ShouldUseStaminaWhileSprinting() && !GetIsSprinting() && !IsInCombat() && GetStatPercents(BCS_Stamina) <= 0.9 )
			{
				return false;
			}
			if( ( !IsCombatMusicEnabled() || IsInFistFightMiniGame() ) && ( !IsActionAllowed(EIAB_RunAndSprint) || !IsActionAllowed(EIAB_Sprint) )  )
			{
				return false;
			}
			if( IsTerrainTooSteepToRunUp() )
			{
				return false;
			}
			if( IsInCombatAction() )
			{
				return false;
			}
			if( IsInAir() )
			{
				return false;
			}
		}
		if( theGame.IsFocusModeActive() )
		{
			return false;
		}
		
		return true;
	}
	
	
	public function SetTerrainPitch( pitch : float )
	{
		terrainPitch	= pitch;
	}
	
	public function IsTerrainTooSteepToRunUp() : bool
	{
		return terrainPitch <= disableSprintTerrainPitch;
	}
	
	public function SetTempLookAtTarget( actor : CGameplayEntity )
	{
		tempLookAtTarget = actor;
	}
	
	private var beingWarnedBy : array<CActor>;
	
	event OnBeingWarnedStart( sender : CActor )
	{
		if ( !beingWarnedBy.Contains(sender) )
			beingWarnedBy.PushBack(sender);
	}
	event OnBeingWarnedStop( sender : CActor )
	{
		beingWarnedBy.Remove(sender);
	}
	
	event OnCanFindPath( sender : CActor )
	{
		AddCanFindPathEnemyToList(sender,true);
	}
	event OnCannotFindPath( sender : CActor )
	{
		AddCanFindPathEnemyToList(sender,false);
	}
	event OnBecomeAwareAndCanAttack( sender : CActor )
	{
		AddEnemyToHostileEnemiesList( sender, true );
		OnApproachAttack( sender );		
	}
	event OnBecomeUnawareOrCannotAttack( sender : CActor )
	{
		AddEnemyToHostileEnemiesList( sender, false );
		OnApproachAttackEnd( sender );
		OnCannotFindPath(sender);
	}	
	event OnApproachAttack( sender : CActor )
	{
		AddEnemyToHostileEnemiesList( sender, true );
		super.OnApproachAttack( sender );
	}
	event OnApproachAttackEnd( sender : CActor )
	{
		AddEnemyToHostileEnemiesList( sender, false );
		super.OnApproachAttackEnd( sender );
	}
	event OnAttack( sender : CActor )
	{
		super.OnAttack( sender );
	}
	event OnAttackEnd( sender : CActor )
	{
		super.OnAttackEnd( sender );
	}

	event OnHitCeiling()
	{
		substateManager.ReactOnHitCeiling();
	}
	
	protected var hostileEnemies			: array<CActor>;		//all enemies that are actively engaged in combat with the player (may or may not be visible by Geralt)
	private var hostileMonsters 		: array<CActor>;		// subgroup from hostileEnemies containing only monsters for sound system
	function AddEnemyToHostileEnemiesList( actor : CActor, add : bool )
	{
		if ( add )
		{
			RemoveTimer( 'RemoveEnemyFromHostileEnemiesListTimer' );
			if ( !hostileEnemies.Contains( actor ) ) 
			{
				hostileEnemies.PushBack( actor );
				
				if( !actor.IsHuman() )
					hostileMonsters.PushBack( actor );
			}
		}
		else
		{
			if ( hostileEnemies.Size() == 1 )
			{
				if ( !actor.IsAlive() || actor.IsKnockedUnconscious() )
				{
					hostileEnemies.Remove( actor );
					if( !actor.IsHuman() )
						hostileMonsters.Remove( actor );
				}
				else
				{
					// If we already waiting to remove an entity
					if( hostileEnemyToRemove )
					{
						hostileEnemies.Remove( hostileEnemyToRemove );
						if( !hostileEnemyToRemove.IsHuman() )
							hostileMonsters.Remove( hostileEnemyToRemove );
					}
					hostileEnemyToRemove = actor;
					AddTimer( 'RemoveEnemyFromHostileEnemiesListTimer', 3.f );
				}
			}
			else 
			{
				hostileEnemies.Remove( actor );
				if( !actor.IsHuman() )
					hostileMonsters.Remove( actor );
			}
		}
	}
	
	 
	
	public function ShouldEnableCombatMusic() : bool
	{
		var moveTargetNPC	: CNewNPC;
	
		if ( thePlayer.GetPlayerMode().GetForceCombatMode() )
			return true;	
		else if ( !IsCombatMusicEnabled() )
		{
			if ( IsInCombat() )
				return true;
			else if ( IsThreatened() )
			{
				moveTargetNPC = (CNewNPC)moveTarget;
				if ( moveTargetNPC.IsRanged() && hostileEnemies.Contains( moveTargetNPC ) )
					return true;
				else
					return false;
			}
			else
				return false;
		}
		else if ( ( thePlayer.IsThreatened() && ( hostileEnemies.Size() > 0 || thePlayer.GetPlayerCombatStance() == PCS_AlertNear ) )
				|| IsInCombat() 
				|| finishableEnemiesList.Size() > 0 
				|| isInFinisher )
			return true;
		else
			return false;
		
	}
	
	public var canFindPathEnemiesList : array<CActor>;
	public var disablecanFindPathEnemiesListUpdate	: bool;
	private var lastCanFindPathEnemy	: CActor;
	private var cachedMoveTarget		: CActor;
	private var reachabilityTestId 	: int;
	private var reachabilityTestId2 : int;
	function AddCanFindPathEnemyToList( actor : CActor, add : bool )
	{
		if ( disablecanFindPathEnemiesListUpdate )
			return;
			
		if ( add && !canFindPathEnemiesList.Contains( actor ) )
		{
			canFindPathEnemiesList.PushBack(actor);
		}
		else if ( !add )
		{
			canFindPathEnemiesList.Remove(actor);
			
			if ( canFindPathEnemiesList.Size() <= 0 )
				playerMode.UpdateCombatMode();
		}
	}
	
	public function ClearCanFindPathEnemiesList( dt : float, id : int )
	{
		canFindPathEnemiesList.Clear();
	}	
	
	public var finishableEnemiesList : array<CActor>;
	function AddToFinishableEnemyList( actor : CActor, add : bool )
	{
		if ( add && !finishableEnemiesList.Contains( actor ) )
		{
			finishableEnemiesList.PushBack(actor);
		}
		else if ( !add )
		{
			finishableEnemiesList.Remove(actor);
		}
	}	
	
	private function UpdateFinishableEnemyList()
	{
		var i : int;
		i = 0;
		while ( i < finishableEnemiesList.Size() )
		{
			if ( !finishableEnemiesList[ i ] )
			{
				finishableEnemiesList.EraseFast( i );
			}
			else
			{
				i += 1;
			}
		}
	}
	
	private timer function ClearFinishableEnemyList( dt : float, id : int )
	{
		finishableEnemiesList.Clear();
	}	

	private var hostileEnemyToRemove : CActor;
	private timer function RemoveEnemyFromHostileEnemiesListTimer( time : float , id : int)
	{
		hostileEnemies.Remove( hostileEnemyToRemove );
		
		if( hostileEnemyToRemove.IsMonster() )
			hostileMonsters.Remove( hostileEnemyToRemove );
			
		hostileEnemyToRemove = NULL;
	}
	
	private function ClearHostileEnemiesList()
	{
		hostileEnemies.Clear();
		hostileMonsters.Clear();
		canFindPathEnemiesList.Clear();
	}

	private var moveTargets 					: array<CActor>;		//all hostileEnemies that Geralt is aware of.
	public function GetMoveTargets() 			: array<CActor>	{ return moveTargets; }
	public function GetNumberOfMoveTargets() 	: int	{ return moveTargets.Size(); }
	public function GetHostileEnemies()			: array<CActor>	{ return hostileEnemies; }
	public function GetHostileEnemiesCount()	: int	{ return hostileEnemies.Size(); }

	protected var enableStrafe 		: bool;
	
	
	public function FindMoveTarget()
	{
		var moveTargetDists				: array<float>;
		var moveTargetCanPathFinds		: array<bool>;
		var aPotentialMoveTargetCanFindPath		: bool;
		
		var newMoveTarget				: CActor;
		var actors 						: array<CActor>;
		var currentHeading				: float;
		var size, i						: int;
		var playerToNewMoveTargetDist	: float;
		var playerToMoveTargetDist		: float;
		var confirmEmptyMoveTarget		: bool;
		var newEmptyMoveTargetTimer		: float;
		var wasVisibleInFullFrame		: bool;
		var setIsThreatened				: bool;
		
		var enemysTarget				: CActor;
		var isEnemyInCombat				: bool;
		var potentialMoveTargets		: array<CActor>;
		var onlyThreatTargets			: bool;
		
		thePlayer.SetupEnemiesCollection( enemyCollectionDist, enemyCollectionDist, 10, 'None', FLAG_Attitude_Neutral + FLAG_Attitude_Hostile + FLAG_Attitude_Friendly + FLAG_OnlyAliveActors );
	
		//if ( moveTarget )
		//	cachedMoveTarget = moveTarget;
	
		if ( GetCurrentStateName() != 'PlayerDialogScene' && IsAlive() )//&& !IsInCombatAction() )//GetBIsCombatActionAllowed() )
		{
			GetVisibleEnemies( actors );

			//Include enemies that geralt cannot see, but is hostile to him
			if ( hostileEnemies.Size() > 0 )
			{
				for( i=0; i < hostileEnemies.Size() ; i+=1 )
				{
					if ( !actors.Contains( hostileEnemies[i] ) )
						actors.PushBack( hostileEnemies[i] );
				}
			}
			
			//Include enemies that are technically dead, but can be finished off
			if ( finishableEnemiesList.Size() > 0 )
			{
				for( i=0; i < finishableEnemiesList.Size() ; i+=1 )
				{
					if ( !actors.Contains( finishableEnemiesList[i] ) )
						actors.PushBack( finishableEnemiesList[i] );
				}
			}
			
			//Check the last moveTarget for situation where enemy targets an ally when you round a corner
			if ( moveTarget && !actors.Contains( moveTarget )  )
				actors.PushBack( moveTarget );			
			
			FilterActors( actors, onlyThreatTargets, false );
			
			//Determine whether Player should be threatened
			if ( actors.Size() > 0 )
			{
				setIsThreatened = false;
			
				if ( onlyThreatTargets )
				{
					setIsThreatened = true;
				}
				else
				{
					for( i=0; i < actors.Size() ; i+=1 )
					{
						if ( IsThreat( actors[i] ) )
						{
							setIsThreatened = true;
							break;
						}
						else
						{
							enemysTarget = actors[i].GetTarget();
							isEnemyInCombat = actors[i].IsInCombat();
							if ( isEnemyInCombat && enemysTarget && GetAttitudeBetween( enemysTarget, this ) == AIA_Friendly && enemysTarget.isPlayerFollower )
							{
								setIsThreatened = true;
								break;
							}							
						}
					}
				}
				
				//After filtering you will only have either all hostile or all neutral npcs
				for( i = actors.Size()-1; i>=0; i-=1 )
				{			
					if ( ( !actors[i].IsAlive() && !finishableEnemiesList.Contains( actors[i] ) )
						|| actors[i].IsKnockedUnconscious()
						|| this.GetUsedVehicle() == actors[i]
						|| !actors[i].CanBeTargeted() )
					{
						actors.EraseFast(i);
					}
					else if ( !IsThreatened() )
					{
						if ( !WasVisibleInScaledFrame( actors[i], 1.f, 1.f ) )
							actors.EraseFast(i);
					}
				}
			}
			else if ( moveTarget && IsThreat( moveTarget ) )
				setIsThreatened = true;
				//SetIsThreatened( true );
			else
				setIsThreatened = false;
				//SetIsThreatened( false );

			if ( setIsThreatened )
			{				
				enemyCollectionDist = 50.f;
				SetIsThreatened( true );
			}
			else
			{
				if ( IsThreatened() )
					AddTimer( 'finishableEnemiesList', 1.f );
				
				enemyCollectionDist = findMoveTargetDistMax;
				SetIsThreatened( false );
			}

			moveTargets = actors;
			potentialMoveTargets = moveTargets;
			
			//MS: By default Geralt will not play PCS_AlertNear unless there is one guy among the hostile npcs that canBeStrafed
			if ( !moveTarget ) 
				enableStrafe = false;
				
			if ( potentialMoveTargets.Size() > 0 )
			{
				for ( i = 0; i < potentialMoveTargets.Size(); i += 1 )
				{	
					if ( potentialMoveTargets[i].CanBeStrafed() )
						enableStrafe = true;
					
					if ( !potentialMoveTargets[i].GetGameplayVisibility() )
						moveTargetDists.PushBack( 100.f ); //Put invisible enemies as the last choice for moveTarget
					else
						moveTargetDists.PushBack( VecDistance( potentialMoveTargets[i].GetNearestPointInPersonalSpace( GetWorldPosition() ), GetWorldPosition() ) );

					if ( canFindPathEnemiesList.Contains( potentialMoveTargets[i] ) )
					{
						moveTargetCanPathFinds.PushBack( true );
						aPotentialMoveTargetCanFindPath = true;
					}
					else
					{
						moveTargetCanPathFinds.PushBack( false );
					}
				}					

				if ( aPotentialMoveTargetCanFindPath )
				{
					for ( i = moveTargetCanPathFinds.Size()-1 ; i >= 0; i-=1 )
					{
						if ( !moveTargetCanPathFinds[i] )
						{
							moveTargetCanPathFinds.EraseFast(i);
							potentialMoveTargets.EraseFast(i);
							moveTargetDists.EraseFast(i);
						}
					}
				}

				if ( moveTargetDists.Size() > 0 )
					newMoveTarget = potentialMoveTargets[ ArrayFindMinF( moveTargetDists ) ];
			}

			if ( newMoveTarget && newMoveTarget != moveTarget )
			{
				if ( moveTarget )
				{
					playerToNewMoveTargetDist =	VecDistance( newMoveTarget.GetNearestPointInPersonalSpace( GetWorldPosition() ), GetWorldPosition() );
					playerToMoveTargetDist = VecDistance( moveTarget.GetNearestPointInPersonalSpace( GetWorldPosition() ), GetWorldPosition() );
					wasVisibleInFullFrame = WasVisibleInScaledFrame( moveTarget, 1.f, 1.f ) ;
					
					if ( !IsThreat( moveTarget )
						|| !wasVisibleInFullFrame
						|| !IsEnemyVisible( moveTarget ) 
						|| ( !moveTarget.IsAlive() && !finishableEnemiesList.Contains( moveTarget ) )
						|| !moveTarget.GetGameplayVisibility()
						|| ( moveTarget.IsAlive() && moveTarget.IsKnockedUnconscious() ) 
						|| ( wasVisibleInFullFrame && IsEnemyVisible( moveTarget ) && playerToNewMoveTargetDist < playerToMoveTargetDist - 0.25f ) )
					{
						SetMoveTarget( newMoveTarget );
					}
				}
				else 
					SetMoveTarget( newMoveTarget );
			}


			if ( !IsThreatened() )
			{
				if ( moveTarget 
					&& ( ( !moveTarget.IsAlive() && !finishableEnemiesList.Contains( moveTarget ) ) || !WasVisibleInScaledFrame( moveTarget, 0.8f, 1.f ) || VecDistance( moveTarget.GetWorldPosition(), this.GetWorldPosition() ) > theGame.params.MAX_THROW_RANGE  )	)
				{
					confirmEmptyMoveTarget =  true;
					newEmptyMoveTargetTimer = 0.f;
				}
			}
			/*else if ( moveTarget 
				&& ( moveTarget.IsAlive() || finishableEnemiesList.Contains( moveTarget ) )
				//&& moveTarget.GetGameplayVisibility() 
				&& hostileEnemies.Contains( moveTarget ) )
			*/	
			else if ( moveTarget && ( IsThreat( moveTarget ) || finishableEnemiesList.Contains( moveTarget ) ) )				
			{
				if ( !IsEnemyVisible( moveTarget ) )
				{
					confirmEmptyMoveTarget =  true;
					newEmptyMoveTargetTimer = 5.f;
				}
				else
					SetMoveTarget( moveTarget );
			}
			else if ( IsInCombat() )
			{
				confirmEmptyMoveTarget =  true;
				newEmptyMoveTargetTimer = 1.0f;
			}
			
			if ( confirmEmptyMoveTarget )
			{
				if ( newEmptyMoveTargetTimer < emptyMoveTargetTimer )
				{
					bIsConfirmingEmptyTarget = false;
					emptyMoveTargetTimer = newEmptyMoveTargetTimer;
				}
					
				ConfirmEmptyMoveTarget( newEmptyMoveTargetTimer );
			}
		}
		else
			SetIsThreatened( false );
			
		//reactionsSystem
		if ( IsThreatened() && !IsInFistFightMiniGame() )
			theGame.GetBehTreeReactionManager().CreateReactionEventIfPossible( this, 'CombatNearbyAction', 5.0, 18.0f, -1.f, -1, true ); //reactionSystemSearch
		else
			theGame.GetBehTreeReactionManager().RemoveReactionEvent( this, 'CombatNearbyAction'); //reactionSystemSearch
			
		// sending nearby monsters count as parameter to sound system
		theSound.SoundParameter( "monster_count", hostileMonsters.Size() );
	}
	
	private function ConfirmEmptyMoveTarget( timeDelta : float )
	{
		if ( !bIsConfirmingEmptyTarget )
		{ 
			bIsConfirmingEmptyTarget = true;
			AddTimer( 'ConfirmEmptyTargetTimer', timeDelta );
		}
	}

	private timer function ConfirmEmptyTargetTimer( time : float , id : int)
	{		
		SetMoveTarget( NULL );	
	}
	

	var isInCombatReason				: int;
	var canFindPathToEnemy				: bool;
	var combatModeEnt 					: CEntity;	
	var navDist 						: float;
	var directDist 						: float;	
	var reachableEnemyWasTooFar			: bool;
	var reachableEnemyWasTooFarTimeStamp	: float;
	var reachablilityFailed				: bool;
	var reachablilityFailedTimeStamp	: float;	
	public function ShouldEnableCombat( out unableToPathFind : bool, forceCombatMode : bool ) : bool
	{
		var shouldFindPathToNPCs 	: bool;
		var playerToTargetDist	 	: float;
		var canFindPathToTarget		: bool;
		var moveTargetNPC 			: CNewNPC;
		var currentTime				: float;
		var currentTime2			: float;
		var isReachableEnemyTooFar	: bool;
		var reachableEnemyWasTooFarTimeStampDelta	: float;
		var reachablilityFailedTimeStampDelta		: float;
		var currentTimeTemp 		: float;
	
		/*if ( GetIsSprinting() ) 
		{
			unableToPathFind = true;
			isInCombatReason = 0; 
			return false;		
		}*/

		if ( forceCombatMode && isSnappedToNavMesh )
			return true;
	
		if ( !IsThreatened() )
		{
			reachableEnemyWasTooFar = false;
			reachablilityFailed = false;		
			isInCombatReason = 0; 
			return false;
		}
	
		if( thePlayer.substateManager.GetStateCur() != 'CombatExploration' && !thePlayer.substateManager.CanChangeToState( 'CombatExploration' )
		&& thePlayer.substateManager.GetStateCur() != 'Ragdoll' ) //&& !thePlayer.substateManager.CanChangeToState( 'Ragdoll' ) ) )
		{
			reachableEnemyWasTooFar = false;
			reachablilityFailed = false;		
			isInCombatReason = 0;
			return false;
		}

		if ( moveTarget )
		{
			canFindPathToEnemy = CanFindPathToTarget( unableToPathFind );
			currentTimeTemp = EngineTimeToFloat( theGame.GetEngineTime() );
			
			if ( canFindPathToEnemy )
				isReachableEnemyTooFar = IsReachableEnemyTooFar();					
			
			if ( IsInCombat() )
			{
				if ( canFindPathToEnemy )
				{
					if ( forceCombatMode )
						return true;
				
					reachablilityFailed = false;
					reachablilityFailedTimeStamp = currentTimeTemp;						
				
					if ( reachableEnemyWasTooFar )
					{												
						if ( isReachableEnemyTooFar )
						{
							currentTime = currentTimeTemp;
							
							if ( GetIsSprinting() )
								reachableEnemyWasTooFarTimeStampDelta = 0.f;
							else
								reachableEnemyWasTooFarTimeStampDelta = 3.f;
								
							if ( currentTime > reachableEnemyWasTooFarTimeStamp + reachableEnemyWasTooFarTimeStampDelta )
							{							
								isInCombatReason = 0;
								unableToPathFind = true;
								return false;
							}
						}
						else
							reachableEnemyWasTooFar = false;
					}
					else
					{
						if ( isReachableEnemyTooFar )
						{
							reachableEnemyWasTooFar = true;
							reachableEnemyWasTooFarTimeStamp = currentTimeTemp;
						}
						else
							reachableEnemyWasTooFar = false;
					}	
			
					return true;
				}
				else
				{
					reachableEnemyWasTooFar = false;
					reachableEnemyWasTooFarTimeStamp = currentTimeTemp;
				
					if ( reachablilityFailed )
					{
						if ( IsEnemyTooHighToReach() )
							reachablilityFailedTimeStampDelta = 1.f;
						else
							reachablilityFailedTimeStampDelta = 5.f;
					
						currentTime2 = currentTimeTemp;
						if ( currentTime2 > reachablilityFailedTimeStamp + reachablilityFailedTimeStampDelta )
						{
							unableToPathFind = true;
							return false;
						}
					}
					else
					{
						reachablilityFailed = true;
						reachablilityFailedTimeStamp = currentTimeTemp;
					}
					
					return true;
				}
			}
			else if ( canFindPathToEnemy )
			{
				if ( forceCombatMode )
				{
					reachableEnemyWasTooFar = false;
					return true;
				}
			
				reachablilityFailed = false;
				reachablilityFailedTimeStamp = currentTimeTemp;
				
				moveTargetNPC = (CNewNPC)moveTarget;
				playerToTargetDist = VecDistance( moveTarget.GetWorldPosition(), this.GetWorldPosition() );

				/*if ( !theGame.GetWorld().NavigationLineTest( this.GetWorldPosition(), moveTarget.GetWorldPosition(), 0.4f ) )
				{
					isInCombatReason = 0;
					return false;					
				}
				else*/ if ( reachableEnemyWasTooFar 
					&& ( isReachableEnemyTooFar || !theGame.GetWorld().NavigationLineTest( this.GetWorldPosition(), moveTarget.GetWorldPosition(), 0.4f ) ) )
				{
					isInCombatReason = 0;
					return false;			
				}
				else if ( playerToTargetDist <= findMoveTargetDistMin )
					isInCombatReason = 1;
				else if ( ( moveTargetNPC.GetCurrentStance() == NS_Fly || moveTargetNPC.IsRanged() ) && hostileEnemies.Contains( moveTarget ) ) 
					isInCombatReason = 2;
				else
				{			 
					isInCombatReason = 0;
					return false;
				}
				
				reachableEnemyWasTooFar = false;
				return true;
			}						
		}
		else
		{
			reachableEnemyWasTooFar = false;
			reachablilityFailed = false;
		}
		
		isInCombatReason = 0;
		return false;
	}
	
	private function CanFindPathToTarget( out unableToPathFind : bool, optional forcedTarget : CNewNPC ) : bool
	{
		var moveTargetNPC : CNewNPC;
		var moveTargetsTemp	: array<CActor>;
		var i : int;
		var safeSpotTolerance : float;
		var ent : CEntity;

		moveTargetsTemp = moveTargets;
	
		for ( i = 0; i < moveTargetsTemp.Size(); i += 1 )
		{
			moveTargetNPC = (CNewNPC)moveTargetsTemp[i];
		
			if ( moveTargetNPC && moveTargetNPC.GetCurrentStance() == NS_Fly )
			{
				isInCombatReason = 2; 
				return true;
			}
		}
	
		switch ( navQuery.GetLastOutput( 0.4 ) )
		{
			case EAsyncTastResult_Failure:
			{
				isInCombatReason = 0; 
				return false;
			}
			case EAsyncTastResult_Success:
			{
				ent = navQuery.GetOutputClosestEntity();
				
				if ( ent )
					combatModeEnt = moveTarget;
					
				navDist = navQuery.GetOutputClosestDistance();
				
				isInCombatReason = 1; 
				return true;
			}
			case EAsyncTastResult_Pending:
			{
				return canFindPathToEnemy;
			}
			case EAsyncTastResult_Invalidated:
			{
				if ( IsInCombat() )
				{
					if ( IsEnemyTooHighToReach() ) 
						safeSpotTolerance = 0.f;
					else
						safeSpotTolerance = 3.f;
				}
				else
					safeSpotTolerance = 0.f;
			
				switch( navQuery.TestActorsList( ENavigationReachability_Any, this, moveTargetsTemp, safeSpotTolerance, 75.0 ) )
				{
					case EAsyncTastResult_Failure:
					{
						isInCombatReason = 0;
						return false;
					}
					case EAsyncTastResult_Success:
					{
						ent = navQuery.GetOutputClosestEntity();
						
						if ( ent )
							combatModeEnt = moveTarget;
							
						navDist = navQuery.GetOutputClosestDistance();					
					
						isInCombatReason = 1; 
						return true;
					}
					case EAsyncTastResult_Pending:
					{
						return canFindPathToEnemy;
					}	
					case EAsyncTastResult_Invalidated:
					{
						if ( IsInCombat() )
							return true;
						else
							return false;
					}	
				}
			}
		}	
	}
	
	private function IsReachableEnemyTooFar() : bool
	{
		//var navDistFailMax			: float = 100.f;
		var navDistLimit			: float = findMoveTargetDist; //25.f;
		var navDistDivisor			: float = 2.f;
		var playerToTargetVector	: Vector;	
	
		directDist = VecDistance( combatModeEnt.GetWorldPosition(), thePlayer.GetWorldPosition() );	
		playerToTargetVector = this.GetWorldPosition() - combatModeEnt.GetWorldPosition();
		
		if ( playerMode.GetForceCombatMode() || isInCombatReason == 2 )
			return false;
		
		if ( ( playerToTargetVector.Z < 0.5 && navDist > navDistLimit && directDist < navDist/navDistDivisor ) )
			return true;
		else
			return false;
	}
	
	private function IsEnemyTooHighToReach() : bool
	{	
		var playerToTargetVector	: Vector;		
	
		playerToTargetVector = this.GetWorldPosition() - combatModeEnt.GetWorldPosition();
	
		if ( playerToTargetVector.Z < -0.5f && !theGame.GetWorld().NavigationLineTest( this.GetWorldPosition(), combatModeEnt.GetWorldPosition(), 0.4f ) )
			return true;
		else
			return false;
	}
	
	//Force Geralt to face an enemy for a moment before changing to another enemy
	public function LockToMoveTarget( lockTime : float )
	{
		/*if ( IsMoveTargetChangeAllowed() )
		{
			bMoveTargetChangeAllowed = false;
			AddTimer( 'DisableLockToMoveTargetTimer', lockTime );
		}*/
	}
	
	private timer function DisableLockToMoveTargetTimer( time : float , id : int)
	{
		if ( !this.IsActorLockedToTarget() )
		{
			SetMoveTargetChangeAllowed( true );
		}
	}
	
	public function SetMoveTargetChangeAllowed( flag : bool )
	{
		//bMoveTargetChangeAllowed = flag;
	}
	
	public function IsMoveTargetChangeAllowed() : bool
	{
		return bMoveTargetChangeAllowed;
	}
	
	public function SetMoveTarget( actor : CActor )
	{		
		if ( !actor && ForceCombatModeOverride() )
			return;
	
		if ( IsMoveTargetChangeAllowed()
			&& moveTarget != actor )
		{
			moveTarget = actor;
			bIsConfirmingEmptyTarget = false;
			RemoveTimer( 'ConfirmEmptyTargetTimer' );
			
			if ( !moveTarget )
				SetScriptMoveTarget( moveTarget );
		}
	}
	
	private var isThreatened	: bool;	
	protected function SetIsThreatened( flag : bool ) 	
	{ 	
		var allowSetIsThreatened : bool;
		
		allowSetIsThreatened = true;
		if ( ForceCombatModeOverride() )
		{
			if ( flag || !moveTarget )
				allowSetIsThreatened = true;
			else
				allowSetIsThreatened = false;
		}
	
		if ( allowSetIsThreatened )
		{
			isThreatened = flag;
		}
	}
	
	public function ForceCombatModeOverride() : bool
	{
		if(	this.GetPlayerMode().GetForceCombatMode() 
			&& canFindPathToEnemy 
			&& theGame.GetGlobalAttitude( GetBaseAttitudeGroup(), moveTarget.GetBaseAttitudeGroup() ) == AIA_Hostile )
			return true;
		else
			return false;
	}
	
	public function IsThreatened() : bool	{ return isThreatened; }
		
	public function EnableFindTarget( flag : bool )
	{
		var target : CActor;
		
		if( IsActorLockedToTarget() )
		{
			target = GetTarget();
			
			if ( target && target.IsAlive() )
				bCanFindTarget = flag;
			else
				bCanFindTarget = true;
		}
		else
			bCanFindTarget = flag;
	}
	
	public function UpdateDisplayTarget( optional forceUpdate : bool, optional forceNullActor : bool )
	{
		var hud 					: CR4ScriptedHud;
		var tempTarget				: CGameplayEntity;
		var angleDist1				: float;
		var angleDist2				: float;
		var nonActorTargetMult		: float;
		var combatActionType 		: int;
		var currTarget				: CActor;
		var interactionTarget		: CInteractionComponent;
		
		var heading					: float;

		if(theGame.IsDialogOrCutscenePlaying())
		{
			currentSelectedDisplayTarget = NULL;
			
			if ( displayTarget )
				ConfirmDisplayTarget( NULL );
			
			return;
		}
		
		if ( forceNullActor )
			currTarget = NULL;
		else
			currTarget = GetTarget();
			
		currentSelectedDisplayTarget = currTarget;
		
		if ( currTarget && !currTarget.IsTargetableByPlayer() )
		{
			currentSelectedDisplayTarget = NULL;
			ConfirmDisplayTarget( currentSelectedDisplayTarget );
			return;
		}
		//Setting multiplier that increases non actor target priority
		nonActorTargetMult = 1.25;
		
		//Update the interaction icon
		hud = (CR4ScriptedHud)theGame.GetHud();	
		
		if ( !IsThreatened() )
		{
			if ( !bLAxisReleased || lastAxisInputIsMovement  )
			{
				if ( currTarget )
					angleDist1 = AbsF( AngleDistance( this.GetHeading(), VecHeading( currTarget.GetWorldPosition() - this.GetWorldPosition() ) ) );
				else
					angleDist1 = 360;
				
				if ( nonActorTarget )
					angleDist2 = AbsF( AngleDistance( this.GetHeading(), VecHeading( nonActorTarget.GetWorldPosition() - this.GetWorldPosition() ) ) );
				else
					angleDist2 = 360;			
			}
			else
			{
				if ( currTarget )
					angleDist1 = AbsF( AngleDistance( theCamera.GetCameraHeading(), VecHeading( currTarget.GetWorldPosition() - theCamera.GetCameraPosition() ) ) );
				else
					angleDist1 = 360;
				
				if ( nonActorTarget )
					angleDist2 = AbsF( AngleDistance( theCamera.GetCameraHeading(), VecHeading( nonActorTarget.GetWorldPosition() - theCamera.GetCameraPosition() ) ) );
				else
					angleDist2 = 360;
			}
		}

		else
		{		
			if ( !bLAxisReleased ) 
			{
				if ( ShouldUsePCModeTargeting() )
				{
					if ( currTarget )
						angleDist1 = AbsF( AngleDistance( theCamera.GetCameraHeading(), VecHeading( currTarget.GetWorldPosition() - theCamera.GetCameraPosition() ) ) );
					else
						angleDist1 = 360;
					
					if ( nonActorTarget && IsInCombatAction() )
					{
						angleDist2 = nonActorTargetMult * AbsF( AngleDistance( theCamera.GetCameraHeading(), VecHeading( nonActorTarget.GetWorldPosition() - theCamera.GetCameraPosition() ) ) );
					}
					else
						angleDist2 = 360;				
				}
				else
				{
					if ( currTarget )
						angleDist1 = AbsF( AngleDistance( rawPlayerHeading, VecHeading( currTarget.GetWorldPosition() - this.GetWorldPosition() ) ) );
					else
						angleDist1 = 360;
					
					if ( nonActorTarget && IsInCombatAction() )
					{
						angleDist2 = nonActorTargetMult * AbsF( AngleDistance( rawPlayerHeading, VecHeading( nonActorTarget.GetWorldPosition() - this.GetWorldPosition() ) ) );
					}
					else
						angleDist2 = 360;
				}
			}
			else
			{
				angleDist1 = 0;
				angleDist2 = 360;
			}
		}
		
		
		if ( angleDist1 < angleDist2 )
			tempTarget = currTarget;
		else
			tempTarget = nonActorTarget;
			
			
		if ( slideTarget && IsInCombatAction() )
		{
			combatActionType = (int)this.GetBehaviorVariable( 'combatActionType' );
			if (  	combatActionType == (int)CAT_Attack			
					|| ( combatActionType == (int)CAT_SpecialAttack && this.GetBehaviorVariable( 'playerAttackType' ) == 1.f )
					|| ( combatActionType == (int)CAT_ItemThrow )
					|| ( combatActionType == (int)CAT_CastSign && !IsCurrentSignChanneled() ) 
					|| ( combatActionType == (int)CAT_CastSign && IsCurrentSignChanneled() && GetCurrentlyCastSign() == ST_Axii )
					|| ( combatActionType == (int)CAT_CastSign && IsCurrentSignChanneled() && GetCurrentlyCastSign() == ST_Igni )
					|| combatActionType == (int)CAT_Dodge
					|| combatActionType == (int)CAT_Roll )
			{
				if ( combatActionType == (int)CAT_CastSign && GetCurrentlyCastSign() == ST_Igni && !IsCombatMusicEnabled() )
					currentSelectedDisplayTarget = tempTarget;	
				else
					currentSelectedDisplayTarget = slideTarget;
			}
			else
				currentSelectedDisplayTarget = tempTarget;	
		}
		else if ( slideTarget 
			&& this.rangedWeapon 
			&& this.rangedWeapon.GetCurrentStateName() != 'State_WeaponWait'
			&& this.playerAiming.GetCurrentStateName() == 'Waiting' ) //( this.rangedWeapon.GetCurrentStateName() == 'State_WeaponShoot' || this.rangedWeapon.GetCurrentStateName() == 'State_WeaponAim' ) )
				currentSelectedDisplayTarget = slideTarget;
		else 
			currentSelectedDisplayTarget = tempTarget;	
		
		interactionTarget = theGame.GetInteractionsManager().GetActiveInteraction();
		if  ( interactionTarget && !IsThreatened() && !( this.IsCastingSign() && this.IsCurrentSignChanneled() ) )
		{
			tempTarget = (CGameplayEntity)interactionTarget.GetEntity();
			if ( tempTarget && tempTarget !=  this.GetUsedVehicle() )
			{
				currentSelectedDisplayTarget = tempTarget;
				SetDisplayTarget( currentSelectedDisplayTarget );
			}
		}
		
		// disabling display for invisible targets
		if ( (CActor)currentSelectedDisplayTarget && !((CActor)currentSelectedDisplayTarget).GetGameplayVisibility() )
		{
			currentSelectedDisplayTarget = NULL;
		}
		
		if ( displayTarget != currentSelectedDisplayTarget )
		{
			if ( forceUpdate )
				SetDisplayTarget( currentSelectedDisplayTarget );
			else
				ConfirmDisplayTarget( currentSelectedDisplayTarget );
		}
	}
	
	private var bConfirmDisplayTargetTimerEnabled 	: bool;
	private var displayTargetToConfirm 				: CGameplayEntity;
	private var currentSelectedDisplayTarget 		: CGameplayEntity;
	
	private function ConfirmDisplayTarget( targetToConfirm : CGameplayEntity )
	{	
		if ( targetToConfirm != displayTarget )
		{
			displayTargetToConfirm = targetToConfirm;
			if( !bConfirmDisplayTargetTimerEnabled )
			{
				bConfirmDisplayTargetTimerEnabled = true;
				
				if ( targetToConfirm )
					AddTimer( 'ConfirmDisplayTargetTimer', 0.1f );
				else
					AddTimer( 'ConfirmDisplayTargetTimer', 0.f );
			}
		}
	}
	
	private timer function ConfirmDisplayTargetTimer( time : float, optional id : int)
	{
		if ( displayTargetToConfirm == currentSelectedDisplayTarget )
			SetDisplayTarget( displayTargetToConfirm );

		bConfirmDisplayTargetTimerEnabled = false;
	}	
	
	
	protected function SetDisplayTarget( e : CGameplayEntity )
	{ 
		var displayTargetActor : CActor;
		
		if ( e != displayTarget )
		{
			displayTarget = e;
			displayTargetActor = (CActor)displayTarget;
			SetPlayerCombatTarget( displayTargetActor );
			
			if ( displayTargetActor && !displayTargetActor.IsTargetableByPlayer())
			{
				isDisplayTargetTargetable = false;
			}
			else if ( !displayTargetActor && displayTarget != nonActorTarget ) 
			{
				isDisplayTargetTargetable = false;
			}
			else 
			{
				isDisplayTargetTargetable = true;
			}
		}
	}

	public function GetDisplayTarget() : CGameplayEntity		{ return displayTarget; }
	
	private var isDisplayTargetTargetable : bool;
	public function IsDisplayTargetTargetable() : bool
	{
		return isDisplayTargetTargetable;
	}
	
	public 	var radialSlots					: array<name>;	
	public function EnableRadialSlots( enable : bool, slotNames : array<name> )
	{
		var hud : CR4ScriptedHud;
		var module : CR4HudModuleRadialMenu;
		var i : int;

		hud = (CR4ScriptedHud)theGame.GetHud();
		module = (CR4HudModuleRadialMenu)hud.GetHudModule("RadialMenuModule");

		for(i=0; i<slotNames.Size(); i+=1)
		{
			module.SetDesaturated( !enable, slotNames[i] );
		}
	}
	
	public function IsEnemyInCone( source : CActor, coneHeading : Vector, coneDist, coneAngle : float, out newLockTarget : CActor ) : bool
	{
		var targets 			: array<CActor>;
		var sourceToTargetDists	: array<float>;	
		var i					: int;
		var targetingInfo		: STargetingInfo;
		
		//GetVisibleEnemies( targets );
		//targets = FilterActors( targets );
		targets = GetMoveTargets();
	
		if ( targets.Size() > 0 )
		{
			targetingInfo.source 				= this;
			targetingInfo.canBeTargetedCheck	= true;
			targetingInfo.coneCheck 			= true;
			targetingInfo.coneHalfAngleCos		= CosF( Deg2Rad( coneAngle * 0.5f ) );
			targetingInfo.coneDist				= coneDist;
			targetingInfo.coneHeadingVector		= coneHeading;
			targetingInfo.distCheck				= true;
			targetingInfo.invisibleCheck		= true;
			targetingInfo.navMeshCheck			= true; 
			targetingInfo.inFrameCheck 			= false; 
			targetingInfo.frameScaleX 			= 1.f; 
			targetingInfo.frameScaleY 			= 1.f; 
			targetingInfo.knockDownCheck 		= false; 
			targetingInfo.knockDownCheckDist 	= 1.5f; 
			targetingInfo.rsHeadingCheck 		= false;
			targetingInfo.rsHeadingLimitCos 	= 1.0f;
			
			for( i = targets.Size() - 1; i >= 0; i -= 1 )
			{
				targetingInfo.targetEntity 		= targets[i];
				if ( !IsEntityTargetable( targetingInfo ) )
					targets.Erase( i );
			}

			for (  i = 0; i < targets.Size(); i += 1 )
				sourceToTargetDists.PushBack( VecDistance( source.GetWorldPosition(), targets[i].GetWorldPosition() ) );
			
			if(sourceToTargetDists.Size() > 0)
				newLockTarget = targets[ ArrayFindMinF( sourceToTargetDists ) ];
			else
				newLockTarget = NULL;
		}
		
		return targets.Size() > 0;
	}	
	
	public function GetScreenSpaceLockTarget( sourceEnt : CGameplayEntity, coneAngle, coneDist, coneHeading : float, optional inFrameCheck : bool ) : CActor
	{
		var source					: CActor;
		var sourcePos, targetPos	: Vector;
		var targets 				: array<CActor>;
		var sourceToTargetDists		: array<float>;
		var sourceCoord				: Vector;
		var targetCoord				: Vector;
		var i 						: int;
		var angleDiff				: float;
		var sourceToTargetHeading	: float;
		var sourceToTargetDist		: float;
		var size 					: float;
		var targetingDist			: float;
		var targetingInfo			: STargetingInfo;
		
		var temp : int;
		
		// MAREK TODO :  Need to use cached values of screenspace coords instead of calculating again
		//GetVisibleEnemies( targets );
		//targets = FilterActors( targets );
		source = (CActor)sourceEnt;
		
		targets = GetMoveTargets();
		
		if ( this.IsPCModeEnabled() )
		{
			if ( ( coneHeading > -45.f && coneHeading < 45.f )
				|| coneHeading > 135.f 
				|| coneHeading < -135.f )
			{
				if ( coneHeading > 0 )
					coneHeading = 180 - coneHeading;
				else
					coneHeading = 180 + coneHeading;
			}
		}		
		
		/*if ( IsCombatMusicEnabled() || hostileEnemies.Size() > 0  )
		{
			if ( targets[0] && !IsThreat( targets[0] ) )
				targets.Clear();
		}*/	
		
		for( i = targets.Size() - 1; i >= 0; i -= 1 )
		{
			if ( ( !targets[i].GetGameplayVisibility() || !IsThreat( targets[i] ) || !IsEnemyVisible( targets[i] ) || !this.CanBeTargetedIfSwimming( targets[i] ) ) 
				&& ( !IsCastingSign() || GetCurrentlyCastSign() != ST_Axii ) )
				targets.Erase(i);
		}
		
		if ( source )
		{
			temp = source.GetTorsoBoneIndex();
			
			if ( temp < 0 )
				sourcePos = source.GetWorldPosition();
			else
				sourcePos = MatrixGetTranslation( source.GetBoneWorldMatrixByIndex( source.GetTorsoBoneIndex() ) );		
		}
		else
			sourcePos = sourceEnt.GetWorldPosition();
			
		theCamera.WorldVectorToViewRatio( sourcePos, sourceCoord.X , sourceCoord.Y ); 
		
		/*if ( !IsUsingVehicle() )
			targetingDist = softLockDist;			
		else*/
			targetingDist = softLockDistVehicle;
		
		if ( targets.Size() > 0 )
		{
			targetingInfo.source 				= this;
			targetingInfo.canBeTargetedCheck	= true;
			targetingInfo.coneCheck 			= false;
			targetingInfo.coneHalfAngleCos		= 0.86602540378f; // = CosF( Deg2Rad( 60.0f * 0.5f ) )
			targetingInfo.coneDist				= targetingDist;
			targetingInfo.coneHeadingVector		= Vector( 0.0f, 1.0f, 0.0f ); 
			targetingInfo.distCheck				= true;
			targetingInfo.invisibleCheck		= true;
			targetingInfo.navMeshCheck			= false; 
			
			if ( inFrameCheck )
				targetingInfo.inFrameCheck 		= true;
			else
				targetingInfo.inFrameCheck 		= false;
				
			targetingInfo.frameScaleX 			= 1.f; 
			targetingInfo.frameScaleY 			= 1.f; 
			targetingInfo.knockDownCheck 		= false; 
			targetingInfo.knockDownCheckDist 	= softLockDist;
			if ( bRAxisReleased )
				targetingInfo.rsHeadingCheck	= false;
			else
				targetingInfo.rsHeadingCheck	= true;
			targetingInfo.rsHeadingLimitCos		= -0.5f; // = CosF( Deg2Rad( 120.0f ) );		
		
			for( i = targets.Size() - 1; i >= 0; i -= 1 )
			{
				temp = targets[i].GetTorsoBoneIndex();
				
				if ( temp < 0 )
					targetPos = targets[i].GetWorldPosition();
				else
					targetPos = MatrixGetTranslation( targets[i].GetBoneWorldMatrixByIndex( targets[i].GetTorsoBoneIndex() ) );
					
				theCamera.WorldVectorToViewRatio( targetPos, targetCoord.X, targetCoord.Y );
				sourceToTargetHeading = VecHeading( targetCoord - sourceCoord );
				angleDiff = AbsF( AngleDistance( coneHeading, sourceToTargetHeading ) );
				
				targetingInfo.targetEntity 			= targets[i];
				if ( !IsEntityTargetable( targetingInfo ) )
					targets.Erase( i );
				else if ( !bRAxisReleased && angleDiff > ( coneAngle * 0.5 ) ) 
					targets.Erase( i );
				else if ( targets[i] == sourceEnt )
					targets.Erase( i );	
			
				/*if ( GetDisplayTarget() && IsInCombatAction() && GetBehaviorVariable( 'combatActionType') == (int)CAT_CastSign && GetCurrentlyCastSign() == ST_Igni )
				{

				}
				else
				{
					targetingInfo.rsHeadingCheck 		= false;
					if ( !IsEntityTargetable( targetingInfo ) 
						|| angleDiff > ( coneAngle * 0.5 )
						|| targets[i] == sourceEnt )
						targets.Erase( i );			
				}*/
			}
		}
		
		size = targets.Size();
		if ( size > 0 )
		{
			for (  i = 0; i < targets.Size(); i += 1 )
			{
				temp = targets[i].GetTorsoBoneIndex();
				
				if ( temp < 0 )
					targetPos = targets[i].GetWorldPosition();
				else
					targetPos = MatrixGetTranslation( targets[i].GetBoneWorldMatrixByIndex( targets[i].GetTorsoBoneIndex() ) );
	
				theCamera.WorldVectorToViewRatio( targetPos, targetCoord.X, targetCoord.Y );
				sourceToTargetHeading = AbsF( VecHeading( targetCoord - sourceCoord ) );
				angleDiff = AngleDistance( 180, sourceToTargetHeading );
				sourceToTargetDist = VecDistance2D( sourceCoord, targetCoord );
				
				sourceToTargetDists.PushBack( SinF( Deg2Rad( angleDiff ) ) * sourceToTargetDist );
			}			
		}
		
		if ( targets.Size() > 0 )//GetDisplayTarget() )
			return targets[ ArrayFindMinF( sourceToTargetDists ) ];
		else
			return NULL;
	}

	public function IsEntityTargetable( out info : STargetingInfo, optional usePrecalcs : bool ) : bool
	{
		var playerHasBlockingBuffs	: bool;
		var sourceActor				: CActor;
		var targetEntity			: CEntity;
		var targetActor				: CActor;
		var targetNPC				: CNewNPC;
		var sourcePosition			: Vector;
		var targetPosition			: Vector;
		var direction				: Vector;
		var sourceToTargetDist		: float;
		var sourceCapsuleRadius 	: float;
		var mpac					: CMovingPhysicalAgentComponent;
		
		var coneDistSq  			: float;
		var knockDownCheckDistSq	: float;
		var sourceToTargetAngleDist	: float;
		var b						: bool;
		var infoSourceWorldPos		: Vector;
		var infoTargetWorldPos		: Vector;
		var finishEnabled			: bool;
	
		if ( usePrecalcs )
		{
			playerHasBlockingBuffs = targetingIn.playerHasBlockingBuffs;
		}
		else
		{
			playerHasBlockingBuffs = thePlayer.HasBuff( EET_Confusion ) || thePlayer.HasBuff( EET_Hypnotized ) || thePlayer.HasBuff( EET_Blindness ) || thePlayer.HasBuff( EET_WraithBlindness );
		}		
		if ( playerHasBlockingBuffs )
		{
			return false;
		}
	
		sourceActor = info.source;
		targetEntity = info.targetEntity;
		if ( !sourceActor || !targetEntity )
		{
			return false;
		}
		
		targetActor = (CActor)targetEntity;

		// "can be targeted" check
		if ( info.canBeTargetedCheck && !targetActor.CanBeTargeted() )
		{
			return false;
		}
		
		// visibility check
		if ( info.invisibleCheck && !targetActor.GetGameplayVisibility() )
		{
			return false;
		}
	
		sourcePosition = sourceActor.GetWorldPosition();
		targetPosition = targetEntity.GetWorldPosition();
				
		if ( targetActor )
		{
			{ // do not target mounted horses
				targetNPC = (CNewNPC)targetActor;
				if ( targetNPC )
				{
					if ( targetNPC.IsHorse() && !targetNPC.GetHorseComponent().IsDismounted() )
					{
						return false;
					}
				}
			}
		}
			
		if ( info.distCheck || info.knockDownCheck )
		{			
			if ( usePrecalcs )
			{
				if ( targetActor )
				{
					// radius is taken form the first actor
					sourceToTargetDist = Distance2DBetweenCapsuleAndPoint( targetActor, sourceActor ) - targetingPrecalcs.playerRadius;
				}
				else
				{
					sourceToTargetDist = VecDistance2D( sourcePosition, targetPosition ) - targetingPrecalcs.playerRadius;
				}			
			}
			else
			{
				if ( targetActor )
				{
					sourceToTargetDist = Distance2DBetweenCapsules( sourceActor, targetActor );
				}
				else
				{
					sourceToTargetDist = Distance2DBetweenCapsuleAndPoint( sourceActor, targetEntity );
				}
			}
		}

		// distance check
		if ( info.distCheck )
		{
			if ( sourceToTargetDist >= info.coneDist )
			{
				return false;
			}
		}

		// prepare source to target direction if needed
		if ( info.coneCheck || info.rsHeadingCheck )
		{
			direction = VecNormalize2D( targetPosition - sourcePosition );
		}
		
		// cone check
		if ( info.coneCheck )
		{
			if ( VecDot2D( direction, info.coneHeadingVector ) < info.coneHalfAngleCos )
			{
				return false;
			}
		}
		
		// heading cone check
		if ( info.rsHeadingCheck )
		{
			if ( usePrecalcs )
			{
				if ( VecDot2D( direction, targetingIn.lookAtDirection ) < info.rsHeadingLimitCos )
				{
					return false;
				}
			}
			else
			{
				if ( VecDot2D( direction, VecNormalize2D( GetLookAtPosition() - sourcePosition ) ) < info.rsHeadingLimitCos )
				{
					return false;
				}
			}
		}
				
		// "in frame" check
		if ( info.inFrameCheck && !WasVisibleInScaledFrame( targetEntity, info.frameScaleX, info.frameScaleY ) )
		{
			return false;
		}
		
		// navmesh check
		if ( info.navMeshCheck && !IsSwimming() )
		{
			sourceCapsuleRadius = 0.1f;
			if ( usePrecalcs )
			{
				sourceCapsuleRadius = targetingPrecalcs.playerRadius;
			}
			else
			{
				mpac = (CMovingPhysicalAgentComponent)sourceActor.GetMovingAgentComponent();
				if ( mpac )
				{
					sourceCapsuleRadius = mpac.GetCapsuleRadius();
				}
			}
			if ( !theGame.GetWorld().NavigationLineTest( sourcePosition, targetPosition, sourceCapsuleRadius ) )
			{
				return false;
			}
		}
		
		// knockdown check
		if ( info.knockDownCheck )
		{
			// if actor is not alive
			if ( targetActor && !targetActor.IsAlive() )
			{
				// and contains enabled "Finish" interaction
				finishEnabled = targetActor.GetComponent( 'Finish' ).IsEnabled();
				if ( finishEnabled )
				{
					// and is contained in finishable enemies list
					if ( finishableEnemiesList.Contains( targetActor ) )
					{
						// and is too far to "finish" -> we cannot target it
						if ( sourceToTargetDist >= info.knockDownCheckDist )
						{
							return false;
						}						
					}
				}
			}				
		}
		
		return true;
	}
	
	public function CanBeTargetedIfSwimming( actor : CActor, optional usePrecalcs : bool ) : bool
	{
		var subDepth	: float;
		var isDiving	: bool;
	
		if ( !actor )
		{
			return false;
		}
		
		if ( usePrecalcs )
		{
			isDiving = targetingIn.isDiving;
		}
		else
		{
			isDiving = IsSwimming() && OnCheckDiving();
		}
	
		subDepth = ((CMovingPhysicalAgentComponent)actor.GetMovingAgentComponent()).GetSubmergeDepth();
				
		if ( isDiving )
		{
			return ( subDepth < -1.0f );
		}
		else
		{
			return ( subDepth >= -1.0f );
		}
	}
	
	/*
	public function IsEntityTargetable( source : CActor, targetEntity : CGameplayEntity, coneCheck : bool, coneAngle, coneDist, coneHeading : float, distCheck, invisibleCheck, navMeshCheck : bool, inFrameCheck : bool, frameScaleX : float, frameScaleY : float, knockDownCheck : bool, knockDownCheckDist : float, rsHeadingCheck : bool, rsHeading : float, rsHeadingLimit : float) : bool
	{
		var targetActor				: CActor;
		var targetNPC				: CNewNPC;
		var direction				: Vector;
		var sourceToTargetDist		: float;
		var coneDistSq  			: float;
		var sourceCapsuleRadius 	: float;
		var knockDownCheckDistSq	: float;
		var sourceToTargetAngleDist	: float;
		var b						: bool;
		var targetsHorse			: W3HorseComponent;
			
		direction = VecNormalize2D( targetEntity.GetWorldPosition() - source.GetWorldPosition() );
		targetActor = (CActor)targetEntity;
		
		if ( distCheck )
		{
			if ( targetActor )
				sourceToTargetDist = VecDistanceSquared( source.GetWorldPosition(), targetActor.GetNearestPointInBothPersonalSpaces( source.GetWorldPosition() ) );
			else
				sourceToTargetDist = VecDistanceSquared( source.GetWorldPosition(), targetEntity.GetWorldPosition() );
			
			coneDistSq = coneDist * coneDist;
		}
		
		if ( knockDownCheck && targetActor )
			knockDownCheckDistSq = knockDownCheckDist * knockDownCheckDist;
			
		if ( navMeshCheck && targetActor ) 
			sourceCapsuleRadius = ((CMovingPhysicalAgentComponent)source.GetMovingAgentComponent()).GetCapsuleRadius();
			
		if ( rsHeadingCheck )
			sourceToTargetAngleDist = AngleDistance( VecHeading( GetLookAtPosition() - source.GetWorldPosition() ), VecHeading( targetEntity.GetWorldPosition() - source.GetWorldPosition() ) );
		
		// do not target mounted horses
		if(targetActor)
		{
			targetNPC = (CNewNPC)targetActor;
			if(targetNPC)
			{
				targetsHorse = (W3HorseComponent)targetNPC.GetHorseComponent();
				if(targetsHorse && targetsHorse.IsNotBeingUsed() )
					return false;
			}
		}	
		
		b = !coneCheck || AbsF( AngleDistance( coneHeading, VecHeading( direction ) ) ) < ( coneAngle * 0.5 );
		b = b && ( !distCheck || sourceToTargetDist < coneDistSq );
		b = b && ( !invisibleCheck || targetActor.GetGameplayVisibility() );
		b = b && ( !navMeshCheck || (!IsSwimming() && theGame.GetWorld().NavigationLineTest( source.GetWorldPosition(), targetActor.GetWorldPosition(), sourceCapsuleRadius ) ) );
		b = b && ( !inFrameCheck || WasVisibleInScaledFrame( targetEntity, frameScaleX, frameScaleY ) );
		b = b && ( !rsHeadingCheck || ( rsHeading >= 0 && sourceToTargetAngleDist < 0 && sourceToTargetAngleDist >= ( rsHeadingLimit * -1 ) ) || ( rsHeading < 0 && sourceToTargetAngleDist >= 0 && sourceToTargetAngleDist <= rsHeadingLimit ) );
		b = b && ( !knockDownCheck || !targetActor.GetComponent( 'Finish' ).IsEnabled() || ( targetActor.GetComponent( 'Finish' ).IsEnabled() && sourceToTargetDist < knockDownCheckDistSq ) );

		if ( b )
			return true;
		else
			return false;
	}
	*/	
	private function FilterActors( out targets : array<CActor>, out onlyThreatsReturned : bool, optional usePrecalcs : bool )
	{
		var i  								: int;
		var size							: int;
		var	foundThreat						: bool;
		var foundNonThreat					: bool;
		var threatsCount					: int;
		var tmpActor						: CActor;
		
		foundThreat = false;
		foundNonThreat = false;
		
		size = targets.Size();
		i = 0;
		threatsCount = 0;
		
		// after that loop first "threatsCount" targets will be "threat"
		for ( i = 0; i < size; i+=1 )
		{
			if( IsThreat( targets[ i ], usePrecalcs ) )
			{
				foundThreat = true;
				if ( i != threatsCount )
				{
					tmpActor = targets[ i ];
					targets[ i ] = targets[ threatsCount ];
					targets[ threatsCount ] = tmpActor;
				}
				threatsCount += 1;
			}
			else
			{
				foundNonThreat = true;
			}
		}
		
		if ( foundThreat )
		{
			onlyThreatsReturned = true;
			if ( foundNonThreat )
			{
				targets.Resize( threatsCount );
			}
		}
	}	
	
	private function InternalFindTargetsInCone( out targets : array< CActor >, out outHeadingVector : Vector, optional usePrecalcs : bool )
	{
		var size, i							: int;
		var coneHalfAngleDot				: float;
		var coneHeading						: float;
		var coneHeadingVector				: Vector;
		var position						: Vector;
		var direction						: Vector;
		var onlyThreatTargetsFound			: bool;
		
		targets.Clear();
		GetVisibleEnemies( targets );
		
		//Include enemies that are technically dead, but can be finished off
		for( i = 0; i < finishableEnemiesList.Size() ; i+=1 )
		{
			if ( !targets.Contains( finishableEnemiesList[i] ) )
			{
				targets.PushBack( finishableEnemiesList[i] );
			}
		}		

		onlyThreatTargetsFound = false;
		FilterActors( targets, onlyThreatTargetsFound, true );
			
		if ( IsCombatMusicEnabled() && targets.Size() > 0 && !onlyThreatTargetsFound && !IsThreat( targets[0], usePrecalcs ) ) 
		{
			targets.Clear();
		}
		
		coneHeading = 0.0f;
		coneHalfAngleDot = 0.0f;
		if ( ( orientationTarget == OT_Camera ) || ( orientationTarget == OT_CameraOffset ) )
		{
			if ( usePrecalcs )
			{
				coneHeading = targetingPrecalcs.cameraHeading;
			}
			else
			{
				coneHeading = theGame.GetGameCamera().GetHeading();
			}
			coneHalfAngleDot = 0.5f; // = CosF( Deg2Rad( 120.f * 0.5f ) ); - Just use calculator... why not? this is constant.
		}
		else
		{ 
			if ( IsSwimming() )
			{
				if ( usePrecalcs )
				{
					coneHeading = targetingPrecalcs.cameraHeading;
				}
				else
				{
					coneHeading = theGame.GetGameCamera().GetHeading();
				}
				coneHalfAngleDot = 0.17364817766f; // = CosF( Deg2Rad( 160.f * 0.5f ) );
			}
			else if ( bLAxisReleased )
			{
				if( IsInCombatAction() )
				{
					coneHeading = GetCombatActionHeading();
				}
				else
				{
					if ( ShouldUsePCModeTargeting() )
						coneHeading = theGame.GetGameCamera().GetHeading();
					else
						coneHeading = cachedRawPlayerHeading;
				}
					
				if ( IsInCombat() )
				{
					if ( ShouldUsePCModeTargeting() )
						coneHalfAngleDot = -1; // = CosF( Deg2Rad( 360.0f * 0.5f ) )
					else
						coneHalfAngleDot = 0.17364817766f; // = CosF( Deg2Rad( 160.f * 0.5f ) );
				}
				else
				{
					coneHalfAngleDot = -1.0f;
				}
			}
			else
			{
				if( IsInCombatAction() )
				{
					coneHeading = GetCombatActionHeading();
				}
				else
				{
					if ( ShouldUsePCModeTargeting() )
						coneHeading = theGame.GetGameCamera().GetHeading();
					else
						coneHeading = cachedRawPlayerHeading;
				}
				
				if ( ShouldUsePCModeTargeting() )
					coneHalfAngleDot = -1; // = CosF( Deg2Rad( 360.0f * 0.5f ) )
				else				
					coneHalfAngleDot = 0.17364817766f; // = CosF( Deg2Rad( 160.f * 0.5f ) );
			}

			coneHeadingVector = VecFromHeading( coneHeading );
			position = this.GetWorldPosition();

			for ( i = targets.Size() - 1; i >= 0; i -= 1 )
			{
				if ( !targets[i] )
				{
					targets.EraseFast(i);
					continue;
				}
					
				direction = VecNormalize2D( targets[i].GetWorldPosition() - position );
				
				if ( VecDot2D( coneHeadingVector, direction ) < coneHalfAngleDot )
				{
					targets.EraseFast( i );
				}
			}
		}
		
		outHeadingVector = coneHeadingVector;
	}
	
	///////////////////////////////////////////////////////////////////////////
	// (new) targeting
	
	function InitTargeting()
	{
		var consts : SR4PlayerTargetingConsts;
		
		if ( !targeting )
		{
			targeting = new CR4PlayerTargeting in this;
		}
		if ( targeting )
		{
			consts.softLockDistance = this.softLockDist;
			consts.softLockFrameSize = this.softLockFrameSize;
			targeting.SetConsts( consts );
		}		
	}
	
	function PrepareTargetingIn( actionCheck : bool, bufferActionType : EBufferActionType, actionInput : bool )
	{
		var coneDist : float;
		
		if ( actionCheck && bufferActionType == EBAT_ItemUse )
		{
			coneDist = findMoveTargetDist;
		}
		else if ( IsSwimming() )
		{
			coneDist = theGame.params.MAX_THROW_RANGE;
		}
		else if ( ( GetPlayerCombatStance() == PCS_AlertNear ) && ( ( playerMoveType == PMT_Walk ) || ( playerMoveType == PMT_Idle ) ) )
		{
			coneDist = softLockDist; 
		}
		else
		{
			coneDist = findMoveTargetDist;
		}
	
		targetingIn.canFindTarget 					= this.bCanFindTarget;
		targetingIn.playerHasBlockingBuffs 			= thePlayer.HasBuff( EET_Confusion ) || thePlayer.HasBuff( EET_Hypnotized ) || thePlayer.HasBuff( EET_Blindness ) || thePlayer.HasBuff( EET_WraithBlindness );
		targetingIn.isHardLockedToTarget			= this.IsHardLockEnabled();
		targetingIn.isActorLockedToTarget 			= this.IsActorLockedToTarget();
		targetingIn.isCameraLockedToTarget 			= this.IsCameraLockedToTarget();
		targetingIn.actionCheck 					= actionCheck;
		targetingIn.actionInput						= actionInput;
		targetingIn.isInCombatAction				= this.IsInCombatAction();
		targetingIn.isLAxisReleased 				= this.bLAxisReleased;
		targetingIn.isLAxisReleasedAfterCounter 	= this.lAxisReleasedAfterCounter;
		targetingIn.isLAxisReleasedAfterCounterNoCA = this.lAxisReleasedAfterCounterNoCA;
		targetingIn.lastAxisInputIsMovement 		= this.lastAxisInputIsMovement;
		targetingIn.isAiming 						= this.playerAiming.GetCurrentStateName() == 'Aiming';
		targetingIn.isSwimming 						= this.IsSwimming();
		targetingIn.isDiving 						= this.IsSwimming() && OnCheckDiving();
		targetingIn.isThreatened 					= this.IsThreatened();
		targetingIn.isCombatMusicEnabled 			= this.IsCombatMusicEnabled();
		targetingIn.isPcModeEnabled 				= this.IsPCModeEnabled();
		targetingIn.isInParryOrCounter				= this.isInParryOrCounter;
		targetingIn.shouldUsePcModeTargeting 		= this.ShouldUsePCModeTargeting();
		targetingIn.bufferActionType 				= bufferActionType;
		targetingIn.orientationTarget 				= this.GetOrientationTarget();
		targetingIn.coneDist 						= coneDist; // computed few lines above
		targetingIn.findMoveTargetDist 				= this.findMoveTargetDist;
		targetingIn.cachedRawPlayerHeading 			= this.cachedRawPlayerHeading;
		targetingIn.combatActionHeading 			= this.GetCombatActionHeading();
		targetingIn.rawPlayerHeadingVector 			= VecFromHeading( this.rawPlayerHeading );
		targetingIn.lookAtDirection					= VecNormalize2D( this.GetLookAtPosition() - GetWorldPosition() );
		targetingIn.moveTarget 						= this.moveTarget;
		targetingIn.aimingTarget 					= this.playerAiming.GetAimedTarget();	
		targetingIn.displayTarget 					= (CActor)this.displayTarget;
		targetingIn.finishableEnemies 				= this.finishableEnemiesList;
		targetingIn.hostileEnemies 					= this.hostileEnemies;
		targetingIn.defaultSelectionWeights 		= ProcessSelectionWeights();
	}
	
	function ResetTargetingOut()
	{
		targetingOut.target 					= NULL;
		targetingOut.result 					= false;
		targetingOut.confirmNewTarget 			= false;
		targetingOut.forceDisableUpdatePosition	= false;	
	}
	
	function MakeFindTargetPrecalcs()
	{
		var mpac : CMovingPhysicalAgentComponent;
	
		targetingPrecalcs.playerPosition 		= thePlayer.GetWorldPosition();
		targetingPrecalcs.playerHeading			= thePlayer.GetHeading();
		targetingPrecalcs.playerHeadingVector	= thePlayer.GetHeadingVector();
		targetingPrecalcs.playerHeadingVector.Z = 0;
		targetingPrecalcs.playerHeadingVector 	= VecNormalize2D( targetingPrecalcs.playerHeadingVector );
		
		targetingPrecalcs.playerRadius = 0.5f;
		mpac = (CMovingPhysicalAgentComponent)thePlayer.GetMovingAgentComponent();
		if ( mpac )
		{
			targetingPrecalcs.playerRadius = mpac.GetCapsuleRadius();
		}
		
		targetingPrecalcs.cameraPosition 		= theCamera.GetCameraPosition();
		targetingPrecalcs.cameraDirection 		= theCamera.GetCameraDirection();
		targetingPrecalcs.cameraHeadingVector 	= targetingPrecalcs.cameraDirection;
		targetingPrecalcs.cameraHeadingVector.Z = 0;
		targetingPrecalcs.cameraHeadingVector	= VecNormalize2D( targetingPrecalcs.cameraHeadingVector );			
		targetingPrecalcs.cameraHeading 		= VecHeading( targetingPrecalcs.cameraHeadingVector );				
	}
	
	public function GetForceDisableUpdatePosition() : bool
	{
		return targetingOut.forceDisableUpdatePosition;
	}
	
	public function SetUseNativeTargeting( use : bool )
	{
		useNativeTargeting = use;
	}
	
	protected function FindTarget( optional actionCheck : bool, optional action : EBufferActionType, optional actionInput : bool ) : CActor
	{
		if ( IsCombatMusicEnabled() && !IsInCombat() && reachableEnemyWasTooFar )
		{
			playerMode.UpdateCombatMode();
		}
	
		PrepareTargetingIn( actionCheck, action, actionInput );
		if ( useNativeTargeting )
		{
			targeting.BeginFindTarget( targetingIn );
			targeting.FindTarget();
			targeting.EndFindTarget( targetingOut );
		}
		else
		{
			UpdateVisibleActors();
			MakeFindTargetPrecalcs();
			ResetTargetingOut();
			FindTarget_Scripted();
		}
		if ( targetingOut.result )
		{
			if ( targetingOut.confirmNewTarget )
			{
				ConfirmNewTarget( targetingOut.target );
			}
			return targetingOut.target;
		}
		return NULL;
	}
		
	protected function FindTarget_Scripted()
	{
		var currentTarget					: CActor;
		var newTarget						: CActor;
		var selectedTarget					: CActor;
		var displayTargetActor				: CActor;
		var playerPosition					: Vector;
		var playerHeadingVector				: Vector;
		var cameraPosition					: Vector;
		var cameraHeadingVector				: Vector;
		var selectionHeadingVector			: Vector;
		var targetingInfo					: STargetingInfo;
		var selectionWeights				: STargetSelectionWeights;
		var targets							: array< CActor >;
		var isMoveTargetTargetable			: bool;		
		var targetChangeFromActionInput		: bool;
		var retainCurrentTarget				: bool;
		
		// caching data
		
		playerPosition = this.GetWorldPosition();
		playerHeadingVector = targetingPrecalcs.playerHeadingVector;			
		cameraPosition = theCamera.GetCameraPosition();
		cameraHeadingVector = targetingPrecalcs.cameraHeadingVector;
		
		currentTarget = GetTarget();		
		if ( currentTarget )
		{
			if ( IsHardLockEnabled() && currentTarget.IsAlive() && !currentTarget.IsKnockedUnconscious() )
			{
				if ( VecDistanceSquared( playerPosition, currentTarget.GetWorldPosition() ) > 50.f * 50.0f )
				{
					HardLockToTarget( false );
				}
				else
				{
					targetingOut.target = currentTarget;
					targetingOut.result = true;
					return;
				}
			}				
			GetVisualDebug().AddSphere('target', 1.0f, currentTarget.GetWorldPosition(), true, Color( 255, 255, 0 ), 1.0f );
		}

		if ( bCanFindTarget && !IsActorLockedToTarget() )
		{		
			if ( !targetingIn.playerHasBlockingBuffs )
			{
				InternalFindTargetsInCone( targets, selectionHeadingVector, true );
			}
			
			targetingInfo.source 				= this;
			targetingInfo.canBeTargetedCheck	= true;
			targetingInfo.coneCheck 			= false;
			targetingInfo.coneHalfAngleCos		= 1.0f;
			targetingInfo.coneDist				= targetingIn.coneDist;
			targetingInfo.distCheck				= true;
			targetingInfo.invisibleCheck		= true;
			targetingInfo.navMeshCheck			= false; //true; 
			
			if ( ShouldUsePCModeTargeting() )
				targetingInfo.inFrameCheck 			= false; 
			else
				targetingInfo.inFrameCheck 			= true; 
				
			targetingInfo.frameScaleX 			= 1.0f; 
			targetingInfo.frameScaleY 			= 1.0f; 
			targetingInfo.knockDownCheck 		= false; 
			targetingInfo.knockDownCheckDist 	= 1.5f; 
			targetingInfo.rsHeadingCheck 		= false;
			targetingInfo.rsHeadingLimitCos 	= 1.0f;

			if ( currentTarget )
			{
				targetingInfo.targetEntity = currentTarget;
				if ( !IsEntityTargetable( targetingInfo, true ) )
				{
					currentTarget = NULL;
				}	
				if ( currentTarget && !CanBeTargetedIfSwimming( currentTarget, true ) )
				{
					currentTarget = NULL;
				}
			}

			isMoveTargetTargetable = false;
			if ( moveTarget )
			{
				if ( CanBeTargetedIfSwimming( moveTarget, true ) )
				{
					targetingInfo.targetEntity = moveTarget;
					targetingInfo.coneDist = findMoveTargetDist;
					targetingInfo.inFrameCheck = false;
					if ( IsEntityTargetable( targetingInfo, true ) )
					{
						isMoveTargetTargetable = true;
					}
				}
			}

			// checking "standard" cone dist again
			targetingInfo.coneDist = targetingIn.coneDist;
			
			if ( !targetingIn.playerHasBlockingBuffs )
			{
				RemoveNonTargetable( targets, targetingInfo, selectionHeadingVector );
			}
			
			newTarget = NULL;
			if ( this.playerAiming.GetCurrentStateName() == 'Aiming' )
			{
				newTarget = this.playerAiming.GetAimedTarget();				
				if ( !newTarget )
				{
					selectionWeights.angleWeight = 1.f;
					selectionWeights.distanceWeight = 0.f;
					selectionWeights.distanceRingWeight = 0.f;
					
					selectedTarget = SelectTarget( targets, false, cameraPosition, cameraHeadingVector, selectionWeights, true );
					newTarget = selectedTarget;				
				}
			}
			else if ( IsSwimming() )
			{
				selectionWeights.angleWeight = 0.9f;
				selectionWeights.distanceWeight = 0.1f;
				selectionWeights.distanceRingWeight = 0.f;
				
				selectedTarget = SelectTarget( targets, true, cameraPosition, cameraHeadingVector, selectionWeights, true );		
				newTarget = selectedTarget;
			}			
			else if ( IsThreatened() )
			{
				// Change locked enemy when the current one becomes invisible
				if ( IsCameraLockedToTarget() )
				{
					if ( currentTarget && !currentTarget.GetGameplayVisibility() )
					{
						ForceSelectLockTarget();
					}
				}			
			
				displayTargetActor = (CActor)displayTarget;
				selectedTarget = SelectTarget( targets, true, playerPosition, selectionHeadingVector, targetingIn.defaultSelectionWeights, true );
					
				if ( !selectedTarget )
				{
					targetingOut.forceDisableUpdatePosition = true;
				}
				
				targetChangeFromActionInput = targetingIn.actionInput && !lAxisReleasedAfterCounter;				
				if ( selectedTarget &&
					 ( !IsThreat( currentTarget, true ) || ShouldUsePCModeTargeting() || ( !IsInCombatAction() && !lAxisReleasedAfterCounterNoCA ) || targetChangeFromActionInput ) )
				{
					newTarget = selectedTarget;
				}
				else if ( displayTargetActor &&
						  ( ( bLAxisReleased && !ShouldUsePCModeTargeting() )|| IsInCombatAction() ) &&
						  ( displayTargetActor.IsAlive() || finishableEnemiesList.Contains( displayTargetActor ) ) &&
						  displayTargetActor.GetGameplayVisibility() &&
						  ( IsEnemyVisible( displayTargetActor ) || finishableEnemiesList.Contains( displayTargetActor ) ) &&
						  this.CanBeTargetedIfSwimming( displayTargetActor, true ) &&
						  IsThreat( displayTargetActor, true ) &&
						  WasVisibleInScaledFrame( displayTargetActor, 1.f, 1.f ) )
				{
					newTarget = displayTargetActor;
				}
				// target closest enemy immediately when transitioning from running/sprint to walk/idle, 
				// but when you are already in walk/idle player should hit air after he kills his target, he should only target closest enemy when that enmy is within his field of vision
				else if ( moveTarget &&
						  isMoveTargetTargetable && 
						 ( !IsInCombatAction() || isInParryOrCounter || GetBehaviorVariable( 'combatActionType' ) == (int)CAT_Dodge || GetBehaviorVariable( 'combatActionType' ) == (int)CAT_Roll ) )
				{
					newTarget = moveTarget;
				}
				else
				{
					newTarget = NULL;
				}
			}
			else
			{
				retainCurrentTarget = false;
				if ( lAxisReleasedAfterCounterNoCA )
				{
					if ( lastAxisInputIsMovement && !this.IsSwimming())
					{
						selectionWeights.angleWeight = 0.375f;
						selectionWeights.distanceWeight = 0.275f;
						selectionWeights.distanceRingWeight = 0.35f;
						selectedTarget = SelectTarget( targets, false, playerPosition, playerHeadingVector, selectionWeights, true );	

						if ( currentTarget != selectedTarget )
						{
							targetingInfo.targetEntity = currentTarget;
							if ( IsEntityTargetable( targetingInfo, true ) && currentTarget.IsAlive() )
							{
								retainCurrentTarget = true;
							}
						}
					}
					else
					{
						selectionWeights.angleWeight = 0.75f;
						selectionWeights.distanceWeight = 0.125f;
						selectionWeights.distanceRingWeight = 0.125f;
						selectedTarget = SelectTarget( targets, false, cameraPosition, cameraHeadingVector, selectionWeights, true );		
					}			
				}
				else
				{
					selectionWeights.angleWeight = 0.6f;
					selectionWeights.distanceWeight = 0.4f;
					selectionWeights.distanceRingWeight = 0.f;
					selectedTarget = SelectTarget( targets, true, playerPosition, targetingIn.rawPlayerHeadingVector, selectionWeights, true );
				}
				
				if ( retainCurrentTarget )
				{
					newTarget = currentTarget;
				}
				else if ( IsInCombatAction() && GetBehaviorVariable( 'isPerformingSpecialAttack' ) == 1.0f )
				{
					newTarget = moveTarget;
				}
				else if ( selectedTarget )
				{
					newTarget = selectedTarget;
				}
				else
				{
					newTarget = NULL;
				}
			}	
		
			targetingOut.confirmNewTarget = true;
		}
		else
		{
			newTarget = NULL;
		}
		
		targetingOut.result = true;
		targetingOut.target = newTarget;			
	}
	
	function UpdateVisibleActors()
	{
		var i : int;
		var now : float;
		
		now = theGame.GetEngineTimeAsSeconds();
		for ( i = visibleActors.Size() - 1; i >= 0; i-=1 )
		{
			// wasn't visible for more than 1 second
			if ( ( now - visibleActorsTime[i] ) > 1.0f )
			{
				visibleActors.EraseFast( i );
				visibleActorsTime.EraseFast( i );
			}
		}
	}
	
	function RemoveNonTargetable( out targets : array< CActor >, out info : STargetingInfo, selectionHeadingVector : Vector )
	{
		var i						: int;
		var cameraPosition 			: Vector;
		var cameraDirection			: Vector;
		var nonCombatCheck			: bool;
		var playerToCamPlaneDist	: float;
		var targetToCamPlaneDist	: float;
		
		if ( targets.Size() == 0 )
		{
			return;
		}
		
		nonCombatCheck = bLAxisReleased && !IsInCombat();
		
		// first, let's prepare targeting info (so that we don't need to do it in each loop step)
		if ( nonCombatCheck )
		{
			info.coneHeadingVector	= targetingPrecalcs.playerHeadingVector; 					
			if ( lastAxisInputIsMovement )
			{
				info.coneHeadingVector	= selectionHeadingVector;
				info.invisibleCheck		= false;
				info.coneCheck 			= true;
				info.coneHalfAngleCos	= 0.76604444311f; // = CosF( Deg2Rad( 80.0f * 0.5f ) )
			}
			else
			{
				info.invisibleCheck	= false;
				info.frameScaleX 	= 0.9f; 
				info.frameScaleY 	= 0.9f; 
			}
		}
		else
		{
			info.coneHeadingVector	= Vector( 0.0f, 0.0f, 0.0f );
				
			//MS: ConeCheck is false because it's already been filtered by InternalFindTargetsInCone
			if ( IsInCombat() )
			{
				info.inFrameCheck = false; 
			}
			else
			{
				if ( !bLAxisReleased )
				{
					info.coneCheck 			= true;
					
					if ( this.IsSwimming() )
						info.coneHalfAngleCos	= -1; // = CosF( Deg2Rad( 360.0f * 0.5f ) )
					else
						info.coneHalfAngleCos	= 0.86602540378f; // = CosF( Deg2Rad( 60.0f * 0.5f ) )
						
					info.coneHeadingVector	= targetingIn.rawPlayerHeadingVector; 
				}
			}
		}
		
		cameraPosition = theCamera.GetCameraPosition();
		cameraDirection = targetingPrecalcs.cameraDirection;
		playerToCamPlaneDist = VecDot2D( cameraDirection, this.GetWorldPosition() - cameraPosition );
		
		// then, using prepared info let's filter out invalid targets
		for( i = targets.Size() - 1; i >= 0; i -= 1 )
		{	
			info.targetEntity = targets[i];
			
			if ( !CanBeTargetedIfSwimming( targets[i], true ) )
			{
				targets.EraseFast( i );
			}
			else if ( !IsEntityTargetable( info, true ) )
			{
				targets.EraseFast( i );
			}			
			else 
			{
				if ( nonCombatCheck && !lastAxisInputIsMovement )
				{
					// removing targets between camera and player
					targetToCamPlaneDist = VecDot2D( cameraDirection, targets[i].GetWorldPosition() - cameraPosition );
					if ( targetToCamPlaneDist < playerToCamPlaneDist )
					{
						targets.EraseFast( i );
					}
				}
			}
		}
	}
	
	var combatModeColor : Color;
	public function CombatModeDebug()
	{
		var visualDebug : CVisualDebug = GetVisualDebug();
		
		var naviQueryMsg	: string;
		var naviQueryMsg1	: string;
		var naviQueryMsg2	: string;
		
		var navSnapMsg		: string;
		var i				: int;
	
		if ( IsCombatMusicEnabled() ) 	
			visualDebug.AddText( 'CombatMusic', "CombatMusic : On", thePlayer.GetWorldPosition() + Vector( 0.f,0.f,1.7f ), true, , Color( 255, 255, 255 ) );
		else
			visualDebug.AddText( 'CombatMusic', "CombatMusic : Off", thePlayer.GetWorldPosition() + Vector( 0.f,0.f,1.7f ), true, , Color( 0, 0, 0 ) );		

		if ( GetPlayerMode().GetForceCombatMode() )
			visualDebug.AddText( 'ForcedCombatMode', "ForcedCombatMode : TRUE", thePlayer.GetWorldPosition() + Vector( 0.f,0.f,1.6f ), true, , Color( 255, 255, 255 ) );
		else
			visualDebug.AddText( 'ForcedCombatMode', "ForcedCombatMode : FALSE", thePlayer.GetWorldPosition() + Vector( 0.f,0.f,1.6f ), true, , Color( 0, 0, 0 ) );	

	
		if ( IsThreatened() )
		{
			if ( IsInCombat() )
				visualDebug.AddText( 'CombatMode', "CombatMode : AlertNear/Far", thePlayer.GetWorldPosition() + Vector( 0.f,0.f,1.5f ), true, , Color( 255, 0, 0 ) );
			else
				visualDebug.AddText( 'CombatMode', "CombatMode : CombatExploration", thePlayer.GetWorldPosition() + Vector( 0.f,0.f,1.5f ), true, , Color( 255, 255, 0 ) );
		}
		else
			visualDebug.AddText( 'CombatMode', "CombatMode : NormalExploration", thePlayer.GetWorldPosition() + Vector( 0.f,0.f,1.5f ), true, , Color( 0, 255, 0 ) );
	
		visualDebug.AddText( 'NaviQuery', naviQueryMsg, combatModeEnt.GetWorldPosition() + Vector( 0.f,0.f,1.3f ), true, , combatModeColor );
		visualDebug.AddText( 'NaviQuery1', naviQueryMsg1, thePlayer.GetWorldPosition() + Vector( 0.f,0.f,1.3f ), true, , combatModeColor );
		visualDebug.AddText( 'NaviQuery2', naviQueryMsg2, thePlayer.GetWorldPosition() + Vector( 0.f,0.f,1.2f ), true, , combatModeColor );
		
		if ( isInCombatReason == 0 )
			visualDebug.AddText( 'CombatModeReason', "CombatModeReason : ", thePlayer.GetWorldPosition() + Vector( 0.f,0.f,1.4f ), true, , Color( 125, 125, 125 ) );
		else if ( isInCombatReason == 1 )
			visualDebug.AddText( 'CombatModeReason', "CombatModeReason : Geralt CAN pathfind to NPC", thePlayer.GetWorldPosition() + Vector( 0.f,0.f,1.4f ), true, , Color( 255, 0, 0 ) );
		else if ( isInCombatReason == 2 )
			visualDebug.AddText( 'CombatModeReason', "CombatModeReason : An NPC is flying or ranged", thePlayer.GetWorldPosition() + Vector( 0.f,0.f,1.4f ), true, , Color( 255, 0, 0 ) );					
		else if ( isInCombatReason == 2 )
			visualDebug.AddText( 'CombatModeReason', "CombatModeReason : Forced Combat Mode", thePlayer.GetWorldPosition() + Vector( 0.f,0.f,1.4f ), true, , Color( 255, 0, 0 ) );

		if ( reachableEnemyWasTooFar )
		{
			combatModeColor.Red = 255;
			combatModeColor.Green = 255;
			combatModeColor.Blue = 0;				
		}
		else
		{
			combatModeColor.Red = 0;
			combatModeColor.Green = 255;
			combatModeColor.Blue = 0;				
		}
		
		if ( IsThreatened() )
		{
			switch ( navQuery.GetLastOutput( 2.0 ) )
			{
				case EAsyncTastResult_Failure:
				{	
					if ( this.playerMode.GetForceCombatMode() )
					{
						if ( isSnappedToNavMesh )
						{
							visualDebug.AddText( 'NaviQuery', "", combatModeEnt.GetWorldPosition() + Vector( 0.f,0.f,1.3f ), true, , combatModeColor );
							visualDebug.AddText( 'NaviQuery1', "Naviquery : Snapped So no need for query", thePlayer.GetWorldPosition() + Vector( 0.f,0.f,1.3f ), true, , combatModeColor );
							visualDebug.AddText( 'NaviQuery2', "Naviquery : Snapped So no need for query", thePlayer.GetWorldPosition() + Vector( 0.f,0.f,1.2f ), true, , combatModeColor );
						}
						else
						{
							visualDebug.AddText( 'NaviQuery', "", combatModeEnt.GetWorldPosition() + Vector( 0.f,0.f,1.3f ), true, , combatModeColor );
							visualDebug.AddText( 'NaviQuery1', "Naviquery : Failed", thePlayer.GetWorldPosition() + Vector( 0.f,0.f,1.3f ), true, , combatModeColor );
							visualDebug.AddText( 'NaviQuery2', "Naviquery : Failed", thePlayer.GetWorldPosition() + Vector( 0.f,0.f,1.2f ), true, , combatModeColor );						
						}
					}
					else
					{
						visualDebug.AddText( 'NaviQuery', "", combatModeEnt.GetWorldPosition() + Vector( 0.f,0.f,1.3f ), true, , combatModeColor );
						visualDebug.AddText( 'NaviQuery1', "Naviquery : Failed", thePlayer.GetWorldPosition() + Vector( 0.f,0.f,1.3f ), true, , combatModeColor );
						visualDebug.AddText( 'NaviQuery2', "Naviquery : Failed", thePlayer.GetWorldPosition() + Vector( 0.f,0.f,1.2f ), true, , combatModeColor );
					}
					break;
				}
				case EAsyncTastResult_Success:
				{			
					visualDebug.AddText( 'NaviQuery', combatModeEnt.GetName(), combatModeEnt.GetWorldPosition() + Vector( 0.f,0.f,1.3f ), true, , combatModeColor );
					visualDebug.AddText( 'NaviQuery1', "Naviquery : Success (navDist: " + navDist + ")", thePlayer.GetWorldPosition() + Vector( 0.f,0.f,1.3f ), true, , combatModeColor );
					visualDebug.AddText( 'NaviQuery2', "Naviquery : Success (directDist: " + directDist + ")", thePlayer.GetWorldPosition() + Vector( 0.f,0.f,1.2f ), true, , combatModeColor );	
					break;
				}
				case EAsyncTastResult_Pending:
				{
					visualDebug.AddText( 'NaviQuery', combatModeEnt.GetName(), combatModeEnt.GetWorldPosition() + Vector( 0.f,0.f,1.3f ), true, , combatModeColor );
					visualDebug.AddText( 'NaviQuery1', "Naviquery : Pending (navDist: " + navDist + ")", thePlayer.GetWorldPosition() + Vector( 0.f,0.f,1.3f ), true, , combatModeColor );
					visualDebug.AddText( 'NaviQuery2', "Naviquery : Pending (directDist: " + directDist + ")", thePlayer.GetWorldPosition() + Vector( 0.f,0.f,1.2f ), true, , combatModeColor );	
					break;
				}
				case EAsyncTastResult_Invalidated:
				{
					visualDebug.AddText( 'NaviQuery', "", combatModeEnt.GetWorldPosition() + Vector( 0.f,0.f,1.3f ), true, , combatModeColor );
					visualDebug.AddText( 'NaviQuery1', "Naviquery : Invalidated", thePlayer.GetWorldPosition() + Vector( 0.f,0.f,1.3f ), true, , combatModeColor );
					visualDebug.AddText( 'NaviQuery2', "Naviquery : Invalidated", thePlayer.GetWorldPosition() + Vector( 0.f,0.f,1.2f ), true, , combatModeColor );			
					break;
				}			
			}
		}
		else
		{
			visualDebug.AddText( 'NaviQuery', "", combatModeEnt.GetWorldPosition() + Vector( 0.f,0.f,1.3f ), true, , combatModeColor );
			visualDebug.AddText( 'NaviQuery1', "", thePlayer.GetWorldPosition() + Vector( 0.f,0.f,1.3f ), true, , combatModeColor );
			visualDebug.AddText( 'NaviQuery2', "", thePlayer.GetWorldPosition() + Vector( 0.f,0.f,1.2f ), true, , combatModeColor );				
		}
		
		if ( navMeshSnapInfoStack.Size() > 0 )
		{
			for ( i = navMeshSnapInfoStack.Size()-1; i >= 0; i -= 1 )
			{
				navSnapMsg = navSnapMsg + navMeshSnapInfoStack[i] + " ";
			}
			
			visualDebug.AddText( 'NavMeshSnap', "NavMeshSnap: Enabled, Sources : " + navSnapMsg, thePlayer.GetWorldPosition() + Vector( 0.f,0.f,1.1f ), true, , Color( 255, 255, 255 ) );
		}
		else
			visualDebug.AddText( 'NavMeshSnap', "NavMeshSnap: Disabled" , thePlayer.GetWorldPosition() + Vector( 0.f,0.f,1.1f ), true, , Color( 0, 0, 0 ) );
		
	}
	
	function IsCombatMusicEnabled() : bool
	{
		if ( theSound.GetCurrentGameState() == ESGS_UnderwaterCombat 
			|| theSound.GetCurrentGameState() == ESGS_Combat 
			|| theSound.GetCurrentGameState() == ESGS_CombatMonsterHunt 
			|| theSound.GetCurrentGameState() == ESGS_FocusUnderwaterCombat )
			return true;
		else
			return false;
	}
	
	function IsSoundStateCombatMusic( gameState : ESoundGameState  ) : bool
	{
		if ( gameState == ESGS_UnderwaterCombat 
			|| gameState == ESGS_Combat 
			|| gameState == ESGS_CombatMonsterHunt 
			|| gameState == ESGS_FocusUnderwaterCombat )
			return true;
		else
			return false;
	}	
		
	private function ConfirmNewTarget( actorToConfirm : CActor )
	{
		var leftJoyRotLimit : float = 1.f;
		
		var target : CActor;
		
		target = GetTarget();
		
		//MS: When Player pushes stick in npcs direction, he needs to push the stick beyond leftJoyRotLimit in order to change targets
		if ( 	!target
				|| !moveTarget
				|| ( target && ( !IsThreat( target ) || !target.IsAlive() ) ) 
				|| VecLength( rawLeftJoyVec ) < 0.7f
				|| ( IsInCombatAction() && ( ( GetBehaviorVariable( 'combatActionType') == (int)CAT_Dodge ) || ( VecLength( rawLeftJoyVec ) >= 0.7f && ( prevRawLeftJoyRot >= ( rawLeftJoyRot + leftJoyRotLimit ) || prevRawLeftJoyRot <= ( rawLeftJoyRot - leftJoyRotLimit ) || AbsF( AngleDistance( cachedRawPlayerHeading, VecHeading( GetDisplayTarget().GetWorldPosition() - this.GetWorldPosition() ) ) ) > 60 ) ) ) ) 
				|| ( !IsInCombatAction() && ( !rangedWeapon || ( rangedWeapon.GetCurrentStateName() != 'State_WeaponHolster' ) ) ))//&& rangedWeapon.GetCurrentStateName() != 'State_WeaponShoot' ) && rangedWeapon.GetCurrentStateName() != 'State_WeaponAim' ) )
		{
			SetPrevRawLeftJoyRot();
			
			if ( actorToConfirm != target )
			{
				SetTarget( actorToConfirm );
			}
		}
	}
	
	protected function SelectTarget( targets : array< CActor >, useVisibilityCheck : bool, sourcePosition : Vector, headingVector : Vector, selectionWeights : STargetSelectionWeights, optional usePrecalcs : bool ) : CActor
	{
		var i					: int;
		var	target				: CActor;	
		var	selectedTarget		: CActor;	
		var currentTarget		: CActor;
		var playerPosition		: Vector;
		var distanceToPlayer	: float;
		var priority			: float;
		var maxPriority			: float;
		var now					: float;
		var remove				: bool;
		var visibleActorIndex	: int;
				
		if ( useVisibilityCheck )
		{
			currentTarget = this.GetTarget();			
			playerPosition = this.GetWorldPosition();
			now = theGame.GetEngineTimeAsSeconds();
				
			for ( i = targets.Size() - 1; i >= 0; i-=1 ) 
			{	
				target = targets[ i ];
				if ( target != currentTarget && ( !IsPCModeEnabled() && !WasVisibleInScaledFrame( target, softLockFrameSize, softLockFrameSize ) ) )			
				{
					remove = true;
					visibleActorIndex = visibleActors.FindFirst( target );
					if ( visibleActorIndex != -1 )
					{
						if ( usePrecalcs )
						{
							distanceToPlayer = Distance2DBetweenCapsuleAndPoint( target, this ) - targetingPrecalcs.playerRadius;
						}
						else
						{
							distanceToPlayer = Distance2DBetweenCapsules( this, target );						
						}
						// if within soft lock distance and soft lock visibility duration -> don't remove yet
						if ( distanceToPlayer < this.softLockDist && ( now - visibleActorsTime[ i ] ) < 1.0f )
						{
							remove = false;
						}
					}
					if ( remove )
					{
						targets.EraseFast( i );
					}
				}
				else
				{
					visibleActorIndex = visibleActors.FindFirst( target );
					if ( visibleActorIndex == -1 )
					{
						visibleActors.PushBack( target );
						visibleActorsTime.PushBack( now );
					}
					else
					{
						visibleActorsTime[ visibleActorIndex ] = now;
					}
				}
			}
		}

		selectedTarget = NULL;
		maxPriority = -1.0f;
		for( i = targets.Size() - 1; i >= 0; i-=1 )
		{
			priority = CalcSelectionPriority( targets[ i ], selectionWeights, sourcePosition, headingVector );				
			if ( priority > maxPriority )
			{
				maxPriority = priority;
				selectedTarget = targets[ i ];
			}
		}			
	
		//LogChannel( 'selectedTarget', selectedTarget );
		return selectedTarget;	
	}

	function Distance2DBetweenCapsuleAndPoint( actor : CActor, entity : CEntity ) : float
	{
		var distance 	: float;
		var mpac 		: CMovingPhysicalAgentComponent;
		
		distance = VecDistance2D( actor.GetWorldPosition(), entity.GetWorldPosition() );
		
		mpac = (CMovingPhysicalAgentComponent)actor.GetMovingAgentComponent();
		if ( mpac )
		{
			distance -= mpac.GetCapsuleRadius();
		}
		
		return distance;		
	}


	function Distance2DBetweenCapsules( actor1 : CActor, actor2 : CActor ) : float
	{
		var distance 	: float;
		var mpac 		: CMovingPhysicalAgentComponent;
		
		distance = VecDistance2D( actor1.GetWorldPosition(), actor2.GetWorldPosition() );
		
		mpac = (CMovingPhysicalAgentComponent)actor1.GetMovingAgentComponent();
		if ( mpac )
		{
			distance -= mpac.GetCapsuleRadius();
		}
		
		mpac = (CMovingPhysicalAgentComponent)actor2.GetMovingAgentComponent();
		if ( mpac )
		{
			distance -= mpac.GetCapsuleRadius();
		}
		
		return distance;		
	}

	protected function ProcessSelectionWeights() : STargetSelectionWeights
	{
		var selectionWeights 			: STargetSelectionWeights;
		
		if ( ShouldUsePCModeTargeting() )
		{
			selectionWeights.angleWeight = 0.75f;
			selectionWeights.distanceWeight = 0.25f;
			selectionWeights.distanceRingWeight = 0.f;		
			return selectionWeights;		
		}
		
		if ( IsInCombatAction() && ( GetBehaviorVariable( 'combatActionType' ) == (int)CAT_Dodge || GetBehaviorVariable( 'combatActionType' ) == (int)CAT_Roll ) )
		{
			selectionWeights.angleWeight = 0.575f;
			selectionWeights.distanceWeight = 0.175f;
			selectionWeights.distanceRingWeight = 0.25f;
		}		
		if ( !lAxisReleasedAfterCounter || IsInCombatAction() ) // !bLAxisReleased ||
		{
			if ( theInput.GetActionValue( 'ThrowItem' ) == 1.f || ( rangedWeapon && rangedWeapon.GetCurrentStateName() != 'State_WeaponWait' ) )
			{
				selectionWeights.angleWeight = 1.f;
				selectionWeights.distanceWeight = 0.f;
				selectionWeights.distanceRingWeight = 0.f;	
			}
			else if ( !lAxisReleasedAfterCounter ) // !bLAxisReleased )
			{
				selectionWeights.angleWeight = 0.55f;//0.75f;
				selectionWeights.distanceWeight = 0.45f;//0.25f;
				selectionWeights.distanceRingWeight = 0.f;//0.3f;
			}
			else
			{
				selectionWeights.angleWeight = 0.75f;
				selectionWeights.distanceWeight = 0.25f;
				selectionWeights.distanceRingWeight = 0.f;//0.3f;			
			}
		}
		else if( !IsCurrentSignChanneled() )
		{
			selectionWeights.angleWeight = 0.35f;
			selectionWeights.distanceWeight = 0.65f;
			selectionWeights.distanceRingWeight = 0.f;		
		}
		else
		{
			selectionWeights.angleWeight = 0.275f;
			selectionWeights.distanceWeight = 0.375f;
			selectionWeights.distanceRingWeight = 0.35f;		
		}
		
		return selectionWeights;	
	}
	
	protected function CalcSelectionPriority( target : CEntity, selectionWeights : STargetSelectionWeights, sourcePosition : Vector, headingVector : Vector ) : float
	{
		var sourceToTarget				: Vector;
		var sourceToTargetDist			: float;
		var sourceToTargetAngleDiff		: float;
		var selectionPriority			: float;
		
		sourceToTarget = target.GetWorldPosition() - sourcePosition;
		sourceToTargetDist = VecLength2D( sourceToTarget );
		// normalize2D sourcetoTarget
		if ( sourceToTargetDist < 0.0001f )
		{
			sourceToTarget = Vector( 0.0f, 0.0f, 0.0f );
		}
		else
		{
			sourceToTarget *= ( 1.0f / sourceToTargetDist );
		}
		sourceToTargetAngleDiff = AbsF( Rad2Deg( AcosF( VecDot2D( sourceToTarget, headingVector ) ) ) );
		
		selectionPriority = ( selectionWeights.angleWeight * ( ( 180 - sourceToTargetAngleDiff ) / 180 ) );
		selectionPriority += selectionWeights.distanceWeight * ( ( softLockDist - sourceToTargetDist ) / softLockDist );	
		
		if ( sourceToTargetDist > 0.f  && sourceToTargetDist <= 6.f )
		{
			selectionPriority += selectionWeights.distanceRingWeight * 1.0f;	
		}
		else if ( sourceToTargetDist > 6.f  && sourceToTargetDist <= softLockDist )
		{
			selectionPriority += selectionWeights.distanceRingWeight * 0.4f;
		}	
		
		return selectionPriority;
	}

	protected function SetTarget( targetActor : CActor, optional forceSetTarget : bool )
	{
		var playerToTargetDistance 	: float;
		var target				 	: CActor;
		var allow					: bool;
		
		target = GetTarget();

		if ( !IsInNonGameplayCutscene() )
			allow = true;
		
		if ( allow )
		{
			if ( targetActor )
			{
				if ( ( targetActor.IsAlive() && !targetActor.IsKnockedUnconscious() ) || finishableEnemiesList.Contains( targetActor ) )
					allow = true;
				else
					allow = false;
			}
			else
				allow = true;		
		}
		
		if ( forceSetTarget )
			allow = true;
			
		if ( allow && target != targetActor )
			allow = true;
		else
			allow = false;
		
		if ( allow )
		{	
			SetPlayerTarget( targetActor );
			
			//playerToTargetDistance = VecDistance( GetWorldPosition(), targetActor.GetNearestPointInBothPersonalSpaces( GetWorldPosition() ) );
			//LogChannel( 'Targeting', "selection " + playerToTargetDistance );			
		}
	}

/*
	protected function SetTarget( targetActor : CActor, optional forceSetTarget : bool )
	{
		var playerToTargetDistance 	: float;
		var target				 	: CActor;
		//var gec : CGameplayEffectsComponent;
		
	
		if ( !IsInNonGameplayCutscene() 
			&& ( ( ( !targetActor || ( ( targetActor.IsAlive() || finishableEnemiesList.Contains( targetActor ) ) && !targetActor.IsKnockedUnconscious() ) ) && !IsActorLockedToTarget() ) || forceSetTarget ) ) 
		{	
			target = GetTarget();
		
			if ( target != targetActor )
			{
				if( target )
				{
					target.StopEffect( 'select_character' );	
					//gec = GetGameplayEffectsComponent( target );
					//if(gec)
					//	gec.SetGameplayEffectFlag( EGEF_OutlineTarget, 0 );
				}
					
				SetPlayerTarget( targetActor );
				target = targetActor;
				
				if(target)
				{		
					playerToTargetDistance = VecDistance( GetWorldPosition(), target.GetNearestPointInBothPersonalSpaces( GetWorldPosition() ) );
				}
				
				//LogChannel( 'Targeting', "selection " + playerToTargetDistance );				
			}
		}
	}
*/	
	public function SetSlideTarget( actor : CGameplayEntity )
	{
		//if ( slideTarget != actor && slideTarget )
		//	EnableCloseCombatCharacterRadius( false );

		slideTarget = actor;
		
		if ( slideTarget )
			SetPlayerCombatTarget((CActor)slideTarget);		
		else
			Log( "slideTarget = NULL" );
		
		if ( slideTarget == nonActorTarget )
			UpdateDisplayTarget( true, true );
		else
			UpdateDisplayTarget();
			
		ConfirmDisplayTargetTimer(0.f);
	}
	
	event OnForceSelectLockTarget()
	{
		ForceSelectLockTarget();
	}

	private function ForceSelectLockTarget()
	{
		var newMoveTarget 	: CActor;
		var target			: CActor;
	
		newMoveTarget = GetScreenSpaceLockTarget( GetDisplayTarget(), 180.f, 1.f, 90 );
		
		if ( !newMoveTarget )
			newMoveTarget = GetScreenSpaceLockTarget( GetDisplayTarget(), 180.f, 1.f, -90 );
			
		if ( newMoveTarget )
		{
			thePlayer.ProcessLockTarget( newMoveTarget );
			
			target = GetTarget();
			if ( target )
			{
				thePlayer.SetSlideTarget( target );
	
				if ( IsHardLockEnabled() ) 
					thePlayer.HardLockToTarget( true );	
			}
		}
		else 
		{
			thePlayer.HardLockToTarget( false );			
		}	
	}
	
	public function SetFinisherVictim( actor : CActor )
	{
		finisherVictim = actor;
	}
	
	public function GetFinisherVictim() : CActor 
	{
		return finisherVictim;
	}	
	
	protected function SetNonActorTarget( actor : CGameplayEntity )		
	{ 
		if ( nonActorTarget != actor )
		nonActorTarget = actor;
	}

	timer function DisableTargetHighlightTimer( time : float , id : int)
	{
		var target : CActor;
		target = GetTarget();
		
		if( target )
		{
			target.StopEffect( 'select_character' );
		}
	}

	public function WasVisibleInScaledFrame( entity : CEntity, frameSizeX : float, frameSizeY : float ) : bool
	{
		var position				: Vector;
		var positionFound			: bool;
		var inFront					: bool;
		var x, y					: float;
		var boneIndex				: int;
		var actor					: CActor;
		var gameplayEntity			: CGameplayEntity;
		var gameplayEntityMatrix	: Matrix;
		var drawableComp			: CDrawableComponent;	
		var box 					: Box;
		var ok						: bool;
			
		if ( !entity )
		{
			return false;
		}
		if ( frameSizeX <= 0.0f && frameSizeY <= 0.0f )
		{
			LogChannel( 'WasVisibleInScaledFrame', "ERROR: WasVisibleInScaledFrame: frameSizeX && frameSizeY are both negative!!!" );
			return false;
		}

		if ( useNativeTargeting )
		{
			return targeting.WasVisibleInScaledFrame( entity, frameSizeX, frameSizeY );
		}
	
		position = entity.GetWorldPosition();
	
		actor = (CActor)entity;
		if ( actor )
		{
			boneIndex = entity.GetBoneIndex( 'pelvis' );
			if ( boneIndex == -1 )
			{
				boneIndex = entity.GetBoneIndex( 'k_pelvis_g' ); // not hack at all. DONE !*100000000000000000000
			}
				
			if ( boneIndex != -1 )
			{
				position = MatrixGetTranslation( entity.GetBoneWorldMatrixByIndex( boneIndex ) );
			}
			else
			{
				position = entity.GetWorldPosition();
				position.Z += ( (CMovingPhysicalAgentComponent)actor.GetMovingAgentComponent() ).GetCapsuleHeight() * 0.5;
			}
			positionFound = true;
		}
		else
		{
			gameplayEntity = (CGameplayEntity)entity;
			if ( gameplayEntity && !( gameplayEntity.aimVector.X == 0 && gameplayEntity.aimVector.Y == 0 && gameplayEntity.aimVector.Z == 0 ) )
			{
				gameplayEntityMatrix = gameplayEntity.GetLocalToWorld();				
				position = VecTransform( gameplayEntityMatrix, gameplayEntity.aimVector );
				positionFound = true;
			}
		}
		
		// if still not found proper position for test
		if  ( !positionFound )
		{
			drawableComp = (CDrawableComponent)entity.GetComponentByClassName( 'CDrawableComponent' );
			if ( drawableComp && drawableComp.GetObjectBoundingVolume( box ) )
			{
				position.Z += ( ( box.Max.Z - box.Min.Z ) * 0.66f );		
			}
		}
		
		inFront = theCamera.WorldVectorToViewRatio( position, x, y );
		if ( !inFront )
		{
			return false;
		}
		x = AbsF( x );
		y = AbsF( y );
	
		ok = true;
		ok = ok && ( frameSizeX <= 0.0f || x < frameSizeX );
		ok = ok && ( frameSizeY <= 0.0f || y < frameSizeY );
	
		return ok;
	}	

	public function HardLockToTarget( flag : bool )
	{
		if( flag && GetTarget().HasTag( 'NoHardLock' ) )
			return;
			
		EnableHardLock( flag );
		LockToTarget( flag );
	}

	public function LockToTarget( flag : bool )
	{
		if ( IsHardLockEnabled() && !flag )
			return;
			
		LockCameraToTarget( flag );
		LockActorToTarget( flag );
	}

	public function LockCameraToTarget( flag : bool )
	{
		if ( flag && !IsCameraLockedToTarget() )
		{
			thePlayer.EnableManualCameraControl( false, 'LockCameraToTarget' );
			//((CCustomCamera)theCamera.GetTopmostCameraObject()).EnableManualControl( false );
			SetIsCameraLockedToTarget( flag );
		}
		else if ( !flag && IsCameraLockedToTarget() )
		{
			thePlayer.EnableManualCameraControl( true, 'LockCameraToTarget' );
			//((CCustomCamera)theCamera.GetTopmostCameraObject()).EnableManualControl( true );
			SetIsCameraLockedToTarget( flag );
		}
	}
	
	public function LockActorToTarget( flag : bool, optional withoutIcon : bool )
	{
		var displayTargetActor : CActor;
	
		if ( flag )
		{		
			if ( !IsActorLockedToTarget() )
			{
				//SetSlideTarget( target );	
				SetIsActorLockedToTarget( flag );
				SetMoveTargetChangeAllowed( true );
				SetMoveTarget( GetTarget() );
				SetMoveTargetChangeAllowed( false );
				SetTarget( GetTarget() );
				SetSlideTarget( GetTarget() );
				AddTimer( 'CheckLockTargetIsAlive', 0.5, true );
			}
			
			if ( IsActorLockedToTarget() )
			{
				displayTargetActor = (CActor)( GetDisplayTarget() );
				
				if ( displayTargetActor && IsThreat( displayTargetActor ) && !withoutIcon )
					EnableHardLockIcon( flag );	
			}
		}
		else if ( !flag && IsActorLockedToTarget() )
		{
			SetIsActorLockedToTarget( flag );
			SetMoveTargetChangeAllowed( true );			
			RemoveTimer( 'CheckLockTargetIsAlive' );
			EnableHardLockIcon( flag );
		}	
	}

	private function EnableHardLockIcon( flag : bool )
	{
		var hud : CR4ScriptedHud;
		var module : CR4HudModuleEnemyFocus;
		
		if( GetTarget().HasTag( 'NoHardLockIcon' ) )
			return;

		hud = (CR4ScriptedHud)theGame.GetHud();
		module = (CR4HudModuleEnemyFocus)hud.GetHudModule("EnemyFocusModule");
		module.SetShowHardLock( flag );
	}
	
	private timer function CheckLockTargetIsAlive( time : float , id : int)
	{
		var vitality	: float;
		var essence		: float;
		var actor 		: CActor;
		var target 		: CActor;
		
		target = (CActor)GetDisplayTarget();
	
		if( !target 
			|| !target.IsAlive() 
			|| ( !target.GetGameplayVisibility() ) 
			|| !CanBeTargetedIfSwimming( target ) 
			|| (!target.UsesVitality() && !target.UsesEssence()))
		{
			if ( !ProcessLockTarget() )
				HardLockToTarget( false );			
		}		
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////
	//
	// @Damage
	//
	//////////////////////////////////////////////////////////////////////////////////////////
	protected function PlayHitAnimation(damageAction : W3DamageAction, animType : EHitReactionType)
	{
		var hitRotation 	: float;
		var onHitCounter 	: SAbilityAttributeValue;
		var counter 		: int;
		
		if( damageAction.HasAnyCriticalEffect() )
			return;
		
		if( !substateManager.ReactOnBeingHit() && !IsUsingVehicle() )
		{
			return;
		}
		
		if ( damageAction.GetHitReactionType() == EHRT_Reflect )
			SetBehaviorVariable( 'isAttackReflected', 1.f );
		else
			SetBehaviorVariable( 'isAttackReflected', 0.f );
		
		SetBehaviorVariable( 'HitReactionType',(int)animType);
		SetBehaviorVariable( 'HitReactionWeapon', ProcessSwordOrFistHitReaction( this, (CActor)damageAction.attacker ) );
		
		if (damageAction.attacker)
		{
			super.PlayHitAnimation( damageAction, animType );
			if ( damageAction.attacker.HasAbility( 'IncreaseHitReactionSeverityWithHitCounter' ) )
			{
				counter = GetHitCounter();
				switch ( counter )
				{
					case 2 :						
						SetBehaviorVariable( 'HitReactionType', 2 );
						break;
					
					case 3 :						
						AddEffectDefault( EET_Stagger, damageAction.attacker, damageAction.attacker.GetName() );
						break;
					
					case 4 :						
						AddEffectDefault( EET_Knockdown, damageAction.attacker, damageAction.attacker.GetName() );
						break;
					
					default : 
						break;
				}
			}
			SetHitReactionDirection(damageAction.attacker);
			SetDetailedHitReaction(damageAction.GetSwingType(), damageAction.GetSwingDirection());
		}
		
		RaiseForceEvent( 'Hit' );
		theGame.GetBehTreeReactionManager().CreateReactionEventIfPossible( this, 'ActorInHitReaction', -1, 30.0f, -1.f, -1, true ); //reactionSystemSearch
		
		if ( IsUsingBoat() )
		{
			SoundEvent("cmb_play_hit_light");
			return;
		}
		
		if ( IsUsingVehicle() )
			return;
		
		if(damageAction.attacker)
		{
			hitRotation = VecHeading( damageAction.attacker.GetWorldPosition() - GetWorldPosition() );
			if ( this.GetBehaviorVariable( 'HitReactionDirection' ) == (float)( (int)EHRD_Back ) )
				hitRotation += 180.f;
		
			//GetVisualDebug().AddArrow( 'temp', GetWorldPosition(), GetWorldPosition() + VecFromHeading( hitRotation )*2, 1.f, 0.2f, 0.2f, true, Color(0,255,255), true, 5.f );
			SetCustomRotation( 'Hit', hitRotation, 1080.f, 0.1f, false );
		}
		
		CriticalEffectAnimationInterrupted("PlayHitAnimation");
	}
	
	public function ReduceDamage( out damageData : W3DamageAction)
	{
		super.ReduceDamage(damageData);
		
		//halve damage if from your own bomb
		if(damageData.attacker == this && (damageData.GetBuffSourceName() == "petard" || (W3Petard)damageData.causer) )
		{
			if ( theGame.CanLog() )
			{
				LogDMHits("CR4Player.ReduceDamage: hitting self with own bomb - damage reduced by 50%", damageData );
			}
			damageData.processedDmg.vitalityDamage = damageData.processedDmg.vitalityDamage / 2;
			damageData.processedDmg.essenceDamage = damageData.processedDmg.essenceDamage / 2;
		}
	}
	
	//crit hit chance 0-1
	public function GetCriticalHitChance( isLightAttack : bool, isHeavyAttack : bool, target : CActor, victimMonsterCategory : EMonsterCategory, isBolt : bool ) : float
	{
		var critChance : float;
		var oilChanceAttribute : name;
		var weapons : array< SItemUniqueId >;
		var i : int;
		var holdsCrossbow : bool;
		var critVal : SAbilityAttributeValue;
		
		critChance = 0;
		
		//cheats
		if( FactsQuerySum( 'debug_fact_critical_boy' ) > 0 )
		{
			critChance += 1;
		}
		
		if( IsInState( 'HorseRiding' ) && ( ( CActor )GetUsedVehicle() ).GetMovingAgentComponent().GetRelativeMoveSpeed() >= 4.0 )
		{
			critChance += 1;
		}
		
		//normal case
		critChance += CalculateAttributeValue( GetAttributeValue( theGame.params.CRITICAL_HIT_CHANCE ) );
		
		//fix cases when we calculate change for crossbow but have sword bonus and vice-versa
		weapons = inv.GetHeldWeapons();
		for( i=0; i<weapons.Size(); i+=1 )
		{			
			holdsCrossbow = ( inv.IsItemCrossbow( weapons[i] ) || inv.IsItemBolt( weapons[i] ) );
			if( holdsCrossbow != isBolt )
			{
				critVal = inv.GetItemAttributeValue( weapons[i], theGame.params.CRITICAL_HIT_CHANCE );
				critChance -= CalculateAttributeValue( critVal );
			}			
		}
		
		//active skills bonus
		if( isHeavyAttack && CanUseSkill( S_Sword_s08 ) )
		{
			critChance += CalculateAttributeValue( GetSkillAttributeValue( S_Sword_s08, theGame.params.CRITICAL_HIT_CHANCE, false, true ) ) * GetSkillLevel( S_Sword_s08 );
		}
		else if( isLightAttack && CanUseSkill( S_Sword_s17 ) )
		{
			critChance += CalculateAttributeValue( GetSkillAttributeValue( S_Sword_s17, theGame.params.CRITICAL_HIT_CHANCE, false, true ) ) * GetSkillLevel( S_Sword_s17 );
		}
	
		if( target && target.HasBuff( EET_Confusion ) )
		{
			critChance += ( ( W3ConfuseEffect )target.GetBuff( EET_Confusion ) ).GetCriticalHitChanceBonus();
		}
		
		//oils
		oilChanceAttribute = MonsterCategoryToCriticalChanceBonus( victimMonsterCategory );
		if( IsNameValid( oilChanceAttribute ) )
		{
			critChance += CalculateAttributeValue( GetAttributeValue( oilChanceAttribute ) );
		}
	
		return critChance;
	}
	
	//gets damage bonus for critical hit
	public function GetCriticalHitDamageBonus(weaponId : SItemUniqueId, victimMonsterCategory : EMonsterCategory, isStrikeAtBack : bool) : SAbilityAttributeValue
	{
		var bonus, oilBonus : SAbilityAttributeValue;
		var vsAttributeName : name;
	
		bonus = super.GetCriticalHitDamageBonus(weaponId, victimMonsterCategory, isStrikeAtBack);
		
		//oil bonus		
		if( inv.ItemHasActiveOilApplied( weaponId, victimMonsterCategory ) )
		{
			vsAttributeName = MonsterCategoryToCriticalDamageBonus(victimMonsterCategory);
			oilBonus = inv.GetItemAttributeValue(weaponId, vsAttributeName);
			bonus += oilBonus;
		}
		
		return bonus;
	}
	
	/**
		Called when we want to play hit animation
	*/	
	public function ReactToBeingHit(damageAction : W3DamageAction, optional buffNotApplied : bool) : bool
	{
		var strength 	: float;
		var animType 	: EHitReactionType;
		var sup 		: bool;
		var boat : CBoatComponent;
		var combatActionType : int;
		var attackAction : W3Action_Attack;
		var npc : CNewNPC;
		var shakeCam : bool;
		
		attackAction = (W3Action_Attack)damageAction;
		//not parried, not countered, not dot, not dodged
		if(!damageAction.IsDoTDamage() && (!attackAction || (!attackAction.IsParried() && !attackAction.IsCountered() && !attackAction.WasDodged()) ) )
		{
			npc = (CNewNPC)attackAction.attacker;
			if(npc && npc.IsHeavyAttack(attackAction.GetAttackName()))
				theGame.VibrateControllerVeryHard();//player got heavy hit
			else
				theGame.VibrateControllerHard();//player got hit
		}
		
		if ( (CActor)GetUsedVehicle() && this.playerAiming.GetCurrentStateName() == 'Aiming' )
		{
			OnRangedForceHolster( true, true );
		}
		
		combatActionType = (int)GetBehaviorVariable( 'combatActionType' );
		
		if ( thePlayer.IsCurrentlyDodging() && ( combatActionType == (int)CAT_Roll || combatActionType == (int)CAT_CiriDodge ) )
			sup = false;
		else if ( this.GetCurrentStateName() == 'DismountHorse' )
			sup = false;
		else
			sup = super.ReactToBeingHit(damageAction, buffNotApplied);
		sup = false;
		//telemetry
		if(damageAction.attacker)
			theTelemetry.LogWithLabelAndValue( TE_FIGHT_HERO_GETS_HIT, damageAction.attacker.ToString(), (int)damageAction.processedDmg.vitalityDamage );
		
		//camera shake
		if(damageAction.DealsAnyDamage())
		{
			if( ((W3PlayerWitcher)this) && GetWitcherPlayer().IsAnyQuenActive() && damageAction.IsDoTDamage())
			{
				shakeCam = false;
			}
			else
			{
				shakeCam = true;
			}
			
			if(shakeCam)
			{
				animType = ModifyHitSeverityReaction(this, damageAction.GetHitReactionType());
			
				if(animType == EHRT_Light || animType == EHRT_LightClose)
					strength = 0.1;
				else if(animType == EHRT_Heavy || animType == EHRT_Igni)
					strength = 0.2;
				
				GCameraShakeLight(strength, false, GetWorldPosition(), 10.0);
			}
			
			this.HitReactionEffect( 0.25 );
			
			//reset uninterrupted hits
			ResetUninterruptedHitsCount();
		}
				
		//pause health regen
		if(!damageAction.IsDoTDamage() && IsThreatened() && ShouldPauseHealthRegenOnHit() && damageAction.DealsAnyDamage() && !damageAction.WasDodged() && attackAction.CanBeParried() && !attackAction.IsParried())
		{
			PauseHPRegenEffects('being_hit', theGame.params.ON_HIT_HP_REGEN_DELAY);
		}
	
		//if player is on a boat and not moving then force dismount
		/*if(usedVehicle)
		{
			boat = (CBoatComponent) usedVehicle.GetComponentByClassName('CBoatComponent');
			if(boat && boat.GetLinearVelocityXY() < boat.IDLE_SPEED_THRESHOLD)
			{
				boat.StopAndDismountBoat();
			}
		}*/
		
		//finesse achievement fail
		if(damageAction.processedDmg.vitalityDamage > 0 && !((W3Effect_Toxicity)damageAction.causer))
			ReceivedCombatDamage();
		
		//tutorial
		if(FactsQuerySum("tut_fight_use_slomo") > 0)
		{
			theGame.RemoveTimeScale( theGame.GetTimescaleSource(ETS_TutorialFight) );
			FactsRemove("tut_fight_slomo_ON");
		}
		
		// State
		if( !substateManager.ReactOnBeingHit( damageAction ) )
		{
			GoToCombatIfNeeded();
			//PushState( 'CombatFists' );
		}
		
		return sup;
	}
	
	protected function ShouldPauseHealthRegenOnHit() : bool
	{
		return true;
	}
	
	public function PlayHitEffect(damageAction : W3DamageAction)
	{
		super.PlayHitEffect(damageAction);

		//fullscreen hit fx
		if(damageAction.DealsAnyDamage() && !damageAction.IsDoTDamage())
			PlayEffect('hit_screen');
	}
	
	function HitReactionEffect( interval : float )
	{
		if ( hitReactionEffect )
		{
			PlayEffect( 'radial_blur' );
			hitReactionEffect = false;
		}
		else
		{
			AddTimer( 'HitReactionEffectCooldown', interval, false );
		}
	}
	
	timer function HitReactionEffectCooldown( td : float , id : int)
	{
		hitReactionEffect = true;
	}
	//////////////////////////////////////////////////////////////////////////////////////////
	//
	// @Parry
	//
	//////////////////////////////////////////////////////////////////////////////////////////
	
	function PerformParryCheck( parryInfo : SParryInfo) : bool
	{
		var mult 					: float;
		var parryType 				: EParryType;
		var parryDir 				: EPlayerParryDirection;
		var parryHeading			: float;
		var fistFightParry 			: bool;
		var action					: W3DamageAction;
		var xmlStaminaDamage 		: float;
		var xmlStaminaDamageName	: name = 'stamina_damage' ;
		var counter 				: int;
		var onHitCounter 			: SAbilityAttributeValue;
		
//		if ( !parryInfo.canBeParried )
//			return false;
		
		if(CanParryAttack() && /*parryInfo.targetToAttackerAngleAbs < theGame.params.PARRY_HALF_ANGLE &&*/ FistFightCheck( parryInfo.target, parryInfo.attacker, fistFightParry ) )
		{	
			parryHeading = GetParryHeading( parryInfo, parryDir ) ;
			//GetVisualDebug().AddArrow( 'CombatActionHeading', GetWorldPosition(), GetWorldPosition() + VecFromHeading( GetParryHeading( parryInfo, parryDir ) )*2, 1.f, 0.2f, 0.2f, true, Color(0,255,255), true, 5.f );
			SetBehaviorVariable( 'parryDirection', (float)( (int)( parryDir ) ) );
			SetBehaviorVariable( 'parryDirectionOverlay', (float)( (int)( parryDir ) ) );
			SetBehaviorVariable( 'parryType', ChooseParryTypeIndex( parryInfo ) );
			
			if ( IsInCombatActionFriendly() )
				RaiseEvent('CombatActionFriendlyEnd');
			
			if ( HasStaminaToParry(parryInfo.attackActionName) )
			{
				this.SetBehaviorVariable( 'combatActionType', (int)CAT_Parry );
				
				if ( parryInfo.targetToAttackerDist > 3.f && !bLAxisReleased && !thePlayer.IsCiri() )
				{
					if ( !RaiseForceEvent( 'PerformParryOverlay' ) )
						return false;
					else
					{
						ClearCustomOrientationInfoStack();
						IncDefendCounter();
					}
				}
				else
				{
					counter = GetDefendCounter();
					onHitCounter = parryInfo.attacker.GetAttributeValue( 'break_through_parry_on_hit_counter' );
					if ( onHitCounter.valueBase > 0 && counter == onHitCounter.valueBase )
					{
						AddEffectDefault( EET_Stagger, parryInfo.attacker, "Break through parry" );
					}
					else if ( RaiseForceEvent( 'PerformParry' ) )
					{
						OnCombatActionStart();
						ClearCustomOrientationInfoStack();
						SetSlideTarget( parryInfo.attacker );
						SetCustomRotation( 'Parry', parryHeading, 1080.f, 0.1f, false );
						IncDefendCounter();
					}
					else
						return false;
				}
			}
			else
			{
				AddEffectDefault(EET_Stagger, parryInfo.attacker, "Parry");
				return true;
			}
			//parryTarget := this
			if ( parryInfo.attacker.IsWeaponHeld( 'fist' ) && !parryInfo.target.IsWeaponHeld( 'fist' ) )
			{
				parryInfo.attacker.ReactToReflectedAttack(parryInfo.target);
			}
			else 
			{
				if ( this.IsInFistFightMiniGame() && fistFightParry )
				{
					if ( IsNameValid(xmlStaminaDamageName) )
					{
						xmlStaminaDamage = CalculateAttributeValue(parryInfo.attacker.GetAttributeValue( xmlStaminaDamageName ));
						DrainStamina(ESAT_FixedValue, xmlStaminaDamage);
					}
				}
				else
				{
					DrainStamina(ESAT_Parry, 0, 0, '', 0, mult);
				}
				if(IsLightAttack(parryInfo.attackActionName))
					parryInfo.target.PlayEffectOnHeldWeapon('light_block');
				else
					parryInfo.target.PlayEffectOnHeldWeapon('heavy_block');
			}
			return true;
		}			
		
		return false;
	}
		
	protected function GetParryHeading( parryInfo : SParryInfo, out parryDir : EPlayerParryDirection ) : float
	{
		var targetToAttackerHeading 		: float;
		var currToTargetAttackerAngleDiff	: float;
	
		targetToAttackerHeading = VecHeading( parryInfo.attacker.GetWorldPosition() - parryInfo.target.GetWorldPosition() );
		currToTargetAttackerAngleDiff = AngleDistance( VecHeading( parryInfo.target.GetHeadingVector() ), targetToAttackerHeading );
		
		if ( !parryInfo.target.IsWeaponHeld( 'fist' ) )
		{
			if( currToTargetAttackerAngleDiff > -45 && currToTargetAttackerAngleDiff < 45  )
			{
				parryDir = PPD_Forward;
				return targetToAttackerHeading;
			}
			else if( currToTargetAttackerAngleDiff >= 45 && currToTargetAttackerAngleDiff < 135 )
			{
				parryDir = PPD_Right;
				//return targetToAttackerHeading;
				return targetToAttackerHeading + 90;
			}
			else if( currToTargetAttackerAngleDiff <= -45 && currToTargetAttackerAngleDiff > -135 )
			{
				parryDir = PPD_Left;
				//return targetToAttackerHeading;
				return targetToAttackerHeading - 90;
			}
			else
			{
				parryDir = PPD_Back;
				//return targetToAttackerHeading;
				return targetToAttackerHeading + 180;
			}
		}
		else
 		{
			if( currToTargetAttackerAngleDiff > -45 && currToTargetAttackerAngleDiff < 45  )
			{
				parryDir = PPD_Forward;
				return targetToAttackerHeading;
			}
			else if( currToTargetAttackerAngleDiff >= 45 && currToTargetAttackerAngleDiff < 180 )
			{
				parryDir = PPD_Right;
				return targetToAttackerHeading + 90;	
			}
			else if( currToTargetAttackerAngleDiff <= -45 && currToTargetAttackerAngleDiff >= -180 )
			{
				parryDir = PPD_Left;
				return targetToAttackerHeading - 90;	
			}
			else
			{
				parryDir = PPD_Back;
				return targetToAttackerHeading + 180;	
			}	
		}
	}
	
	function ProcessLockTarget( optional newLockTarget : CActor, optional checkLeftStickHeading : bool ) : bool
	{
		var attackerNearestPoint		: Vector;
		var playerNearestPoint			: Vector;
		var incomingAttacker 			: CActor;
		var tempLockTarget				: CActor;
		var target						: CActor;
		var useIncomingAttacker			: bool;
		
		if( newLockTarget.HasTag( 'NoHardLock' ) )
			return false;

		if ( newLockTarget )
			tempLockTarget = newLockTarget;
		else
		{
			incomingAttacker = GetClosestIncomingAttacker();
			if ( incomingAttacker && incomingAttacker.IsAlive()  && IsUsingVehicle() )
			{	
				tempLockTarget = incomingAttacker;
				useIncomingAttacker = false;
			}
			
			if ( !useIncomingAttacker )
			{
				target = GetTarget();
				if( target.HasTag('ForceHardLock'))
				{
					return true;
				}
				else if ( target && target.IsAlive() && target.GetGameplayVisibility() && IsEnemyVisible( target ) && IsThreat( target ) && CanBeTargetedIfSwimming( target ) )
					tempLockTarget = FindTarget();
				else 
				{
					tempLockTarget = GetScreenSpaceLockTarget( GetDisplayTarget(), 180.f, 1.f, 0.f );
				}
			}
		}
		
		if( tempLockTarget.HasTag( 'NoHardLock' ) )
			return false;
		
		if ( tempLockTarget )
		{
			if ( IsCombatMusicEnabled() || hostileEnemies.Size() > 0 )
			{
				if ( !IsThreat( tempLockTarget ) )
					tempLockTarget = NULL;
			}
		}	
		
		SetTarget( tempLockTarget, true );
		SetMoveTargetChangeAllowed( true );
		SetMoveTarget( tempLockTarget );
		SetMoveTargetChangeAllowed( false );
		SetSlideTarget( tempLockTarget );
		
		if ( tempLockTarget )
		{
			if ( this.IsActorLockedToTarget() )
				EnableHardLockIcon( true );	
			
			return true;
		}	
		else
			return false;
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////  @COMBAT  ///////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////////////////////////////	
	
	event OnTaskSyncAnim( npc : CNewNPC, animNameLeft : name ) {}
	
	//checks if player is doing special attack light/heavy
	public function IsDoingSpecialAttack(heavy : bool) : bool
	{
		var pat : EPlayerAttackType;
		
		if(IsInCombatAction() && ( (int)GetBehaviorVariable('combatActionType')) == CAT_SpecialAttack)
		{
			pat = (int)GetBehaviorVariable('playerAttackType');
			
			if(heavy && pat == PAT_Heavy)
			{
				return true;
			}
			else if(!heavy && pat == PAT_Light)
			{
				return true;
			}
		}
		
		return false;
	}
	
	public function SetIsCurrentlyDodging(enable : bool, optional isRolling : bool)
	{
		super.SetIsCurrentlyDodging(enable, isRolling);
		
		if ( isRolling )
		{
			SetCanPlayHitAnim( false );
			this.AddBuffImmunity( EET_KnockdownTypeApplicator, 'Roll', false );
			this.AddBuffImmunity( EET_Knockdown, 'Roll', false );
			this.AddBuffImmunity( EET_HeavyKnockdown, 'Roll', false );
			this.AddBuffImmunity( EET_Stagger, 'Roll', false );
		}
		else
		{
			SetCanPlayHitAnim( true );
			this.RemoveBuffImmunity( EET_KnockdownTypeApplicator, 'Roll' );
			this.RemoveBuffImmunity( EET_Knockdown, 'Roll' );
			this.RemoveBuffImmunity( EET_HeavyKnockdown, 'Roll' );
			this.RemoveBuffImmunity( EET_Stagger, 'Roll' );
		}
	}
	
	public function EnableHardLock( flag : bool )
	{
		super.EnableHardLock(flag);
		
		if(flag && ShouldProcessTutorial('TutorialTargettingWaiting'))
		{
			FactsAdd("tut_hardlocked");
		}
	}
		
	protected function TestParryAndCounter(data : CPreAttackEventData, weaponId : SItemUniqueId, out parried : bool, out countered : bool) : array<CActor>
	{
		var ret : array<CActor>;
	
		//cheat for QA tests - NPCs won't parry/counter
		if(FactsQuerySum('player_is_the_boss') > 0)
		{
			//----------------  DEBUG	
			//draw debug AR
			SetDebugAttackRange(data.rangeName);
			RemoveTimer('PostAttackDebugRangeClear');		//disable AR clearing since we've just set a new one
		
			return ret;
		}
		
		ret = super.TestParryAndCounter(data, weaponId, parried, countered);
		
		//achievement
		if(parried)
			theGame.GetGamerProfile().ResetStat(ES_CounterattackChain);
			
		return ret;
	}
		
	public function SetSpecialAttackTimeRatio(f : float)
	{
		LogSpecialHeavy(f);
		specialAttackTimeRatio = f;
	}
	
	public function GetSpecialAttackTimeRatio() : float
	{
		return specialAttackTimeRatio;
	}
	
	//called when we processed special heavy attack action - either from hit or from CombatActionEnd()
	public function OnSpecialAttackHeavyActionProcess()
	{
		//clear ration after attack performed
		SetSpecialAttackTimeRatio(0.f);
	}
	
	protected function DoAttack(animData : CPreAttackEventData, weaponId : SItemUniqueId, parried : bool, countered : bool, parriedBy : array<CActor>, attackAnimationName : name, hitTime : float)
	{
		var shakeStr : float;
		var weapon : EPlayerWeapon;
		var targetActor : CActor;
		
		//cam shake for player's heavy attacks		
		if ( animData.attackName == 'attack_heavy_special' )
		{
			if( specialAttackTimeRatio != 1 )
				shakeStr = (specialAttackTimeRatio / 3.333) + 0.2;
			else
				shakeStr = 0.5;	
	
			GCameraShake( shakeStr, false, GetWorldPosition(), 10);
		}
		else if ( IsHeavyAttack(attackActionName) )
		{
			if(parriedBy.Size() > 0)
				shakeStr = 0.2;
			else
				shakeStr = 0.1;
				
			GCameraShake(shakeStr, false, GetWorldPosition(), 10);
		}
		
		targetActor = (CActor)slideTarget;
		if ( targetActor && hitTargets.Contains(targetActor) )
		{
			weapon = this.GetMostConvenientMeleeWeapon(targetActor,true);
			if ( this.GetCurrentMeleeWeaponType() != PW_Fists && weapon != this.GetCurrentMeleeWeaponType() )
			{
				if ( weapon == PW_Steel )
				{
					thePlayer.OnEquipMeleeWeapon(PW_Steel,true);
				}
				else if ( weapon == PW_Silver )
				{
					thePlayer.OnEquipMeleeWeapon(PW_Silver,true);
				}
					
			}
		}
		
		super.DoAttack(animData, weaponId, parried, countered, parriedBy, attackAnimationName, hitTime);
	}
	
	//var delayCombatStanceTimeStamp : float;
	
	private var confirmCombatStanceTimeStamp : float;
	private var isConfirmingCombatStance : bool;
	final function SetPlayerCombatStance(stance : EPlayerCombatStance, optional force : bool )
	{
		var stanceInt : int;
	
		if ( !CanChangeCombatStance( stance, force ) )
			return;
		
		combatStance = stance;
		stanceInt = (int)stance;
		
		SetBehaviorVariable( 'playerCombatStance' , (float)stanceInt);
		SetBehaviorVariable( 'playerCombatStanceForOverlay' , (float)stanceInt);
		if ( force )
			SetBehaviorVariable( 'forceCombatStance' , 1.f);
		else
			SetBehaviorVariable( 'forceCombatStance' , 0.f);
			
		if ( stance == PCS_AlertNear )
			this.SetBehaviorVariable('isInCombatForOverlay',1.f);
		else
			this.SetBehaviorVariable('isInCombatForOverlay',0.f);
	}
	
	private function CanChangeCombatStance( stance : EPlayerCombatStance, optional force : bool ) : bool
	{
		var currTime : float;
		
		if ( force )
			return true;

		if ( IsInFistFightMiniGame() )
			return true;

		if ( isInHolsterAnim )
			return false;
		
		if ( ( combatStance ==  PCS_Normal || combatStance ==  PCS_AlertFar ) && stance == PCS_AlertNear )
		{
			currTime = theGame.GetEngineTimeAsSeconds();
			if ( !isConfirmingCombatStance )
			{		
				isConfirmingCombatStance = true;
				confirmCombatStanceTimeStamp = currTime;
				
				return false;
			}
			else if ( currTime < confirmCombatStanceTimeStamp + 1.f )
			{
				if (  stance == PCS_AlertNear )
					return false;
			}
			else
				isConfirmingCombatStance = false;
		}
		else
			isConfirmingCombatStance = false;

		return true;
	}
	
	private var isInHolsterAnim :  bool;
	event OnHolsterWeaponStart()
	{
		isInHolsterAnim = true;
	}
	
	event OnHolsterWeaponEnd()
	{
		isInHolsterAnim = false;		
	}	
	
	final function GetPlayerCombatStance() : EPlayerCombatStance
	{
		return combatStance;
	}
	
	timer function DelayedDisableFindTarget( time : float , id : int)
	{
		if ( GetTarget().IsAlive() )
		{
			EnableFindTarget( false );
		}
		else
		{
			EnableFindTarget( true );
		}		
	}
	
	///////////////////////////////////////////////////////////////////////////
	//  @BUFFER @COMBATACTIONBUFFER
	///////////////////////////////////////////////////////////////////////////
	
	private var dodgeTimerRunning : bool;
	
	function StartDodgeTimer()
	{
		dodgeTimerRunning = true;
		thePlayer.AddTimer('DodgeTimer',0.2,false);
	}
	
	function StopDodgeTimer()
	{
		this.RemoveTimer('DodgeTimer');
		dodgeTimerRunning = false;
	}
	
	function IsDodgeTimerRunning() : bool
	{
		return dodgeTimerRunning;
	}
	
	timer function DodgeTimer( dt : float, id : int )
	{
		dodgeTimerRunning = false;
	}
	
	public function EvadePressed( bufferAction : EBufferActionType )
	{
	}
	
	public function PerformingCombatAction() : EBufferActionType
	{
		return BufferCombatAction;
	}
	
	public function PushCombatActionOnBuffer( action : EBufferActionType, stage : EButtonStage, optional allSteps : bool )
	{
		BufferButtonStage = stage;
		BufferCombatAction = action;
		BufferAllSteps = allSteps;
	}
	
	protected function ProcessCombatActionHeading( action : EBufferActionType ) : float
	{
		var processedActionHeading 	: float;
	
		HandleMovement( 0.f );
	
		if ( ShouldUsePCModeTargeting() )
			return theGame.GetGameCamera().GetHeading();
	
		if ( lAxisReleasedAfterCounter ) // && IsInCombatAction() )
			ResetCachedRawPlayerHeading();
			
		processedActionHeading = cachedRawPlayerHeading;
			
		return processedActionHeading;
	}
	/*
	private function ProcessCombatActionHeading( action : EBufferActionType ) : float
	{
		var processedActionHeading 	: float;
		var unusedActor 			: CActor;	//MS: placeholder variable to fix memory error

		if ( IsUsingVehicle() )
		{
			processedActionHeading = theGame.GetGameCamera().GetHeading();
			return processedActionHeading;
		}

		if ( !bLAxisReleased || lAxisPushedTimeStamp + 0.5f > theGame.GetEngineTimeAsSeconds() )
			processedActionHeading = cachedRawPlayerHeading;
		else 
		{
			if ( GetDisplayTarget() )
			{
				if (  cachedCombatActionHeading == cachedRawPlayerHeading )
					ResetCachedRawPlayerHeading();
				else
				{
					cachedRawPlayerHeading = cachedCombatActionHeading;
					canResetCachedCombatActionHeading = true;
				}
	
				processedActionHeading = cachedRawPlayerHeading;	
			}
			else 
			{	
				if ( lAxisReleasedAfterCounterNoCA )
					ResetRawPlayerHeading();
					
				cachedRawPlayerHeading = rawPlayerHeading;	
			
				if ( lAxisReleasedAfterCounterNoCA )
					processedActionHeading = GetHeading();
				else
					processedActionHeading = cachedRawPlayerHeading;
			}
		}
		
		if ( this.IsCameraLockedToTarget() && this.IsActorLockedToTarget() && action != EBAT_Dodge && action != EBAT_Roll  )
			processedActionHeading = theGame.GetGameCamera().GetHeading();
			
		if ( lAxisReleasedAfterCounterNoCA  )
		{
			if ( action == EBAT_Dodge || action == EBAT_Roll )
			{
				if ( ( !IsEnemyInCone( this, GetHeadingVector(), softLockDist, 60.f, unusedActor ) || !IsEnemyInCone( this, GetHeadingVector() + 180, softLockDist, 60.f, unusedActor ) ) && moveTarget )
					processedActionHeading = VecHeading( moveTarget.GetWorldPosition() - GetWorldPosition() ) + 180;
				else 
					processedActionHeading = GetHeading() + 180;
			}
		}
			
		//GetVisualDebug().AddArrow( 'cachedRawPlayerHeading', GetWorldPosition(), GetWorldPosition() + VecFromHeading( cachedRawPlayerHeading ), 1.f, 0.2f, 0.2f, true, Color(0,255,128), true, 5.f );	
		//GetVisualDebug().AddArrow( 'CombatActionHeading', GetWorldPosition(), GetWorldPosition() + VecFromHeading( GetCombatActionHeading() )*2, 1.f, 0.2f, 0.2f, true, Color(0,255,255), true, 5.f );

		return processedActionHeading;
	}*/
	
	function ResetRawPlayerHeading()
	{		
		if ( GetDisplayTarget() )
			rawPlayerHeading = VecHeading( GetDisplayTarget().GetWorldPosition() - this.GetWorldPosition() );	
		else
			rawPlayerHeading = GetHeading();

		//LogChannel('ResetRawPlayerHeading',"ResetRawPlayerHeading" );
	}	
	
	function ResetCachedRawPlayerHeading()
	{
		cachedRawPlayerHeading = rawPlayerHeading;
		if ( GetDisplayTarget() && IsDisplayTargetTargetable() && AbsF( AngleDistance( VecHeading( GetDisplayTarget().GetWorldPosition() - this.GetWorldPosition() ), this.GetHeading() ) ) < 90.f )
			cachedRawPlayerHeading = VecHeading( GetDisplayTarget().GetWorldPosition() - this.GetWorldPosition() );	
		else
			cachedRawPlayerHeading = this.GetHeading();
			
		if ( canResetCachedCombatActionHeading )
			cachedCombatActionHeading = cachedRawPlayerHeading;	
	}		
	
	public function GetCombatActionTarget( action : EBufferActionType ) : CGameplayEntity
	{
		var selectedTargetableEntity	: CGameplayEntity;
	
		if (  !this.IsUsingVehicle() )
			selectedTargetableEntity = FindNonActorTarget( true, action );

		if ( selectedTargetableEntity )
		{
			return selectedTargetableEntity;
		}
		else
		{
			/*if ( !IsCombatMusicEnabled() && displayTarget )
			{
				if ( !( (CActor)displayTarget ) )
					return NULL;
				else
					return displayTarget;
			}*/
			
			if ( !this.IsUsingVehicle() )
				FindTarget( true, action, true );
			else
				((CR4PlayerStateUseGenericVehicle)this.GetState( 'UseGenericVehicle' )).FindTarget();

			return GetTarget();
		}
	}
	
	//MS: FindNonActorTarget may or may not have an interaction component, which is why it is separate from ProcessInteraction
	private function FindNonActorTarget( actionCheck : bool, optional action : EBufferActionType ) : CGameplayEntity
	{
		var targetableEntities			: array<CGameplayEntity>;
		var selectedTargetableEntity	: CGameplayEntity;
		var selectionPriority			: array< float >;
		var selectionWeights			: STargetSelectionWeights;
		var findEntityDist				: float;
		var i, size						: int;
		var playerHeading				: float;
		var playerInventory				: CInventoryComponent;
		var castSignType				: ESignType;
		var targetingInfo				: STargetingInfo;
		var playerPosition				: Vector;
		var cameraPosition				: Vector;
		var playerHeadingVector			: Vector;
		var rawPlayerHeadingVector		: Vector;
	
		playerPosition = this.GetWorldPosition();
		cameraPosition = theCamera.GetCameraPosition();
		rawPlayerHeadingVector = VecFromHeading( rawPlayerHeading );
	
		if ( bCanFindTarget && !IsHardLockEnabled() )
		{	
			if ( actionCheck && IsInCombat() && action == EBAT_CastSign )
			{
				findEntityDist = 6.f;
				selectionWeights.angleWeight = 0.375f;
				selectionWeights.distanceWeight = 0.275f;
				selectionWeights.distanceRingWeight = 0.35f;					
			}
			else if ( !IsInCombat() && lastAxisInputIsMovement )
			{
				findEntityDist = softLockDist;
				selectionWeights.angleWeight = 0.375f;
				selectionWeights.distanceWeight = 0.275f;
				selectionWeights.distanceRingWeight = 0.35f;				
			}
			else
			{
				findEntityDist = softLockDist;
				selectionWeights.angleWeight = 0.75f;
				selectionWeights.distanceWeight = 0.125f;
				selectionWeights.distanceRingWeight = 0.125f;					
			}

			//MSTODO : Ask programmers for filter for interactive entities
			if ( !IsInCombat() || !bLAxisReleased )
			{
				FindGameplayEntitiesInRange( targetableEntities, this, findEntityDist, 10, theGame.params.TAG_SOFT_LOCK );
			}	
			
			if ( targetableEntities.Size() > 0 )
			{
				playerInventory = this.GetInventory();
				castSignType = this.GetEquippedSign();
				
				if ( !bLAxisReleased )
				{
					targetingInfo.source 				= this;
					targetingInfo.canBeTargetedCheck	= false;
					targetingInfo.coneCheck 			= true;
					targetingInfo.coneHalfAngleCos		= 0.5f; // = CosF( Deg2Rad( 120.0f * 0.5f ) )
					targetingInfo.coneDist				= softLockDist;
					targetingInfo.coneHeadingVector		= rawPlayerHeadingVector; 
					targetingInfo.distCheck				= true;
					targetingInfo.invisibleCheck		= false;
					targetingInfo.navMeshCheck			= false; 
					targetingInfo.frameScaleX 			= 1.0f; 
					targetingInfo.frameScaleY 			= 1.0f; 
					targetingInfo.knockDownCheck 		= false; 
					targetingInfo.knockDownCheckDist 	= 0.0f; 
					targetingInfo.rsHeadingCheck 		= false;
					targetingInfo.rsHeadingLimitCos		= 1.0f;
				}
				
				for( i = targetableEntities.Size()-1; i>=0; i-=1 )
				{
					if ( bLAxisReleased )
					{
						if ( !lastAxisInputIsMovement )
						{
							if ( !WasVisibleInScaledFrame( targetableEntities[i], 0.9f, 0.9f ) )
							{
								targetableEntities.Erase(i);
								continue;
							}
						}
						else if ( !WasVisibleInScaledFrame( targetableEntities[i], 1.f, 1.f ) )
						{
							targetableEntities.Erase(i);
							continue;
						}
					}
					else
					{
						targetingInfo.targetEntity 			= targetableEntities[i];
						if ( actionCheck && moveTarget )
						{
							targetingInfo.inFrameCheck 			= false; 
							if ( !IsEntityTargetable( targetingInfo ) )
							{
								targetableEntities.Erase(i);
								continue;
							}
						}
						else
						{
							targetingInfo.inFrameCheck 			= true; 
							if ( !IsEntityTargetable( targetingInfo ) )
							{
								targetableEntities.Erase(i);	
								continue;
							}
						}
					}
					
					if ( actionCheck )
					{
						if ( action == EBAT_ItemUse )
						{
							if ( ( playerInventory.IsItemBomb( this.GetSelectedItemId() ) && !targetableEntities[i].HasTag( 'softLock_Bomb' ) )
								|| ( playerInventory.IsItemCrossbow( this.GetSelectedItemId() ) && !targetableEntities[i].HasTag( 'softLock_Bolt' ) ) )
							{
								targetableEntities.Erase(i);
								continue;
							}
						}	
						else if ( action == EBAT_CastSign )
						{
							if ( ( castSignType == ST_Aard && !targetableEntities[i].HasTag( 'softLock_Aard' ) )
								|| ( castSignType == ST_Igni && !targetableEntities[i].HasTag( 'softLock_Igni' ) )
								|| ( castSignType == ST_Axii && !targetableEntities[i].HasTag( 'softLock_Axii' ) )
								|| castSignType == ST_Yrden 
								|| castSignType == ST_Quen )
							{
								targetableEntities.Erase(i);
								continue;
							}						
						}	
						else if ( action == EBAT_LightAttack || action == EBAT_HeavyAttack || action == EBAT_SpecialAttack_Heavy )
						{
							if ( ( IsWeaponHeld( 'fist' ) && !targetableEntities[i].HasTag( 'softLock_Fist' ) ) || ( !IsWeaponHeld( 'fist' ) && !targetableEntities[i].HasTag( 'softLock_Weapon' ) ) ) 
							{
								targetableEntities.Erase(i);
								continue;
							}
						}
						else
						{
							targetableEntities.Erase(i);
							continue;
						}
					}
				}
			}
			
			if ( targetableEntities.Size() > 0)
			{
				playerHeading = this.GetHeading();
				playerHeadingVector = this.GetHeadingVector();
				if  ( IsInCombat() )
				{
					for( i = 0; i < targetableEntities.Size(); i += 1 )
					{					
						if ( bLAxisReleased )
							selectionPriority.PushBack( CalcSelectionPriority( targetableEntities[i], selectionWeights, cameraPosition, rawPlayerHeadingVector ) );
						else
							selectionPriority.PushBack( CalcSelectionPriority( targetableEntities[i], selectionWeights, playerPosition, rawPlayerHeadingVector ) );
					}
					
					if ( selectionPriority.Size() > 0 )
						selectedTargetableEntity = targetableEntities[ ArrayFindMaxF( selectionPriority ) ];
				}
				else 
				{
					if ( bLAxisReleased )
					{
						if ( !lastAxisInputIsMovement )
						{
							for( i = 0; i < targetableEntities.Size(); i += 1 ) 
								selectionPriority.PushBack( CalcSelectionPriority( targetableEntities[i], selectionWeights, cameraPosition, rawPlayerHeadingVector ) );	
								
							if ( selectionPriority.Size() > 0 )
								selectedTargetableEntity = targetableEntities[ ArrayFindMaxF( selectionPriority ) ];		
						}
						else
						{
							if ( IsInCombatAction() )
								selectedTargetableEntity = nonActorTarget;
							else
							{
								for( i = 0; i < targetableEntities.Size(); i += 1 ) 
									selectionPriority.PushBack( CalcSelectionPriority( targetableEntities[i], selectionWeights, playerPosition, playerHeadingVector ) );
									
								if ( selectionPriority.Size() > 0 )
								{
									selectedTargetableEntity = targetableEntities[ ArrayFindMaxF( selectionPriority ) ];
									
									targetingInfo.source 				= this;
									targetingInfo.targetEntity 			= selectedTargetableEntity;
									targetingInfo.canBeTargetedCheck	= false;
									targetingInfo.coneCheck 			= true;
									targetingInfo.coneHalfAngleCos		= 0.0f; // = CosF( Deg2Rad( 180.0f * 0.5f ) )
									targetingInfo.coneDist				= softLockDist;
									targetingInfo.coneHeadingVector		= this.GetHeadingVector(); 
									targetingInfo.distCheck				= true;
									targetingInfo.invisibleCheck		= false;
									targetingInfo.navMeshCheck			= false; 
									targetingInfo.inFrameCheck 			= false; 
									targetingInfo.frameScaleX 			= 1.0f; 
									targetingInfo.frameScaleY 			= 1.0f; 
									targetingInfo.knockDownCheck 		= false; 
									targetingInfo.knockDownCheckDist 	= 0.0f; 
									targetingInfo.rsHeadingCheck 		= false;
									targetingInfo.rsHeadingLimitCos		= 1.0f;									
									
									if ( !IsEntityTargetable( targetingInfo ) )
										selectedTargetableEntity = NULL;
								}
							}	
						}
					}
					else
					{
						for( i = 0; i < targetableEntities.Size(); i += 1 ) 
							selectionPriority.PushBack( CalcSelectionPriority( targetableEntities[i], selectionWeights, playerPosition, rawPlayerHeadingVector ) );
						
						if ( selectionPriority.Size() > 0 )
							selectedTargetableEntity = targetableEntities[ ArrayFindMaxF( selectionPriority ) ];							
					}
				}
			}
			else
				selectedTargetableEntity = NULL;
		}	
		
		SetNonActorTarget( selectedTargetableEntity );
		return selectedTargetableEntity;
	}
	/*
	timer function IsItemUseInputHeld ( time : float , id : int)
	{	
		if ( GetBIsInputAllowed() 
			&& GetBIsCombatActionAllowed()
			&& IsActionAllowed( EIAB_Crossbow ) 
			&& inv.IsIdValid( GetSelectedItemId() )
			&& inv.IsItemCrossbow( GetSelectedItemId()En )
			&& rangedWeapon.GetCurrentStateName() == 'State_WeaponWait' )
		{
			SetIsAimingCrossbow( true );
			PushCombatActionOnBuffer( EBAT_ItemUse, BS_Pressed );
			ProcessCombatActionBuffer();
		}
		
		if ( theInput.GetActionValue( 'ThrowItem' ) == 0.f )
		{
			if ( GetBIsCombatActionAllowed() )
			{
				PushCombatActionOnBuffer( EBAT_ItemUse, BS_Pressed );
				ProcessCombatActionBuffer();
			}
				
			SetIsAimingCrossbow( false );
			RemoveTimer( 'IsItemUseInputHeld' );
		}
	}*/

	public function SetupCombatAction( action : EBufferActionType, stage : EButtonStage )
	{
		var weaponType : EPlayerWeapon;
		var canAttackTarget	: CGameplayEntity;
		var target : CActor;
		
		/*if( thePlayer.substateManager.GetStateCur() == 'Slide' )
		{
			return;
		}*/
		if ( !IsCombatMusicEnabled() )
		{
			SetCombatActionHeading( ProcessCombatActionHeading( action ) ); 
			FindTarget();
			UpdateDisplayTarget( true );
		}
		
		if ( displayTarget && IsDisplayTargetTargetable() )
			canAttackTarget = displayTarget;
		else if ( GetTarget() )
			canAttackTarget = GetTarget(); 
		else if( !target && IsCombatMusicEnabled() )
			canAttackTarget = moveTarget;			
			
		target = (CActor)canAttackTarget;		

		if ( !AllowAttack( target, action ) )
			return;
	
		if( ( action != EBAT_ItemUse ) && ( action != EBAT_CastSign ) )
		{
			weaponType = weaponHolster.GetCurrentMeleeWeapon();
			PrepareToAttack( target, action );
			
			//Do not automatically attack when drawing sword
			if ( weaponType != weaponHolster.GetCurrentMeleeWeapon() )
			{
				//Check if switching from PW_None to PW_Fists. If so, allow the attack
				if ( !( weaponType == PW_None && weaponHolster.GetCurrentMeleeWeapon() == PW_Fists ) )
					return;
			}
		}
		
		//geralt's special attack heavy
		if(action == EBAT_SpecialAttack_Heavy && !((W3ReplacerCiri)this) )
			thePlayer.SetAttackActionName(SkillEnumToName(S_Sword_s02));
		
		CriticalEffectAnimationInterrupted("SetupCombatAction " + action);
		PushCombatActionOnBuffer( action, stage );
		
		if( GetBIsCombatActionAllowed() )
		{
			ProcessCombatActionBuffer();
		}
	}
	
	public function AllowAttack( target : CActor, action : EBufferActionType ) : bool
	{
		var newTarget : CActor;
		var canAttackWhenNotInCombat : bool;
		var messageDisplayed	: bool;
		
		var itemId : SItemUniqueId;
		var isShootingCrossbow : bool;
		
		var isInCorrectState : bool;
		
		if ( target )
		{
			if ( target.IsTargetableByPlayer())
			{
				if ( !target.IsAttackableByPlayer() ) 
				{
					DisplayHudMessage(GetLocStringByKeyExt("panel_hud_message_cant_attack_this_target"));
					return false;				
				}
			}
		}
		
		if ( this.GetCurrentStateName() == 'Exploration' )
			isInCorrectState = true;
		
		if ( action == EBAT_ItemUse ) 
		{
			itemId = thePlayer.GetSelectedItemId();
			if ( inv.IsIdValid(itemId) && inv.IsItemCrossbow(itemId) )
				isShootingCrossbow = true;
				
			if ( !isInCorrectState )
			{
				if ( this.GetCurrentStateName() == 'AimThrow' && !isShootingCrossbow )
				{
					isInCorrectState = true;
				}
			}		
		}		
		
		if ( isInCorrectState  )
			canAttackWhenNotInCombat = thePlayer.CanAttackWhenNotInCombat( action, false, newTarget, target );
		
		if( !target )
		{
			if ( isInCorrectState )
			{
				SetCombatActionHeading( ProcessCombatActionHeading( action ) );
				target = newTarget;
			}
		}

		if ( isInCorrectState )
		{
			if ( !canAttackWhenNotInCombat )
			{				
				if ( DisplayCannotAttackMessage( target ) )
					messageDisplayed = true;
				else if ( ( action == EBAT_LightAttack || action == EBAT_HeavyAttack ) 
						&& !RaiseAttackFriendlyEvent( target ) )
					messageDisplayed = true;				
				else 
				{
					if ( !CanRaiseCombatActionFriendlyEvent( isShootingCrossbow ) )
						messageDisplayed = true;
				}
			}
			
			if ( messageDisplayed )
			{
				theInput.ForceDeactivateAction('ThrowItem');
				theInput.ForceDeactivateAction('ThrowItemHold');
				this.SignalGameplayEvent( 'FriendlyAttackAction' );
				return false;
			}
		}

		return true;
	}
	

	//returns true if processed
	public function ProcessCombatActionBuffer() : bool
	{
		var actionResult 		: bool;
		var action	 			: EBufferActionType			= this.BufferCombatAction;
		var stage	 			: EButtonStage 				= this.BufferButtonStage;
		var s					: SNotWorkingOutFunctionParametersHackStruct1;
		var allSteps 			: bool						= this.BufferAllSteps;

		if ( IsInCombatActionFriendly() )
		{
			RaiseEvent('CombatActionFriendlyEnd');
		}
		
		//Disable any npcs that are set to unpushable when Player performs another combat action
		if ( ( action != EBAT_SpecialAttack_Heavy && action != EBAT_ItemUse )
			|| ( action == EBAT_SpecialAttack_Heavy && stage == BS_Pressed ) 
			|| ( action == EBAT_ItemUse && stage != BS_Released )  )
		{
			GetMovingAgentComponent().GetMovementAdjustor().CancelAll();
			SetUnpushableTarget( NULL );
		}
		
		//if ( !( action == EBAT_Dodge && stage == BS_Pressed && IsInCombatAction() && GetBehaviorVariable( 'combatActionType' ) == (int)CAT_Dodge ) )
		if ( !( action == EBAT_Dodge || action == EBAT_Roll ) )
		{
			SetIsCurrentlyDodging(false);
		}
		//-- init	
		SetCombatActionHeading( ProcessCombatActionHeading( action ) );
		
		//theGame.GetSyncAnimManager().OnRemoveFinisherCameraAnimation();
		
		if ( action == EBAT_ItemUse && GetInventory().IsItemCrossbow( selectedItemId ) )
		{
			//stage == BS_Pressed && 
			if ( rangedWeapon 
				&& ( ( rangedWeapon.GetCurrentStateName() != 'State_WeaponShoot' && rangedWeapon.GetCurrentStateName() != 'State_WeaponAim' ) || GetIsShootingFriendly() ) )
			{
				SetSlideTarget( GetCombatActionTarget( action ) );
			}
		}
		else if ( !( ( action == EBAT_SpecialAttack_Heavy && stage == BS_Released ) || GetCurrentStateName() == 'AimThrow' ) )
		{
			SetSlideTarget( GetCombatActionTarget( action ) );
		}
		
		if( !slideTarget )
			LogChannel( 'Targeting', "NO SLIDE TARGET" );
			
		//-- process
		actionResult = true;
		
		switch ( action )
		{
			case EBAT_EMPTY :
			{
				this.BufferAllSteps = false;
				return true;
			} break;
			
			case EBAT_LightAttack :
			{
				if ( IsCiri() )
					return false;
				
				switch ( stage )
				{
					case BS_Pressed ://BS_Released :
					{
						// early out, stamina drain etc
						//if( HasStaminaToUseAction(ESAT_LightAttack) )
						//{
						
							// replacing stamina lock with stamina drain - change in design
							/*
							s = LockStamina(ESAT_LightAttack);
							if(s.retValue)
							{
								AddCombatActionStaminaLock(s.outValue);
							}
							*/
							DrainStamina(ESAT_LightAttack);
							//target.SignalGameplayEventParamInt('Time2Dodge', (int)EDT_Attack );
							
							thePlayer.BreakPheromoneEffect();
							actionResult = OnPerformAttack(theGame.params.ATTACK_NAME_LIGHT);
						//}
					} break;
					
					default :
					{
						actionResult = false;
					}break;
				}
			}break;
			
			case  EBAT_HeavyAttack :
			{
				if ( IsCiri() )
					return false;
				
				switch ( stage )
				{
					case BS_Released :
					{
						// early out, stamina drain etc
						//if( HasStaminaToUseAction(ESAT_HeavyAttack) )
						//{
							// replacing stamina lock with stamina drain - change in design
							/*
							s = LockStamina(ESAT_HeavyAttack);
							if(s.retValue)
							{
								AddCombatActionStaminaLock(s.outValue);
							}
							*/
							DrainStamina(ESAT_HeavyAttack);
							
							//target.SignalGameplayEventParamInt('Time2Dodge', (int)EDT_Attack );
							
							thePlayer.BreakPheromoneEffect();		
							actionResult = this.OnPerformAttack(theGame.params.ATTACK_NAME_HEAVY);
						//}
					} break;
					
					case BS_Pressed :
					{
						if ( this.GetCurrentStateName() == 'CombatFists' )
						{
							// early out, stamina drain etc
							//if( HasStaminaToUseAction(ESAT_HeavyAttack) )
							//{
								// replacing stamina lock with stamina drain - change in design
								/*
								s = LockStamina(ESAT_HeavyAttack);
								if(s.retValue)
								{
									AddCombatActionStaminaLock(s.outValue);
								}
								*/
								DrainStamina(ESAT_HeavyAttack);
								
								//target.SignalGameplayEventParamInt('Time2Dodge', (int)EDT_Attack );
								
								thePlayer.BreakPheromoneEffect();		
								actionResult = this.OnPerformAttack(theGame.params.ATTACK_NAME_HEAVY);
							//}
						}
					} break;					
					
					default :
					{
						actionResult = false;
						
					} break;
				}
			} break;
			
			case EBAT_ItemUse :		//this gets called only for bombs. No usable items use this!
			{				
				switch ( stage )
				{
					case BS_Pressed :
					{
						if ( !( (W3PlayerWitcher)this ) || 
							( !IsInCombatActionFriendly() && !( !GetBIsCombatActionAllowed() && ( GetBehaviorVariable( 'combatActionType' ) == (int)CAT_Attack || GetBehaviorVariable( 'combatActionType' ) == (int)CAT_CastSign ) ) ) )						
							//( !IsCastingSign() && !IsInCombatActionFriendly() && !( !GetBIsCombatActionAllowed() && GetBehaviorVariable( 'combatActionType' ) == (int)CAT_Attack ) ) )
						{
							if ( inv.IsItemCrossbow( selectedItemId ) )
							{
								rangedWeapon = ( Crossbow )( inv.GetItemEntityUnsafe( selectedItemId ) );
								rangedWeapon.OnRangedWeaponPress();
								GetTarget().SignalGameplayEvent( 'Approach' );
								GetTarget().SignalGameplayEvent( 'ShootingCrossbow' );
							}
							else if(inv.IsItemBomb(selectedItemId) && this.inv.SingletonItemGetAmmo(selectedItemId) > 0 )
							{
								if( ((W3PlayerWitcher)this).GetBombDelay( ((W3PlayerWitcher)this).GetItemSlot( selectedItemId ) ) <= 0.0f )
								{
									BombThrowStart();
									GetTarget().SignalGameplayEvent( 'Approach' );
								}
							}
							else
							{
								DrainStamina(ESAT_UsableItem);
								UsableItemStart();				
							}
						}
						
					} if (!allSteps) break;
					
					case BS_Released:
					{
						if ( !( (W3PlayerWitcher)this ) || 
							( !IsInCombatActionFriendly() && ( GetBIsCombatActionAllowed() || !( !GetBIsCombatActionAllowed() && ( GetBehaviorVariable( 'combatActionType' ) == (int)CAT_Attack || GetBehaviorVariable( 'combatActionType' ) == (int)CAT_CastSign ) ) ) ) )						
							//( !IsCastingSign() && !IsInCombatActionFriendly() && !( !GetBIsCombatActionAllowed() && GetBehaviorVariable( 'combatActionType' ) == (int)CAT_Attack ) ) )
						{
							if ( inv.IsItemCrossbow( selectedItemId ) )
							{
								/*if ( rangedWeapon.GetCurrentStateName() == 'State_WeaponWait' )
								{
									rangedWeapon = ( Crossbow )( inv.GetItemEntityUnsafe( selectedItemId ) );
									rangedWeapon.OnRangedWeaponPress();
								}*/
								rangedWeapon.OnRangedWeaponRelease();
							}
							else if(inv.IsItemBomb(selectedItemId))
							{
								BombThrowRelease();
							}
							else						
							{
								UsableItemRelease();
							}
						}
					} break;
					
					default :
					{
						actionResult = false;
						break;
					}
				}
			} break;
			
			case EBAT_Dodge :
			{
				switch ( stage )
				{
					case BS_Released :
					{
						theGame.GetBehTreeReactionManager().CreateReactionEvent( this, 'PlayerEvade', 1.0f, 10.0f, -1.0f, -1 );
						thePlayer.BreakPheromoneEffect();
						actionResult = this.OnPerformEvade( PET_Dodge );
					} break;
					
					/*case BS_Pressed :
					{
						actionResult = this.OnPerformEvade( PET_Roll );
					} break;*/
					
					default :
					{
						actionResult = false;
					} break;
				}
			} break;
			
			case EBAT_Roll :
			{
				if ( IsCiri() )
					return false;
				
				switch ( stage )
				{
					case BS_Released :
					{
						theGame.GetBehTreeReactionManager().CreateReactionEvent( this, 'PlayerEvade', 1.0f, 10.0f, -1.0f, -1 );
						thePlayer.BreakPheromoneEffect();
						actionResult = this.OnPerformEvade( PET_Roll );
					} break;
					
					case BS_Pressed :
					{
						if ( this.GetBehaviorVariable( 'combatActionType' ) == 2.f )
						{
							if ( GetCurrentStateName() == 'CombatSteel' || GetCurrentStateName() == 'CombatSilver' )
								actionResult = this.OnPerformEvade( PET_Pirouette );
							else	
								actionResult = this.OnPerformEvade( PET_Roll );
						}
						else
						{
							if ( GetCurrentStateName() == 'CombatSteel' || GetCurrentStateName() == 'CombatSilver' )
							{
								actionResult = this.OnPerformEvade( PET_Dodge );
								actionResult = this.OnPerformEvade( PET_Pirouette );
							}
							else
							{
								actionResult = this.OnPerformEvade( PET_Dodge );
								actionResult = this.OnPerformEvade( PET_Roll );
							}
						}
						
						
					} break;
					
					default :
					{
						actionResult = false;
					} break;
				}
			} break;
			
			case EBAT_Draw_Steel :
			{
				switch ( stage )
				{
					case BS_Pressed :
					{
						if( !IsActionAllowed(EIAB_DrawWeapon) )
						{
							thePlayer.DisplayActionDisallowedHudMessage(EIAB_DrawWeapon);
							actionResult = false;
							break;
						}
						if( GetWitcherPlayer().IsItemEquippedByCategoryName( 'steelsword' ) )
						{
							OnEquipMeleeWeapon( PW_Steel, false, true );
						}
						
						actionResult = false;
						
					} break;
					
					default :
					{
						actionResult = false;
					} break;
				}
			} break;
			
			case EBAT_Draw_Silver :
			{
				switch ( stage )
				{
					case BS_Pressed :
					{
						if( !IsActionAllowed(EIAB_DrawWeapon) )
						{
							thePlayer.DisplayActionDisallowedHudMessage(EIAB_DrawWeapon);							
							actionResult = false;
							break;
						}
						if( GetWitcherPlayer().IsItemEquippedByCategoryName( 'silversword' ) )
						{
							OnEquipMeleeWeapon( PW_Silver, false, true );
						}
						
						actionResult = false;
						
					} break;
					
					default :
					{
						actionResult = false;
					} break;
				}
			} break;
			
			case EBAT_Sheathe_Sword :
			{
				switch ( stage )
				{
					case BS_Pressed :
					{
						if( GetCurrentMeleeWeaponType() == PW_Silver )
						{
							if( GetWitcherPlayer().IsItemEquippedByCategoryName( 'silversword' ) )
							{
								OnEquipMeleeWeapon( PW_Silver, false, true );
							}
						}
						else if( GetCurrentMeleeWeaponType() == PW_Steel )
						{
							if( GetWitcherPlayer().IsItemEquippedByCategoryName( 'steelsword' ) )
							{
								OnEquipMeleeWeapon( PW_Steel, false, true );
							}
						}
						
						actionResult = false;
						
					} break;
					
					default :
					{
						actionResult = false;
					} break;
				}
			} break;
			
			default:
				return false;	//not processed
		}

		//if here then buffer was processed
		CleanCombatActionBuffer();
		
		if (actionResult)
		{
			SetCombatAction( action ) ;
			
			if(GetWitcherPlayer().IsInFrenzy())
				GetWitcherPlayer().SkillFrenzyFinish(0);
		}
		
		return true;		
	}
	
	public function CleanCombatActionBuffer()
	{
		BufferCombatAction = EBAT_EMPTY;
		BufferAllSteps = false;
	}
	
	public function CancelHoldAttacks()
	{
		RemoveTimer( 'IsSpecialLightAttackInputHeld' );
		RemoveTimer( 'IsSpecialHeavyAttackInputHeld' );
		RemoveTimer( 'SpecialAttackLightSustainCost' );
		RemoveTimer( 'SpecialAttackHeavySustainCost' );
		RemoveTimer( 'UpdateSpecialAttackLightHeading' );
		UnblockAction( EIAB_Crossbow, 'SpecialAttack' );
		
		ResumeStaminaRegen('WhirlSkill');
		
		if ( GetBehaviorVariable( 'combatActionType' ) == (int)CAT_SpecialAttack && GetBehaviorVariable( 'isPerformingSpecialAttack' ) == 1.f )
		{
			if( GetBehaviorVariable( 'playerAttackType' ) == (int)PAT_Light )
			{	
				SetAttackActionName(SkillEnumToName(S_Sword_s01));
				PushCombatActionOnBuffer( EBAT_SpecialAttack_Light, BS_Released );
				ProcessCombatActionBuffer();		
				//SetupCombatAction( EBAT_SpecialAttack_Light, BS_Released );
				((W3PlayerWitcherStateCombatFists) GetState('Combat')).ResetTimeToEndCombat();
				
			}
			else if( GetBehaviorVariable( 'playerAttackType' ) == (int)PAT_Heavy )
			{	
				SetAttackActionName(SkillEnumToName(S_Sword_s02));
				PushCombatActionOnBuffer( EBAT_SpecialAttack_Heavy, BS_Released );
				ProcessCombatActionBuffer();
				//SetupCombatAction( EBAT_SpecialAttack_Heavy, BS_Released );
			}
		}
	}	
	
	public function RaiseAttackFriendlyEvent( actor : CActor ) : bool
	{
		var playerToTargetHeading : float;
	
		if ( actor && RaiseCombatActionFriendlyEvent() )
		{
			SetBehaviorVariable( 'tauntTypeForOverlay', 0.f );
			SetBehaviorVariable( 'combatActionTypeForOverlay', (int)CAT_Attack );
			
			if ( actor )
				actor.SignalGameplayEvent('PersonalTauntAction');
			theGame.GetBehTreeReactionManager().CreateReactionEventIfPossible( this, 'TauntAction', -1.0, 4.5f, -1, 9999, true ); //reactionSystemSearch						
		
			OnCombatActionStart();

			playerToTargetHeading = VecHeading( actor.GetWorldPosition() - GetWorldPosition() );

			SetCustomRotation( 'Attack', playerToTargetHeading, 0.0f, 0.3f, false );
			
			return true;
		}
		
		return false;
	}	
	
	public function SendAttackReactionEvent()
	{
		var reactionName : name;
		
		/*switch ( action )
		{
			case EBAT_LightAttack :
			reactionName = 'AttackAction';
			break;
			case EBAT_HeavyAttack :
			reactionName = 'AttackAction';
			break;
			case EBAT_SpecialAttack_Light :
			reactionName = 'AttackAction';
			break;
			case EBAT_SpecialAttack_Heavy :
			reactionName = 'AttackAction';
			break;
			case EBAT_Ciri_SpecialAttack :
			reactionName = 'AttackAction';
			break;
			default:
			return;
		}*/
		
		reactionName = 'AttackAction';
		
		if ( IsNameValid(reactionName) )
		{
			theGame.GetBehTreeReactionManager().CreateReactionEventIfPossible( this, reactionName, -1.0, 8.0f, -1, 5, true ); //reactionSystemSearch
		}
		
		// event for horse - trigger running away
		theGame.GetBehTreeReactionManager().CreateReactionEventIfPossible( this, 'outOfMyWay', -1.0, 2.0f, -1, 5, true ); //reactionSystemSearch
	}
	
	var forceCanAttackWhenNotInCombat : int; // 0 = NoForce, 1 = ForceWhenNoDisplayTarget 2 = ForceEvenWithDisplayTarget
	public function SetForceCanAttackWhenNotInCombat( forceMode : int )
	{
		forceCanAttackWhenNotInCombat = forceMode;
	}
	
	public function CanAttackWhenNotInCombat( actionType : EBufferActionType, altCast : bool, out newTarget : CActor, optional target : CGameplayEntity ) : bool
	{
		var localTargets					: array<CActor>;
		var i, size						: int;
		var inputHeading 				: float;
		var clearanceMin, clearanceMax	: float;
		var attackLength				: float;
		var attackAngle					: float;
		var npc							: CNewNPC;
		var canAttackTarget				: CGameplayEntity;
		var canAttackTargetActor		: CActor;
		
		if ( target )
			canAttackTarget = target;
		else if ( displayTarget && IsDisplayTargetTargetable() )
			canAttackTarget = displayTarget;
		else
			canAttackTarget = slideTarget;
		
		canAttackTargetActor = (CActor)canAttackTarget;
		
		if ( forceCanAttackWhenNotInCombat == 2 ) 
			return true;
		else if ( forceCanAttackWhenNotInCombat == 1 && ( !canAttackTarget || !canAttackTargetActor.IsHuman() ) ) 
			return true;			
		
		if ( actionType == EBAT_CastSign )
		{
			if ( thePlayer.GetEquippedSign() != ST_Quen && thePlayer.GetEquippedSign() != ST_Axii )
			{
				if ( CanUseSkill( S_Magic_s20 ) )
				{
					if ( thePlayer.GetEquippedSign() == ST_Aard )
						attackLength = 6.f;
					else if ( thePlayer.GetEquippedSign() == ST_Igni )
						attackLength = 4.f;
					else
						attackLength = 6.f;	
				}
				else
				{
					if ( thePlayer.GetEquippedSign() == ST_Aard )
						attackLength = 9.f;
					else if ( thePlayer.GetEquippedSign() == ST_Igni )
						attackLength = 6.f;
					else
						attackLength = 6.f;					
				}
				
				if ( altCast )
					attackAngle	= 180.f;
				else
					// sign cone angle / 2 with a bonus for safetey
					attackAngle	= 90.f;
				
				if ( !lastAxisInputIsMovement )
					inputHeading = VecHeading( theCamera.GetCameraDirection() );
				else if ( lAxisReleasedAfterCounter )
					inputHeading = GetHeading();
				else
					inputHeading = GetCombatActionHeading();				
					
				clearanceMin = 1.f;
				clearanceMax = attackLength	+ 1.f;
			}
			else if ( thePlayer.GetEquippedSign() == ST_Axii )
			{
				npc = (CNewNPC)canAttackTarget;
				if ( npc && npc.GetNPCType() == ENGT_Quest && !npc.HasTag(theGame.params.TAG_AXIIABLE_LOWER_CASE) && !npc.HasTag(theGame.params.TAG_AXIIABLE))
					return false;
				else if ( npc && npc.IsUsingHorse() )
					return false;
				else
					return true;
			}
			else
				return true;
		}
		else if ( actionType == EBAT_ItemUse )
		{
			attackLength = theGame.params.MAX_THROW_RANGE;
			attackAngle	= 90.f;
			
			if ( thePlayer.lastAxisInputIsMovement )
				inputHeading = GetCombatActionHeading();
			else 
				inputHeading = VecHeading( theCamera.GetCameraDirection() );

			clearanceMin = 0.8f;
			clearanceMax = attackLength	+ 3.f;	
		}
		else
		{
			if ( actionType == EBAT_SpecialAttack_Light || actionType == EBAT_SpecialAttack_Heavy )
			{
				attackLength = 1.9f;
				attackAngle	= 90.f;
			}
			else
			{
				if( thePlayer.GetCurrentMeleeWeaponType() == PW_Fists || thePlayer.GetCurrentMeleeWeaponType() == PW_None )
					attackLength = 1.2f; 
				else
					attackLength = 1.9f;
					
				attackAngle	= 90.f;	
			}
			
			if ( lastAxisInputIsMovement )
				inputHeading = GetCombatActionHeading();
			else
				inputHeading = VecHeading( theCamera.GetCameraDirection() );
				
			clearanceMin = attackLength	/ 2.f;
			clearanceMax = attackLength	+ 3.f;
		}

		//Use slideTarget first if it's NULL, then we try other npcs in the area
		if ( canAttackTarget )
		{
			if ( ( canAttackTargetActor && canAttackTargetActor.IsHuman() ) || canAttackTargetActor.HasTag( 'softLock_Friendly' ) )
			{
				if ( ShouldPerformFriendlyAction( canAttackTargetActor, inputHeading, attackAngle, clearanceMin, clearanceMax ) )
				{
					SetSlideTarget( canAttackTargetActor );
					newTarget =	canAttackTargetActor;
					return false;
				}
			}
			
			//return true;
		}
		
		return true;
		
		thePlayer.GetVisibleEnemies( localTargets );	
		size = localTargets.Size();
		
		if ( size > 0 )
		{
			for ( i = size-1; i>=0; i-=1 )
			{	
				/*
					Andrzej: Geralt's friendly combat action - taunting actors with a sword or playing with Signs is set to work only for humans. 
					We don't want it to work against all non-humans, so I've added an exception that works similar to targeting non actor objects.
					If you want Geralt to play friendly combat action when targeting monsters, add tag softLock_Friendly to monster's entity.
				*/
				if ( !localTargets[i].IsHuman() && !localTargets[i].HasTag( 'softLock_Friendly' ) )
					localTargets.Erase(i);
			}
		}
	
		size = localTargets.Size();
		if ( size > 0 )
		{		
			for ( i = 0; i < localTargets.Size(); i += 1 )
			{	
				if ( ShouldPerformFriendlyAction( localTargets[i], inputHeading, attackAngle, clearanceMin, clearanceMax ) )			
				{
					SetSlideTarget( localTargets[i] );
					newTarget =	localTargets[i];
					return false;
				}
			}
		}

		newTarget =	NULL;

		return true;
	}	
	
	private function ShouldPerformFriendlyAction( actor : CActor, inputHeading, attackAngle, clearanceMin, clearanceMax : float ) : bool
	{
		var npc : CNewNPC;
		var argh : float;
		var playerToTargetDist			: float;
	
		npc = (CNewNPC)actor;
		
		if ( npc && 
			( GetAttitudeBetween(thePlayer, npc) == AIA_Hostile || ( GetAttitudeBetween(thePlayer, npc) == AIA_Neutral && npc.GetNPCType() != ENGT_Guard ) ) )
		{
		}
		else
		{
			playerToTargetDist = VecDistance( this.GetWorldPosition(), actor.PredictWorldPosition( 0.5f ) ); //actor.GetNearestPointInPersonalSpace( this.GetWorldPosition() ) );
			
			argh = AbsF( AngleDistance( inputHeading, VecHeading( actor.GetWorldPosition() - thePlayer.GetWorldPosition() ) ) );
			
			if ( AbsF( AngleDistance( inputHeading, VecHeading( actor.GetWorldPosition() - thePlayer.GetWorldPosition() ) ) ) < attackAngle )
			{
				if ( playerToTargetDist < clearanceMax )
				{		
					return true;
				}
			}
			else
			{
				if ( playerToTargetDist < clearanceMin )
				{	
					return true;
				}
			}
		}

		return false;
	}
	
	///////////////////////////////////////////////////////////////////////////
	// 								HUD //#B
	///////////////////////////////////////////////////////////////////////////
	
	public function GetHudMessagesSize() : int 
	{
		return HudMessages.Size();
	}
	
	public function GetHudPendingMessage() : string
	{
		return HudMessages[0];
	}
	
	public function DisplayHudMessage( value : string ) : void
	{
		if (value == "")
		{
			return;
		}
		
		if( GetHudMessagesSize() > 0 )
		{
			if( HudMessages[HudMessages.Size()-1] == value )
			{
				return;
			}
		}
		HudMessages.PushBack(value);
	}
	
	//hacks for review requests
	private final function DisallowedActionDontShowHack(action : EInputActionBlock, isTimeLock : bool) : bool
	{
		var locks : array< SInputActionLock >;
		var i : int;
		
		//no info if we're trying to attack while staggered
		if((action == EIAB_Fists || action == EIAB_SwordAttack || action == EIAB_Signs || action == EIAB_LightAttacks || action == EIAB_HeavyAttacks || action == EIAB_SpecialAttackLight || action == EIAB_SpecialAttackHeavy) && (HasBuff(EET_Stagger) || HasBuff(EET_LongStagger)) )
		{
			return true;
		}
		
		//display message if trying to throw bombs while hypnotized by bies or blinded by water hag
		if( action == EIAB_ThrowBomb && ( HasBuff( EET_Hypnotized ) || HasBuff( EET_Confusion ) ) )
		{
			return false;
		}
		
		//show if locked temporarily
		if(isTimeLock)
			return false;
		
		//always show meditation message
		if(action == EIAB_OpenMeditation)
			return false;
		
		//if there's at least one lock from quest or from location fine
		locks = GetActionLocks(action);
		for(i=0; i<locks.Size(); i+=1)
		{
			if(locks[i].isFromQuest || locks[i].isFromPlace)
				return false;
		}
		
		if ( this.IsCurrentlyUsingItemL() )
		{
			if ( action == EIAB_HeavyAttacks || action == EIAB_Parry )
				return false;
		}
		
		//otherwise we don't display locks
		return true;
	}
	
	public final function DisplayActionDisallowedHudMessage(action : EInputActionBlock, optional isCombatLock : bool, optional isPlaceLock : bool, optional isTimeLock : bool, optional isDangerous : bool)
	{
		var lockType : name;
		
		if(action != EIAB_Undefined && DisallowedActionDontShowHack(action, isTimeLock))
			return;
		
		//combat lock is strongest - overrides all
		if(IsInCombat() && !IsActionCombat(action))
			isCombatLock = true;
			
		//if no specific lock set, check based on action
		if(!isCombatLock && !isPlaceLock && !isTimeLock && action != EIAB_Undefined)
		{
			lockType = inputHandler.GetActionBlockedHudLockType(action);
			
			if(lockType == 'combat')
				isCombatLock = true;
			else if(lockType == 'place')
				isPlaceLock = true;
			else if(lockType == 'time')
				isTimeLock = true;
		}
		
		if(isDangerous)
		{
			DisplayHudMessage(GetLocStringByKeyExt( "message_meditation_too_dangerous" ));
		}
		else if(isCombatLock)
		{
			DisplayHudMessage(GetLocStringByKeyExt( "panel_hud_message_actionnotallowed_combat" ));
		}
		else if(isPlaceLock)
		{
			DisplayHudMessage(GetLocStringByKeyExt( "menu_cannot_perform_action_here" ));
		}
		else if(isTimeLock)
		{
			DisplayHudMessage(GetLocStringByKeyExt( "menu_cannot_perform_action_now" ));
		}		
	}
	
	//removes first or all instances of given message
	public function RemoveHudMessageByString(msg : string, optional allQueuedInstances : bool)
	{
		var i, j : int;
		
		for(i=0; i<HudMessages.Size(); i+=1)
		{
			if(HudMessages[i] == msg)
			{
				HudMessages.EraseFast(i);
				
				if(!allQueuedInstances)
					return;
					
				break;
			}
		}
		
		//if here then we want all remaining instances as well
		for(j=HudMessages.Size()-1; j >= i; j-=1)
		{
			if(HudMessages[i] == msg)
			{
				HudMessages.EraseFast(i);
			}
		}
	}
			
	public function RemoveHudMessageByIndex(idx : int)
	{
		if(idx >= 0 && idx < HudMessages.Size())
			HudMessages.Erase(idx);
	}
	
	function SetSettlementBlockCanter( valueAdd : int ) // #B
	{
		m_SettlementBlockCanter += valueAdd;
	}
	
	var countDownToStart : int;
	default countDownToStart = 0;
	
	function DisplayRaceStart( countDownSecondsNumber : int ) // #B
	{
		var i : int;
		countDownToStart = countDownSecondsNumber;
		for( i = countDownSecondsNumber; i > 0; i -= 1 )
		{
			DisplayHudMessage(IntToString(i));
		}
		DisplayHudMessage(GetLocStringByKeyExt("panel_hud_message_race_start"));
		AddTimer('RaceCountdown',1,true);
	}
	
	timer function RaceCountdown(dt : float, id : int) // #B 
	{
		var hud : CR4ScriptedHud;
		var messageModule : CR4HudModuleMessage;
		
		countDownToStart -= 1;
		hud = (CR4ScriptedHud)theGame.GetHud();
		
		if( hud )
		{
			messageModule = (CR4HudModuleMessage)hud.GetHudModule("MessageModule");
			if( messageModule )
			{
				messageModule.OnMessageHidden(); // to force show next messeage
			}
		}
		
		if( countDownToStart <= 0 )
		{
			RemoveTimer('RaceCountdown');
		}
	}
	
	public function GetCountDownToStart() : int // #B
	{
		return countDownToStart;
	}
	
	public function HAXE3GetContainer() : W3Container //#B temp for E3
	{
		return HAXE3Container;
	}

	public function HAXE3SetContainer( container : W3Container) : void //#B temp for E3
	{
		HAXE3Container = container;
	}

	public function HAXE3GetAutoLoot() : bool //#B temp for E3
	{
		return HAXE3bAutoLoot;
	}

	public function HAXE3SetAutoLoot( value : bool ) : void //#B temp for E3
	{
		HAXE3bAutoLoot = value;
	}
	
	public function GetShowHud() : bool
	{
		return bShowHud;
	}

	public function SetShowHud( value : bool ) : void
	{
		bShowHud = value;
	}

	public function DisplayItemRewardNotification( itemName : name, optional quantity : int ) : void 
	{
		var hud : CR4ScriptedHud;
		hud = (CR4ScriptedHud)theGame.GetHud();
		hud.OnItemRecivedDuringScene(itemName, quantity); // #B because our default currency are Crowns !!!
	}
	
	function IsNewQuest( questGuid : CGUID ) : bool // #B
	{
		var i : int;
		for(i = 0; i < displayedQuestsGUID.Size(); i += 1 )
		{
			if( displayedQuestsGUID[i] == questGuid )
			{
				return false;
			}
		}
		displayedQuestsGUID.PushBack(questGuid);
		return true;
	}	
	
	function GetRewardMultiplierData( rewardName : name ) : SRewardMultiplier
	{
		var defaultReward : SRewardMultiplier;
		var i 			  : int;
		
		for(i = 0; i < rewardsMultiplier.Size(); i += 1 )
		{
			if( rewardsMultiplier[i].rewardName == rewardName )
			{
				return rewardsMultiplier[i];
			}
		}
		
		defaultReward.rewardName = rewardName;
		defaultReward.rewardMultiplier = 1.0;
		defaultReward.isItemMultiplier = false;
		
		return defaultReward;
	}

	function GetRewardMultiplier( rewardName : name ) : float // #B
	{
		var i : int;
		for(i = 0; i < rewardsMultiplier.Size(); i += 1 )
		{
			if( rewardsMultiplier[i].rewardName == rewardName )
			{
				return rewardsMultiplier[i].rewardMultiplier;
			}
		}
		return 1.0;
	}

	function GetRewardMultiplierExists( rewardName : name ) : bool // #B
	{
		var i : int;
		for(i = 0; i < rewardsMultiplier.Size(); i += 1 )
		{
			if( rewardsMultiplier[i].rewardName == rewardName )
			{
				return true;
			}
		}
		return false;
	}

	function SetRewardMultiplier( rewardName : name, value : float, optional isItemMultiplier : bool ) : void // #B
	{
		var i : int;
		var rewardMultiplier : SRewardMultiplier;
		
		for(i = 0; i < rewardsMultiplier.Size(); i += 1 )
		{
			if( rewardsMultiplier[i].rewardName == rewardName )
			{
				rewardsMultiplier[i].rewardMultiplier = value;
				rewardsMultiplier[i].isItemMultiplier = isItemMultiplier;
				return;
			}
		}
		
		rewardMultiplier.rewardName = rewardName;
		rewardMultiplier.rewardMultiplier = value;
		rewardMultiplier.isItemMultiplier = isItemMultiplier;
		
		rewardsMultiplier.PushBack(rewardMultiplier);
	}	

	function RemoveRewardMultiplier( rewardName : name ) : void // #B
	{
		var i : int;
		for(i = 0; i < rewardsMultiplier.Size(); i += 1 )
		{
			if( rewardsMultiplier[i].rewardName == rewardName )
			{
				rewardsMultiplier.Erase(i);
				return;
			}
		}
	}
	
	////////////////////////////////////////////////////////////////////////////////
	//
	// @Items
	//
	////////////////////////////////////////////////////////////////////////////////
	
	public final function TissueExtractorDischarge() : bool
	{
		var ids : array<SItemUniqueId>;
		var chargesLeft, uses, curr, max, red, blue, green : int;
		var i : int;
		var text : string;
		
		ids = thePlayer.inv.GetItemsByName( 'q705_tissue_extractor' );		
		if( ids.Size() == 0 )
		{
			return false;
		}
		
		curr = GetTissueExtractorChargesCurr();
		max = GetTissueExtractorChargesMax();
		
		if( curr >= max )
		{
			//calculate how many times the effect will work
			uses = FloorF( ( ( float ) curr ) / ( ( float ) max ) );
			chargesLeft = Max( 0, curr - uses * max );
			
			//update charges
			inv.SetItemModifierInt( ids[0], 'charges', chargesLeft );			
			
			//add items
			blue = 0;
			green = 0;
			red = 0;
			for( i=0; i<uses; i+=1 )
			{
				switch( RandRange( 3 ) )
				{
					case 0:
						blue += 1;
						break;
					case 1:
						green += 1;
						break;
					case 2:
						red += 1;
				}
			}
			
			text = GetLocStringByKeyExt( "message_q705_extractor_extracted" );
			
			if( blue > 0 )
			{
				inv.AddAnItem( 'Greater mutagen blue', blue, false, true );
				text += "<br/>" + blue + "x " + GetLocStringByKey( inv.GetItemLocalizedNameByName( 'Greater mutagen blue' ) );
			}
			if( green > 0 )
			{
				inv.AddAnItem( 'Greater mutagen green', green, false, true );
				text += "<br/>" + green + "x " + GetLocStringByKey( inv.GetItemLocalizedNameByName( 'Greater mutagen green' ) );
			}
			if( red > 0 )
			{
				inv.AddAnItem( 'Greater mutagen red', red, false, true );
				text += "<br/>" + red + "x " + GetLocStringByKey( inv.GetItemLocalizedNameByName( 'Greater mutagen red' ) );
			}
			
			//popup to inform player			
			theGame.GetGuiManager().ShowNotification( text );
			
			//clear flag for UI notification when item becomes charged
			inv.SetItemModifierInt( ids[0], 'ui_notified', 0 );
			
			return true;
		}
		else
		{
			//popup to inform player
			theGame.GetGuiManager().ShowNotification( GetLocStringByKeyExt( "message_q705_extractor_too_few_charges" ) );
		}
		
		return false;
	}
	
	public final function TissueExtractorIncCharge()
	{
		var ids : array<SItemUniqueId>;
		var uiData : SInventoryItemUIData;
		var curr : int;
		
		ids = thePlayer.inv.GetItemsByName( 'q705_tissue_extractor' );
		if( ids.Size() == 0 )
		{
			return;
		}
		
		curr = GetTissueExtractorChargesCurr() + 1;
		inv.SetItemModifierInt( ids[0], 'charges', curr );
		
		//mark as new in inventory
		if( curr >= GetTissueExtractorChargesMax() )
		{
			uiData = inv.GetInventoryItemUIData( ids[0] );
			uiData.isNew = true;
			inv.SetInventoryItemUIData( ids[0], uiData );
			
			//show popup ingame
			if( inv.GetItemModifierInt( ids[0], 'ui_notified', 0 ) == 0 )
			{
				inv.SetItemModifierInt( ids[0], 'ui_notified', 1 );
				theGame.GetGuiManager().ShowNotification( GetLocStringByKeyExt( "message_q705_extractor_charged" ), , true );
			}
		}
	}
	
	public final function GetTissueExtractorChargesCurr() : int
	{
		var ids : array<SItemUniqueId>;
		
		ids = thePlayer.inv.GetItemsByName( 'q705_tissue_extractor' );
		if( ids.Size() == 0 )
		{
			return 0;
		}
		
		return inv.GetItemModifierInt( ids[0], 'charges', 0 );
	}
	
	public final function GetTissueExtractorChargesMax() : int
	{
		var ids : array<SItemUniqueId>;
		var val : SAbilityAttributeValue;
		
		ids = thePlayer.inv.GetItemsByName( 'q705_tissue_extractor' );
		if( ids.Size() == 0 )
		{
			return 0;
		}
		
		val = inv.GetItemAttributeValue( ids[0], 'maxCharges' );
		
		return FloorF( val.valueBase );
	}
	
	public function GetEquippedSword(steel : bool) : SItemUniqueId;
	
	public final function HasRequiredLevelToEquipItem(item : SItemUniqueId) : bool
	{
		if(HasBuff(EET_WolfHour))
		{
			if((inv.GetItemLevel(item) - 2) > GetLevel() )
				return false;
		}
		else
		{
			if(inv.GetItemLevel(item) > GetLevel() )	
				return false;
		}
		
		return true;
	}
	
	public function SkillReduceBombAmmoBonus()
	{
		var i, ammo, maxAmmo : int;
		var items : array<SItemUniqueId>;
	
		items = inv.GetSingletonItems();
		
		for(i=0; i<items.Size(); i+=1)
		{
			ammo = inv.GetItemModifierInt(items[i], 'ammo_current');
							
			//if doesn't have infinite ammo
			if(ammo > 0)
			{
				maxAmmo = inv.SingletonItemGetMaxAmmo(items[i]);
				
				//if current ammo > max ammo, set current ammo to max ammo
				if(ammo > maxAmmo)
				{
					inv.SetItemModifierInt(items[i], 'ammo_current', maxAmmo);
				}
			}
		}
		theGame.GetGlobalEventsManager().OnScriptedEvent( SEC_OnAmmoChanged );
	}
		
	public function ConsumeItem( itemId : SItemUniqueId ) : bool
	{
		var params : SCustomEffectParams;
		var buffs : array<SEffectInfo>;
		var i : int;
		var category : name;
		var potionToxicity : float;
		
		if(!inv.IsIdValid(itemId))
			return false;
		
		//apply buff
		category = inv.GetItemCategory(itemId);
		if(category == 'edibles' || inv.ItemHasTag(itemId, 'Drinks') || ( category == 'alchemy_ingredient' && inv.ItemHasTag(itemId, 'Alcohol')) )
		{
			//cannot eat in fistfights
			if(IsFistFightMinigameEnabled())
			{
				DisplayActionDisallowedHudMessage(EIAB_Undefined, false, false, true);
				return false;
			}
		
			//edible buff
			inv.GetItemBuffs(itemId, buffs);
			
			for(i=0; i<buffs.Size(); i+=1)
			{
				params.effectType = buffs[i].effectType;
				params.creator = this;
				params.sourceName = "edible";
				params.customAbilityName = buffs[i].effectAbilityName;
				AddEffectCustom(params);
			}
			
			//custom hack
			if ( inv.ItemHasTag(itemId, 'Alcohol') )
			{
				potionToxicity = CalculateAttributeValue(inv.GetItemAttributeValue(itemId, 'toxicity'));
				abilityManager.GainStat(BCS_Toxicity, potionToxicity );				
				AddEffectDefault(EET_Drunkenness, NULL, inv.GetItemName(itemId));
			}
			PlayItemConsumeSound( itemId );
		}
		
		if(inv.IsItemFood(itemId))
			FactsAdd("consumed_food_cnt");
		
		//remove item
		if(!inv.ItemHasTag(itemId, theGame.params.TAG_INFINITE_USE) && !inv.RemoveItem(itemId))
		{
			LogAssert(false,"Failed to remove consumable item from player inventory!" + inv.GetItemName( itemId ) );
			return false;
		}
		
		return true;
	}
	
	public function MountVehicle( vehicleEntity : CEntity, mountType : EVehicleMountType, optional vehicleSlot : EVehicleSlot )
	{
		var vehicle : CVehicleComponent; 
		vehicle = (CVehicleComponent)(vehicleEntity.GetComponentByClassName('CVehicleComponent'));
		
		if ( vehicle )
			vehicle.Mount( this, mountType, vehicleSlot );
	}
	
	public function DismountVehicle( vehicleEntity : CEntity, dismountType : EDismountType )
	{
		var vehicle : CVehicleComponent; 
		vehicle = (CVehicleComponent)(vehicleEntity.GetComponentByClassName('CVehicleComponent'));
		
		if ( vehicle )
			vehicle.IssueCommandToDismount( dismountType );
	}
	
	////////////////
	// @stamina @stats
	////////////////
	
	protected function ShouldDrainStaminaWhileSprinting() : bool
	{
		if( HasBuff( EET_PolishedGenitals ) && !IsInCombat() && !IsThreatened() )
		{
			return false;
		}
		
		return super.ShouldDrainStaminaWhileSprinting();
	}
	
	//Returns true if actor has enough stamina to perform given action type (refer to DrainStamina for more info).
	//If there is not enough stamina and actor is a player character then a insufficient stamina indication is shown on HUD
	public function HasStaminaToUseAction(action : EStaminaActionType, optional abilityName : name, optional dt :float, optional multiplier : float) : bool
	{
		var cost : float;
		var ret : bool;
		
		ret = super.HasStaminaToUseAction(action, abilityName, dt, multiplier);
	
		if(!ret)
		{
			SetCombatActionHeading( GetHeading() );
			
			if(multiplier == 0)
				multiplier = 1;
				
			cost = multiplier * GetStaminaActionCost(action, abilityName, dt);
			SetShowToLowStaminaIndication(cost);
		}
		
		return ret;
	}
		
	//since we cannot add timer on abilityManager...
	timer function AbilityManager_FloorStaminaSegment(dt : float, id : int)
	{
		((W3PlayerAbilityManager)abilityManager).FloorStaminaSegment();
	}
		
	public function DrainToxicity(amount : float )
	{
		if(abilityManager && abilityManager.IsInitialized() && IsAlive())
			abilityManager.DrainToxicity(amount);
	}
	
	public function DrainFocus(amount : float )
	{
		if(abilityManager && abilityManager.IsInitialized() && IsAlive())
			abilityManager.DrainFocus(amount);
	}
	
	public function GetOffenseStat():int
	{
		if(abilityManager && abilityManager.IsInitialized())
			return ((W3PlayerAbilityManager)abilityManager).GetOffenseStat();
		
		return 0;
	}
	
	public function GetDefenseStat():int
	{
		if(abilityManager && abilityManager.IsInitialized())
			return ((W3PlayerAbilityManager)abilityManager).GetDefenseStat();
		
		return 0;
	}
	
	public function GetSignsStat():float
	{
		if(abilityManager && abilityManager.IsInitialized())
			return ((W3PlayerAbilityManager)abilityManager).GetSignsStat();
		
		return 0;
	}
		
	////////////////
	// water
	////////////////
	
	private var inWaterTrigger : bool;
	
	event OnOceanTriggerEnter()
	{
		inWaterTrigger = true;
	}
	
	event OnOceanTriggerLeave()
	{
		inWaterTrigger = false;
	}
	
	public function IsInWaterTrigger() : bool
	{
		return inWaterTrigger;
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////
	// @Skills @Perks
	//////////////////////////////////////////////////////////////////////////////////////////

	public function GetSkillColor(skill : ESkill) : ESkillColor
	{
		if(abilityManager && abilityManager.IsInitialized())
			return ((W3PlayerAbilityManager)abilityManager).GetSkillColor(skill);
			
		return SC_None;
	}
	
	public function GetSkillSlotIndexFromSkill(skill : ESkill) : int
	{
		if(abilityManager && abilityManager.IsInitialized())
			return ((W3PlayerAbilityManager)abilityManager).GetSkillSlotIndexFromSkill(skill);
			
		return -1;
	}
	
	public final function GetSkillSlotIndex(slotID : int, checkIfUnlocked : bool) : int
	{
		if(abilityManager && abilityManager.IsInitialized())
			return ((W3PlayerAbilityManager)abilityManager).GetSkillSlotIndex(slotID, checkIfUnlocked);
			
		return -1;
	}
	
	public final function GetSkillSlotIDFromIndex(skillSlotIndex : int) : int
	{
		if(abilityManager && abilityManager.IsInitialized())
			return ((W3PlayerAbilityManager)abilityManager).GetSkillSlotIDFromIndex(skillSlotIndex);
			
		return -1;
	}
	
	public function GetSkillSlotID(skill : ESkill) : int
	{
		if(abilityManager && abilityManager.IsInitialized())
			return ((W3PlayerAbilityManager)abilityManager).GetSkillSlotID(skill);
			
		return -1;
	}
	
	public function GetSkillGroupBonus(groupID : int) : name
	{
		if(abilityManager && abilityManager.IsInitialized())
			return ((W3PlayerAbilityManager)abilityManager).GetGroupBonus(groupID);
			
		return '';
	}
	
	public function GetGroupBonusCount(commonColor : ESkillColor,groupID : int) : int
	{
		if(abilityManager && abilityManager.IsInitialized())
			return ((W3PlayerAbilityManager)abilityManager).GetSkillGroupColorCount(commonColor, groupID);
			
		return 0;
	}
	
	public function GetMutagenSlotIDFromGroupID(groupID : int) : int
	{
		if(abilityManager && abilityManager.IsInitialized())
			return ((W3PlayerAbilityManager)abilityManager).GetMutagenSlotIDFromGroupID(groupID);
			
		return -1;
	}
	
	public function GetSkillLevel(skill : ESkill) : int
	{
		if(abilityManager && abilityManager.IsInitialized())
			return ((W3PlayerAbilityManager)abilityManager).GetSkillLevel(skill);
			
		return -1;
	}
	
	public function GetBoughtSkillLevel(skill : ESkill) : int
	{
		if(abilityManager && abilityManager.IsInitialized())
			return ((W3PlayerAbilityManager)abilityManager).GetBoughtSkillLevel(skill);
			
		return -1;
	}

	public function AddSkill(skill : ESkill, optional isTemporary : bool)
	{
		if(abilityManager && abilityManager.IsInitialized())
			((W3PlayerAbilityManager)abilityManager).AddSkill(skill, isTemporary);
	}
	
	public function AddMultipleSkills(skill : ESkill, optional number : int, optional isTemporary : bool)
	{
		var i : int;
		
		if(number)
		{
			for( i=0; i<number; i+=1)
			{
				AddSkill(skill,isTemporary);
			}
		}
		else
		{
			AddSkill(skill,isTemporary);
		}
	}
	
	public function GetSkillAbilityName(skill : ESkill) : name
	{
		if(abilityManager && abilityManager.IsInitialized())
			return ((W3PlayerAbilityManager)abilityManager).GetSkillAbilityName(skill);
			
		return '';
	}
	
	public function HasStaminaToUseSkill(skill : ESkill, optional perSec : bool, optional signHack : bool) : bool
	{
		var ret : bool;
		var cost : float;
	
		cost = GetSkillStaminaUseCost(skill, perSec);
		
		ret = ( CanUseSkill(skill) && (abilityManager.GetStat(BCS_Stamina, signHack) >= cost) );
		
		//perk, using adrenaline instead of stamina when out of stamina
		if(!ret && IsSkillSign(skill) && CanUseSkill(S_Perk_09) && GetStat(BCS_Focus) >= 1)
		{
			ret = true;
		}
			
		//Gryphon Armor Set Bonus 1 - next basic sign is being cast for free
		if( !ret && IsSkillSign( skill ) && GetWitcherPlayer().HasBuff( EET_GryphonSetBonus ) )
		{
			ret = true;
		}
		
		if(!ret)
		{
			SetCombatActionHeading( GetHeading() );
			SetShowToLowStaminaIndication(cost);
		}
			
		return ret;
	}
	
	protected function GetSkillStaminaUseCost(skill : ESkill, optional perSec : bool) : float
	{
		if(abilityManager && abilityManager.IsInitialized())
			return ((W3PlayerAbilityManager)abilityManager).GetSkillStaminaUseCost(skill, perSec);
			
		return 0;
	}
	
	//works for perks and bookperks as well
	public function GetSkillAttributeValue(skill : ESkill, attributeName : name, addBaseCharAttribute : bool, addSkillModsAttribute : bool) : SAbilityAttributeValue
	{
		var null : SAbilityAttributeValue;
		
		if(abilityManager && abilityManager.IsInitialized())
			return abilityManager.GetSkillAttributeValue(SkillEnumToName(skill), attributeName, addBaseCharAttribute, addSkillModsAttribute);
		
		return null;
	}
	
	public function GetSkillLocalisationKeyName(skill : ESkill) : string // #B
	{
		if(abilityManager && abilityManager.IsInitialized())
			return ((W3PlayerAbilityManager)abilityManager).GetSkillLocalisationKeyName(skill);
			
		return "";
	}
	
	public function GetSkillLocalisationKeyDescription(skill : ESkill) : string // #B
	{
		if(abilityManager && abilityManager.IsInitialized())
			return ((W3PlayerAbilityManager)abilityManager).GetSkillLocalisationKeyDescription(skill);
			
		return "";
	}
	
	public function GetSkillIconPath(skill : ESkill) : string // #B
	{
		if(abilityManager && abilityManager.IsInitialized())
			return ((W3PlayerAbilityManager)abilityManager).GetSkillIconPath(skill);
		
		return "";
	}
	
	public function HasLearnedSkill(skill : ESkill) : bool
	{
		if(abilityManager && abilityManager.IsInitialized())
			return ((W3PlayerAbilityManager)abilityManager).HasLearnedSkill(skill);
			
		return false;
	}
	
	public function IsSkillEquipped(skill : ESkill) : bool
	{
		if(abilityManager && abilityManager.IsInitialized())
			return ((W3PlayerAbilityManager)abilityManager).IsSkillEquipped(skill);
		
		return false;
	}
	
	public function CanUseSkill(skill : ESkill) : bool
	{
		if(abilityManager && abilityManager.IsInitialized())
			return ((W3PlayerAbilityManager)abilityManager).CanUseSkill(skill);
			
		return false;
	}	
	
	public function CanLearnSkill(skill : ESkill) : bool //#B
	{
		if(abilityManager && abilityManager.IsInitialized())
			return ((W3PlayerAbilityManager)abilityManager).CanLearnSkill(skill);
			
		return false;
	}
	
	public function HasSpentEnoughPoints(skill : ESkill) : bool //#J
	{
		if(abilityManager && abilityManager.IsInitialized())
			return ((W3PlayerAbilityManager)abilityManager).HasSpentEnoughPoints(skill);
			
		return false;
	}
	
	public function PathPointsForSkillsPath(skill : ESkill) : int //#J
	{
		if(abilityManager && abilityManager.IsInitialized())
			return ((W3PlayerAbilityManager)abilityManager).PathPointsSpentInSkillPathOfSkill(skill);
			
		return -1;
	}
	
	public function GetPlayerSkills() : array<SSkill> // #B
	{
		var null : array<SSkill>;
		
		if(abilityManager && abilityManager.IsInitialized())
			return ((W3PlayerAbilityManager)abilityManager).GetPlayerSkills();
			
		return null;
	}
	
	public function GetPlayerSkill(s : ESkill) : SSkill // #B
	{
		var null : SSkill;
		
		if(abilityManager && abilityManager.IsInitialized())
			return ((W3PlayerAbilityManager)abilityManager).GetPlayerSkill(s);
			
		return null;
	}
	
	public function GetSkillSubPathType(s : ESkill) : ESkillSubPath // #B
	{
		if(abilityManager && abilityManager.IsInitialized())
			return ((W3PlayerAbilityManager)abilityManager).GetSkillSubPathType(s);
			
		return ESSP_NotSet;
	}
	
	public function GetSkillSlotsCount() : int
	{
		if(abilityManager && abilityManager.IsInitialized())
			return ((W3PlayerAbilityManager)abilityManager).GetSkillSlotsCount();
			
		return 0;
	}
	
	public function GetSkillSlots() : array<SSkillSlot>
	{
		var null : array<SSkillSlot>;
		
		if(abilityManager && abilityManager.IsInitialized())
			return ((W3PlayerAbilityManager)abilityManager).GetSkillSlots();
			
		return null;
	}
	
	public function GetPlayerSkillMutagens() : array<SMutagenSlot>
	{
		var null : array<SMutagenSlot>;
		
		if(abilityManager && abilityManager.IsInitialized())
			return ((W3PlayerAbilityManager)abilityManager).GetPlayerSkillMutagens();
			
		return null;
	}
	
	// mutagens
	//public function OnSkillMutagenEquipped()

	public function BlockSkill(skill : ESkill, block : bool, optional cooldown : float) : bool
	{
		if(abilityManager && abilityManager.IsInitialized())
			return ((W3PlayerAbilityManager)abilityManager).BlockSkill(skill, block, cooldown);
			
		return false;
	}
	
	public function IsSkillBlocked(skill : ESkill) : bool
	{
		if(abilityManager && abilityManager.IsInitialized())
			return ((W3PlayerAbilityManager)abilityManager).IsSkillBlocked(skill);
			
		return false;
	}

	//returns true if succeeded
	public function EquipSkill(skill : ESkill, slotID : int) : bool
	{
		var ret : bool;
		var groupID : int;
		var pam : W3PlayerAbilityManager;
		
		if(abilityManager && abilityManager.IsInitialized())
		{
			pam = (W3PlayerAbilityManager)abilityManager;
			ret = pam.EquipSkill(skill, slotID);
			if(ret)
			{
				groupID = pam.GetSkillGroupIdFromSkillSlotId(slotID);
				LogSkillColors("Equipped <<" + GetSkillColor(skill) + ">> skill <<" + skill + ">> to group <<" + groupID + ">>");
				LogSkillColors("Group bonus color is now <<" + pam.GetSkillGroupColor(groupID) + ">>");
				LogSkillColors("");
			}
	
			return ret;
		}
	
		return false;
	}
	
	//returns true if succeeded
	public function UnequipSkill(slotID : int) : bool
	{
		var ret : bool;
		var groupID : int;
		var skill : ESkill;
		var pam : W3PlayerAbilityManager;
		
		if(abilityManager && abilityManager.IsInitialized())
		{
			pam = (W3PlayerAbilityManager)abilityManager;
			GetSkillOnSlot(slotID, skill);
			ret = pam.UnequipSkill(slotID);
			if(ret)
			{
				groupID = pam.GetSkillGroupIdFromSkillSlotId(slotID);
				LogSkillColors("Unequipped <<" + GetSkillColor(skill) + ">> skill <<" + skill + ">> from group <<" + groupID + ">>");
				LogSkillColors("Group bonus color is now <<" + pam.GetSkillGroupColor(groupID) + ">>");
				LogSkillColors("");
			}
			return ret;
		}
			
		return false;
	}
	
	//returns true if succeeded
	public function GetSkillOnSlot(slotID : int, out skill : ESkill) : bool
	{
		if(abilityManager && abilityManager.IsInitialized())
			return ((W3PlayerAbilityManager)abilityManager).GetSkillOnSlot(slotID, skill);
			
		skill = S_SUndefined;
		return false;
	}
	
	//returns random free skill slot (if any, otherwise -1)
	public function GetFreeSkillSlot() : int
	{
		var i, size : int;
		var skill : ESkill;
	
		size = ((W3PlayerAbilityManager)abilityManager).GetSkillSlotsCount();
		for(i=1; i<size; i+=1)
		{
			if(!GetSkillOnSlot(i, skill))
				continue;	//if slot locked
				
			if(skill == S_SUndefined)	//empty unlocked slot
				return i;
		}
		
		return -1;
	}

	//////////////////
	// @attacks
	//////////////////
	
	//performs an attack (mechanics wise) on given target and using given attack data
	protected function Attack( hitTarget : CGameplayEntity, animData : CPreAttackEventData, weaponId : SItemUniqueId, parried : bool, countered : bool, parriedBy : array<CActor>, attackAnimationName : name, hitTime : float, weaponEntity : CItemEntity)
	{	
		var attackAction : W3Action_Attack;
	
		if(!PrepareAttackAction(hitTarget, animData, weaponId, parried, countered, parriedBy, attackAnimationName, hitTime, weaponEntity, attackAction))
			return;	//failed to create a valid attack action
		
		if ( attackAction.IsParried() && ( ((CNewNPC)attackAction.victim).IsShielded(attackAction.attacker) || ((CNewNPC)attackAction.victim).SignalGameplayEventReturnInt('IsDefending',0) == 1 ) )
		{
			thePlayer.SetCanPlayHitAnim(true);
			thePlayer.ReactToReflectedAttack(attackAction.victim);
		}
				
		theTelemetry.LogWithLabel( TE_FIGHT_PLAYER_ATTACKS, attackAction.GetAttackName() );
	
		//process action
		theGame.damageMgr.ProcessAction(attackAction);
		
		delete attackAction;
	}
	
	public function IsHeavyAttack(attackName : name) : bool
	{
		var skill : ESkill;
		var sup : bool;
	
		sup = super.IsHeavyAttack(attackName);
		if(sup)
			return true;
			
		if ( attackName == 'attack_heavy_special' )
			return true;
			
		skill = SkillNameToEnum(attackName);
		
		return skill == S_Sword_2 || skill == S_Sword_s02;
	}

	public function IsLightAttack(attackName : name) : bool
	{
		var skill : ESkill;
		var sup : bool;
	
		sup = super.IsLightAttack(attackName);
		if(sup)
			return true;
			
		skill = SkillNameToEnum(attackName);
		
		return skill == S_Sword_1 || skill == S_Sword_s01;
	}
	
	public final function ProcessWeaponCollision()
	{
		var l_stateName			: name;
		
		var l_weaponPosition	: Vector;
		var l_weaponTipPos		: Vector;
		var l_collidingPosition	: Vector;
		var l_offset			: Vector;
		var l_normal			: Vector;
		
		var l_slotMatrix		: Matrix;
		
		var l_distance			: float;
		
		var l_materialName		: name;
		var l_hitComponent		: CComponent;
		var l_destructibleCmp	: CDestructionSystemComponent;
		var barrel : COilBarrelEntity;
		
		//return;
		
		if( isCurrentlyDodging )
			return;
		
		l_stateName = GetCurrentStateName();
		
		if( !attackEventInProgress && l_stateName == 'CombatFists' )
			return;
		
		CalcEntitySlotMatrix('r_weapon', l_slotMatrix);
		
		l_weaponPosition 	= MatrixGetTranslation( l_slotMatrix );
		
		// Finding weapon's tip
		switch( l_stateName )
		{
			case 'CombatFists':
				l_offset 	= MatrixGetAxisX( l_slotMatrix );
				l_offset 	= VecNormalize( l_offset ) * 0.25f;
			break;
			// sword
			default:
				l_offset 	= MatrixGetAxisZ( l_slotMatrix );
				l_offset 	= VecNormalize( l_offset ) * 1.f;
			break;
		}
		
		l_weaponTipPos			= l_weaponPosition + l_offset;
		
		
		
		if( !attackEventInProgress )
		{			
			// If the weapon is not moving fast enough, do not play collision fx
			if( m_LastWeaponTipPos == Vector ( 0, 0, 0 ) )
				l_distance = 0;
			else
				l_distance 	= VecDistance( l_weaponTipPos, m_LastWeaponTipPos ) ;
				
			//GetVisualDebug().AddText( 'LastWeaponTipText', "Last - dist: " + l_distance, m_LastWeaponTipPos, true, , Color( 249, 98, 158 ) );
			//GetVisualDebug().AddArrow( 'OldDirectArrow', l_weaponPosition, m_LastWeaponTipPos , 0.8f, 0.1f, 0.2f, true, Color( 249, 98, 158 ) );
				
			m_LastWeaponTipPos	= l_weaponTipPos;
			if( l_distance < 0.35f )
				return;				
			
		}	
		
		/*GetVisualDebug().AddSphere( 'WeaponPosition', 0.1f, l_weaponPosition, true, Color( 249, 98, 158 ) );		
		GetVisualDebug().AddText( 'WeaponTipText', "Weapon Tip", l_weaponTipPos, true, , Color( 249, 98, 158 ) );
		GetVisualDebug().AddArrow( 'CollisionArrow', l_weaponPosition, l_weaponTipPos , 0.8f, 0.1f, 0.2f, true, Color( 249, 98, 158 ) );*/
		
		m_LastWeaponTipPos		= l_weaponTipPos;			
		
		if ( !theGame.GetWorld().StaticTraceWithAdditionalInfo( l_weaponPosition, l_weaponTipPos, l_collidingPosition, l_normal, l_materialName, l_hitComponent, m_WeaponFXCollisionGroupNames ) )
		{
			// Test left fist
			if( l_stateName == 'CombatFists' )
			{
				CalcEntitySlotMatrix('l_weapon', l_slotMatrix);
				l_weaponPosition 	= MatrixGetTranslation( l_slotMatrix );
				l_offset 			= MatrixGetAxisX( l_slotMatrix );
				l_offset 			= VecNormalize( l_offset ) * 0.25f;
				l_weaponTipPos		= l_weaponPosition + l_offset;
				if( !theGame.GetWorld().StaticTrace( l_weaponPosition, l_weaponTipPos, l_collidingPosition, l_normal, m_WeaponFXCollisionGroupNames ) )
				{
					return;
				}
			}
			else
			{
				return;
			}
		}
		
		if( !m_CollisionEffect )
		{
			m_CollisionEffect = theGame.CreateEntity( m_CollisionFxTemplate, l_collidingPosition, EulerAngles(0,0,0) );
		}
		
		m_CollisionEffect.Teleport( l_collidingPosition );
		
		// Play hit effect
		switch( l_stateName )
		{
			case 'CombatFists':
				m_CollisionEffect.PlayEffect('fist');
			break;
			default:				
				// Optimisation because IsSwordWooden() is heavy (around 0.13 ms)
				if( m_RefreshWeaponFXType )
				{
					m_PlayWoodenFX 			= IsSwordWooden();
					m_RefreshWeaponFXType 	= false;
				}
			
				if( m_PlayWoodenFX )
				{
					m_CollisionEffect.PlayEffect('wood');
				}
				else
				{
					switch( l_materialName )
					{
						case 'wood_hollow':
						case 'wood_debris':
						case 'wood_solid':
							m_CollisionEffect.PlayEffect('wood');
						break;
						case 'dirt_hard':
						case 'dirt_soil':
						case 'hay':
							m_CollisionEffect.PlayEffect('fist');
						break;
						case 'stone_debris':
						case 'stone_solid':
						case 'clay_tile':
						case 'gravel_large':
						case 'gravel_small':
						case 'metal':
						case 'custom_sword':
							m_CollisionEffect.PlayEffect('sparks');
						break;
						case 'flesh':
							m_CollisionEffect.PlayEffect('blood');
						break;
						default:
							m_CollisionEffect.PlayEffect('wood');
						break;
					}
					
				}
			break;
		}
		
		//don't ask...
		if(l_hitComponent)
		{
			barrel = (COilBarrelEntity)l_hitComponent.GetEntity();
			if(barrel)
			{
				barrel.OnFireHit(NULL);	//sets barrel on fire so that it explodes in a few sec
				return;
			}
		}
		
		// Destroy destructibles
		l_destructibleCmp = (CDestructionSystemComponent) l_hitComponent;
		if( l_destructibleCmp && l_stateName != 'CombatFists' )
		{
			l_destructibleCmp.ApplyFracture();
		}
		
		
		//GetVisualDebug().AddText( 'collisionText', "Collision Here", l_collidingPosition, true, , Color( 249, 98, 158 ) );
	}
	
	public function ReactToReflectedAttack( target : CGameplayEntity)
	{
		
		var hp, dmg : float;
		var action : W3DamageAction;
		
		super.ReactToReflectedAttack(target);
		
		if ( !((CNewNPC)target).IsShielded(this) )
		{
			action = new W3DamageAction in this;
			action.Initialize(target,this,NULL,'',EHRT_Reflect,CPS_AttackPower,true,false,false,false);
			action.AddEffectInfo(EET_Stagger);
			action.SetProcessBuffsIfNoDamage(true);
			
			theGame.damageMgr.ProcessAction( action );		
			delete action;
		}
		
		theGame.VibrateControllerLight();//player attack was reflected
	}
	
	//////////////////
	// falling damage
	//////////////////
	
	//return false when not falling
	function GetFallDist( out fallDist : float ) : bool
	{
		var fallDiff, jumpTotalDiff : float;
		
		// Get the falling height
		substateManager.m_SharedDataO.CalculateFallingHeights( fallDiff, jumpTotalDiff );
		
		if ( fallDiff <= 0 )
			return false;
			
		fallDist = fallDiff;
		return true;
	}
	
	function ApplyFallingDamage(heightDiff : float, optional reducing : bool) : float
	{
		var hpPerc : float;
		var tut : STutorialMessage;
	
		if ( IsSwimming() || FactsQuerySum("block_falling_damage") >= 1 )
			return 0.0f;
		
		hpPerc = super.ApplyFallingDamage( heightDiff, reducing );
			
		if(hpPerc > 0)		
		{
			theGame.VibrateControllerHard();//player falling damage
		
			if(IsAlive())
			{
				if(ShouldProcessTutorial('TutorialFallingDamage'))
				{
					FactsSet( "tutorial_falling_damage", 1 );
				}	
				
				if(FactsQuerySum("tutorial_falling_damage") > 1 && ShouldProcessTutorial('TutorialFallingRoll'))
				{
					//fill tutorial object data
					tut.type = ETMT_Hint;
					tut.tutorialScriptTag = 'TutorialFallingRoll';
					tut.hintPositionType = ETHPT_DefaultGlobal;
					tut.hintDurationType = ETHDT_Long;
					tut.canBeShownInMenus = false;
					tut.glossaryLink = false;
					tut.markAsSeenOnShow = true;
					
					//show tutorial
					theGame.GetTutorialSystem().DisplayTutorial(tut);
				}
			}
		}
			
		return hpPerc;
	}
		
	//--------------------------------- STAMINA INDICATOR #B --------------------------------------
	
	public function SetShowToLowStaminaIndication( value : float ) : void
	{
		fShowToLowStaminaIndication = value;
	}
	
	public function GetShowToLowStaminaIndication() : float
	{
		return fShowToLowStaminaIndication;
	}
	
	public final function IndicateTooLowAdrenaline()
	{
		SoundEvent("gui_no_adrenaline");
		showTooLowAdrenaline = true;
	}
	
	/////////////////////////////////
		
	protected function GotoCombatStateWithAction( initialAction : EInitialAction, optional initialBuff : CBaseGameplayEffect )
	{
		if ( this.GetCurrentActionType() == ActorAction_Exploration )
			ActionCancelAll();
			
		((W3PlayerWitcherStateCombatFists)this.GetState('CombatFists')).SetupState( initialAction, initialBuff );	
		this.GotoState( 'CombatFists' );
		
	}
	///////////////////////////////////////////////////////////////////////////////////////////
	// COMBAT
	public function IsThreat( actor : CActor, optional usePrecalcs : bool ) : bool
	{
		var npc 				: CNewNPC;
		var dist 				: float;
		var targetCapsuleHeight : float;
		var isDistanceExpanded 	: bool;
		var distanceToTarget	: float;
		var attitude 			: EAIAttitude;

		if (!actor)
		{
			return false;
		}
			
		if ( finishableEnemiesList.Contains( actor ) )
		{
			return true;
		}
			
		if ( !actor.IsAlive() || actor.IsKnockedUnconscious() )
		{
			return false;
		}
			
		npc = (CNewNPC)actor;
		if (npc && npc.IsHorse() )
		{
			return false;
		}
		
		if ( hostileEnemies.Contains( actor ) )
		{
			return true;
		}
		
		//MS: We add a tolerance to make geralt go to alertfar everytime he runs away from npc
		if ( GetAttitudeBetween( this, actor ) == AIA_Hostile )
		{		
			if ( usePrecalcs )
			{
				distanceToTarget = Distance2DBetweenCapsuleAndPoint( actor, this ) - targetingPrecalcs.playerRadius;
			}
			else
			{
				distanceToTarget = Distance2DBetweenCapsules( this, actor );
			}

			// shortDistance = findMoveTargetDist + 5.0f;
			if ( distanceToTarget < findMoveTargetDist + 5.0f )
			{
				return true;
			}
			
			if ( actor.IsInCombat() || this.IsHardLockEnabled() )
			{
				targetCapsuleHeight = ( (CMovingPhysicalAgentComponent)actor.GetMovingAgentComponent() ).GetCapsuleHeight();
				if ( targetCapsuleHeight >= 2.0f || npc.GetCurrentStance() == NS_Fly )
				{	
					// expandedDistance = 40.f;
					if ( distanceToTarget < 40.0f )
					{
						return true;
					}
				}
			}			
		}
		
		if ( actor.GetAttitudeGroup() == 'npc_charmed' )
		{
			if ( theGame.GetGlobalAttitude( GetBaseAttitudeGroup(), actor.GetBaseAttitudeGroup() ) == AIA_Hostile )
			{
				return true;
			}
		}
	
		return false;
	}

	function SetBIsCombatActionAllowed ( flag : bool )
	{
		bIsCombatActionAllowed = flag;
		
		if ( !flag )
		{
			SetBIsInCombatAction(true);
		}
		else
		{
			this.ProcessLAxisCaching();
			//UnblockAction(EIAB_Interactions, 'InsideCombatAction' );
		}
		
		//LogChannel('combatActionAllowed', "Is SET TO: " + flag );
	}
	
	function GetBIsCombatActionAllowed() : bool
	{
		return bIsCombatActionAllowed;
	}
	
	function SetCombatAction( action : EBufferActionType )
	{
		currentCombatAction = action;
	}
	
	function GetCombatAction() : EBufferActionType
	{
		return currentCombatAction;
	}	

	protected function WhenCombatActionIsFinished()
	{
		if(IsThrowingItem() || IsThrowingItemWithAim() )
		{
			if(inv.IsItemBomb(selectedItemId))
			{
				BombThrowAbort();
			}
			else
			{
				ThrowingAbort();
			}
		}
		
		if ( this.GetCurrentStateName() != 'DismountHorse' )
			OnRangedForceHolster( true );	
		
		//SetBehaviorVariable( 'combatActionType', (int)CAT_None2);
	}

	public function IsInCombatAction_Attack(): bool
	{
		if ( IsInCombatAction_NonSpecialAttack() || IsInCombatAction_SpecialAttack() )
			return true;
		else
			return false;
	}	
	
	public function IsInCombatAction_NonSpecialAttack(): bool
	{
		if ( IsInCombatAction() && ( GetCombatAction() == EBAT_LightAttack || GetCombatAction() == EBAT_HeavyAttack ) )
			return true;
		else
			return false;
	}
	
	public function IsInSpecificCombatAction ( specificCombatAction : EBufferActionType ) : bool
	{
		if ( IsInCombatAction() && GetCombatAction() == specificCombatAction )
			return true;
		else
			return false;
	}
	
	public function IsInRunAnimation() : bool
	{
		return isInRunAnimation;
	}
	
	//I need to call it after scene ends thats why it's public. PF
	public function SetCombatIdleStance( stance : float )
	{
		SetBehaviorVariable( 'combatIdleStance', stance );
		SetBehaviorVariable( 'CombatStanceForOverlay', stance );
		
		if ( stance == 0.f )
			LogChannel( 'ComboInput',  "combatIdleStance = Left" );
		else
			LogChannel( 'ComboInput',  "combatIdleStance = Right" );
	}
	
	public function GetCombatIdleStance() : float
	{
		// 0.f == Left
		return GetBehaviorVariable( 'combatIdleStance' );
	}	

	protected var isRotatingInPlace	: bool;
	event OnRotateInPlaceStart()
	{
		isRotatingInPlace = true;
	}
	
	event OnRotateInPlaceEnd()
	{
		isRotatingInPlace = false;
	}	

	event OnFullyBlendedIdle()
	{
		if ( bLAxisReleased )
		{
			ResetRawPlayerHeading();
			ResetCachedRawPlayerHeading();
			defaultLocomotionController.ResetMoveDirection();
		}
	}
	
	private var isInIdle : bool;
	
	event OnPlayerIdleStart()
	{
		isInIdle = true;
	}
	
	event OnPlayerIdleEnd()
	{
		isInIdle = false;
	}
	
	public function IsInIdle() : bool
	{
		return isInIdle;
	}
	
	event OnRunLoopStart()
	{
		EnableRunCamera( true );
	}

	event OnRunLoopEnd()
	{
		EnableRunCamera( false );
	}
	
	event OnCombatActionStartBehgraph()
	{
		var action : EBufferActionType;
		var cost, delay : float;
	
		// Block saves
		//theGame.CreateNoSaveLock( noSaveLockCombatActionName, noSaveLockCombatAction, true );	
	
		OnCombatActionStart();	
		
		action = PerformingCombatAction();
		switch ( action )
		{
			case EBAT_LightAttack :
			{
				abilityManager.GetStaminaActionCost(ESAT_LightAttack, cost, delay);
			} break;
			case EBAT_HeavyAttack :
			{
				abilityManager.GetStaminaActionCost(ESAT_HeavyAttack, cost, delay);
			} break;
			case EBAT_ItemUse :
			{
				abilityManager.GetStaminaActionCost(ESAT_UsableItem, cost, delay);
			} break;
			case EBAT_Parry :
			{
				abilityManager.GetStaminaActionCost(ESAT_Parry, cost, delay);
			} break;
			case EBAT_Dodge :
			{
				abilityManager.GetStaminaActionCost(ESAT_Dodge, cost, delay);
			} break;
			case EBAT_Roll :
				abilityManager.GetStaminaActionCost(ESAT_Roll, cost, delay);
				break;
			case EBAT_SpecialAttack_Light :
			{
				abilityManager.GetStaminaActionCost(ESAT_Ability, cost, delay, 0,0, GetSkillAbilityName(S_Sword_s01));
			} break;
			case EBAT_SpecialAttack_Heavy :
			{
				abilityManager.GetStaminaActionCost(ESAT_Ability, cost, delay, 0,0, GetSkillAbilityName(S_Sword_s02));
			} break;
			case EBAT_Roll :
			{
				abilityManager.GetStaminaActionCost(ESAT_Evade, cost, delay);
			} break;
			/*
			case EBAT_Ciri_SpecialAttack :
			{
				cost = GetStaminaActionCost();
			} break;
			*/
			default :
				;
		}
		
		//Pause the stamina regen for as long as we're doing combat actions.
		//Pause only once to avoid the pause counter from increasing with each lock
		if( delay > 0 )
			PauseStaminaRegen( 'InsideCombatAction' );
	}
	
	public function HolsterUsableItem() : bool
	{
		return holsterUsableItem;
	}

	private var isInGuardedState : bool;
	public function IsInGuardedState() : bool
	{
		return isInGuardedState;
	}
	
	event OnGuardedStart() 
	{
		isInParryOrCounter = true;
		isInGuardedState = true;
	}
	
	event OnGuardedEnd() 
	{
		isInParryOrCounter = false;
		isInGuardedState = false;
	}
	
	private var restoreUsableItem : bool;
	private var holsterUsableItem : bool;
	event OnCombatActionStart()
	{	
		//Block Actions
		//BlockAction( EIAB_DrawWeapon, 'OnCombatActionStart' );
		BlockAction( EIAB_UsableItem, 'OnCombatActionStart' );
		BlockAction( EIAB_CallHorse, 'OnCombatActionStart' );
		
		/*if ( !IsGuarded() )
			SetParryTarget( NULL );*/
	
		LogChannel('combatActionAllowed',"FALSE OnCombatActionStart");
		SetBIsCombatActionAllowed( false );
		SetBIsInputAllowed( false, 'OnCombatActionStart' );
		//lastAxisInputIsMovement = true;
		
		ClearFinishableEnemyList( 0.f, 0 );		
		
		bIsInHitAnim = false;
		
		//Holster Crossbow if it's held
		//if ( inv.IsItemCrossbow( inv.GetItemFromSlot( 'l_weapon' ) ) )//&& GetBehaviorVariable( 'combatActionType' ) != (int)CAT_Crossbow )
		if ( rangedWeapon && rangedWeapon.GetCurrentStateName() != 'State_WeaponWait' )
		{
			CleanCombatActionBuffer();
			SetIsAimingCrossbow( false );
			OnRangedForceHolster( false, true );
		}
			
		//Holster UsableItem if it's held
		holsterUsableItem = false;	
		if ( thePlayer.IsHoldingItemInLHand() ) // && !thePlayer.IsUsableItemLBlocked() )
		{
			if ( GetBehaviorVariable( 'combatActionType' ) == (int)CAT_CastSign )
				holsterUsableItem = true;
			else if ( GetBehaviorVariable( 'combatActionType' ) == (int)CAT_Attack )
			{
				if ( this.GetCurrentStateName() == 'CombatFists' )
					holsterUsableItem = true;
			}
		}

		if ( holsterUsableItem )
		{
			thePlayer.SetPlayerActionToRestore ( PATR_None );
			thePlayer.OnUseSelectedItem( true );

			restoreUsableItem = true;		
		}

		//Stop Geralt from automatically attacking while in AttackApproach when Player performs a non-attack combat action
		if ( GetBehaviorVariable( 'combatActionType' ) != (int)CAT_Attack && GetBehaviorVariable( 'combatActionType' ) != (int)CAT_PreAttack )
		{
			RemoveTimer( 'ProcessAttackTimer' );
			RemoveTimer( 'AttackTimerEnd' );
			UnblockAction( EIAB_DrawWeapon, 'OnCombatActionStart_Attack' );
		}
		else
		{
			//MS: Do not remove this!! The attack to idle transition states will not work correctly if you change weapon mid-attack. 
			BlockAction( EIAB_DrawWeapon, 'OnCombatActionStart_Attack' );
		}		
			
		//GetMovingAgentComponent().SnapToNavigableSpace(true);		
	}

	var isInParryOrCounter : bool;
	event OnParryOrCounterStart()
	{
		isInParryOrCounter = true;
		OnCombatActionStartBehgraph();
	}
	
	event OnParryOrCounterEnd()
	{
		isInParryOrCounter = false;
		OnCombatActionEnd();
		SetBIsInCombatAction( false );
	}
	
	//called when a combat action is completed (e.g. single hit in a combo sequence)
	event OnCombatActionEnd()
	{
		var item : SItemUniqueId;
		var combatActionType : float;
		
		super.OnCombatActionEnd();
		
		
		//Unblock Actions
		BlockAllActions( 'OnCombatActionStart', false );
		
		UnblockAction( EIAB_DrawWeapon, 'OnCombatActionStart_Attack' );
		
		// failsafe	
		UnblockAction( EIAB_Movement, 'CombatActionFriendly' );		
		
		//why? this way after EACH attack you reset it - what's the point then?
		//ResetUninterruptedHitsCount();
		
		oTCameraOffset = 0.f;
		oTCameraPitchOffset = 0.f;
		
		//LogChannel('combatActionAllowed',"TRUE OnCombatActionEnd");
		SetBIsCombatActionAllowed( true );
		//reapply critical buff if any
		//ReapplyCriticalBuff();
		SetBIsInputAllowed( true, 'OnCombatActionEnd' );			
		SetCanPlayHitAnim( true );
		EnableFindTarget( true );
		
		//AK: commented out because it sets dodging flag to false right after dodging starts when we chain multiple dodges
		//IsCurrentlyDodging returned false in the middle of dodge anim
		//SetIsCurrentlyDodging( false );
		SetFinisherVictim( NULL );
		
		OnBlockAllCombatTickets( false );
		
		LogStamina("CombatActionEnd");
		
		//GetMovingAgentComponent().SnapToNavigableSpace(false);
		
		SetAttackActionName('');
		combatActionType = GetBehaviorVariable('combatActionType');
		
		//clean-up after special attack heavy finishes
		if(GetBehaviorVariable('combatActionType') == (int)CAT_SpecialAttack)
		{
			theGame.GetGameCamera().StopAnimation( 'camera_shake_loop_lvl1_1' );
			OnSpecialAttackHeavyActionProcess();
		}
		// Do we need to interrupt?
		substateManager.ReactToChanceToFallAndSlide();
	}
	
	event OnCombatActionFriendlyStart()
	{
		SetBIsInCombatActionFriendly(true);
		BlockAction( EIAB_Movement, 'CombatActionFriendly', false, false, false );
		OnCombatActionStart();
	}
	
	event OnCombatActionFriendlyEnd()
	{
		SetBIsInCombatActionFriendly(false);
		UnblockAction( EIAB_Movement, 'CombatActionFriendly' );
		OnCombatActionEnd();
		SetBIsInCombatAction(false);
		//RaiseForceEvent( 'ForceIdle' );
	}	
	
	event OnHitStart()
	{
		var timeLeft : float;
		var currentEffects : array<CBaseGameplayEffect>;
		var none 	: SAbilityAttributeValue;

		CancelHoldAttacks();	
		WhenCombatActionIsFinished();
		if ( isInFinisher )
		{
			if ( finisherTarget )
				( (CNewNPC)finisherTarget ).SignalGameplayEvent( 'FinisherInterrupt' );
			isInFinisher = false;
			finisherTarget = NULL;
			SetBIsCombatActionAllowed( true );
		}	
		
		bIsInHitAnim = true;
		
		OnCombatActionStart();	//"because it's needed"
		
		//OnCombatActionStart pauses the regen and we don't want that
		ResumeStaminaRegen( 'InsideCombatAction' );
		
		if( GetHealthPercents() < 0.3f )
		{
			PlayBattleCry('BattleCryBadSituation', 0.10f, true );
		}
		else
		{
			PlayBattleCry('BattleCryBadSituation', 0.05f, true );
		}
	}
	
	event OnHitStartSwimming()
	{	
		OnRangedForceHolster( true, true, false );
	}
	
	private var finisherSaveLock : int;
	event OnFinisherStart()
	{
		var currentEffects : array<CBaseGameplayEffect>;
		
		theGame.CreateNoSaveLock("Finisher",finisherSaveLock,true,false);
		
		isInFinisher = true;
		
		finisherTarget = slideTarget;
		OnCombatActionStart();
		
		CancelHoldAttacks();
	
		PlayFinisherCameraAnimation( theGame.GetSyncAnimManager().GetFinisherCameraAnimName() );
		this.AddAnimEventCallback('SyncEvent','OnFinisherAnimEvent_SyncEvent');
		SetImmortalityMode( AIM_Invulnerable, AIC_SyncedAnim );
	}
	
	public function IsPerformingFinisher() : bool
	{
		return isInFinisher;
	}
	
	private function PlayFinisherCameraAnimation( cameraAnimName : name )
	{
		var camera 	: CCustomCamera = theGame.GetGameCamera();
		var animation		: SCameraAnimationDefinition;
		
		if( IsLastEnemyKilled() && theGame.GetWorld().NavigationCircleTest( this.GetWorldPosition(), 3.f ) )
		{
			camera.StopAnimation('camera_shake_hit_lvl3_1' );
			
			animation.animation = cameraAnimName;
			animation.priority = CAP_Highest;
			animation.blendIn = 0.15f;
			animation.blendOut = 1.0f;
			animation.weight = 1.f;
			animation.speed	= 1.0f;
			animation.reset = true;
			
			camera.PlayAnimation( animation );
			//thePlayer.AddTimer( 'RemoveFinisherCameraAnimationCheck', 0.01, true );
			
			thePlayer.EnableManualCameraControl( false, 'Finisher' );
		}
	}	
	
	public function IsLastEnemyKilled() : bool
	{
		var tempMoveTargets		: array<CActor>;
		
		FindMoveTarget();
		tempMoveTargets = GetMoveTargets();
		if  ( tempMoveTargets.Size() <= 0 || !thePlayer.IsThreat( tempMoveTargets[0] ) )
			return true;
		
		return false; 
	}
	
	event OnFinisherAnimEvent_SyncEvent( animEventName : name, animEventType : EAnimationEventType, animInfo : SAnimationEventAnimInfo )
	{
		if ( finisherTarget )
			( (CNewNPC)finisherTarget ).SignalGameplayEvent('FinisherKill');
		finisherTarget = NULL;
	}
	
	event OnFinisherEnd()
	{
		isInFinisher = false;
		finisherTarget = NULL;
		
		theGame.ReleaseNoSaveLock(finisherSaveLock);
		
		this.RemoveAnimEventCallback('SyncEvent');
		
		//SetIsPerformingPhaseChangeAnimation( false ); // for eredin fight
		SetImmortalityMode( AIM_None, AIC_SyncedAnim );
		theGame.RemoveTimeScale( 'AnimEventSlomoMo' );
		AddTimer( 'FinisherEndEnableCamera', 0.5f );
		//OnBlockAllCombatTickets( false );
		OnCombatActionEnd();
		OnCombatActionEndComplete();
	}
	
	private timer function FinisherEndEnableCamera( dt : float, id : int )
	{
		thePlayer.EnableManualCameraControl( true, 'Finisher' );
	}
	
	public function SpawnFinisherBlood()
	{
		var weaponEntity		: CEntity;
		var weaponSlotMatrix	: Matrix;
		var bloodFxPos			: Vector;
		var bloodFxRot			: EulerAngles;
		var tempEntity			: CEntity;
		
		weaponEntity = this.GetInventory().GetItemEntityUnsafe( GetInventory().GetItemFromSlot('r_weapon') );
		weaponEntity.CalcEntitySlotMatrix( 'blood_fx_point', weaponSlotMatrix );
		bloodFxPos = MatrixGetTranslation( weaponSlotMatrix );
		bloodFxRot = this.GetWorldRotation();//MatrixGetRotation( weaponSlotMatrix );
		tempEntity = theGame.CreateEntity( (CEntityTemplate)LoadResource('finisher_blood'), bloodFxPos, bloodFxRot);
		tempEntity.PlayEffect('crawl_blood');
	}

	//called when all combat actions have ended (e.g. whole combo)
	event OnCombatActionEndComplete()
	{
		var buff : CBaseGameplayEffect;
		
		buff = ChooseCurrentCriticalBuffForAnim();
		SetCombatAction( EBAT_EMPTY );
		
		//Unblock Actions what you wann
		UnblockAction( EIAB_DrawWeapon, 'OnCombatActionStart' );
		UnblockAction( EIAB_OpenInventory, 'OnCombatActionStart' );
		UnblockAction( EIAB_UsableItem, 'OnCombatActionStart' );
		
		UnblockAction( EIAB_DrawWeapon, 'OnCombatActionStart_Attack' );			
		
		SetUnpushableTarget( NULL );
		SetBIsInCombatAction(false);
		SetIsCurrentlyDodging(false);
		SetMoveTargetChangeAllowed( true );
		SetCanPlayHitAnim( true );
		
		SetFinisherVictim( NULL );
		
		this.RemoveBuffImmunity(EET_Burning, 'AnimEvent_RemoveBurning');
		
		if ( rangedWeapon && rangedWeapon.GetCurrentStateName() == 'State_WeaponWait' && !buff )
		{
			ClearCustomOrientationInfoStack();
			SetSlideTarget( NULL );
		}
		
		UnblockAction( EIAB_Crossbow, 'OnForceHolster' );
			
		specialAttackCamera = false;
		
		bIsRollAllowed = false;
		
		if ( bLAxisReleased )
		{
			ResetRawPlayerHeading();
			ResetCachedRawPlayerHeading();
		}
		
		//reapply critical buff if any
		ReapplyCriticalBuff();	
		SetBIsInputAllowed( true, 'OnCombatActionEndComplete' );
		
		//stamina regen is paused as long as we are doing some combat actions
		ResumeStaminaRegen( 'InsideCombatAction' );
		
		bIsInHitAnim = false;
		
		SetBIsCombatActionAllowed( true );
		
		m_LastWeaponTipPos = Vector(0, 0, 0, 0 );
		
		//free tickets
		this.AddTimer('FreeTickets',3.f,false);
		
		// remove save lock
		//theGame.ReleaseNoSaveLockByName( noSaveLockCombatActionName );
	}
	
	event OnMovementFullyBlended() 
	{
		SetBehaviorVariable( 'isPerformingSpecialAttack', 0.f );	
	
		if ( restoreUsableItem )
		{
			restoreUsableItem = false;
			SetPlayerActionToRestore ( PATR_Default );
			OnUseSelectedItem();
		}	
	}
	
	event OnCombatMovementStart()
	{
		SetCombatIdleStance( 1.f );
		OnCombatActionEndComplete();
	}
	
	timer function FreeTickets( dt : float, id : int )
	{
		FreeTicketAtCombatTarget();
	}
	
	
	/*
		These declarations are needed here only to call event with the same name inside combat state (there's no other way to call it!).
	*/
	event OnGuardedReleased(){}
	event OnPerformAttack( playerAttackType : name ){}
	event OnPerformEvade( playerEvadeType : EPlayerEvadeType ){}	
	event OnInterruptAttack(){}
	event OnPerformGuard(){}
	event OnSpawnHorse(){}
	event OnDismountActionScriptCallback(){}
	
	event OnHorseSummonStart()
	{
		thePlayer.BlockAction(EIAB_CallHorse,			'HorseSummon');
		thePlayer.BlockAction(EIAB_Signs,				'HorseSummon');
		thePlayer.BlockAction(EIAB_Crossbow,			'HorseSummon');
		thePlayer.BlockAction(EIAB_UsableItem,			'HorseSummon');
		thePlayer.BlockAction(EIAB_ThrowBomb,			'HorseSummon');
		thePlayer.BlockAction(EIAB_SwordAttack,			'HorseSummon');
		thePlayer.BlockAction(EIAB_Jump,				'HorseSummon');
		thePlayer.BlockAction(EIAB_Dodge,				'HorseSummon');
		thePlayer.BlockAction(EIAB_LightAttacks,		'HorseSummon');
		thePlayer.BlockAction(EIAB_HeavyAttacks,		'HorseSummon');
		thePlayer.BlockAction(EIAB_SpecialAttackLight,	'HorseSummon');
		thePlayer.BlockAction(EIAB_SpecialAttackHeavy,	'HorseSummon');
		
		horseSummonTimeStamp = theGame.GetEngineTimeAsSeconds();
	}
	
	event OnHorseSummonStop()
	{
		thePlayer.BlockAllActions('HorseSummon',false);
	}
	
	/*
		CombatAction events when on vehicles
	*/
	event OnCombatActionStartVehicle( action : EVehicleCombatAction )
	{
		this.SetBIsCombatActionAllowed( false );
		
		if ( action != EHCA_ShootCrossbow )
		{
			SetIsAimingCrossbow( false );
			OnRangedForceHolster();
		}		
	}
	
	event OnCombatActionEndVehicle()
	{
		this.SetBIsCombatActionAllowed( true );
	}

	////////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////  @CRITICAL STATES  /////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////////
	
	protected function CriticalBuffInformBehavior(buff : CBaseGameplayEffect)
	{
		/*if ( this.GetCurrentStateName() == 'Exploration' || this.GetCurrentStateName() == 'AimThrow' )
			GotoCombatStateWithAction( IA_CriticalState, buff );
		else
		{*/
			if( !CanAnimationReactToCriticalState( buff ) )
			{
				return;
			}
			
//			if ( IsInCombatAction() )
//				RaiseEvent('ForceBlendOut');
			
			SetBehaviorVariable( 'CriticalStateType', (int)GetBuffCriticalType(buff) );
			SetBehaviorVariable( 'bCriticalState', 1);	
		
			if(CriticalBuffUsesFullBodyAnim(buff))
				RaiseEvent('CriticalState');
			
			SetBehaviorVariable( 'IsInAir', (int)IsInAir());
			
			LogCritical("Sending player critical state event for <<" + buff.GetEffectType() + ">>");
			
		//}
	}
	
	private function CanAnimationReactToCriticalState( buff : CBaseGameplayEffect ) : bool
	{
		var buffCritical	: W3CriticalEffect;
		var buffCriticalDOT	: W3CriticalDOTEffect;
		var isHeavyCritical	: bool;
		
		isHeavyCritical	= false;
		
		// Find out if it is a heavy critical state
		buffCritical	= ( W3CriticalEffect ) buff;
		if( buffCritical )
		{
			isHeavyCritical	= buffCritical.explorationStateHandling == ECH_HandleNow;
		}
		else
		{
			buffCriticalDOT	= ( W3CriticalDOTEffect ) buff;
			if( buffCriticalDOT )
			{
				isHeavyCritical	= buffCriticalDOT.explorationStateHandling == ECH_HandleNow;
			}
		}
		
		// If it is not, we may skip it 
		if( !isHeavyCritical )
		{
			if( !CanReactToCriticalState() )
			{
				return false;
			}
		}
		
		return true;
	}
	
	public function CanReactToCriticalState() : bool
	{
		return substateManager.CanReactToHardCriticalState();
	}
		
	event OnCriticalStateAnimStart()
	{
		var heading : float;
		var newCritical : ECriticalStateType;
		var newReqCS : CBaseGameplayEffect;
		
		OnCombatActionEndComplete();
		
		//abort throwing if super was processed properly
		newReqCS = newRequestedCS;
		if(super.OnCriticalStateAnimStart())
		{
			//WhenCombatActionIsFinished();
			RemoveTimer( 'IsItemUseInputHeld' );
			keepRequestingCriticalAnimStart = false;
			CancelHoldAttacks();
			
			//knockdown direction
			// No knockdown when using a vehicule: the vehicule will handle the knock down logic
			//PFTODO
			//we need this for NPCs also (knockdown dir)
			if(!IsUsingVehicle())
			{
				newCritical = GetBuffCriticalType(newReqCS);
				if(newCritical == ECST_HeavyKnockdown 
					|| newCritical == ECST_Knockdown 
					|| newCritical == ECST_Stagger 
					|| newCritical == ECST_Ragdoll 
					|| newCritical == ECST_LongStagger )
				{
					if(newReqCS.GetCreator())
						heading = VecHeading(newReqCS.GetCreator().GetWorldPosition() - GetWorldPosition());
					else
						heading = GetHeading();
						
					//this.GetMovingAgentComponent().GetMovementAdjustor().CancelAll();	
					SetCustomRotation( 'Knockdown', heading, 2160.f, 0.1f, true );
					
					if ( newCritical != ECST_Stagger  && newCritical != ECST_LongStagger )
						substateManager.ReactOnCriticalState( true );
				}
			}
			
			theGame.GetBehTreeReactionManager().CreateReactionEventIfPossible( this, 'CriticalEffectStart', -1, 30.0f, -1.f, -1, true ); //reactionSystemSearch
			return true;
		}
		
		//SetBehaviorVariable( 'bCriticalStopped', 1);
		return false;
	}
	
	/*
		Called when new critical effect has started
		This will interrupt current critical state
		
		returns true if the effect got fired properly
	*/
	public function StartCSAnim(buff : CBaseGameplayEffect) : bool
	{
		SetBehaviorVariable( 'bCriticalStopped', 0 );

		if(super.StartCSAnim(buff))
		{
			if(!CriticalBuffUsesFullBodyAnim(buff))
			{
				OnCriticalStateAnimStart();
			}
		
			ResumeStaminaRegen( 'InsideCombatAction' );
		
			keepRequestingCriticalAnimStart = true;
			AddTimer('RequestCriticalAnimStart', 0, true);
			//RequestCriticalAnimStart(0);
			
			return true;
		}
		
		return false;
	}
	
	public function CriticalEffectAnimationInterrupted(reason : string) : bool
	{
		var ret : bool;	//for debug
		
		LogCriticalPlayer("R4Player.CriticalEffectAnimationInterrupted() - because: " + reason);
		
		ret = super.CriticalEffectAnimationInterrupted(reason);
		
		if(ret)
		{
			keepRequestingCriticalAnimStart = false;
		}
			
		substateManager.ReactOnCriticalState( false );
		
		return ret;
	}
	
	public function CriticalStateAnimStopped(forceRemoveBuff : bool)
	{
		LogCriticalPlayer("R4Player.CriticalStateAnimStopped() - forced: " + forceRemoveBuff);
		
		theGame.GetBehTreeReactionManager().CreateReactionEventIfPossible( this, 'RecoveredFromCriticalEffect', -1, 30.0f, -1.f, -1, true ); //reactionSystemSearch
		super.CriticalStateAnimStopped(forceRemoveBuff);
		
		substateManager.ReactOnCriticalState( false );
	}
	
	// keeps requesting (sending event) to enter critical states anim state in behavior
	timer function RequestCriticalAnimStart(dt : float, id : int)
	{	
		if(keepRequestingCriticalAnimStart)
		{
			if(newRequestedCS && newRequestedCS.GetDurationLeft() > 0)
			{
				CriticalBuffInformBehavior(newRequestedCS);
			}
			else
			{
				keepRequestingCriticalAnimStart = false;
				RemoveTimer('RequestCriticalAnimStart');
			}
		}
		else
		{
			RemoveTimer('RequestCriticalAnimStart');
		}
	}
	
	event OnRagdollUpdate(progress : float)
	{
		//super.OnRagdollUpdate(progress);
		
		SetIsInAir(progress == 0);
	}

	// getting from ragdoll after certain time has passed
	event OnRagdollOnGround()
	{
		// try to getup immediately as currently when laying on ground we might be constantly switched between on ground and in air
		TryToEndRagdollOnGround( 0.0f );
	}
	
	event OnRagdollInAir()
	{
		RemoveTimer('TryToEndRagdollOnGround');
	}

	event OnNoLongerInRagdoll()
	{
		RemoveTimer('TryToEndRagdollOnGround');
	}

	timer function TryToEndRagdollOnGround( td : float, optional id : int)
	{
		var critical : CBaseGameplayEffect;
		var type : EEffectType;

		critical = GetCurrentlyAnimatedCS();
		if(critical)
		{
			type = critical.GetEffectType();
			if(type == EET_Knockdown || type == EET_HeavyKnockdown || type == EET_Ragdoll)
			{
				// 2.5 seconds is not that long but this is not ragdoll simulator :)
				if (critical.GetTimeActive() >= 2.5f)
				{
					SetIsInAir(false);
					RequestCriticalAnimStop();
					RemoveTimer('TryToEndRagdollOnGround');
				}
				else
				{
					AddTimer('TryToEndRagdollOnGround', 0.2f, true);
				}
				return;
			}
		}
		
		// not in critical or type differs
		RemoveTimer('TryToEndRagdollOnGround');
	}
	
	public function RequestCriticalAnimStop(optional dontSetCriticalToStopped : bool)
	{
		var buff : CBaseGameplayEffect;
		
		buff = GetCurrentlyAnimatedCS();
		if(buff && !CriticalBuffUsesFullBodyAnim(buff))
		{			
			CriticalStateAnimStopped(false);			
		}
		
		if(!buff || !CriticalBuffUsesFullBodyAnim(buff))
		{
			SetBehaviorVariable( 'bCriticalState', 0);
		}
	
		super.RequestCriticalAnimStop(dontSetCriticalToStopped);
	}
	////////////////////////////////////////////////////////////////////////////////////////////
	// @Buffs @Effects
	////////////////////////////////////////////////////////////////////////////////////////////

	public function SimulateBuffTimePassing(simulatedTime : float)
	{
		effectManager.SimulateBuffTimePassing(simulatedTime);
	}

	public function AddEffectDefault(effectType : EEffectType, creat : CGameplayEntity, srcName : string, optional isSignEffect : bool) : EEffectInteract
	{
		var params : SCustomEffectParams;
		
		/*
			Welcome to the Ancient Pit. If you're here reading this then you're doomed...
			
			You're probably asking why someone is overriding default effect durations with some custom arbitrary numbers...
			
			The thuth is: noone remembers...
			
			But we need this and you cannot remove it or shit will start falling apart.
		*/
		if(effectType == EET_Stagger || effectType == EET_LongStagger || effectType == EET_Knockdown || effectType == EET_HeavyKnockdown)
		{
			params.effectType = effectType;
			params.creator = creat;
			params.sourceName = srcName;
			params.isSignEffect = isSignEffect;
			
			if ( effectType == EET_Stagger )
				params.duration = 1.83;
			else if ( effectType == EET_LongStagger )
				params.duration = 4;
			else if ( effectType == EET_Knockdown ) 
				params.duration = 2.5;
			else if ( effectType == EET_HeavyKnockdown ) 
				params.duration = 4;
				
			return super.AddEffectCustom(params);
		}
		else
		{
			return super.AddEffectDefault(effectType, creat, srcName, isSignEffect);
		}
	}
	
	
	////////////////////////////////////////////////////////////////////////////////////////////
	
	//a cheat to ressurect player
	public function CheatResurrect()
	{
		var items 		: array< SItemUniqueId >;
		var i, size, itemLevel, maxPrice, itemPrice 	: int;
		var itemToEquip : SItemUniqueId;

		if(IsAlive())
			return;
			
		
		if ( !theGame.GetGuiManager().GetRootMenu() )
		{
			Log(" *** Call this function after DeathScreen appears *** ");
			return;
		}
		
		SetAlive(true);
		
		SetKinematic(true);
	
		EnableFindTarget( true );
		SetBehaviorVariable( 'Ragdoll_Weight', 0.f );
		RaiseForceEvent( 'RecoverFromRagdoll' );
		SetCanPlayHitAnim( true );
		SetBehaviorVariable( 'CriticalStateType', (int)ECST_None );		
		GoToStateIfNew('Exploration');	

		( (CDismembermentComponent)this.GetComponent( 'Dismemberment' ) ).ClearVisibleWound();
		
		SetIsInAir(false);	//might block getup from ragdol in knockdown
		
		theInput.SetContext('Exploration');
		
		ResetDeathType();
		
		ForceUnlockAllInputActions(false);
		
		theGame.CloseMenu('DeathScreenMenu');
		
		//restore sounds
		theSound.LeaveGameState(ESGS_Death);

		//need to call stop/start functions, otherwise no auto HP regen, tox drain, etc. ever again
	 	abilityManager.ForceSetStat(BCS_Vitality, GetStatMax(BCS_Vitality));
		effectManager.StopVitalityRegen();
		abilityManager.ForceSetStat( BCS_Air , 100.f );
		effectManager.StopAirRegen();
		abilityManager.ForceSetStat( BCS_Stamina , 100.f );
		effectManager.StopStaminaRegen();
		abilityManager.ForceSetStat( BCS_Toxicity , 0.f );
		abilityManager.ForceSetStat( BCS_Focus , 0.f );
		GetWitcherPlayer().UpdateEncumbrance();

		//equip highest level sword in inventory that can be equipped
		if ( !inv.IsThereItemOnSlot( EES_SteelSword ) )
		{
			items = inv.GetItemsByCategory( 'steelsword' );
		}
		else if ( !inv.IsThereItemOnSlot( EES_SilverSword ) )
		{
			items = inv.GetItemsByCategory( 'silversword' );
		}
		
		size = items.Size();
		maxPrice = -1;
		for ( i = 0; i < size; i += 1 )
		{
			itemPrice = inv.GetItemPrice(items[i]);
			itemLevel = inv.GetItemLevel(items[i]);
			if ( itemLevel <= GetLevel() && itemPrice > maxPrice )
			{
				maxPrice = itemPrice;
				itemToEquip = items[i];
			}
		}
		if( inv.IsIdValid( itemToEquip ) )
		{
			EquipItem( itemToEquip , , true );
		}

		theGame.ReleaseNoSaveLock(deathNoSaveLock);
	}
	
	////////////////////////////////////////////////////////////////////////////////////////////
	
	public function SetIsInsideInteraction(b : bool)				{isInsideInteraction = b;}
	public function IsInsideInteraction() : bool					{return isInsideInteraction;}
	
	public function SetIsInsideHorseInteraction( b : bool, horse : CEntity )
	{
		isInsideHorseInteraction = b;
		horseInteractionSource = horse;
	}
	public function IsInsideHorseInteraction() : bool				{return isInsideHorseInteraction;}
		
	
	event OnInteractionActivationTest( interactionComponentName : string, activator : CEntity )
	{
		if ( interactionComponentName == "ClimbLadder" )
		{
			if( PlayerHasLadderExplorationReady() )
			{
				return true;
			}
		}
		
		return false;
	}
	
	private function PlayerHasLadderExplorationReady() : bool
	{
		if( !substateManager.CanInteract() )
		{
			return false;
		}
		
		if( !substateManager.m_SharedDataO.HasValidLadderExploration() )
		{
			return false;
		}
		
		return true;
	}
	
	////////////////////////////////////////////////////////////////////////////////////////////
	//////////////////////////////   @COMBAT   /////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////////
	
	public function SetGuarded(flag : bool)
	{
		super.SetGuarded(flag);
		
		if(flag && FactsQuerySum("tut_fight_use_slomo") > 0)
		{
			theGame.RemoveTimeScale( theGame.GetTimescaleSource(ETS_TutorialFight) );
			FactsRemove("tut_fight_slomo_ON");
		}
	}
	
	
	public function IsGuarded() : bool
	{
		return super.IsGuarded() && ( !rangedWeapon || rangedWeapon.GetCurrentStateName() == 'State_WeaponWait' );
	}
	////////////////////////////////////////////////////////////////////////////////////////////
	/////////////////////   @THROWABLE   @BOMBS   @PETARDS  @Usable ///////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////////
		
	public function GetSelectedItemId() : SItemUniqueId			{return selectedItemId;}
	public function ClearSelectedItemId()						{selectedItemId = GetInvalidUniqueId();}
	
	public function IsHoldingItemInLHand() : bool
	{
		return currentlyEquipedItemL != GetInvalidUniqueId();
	}
	
	public function GetCurrentlyUsedItemL () : W3UsableItem
	{
		return currentlyUsedItemL;
	}
	
	public function SetPlayerActionToRestore ( actionToRestoreType : EPlayerActionToRestore )
	{
		playerActionToRestore = actionToRestoreType;
	}
	
	public function IsCurrentlyUsingItemL () : bool
	{
		return currentlyUsingItem;
	}
	
	function BlockSlotsOnLItemUse ()
	{
		var slotsToBlock : array<name>;
		
		slotsToBlock.PushBack( 'Slot1' );
		slotsToBlock.PushBack( 'Slot2' );
		slotsToBlock.PushBack( 'Slot3' );
		slotsToBlock.PushBack( 'Slot4' );
		slotsToBlock.PushBack( 'Slot5' );
		slotsToBlock.PushBack( 'Yrden' );
		slotsToBlock.PushBack( 'Quen' );
		slotsToBlock.PushBack( 'Igni' );
		slotsToBlock.PushBack( 'Axii' );
		slotsToBlock.PushBack( 'Aard' );
		
		
		EnableRadialSlotsWithSource ( false, slotsToBlock, 'usableItemL' );
	}
	
	function UnblockSlotsOnLItemUse ()
	{
		var slotsToBlock : array<name>;
		
		slotsToBlock.PushBack( 'Slot1' );
		slotsToBlock.PushBack( 'Slot2' );
		slotsToBlock.PushBack( 'Slot3' );
		slotsToBlock.PushBack( 'Slot4' );
		slotsToBlock.PushBack( 'Slot5' );
		slotsToBlock.PushBack( 'Yrden' );
		slotsToBlock.PushBack( 'Quen' );
		slotsToBlock.PushBack( 'Igni' );
		slotsToBlock.PushBack( 'Axii' );
		slotsToBlock.PushBack( 'Aard' );
		
		
		EnableRadialSlotsWithSource ( true, slotsToBlock, 'usableItemL' );
	}
	
	function IsUsableItemLBlocked () : bool
	{
		return isUsableItemBlocked;
	}
	function HideUsableItem( optional force :  bool )
	{
		if( currentlyEquipedItemL != GetInvalidUniqueId() )
		{
			if( force )
			{
				if( !RaiseForceEvent( 'ItemEndL' ) )	
				{
					
					OnUsingItemsReset();
				}
				return;
				
			}
			RaiseEvent( 'ItemUseL' );
		}
	}
	function ProcessUsableItemsTransition ( actionToRestore : EPlayerActionToRestore )
	{
		var category 		: name;
		var signSkill 		: ESkill;
		
		category = inv.GetItemCategory ( selectedItemId );
		signSkill = SignEnumToSkillEnum( GetEquippedSign());
		
		switch ( actionToRestore )
		{
			case PATR_None:
				if ( currentlyUsedItemL )
				{
					inv.UnmountItem( currentlyEquipedItemL, true );
				}
				currentlyEquipedItemL = GetInvalidUniqueId();
				return;
	
			case PATR_Default:
				if ( IsSlotQuickslot( inv.GetSlotForItemId ( selectedItemId )) && category == 'usable' &&  currentlyEquipedItemL != selectedItemId )
				{
					if ( currentlyUsedItemL )
					{
						inv.UnmountItem( currentlyEquipedItemL, true );
					}
					currentlyEquipedItemL = GetInvalidUniqueId();
					OnUseSelectedItem();
					return;
				}
				break;
			case PATR_Crossbow:
				if ( inv.IsItemCrossbow ( selectedItemId ) )
				{
					if ( currentlyUsedItemL )
					{
						inv.UnmountItem( currentlyEquipedItemL, true );
					}
					currentlyEquipedItemL = GetInvalidUniqueId();
					SetIsAimingCrossbow( true );
					
					if ( theInput.IsActionPressed( 'ThrowItem' ) )
						SetupCombatAction( EBAT_ItemUse, BS_Pressed );
					else
					{
						SetupCombatAction( EBAT_ItemUse, BS_Pressed );
						SetupCombatAction( EBAT_ItemUse, BS_Released );
					}
					return;
				}
				break;
			case PATR_CastSign:
				if( signSkill != S_SUndefined && playerActionToRestore == PATR_CastSign  )
				{
					if ( currentlyUsedItemL )
					{
						inv.UnmountItem( currentlyEquipedItemL, true );
					}
					currentlyEquipedItemL = GetInvalidUniqueId();
					
					if( HasStaminaToUseSkill( signSkill, false ) )
					{
						if( GetInvalidUniqueId() != inv.GetItemFromSlot( 'l_weapon' ) )
							PushCombatActionOnBuffer( EBAT_CastSign, BS_Pressed );
						else
							SetupCombatAction( EBAT_CastSign, BS_Pressed );
					}
					else
					{
						thePlayer.SoundEvent("gui_no_stamina");
					}
					return;
				}
				break;
			case PATR_ThrowBomb:
				if ( inv.IsItemBomb ( selectedItemId ) )
				{
					if ( currentlyUsedItemL )
					{
						inv.UnmountItem( currentlyEquipedItemL, true );
					}
					currentlyEquipedItemL = GetInvalidUniqueId();
					PrepareToAttack();
					SetupCombatAction( EBAT_ItemUse, BS_Pressed );
					return;
				}
				break;
			case PATR_CallHorse:
				theGame.OnSpawnPlayerHorse();
				break;
			default:
				if ( currentlyUsedItemL )
				{
					inv.UnmountItem( currentlyEquipedItemL, true );
				}
				currentlyEquipedItemL = GetInvalidUniqueId();
				return;
		}
		if ( currentlyUsedItemL )
		{
			inv.UnmountItem( currentlyEquipedItemL, true );
		}
		currentlyEquipedItemL = GetInvalidUniqueId();
	}
	
	function GetUsableItemLtransitionAllowed () : bool
	{
		return isUsableItemLtransitionAllowed;
	}
	
	function SetUsableItemLtransitionAllowed ( isAllowed : bool) 
	{
		isUsableItemLtransitionAllowed = isAllowed;
	}
	
	event OnItemUseLUnBlocked ()
	{
		if ( isUsableItemBlocked )
		{
			isUsableItemBlocked = false;
			UnblockSlotsOnLItemUse ();
		}
	}
	
	event OnItemUseLBlocked ()
	{
		if ( !isUsableItemBlocked )
		{
			isUsableItemBlocked = true;
			BlockSlotsOnLItemUse ();
		}
	}
	
	event OnUsingItemsReset()
	{
		if ( currentlyUsingItem )
		{
			OnItemUseLUnBlocked ();
			OnUsingItemsComplete();
		}
	}
	event OnUsingItemsComplete ()
	{
		if ( isUsableItemBlocked )
		{
			OnItemUseLUnBlocked ();
		}
		currentlyUsingItem = false;
		if ( GetUsableItemLtransitionAllowed () )
		{
			ProcessUsableItemsTransition( playerActionToRestore );
		}
		else
		{
			if ( currentlyUsedItemL )
			{
				inv.UnmountItem( currentlyEquipedItemL, true );
			}
			currentlyEquipedItemL = GetInvalidUniqueId();
		}
		
		SetPlayerActionToRestore ( PATR_Default );
	}
	
	event OnUseSelectedItem( optional force :  bool )
	{
		var category : name;
		var itemEntity : W3UsableItem;
		
		if ( isUsableItemBlocked && !force )
		{
			return false;
		}
		if ( IsCastingSign() )
			return false;
		
		if ( currentlyEquipedItemL != GetInvalidUniqueId() )
		{
			SetBehaviorVariable( 'SelectedItemL', (int)GetUsableItemTypeById( currentlyEquipedItemL ), true );		
			if ( force )
			{
				if ( RaiseEvent( 'ItemEndL' ) )
				{
					SetUsableItemLtransitionAllowed ( true );
					return true;
				}
			}
			else
			{
				if ( RaiseEvent( 'ItemUseL' ) )
				{
					SetUsableItemLtransitionAllowed ( true );
					return true;
				}
			}
		}
		else
		{
			category = inv.GetItemCategory( selectedItemId );
			if( category != 'usable' )
			{
				return false;
			}
			SetBehaviorVariable( 'SelectedItemL', (int)GetUsableItemTypeById( selectedItemId ), true );
			if( RaiseEvent( 'ItemUseL' ) )
			{	
				currentlyEquipedItemL = selectedItemId;
				SetUsableItemLtransitionAllowed ( false );
				currentlyUsingItem = true;
		
				return true;
			}
			inv.UnmountItem( selectedItemId, true );
		}
	}
	
	protected saved var currentlyUsingItem : bool;
	
	public function ProcessUseSelectedItem( itemEntity : W3UsableItem, optional shouldCallOnUsed : bool )
	{
		currentlyUsedItemL = itemEntity;
		DrainStamina(ESAT_UsableItem);
			
		if ( shouldCallOnUsed )
		{
			currentlyUsedItemL.OnUsed( thePlayer );
		}
	}
	
	function GetUsableItemTypeById ( itemId : SItemUniqueId ) : EUsableItemType
	{
		var itemName : name;
		
		itemName = inv.GetItemName ( itemId );
		
		return theGame.GetDefinitionsManager().GetUsableItemType ( itemName );
				
	}
	
	// Starts the 'WaitForItemSpawnAndProccesTask' task
	public function StartWaitForItemSpawnAndProccesTask()
	{
		AddTimer( 'WaitForItemSpawnAndProccesTask', 0.001f, true,,,,true );
	}
	
	// Kills the 'WaitForItemSpawnAndProccesTask' task
	public function KillWaitForItemSpawnAndProccesTask()
	{
		RemoveTimer ( 'WaitForItemSpawnAndProccesTask' );
	}
	
	// Informs the 'WaitForItemSpawnAndProccesTask' task, that selected item should be used ASAP.
	// Flag will be reset by the task itself
	public function AllowUseSelectedItem()
	{
		m_useSelectedItemIfSpawned = true;
	}
	
	// Task waits for inventory to created selected item. Item will be used ASAP as the task is allowed to do so.
	// Right after that - it kills itself.
	timer function WaitForItemSpawnAndProccesTask( timeDelta : float , id : int )
	{
		var itemEntity : W3UsableItem;
		var canTaskBeKilled : bool;
		canTaskBeKilled = false;
	
		if ( IsCastingSign() )
		{
			return;
		}
	
		// selectad item is wrong!
		if ( selectedItemId == GetInvalidUniqueId() )
		{
			canTaskBeKilled = true;
		}
			
		itemEntity = (W3UsableItem)inv.GetItemEntityUnsafe( selectedItemId );
		if ( itemEntity && m_useSelectedItemIfSpawned )
		{
			// we have selected item and we are allowed to use it, so to it and kill itself.
			canTaskBeKilled = true;
			m_useSelectedItemIfSpawned = false; 			// reset flag
			ProcessUseSelectedItem( itemEntity, true );	 
		}
		
		if ( canTaskBeKilled )
		{
			KillWaitForItemSpawnAndProccesTask();
		}
	}
	
	event OnBombProjectileReleased()
	{
		ResetRawPlayerHeading();	
		UnblockAction(EIAB_ThrowBomb, 'BombThrow');
		UnblockAction(EIAB_Crossbow, 'BombThrow');
		
		if(GetCurrentStateName() == 'AimThrow')
			PopState();
			
		FactsAdd("ach_bomb", 1, 4 );
		theGame.GetGamerProfile().CheckLearningTheRopes();
	}
	
	public function SetIsThrowingItemWithAim(b : bool)
	{
		isThrowingItemWithAim = b;
	}
	
	public function SetIsThrowingItem( flag : bool )			{isThrowingItem = flag;}
	public function IsThrowingItem() : bool						{return isThrowingItem;}	
	public function IsThrowingItemWithAim() : bool				{return isThrowingItemWithAim;}
	public function SetThrowHold(b : bool)						{isThrowHoldPressed = b;}
	public function IsThrowHold() : bool						{return isThrowHoldPressed;}
	public function SetIsAimingCrossbow( flag : bool )			{isAimingCrossbow = flag;}
	public function GetIsAimingCrossbow() : bool				{return isAimingCrossbow;}	
	
	event OnThrowAnimLeave()
	{
		var throwStage : EThrowStage;
		var thrownEntity		: CThrowable;
		
		thrownEntity = (CThrowable)EntityHandleGet( thrownEntityHandle );
		
		if(thrownEntity && !thrownEntity.WasThrown())
		{
			throwStage = (int)GetBehaviorVariable( 'throwStage', (int)TS_Stop);		
			if(inv.IsItemBomb(selectedItemId))
			{
				BombThrowCleanUp();
			}
			else
			{
				ThrowingAbort();
			}
		}
		
		thrownEntity = NULL;
		SetIsThrowingItem( false );
		SetIsThrowingItemWithAim( false );
		
		this.EnableRadialSlotsWithSource( true, this.radialSlots, 'throwBomb' );	
		UnblockAction(EIAB_ThrowBomb, 'BombThrow');
		UnblockAction(EIAB_Crossbow, 'BombThrow');
	}
	
	//Called when bomb throwing has started - it is ensured that we CAN throw it. At this point we don't know yet if it's a quick throw or aimed throw
	protected function BombThrowStart()
	{
		var slideTargetActor : CActor;
	
		BlockAction( EIAB_ThrowBomb, 'BombThrow' );
		BlockAction(EIAB_Crossbow, 'BombThrow');
		
		SetBehaviorVariable( 'throwStage', (int)TS_Start );		
		SetBehaviorVariable( 'combatActionType', (int)CAT_ItemThrow );
		
		if ( slideTarget )
		{
			AddCustomOrientationTarget( OT_Actor, 'BombThrow' );
			
			slideTargetActor = (CActor)( slideTarget );
			
			//AK BOMB: moved rotation from anim event to scripts to prevent rotation to friendly and neutral npcs.
			// removed the check after commenting out ProcessCanAttackWhenNotInCombatBomb
			//if( !slideTargetActor || ( slideTargetActor && GetAttitudeBetween(this, slideTarget) == AIA_Hostile ) )
			//	SetCustomRotation( 'Throw', VecHeading( slideTarget.GetWorldPosition() - GetWorldPosition() ), 0.0f, 0.3f, false );
		}
		else
		{
			if ( lastAxisInputIsMovement )
				AddCustomOrientationTarget( OT_Actor, 'BombThrow' );
			else
				AddCustomOrientationTarget( OT_Camera, 'BombThrow' );
		}
		
		UpdateLookAtTarget();
		SetCustomRotation( 'Throw', VecHeading( this.GetLookAtPosition() - GetWorldPosition() ), 0.0f, 0.3f, false );
		
		SetBehaviorVariable( 'itemType', (int)IT_Petard );
		
		ProcessCanAttackWhenNotInCombatBomb();
		
		if ( RaiseForceEvent('CombatAction') )
			OnCombatActionStart();
		
		//FIXME might be aborted afterwards and no bomb would be thrown actually
		theTelemetry.LogWithLabel(TE_FIGHT_HERO_THROWS_BOMB, inv.GetItemName( selectedItemId ));	
	}
	
	//from animation
	event OnThrowAnimStart()
	{
		var itemId : SItemUniqueId;
		var thrownEntity		: CThrowable;
		//Disable slots on radial menu
		this.radialSlots.Clear();
		GetWitcherPlayer().GetItemEquippedOnSlot(EES_Petard1, itemId );
		
		if( GetSelectedItemId() == itemId )
		{
			this.radialSlots.PushBack( 'Slot2' );
		}
		else
		{
			this.radialSlots.PushBack( 'Slot1' );
		}
		this.radialSlots.PushBack( 'Slot3' );
		this.radialSlots.PushBack( 'Slot4' );
		this.radialSlots.PushBack( 'Slot5' );
		this.EnableRadialSlotsWithSource( false, this.radialSlots, 'throwBomb' );		
	
		thrownEntity = (CThrowable)inv.GetDeploymentItemEntity( selectedItemId,,,true );
		thrownEntity.Initialize( this, selectedItemId );
		EntityHandleSet( thrownEntityHandle, thrownEntity );
		SetIsThrowingItem( true );
	}
	
	public function BombThrowAbort()
	{
		BombThrowCleanUp();
		UnblockAction( EIAB_ThrowBomb, 'BombThrow' );
		UnblockAction(EIAB_Crossbow, 'BombThrow');
	}
	
	private function BombThrowCleanUp()
	{
		var throwStage : EThrowStage;
		var thrownEntity		: CThrowable;
		var vehicle : CVehicleComponent; 
		
		thrownEntity = (CThrowable)EntityHandleGet( thrownEntityHandle );
		
		this.EnableRadialSlotsWithSource( true, this.radialSlots, 'throwBomb'  );	
		throwStage = (int)GetBehaviorVariable( 'throwStage', (int)TS_Stop);
				
		SetBehaviorVariable( 'throwStage', (int)TS_Stop );

		if( GetCurrentStateName() == 'AimThrow')
		{
			PopState();
			thrownEntity.StopAiming( true );	
		}
		else if ( this.IsUsingHorse() )
		{
			vehicle = (CVehicleComponent)(GetUsedVehicle().GetComponentByClassName('CVehicleComponent'));
			vehicle.GetUserCombatManager().OnForceItemActionAbort();
		}
			
		//if bomb was not detached yet (is not flying)
		if(thrownEntity && !thrownEntity.WasThrown())
		{ 
			thrownEntity.BreakAttachment();
			thrownEntity.Destroy();
		}
	
		thrownEntity = NULL;
		SetIsThrowingItem( false );
		SetIsThrowingItemWithAim( false );
		RemoveCustomOrientationTarget( 'BombThrow' );		
	}
	
	public function ProcessCanAttackWhenNotInCombatBomb()
	{
		var targets : array< CGameplayEntity >;
		var temp, throwVector, throwFrom, throwTo, throwVectorU : Vector;
		var temp_n : name;
		var throwVecLen : float;
		var component : CComponent;
		/* //AK BOMB: keeping it just in case we need to bring it back
		var impactRange : float;
		var entities	: array<CGameplayEntity>;
		var ent 		: CEntity;
		var actor		: CActor;
		var petard		: W3Petard;
		var vehicle		: CEntity;
		var slotMatrix	: Matrix;
		var isShootingFriendly	: bool;
		
		
		if ( thrownEntity )
		{
			petard = (W3Petard)( thrownEntity );
			
			if ( !IsThreatened() )
			{
				if ( this.playerAiming.GetCurrentStateName() == 'Aiming' )
					ent = playerAiming.GetSweptFriendly();
				else
					actor = (CActor)GetDisplayTarget();
				
				if( ent || ( actor && actor.IsHuman() && !IsThreat( actor ) ) )
					SetIsShootingFriendly( true );
				else
					SetIsShootingFriendly( false );				
			}
			else
				SetIsShootingFriendly( false );				
		}
		else
			SetIsShootingFriendly( false );
		*/
		
		//Quest can lock bomb throwing to allow bombs to throw only at specific targets
		if( FactsQuerySum( "BombThrowSpecificTargets" ) > 0 )
		{
			//more optimal but less accurate version
			//FindGameplayEntitiesCloseToPoint( targets, playerAiming.GetThrowPosition(), 2.f, 20, 'BombThrowSpecificTarget' );
			//SetIsShootingFriendly( targets.Size() == 0 );
			
			//fun fact - without breaking all calculations into separate variables this code doesn't work...
			throwFrom = playerAiming.GetThrowStartPosition();
			throwTo = playerAiming.GetThrowPosition();
			throwVector = throwTo - throwFrom;
			throwVecLen = VecDistance( throwFrom, throwTo );
			throwVectorU =  throwVector / throwVecLen;
			if( theGame.GetWorld().StaticTraceWithAdditionalInfo( throwFrom, throwTo + throwVectorU, temp, temp, temp_n, component ) && component && component.GetEntity().HasTag( 'BombThrowSpecificTarget' ) )
			{
				SetIsShootingFriendly( false );
			}
			else
			{
				SetIsShootingFriendly( true );
			}
		}
		else if( FactsQuerySum( "BombThrowDisallowSpecificTargets" ) > 0 )
		{
			//fun fact - without breaking all calculations into separate variables this code doesn't work...
			throwFrom = playerAiming.GetThrowStartPosition();
			throwTo = playerAiming.GetThrowPosition();
			throwVector = throwTo - throwFrom;
			throwVecLen = VecDistance( throwFrom, throwTo );
			throwVectorU =  throwVector / throwVecLen;
			if( theGame.GetWorld().StaticTraceWithAdditionalInfo( throwFrom, throwTo + throwVectorU, temp, temp, temp_n, component ) && component && component.GetEntity().HasTag( 'BombThrowDisallowedTarget' ) )
			{
				SetIsShootingFriendly( true );
			}
			else
			{
				SetIsShootingFriendly( false );
			}
		}
		else
		{
			SetIsShootingFriendly( false );
		}
		
		SetBehaviorVariable( 'isShootingFriendly', (float)( GetIsShootingFriendly() ) );		
	}

	public function SetIsShootingFriendly( flag : bool )
	{
		isShootingFriendly = flag;
	}

	public function GetIsShootingFriendly() : bool
	{
		return isShootingFriendly;
	}
	
	//only for usable items
	protected function UsableItemStart()
	{
		var thrownEntity : CThrowable;
		
		//this seems like bullshit but it's because usable items use the same code as throwing bombs and shooting crossbow
		thrownEntity = (CThrowable)inv.GetDeploymentItemEntity( selectedItemId,,,true );
		thrownEntity.Initialize( this, selectedItemId );
		EntityHandleSet( thrownEntityHandle, thrownEntity );
		SetBehaviorVariable( 'throwStage', (int)TS_Start );
		SetIsThrowingItem( true );
		SetBehaviorVariable( 'combatActionType', (int)CAT_ItemThrow );
		
		if ( slideTarget )
		{
			AddCustomOrientationTarget( OT_Actor, 'UsableItems' );
		}
		else
		{
			if ( lastAxisInputIsMovement )
				AddCustomOrientationTarget( OT_Actor, 'UsableItems' );
			else
				AddCustomOrientationTarget( OT_Camera, 'UsableItems' );		
		}
		
		SetBehaviorVariable( 'itemType', (int)(-1) );
		
		if ( RaiseForceEvent('CombatAction') )
			OnCombatActionStart();
	}
	
	protected function BombThrowRelease()
	{
		var stateName : name;
		
		stateName = playerAiming.GetCurrentStateName();
		OnDelayOrientationChangeOff();
		
		if( GetIsShootingFriendly() || ( FactsQuerySum( "BombThrowSpecificTargets" ) > 0 && stateName != 'Aiming' ) )
		{
			BombThrowAbort();
		}
		else
		{
			SetBehaviorVariable( 'throwStage', (int)TS_End );
			
			if ( stateName == 'Aiming' )
			{
				SetCustomRotation( 'Throw', VecHeading( this.GetLookAtPosition() - GetWorldPosition() ), 0.0f, 0.2f, false );
			}
		}
	}
	
	protected function UsableItemRelease()
	{
		OnDelayOrientationChangeOff();
		SetBehaviorVariable( 'throwStage', (int)TS_End );
		RemoveCustomOrientationTarget( 'UsableItems' );		
	}
			
	// Called when usable item use or crossbow shot was aborted (bombs use different function)
	public function ThrowingAbort()
	{
		var thrownEntity		: CThrowable;
		
		thrownEntity = (CThrowable)EntityHandleGet( thrownEntityHandle );
		
		SetBehaviorVariable( 'throwStage', (int)TS_Stop );
		RaiseEvent( 'actionStop' );

		if( GetCurrentStateName() == 'AimThrow')
		{
			PopState();
			thrownEntity.StopAiming( true );
		}
		
		//if bomb was not detached yet (is not flying)
		if(thrownEntity && !thrownEntity.WasThrown())
		{ 
			thrownEntity.BreakAttachment();
			thrownEntity.Destroy();
		}
		this.EnableRadialSlotsWithSource( true, this.radialSlots, 'throwBomb' );	
	}
	
	public function CanSetupCombatAction_Throw() : bool
	{
		//if has item selected
		if(!inv.IsIdValid( selectedItemId ))
			return false;
			
		//if not a throwable item
		if(!inv.IsItemSingletonItem(selectedItemId))
			return false;
			
		//if input is not blocked
		if(!GetBIsInputAllowed())
			return false;
			
		//if has ammo
		if(inv.GetItemQuantity(GetSelectedItemId()) <= 0 && !inv.ItemHasTag(selectedItemId, theGame.params.TAG_INFINITE_AMMO))
			return false;
			
		//if action is not blocked or (HACK) we're in swimming
		if(!inputHandler.IsActionAllowed(EIAB_ThrowBomb) && GetCurrentStateName() != 'Swimming')
			return false;
	
		return true;
	}
	
	public function GetThrownEntity() : CThrowable
	{
		return (CThrowable)EntityHandleGet( thrownEntityHandle );
	}
	
	// Crossbow events and  functions
	event OnWeaponWait()			{ rangedWeapon.OnWeaponWait(); }
	event OnWeaponDrawStart()		{ rangedWeapon.OnWeaponDrawStart(); }
	event OnWeaponReloadStart() 	{ rangedWeapon.OnWeaponReloadStart(); }
	event OnWeaponReloadEnd()		{ rangedWeapon.OnWeaponReloadEnd(); }
	event OnWeaponAimStart()		{ rangedWeapon.OnWeaponAimStart(); }
	event OnWeaponShootStart()		{ rangedWeapon.OnWeaponShootStart(); }
	event OnWeaponShootEnd()		{ rangedWeapon.OnWeaponShootEnd(); }
	event OnWeaponAimEnd()			{ rangedWeapon.OnWeaponAimEnd(); }
	event OnWeaponHolsterStart()	{ rangedWeapon.OnWeaponHolsterStart(); }
	event OnWeaponHolsterEnd()		{ rangedWeapon.OnWeaponHolsterEnd(); }
	event OnWeaponToNormalTransStart() { rangedWeapon.OnWeaponToNormalTransStart(); }
	event OnWeaponToNormalTransEnd() { rangedWeapon.OnWeaponToNormalTransEnd(); }
	
	event OnEnableAimingMode( enable : bool )
	{
		if( !crossbowDontPopStateHack )
		{
			if ( enable )
				PushState( 'AimThrow' );
			else if ( GetCurrentStateName() == 'AimThrow' )
				PopState();
		}
	}
	
	event OnRangedForceHolster( optional forceUpperBodyAnim, instant, dropItem : bool )
	{
		if(rangedWeapon)
			rangedWeapon.OnForceHolster( forceUpperBodyAnim, instant, dropItem );
	}
	
	
	public function IsCrossbowHeld() : bool
	{	
		if (rangedWeapon)
			return rangedWeapon.GetCurrentStateName() != 'State_WeaponWait';
		return false;
	}
	
	// Tickets
	event OnBlockAllCombatTickets( release : bool )
	{
		if (!release )
			((CR4PlayerStateCombat)GetState('Combat')).OnBlockAllCombatTickets(false); 
	}
	event OnForceTicketUpdate()						{}

	////////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////  @ATTACKS 		   /////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////////
	
	/*script*/ event OnProcessActionPost(action : W3DamageAction)
	{
		var npc : CNewNPC;
		var attackAction : W3Action_Attack;
		var lifeLeech : float;
		
		super.OnProcessActionPost(action);
		
		attackAction = (W3Action_Attack)action;
		
		if(attackAction)
		{
			npc = (CNewNPC)action.victim;
			
			if(npc && npc.IsHuman() )
			{
				PlayBattleCry('BattleCryHumansHit', 0.05f );
			}
			else
			{
				PlayBattleCry('BattleCryMonstersHit', 0.05f );
			}
			
			if(attackAction.IsActionMelee())
			{
				//uninterrupted hits counting
				IncreaseUninterruptedHitsCount();
				
				//camera shake
				if( IsLightAttack( attackAction.GetAttackName() ) )
				{
					GCameraShake(0.1, false, GetWorldPosition(), 10);
				}
				
				//Caretaker Shovel life steal
				if(npc && inv.GetItemName(attackAction.GetWeaponId()) == 'PC Caretaker Shovel')
				{
					//inv.PlayItemEffect( items[i], 'stab_attack' );
					lifeLeech = CalculateAttributeValue(inv.GetItemAttributeValue(attackAction.GetWeaponId() ,'lifesteal'));
					if (npc.UsesVitality())
						lifeLeech *= action.processedDmg.vitalityDamage;
					else if (UsesEssence())
						lifeLeech *= action.processedDmg.essenceDamage;
					else
						lifeLeech = 0;
						
					if ( lifeLeech > 0 )
					{
						inv.PlayItemEffect( attackAction.GetWeaponId(), 'stab_attack' );
						PlayEffect('drain_energy_caretaker_shovel');		
						GainStat(BCS_Vitality, lifeLeech);
					}
				}
			}
		}
	}
	
	public function SetHitReactTransScale(f : float)			{hitReactTransScale = f;}
	public function GetHitReactTransScale() : float				
	{
		if ( ( (CNewNPC)slideTarget ).GetIsTranslationScaled() )
			return hitReactTransScale;
		else
			return 1.f;
	}
		
	////////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////  @HORSE  		   /////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////////
	
	public function GetHorseWithInventory() : CNewNPC
	{
		return (CNewNPC)EntityHandleGet( horseWithInventory );
	}
	public function GetHorseCurrentlyMounted() : CNewNPC
	{
		return currentlyMountedHorse;
	}
	// Do not use outside of vehicle component
	public function _SetHorseCurrentlyMounted( horse : CNewNPC )
	{
		currentlyMountedHorse = horse;
	}
	
	public function WasHorseRecentlySummoned() : bool
	{
		if ( horseSummonTimeStamp + 5.f > theGame.GetEngineTimeAsSeconds() )
			return true;
			
		return false;
	}
	
	private const var MOUNT_DISTANCE_CBT : float;
	default MOUNT_DISTANCE_CBT = 3.0;
	
	private const var MOUNT_ANGLE_CBT : float;
	default MOUNT_ANGLE_CBT = 35.0;
	
	private const var MOUNT_ANGLE_EXP : float;
	default MOUNT_ANGLE_EXP = 45.0;
	
	public function IsMountingHorseAllowed( optional alwaysAllowedInExploration : bool ) : bool
	{
		var angle : float;
		var distance : float;
		
		if( IsInsideHorseInteraction() )
		{
			angle = AngleDistance( thePlayer.rawPlayerHeading, VecHeading( thePlayer.horseInteractionSource.GetWorldPosition() - thePlayer.GetWorldPosition() ) );
			
			if( thePlayer.IsInCombat() )
			{
				if( AbsF( angle ) < MOUNT_ANGLE_CBT )
				{
					distance = VecDistance( thePlayer.GetWorldPosition(), thePlayer.horseInteractionSource.GetWorldPosition() );
					
					if( distance < MOUNT_DISTANCE_CBT )
					{
						return true;
					}
					else
					{	
						return false;
					}
				}
				else
				{
					return false;
				}
			
			}
			else
			{
				if( alwaysAllowedInExploration )
				{
					return true;
				}
				else
				{
					if( AbsF( angle ) < MOUNT_ANGLE_EXP )
					{
						return true;
					}
					else
					{
						return false;
					}
				}
			}
		}
		else
		{
			return false;
		}
	}
	
	public function FollowActor( actor : CActor ) 
	{
		var l_aiTreeDecorator		: CAIPlayerActionDecorator;
		var l_aiTree_onFoot			: CAIFollowSideBySideAction;
		var l_aiTree_onHorse		: CAIRiderFollowSideBySideAction;
		var l_success				: bool = false;
		
		actor.AddTag( 'playerFollowing' );
	
		if( thePlayer.IsUsingHorse() )
		{
			l_aiTree_onHorse = new CAIRiderFollowSideBySideAction in this;
			l_aiTree_onHorse.OnCreated();
	
			l_aiTree_onHorse.params.targetTag = 'playerFollowing';
		}
		else
		{
			l_aiTree_onFoot = new CAIFollowSideBySideAction in this;
			l_aiTree_onFoot.OnCreated();
	
			l_aiTree_onFoot.params.targetTag = 'playerFollowing';
		}
		
		l_aiTreeDecorator = new CAIPlayerActionDecorator in this;
		l_aiTreeDecorator.OnCreated();
		l_aiTreeDecorator.interruptOnInput 	= false;
		
		if( thePlayer.IsUsingHorse() )
			l_aiTreeDecorator.scriptedAction 	= l_aiTree_onHorse;	
		else
			l_aiTreeDecorator.scriptedAction 	= l_aiTree_onFoot;	

		if( l_aiTreeDecorator )
			l_success = ForceAIBehavior( l_aiTreeDecorator, BTAP_Emergency );
		else if( thePlayer.IsUsingHorse() )
			l_success = ForceAIBehavior( l_aiTree_onHorse, BTAP_Emergency );
		else
			l_success = ForceAIBehavior( l_aiTree_onFoot, BTAP_Emergency );
			
		if ( l_success )
		{
			GetMovingAgentComponent().SetGameplayRelativeMoveSpeed( 0.0f );
		}
	}
	
	public function SetCanFollowNpc( val : bool, actor : CActor ) { canFollowNpc = val; actorToFollow = actor; }
	public function CanFollowNpc() : bool { return canFollowNpc; }
	public function GetActorToFollow() : CActor { return actorToFollow; }

	/*public function SetIsFollowing( val : bool )
	{ 
		isFollowing = val; 
		
		if( val )
			followingStartTime = theGame.GetEngineTimeAsSeconds();
		else
			followingStartTime = 0.0;
	}
	public function GetFollowingStartTime() : float { return followingStartTime; }
	public function IsFollowing() : bool { return isFollowing; }
	
	timer function ResetIsFollowing( td : float, id : int )
	{
		isFollowing = false;
	}*/
	
	////////////////////////////////////////////////////////////////////////////////////////////
	/////////////////////   @SWIMMING   ////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////////
	
	public function SetIsSwimming ( toggle : bool )		
	{ 
		if( isSwimming != toggle )
		{			
			thePlayer.substateManager.SetBehaviorParamBool( 'isSwimmingForOverlay', toggle );
			isSwimming = toggle;
		}	
	}
	//public function IsSwimming () : bool				{ return isSwimming;	}
	
	////////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////  @DURABILITY  //////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////////
	
	//returns true if repaired
	public function RepairItemUsingConsumable(item, consumable : SItemUniqueId) : bool
	{
		var curr, max, repairValue, itemValue, repairBonus, newDurability : float;
	
		//basic check
		if(!inv.IsIdValid(item) || !inv.IsIdValid(consumable) || !inv.HasItemDurability(item))
			return false;
			
		curr = inv.GetItemDurability(item);
		max = inv.GetItemMaxDurability(item);
		
		//check durability level
		if(curr > max)
			return false;
			
		//check consumable type
		if( (inv.IsItemAnyArmor(item) && inv.ItemHasTag(consumable, theGame.params.TAG_REPAIR_CONSUMABLE_ARMOR)) ||
			(inv.IsItemSilverSwordUsableByPlayer(item) && inv.ItemHasTag(consumable, theGame.params.TAG_REPAIR_CONSUMABLE_SILVER)) ||
			(inv.IsItemSteelSwordUsableByPlayer(item) && inv.ItemHasTag(consumable, theGame.params.TAG_REPAIR_CONSUMABLE_STEEL))  )
		{
			//item stats
			itemValue = CalculateAttributeValue(inv.GetItemAttributeValue(consumable, 'durabilityRepairValue'));
			if(itemValue <= 0)
			{
				LogAssert(false, "CR4Player.RepairItemUsingConsumable: consumable <<" + inv.GetItemName(consumable) + ">> has <=0 durabilityRepairValue!!!");
				return false;
			}
			repairBonus = CalculateAttributeValue(inv.GetItemAttributeValue(consumable, 'durabilityBonusValue'));
						
			//calculate
			repairValue = max * itemValue /100;
			
			/* disabled repairing over 100%
			if(HasBookPerk(S_Book_28))
				max = max * (1 + (repairBonus + perkValue) /100);
			*/
			
			newDurability = MinF(max, curr + repairValue);
			
			inv.SetItemDurabilityScript(item, newDurability);
			
			//consume
			inv.RemoveItem(consumable);
			
			return true;
		}
		return false;
	}
	
	////////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////  @PushingObject 		   /////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////////////////////////////
	/*
	event OnRigidBodyCollision( component : CComponent, actorIndex : int, shapeIndex : int )
	{
		pushableComponent = component;
		if ( pushableComponent )
			this.RaiseEvent('PushObject');
		
		//component.ApplyForceAtPointToPhysicalObject
	}
	
	event OnRigidBodyExit( component : CComponent )
	{
		this.RaiseEvent('PushObjectEnd');
		pushableComponent = NULL;
	}
			
	event OnPushObjectStart()
	{
		moveAdj = GetMovingAgentComponent().GetMovementAdjustor();
		moveAdj.CancelAll();
		pushRotTicket = moveAdj.CreateNewRequest( 'RotateToObject' );
		moveAdj.MaxRotationAdjustmentSpeed(pushRotTicket,30);
		moveAdj.Continuous(pushRotTicket);
		moveAdj.DontEnd(pushRotTicket);
		this.AddTimer('PushObjectUpdate',0.01,true, , , true);
		
	}
	
	event OnPushObjectStop()
	{
		this.RemoveTimer('PushObjectUpdate');
		moveAdj.CancelByName('RotateToObject');
		moveAdj = NULL;
	}
	
	timer function PushObjectUpdate( dt : float , id : int)
	{
		var impulse : Vector;
		moveAdj.RotateTo( pushRotTicket, rawPlayerHeading );
		impulse = this.GetHeadingVector()*10.0;
		//impulse.Z += 0.5;
		//pushableComponent.ApplyLocalImpulseToPhysicalObject(impulse);
	}
	*/
	
	///////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////  @DAY @NIGHT CYCLE CHECK  /////////////////////////////////////
	///////////////////////////////////////////////////////////////////////////////////////////
	
	private function CheckDayNightCycle()
	{
		var time : GameTime;
		var isNight : bool;
		
		//if changed
		isNight = theGame.envMgr.IsNight();
		if(prevDayNightIsNight != isNight)
		{
			if(isNight)				
				OnNightStarted();
			else
				OnDayStarted();
				
			prevDayNightIsNight = isNight;
		}
		
		//schedule next call		
		if(isNight)
			time = theGame.envMgr.GetGameTimeTillNextDay();
		else
			time = theGame.envMgr.GetGameTimeTillNextNight();
			
		AddGameTimeTimer('DayNightCycle', time);
	}
	
	timer function DayNightCycle(dt : GameTime, id : int)
	{
		CheckDayNightCycle();
	}
	
	/*script*/ event OnNightStarted()
	{
		var pam : W3PlayerAbilityManager;
		
		if(CanUseSkill(S_Perk_01))
		{
			pam = (W3PlayerAbilityManager)abilityManager;
			pam.SetPerk01Abilities(false, true);
		}		
	}
	
	/*script*/ event OnDayStarted()
	{
		var pam : W3PlayerAbilityManager;
		
		if(CanUseSkill(S_Perk_01))
		{
			pam = (W3PlayerAbilityManager)abilityManager;
			pam.SetPerk01Abilities(true, false);
		}
	}
	
	///////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////  @INPUT  //////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////////////////////////////
	
	public function ForceUnlockAllInputActions(alsoQuestLocks : bool)
	{
		if ( inputHandler )
			inputHandler.ForceUnlockAllInputActions(alsoQuestLocks);
	}
	
	public function SetPrevRawLeftJoyRot()
	{
		prevRawLeftJoyRot = rawLeftJoyRot;
	}
	
	public function GetPrevRawLeftJoyRot() : float
	{
		return prevRawLeftJoyRot;
	}	
	
	public function GetExplorationInputContext() : name
	{
		return explorationInputContext;
	}
	
	public function GetCombatInputContext() : name
	{
		return combatInputContext;
	}
	
	///////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////  @EXPLORATION  ////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////////////////////////////
	
	public function SetIsOnBoat(b : bool)
	{
		isOnBoat = b;
	}
	
	public function IsOnBoat() : bool
	{
		return isOnBoat;
	}
	
	public function IsInShallowWater() : bool
	{
		return isInShallowWater;
	}
	
	event OnEnterShallowWater()
	{
		if ( isInShallowWater )
			return false;
		
		isInShallowWater = true;
		BlockAction( EIAB_Dodge,'ShallowWater', false, false, true );
		BlockAction( EIAB_Sprint,'ShallowWater', false, false, true );
		BlockAction( EIAB_Crossbow,'ShallowWater', false, false, true );
		BlockAction( EIAB_Jump,'ShallowWater', false, false, true );
		SetBehaviorVariable( 'shallowWater',1.0);
	}
	event OnExitShallowWater()
	{
		if ( !isInShallowWater )
			return false;
		
		isInShallowWater = false;
		BlockAllActions('ShallowWater',false);
		SetBehaviorVariable( 'shallowWater',0.0);
	}
	
	public function TestIsInSettlement() : bool
	{
		return IsInSettlement();
	}

	///////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////  GLOSSARY  ////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////////////////////////////

	//Processes glossary image filename and exchanges it with override if provided
	public function ProcessGlossaryImageOverride( defaultImage : string, uniqueTag : name ) : string
	{
		var size : int;
		var i : int; 
		
		size = glossaryImageOverride.Size();
		
		if( size == 0 )
			return defaultImage;
		
		for( i = 0; i < size; i += 1 )
		{
			if( glossaryImageOverride[i].uniqueTag == uniqueTag )
				return glossaryImageOverride[i].imageFileName;
			
		}
		
		return defaultImage;
	}
	
	//Adds glossary image override filename to array
	public function EnableGlossaryImageOverride( uniqueTag : name, imageFileName : string, enable : bool )
	{
		var imageData : SGlossaryImageOverride;
		var size : int;
		var i : int;
		
		for( i = 0; i < glossaryImageOverride.Size(); i += 1 )
		{
			if( glossaryImageOverride[i].uniqueTag == uniqueTag )
			{
				glossaryImageOverride.Remove(glossaryImageOverride[i]);
			}
		}
		
		if( enable )
		{
			if( IsNameValid(uniqueTag) && imageFileName != "" )
			{
				glossaryImageOverride.PushBack( SGlossaryImageOverride( uniqueTag, imageFileName ) );
			}
		}
	}
	///////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////  WEATHER DISPLAY  /////////////////////////////
	///////////////////////////////////////////////////////////////////////////////////////////	
	public function SetWeatherDisplayDisabled( disable : bool )
	{
		disableWeatherDisplay = disable;
	}
	
	public function GetWeatherDisplayDisabled() : bool
	{
		return disableWeatherDisplay;
	}
	
	///////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////  MONSTER HUNT INVESTIGATION AREAS  /////////////////////////////
	///////////////////////////////////////////////////////////////////////////////////////////
	
	public function SetCurrentMonsterHuntInvestigationArea ( area : W3MonsterHuntInvestigationArea )
	{
		currentMonsterHuntInvestigationArea = area;
	}


	///////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////  BARBER SYSTEM CUSTOM HEAD   /////////////////////////////
	///////////////////////////////////////////////////////////////////////////////////////////
	
	public function RememberCustomHead( headName : name )
	{
		rememberedCustomHead = headName;
	}
	
	public function GetRememberedCustomHead() : name
	{
		return rememberedCustomHead;
	}

	public function ClearRememberedCustomHead()
	{
		rememberedCustomHead = '';
	}	
	
	///////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////  @TUTORIAL	   ////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////////////////////////////
	
	public function CreateTutorialInput()
	{
		var prevInputHandler : CPlayerInput;
		
		prevInputHandler = inputHandler;
		inputHandler = new W3PlayerTutorialInput in this;
		inputHandler.Initialize(false, prevInputHandler);
		
		if(prevInputHandler)
			delete prevInputHandler;
	}
	
	public function CreateInput()
	{
		var oldInputHandler : CPlayerInput;
		
		oldInputHandler = inputHandler;
		inputHandler = new CPlayerInput in this;
		inputHandler.Initialize(false, oldInputHandler);
	}
	
	timer function TutorialSilverCombat(dt : float, id : int)
	{
		var i : int;
		var actors : array<CActor>;		
	
		if(IsInCombat())
		{
			actors = GetNPCsAndPlayersInRange(20, 1000000, ,FLAG_ExcludePlayer + FLAG_OnlyAliveActors);
			for(i=0; i<actors.Size(); i+=1)
			{
				if(actors[i] && IsRequiredAttitudeBetween(this, actors[i], true) && actors[i].UsesEssence())
				{
					FactsAdd("TutorialShowSilver");
					
					RemoveTimer('TutorialSilverCombat');
					break;
				}
			}
		}
	}	

	private saved var m_bossTag : name;
	
	public function GetBossTag() : name
	{
		return m_bossTag;
	}

	public function SetBossTag( bossTag : name )
	{
		m_bossTag = bossTag;
	}
	
	private saved var m_usingCoatOfArms : bool;		default m_usingCoatOfArms = false;
	
	public function IsUsingCoatOfArms() : bool
	{
		return m_usingCoatOfArms;
	}

	public function SetUsingCoatOfArms( using : bool)
	{
		m_usingCoatOfArms = using;
	}

	private saved var m_initialTimeOut : float;
	private saved var m_currentTimeOut : float;
	
	public function GetInitialTimeOut() : float
	{
		return m_initialTimeOut;
	}

	public function SetInitialTimeOut( timeOut : float )
	{
		m_initialTimeOut = timeOut;
	}

	public function GetCurrentTimeOut() : float
	{
		return m_currentTimeOut;
	}

	public function SetCurrentTimeOut( timeOut : float )
	{
		m_currentTimeOut = timeOut;
	}
	

	///////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////  @FINISHERS	   ////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////////////////////////////	
	
	timer function DelayedFinisherInputTimer(dt : float, id : int)
	{	
		//theGame.SetTimeScale( 0.1, theGame.GetTimescaleSource(ETS_FinisherInput), theGame.GetTimescalePriority(ETS_FinisherInput) );
		//GetFinisherVictim().EnableFinishComponent( true );	
	}
	
	timer function RemoveFinisherCameraAnimationCheck(dt : float, id : int)
	{
		if ( !isInFinisher && !bLAxisReleased )
		{
			theGame.GetSyncAnimManager().OnRemoveFinisherCameraAnimation();
			RemoveTimer( 'RemoveFinisherCameraAnimationCheck' );
		}
	}
	
	///////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////  @DEBUG @TIMERS	   ////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////////////////////////////
		
	timer function GameplayFactRemove(dt : float, timerId : int)
	{
		theGame.GameplayFactRemoveFromTimer(timerId);
	}	
	
	//gives NORMAL starting inventory
	timer function GiveStartingItems(dt : float, timerId : int)
	{
		var template : CEntityTemplate;
		var invEntity : CInventoryComponent;
		var entity : CEntity;
		var items : array<SItemUniqueId>;
		var id : SItemUniqueId;
		var i : int;
		
		//wait for inventory to init
		if(inv)
		{			
			inv.GetAllItems(items);
			if(items.Size() <= 0)
			{
				return;
			}
		}
		else
		{
			return;
		}
		
		//add items
		template = (CEntityTemplate)LoadResource("geralt_inventory_release");
		entity = theGame.CreateEntity(template, Vector(0,0,0));
		invEntity = (CInventoryComponent)entity.GetComponentByClassName('CInventoryComponent');
		
		invEntity.GetAllItems(items);				
		for(i=0; i<items.Size(); i+=1)
		{
			id = invEntity.GiveItemTo(inv, items[i], 0, false, true);
			if ( inv.ItemHasTag(id,'Scabbard') )
			{
				inv.MountItem(id);
			}
			else if(!inv.IsItemFists(id) && inv.GetItemName(id) != 'Cat 1')	//hack for cat potion - don't equip!
			{
				EquipItem(id);
			}
			else if(inv.IsItemSingletonItem(id))
			{
				inv.SingletonItemSetAmmo(id, inv.SingletonItemGetMaxAmmo(id));
			}
		}
		
		entity.Destroy();
		
		//remove timer
		RemoveTimer('GiveStartingItems');
	}
	
	//Adds items used for testing. Won't be called in final release. Items are added from geralt_inventory entity.
	//Works as a timer since we need to wait for inventory to init and there is no such event.
	timer function Debug_GiveTestingItems(dt : float, optional id : int)
	{
		var template : CEntityTemplate;
		var invTesting : CInventoryComponent;
		var entity : CEntity;
		var items : array<SItemUniqueId>;
		var i : int;
		var slot : EEquipmentSlots;
			
		//wait for inventory to init
		if(inv)
		{
			inv.GetAllItems(items);
			if(items.Size() <= 0)
			{
				return;
			}
		}
		else
		{
			return;
		}
		
		template = (CEntityTemplate)LoadResource("geralt_inventory_internal");
		entity = theGame.CreateEntity(template, Vector(0,0,0));
		invTesting = (CInventoryComponent)entity.GetComponentByClassName('CInventoryComponent');
		invTesting.GiveAllItemsTo(inv, true);
		entity.Destroy();
		
		//once called remove the timer
		RemoveTimer('Debug_GiveTestingItems');
		
		//equip crossbow, bombs and bolts, select bolts
		inv.GetAllItems(items);
				
		for(i=0; i<items.Size(); i+=1)
		{
			if( inv.IsItemCrossbow(items[i]) || inv.IsItemBomb(items[i]) )
			{
				slot = inv.GetSlotForItemId(items[i]);
				EquipItem(items[i], slot);
				
				if( (W3PlayerWitcher)this && inv.IsItemCrossbow(items[i]) )
					GetWitcherPlayer().SelectQuickslotItem(slot);
			}			
			else if(inv.IsItemBolt(items[i]))
			{
				slot = inv.GetSlotForItemId(items[i]);
				EquipItem(items[i], slot);
			}
			
			if(inv.IsItemSingletonItem(items[i]))
			{
				inv.SingletonItemSetAmmo(items[i], inv.SingletonItemGetMaxAmmo(items[i]));
			}
		}
	}
	
	//called in tutorial in not final version to remove testing items
	timer function Debug_RemoveTestingItems(dt : float, id : int)
	{
		var template : CEntityTemplate;
		var entity : CEntity;
		var invTesting : CInventoryComponent;
		var ids : array<SItemUniqueId>;
		var i : int;
		
		template = (CEntityTemplate)LoadResource("geralt_inventory_internal");
		entity = theGame.CreateEntity(template, Vector(0,0,0));
		invTesting = (CInventoryComponent)entity.GetComponentByClassName('CInventoryComponent');
		invTesting.GetAllItems(ids);
		
		for(i=0; i<ids.Size(); i+=1)
			inv.RemoveItemByName(invTesting.GetItemName(ids[i]), invTesting.GetItemQuantity(ids[i]));
		
		entity.Destroy();
		RemoveTimer('Debug_RemoveTestingItems');
	}
	
	timer function Debug_DelayedConsoleCommand(dt : float, id : int)
	{
		//inv.AddAnItem('Recipe for Mutagen 23');
		inv.AddAnItem('Boots 2 schematic');
	}
	
	function DBG_SkillSlots()
	{
		((W3PlayerAbilityManager)abilityManager).DBG_SkillSlots();
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////////  @BACKLIGHT COLOR  ////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	public final function SetPadBacklightColor(r, g, b : int)
	{
		var padBacklightColor : Vector;
		
		padBacklightColor.X = r / 255;
		padBacklightColor.Y = g / 255;
		padBacklightColor.Z = b / 255;
		
		SetBacklightColor(padBacklightColor);
	}
	
	public final function SetPadBacklightColorFromSign(signType : ESignType)
	{
		LogPS4Light("SetPadBacklightColorFromSign... " + signType);
		
		switch(signType)
		{
			case ST_Yrden: 	SetPadBacklightColor( 200 , 81  , 255 ); break;	// Violet
			case ST_Quen: 	SetPadBacklightColor( 255 , 205 , 68  ); break;	// Yellow
			case ST_Igni: 	SetPadBacklightColor( 255 , 79  , 10  ); break;	// Orange
			case ST_Axii: 	SetPadBacklightColor( 255 , 255 , 255 ); break;	// White
			case ST_Aard: 	SetPadBacklightColor( 158 , 214 , 255 ); break;	// Blue
		}
	}
	
	timer function ResetPadBacklightColorTimer(dt : float, id : int)
	{
		ResetPadBacklightColor();
	}
	
	public final function ResetPadBacklightColor(optional skipHeldWeapon : bool)
	{
		var weapons : array<SItemUniqueId>;
		var sword : CWitcherSword;
		var healthPercentage : float;
		var tmpBacklight : Vector;
		
		if(!skipHeldWeapon)
		{
			weapons = inv.GetHeldWeapons();
			
			//if holding a sword the default backlight color matches the one set in sword entity
			if(weapons.Size() > 0)
			{
				sword = (CWitcherSword)inv.GetItemEntityUnsafe(weapons[0]);
				if(sword)
				{
					tmpBacklight.X = sword.padBacklightColor.X / 255.0f;
					tmpBacklight.Y = sword.padBacklightColor.Y / 255.0f;
					tmpBacklight.Z = sword.padBacklightColor.Z / 255.0f;
					tmpBacklight.W = 1.0f;
					SetBacklightColor( tmpBacklight );
					LogPS4Light("Setting light from sword template: " + NoTrailZeros(sword.padBacklightColor.X) + ", " + NoTrailZeros(sword.padBacklightColor.Y) + ", " + NoTrailZeros(sword.padBacklightColor.Z) );
					return;
				}
			}
		}
		
		healthPercentage = GetStatPercents( BCS_Vitality );
		SetBacklightFromHealth( healthPercentage );
		LogPS4Light("Setting light from health, " + NoTrailZeros(RoundMath(healthPercentage*100)) + "%");
	}
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	event OnOpenningDoor()
	{
		if( !thePlayer.IsUsingHorse() )
			RaiseEvent('OpenDoor');
	}
	
	public final function SetLoopingCameraShakeAnimName( n : name )
	{
		loopingCameraShakeAnimName = n;
	}
	
	public var loopingCameraShakeAnimName : name;
	timer function RemoveQuestCameraShakeTimer( dt : float , id : int)
	{
		RemoveQuestCameraShake( loopingCameraShakeAnimName );
	}
	
	public function RemoveQuestCameraShake( animName : name )
	{
		var camera 	: CCustomCamera = theGame.GetGameCamera();
		var animation : SCameraAnimationDefinition;
		
		camera.StopAnimation( animName );
	}
	
	public function GetCameraPadding() : float
	{
		if( theGame.IsFocusModeActive() )
		{
			return 0.25; // Tweaked for [108933] Geralt is being clipped when using focus mode while running towards camera.
		}
		else
		{
			return 0.02f; // Tweaked for [114907] Player dissolving while aiming crossbow.
		}
	}
	
	public function IsPerformingPhaseChangeAnimation() : bool			{ return isPerformingPhaseChangeAnimation; }
	public function SetIsPerformingPhaseChangeAnimation( val : bool )	{ isPerformingPhaseChangeAnimation = val; }
	
	private function DealCounterDamageToOlgierd()
	{
		var damage : W3DamageAction;
		
		damage = new W3DamageAction in this;
				
		damage.Initialize( thePlayer.GetTarget(), thePlayer.GetTarget(), NULL, this, EHRT_None, CPS_Undefined, false, false, false, true );
		damage.AddDamage( theGame.params.DAMAGE_NAME_DIRECT, thePlayer.GetTarget().GetStatMax( BCS_Vitality ) * 3 / 100 );
		theGame.damageMgr.ProcessAction( damage );
		
		delete damage;
	}
	
	timer function PlayDelayedCounterDamageEffect( dt : float, id : int )
	{
		thePlayer.GetTarget().PlayEffect( 'olgierd_energy_blast' );
	}

	// TEST
	public function SetTestAdjustRequestedMovementDirection( val : bool )
	{
		testAdjustRequestedMovementDirection = val;
	}
	
	event OnVisualDebug( frame : CScriptedRenderFrame, flag : EShowFlags )
	{
		var	boneFollow		: int;
		var	bonePosition 	: Vector;
		var yrdenEntity		: W3YrdenEntity;
		
		substateManager.OnVisualDebug( frame, flag );
		
		boneFollow		= thePlayer.GetBoneIndex( 'Reference' );
		bonePosition	= MatrixGetTranslation( thePlayer.GetBoneWorldMatrixByIndex( boneFollow ) );
		frame.DrawText( "R", bonePosition, Color( 50, 200, 70 ) );
		//frame.DrawText( "R", bonePositionCam, Color( 200, 50, 70 ) );
		
		boneFollow		= thePlayer.GetBoneIndex( 'Trajectory' );
		bonePosition	= MatrixGetTranslation( thePlayer.GetBoneWorldMatrixByIndex( boneFollow ) );
		frame.DrawSphere( bonePosition, 0.1f, Color( 200, 50, 70 ) );
		frame.DrawText( "T", bonePosition, Color( 200, 50, 70 ) );
		
		//frame.DrawSphere( lastSafePosition, 1.0f, Color( 50, 200, 70 ) );
		//frame.DrawText( "SavePos", lastSafePosition, Color( 50, 200, 70 ) );
		
		yrdenEntity = (W3YrdenEntity)GetWitcherPlayer().GetSignEntity(ST_Yrden);
		yrdenEntity.OnVisualDebug(frame, flag, false);
		
		return true;
	}
	
	timer function PotDrinkTimer(dt : float, id : int)
	{
		inputHandler.PotDrinkTimer(false);
	}
	
	public function SetIsHorseRacing( val : bool )
	{
		isHorseRacing = val;
	}
	
	public function GetIsHorseRacing() : bool
	{
		return isHorseRacing;
	}
	
	public function SetHorseCombatSlowMo( val : bool )
	{
		horseCombatSlowMo = val;
	}
	
	public function GetHorseCombatSlowMo() : bool
	{
		return horseCombatSlowMo;
	}
	
	public function SetItemsPerLevelGiven( id : int )
	{
		itemsPerLevelGiven[id] = true;
	}
	
	private function AddItemPerLevelList()
	{
		var i : int; 

		itemsPerLevel.Clear();
		itemsPerLevel.PushBack('O');		
		itemsPerLevel.PushBack('No Mans Land sword 2');		
		itemsPerLevel.PushBack('No Mans Land sword 3');		
		itemsPerLevel.PushBack('Silver sword 2');		
		itemsPerLevel.PushBack('Boots 01');		
		itemsPerLevel.PushBack('Novigraadan sword 2');		
		itemsPerLevel.PushBack('Light armor 01');		
		itemsPerLevel.PushBack('Heavy boots 01');		
		itemsPerLevel.PushBack('Nilfgaardian sword 3');		
		itemsPerLevel.PushBack('Silver sword 3');		
		itemsPerLevel.PushBack('Heavy gloves 01');		
		itemsPerLevel.PushBack('Skellige sword 2');		
		itemsPerLevel.PushBack('Heavy pants 01');		
		itemsPerLevel.PushBack('Silver sword 4');		
		itemsPerLevel.PushBack('No Mans Land sword 4');		
		itemsPerLevel.PushBack('Heavy armor 01');		
		itemsPerLevel.PushBack('Heavy boots 02');		
		itemsPerLevel.PushBack('Skellige sword 3');		
		itemsPerLevel.PushBack('Silver sword 5');		
		itemsPerLevel.PushBack('Heavy pants 02');		
		itemsPerLevel.PushBack('Heavy gloves 02');		
		itemsPerLevel.PushBack('Heavy gloves 02');		
		itemsPerLevel.PushBack('Heavy armor 02');		
		itemsPerLevel.PushBack('Scoiatael sword 1');		
		
		if ( itemsPerLevelGiven.Size() < 49 )
		{
			itemsPerLevelGiven.Clear();
			for (i = 0; i < itemsPerLevel.Size(); i += 1) { itemsPerLevelGiven.PushBack( false ); }
		}		
	}
	
	// TEMP
	public function DealDamageToBoat( dmg : float, index : int, optional globalHitPos : Vector )
	{
		var boat : CBoatDestructionComponent;
		
		if(usedVehicle)
		{
			boat = (CBoatDestructionComponent) usedVehicle.GetComponentByClassName( 'CBoatDestructionComponent' );
			if( boat )
			{
				boat.DealDamage( dmg, index, globalHitPos );
			}
		}
	}
	
	////////////////////////////////////////////////////////////////////////////////
	//
	// PLAYABLE AREA
	//
	public function OnStartTeleportingPlayerToPlayableArea()
	{
		var FADEOUT_INTERVAL : float = 0.5;
		
		// if we jumped on horse right before being teleported, we need to disable falling damage because height difference may kill us
		if ( thePlayer.IsUsingHorse() )
		{
			if ( thePlayer.GetUsedHorseComponent().OnCheckHorseJump() )
			{
				thePlayer.GetUsedHorseComponent().SetCanTakeDamageFromFalling( false );
			}
		}

		if ( thePlayer.IsActionAllowed( EIAB_FastTravel ) )
		{
			OnOpenMapToLetPlayerGoBackToPlayableArea();
		}
		else
		{
			theGame.FadeOutAsync( FADEOUT_INTERVAL );
			thePlayer.AddTimer( 'BorderTeleportFadeOutTimer', FADEOUT_INTERVAL, false );
		}	
	}
	
	timer function BorderTeleportFadeOutTimer( dt : float, id : int )
	{
		OnTeleportPlayerToPlayableArea( false );
	}
	
	public function OnOpenMapToLetPlayerGoBackToPlayableArea()
	{
		var initData : W3MapInitData;
		
		initData = new W3MapInitData in this;
		initData.SetTriggeredExitEntity( true );
		initData.ignoreSaveSystem = true;
		initData.setDefaultState('FastTravel');
		theGame.RequestMenuWithBackground( 'MapMenu', 'CommonMenu', initData );
	}
	
	public function OnTeleportPlayerToPlayableArea( afterClosingMap : bool )
	{
		var BLACKSCREEN_INTERVAL : float = 0.1;
		var manager : CCommonMapManager = theGame.GetCommonMapManager();
		
		thePlayer.TeleportWithRotation( manager.GetBorderTeleportPosition(), manager.GetBorderTeleportRotation() );
		thePlayer.AddTimer( 'BorderTeleportFadeInTimer', BLACKSCREEN_INTERVAL, false );
		
		theGame.FadeOutAsync( 0 );
		theGame.SetFadeLock('PlayerTeleportation');
	}
	
	timer function BorderTeleportFadeInTimer( dt : float, id : int )
	{
		theGame.ResetFadeLock('PlayerTeleportation');
		theGame.FadeOutAsync( 0 );
		theGame.FadeInAsync( 2.0f );
	}
	
	public final function SetLastInstantKillTime(g : GameTime)
	{
		lastInstantKillTime = g;
	}
	//
	//
	//
	////////////////////////////////////////////////////////////////////////////////

	timer function TestTimer(dt : float, id : int )
	{
		LogChannel('asdf', "asdf");
		theGame.FadeOutAsync( 5 );
	}
	
	public final function Debug_ReleaseCriticalStateSaveLocks()
	{
		effectManager.Debug_ReleaseCriticalStateSaveLocks();
	}
	
	timer function Debug_SpamSpeed(dt : float, id : int)
	{
		if(currentlyMountedHorse)
		{
			LogSpeed("curr player's horse speed: " + NoTrailZeros(currentlyMountedHorse.GetMovingAgentComponent().GetSpeed())) ;
		}
		else
		{
			LogSpeed("curr player speed: " + NoTrailZeros(GetMovingAgentComponent().GetSpeed())) ;
		}
	}
	
	timer function RemoveInstantKillSloMo(dt : float, id : int)
	{
		theGame.RemoveTimeScale( theGame.GetTimescaleSource(ETS_InstantKill) );
	}
	
	timer function RemoveForceFinisher(dt : float, id : int)
	{
		forceFinisher = false;
	}
	
	public final function Debug_ClearAllActionLocks(optional action : EInputActionBlock, optional all : bool)
	{
		inputHandler.Debug_ClearAllActionLocks(action, all);
	}

	function OnFocusedCameraBlendBegin() {}
	function OnFocusedCameraBlendUpdate( progress : float ) {}
	function OnFocusedCameraBlendEnd() {}
	
	public function GetEtherealCount() : int { return etherealCount; }
	public function IncrementEtherealCount() 
	{ 
		etherealCount += 1; 
		if( etherealCount == 6 )
			ResetEtherealCount();
	}
	public function ResetEtherealCount() { etherealCount = 0; }
	
	public function SetInsideDiveAttackArea( val : bool ) { insideDiveAttackArea = val; }
	public function IsInsideDiveAttackArea() : bool { return insideDiveAttackArea; }
	public function SetDiveAreaNumber( val : int ) { diveAreaNumber = val; }
	public function GetDiveAreaNumber() : int { return diveAreaNumber; }
	
	// PHANTOM WEAPON
	//------------------------------------------------------------------------------------------------------------------
	public function InitPhantomWeaponMgr()
	{
		if( !phantomWeaponMgr )
		{
			phantomWeaponMgr = new CPhantomWeaponManager in this;
			phantomWeaponMgr.Init( this.GetInventory() );
		}
	}
	
	public function DestroyPhantomWeaponMgr()
	{
		if( phantomWeaponMgr )
		{
			delete phantomWeaponMgr;
		}
	}
	
	public function GetPhantomWeaponMgr() : CPhantomWeaponManager
	{
		if( phantomWeaponMgr )
		{
			return phantomWeaponMgr;
		}
		else
		{
			return NULL;
		}
	}
	
	public timer function DischargeWeaponAfter( td : float, id : int )
	{
		GetPhantomWeaponMgr().DischargeWeapon();
	}
	//------------------------------------------------------------------------------------------------------------------
	// FORCED FINISHER - mutation8
	//------------------------------------------------------------------------------------------------------------------
	
	private var forcedFinisherVictim : CActor;
	
	timer function PerformFinisher( time : float , id : int )
	{
		var combatTarget : CActor;
		var i : int;
		
		combatTarget = thePlayer.GetTarget();
		
		if( combatTarget )
		{
			combatTarget.Kill( 'AutoFinisher', false, thePlayer );
			thePlayer.SetFinisherVictim( combatTarget );
			forcedFinisherVictim = combatTarget;
			thePlayer.CleanCombatActionBuffer();
			thePlayer.OnBlockAllCombatTickets( true );
			moveTargets = thePlayer.GetMoveTargets();
					
			for( i = 0; i < moveTargets.Size(); i += 1 )
			{
				if( combatTarget != moveTargets[i] )
					moveTargets[i].SignalGameplayEvent( 'InterruptChargeAttack' );
			}	
			
			if( theGame.GetInGameConfigWrapper().GetVarValue( 'Gameplay', 'AutomaticFinishersEnabled' ) == "true" )
				combatTarget.AddAbility( 'ForceFinisher', false );
			
			if( combatTarget.HasTag( 'ForceFinisher' ) )
				combatTarget.AddAbility( 'ForceFinisher', false );
				
			combatTarget.SignalGameplayEvent( 'ForceFinisher' );
			
			thePlayer.FindMoveTarget();

			thePlayer.AddTimer( 'SignalFinisher', 0.2, false );
		}
	}
	
	timer function SignalFinisher( time : float , id : int )
	{
		forcedFinisherVictim.SignalGameplayEvent( 'Finisher' );
		forcedFinisherVictim = NULL;
	}
}

exec function ttt()
{
	thePlayer.AddTimer( 'TestTimer', 5, false );
}
