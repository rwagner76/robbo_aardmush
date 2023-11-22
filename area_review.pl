use List::Compare;

if (scalar(@ARGV) != 2) {showUsage();}
my $area = $ARGV[0];
my $port = $ARGV[1];

my $objfile = $area."_object_".$port.".tsv";
my $mobfile = $area."_mob_".$port.".tsv";

my (%mob,%obj); #A couple big global hashes

#Added resist tracker by type for the end summary
my %addedresists;
my $objaddedresists = 0;

#Data on quality of objects
my %objquality;
my $objreqreview = 0;

#Mob review/summary info
my $mobreqreview = 0;
my $mobtotalalign = 0; #Going to average the alignments.
my %mobguilds; #Count how many mobs of each guild
my $animalcount = 0;
my %mobwatchflags; #Areaattack, Assistalign, Assistpcs, Assistself, Assistmobs, Assistrace. (should be used sparingly)

open(FILE,"<$objfile") || die("Can't find file $objfile");
@lines = <FILE>;
close FILE;
chomp @lines;
foreach $line (@lines) {
   my ($key,$attrib,$value) = split("\t",$line);
   push @keys, $key;
   $obj{$key}{$attrib} = $value;
}

open(FILE,"<$mobfile") || die("Can't find file $mobfile");
@lines = <FILE>;
close FILE;
chomp @lines;
foreach $line (@lines) {
   my ($key,$attrib,$value) = split("\t",$line);
   push @keys, $key;
   $mob{$key}{$attrib} = $value;
}

my @objkeys = sort(keys(%obj));
my @mobkeys = sort(keys(%mob));

foreach $key (@objkeys) {
   my %a = %{$obj{$key}};
   $a{"NeedsReview"} = 0;
   print "Checking object ".$key." (".$a{"Name"}.")\n";
   print "--------------------------------------------------------------------------------\n";
   print "\tItem Type: ".$a{"Object Type"}."\n";
   my @attributes = sort(keys(%a));
   my @affects = grep(/^Affects\d+/,@attributes);
   if (scalar(@affects) && defined($a{"Wearable"})) {
      if (checkObjAffects($key,@affects)) {$a{"NeedsReview"} = 1;};
   }
   if (checkObjWeightandValue($key,@affects)) {$a{"NeedsReview"} = 1;};
   if ($a{"Object Type"} eq "Weapon") {
      if (checkWeaponDice($key)) {$a{"NeedsReview"} = 1;};
   }

   if (length(%a{"Name"} > 50)) {
      print "\tWarning: Short name of object is longer than 50 characters\n";
      $a{"NeedsReview"} = 1;
   }
   if (length(%a{"Room Name"} > 80)) {
      print "\tWarning: Room name of object is longer than 80 characters\n";
      $a{"NeedsReview"} = 1;
   }
   
   if ($a{"NeedsReview"}) {
      $objreqreview += 1;
      print "Note: Object should be reviewed!\n";
   }
   print "--------------------------------------------------------------------------------\n\n";
}

# MOBS!

foreach $key (@mobkeys) {
   # Quick pass to calculate average alignment ahead of the individual mob review
   my %a = %{$mob{$key}};
   $mobtotalalign += $a{"Alignment"};
}

my $mobavgalignment = int($mobtotalalign/scalar(@mobkeys));

foreach $key (@mobkeys) {
   my %a = %{$mob{$key}};
   $a{"NeedsReview"} = 0;
   print "Checking mob ".$key." (".$a{"Name"}.")\n";
   print "--------------------------------------------------------------------------------\n";
   if (length(%a{"Name"} > 50)) {
      print "\tWarning: Short name of mob is longer than 50 characters (limit?)";
      $a{"NeedsReview"} = 1;
   }
   if (length(%a{"Room Name"} > 80)) {
      print "\tWarning: Room name of mob is longer than 80 characters\n";
      $a{"NeedsReview"} = 1;
   }
   my @desc = split(/\\n/,$a{"Desc"});
   if (scalar(@desc < 3)) {
      print "\tWarning: Less than 3 lines of text in the mob's description\n";
      $a{"NeedsReview"} = 1;
   }
   if ($a{"NeedsReview"} == 0) {print "\tDescriptions are OK.\n";}
   if (($a{"Alignment"} > 1875) || ($a{"Alignment"} < -1875)) {
      print "\tWarning: Mob alignment is set to an extreme value. Value: ".$a{"Alignment"}."\n";
      $a{"NeedsReview"} = 1;
   }
   if (checkMobFlags($key)) {
      $a{"NeedsReview"} = 1;
   } else {
      print "\tMob flags are OK.\n";
   }
   if (! defined $a{"Guilds"}) {
      if ((! $a{"Flags"} =~ /undead/) && (! $a{"Flags"} =~ /animal/)) {
         print "\tWarning: Mob does not have guild set OR flag set for undead/animal.\n";
         $a{"NeedsReview"} = 1;
      }
   } elsif ($a{"Guilds"} =~ /,/) {
      print "\tWarning: Mob has multiple guilds assigned.\n";
      $a{"NeedsReview"} = 1;
   } else {
	    print "\tGuild is okay.\n";
	    $mobguilds{$a{"Guilds"}} += 1;
   }

   if (checkMobPoints($key)) {
      $a{"NeedsReview"} = 1;
   } else {
      print "\tMob points and gold are OK.\n";
   }


   if ($a{"NeedsReview"}) {
      $mobreqreview += 1;
      print "Note: Mob should be reviewed!\n";
   }
   
   print "--------------------------------------------------------------------------------\n\n";
}

print "Area summary:\n";
print "--------------------------------------------------------------------------------\n";
print "Total objects            : ".scalar(@objkeys)."\n";
print "Object quality (by score):\n";
my @qlist = ("Masterpiece","Average","Mediocre","Bad");
foreach $q (@qlist) {
   printf("\t%11s: %4d\n",$q,$objquality{$q});
}

print "\nTotal mobs              : ".scalar(@mobkeys)."\n";
print "Average mob alignment   : $mobavgalignment\n";
print "Mob guild counts        :\n";
foreach $g (keys(%mobguilds)) {
   printf("\t%11s: %4d\n",$g,$mobguilds{$g});
   if ($mobguilds{$g} > scalar(@mobkeys)/2) {print "\tWarning: More than 50% of mobs belong to the $g guild.\n";}
}
my $animalpct = int($animalcount/scalar(@mobkeys) * 100);
print "Mob animal counts       : $animalcount ($animalpct\%)";
if ($animalpct > 33) {print "Warning: Animal count is over 1/3 of mobs.\n"};

if (scalar(keys(%mobwatchflags))) {
   print "Flags to be used sparingly:\n";
   foreach my $f (keys(%mobwatchflags)) {
      fprint("\t%10s: %d",$f,$mobwatchflags{$f});
   }
}


print "\nObjects requiring review: $objreqreview\n";
print "Mobs requiring review   : $mobreqreview\n";



print "\nTotal objects with added (non-standard) resists: $objaddedresists\n";
foreach my $resist (keys(%addedresists)) {
   if ($addedresists{$resist} > 1) {print "Warning: More than one object in the area has added resist of type $resist\n";}
}

sub checkMobFlags {
   my ($key) = @_;
   my %mt = %{$mob{$key}};
   my $return = 0;
   if (! $mt{"Flags"} =~ /confined/) {
      print "\tWarning: Mob does not have the confined flag.";
   }
   
   if ($a{"Flags"} =~ /animal/) {$animalcount++;}
   
   my @checkflags = ("areaattack","assistalign","assistpcs","assistself","assistmobs","assistrace");
   foreach my $f (@checkflags) {
      if ($a{"Flags"} =~ /$f/) {$mobwatchflags{$f} += 1;}
   }
   
   # If possible, check for plurals and/or if nocorpse is needed. The last might be impossible.
}

sub checkMobPoints {
   my ($key) = @_;
   my %mt = %{$mob{$key}};
   my $return = 0;
   my ($hpmin,$hpavg,$hpmax,$hpadd,$dmmin,$dmavg,$dmmax,$dr,$hr,$gold) = getMobPoints($mt{"Level"});
   if ($mt{"HP/Move Range Min"} < $hpmin) {
      print "\tHP/Move minimum is below minimum for level: ".$mt{"HP/Move Range Min"}." vs level minimum $hpmin\n";
      $return = 1;
   }
   if ($mt{"HP/Move Range Max"} > $hpmax) {
      print "\tHP/Move maximum is above maximum for level: ".$mt{"HP/Move Range Max"}." vs level minimum $hpmax\n";
      $return = 1;
   }
   if (($mt{"HP/Move Range Avg"} > ($hpavg * 1.25)) || ($mt{"HP/Move Range Avg"} < ($hpavg * .75))) {
      print "\tHP/Move average is more than 25\% out of spec for level: ".$mt{"HP/Move Range Avg"}." vs level average $hpavg\n";
      $return = 1;
   }
   if ($mt{"HP/Move Range Bonus"} > $hpadd) {
      print "\tHP/Move range bonus is above maximum for level: ".$mt{"HP/Move Range Bonus"}." vs level bonus $hpadd\n";
      $return = 1;
   }

   if ($mt{"Damage Range Min"} < $dmmin) {
      print "\tDamage minimum is below minimum for level: ".$mt{"Damage Range Min"}." vs level minimum $dmmin\n";
      $return = 1;
   }
   if ($mt{"Damage Range Max"} > $dmmax) {
      print "\tDamage maximum is above maximum for level: ".$mt{"Damage Range Max"}." vs level minimum $dmmax\n";
      $return = 1;
   }
   if (($mt{"Damage Range Avg"} > ($dmavg * 1.25)) || ($mt{"Damage Range Avg"} < ($dmavg * .75))) {
      print "\tDamage average is more than 25\% out of spec for level: ".$mt{"Damage Range Avg"}." vs level average $dmavg\n";
      $return = 1;
   }


   print "\tNote: Mana range table is unknown. Can't check.\n";
   
   
   return $return;
}


sub checkObjAffects {
   my ($key,@affects) = @_;
   my %ot = %{$obj{$key}};
   my ($statscore,$hrdrscore,$hpmnmvscore,$negpoints);
   my %resists;
   my @statlist = ("Intelligence","Strength","Dexterity","Constitution","Luck","Wisdom");
   foreach my $affect (@affects) {
      if ($ot{$affect} =~ /Stat/) {
         my ($junk,$attr,$val) = split(/,/,$ot{$affect});
         if ($attr =~ /roll/) {
            $val =~ s/\+//;
            $hrdrscore += ($val/2);
            if ($val =~ /-/) { $negpoints -= ($val/2); }
         } elsif (grep( /$attr/,@statlist )) {
            $val =~ s/\+//;
            $statscore += $val;
            if ($val =~ /-/) { $negpoints -= $val/2; }
         } else {
            $val =~ s/\+//;
            $hpmnmvscore += ($val/10);
            if ($val =~ /-/) { $negpoints -= $val/10; }
         }
      } else {
         my ($junk,$resist,$val) = split(/,/,$ot{$affect});
         $resists{$resist} = $val;
      }
   }
   if (exists $ot{"Wearable"}) {
      my ($maxpoints,$maxstat,$maxsaves,$maxhrdr,$maxhpmnmv,$maxneg) = getObjMaxPoints($key);
      if (($statscore) && ($statscore > $maxstat)) {
         print "\tWarning: Over max points from stats : $statscore out of possible $maxstat\n";
         $ot{"NeedsReview"} = 1;
      } elsif ($statscore) {print "\tPoints from stats : $statscore out of possible $maxstat\n";}
      if (($hrdrscore) && ($hrdrscore > $maxhrdr)) {
         print "\tWarning: Over max points from HR/DR : $hrdrscore out of possible $maxhrdr\n";
         $ot{"NeedsReview"} = 1;
      } elsif ($hrdrscore) {print "\tPoints from HR/DR : $hrdrscore out of possible $maxhrdr\n";}
      if (($hpmnmvscore) && ($hpmnmvscore > $maxhpmnmv)) {
         print "\tWarning: Over max points from HP/Mana/Moves : $hpmnmvscore out of possible $maxhpmnmv\n";
         $ot{"NeedsReview"} = 1;
      } elsif ($hpmnmvscore) {print "\tPoints from HP/Mana/Moves : $hpmnmvscore out of possible $maxhpmnmv\n";}
      if (($negpoints) && ($negpoints > $maxneg)) {
         print "\tWarning: Over max negative points : $negpoints out of possible $maxneg\n";
         $ot{"NeedsReview"} = 1;
      }
      elsif ($negpoints) {print "\tNegative points : $negpoints out of possible $maxneg\n";}
      

      my $totalpoints = $statscore + $hrdrscore + $hpmnmvscore;
      if ($totalpoints > $maxpoints) {
         print "\tWarning: Over max total points : $totalpoints out of possible $maxpoints\n";
         $ot{"NeedsReview"} = 1;
      }
      else {print "\tTotal points : $totalpoints out of possible $maxpoints\n";}
      calcItemQuality($totalpoints,$maxpoints);
      
      if ($statscore > (ceiling($totalpoints * .6))) {
         print "\tWarning: More than 60% of max points have been allocated to stats!\n";
         $ot{"NeedsReview"} = 1;
      }
      if ($hrdrscore > (ceiling($totalpoints * .6))) {
         print "\tWarning: More than 60% of max points have been allocated to HR/DR!\n";
         $ot{"NeedsReview"} = 1;
      }
      if ($hpmnmvscore > (ceiling($totalpoints * .6))) {
         print "\tWarning: More than 60% of max points have been allocated to HP/Mana/Moves!\n";
         $ot{"NeedsReview"} = 1;
      }

      
      my $resistsokay = 1;
      my $hasaddedresists = 0;
      foreach my $resist (keys(%resists)) {
         my ($maxallphys,$maxallmag) = getArmorResWeight($ot{"Level"},"resists");
         my $val = $resists{$resist};
         if ($ot{"Object Type"} ne "Armor") {
            print "\tWarning: Resist $resist of $val has been added to non-armor object.\n";
            $resistsokay = 0;
         }
         $val =~ s/\+//;
         my $addedresists = 0;
         if ($resist eq "Allphysical") {
            if ($val > $maxallphys) { 
               print "\tWarning: Resist AllPhysical is over max: $val vs maximum $maxallphys\n";
               $resistsokay = 0;
            }
         } elsif ($resist eq "Allmagic") {
            if ($val > $maxallmag) {
               print "\tWarning: Resist AllMagic is over max: $val vs maximum $maxallphys\n";
               $resistsokay = 0;
            }
         } else {
            print "\tWarning: Non-standard resist $resist of $val has been added to this object.\n";
            $resistsokay = 0;
            $addedresists += $val;
            $hasaddedresists = 1;
            # Keep track of how many objects have a positive resist of a given type.
            if (($val > 0) && (defined $addedresists{$resist})) {
               $addedresists{$resist} += 1;
            } elsif ($val > 0) {$addedresists{$resist} = 1;}
         }
      }
      if ($hasaddedresists) {$objaddedresists += 1;}
      if ($addedresists != 0) {"\tWarning: Extra resists do not have a +/- balancing to 0.";}
      if ($resistsokay) {print "\tObject resists are OK.\n";} else {$ot{"NeedsReview"} = 1;}
   }
   return $ot{"NeedsReview"};
}


sub calcItemQuality {
   my ($totalpoints,$maxpoints) = @_;
   if ($totalpoints > $maxpoints) {
      $objquality{"Masterpiece"} += 1;
      print "\tCalculated Object Quality: Masterpiece\n";
   } elsif ($totalpoints > ($maxpoints/2)) {
      $objquality{"Average"} += 1;
      print "\tCalculated Object Quality: Average\n";   
   } elsif ($totalpoints > 0) {
      $objquality{"Mediocre"} += 1;
      print "\tCalculated Object Quality: Mediocre\n";   
   } elsif ($totalpoints <= 0) {
      $objquality{"Bad"} += 1;
      print "\tCalculated Object Quality: Bad\n";   
   }
}



sub isDual {
   my ($key) = @_;
   my %ot = %{$obj{$key}};
   my (@wearable) = split(/,\ /,$ot{"Wearable"});
   my @duallocs = ("neck","ear","wrist","finger");
   foreach $dualloc (@duallocs) {
      if (grep( /$dualloc/, @wearable)) {
         print "\tItem is a dual location wearable: @wearable\n";
         return 1;
      }
   }
   print "\tItem is a single location wearable: @wearable\n";
   return 0;
}


sub checkWeaponDice {
   my ($key) = @_;
   my %ot = %{$obj{$key}};
   my $level = $ot{"Level"};
   my ($min,$max,$avg) = getWeaponwdice($level);
   if ($ot{"Avg Damage"} > $avg) {
      print "\tWarning: Average damage is higher than table values. Item average: ".$ot{"Avg Damage"}.". Avg for level: ".$avg."\n";
      return 1;
   }
   else {
      print "\tWeapon average damage is in spec.\n";
      return 0;
   }

}


sub checkObjWeightandValue {
   my ($key) = @_;
   my %ot = %{$obj{$key}};
   my $level = $ot{"Level"};
   my $weight = $ot{"Weight"};
   my $value = $ot{"Value"};
   my $overweight = 0;
   my $underweight = 0;
   my $minweight = 1;
   my $maxweight;
   my $maxvalue;
   if ($ot{"Object Type"} eq "Armor") {
      $maxweight = getArmorResWeight($level,"weight");
      $minweight = int($level/10);
      $maxvalue = $level * 50;
   }
   if ($ot{"Object Type"} eq "Boat") {
      $maxweight = 20;
      $minweight = int($level/10);
      $maxvalue = $level * 5;
   }
   if ($ot{"Object Type"} eq "Container") {
      $maxweight = int($level/2);
      $minweight = int($level/15);
      $maxvalue = $level * 10;
   }
   if ($ot{"Object Type"} eq "Drink") {
      $maxweight = int($level/2);
      $minweight = int($level/15);
      $maxvalue = $level * 10;
   }
   if ($ot{"Object Type"} eq "Food") {
      $maxweight = int($level/2);
      $minweight = 1;
      $maxvalue = $level * 2;
   }
   if ($ot{"Object Type"} eq "Furniture") {
      $maxweight = int($level/2);
      $minweight = int($level/20);
      $maxvalue = $level * 5;
   }
   if ($ot{"Object Type"} eq "Key") {
      $maxweight = int($level/2);
      $minweight = 1;
      $maxvalue = $level * 2;
   }
   if ($ot{"Object Type"} eq "Light") {
      $maxweight = int($level/2);
      $minweight = 1;
      $maxvalue = $level * 4;
   }
   if ($ot{"Object Type"} eq "Map") {
      $maxweight = int($level/2);
      $minweight = 1;
      $maxvalue = $level;
   }
   if ($ot{"Object Type"} eq "Pill") {
      $maxweight = int($level/2);
      $minweight = 1;
      $maxvalue = $level * 4;
   }
   if ($ot{"Object Type"} eq "Portal") {
      $maxweight = $level;
      $minweight = 1;
      $maxvalue = $level * 6;
   }
   if ($ot{"Object Type"} eq "Potion") {
      $maxweight = int($level/2);
      $minweight = 1;
      $maxvalue = $level * 6;
   }
   if ($ot{"Object Type"} eq "Scroll") {
      $maxweight = int($level/2);
      $minweight = 1;
      $maxvalue = $level * 6;
   }
   if ($ot{"Object Type"} eq "Staff") {
      $maxweight = int($level/2);
      $minweight = 1;
      $maxvalue = $level * 6;
   }
   if ($ot{"Object Type"} eq "Trash") {
      $maxweight = int($level/3);
      $minweight = 1;
      $maxvalue = $level * 2;
   }
   if ($ot{"Object Type"} eq "Treasure") {
      $maxweight = int($level/2);
      $minweight = 1;
      $maxvalue = $level * 6;
   }
   if ($ot{"Object Type"} eq "Wand") {
      $maxweight = int($level/3);
      $minweight = 1;
      $maxvalue = $level * 6;
   }
   if ($ot{"Object Type"} eq "Weapon") {
      $maxweight = int($level/3);
      $minweight = 1;
      $maxvalue = $level * 15;
   }



   if ($minweight == 0) {$minweight = 1;}
   my $return = 0;
   if ($weight > $maxweight) {
      print "\tWarning: Item is overweight. Weight: $weight vs Max: $maxweight\n";
      $return = 1;
   }
   elsif ($weight < $minweight) {
      print "\tWarning: Item is underweight. Weight: $weight vs Min: $minweight\n";
      $return = 1;
   }
   else {print "\tWeight is OK.\n"}
   if ($value > $maxvalue) {
      print "\tWarning: Item is over valued. Value: $value vs Max: $maxvalue\n";
      $return = 1;
   }
   else {print "\tValue is OK.\n"}
   return $return;
}

sub ceiling {
	my ($num) = @_;
	return int($num+0.99);
}

sub showUsage {
   print "Usage:\n";
   print "perl area_diff.pl <area> <port>\n\n";
   print "Port would be: main or test.\n";
}

sub getObjMaxPoints {
   my $optable = <<'END_TABLE';
1 1.0 1 1.0 1.0 1.0 0 1.0 1 1.0 1.0 1.0 0
2 1.0 1 1.0 1.0 1.0 0 1.0 1 1.0 1.0 1.0 0
3 1.0 1 1.0 1.0 1.0 0 1.0 1 1.0 1.0 1.0 0
4 1.0 1 1.0 1.0 1.0 0 1.0 1 1.0 1.0 1.0 0
5 1.0 1 1.0 1.0 1.0 0 1.0 1 1.0 1.0 1.0 0
6 2.0 1 1.0 1.0 1.0 0 1.0 1 1.0 1.0 1.0 0
7 2.0 1 1.0 1.0 1.0 0 1.0 1 1.0 1.0 1.0 0
8 2.0 1 1.0 1.0 1.0 0 1.0 1 1.0 1.0 1.0 0
9 2.0 1 1.0 1.0 1.0 0 1.0 1 1.0 1.0 1.0 0
10 2.0 1 1.0 1.0 1.0 0 1.0 1 1.0 1.0 1.0 0
11 2.0 1 1.0 1.0 1.1 0 1.5 1 1.0 1.0 1.0 0
12 2.0 1 1.0 1.0 1.2 0 1.5 1 1.0 1.0 1.0 0
13 2.0 1 1.0 1.0 1.3 0 1.5 1 1.0 1.0 1.0 0
14 2.0 1 1.0 1.0 1.4 0 1.5 1 1.0 1.0 1.1 0
15 2.0 1 1.0 1.0 1.5 0 1.5 1 1.0 1.0 1.1 0
16 3.0 1 1.0 1.0 1.6 0 2.0 1 1.0 1.0 1.2 0
17 3.0 1 1.0 1.0 1.7 0 2.0 1 1.0 1.0 1.3 0
18 3.0 1 1.0 1.0 1.8 0 2.0 1 1.0 1.0 1.4 0
19 3.0 1 1.0 1.0 1.9 0 2.0 1 1.0 1.0 1.4 0
20 3.0 1 1.0 1.0 2.0 2 2.0 1 1.0 1.0 1.5 0
21 3.0 2 1.0 1.0 2.1 2 2.0 2 1.0 1.0 1.6 0
22 3.0 2 1.0 1.0 2.2 2 2.0 2 1.0 1.0 1.7 0
23 3.0 2 1.0 1.0 2.3 2 2.0 2 1.0 1.0 1.7 0
24 3.0 2 1.0 1.0 2.4 2 2.0 2 1.0 1.0 1.8 0
25 3.0 2 1.0 1.0 2.5 2 2.0 2 1.0 1.0 1.9 0
26 4.0 2 1.0 1.0 2.6 2 3.0 2 1.0 1.0 2.0 0
27 4.0 2 1.0 1.0 2.7 2 3.0 2 1.0 1.0 2.0 2
28 4.0 2 1.0 1.0 2.8 2 3.0 2 1.0 1.0 2.1 2
29 4.0 2 1.0 1.0 2.9 2 3.0 2 1.0 1.0 2.2 2
30 4.0 3 1.5 1.5 3.0 3 3.0 2 1.0 1.0 2.3 2
31 4.0 3 1.5 1.5 3.1 3 3.0 2 1.0 1.0 2.3 2
32 4.0 3 1.5 1.5 3.2 3 3.0 2 1.0 1.0 2.4 2
33 4.0 3 1.5 1.5 3.3 3 3.0 2 1.0 1.0 2.5 2
34 4.0 3 1.5 1.5 3.4 3 3.0 3 1.5 1.5 2.6 2
35 4.0 3 1.5 1.5 3.5 3 3.0 3 1.5 1.5 2.6 2
36 4.0 3 1.5 1.5 3.6 3 3.0 3 1.5 1.5 2.7 2
37 4.0 3 1.5 1.5 3.7 3 3.0 3 1.5 1.5 2.8 2
38 4.0 3 1.5 1.5 3.8 3 3.0 3 1.5 1.5 2.9 2
39 4.0 3 1.5 1.5 3.9 3 3.0 3 1.5 1.5 2.9 2
40 4.0 4 2.0 2.0 4.0 4 3.0 3 1.5 1.5 3.0 3
41 6.0 4 2.0 2.0 4.1 4 4.5 3 1.5 1.5 3.1 3
42 6.0 4 2.0 2.0 4.2 4 4.5 3 1.5 1.5 3.2 3
43 6.0 4 2.0 2.0 4.3 4 4.5 3 1.5 1.5 3.2 3
44 6.0 4 2.0 2.0 4.4 4 4.5 3 1.5 1.5 3.3 3
45 6.0 4 2.0 2.0 4.5 4 4.5 3 1.5 1.5 3.4 3
46 6.0 4 2.0 2.0 4.6 4 4.5 3 1.5 1.5 3.5 3
47 6.0 4 2.0 2.0 4.7 4 4.5 4 2.0 2.0 3.5 3
48 6.0 4 2.0 2.0 4.8 4 4.5 4 2.0 2.0 3.6 3
49 6.0 4 2.0 2.0 4.9 4 4.5 4 2.0 2.0 3.7 3
50 6.0 5 2.5 2.5 5.0 5 4.5 4 2.0 2.0 3.8 3
51 6.0 5 2.5 2.5 5.1 5 4.5 4 2.0 2.0 3.8 3
52 6.0 5 2.5 2.5 5.2 5 4.5 4 2.0 2.0 3.9 3
53 6.0 5 2.5 2.5 5.3 5 4.5 4 2.0 2.0 4.0 3
54 6.0 5 2.5 2.5 5.4 5 4.5 4 2.0 2.0 4.1 4
55 6.0 5 2.5 2.5 5.5 5 4.5 4 2.0 2.0 4.1 4
56 7.0 5 2.5 2.5 5.6 5 5.0 4 2.0 2.0 4.2 4
57 7.0 5 2.5 2.5 5.7 5 5.0 4 2.0 2.0 4.3 4
58 7.0 5 2.5 2.5 5.8 5 5.0 4 2.0 2.0 4.4 4
59 7.0 5 2.5 2.5 5.9 5 5.0 4 2.0 2.0 4.4 4
60 7.0 6 3.0 3.0 6.0 6 5.0 5 2.5 2.5 4.5 4
61 7.0 6 3.0 3.0 6.1 6 5.0 5 2.5 2.5 4.6 4
62 7.0 6 3.0 3.0 6.2 6 5.0 5 2.5 2.5 4.7 4
63 7.0 6 3.0 3.0 6.3 6 5.0 5 2.5 2.5 4.7 4
64 7.0 6 3.0 3.0 6.4 6 5.0 5 2.5 2.5 4.8 4
65 7.0 6 3.0 3.0 6.5 6 5.0 5 2.5 2.5 4.9 4
66 7.0 6 3.0 3.0 6.6 6 5.0 5 2.5 2.5 5.0 4
67 7.0 6 3.0 3.0 6.7 6 5.0 5 2.5 2.5 5.0 5
68 7.0 6 3.0 3.0 6.8 6 5.0 5 2.5 2.5 5.1 5
69 7.0 6 3.0 3.0 6.9 6 5.0 5 2.5 2.5 5.2 5
70 7.0 7 3.5 3.5 7.0 7 5.0 5 2.5 2.5 5.3 5
71 8.0 7 3.5 3.5 7.1 7 6.0 5 2.5 2.5 5.3 5
72 8.0 7 3.5 3.5 7.2 7 6.0 5 2.5 2.5 5.4 5
73 8.0 7 3.5 3.5 7.3 7 6.0 5 2.5 2.5 5.5 5
74 8.0 7 3.5 3.5 7.4 7 6.0 6 3.0 3.0 5.6 5
75 8.0 7 3.5 3.5 7.5 7 6.0 6 3.0 3.0 5.6 5
76 8.0 7 3.5 3.5 7.6 7 6.0 6 3.0 3.0 5.7 5
77 8.0 7 3.5 3.5 7.7 7 6.0 6 3.0 3.0 5.8 5
78 8.0 7 3.5 3.5 7.8 7 6.0 6 3.0 3.0 5.9 5
79 8.0 7 3.5 3.5 7.9 7 6.0 6 3.0 3.0 5.9 6
80 8.0 8 4.0 4.0 8.0 8 6.0 6 3.0 3.0 6.0 6
81 9.0 8 4.0 4.0 8.1 8 6.5 6 3.0 3.0 6.1 6
82 9.0 8 4.0 4.0 8.2 8 6.5 6 3.0 3.0 6.2 6
83 9.0 8 4.0 4.0 8.3 8 6.5 6 3.0 3.0 6.2 6
84 9.0 8 4.0 4.0 8.4 8 6.5 6 3.0 3.0 6.3 6
85 9.0 8 4.0 4.0 8.5 8 6.5 6 3.0 3.0 6.4 6
86 9.0 8 4.0 4.0 8.6 8 6.5 6 3.0 3.0 6.5 6
87 9.0 8 4.0 4.0 8.7 8 7.0 7 3.5 3.5 6.5 6
88 9.0 8 4.0 4.0 8.8 8 7.0 7 3.5 3.5 6.6 6
89 9.0 8 4.0 4.0 8.9 8 7.0 7 3.5 3.5 6.7 6
90 9.0 9 4.5 4.5 9.0 9 7.0 7 3.5 3.5 6.8 6
91 12.0 9 4.5 4.5 9.1 9 9.0 7 3.5 3.5 6.8 6
92 12.0 9 4.5 4.5 9.2 9 9.0 7 3.5 3.5 6.9 6
93 12.0 9 4.5 4.5 9.3 9 9.0 7 3.5 3.5 7.0 6
94 12.0 9 4.5 4.5 9.4 9 9.0 7 3.5 3.5 7.1 7
95 12.0 9 4.5 4.5 9.5 9 9.0 7 3.5 3.5 7.1 7
96 12.0 9 4.5 4.5 9.6 9 9.0 7 3.5 3.5 7.2 7
97 12.0 9 4.5 4.5 9.7 9 9.0 7 3.5 3.5 7.3 7
98 12.0 9 4.5 4.5 9.8 9 9.0 7 3.5 3.5 7.4 7
99 12.0 9 4.5 4.5 9.9 9 9.0 7 3.5 3.5 7.4 7
100 12.0 10 5.0 5.0 10.0 10 9.0 8 4.0 4.0 7.5 7
101 14.0 10 5.0 5.0 10.1 10 10.5 8 4.0 4.0 7.6 7
102 14.0 10 5.0 5.0 10.2 10 10.5 8 4.0 4.0 7.7 7
103 14.0 10 5.0 5.0 10.3 10 10.5 8 4.0 4.0 7.7 7
104 14.0 10 5.0 5.0 10.4 10 10.5 8 4.0 4.0 7.8 7
105 14.0 10 5.0 5.0 10.5 10 10.5 8 4.0 4.0 7.9 7
106 14.0 10 5.0 5.0 10.6 10 10.5 8 4.0 4.0 8.0 7
107 14.0 10 5.0 5.0 10.7 10 10.5 8 4.0 4.0 8.0 8
108 14.0 10 5.0 5.0 10.8 10 10.5 8 4.0 4.0 8.1 8
109 14.0 10 5.0 5.0 10.9 10 10.5 8 4.0 4.0 8.2 8
110 14.0 11 5.5 5.5 11.0 11 10.5 8 4.0 4.0 8.3 8
111 16.0 11 5.5 5.5 11.1 11 12.0 8 4.0 4.0 8.3 8
112 16.0 11 5.5 5.5 11.2 11 12.0 8 4.0 4.0 8.4 8
113 16.0 11 5.5 5.5 11.3 11 12.0 8 4.0 4.0 8.5 8
114 16.0 11 5.5 5.5 11.4 11 12.0 9 4.5 4.5 8.6 8
115 16.0 11 5.5 5.5 11.5 11 12.0 9 4.5 4.5 8.6 8
116 16.0 11 5.5 5.5 11.6 11 12.0 9 4.5 4.5 8.7 8
117 16.0 11 5.5 5.5 11.7 11 12.0 9 4.5 4.5 8.8 8
118 16.0 11 5.5 5.5 11.8 11 12.0 9 4.5 4.5 8.9 8
119 16.0 11 5.5 5.5 11.9 11 12.0 9 4.5 4.5 8.9 8
120 16.0 12 6.0 6.0 12.0 12 12.0 9 4.5 4.5 9.0 9
121 18.0 12 6.0 6.0 12.1 12 13.5 9 4.5 4.5 9.1 9
122 18.0 12 6.0 6.0 12.2 12 13.5 9 4.5 4.5 9.2 9
123 18.0 12 6.0 6.0 12.3 12 13.5 9 4.5 4.5 9.2 9
124 18.0 12 6.0 6.0 12.4 12 13.5 9 4.5 4.5 9.3 9
125 18.0 12 6.0 6.0 12.5 12 13.5 9 4.5 4.5 9.4 9
126 18.0 12 6.0 6.0 12.6 12 13.5 9 4.5 4.5 9.5 9
127 18.0 12 6.0 6.0 12.7 12 13.5 10 5.0 5.0 9.5 9
128 18.0 12 6.0 6.0 12.8 12 13.5 10 5.0 5.0 9.6 9
129 18.0 12 6.0 6.0 12.9 12 13.5 10 5.0 5.0 9.7 9
130 18.0 13 6.5 6.5 13.0 13 13.5 10 5.0 5.0 9.8 9
131 20.0 13 6.5 6.5 13.1 13 15.0 10 5.0 5.0 9.8 9
132 20.0 13 6.5 6.5 13.2 13 15.0 10 5.0 5.0 9.9 9
133 20.0 13 6.5 6.5 13.3 13 15.0 10 5.0 5.0 10.0 9
134 20.0 13 6.5 6.5 13.4 13 15.0 10 5.0 5.0 10.1 10
135 20.0 13 6.5 6.5 13.5 13 15.0 10 5.0 5.0 10.1 10
136 20.0 13 6.5 6.5 13.6 13 15.0 10 5.0 5.0 10.2 10
137 20.0 13 6.5 6.5 13.7 13 15.0 10 5.0 5.0 10.3 10
138 20.0 13 6.5 6.5 13.8 13 15.0 10 5.0 5.0 10.4 10
139 20.0 13 6.5 6.5 13.9 13 15.0 10 5.0 5.0 10.4 10
140 20.0 14 7.0 7.0 14.0 14 15.0 11 5.5 5.5 10.5 10
141 22.0 14 7.0 7.0 14.1 14 16.5 11 5.5 5.5 10.6 10
142 22.0 14 7.0 7.0 14.2 14 16.5 11 5.5 5.5 10.7 10
143 22.0 14 7.0 7.0 14.3 14 16.5 11 5.5 5.5 10.7 10
144 22.0 14 7.0 7.0 14.4 14 16.5 11 5.5 5.5 10.8 10
145 22.0 14 7.0 7.0 14.5 14 16.5 11 5.5 5.5 10.9 10
146 22.0 14 7.0 7.0 14.6 14 16.5 11 5.5 5.5 11.0 11
147 22.0 14 7.0 7.0 14.7 14 16.5 11 5.5 5.5 11.0 11
148 22.0 14 7.0 7.0 14.8 14 16.5 11 5.5 5.5 11.1 11
149 22.0 14 7.0 7.0 14.9 14 16.5 11 5.5 5.5 11.2 11
150 22.0 15 7.5 7.5 15.0 15 16.5 11 5.5 5.5 11.3 11
151 24.0 15 7.5 7.5 15.1 15 18.0 11 5.5 5.5 11.3 11
152 24.0 15 7.5 7.5 15.2 15 18.0 11 5.5 5.5 11.4 11
153 24.0 15 7.5 7.5 15.3 15 18.0 11 5.5 5.5 11.5 11
154 24.0 15 7.5 7.5 15.4 15 18.0 12 6.0 6.0 11.6 11
155 24.0 15 7.5 7.5 15.5 15 18.0 12 6.0 6.0 11.6 11
156 24.0 15 7.5 7.5 15.6 15 18.0 12 6.0 6.0 11.7 11
157 24.0 15 7.5 7.5 15.7 15 18.0 12 6.0 6.0 11.8 11
158 24.0 15 7.5 7.5 15.8 15 18.0 12 6.0 6.0 11.9 11
159 24.0 15 7.5 7.5 15.9 15 18.0 12 6.0 6.0 11.9 11
160 24.0 16 8.0 8.0 16.0 16 18.0 12 6.0 6.0 12.0 12
161 26.0 16 8.0 8.0 16.1 16 19.5 12 6.0 6.0 12.1 12
162 26.0 16 8.0 8.0 16.2 16 19.5 12 6.0 6.0 12.2 12
163 26.0 16 8.0 8.0 16.3 16 19.5 12 6.0 6.0 12.2 12
164 26.0 16 8.0 8.0 16.4 16 19.5 12 6.0 6.0 12.3 12
165 26.0 16 8.0 8.0 16.5 16 19.5 12 6.0 6.0 12.4 12
166 26.0 16 8.0 8.0 16.6 16 19.5 12 6.0 6.0 12.5 12
167 26.0 16 8.0 8.0 16.7 16 19.5 13 6.5 6.5 12.5 12
168 26.0 16 8.0 8.0 16.8 16 19.5 13 6.5 6.5 12.6 12
169 26.0 16 8.0 8.0 16.9 16 19.5 13 6.5 6.5 12.7 12
170 26.0 17 8.5 8.5 17.0 17 19.5 13 6.5 6.5 12.8 12
171 28.0 17 8.5 8.5 17.1 17 21.0 13 6.5 6.5 12.8 12
172 28.0 17 8.5 8.5 17.2 17 21.0 13 6.5 6.5 12.9 12
173 28.0 17 8.5 8.5 17.3 17 21.0 13 6.5 6.5 13.0 13
174 28.0 17 8.5 8.5 17.4 17 21.0 13 6.5 6.5 13.1 13
175 28.0 17 8.5 8.5 17.5 17 21.0 13 6.5 6.5 13.1 13
176 28.0 17 8.5 8.5 17.6 17 21.0 13 6.5 6.5 13.2 13
177 28.0 17 8.5 8.5 17.7 17 21.0 13 6.5 6.5 13.3 13
178 28.0 17 8.5 8.5 17.8 17 21.0 13 6.5 6.5 13.4 13
179 28.0 17 8.5 8.5 17.9 17 21.0 13 6.5 6.5 13.4 13
180 28.0 18 9.0 9.0 18.0 18 21.0 14 7.0 7.0 13.5 13
181 30.0 18 9.0 9.0 18.1 18 22.5 14 7.0 7.0 13.6 13
182 30.0 18 9.0 9.0 18.2 18 22.5 14 7.0 7.0 13.7 13
183 30.0 18 9.0 9.0 18.3 18 22.5 14 7.0 7.0 13.7 13
184 30.0 18 9.0 9.0 18.4 18 22.5 14 7.0 7.0 13.8 13
185 30.0 18 9.0 9.0 18.5 18 22.5 14 7.0 7.0 13.9 13
186 30.0 18 9.0 9.0 18.6 18 22.5 14 7.0 7.0 14.0 14
187 30.0 18 9.0 9.0 18.7 18 22.5 14 7.0 7.0 14.0 14
188 30.0 18 9.0 9.0 18.8 18 22.5 14 7.0 7.0 14.1 14
189 30.0 18 9.0 9.0 18.9 18 22.5 14 7.0 7.0 14.2 14
190 30.0 19 9.5 9.5 19.0 19 22.5 14 7.0 7.0 14.3 14
191 30.0 19 9.5 9.5 19.1 19 22.5 14 7.0 7.0 14.3 14
192 30.0 19 9.5 9.5 19.2 19 22.5 14 7.0 7.0 14.4 14
193 30.0 19 9.5 9.5 19.3 19 22.5 14 7.0 7.0 14.5 14
194 30.0 19 9.5 9.5 19.4 19 22.5 15 7.5 7.5 14.6 14
195 30.0 19 9.5 9.5 19.5 19 22.5 15 7.5 7.5 14.6 14
196 35.0 19 9.5 9.5 19.6 19 26.0 15 7.5 7.5 14.7 14
197 35.0 19 9.5 9.5 19.7 19 26.0 15 7.5 7.5 14.8 14
198 35.0 19 9.5 9.5 19.8 19 26.0 15 7.5 7.5 14.9 14
199 35.0 19 9.5 9.5 19.9 19 26.0 15 7.5 7.5 14.9 14
200 35.0 20 10.0 10.0 20.0 20 26.0 15 7.5 7.5 15.0 15
201 35.0 20 10.0 10.0 20.1 20 26.0 15 7.5 7.5 15.1 15
202 36.0 22 11.0 12.0 20.2 20 27.0 17 8.5 8.5 15.2 15
203 36.0 22 11.0 12.0 20.3 20 27.0 17 8.5 8.5 15.3 15
204 36.0 22 11.0 12.0 20.4 20 27.0 17 8.5 8.5 15.3 15
205 36.0 22 11.0 12.0 20.5 20 27.0 17 8.5 8.5 15.4 15
206 36.0 22 11.0 12.0 20.6 20 27.0 17 8.5 8.5 15.5 15
207 36.0 22 11.0 12.0 20.7 20 27.0 17 8.5 8.5 15.6 15
208 36.0 22 11.0 12.0 20.8 20 27.0 17 8.5 8.5 15.6 15
209 36.0 22 11.0 12.0 20.9 20 27.0 17 8.5 8.5 15.6 15
210 36.0 22 11.0 12.0 21.0 20 27.0 17 8.5 8.5 15.6 15
211 38.0 24 12.0 12.0 21.1 20 28.0 18 9.0 9.0 15.9 15
212 38.0 24 12.0 12.0 21.2 20 28.0 18 9.0 9.0 16.0 15
213 38.0 24 12.0 12.0 21.3 20 28.0 18 9.0 9.0 16.1 15
214 38.0 24 12.0 12.0 21.4 20 28.0 18 9.0 9.0 16.2 15
215 38.0 24 12.0 12.0 21.5 20 28.0 18 9.0 9.0 16.3 15
216 38.0 24 12.0 12.0 21.6 20 28.0 18 9.0 9.0 16.4 15
217 38.0 24 12.0 12.0 21.7 20 28.0 18 9.0 9.0 16.4 15
218 38.0 24 12.0 12.0 21.8 20 28.0 18 9.0 9.0 16.4 15
219 38.0 24 12.0 12.0 21.9 20 28.0 18 9.0 9.0 16.5 15
220 38.0 24 12.0 12.0 22.0 20 28.0 18 9.0 9.0 16.5 15
221 40.0 26 13.0 13.0 22.1 20 29.0 20 10.0 10.0 16.5 15
222 40.0 26 13.0 13.0 22.2 20 29.0 20 10.0 10.0 16.6 15
223 40.0 26 13.0 13.0 22.3 20 29.0 20 10.0 10.0 16.7 15
224 40.0 26 13.0 13.0 22.4 20 29.0 20 10.0 10.0 16.8 15
225 40.0 26 13.0 13.0 22.5 20 29.0 20 10.0 10.0 16.8 15
226 40.0 26 13.0 13.0 22.6 20 29.0 20 10.0 10.0 16.9 15
227 40.0 26 13.0 13.0 22.7 20 29.0 20 10.0 10.0 17.0 15
228 40.0 26 13.0 13.0 22.8 20 29.0 20 10.0 10.0 17.1 15
229 40.0 26 13.0 13.0 22.9 20 29.0 20 10.0 10.0 17.2 15
230 42.0 28 14.0 14.0 23.0 20 30.0 22 11.0 11.0 17.3 15
231 42.0 28 14.0 14.0 23.1 20 30.0 22 11.0 11.0 17.4 15
232 42.0 28 14.0 14.0 23.2 20 30.0 22 11.0 11.0 17.5 15
233 42.0 28 14.0 14.0 23.3 20 30.0 22 11.0 11.0 17.5 15
234 42.0 28 14.0 14.0 23.4 20 30.0 22 11.0 11.0 17.6 15
235 42.0 28 14.0 14.0 23.5 20 30.0 22 11.0 11.0 17.7 15
236 42.0 28 14.0 14.0 23.6 20 30.0 22 11.0 11.0 17.7 15
237 42.0 28 14.0 14.0 23.7 20 30.0 22 11.0 11.0 17.8 15
238 42.0 28 14.0 14.0 23.8 20 30.0 22 11.0 11.0 17.9 15
239 42.0 28 14.0 14.0 23.9 20 30.0 22 11.0 11.0 17.9 15
240 44.0 28 14.0 14.0 24.0 20 31.0 24 12.0 12.0 17.9 15
241 44.0 28 14.0 14.0 24.1 20 31.0 24 12.0 12.0 18.0 15
242 44.0 28 14.0 14.0 24.2 20 31.0 24 12.0 12.0 18.2 15
243 44.0 28 14.0 14.0 24.3 20 31.0 24 12.0 12.0 18.2 15
244 44.0 28 14.0 14.0 24.4 20 31.0 24 12.0 12.0 18.3 15
245 44.0 28 14.0 14.0 24.5 20 31.0 24 12.0 12.0 18.4 15
246 44.0 28 14.0 14.0 24.6 20 31.0 24 12.0 12.0 18.5 15
247 44.0 28 14.0 14.0 24.7 20 31.0 24 12.0 12.0 18.5 15
248 44.0 28 14.0 14.0 24.8 20 31.0 24 12.0 12.0 18.6 15
249 44.0 28 14.0 14.0 24.9 20 31.0 24 12.0 12.0 18.7 15
250 46.0 30 15.0 15.0 25.0 20 32.0 25 12.5 12.5 18.8 15
251 46.0 30 15.0 15.0 25.1 20 32.0 25 12.5 12.5 18.9 15
252 46.0 30 15.0 15.0 25.2 20 32.0 25 12.5 12.5 18.9 15
253 46.0 30 15.0 15.0 25.3 20 32.0 25 12.5 12.5 19.0 15
254 46.0 30 15.0 15.0 25.4 20 32.0 25 12.5 12.5 19.1 15
255 46.0 30 15.0 15.0 25.5 20 32.0 25 12.5 12.5 19.1 15
256 46.0 30 15.0 15.0 25.6 20 32.0 25 12.5 12.5 19.2 15
257 46.0 30 15.0 15.0 25.7 20 32.0 25 12.5 12.5 19.3 15
258 46.0 30 15.0 15.0 25.8 20 32.0 25 12.5 12.5 19.4 15
259 46.0 30 15.0 15.0 25.9 20 32.0 25 12.5 12.5 19.4 15
260 48.0 32 16.0 16.0 26.0 20 33.0 25 12.5 12.5 19.4 15
261 48.0 32 16.0 16.0 26.1 20 33.0 25 12.5 12.5 19.5 15
262 48.0 32 16.0 16.0 26.2 20 33.0 25 12.5 12.5 19.6 15
263 48.0 32 16.0 16.0 26.3 20 33.0 25 12.5 12.5 19.6 15
264 48.0 32 16.0 16.0 26.4 20 33.0 25 12.5 12.5 19.7 15
265 48.0 32 16.0 16.0 26.5 20 33.0 25 12.5 12.5 19.8 15
266 48.0 32 16.0 16.0 26.6 20 33.0 25 12.5 12.5 19.9 15
267 48.0 32 16.0 16.0 26.7 20 33.0 25 12.5 12.5 20.0 15
268 48.0 32 16.0 16.0 26.8 20 33.0 25 12.5 12.5 20.1 15
269 48.0 32 16.0 16.0 26.9 20 33.0 25 12.5 12.5 20.2 15
270 50.0 34 17.0 17.0 27.0 20 35.0 26 13.0 13.0 20.3 15
271 50.0 34 17.0 17.0 27.1 20 35.0 26 13.0 13.0 20.3 15
272 50.0 34 17.0 17.0 27.2 20 35.0 26 13.0 13.0 20.4 15
273 50.0 34 17.0 17.0 27.3 20 35.0 26 13.0 13.0 20.5 15
274 50.0 34 17.0 17.0 27.4 20 35.0 26 13.0 13.0 20.6 15
275 50.0 34 17.0 17.0 27.5 20 35.0 26 13.0 13.0 20.7 15
276 50.0 34 17.0 17.0 27.6 20 35.0 26 13.0 13.0 20.8 15
277 50.0 34 17.0 17.0 27.7 20 35.0 26 13.0 13.0 20.8 15
278 50.0 34 17.0 17.0 27.8 20 35.0 26 13.0 13.0 20.9 15
279 50.0 34 17.0 17.0 27.9 20 35.0 26 13.0 13.0 21.0 15
280 53.0 36 18.0 18.0 28.0 20 35.0 28 14.0 14.0 21.1 15
281 53.0 36 18.0 18.0 28.1 20 35.0 28 14.0 14.0 21.2 15
282 53.0 36 18.0 18.0 28.2 20 35.0 28 14.0 14.0 21.3 15
283 53.0 36 18.0 18.0 28.3 20 35.0 28 14.0 14.0 21.3 15
284 53.0 36 18.0 18.0 28.4 20 35.0 28 14.0 14.0 21.4 15
285 53.0 36 18.0 18.0 28.5 20 35.0 28 14.0 14.0 21.4 15
286 53.0 36 18.0 18.0 28.6 20 35.0 28 14.0 14.0 21.5 15
287 53.0 36 18.0 18.0 28.7 20 35.0 28 14.0 14.0 21.6 15
288 53.0 36 18.0 18.0 28.8 20 35.0 28 14.0 14.0 21.7 15
289 53.0 36 18.0 18.0 28.9 20 35.0 28 14.0 14.0 21.8 15
290 53.0 36 18.0 18.0 29.0 20 35.0 28 14.0 14.0 21.8 15
291 55.0 40 20.0 20.0 29.1 20 35.0 28 14.0 14.0 21.9 15
END_TABLE
   #Level  S-Pnts S-Stat S-Svs  S-Hrdr S-hp   S-Negall  D-Pnts D-Stat D-svs  D-hrdr D-hp   D-Negall
   my @table = split(/\n/,$optable);
   my ($key) = @_;
   my %ot = %{$obj{$key}};
   my $level = $ot{"Level"};
   my @match = grep(/^$level\ /,@table);
   my @points = split(/\s/,$match[0]);
   if (isDual($key)) { return splice(@points,7,6) }
   else { return splice(@points,1,6) }
}

sub getMobPoints {
   my $mptable = <<'END_TABLE';
1 1 1 2 6 1 2 2 21 0 5
2 1 1 2 15 1 2 2 22 1 5
3 2 3 5 24 1 2 3 23 2 5
4 3 5 8 34 1 2 3 24 2 5
5 5 8 12 42 2 4 6 25 2 5
6 11 18 26 52 2 4 6 26 3 13
7 18 29 41 63 2 5 8 27 3 13
8 25 41 58 74 2 5 8 28 4 13
9 30 50 71 79 2 6 10 29 4 13
10 22 36 52 103 2 6 10 30 5 13
11 23 37 53 106 2 6 10 31 5 30
12 24 40 57 117 2 6 10 32 6 30
13 35 57 81 129 2 6 10 33 7 30
14 36 59 83 145 3 9 15 34 7 30
15 47 77 109 161 3 9 15 35 8 30
16 50 82 116 180 3 9 15 36 8 30
17 63 104 146 200 3 9 15 37 9 30
18 66 110 155 222 4 12 20 38 9 30
19 82 136 191 238 4 14 24 39 9 30
20 98 163 229 250 4 12 20 40 10 30
21 103 171 240 266 4 12 20 41 10 60
22 108 179 251 282 4 12 20 42 11 60
23 113 187 263 298 4 12 20 43 11 60
24 132 220 309 314 5 15 25 44 11 60
25 138 229 321 330 5 18 30 45 11 60
26 143 238 334 346 5 18 30 46 12 60
27 165 274 384 362 5 18 30 47 12 60
28 171 284 398 376 5 18 30 48 13 60
29 177 294 412 398 5 18 30 49 14 60
30 186 309 433 416 5 18 30 50 15 60
31 195 324 454 430 5 18 30 51 15 120
32 207 344 482 450 5 18 30 52 16 120
33 222 369 517 470 5 20 35 53 16 120
34 234 389 545 490 5 20 35 54 17 120
35 252 419 587 510 5 20 35 55 17 120
36 267 444 622 530 5 20 35 56 18 120
37 279 464 650 550 5 20 35 57 18 120
38 291 484 678 570 5 23 40 58 19 120
39 297 494 692 592 5 23 40 59 19 120
40 303 504 706 600 5 23 40 60 20 120
41 348 579 811 630 5 23 40 61 20 240
42 372 619 867 660 5 23 40 62 21 240
43 390 649 909 690 5 23 40 63 21 240
44 408 679 951 720 5 23 40 64 22 240
45 426 709 993 750 5 23 40 65 22 240
46 444 739 1035 780 5 25 45 66 23 240
47 462 769 1077 810 5 25 45 67 23 240
48 480 799 1119 840 5 25 45 68 24 240
49 504 839 1175 880 5 25 45 69 24 240
50 528 879 1231 920 5 28 50 70 25 240
51 537 894 1252 928 5 28 50 71 25 600
52 546 909 1273 936 5 30 55 72 26 600
53 555 924 1294 944 5 30 55 73 26 600
54 564 939 1315 952 5 30 55 74 27 600
55 573 954 1336 960 6 36 66 75 27 600
56 579 964 1350 970 6 36 66 76 27 600
57 585 974 1364 978 6 36 66 77 28 600
58 585 974 1364 978 6 36 66 78 29 600
59 585 974 1364 986 6 39 72 79 29 600
60 591 984 1378 992 6 39 72 80 30 600
61 721 1202 1683 797 6 39 72 81 31 1200
62 710 1184 1658 915 6 39 72 82 32 1200
63 744 1239 1736 960 7 46 84 83 33 1200
64 757 1262 1767 1037 7 46 84 84 34 1200
65 792 1320 1849 1079 7 49 91 85 35 1200
66 806 1344 1882 1155 7 49 91 86 36 1200
67 839 1398 1958 1201 7 53 98 87 37 1200
68 852 1419 1988 1280 7 53 98 88 38 1200
69 856 1425 1996 1274 8 60 112 89 39 1200
70 891 1484 2079 1315 8 60 112 90 40 1200
71 905 1509 2113 1390 8 60 112 91 40 2400
72 922 1536 2151 1463 8 60 112 92 41 2400
73 989 1649 2309 1550 8 60 112 93 41 2400
74 1036 1726 2417 1673 8 64 120 94 42 2400
75 1105 1841 2577 1758 8 64 120 95 42 2400
76 1151 1917 2685 1882 9 72 135 96 42 2400
77 1220 2034 2848 1965 9 72 135 97 43 2400
78 1251 2085 2919 2064 9 77 144 98 43 2400
79 1306 2177 3048 2122 9 77 144 99 44 2400
80 1349 2248 3149 2151 9 77 144 100 45 2400
81 1363 2272 3181 2227 9 77 144 101 45 4200
82 1380 2299 3219 2300 9 77 144 102 46 4200
83 1421 2368 3316 2331 9 77 144 103 46 4200
84 1438 2397 3356 2402 9 77 144 104 47 4200
85 1480 2467 3454 2432 9 81 153 105 47 4200
86 1528 2546 3565 2553 9 81 153 106 48 4200
87 1601 2667 3735 2632 9 81 153 107 48 4200
88 1648 2747 3846 2752 10 95 180 108 49 4200
89 1723 2870 4019 2829 10 95 180 109 49 4200
90 1770 2949 4129 2850 10 95 180 110 50 4200
91 1814 3022 4232 2877 10 95 180 111 52 5400
92 1861 3101 4342 2898 10 95 180 112 55 5400
93 1905 3175 4445 2924 10 95 180 113 56 5400
94 1952 3254 4556 2945 10 95 180 114 60 5400
95 1997 3327 4659 2972 10 100 190 115 62 5400
96 2044 3407 4770 2992 10 100 190 116 65 5400
97 2089 3481 4873 3018 10 100 190 117 67 5400
98 2136 3560 4985 3039 10 105 200 118 70 5400
99 2181 3634 5088 3065 10 105 200 119 72 5400
100 2229 3714 5200 3085 10 105 200 120 75 5400
101 2300 3833 5366 3166 10 105 200 121 76 5750
102 2372 3952 5534 3247 10 105 200 122 78 5750
103 2437 4062 5687 3237 10 105 200 123 79 5750
104 2477 4127 5779 3272 10 110 210 124 81 5750
105 2543 4238 5933 3261 10 110 210 125 82 5750
106 2583 4304 6027 3295 10 110 210 126 84 5750
107 2650 4416 6183 3283 11 121 231 127 85 5750
108 2690 4483 6277 3316 11 121 231 128 87 5750
109 2757 4595 6434 3304 11 127 242 129 89 5750
110 2825 4707 6591 3292 11 127 242 130 90 5750
111 2895 4825 6756 3374 11 127 242 131 90 6120
112 2966 4943 6921 3456 11 127 242 132 91 6120
113 3064 5107 7150 3492 11 127 242 133 91 6120
114 3136 5226 7317 3573 11 132 253 134 92 6120
115 3235 5392 7549 3607 11 132 253 135 92 6120
116 3271 5452 7633 3647 11 132 253 136 93 6120
117 3335 5558 7782 3641 12 144 276 137 93 6120
118 3372 5619 7868 3680 12 144 276 138 94 6120
119 3436 5726 8017 3673 12 150 288 139 94 6120
120 3537 5894 8253 3705 12 150 288 140 95 6120
121 3609 6015 8422 3784 12 150 288 141 95 6480
122 3682 6136 8591 3863 12 150 288 142 96 6480
123 3746 6243 8741 3856 12 150 288 143 96 6480
124 3782 6303 8825 3896 12 156 300 144 97 6480
125 3846 6410 8974 3889 12 156 300 145 97 6480
126 3882 6470 9059 3929 12 156 300 146 98 6480
127 3947 6577 9209 3922 13 169 325 147 98 6480
128 3983 6638 9294 3961 13 169 325 148 99 6480
129 4045 6741 9438 3958 13 176 338 149 99 6480
130 4112 6853 9594 3946 13 176 338 150 100 6480
131 4149 6914 9680 3985 13 176 338 151 102 6840
132 4186 6976 9767 4023 13 176 338 152 104 6840
133 4250 7083 9917 4016 13 182 351 153 106 6840
134 4287 7145 10004 4054 13 182 351 154 108 6840
135 4352 7253 10155 4046 13 182 351 155 110 6840
136 4390 7315 10242 4084 14 196 378 156 112 6840
137 4454 7423 10393 4076 14 196 378 157 114 6840
138 4492 7486 10481 4113 14 203 392 158 116 6840
139 4557 7594 10633 4105 14 203 392 159 118 6840
140 4622 7702 10784 4097 14 203 392 160 120 6840
141 4660 7766 10873 4133 14 203 392 161 121 7200
142 4698 7829 10961 4170 14 203 392 162 122 7200
143 4763 7937 11113 4162 14 210 406 163 123 7200
144 4801 8001 11202 4198 14 210 406 164 124 7200
145 4866 8110 11354 4189 14 210 406 165 125 7200
146 4905 8174 11444 4225 15 225 435 166 126 7200
147 4970 8283 11596 4216 15 225 435 167 127 7200
148 5009 8347 11687 4252 15 233 450 168 128 7200
149 5074 8456 11839 4243 15 233 450 169 129 7200
150 5139 8565 11991 4234 15 233 450 170 130 7200
151 5183 8638 12093 4261 15 233 450 171 130 7560
152 5231 8718 12206 4281 15 233 450 172 131 7560
153 5301 8835 12370 4264 15 233 450 173 131 7560
154 5350 8916 12483 4283 15 240 465 174 131 7560
155 5510 9183 12857 4116 15 240 465 175 132 7560
156 5559 9265 12971 4134 15 240 465 176 132 7560
157 5629 9382 13135 4117 15 240 465 177 133 7560
158 5678 9464 13250 4135 15 248 480 178 134 7560
159 5749 9580 13413 4119 15 248 480 179 134 7560
160 5733 9555 13378 4244 15 248 480 180 135 7560
161 5774 9622 13472 4277 15 248 480 181 135 7920
162 5814 9689 13565 4310 15 248 480 182 136 7920
163 5880 9799 13719 4300 15 248 480 183 136 7920
164 5920 9866 13813 4333 15 248 480 184 137 7920
165 5986 9976 13966 4323 15 255 495 185 137 7920
166 6026 10043 14061 4356 15 255 495 186 137 7920
167 6092 10153 14215 4346 16 272 528 187 138 7920
168 6133 10221 14310 4378 16 272 528 188 137 7920
169 6199 10330 14463 4369 16 280 544 189 139 7920
170 6264 10440 14616 4359 16 280 544 190 140 7920
171 6305 10508 14712 4391 16 280 544 191 140 8400
172 6351 10585 14819 4414 16 280 544 192 141 8400
173 6417 10694 14973 4405 16 280 544 193 142 8400
174 6463 10771 15080 4428 16 280 544 194 142 8400
175 6529 10881 15234 4418 16 288 560 195 142 8400
176 6575 10957 15341 4442 16 288 560 196 143 8400
177 6616 11026 15438 4473 17 306 595 197 143 8400
178 6687 11144 15603 4455 17 306 595 198 144 8400
179 6796 11326 15857 4473 17 315 612 199 144 8400
180 6910 11516 16123 4483 17 315 612 200 145 8400
181 6973 11621 16271 4528 17 315 612 201 146 9000
182 7061 11768 16476 4531 17 315 612 202 148 9000
183 7125 11874 16624 4575 17 323 629 203 149 9000
184 7213 12021 16830 4578 17 323 629 204 151 9000
185 7277 12127 16979 4622 18 342 666 205 152 9000
186 7365 12274 17185 4625 18 351 684 206 154 9000
187 7429 12381 17334 4668 18 351 684 207 155 9000
188 7517 12528 17540 4671 18 360 702 208 156 9000
189 7603 12672 17741 4727 19 380 741 209 158 9000
190 7714 12856 18000 4743 19 390 760 210 160 9000
191 7799 12998 18198 4801 19 390 760 211 162 9600
192 7865 13107 18351 4792 19 390 760 212 164 9600
193 7994 13323 18652 4876 19 390 760 213 166 9600
194 8148 13580 19012 4919 19 390 760 214 168 9600
195 8277 13795 19314 5004 19 390 760 215 170 9600
196 8432 14053 19675 5046 19 390 760 216 172 9600
197 8562 14269 19978 5130 20 410 800 217 174 9600
198 8718 14529 20341 5170 20 410 800 218 176 9600
199 8892 14819 20747 5280 20 410 800 219 178 9600
200 9137 15227 21319 5372 20 410 800 220 180 9600
201 9356 15592 21830 5507 21 431 840 221 182 9600
202 9647 16077 22509 5622 21 431 840 222 184 9600
203 9866 16443 23020 5756 21 431 840 223 186 9600
204 10114 16855 23598 5844 22 451 880 224 188 9600
205 10244 17073 23903 5926 22 451 880 225 190 9600
206 10493 17488 24484 6011 22 462 902 226 192 9600
207 10713 17855 24998 6144 22 462 902 227 194 9600
208 10963 18272 25581 6227 22 462 902 228 196 9600
209 11184 18639 26096 6360 22 462 902 229 198 9600
210 11435 19058 26682 6441 23 483 943 230 200 9600
211 11664 19440 27217 6559 23 483 943 231 202 9600
212 11909 19847 27787 6652 23 483 943 232 204 9600
213 12122 20203 28285 6796 23 495 966 233 206 9600
214 12278 20462 28648 6837 23 495 966 234 208 9600
215 12401 20668 28936 6931 23 495 966 235 210 9600
216 12557 20928 29300 6971 24 516 1008 236 212 10500
217 12681 21134 29589 7065 24 516 1008 237 214 10500
218 12837 21395 29953 7104 24 516 1008 238 216 10500
219 12961 21602 30243 7197 24 528 1032 239 218 10500
220 13163 21938 30714 7261 24 528 1032 240 220 10500
221 13287 22145 31003 7354 24 528 1032 241 222 10500
222 13535 22557 31581 7442 25 550 1075 242 224 10500
223 13659 22764 31871 7535 25 550 1075 243 226 10500
224 13817 23027 32239 7572 25 550 1075 244 228 10500
225 13941 23235 32529 7664 25 563 1100 245 230 10500
226 14099 23498 32899 7701 25 563 1100 246 232 10500
227 14224 23706 33189 7793 25 563 1100 247 234 10500
228 14383 23971 33559 7828 26 585 1144 248 236 10500
229 14553 24254 33956 7945 26 585 1144 249 238 10500
230 14712 24519 34328 7980 26 585 1144 250 240 10500
231 14837 24727 34619 8072 26 598 1170 251 242 10500
232 14996 24993 34991 8106 26 598 1170 252 244 10500
233 15121 25202 35283 8197 26 598 1170 253 246 10500
234 15281 25469 35657 8230 27 621 1215 254 248 10500
235 15407 25677 35949 8322 27 621 1215 255 250 10500
236 15567 25945 36323 8354 27 621 1215 256 252 11500
237 15692 26154 36616 8445 27 635 1242 257 254 11500
238 15853 26422 36991 8477 27 635 1242 258 256 11500
239 15979 26631 37284 8568 27 635 1242 259 258 11500
240 16140 26900 37660 8599 28 658 1288 260 260 11500
241 16311 27185 38060 8714 28 658 1288 261 262 11500
242 16473 27455 38437 8744 28 658 1288 262 264 11500
243 16599 27665 38731 8834 28 672 1316 263 266 11500
244 16852 28087 39322 8912 28 672 1316 264 268 11500
245 17069 28448 39828 9051 28 672 1316 265 270 11500
246 17323 28872 40421 9127 29 696 1363 266 272 11500
247 17578 29296 41014 9203 29 696 1363 267 274 11500
248 17795 29658 41522 9341 29 696 1363 268 276 11500
249 18050 30083 42117 9416 29 711 1392 269 278 11500
250 18306 30509 42713 9490 29 711 1392 270 280 11500
END_TABLE
   #Level  Hp Min Hp Avg Hp Max Hp Add Dm Min Dm Avg Dm Max DR    HR    Gold
   my ($level) = @_;
   my @table = split(/\n/,$mptable);
   my @match = grep(/^$level\ /,@table);
   my @data = split(/\s/,$match[0]);
   shift @data;
   return @data;
}

sub getArmorResWeight {
   my ($level,$lookup) = @_;
   my $artable=<<'END_TABLE';
1-11 0 0 1
12-14 0 0 2
15-17 1 0 2
18-19 1 0 3
20-23 1 1 3
24-29 1 1 4
30-32 1 1 5
33-35 2 1 5
36-43 2 1 6
44-47 2 2 7
48-50 2 2 8
51-53 3 2 8
54-59 3 2 9
60-62 3 3 10
63-65 4 3 10
66-71 4 3 11
72-80 4 3 12
81-83 5 3 13
84-89 5 4 14
90-95 5 4 15
96-98 5 4 16
99-101 6 4 16
102-107 6 4 17
108-113 6 5 18
114-116 6 5 19
117-119 7 5 19
120-125 7 5 20
126-131 7 5 21
132-134 7 6 22
135-137 8 6 22
138-143 8 6 23
144-149 8 6 24
150-153 8 6 25
154-155 9 6 25
156-161 9 7 26
162-167 9 7 27
168-170 9 7 28
171-173 10 7 28
174-178 10 7 29
179-179 10 7 30
180-184 10 8 30
185-188 10 8 31
189-190 11 8 31
191-197 11 8 32
198-201 11 8 33
END_TABLE

   my @artable = split(/\n/,$artable);
   foreach $arline (@artable) {
      my ($levelrange,$allphys,$allmag,$maxweight) = split(/\s+/,$arline);
      my ($minlevel,$maxlevel) = split(/-/,$levelrange);
      if (($level >= $minlevel) && ($level <= $maxlevel)) {
         if ($lookup eq "weight") { return $maxweight; }
         elsif ($lookup eq "resists") { return ($allphys,$allmag);}
      }
   }
}

sub getWeaponwdice {
   my ($level) = @_;
   my $wdice=<<'END_TABLE';
1 3 5 4
2 3 5 4
3 3 5 4
4 3 9 6
5 3 9 6
6 3 11 7
7 3 11 7
8 6 12 9
9 6 12 9
10 4 16 10
11 4 16 10
12 5 19 12
13 5 23 14
14 5 27 16
15 7 29 18
16 8 32 20
17 6 38 22
18 8 40 24
19 9 43 26
20 7 49 28
21 12 48 30
22 12 50 31
23 11 53 32
24 13 53 33
25 14 54 34
26 14 58 36
27 15 61 38
28 11 65 38
29 11 69 40
30 9 71 40
31 11 74 42
32 8 76 42
33 11 77 44
34 13 75 44
35 10 82 46
36 12 81 46
37 12 84 48
38 11 89 50
39 12 92 52
40 10 98 54
41 10 102 56
42 12 104 58
43 13 107 60
44 10 114 62
45 13 115 64
46 12 120 66
47 19 117 68
48 11 129 70
49 18 126 72
50 13 135 74
51 15 137 76
52 12 144 78
53 12 148 80
54 14 150 82
55 14 154 84
56 16 156 86
57 13 163 88
58 13 167 90
59 20 164 92
60 21 167 94
61 16 176 96
62 18 178 98
63 14 186 100
64 15 189 102
65 21 187 104
66 21 191 106
67 18 198 108
68 18 202 110
69 15 209 112
70 15 213 114
71 23 209 116
72 21 215 118
73 20 220 120
74 20 224 122
75 25 223 124
76 23 229 126
77 16 240 128
78 17 243 130
79 26 236 131
80 24 240 132
81 24 244 134
82 19 251 135
83 13 261 137
84 11 269 140
85 11 273 142
86 22 266 144
87 21 269 145
88 21 279 150
89 18 292 155
90 10 310 160
91 12 318 165
92 10 330 170
93 19 331 175
94 11 349 180
95 12 358 185
96 20 360 190
97 21 369 195
98 11 389 200
99 11 399 205
100 11 409 210
101 11 419 215
102 12 428 220
103 12 434 223
104 11 439 225
105 11 443 227
106 10 450 230
107 10 454 232
108 10 460 235
109 12 462 237
110 12 468 240
111 12 472 242
112 12 478 245
113 13 481 247
114 13 487 250
115 23 483 253
116 23 487 255
117 10 504 257
118 10 510 260
119 23 513 268
120 23 517 270
121 10 534 272
122 10 540 275
123 12 542 277
124 12 548 280
125 25 539 282
126 25 545 285
127 12 562 287
128 12 568 290
129 11 573 292
130 11 579 295
131 26 564 295
132 26 570 298
133 16 584 300
134 16 588 302
135 15 595 305
136 15 599 307
137 18 602 310
138 18 608 313
139 13 617 315
140 13 621 317
141 18 622 320
142 18 626 322
143 22 628 325
144 23 631 327
145 21 639 330
146 21 643 332
147 27 643 335
148 27 647 337
149 21 659 340
150 21 665 343
151 25 665 345
152 25 675 350
153 21 683 352
154 22 688 355
155 25 689 357
156 25 695 360
157 21 705 363
158 21 709 365
159 24 710 367
160 24 716 370
161 23 721 372
162 23 727 375
163 22 732 377
164 22 738 380
165 27 737 382
166 27 723 385
167 30 744 387
168 30 750 390
169 25 761 393
170 25 765 395
171 22 772 397
172 22 778 400
173 27 779 403
174 27 783 405
175 25 789 407
176 25 795 410
177 31 795 413
178 31 799 415
179 25 809 417
180 25 815 420
181 25 821 423
182 25 825 425
183 29 825 427
184 30 830 430
185 32 832 432
186 32 838 435
187 27 849 438
188 28 853 440
189 24 862 443
190 24 866 445
191 30 864 447
192 30 870 450
193 27 875 451
194 27 879 453
195 28 882 455
196 29 885 457
197 31 887 459
198 31 891 461
199 28 898 463
200 28 912 470
201 24 926 475
END_TABLE
   my @wdice = split(/\n/,$wdice);
   foreach $wline (@wdice) {
      my ($reclevel,$min,$max,$avg) = split(/\s/,$wline);
      if ($level == $reclevel) {return ($min,$max,$avg);}
   }
}