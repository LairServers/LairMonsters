//Don't forget to get the Gib Group class: GibGroupAlien
class LairAliensController extends KFMonsterController
    config(User);

var LairAliensBase ab;
var transient float ValidKillTime;
var transient byte NoneSightCount;
var transient bool bInitKill;

function Restart()
{
    ab = LairAliensBase(Pawn);
    super.Restart();
    //return;    
}

function bool CanKillMeYet()
{
    local Controller C;

    // End:0x14
    // End:0x47
    if(!bInitKill)
    {
        bInitKill = true;
        ValidKillTime = Level.TimeSeconds + 60.0;
        return false;
    }
    // End:0x61
    else
    {
        // End:0x61
        if(ValidKillTime > Level.TimeSeconds)
        {
            return false;
        }
    }
    C = Level.ControllerList;
    J0x75:
    // End:0x114 [Loop If]
    if(C != none)
    {
        // End:0xFD
        if((((C.bIsPlayer && C.PlayerReplicationInfo != none) && C.Pawn != none) && C.Pawn.Health > 0) && C.LineOfSightTo(Pawn))
        {
            NoneSightCount = 0;
            return false;
        }
        C = C.nextController;
        // [Loop Continue]
        goto J0x75;
    }
    return ++ NoneSightCount > 45;
    //return;    
}

function bool FindNewEnemy()
{
    local Pawn BestEnemy;
    local float BestDist, newdist;
    local Controller PC;

    // End:0x14
    if(KFM.bNoAutoHuntEnemies)
    {
        return false;
    }
    PC = Level.ControllerList;
    J0x28:
    // End:0x10F [Loop If]
    if(PC != none)
    {
        // End:0xF8
        if(((PC.bIsPlayer && PC.Pawn != none) && PC.Pawn.Health > 0) && KFHumanPawn(PC.Pawn) != none)
        {
            newdist = ab.GetEnemyDesire(KFHumanPawn(PC.Pawn));
            // End:0xF8
            if((BestEnemy == none) || newdist < BestDist)
            {
                BestEnemy = PC.Pawn;
                BestDist = newdist;
            }
        }
        PC = PC.nextController;
        // [Loop Continue]
        goto J0x28;
    }
    // End:0x120
    if(BestEnemy == Enemy)
    {
        return false;
    }
    // End:0x13E
    if(BestEnemy != none)
    {
        Enemy = none;
        return SetEnemy(BestEnemy);
    }
    return false;
    //return;    
}

function bool SetEnemy(Pawn NewEnemy, optional bool bHateMonster)
{
    // End:0x12
    if(AliensBase(NewEnemy) != none)
    {
        return false;
    }
    // End:0x14A
    if((((((KFM.Intelligence >= 2) && Enemy != none) && NewEnemy != none) && NewEnemy != Enemy) && NewEnemy.Controller != none) && NewEnemy.Controller.bIsPlayer)
    {
        // End:0xE7
        if((KFHumanPawn(Enemy) != none) && KFHumanPawn(NewEnemy) != none)
        {
            // End:0xE4
            if(ab.GetEnemyDesire(KFHumanPawn(Enemy)) > ab.GetEnemyDesire(KFHumanPawn(NewEnemy)))
            {
                return false;
            }
        }
        // End:0x143
        else
        {
            // End:0x143
            if(LineOfSightTo(Enemy) && VSizeSquared(Enemy.Location - Pawn.Location) < VSizeSquared(NewEnemy.Location - Pawn.Location))
            {
                return false;
            }
        }
        Enemy = none;
    }
    // End:0x212
    if((((((bHateMonster && KFMonster(NewEnemy) != none) && NewEnemy.Controller != none) && (NewEnemy.Controller.Target == Pawn) || FRand() < 0.150) && NewEnemy.Health > 0) && VSize(NewEnemy.Location - Pawn.Location) < float(1500)) && LineOfSightTo(NewEnemy))
    {
        ChangeEnemy(NewEnemy, CanSee(NewEnemy));
        return true;
    }
    // End:0x271
    if(super(MonsterController).SetEnemy(NewEnemy, bHateMonster))
    {
        // End:0x26F
        if(!bTriggeredFirstEvent)
        {
            bTriggeredFirstEvent = true;
            // End:0x26F
            if(KFM.FirstSeePlayerEvent != 'None')
            {
                TriggerEvent(KFM.FirstSeePlayerEvent, Pawn, Pawn);
            }
        }
        return true;
    }
    return false;
    //return;    
}

function ChangeEnemy(Pawn NewEnemy, bool bCanSeeNewEnemy)
{
    super(MonsterController).ChangeEnemy(NewEnemy, bCanSeeNewEnemy);
    ab.ChangedEnemy(NewEnemy);
    //return;    
}

final function FindHidingPoint()
{
    local NavigationPoint N, Best;
    local float D, BestD;

    N = Level.NavigationPointList;
    J0x14:
    // End:0xD2 [Loop If]
    if(N != none)
    {
        D = VSizeSquared(N.Location - Pawn.Location);
        // End:0xBB
        if(((D < 4000000.0) && !Enemy.LineOfSightTo(N)) && ActorReachable(N))
        {
            D *= FRand();
            // End:0xBB
            if((Best == none) || BestD < D)
            {
                Best = N;
                BestD = D;
            }
        }
        N = N.nextNavigationPoint;
        // [Loop Continue]
        goto J0x14;
    }
    // End:0xEB
    if(Best != none)
    {
        MoveTarget = Best;
    }
    // End:0x13E
    else
    {
        // End:0xFF
        if(InitialPathGoal == none)
        {
            InitialPathGoal = FindRandomDest();
        }
        // End:0x121
        if(ActorReachable(InitialPathGoal))
        {
            MoveTarget = InitialPathGoal;
            InitialPathGoal = none;
            return;
        }
        // End:0x133
        else
        {
            // End:0x133
            if(FindBestPathToward(InitialPathGoal, true, true))
            {
                return;
            }
        }
        MoveTarget = Enemy;
    }
    //return;    
}

function FightEnemy(bool bCanCharge)
{
    // End:0x26
    if(bPreparingMove && KFM.bShotAnim)
    {
        GotoState('WaitForAnim');
        return;
    }
    // End:0x64
    if(KFM.MeleeRange != KFM.default.MeleeRange)
    {
        KFM.MeleeRange = KFM.default.MeleeRange;
    }
    // End:0x8B
    if((Enemy == none) || Enemy.Health <= 0)
    {
        FindNewEnemy();
    }
    // End:0xF2
    if((Enemy == FailedHuntEnemy) && Level.TimeSeconds == FailedHuntTime)
    {
        // End:0xF2
        if(Enemy == FailedHuntEnemy)
        {
            GoalString = "FAILED HUNT - HANG OUT";
            // End:0xF2
            if(EnemyVisible())
            {
                bCanCharge = false;
            }
        }
    }
    // End:0x112
    if(!EnemyVisible())
    {
        GoalString = "Hunt";
        GotoState('ZombieHunt');
        return;
    }
    Target = Enemy;
    GoalString = "Charge";
    PathFindState = 2;
    DoCharge();
    //return;    
}

function ExecuteWhatToDoNext()
{
    bHasFired = false;
    GoalString = "WhatToDoNext at " $ string(Level.TimeSeconds);
    // End:0x65
    if(Pawn == none)
    {
        WarnInternal((GetHumanReadableName()) $ " WhatToDoNext with no pawn");
        return;
    }
    // End:0x91
    if(KFM.bStartUpDisabled)
    {
        KFM.bStartUpDisabled = false;
        GotoState('WaitToStart');
        return;
    }
    // End:0xB7
    if(bPreparingMove && KFM.bShotAnim)
    {
        GotoState('WaitForAnim');
        return;
    }
    // End:0xDF
    if(Level.Game.bGameEnded && FindFreshBody())
    {
        return;
    }
    // End:0x107
    if(Pawn.Physics == 0)
    {
        Pawn.SetMovementPhysics();
    }
    // End:0x12D
    if((Pawn.Physics == 2) && DoWaitForLanding())
    {
        return;
    }
    // End:0x16B
    if((Enemy != none) && (Enemy.Health <= 0) || Enemy.Controller == none)
    {
        Enemy = none;
    }
    // End:0x189
    if((Enemy == none) || !EnemyVisible())
    {
        FindNewEnemy();
    }
    // End:0x19D
    if(Enemy != none)
    {
        ChooseAttackMode();
    }
    // End:0x1DD
    else
    {
        GoalString = "WhatToDoNext Wander or Camp at " $ string(Level.TimeSeconds);
        WanderOrCamp(true);
    }
    //return;    
}

final function MoveToPoint(optional Actor MoveT, optional Vector Dest)
{
    MoveTarget = MoveT;
    Destination = Dest;
    GotoState('AIMoveToPoint', 'Begin');
    //return;    
}

state ZombieHunt
{
    function BeginState()
    {
        //return;        
    }

    function EndState()
    {
        //return;        
    }

    function PickDestination()
    {
        local Vector nextSpot, ViewSpot, Dir;
        local float posZ;
        local bool bCanSeeLastSeen;

        // End:0x0B
        if(FindFreshBody())
        {
            return;
        }
        // End:0x3D
        if((Enemy != none) && Enemy.Health <= 0)
        {
            Enemy = none;
            WhatToDoNext(23);
            return;
        }
        // End:0x5B
        if(PathFindState == 0)
        {
            InitialPathGoal = FindRandomDest();
            PathFindState = 1;
        }
        // End:0xD2
        if(PathFindState == 1)
        {
            // End:0x7E
            if(InitialPathGoal == none)
            {
                PathFindState = 2;
            }
            // End:0xD2
            else
            {
                // End:0xB5
                if(ActorReachable(InitialPathGoal))
                {
                    MoveTarget = InitialPathGoal;
                    PathFindState = 2;
                    // End:0xB0
                    if(FRand() < 0.30)
                    {
                        PathFindState = 0;
                    }
                    return;
                }
                // End:0xD2
                else
                {
                    // End:0xCA
                    if(FindBestPathToward(InitialPathGoal, true, true))
                    {
                        return;
                    }
                    // End:0xD2
                    else
                    {
                        PathFindState = 2;
                    }
                }
            }
        }
        // End:0xF9
        if(Pawn.JumpZ > float(0))
        {
            Pawn.bCanJump = true;
        }
        // End:0x140
        if((KFM.Intelligence == 0) && FRand() < 0.250)
        {
            Destination = Pawn.Location + (VRand() * float(200));
            return;
        }
        // End:0x1C9
        if(ActorReachable(Enemy))
        {
            // End:0x174
            if(ab.bShouldLurk)
            {
                ab.HuntHadContact();
                FindHidingPoint();
                return;
            }
            Destination = Enemy.Location;
            // End:0x1C0
            if((KFM.Intelligence == 0) && FRand() < 0.50)
            {
                Destination += (VRand() * float(50));
                return;
            }
            MoveTarget = none;
            return;
        }
        ViewSpot = Pawn.Location + (Pawn.BaseEyeHeight * vect(0.0, 0.0, 1.0));
        bCanSeeLastSeen = bEnemyInfoValid && FastTrace(LastSeenPos, ViewSpot);
        // End:0x26D
        if(FindBestPathToward(Enemy, true, true))
        {
            // End:0x26B
            if(ab.bShouldLurk && Enemy.LineOfSightTo(MoveTarget))
            {
                ab.HuntHadContact();
                FindHidingPoint();
            }
            return;
        }
        // End:0x2B5
        if(bSoaking && Physics != 2)
        {
            SoakStop("COULDN'T FIND PATH TO ENEMY " $ string(Enemy));
        }
        MoveTarget = none;
        // End:0x2D7
        if(!bEnemyInfoValid)
        {
            Enemy = none;
            GotoState('StakeOut');
            return;
        }
        Destination = LastSeeingPos;
        bEnemyInfoValid = false;
        // End:0x33C
        if(FastTrace(Enemy.Location, ViewSpot) && VSize(Pawn.Location - Destination) > Pawn.CollisionRadius)
        {
            SeePlayer(Enemy);
            return;
        }
        posZ = (LastSeenPos.Z + Pawn.CollisionHeight) - Enemy.CollisionHeight;
        nextSpot = LastSeenPos - (Normal(Enemy.Velocity) * Pawn.CollisionRadius);
        nextSpot.Z = posZ;
        // End:0x3C7
        if(FastTrace(nextSpot, ViewSpot))
        {
            Destination = nextSpot;
        }
        // End:0x4D6
        else
        {
            // End:0x446
            if(bCanSeeLastSeen)
            {
                Dir = Pawn.Location - LastSeenPos;
                Dir.Z = 0.0;
                // End:0x438
                if(VSize(Dir) < Pawn.CollisionRadius)
                {
                    Destination = Pawn.Location + (VRand() * float(500));
                    return;
                }
                Destination = LastSeenPos;
            }
            // End:0x4D6
            else
            {
                Destination = LastSeenPos;
                // End:0x4D6
                if(!FastTrace(LastSeenPos, ViewSpot))
                {
                    // End:0x4B3
                    if(PickWallAdjust(Normal(LastSeenPos - ViewSpot)) || FindViewSpot())
                    {
                        // End:0x4A4
                        if(Pawn.Physics == 2)
                        {
                            SetFall();
                        }
                        // End:0x4B0
                        else
                        {
                            GotoState('Hunting', 'AdjustFromWall');
                        }
                    }
                    // End:0x4D6
                    else
                    {
                        Destination = Pawn.Location + (VRand() * float(500));
                        return;
                    }
                }
            }
        }
        //return;        
    }
    stop;    
}

state ZombieCharge
{
Begin:
    // End:0x3B
    if(Pawn.Physics == 2)
    {
        Focus = Enemy;
        Destination = Enemy.Location;
        WaitForLanding();
    }
    // End:0x81
    if(ab.bShouldLurk && Enemy.LineOfSightTo(MoveTarget))
    {
        ab.ChargeHadContact();
        FindHidingPoint();
        goto 'moving';
    }
    // End:0x94
    if(Enemy == none)
    {
        WhatToDoNext(16);
    }
WaitForAnim:

    // End:0xBA
    if(bPreparingMove)
    {
        J0x9D:
        // End:0xBA [Loop If]
        if(KFM.bShotAnim)
        {
            Sleep(0.350);
            // [Loop Continue]
            goto J0x9D;
        }
    }
    // End:0xD3
    if(!FindBestPathToward(Enemy, false, true))
    {
        GotoState('TacticalMove');
    }
moving:

    // End:0x175
    if(KFM.Intelligence == 0)
    {
        // End:0x117
        if(FRand() < 0.30)
        {
            MoveTo(Pawn.Location + (VRand() * float(200)), none);
        }
        // End:0x172
        else
        {
            // End:0x153
            if((MoveTarget == Enemy) && FRand() < 0.50)
            {
                MoveTo(MoveTarget.Location + (VRand() * float(50)), none);
            }
            // End:0x172
            else
            {
                MoveToward(MoveTarget, FaceActor(1.0),, ShouldStrafeTo(MoveTarget));
            }
        }
    }
    // End:0x194
    else
    {
        MoveToward(MoveTarget, FaceActor(1.0),, ShouldStrafeTo(MoveTarget));
    }
    WhatToDoNext(17);
    // End:0x1BF
    if(bSoaking)
    {
        SoakStop("STUCK IN CHARGING!");
    }
    stop;                    
}

state StakeOut
{
    final function PickWanderMove()
    {
        // End:0x14
        if(InitialPathGoal == none)
        {
            InitialPathGoal = FindRandomDest();
        }
        // End:0x36
        if(ActorReachable(InitialPathGoal))
        {
            MoveTarget = InitialPathGoal;
            InitialPathGoal = none;
            return;
        }
        // End:0x52
        else
        {
            // End:0x4B
            if(FindBestPathToward(InitialPathGoal, true, true))
            {
                return;
            }
            // End:0x52
            else
            {
                InitialPathGoal = none;
            }
        }
        MoveTarget = none;
        //return;        
    }

Begin:
    Pawn.Acceleration = vect(0.0, 0.0, 0.0);
    Focus = none;
    Pawn.bWantsToCrouch = false;
    // End:0xAD
    if((Enemy != none) && LineOfSightTo(Enemy))
    {
        Focus = Enemy;
        FinishRotation();
        // End:0x84
        if((Enemy != none) && KFM.HasRangedAttack())
        {
            FireWeaponAt(Enemy);
        }
        // End:0xAA
        if(bPreparingMove)
        {
            J0x8D:
            // End:0xAA [Loop If]
            if(KFM.bShotAnim)
            {
                Sleep(0.150);
                // [Loop Continue]
                goto J0x8D;
            }
        }
    }
    // End:0xB3
    else
    {
        StopFiring();
    }
    Sleep(0.020);
    PickWanderMove();
    // End:0xEB
    if(MoveTarget == none)
    {
        MoveTo(Pawn.Location + (VRand() * 150.0));
    }
    // End:0xF3
    else
    {
        MoveToward(MoveTarget);
    }
    WhatToDoNext(31);
    // End:0x11E
    if(bSoaking)
    {
        SoakStop("STUCK IN STAKEOUT!");
    }
    stop;        
}

state AIMoveToPoint extends MoveToGoalNoEnemy
{
    ignores SetEnemy, damageAttitudeTo;

    function EndState()
    {
        ab.NotifyMoveDone();
        //return;        
    }

Begin:
    // End:0x16
    if(MoveTarget != none)
    {
        MoveToward(MoveTarget);
    }
    // End:0x1E
    else
    {
        MoveTo(Destination);
    }
    ab.NotifyMoveDone();
    WhatToDoNext(33);
    stop;            
}
