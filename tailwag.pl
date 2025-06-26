#!/usr/bin/env perl
use strict;
use warnings;
use List::Util qw(shuffle);
use Getopt::Long;
use Pod::Usage;
use File::Basename;
use File::Spec;

# Define variables for command-line options
my $country;
my $city;
my $region;
my $named;
my $debug;
my $off;
my $help;
my $man;
my $list_regions;

# Default regions (can be overridden by config file)
my %regions = (
    uswest  => '^us-(lax|sjc|phx|sea|slc|den)',
    useast  => '^us-(nyc|bos|atl|mia|ord|dfw)',
    europe  => '^(gb|de|fr|nl|ch|se|no|fi|dk|es|it)',
    asia    => '^(jp|sg|hk|tw|kr)',
    oceania => '^(au|nz)'
);

# Load regions from config file if it exists
my $config_file = $ENV{HOME} . '/.tailwag.conf';
if (-f $config_file) {
    open(my $fh, '<', $config_file) or warn "Cannot open config file: $!";
    while (my $line = <$fh>) {
        chomp $line;
        next if $line =~ /^\s*#/ or $line =~ /^\s*$/;  # Skip comments and empty lines
        if ($line =~ /^\s*(\w+)\s*=\s*(.+)$/) {
            $regions{$1} = $2;
        }
    }
    close($fh);
}

# Parse command-line options
GetOptions(
    "country=s"    => \$country,
    "city=s"       => \$city,
    "region=s"     => \$region,
    "named=s"      => \$named,
    "debug"        => \$debug,
    "off"          => \$off,
    "help|h"       => \$help,
    "man"          => \$man,
    "list-regions" => \$list_regions
) or pod2usage(2);

# Handle help and documentation requests
pod2usage(1) if $help;
pod2usage(-exitval => 0, -verbose => 2) if $man;

# Handle list-regions request
if ($list_regions) {
    print "Available regions:\n";
    for my $region_name (sort keys %regions) {
        print "  $region_name: $regions{$region_name}\n";
    }
    exit 0;
}

if ($off) {
  print "exit node off\n";
  exec "tailscale set --exit-node=";
  exit;
}

if ($named) {
  print "exit-node=$named\n";
  exec "tailscale set --exit-node=$named --exit-node-allow-lan-access";
  exit;
}

# Run the tailscale command and capture the output
my $exitnodes_list = `tailscale exit-node list`;

# Split the output into lines
my @lines = split /\n/, $exitnodes_list;
@lines = grep(/^\s*\d+/, @lines);

# Initialize an array to store matching hostnames
my @hostnames;

# Iterate through each line (skipping the first and last lines)
#for my $line (@lines[2..$#lines-2]) {
for my $line (@lines) {
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

__END__

=head1 NAME

tailwag - Randomly select and switch between Tailscale exit nodes

=head1 SYNOPSIS

tailwag [options]

 Options:
   --country=CODE     Filter by country code (e.g., us, gb, de)
   --city=CODE        Filter by city code (e.g., lax, nyc, lon)
   --region=NAME      Filter by predefined region (e.g., uswest, europe)
   --named=HOSTNAME   Use specific exit node by hostname
   --off              Turn off exit node usage
   --list-regions     List all available regions
   --debug            Show debug information
   --help, -h         Show brief help message
   --man              Show full documentation

=head1 DESCRIPTION

B<tailwag> randomly selects and switches between available Tailscale exit nodes.
It's particularly useful for Mullvad exit node users who want to quickly change
their VPN endpoint without manual selection.

The tool automatically:

=over 4

=item * Excludes offline nodes

=item * Excludes the currently selected node

=item * Enables LAN access when setting exit nodes

=back

=head1 OPTIONS

=over 4

=item B<--country=CODE>

Filter exit nodes by country code. The country code is extracted from the
hostname pattern (e.g., 'us' from us-nyc-wg-301.mullvad.ts.net).

=item B<--city=CODE>

Filter exit nodes by city code. The city code is extracted from the
hostname pattern (e.g., 'nyc' from us-nyc-wg-301.mullvad.ts.net).

=item B<--region=NAME>

Filter by predefined region. Use --list-regions to see available regions.
Regions can be customized in ~/.tailwag.conf.

=item B<--named=HOSTNAME>

Connect to a specific exit node by its full hostname.

=item B<--off>

Disconnect from the current exit node (disable exit node usage).

=item B<--list-regions>

Display all available regions and their patterns.

=item B<--debug>

Show the list of matching hostnames before selection.

=item B<--help, -h>

Print a brief help message and exit.

=item B<--man>

Print the full manual page and exit.

=back

=head1 EXAMPLES

    # Random exit node from any available
    tailwag

    # Random US exit node
    tailwag --country us

    # Random exit node in Los Angeles
    tailwag --city lax

    # Random exit node in US West region
    tailwag --region uswest

    # Specific exit node
    tailwag --named us-lax-wg-301.mullvad.ts.net

    # Turn off exit node
    tailwag --off

=head1 CONFIGURATION

You can define custom regions in ~/.tailwag.conf. The file format is:

    # This is a comment
    region_name = regex_pattern
    
    # Examples:
    myregion = ^us-(nyc|bos|phl)
    nordics = ^(se|no|fi|dk)

Built-in regions can be overridden by defining them in the config file.

=head1 REQUIREMENTS

=over 4

=item * Tailscale must be installed and authenticated

=item * User must have permission to run 'tailscale set' commands

=item * For Mullvad nodes: active Mullvad account linked to Tailscale

=back

=head1 LIMITATIONS

=over 4

=item * Designed primarily for Mullvad exit nodes (hostname pattern dependent)

=item * May not work correctly with mixed Mullvad and non-Mullvad exit nodes

=item * Requires sudo/admin privileges to change exit nodes

=back

=head1 AUTHOR

Originally created for personal use with Mullvad VPN via Tailscale.

=head1 LICENSE

See LICENSE file in the distribution.

=cut
