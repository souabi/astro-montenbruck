#!/perl

use 5.22.0;
use strict;
no warnings qw/experimental/;
use feature qw/switch/;

use utf8;
use FindBin qw/$Bin/;
use lib ("$Bin/lib", "$Bin/../lib");
use Getopt::Long qw/GetOptions/;
use POSIX qw /floor/;
use Pod::Usage qw/pod2usage/;
use DateTime;
use Term::ANSIColor;

use Readonly;
use Helpers qw/parse_datetime $LOCALE/;
use Display qw/%LIGHT_THEME %DARK_THEME print_data/;
use Astro::Montenbruck::Time qw/jd0 cal2jd jd2cal jd2unix/;
use Astro::Montenbruck::Lunation qw/:all/;

my $now = DateTime->now()->set_locale($LOCALE);

my $help   = 0;
my $date   = $now->strftime('%F');
my $tzone  = $now->strftime('%z');
my @place;
my $theme  = 'dark';

# Parse options and print usage if there is a syntax error,
# or if usage was explicitly requested.
GetOptions(
    'help|?'     => \$help,
    'date:s'     => \$date,
    'theme:s'    => \$theme,
    'timezone:s' => \$tzone,
) or pod2usage(2);

pod2usage(1) if $help;

my $scheme = do {
    given (lc $theme) {
        \%DARK_THEME when 'dark';
        \%LIGHT_THEME when 'light';
        default { warn "Unknown theme: $theme. Using default (dark)"; \%DARK_THEME }
    }
};

my $display_quarter = sub {
    my ($q, $j) = @_;
    my $dt = DateTime->from_epoch(epoch => jd2unix$j)->set_time_zone($tzone);
    # print_data($q, $dt->strftime('%F %T'), scheme => $scheme);
    print colored( sprintf('%-14s', $q), $scheme->{data_row_title} );
    print colored(': ', $scheme->{data_row_title});
    print colored(
        $dt->strftime('%F %H:%M'),
        $scheme->{table_row_data}
    );
    say();
};


my $dt = parse_datetime($date);
$dt->set_time_zone($tzone) if defined($tzone);
say();
print_data('Date', $dt->strftime('%F'), scheme => $scheme, title_width => 14);
print_data('Time Zone', $dt->strftime('%Z'), scheme => $scheme, title_width => 14);
say();
# find New Moon closest to the date
my $j = search_event([$dt->year, $dt->month, $dt->day], $NEW_MOON);
# if the event has not happened yet, find the previous one
if ($j > $dt->jd) {
    my ($y, $m, $d) = jd2cal($j - 28);
    $j = search_event([$y, $m, floor($d)], $NEW_MOON);
}

$display_quarter->($NEW_MOON, $j);

for my $q ($FIRST_QUARTER, $FULL_MOON, $LAST_QUARTER, $NEW_MOON) {
    my ($y, $m, $d) = jd2cal$j;
    $j = search_event([$y, $m, floor($d)], $q);
    $display_quarter->($q, $j);
} 




print "\n";


__END__

=pod

=encoding UTF-8

=head1 NAME

phases — calculate date/time of principal lunar phases around a date.

=head1 SYNOPSIS

  phases [options]

=head1 OPTIONS

=over 4

=item B<--help>

Prints a brief help message and exits.

=item B<--date>

Date, either a I<calendar entry> in format C<YYYY-MM-DD>, or a floating-point I<Julian Day>:

  --date="2019-06-08"

=item B<--timezone>

Time zone short name, e.g.: C<EST>, C<UTC> etc. or I<offset from Greenwich>
in format B<+HHMM> / B<-HHMM>, like C<+0300>.

    --timezone=CET # Central European Time
    --timezone=EST # Eastern Standard Time
    --timezone=UTC # Universal Coordinated Time
    --timezone=GMT # Greenwich Mean Time, same as the UTC
    --timezone=+0300 # UTC + 3h (eastward from Greenwich)

By default, local timezone by default, UTC under Windows.

Please, note: Windows platform does not recognize some time zone names, C<MSK> for instance. 
In such cases, use I<offset from Greenwich> format, as described above.


=item B<--theme> color scheme:

=over

=item * B<dark>, default: color scheme for dark consoles

=item * B<light> color scheme for light consoles

=back

=back

=head1 DESCRIPTION

B<phases>  computes lunar phases around a date.

=cut
