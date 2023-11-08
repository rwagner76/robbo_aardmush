# robbo_aardmush
Robbo's Aardwolf Plugins for MUSHclient

## EnchantRobbot (ebot)
Robbo's Enchantbot is a script to improve the quality of life for Enchanters on Aardwolf. Its primary functions are:
- Enchant an item from a shopkeeper one at a time, but use some logic to determine if the item should be kept or tossed.
- Intelligently choose whether to attempt a re-enchant on items with poor stats.
- Provide some utility functions for sorting and managing equipment and sets carried.
- Complain if Enchanter's Focus isn't up when you run it.

### Installation
Download EnchantRobbot.xml and place into your MUSHClient Worlds\Plugins folder, then install the plugin.
Type 'ebot config' to check plugin default configuration.

### Usage
```
                       EnchantBot Help
=============================================================================
 ebot help                 --> Show help
 ebot config               --> Show configured settings
 ebot enchant <keyword>    --> Enchant an item
 ebot enchant              --> Repeat last enchant
 ebot reset                --> Reset running state if things get weird
 ---------------------------------------------------------------------------
                  Configuration Commands
 ebot mindr                --> Set minimum DR for an item
 ebot minstats             --> Set minimum additional stats for an item
 ebot keepbag <keyword>    --> Set bag to store 'keeper' items
 ebot tossbag <keyword>    --> Set bag to store junk items
 ebot bagjunk              --> Toggle bagging of junk items
 ebot setitem <keyword>    --> Optionally, set item keyword to enchant
 	                             (you don't need to use ebot enchant <keyword>)
 ---------------------------------------------------------------------------
                      Utility Commands
 sorteq <keyword> <bag>  --> Sort items matching keyword by score and
 	                             re-order in bag.
 geteqset <prefix> <bag>   --> Pull a set starting with prefix from a bag
 	                             (all possible wear locations)
 puteqset <prefix> <bag>   --> Put a set starting with prefix into a bag
 	                             (all possible wear locations)
 cancelsort                --> Cancels set sort in progress
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

```

## Guinness's Test Port Toolbox (GuinnessTools.xml)
This has a variety of simple aliases and tools mostly for Guinness' use, but would be of value to anybody reviewing mobs, objects, rooms, and programs in an area. It's mostly to prevent a lot of repetitive typing, and many commands are ideally run while saving output to a log file for offline review.
- Commands that dump a lot of data (like mstatall, rstatall, etc) use temporary timers to pause slightly between each command, so you don't get automatically disconnected.
- Bulk commands will turn off your prompt during execution
- mpdumpall command will enable 'rawcolors' during execution


### Installation
Download GuinnessTools.xml and place into your MUSHClient Worlds\Plugins folder, then install the plugin. (make sure this is your test port instance!)

### Usage
```
                      Test Port Toolbox Help
=============================================================================
 ggo                       --> Alias for rgoto that increments the room vnum
                               you're in. Starts at 'rgoto 0'. (Guinness Go!)
 ggo reset                 --> Sets ggo back to 0.
 mstatall keyword N        --> Dumps mstat for each mob in 'keyword' area,
                               counting from 0 to N. (N is a number)
 rstatall keyword N        --> Dumps rstat for each room in 'keyword' area,
                               counting from 0 to N.
 ostatall keyword N        --> Dumps ostat for each room in 'keyword' area,
                               counting from 0 to N. The object is loaded
                               before ostat.
 mpdumpall keyword N       --> Does mpdump of all programs 0 to N.
                               Uses rawcolor mode and noline.
 meditall keyword N        --> Similar to mstatall, dumps mob editor
                               details.
 reditall keyword N        --> Similar to rstatall, dumps room editor
                               details.
 oeditall keyword N        --> Similar to rstatall, dumps room editor
                               details.                               