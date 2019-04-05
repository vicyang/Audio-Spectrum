package LoadPCM;
use Fcntl qw/:seek/;

my %inf;
my @data;

sub new
{
    my $class = shift;
    my $file = shift;
    open my $fh, "<:raw", $file or die "File not found!\n";
    seek($fh, 12, SEEK_SET);      # 略过文件头
    load_fmt_chunk( $fh, \%inf );
    load_data_chunk( $fh, \%inf, \@data );
    $class;
}

sub info
{
    my $class = shift;
    return \%inf;
}

sub data
{
    my $class = shift;
    return @data;
}

sub load_fmt_chunk
{
    my ($fh, $inf_ref) = @_;
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
    @{$inf_ref}{ @item } = unpack("LLssLLsss", $buff);

    for my $k ( @item ) {
        printf "%-15s: %d\n", $k, $inf_ref->{$k};
    }
}

sub load_data_chunk
{
    my ($fh, $inf, $data) = @_;
    #my ($rframe, $rlength) = @_;
    my $buff;
    read($fh, $buff, 8);
    ( $ID, $ChunkSize ) = unpack("LL", $buff);
    # 元素数量 = ChunkSize / 对齐字节数
    $inf->{'DataLength'} = $ChunkSize / $inf->{'BlockAlign'}; 
    
    my $frame_bytes = $inf->{'BlockAlign'};
    for my $it ( 1 .. $inf->{'DataLength'} )
    {
        read($fh, $buff, $frame_bytes);
        if ( $inf->{"BitsPerSample"} == 8 ) {
            # signed
            push @$data, [ map { $_ - 128 } unpack( "C"x $inf->{"Channels"} , $buff) ];
        } else {
            push @$data, [ unpack( "s"x $inf->{"Channels"} , $buff) ];
        }
    }

    printf( "%-15s: %d\n", $_, $inf->{$_} ) for ("ChunkSize");
}

1;