function do_noddi_amico_fit(fdti,par)

if ~exist('par'),  par=''; end

def_par.bvec = 'eddy_rotated_bvecs';
def_par.bval = 'bval';
def_par.mask = 'nodif_brain_mask';

def_par.sge=1;
def_par.jobname='noddi';
def_par.AMICO_data_path = '';
def_par.sujname = ''; %if empty it will be guess from fdti (get_parent_path 3)
def_par.common_protocol = 0;  %set to one if you are sure there are the exact same bval between the subject 
% it save time but first subject must run first if 1 all amico kernel will be in AMICO_data_path
% if 0 this will be recompute for each subject and store in AMICO subject dir

par = complet_struct(par,def_par);


if isempty(par.AMICO_data_path) & par.common_protocol
    sujdir = get_parent_path(fdti(1),3);
    par.AMICO_data_path = fullfile(sujdir{1},'AMICO');
    if ~exist(par.AMICO_data_path,'dir'); mkdir(par.AMICO_data_path);end
    fprintf('AMICO path will be in %s\n',par.AMICO_data_path)
end

if isempty(par.sujname)
    [~, par.sujname ]= get_parent_path(fdti,3);
    fprintf('Please check : taking sujname for first and last subject\n%s\n%s\n,',par.sujname{1},par.sujname{end})
end


if par.sge
    cmd = '';
    fn = fieldnames(par);
    %write the parameters
    for kk=1:length(fn)
        if isnumeric(par.(fn{kk}))
            cmd = sprintf('%s par.%s = %f\n',cmd,fn{kk},par.(fn{kk}));
        elseif ischar(par.(fn{kk}))
            cmd = sprintf('%s par.%s = ''%s''\n',cmd,fn{kk},par.(fn{kk}));
        end
    end
    
    %force sge to 0
    cmd = sprintf('%s par.sge = 0\n',cmd);
    %write the matlab command
    for nbs = 1:length(fdti)
        job{nbs} = sprintf('%s\n par.sujname={''%s''};\n\n do_noddi_amico_fit({''%s''},par)',cmd,par.sujname{nbs},fdti{nbs});
    end
    
    do_cmd_matlab_sge(job,par)
    return
end


bvecf = get_file_from_same_dir(fdti,par.bvec,1);
bvalf = get_file_from_same_dir(fdti,par.bval,1);
fm  = get_file_from_same_dir(fdti,par.mask,1);


dti = get_parent_path(fdti);

cmd={};
for ns=1:length(dti)
    if ~exist(fullfile(dti{ns},'camino.sheme'),'file')
        cmd{ns} = sprintf('source camino_path; cd %s; fsl2scheme -bvecfile %s -bvalfile %s -bscale 1 > camino.sheme',...
            dti{ns},bvecf{ns},bvalf{ns})
    end
end
do_cmd_sge(cmd,struct('sge',0))

fsche=get_subdir_regex_files(dti,'camino.sheme$',1);

if ~exist('AMICO_Setup.m','file')
    addpath('/network/lustre/iss01/cenir/software/irm/matlab_toolbox/AMICO/matlab');
    addpath(genpath('/network/lustre/iss01/cenir/software/irm/matlab_toolbox/NODDI_toolbox_v0.9'))
end


AMICO_Setup
global AMICO_data_path

for nbs = 1:length(dti)
    
    if par.common_protocol
        AMICO_data_path = par.AMICO_data_path;
    else
        AMICO_data_path = fullfile( dti{nbs} , 'AMICO');
        if ~exist(AMICO_data_path,'dir'); mkdir(AMICO_data_path);end
    end
    
    AMICO_PrecomputeRotationMatrices(); % NB: this needs to be done only once and for all but skip if exist
    
    
    afdti=unzip_volume(fdti(nbs));afm=unzip_volume(fm(nbs))

    try        
        AMICO_SetSubject( 'amico_all', par.sujname{nbs} );
        
        % Override default file names
        CONFIG.DATA_path = dti{nbs};
        CONFIG.dwiFilename    = afdti{1};
        CONFIG.maskFilename   = afm{1};
        CONFIG.schemeFilename =fsche{nbs};
        
        AMICO_LoadData
        %Generate the kernels corresponding to the different compartments of the NODDI model:
        % Setup AMICO to use the 'NODDI' model
        AMICO_SetModel( 'NODDI' );
        % Generate the kernels corresponding to the protocol
        AMICO_GenerateKernels( false );
        % Resample the kernels to match the specific subject's scheme
        AMICO_ResampleKernels();
        % Load the kernels in memory
        %nomore KERNELS = AMICO_LoadKernels();
        AMICO_Fit()

    catch err
        display(err.message);
        disp(getReport(err,'extended'));
    end

    gzip_volume(afdti);    gzip_volume(afm);
end



