// Written by Marco
Class LairSoldierBase extends KFMonster
	Abstract;

#exec obj load file="LairMonstersV1_S.uax"
#exec obj load file="KFSoldiers.ukx"

var(Sounds) sound SoundFootsteps[20],WeaponFireSound,WeaponReloadSound;
var(Weapon) class<KFWeaponAttachment> WAttachClass;
var(Weapon) int AmmoPerClip,WeaponHitDamage[2];
var(Weapon) float WeaponFireRate,WeaponMissRate;
var(Weapon) vector FireOffset;
var(AI) float WeaponFireTime,AimingError;
var() name FireAnim,WeaponReloadAnim,MeleeAttackAnim;
var KFWeaponAttachment GunAttachment;
var int ClipCount;
var float NextTauntTime;

var(Weapon) bool bReloadClipAtTime;
var(AI) bool bFightOnSight,bPickVisPointOnHunt,bFreezeActionAnim,bLurker;

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	GroundSpeed = Default.OriginalGroundSpeed;
	OriginalGroundSpeed = Default.OriginalGroundSpeed;
	if( Level.NetMode!=NM_Client )
	{
		AttachWeapon();
		if( LairSoldierController(Controller)!=None )
			LairSoldierController(Controller).ZZB = Self;
	}
}

simulated function bool HitCanInterruptAction()
{
	return !bShotAnim;
}

final function AttachWeapon()
{
	if ( GunAttachment==None )
		GunAttachment = Spawn(WAttachClass,Self);
	else
		GunAttachment.NetUpdateTime = Level.TimeSeconds - 1;
	AttachToBone(GunAttachment,GetWeaponBoneFor(None));
}
final function DeAttachWeapon()
{
	if( GunAttachment!=None )
		GunAttachment.Destroy();
}

function Died(Controller Killer, class<DamageType> damageType, vector HitLocation)
{
	DeAttachWeapon();
	Super.Died(Killer,damageType,HitLocation);
}
simulated function Destroyed()
{
	DeAttachWeapon();
	Super.Destroyed();
}

function ClawDamageTarget()
{
	local vector PushDir;
	local float UsedMeleeDamage;

	UsedMeleeDamage = (MeleeDamage - (MeleeDamage * 0.05)) + (MeleeDamage * (FRand() * 0.1));

	if(Controller!=none && Controller.Target!=none)
		PushDir = (damageForce * Normal(Controller.Target.Location - Location));
	else PushDir = damageForce * vector(Rotation);
	// Melee damage is +/- 10% of default
	if ( MeleeDamageTarget(UsedMeleeDamage, PushDir) )
		PlaySound(MeleeAttackHitSound, SLOT_None, 2.0);
}
simulated function FootStepping(int Side)
{
	local int SurfaceTypeID, i;
	local actor A;
	local material FloorMat;
	local vector HL,HN,Start,End,HitLocation,HitNormal;
	local float FootVolumeMod;

	SurfaceTypeID = 0;
	FootVolumeMod = 1.0;

	for ( i=0; i<Touching.Length; i++ )
		if ( ((PhysicsVolume(Touching[i]) != None) && PhysicsVolume(Touching[i]).bWaterVolume)
			|| (FluidSurfaceInfo(Touching[i]) != None) )
		{
			PlaySound(sound'Inf_Player.FootStepWaterDeep', SLOT_Interact, 0.8f,, 126.f);

			// Play a water ring effect as you walk through the water
 			if ( !Level.bDropDetail && (Level.DetailMode != DM_Low) && (Level.NetMode != NM_DedicatedServer)
				&& !Touching[i].TraceThisActor(HitLocation, HitNormal,Location - CollisionHeight*vect(0,0,1.1), Location) )
			{
				Spawn(class'WaterRingEmitter',,,HitLocation,rot(16384,0,0));
			}

			return;
		}

	// Lets still play the sounds when walking slow, just play them quieter
	if ( bIsCrouched || bIsWalking )
		FootVolumeMod = 0.4f;

	if ( (Base!=None) && (!Base.IsA('LevelInfo')) && (Base.SurfaceType!=0) )
		SurfaceTypeID = Base.SurfaceType;
	else
	{
		Start = Location - Vect(0,0,1)*CollisionHeight;
		End = Start - Vect(0,0,16);
		A = Trace(hl,hn,End,Start,false,,FloorMat);
		if (FloorMat !=None)
			SurfaceTypeID = FloorMat.SurfaceType;
	}
	PlaySound(SoundFootsteps[SurfaceTypeID], SLOT_Interact, (0.45f * FootVolumeMod),,(128.f * FootVolumeMod));
}
function RemoveHead()
{
	Health = Min(1,Health);
}

simulated function SetBurningBehavior()
{
	if( Role == Role_Authority )
	{
		Intelligence = BRAINS_Retarded; // burning dumbasses!

		GroundSpeed = OriginalGroundSpeed * 0.8;
		AirSpeed *= 0.8;
		WaterSpeed *= 0.8;

		// Make them less accurate while they are burning
		if( Controller != none )
			MonsterController(Controller).Accuracy = -5;  // More chance of missing. (he's burning now, after all) :-D
	}
}
simulated function UnSetBurningBehavior()
{
	if ( Role == Role_Authority )
	{
		Intelligence = default.Intelligence;

		GroundSpeed = GetOriginalGroundSpeed();
		AirSpeed = default.AirSpeed;
		WaterSpeed = default.WaterSpeed;

		// Set normal accuracy
		if ( Controller != none )
			MonsterController(Controller).Accuracy = MonsterController(Controller).default.Accuracy;
	}
	bAshen = False;
}

function RangedAttack(Actor A);

function DoorAttack(Actor A)
{
	if ( bShotAnim )
		return;
	else if ( A!=None )
	{
		bShotAnim = true;
		SetAnimAction(MeleeAttackAnim);
		Acceleration = vect(0,0,0);
		GotoState('DoorBashing');
	}
}
function HandleBumpGlass()
{
	Acceleration = vect(0,0,0);
	SetAnimAction(MeleeAttackAnim);
	bShotAnim = true;
	Controller.GotoState('WaitForAnim');
}

simulated function SetWeaponAttachment(WeaponAttachment NewAtt)
{
	NewAtt.SetRelativeRotation(NewAtt.Default.RelativeRotation+rot(32768,0,0));
}

simulated function int DoAnimAction( name AnimName )
{
	if( AnimName==WeaponReloadAnim || AnimName==FireAnim || AnimName==MeleeAttackAnim )
	{
		if( AnimName==FireAnim )
		{
			AnimBlendParams(1, 1.0, 0.0,0.8f, SpineBone2, true);
			PlayAnim(AnimName,, 0.f, 1);
		}
		else
		{
			AnimBlendParams(1, 1.0, 0.0,, SpineBone1);
			PlayAnim(AnimName,, 0.1, 1);
		}
		return 1;
	}
	return Super.DoAnimAction(AnimName);
}

state DoorBashing
{
Begin:
	Sleep(GetAnimDuration(MeleeAttackAnim)*0.6f);
	ClawDamageTarget();
	Sleep(GetAnimDuration(MeleeAttackAnim)*0.4f+0.1f);
	GotoState('');
}

// New AI: ==============================================================
function bool ReadyToFire( Pawn Enemy )
{
	return (Controller.LineOfSightTo(Enemy) && (FRand()<0.5f || Controller.ActorReachable(Enemy)) && !ShootingFriendly(Enemy));
}

final function bool ShootingFriendly( Actor Spot )
{
	local vector Dummy;
	local Actor A;

	if( Monster(Spot)!=None )
		return false;
	bBlockHitPointTraces = false;
	A = Trace(Dummy,Dummy,Spot.Location,Location+Normal(Spot.Location-Location)*CollisionRadius,True);
	bBlockHitPointTraces = true;

	return (A!=None && (Monster(A)!=None || Monster(A.Owner)!=None));
}

function PrepareToAttack( Pawn Enemy )
{
	Controller.Focus = Enemy;
	Acceleration = vect(0,0,0);
	bWantsToCrouch = true;
}
function float FightEnemyNow( Pawn Enemy ) // Return attack time.
{
	GoToState('FiringWeapon');
	return WeaponFireTime+FRand()*WeaponFireTime*0.25f;
}
function FinishAttacking()
{
	bWantsToCrouch = false;
}

function LostContact();

function DesireAttackPoint( out float Desire, NavigationPoint N, Pawn Enemy )
{
	Desire+=FRand()*Desire*2.f;
	if( VSizeSquared(N.Location-Enemy.Location)>4000000.f )
		Desire*=0.4f;
}

// Return next orders.
function bool WhatToDoNext()
{
	if( ClipCount>=AmmoPerClip )
	{
		Controller.GoToState('GoReloading');
		return true;
	}
	return false;
}

function bool TauntAtEnemy()
{
	if( bShotAnim || NextTauntTime>Level.TimeSeconds )
		return false;
	NextTauntTime = Level.TimeSeconds+10.f+10.f*FRand();
	if( FRand()>0.25f )
		return false;
	bWantsToCrouch = false;
	bShotAnim = true;
	Acceleration = vect(0,0,0);
	if( FRand()<0.5f )
		SetAnimAction('gesture_point');
	else SetAnimAction('gesture_beckon');
	return true;
}

function PlayReloading()
{
	bWantsToCrouch = true;
	bShotAnim = true;
	SetAnimAction(WeaponReloadAnim);
	if( bReloadClipAtTime )
		--ClipCount;
	else ClipCount = 0;
	Acceleration = vect(0,0,0);
	GoToState('Reloading','Begin');
}

function bool LurkBackOff( Pawn Enemy )
{
	local vector Dir;

	Dir = (Location-Enemy.Location);
	Dir.Z = 0;
	return ((vector(Enemy.Rotation) Dot Normal(Dir)) > 0.8f);
}

final function vector GetFirePosStart()
{
	local vector X,Y,Z;

	GetAxes(Rotation,X,Y,Z);
	return Location+X*FireOffset.X*CollisionRadius+Y*FireOffset.Y*CollisionRadius+Z*FireOffset.Z*CollisionHeight;
}
function FireWeaponOnce()
{
	local vector HL,HN,End,Start,X;
	local rotator R;
	local Actor A;

	Controller.Target = Controller.Enemy;

	if ( !SavedFireProperties.bInitialized )
	{
		SavedFireProperties.AmmoClass = Class'BullpupAmmo';
		SavedFireProperties.ProjectileClass = None;
		SavedFireProperties.WarnTargetPct = 0.15;
		SavedFireProperties.MaxRange = 10000;
		SavedFireProperties.bTossed = False;
		SavedFireProperties.bTrySplash = False;
		SavedFireProperties.bLeadTarget = True;
		SavedFireProperties.bInstantHit = True;
		SavedFireProperties.bInitialized = true;
	}

	Start = GetFirePosStart();
	R = AdjustAim(SavedFireProperties,Start,AimingError);
	X = Normal(vector(R)+VRand()*WeaponMissRate);
	End = Start+X*10000.f;
	bBlockHitPointTraces = false;
	A = Trace(HL,HN,End,Start,True);
	bBlockHitPointTraces = true;

	if( A!=None )
		A.TakeDamage(WeaponHitDamage[0]+Rand(WeaponHitDamage[1]),Self,HL,X*600,Class'DamageType');
	else HL = End;
	if( GunAttachment!=None )
	{
		SetAnimAction(FireAnim);
		GunAttachment.UpdateHit(A,HL,HN);
		GunAttachment.NetUpdateTime = Level.TimeSeconds - 1;
		GunAttachment.FlashCount++;
		if( Level.NetMode!=NM_DedicatedServer )
			GunAttachment.ThirdPersonEffects();
	}

	PlaySound(WeaponFireSound,SLOT_Interact,TransientSoundVolume * 0.85,,TransientSoundRadius,(1.0 + FRand()*0.015f),false);
}

State FiringWeapon
{
	function BeginState()
	{
		SetTimer(WeaponFireRate,true);
	}
	function EndState()
	{
		SetTimer(0,false);
	}
	function FinishAttacking()
	{
		bWantsToCrouch = false;
		GoToState('');
	}
	function Timer()
	{
		FireWeaponOnce();
		if( ++ClipCount>=AmmoPerClip )
			LairSoldierController(Controller).WhatToDoNext(69);
	}
}
State Reloading
{
	function AnimEnd( int Channel )
	{
		Global.AnimEnd(Channel);
		if( !bShotAnim )
		{
			if( ClipCount>0 )
				PlayReloading();
			else GoToState('');
		}
	}
Begin:
	Sleep(GetAnimDuration(WeaponReloadAnim)*0.4f);
	PlaySound(WeaponReloadSound,SLOT_Interact,,,,(1.0 + FRand()*0.015f),false);
}

defaultproperties
{
     SoundFootsteps(0)=SoundGroup'KF_PlayerGlobalSnd.Player_StepDefault'
     SoundFootsteps(1)=SoundGroup'KF_PlayerGlobalSnd.Player_StepDirt'
     SoundFootsteps(2)=SoundGroup'KF_PlayerGlobalSnd.Player_StepDirt'
     SoundFootsteps(3)=SoundGroup'KF_PlayerGlobalSnd.Player_StepMetal'
     SoundFootsteps(4)=SoundGroup'KF_PlayerGlobalSnd.Player_StepWood'
     SoundFootsteps(5)=SoundGroup'KF_PlayerGlobalSnd.Player_StepGrass'
     SoundFootsteps(6)=SoundGroup'KF_PlayerGlobalSnd.Player_StepDirt'
     SoundFootsteps(7)=SoundGroup'KF_PlayerGlobalSnd.Player_StepDefault'
     SoundFootsteps(8)=SoundGroup'KF_PlayerGlobalSnd.Player_StepDefault'
     SoundFootsteps(9)=SoundGroup'KF_PlayerGlobalSnd.Player_StepWater'
     SoundFootsteps(10)=SoundGroup'KF_PlayerGlobalSnd.Player_StepBrGlass'
     SoundFootsteps(11)=SoundGroup'KF_PlayerGlobalSnd.Player_StepDefault'
     SoundFootsteps(12)=SoundGroup'KF_PlayerGlobalSnd.Player_StepConc'
     SoundFootsteps(13)=SoundGroup'KF_PlayerGlobalSnd.Player_StepWood'
     SoundFootsteps(14)=SoundGroup'KF_PlayerGlobalSnd.Player_StepDefault'
     SoundFootsteps(15)=SoundGroup'KF_PlayerGlobalSnd.Player_StepMetal'
     SoundFootsteps(16)=SoundGroup'KF_PlayerGlobalSnd.Player_StepDefault'
     SoundFootsteps(17)=SoundGroup'KF_PlayerGlobalSnd.Player_StepDefault'
     SoundFootsteps(18)=SoundGroup'KF_PlayerGlobalSnd.Player_StepDefault'
     SoundFootsteps(19)=SoundGroup'KF_PlayerGlobalSnd.Player_StepDefault'
     WeaponFireSound=SoundGroup'KF_BullpupSnd.Bullpup_Fire'
     WeaponReloadSound=Sound'KF_BullpupSnd.Bullpup_Reload_013'
     WAttachClass=Class'KFMod.BullpupAttachment'
     AmmoPerClip=20
     WeaponHitDamage(0)=3
     WeaponHitDamage(1)=4
     WeaponFireRate=0.100000
     WeaponMissRate=0.025000
     FireOffset=(X=0.800000)
     WeaponFireTime=1.250000
     AimingError=300.000000
     FireAnim="BullpupFire"
     WeaponReloadAnim="ReloadBullpup"
     MeleeAttackAnim="AxeAttack"
     bFightOnSight=True
     bPickVisPointOnHunt=True
     bFreezeActionAnim=True
     MoanVoice=SoundGroup'LairMonstersV1_S.Talk.ZEDTalk'
     KFHitFront="HitF"
     KFHitBack="HitB"
     KFHitLeft="HitL"
     KFHitRight="HitR"
     MeleeDamage=35
     MeleeAttackHitSound=SoundGroup'KF_AxeSnd.Axe_HitWood'
     LeftShoulderBone="Bip01 L UpperArm"
     RightShoulderBone="Bip01 R UpperArm"
     LeftThighBone="Bip01 L Thigh"
     RightThighBone="Bip01 R Thigh"
     LeftFArmBone="Bip01 L Forearm"
     RightFArmBone="Bip01 R Forearm"
     LeftFootBone="Bip01 L Foot"
     RightFootBone="Bip01 R Foot"
     LeftHandBone="bip01 l hand"
     RightHandBone="Bip01 R Hand"
     NeckBone="Bip01 Neck"
     OriginalGroundSpeed=500.000000
     HeadHealth=200.000000
     HitSound(0)=SoundGroup'LairMonstersV1_S.Misc.ZEDPain'
     DeathSound(0)=SoundGroup'LairMonstersV1_S.Misc.ZEDDie'
     IdleHeavyAnim="BullpupIdle"
     IdleRifleAnim="BullpupIdle"
     FireRootBone="bip01 Spine"
     RagdollOverride="Male"
     bCanCrouch=True
     bCanStrafe=True
     GroundSpeed=200.000000
     CrouchHeight=38.000000
     HealthMax=300.000000
     Health=300
     MenuName="Infected Soldier"
     ControllerClass=Class'LairMonstersV1.LairSoldierController'
     MovementAnims(1)="RunB"
     TurnLeftAnim="TurnL"
     TurnRightAnim="TurnR"
     CrouchAnims(0)="CrouchF"
     CrouchAnims(1)="CrouchB"
     CrouchAnims(2)="CrouchL"
     CrouchAnims(3)="CrouchR"
     WalkAnims(1)="WalkB"
     WalkAnims(2)="WalkL"
     WalkAnims(3)="WalkR"
     AirAnims(0)="JumpF_Mid"
     AirAnims(1)="JumpB_Mid"
     AirAnims(2)="JumpL_Mid"
     AirAnims(3)="JumpR_Mid"
     TakeoffAnims(0)="JumpF_Takeoff"
     TakeoffAnims(1)="JumpB_Takeoff"
     TakeoffAnims(2)="JumpL_Takeoff"
     TakeoffAnims(3)="JumpR_Takeoff"
     LandAnims(0)="JumpF_Land"
     LandAnims(1)="JumpB_Land"
     LandAnims(2)="JumpL_Land"
     LandAnims(3)="JumpR_Land"
     DoubleJumpAnims(0)="DoubleJumpF"
     DoubleJumpAnims(1)="DoubleJumpB"
     DoubleJumpAnims(2)="DoubleJumpL"
     DoubleJumpAnims(3)="DoubleJumpR"
     AirStillAnim="Jump_Mid"
     TakeoffStillAnim="Jump_Takeoff"
     CrouchTurnRightAnim="Crouch_TurnR"
     CrouchTurnLeftAnim="Crouch_TurnR"
     IdleCrouchAnim="Crouch"
     IdleSwimAnim="Swim_Tread"
     IdleWeaponAnim="BullpupIdle"
     IdleRestAnim="BullpupIdle"
     RootBone="Bip01"
     HeadBone="Bip01 Head"
     SpineBone1="Bip01 Spine1"
     SpineBone2="bip01 Spine2"
     Mesh=SkeletalMesh'KFSoldiers.Soldier'
     LODBias=6.000000
     PrePivot=(Z=0.000000)
     Skins(0)=Texture'KFCharacters.DavinSkin'
     Skins(1)=Texture'KFCharacters.JimBadge'
     Skins(2)=FinalBlend'KFCharacters.GasMaskFinal'
     ScaleGlow=0.800000
     CollisionRadius=20.000000
     CollisionHeight=50.000000
}
