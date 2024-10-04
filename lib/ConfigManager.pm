package ConfigManager;

use strict;
use warnings;

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub get_config {
    my $self = shift;
    return {
        'toggle_key' => 'ALT',
        'search_trigger' => 'search',
        'backend' => 'clipboard',
    }; # Dummy data
}


sub set_config {
    my ($self, $key, $value) = @_;
    # Implement config setting logic
}

1;
