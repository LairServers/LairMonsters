Class ZEDMario extends ZEDSoldierBase;

#exec obj load file="Mario.ukx" package="ZEDSoldiers"

function RangedAttack(Actor A)
{
	local float D;

	D = VSize(A.Location-Location);
	if( Physics==PHYS_Walking && D<800.f && Controller.ActorReachable(A) && CheckJumpReach(A) )
	{
		Controller.MoveTarget = A;
		Acceleration = vect(0,0,0);
		SetPhysics(PHYS_Falling);
		Velocity = SuggestFallVelocity(A.Location+A.Velocity+vect(0,0,1)*(A.CollisionHeight+CollisionHeight),Location,GetJumpHeight(A),FMax(D*1.5f,200));
		PlaySound(JumpSound,SLOT_Interact);
		Controller.GoToState('ZombieHunt','Begin');
	}
}
final function bool CheckJumpReach( Actor A )
{
	local vector E,End,Dummy;

	E.X = FMin(CollisionRadius,A.CollisionRadius);
	E.Y = E.X;
	E.Z = FMin(CollisionHeight,A.CollisionHeight);

	End = (Location+A.Location)*0.5f;
	End.Z = FMax(Location.Z,A.Location.Z)+350.f;
	return (Trace(Dummy,Dummy,End,Location,false,E)==None && A.Trace(Dummy,Dummy,End,A.Location,false,E)==None);
}
final function float GetJumpHeight( Actor A )
{
	return (FMax(A.Location.Z-Location.Z,0.f)+600.f);
}

function ZombieMoan();

function bool TauntAtEnemy()
{
	if( Super.TauntAtEnemy() )
	{
		PlaySound(Sound'MarioTaunt',SLOT_Interact);
		return true;
	}
	return false;
}

simulated function int DoAnimAction( name AnimName )
{
	if( AnimName==FireAnim )
	{
		AnimBlendParams(1, 1.0, 0.0,, SpineBone1);
		PlayAnim(AnimName,2.f, 0.1, 1);
		return 1;
	}
	return Super.DoAnimAction(AnimName);
}

// Only ready to attack once close enough.
function bool ReadyToFire( Pawn Enemy )
{
	return (VSizeSquared(Location-Enemy.Location)<1000000 && FRand()<0.5f && Super.ReadyToFire(Enemy));
}

function TossFireball()
{
	bShotAnim = true;
	SetAnimAction(FireAnim);
	Acceleration = vect(0,0,0);
	SetTimer(WeaponFireRate,false);
}
function FireWeaponOnce()
{
	local vector Start;
	local rotator R;

	Controller.Target = Controller.Enemy;

	if ( !SavedFireProperties.bInitialized )
	{
		SavedFireProperties.AmmoClass = Class'FlameAmmo';
		SavedFireProperties.ProjectileClass = Class'MarioFireBall';
		SavedFireProperties.WarnTargetPct = 0.2;
		SavedFireProperties.MaxRange = 2000;
		SavedFireProperties.bTossed = True;
		SavedFireProperties.bTrySplash = True;
		SavedFireProperties.bLeadTarget = True;
		SavedFireProperties.bInstantHit = false;
		SavedFireProperties.bInitialized = true;
	}

	Start = GetFirePosStart();
	R = AdjustAim(SavedFireProperties,Start,AimingError);

	Spawn(Class'MarioFireBall',,,Start,R);
	PlaySound(WeaponFireSound,SLOT_Interact,TransientSoundVolume * 2.5,,TransientSoundRadius,(1.0 + FRand()*0.015f),false);
}
function DesireAttackPoint( out float Desire, NavigationPoint N, Pawn Enemy )
{
	// Must attack from close distance.
	if( VSizeSquared(N.Location-Enemy.Location)>1000000 )
		Desire = -1;
	else Desire += Desire*FRand();
}
function PrepareToAttack( Pawn Enemy )
{
	Super.PrepareToAttack(Enemy);
	bWantsToCrouch = false;
}
function float FightEnemyNow( Pawn Enemy ) // Return attack time.
{
	GoToState('FiringWeapon');
	return GetAnimDuration(FireAnim);
}
singular event BaseChange()
{
	local float decorMass;

	if ( bInterpolating )
		return;
	if ( (base == None) && (Physics == PHYS_None) )
		SetPhysics(PHYS_Falling);
	// Pawns can only set base to non-pawns, or pawns which specifically allow it.
	// Otherwise we do some damage and jump off.
	else if ( Pawn(Base) != None && Base != DrivenVehicle )
	{
		if ( !Pawn(Base).bCanBeBaseForPawns )
		{
			PlaySound(Sound'Stomp',SLOT_Talk,TransientSoundVolume * 2.5);
			Base.TakeDamage( 8000, Self,Location,0.5 * Velocity , class'Crushed');
			JumpOffPawn();
		}
	}
	else if ( (Decoration(Base) != None) && (Velocity.Z < -400) )
	{
		decorMass = FMax(Decoration(Base).Mass, 1);
		Base.TakeDamage((-2* Mass/decorMass * Velocity.Z/400), Self, Location, 0.5 * Velocity, class'Crushed');
	}
}

State FiringWeapon
{
	function AnimEnd( int Channel )
	{
		Global.AnimEnd(Channel);
		if( !bShotAnim )
			TossFireball();
	}
	function BeginState()
	{
		TossFireball();
	}
	function Timer()
	{
		FireWeaponOnce();
	}
}

defaultproperties
{
     WeaponFireSound=Sound'LairMonstersV1.fx.Fireball'
     WAttachClass=Class'KFMod.FlameThrowerAttachment'
     WeaponFireRate=0.450000
     WeaponMissRate=0.150000
     FireOffset=(X=1.000000,Z=0.400000)
     AimingError=350.000000
     FireAnim="NadeToss"
     MoanVoice=None
     JumpSound=Sound'LairMonstersV1.fx.Jump'
     OriginalGroundSpeed=270.000000
     HeadHealth=750.000000
     HitSound(0)=Sound'LairMonstersV1.Taunts.mario-pain'
     DeathSound(0)=Sound'LairMonstersV1.Taunts.mario-die'
     ScoringValue=40
     IdleHeavyAnim="NadeIdle"
     IdleRifleAnim="NadeIdle"
     JumpZ=600.000000
     HealthMax=800.000000
     Health=800
     MenuName="Super Mario"
     IdleWeaponAnim="NadeIdle"
     IdleRestAnim="NadeIdle"
     Mesh=SkeletalMesh'LairMonstersV1.MarioMesh'
     Skins(0)=Texture'LairMonstersV1.Skins.marioheadA'
     Skins(1)=Texture'LairMonstersV1.Skins.marioheadA'
}
