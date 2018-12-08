function nifti_reg_applywarp(fmov,fwarp,fref,par)
%nifti_reg_applywarp(fmov,fwarp,fref,par) 
% fmov images to apply transfo fwarp to reference image fref

if ~exist('par','var'),par ='';end

defpar.sge=1;
defpar.jobname = 'niregApplyW';
defpar.walltime = '02:00:00';
defpar.prefix = 'nw_';
defpar.mask = '';
defpar.interp = 1; % Interpolation order (0, 1, 3, 4)[3] (0=NN, 1=LIN; 3=CUB, 4=SINC) 
defpar.folder = 'warp'; % create res in folder where the warp is if = 'mov' 
defpar.inv = 0;   
defpar.inv_ref=''; % target image in the direct registration
defpar.inv_temp_dir = ''; %
defpar.inv_delete=0;

par = complet_struct(par,defpar);

if length(fref)==1
    fref = repmat(fref,size(fmov));
end

if length(fmov)==1 %ie inverse a template
    fmov = repmat(fmov,size(fref));
end

[ppwarp fname_warp ] = get_parent_path(fwarp); %fname_warp = change_file_extension(fname_warp,'');

[ppmov fname_mov ] = get_parent_path(fmov); fname_mov = change_file_extension(fname_mov,'');

switch par.folder
    case 'warp'
        ores = ppwarp;
    case 'mov'
        ores = ppmov;

end

%fwarpi = nifti_reg_inversewarp(fwarp,fanat,fref,par);  nifti_reg_inversewarp(fwarp,fref,frefw,par)
%nifti_reg_applywarp(fmov,fwarpic,fanat,par)

% -i ../../../template/mask.nii -r v10_s20141028_SN_Track_Rat1-917505-00001-000001.nii.gz -o iwmask.nii
%-t [aw_v10_s20141028_SN_Track_Rat1-917505-00001-000001_to_ants_template0GenericAffine.mat,1] -t aw_v10_s20141028_SN_Track_Rat1-917505-00001-000001_to_ants_template1InverseWarp.nii.gz
[dirw, fwarp_file] = get_parent_path(fwarp);
        
if par.inv
    fo_def = addprefixtofilenames(fwarp_file,'defo_');
    foinv = addprefixtofilenames(fwarp_file,'i');
    frefiw = par.inv_ref;
    if length(frefiw)==1,    frefiw = repmat(frefiw,size(fwarp)); end
end

job=cell(fmov);
for k=1:length(fmov)
    path_warp = cellstr(deblank(ores{k}));
    
    ffname_mov = cellstr(fname_mov{k});
    ffmov = cellstr(char(fmov{k}));
    if strcmp(par.folder,'warp')
        path_warp=repmat(path_warp,size(ffmov)); %one warp several move
    end
    
    if isempty(par.inv_temp_dir)        
        cmd = sprintf('cd %s\n',dirw{k});
    else
        tmpdir = tempname(par.inv_temp_dir);
        cmd = sprintf('mkdir -p %s\ncd %s\n',tmpdir,tmpdir);
    end
    
    the_fwarp = fwarp{k};
    if par.inv
        cmd = sprintf('%s reg_transform -def %s %s -ref %s \n',cmd,the_fwarp,fo_def{k},fref{k});
        cmd = sprintf('%s reg_transform -invNrr %s %s %s \n',cmd,fo_def{k},frefiw{k},foinv{k});
        the_fwarp = foinv{k};
    end

    for nb_mov = 1:length(ffname_mov)
        
        fo = fullfile(path_warp{nb_mov},[par.prefix ffname_mov{nb_mov} '.nii.gz']);
        
        %cmd = sprintf('cd %s',ores{k});
        cmd = sprintf('%s reg_resample -flo %s -ref %s -res %s ',cmd,ffmov{nb_mov},fref{k},fo);
        
        %cmd = sprintf('%s ',cmd);        
        cmd = sprintf('%s -trans %s',cmd,the_fwarp);        
        cmd = sprintf('%s -inter %d \n\n',cmd,par.interp);
        
    end        
    if par.inv_delete
        if isempty(par.inv_temp_dir)
            cmd = sprintf('%s rm -f %s %s \n\n',cmd,fo_def{k},foinv{k})
        else
            cmd = sprintf('%s rm -rf %s \n\n',cmd,tmpdir);
        end
    end
    job{k} = cmd;
end

do_cmd_sge(job,par);
