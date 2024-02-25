
debug_mode = "on"

curKey = ""
xlist = {}
xstat = {}
executingAction = "none"
mt = {}
rt = {}
ot = {}
raws = {}
oaff = {}
goidx = {}

-- For area reports
totalmobresets = 0
perMobGmx = {}
mobsHighGmx = 0
guildTotals = {}
objQuality = {}

-- Used for scraping sub-resets
topreset = ''

-- For refreshing data in buildstuff mob/objpoints and help wdice
local mobpoints = {}
local objpoints = {}
local wdice = {}

-- Check and prep database
local dbfile = GetInfo(60).."robbo_aardmush\\db\\areadata.db"
local schema_version = 1

toolboxdb = sqlite3.open(dbfile)

-- Main execution

function OnPluginInstall()
   db_prep(dbfile,schema_version)
end

function OnPluginClose()
   toolboxdb:close_vm()
   toolboxdb:close()
end


function OnHelp()
   local help = [[

                      Test Port Toolbox Help
=============================================================================
 ggo                       --> Alias for rgoto that increments the room vnum
                               you're in. Starts at 'rgoto 0'. (Guinness Go!)
 ggo reset                 --> Sets ggo back to the first room in rlist.
 gmgo                      --> Alias for mgoto that increments the mob vnum
                               you're in. Starts at 'mgoto area-0'. (Guinness Go!)
 gmgo reset                --> Sets ggo back to the first mob in the area.
 mstatall/rstatall/ostatall--> Dumps mstat for each key in 'keyword' area,
                               Required to do area reports. Automatically
                               exports a copy to a file when done.
 meditall/reditall/oeditall--> Dumps edit data for each room in 'keyword'
                               area. Required to do area reports.  Saves
                               data to a database, as well as saving a
                               file at the end.
 mpdumpall # [#]           --> Does mpdump of all programs 0 to N.
                               Uses rawcolor mode and noline.
 gcancel                   --> Cancels any capture operation in process.
 toolbox help              --> Show this help file

]]

  print(help)
end

function printSerialize(name,line,wildcards)
   -- Pass what to serialize and an ID.
   local type = wildcards[1]
   local key = getGMCPZone().."-"..wildcards[2]
   if type == "obj" then
      if ot[key] == nil then return end
      Note(serialize.save_simple(ot[key]))
   elseif type == "oaff" then
      if oaff[key] == nil then return end
      Note(serialize.save_simple(oaff[key]))
   elseif  type == "mob" then
      if mt[key] == nil then return end
      Note(serialize.save_simple(mt[key]))
   elseif type == "raws" then
      Note(serialize.save_simple(raws))
   elseif type == "room" then
      Note(serialize.save_simple(rt[key]))
   end
   
end

function rewriteMpdumpHeader(name,line,wildcards)
   local mpkey = wildcards[1]
   WriteLog("Dumping mobprog: "..mpkey)
   Note("Dumping mobprog: "..mpkey)
end

function ggoNext(name,line,wildcards)
   local area = getGMCPZone()
   local needsinit = false
   local action = wildcards['action']
   local index = goidx[action]
   if #xlist[action] == 0 then
      needsinit = true
   else
      local lastarea = select(2,splitkey(xlist[action][1]))
      if lastarea ~= area then
         Note("You're in a different area than your last "..action..". If this is okay, you'll want to '"..action.." reset' now.")
         return
      end
   end
   if wildcards['param'] == 'reset' then needsinit = true end
   if xlist[action][index] == nil then needsinit = true end
   if ggoIndex == nil then ggoIndex = 1 end
   if needsinit then
      executingAction = 'ggo'
      Execute("rlist")
   else
      Send("rgoto "..xlist[action][index])
      index = index + 1
      if index > #xlist['ggo'] then index = 1 end
      goidx[action] = index
   end
end

function cancelAction(name,line,wildcards)
   executingAction = "none"
   clearTempTimers()
end

function initMobPoints(name,line,wildcards)
   mobpoints = {}
   EnableTrigger("trg_mobpoints",true)
   Send("buildstuff mobpoints")
   Send("echo -- END MOBPOINTS --")
end

function initWDice(name,line,wildcards)
   wdice = {}
   EnableTrigger("trg_wdice1",true)
   EnableTrigger("trg_wdice2",true)
   local helpwin = IsPluginInstalled("a1965272c8ca966b76f36fa3")
   if helpwin then
      EnablePlugin("a1965272c8ca966b76f36fa3",false)
   end
   Send("help wdice")
   if helpwin then
      DoAfterSpecial(1,'EnablePlugin("a1965272c8ca966b76f36fa3",true)',sendto.script)
      DoAfterSpecial(1.1,'echo -- END WDICE --',sendto.execute)
   end
end

function captureWDice(name,line,wildcards)
   local query = string.format("INSERT OR REPLACE INTO wdice(level,min,max,avg) VALUES(%s,%s,%s,%s);",wildcards[1],wildcards[2],wildcards[3],wildcards[4])
   table.insert(wdice,query)
   if #wildcards == 8 then
      query = string.format("INSERT OR REPLACE INTO wdice(level,min,max,avg) VALUES(%s,%s,%s,%s);",wildcards[5],wildcards[6],wildcards[7],wildcards[8])
      table.insert(wdice,query)
   end
end

function endWDice()
   DebugNote("Saving weapon dice...")
   EnableTrigger("trg_wdice1",false)
   EnableTrigger("trg_wdice2",false)
   execute_in_transaction(toolboxdb,wdice)
end


function captureMobPoints(name,line,wildcards)
   local query = string.format("INSERT OR REPLACE INTO mobpoints(level,hpmin,hpavg,hpmax,hpadd,dmmin,dmavg,dmmax,dr,hr,gold) VALUES(%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s);",wildcards[1],wildcards[2],wildcards[3],wildcards[4],wildcards[5],wildcards[6],wildcards[7],wildcards[8],wildcards[9],wildcards[10],wildcards[11])
   table.insert(mobpoints,query)
end

function endMobPoints()
   EnableTrigger("trg_mobpoints",false)
   execute_in_transaction(toolboxdb,mobpoints)
end

function initObjPoints(name,line,wildcards)
   objpoints = {}
   EnableTrigger("trg_objpoints",true)
   Send("buildstuff objpoints")
   Send("echo -- END OBJPOINTS --")
end

function captureObjPoints(name,line,wildcards)
   local query = string.format("INSERT OR REPLACE INTO objpoints(level,spnts,sstat,ssvs,shrdr,shp,snegall,dpnts,dstat,dsvs,dhrdr,dhp,dnegall) VALUES(%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s);",wildcards[1],wildcards[2],wildcards[3],wildcards[4],wildcards[5],wildcards[6],wildcards[7],wildcards[8],wildcards[9],wildcards[10],wildcards[11],wildcards[12],wildcards[13])
   table.insert(objpoints,query)
end

function endObjPoints()
   EnableTrigger("trg_objpoints",true)
   execute_in_transaction(toolboxdb,objpoints)
end


function mpdumpAll(name,line,wildcards)
   if  GetOption("enable_timers") == 0 then
      Note("Warning: Timers are currently disabled. Cannot execute.")
      return
   end
   local area = getGMCPZone()
   if area == nil then Note("Set your area keyword with 'garea keyword' first!") return end
   local command = line:sub(1,1).."statcap "
   local ext = ".txt"
   --local f = io.output ('worlds\plugins\robbo_aardmush\exports\'..line:sub(1,1).."mpdump_"..type.."_"..getPort()..ext)
   local min = 0
   local max = 0
   if #wildcards == 1 then
      max = tonumber(wildcards[1])
   else
      min = tonumber(wildcards[1])
      max = tonumber(wildcards[2])
   end
   local delay = 1
   for i = min,max do
      local key = area.."-"..tostring(i)
      DoAfterSpecial(delay,"mpdump noline "..key,sendto.execute)
      DoAfterSpecial((delay+0.1),"echo -- end program --",sendto.execute)
      delay = delay + 1
   end
end

-- Xlist and control loops for captures
function xlistExecute(name, line, wildcards)
   local type=wildcards['type']
   if executingAction ~= "none" then
      xlist[executingAction] = {}
      EnableTrigger("trg_captureListKeys",true)
      EnableTrigger("trg_endListKeys",true)
   end
   Send(type.."list")
end

function addListKey(name, line, wildcards)
   Note("adding key: "..wildcards[1])
   table.insert(xlist[executingAction],wildcards[1])
end

function endListkeys(name, line, wildcards)
   local area = getGMCPZone()
   EnableTrigger("trg_captureListKeys",false)
   EnableTrigger("trg_endListKeys",false)
   DebugNote("Toolbox: Captured "..table.getn(xlist[executingAction]).." keys for action: "..executingAction)

   if executingAction == "ggo" then Execute("ggo")
   elseif executingAction == "gmgo" then Execute("gmgo")
   else captureLoop(xlist[executingAction])
   end
end

function captureLoop(kt)
   local interval = 1.8
   local delay = interval
   local command
   local type = string.sub(executingAction,1,1)
   if string.sub(executingAction,2,8) == 'editAll' then
      command = type .."editcap "
   elseif string.sub(executingAction,2,8) == 'statStr' then
      command = type .."statstr "
   elseif string.sub(executingAction,2,8) == 'statCap' then
      command = type .."statcap "
   end
   for i,key in ipairs(kt) do
      DoAfterSpecial(delay,"echo -- START CAPTURE --",sendto.execute)
      delay = delay + .1
      DoAfterSpecial(delay,command..key,sendto.execute)
      if string.sub(executingAction,2,8) ~= 'editAll' then
         -- Edit commands have secondary triggers, will trigger on return to game.
         delay = delay + .1
         DoAfterSpecial(delay,"echo -- END CAPTURE --",sendto.execute)
      end
      delay = delay + interval
   end
   delay = delay + 1
   DoAfterSpecial(delay,"echo -- END ALL CAPTURE COMMANDS --",sendto.execute)
end

function captureStart(name,line,wildcards)
   DebugNote("Starting capture type "..executingAction)
   EnableTriggerGroup("tgrp_endCaptures",true)
   if string.sub(executingAction,2,8) == 'statCap' then
      EnableTrigger("trg_captureXstatLines",true)
   elseif string.sub(executingAction,2,8) == 'statStr' then
      EnableTriggerGroup("tgrp_statStrings",true)
   elseif executingAction == 'oeditAll' then
      EnableTriggerGroup("oeditCaptures",true)
   elseif executingAction == 'meditAll' then
      EnableTriggerGroup("meditCaptures",true)
      EnableTriggerGroup("meditStatCaptures",true)
      EnableTrigger("trg_meditDesc",true)
   elseif executingAction == 'reditAll' then
      EnableTriggerGroup("reditCaptures",true)
   end
end

function captureEnd(name,line,wildcards)
   EnableTriggerGroup("tgrp_endCaptures",false)
   if executingAction == 'none' then return end
   DebugNote("Capture completed for action "..executingAction.." for key "..curKey)
   EnableTrigger("trg_captureXstatLines",false)
   EnableTriggerGroup("tgrp_statStrings",false)
   EnableTrigger("trg_meditDesc",false)
   EnableTriggerGroup("meditCaptures",false)
   EnableTriggerGroup("meditStatCaptures",false)
   EnableTriggerGroup("oeditCaptures",false)
   EnableTriggerGroup("reditCaptures",false)
   EnableTriggerGroup("tgrp_statStrings",false)
   if string.sub(executingAction,2,8) == 'statStr' then
      writeRawstoDB(curKey,raws[curKey],toolboxdb,executingAction)
   end
   if executingAction == 'oeditAll' then
      writeObjecttoDB(curKey,ot[curKey],oaff[curKey],toolboxdb)
   end
   if executingAction == 'meditAll' then
      writeMobtoDB(curKey,mt[curKey],toolboxdb)
   end
   if executingAction == 'reditAll' then
      writeRoomtoDB(curKey,rt[curKey],toolboxdb)
   end

end


function captureLoopEnd(name, line, wildcards)
   -- End of all caputures done
   DebugNote("Completed "..executingAction)
   if string.sub(executingAction,2,8) == 'statCap' then
      exportXstatToFile()
   end
   if string.sub(executingAction,2,8) == 'editAll' then
      exportxEditToFile()
   end
end

function captureStatLines(name,line,wildcards)
   -- Grab all lines during a full m/r/ostat output
   if xstat[curKey] == nil then xstat[curKey] = {} end
   if string.sub(executingAction,2,8) == 'statCap' then
      table.insert(xstat[curKey], line)
   end
end

function statAll(name, line, wildcards)
   local type = wildcards['type']
   if  GetOption("enable_timers") == 0 then
      Note("Warning: Timers are currently disabled. Cannot execute.")
      return
   end
   if wildcards['param'] == 'strings' then
      executingAction = type.."statStr"
   else
      executingAction = type.."statCap"
      xstat = {}
   end
   
   Execute(type.."list")
end

function editAll(name,line,wildcards)
   if  GetOption("enable_timers") == 0 then
      Note("Warning: Timers are currently disabled. Cannot execute.")
      return
   end
   local type = wildcards['type']
   executingAction = type.."editAll"
   Execute(wildcards['type'].."list")
end

-- Start the various captures

function statCapStart(name,line,wildcards)
   local type = wildcards['type']
   curKey = wildcards['key']
   EnableTrigger("trg_startCapture",true)
   if type == 'ostat' then 
      Send("oload "..curKey)
      Send("ostat "..curKey.." world")
   else
      Send(type.." "..curKey)
   end
end

function statCapStringsStart(name,line,wildcards)
   local type = wildcards['type']
   curKey = wildcards['key']
   raws[curKey] = {}
   EnableTrigger("trg_startCapture",true)
   if type == 'ostat' then
      Send("oload "..curKey)
      Send("ostat "..curKey.." world strings raw")
   elseif type == 'mstat' then
      Send("mstat "..curKey.." strings raw")
   elseif type == 'rstat' then
      Send("rstat "..curKey.." strings raw")
   end
end


function editCap(name,line,wildcards)
   curKey = wildcards['key']
   local type = wildcards['type']
   EnableTrigger("trg_startCapture",true)
   if type =='medit' then
      mt[curKey] = {}
      mt[curKey]['zone'] = getGMCPZone()
      Send("medit "..curKey)
      Send("v")
      Send("q")
   elseif type == 'oedit' then
      ot[curKey] = {}
      oaff[curKey] = {}
      ot[curKey]['zone'] = getGMCPZone()
      Send("oedit "..curKey)
   elseif type == 'redit' then
      rt[curKey] = {}
      rt[curKey]['zone'] = getGMCPZone()
      rt[curKey]['resetcount'] = '0'
      Send("redit "..curKey)
   end
end

function displayEditTable(name,line,wildcards)
   local area = getGMCPZone()
   local types = {o="object", m="mob"}
   local type = types[wildcards['type']]
   
   local key = area.."-"..wildcards['keynum']
   Note("-----------------------------------------------------------------------------")
   Note("                   Dumping details for "..type.." "..key)
   Note("-----------------------------------------------------------------------------")
   if type == "object" then
      writeTabletoNote(ot[key])
   elseif type == "mob" then
      writeTabletoNote(mt[key])
   end
end

function exportOtable(name,line,wildcards)
   local parsable = false
   if wildcards[1] == "parsable" then parsable = true end
   exportData("object",ot,parsable)
end

function exportMtable(name,line,wildcards)
   local parsable = false
   if wildcards[1] == "parsable" then parsable = true end
   exportData("mob",mt,parsable)
end

function exportXstatToFile()
   Note("Saving "..executingAction)
   local area = getGMCPZone()
   local outfile = "worlds\\plugins\\robbo_aardmush\\exports\\"..area.."_"..executingAction.."_"..getPort()..".txt"
   DebugNote("Toolbox: Opening file "..outfile)  
   local f = io.output (outfile)
   for x,key in ipairs(xlist[executingAction]) do
      writeArraytoFile(xstat[key],f)
   end
   f:close ()
end

function exportxEditToFile(type)
   local type = string.sub(executingAction,1,1)
   local area = getGMCPZone()
   local t = {}
   if type == "m" then t = mt end
   if type == "o" then t = ot end
   if type == "r" then t = rt end
   Note("Exporting data for type: "..type.." to an export file. You can use this for comparison later if needed.")
   local ext = ".tsv"
   local f = io.output ("worlds\\plugins\\robbo_aardmush\\exports\\"..area.."_"..type.."editData_"..getPort()..ext)
   for i,key in ipairs(xlist[executingAction]) do
      local attribs = getTableKeys(t[key])
      for j,attrib in ipairs(attribs) do
         f:write(key.."\t"..attrib.."\t"..t[key][attrib].."\n")
      end
   end
   f:close ()
end
