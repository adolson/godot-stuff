#!/usr/bin/perl

# this script will take an image file that has any number of rows of sprites and
# convert it to numbered image frame files.
# will automatically number and zero-pad based on total frame count.
# can also ensure there is a custom size transparent border around each frame.
# can also ensure dimensions are even numbers (better mipmapping)

# resulting frames can be merged back into a sprite sheet using imagemagick:
# montage -background transparent -mode Concatenate sprites-f* spritesheet.png
# if resulting sheet is too wide or tall for Godot (>2048px), try changing
# the number of vertical or horizontal tiles
# montage -tiles 5x -background transparent -mode Concatenate sprites-f* spritesheet.png
# montage -tiles x5 -background transparent -mode Concatenate sprites-f* spritesheet.png

use strict;
use warnings;
use Image::Magick;

my $TESTANIMATION=1; # test the result immediately

my $SOURCE = $ARGV[0];
my $COLS = $ARGV[1] ||= 20;
my $ROWS = $ARGV[2] ||= 1;
my $PREFIX = $ARGV[3];
if (!$PREFIX) {
        $PREFIX = $SOURCE;
        $PREFIX =~ s{\.[^.]+$}{}; # strip file extension
        $PREFIX .= '-f'; # append -f (for frame). may help avoid overwriting non-frames? I dunno. maybe not needed.
}
my $BORDER = $ARGV[4] ||= 0;
my $ALLOWODD = $ARGV[5] ||= 0; # force width and height to be a power of 2
my $TRANSBG = $ARGV[6] ||= 'magenta'; # background color to make transparent

my $SPRITECOUNT = $COLS * $ROWS; # number of sprites
my $DIGITS = "%0" . length($SPRITECOUNT) . "d"; # automatic format for sprite numbering

if (!$SOURCE) {
        print "\nERROR:\n\tYou must specify a source sprite sheet.";
        print "\n\nSYNTAX:";
        print "\n\tstrip-to-frames.pl source [cols=20] [rows=1] [prefix] [border] [oddsize] [transbg]";
        print "\n\nOPTIONS:";
        print "\n\tsource\t- source image file";
        print "\n\tcols\t- number of sprite columns (default=20)";
        print "\n\trows\t- number of sprite rows (default=1)";
        print "\n\tprefix\t- sprite frame image prefix (default=source-f)";
        print "\n\tborder\t- size, in px, of transparent border padding to add to image (default=0)";
        print "\n\toddsize\t- set to allow odd-numbered width and height dimensions (default=0)";
	print "\n\ttransbg\t- which color of the background to change to transparent (default=magenta)";
        print "\n\n";
        exit;
}

my $image = new Image::Magick;

# get x and y resolution of source
my ($xsize, $ysize, $filesize, $fileformat) = $image->Ping($SOURCE);


# calc sprite x and y size
my $xsprite = $xsize / $COLS;
my $ysprite = $ysize / $ROWS;

print "\nExtracting $SPRITECOUNT sprites ($xsprite x $ysprite) from source strip ($xsize x $ysize)...\n";

#TODO maybe print a warning / prompt if image size is not an exact multiple of calculated width or height

my $row;
my $col;
my $num;
my $geometry;
foreach (1..$ROWS) {
        $row = $_;
        foreach (1..$COLS) {
                $col = $_;
                # calc which sprite number we're on
                $num = sprintf($DIGITS,($col + (($row - 1) * $COLS)));
                # find the sprite in the image
                $geometry = $xsprite . "x" . $ysprite . "+" . ($xsprite*($col-1)) . "+" . ($ysprite*($row-1));
                # ensure the variable is empty
                @$image = ();
                # now read the source image before processing the next sprite
                $image->Read($SOURCE);
                # crop it
                $image->Crop(geometry=>$geometry);
                # set magenta to transparent
                #FIXME this should maybe be automatic - pull color from first pixel?
                #FIXME maybe only if there is no alpha channel already? 
                $image->Set('alpha'=>'set');
                $image->Transparent($TRANSBG);
                # repage
                $image->Set('page'=>'0x0+0+0');
                # write to file
                $image->Write(filename=>"$PREFIX$num.png", compression=>'None');
        }
}



print "Sprite extraction complete. Optimizing sprite size...\n";



# shrink from south-east corner

my ($xmax, $ymax);
foreach (1..$SPRITECOUNT) {
        $num = sprintf($DIGITS,$_);
        # ensure the variable is empty
        @$image = ();
        # read the sprite
        $image->Read("$PREFIX$num.png");
        $image->Set(magick=>'RGBA');
        # store the north-west corner pixel value
        my @corner = my @corner2 = $image->GetPixel(x=>0, y=>0, channel=>'RGBA', normalize=>'true');
        $corner2[0] = 0;
        $corner2[1] = 1;
        $corner2[2] = 1;
        $corner2[3] = 0;
        $image->SetPixel(x=>0,y=>0,channel=>'RGBA',normalize=>'true',color=>\@corner2);
        # trim the south-east edges
        $image->Trim();
        # restore the pixel we overwrote
        $image->SetPixel(x=>0,y=>0,channel=>'RGBA',normalize=>'true',color=>\@corner);
        # repage
        $image->Set('page'=>'0x0+0+0');
        # find the biggest height and width so far
        my ($xtmp, $ytmp) = $image->Get('width','height');
        $xmax ||= $xtmp;
        $xmax = $xtmp if ($xtmp > $xmax);
        $ymax ||= $ytmp;
        $ymax = $ytmp if ($ytmp > $ymax);
        # write the image
        $image->Write("$PREFIX$num.png");
}

# optional transparent border padding
$xmax += $BORDER;
$ymax += $BORDER;

# now loop through and scale the canvas to the max size found in the previous loop
foreach (1..$SPRITECOUNT) {
        $num = sprintf($DIGITS,$_);
        @$image = ();
        $image->Read("$PREFIX$num.png");
        $image->Set(magick=>'RGBA');
        my $geometry = $xmax . "x" . $ymax;
        # increase canvas size 
        $image->Extent(geometry=>$geometry,background=>'transparent',gravity=>'NorthWest');
        # repage
        $image->Set('page'=>'0x0+0+0');
        # write the image
        $image->Write("$PREFIX$num.png");
}



# now we repeat the above two loops in the opposite direction


my ($xmax2, $ymax2);
foreach (1..($SPRITECOUNT)) {
        $num = sprintf($DIGITS,$_);
        # ensure the variable is empty
        @$image = ();
        # read the sprite
        $image->Read("$PREFIX$num.png");
        $image->Set(magick=>'RGBA');
        # store the south-east corner pixel value
        my @corner = my @corner2 = $image->GetPixel(x=>$xmax-1, y=>$ymax-1, channel=>'RGBA', normalize=>'true');
        #FIXME figure out a better color to use here and in the first loop
        $corner2[0] = 0;
        $corner2[1] = 1;
        $corner2[2] = 1;
        $corner2[3] = 0;
        $image->SetPixel(x=>$xmax-1,y=>$ymax-1,channel=>'RGBA',normalize=>'true',color=>\@corner2);
        # trim the north-west edges
        $image->Trim();
        # repage
        $image->Set('page'=>'0x0+0+0');
        # find the biggest height and width so far
        my ($xtmp, $ytmp) = $image->Get('width','height');
        $xmax2 ||= $xtmp;
        $xmax2 = $xtmp if ($xtmp > $xmax2);
        $ymax2 ||= $ytmp;
        $ymax2 = $ytmp if ($ytmp > $ymax2);
        # restore the pixel we overwrote
        $image->SetPixel(x=>$xtmp-1,y=>$ytmp-1,channel=>'RGBA',normalize=>'true',color=>\@corner);
        # write the image
        $image->Write("$PREFIX$num.png");
}

# optional transparent border padding
$xmax2 += $BORDER;
$ymax2 += $BORDER;

# make sure dimensions are even numbers unless this is disabled
$xmax2 +=1 if ($xmax2 % 2) and !$ALLOWODD;
$ymax2 +=1 if ($ymax2 % 2) and !$ALLOWODD;

# now loop through and scale the canvas north-east to the max size found in the previous loop
foreach (1..$SPRITECOUNT) {
        $num = sprintf($DIGITS,$_);
        @$image = ();
        $image->Read("$PREFIX$num.png");
        $image->Set(magick=>'RGBA');
        my $geometry = $xmax2 . "x" . $ymax2;
        # increase canvas size with gravity towards south-east
        $image->Extent(geometry=>$geometry,background=>'transparent',gravity=>'SouthEast');
        # repage
        $image->Set('page'=>'0x0+0+0');
        # write the image
        $image->Write("$PREFIX$num.png");
}

print "Optimization of sprites ($xmax2 x $ymax2) complete. All done!\n\n";
my $cmd = "animate -dispose 3 -delay 10 $PREFIX*";
print "Test using this:\n\t$cmd\n\n";

#TODO prompt asking if we should test
if ($TESTANIMATION) {
        system($cmd);
        #FIXME the below stuff works, but I can't figure out how to get it to render on a checkerboard and
        #FIXME to dispose of the previous frame, so we'll use the system() call for now.
        #@$image = ();
        #$image->Read("$PREFIX*.png");
        #$image->Animate(delay=>10,dispose=>'Previous',background=>'white',server=>':0'); #FIXME X server should be pulled from env
}

exit;
