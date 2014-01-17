package Opsview::Printer;

sub printHostGroups {
    my ($class, $groups, $groupId) = @_;

    $groupId = '1' unless defined($groupId);

    my @table;
    push @table, [ "Id", "Name", "State", "Down", "Warning", "Critical" ];

    my @parentStack;
    my @copy = @$groups;

    # The id is to keep looping over the groups looking for the successive parents
    # Because the number of groups shrinks, it should not be too bad
    do {
        my $parentId = undef;
        if (scalar(@parentStack)) {
            $parentId = $parentStack[$#parentStack];
        }

        my $found = 0;
        for (my $i=0; $i<scalar(@copy); $i++) {
            my $group = $copy[$i];

            if (defined($parentId)) {
                my $parents = $group->{'matpath'};
                next unless (
                    defined($parents) && scalar(@$parents) &&
                    $parents->[scalar(@$parents) - 1]->{'id'}) eq $parentId;
            } else {
                next unless ($group->{'hostgroupid'} eq $groupId);
            }

            push @table, [
                $group->{'hostgroupid'},
                ('  ' x scalar(@parentStack)) . $group->{'name'},
                $group->{'computed_state'},
                _format($group->{'hosts'}->{'down'}),
                _format($group->{'services'}->{'warning'}),
                _format($group->{'services'}->{'critical'})
            ];

            $found = 1;
            splice @copy, $i, 1;

            # If the group has children
            if ($group->{'leaf'} ne '1') {
                # add the id on top of the stack and start the loop again
                push @parentStack, $group->{'hostgroupid'};
                last;
            }
        }

        # if we have not found anything
        if (scalar(@parentStack) && !$found) {
            # pop the parent id from the stack
            pop @parentStack;
        }
    } while (scalar(@parentStack));

    _printTable(\@table);
}

sub printViews {
    my ($class, $views) = @_;

    my $table = [ [ "Name", "Description", "State", "Down", "Warning", "Critical" ] ];
    foreach my $view (@$views) {
        push @$table, [
            $view->{'name'},
            $view->{'description'},
            $view->{'computed_state'},
            _format($view->{'hosts'}->{'down'}),
            _format($view->{'services'}->{'warning'}),
            _format($view->{'services'}->{'critical'})
        ];
    }

    _printTable($table);
}

sub printView {
    my ($class, $view) = @_;

    my $table = [ [ "Name", "State", "Down", "Warning", "Critical" ] ];
    foreach my $host (@$view) {
        foreach my $service (@{$host->{'services'}}) {
            push @$table, [
                $host->{'name'},
                $host->{'state'},
                $service->{'name'},
                $service->{'state'},
                $service->{'unhandled'} ? 'unhandled' : 'handled',
                $service->{'output'},
            ];
        }
    }

    _printTable($table);
}

sub printHosts {
    my ($class, $hosts) = @_;

    my $table = [ [ "Name", "Alias", "State", "Ok", "Warning", "Critical" ] ];
    foreach my $host (@$hosts) {
        push @$table, [
            $host->{'name'},
            $host->{'alias'},
            $host->{'state'},
            $host->{'summary'}->{'ok'}->{'handled'} || 0,
            _format($host->{'summary'}->{'warning'}),
            _format($host->{'summary'}->{'critical'})
        ];
    }

    _printTable($table);
}

sub printServices {
    my ($class, $hosts) = @_;

    my $table = [ [ "Host", "Name", "State", "Unhandled", "Output" ] ];
    foreach my $host (@$hosts) {
        foreach my $service (@{$host->{'services'}}) {
            push @$table, [
                $host->{'name'},
                $service->{'name'},
                $service->{'state'},
                $service->{'unhandled'} || 0,
                $service->{'output'},
            ];
        }
    }

    _printTable($table);
}

sub prettyPrint {
  my ($class, $value, $level) = @_;

  $level = 0 unless (defined($level));

  if (ref($value) eq 'HASH') {
    print '  ' x $level;
    if (scalar(%$value) == 0) {
      print '{}';
    } else {
      print "{\n";
      my $first = 1;
      foreach my $key (sort { $a cmp $b } keys %$value) {
        print '  ' x ( $level + 1 );
        print $key;
        print ' => ';
        my $element = $value->{ $key };
        if (ref($element)) {
          print "\n";
        }
        $class->prettyPrint($element, $level + 2);
        print "\n";
        $first = 0;
      }
      print '  ' x $level;
      print "}";
    }
  } elsif (ref($value) eq 'ARRAY') {
    print '  ' x $level;
    if (scalar(@$value) == 0) {
      print "[]";
    } else {
      print "[\n";
      my $first = 1;
      foreach my $element (@$value) {
        if (ref($element) && !$first) {
          print "\n";
        }
        $class->prettyPrint($element, $level + 1);
        print "\n";
      }
      print '  ' x $level;
      print "]";
      $first = 0;
    }
  } else {
    print $value;
  }
}

sub _printTable {
  my ($table) = @_;

  my $widths = [];

  foreach my $row (@$table) {
    for (my $i=0; $i<scalar(@$row); $i++) {
      my $width = length($row->[$i]);
      if (!defined($widths->[$i]) || $width > $widths->[$i]) {
        $widths->[$i] = $width;
      }
    }
  }

  foreach my $row (@$table) {
    for (my $i=0; $i<scalar(@$row); $i++) {
      my $width = length($row->[$i]);
      my $maxWidth = $widths->[$i];

      print ' ';
      print $row->[$i];
      print ' ' x ( $maxWidth - $width );
      print ' ';
    }
    print "\n";
  }
}

sub _format {
    my ($object) = @_;
    my $handled = $object->{'handled'} || 0;
    my $unhandled = $object->{'unhandled'} || 0;
    return "$unhandled ($handled)";
}

1;
