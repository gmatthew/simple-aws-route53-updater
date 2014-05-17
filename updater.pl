#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use Digest::MD5;
my $domains      = [];
my $ttl          = 60;
my $type         = 'A';
my $ip_address   = '';
my $comment      = '';
my $zone_id      = '';
my $account      = '';

sub did_ip_change;

GetOptions(	"domain=s@"  => \$domains,
		"ttl:i"     => \$ttl,
		"type:s"    => \$type,
		"zoneid=s"  => \$zone_id,
		"comment:s" => \$comment,
		"account=s" => \$account
) or die("Error in command line arguments\n");


#generate tracker filename
my $encrypter = Digest::MD5->new;
$encrypter->add(@$domains);
$encrypter->add($type);

my $tracker_file = './ip_tracker_'.$encrypter->hexdigest.'.txt';


if ( (scalar(@$domains) > 0) && $zone_id && $account ) {

	#obtain external ip
	chomp( $ip_address = `wget -q -O - checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*//'`);

	if ($ip_address) {

		#did our address change?
		my $ip_changed = did_ip_change($ip_address);
		exit unless $ip_changed;
		
		#build xml
		my $xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><ChangeResourceRecordSetsRequest xmlns=\"https://route53.amazonaws.com/doc/2013-04-01/\"><ChangeBatch><Comment>$comment</Comment><Changes>";
					   
		foreach my $domain (@$domains) {	
			$xml .= "<Change><Action>UPSERT</Action><ResourceRecordSet><Name>$domain</Name><Type>$type</Type><TTL>$ttl</TTL><ResourceRecords><ResourceRecord><Value>$ip_address</Value></ResourceRecord></ResourceRecords></ResourceRecordSet></Change>";
		}
		
		$xml .=	"</Changes></ChangeBatch></ChangeResourceRecordSetsRequest>";
		
		#push to AWS
		system( "perl dnscurl.pl --keyname $account -- -X POST -d '$xml' -H \"Content-Type: text/xml; charset=UTF-8\" https://route53.amazonaws.com/2013-04-01/hostedzone/$zone_id/rrset" );

	}
	else {
		print "Unable to determine your ip address";
	}
}
else {
	print "Missing Options";
}


sub did_ip_change {
	my ($ip) = shift @_;
	my $changed = 0;

	my $old_ip = `cat $tracker_file`;

	if ( $old_ip ne $ip ) {
		open( my $fh, ">", $tracker_file );
		print $fh $ip;
		close $fh;

		$changed = 1;
	}

	return $changed;
}
