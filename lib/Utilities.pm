package Utilities;

use strict;
use warnings;

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub validate_input {
    my ($self, $input, $type) = @_;
    # Implement input validation logic
}

sub create_backup {
    my ($self, $file_path) = @_;
    # Implement backup creation logic
}

1;
