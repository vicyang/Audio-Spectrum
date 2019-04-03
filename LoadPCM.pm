package LoadPCM;
use Fcntl qw/:seek/;

our $fh;
our %fmt;
our %data;

sub init
{
    $file = shift if ( @_ > 0 );
    open our $fh, "<:raw", $file;
    seek($fh, 12, SEEK_SET);      # 略过文件头
    load_fmt_chunk();
}

sub load_fmt_chunk
{
    our %fmt;
    my $buff;
    my @item = qw/ ID
            ChunkSize 
            FormatTag 
            Channels 
            SamplesPerSec
            AvgBytesPerSec
            BlockAlign
            BitsPerSample /;
    read($fh, $buff, 24);
    @fmt{ @item } = unpack("LLssLLsss", $buff);

    for my $k ( @item ) {
        printf "%-15s: %d\n", $k, $fmt{$k};
    }
}

sub load_data_chunk
{
    my ($rframe, $rlength) = @_;
    our $fh;
    our %data;
    my $buff;
    read($fh, $buff, 8);
    @data{"ID", "ChunkSize"} = unpack("LL", $buff);
    $data{"length"} = $data{ChunkSize} / $fmt{"BlockAlign"};
    
    my @frame;
    my $frame_bytes = $fmt{"BlockAlign"};

    for my $it ( 1 .. $data{"length"} )
    {
        read($fh, $buff, $frame_bytes);
        if ( $fmt{"BitsPerSample"} == 8 ) {
            # signed
            push @frame, [ map { $_ - 128 } unpack( "C"x $fmt{"Channels"} , $buff) ];
        } else {
            push @frame, [ unpack( "s"x $fmt{"Channels"} , $buff) ];
        }
    }

    printf( "%-15s: %d\n", $_, $data{$_} ) for ("ChunkSize");

    $data{"frame"} = \@frame;
    @$rframe = @frame;
    $$rlength = $data{"length"};
}

1;