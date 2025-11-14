function change_spm_path(fSPMmat, oldpath, newpath)
%
% CHANGE_SPM_PATH Change SPM.mat images path or folders name (part of path).
% CHANGE_SPM_PATH replaces 'oldpath' in path with 'newpath'


%   SPMmat   - SPM.mat (cell array)
%   oldpath - string part ot the old path that need to be change
%   newpath - string to replace 
%              directory in old_fdir must match a new directory in new_fdir.
%   example change_spm_path(fSPMmat, '/network/lustre/iss02/cenir','/network/iss/cenir')



% ---------EXAMPLES---------
%
%   fSPMmat = {'path to spm.mat'}
%   change_spm_path(fSPMmat,{'/iss01/'},{'/iss02/'})
%   change_spm_path(fSPMmat,{'/network/lustre/iss01/cenir'},{'/network/lustre/iss02/cenir'})
%   change_spm_path(fSPMmat,{'/lustre/iss01/'},{'/iss/'});
%
%   Original SPM.mat will be overwritten, so it's better to make a copy.
%
%--------------------------------------------------------------------------
% Mateus Joffily - CNC/CNRS - July/2007

% Copyright (C) 2006, 2010 Mateus Joffily, mateusjoffily@gmail.com.
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

% Initialize SPM
SPM = [];
oldpath = cellstr(oldpath);
newpath = cellstr(newpath);
% Get SPM.mat full path name
for nbr = 1:length(fSPMmat)
SPMmat   = spm_select('CPath', fSPMmat{nbr});

% Append .mat to SPMmat filename, if it doesn't exist
SPMmat = [spm_str_manip(SPMmat, 's') '.mat'];

% Get current SPM.mat directory
SPMnew = spm_str_manip(SPMmat, 'H');

% Load SPM.mat
if exist(SPMmat, 'file')
    load(SPMmat, 'SPM');
else
    disp(['SPM.mat file not found: ' SPMmat]);
    return
end

% Change statistic images path
%--------------------------------------------------------------------------
if isfield(SPM, 'swd')
    % Get old SPM path
    SPMold  = SPM.swd;

    % Set new SPM path
    SPM.swd = SPMnew;

    if isfield(SPM, 'Vbeta')
        new_fnames = strrep({SPM.Vbeta.fname}, SPMold, SPMnew);
        for i = 1:numel(new_fnames)
            SPM.Vbeta(i).fname = new_fnames{i};
        end
    end

    if isfield(SPM, 'VResMS')
        new_fnames = strrep({SPM.VResMS.fname}, SPMold, SPMnew);
        SPM.VResMS.fname = new_fnames{1};
    end

    if isfield(SPM, 'VM')
        new_fnames = strrep({SPM.VM.fname}, SPMold, SPMnew);
        SPM.VM.fname = new_fnames{1};
    end

    if isfield(SPM, 'xCon')
        for i = 1:numel(SPM.xCon)
            new_fnames = strrep({SPM.xCon(i).Vcon.fname}, SPMold, SPMnew);
            SPM.xCon(i).Vcon.fname = new_fnames{1};
            new_fnames = strrep({SPM.xCon(i).Vspm.fname}, SPMold, SPMnew);
            SPM.xCon(i).Vspm.fname = new_fnames{1};
        end
    end
end

% Change functional images path
%--------------------------------------------------------------------------
% current funtional images' path
fdir  = spm_str_manip(SPM.xY.P, 'H');
% current functional image's name
fname = spm_str_manip(SPM.xY.P, 't');

for i = 1:size(fdir,1)
   % idx = find(strcmp(old_fdir, fdir(i,:)));
    new_fnames = strrep({fdir(i,:)}, oldpath{1}, newpath{1});
    new_fname = char(fullfile(new_fnames, fname(i,:)));
    SPM.xY.P(i,1:length(new_fname)) = new_fname;
    ffname = strrep({SPM.xY.VY(i).fname},oldpath{1}, newpath{1});
    SPM.xY.VY(i).fname = ffname{1};
end
SPM.xY.P = deblank(SPM.xY.P);

% Save SPM.mat
save(SPMmat, 'SPM');

end
