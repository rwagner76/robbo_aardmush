function exceptionReport(name,line,wildcards)
   local area = wildcards[1]
   Note("Area report for "..area..":")
   local mobkeys = sortKeys(querytoArray(toolboxdb,string.format("SELECT key from mobs where zone='%s';",area)))
   local mobexceptions = checkMobExceptions(mobkeys,toolboxdb)
   local objkeys = sortKeys(querytoArray(toolboxdb,string.format("SELECT key from objects where zone='%s';",area)))
   local objexceptions = checkObjExceptions(objkeys,toolboxdb)
   local roomkeys = sortKeys(querytoArray(toolboxdb,string.format("SELECT key from rooms where zone='%s';",area)))
   local roomexceptions = checkRoomExceptions(roomkeys,toolboxdb)
   Note("Overall area checks:")
   local areaexceptions = checkAreaExceptions(area,mobkeys,objkeys,roomkeys,toolboxdb)
end

function checkMobExceptions(keys,db)
   local mobExceptions = {}
   totalmobresets = 0
   mobsHighGmx = 0
   guildTotals = {}
   perMobGmx = {}
   for i,key in ipairs(keys) do
      local mobex = {}
      local mobt = querytoTable(toolboxdb,string.format("SELECT * from mobs where key='%s';",key))
      local mobs = querytoTable(toolboxdb,string.format("SELECT * from mobstats where key='%s';",key))
      local rawt = querytoTable(toolboxdb,string.format("SELECT name,roomname FROM rawstrings WHERE key='%s' AND type='mob';",key))
      local rstt = querytoTable(db,string.format("SELECT key AS room,num,gamemax from resets WHERE loadkey='%s' and type='mob' ORDER BY key;",key))
      local ptable = querytoTable(db,string.format("SELECT * from mobpoints where level='%s';",mobt[1].level))
      -- Checks
      if mobt[1].shop == "yes" then
         table.insert(mobex,"\tNote: mob is a shopkeeper")
      end
      tableConcat(mobex,checkMobStrings(mobt[1],rawt[1]))
      tableConcat(mobex,checkMobRace(mobt[1]))
      tableConcat(mobex,checkMobFlags(mobt[1]))
      tableConcat(mobex,checkKeywords(mobt[1]))
      tableConcat(mobex,checkMobResets(key,rstt))
      if #ptable == 0 then DebugNote("Couldn't get points table for level "..mobt[1].level.." for mob "..key) end
      tableConcat(mobex,checkMobGold(key,mobt[1],ptable[1]))
      tableConcat(mobex,checkMobGuild(mobt[1]))

      -- Collate Results
      if #mobex > 0 then
         Note("Exceptions for mob: "..key)
         writeArraytoNote(mobex)
      end
      table.insert(mobExceptions,mobex)
   end
   return mobExceptions
end

function checkObjExceptions(keys,db)
   local objectExceptions = {}
   objQuality = {Masterpiece = 0, Max = 0, Good = 0, Mediocre = 0, ['Negative/No Stats'] = 0}
   for i,key in ipairs(keys) do
      local objex = {}
      local objt = querytoTable(db,string.format("SELECT * from objects where key='%s';",key))
      local oaff = querytoTable(db,string.format("SELECT * from oaffects where key='%s';",key))
      local mres = querytoTable(db,string.format("SELECT * from maxresists where level='%s';",objt[1].level))
      local rawt = querytoTable(db,string.format("SELECT name,roomname FROM rawstrings WHERE key='%s' AND type='object';",key))
      --DebugNote("Checking object "..key)
      -- Checks
      tableConcat(objex,checkObjStrings(objt[1],rawt[1]))
      tableConcat(objex,checkKeywords(objt[1]))
      if objt[1].type ~= "None" and objt[1].type ~= "Fountain" and objt[1].type ~= "Raw material" then
         tableConcat(objex,checkObjWeightVal(objt[1],key,toolboxdb))
         tableConcat(objex,checkWearable(objt[1]))
      else
         table.insert(objex,"\tObject does not have a type set.")
      end
      if objt[1].type == 'Raw material' then
         table.insert(objex,"\tNote: Object is of type 'Raw material', this requires Lasher's approval.")
      end
      
      if objt[1].type == 'Weapon' then
         local wdata = querytoTable(db,string.format("SELECT * from weapons where key='%s';",key))
         tableConcat(objex,checkWDice(objt[1],wdata[1]))
      end
      tableConcat(objex,checkObjResists(objt[1],oaff,mres[1]))
      local points = calcObjPoints(objt[1],oaff)
      if objt[1].type == "Armor" or objt[1].type == "Light" or objt[1].type == "Weapon" then
         --DebugNote("Calculated points for "..key..": "..points['total'])
         local ptable = querytoTable(db,string.format("SELECT * from objpoints where level='%s';",objt[1].level))
         tableConcat(objex,checkObjPoints(objt[1],ptable[1],points))
      end
      if objt[1].type ~= "Armor" and objt[1].type ~= "Light" and objt[1].type ~= "Weapon" and points.total ~= 0 then
         table.insert(objex,"\tObject is not armor, light, or weapon and has stat affects assigned.")
      end

      -- Collate Results
      if #objex > 0 then
         Note("Exceptions for object: "..key)
         writeArraytoNote(objex)
      end
      table.insert(objectExceptions,objex)
   end
   return objectExceptions
end

function checkRoomExceptions(keys,db)
   local roomExceptions = {}
   --DebugNote("Total keys: "..#keys)
   --DebugNote(serialize.save_simple(keys))
   for _,key in ipairs(keys) do
      --Note("Checking room "..key)
      local roomex = {}
      local roomt = querytoTable(db,string.format("SELECT * from rooms where key='%s';",key))
      local rawt = querytoTable(db,string.format("SELECT name FROM rawstrings WHERE key='%s' AND type='room';",key))
      -- Checks
      tableConcat(roomex,checkRoomStrings(roomt[1],rawt[1]))
      tableConcat(roomex,checkRoomRates(roomt[1]))
      tableConcat(roomex,checkRoomFlags(roomt[1]))
      -- Collate Results
      if #roomex > 0 then
         Note("Exceptions for room: "..key)
         writeArraytoNote(roomex)
      end
      table.insert(roomExceptions,roomex)
   end
   return roomExceptions
end

function checkAreaExceptions(area,mobkeys,objectkeys,roomkeys,db)
   local areaex = {}
   -- Rooms
   tableConcat(areaex,checkAreaRoomFlags(area,roomkeys,db))
   tableConcat(areaex,checkAreaRoomRates(area,roomkeys,db))

   -- Mobs
   tableConcat(areaex,checkMobResetTotals(area,roomkeys,db))
   tableConcat(areaex,checkAreaMobFlags(area,db))
   if mobsHighGmx > 3 then
      table.insert(areaex,"Area has more than 3 mobs with 8 or more resets:")
      for k,v in pairs(perMobGmx) do
         if v >= 8 then
            table.insert(areaex,"\t"..k)
         end
      end
   end
   local animals = countQuery(db,string.format("SELECT count(*) AS count FROM mobs WHERE zone='%s' AND flags like '%s';",area,"%animal%"))
   if animals > 0 then
      if math.floor(animals/#mobkeys * 100) > 33 then
         table.insert(areaex,"More than 1/3 of mobs in the zone have the animal flag.")
      end
   end
   tableConcat(areaex,checkAreaGuilds(mobkeys))
   -- Objects
   tableConcat(areaex,checkAreaResists(area,db))
   table.insert(areaex,"--------------------------------------------------------------------------------------------------")
   table.insert(areaex,"Object Quality Summary Totals:")
   table.insert(areaex,"\tMasterpiece**    : "..objQuality['Masterpiece'])
   table.insert(areaex,"\tMax              : "..objQuality['Max'])
   table.insert(areaex,"\tGood             : "..objQuality['Good'])
   table.insert(areaex,"\tMediocre         : "..objQuality['Mediocre'])
   table.insert(areaex,"\tNegative/No Stats: "..objQuality['Mediocre'])
   table.insert(areaex,"Please review the masterpiece/max/other item rules for object quality.")
   table.insert(areaex,"\t** - Any items over stats in any category is marked as masterpiece, this may not be intentional.")
   table.insert(areaex,"--------------------------------------------------------------------------------------------------")
   -- Collate results
   if #areaex > 0 then
      writeArraytoNote(areaex)
   end

   return areaex
end



function checkMobStrings(mobt,rawt)
   local ex = {}
   if mobt.name == nil then
      table.insert(ex,"\tName is blank.")
   end
   if mobt.story == nil then
      table.insert(ex,"\tStory is blank.")
   elseif string.len(mobt.story) > 80 then
      table.insert(ex,"\tStory is longer than 80 characters.")
   end
   if mobt.desc == nil then
      table.insert(ex,"\tDescription is blank.")
   elseif countMatches(mobt.desc,"\\n") < 3 then
      table.insert(ex,"\tDescription is less than 4 lines.")
   end
   if rawt == nil then
      table.insert(ex,"\tRaw strings haven't been collected. Run 'mstatall strings'.")
      return ex
   end
   if rawt.name == nil then
      table.insert(ex,"\tRaw strings haven't been collected. Run 'mstatall strings'.")
   elseif string.len(rawt.name) > 50 then
      table.insert(ex,"\tName is longer than 50 characters.")
      if countMatches(rawt.name,'@') > 0 then
         table.insert(ex,"\tName contains color codes. (not allowed for mobs)")
      end
   end
   if rawt.roomname == nil then
      table.insert(ex,"\tRoom Name is blank.")
   elseif string.len(rawt.roomname) > 80 then
      table.insert(ex,"\tRoom Name is longer than 80 characters.")
      if countMatches(rawt.roomname,'@') > 0 then
         table.insert(ex,"\tRoom Name contains color codes. (not allowed for mobs)")
      end
   end
   return ex
end

function checkKeywords(t)
   local ex = {}
   if t.keywords == nil then
      table.insert(ex,"\tKeywords are unknown or blank.")
      return ex
   end
   local keywords = split(t.keywords,' ')
   local nmatch = false
   local rnmatch = 0
   if t.name ~= nil then
      for i,kw in ipairs(keywords) do
         if countMatches(t.name,kw) > 0 then nmatch = true end
      end
   end
   if t.roomname ~= nil then
      for i,kw in ipairs(keywords) do
         if countMatches(t.roomname,kw) > 0 then rnmatch = true end
      end
   end
   
   if not nmatch then
      table.insert(ex,"\tNone of the keywords are found in name field.")
   end
   if not rnmatch then
      table.insert(ex,"\tNone of the keywords are found in roomname field.")
   end

   return ex
end

function checkMobRace(mobt)
   local ex = {}
   local badraces = {'school monst', 'cguard', 'fido', 'generic'}
   if mobt.race == nil then
      table.insert(ex,"\tMob race is blank.")
   elseif table.contains(badraces,mobt.race) then
      table.insert(ex,"\tMob race "..mobt.race.." is not allowed for areas.")
   elseif mobt.race == 'unique' then
      table.insert(ex,"\tWarning: Mob race unique requires head builder to set stats.")
   end
   return ex
end

function checkMobFlags(mobt)
   local ex = {}
      if mobt.flags == nil then
         table.insert(ex,"\tMob does not have any flags set!")
      elseif countMatches(mobt.flags,'confined') == 0 then
         table.insert(ex,"\tMob does not have the confined flag.")
      end
   return ex
end

function checkMobGold(key,mobt,ptable)
   local ex = {}
   if ptable == nil then
      --DebugNote("ptable for mob ".. key .." is null.")
      return ex
   end
   if mobt.gold == nil then
      table.insert(ex,"\tMob gold is unknown/blank!")
   else
      if perMobGmx[key] == nil then perMobGmx[key] = 0 end
      local multiplier = 1
      if perMobGmx[key] > 1 then
         multiplier = 1 - (perMobGmx[key] - 1) / 10
         if multiplier < 0.5 then multiplier = 0.5 end
         --DebugNote('Mob '..key..' has '..perMobGmx[key]..' total resets. Adjusting gold to '..multiplier..' of maximum: '..maxgold)
      end
      local maxgold = multiplier * ptable.gold
      if mobt.gold > maxgold then
         table.insert(ex,"\tMob has "..perMobGmx[key].." possible resets. Gold "..mobt.gold.." is higher than max allowed: "..maxgold.." (multiplier "..multiplier..")")
      end
   end
   return ex
end

function checkMobGuild(mobt)
   local ex = {}
   local animal = false
   local undead = false
   if mobt.flags ~= nil then
      if countMatches(mobt.flags,"animal") > 0 then animal = true end
      if countMatches(mobt.flags,"undead") > 0 then undead = true end
   end
   if mobt.guilds == nil and animal == false and undead == false then
      table.insert(ex,"\tMob does not have a guild set (and is not undead/animal).")
   end
   if mobt.guilds ~= nil then
      if countMatches(mobt.guilds,",") > 0 then   
         table.insert(ex,"\tMob has multiple guilds set. Only one is allowed.")
      else
         if guildTotals[mobt.guilds] == nil then guildTotals[mobt.guilds] = 0 end
         guildTotals[mobt.guilds] = guildTotals[mobt.guilds] + 1
      end
   end
   return ex
end


function checkMobResets(key,rt)
   local ex = {}
   if rt == nil then return ex end
   if #rt == 0 then return ex end
   local gmx = rt[1].gamemax
   local inroomresets = {}
   local dumprt = false
   local room = ''
   local roomcount = 0
   for i,t in ipairs(rt) do
      if t.gamemax ~= gmx then
         table.insert(ex,"\tMob has different 'max in-game' values for different resets/rooms.")
         dumprt = true
      end
      if t.gamemax > gmx then gmx = t.gamemax end
      if t.room ~= room then roomcount = roomcount + 1 end
   end
   if gmx > #rt then
      table.insert(ex,"\tWarning: Mob has a higher in-game max than total resets. (extra copies may repop later)")
      if gmx < 10 then dumprt = true end
   end
   if gmx < #rt then
      table.insert(ex,"\tWarning: Mob has a higher number of resets than in-game max! (not all copies may load)")
      if gmx < 10 then dumprt = true end
   end
   if gmx > 7 and roomcount < 3 then
      table.insert(ex,"\tMob has 8 or more resets in less than 3 rooms.")
   end
   if gmx > 8 then
      table.insert(ex,"\tMob has in-game max (resets) greater than 8!")
   end
   if gmx >= 8 then
      mobsHighGmx = mobsHighGmx + 1
   end

   perMobGmx[key] = gmx
   if dumprt then table.insert(ex,serialize.save_simple(rt)) end
   --DebugNote("Max in game for mob "..key.." is: "..gmx..". Total resets found: "..#rt)
   totalmobresets = totalmobresets + gmx
   return ex
end
--- Object Checks ---

function checkObjStrings(objt,rawt)
   local ex = {}
   if objt.name == nil then
      table.insert(ex,"\tName is blank.")
   end
   if rawt == nil then
      table.insert(ex,"\tRaw strings haven't been collected. Run 'ostatall strings'.")
      return ex
   end

   if rawt.name == nil then
      table.insert(ex,"\tRaw strings haven't been collected. Run 'ostatall strings'.")
   elseif string.len(rawt.name) > 50 then
      table.insert(ex,"\tName is longer than 50 characters.")
   end
   if rawt.roomname == nil then
      table.insert(ex,"\tRoom Name is blank.")
   elseif string.len(rawt.roomname) > 80 then
      table.insert(ex,"\tRoom Name is longer than 80 characters.")
   end
   return ex
end

function objMaxInGame(key,db)
   local max = 0
   local mobsWithItem = querytoTable(db,string.format("select DISTINCT resets.gamemax from resets LEFT JOIN subresets ON resets.key = subresets.key AND resets.num = subresets.parent WHERE subresets.type='equip' and subresets.loadkey like '%s' ORDER BY resets.gamemax;",key))
   for i,r in pairs(mobsWithItem) do
      max = max + r.gamemax
   end
   return max
end

function objCountinShop(key,db)
   local max = 0
   local mobsWithItem = querytoTable(db,string.format("select DISTINCT resets.gamemax from resets LEFT JOIN subresets ON resets.key = subresets.key AND resets.num = subresets.parent WHERE subresets.type='give' and subresets.loadkey like '%s' ORDER BY resets.gamemax;",key))
   for i,r in pairs(mobsWithItem) do
      max = max + r.gamemax
   end
   return max
end

function checkObjWeightVal(objt,key,db)
   local ex = {}
   local minw,maxw,maxv = objcost(objt.level,objt.type)
   if maxw < 1 then maxw = 1 end
   if minw < 1 then minw = 1 end
   
   if objt.weight == nil then
      table.insert(ex,"\tObject weight is unknown/blank!")
   else
      if objt.weight > maxw then table.insert(ex,"\tObject is over maximum weight for type "..objt.type..". (set to ".. objt.weight ..", max is "..maxw..").") end
      if objt.weight < minw then table.insert(ex,"\tObject is below minimum weight for type "..objt.type..". (set to ".. objt.weight ..", min is "..minw..").") end
   end
   if objt.value == nil then
      table.insert(ex,"\tObject value is unknown/blank!")
   else
      local maxload = objMaxInGame(key,db)
      local maxshop = objCountinShop(key,db)
      if debug_mode == "on" then
         --table.insert(ex,"Total possible object resets (equip): "..maxload)
         --table.insert(ex,"Total possible object resets (shop) : "..maxshop)
      end
      local multiplier = 1
      if maxload > 1 then
         multiplier = 1 - (maxload - 1) / 10
         if multiplier < 0 then multiplier = 0 end
      end
      maxv = math.floor(maxv * multiplier)
      if objt.value > maxv then
         table.insert(ex,"\t"..objt.type.." is over maximum value. Max with "..maxload.." possible resets is "..maxv..", currently set to "..objt.value..".")
      end
   end
   return ex
end

function checkWearable(objt)
   local ex = {}
   if objt.wearable ~= nil then
      if countMatches(objt.wearable,",") > 0 then
         table.insert(ex,"\tObject has multiple wear locations set! This is not typical ("..objt.wearable..").")
         return ex
      end
      if objt.type == 'Weapon' and objt.wearable ~= 'wield' and objt.wearable ~= 'ready' then
         table.insert(ex,"\tObject is a weapon, but wearable location is not wield or ready ("..objt.wearable..").")
         return ex
      end
      if objt.type == 'Light' and objt.wearable ~= 'light' then
         table.insert(ex,"\tObject is a light, but wearable location is not set to light ("..objt.wearable..").")
         return ex
      end
      if objt.type == 'Treasure' then
         table.insert(ex,"\tWarning: Object is type treasure and has a wearable location set ("..objt.wearable..").")
         return ex
      end
      if objt.wearable == 'above' or objt.wearable == 'portal' then
         table.insert(ex,"\tWarning: Object is set to "..objt.wearable.." wear location. This is not allowed.")
      end
      if objt.type ~= 'Armor' and objt.type ~= 'Weapon' and objt.type ~= 'Light' and objt.wearable ~= 'hold' then
         table.insert(ex,"\tObject is not armor, weapon, or light but has a wear location other than hold set ("..objt.wearable..").")
         return ex
      end
   end
   if (objt.type == 'Armor' or objt.type == 'Weapon') and objt.wearable == nil then
      table.insert(ex,"\tObject is armor, but has no wear location set.")
   end
   return ex
end

function checkObjFlags(objt)
   local ex = {}
   if objt.flags == nil and objt.type ~= 'Trash' then
      table.insert(ex,"\tObject is not of type trash, so likely should have the magic flag.")
   elseif countMatches(objt.flags,"magic") == 0 and objt.type ~= 'Trash' then
      table.insert(ex,"\tObject is not of type trash, so likely should have the magic flag.")
   end
   return ex
end

function checkWDice(objt,wdata)
   local ex = {}
   local wdice = querytoTable(toolboxdb,string.format("SELECT avg from wdice where level='%s';",objt.level))
   if wdice[1] == nil then
      table.insert(ex,"\tObject is weapon, but wdice for this object is not defined. Level is "..objt.level)
      return ex
   end
   if wdata.avgdam == nil then
       table.insert(ex,"\tObject is weapon, but average damage is unknown/blank!")
   elseif wdata.avgdam > wdice[1].avg then
       table.insert(ex,"\tWeapon average damage (".. wdata.avgdam..") is higher than wdice table values for this level (".. wdice[1].avg ..").")
   end
   return ex
end

function calcObjPoints(objt,oaff)
   local fullpt = {"strength", "dexterity", "intelligence", "constitution", "wisdom", "luck"}
   local halfpt = {"hit roll", "damage roll"}
   local tenthpt = {"hit point", "mana", "moves"}
   local stats = 0
   local saves = 0
   local hrdr = 0
   local hpmnmv = 0
   local negall = 0
   
   for _,a in ipairs(oaff) do
      if table.contains(fullpt,a.affects) then
         stats = stats + a.adjust
         if a.adjust < 0 then negall = negall - a.adjust end
      elseif table.contains(halfpt,a.affects) then
         hrdr = hrdr + (a.adjust/2)
         if a.adjust < 0 then negall = negall - (a.adjust/2) end
      elseif table.contains(tenthpt,a.affects) then
         hpmnmv = hpmnmv + (a.adjust/10)
         if a.adjust < 0 then negall = negall - (a.adjust/10) end
      end
   end
   local total = stats + hrdr + hpmnmv
   local p = {total = total,stats = stats,saves = saves,hrdr = hrdr,hpmnmv = hpmnmv,negall = negall}
   return p
end

function checkObjPoints(objt,ptable,points)
   local ex = {}
   local isdual = false
   if objt.wearable ~= nil then
      -- We'll have already gotten a warning about the lack of wearable location for armor
      isdual = isDual(objt.wearable)
   end
   local tpts,stats,hrdr,hp,negall
   if isdual then
      tpnts,stats,hrdr,hp,negall = ptable.dpnts,ptable.dstat,ptable.dhrdr,ptable.dhp,ptable.dnegall
   else
      tpnts,stats,hrdr,hp,negall = ptable.spnts,ptable.sstat,ptable.shrdr,ptable.shp,ptable.snegall
   end

   if points.total > tpnts then
      table.insert(ex,"\tObject total points ("..points.total..") is over maximum allowed ("..tpnts..").")
   end
   if points.stats > stats then
      table.insert(ex,"\tObject points from stats ("..points.stats..") is over maximum allowed ("..stats..").")
   end
   if points.hrdr > hrdr then
      table.insert(ex,"\tObject points from HR/DR ("..points.hrdr..") is over maximum allowed ("..hrdr..").")
   end
   if points.hpmnmv > hp then
      table.insert(ex,"\tObject points from hp/mana/moves ("..points.hpmnmv..") is over maximum allowed ("..hp..").")
   end
   if points.negall > negall then
      table.insert(ex,"\tObject negative points ("..points.negall..") is over maximum allowed ("..negall..").")
   end
   
   --DebugNote('Total points: '..points.total..'/'..tpnts..' max.')
   if points.total > tpnts or points.stats > stats or points.hrdr > hrdr or points.hpmnmv > hp then objQuality['Masterpiece'] = objQuality['Masterpiece'] + 1
      elseif points.total == tpnts then objQuality['Max'] = objQuality['Max'] + 1
      elseif points.total > tpnts/2 then objQuality['Good'] = objQuality['Good'] + 1
      elseif points.total > 0 then objQuality['Mediocre'] = objQuality['Mediocre'] + 1
      else objQuality['Negative/No Stats'] = objQuality['Negative/No Stats'] + 1
   end
   return ex
end

function checkObjResists(objt,oaff,mres)
   local ex = {}
   if oaff == nil then return ex end
   if #oaff == 0 then return ex end
   local rcounter = 0
   for i,a in ipairs(oaff) do
      if a.type == 'resist' and a.affects ~= "allmagic" and a.affects ~= "allphysical" then
         rcounter = rcounter + a.adjust
      elseif a.type == 'resist' and a.affects == "allmagic" and objt.type ~= "Armor" then
         table.insert(ex,"\tObject is not of type armor and has added allmagic resists.")
      elseif a.type == 'resist' and a.affects == "allphysical" and objt.type ~= "Armor" then
         table.insert(ex,"\tObject is not of type armor and has added allphysical resists.")
      end
      if a.type == 'resist' and a.affects == "allmagic" then
         if mres == nil then
            table.insert(ex,"\tFailed to get object max resists allmagic for level "..objt.level)
         else
            if a.adjust > mres.allmagic then
               table.insert(ex,"\tObject has higher than the allowed allmagic resist type. ("..a.adjust.." vs max "..mres.allmagic..")")
            end
         end
      end
      if a.type == 'resist' and a.affects == "allphysical" then
         if mres == nil then
            table.insert(ex,"\tFailed to get object max resists allphysical for level "..objt.level)
         else
            if a.adjust > mres.allphys then
               table.insert(ex,"\tObject has higher than the allowed allphysical resist type. ("..a.adjust.." vs max "..mres.allphys..")")
            end
         end
      end
   end
   
   if rcounter > 0 then
      table.insert(ex,"\tObject has added positive resists with not enough negative resists to match. This is normally not allowed.")
   end
   return ex

end


-- Room checks

function checkRoomStrings(roomt,rawt)
   local ex = {}
   if roomt.name == nil then
      table.insert(ex,"\tName is blank.")
   end
   if roomt.desc == nil then
      table.insert(ex,"\tDescription is blank.")
   elseif countMatches(roomt.desc,"\\n") < 3 then
      table.insert(ex,"\tDescription is less than 4 lines.")
   end
   if rawt == nil then
      table.insert(ex,"\tRaw strings haven't been collected. Run 'rstatall strings'.")
      return ex
   end

   if rawt.name == nil then
      table.insert(ex,"\tRaw strings haven't been collected. Run 'rstatall strings'.")
   elseif string.len(rawt.name) > 50 then
      table.insert(ex,"\tName is longer than 50 characters.")
      if countMatches(rawt.name,'@') > 0 then
         table.insert(ex,"\tName contains color codes. (not allowed for mobs)")
      end
   end
   return ex
end

function checkRoomRates(roomt)
   local ex = {}
   if roomt.manarate == nil then
      table.insert(ex,"\tMana Rate is blank/unknown.")
   elseif roomt.healrate == nil then
      table.insert(ex,"\tHeal Rate is blank/unknown.")
   else
      if roomt.healrate > 120 or roomt.healrate < -120 then
         table.insert(ex,"\tHeal Rate is outside the allowed range (-120 to 120). Value is:"..roomt.healrate)
      end
      if roomt.manarate > 120 or roomt.manarate < -120 then
         table.insert(ex,"\tMana Rate is outside the allowed range (-120 to 120). Value is:"..roomt.manarate)
      end
   end
   return ex
end

function checkRoomFlags(roomt)
   local ex = {}
   if roomt.flags == nil then return ex end
   local badflags = {'combatmaze','donate','clanroom','bank','jail','helperonly','fidobranch','leadersonly','vault','clanmaze','nomagic'}
   local permflags = {'silentspell','noquaff'}
   for i,v in ipairs(badflags) do
      if countMatches(roomt.flags,v) > 0 then
         table.insert(ex,"\tRoom has the '"..v.."', which is not allowed.")
      end
   end
   for i,v in ipairs(permflags) do
      if countMatches(roomt.flags,v) > 0 then
         table.insert(ex,"\tWarning: Room has the '"..v.."', which requires head builder approval.")
      end
   end
   if countMatches(roomt.flags,"pk") > 0 and countMatches(roomt.flags,"safe") > 0 then
      table.insert(ex,"Room has both the 'pk' and 'safe' flags. This should never be set together.")
   end
   return ex
end


-- Area checks
function checkMobResetTotals(area,roomkeys,db)
   local ex = {}
   local avgmoblevel = querytoArray(db,string.format("SELECT AVG(level) from mobs WHERE zone='%s';",area))
   DebugNote("Total mobs: "..totalmobresets.." divided by total rooms: "..#roomkeys.." is "..totalmobresets/#roomkeys.." per room.")
   if avgmoblevel[1] >= 201 and totalmobresets/#roomkeys > 4 then
      table.insert(ex,"For SH area, total mob resets should be 4 per room or less. Counted: "..totalmobresets/#roomkeys.." per room.")
   elseif avgmoblevel[1] < 201 and totalmobresets/#roomkeys > 3 then
      table.insert(ex,"For non-SH area, total mob resets should be 3 per room or less. Counted: "..totalmobresets/#roomkeys.." per room.")
   end
   return ex
end

function checkAreaRoomRates(area,roomkeys,db)
   local ex = {}
   local totalrooms = #roomkeys
   local exhealrooms = countQuery(db,string.format("SELECT count(*) AS count FROM rooms WHERE zone='%s' AND (healrate < 80 OR healrate > 110);",area))
   local exmanarooms = countQuery(db,string.format("SELECT count(*) AS count FROM rooms WHERE zone='%s' AND (manarate < 80 OR manarate > 110);",area))
   --DebugNote("Rooms with exceptions for heal rate: "..exhealrooms)
   --DebugNote("Rooms with exceptions for mana rate: "..exmanarooms)
   if exhealrooms > 0 and exhealrooms/totalrooms > .2 then
      table.insert(ex,"Rooms with heal rates less than 80 or over 110 is over 20%. Total rooms: "..totalrooms.." exception rooms: "..exhealrooms)
   end
   if exmanarooms > 0 and exmanarooms/totalrooms > .2 then
      table.insert(ex,"Rooms with mana rates less than 80 or over 110 is over 20%. Total rooms: "..totalrooms.." exception rooms: "..exmanarooms)
   end
   return ex
end

function checkAreaRoomFlags(area,roomkeys,db)
   local ex = {}
   local totalrooms = #roomkeys
   local pkrooms = countQuery(db,string.format("SELECT count(*) AS count FROM rooms WHERE zone='%s' AND flags like '%s';",area,"%pk%"))
   --DebugNote("Total PK Rooms: "..pkrooms)
   if pkrooms > 0 and pkrooms/totalrooms > .2 then
      table.insert(ex,"PK room percentage is over 20%. Total rooms: "..totalrooms.." PK rooms: "..pkrooms)
   end
   local nohungerrooms = countQuery(db,string.format("SELECT count(*) AS count FROM rooms WHERE zone='%s' AND flags like '%s';",area,"nohunger"))
   if nohungerrooms > 1 then
      table.insert(ex,"Rooms with nohunger found: "..nohungerrooms..". These should be used sparingly or not at all.")
   end
   return ex
end

function checkAreaMobFlags(area,db)
   local ex = {}
   local cflags = {'areaattacks','assistalign','assistpcs','assistself','assistmobs','assistrace'}
   for i,flag in ipairs(cflags) do
      local c = countQuery(db,string.format("SELECT count(*) AS count FROM mobs WHERE zone='%s' AND flags like '%s';",area,"%"..flag.."%"))
      if c > 2 then
         table.insert(ex,c.." uses of the mob flag "..flag.." used. This should be used very sparingly.")
      end
   end
   return ex
end

function checkAreaGuilds(mobkeys)
   local ex = {}
   for guild,count in pairs(guildTotals) do
      --DebugNote("Percentage of guild "..guild.." in area is: "..(count/#mobkeys * 100))
      if (count/#mobkeys * 100) > 50 then
         table.insert(ex,"More than 1/2 of the mobs in the area are of guild: "..guild)
      end
   end
   return ex
end

function checkAreaResists(area,db)
   local ex = {}
   local q = string.format("select key,affects,adjust,COUNT(*) AS count from oaffects where key like '%s' AND type='resist' and affects!='allmagic' and affects!='allphysical' AND adjust > 0 GROUP BY affects HAVING COUNT(*)>1",area.."-%")
   local t = querytoTable(db,q)
   if #t > 0 then
      table.insert(ex,"\tMultiple objects have added resists for the same resist type. This is not permitted. Check these objects:")
      for i,r in ipairs(t) do
         table.insert(ex,"\t\t"..r.key)
      end
   end
   return ex
end
      
