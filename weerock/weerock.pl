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
#===============================================================================
#
#         FILE:  weerock.pl
#
#  DESCRIPTION:  WeeChat Pluging to show others youre good taste in music
#                
#                Supported Players:
#                   audacious
#                   banshee
#                   exaile
#                   moc
#                   mpc
#                   ncmpcpp
#                   pytone
#                   quod libet
#                   rhytmbox(requires Net::DBus)
#
# REQUIREMENTS:  weechat 3.1+,one of the above players
#       AUTHOR:  Sebastian Köhler (sk), sebkoehler@whoami.org.uk
#      WEBSITE:  http://hg.whoami.org.uk/weerock
#      VERSION:  0.3
#      CREATED:  31.01.2010 04:17:41
#===============================================================================

use strict;

my $description = "Rock this chat!";
my $helptext = "Use this command to show your current song in the channel\n\n";

weechat::register('weerock','Sebstian Köhler','0.3','Apache 2.0',
                   $description,'','');

weechat::hook_command('audacious',$description,"","$helptext","","audacious",
                      "");

weechat::hook_command('banshee',$description,"","$helptext","","banshee","");

weechat::hook_command('exaile',$description,"","$helptext","","exaile","");

weechat::hook_command('moc',$description,"","$helptext","","moc","");

weechat::hook_command('mpc',$description,"",
                      "$helptext".
                      "SETTINGS\n".
                      "    /set plugins.var.perl.weerock.mpc_host PASSWORD\@IP\n".
                      "        Default: localhost\n".
                      "    /set plugins.var.perl.weerock.mpc_port PORT\n".
                      "        Default: 6600\n",
                      "","mpc","");

weechat::hook_command('ncmpcpp',$description,"",
                      "$helptext".
                      "SETTINGS".
                      "    /set plugins.var.perl.weerock.ncmpcpp_host PASSWORD\@IP\n".
                      "        Default: localhost\n".
                      "    /set plugins.var.perl.weerock.ncmpcpp_port PORT\n".
                      "        Default: 6600\n",
                      "","ncmpcpp","");

weechat::hook_command('pytone',$description,"","$helptext","","pytone","");

weechat::hook_command('quodlibet',$description,"","$helptext","","quodlibet",
                      "");

weechat::hook_command('rhythmbox',$description,"","$helptext","","rhythmbox",
                      "");

weechat::hook_command('weerock',$description,"","Show help for weerock","",
                      "weerock","");

return weechat::WEECHAT_RC_OK;

sub audacious {
    load_defaults();
    my $cmd = "audtool2 --current-song-tuple-data artist ".
                       "--current-song-tuple-data album ".
                       "--current-song-tuple-data title ".
                       "--current-song-output-length-seconds ".
                       "--current-song-length-seconds 2> /dev/null";
    my $exp = "(.*)\n(.*)\n(.*)\n(.*)\n(.*)";
 
    exec_to_channel($cmd,$exp,'audacious',(0,1,2,3,4));
}

sub banshee {
    load_defaults();
    my $cmd = "banshee --query-artist --query-album --query-title ".
                      "--query-position --query-duration 2> /dev/null";
    my $exp = "artist: (.*)\nalbum:\ (.*)\ntitle: (.*)\nposition: ".
              "(.*),.*\nduration: (.*),.*";
   
    exec_to_channel($cmd,$exp,'banshee',(0,1,2,3,4));
}

sub exaile {
    load_defaults();
    my $cmd = "exaile --get-artist --get-album --get-title ".
              "--current-position --get-length 2>/dev/null";
    my $exp = "(.*)\n(.*)\n(.*)\n(.*)\n(.*)";

    exec_to_channel($cmd,$exp,'exaile',(0,1,2,3,4));
}

sub moc {
    load_defaults();
    my $cmd = "mocp -i 2> /dev/null";
    my $exp = "Artist: (.*)\n.*: (.*)\n.*: (.*)\n.*: (.*)\n.*\n.*\n.*: (.*)";
    
    exec_to_channel($cmd,$exp,'mocp',(0,2,1,4,3));
}

sub mpc {
    load_defaults();
    my $host = weechat::config_get_plugin("mpc_host");
    my $port = weechat::config_get_plugin("mpc_port");
    my $cmd = "mpc status -h $host -p $port -f \"%artist% #| ".
              "%album% #| %title%\"";
    my $exp = '(.*) \| (.*) \| (.*)\n.*(\d+:\d{2})/(\d+:\d{2})';
   
    exec_to_channel($cmd,$exp,'mpd',(0,1,2,3,4));
}

sub ncmpcpp {
    load_defaults();
    my $host = weechat::config_get_plugin("ncmpcpp_host");
    my $port = weechat::config_get_plugin("ncmpcpp_port");
    my $cmd = "ncmpcpp -h $host -p $port --now-playing ".
              "'%a ^ %b ^ %t' 2> /dev/null";
    my $exp = '(.*) \^ (.*) \^ (.*)';
    
    exec_to_channel($cmd,$exp,'mpd',(0,1,2,3,4));
}

sub pytone {
    load_defaults();
    my $cmd = "pytonectl getplayerinfo 2> /dev/null";
    my $exp = '(.*) - (.*) \( (\d?\d:\d\d)\/ (\d?\d:\d\d)\)';

    exec_to_channel($cmd,$exp,'pytone',(0,4,1,2,3));
}

sub quodlibet {
    load_defaults();
    my $cmd = "quodlibet --print-playing 2> /dev/null";
    my $exp = "(.*) \- (.*) \- .* \- (.*)";
    
    exec_to_channel($cmd,$exp,'quodlibet',(0,1,2,3,4));
}

sub rhythmbox {
    require Net::DBus;
    
    load_defaults();

    my ($artist,$album,$title,$ct,$tt) = ("","","","","");

    if(`pgrep rhythmbox`) {
        my $bus = Net::DBus->session;
        my $rboxservice = $bus->get_service("org.gnome.Rhythmbox");
        my $rboxplayer = $rboxservice->get_object("/org/gnome/Rhythmbox/Player");
        my $rboxshell = $rboxservice->get_object("/org/gnome/Rhythmbox/Shell");
        
        if($rboxplayer->getPlaying()) {
            my $song = $rboxshell->getSongProperties($rboxplayer->getPlayingUri());
            my $ct = sec_to_min($rboxplayer->getElapsed());
            if(exists $song->{'artist'}) {
                $artist = $song->{'artist'};
            }
            if(exists $song->{'title'}) {
                $title = $song->{'title'};
            }
            if(exists $song->{'album'}) {
                $album = $song->{'album'};
            }
            if(exists $song->{'duration'}) {
                $tt = sec_to_min($song->{'duration'});
            }
        }
    }
    echo_to_channel(build_message($artist,$album,$title,$ct,$tt));
}

sub weerock {
    my $bold   = weechat::color("bold");
    my $unbold = weechat::color("-bold");
    
    my $help = "%bold%NAME%unbold%\n".
               "    weerock - $description\n".
               "%bold%COMMANDS%unbold%\n".
               "    /audacious\n".
               "    /banshee\n".
               "    /exaile\n".
               "    /moc\n".
               "    /mpc\n".
               "    /ncmpcpp\n".
               "    /pytone\n".
               "    /quodlibet\n".
               "    /rhythmbox\n\n".
               "    For more information do:\n".
               "    /help command\n\n".
               "%bold%GLOBAL SETTINGS%unbold%\n".
               "    /set plugins.var.perl.weerock.format STRING\n".
               "        STRING will be send to the Channel\n".
               "        Following Variables are available:\n".
               "            %artist% - Artist\n".
               "            %album%  - Album\n".
               "            %title%  - Title\n".
               "            %ct%     - Current Time\n".
               "            %tt%     - Total Time\n".
               "        Default: \"%artist%(%album%) - %title% [%ct%/%tt%]\"\n".
               "    /set plugins.var.perl.weerock.left_string STRING\n".
               "        STRING is printed before the song information\n".
               "        Default: \"/me np \"\n".
               "    /set plugins.var.perl.weerock.right_string STRING\n".
               "        STRING is printed after the song information\n".
               "        Default: \"\"";
    
    $help =~ s/%bold%/$bold/g;
    $help =~ s/%unbold%/$unbold/g;
    echo_to_buffer($help);
}

#
##
### Basic functions
##
#

sub exec_to_channel {
    my ($cmd,$exp,$program,@ord) = @_;
    
    if(`pgrep $program`) {

        my @data = `$cmd` =~ /$exp/;
        $data[$ord[3]] = sec_to_min($data[$ord[3]]);
        $data[$ord[4]] = sec_to_min($data[$ord[4]]);
        echo_to_channel(build_message($data[$ord[0]]||'',$data[$ord[1]]||'',$data[$ord[2]]||'',$data[$ord[3]]||'',$data[$ord[4]]||''));   
    }
}

sub echo_to_channel {
    my ($string) = @_;
    my $buffer = weechat::current_buffer;
    my $left_string = weechat::config_get_plugin("left_string");
    my $right_string = weechat::config_get_plugin("right_string" eq "");
    weechat::command($buffer, "$left_string" . $string . "$right_string");
}

sub echo_to_buffer {
    my ($string) = @_;
    my $buffer = weechat::current_buffer;
    weechat::print($buffer,$string);
}

sub sec_to_min {
    my ($sec) = @_;
    if(! $sec) { return 0; }
    if($sec =~ /\d+:\d+/) { return $sec; }
    return int($sec/60).":".sprintf("%02d",$sec%60);
}

sub build_message {
    my ($artist, $album, $title, $ct, $tt) = @_;
    my $message = weechat::config_get_plugin("format");

    $message =~ s/%artist%/$artist/g;
    $message =~ s/%album%/$album/g;
    $message =~ s/%title%/$title/g;
    $message =~ s/%ct%/$ct/g;
    $message =~ s/%tt%/$tt/g;
    $message =~ s/\n//g;

    return $message;
}


sub load_defaults {
    if(weechat::config_get_plugin("mpc_host") eq "") {
        weechat::config_set_plugin("mpc_host", "localhost");
    }
    if(weechat::config_get_plugin("mpc_port") eq ""){
        weechat::config_set_plugin("mpc_port", 6600);
    }
    if(weechat::config_get_plugin("ncmpcpp_host") eq ""){
        weechat::config_set_plugin("ncmpcpp_host", "localhost");
    }
    if(weechat::config_get_plugin("ncmpcpp_port") eq ""){
        weechat::config_set_plugin("ncmpcpp_port", "6600"); 
    }
    if(weechat::config_get_plugin("left_string" eq "")) {
        weechat::config_set_plugin("left_string", "/me np ");
    }
    if(weechat::config_get_plugin("right_string" eq "")) {
        weechat::config_set_plugin("right_string", "");
    }
    if(weechat::config_get_plugin("format") eq "") {
        weechat::config_set_plugin("format", "%artist%(%album%) ".
                                             "- %title% [%ct%/%tt%]");
    }
}
