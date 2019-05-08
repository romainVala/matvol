function job = job_afni_despike( img , par )
% JOB_AFNI_DESPIKE - AFNI:3dDespike
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
    in_obj  = img;
    img = in_obj.toJob(1);
end


%% defpar

% 3dDespike options
defpar.method  = ''; % NEW, NEW25, localedit (afni default is NEW)
defpar.mask    = 0 ; % 0 / 1 (afni default is yes+dilate4)
defpar.dilate  = []; % 1, 2, 3, 4, ... (afni default is yes+dilate4)
defpar.cmd_arg = ''; % Allows you to use all addition arguments not scripted in this job_afni_despike.m file

defpar.prefix          = 'd';
defpar.OMP_NUM_THREADS = 0; % number pf CPU threads : 0 means all CPUs available

defpar.sge      = 0;
defpar.jobname  = 'job_afni_despike';
defpar.walltime = '00:30:00';

defpar.auto_add_obj = 1;

defpar.pct      = 0;
defpar.redo     = 0;
defpar.run      = 0;
defpar.display  = 0;
defpar.verbose  = 1;

par = complet_struct(par,defpar);

% Security
if par.sge
    par.auto_add_obj = 0;
end
if par.sge || par.pct
    par.OMP_NUM_THREADS = 1; % in case of parallelization, only use 1 thread per job
end


%% Setup that allows this scipt to prepare the commands only, no execution

parsge  = par.sge;
par.sge = -1; % only prepare commands

parverbose  = par.verbose;
par.verbose = 0; % don't print anything yet


%% 3dDespike

nSubj = length(img);
job  = cell(0);

cjob = 0;
for iSubj = 1 : nSubj
    
    for vol = 1 : length(img{iSubj})
        
        src = deblank( img{iSubj}{vol} ) ;
        
        % output exists ?
        dst = addprefixtofilenames( src , par.prefix );
        if ~par.redo   &&   exist(dst,'file')
            fprintf('[%s]: skiping subj/vol %d/%d because %s exist \n',mfilename,iSubj,vol,dst);
        else
            
            cjob = cjob + 1;
            
            N = nifti(src);
            
            if length(N.dat.dim) == 4
                if N.dat.dim(4) < 15
                    [ ~ , cmd ] = r_movefile(src, dst, 'linkn', par); % cannot do 3dDespike with less than 15 volumes
                else
                    % main command (1/2)
                    cmd = '';
                    cmd = sprintf('%s export OMP_NUM_THREADS=%d; 3dDespike -overwrite', cmd, par.OMP_NUM_THREADS);
                    
                    % options
                    if ~isempty(par.method), cmd = sprintf('%s -%s', cmd, par.method); end
                    if ~isempty(par.mask  )
                        if par.mask == 1
                            if ~isempty(par.dilate)
                                cmd = sprintf('%s -dilate %d', cmd, par.dilate);
                            else
                                % pass, use default setting
                            end
                        elseif par.mask == 0
                            cmd = sprintf('%s -nomask', cmd);
                        end
                    else
                        if ~isempty(par.dilate), cmd = sprintf('%s -dilate %d', cmd, par.dilate); end
                    end
                    if ~isempty(par.cmd_arg), cmd = sprintf('%s %s', cmd, par.cmd_arg); end
                    
                    % main command (2/2)
                    cmd = sprintf('%s -prefix %s %s; \n', cmd, dst, src);
                end
            else
                [ ~ , cmd ] = r_movefile(src, dst, 'linkn', par); % cannot do 3dDespike with less than 15 volumes
            end
            
            job{cjob,1} = char(cmd);
            
        end
        
    end % vol
    
end % iSubj


%% Run the jobs

% Fetch origial parameters, because all jobs are prepared
par.sge     = parsge;
par.verbose = parverbose;

% Run CPU, run !
job = do_cmd_sge(job, par);


%% Add outputs objects

if obj && par.auto_add_obj && par.run
    
    tag             =  {in_obj.tag};
    ext             = '.*.nii$';
    for iVol = 1 : numel(in_obj)
        in_obj(iVol).serie.addVolume(['^' par.prefix tag{iVol} ext],[par.prefix tag{iVol}])
    end
    
end


end % function
