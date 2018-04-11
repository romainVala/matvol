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
% Write your prepend aruments inside the matvol_config.m file that can be reached by MATLAB paths (your userpath for instance)
% This file will be used by @volume/show method, to prepend to the command calling the viewer.
%
% If you want to set a default viewer, you can use the same method
%
%
%
% WARNING :
% =======
%
% It may be quit tricky to find the proper setup to use your viewer.
% Maybe you will need to add environment variables, at MATLAB startup for instance.


%% Check input arguments

volumeArray = shiftdim(volumeArray,1); % need to shift dimensions to have the volumes displayed in meaningful order.

if numel(volumeArray) == 0
    error('[@volume:show] no volume to show')
end

% Load user cfg
p = matvol_config;
prepend_content = p.volume_show_prepend;

if nargin < 2
    viewer = p.volume_show_viewer;
end

assert(ischar(viewer),'viewer must be char')

    
%% Show with mrview, using the prefix (if they exist)

cmd = [ prepend_content ' ' viewer ];

for vol = 1 : numel(volumeArray)
    for p = 1 : size(volumeArray(vol).path,1)
        cmd = [cmd ' ' volumeArray(vol).path(p,:)]; %#ok<AGROW>
    end
end
cmd = [cmd ' &']; % the viewer do not pause matlab execution

system(cmd);


end % function
