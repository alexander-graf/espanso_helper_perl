package PackageManager;

use strict;
use warnings;

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub install_package {
    my ($self, $package_name) = @_;
    # Implement package installation logic
}

sub remove_package {
    my ($self, $package_name) = @_;
    # Implement package removal logic
}

sub list_packages {
    my $self = shift;
    return ['Package 1', 'Package 2', 'Package 3']; # Dummy data
}


1;
