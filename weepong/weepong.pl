#!/usr/bin/perl
#
#   Copyright [2010] [Sebastian Köhler]
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
#         FILE:  weepong.pl
#
#       AUTHOR:  Sebastian Köhler (sk), sebkoehler@whoami.org.uk
#      WEBSITE:  hg.whoami.org.uk
#      CREATED:  27.08.2010 19:54:04

use strict;
use warnings;

my $title = "Pong, Fuck Yeah!";
my $version = "0.1";
my $weepong_buffer;

my $ballx = 5;
my $bally = 15;
my @balldir = (1,1);

my $paddleheight = 3;
my $hpaddley = 4;
my $cpaddley = 4;

my $fieldx = 50;
my $fieldy = 20;

my $redraw_loop = "";
my $ai_loop = "";
my $ball_loop = "";

weechat::register("weepong", 'sebkoehler@whoami.org.uk',
                  $version, "Apache 2.0", "Pong, Fuck Yeah!", "", "");

weechat::hook_command("weepong", "Play Pong", "", 
                      "Keys:\n".
                      "   arrow up: move paddle up\n".
                      " arrow down: move paddle down\n".
                      " Use /weepong start to start a game", 
                      "", "weepong", "");

sub weepong_init {
    $weepong_buffer = weechat::buffer_search("perl", "weepong");
    if ($weepong_buffer eq "") {
        $weepong_buffer = weechat::buffer_new("weepong", "", "", "close", "");
    }
    if ($weepong_buffer ne "") {
        weechat::buffer_set($weepong_buffer, "type", "free");
        weechat::buffer_set($weepong_buffer, "title", $title);
        weechat::buffer_set($weepong_buffer, "key_bind_meta2-A", "/weepong up");
        weechat::buffer_set($weepong_buffer, "key_bind_meta2-B", "/weepong down");
        weechat::buffer_set($weepong_buffer, "key_bind_meta-n", "/weepong new_game");
        weechat::buffer_set($weepong_buffer, "key_bind_meta-p", "/weepong pause");
        weechat::buffer_set($weepong_buffer, "display", "1");
    }
}

sub ai_move {
    if($bally < $cpaddley && $cpaddley > 0) {
        $cpaddley--;
    }
    if($bally > ($cpaddley + $paddleheight/2) && $cpaddley < ($fieldy-1)) {
        $cpaddley++;
    }
}

sub ball_move { 
    $ballx += $balldir[0];
    $bally += $balldir[1];
    detect_collision();
}

sub detect_collision {
    if($bally >= ($fieldy-2) || $bally <= 1) {
        $balldir[1] *= -1;
    }
    if($ballx >= ($fieldx-2) && $bally >= $hpaddley && $bally <= ($hpaddley + $paddleheight)) {
        $balldir[0] *= -1;
    }
    if($ballx <= 1 && $bally >= $cpaddley && $bally <= ($cpaddley + $paddleheight)) {
        $balldir[0] *= -1;
    }
    if($ballx <= 0 || $ballx >= ($fieldx-1)) {
        $ballx = 10;
        $bally = 10;
        $balldir[0] *= -1;
        $balldir[1] *= -1;
    }
}

sub close {
    if($redraw_loop ne "") {
        weechat::unhook($redraw_loop);
    }
    if($ai_loop ne "") {
        weechat::unhook($ai_loop);
    }
    if($ball_loop ne "") {
        weechat::unhook($ball_loop);
    }
}

sub display_field {
    
    my $border = weechat::color(",white");
    for(my $x = 0; $x < $fieldx;$x++) {
        $border .= "-";
    }
    $border .= weechat::color(",default");

    weechat::print_y($weepong_buffer,0,$border);
    for(my $y = 1;$y < ($fieldy-1);$y++) {
        display_line($y);
    }
    weechat::print_y($weepong_buffer,$fieldy-1,$border);
    
}

sub display_line {
    my ($y) = @_;
    my $line = "";
    
    if($y >= $cpaddley && $y <= ($paddleheight + $cpaddley)) {
        $line .= weechat::color(",white");
        $line .= "|";
        $line .= weechat::color(",default");
    } else {
        $line .= " ";
    }

    for(my $x = 1;$x < ($fieldx-1);$x++) {
        if($x == $ballx && $y == $bally) {
            $line .= weechat::color(",white");
            $line .= "০";
            $line .= weechat::color(",default"); 
        } else {
            $line .= " ";
        }
    }

    if($y >= $hpaddley && $y <=($paddleheight + $hpaddley)) {
        $line .= weechat::color(",white");
        $line .= "|";
        $line .= weechat::color(",default");
    }
    weechat::print_y($weepong_buffer,$y,$line);
}

sub weepong {
    my ($data, $buffer, $args) = ($_[0], $_[1], $_[2]);
        
    if($args eq "start") {
        weepong_init();
        $redraw_loop = weechat::hook_timer(50,0,0,'display_field','');
        $ai_loop = weechat::hook_timer(150,0,0,'ai_move','');
        $ball_loop = weechat::hook_timer(100,0,0,'ball_move','');
    }
    if ($args eq "up") {
        if($hpaddley > 0) {
            $hpaddley--;
        }
    }
    if($args eq "down") {
        if((($hpaddley + $paddleheight) < $fieldy)) {
            $hpaddley++;
        }
    }
}
