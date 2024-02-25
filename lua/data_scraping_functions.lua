-- mpdump Captures
function mpDumpStart(name,line,wildcards)
   EnableTrigger("trg_mpDumpStart",false)
   EnableTrigger("trg_mpDumpMiddle",true)
   EnableTrigger("trg_mpDumpEnd",true)
   mpdump[progracurKey] = {}
   table.insert(mpdump[progracurKey], line)
end

function mpDumpMiddle(name,line,wildcards)
   table.insert(mpdump[progracurKey], line)
end

function mpDumpEnd(name,line,wildcards)
   table.insert(mpdump[progracurKey], line)
   EnableTrigger("trg_mpDumpMiddle",false)
   EnableTrigger("trg_mpDumpEnd",false)
end


-- xedit Captures
function meditInGame(name,line,wildcards)
   mt[curKey]['ingame'] = wildcards[1]
end

function meditA(name, line, wildcards)
   mt[curKey]['keywords'] = wildcards[1]
end

function meditB(name, line, wildcards)
   mt[curKey]['name'] = wildcards[1]
end

function meditD(name, line, wildcards)
   mt[curKey]['roomname'] = wildcards[1]
end

function meditF(name, line, wildcards)
   mt[curKey]['story'] = wildcards[1]
end

function meditG(name, line, wildcards)
   EnableTrigger("trg_meditG",false)
   if wildcards[1] == "Description is set." then
      Send("g")
      Send(".q")
   end
end

function meditHJ(name, line, wildcards)
   mt[curKey]['level'] = wildcards[1]
   mt[curKey]['alignment'] = wildcards[2]
end

function meditIK(name, line, wildcards)
   mt[curKey]['gold'] = wildcards[1]
   mt[curKey]['sex'] = wildcards[2]
end

function meditLM(name, line, wildcards)
   mt[curKey]['race'] = wildcards[1]
   mt[curKey]['position'] = wildcards[2]
end

function meditN(name, line, wildcards)
   mt[curKey]['guilds'] = wildcards[1]
end

function meditO(name, line, wildcards)
   mt[curKey]['subclass'] = wildcards[1]
end

function meditR(name, line, wildcards)
   mt[curKey]['flags'] = wildcards[1]
   if string.sub(mt[curKey]['flags'],-1) == ',' then
      EnableTrigger("trg_meditR_add",true)
   end
end

function meditRAdd(name, line, wildcards)
   mt[curKey]['flags'] = mt[curKey]['flags'].." "..wildcards[1]
   EnableTrigger("trg_meditR_add",false)
end

function meditS(name, line, wildcards)
   mt[curKey]['affects'] = wildcards[1]
   if string.sub(mt[curKey]['affects'],-1) == ',' then
      EnableTrigger("trg_meditS_add",true)
   end
end

function meditSAdd(name, line, wildcards)
   mt[curKey]['affects'] = mt[curKey]['affects'].." "..wildcards[1]
   EnableTrigger("trg_meditS_add",false)
end

function meditT(name, line, wildcards)
   mt[curKey]['immune'] = wildcards[1]
end

function meditW(name, line, wildcards)
   i,j = string.find(wildcards[1],' ')
   mt[curKey]['mprogs'] = string.sub(wildcards[1],1,(i-1))
end

function meditX(name, line, wildcards)
   local shop = 'yes'
   if string.find(wildcards[1],"not") then shop = 'no' end
   mt[curKey]['shop'] = shop
   EnableTrigger("trg_meditX",false)
   Send("Q")
end

function meditStatsA(name, line, wildcards)
   mt[curKey][string.lower(wildcards[1])] = wildcards[2]
   mt[curKey][string.lower(wildcards[3])] = wildcards[4]
   mt[curKey][string.lower(wildcards[5])] = wildcards[6]
end

function meditStatsBD(name, line, wildcards)
   mt[curKey]['hitroll'] = wildcards[1]
   mt[curKey]['saves'] = wildcards[2]
end

function meditStatsCE(name, line, wildcards)
   mt[curKey]['damroll'] = wildcards[1]
   mt[curKey]['extrahits'] = wildcards[2]
end

function meditStatsF(name, line, wildcards)
   mt[curKey]['damtype'] = wildcards[1]
end

function meditStatsG(name, line, wildcards)
   mt[curKey]['spellset'] = wildcards[1]
end

function meditStatsV(name, line, wildcards)
   local mverb = wildcards[1]
   if mverb == "None Set" then mverb = wildcards[2].." (default)" end
   mt[curKey]['mverb'] = mverb
end

function meditStatsResists(name, line, wildcards)
   mt[curKey]['resists'] = wildcards[1]
end

function meditStatsIJK(name, line, wildcards)
   mt[curKey]['dammax'] = wildcards[1]
   mt[curKey]['damavg'] = wildcards[2]
   mt[curKey]['dammin'] = wildcards[3]
end

function meditStatsLMN(name, line, wildcards)
   mt[curKey]['hpmax'] = wildcards[1]
   mt[curKey]['hpavg'] = wildcards[2]
   mt[curKey]['hpmin'] = wildcards[3]
end

function meditStatsO(name, line, wildcards)
   mt[curKey]['hpbonus'] = wildcards[1]
end

function meditStatsPRS(name, line, wildcards)
   mt[curKey]['manamax'] = wildcards[1]
   mt[curKey]['manaavg'] = wildcards[2]
   mt[curKey]['manamin'] = wildcards[3]

end

function meditStatsT(name, line, wildcards)
   mt[curKey]['manabonus'] = wildcards[1]
end

function meditDescStart(name, line, wildcards)
   mt[curKey]['desc'] = ""
   EnableTrigger("trg_meditDescMiddle",true)
   EnableTrigger("trg_meditDescEnd",true)
end

function meditDescMiddle(name, line, wildcards)
   EnableTrigger("trg_meditDescStart",false)
   if wildcards[1] ~= "==========================================================================" then
      if mt[curKey]['desc'] == "" then
         mt[curKey]['desc'] = wildcards[1]
      else
         mt[curKey]['desc'] = mt[curKey]['desc'].."\\n"..wildcards[1]
      end
   end
end

function meditDescEnd(name,line,wildcards)
   EnableTrigger("trg_meditDescMiddle",false)
   EnableTrigger("trg_meditDescEnd",false)
end

function oeditAffectValues(name,line,wildcards)
   if oaff[curKey][string.lower(wildcards[1])] == nil then
      oaff[curKey][string.lower(wildcards[1])] = {}
   end
   oaff[curKey][string.lower(wildcards[1])][string.lower(wildcards[2])] = wildcards[3]
end

function oeditAffectFlag(name,line,wildcards)
   if oaff[curKey]['flag'] == nil then
      oaff[curKey]['flag'] = {}
   end
   oaff[curKey]['flag'][wildcards[1]] = "on"
end


function oeditA(name, line, wildcards)
   ot[curKey]['keywords'] = wildcards[1]
end

function oeditB(name, line, wildcards)
   ot[curKey]['name'] = wildcards[1]
end

function oeditD(name, line, wildcards)
   ot[curKey]['roomname'] = wildcards[1]
end

function oeditF(name, line, wildcards)
   ot[curKey]['type'] = wildcards[1]
end

function oeditHI(name, line, wildcards)
   ot[curKey]['level'] = wildcards[1]
   ot[curKey]['value'] = wildcards[2]
end

function oeditJK(name, line, wildcards)
   ot[curKey]['weight'] = wildcards[1]
   ot[curKey]['size'] = wildcards[2]
end

function oeditL(name, line, wildcards)
   ot[curKey]['material'] = wildcards[1]
end

function oeditM(name, line, wildcards)
   ot[curKey]['flags'] = wildcards[1]
   if string.sub(ot[curKey]['flags'],-1) == ',' then
      EnableTrigger("trg_oeditM_add",true)
   end
end

function oeditMAdd(name, line, wildcards)
   ot[curKey]['flags'] = ot[curKey]['flags'].." "..wildcards[1]
   EnableTrigger("trg_oeditM_add",false)
end

function oeditN(name, line, wildcards)
   ot[curKey]['wearable'] = wildcards[1]
end

function oeditO(name, line, wildcards)
   ot[curKey]['descs'] = wildcards[1]
end

function oeditP(name, line, wildcards)
   ot[curKey]['affects'] = wildcards[1]
   EnableTrigger("trg_oeditP",false)
   Send("P")
   Send("Q")
end

function oeditR(name,line,wildcards)
   EnableTrigger("trg_oeditR",false)
   Send("R")
   Send("Q")
end

function oeditS(name, line, wildcards)
   -- Last line, let's decide if we need to do more, but don't run us more than once.
   ot[curKey]['objprogs'] = wildcards[1]
   EnableTrigger("trg_oeditS",false)
   Send("Q")
end

function oeditWeaponA(name, line, wildcards)
   ot[curKey]['wtype'] = wildcards[1]
end

function oeditWeaponB(name, line, wildcards)
   ot[curKey]['damtype'] = wildcards[1]
end

function oeditWeaponD(name, line, wildcards)
   ot[curKey]['avgdam'] = wildcards[1]
end

function oeditWeaponF(name, line, wildcards)
   ot[curKey]['specials'] = wildcards[1]
end

function oeditWeaponG(name, line, wildcards)
   ot[curKey]['dverb'] = wildcards[1]
end


function oeditAffectStart()
   EnableTrigger("trg_oeditAffectValues",true)
   EnableTrigger("trg_oeditAffectFlag",true)
   if oaff[curKey] == nil then oaff[curKey] = {} end
end

function oeditAffectEnd()
   EnableTrigger("trg_oeditAffectValues",false)
   EnableTrigger("trg_oeditAffectFlag",false)
end

function captureRawKeywords(name,line,wildcards)
   -- Don't really need this one
end

function captureRawName(name,line,wildcards)
   raws[curKey]['rawname'] = wildcards[1]
end

function captureRawRoomName(name,line,wildcards)
   raws[curKey]['rawroomname'] = wildcards[1]
end


function oeditContainersA(name,line,wildcards)
   ot[curKey]['capacity'] = wildcards[1]
end

function oeditContainersB(name,line,wildcards)
   ot[curKey]['maxitem'] = wildcards[1]
end

function oeditContainersC(name,line,wildcards)
   ot[curKey]['multiplier'] = wildcards[1]
end

function oeditContainersD(name,line,wildcards)
   ot[curKey]['keyobject'] = wildcards[1]
end

function oeditContainersE(name,line,wildcards)
   ot[curKey]['containerflags'] = wildcards[1]
end

function oeditMagicA(name,line,wildcards)
   ot[curKey]['spelllevel'] = wildcards[1]
   if ot[curKey]['type'] ~= 'Wand' then
      ot[curKey]['uses'] = '1'
   end
end

function oeditMagicB(name,line,wildcards)
   ot[curKey]['uses'] = wildcards[1]
end

function oeditMagicSpells(name,line,wildcards)
   if ot[curKey]['spells'] == nil then
      ot[curKey]['spells'] = {}
   end
   if wildcards[1] ~= 'None' then
      table.insert(ot[curKey]['spells'],wildcards[1])
   end
end


function oeditFoodA(name,line,wildcards)
   ot[curKey]['foodname'] = wildcards[1]
end

function oeditFoodB(name,line,wildcards)
   ot[curKey]['foodsize'] = wildcards[1]
end

function oeditFoodC(name,line,wildcards)
   ot[curKey]['drinksize'] = wildcards[1]
end

function oeditFoodD(name,line,wildcards)
   ot[curKey]['proof'] = wildcards[1]
end

function oeditFoodE(name,line,wildcards)
   ot[curKey]['totalsize'] = wildcards[1]
end

function oeditFoodF(name,line,wildcards)
   ot[curKey]['startsize'] = wildcards[1]
end

function oeditFoodG(name,line,wildcards)
   ot[curKey]['foodflags'] = wildcards[1]
end

function reditA(name,line,wildcards)
   rt[curKey]['name'] = wildcards[1]
end

function reditB(name,line,wildcards)
   EnableTrigger("trg_reditB",false)
   Send("B")
   Send(".q")
end
function reditC(name,line,wildcards)
   rt[curKey]['sector'] = wildcards[1]
   rt[curKey]['sectorflags'] = wildcards[2]
end

function reditDF(name,line,wildcards)
   rt[curKey]['healrate'] = wildcards[1]
   rt[curKey]['minlevel'] = wildcards[2]
end

function reditEG(name,line,wildcards)
   rt[curKey]['manarate'] = wildcards[1]
   rt[curKey]['maxlevel'] = wildcards[2]
end

function reditJT(name,line,wildcards)
   rt[curKey]['brightness'] = wildcards[1]
   rt[curKey]['color'] = wildcards[2]
end

function reditKU(name,line,wildcards)
   rt[curKey]['maxchars'] = wildcards[1]
   rt[curKey]['gmcpcolor'] = wildcards[2]
end

function reditM(name,line,wildcards)
   rt[curKey]['flags'] = wildcards[1]
end

function reditN(name,line,wildcards)
   EnableTrigger("trg_reditN",false)
   rt[curKey]['resetcount'] = wildcards[1]
   if tonumber(wildcards[1]) > 0 then
      Send("N")
      Send("Q")
   end
end

function reditExitCounts(name,line,wildcards)
   if wildcards[2] == "standard " then
      rt[curKey]['stdexits'] = wildcards[1]
   elseif wildcards[2] == "custom " then
      rt[curKey]['cexits'] = wildcards[1]
   elseif wildcards[2] == "map" then
      rt[curKey]['mapexits'] = wildcards[1]
   end
end

function reditR(name,line,wildcards)
   rt[curKey]['desccount'] = wildcards[1]
end

function reditS(name,line,wildcards)
   rt[curKey]['rprogs'] = wildcards[1]
   EnableTrigger("trg_reditS",false)
   Send("Q")
   Send("")
end

function reditSave(name,line,wildcards)
   Send("N")
   Send("")
end

function reditDescStart(name, line, wildcards)
   rt[curKey]['desc'] = ""
   EnableTrigger("trg_reditDescMiddle",true)
   EnableTrigger("trg_reditDescEnd",true)
end

function reditDescMiddle(name, line, wildcards)
   EnableTrigger("trg_reditDescStart",false)
   if wildcards[1] ~= "==========================================================================" then
      if rt[curKey]['desc'] == "" then
         rt[curKey]['desc'] = wildcards[1]
      else
         rt[curKey]['desc'] = rt[curKey]['desc'].."\\n"..wildcards[1]
      end
   end
end

function reditDescEnd(name,line,wildcards)
   EnableTrigger("trg_reditDescMiddle",false)
   EnableTrigger("trg_reditDescEnd",false)
end

function reditTopResets(name,line,wildcards)
   if rt[curKey]['resets'] == nil then rt[curKey]['resets'] = {} end
   local t = {}
   if #wildcards == 3 then
      t = {num = wildcards[1], type = wildcards[2], key = wildcards[3]}
   else
      t = {num = wildcards[1], type = wildcards[2], key = wildcards[3], gamemax = wildcards[4], roommax = wildcards[5]}
   end
   
   table.insert(rt[curKey]['resets'],t)
   topreset = wildcards[1]
end

function reditSubReset(name,line,wildcards)
   local type = string.lower(wildcards[1])
   local chance = 5000
   if rt[curKey]['subresets'] == nil then rt[curKey]['subresets'] = {} end
   if wildcards[4] ~= nil then chance = wildcards[4] end
   
   local t = {}
   if type == 'give' then
      t = {parent = topreset, type = type, key = wildcards[2]}
   elseif type == 'equip' then
      t = {parent = topreset, type = type, key = wildcards[2], wearloc = wildcards[3], chance = chance}
   end
   
   table.insert(rt[curKey]['subresets'],t)
end