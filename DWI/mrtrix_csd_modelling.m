function job = mrtrix_csd_modelling(fdwi,par)
%  MRTRIX_CSD_MODELLING : Compute ODF - 
% 
%
% Workflow, this function can do
%   Average f-response 
%   Upsampling dwi file and mask
%   Compute fod
%   Intensity normalisation
%   Note that this function by default compute juste FOD
%
% Inputs : 
%       
%       fdwi : cell table of dwi files
%       par  : matvol parameters structure
%            
%            .do_responsemean            : (1 or 0) Yes/No to compute average f-response 
%            .csd_type                   : (char) chose an algorithm to compute ODF
%            .do_intensity_normalisation : (1 or 0) Yes/No Intensity normalisation
%             ... see below             
%
% Need MRtrix3
%  
% Note that if you want to run Single-Shell 3-Tissue CSD (ss3t_csd_beta1), 
%      ensure that MRtrix3Tissue is installed
%
%
% --------------------------------------------------------------------------



if ~exist('par','var'), par = ''; end



defpar.response_wm  = 'response_wm.txt'; % (char) WM RF filename (default response_wm.txt). File must be in the same dir as fdwi input
defpar.response_gm  = '';   % (char) 'response_gm.txt' GM RF filename. File must be in the same dir as fdwi input
defpar.response_csf = '';   % (char) 'response_csf.txt' CSF RF filename. File must be in the same dir as fdwi input.

defpar.mask_name      = '';   % (char), filename of the input mask, must be in the same fdwi folder.
defpar.csd_type  = 'msmt_csd'; % (char) algorithm to choose : csd, msmt_csd, single_msmt_csd, (ss3t_csd_beta1 ???)
defpar.prefix_fodname = '';         % (char) define the prefix to be added to tissue fod name


% Average f-response 
defpar.do_responsemean = 0;   % Use 1 or 0 : Whether 1 the result will be saved in the first folder

% Upsampling dwi file and mask
defpar.do_upsampling     = 0;               % Use 1 or 0
defpar.prefix_upsampling = 'upsampling';    % (char) define the prefix to be added the new DWImage and mask name
defpar.voxel_size        = 1.25;            % define the voxel size for the new DWImage and mask (default value = 1.25)


% Intensity normalisation
defpar.do_intensity_normalisation = 0 ; % Use 1 or 0 for do or not Global normalization of intensity


defpar.grad_file = 'grad.b';   %       (char) gradient table in MRtrix format
defpar.bvec      = '';           
defpar.bval      = '';


defpar.redo  = 0;               % Use 0 or 1.
defpar.sge   = 1;
defpar.jobname       = 'voxel_modelling';
defpar.workflow_qsub = 0;       % Use 0 or 1.
par = complet_struct(par,defpar);


% Initialisation
cmd1job = '';          % RF mean
job     = {};          % job fod

assert(~isempty(par.mask_name),'par.mask_name must be defined');
mask_new_name = par.mask_name;

% Response Function
[dwi_dir, fdwi_name] =  get_parent_path(fdwi,1);
fwm  = fullfile(dwi_dir, par.response_wm);
fgm  = fullfile(dwi_dir, par.response_gm);
fcsf = fullfile(dwi_dir, par.response_csf);



%------------ Step 1
% Check RF and compute Response mean
switch par.csd_type
    
    case {'msmt_csd','ss3t_csd_beta1'}
        
        if any([isempty(par.response_wm) isempty(par.response_gm) isempty(par.response_csf)])  || isempty(par.response_wm)
            error('Define the 3 tissue responses function to use this %s algorithm', par.csd_type); % Ici, problème !
        end 
        
        if par.do_responsemean
            % Change par.response_*
            par.response_wm  = fullfile(dwi_dir{1},'average_response_wm.txt');
            par.response_gm  = fullfile(dwi_dir{1},'average_response_gm.txt');
            par.response_csf = fullfile(dwi_dir{1},'average_response_csf.txt');% fullfile
            
            if ~exist(par.response_wm, 'file') || par.redo
                cmd1 = sprintf('%s ',fwm{:});
                cmd1job  = sprintf('responsemean %s average_response_wm.txt -force',cmd1);
            end
            
            if ~exist(par.response_gm, 'file') || par.redo
                cmd1 = sprintf('%s ',fgm{:});
                cmd1job  = sprintf('%s\nresponsemean %s average_response_gm.txt -force',cmd1job,cmd1);
            end
            
            if ~exist(par.response_csf, 'file')|| par.redo
                cmd1 = sprintf('%s ',fcsf{:});
                cmd1job  = sprintf('%s\nresponsemean %s average_response_csf.txt -force',cmd1job,cmd1);
            end    
        end
        
    case 'single_msmt_csd'
        
        if  ~isempty(par.response_wm) && ~isempty(par.response_csf)
            
            % Change par.response_*
            par.response_wm  = fullfile(dwi_dir{1},'average_response_wm.txt');
            par.response_csf = fullfile(dwi_dir{1},'average_response_csf.txt');% fullfile
            
            if ~exist(par.response_wm, 'file') || par.redo
                cmd1 = sprintf('%s ',fwm{:});
                cmd1job  = sprintf('responsemean %s average_response_wm.txt -force',cmd1);
            end
            
            if ~exist(par.response_csf, 'file') || par.redo
                cmd1 = sprintf('%s ',fcsf{:});
                cmd1job  = sprintf('%s\nresponsemean %s average_response_csf.txt -force',cmd1job,cmd1);
            end
            
        elseif ~isempty(par.response_wm) %&& isempty(par.response_csf)
            
            % Change par.response_wm
            par.response_wm  = fullfile(dwi_dir{1},'average_response_wm.txt');
            
            if ~exist(par.response_wm, 'file') || par.redo
                cmd1 = sprintf('%s ',fwm{:});
                cmd1job  = sprintf('responsemean %s average_response_wm.txt -force',cmd1);
            end
        else
            error('WM response function must be defined');
        end
        
        % single shell and single tissue
    case 'csd'
        
        if isempty(~isempty(par.response_wm))
            error('WM response function must be defined');
        end
        
        if par.do_responsemean
            cmd1 = sprintf('%s ',fwm{:});
            cmd1job  = sprintf('responsemean %s average_response_wm.txt',cmd1);       
            
            % Change par.response_wm
            par.response_wm  = fullfile(dwi_dir{1},'average_response_wm.txt');
            if ~exist(par.response_wm, 'file') || par.redo
                cmd1     = sprintf('%s ',fwm{:});
                cmd1job  = sprintf('responsemean %s average_response_wm.txt -force',cmd1);
            end
        end
end

if ~isempty(cmd1job)
    cmd1job  = sprintf('cd %s\n %s',dwi_dir{1},cmd1job);
    if ~par.sge || ~par.workflow_qsub
        [status, coment] = unix('responsemean -version');
        if status == 127
            error('''responsemean''command not found, Check your mrtrix version')
        else
            unix(cmd1job);
        end
    end
end



%----------- Step 2
for nbsuj = 1:length(fdwi)
    
    % just check csf_fod file, to be coded for the other files
    dwifile = fullfile(dwi_dir{nbsuj}, [par.prefix_fodname 'csf_fod.nii']);   % Check if ODF exisite
    if exist(dwifile,'file') && par.redo == 0, skip = 1; else skip = 0; end
    
    % Skip subject have wm_
    if ~ skip
        cmd   = sprintf('cd %s\n', dwi_dir{nbsuj}) ;
        dwi_new_name = fdwi_name{nbsuj};
        
        if par.do_upsampling
            dwi_new_name = [par.prefix_upsampling '_' fdwi_name{nbsuj}];
            mask_new_name = [par.prefix_upsampling '_' par.mask_name];
            cmd = sprintf('%smrgrid  %s regrid -vox %f %s -force \n',cmd, fdwi_name{nbsuj},par.voxel_size, dwi_new_name);
            cmd = sprintf('%smrgrid  %s regrid -vox %f %s -force \n',cmd, par.mask_name,par.voxel_size,mask_new_name);
        end %
        
        
        % Estimate FOD : need dwi file and mask
        switch par.csd_type
            case 'csd'
                
                cmd = sprintf('%s\n dwi2fod csd %s %s %swm_fod.nii -mask %s -grad %s -force \n',...
                    cmd, dwi_new_name,par.response_wm,par.prefix_fodname, mask_new_name, par.grad_file);
                
                if par.do_intensity_normalisation
                    warning('Global normalization of intensity for a single tissue must be performed before calculating the response function using "dwinormalise group" script.');
                end
                
            case 'msmt_csd'
                cmd = sprintf('%s\ndwi2fod msmt_csd %s %s %swm_fod.nii %s %sgm_fod.nii %s %scsf_fod.nii -grad %s -mask %s -force\n'...
                    ,cmd, dwi_new_name, par.response_wm,par.prefix_fodname, par.response_gm, par.prefix_fodname, par.response_csf, par.prefix_fodname, par.grad_file, mask_new_name);
                
                if par.do_intensity_normalisation
                    
                    cmd = sprintf('%smtnormalise %swm_fod.nii wm_fod_norm.nii %sgm_fod.nii gm_fod_norm.nii %scsf_fod.nii csf_fod_norm.nii -mask %s -force\n', cmd, par.prefix_fodname, par.prefix_fodname, par.prefix_fodname, mask_new_name);
                end
                
            case 'single_msmt_csd'
                if ~isempty(par.response_csf)
                    
                    cmd = sprintf('%s\ndwi2fod msmt_csd %s %s %swm_fod.nii %s %scsf_fod.nii -grad %s -mask %s -force\n'...
                        ,cmd, dwi_new_name, par.response_wm,par.prefix_fodname, par.response_csf, par.prefix_fodname, par.grad_file, mask_new_name);
                    
                    if par.do_intensity_normalisation
                        
                        cmd = sprintf('%smtnormalise %swm_fod.nii wm_fod_norm.nii %scsf_fod.nii csf_fod_norm.nii -mask %s -force\n', cmd, par.prefix_fodname, par.prefix_fodname, mask_new_name);
                        warning('It''s not recommanded to use mtnormalise in this approach, check the mrtrix3 documentation.');
                        disp('Press to continue')
                    end
                else
                    cmd = sprintf('%s\n dwi2fod msmt_csd %s %s %swm_fod.nii -mask %s -grad %s -force \n',...
                        cmd, dwi_new_name,par.response_wm,par.prefix_fodname, mask_new_name, par.grad_file);
                    if par.do_intensity_normalisation
                        % use mtnormalise ???  to be coded
                    end
                end
                
            case 'ss3t_csd_beta1'
                
                fprintf('Using Single-Shell 3-Tissue CSD: ensure that MRtrix3Tissue is installed.\n');
                % pause
                cmd = sprintf('%s mrconvert %s -grad %s dwi_prep_tem.mif -force\n',cmd,dwi_new_name,par.grad_file); % pipe fonctionnepas
                cmd = sprintf('%s ss3t_csd_beta1 dwi_prep_tem.mif %s %swm_fod.nii %s %sgm_fod.nii %s %scsf_fod.nii -mask %s -force\n'...
                    ,cmd,par.response_wm, par.prefix_fodname, par.response_gm, par.prefix_fodname, par.response_csf, par.prefix_fodname, mask_new_name);
                
                if par.do_intensity_normalisation
                    
                    cmd = sprintf('%smtnormalise %swm_fod.nii wm_fod_norm.nii %sgm_fod.nii gm_fod_norm.nii %scsf_fod.nii csf_fod_norm.nii -mask %s -force\n', cmd, par.prefix_fodname, par.prefix_fodname, par.prefix_fodname, mask_new_name)
                end
            otherwise
                error('Error. \nUnknown %s algorithm', par.csd_type)
        end % par.csd_type. < wm_fod.nii or wm_fod_norm ...>
        
        
        
        
        job{end+1} = cmd;
    end % ~ skip
    
    
end % for

if par.sge && ~isempty(cmd1job) && par.workflow_qsub
    jobname = par.jobname;
    par.jobname = 'mean_response';
    
    do_cmd_sge({cmd1job},par);
    par.jobname = jobname;
end

job = do_cmd_sge(job,par);



end







