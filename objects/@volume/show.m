function show( volumeArray, viewer )
% SHOW method uses a binary via the terminal to show volumes, such as :
% mrview, fslview, fsleyes, ...
% 
% IN CASE OF PROBLEM WITH THE LIBRARIES USED BY BINARIES :
%
% Using binary files via MATLAB 'system' function can be problematic.
% Usually it is the specific environement variables MATLAB redefines, such
% as LD_PATH_LIBRARY, that causes a mismatch between the library noramlly
% used by the viewer and the the specific versions MATLAB uses.
%
% Usually, you can reset locally the LD_PATH_LIBRARY environement variable
% just before calling the binary, such as :
% !LD_LIBRARY_PATH= mrview path/to/volume.nii &
% or
% !LD_LIBRARY_PATH= fslview path/to/volume.nii &
%
% The prepend arguments are SPECIFIC to YOUR SYSTEM, "LD_LIBRARY_PATH=" is
% the most common I've encountered so far.
%
% OUR SOLUTION :
%
% Write your prepend aruments inside the file : 
% objects/show_prepend.txt
% This file will be read by @volume/show method, and the content of this
% file will be prepend to the command calling the viewer.
%


%% Check input arguments

AssertIsVolumeArray(volumeArray);

if numel(volumeArray) == 0
    error('[@volume:show] no volume to show')
end

if nargin < 2
    viewer = 'mrview';
end


%% object/show_prepend.txt exists ?

file_fullpath = [matvoldir 'objects' filesep 'show_prepend.txt'];

if exist(file_fullpath,'file')
    
    fileID = fopen(file_fullpath,'r','n','UTF-8');
    if ~(fileID == -1)
        prepend_content = fread(fileID,'*char')'; % read the entire content as text
        fclose(fileID);
    else
        error('[@volume:show] Could not open in read mode file %s', file_fullpath)
    end
    
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
