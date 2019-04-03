=info
    $points 每框取样的数量，$offset 应小于 $flen-$points*2-1，
    因为每一次取样的范围是 ($offset .. $offset + $points) 而 if 判断后还会加一次 $points 的距离
=cut

use Modern::Perl;
use OpenGL qw/ :all /;
use OpenGL::Config;
use Math::FFT;
use Try::Tiny;
use Time::HiRes qw/time sleep/;
use LoadPCM;

STDOUT->autoflush(1);

our $FPS = 20;
our $SIZE_X = 800;
our $SIZE_Y = 600;
our ($TOP, $RIGHT);

our $WinID;
our $PI  = 3.1415926536;
our $PI2 = $PI * 2;

our @frame;
our $flen;
#LoadPCM::init( "RELOADED - Dead Island installer.wav" );
#LoadPCM::init("linkmicinvitePCM.wav");
LoadPCM::init("audiofiles/Animals.wav");
LoadPCM::load_data_chunk( \@frame, \$flen );
our $bits = $LoadPCM::fmt{"BitsPerSample"};
our $channels = $LoadPCM::fmt{"Channels"};
our $move = $LoadPCM::fmt{"SamplesPerSec"} / $FPS;

printf "Frames: %d %d, Move step: %d\n", $flen, $#frame, $move;
die "frame data error" if not defined $frame[0]->[0];
&Main();

sub display 
{
    our $FPS;
    state $time_a = time();
    state $offset = 0;
    state $repeat = 0;
    state $time_dt = 0.0;

    glClear(GL_COLOR_BUFFER_BIT);

    glPushMatrix();
    glColor3f(1.0, 1.0, 1.0);
    glBegin(GL_LINES);
        glVertex3f(0.0, 0.0, 0.0);
        glVertex3f($RIGHT, 0.0, 0.0);
    glEnd();

    #if ($bits == 8 ) { glTranslatef(0.0, 50.0, 0.0); }
    glColor3f(1.0, 0.0, 0.0);

    my $points = 1024;
    my $yscale = 0.01;
    my $xscale = ($SIZE_X-10.0) /$points;
    #my $ch = $channels > 1 ? 1 : 1;
    my $ch = 0;

    glBegin(GL_LINE_STRIP);
    #glBegin(GL_POINTS);
    for my $id ( $offset .. $offset+$points )
    {
        glVertex3f( ($id-$offset)*$xscale, $frame[$id]->[$ch]*$yscale, 0.0 );
    }
    glEnd();

    my $series = [ map {  $frame[$_]->[$ch] } ($offset .. $offset+$points-1 ) ];
    my $fft = Math::FFT->new($series);
    my $coeff = $fft->rdft();
    my $spectrum = $fft->spctrm;

    if ( $offset < ($flen-$move*2-1) ) {
        $offset += $move;
    } else {
        $repeat ++;
        #$offset = 0;
    }

    try { $frame[$offset+$points]->[$ch]*$yscale or die } catch { printf "%d", $offset+$points; destroy() };

    my $ref = $spectrum;
    glColor3f(1.0, 1.0, 0.0);
    glBegin(GL_LINE_STRIP);
    for my $id ( 0 .. $#$ref )
    {
        glVertex3f( $id * $xscale *2.0, $ref->[$id] * $yscale * 0.5, 0.0  );
    }
    glEnd();

    glPopMatrix();

    our ($W, $H);
    if ( $repeat == 0 ) { $time_dt = time()-$time_a; }
    glRasterPos3f( $RIGHT-100.0, $TOP-20.0, 0.0);
    glutBitmapString( GLUT_BITMAP_9_BY_15, sprintf "%.2f FPS\n", $FPS );
    glutBitmapString( GLUT_BITMAP_9_BY_15, sprintf "%.2f s", $time_dt );

    glutSwapBuffers();
}

sub init 
{
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glLineWidth(1.0);
    glPointSize(1.0);
    #glDisable(GL_LINE_SMOOTH);
}

sub idle
{
    our $FPS;
    state $count = 0;
    state $ta = time();
    state $prev = time();
    state $tu;
    $count++;

    $tu = sprintf "%.4f", time() - $prev;
    
    if ( $count >= 20 )
    {
        $FPS = $count / (time()-$ta);
        $ta = time();
        $count = 0;
    }

    sleep 0.05-$tu if $tu < 0.05;
    $prev = time();
    glutPostRedisplay();

}

sub Reshape 
{
    our ($TOP, $RIGHT);
    my $half = $SIZE_Y/2.0;
    $TOP = $half, $RIGHT = $SIZE_X;
    glViewport(0.0,0.0, $SIZE_X, $SIZE_Y);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(-5.0, $SIZE_X, -$half, $half,-20.0,200.0);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    gluLookAt(0.0,0.0,100.0,0.0,0.0,0.0, 0.0,1.0,100.0);
}

sub hitkey 
{
    my $key = shift;
    if (lc(chr($key)) eq 'q') 
    {
        glutDestroyWindow($WinID);
        exit;
    }
    elsif ($key == 27) 
    {
        glutDestroyWindow($WinID);
        exit;
    }
}

sub destroy
{
    glutDestroyWindow($WinID);
    exit;
}

sub Main 
{
    glutInit();
    glutInitDisplayMode(GLUT_RGBA | GLUT_DOUBLE |GLUT_MULTISAMPLE );
    glutInitWindowSize($SIZE_X, $SIZE_Y);
    glutInitWindowPosition(100,100);
    our $WinID = glutCreateWindow("PCM");
    &init();
    glutDisplayFunc(\&display);
    glutReshapeFunc(\&Reshape);
    glutKeyboardFunc(\&hitkey);
    glutIdleFunc(\&idle);
    glutMainLoop();
}
