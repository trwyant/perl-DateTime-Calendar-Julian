package DateTime::Calendar::Julian;

use strict;

use vars qw($VERSION);

$VERSION = '0.02';

use DateTime 0.07;
@DateTime::Calendar::Julian::ISA = 'DateTime';

use Params::Validate qw( validate SCALAR BOOLEAN OBJECT );

sub _floor {
    my $x  = shift;
    my $ix = int $x;
    if ($ix <= $x) {
        return $ix;
    } else {
        return $ix - 1;
    }
}

my @start_of_month = (0, 31, 61, 92, 122, 153, 184, 214, 245, 275, 306, 337);

# Julian dates are formatted in exactly the same way as Gregorian dates,
# so we use most of the DateTime methods.

# This is the difference between Julian and Gregorian calendar:
sub _is_leap_year {
    my ($self, $year) = @_;

    return ($year % 4 == 0);
}

# Algorithms from http://home.capecod.net/~pbaum/date/date0.htm
sub _ymd2rd {
    my ($self, $y, $m, $d) = @_;

    if ($m <= 2) {
        $m += 12;
        $y--;
    }

    my $rd = $d + $start_of_month[$m-3] + 365*$y + _floor($y/4) - 308;
    return $rd;
}

sub _rd2ymd {
    my ($self, $rd, $extra) = @_;

    my $z = $rd + 308;
    my $y = _floor(($z*100-25)/36525);
    my $doy = $z - _floor(365.25*$y);
    my $m = int((5*$doy + 456)/153);
    my $d = $doy - $start_of_month[$m-3];
    if ($m > 12) {
        $m -= 12;
        $y++;
    }

    if ($extra) {
        # day_of_week, day_of_year
        my $dow = (($rd + 6)%7) + 1;
        return $y, $m, $d, $dow, $doy;
    }
    return $y, $m, $d;
}

# Aliases provided for compatibility with DateTime; if DateTime switches
# over to _ymd2rd and _rd2ymd, these will be removed eventually.
*_greg2rd = \&_ymd2rd;
*_rd2greg = \&_rd2ymd;

sub epoch {
    my $self = shift;

    my $greg = DateTime->from_object( object => $self );
    return $greg->epoch;
}

sub from_epoch {
    my $class = shift;

    my $greg = DateTime->from_epoch( @_ );
    return $class->from_object( object => $greg );
}

# Grrr. Compare with DateTime::last_day_of_month and weep.
my @MonthLengths =
    ( 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );
my @LeapYearMonthLengths = @MonthLengths;
$LeapYearMonthLengths[1]++;

sub last_day_of_month {
    my $class = shift;
    my %p = validate( @_,
                      { year   => { type => SCALAR },
                        month  => { type => SCALAR },
                        hour   => { type => SCALAR, optional => 1 },
                        minute => { type => SCALAR, optional => 1 },
                        second => { type => SCALAR, optional => 1 },
                        language  => { type => SCALAR | OBJECT, optional => 1 },
                        time_zone => { type => SCALAR | OBJECT, optional => 1 },
                      }
                    );

    my $day = ( $class->_is_leap_year( $p{year} ) ?
                $LeapYearMonthLengths[ $p{month} - 1 ] :
                $MonthLengths[ $p{month} - 1 ]
              );

    return $class->new( %p, day => $day );
}

1;

__END__

=head1 NAME

DateTime::Calendar::Julian - Dates in the Julian calendar

=head1 SYNOPSIS

  use DateTime::Calendar::Julian;

  $dt = DateTime::Calendar::Julian->new( year  => 964,
                                         month => 10,
                                         day   => 16,
                                       );

  # convert Julian->Gregorian...

  $dtgreg = DateTime->from_object( object => $dt );

  # ... and back again

  $dtjul = DateTime::Calendar::Julian->from_object( object => $dtgreg );

=head1 DESCRIPTION

DateTime::Calendar::Julian implements the Julian Calendar.  This module
implements all methods of DateTime; see the DateTime(3) manpage for all
methods.

=head1 BACKGROUND

The Julian calendar was introduced by Julius Caesar in 46BC.  It
featured a twelve-month year of 365 days, with a leap year in February
every fourth year.  This calendar was adopted by the Christian church in
325AD.  Around 532AD, Dionysius Exiguus moved the starting point of the
Julian calendar to the calculated moment of birth of Jesus Christ. Apart
from differing opinions about the start of the year (often January 1st,
but also Christmas, Easter, March 25th and other dates), this calendar
remained unchanged until the calendar reform of pope Gregory XIII in
1582.  Some backward countries, however, used the Julian calendar until
the 18th century or later.

This module uses the proleptic Julian calendar for years before 532AD,
or even 46BC.  This means that dates are calculated as if this calendar
had existed unchanged from the beginning of time.  The assumption is
made that January 1st is the first day of the year.

Note that BC years are given as negative numbers, with 0 denoting the
year 1BC (there was no year 0AD!), -1 the year 2BC, etc.

=head1 SUPPORT

Support for this module is provided via the datetime@perl.org email
list. See http://lists.perl.org/ for more details.

=head1 AUTHOR

Eugene van der Pijll <pijll@gmx.net>

=head1 COPYRIGHT

Copyright (c) 2003 Eugene van der Pijll.  All rights reserved.  This
program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<DateTime>

datetime@perl.org mailing list

=cut
