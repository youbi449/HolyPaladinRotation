local _, addonTable = ...;

--- @type MaxDps
if not MaxDps then
    return
end
local Paladin = addonTable.Paladin;
local MaxDps = MaxDps;
local UnitPower = UnitPower;
local HolyPower = Enum.PowerType.HolyPower;
local HL = {
    -- Spell
    BeaconOfLight = 53563,
    HolyShock = 20473,
    BestowFaith = 223306,
    HolyLight = 82326,
    WordOfGlory = 85673,
    FlashLight = 19750,
    LightOfTheMartyr = 183998,
    LightOfDawn = 85222,
    BlessingOfSacrifice = 199448,
    AurasMastery = 31821,
    DivineProtection = 498,
    AurasDevotion = 465,
    Longanimite = 25771,
    Longanimite2 = 465,
    DivineShield = 642,
    BlessingOfProtection = 1022,
    -- Talents
    LightsHammer = 114158,
    HolyAvenger = 105809,
    Seraphim = 152262,
    AvengingCrusader = 216331,
    DivinePurpose = 223817,
    GlimmerofLight = 325966,
    --
    -- Kyrian
    DivineToll = 304971,
    --
    -- Venthyr
    AshenHallow = 316958,
    --
    -- NightFae
    BlessingoftheSeasons = 328278,
    BlessingofSpring = 328282,
    BlessingofSummer = 328620,
    BlessingofAutumn = 328622,
    BlessingofWinter = 328281,
    --
    -- Necrolord
    VanquishersHammer = 328204
    --
};

local CN = {
    None = 0,
    Kyrian = 1,
    Venthyr = 2,
    NightFae = 3,
    Necrolord = 4
};

setmetatable(HL, Paladin.spellMeta);
function AoeHeal(limit, number)
    local aoe = 0
    if math.floor((UnitHealth("player") / UnitHealthMax("player")) * 100) <= limit then
        aoe = aoe + 1
    end
    for i = 1, 4 do
        local healthPercent = math.floor((UnitHealth("party" .. i) / UnitHealthMax("party" .. i)) * 100)
        if not UnitIsDead("party" .. i) then
            if UnitInRange("party" .. i) then
                if healthPercent <= limit then
                    aoe = aoe + 1
                end
            end
        end
    end
    if aoe >= number then
        return true
    else
        return false
    end
end

function Buff(buff, unit)
    for i = 1, 40 do
        name, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer, nameplateShowAll, timeMod =
            UnitBuff(unit, i)
        if spellId == buff then
            return true
        end
    end
    return false
end

function checkIfGroupMemberHaveBeaconOfLight()
    beaconIsLaunched = false
    if IsInGroup() then
        if (GetNumGroupMembers() > 5) then
            -- raid
            for i = 1, 40 do
                if (Buff(HL.BeaconOfLight, 'raid' .. i)) then
                    beaconIsLaunched = true
                end
            end
        else
            -- party
            for i = 1, 4 do
                if (Buff(HL.BeaconOfLight, 'party' .. i)) then
                    beaconIsLaunched = true
                end
            end
        end
    end
    return beaconIsLaunched

end

function targetIsMe()
    local targetName = UnitName('target')
    local selfName = UnitName('player')
    if targetName == selfName then
        return true
    else
        return false
    end
end
function correctHealingSpell(spell, minPercent, unit)
    local cooldown = fd.cooldown;
    local selfHealth = UnitHealth('player');
    local selfHealthMax = UnitHealthMax('player');
    local selfHealthPercent = (selfHealth / selfHealthMax) * 100;
    local health = UnitHealth('target');
    local healthMax = UnitHealthMax('target');
    local healthPercent = (health / healthMax) * 100;
    if IsSpellKnown(spell) and not UnitIsDead(unit) and cooldown[spell].ready then
        if unit == 'player' then
            if selfHealthPercent <= minPercent then
                return true
            end
        elseif unit == 'target' then
            if healthPercent <= minPercent then
                return true
            end
        end
    else
        return false
    end
end
function Paladin:Holy()
    fd = MaxDps.FrameData;
    covenantId = fd.covenant.covenantId;
    targets = MaxDps:SmartAoe();
    cooldown = fd.cooldown;
    buff = fd.buff;
    debuff = fd.debuff;
    talents = fd.talents;
    targets = fd.targets;
    gcd = fd.gcd;
    targetHp = MaxDps:TargetPercentHealth() * 100;
    selfHealth = UnitHealth('player');
    selfHealthMax = UnitHealthMax('player');
    selfHealthPercent = (selfHealth / selfHealthMax) * 100;
    health = UnitHealth('target');
    healthMax = UnitHealthMax('target');
    healthPercent = (health / healthMax) * 100;
    currentSpeed = tonumber(string.format("%d", (GetUnitSpeed("player") / 7) * 100))
    MaxDps:GlowEssences();
    currentSpell = fd.currentSpell;
    local HolyPower = Enum.PowerType.HolyPower;
    holyPower = UnitPower('player', HolyPower);
    fd.holyPower = holyPower;

    if correctHealingSpell(HL.AurasMastery, 40, 'player') and Buff(HL.AurasDevotion, 'player') then
        return HL.AurasMastery
    end
    if correctHealingSpell(HL.DivineProtection, 40, 'player') then
        return HL.DivineProtection
    end

    if AoeHeal(70, 3) and holyPower >= 3 then
        return HL.LightOfDawn
    end
    if UnitCanAttack('target', 'player') or not UnitExists('target') or targetIsMe() then
        return Paladin:selfHeal()
    else
        return Paladin:TargetHeal()
    end

end

function Paladin:selfHeal()

    if selfHealthPercent <= 20 and not Buff(HL.Longanimite, 'player')  then
        return HL.DivineShield
    end
    if correctHealingSpell(HL.BlessingOfProtection, 40, 'player') and not Buff(HL.Longanimite, 'player') and UnitGroupRolesAssigned('player') ~= 'TANK' then
        return HL.BlessingOfProtection
    end

    if holyPower >= 3 and correctHealingSpell(HL.WordOfGlory, 80, 'player') then
        return HL.WordOfGlory
    end
    if cooldown[HL.HolyShock].ready and correctHealingSpell(HL.HolyShock, 80, 'player') then
        return HL.HolyShock
    end
    if correctHealingSpell(HL.FlashLight, 55, 'player') then
        return HL.FlashLight
    end
    if talents[HL.BestowFaith] and correctHealingSpell(HL.BestowFaith, 65, 'player') then
        return HL.BestowFaith
    end
    if correctHealingSpell(HL.HolyLight, 85, 'player') then
        return HL.HolyLight
    end

    return
end

function Paladin:TargetHeal()
    
    if not checkIfGroupMemberHaveBeaconOfLight() and IsInGroup() and
        correctHealingSpell(HL.BeaconOfLight, 100, 'player') then
        return HL.BeaconOfLight
    end

    if correctHealingSpell(HL.BlessingOfProtection, 40, 'target') and not Buff(HL.Longanimite, 'target') and UnitGroupRolesAssigned('target') ~= 'TANK' then
        return HL.BlessingOfProtection
    end

    if correctHealingSpell(HL.BlessingOfSacrifice, 45, 'target') then
        return HL.BlessingOfSacrifice
    end
    if holyPower >= 3 and correctHealingSpell(HL.WordOfGlory, 80, 'target') then
        return HL.WordOfGlory
    end
    if correctHealingSpell(HL.HolyShock, 85, 'target') then
        return HL.HolyShock
    end
    if currentSpeed > 0 and correctHealingSpell(HL.LightOfTheMartyr, 55, 'target') then
        return HL.LightOfTheMartyr
    end
    if correctHealingSpell(HL.FlashLight, 55, 'target') then
        return HL.FlashLight
    end
    if talents[HL.BestowFaith] and correctHealingSpell(HL.BestowFaith, 65, 'target') then
        return HL.BestowFaith
    end
    if correctHealingSpell(HL.HolyLight, 85, 'target') then
        return HL.HolyLight
    end
    return
end

function Paladin:SelfDefense()

end

function Paladin:AoeHeal()

end
