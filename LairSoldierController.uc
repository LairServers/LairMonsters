Class LairSoldierController extends KFMonsterController;

var LairSoldierBase ZZB;
var vector MoveStartSpot;
var byte NumReloadMoves;
var NavigationPoint RandomMoveDest;

function DoCharge()
{
	if(pawn != none)
	{
		KFM.MeleeRange = KFM.default.MeleeRange;
		GotoState('ZombieHunt');
	}
}

function ExecuteWhatToDoNext()
{
	bHasFired = false;
	GoalString = "WhatToDoNext at "$Level.TimeSeconds;

	if ( Pawn == None )
	{
		warn(GetHumanReadableName()$" WhatToDoNext with no pawn");
		return;
	}

	if ( bPreparingMove && ZZB.bShotAnim && (ZZB.bFreezeActionAnim || ZZB.ExpectingChannel==0) )
	{
		Pawn.Acceleration = vect(0,0,0);
		GotoState('WaitForAnim');
		return;
	}
	if (Pawn.Physics == PHYS_None)
		Pawn.SetMovementPhysics();
	if ( (Pawn.Physics == PHYS_Falling) && DoWaitForLanding() )
		return;

	if ( (Enemy != None) && ((Enemy.Health <= 0) || (Enemy.Controller == None)) )
		Enemy = None;

	if ( Level.Game.bGameEnded && (Enemy != None) && Enemy.Controller.bIsPlayer )
		Enemy = None;

	if ( (Enemy == None) || !EnemyVisible() )
		FindNewEnemy();

	Pawn.bWantsToCrouch = false;
	if( ZZB.WhatToDoNext() )
		return;

	if ( Enemy != None )
		ChooseAttackMode();
	else
	{
		GoalString = "WhatToDoNext Wander or Camp at "$Level.TimeSeconds;
		WanderOrCamp(true);
	}
}

function FightEnemy(bool bCanCharge)
{
	if( ZZB.bShotAnim && (ZZB.bFreezeActionAnim || ZZB.ExpectingChannel==0) )
	{
		GoToState('WaitForAnim');
		Return;
	}
	KFM.MeleeRange = KFM.default.MeleeRange;

	if ( Enemy == none || Enemy.Health <= 0 )
		FindNewEnemy();

	if ( (Enemy == FailedHuntEnemy) && (Level.TimeSeconds == FailedHuntTime) )
	{
		if ( Enemy == FailedHuntEnemy )
		{
			GoalString = "FAILED HUNT - HANG OUT";
			if ( EnemyVisible() )
				bCanCharge = false;
		}
	}
	if ( !EnemyVisible() )
	{
		GoalString = "Hunt";
		GotoState('ZombieHunt');
		return;
	}

	// see enemy - decide whether to charge it or strafe around/stand and fire
	Target = Enemy;
	GoalString = "Charge";
	PathFindState = 2;
	DoCharge();
}

final function bool PickCover()
{
	local NavigationPoint N,Best;
	local float Dist,BDist;

	for( N=Level.NavigationPointList; N!=None; N=N.nextNavigationPoint )
	{
		Dist = VSizeSquared(N.Location-Pawn.Location);
		if( Dist>810000 || (Enemy!=None && FastTrace(Enemy.Location,N.Location)) || !ActorReachable(N) )
			continue;
		Dist+=Dist*FRand();
		if( Best==None || Dist>BDist )
		{
			Best = N;
			BDist = Dist;
		}
	}
	MoveTarget = Best;
	return (Best!=None);
}

state GoReloading
{
Ignores SeePlayer,HearNoise,DamageAttitudeTo,EnemyNotVisible;

	function BeginState()
	{
		NumReloadMoves = 0;
		RandomMoveDest = None;
		SetTimer(0.25,true);
	}
	function Timer()
	{
		if( Enemy!=None && !LineOfSightTo(Enemy) )
			GoToState(,'ReloadNow');
	}
	final function PickDestination()
	{
		if( PickCover() )
			return;
		if( RandomMoveDest==None )
		{
			RandomMoveDest = FindRandomDest();
			if( RandomMoveDest==None )
			{
FailedMove:
				Destination = Pawn.Location+VRand()*400.f;
				NumReloadMoves+=5;
				return;
			}
		}
		if( ActorReachable(RandomMoveDest) )
		{
			MoveTarget = RandomMoveDest;
			RandomMoveDest = None;
			return;
		}
		if( FindBestPathToward(RandomMoveDest,true,true) )
			return;
		RandomMoveDest = None;
		GoTo'FailedMove';
	}
Begin:
	MoveStartSpot = Pawn.Location;
	PickDestination();
	if( MoveTarget!=None )
		MoveToward(MoveTarget,Enemy);
	else MoveTo(Destination,Enemy);
	if( Enemy==None || !LineOfSightTo(Enemy) || ++NumReloadMoves>10 )
	{
ReloadNow:
		SetTimer(0.f,false);
		Focus = None;
		FocalPoint = MoveStartSpot;
		FinishRotation();
		ZZB.PlayReloading();
		GotoState('WaitForAnim');
	}
	GoTo'Begin';
}
state AttackEnemy
{
	function BeginState()
	{
		SetTimer(0.25,true);
	}
	function EndState()
	{
		if( ZZB!=None && ZZB.Health>0 )
			ZZB.FinishAttacking();
	}
	function EnemyNotVisible()
	{
		ZZB.LostContact();
		WhatToDoNext(21);
	}
	function Timer()
	{
		if( Enemy==None || Enemy.Health<=0 )
		{
			Enemy = None;
			ZZB.LostContact();
			WhatToDoNext(26);
		}
	}
Begin:
	ZZB.PrepareToAttack(Enemy);
	FinishRotation();
	Sleep(ZZB.FightEnemyNow(Enemy));
	WhatToDoNext(27);
}
state ZombieHunt
{
	function BeginState()
	{
		bHuntPlayer = true;
		bHunting = true;
		SetTimer(0.15,true);
	}
	function EndState()
	{
		bHuntPlayer = false;
		bHunting = false;
	}
	function Timer()
	{
		if( Enemy!=None && Enemy.Health>0 && CanSee(Enemy) )
			ZZB.RangedAttack(Enemy);
	}
	function SeePlayer(Pawn SeenPlayer)
	{
		if ( SeenPlayer == Enemy )
		{
			if ( Level.timeseconds - ChallengeTime > 7 )
			{
				ChallengeTime = Level.TimeSeconds;
				ZZB.ZombieMoan();
			}
			VisibleEnemy = Enemy;
			EnemyVisibilityTime = Level.TimeSeconds;
			bEnemyIsVisible = true;
			Focus = Enemy;
			if ( ZZB.TauntAtEnemy() )
				GotoState('WaitForAnim');
		}
		else Global.SeePlayer(SeenPlayer);
	}
	final function bool PickVisibleNode()
	{
		local NavigationPoint N,Best;
		local float Dist,BDist;

		for( N=Level.NavigationPointList; N!=None; N=N.nextNavigationPoint )
		{
			Dist = VSizeSquared(N.Location-Pawn.Location);
			if( Dist>810000 || !FastTrace(Enemy.Location,N.Location) || !ActorReachable(N) )
				continue;
			ZZB.DesireAttackPoint(Dist,N,Enemy);
			if( Dist<0 )
				continue;
			if( Best==None || Dist>BDist )
			{
				Best = N;
				BDist = Dist;
			}
		}
		if( Best!=None )
		{
			MoveTarget = Best;
			return true;
		}
		return false;
	}
	function PickDestination()
	{
		local vector nextSpot, ViewSpot,Dir;
		local float posZ;
		local bool bCanSeeLastSeen;

		if ( Enemy==None || Enemy.Health<=0 )
		{
			Enemy = None;
			WhatToDoNext(23);
			return;
		}
		if( ZZB.bFightOnSight && Enemy!=None && ZZB.ReadyToFire(Enemy) )
		{
			GoToState('AttackEnemy');
			return;
		}
		if( ZZB.bPickVisPointOnHunt && PickVisibleNode() )
			return;
		if( PathFindState==0 )
		{
			InitialPathGoal = FindRandomDest();
			PathFindState = 1;
		}
		if( PathFindState==1 )
		{
			if( InitialPathGoal==None )
				PathFindState = 2;
			else if( ActorReachable(InitialPathGoal) )
			{
				MoveTarget = InitialPathGoal;
				PathFindState = 2;
				Return;
			}
			else if( FindBestPathToward(InitialPathGoal, true,true) )
				Return;
			else PathFindState = 2;
		}

		if ( Pawn.JumpZ > 0 )
			Pawn.bCanJump = true;

		if( KFM.Intelligence==BRAINS_Retarded && FRand()<0.25 )
		{
			Destination = Pawn.Location+VRand()*200;
			Return;
		}
		if ( ActorReachable(Enemy) )
		{
			Destination = Enemy.Location;
			if( KFM.Intelligence==BRAINS_Retarded && FRand()<0.5 )
			{
				Destination+=VRand()*50;
				Return;
			}
			MoveTarget = None;
			return;
		}

		ViewSpot = Pawn.Location + Pawn.BaseEyeHeight * vect(0,0,1);
		bCanSeeLastSeen = bEnemyInfoValid && FastTrace(LastSeenPos, ViewSpot);

		if ( FindBestPathToward(Enemy, true,true) )
			return;

		if ( bSoaking && (Physics != PHYS_Falling) )
			SoakStop("COULDN'T FIND PATH TO ENEMY "$Enemy);

		MoveTarget = None;
		if ( !bEnemyInfoValid )
		{
			Enemy = None;
			GotoState('StakeOut');
			return;
		}

		Destination = LastSeeingPos;
		bEnemyInfoValid = false;
		if ( FastTrace(Enemy.Location, ViewSpot)
			 && VSize(Pawn.Location - Destination) > Pawn.CollisionRadius )
		{
			SeePlayer(Enemy);
			return;
		}

		posZ = LastSeenPos.Z + Pawn.CollisionHeight - Enemy.CollisionHeight;
		nextSpot = LastSeenPos - Normal(Enemy.Velocity) * Pawn.CollisionRadius;
		nextSpot.Z = posZ;
		if ( FastTrace(nextSpot, ViewSpot) )
			Destination = nextSpot;
		else if ( bCanSeeLastSeen )
		{
			Dir = Pawn.Location - LastSeenPos;
			Dir.Z = 0;
			if ( VSize(Dir) < Pawn.CollisionRadius )
			{
				Destination = Pawn.Location+VRand()*500;
				return;
			}
			Destination = LastSeenPos;
		}
		else
		{
			Destination = LastSeenPos;
			if ( !FastTrace(LastSeenPos, ViewSpot) )
			{
				// check if could adjust and see it
				if ( PickWallAdjust(Normal(LastSeenPos - ViewSpot)) || FindViewSpot() )
				{
					if ( Pawn.Physics == PHYS_Falling )
						SetFall();
					else GotoState('Hunting', 'AdjustFromWall');
				}
				else Destination = Pawn.Location+VRand()*500;
			}
		}
	}

AdjustFromWall:
	MoveTo(Destination, MoveTarget);

Begin:
	WaitForLanding();
	if ( CanSee(Enemy) )
		SeePlayer(Enemy);
WaitForAnim:
	if( ZZB.bShotAnim && (ZZB.bFreezeActionAnim || ZZB.ExpectingChannel==0) )
	{
		while( ZZB.bShotAnim )
			Sleep(0.25f);
	}
	PickDestination();

SpecialNavig:
	MoveStartSpot = Pawn.Location;
	if (MoveTarget == None)
		MoveTo(Destination);
	else
		MoveToward(MoveTarget,FaceActor(10),,(FRand() < 0.75) && ShouldStrafeTo(MoveTarget));

	// We entered to line of sight with the enemy and enemy is looking at me, back off again.
	MoveTarget = None;
	if( ZZB.bLurker && Enemy!=None && LineOfSightTo(Enemy) && ZZB.LurkBackOff(Enemy) && (PointReachable(MoveStartSpot) || PickCover()) )
	{
		if( MoveTarget!=None )
			MoveToward(MoveTarget,Enemy);
		else MoveTo(MoveStartSpot,Enemy);
		if( Enemy!=None && !LineOfSightTo(Enemy) )
		{
			Pawn.Acceleration = vect(0,0,0);
			Pawn.bWantsToCrouch = true;
			Focus = Enemy;
			Sleep(1.f+FRand()*1.5f);
		}
	}

	WhatToDoNext(27);
	if ( bSoaking )
		SoakStop("STUCK IN HUNTING!");
}

defaultproperties
{
}
