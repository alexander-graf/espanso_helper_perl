package EspansoGUI;

use strict;
use warnings;
use Gtk3 -init;
use YAML::XS qw(LoadFile DumpFile);
use File::HomeDir;
use File::Basename;
use Data::Dumper;

sub new {
    my $class = shift;
    my $self = {
        window => undef,
        content_area => undef,
        yaml_dir => File::HomeDir->my_home . "/.config/espanso/match/",
        current_file => "base.yml",
        matches => [],
        file_combo => undef,
    };
    bless $self, $class;
    $self->load_matches();
    $self->_build_ui();
    return $self;
}

sub load_matches {
    my $self = shift;
    my $file_path = $self->{yaml_dir} . $self->{current_file};
    if (-e $file_path) {
        my $data = eval { LoadFile($file_path) };
        if ($@) {
            warn "Error loading YAML file: $@";
            $self->{matches} = [];
        } elsif (ref($data) eq 'HASH' && exists $data->{matches} && ref($data->{matches}) eq 'ARRAY') {
            $self->{matches} = $data->{matches};
        } else {
            warn "Unexpected data structure in YAML file. Expected a hash with a 'matches' key.";
            $self->{matches} = [];
        }
    } else {
        $self->{matches} = [];
    }
    print "Loaded matches: ", Dumper($self->{matches}); # Debug output
}

sub save_matches {
    my $self = shift;
    my $file_path = $self->{yaml_dir} . $self->{current_file};
    my $data = { matches => $self->{matches} };
    eval { DumpFile($file_path, $data) };
    warn "Error saving YAML file: $@" if $@;
}

sub _build_ui {
    my $self = shift;
    
    $self->{window} = Gtk3::Window->new('toplevel');
    $self->{window}->set_title('Espanso Configuration Manager');
    $self->{window}->set_default_size(800, 600);
    
    my $main_box = Gtk3::Box->new('vertical', 5);
    $self->{window}->add($main_box);
    
    my $toolbar = $self->_create_toolbar();
    $main_box->pack_start($toolbar, 0, 0, 0);
    
    $self->{file_combo} = $self->_create_file_combo();
    $main_box->pack_start($self->{file_combo}, 0, 0, 0);
    
    $self->{content_area} = Gtk3::Box->new('vertical', 5);
    $main_box->pack_start($self->{content_area}, 1, 1, 0);
    
    $self->{window}->show_all();
}

sub _create_toolbar {
    my $self = shift;
    my $toolbar = Gtk3::Toolbar->new();
    
    my $new_button = Gtk3::ToolButton->new(undef, 'New Match');
    $new_button->signal_connect(clicked => sub { $self->add_match() });
    $toolbar->insert($new_button, -1);
    
    my $refresh_button = Gtk3::ToolButton->new(undef, 'Refresh');
    $refresh_button->signal_connect(clicked => sub { $self->show_matches() });
    $toolbar->insert($refresh_button, -1);
    
    return $toolbar;
}

sub _create_file_combo {
    my $self = shift;
    my $combo = Gtk3::ComboBoxText->new();
    
    opendir(my $dh, $self->{yaml_dir}) or die "Can't open directory: $!";
    my @yaml_files = grep { /\.yml$/ } readdir($dh);
    closedir($dh);
    
    $combo->append_text($_) for @yaml_files;
    $combo->set_active(0);
    
    $combo->signal_connect(changed => sub {
        $self->{current_file} = $combo->get_active_text();
        $self->load_matches();
        $self->show_matches();
    });
    
    return $combo;
}

sub show_matches {
    my $self = shift;
    $self->{matches} = [] unless ref($self->{matches}) eq 'ARRAY';
    $self->_clear_content_area();
    
    my $scrolled_window = Gtk3::ScrolledWindow->new();
    $scrolled_window->set_policy('automatic', 'automatic');
    
    my $list_box = Gtk3::ListBox->new();
    $scrolled_window->add($list_box);
    
    for my $match (@{$self->{matches}}) {
        my $row = Gtk3::ListBoxRow->new();
        my $hbox = Gtk3::Box->new('horizontal', 5);
        
        my $label = Gtk3::Label->new($match->{trigger} . " -> " . substr($match->{replace}, 0, 30) . "...");
        $hbox->pack_start($label, 1, 1, 0);
        
        my $edit_button = Gtk3::Button->new('Edit');
        $edit_button->signal_connect(clicked => sub { $self->edit_match($match) });
        $hbox->pack_start($edit_button, 0, 0, 0);
        
        my $delete_button = Gtk3::Button->new('Delete');
        $delete_button->signal_connect(clicked => sub { $self->delete_match($match) });
        $hbox->pack_start($delete_button, 0, 0, 0);
        
        $row->add($hbox);
        $list_box->add($row);
    }
    
    $self->{content_area}->pack_start($scrolled_window, 1, 1, 0);
    $self->{content_area}->show_all();
}

sub add_match {
    my $self = shift;
    $self->show_match_dialog();
}

sub edit_match {
    my ($self, $match) = @_;
    $self->show_match_dialog($match);
}

sub delete_match {
    my ($self, $match) = @_;
    my $dialog = Gtk3::MessageDialog->new(
        $self->{window},
        'modal',
        'question',
        'yes-no',
        "Are you sure you want to delete this match?"
    );
    
    my $response = $dialog->run();
    $dialog->destroy();
    
    if ($response eq 'yes') {
        @{$self->{matches}} = grep { $_ ne $match } @{$self->{matches}};
        $self->save_matches();
        $self->show_matches();
    }
}

sub show_match_dialog {
    my ($self, $match) = @_;
    my $dialog = Gtk3::Dialog->new(
        $match ? 'Edit Match' : 'Add New Match',
        $self->{window},
        'modal',
        'OK' => 'ok',
        'Cancel' => 'cancel'
    );
    
    my $content_area = $dialog->get_content_area();
    
    my $grid = Gtk3::Grid->new();
    $grid->set_column_spacing(5);
    $grid->set_row_spacing(5);
    
    my $trigger_label = Gtk3::Label->new('Trigger:');
    my $trigger_entry = Gtk3::Entry->new();
    $trigger_entry->set_text($match->{trigger} // '') if $match;
    
    my $replace_label = Gtk3::Label->new('Replace:');
    my $replace_entry = Gtk3::TextView->new();
    $replace_entry->set_wrap_mode('word');
    my $replace_buffer = $replace_entry->get_buffer();
    $replace_buffer->set_text($match->{replace} // '') if $match;
    
    my $scrolled_window = Gtk3::ScrolledWindow->new();
    $scrolled_window->set_policy('automatic', 'automatic');
    $scrolled_window->add($replace_entry);
    
    $grid->attach($trigger_label, 0, 0, 1, 1);
    $grid->attach($trigger_entry, 1, 0, 1, 1);
    $grid->attach($replace_label, 0, 1, 1, 1);
    $grid->attach($scrolled_window, 1, 1, 1, 1);
    
    $content_area->add($grid);
    $dialog->set_default_size(400, 300);
    $dialog->show_all();
    
    my $response = $dialog->run();
    
    if ($response eq 'ok') {
        my $new_match = {
            trigger => $trigger_entry->get_text(),
            replace => $replace_buffer->get_text($replace_buffer->get_start_iter, $replace_buffer->get_end_iter, 1),
        };
        
        if ($match) {
            my $index = 0;
            $index++ until $self->{matches}[$index] == $match or $index > $#{$self->{matches}};
            $self->{matches}[$index] = $new_match if $index <= $#{$self->{matches}};
        } else {
            push @{$self->{matches}}, $new_match;
        }
        
        $self->save_matches();
        $self->show_matches();
    }
    
    $dialog->destroy();
}

sub _clear_content_area {
    my $self = shift;
    foreach my $child ($self->{content_area}->get_children()) {
        $self->{content_area}->remove($child);
    }
}

sub run {
    my $self = shift;
    $self->show_matches();
    Gtk3::main();
}

1;
