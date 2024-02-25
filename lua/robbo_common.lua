-- Common functions
function toggleConfig(v,p)
   -- set on/off or toggles
   -- v for value, p for parameter passed
   if p == 'on' or p == 'off' then
      v = p
   elseif b == 'on' then
      v = 'off'
   elseif b == 'off' then
      v = 'on'
   end
   return v
end

function tNilTozero(t,k)
   -- If a table value is undefined/nil, return zero instead
   local v = t[k]
   if v == nil then v = 0 end
   return tonumber(v)
end

function tableConcat(t1,t2)
   for _,v in ipairs(t2) do
      table.insert(t1, v)
   end
end

function round(x)
  if x == nil then return end
  return x>=0 and math.floor(x+0.5) or math.ceil(x-0.5)
end

function countMatches(base, pattern)
   base = string.lower(base)
   pattern = string.lower(pattern)
   return select(2, string.gsub(base, pattern, ""))
end

function DebugNote(s)
    if debug_mode == "on" then
        Note("Toolbox DEBUG: "..s)
    end
end

function split (inputstr, sep)
   if sep == nil then
      sep = "%s"
   end
   local t={}
   for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
      table.insert(t, str)
   end
   return t
end

function splitKey(key)
   -- Splits zone-nn key into two parts
   local t = split(key,"-")
   return t[1],t[2]
end

function getTableKeys(t)
  -- Returns list of table keys, sorted
  local keyset = {}
  for k,v in pairs(t) do
    keyset[#keyset + 1] = k
  end
  table.sort(keyset)
  return keyset
end

function table.contains(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end

function string.concat(...)
   local delim = table.remove(arg)
   local t = {}
   for i,v in ipairs(arg) do
      table.insert(t,v)
   end
   return table.concat(t,delim)
end

function writeTabletoFile(t,f,ikey,p)
   -- Dump contents of array to open file 'f'
   -- Uses pairs
   -- Make sure you open and close the file!
   -- Can pass ikey (area-nn) for parsable output
   if t == nil then return end
   local keys = getTableKeys(t)
   local maxlen = 0
   --Prepass for formatting
   for i,k in ipairs(keys) do
      if string.len(k) > maxlen then maxlen = string.len(k) end
   end
   for i,k in ipairs(keys) do
      if p == true then
         -- Parsable = .tsv file
         f:write(ikey.."\t"..k.."\t"..t[k].."\n")
      else
         f:write(string.format("%"..maxlen.."s",k)..": "..t[k].."\n")
      end
   end
   if p ~= true then f:write("\n") end
end

function writeTabletoNote(t)
   -- Dump contents of array to output(Note)
   -- Uses pairs
   -- Make sure you open and close the file!
   if t == nil then return end
   Note(serialize.save_simple(t))
end


function writeArraytoFile(t,f)
   -- Dump contents of array to open file 'f'
   -- Uses ipairs, so iterative
   -- Make sure you open and close the file!
   if t == nil then return end
   for i,v in ipairs(t) do
      f:write(v.."\n")
   end
   f:write("\n")
end

function writeArraytoNote(t)
   -- Dump contents of array to Output (Note)
   -- Uses ipairs, so iterative
   if t == nil then return end
   for i,v in ipairs(t) do
      Note(v)
   end
   Note()
end

function sortKeys(a)
   -- For sorting mob keys numerically, rather than alphabetically
   local tt = {}
   local st = {}
   local zone
   for i,v in ipairs(a) do
      local keysplit = split(v,'-')
      zone = keysplit[1]
      table.insert(tt,tonumber(keysplit[2]))
   end
   table.sort(tt)
   for i,v in ipairs(tt) do
      table.insert(st,zone.."-"..v)
   end
   return st
end


-- MUSHClient Utility
function clearTempTimers()
   Note("Clearing all temporary timers!")
   DeleteTemporaryTimers ()
end

-- lookup functions

function getGMCPZone()
   local res
   local current_zone
   res, current_zone = CallPlugin("3e7dedbe37e44942dd46d264","gmcpval","room.info.zone")
   return current_zone
end

function getPort()
   local port = GetInfo(1)
   if port == "aardmud.net" then port = "test" end
   if port == "aardmud.org" then port = "main" end
   return port
end

function isDual(wearable)
   local dual = false
   local duallocs = {"neck","ear","wrist","finger"}
   for i,v in ipairs(duallocs) do
      if countMatches(wearable,v) > 0 then dual = true end
   end
   return dual
end

function objcost(level,type)
   level = tonumber(level)
   local minw,maxw,maxv
   if type == 'Armor' then
      maxw = level/6
      minw = level/10
      maxv = level*50
   elseif type == 'Boat' then
      maxw = 20
      minw = 1
      maxv = level*5
   elseif type == 'Container' then
      maxw = level/2
      minw = level/15
      maxv = level*10
   elseif type == 'Drink' then
      maxw = level/2
      minw = level/15
      maxv = level*10
   elseif type == 'Food' then
      maxw = level/15
      minw = 1
      maxv = level*2
   elseif type == 'Furniture' then
      maxw = level/2
      minw = 1
      maxv = level*5
   elseif type == 'Gold' then
      -- Note that this doesn't have a definition in help files.
      -- Gold type is used for crumble objects
      maxw = 1
      minw = 1
      maxv = level*10000

   elseif type == 'Key' then
      maxw = level/2
      minw = 1
      maxv = level*2
   elseif type == 'Light' then
      maxw = level/2
      minw = 1
      maxv = level*4
   elseif type == 'Map' then
      maxw = level/2
      minw = 1
      maxv = level
   elseif type == 'Pill' then
      maxw = level/2
      minw = 1
      maxv = level*4
   elseif type == 'Portal' then
      maxw = level
      minw = 1
      maxv = level*6
   elseif type == 'Potion' then
      maxw = level/2
      minw = 1
      maxv = level*6
   elseif type == 'Scroll' then
      maxw = level/2
      minw = 1
      maxv = level*6
   elseif type == 'Staff' then
      maxw = level/2
      minw = 1
      maxv = level*6
   elseif type == 'Trash' then
      maxw = level/3
      minw = 1
      maxv = level*2
   elseif type == 'Treasure' then
      maxw = level/2
      minw = 1
      maxv = level*6
   elseif type == 'Wand' then
      maxw = level/3
      minw = 1
      maxv = level*6
   elseif type == 'Weapon' then
      maxw = level/3
      minw = 1
      maxv = level*15
   end
   return round(minw), round(maxw), round(maxv)

end