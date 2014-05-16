#!/usr/bin/perl -w
use strict;
use Getopt::Long;

my $domain = '';
my $ttl = 60;
my $type = 'A';
my $ip_address = '';
my $comment = '';
my $output= '/tmp/dns-updater.xml';
my $zone_id = '';
my $account = '';
my $tracker_file = './ip-tracker.txt';

GetOptions ( 	"domain=s" => \$domain,
		"ttl:i" => \$ttl,
		"type:s" => \$type,
		"zoneid=s" => \$zone_id,
		"comment:s" => \$comment,
		"account=s" => \$account)
or die("Error in command line arguments\n"); 

sub did_ip_change {
	my ($ip) = shift @_;
	my $changed = 0;
		
	my $old_ip = `cat $tracker_file`;
	
	if ($old_ip ne $ip) {
		open (my $fh, ">", $tracker_file);
		print $fh $ip;
		close $fh;

		$changed = 1;
	}
	
	return $changed; 
}

if ($domain && $zone_id && $account) {

	chomp ($ip_address = `wget -q -O - checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*//'`);	
	my $ip_changed = did_ip_change($ip_address);
		
	if ($ip_address) {

		exit unless $ip_changed;
		my $xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<ChangeResourceRecordSetsRequest xmlns=\"https://route53.amazonaws.com/doc/2013-04-01/\">
<ChangeBatch>
   <Comment>$comment</Comment>
   <Changes>
      <Change>
         <Action>UPSERT</Action>
         <ResourceRecordSet>
            <Name>$domain</Name>
            <Type>$type</Type>
            <TTL>$ttl</TTL>
            <ResourceRecords>
               <ResourceRecord>
                  <Value>$ip_address</Value>
               </ResourceRecord>
            </ResourceRecords>
         </ResourceRecordSet>
      </Change>
   </Changes>
</ChangeBatch>
</ChangeResourceRecordSetsRequest>";

		#write xml file to disk
		open (my $fh, ">", $output);
		print $fh $xml;
		close($fh); 
	
		#push to AWS 
		system("perl dnscurl.pl --keyname $account -- -X POST -H \"Content-Type: text/xml; charset=UTF-8\" --upload-file $output https://route53.amazonaws.com/2013-04-01/hostedzone/$zone_id/rrset");
		
		#remove output
		unlink $output;
	} else {
		print "Unable to determine your ip address";
	}
} else {
	print "Missing Options";
}
