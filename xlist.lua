function xlistExecute(name, line, wildcards)
   local type=wildcards['type']
   xlist[executingAction] = {}
   EnableTrigger("captureListKeys",true)
   EnableTrigger("endCaptureListKeys",true)
   Send(type.."list")
end

function addListKey(name, line, wildcards)
   table.insert(xlist[executingAction],wildcards[1])
end

function endListkeys(name, line, wildcards)
   local area = getGMCPZone()
   EnableTrigger("captureListKeys",false)
   EnableTrigger("endCaptureListKeys",false)

   DebugNote("Toolbox: Captured "..table.getn(xlist[executingAction]).." keys for action: "..executingAction)

   if executingAction == "ggo" then Execute("ggo")
   else if executingAction == "gmgo" then Execute("gmgo") end
   else captureLoop(xlist[ExecutingAction])
end

function captureLoop(kt)
   local interval = 1.5
   local delay = interval
   local command
   local type = string.sub(executingAction,1,1)
   
   if string.sub(executingAction,2,7) == 'editAll'
      command = type .."editcap "
   elseif string.sub(executingAction,2,7) == 'statStr'
      command = type .."statstr "
   elseif string.sub(executingAction,2,7) == 'statCap'
      command = type .."statcap "
   end

   for i,key in ipairs(kt) do
      DoAfterSpecial(delay,"echo -- START CAPTURE --",sendto.execute)
      delay = delay + .1
      DoAfterSpecial(delay,command..key,sendto.execute)
      if string.sub(executingAction,2,7) ~= 'editAll'
         -- Edit commands have secondary triggers, will trigger on return to game.
         delay = delay + .1
         DoAfterSpecial(delay,"echo -- END CAPTURE --",sendto.execute)
      end
      delay = delay + interval
   end
   delay = delay + 1
   DoAfterSpecial(delay,"echo -- END ALL CAPTURE COMMANDS --",sendto.execute)
   delay = delay + 2
   DoAfterSpecial(delay,'gcancel',sendto.execute)
end

function captureLoopEnd(name, line, wildcards)
   local area = getGMCPZone()
   Execute('gcancel')
   if string.sub(executingAction,2,7) ~= 'statCap' then
      exportXstatToFile(string.sub(executingAction,1,5))
   end



   executingAction = "none"
end

function captureStart(name,line,wildcards)
   if string.sub(executingAction,2,7) == 'statCap' then
      enableTrigger("trg_captureXstatLines",true)
   --elseif executingAction == 'ostatStr' then
   --   EnableTriggerGroup("ostatStringCaptures",true)
   --elseif executingAction == 'mstatStr' then
   --   EnableTriggerGroup("mstatStringCaptures",true)
   --elseif executingAction == 'rstatStr' then
   --   EnableTriggerGroup("rstatStringCaptures",true)
   elseif executingAction == 'oeditAll' then
      EnableTriggerGroup("oeditCaptures",true)
   elseif executingAction == 'meditAll' then
      EnableTriggerGroup("meditCaptures",true)
      EnableTriggerGroup("meditStatCaptures",true)
      EnableTrigger("trg_meditDesc",true)
   --elseif executingAction == 'reditAll' then
   --   EnableTriggerGroup("reditCaptures",true)
   end
   EnableTriggerGroup("tgrp_endCaptures",true)
end

function captureEnd(name,line,wildcards)
   EnableTrigger("trg_captureXstatLines",false)
   ---EnableTriggerGroup("mstatStringCaptures",false)
   ---EnableTriggerGroup("ostatStringCaptures",false)
   ---EnableTriggerGroup("rstatStringCaptures",false)
   EnableTriggerGroup("meditCaptures",false)
   EnableTriggerGroup("meditStatCaptures",false)
   EnableTrigger("trg_meditDesc",false)
   EnableTriggerGroup("oeditCaptures",false)
   ---EnableTriggerGroup("reditCaptures",false)
   EnableTriggerGroup("tgrp_endCaptures",false)

end

function captureStatLines()
   -- Grab all lines during a full m/r/ostat output
   if xstat[curKey] == nil then xstat[curKey] = {} end
   if executingAction == 'ostatCap' then
      table.insert(xstat[curKey], line)
   end
end

function exportXstatToFile(stype)
   Note("Saving "..stype)
   local outfile = "worlds\\plugins\\robbo_aardmush\\exports\\"..area.."_"..stype.."_"..getPort()..".txt"
   DebugNote("Toolbox: Opening file "..outfile)  
   local f = io.output (outfile)
   for x,key in ipairs(xlist[executingAction]) do
      writeArraytoFile(xstat[key],f)
   end
   f:close ()
end

function statAll(name, line, wildcards)
   if  GetOption("enable_timers") == 0 then
      Note("Warning: Timers are currently disabled. Cannot execute.")
      return
   end
   if wildcards['param'] == 'strings' then
      executingAction = "statStr"
   else
      executingAction = "statCap"
   end
   Execute(wildcards['type'] .."list")
end

function editAll(name,line,wildcards)
   if  GetOption("enable_timers") == 0 then
      Note("Warning: Timers are currently disabled. Cannot execute.")
      return
   end
   executingAction = type.."editAll"
   Execute(wildcards['type'].."list")
end
