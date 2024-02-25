-- DB functions - common

function db_prep(dbfile,schema_version)
    local db = sqlite3.open(dbfile)
    local release_version = 1

    create_initial_tables(db)

    for row in db:nrows("PRAGMA user_version") do
        db_version = row.user_version
    end

    DebugNote("Database schema version "..db_version)

    local fk_enabled
    for row in db:nrows("PRAGMA foreign_keys") do
        fk_enabled = row.user_version
    end
    if fk_enabled == "OFF" then db:execute("PRAGMA foreign_keys = ON;") end

    local journal_mode
    for row in db:nrows("PRAGMA journal_mode") do
         journal_mode = row.journal_mode
    end
    if journal_mode ~= "WAL" then db:execute("PRAGMA journal_mode=WAL;") end

    if db_version >= schema_version then
        return
    end

    -- Individual migrations go here

    -- end migrations
    db:execute(string.format("PRAGMA user_version = %i;", schema_version))
    db:close_vm()
    db:close()
end

function create_initial_tables(db)
    local db_tables = {}
    local query = "SELECT name FROM sqlite_master WHERE type='table';"
    local create_tables = {}

    for row in db:nrows(query) do
        db_tables[row.name] = true
    end

    

    if not db_tables["mobs"] then
        DebugNote("Creating table 'mobs'")
        query = 
            [[
				CREATE TABLE mobs (
					key 			TEXT NOT NULL PRIMARY KEY,
					zone 			TEXT NOT NULL,
					ingame    INTEGER,
					keywords	TEXT,
					name			TEXT,
					roomname	TEXT,
					story			TEXT,
					desc			TEXT,
					level			INTEGER,
					alignment	INTEGER,
					gold			INTEGER,
					sex				TEXT,
					race			TEXT,
					guilds		TEXT,
					subclass	TEXT,
					flags			TEXT,
					affects		TEXT,
					immune		TEXT,
					actions		TEXT,
					mprogs		INTEGER,
					shop			TEXT
					);
				]]
       DebugNote("Query returns: "..db:execute(query))
    end

    if not db_tables["objects"] then
        DebugNote("Creating table 'objects'")
        query =
            [[
				CREATE TABLE objects (
					key 			TEXT NOT NULL PRIMARY KEY,
					zone 			TEXT NOT NULL,
					keywords	TEXT,
					name			TEXT,
					roomname	TEXT,
					type			TEXT,
					level			INTEGER,
					value			INTEGER,
					weight		INTEGER,
					size			INTEGER,
					material	TEXT,
					flags			TEXT,
					wearable	TEXT,
					descs			INTEGER,
					affects		INTEGER,
					objprogs	INTEGER
					);
				]]
       DebugNote("Query returns: "..db:execute(query))
    end

    if not db_tables["rooms"] then
        DebugNote("Creating table 'rooms'")
        query =
            [[
				CREATE TABLE rooms (
					key 				TEXT NOT NULL PRIMARY KEY,
					zone 				TEXT NOT NULL,
					name				TEXT,
					desc				TEXT,
					sector  		TEXT,
					sectorflags	TEXT,
					healrate		INTEGER,
					manarate		INTEGER,
					minlevel		INTEGER,
					maxlevel		INTEGER,
					brightness	INTEGER,
					maxchars		INTEGER,
					color				TEXT,
					gmcpcolor		TEXT,
					flags				TEXT,
					resets			INTEGER,
					stdexits		INTEGER,
					cexits			INTEGER,
					mapexits		INTEGER,
					desccount		INTEGER,
					rprogs			INTEGER
					);
				]]
       DebugNote("Query returns: "..db:execute(query))
    end



    if not db_tables["mobstats"] then
        DebugNote("Creating table 'mobstats'")
        query =
            [[
				CREATE TABLE mobstats (
					key 			TEXT NOT NULL PRIMARY KEY,
					str				INTEGER,
					int				INTEGER,
					wis				INTEGER,
					dex				INTEGER,
					con				INTEGER,
					luck			INTEGER,
					hitroll		INTEGER,
					damroll		INTEGER,
					saves     INTEGER,
					damtype		TEXT,
					spellset  TEXT,
					mverb			TEXT,
					resists		TEXT,
					dammax		INTEGER,
					damavg		INTEGER,
					dammin		INTEGER,
					manamax		INTEGER,
					manaavg		INTEGER,
					manamin		INTEGER,
					manabonus	INTEGER,
					hpmax			INTEGER,
					hpavg			INTEGER,
					hpmin			INTEGER,
					hpbonus		INTEGER,
					FOREIGN KEY(key) REFERENCES mobs(key)
					);
			]]
      DebugNote("Query returns: "..db:execute(query))
    end

    if not db_tables["oaffects"] then
        DebugNote("Creating table 'oaffects'")
        query =
            [[
				CREATE TABLE oaffects (
					key 			TEXT NOT NULL,
					type			TEXT NOT NULL,
					affects		TEXT NOT NULL,
					adjust		INTEGER,
					FOREIGN KEY(key) REFERENCES objects(key)
					);
				]]
       DebugNote("Query returns: "..db:execute(query))
    end

    if not db_tables["weapons"] then
        DebugNote("Creating table 'weapons'")
        query =
            [[
				CREATE TABLE weapons (
					key 			TEXT NOT NULL PRIMARY KEY,
					wtype			TEXT,
					avgdam		INTEGER,
					specials	TEXT,
					dverb			TEXT,
					FOREIGN KEY(key) REFERENCES objects(key)
					);
				]]
       DebugNote("Query returns: "..db:execute(query))
    end

    if not db_tables["mobpoints"] then
        DebugNote("Creating table 'mobpoints'")
        query =
            [[
				CREATE TABLE mobpoints (
					level 			INTEGER NOT NULL PRIMARY KEY,
					hpmin				INTEGER NOT NULL,
					hpavg				INTEGER NOT NULL,
					hpmax				INTEGER NOT NULL,
					hpadd				INTEGER NOT NULL,
					dmmin				INTEGER NOT NULL,
					dmavg				INTEGER NOT NULL,
					dmmax				INTEGER NOT NULL,
					dr					INTEGER NOT NULL,
					hr					INTEGER NOT NULL,
					gold				INTEGER NOT NULL
					);
				]]
       DebugNote("Query returns: "..db:execute(query))
    end

    if not db_tables["objpoints"] then
        DebugNote("Creating table 'objpoints'")
        query =
            [[
				CREATE TABLE objpoints (
					level 			INTEGER NOT NULL PRIMARY KEY,
					spnts				REAL NOT NULL,
					sstat				INTEGER NOT NULL,
					ssvs				REAL NOT NULL,
					shrdr				REAL NOT NULL,
					shp					REAL NOT NULL,
					snegall			INTEGER NOT NULL,
					dpnts				REAL NOT NULL,
					dstat				INTEGER NOT NULL,
					dsvs				REAL NOT NULL,
					dhrdr				REAL NOT NULL,
					dhp					REAL NOT NULL,
					dnegall			INTEGER NOT NULL
					);
				]]
       DebugNote("Query returns: "..db:execute(query))
    end

    if not db_tables["wdice"] then
        DebugNote("Creating table 'wdice'")
        query =
            [[
				CREATE TABLE wdice (
					level 	INTEGER NOT NULL PRIMARY KEY,
					min			INTEGER NOT NULL,
					max			INTEGER NOT NULL,
					avg			INTEGER NOT NULL
					);
				]]
       DebugNote("Query returns: "..db:execute(query))
    end

    if not db_tables["rawstrings"] then
        DebugNote("Creating table 'rawstrings'")
        query =
            [[
				CREATE TABLE rawstrings (
					key   		TEXT NOT NULL,
					type			TEXT NOT NULL,
					name			TEXT,
					roomname	TEXT,
					PRIMARY KEY (key, type)
					);
				]]
       DebugNote("Query returns: "..db:execute(query))
    end

    if not db_tables["food"] then
        DebugNote("Creating table 'food'")
        query =
            [[
				CREATE TABLE food (
					key       TEXT NOT NULL,
					foodname  TEXT,
					foodsize	INTEGER,
					drinksize	INTEGER,
					proof			INTEGER,
					totalsize	INTEGER,
					startsize	INTEGER,
					flags TEXT,
					FOREIGN KEY(key) REFERENCES objects(key)
					);
				]]
       DebugNote("Query returns: "..db:execute(query))
    end

    if not db_tables["containers"] then
        DebugNote("Creating table 'containers'")
        query =
            [[
				CREATE TABLE containers (
					key       	TEXT NOT NULL,
					capacity		INTEGER,
					maxitem			INTEGER,
					multiplier	INTEGER,
					keyobject		TEXT,
					flags			  TEXT,
					FOREIGN KEY(key) REFERENCES objects(key)
					);
				]]
       DebugNote("Query returns: "..db:execute(query))
    end

    if not db_tables["magicitems"] then
        DebugNote("Creating table 'magicitems'")
        query =
            [[
				CREATE TABLE magicitems (
					key       	TEXT NOT NULL,
          level				INTEGER,
					uses				INTEGER,
					spells			INTEGER,
					FOREIGN KEY(key) REFERENCES objects(key)
					);
				]]
       DebugNote("Query returns: "..db:execute(query))
    end

    if not db_tables["resets"] then
        DebugNote("Creating table 'resets'")
        query =
            [[
				CREATE TABLE resets (
					key       	TEXT NOT NULL,
          num					INTEGER NOT NULL,
					type				TEXT NOT NULL,
					loadkey			TEXT NOT NULL,
					gamemax			INTEGER,
					roommax			INTEGER,
					FOREIGN KEY(key) REFERENCES rooms(key),
					PRIMARY KEY(key,num)
					);
				]]
       DebugNote("Query returns: "..db:execute(query))
    end

    if not db_tables["subresets"] then
        DebugNote("Creating table 'subresets'")
        query =
            [[
				CREATE TABLE subresets (
					key       	TEXT NOT NULL,
          parent			INTEGER NOT NULL,
					type				TEXT NOT NULL,
					loadkey			TEXT NOT NULL,
					wearloc			TEXT,
					chance			INTEGER,
					FOREIGN KEY(key) REFERENCES rooms(key),
					FOREIGN KEY(parent) REFERENCES resets(num)
					);
				]]
       DebugNote("Query returns: "..db:execute(query))
    end

    if not db_tables["zoneinfo"] then
        DebugNote("Creating table 'zoneinfo'")
        query =
            [[
				CREATE TABLE zoneinfo (
					keyword			TEXT NOT NULL PRIMARY KEY,
					name       	TEXT NOT NULL,
          repopmsg		TEXT,
          levelrange	TEXT,
          minlevel		TEXT,
          maxlevel		TEXT
					);
				]]
       DebugNote("Query returns: "..db:execute(query))
    end

    db:close_vm()
end

function execute_in_transaction(db, operations)
    query = "BEGIN TRANSACTION;" .. table.concat(operations, "") .. "COMMIT;"
    db:exec(query)
end

function bindQs(s)
   -- Give a comma-seperated list, receive a list of ? instead!
   -- For DB prepare statements
   local t = split(s,',')
   local qs = {}
   for i,v in ipairs(t) do
      table.insert(qs,"?")
   end
   return table.concat(qs,',')
end

function querytoTable(db,q)
   local t = {}
   for r in db:nrows(q) do table.insert(t,r) end
   return t
end

function querytoArray(db,q)
   local a = {}
   local rc = 0
   for r in db:rows(q) do
     table.insert(a,r[1])
   end
   return a
end

function countQuery(db,q)
   for r in db:rows(q) do
      return r[1]
   end
end

-- Specific transactions

function writeMobtoDB(key,t,db)
   local mclist = "key,zone,ingame,keywords,name,roomname,story,desc,level,alignment,gold,sex,race,guilds,subclass,flags,affects,immune,actions,mprogs,shop"
   local qs = bindQs(mclist)
   local query = "INSERT OR REPLACE INTO mobs("..mclist..") VALUES("..qs..");"
   local stmt = db:prepare(query)
   stmt:bind_values(key,t['zone'],t['ingame'],t['keywords'],t['name'],t['roomname'],t['story'],t['desc'],t['level'],t['alignment'],t['gold'],t['sex'],t['race'],t['guilds'],t['subclass'],t['flags'],t['affects'],t['immune'],t['actions'],t['mprogs'],t['shop'])
   stmt:step()
   stmt:finalize()

   local statslist = "key,str,int,wis,dex,con,luck,hitroll,damroll,saves,damtype,spellset,mverb,resists,dammax,damavg,dammin,manamax,manaavg,manamin,manabonus,hpmax,hpavg,hpmin,hpbonus"
   qs = bindQs(statslist)
   query = "INSERT OR REPLACE INTO mobstats("..statslist..") VALUES("..qs..");"
   stmt = db:prepare(query)
   stmt:bind_values(key,t['str'],t['int'],t['wis'],t['dex'],t['con'],t['luck'],t['hitroll'],t['damroll'],t['saves'],t['damtype'],t['spellset'],t['mverb'],t['resists'],t['dammax'],t['damavg'],t['dammin'],t['manamax'],t['manaavg'],t['manamin'],t['manabonus'],t['hpmax'],t['hpavg'],t['hpmin'],t['hpbonus'])
   stmt:step()
   stmt:finalize()

   db:close_vm()
end

function writeObjecttoDB(key,t,oat,db)
   -- This one needs the oaffect table as well
   local oclist = "key,zone,keywords,name,roomname,type,level,value,weight,size,material,flags,wearable,descs,affects,objprogs"
   local qs = bindQs(oclist)
   local query = "INSERT OR REPLACE INTO objects("..oclist..") VALUES("..qs..");"
   local stmt = db:prepare(query)
   stmt:bind_values(key,t['zone'],t['keywords'],t['name'],t['roomname'],t['type'],t['level'],t['value'],t['weight'],t['size'],t['material'],t['flags'],t['wearable'],t['descs'],t['affects'],t['objprogs'])
   stmt:step()
   stmt:finalize()
   
   if t['type'] == 'Weapon' then
      local wlist = "key,wtype,avgdam,specials,dverb"
      qs = bindQs(wlist)
      query = "INSERT OR REPLACE INTO weapons("..wlist..") VALUES("..qs..");"
      stmt = db:prepare(query)
      stmt:bind_values(key,t['wtype'],t['avgdam'],t['specials'],t['dverb'])
      stmt:step()
      stmt:finalize()
   end
   
   if t['spelllevel'] ~= nil then
      local wlist = "key,level,uses,spells"
      local spells = table.concat(t['spells'],',')
      qs = bindQs(wlist)
      query = "INSERT OR REPLACE INTO magicitems("..wlist..") VALUES("..qs..");"
      stmt = db:prepare(query)
      stmt:bind_values(key,t['spelllevel'],t['uses'],spells)
      stmt:step()
      stmt:finalize()
   end

   if t['foodsize'] ~= nil then
      local wlist = "key,foodname,foodsize,drinksize,proof,totalsize,startsize,flags"
      qs = bindQs(wlist)
      query = "INSERT OR REPLACE INTO food("..wlist..") VALUES("..qs..");"
      stmt = db:prepare(query)
      stmt:bind_values(key,t['foodname'],t['foodsize'],t['drinksize'],t['proof'],t['totalsize'],t['startsize'],t['foodflags'])
      stmt:step()
      stmt:finalize()
   end

   if t['type'] == 'Container' then
      local wlist = "key,capacity,maxitem,multiplier,keyobject,flags"
      qs = bindQs(wlist)
      query = "INSERT OR REPLACE INTO containers("..wlist..") VALUES("..qs..");"
      stmt = db:prepare(query)
      stmt:bind_values(key,t['capacity'],t['maxitem'],t['multiplier'],t['keyobject'],t['containerflags'])
      stmt:step()
      stmt:finalize()
   end
   
   
   local oaff = getTableKeys(oat)
   
   if #oaff > 0 then
      local queries = {}
      table.insert(queries,"DELETE FROM oaffects where key='"..key.."';")
      for i,type in ipairs(oaff) do
         local affects = getTableKeys(oat[type])
         for j,affect in ipairs(affects) do
            local adjust = oat[type][affect]
            query = string.format("INSERT INTO oaffects (key,type,affects,adjust) values ('%s','%s','%s','%s');",key,type,affect,adjust)
            table.insert(queries,query)
         end
      end
      execute_in_transaction(db, queries)
   end
   db:close_vm()
end

function writeRawstoDB(key,t,db,a)
   local type
   if string.sub(a,1,1) == 'm' then type = 'mob'
   elseif string.sub(a,1,1) == 'o' then type = 'object'
   elseif string.sub(a,1,1) == 'r' then type = 'room'
   end
   
   local mclist = "key,type,name,roomname"
   local qs = bindQs(mclist)
   local query = "INSERT OR REPLACE INTO rawstrings("..mclist..") VALUES("..qs..");"
   local stmt = db:prepare(query)
   stmt:bind_values(key,type,t['rawname'],t['rawroomname'])
   stmt:step()
   stmt:finalize()

   db:close_vm()
end

function writeRoomtoDB(key,t,db)
   local mclist = "key,zone,name,desc,sector,sectorflags,healrate,manarate,minlevel,maxlevel,brightness,maxchars,color,gmcpcolor,flags,resets,stdexits,cexits,mapexits,desccount,rprogs"
   local qs = bindQs(mclist)
   local query = "INSERT OR REPLACE INTO rooms("..mclist..") VALUES("..qs..");"
   --DebugNote(query)
   local stmt = db:prepare(query)
   stmt:bind_values(key,t['zone'],t['name'],t['desc'],t['sector'],t['sectorflags'],t['healrate'],t['manarate'],t['minlevel'],t['maxlevel'],t['brightness'],t['maxchars'],t['color'],t['gmcpcolor'],t['flags'],t['resetcount'],t['stdexits'],t['cexits'],t['mapexits'],t['desccount'],t['rprogs'])
   stmt:step()
   DebugNote("DB Error: "..db:errmsg())
   stmt:finalize()
   db:close_vm()
   --DebugNote("Serializing room:"..key)
   --DebugNote(serialize.save_simple(t))
   
   if t['resets'] ~= nil then
      local queries = {}
      for i,v in ipairs(t['resets']) do
         local q = string.format("INSERT OR REPLACE INTO resets(key,num,type,loadkey,gamemax,roommax) VALUES('%s','%s','%s','%s','%s','%s');",key,v.num,v.type,v.key,v.gamemax,v.roommax)
         table.insert(queries,q)
      end
      writeTabletoNote(queries)
      execute_in_transaction(db, queries)
   end
   
   if t['subresets'] ~= nil then
      local queries = {}
      for i,v in ipairs(t['subresets']) do
         local q = string.format("INSERT OR REPLACE INTO subresets(key,parent,type,loadkey,wearloc,chance) VALUES('%s','%s','%s','%s','%s','%s');",key,v.parent,v.type,v.key,v.wearloc,v.chance)
         table.insert(queries,q)
      end
      writeTabletoNote(queries)
      execute_in_transaction(db, queries)
   end
end
