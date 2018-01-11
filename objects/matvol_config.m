function [ p ] = matvol_config
%MATVOL_CONFIG
% matvol users have to make a copy of this file, place the copy in a directory which path is over matvol install dir.
% Usualy, the userpath is a good position, because it is automaticly in the highest position at matlab startup.


% --- @volume/show --------------------------------------------------------
% see 'help volume.show' for more info

% Prepend arguments to the terminal line sent via matlab
p.volume_show_prepend = 'LD_LIBRARY_PATH=';

% Your viewer name (mrview, fslview, fsleyes, ...)
p.volume_show_viewer  = 'mrview';


% --- @mvObject/mvObject (constructor) --------------------------------------------------------
p.mvObject_cfg = struct;
p.mvObject_cfg.allow_duplicate   = 0;
p.mvObject_cfg.remove_duplicates = 1;

end % function
