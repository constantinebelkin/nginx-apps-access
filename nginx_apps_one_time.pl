#! /usr/bin/perl

# NGINX hosts access checking script
# by amazingcat LLC
# v1.0.3

require v5;

# use strict;
# use warnings;
# use Data::Dumper qw(Dumper);

############ Config ##############
use constant {
    NGINX_APPS_DIR         => '/etc/nginx/sites-enabled/',
    CODES_TO_IGNORE        => ('401'),
}
##################################

my $file_status;
my @hosts;
my @server;

opendir(DIR, NGINX_APPS_DIR) or die "There is no such NGINX hosts directory $!";
my @directory = readdir(DIR);
closedir(DIR);

sub detect_url {
    my $server_value = $_[0];
    my $to_push;
    
    if (index($server_value, ' ') != -1) {
        my @multiurls = split / /, $server_value;
        foreach my $url (@multiurls) {
            if (index($url, '*') == -1){
                $to_push = $url;
                last;
            }
        }
    } else {
        $to_push = $server_value;
    }
    
    return $to_push;
}

sub detect_failed_apps {
    my $fails = "";
    
    foreach my $url (@hosts) {
        my $result = qx/curl -L -k -s -o \/dev\/null -w '%{http_code}' $url/;
        # print("Result of $url is $result\n");
        unless ($result eq '200' || grep(/^$result$/, CODES_TO_IGNORE)) {
            $fails .= "Location: $url, Status: $result\n";
        }
    }
    
    return $fails;
}

foreach my $filename (@directory) {
    open(FILE, NGINX_APPS_DIR . $filename) or next;
    while (my $line = <FILE>) {
        chomp $line;
	    if(index($line, 'server_name ') != -1) {
	        @server = split /server_name /, $line;
	        my $server_value = substr($server[1], 0, -1);
    
            if (index($server[0], '#') == -1 && $server_value ne '_') {
	            push @hosts, detect_url($server_value);
	            last;
	        }
        }
    }
}

print(detect_failed_apps());

