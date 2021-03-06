﻿=info
    $points 每框取样的数量，$offset 应小于 $flen-$points*2-1，
    因为每一次取样的范围是 ($offset .. $offset + $points) 而 if 判断后还会加一次 $points 的距离
=cut

use Modern::Perl;
use FindBin;
use lib $FindBin::Bin ."/lib";

#use feature qw/state/;
use OpenGL qw/ :all /;
use OpenGL::Config;

use Time::HiRes qw/time sleep/;
use Try::Tiny;
use Win32::Sound;
use Math::FFT;
use LoadPCM;

STDOUT->autoflush(1);

our $FPS = 20;
our $SIZE_X = 800;
our $SIZE_Y = 600;
our ($TOP, $RIGHT);

our $WinID;
our $PI  = 3.1415926536;
our $PI2 = $PI * 2;

#our $wavefile = "audiofiles/Marine_60s.wav";
our $wavefile = "audiofiles/Animals.wav";

our $wave = LoadPCM->new($wavefile);
our $info = $wave->info();
our @frame = $wave->data();
our $flen = $info->{'DataLength'};
our $channels = $info->{"Channels"};
our $bits = $info->{"BitsPerSample"};
our $Hz = $info->{"SamplesPerSec"};
our $move = $Hz / $FPS;

sub play
{
    our $wavefile;
    Win32::Sound::Volume('20%');
    Win32::Sound::Play( $wavefile, SND_ASYNC );
}

printf "Frames: %d %d, Move step: %d\n", $flen, $#frame, $move;
die "frame data error" if not defined $frame[0]->[0];

&Main();

sub reduce_spec
{
    my ($data, $maxfreq, $parts) = @_;
    my $spec = [];
    my $step = 512/32;
    my ($accum, $max) = (0, 0);

    for my $id ( 1 .. $#$data-1 ) {
        if ( $id % $step == 0 ) {
            $max = $max > 10 ? $max : 1;
            push @$spec, [ $id, (log(sqrt($max*2))/log(2))*20.0 ];
            ($accum, $max) = (0, 0);
        }
        #$max += $data->[$id];
        $max = $data->[$id] if ($data->[$id] > $max);
    }
    return $spec;
}

sub display 
{
    our $FPS;
    state $time_a = time();
    state $offset = 0;
    state $repeat = 0;
    state $time_dt = 0.0;
    state $time_pass = 0.0;
    state $played = 0;

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
    for my $id ( $offset .. $offset+$points-1 ) {
        glVertex3f( ($id-$offset)*$xscale, $frame[$id]->[$ch]*$yscale, 0.0 );
    }
    glEnd();

    my $series = [ map {  $frame[$_]->[$ch] } ($offset .. $offset+$points-1 ) ];
    my $fft = Math::FFT->new($series);
    my $coeff = $fft->rdft();
    my $spectrum = $fft->spctrm;
    my $spec = reduce_spec( $spectrum, 200, 20 );

    $time_pass = time() - $time_a;
    if ($time_pass >= 2.0 and $played == 0)
    {
        printf "play";
        play();
        sleep 0.1;
        $played = 1;
    }

    if ( $offset < ($flen-$move*2-1) ) {
        $offset += $move if ( $played == 1 );
    } else {
        $repeat ++;
        #$offset = 0;
    }

    try { $frame[$offset+$points]->[$ch] * 1 or die } catch { printf "Over %d", $offset; destroy() };

    glTranslatef(200.0, -200.0, 0.0);
    my $ref = $spec;
    glColor3f(0.9, 0.8, 0.3);
    glBegin( GL_QUADS );
    for my $id ( 0 .. $#$ref )
    {
        #glVertex3f( $id * $xscale * 1.2, $ref->[$id] * $yscale * 0.5, 0.0  );
        glVertex3f( $ref->[$id][0], $ref->[$id][1], 0.0  );
        glVertex3f( $ref->[$id][0]-6.0, $ref->[$id][1], 0.0  );
        glVertex3f( $ref->[$id][0]-6.0, 0.0, 0.0  );
        glVertex3f( $ref->[$id][0],  0.0, 0.0  );
    }
    glEnd();

    glPopMatrix();

    our ($W, $H);
    if ( $repeat == 0 and $played ) { $time_dt = time()-$time_a; }
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
        #glFlush();
        glutDestroyWindow($WinID);
        exit;
    }
    elsif ($key == 27) 
    {
        #glFlush();
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
