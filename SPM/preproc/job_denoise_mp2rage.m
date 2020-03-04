function  jobs = job_denoise_mp2rage(INV1,INV2,UNI,par)
% JOB_DENOISE_MP2RAGE - SPM:Tools:mp2rage:rmbg
%
% INPUT : img can be 'char' of volume(file), multi-level 'cellstr' of volume(file), '@volume' array
%
% To build the image list easily, use get_subdir_regex & get_subdir_regex_files
%
% See also mp2rage_main_remove_background get_subdir_regex get_subdir_regex_files exam exam.AddSerie exam.addVolume


%% Check input arguments

if ~exist('par','var')
    par = ''; % for defpar
end

if nargin < 1
    help(mfilename)
    error('[%s]: not enough input arguments - img is required',mfilename)
end

obj = 0;
if isa(INV1,'volume') 
    obj = 1;
    volumeArray_INV1 = INV1;
    volumeArray_INV2 = INV2;
    volumeArray_UNI  = UNI;
    INV1 = volumeArray_INV1.toJob(0);
    INV2 = volumeArray_INV2.toJob(0);
    UNI  = volumeArray_UNI .toJob(0);
end

assert( length(INV1) == length(INV2) && length(INV1) == length(UNI), 'INV1, INV2 & UNI must have the samie dimension' )


%% defpar

% SPM:Tools:mp2rage:rmbg
defpar.regularization = 50;
defpar.prefix         = 'c';

% cluster
defpar.sge      = 0;
defpar.mem      = '4G'; % (need more than 1G for this job)
defpar.jobname  = 'spm_mp2rage_denoise_T1';
defpar.walltime = '00:30:00';

% matvol classics
defpar.redo         = 0;
defpar.run          = 1;
defpar.display      = 0;
defpar.auto_add_obj = 1;


par = complet_struct(par,defpar);


%% SPM:Spatial:Smooth

skip = [];

jobs = cell(1,length(UNI));

for subj = 1 : length(UNI)
    % Test if exist
    output = addprefixtofilenames(cellstr(char(UNI(subj))),par.prefix);
    if ~par.redo   &&  exist(output{end},'file')
        skip = [skip subj]; %#ok<AGROW>
        fprintf('[%s]: skiping subj %d because %s exist \n',mfilename,subj,output{1});
    end
    jobs{subj}.spm.tools.mp2rage.rmbg.INV1            = INV1(subj);
    jobs{subj}.spm.tools.mp2rage.rmbg.INV2            = INV2(subj);
    jobs{subj}.spm.tools.mp2rage.rmbg.UNI             = UNI (subj);
    jobs{subj}.spm.tools.mp2rage.rmbg.regularization  = par.regularization;
    jobs{subj}.spm.tools.mp2rage.rmbg.output.prefix   = par.prefix;
    jobs{subj}.spm.tools.mp2rage.rmbg.show            = 'no';
end


%% Other routines

[ jobs ] = job_ending_rountines( jobs, skip, par );


%% Add outputs objects

if obj && par.auto_add_obj && (par.run || par.sge)
    
    for iVol = 1 : length(volumeArray_UNI)
        
        % Shortcut
        vol = volumeArray_UNI(iVol);
        ser = vol.serie;
        tag = vol.tag;
        
        if par.run
            
            ext  = '.*.nii';
            
            ser.addVolume(['^' par.prefix tag ext],[par.prefix tag],1)
            
        elseif par.sge
            
            ser.addVolume('root', addprefixtofilenames(vol.path,par.prefix),[par.prefix tag])
            
        end
        
    end % iVol
    
end % obj


end % function
