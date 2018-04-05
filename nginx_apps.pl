#! /usr/bin/perl

# use strict;
# use warnings;
# use Data::Dumper qw(Dumper);

############ Config ##############
my $nginx_apps_dir = '/etc/nginx/sites-enabled/';
my @codes_to_ignore = ('401');
##################################

my $file_status;
my @apps;
my @server;

opendir(DIR, $nginx_apps_dir) or die "$!";
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
    
    foreach my $url (@apps) {
        my $result = qx/curl -L -k -s -o \/dev\/null -w '%{http_code}' $url/;
        # print("Result of $url is $result\n");
        if ($result ne '200' && grep { $_ ne $result} @codes_to_ignore) {
            $fails .= "Location: $url, Status: $result\n";
        }
    }
    
    return $fails;
}

foreach my $file (@directory) {
    open(my $buffer, $nginx_apps_dir . $file) or next;
    while (my $line = <$buffer>) {
        chomp $line;
	    if(index($line, 'server_name ') != -1) {
	        @server = split /server_name /, $line;
	        my $server_value = substr($server[1], 0, -1);
    
            if (index($server[0], '#') == -1 && $server_value ne '_') {
	            push @apps, detect_url($server_value);
	            last;
	        }
        }
    }
}

print(detect_failed_apps());

