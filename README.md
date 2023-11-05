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