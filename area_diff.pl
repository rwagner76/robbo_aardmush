use List::Compare;

if ($#ARGV != 1) {showUsage();}
my $area = $ARGV[0];
my $type = $ARGV[1];

$mainfile = $area."_".$type."Data_main.tsv";
$testfile = $area."_".$type."Data_test.tsv";

open(FILE,"<$mainfile") || die("Can't find file $mainfile");
@lines = <FILE>;
close FILE;
chomp @lines;
foreach $line (@lines) {
   ($key,$attrib,$value) = split("\t",$line);
   push @keys, $key;
   $main{$key}{$attrib} = $value;
}

open(FILE,"<$testfile") || die("Can't find file $testfile");
@lines = <FILE>;
close FILE;
chomp @lines;
foreach $line (@lines) {
   ($key,$attrib,$value) = split("\t",$line);
   push @keys, $key;
   $test{$key}{$attrib} = $value;
}

my @mainkeys = sort(keys(%main));
my @testkeys = sort(keys(%test));
my $lc = List::Compare->new(\@mainkeys,\@testkeys);
my @mainonly = $lc->get_unique;
my @testonly = $lc->get_complement;
my @inboth = $lc->get_intersection;
foreach $key (@mainonly) {print "Warning: object $key only exists in main port list. Cannot compare $type.\n";}
foreach $key (@testonly) {print "Warning: object $key only exists in test port list. Cannot compare $type.\n";}

foreach $key (@inboth) {
   %ma = %{$main{$key}};
   %ta = %{$test{$key}};
   @mainattribs = sort(keys(%ma));
   @testattribs = sort(keys(%ta));
   my $ac = List::Compare->new(\@mainattribs,\@testattribs);
   @amainonly = $ac->get_unique;
   @atestonly = $ac->get_complement;
   @ainboth = $ac->get_intersection;
   foreach $attrib (@amainonly) {
      $mval = $main{$key}{$attrib};
      print "Warning: attribute $attrib for $key only exists in main port data. Value: $mval.\n";
   }
   foreach $attrib (@atestonly) {
      $tval = $main{$key}{$attrib};
      print "Warning: attribute $attrib for $key only exists in test port data. Value: $tval.\n";
   }
   foreach $attrib (@ainboth) {
      #print "Checking $attrib on $key\n";
      $mval = $ma{$attrib};
      $tval = $ta{$attrib};
      if ($mval ne $tval) {
         print "$key attribute $attrib differs:\n\tTEST: $tval\n\tMAIN: $mval\n";
      } else {
      	 #print "$key attribute $attrib check:\n\tTEST: $tval\n\tMAIN: $mval\n";
      }
   }
}

sub showUsage() {
	 print "Usage:\n";
	 print "perl area_diff.pl <area> <type>\n\n";
	 print "Types would be: redit, medit, or oedit\n";
	
	
}