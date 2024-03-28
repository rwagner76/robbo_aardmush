function captureKeywords(name,line,wildcards)
   local s = wildcards[1]
   SetVariable("restring_Keywords",s)
   EnableTrigger("trg_restringKeywords",false)
end

function capture_restringID(name,line,wildcards)
   local id = wildcards[1]
   SetVariable("restring_ID",id)
   EnableTrigger("trg_restringID",false)
   DoAfterSpecial(.5,'restringHelp()',sendto.script)
end

function capture_firstroom(name,line,wildcards)
   local rid = wildcards[1]
   SetVariable("tportal_Dest",rid)
   DoAfterSpecial(.5,'tportalHelp()',sendto.script)
end

function pluginHelp()
   Note("----------------------------------------------------------------------------")
   Note(" To start a new restring, type 'restring <keyword>' for item in your")
   Note(" inventory.")
   Note("")
   Note(" To start a new trivia portal, type 'tportal <zone>'.")
   Note("")
   Note(" Additional help will be displayed once you type these commands.")
   Note("----------------------------------------------------------------------------")
end


function restringHelp(name,line,wildcards)
   Note("To perform restring, use:")
   Note("   keywords <all keywords here>  This will be appended to current keywords: '"..GetVariable("restring_Keywords").."'") 
   Note("   short <shortdesc here>")
   Note("   long <roomdesc here>")
   Note("You can use 'restring check' followed by 'restring set' once you're done. You must check before you set.")
   Note("Once the item restring has been completed, use 'restring charge <playername>' to pcharge the player.")
   Note("You can use 'restring balance <playername>' to check their TP balance before you start.")
   Note("")
   Execute("restring check")
end

function tportalHelp(name,line,wildcards)
   Note("To perform restring, use:")
   Note("   keywords <all keywords here> (first two keywords will automatically be 'trivia portal', you do not need these.)") 
   Note("   short <shortdesc here>")
   Note("   long <roomdesc here>")
   Note("   owner <playername>")
   Note("You can use 'tportal check' followed by 'tportal create' once you're done. You must check before you create.")
   Note("Once the portal has been completed, use 'tportal charge' to pcharge the owner.")
   Note("You can use 'tportal balance' to check their TP balance before you create the portal.")
   Note("")
   Execute("tportal check")
end

function checkShort(name,line,wildcards)
   local s = wildcards[1]
   if string.len(s) > 40 then
      Note("Error: Length is over 40 characters ("..string.len(s)..")")
   end
   EnableTrigger("trg_checkShort",false)
end

function checkLong(name,line,wildcards)
   local s = wildcards[1]
   if string.len(s) > 80 then   
      Note("Warning: Length is over 80 characters")
   end                                        
   EnableTrigger("trg_checkLong",false)
end

function setShort(name,line,wildcards)
   local s = wildcards[1]
   if s == "clear" then
      SetVariable("restring_Short","")
      Note("Short description cleared.")
      return
   end
   if string.len(s) > 100 then Note("Error: String with color codes must be 100 characters or less.") return end
   
   local last = ''
      for m in string.gmatch(s,'@%g') do
      last = m
   end
   if last ~= '' and last ~= '@w' then Note("Error: String contains color codes, but does not end with @w.") return end
   SetVariable("restring_Short",s)
   Note("Short description for restring set to: "..s)
   EnableTrigger("trg_checkShort",true)
   Send("echo self Short: "..s)
end

function setLong(name,line,wildcards)
   local s = wildcards[1]
   if s == "clear" then
      SetVariable("restring_Long","")
      Note("Long description cleared.")
      return
   end
   local last = ''
      for m in string.gmatch(s,'@%g') do
      last = m
   end
   if last ~= '' and last ~= '@w' then Note("Error: String contains color codes, but does not end with @w.") return end
   SetVariable("restring_Long",s)
   Note("Long description for restring set to: "..s)
   EnableTrigger("trg_checkLong",true)
   Send("echo self Long: "..s)
end

function setKeywords(name,line,wildcards)
   local s = wildcards[1]
   if s == "clear" then
      SetVariable("restring_AddKeywords","")
      Note("Extra keywords cleared.")
      return
   end
   if string.find(s,"'") then Note("Error: keywords cannot contain quotes.") return end
   if string.find(s,'"') then Note("Error: keywords cannot contain quotes.") return end
   if string.find(s,'@') then Note("Error: keywords cannot contain color codes.") return end
   SetVariable("restring_AddKeywords",s)
   Note("Additional Keywords for object will be: "..s)
   Note("Full keywords will be: "..GetVariable("restring_Keywords").." "..s)
end

function setOwner(name,line,wildcards)
   local s = wildcards[1]
   SetVariable("restring_Owner",s)
   Note("Owner for the trivia portal will be: "..s)
end

function restringCommand(name,line,wildcards)
   local s = wildcards[1]
   if s == "help" then pluginHelp() return end
   if s == "check" then
      local addkw = GetVariable("restring_AddKeywords")
      local short = GetVariable("restring_Short")
      local long = GetVariable("restring_Long")
      if addkw == '' then addkw = '(unchanged)' end
      if short == '' then short = '(unchanged)' end
      if long == '' then long = '(unchanged)' end
      Note("Restring check for item "..GetVariable("restring_ID"))
      Note("Keywords: "..GetVariable("restring_Keywords").." "..addkw)
      Note("Short   : "..short)
      Note("Long    : "..long)
      SetVariable("restring_Checked","yes")
   elseif s == "set" then
      if GetVariable("restring_Checked") == "yes" then
         local id = GetVariable("restring_ID")
         local short = GetVariable("restring_Short")
         local long = GetVariable("restring_Long")
         local kw = GetVariable("restring_Keywords").." "..GetVariable("restring_AddKeywords")
         if kw ~= '' then Send("ostring "..id.." keywords "..'"'..kw..'"') else Note("Warning: keywords are unchanged, not attempting change keywords.") end
         if short ~= '' then Send("ostring "..id.." short "..'"'..short..'"') else Note("Warning: Short desc is unchanged, not attempting to change short desc.") end
         if long ~= '' then Send("ostring "..id.." long "..'"'..long..'"') else Note("Warning: long desc is unchanged, not attempting to change long desc.") end
         SetVariable("restring_Set","yes")
      else
         Note("You should run 'restring check' first!")
      end
   elseif string.sub(s,1,6) == "charge" then
      if GetVariable("restring_Set") == "yes" then
         local player = string.sub(s,8)
         local id = GetVariable("restring_ID")
         if string.len(player) < 2 then
            Note("You must specify a player name!")
         else
            Send("pcharge "..player.." 0 2 0 Restring of item "..id)
         end
      else
         Note("You should probably run 'restring set' first!")
      end
   elseif string.sub(s,1,7) == "balance" then
      local player = string.sub(s,9)
      if string.len(player) < 2 then
         Note("You must specify a player name!")
      else
         Send("pcharge "..player.." 0 0 0 Checking balance before restring")
      end
   else
      EnableTrigger("trg_restringID",true)
      EnableTrigger("trg_restringKeywords",true)
      SetVariable("restring_AddKeywords","")
      SetVariable("restring_Short","")
      SetVariable("restring_Long","")
      Send("ostat '"..s.."' here")
      SetVariable("restring_Checked","no")
      SetVariable("restring_Set","no")
   end
end

function checkKeywords(kw,short,long)

end

function tportalCommand(name,line,wildcards)
   local s = wildcards[1]
   if s == "help" then pluginHelp() return end
   if s == "check" then
      local addkw = GetVariable("restring_AddKeywords")
      local short = GetVariable("restring_Short")
      local long = GetVariable("restring_Long")
      local owner = GetVariable("restring_Owner")
      if addkw == '' then addkw = '<none additional set>' end
      if short == '' then short = 'Needs to be set!' end
      if long == '' then long = 'Needs to be set!' end
      if owner == '' then owner = 'Needs to be set!' end
      Note("String check for new trivia portal:")
      Note("Keywords: "..GetVariable("restring_Keywords").." "..addkw)
      Note("Short   : "..short)
      Note("Long    : "..long)
      Note("Owner   : "..owner)
      Note("Dest    : "..GetVariable("tportal_Dest"))
      SetVariable("restring_Checked","yes")
   elseif s == "create" then
      if GetVariable("restring_Checked") == "yes" then
         local id = GetVariable("restring_ID")
         local short = GetVariable("restring_Short")
         local long = GetVariable("restring_Long")
         local kw = GetVariable("restring_Keywords").." "..GetVariable("restring_AddKeywords")
         local owner = GetVariable("restring_Owner")
         local firstroom = GetVariable("tportal_Dest")
         if kw == "" or short == "" or long == "" or owner == "" or firstroom == "" then Note("You must set all the required fields. Use 'tportal check' to verify your work!") return end
         Send("oload badtrip-9")
         Send("ostring 'trivia portal' short "..'"'..short..'"')
         Send("ostring 'trivia portal' long "..'"'..long..'"')
         Send("ostring 'trivia portal' keywords "..'"'..kw..'"')
         Send("ostring 'trivia portal' owner "..owner)
         Send("oset 'trivia portal' destination "..firstroom)
         Send("keep 'trivia portal'")
         SetVariable("restring_Set","yes")
      else
         Note("You should run 'restring check' first!")
      end
   elseif s == "charge" then
      if GetVariable("restring_Set") == "yes" then
         local owner = GetVariable("restring_Owner")
         local zone = GetVariable("tportal_Zone")
         if owner == '' then
            Note("You must define an owner for the trivia portal first! (owner <playername>)")
         else
            Send("pcharge "..owner.." 0 15 0 New Trivia Portal to area "..zone)
         end
      else
         Note("You should probably run 'tportal create' first!")
      end
   elseif s == "balance" then
      local owner = GetVariable("restring_Owner")
      if owner == '' then
         Note("You must define an owner for the trivia portal first! (owner <playername>)")
      else
         Send("pcharge "..owner.." 0 0 0 Checking balance before restring")
      end
   else
      SetVariable("restring_AddKeywords","")
      SetVariable("restring_Keywords","trivia portal")
      SetVariable("restring_ID","")
      SetVariable("restring_Short","")
      SetVariable("restring_Long","")
      SetVariable("restring_Owner","")
      SetVariable("restring_Checked","no")
      SetVariable("restring_Set","no")
      local badzones = {"limbo","mesolar","alagh","abend","gelidus","vidblain","uncharted","southern","uplanes","ninehells","lplanes","immhomes","warzone","lasertwo","oradrin","inferno","terra","icefall","titan","winds","genie","transcend","whiteclaw","blackclaw","seaking","prosper","darkside","soh2"}
      for i,v in ipairs(badzones) do
         if s == v then Note("That is an illegal zone for a trivia portal. Check helpfiles for more information!") return end
      end
      SetVariable("tportal_Zone",s)
      EnableTrigger("trg_FirstRoom",true)
      Send("zstat "..s)
   end
end