# robbo_aardmush
Robbo's Aardwolf Immortal Plugins for MUSHclient

## Imm_Restring
This is a plugin only for imms, as it won't do anything for regular players.  It's used to restring items as well as create new trivia portals.

### Installation
Easiest is to ensure you have 'git' installed. You can download git for Windows (just google it quick) or it's available in all Linux distributions (use your package manager)
- Navigate to your worlds/plugins folder.
- ```git clone git@github.com:rwagner76/robbo_aardmush.git```
- Load plugins from the robbo_aardmush folder

### Updating
- Navigate to your worlds/plugins folder.
-   ```git pull```
- Reload plugins as desired.

### Usage
```
----------------------------------------------------------------------------
 To start a new restring, type 'restring <keyword>' for item in your
 inventory.

 To start a new trivia portal, type 'tportal <zone>'.

 Additional help will be displayed once you type these commands.
 
 The plugin will validate strings, color code termination, legal zones, and
 provide convenience aliases for pcharge to check balances and charge
 players. It also will automatically grab the first room for portal
 destinations.
----------------------------------------------------------------------------
```




## Newbie Channel Activity Tracker
The Newbie Channel Activity tracker is made for our imm friends (and spouses)
- Provides a report of how many times helpers/advisors/imms talk on the Newbie channel.
- Saves state, can be reset whenever you want.

### Installation
Download NewbieChannelTracker.xml and place into your MUSHClient Worlds\Plugins folder, then install the plugin.

### Usage
```
                      NewbieTracker Help
=============================================================================
 newbietracker show        --> Display saved activity data
 newbietracker reset       --> Reset tracker
 newbietracker help        --> Get help

```

## Guinness's Test Port Toolbox (GuinnessTools.xml)
This has a variety of simple aliases and tools mostly for Guinness' use, but would be of value to anybody reviewing mobs, objects, rooms, and programs in an area. It's mostly to prevent a lot of repetitive typing, and many commands are ideally run while saving output to a log file for offline review.
- Commands that dump a lot of data (like mstatall, rstatall, etc) use temporary timers to pause slightly between each command, so you don't get automatically disconnected.
- Bulk commands will turn off your prompt during execution
- mpdumpall command will enable 'rawcolors' during execution


### Installation
Download GuinnessTools.xml and place into your MUSHClient Worlds\Plugins folder, then install the plugin. (make sure this is your test port instance!)
or:  git clone this repository into your worlds\plugins folder

### Usage
```
                      Test Port Toolbox Help
=============================================================================
 garea keyword             --> Set the area you're working in so you don't
                               need to type keywords
 ggo                       --> Alias for rgoto that increments the room vnum
                               you're in. Starts at 'rgoto 0'. (Guinness Go!)
 ggo #                     --> Sets ggo to # and goes!
 ggo reset                 --> Sets ggo back to 0.
 gmgo                      --> Alias for mgoto that increments the mob vnum
                               you're in. Starts at 'mgoto area-0'. (Guinness Go!)
 gmgo #                    --> Sets ggo to # and goes!
 gmgo reset                --> Sets ggo back to 0.
 gcancal                   --> Deletes all temporary timers queued.
 mstatall # [#]            --> Dumps mstat for each mob in 'keyword' area,
                               counting from 0 to #.
 rstatall # [#]            --> Dumps rstat for each room in 'keyword' area,
                               counting from 0 to #.
 ostatall # [#]            --> Dumps ostat for each room in 'keyword' area,
                               counting from 0 to #. The object is loaded
                               before ostat.
 mpdumpall # [#]           --> Does mpdump of all programs 0 to N.
                               Uses rawcolor mode and noline.
 meditall # [#]            --> Collects mob editor details for later export.
 oeditall # [#]            --> Collects object editor details for later export.
 exportmobs [parsable]     --> Exports all mob data collected by meditall.
 exportobjects [parsable]  --> Exports all object data collected by oeditall.
 exportmstat/ostat/rstat   --> Exports rstat/mstat/ostat data collected by statall
                               commands.
 toolbox help              --> Show this help file

 Note: use 'parsable' option with exports to create files usable by area audit tools.
 Exported files will be saved to worlds\plugins\robbo_aardmush\exports
 ```
 
 ## Area evaluation scripts
 ### Setup/requirements:
 Ensure Strawberry Perl is installed (https://strawberryperl.com/)
 Once installed, install module List::Compare:
 ```
 perl -MCPAN -e'install List::Compare'
 ```
 
 ### Area Diff Usage:
 From your exports directory, run:
 ```
 
 Ensure you have parsable object or mob dumps from an area on BOTH test and main ports.
 
 Area diff:
 perl ..\area_diff.pl zonename [object|mob]
 ```
 
 ### Area Review Usage:
 From your exports directory, run:
 ```
 
 Ensure you have parsable object AND mob dumps from an area on test or main port.
 
 Area review:
 perl ..\area_review.pl zonename [test|main]
 ```
 
 If you have issues with filenames not containing test or main port in the name, this is determined by your world hostname/IP setting.
 aardmud.net = test, aardmud.org = main.
