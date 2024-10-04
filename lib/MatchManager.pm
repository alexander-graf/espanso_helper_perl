package MatchManager;

use strict;
use warnings;
use YAML::XS qw(LoadFile DumpFile);
use File::HomeDir;

sub new {
    my $class = shift;
    my $self = {
        file_path => File::HomeDir->my_home . "/.config/espanso/match/base.yml",
        matches => [],
    };
    bless $self, $class;
    $self->load_matches();
    return $self;
}

sub load_matches {
    my $self = shift;
    if (-e $self->{file_path}) {
        $self->{matches} = LoadFile($self->{file_path});
    }
}

sub save_matches {
    my $self = shift;
    DumpFile($self->{file_path}, $self->{matches});
}

sub list_matches {
    my $self = shift;
    return $self->{matches};
}

sub add_match {
    my ($self, $match) = @_;
    push @{$self->{matches}}, $match;
    $self->save_matches();
}

sub update_match {
    my ($self, $index, $match) = @_;
    $self->{matches}->[$index] = $match;
    $self->save_matches();
}

sub delete_match {
    my ($self, $index) = @_;
    splice @{$self->{matches}}, $index, 1;
    $self->save_matches();
}

1;
