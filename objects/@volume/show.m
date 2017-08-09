function show( volumeArray, viewer )
% SHOW method uses a binary via the terminal to show volumes, such as :
% mrview, fslview, fsleyes, ...
%
%
% IN CASE OF PROBLEM WITH THE LIBRARIES USED BY BINARIES :
% ======================================================
%
% Using binary files via MATLAB 'system' function can be problematic.
% Usually it is the specific environement variables MATLAB redefines, such
% as LD_PATH_LIBRARY, that causes a mismatch between the library noramlly
% used by the viewer and the the specific versions MATLAB uses.
%
% Usually, you can reset locally the LD_PATH_LIBRARY environement variable just before calling the binary, such as :
% !LD_LIBRARY_PATH= mrview path/to/volume.nii &
% or
% !LD_LIBRARY_PATH= fslview path/to/volume.nii &
%
% The prepend arguments are SPECIFIC to YOUR SYSTEM, "LD_LIBRARY_PATH=" is the most common I've encountered so far.
%
%
%
% OUR SOLUTION :
% ============
%
% Write your prepend aruments inside the function 'volume_show_prepend' that can be reached by MATLAB paths (your userpath for instance):
%
%---BEGUINING--------------------------------------------------------------
% function [ prepend ] = volume_show_prepend
%
% prepend = 'LD_LIBRARY_PATH='; % <--- write there your prepend arguments
%
% end
%---ENDING-----------------------------------------------------------------
%
% This file will be used by @volume/show method, to prepend to the command calling the viewer.
%
%
%
% OTHER TIP :
% =========
%
% If you want to set a default viewer, you can use a similar method, by creating a function 'volume_show_viewer' :
%
%---BEGUINING--------------------------------------------------------------
% function [ viewer ] = volume_show_viewer
%
% viewer = '/usr/bin/fslview'; % <--- write there your viewer name (mrview, fslview, fsleyes, ...)
%
% end
%---ENDING-----------------------------------------------------------------
%
%
%
% WARNING :
% =======
%
% It may be quit tricky to find the proper setup to use your viewer.
% Maybe you will need to add environment variables, at MATLAB startup for instance.


%% Check input arguments

AssertIsVolumeArray(volumeArray);

if numel(volumeArray) == 0
    error('[@volume:show] no volume to show')
end

if nargin < 2
    
    if which('volume_show_viewer')
        viewer = volume_show_viewer;
    else
        error('A viewer must be defined as input argument or by the user via the function volume_show_viewer. See the help for more info')
    end
    
end

assert(ischar(viewer),'viewer must be char')


%% User defined finction volume_show_prepend exists ?

if which('volume_show_prepend')
    prepend_content = volume_show_prepend;
else
    prepend_content = '';
end


%% Show with mrview, using the prefix (if they exist)

cmd = [ prepend_content ' ' viewer ];

for vol = 1 : numel(volumeArray)
    cmd = [cmd ' ' volumeArray(vol).path]; %#ok<AGROW>
end
cmd = [cmd ' &']; % the viewer do not pause matlab execution

system(cmd);


end % function
