#!/usr/bin/env perl
use strict;
use warnings;
use List::Util qw(shuffle);
use Getopt::Long;

# Define variables for command-line options
my $country;
my $city;
my $region;
my $named;
my $debug;
my $off;

# Define regions
my %regions = (
  uswest => '^us-(lax|sjc|phx|sea|slc|den)'
  );

# Parse command-line options
GetOptions(
    "country=s" => \$country,
    "city=s"    => \$city,
    "region=s"  => \$region,
    "named=s"  => \$named,
    "debug" => \$debug,
    "off" => \$off
);

if ($off) {
  print "exit node off";
  exec "tailscale set --exit-node=";
  exit;
}

if ($named) {
  print "exit-node=$named";
  exec "tailscale set --exit-node=$named --exit-node-allow-lan-access";
  exit;
}

# Run the tailscale command and capture the output
my $exitnodes_list = `tailscale exit-node list`;

# Split the output into lines
my @lines = split /\n/, $exitnodes_list;

# Initialize an arry to store matching hostnames
my @hostnames;

# Iterate through each line (skipping the first and last lines)
for my $line (@lines[2..$#lines-2]) {
    # skip empty line
    next if($line=~/^\s*$/);

    # Split the line into columns
    my @columns = split /\s{2,}/, $line;

    # Store the values in variables for readability
    my ($ip, $hostname, $country_val, $city_val, $status) = @columns;

    # Skip nodes with 'offline' or 'selected' status
    next if ($status eq 'offline' or $status eq 'selected');

    # initialize flag to track if record fails any filter
    my $not_failed = 1;

    # Ignore the Country name in the source. Extract country code from hostname
    if ($country and $hostname =~ /^([a-z]+)-/) {
        $country_val = $1; 
        $not_failed = lc($country_val) eq lc($country);
    }

    # Ignore the City name in the source. Extract city code from hostname
    if ($not_failed and $city and $hostname =~ /^[a-z]+-([a-z]+)/) {
        $city_val = $1; 
        $not_failed = lc($city_val) eq lc($city);
    }

    # process region parameter if provided
    if ($not_failed and $region) {
      # Check if a valid region parameter was passed
      if (exists $regions{$region}) {
        # Test if hostname matches region
        my $region_expr = $regions{$region};
        $not_failed = $hostname =~ /$region_expr/i;
      } else {
        $not_failed = 0;
      }
    }

    if ($not_failed) {
      push(@hostnames, $hostname);
    }
}

# Randomly select one record
my $selected_hostname;
if (@hostnames) {
  if ($debug) {
    print "HOSTNAMES:\n@hostnames\n\n";
  }
  $selected_hostname = (shuffle @hostnames)[0];
  print "$selected_hostname\n";
  exec "tailscale set --exit-node=$selected_hostname --exit-node-allow-lan-access";
} else {
    # No records found for the given filter
    print "No records found for the given filter.\n";
}
