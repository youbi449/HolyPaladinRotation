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

    if AoeHeal(70, 3) and holyPower >= 3 then
        return HL.LightOfDawn
    end
    if UnitCanAttack('target', 'player') or not UnitExists('target') then
        return Paladin:selfHeal()
    else
        return Paladin:TargetHeal()
    end

end

function Paladin:selfHeal()
    
    if holyPower >= 3 and selfHealthPercent <= 50 then
        return HL.WordOfGlory
    end
    if healthPercent <= 55 then
        return HL.FlashLight
    end
    if cooldown[HL.BestowFaith].ready and talents[HL.BestowFaith] and selfHealthPercent <= 65 then
        return HL.BestowFaith
    end
    if selfHealthPercent <= 70 then
        return HL.HolyLight
    end
    if cooldown[HL.HolyShock].ready and selfHealthPercent < 80 then
        return HL.HolyShock
    end

end

function Paladin:TargetHeal()
    
    if not checkIfGroupMemberHaveBeaconOfLight() and IsInGroup() then
        return HL.BeaconOfLight
    end
    if cooldown[HL.BlessingOfSacrifice].ready and healthPercent <= 45 then
        return HL.BlessingOfSacrifice
    end
    if holyPower >= 3 and healthPercent <= 50 then
        return HL.WordOfGlory
    end

    if currentSpeed > 0 and healthPercent <= 55 then
        return
    end
    if healthPercent <= 55 then
        return HL.FlashLight
    end
    if cooldown[HL.BestowFaith].ready and talents[HL.BestowFaith] and healthPercent <= 65 then
        return HL.BestowFaith
    end
    if healthPercent <= 70 then
        return HL.HolyLight
    end
    if cooldown[HL.HolyShock].ready and healthPercent < 80 then
        return HL.HolyShock
    end

end
