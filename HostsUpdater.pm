# NGINX hosts access checking script
# by amazingcat LLC
# v2.0.1

package HostsUpdater;

# use strict;
# use warnings;
# use Data::Dumper qw(Dumper);


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

sub update_hosts_file {
    my ($hosts_ref, $hosts_filename_ref) = @_;
    my @hosts = @{ $hosts_ref };
    my $hosts_filename = ${ $hosts_filename_ref };
    
    if (open FILE, '>>', $hosts_filename 
        or die "Can not create a hosts file: $!") {
        foreach my $host (@hosts) {
            print FILE "$host\n";  
        }
    }
    
    close FILE;
}

sub init {
    my $hosts_filename  = $_[0];
    my $nginx_apps_dir  = $_[1];
    
    my @hosts;
    my @server;

    opendir(DIR, $nginx_apps_dir) or die "There is no such NGINX hosts directory $!";
    my @directory = readdir(DIR);
    closedir(DIR);

    foreach my $file (@directory) {
        open(FILE, $nginx_apps_dir . $file) or next;
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
        
        close FILE;
    }
    
    update_hosts_file(\@hosts, \$hosts_filename);
    
    return @hosts;
}

1;
