#! /usr/bin/perl

# NGINX hosts access checking script
# by amazingcat LLC
# v2.0.1

require v5.004;

use strict;
use warnings;
# use Data::Dumper qw(Dumper);

use File::stat;
use File::Basename;

############ Config ##############
use constant {
    DIR                    => dirname(__FILE__) . '/',
    HOSTS_FILENAME         => 'hosts.list',
    CHECKED_HOSTS_FILE     => 'checked_hosts.list',
    NGINX_APPS_DIR         => '/etc/nginx/sites-enabled/',
    CODES_TO_IGNORE        => ('401'),
    HOSTS_UPDATE_FREQUENCY => 3600, # in sec (UNIX time since `epoch`)
};
##################################

use lib DIR;
use HostsUpdater;

sub check_hosts_storage {
    my @checked = ();
    my @hosts = ();
    
    if (open FILE, '<', DIR . CHECKED_HOSTS_FILE) {
        while (my $line = <FILE>) {
            chomp $line;
            push @checked, $line;
        }
        close FILE;
    } elsif (open FILE, '>', DIR . CHECKED_HOSTS_FILE 
        or die "Can not create a checked host file: $!") {
        close FILE;
    }
    
    my $file_stat = stat(DIR . HOSTS_FILENAME);
    
    if ((open FILE, '<', DIR . HOSTS_FILENAME) && 
        ((time() - $file_stat->mtime) < HOSTS_UPDATE_FREQUENCY)) {
        while (my $line = <FILE>) {
            chomp $line;
            push @hosts, $line;
        }
        close FILE;
    } else {
        truncate DIR . HOSTS_FILENAME, 0 if -e DIR . HOSTS_FILENAME; # reset hosts file if it exists
        @hosts = HostsUpdater::init(DIR . HOSTS_FILENAME, NGINX_APPS_DIR);
    }
    
    return \@checked, \@hosts;
}

sub check_host {
    my $url = $_[0];
    my $fails = "";
    
    my $result = qx/curl -L -k -s -o \/dev\/null -w '%{http_code}' $url/;
    # print("$url is checked: $result\n");
    unless ($result eq '200' || grep(/^$result$/, CODES_TO_IGNORE)) {
        $fails .= "Location: $url, Status: $result\n";
    }
    
    return $fails;
}

############# Main #################

my ($checked_ref, $hosts_ref) = check_hosts_storage();
my @checked = @{ $checked_ref };
my @hosts = @{ $hosts_ref };

if (@hosts) {
    my $checked_flag;
    foreach my $host (@hosts) {
        $checked_flag = 0;
        foreach my $element (@checked) {
            $checked_flag = 1 if ($element eq $host);
        } 
        unless ($checked_flag) { 
            print(check_host($host));
            if (open FILE, '>>', DIR . CHECKED_HOSTS_FILE 
                or die "Can not create a checked host file: $!") {
                print FILE "$host\n";
                close FILE;
            }
            last;
        }
    }
    truncate DIR . CHECKED_HOSTS_FILE, 0 if $checked_flag; # reset checked hosts file
}

