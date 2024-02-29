#!/usr/bin/env perl
use strict;
use warnings;
use List::Util qw(shuffle);
use Getopt::Long;

# Define variables for command-line options
my $country;
my $city;

# Parse command-line options
GetOptions(
    "country=s" => \$country,
    "city=s"    => \$city
);
$country = lc($country) if $country;
$city = lc($city) if $city;

# Run the tailscale command and capture the output
my $command_output = `tailscale exit-node list`;

# Split the output into lines
my @lines = split /\n/, $command_output;

# Initialize a hash of arrays to store the parsed data
my %parsed_data;

# Iterate through each line (skipping the first and last lines)
for my $line (@lines[2..$#lines-2]) {
    # Split the line into columns
    my @columns = split /\s{2,}/, $line;

    # Store the values in variables for readability
    my ($ip, $hostname, $country_val, $city_val, $status) = @columns;

    # Skip nodes with 'offline' status
    next if $status eq 'offline';

    # Ignore the Country name in the source. Extract country code from hostname
    if ($hostname =~ /^([a-z]+)-/) {
        $country_val = lc($1); # Capitalize the city name
    }

    # Ignore the City name in the source. Extract city code from hostname
    if ($hostname =~ /^[a-z]+-([a-z]+)/) {
        $city_val = lc($1); # Capitalize the city name
    }

    # Push the data into the hash of arrays based on COUNTRY or US CITY
    push @{$parsed_data{$country_val}}, {
        HOSTNAME => $hostname,
    };
    push @{$parsed_data{$city_val}}, {
        HOSTNAME => $hostname,
    } if $city_val;
}

# Filter data based on the provided parameters
my @hostnames;
if ($country) {
    @hostnames = map { $_->{HOSTNAME} } @{$parsed_data{$country}} if exists $parsed_data{$country};
} elsif ($city) {
    @hostnames = map { $_->{HOSTNAME} } @{$parsed_data{$city}} if exists $parsed_data{$city};
} else {
    # No filter, select from all records
    for my $key (keys %parsed_data) {
        push @hostnames, map { $_->{HOSTNAME} } @{$parsed_data{$key}};
    }
}

# Randomly select one record
my $selected_hostname;
if (@hostnames) {
    $selected_hostname = (shuffle @hostnames)[0];
    print "$selected_hostname\n";
    exec "tailscale set --exit-node=$selected_hostname --exit-node-allow-lan-access";
} else {
    # No records found for the given filter
    print "No records found for the given filter.\n";
}
