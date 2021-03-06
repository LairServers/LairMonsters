//Don't forget to get the Gib Group class: GibGroupAlien
class LairAliensBase extends KFMonster
    dependson(LairAliensController)
    hidecategories(AnimTweaks,DeRes,Force,Gib,Karma,UDamage,UnrealPawn)
    config(User)
    abstract;

struct FGibType
{
    var() name Bone;
    var() StaticMesh Mesh;
    var() float Scale;
    var byte bHidden;
};

var transient float NextLeapTime;
var transient float WallJumpTimer;
var transient float UnfearTimer;
var() float PounceSpeed;
var(Anims) name MeleeAirAnims[2];
var byte CurrentID;
var() array<FGibType> GibParts;
var() array<name> DeathAnimations;
var() class<Projectile> RangedProjectile;
var bool bShouldLurk;
var bool bHeadHasSplitted;
var bool bPouncing;
var bool bForcedWalkAnim;
var bool bClientWalkAnim;

replication
{
    // Pos:0x000
    reliable if(Role == ROLE_Authority)
        bForcedWalkAnim
}

simulated function PostNetReceive()
{
    // End:0x7A
    if(bClientWalkAnim != bForcedWalkAnim)
    {
        bClientWalkAnim = bForcedWalkAnim;
        // End:0x53
        if(bForcedWalkAnim)
        {
            // End:0x50
            if(Health > 0)
            {
                bPhysicsAnimUpdate = false;
                UnresolvedNativeFunction_97(MovementAnims[0], -1.0 / default.GroundSpeed);
            }
        }
        // End:0x7A
        else
        {
            // End:0x7A
            if(Health > 0)
            {
                bPhysicsAnimUpdate = default.bPhysicsAnimUpdate;
                UnresolvedNativeFunction_97(AirAnims[0], 0.050);
            }
        }
    }
    //return;    
}

simulated function PostBeginPlay()
{
    super.PostBeginPlay();
    CurrentID = byte(Rand(256));
    // End:0x2D
    if(default.OriginalGroundSpeed > float(0))
    {
        OriginalGroundSpeed = default.OriginalGroundSpeed;
    }
    //return;    
}

function PlayHit(float Damage, Pawn instigatedBy, Vector HitLocation, class<DamageType> DamageType, Vector Momentum, optional int HitIdx)
{
    //return;    
}

simulated function SetAnimAction(name NewAction)
{
    // End:0x11
    if(NewAction == 'None')
    {
        return;
    }
    ExpectingChannel = DoAnimAction(NewAction);
    // End:0x3D
    if(ExpectingChannel == 0)
    {
        bPhysicsAnimUpdate = false;
        bWaitForAnim = true;
    }
    // End:0x84
    if(Level.NetMode != NM_Client)
    {
        AnimAction = NewAction;
        bResetAnimAct = true;
        ResetAnimActTime = Level.TimeSeconds + 0.20;
    }
    //return;    
}

simulated function AnimEnd(int Channel)
{
    // End:0x49
    if(Channel == ExpectingChannel)
    {
        AnimAction = 'None';
        bShotAnim = false;
        ExpectingChannel = -1;
        // End:0x49
        if(Controller != none)
        {
            Controller.bPreparingMove = false;
        }
    }
    // End:0x90
    if(!bPhysicsAnimUpdate && Channel == 0)
    {
        // End:0x83
        if(bClientWalkAnim)
        {
            UnresolvedNativeFunction_97(MovementAnims[0], -1.0 / default.GroundSpeed);
        }
        // End:0x90
        else
        {
            bPhysicsAnimUpdate = default.bPhysicsAnimUpdate;
        }
    }
    super(xPawn).AnimEnd(Channel);
    //return;    
}

final simulated function Rotator GetFloorOrientation(Vector Norm, Vector Dir)
{
    local float DD;

    Dir = Normal(Dir);
    DD = Dir Dot Norm;
    J0x1F:
    // End:0x4D [Loop If]
    if(Abs(DD) > 0.990)
    {
        Dir = VRand();
        DD = Dir Dot Norm;
        // [Loop Continue]
        goto J0x1F;
    }
    Dir = Normal(Dir - (DD * Norm));
    return OrthoRotation(Dir, Normal(Norm Cross Dir), Norm);
    //return;    
}

function float GetEnemyDesire(KFHumanPawn Other)
{
    local float D;

    D = VSizeSquared(Other.Location - Location);
    // End:0x52
    if((D < 9000000.0) && Controller.LineOfSightTo(Other))
    {
        D *= 0.10;
    }
    return D;
    //return;    
}

function HuntHadContact()
{
    //return;    
}

function ChargeHadContact()
{
    //return;    
}

function ChangedEnemy(Pawn Other)
{
    //return;    
}

function NotifyMoveDone()
{
    //return;    
}

final function FireProj(Vector Start)
{
    local Vector X, Y, Z;

    // End:0x0D
    if(RangedProjectile == none)
    {
        return;
    }
    GetAxes(Rotation, X, Y, Z);
    Start = ((Location + ((X * Start.X) * CollisionRadius)) + ((Y * Start.Y) * CollisionRadius)) + ((Z * Start.Z) * CollisionHeight);
    // End:0x122
    if(!SavedFireProperties.bInitialized)
    {
        SavedFireProperties.AmmoClass = class'SkaarjAmmo';
        SavedFireProperties.ProjectileClass = RangedProjectile;
        SavedFireProperties.WarnTargetPct = 0.30;
        SavedFireProperties.MaxRange = 20000.0;
        SavedFireProperties.bTossed = RangedProjectile.default.Physics == 2;
        SavedFireProperties.bTrySplash = false;
        SavedFireProperties.bLeadTarget = true;
        SavedFireProperties.bInstantHit = false;
        SavedFireProperties.bInitialized = true;
    }
    UnresolvedNativeFunction_97(RangedProjectile,,, Start, AdjustAim(SavedFireProperties, Start, 5));
    //return;    
}

final function bool NeedToTurnFor(Vector targ)
{
    local int YawErr;

    YawErr = (rotator(targ - Location).Yaw - Rotation.Yaw) & 65535;
    return (YawErr > 8000) && YawErr < 57535;
    //return;    
}

function TakeDamage(int Damage, Pawn instigatedBy, Vector HitLocation, Vector Momentum, class<DamageType> DamageType, optional int HitIndex)
{
    // End:0x46
    if((class<DamTypeAlienSlash>(DamageType) == none) || class<DamTypeVomit>(DamageType) == none)
    {
        super.TakeDamage(Damage, instigatedBy, HitLocation, Momentum, DamageType, HitIndex);
    }
    //return;    
}

simulated function SpecialHideHead()
{
    local Coords boneCoords;
    local int i;

    // End:0x0B
    if(bHeadHasSplitted)
    {
        return;
    }
    bHeadHasSplitted = true;
    i = 0;
    J0x1A:
    // End:0x78 [Loop If]
    if(i < GibParts.Length)
    {
        // End:0x6E
        if((GibParts[i].Bone == 'neck') || GibParts[i].Bone == 'head')
        {
            ShatterGib(i);
            // [Explicit Break]
            goto J0x78;
        }
        ++ i;
        J0x78:
        // [Loop Continue]
        goto J0x1A;
    }
    boneCoords = GetBoneCoords('neck');
    AttachEmitterEffect(NeckSpurtNoGibEmitterClass, 'neck', boneCoords.Origin, rot(0, 0, 0));
    AttachToBone(SeveredHead, 'neck');
    //return;    
}

final simulated function ShatterGib(int Index)
{
    local SeveredAppendage G;

    // End:0x1A
    if(GibParts[Index].bHidden != 0)
    {
        return;
    }
    G = UnresolvedNativeFunction_97(class'SeveredHead',,, GetBoneCoords(GibParts[Index].Bone).Origin, GetBoneRotation(GibParts[Index].Bone));
    // End:0x68
    if(G == none)
    {
        return;
    }
    G.SetStaticMesh(GibParts[Index].Mesh);
    // End:0xC8
    if(GibParts[Index].Scale > float(0))
    {
        G.SetDrawScale(DrawScale * GibParts[Index].Scale);
    }
    // End:0xDC
    else
    {
        G.SetDrawScale(DrawScale);
    }
    // End:0x104
    if(FRand() < 0.50)
    {
        G.SetDrawScale3D(vect(1.0, -1.0, 1.0));
    }
    G.SpawnTrail();
    G.Velocity += ((Velocity * 1.20) + ((VRand() * Velocity) * 0.20));
    SetBoneScale(Index, 0.0, GibParts[Index].Bone);
    GibParts[Index].bHidden = 1;
    //return;    
}

function ProcessHitFX()
{
    //return;    
}

function DoDamageFX(name BoneName, int Damage, class<DamageType> DamageType, Rotator R)
{
    //return;    
}

simulated function PlayDying(class<DamageType> DamageType, Vector HitLoc)
{
    AmbientSound = none;
    bCanTeleport = false;
    bReplicateMovement = false;
    bTearOff = true;
    bPlayedDeath = true;
    StopBurnFX();
    // End:0x44
    if(CurrentCombo != none)
    {
        CurrentCombo.Destroy();
    }
    HitDamageType = DamageType;
    TakeHitLocation = HitLoc;
    bSTUNNED = false;
    bMovable = true;
    // End:0x92
    if((class<DamTypeBurned>(DamageType) != none) || class<DamTypeFlamethrower>(DamageType) != none)
    {
        ZombieCrispUp();
    }
    ProcessHitFX();
    // End:0x17B
    if(DamageType != none)
    {
        // End:0xD2
        if(DamageType.default.bSkeletize)
        {
            SetOverlayMaterial(DamageType.default.DamageOverlayMaterial, 4.0, true);
        }
        // End:0x17B
        else
        {
            // End:0x10C
            if(DamageType.default.DeathOverlayMaterial != none)
            {
                SetOverlayMaterial(DamageType.default.DeathOverlayMaterial, DamageType.default.DeathOverlayTime, true);
            }
            // End:0x17B
            else
            {
                // End:0x17B
                if(((DamageType.default.DamageOverlayMaterial != none) && Level.DetailMode != 0) && !Level.bDropDetail)
                {
                    SetOverlayMaterial(DamageType.default.DamageOverlayMaterial, 2.0 * DamageType.default.DamageOverlayTime, true);
                }
            }
        }
    }
    AnimBlendParams(1, 0.0);
    FireState = 0;
    LifeSpan = RagdollLifeSpan;
    GotoState('ZombieDying');
    PlayDyingAnimation(DamageType, HitLoc);
    //return;    
}

function AcidSplat()
{
    UnresolvedNativeFunction_97(class'AcidSplash', self);
    //return;    
}

simulated function PlayDyingAnimation(class<DamageType> DamageType, Vector HitLoc)
{
    local Vector shotDir, hitLocRel, deathAngVel, shotStrength;
    local float maxDim;
    local KarmaParamsSkel skelParams;
    local byte i;

    // End:0x17
    if(MyExtCollision != none)
    {
        MyExtCollision.Destroy();
    }
    // End:0x36
    if(Level.NetMode != NM_Client)
    {
        AcidSplat();
    }
    // End:0x6E
    if((Level.NetMode == NM_DedicatedServer) || bGibbed)
    {
        StopAnimating(true);
        LifeSpan = 0.250;
        return;
    }
    // End:0xAC
    if(GibParts.Length > 0)
    {
        i = byte(Rand(3));
        J0x86:
        // End:0xAC [Loop If]
        if(i < 3)
        {
            ShatterGib(Rand(GibParts.Length));
            ++ i;
            // [Loop Continue]
            goto J0x86;
        }
    }
    // End:0x65B
    if(Len(RagdollOverride) != 0)
    {
        // End:0xF7
        if((Level.NetMode != NM_ListenServer) && (Level.TimeSeconds - LastRenderTime) > float(3))
        {
            Destroy();
            return;
        }
        KMakeRagdollAvailable();
        // End:0x115
        if(!KIsRagdollAvailable())
        {
            LifeSpan = 0.10;
            return;
        }
        skelParams = KarmaParamsSkel(KParams);
        skelParams.KSkeleton = RagdollOverride;
        StopAnimating(true);
        // End:0x17B
        if(class'GameInfo'.static.UseLowGore() && NeckRot != rot(0, 0, 0))
        {
            SetBoneRotation('neck', NeckRot);
        }
        // End:0x1F9
        if(DamageType != none)
        {
            // End:0x1AB
            if(DamageType.default.bLeaveBodyEffect)
            {
                TearOffMomentum = vect(0.0, 0.0, 0.0);
            }
            // End:0x1F9
            if(DamageType.default.bKUseOwnDeathVel)
            {
                RagDeathVel = DamageType.default.KDeathVel;
                RagDeathUpKick = DamageType.default.KDeathUpKick;
                RagShootStrength = DamageType.default.KDamageImpulse;
            }
        }
        shotDir = Normal(GetTearOffMomemtum());
        shotStrength = RagDeathVel * shotDir;
        hitLocRel = TakeHitLocation - Location;
        // End:0x356
        if(DamageType.default.bLocationalHit)
        {
            hitLocRel.X *= RagSpinScale;
            hitLocRel.Y *= RagSpinScale;
            // End:0x2D9
            if(Abs(hitLocRel.X) > RagMaxSpinAmount)
            {
                // End:0x2B6
                if(hitLocRel.X < float(0))
                {
                    hitLocRel.X = FMax(hitLocRel.X * RagSpinScale, RagMaxSpinAmount * float(-1));
                }
                // End:0x2D9
                else
                {
                    hitLocRel.X = FMin(hitLocRel.X * RagSpinScale, RagMaxSpinAmount);
                }
            }
            // End:0x353
            if(Abs(hitLocRel.Y) > RagMaxSpinAmount)
            {
                // End:0x330
                if(hitLocRel.Y < float(0))
                {
                    hitLocRel.Y = FMax(hitLocRel.Y * RagSpinScale, RagMaxSpinAmount * float(-1));
                }
                // End:0x353
                else
                {
                    hitLocRel.Y = FMin(hitLocRel.Y * RagSpinScale, RagMaxSpinAmount);
                }
            }
        }
        // End:0x378
        else
        {
            hitLocRel.X *= RagSpinScale;
            hitLocRel.Y *= RagSpinScale;
        }
        // End:0x39C
        if(VSize(GetTearOffMomemtum()) < 0.010)
        {
            deathAngVel = VRand() * 18000.0;
        }
        // End:0x3B5
        else
        {
            deathAngVel = RagInvInertia * (hitLocRel Cross shotStrength);
        }
        // End:0x3E3
        if(DamageType.default.bRubbery)
        {
            skelParams.KStartLinVel = vect(0.0, 0.0, 0.0);
        }
        // End:0x414
        if(DamageType.default.bKUseTearOffMomentum)
        {
            skelParams.KStartLinVel = (GetTearOffMomemtum()) + Velocity;
        }
        // End:0x498
        else
        {
            skelParams.KStartLinVel.X = 0.60 * Velocity.X;
            skelParams.KStartLinVel.Y = 0.60 * Velocity.Y;
            skelParams.KStartLinVel.Z = 1.0 * Velocity.Z;
            skelParams.KStartLinVel += shotStrength;
        }
        // End:0x4F4
        if((!DamageType.default.bLeaveBodyEffect && !DamageType.default.bRubbery) && Velocity.Z > float(-10))
        {
            skelParams.KStartLinVel.Z += RagDeathUpKick;
        }
        // End:0x538
        if(DamageType.default.bRubbery)
        {
            Velocity = vect(0.0, 0.0, 0.0);
            skelParams.KStartAngVel = vect(0.0, 0.0, 0.0);
        }
        // End:0x5C0
        else
        {
            skelParams.KStartAngVel = deathAngVel;
            maxDim = float(Max(int(CollisionRadius), int(CollisionHeight)));
            skelParams.KShotStart = TakeHitLocation - (float(1) * shotDir);
            skelParams.KShotEnd = TakeHitLocation + ((float(2) * maxDim) * shotDir);
            skelParams.KShotStrength = RagShootStrength;
        }
        // End:0x604
        if((DamageType != none) && DamageType.default.bCauseConvulsions)
        {
            RagConvulseMaterial = DamageType.default.DamageOverlayMaterial;
            skelParams.bKDoConvulsions = true;
        }
        KSetBlockKarma(true);
        SetPhysics(14);
        skelParams.bRubbery = DamageType.default.bRubbery;
        bRubbery = DamageType.default.bRubbery;
        skelParams.KActorGravScale = RagGravScale;
        return;
    }
    Velocity += (GetTearOffMomemtum());
    BaseEyeHeight = default.BaseEyeHeight;
    SetTwistLook(0, 0);
    SetInvisibility(0.0);
    PlayDirectionalDeath(HitLoc);
    SetPhysics(2);
    //return;    
}

simulated function PlayDirectionalDeath(Vector HitLoc)
{
    UnresolvedNativeFunction_97(DeathAnimations[Rand(DeathAnimations.Length)], 1.0 + FRand(), 0.050);
    //return;    
}

simulated function SpawnGibs(Rotator HitRotation, float ChunkPerterbation)
{
    local int i;

    bGibbed = true;
    PlayDyingSound();
    // End:0x22
    if(class'GameInfo'.static.UseLowGore())
    {
        return;
    }
    // End:0x54
    if(FlamingFXs != none)
    {
        FlamingFXs.Emitters[0].SkeletalMeshActor = none;
        FlamingFXs.Destroy();
    }
    // End:0x73
    if(ObliteratedEffectClass != none)
    {
        UnresolvedNativeFunction_97(ObliteratedEffectClass,,, Location, HitRotation);
    }
    super(xPawn).SpawnGibs(HitRotation, ChunkPerterbation);
    i = 0;
    J0x8A:
    // End:0xAF [Loop If]
    if(i < GibParts.Length)
    {
        ShatterGib(i);
        ++ i;
        // [Loop Continue]
        goto J0x8A;
    }
    //return;    
}

function DoorAttack(Actor A)
{
    // End:0x20
    if(bShotAnim || Physics == 3)
    {
        return;
    }
    // End:0x56
    else
    {
        // End:0x56
        if(A != none)
        {
            bShotAnim = true;
            SetAnimAction(MeleeAnims[Rand(3)]);
            Acceleration = vect(0.0, 0.0, 0.0);
        }
    }
    //return;    
}

simulated event KImpact(Actor Other, Vector pos, Vector impactVel, Vector impactNorm)
{
    local Vector WallHit, WallNormal;
    local Actor WallActor;
    local float RagHitVolume;

    // End:0xE6
    if((((LastStreakLocation == vect(0.0, 0.0, 0.0)) || VSizeSquared(LastStreakLocation - pos) < 1400.0) && Level.TimeSeconds > LastStreakTime) && !class'GameInfo'.static.UseLowGore())
    {
        LastStreakLocation = pos;
        WallActor = Trace(WallHit, WallNormal, pos - (impactNorm * float(16)), pos + (impactNorm * float(16)), false);
        // End:0xE6
        if(WallActor != none)
        {
            UnresolvedNativeFunction_97(class'AlienBloodDecal',,, WallHit, rotator(-WallNormal));
            LastStreakTime = Level.TimeSeconds + BloodStreakInterval;
        }
    }
    // End:0x160
    if((RagImpactSounds.Length > 0) && Level.TimeSeconds > (RagLastSoundTime + RagImpactSoundInterval))
    {
        RagHitVolume = FMin(2.0, VSizeSquared(impactVel) / float(40000));
        UnresolvedNativeFunction_97(RagImpactSounds[Rand(RagImpactSounds.Length)], 0, RagHitVolume);
        RagLastSoundTime = Level.TimeSeconds;
    }
    //return;    
}

defaultproperties
{
    CurrentDamType=class'DamTypeAlienSlash'
    ExpectingChannel=-1
    ProjectileBloodSplatClass=none
    ObliteratedEffectClass=Class'KFMod.BileExplosion'
    GibGroupClass=class'GibGroupAlien'
    ControllerClass=class'LairMonstersV1.LairAliensController'
    DodgeAnims[0]=Jump
    DodgeAnims[1]=Jump
    DodgeAnims[2]=Jump
    DodgeAnims[3]=Jump
    bAlwaysRelevant=true
}
