function jobs = job_apply_normalize(warp_field,img, par)
% JOB_APPLY_NORMALIZE - SPM:Spatial:Normalise:Write
%
% for spm12 warp_field, is indeed the flow field y_*.nii or iy_*.nii
%
% To build the image list easily, use get_subdir_regex & get_subdir_regex_files
%
% See also job_do_segment get_subdir_regex get_subdir_regex_files


%% Check input arguments

if ~exist('par','var')
    par = ''; % for defpar
end

if nargin < 2
    error('[%s]: not enough input arguments - warp_filed & imagelist are required',mfilename)
end


%% defpar

% SPM:Spatial:Normalise:Write options
defpar.preserve = 0;
defpar.bb       = [-78 -112 -70 ; 78 76 85];
defpar.vox      = [2 2 2];
defpar.interp   = 4;
defpar.wrap     = [0 0 0];
defpar.prefix   = 'w';

defpar.redo    = 0;
defpar.sge     = 0;
defpar.run     = 0;
defpar.display = 0;
defpar.jobname = 'spm_apply_norm';

par = complet_struct(par,defpar);


%% SPM:Spatial:Normalise:Write

% Check spm_version
[~ , r]=spm('Ver','spm');

skip = [];

for subj = 1:length(warp_field)
    
    if strfind(r,'SPM8')
        
        jobs{subj}.spm.spatial.normalise.write.subj(1).matname = warp_field(subj); %#ok<*AGROW>
        jobs{subj}.spm.spatial.normalise.write.subj(1).resample = cellstr(img{subj});
        jobs{subj}.spm.spatial.normalise.write.roptions.preserve =  par.preserve;
        jobs{subj}.spm.spatial.normalise.write.roptions.bb =  par.bb;
        jobs{subj}.spm.spatial.normalise.write.roptions.vox = par.vox;
        jobs{subj}.spm.spatial.normalise.write.roptions.interp = par.interp;
        jobs{subj}.spm.spatial.normalise.write.roptions.wrap = par.wrap;
        jobs{subj}.spm.spatial.normalise.write.roptions.prefix = par.prefix;
        
    elseif strfind(r,'SPM12')
        
        jobs{subj}.spm.spatial.normalise.write.subj(1).def = warp_field(subj);
        jobs{subj}.spm.spatial.normalise.write.subj(1).resample = cellstr(img{subj});
        % Test if exist
        folast = addprefixtofilenames(cellstr(char(img(subj))),par.prefix);
        if ~par.redo   &&  exist(folast{end},'file')
            skip = [skip subj];
            fprintf('[%s]: skiping subj %d because %s exist \n',mfilename,subj,folast{1});
        end
        jobs{subj}.spm.spatial.normalise.write.woptions.bb = par.bb;
        jobs{subj}.spm.spatial.normalise.write.woptions.vox = par.vox;
        jobs{subj}.spm.spatial.normalise.write.woptions.interp = par.interp;
        jobs{subj}.spm.spatial.normalise.write.woptions.prefix = par.prefix;
        
    end
    
end


%% Other routines

% Skip the empty jobs
jobs(skip) = [];

if isempty(jobs)
    return
end


if par.sge
    for k=1:length(jobs)
        j       = jobs(k); %#ok<NASGU>
        cmd     = {'spm_jobman(''run'',j)'};
        varfile = do_cmd_matlab_sge(cmd,par);
        save(varfile{1},'j');
    end
end


if par.display
    spm_jobman('interactive',jobs);
    spm('show');
end


% Run !
if par.run
    spm_jobman('run',jobs)
end


end % function
