function job = job_do_SIAM(fanat,par)
% JOB_DO_SIAM  : human brain segmentation from any MRI 3D volume
%
%
% Inputs : 
%        fanat  : provide "cellstr" of 3d images path
%        par    : siam & matvol parameters 
%        
% environment :
% 
%   source /network/iss/cenir/software/irm/bin/siam_path
%
% For more information see : https://github.com/romainVala/SIAM
%
%

if ~exist('par'), par = ''; end


defpar.device      = 'cpu';             % Take "char": 'cpu', 'maps', or ''. Note that '' means running by default in GPU mode
defpar.prefix      = '';                % Provide prefix as a string; if empty, a default will be used.

defpar.model       = 0;                 % Chose the model : -1, 0, 1, ...
defpar.voxelsize   = [];                %


defpar.sge      = 1;
defpar.jobname  = 'SIAM';
defpar.mem      = '32G';
defpar.walltime = '06';    % string hours
defpar.nbthread = 4;       % cpus-per-task

par = complet_struct(par,defpar);


if isempty(par.prefix)
    prefix = '';
    regex  = 'siamV'
else
    prefix = ['-o ' par.prefix];
    regex  = prefix;
end




if par.disable_tta
    disable_tta = '--disable_tta';
else
    disable_tta = '';
end

switch par.device
    case 'cpu'
        device = '-device cpu';
    case 'maps'
        device = '-device maps';
    otherwise
        device = '';
end
    
[pfanat, fanatname] = get_parent_path(fanat,1);



voxelsize = '';
if ~isempty(par.voxelsize)
    voxelsize = ['-voxelsize ' num2str(par.voxelsize)];
end

% subfolder  = r_mkdir(pfanat, par.subfolder);
    
for nbr=1:length(fanat)
    cmd      = sprintf('cd %s\n', pfanat{nbr});
    cmd      = sprintf('%ssiam-pred -i %s %s %s -m %d %s\n',cmd,fanat{nbr}, prefix, device, par.model,voxelsize);    

    job{nbr} = cmd;
    
end


job = do_cmd_sge(job,par);


fprintf('\n\nsource /network/iss/cenir/software/irm/bin/siam_path\n')
pause(2);
