function jobs = job_apply_normalize(warp_field,img, par)
% JOB_APPLY_NORMALIZE - SPM:Spatial:Normalise:Write
%
% INPUT : warp_field & img can be 'char' of volume(file), single-level 'cellstr' of volume(file), '@volume' array
%
% for spm12 warp_field, is indeed the flow field y_*.nii or iy_*.nii
%
% To build the image list easily, use get_subdir_regex & get_subdir_regex_files
%
% See also job_do_segment get_subdir_regex get_subdir_regex_files exam exam.AddSerie exam.addVolume


%% Check input arguments

if ~exist('par','var')
    par = ''; % for defpar
end

if nargin < 1
    help(mfilename)
    error('[%s]: not enough input arguments - warp_filed & imagelist are required',mfilename)
end

obj = 0;
if isa(img,'volume')
    obj = 1;
    in_obj = img;
    img    = in_obj.toJob(1);
    for i = 1 : length(img)
        img{i} = char(img{i}(~cellfun(@isempty,img{i}))); % remove empty lines
    end
    warp_field = warp_field.toJob;
elseif ischar(img) || iscellstr(img)
    % Ensure the inputs are cellstrings, to avoid dimensions problems
    img = cellstr(img)';
else
    error('[%s]: wrong input format (cellstr, char, @volume)', mfilename)
end


%% defpar

% SPM:Spatial:Normalise:Write options
defpar.preserve = 0;
defpar.bb       = [-78 -112 -70 ; 78 76 85];
defpar.vox      = [2 2 2];
defpar.bb       = [NaN NaN NaN ; NaN NaN NaN];
defpar.vox      = [NaN NaN NaN];
defpar.interp   = 4;
defpar.wrap     = [0 0 0];
defpar.prefix   = 'w';

defpar.redo    = 0;
defpar.sge     = 0;
defpar.run     = 0;
defpar.display = 0;
defpar.jobname = 'spm_apply_norm';

defpar.auto_add_obj = 1;

par = complet_struct(par,defpar);

% Security
if par.sge
    par.auto_add_obj = 0;
end


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

[ jobs ] = job_ending_rountines( jobs, skip, par );


%% Add outputs objects

if obj && par.auto_add_obj
    
    serieArray = [in_obj.serie];
    tag        =  in_obj(1).tag;
    ext        = '.*.nii$';
    
    serieArray.addVolume(['^' par.prefix tag ext],[par.prefix tag])
    
end


end % function
