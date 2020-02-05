function  jobs = job_smooth(img,par)
% JOB_SMOOTH - SPM:Spatial:Smooth
%
% INPUT : img can be 'char' of volume(file), multi-level 'cellstr' of volume(file), '@volume' array
%
% To build the image list easily, use get_subdir_regex & get_subdir_regex_files
%
% See also get_subdir_regex get_subdir_regex_files exam exam.AddSerie exam.addVolume


%% Check input arguments

if ~exist('par','var')
    par = ''; % for defpar
end

if nargin < 1
    help(mfilename)
    error('[%s]: not enough input arguments - img is required',mfilename)
end

obj = 0;
if isa(img,'volume')
    obj = 1;
    volumeArray  = img;
    img = volumeArray.toJob(0);
end


%% defpar

% SPM:Spatial:Smooth
defpar.smooth   = [8 8 8];
defpar.prefix   = 's';

% cluster
defpar.sge      = 0;
defpar.jobname  = 'spm_smooth';
defpar.walltime = '00:30:00';

% matvol classics
defpar.redo         = 0;
defpar.run          = 1;
defpar.display      = 0;
defpar.auto_add_obj = 1;


par = complet_struct(par,defpar);


%% SPM:Spatial:Smooth

skip = [];

for subj = 1 : length(img)
    % Test if exist
    folast = addprefixtofilenames(cellstr(char(img(subj))),par.prefix);
    if ~par.redo   &&  exist(folast{end},'file')
        skip = [skip subj];
        fprintf('[%s]: skiping subj %d because %s exist \n',mfilename,subj,folast{1});
    end
    jobs{subj}.spm.spatial.smooth.data = cellstr(char(img(subj))); %#ok<*AGROW>
    jobs{subj}.spm.spatial.smooth.fwhm = par.smooth;
    jobs{subj}.spm.spatial.smooth.dtype = 0;
    jobs{subj}.spm.spatial.smooth.prefix = par.prefix;
end


%% Other routines

[ jobs ] = job_ending_rountines( jobs, skip, par );


%% Add outputs objects

if obj && par.auto_add_obj && (par.run || par.sge)
    
    for iVol = 1 : length(volumeArray)
        
        % Shortcut
        vol = volumeArray(iVol);
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
