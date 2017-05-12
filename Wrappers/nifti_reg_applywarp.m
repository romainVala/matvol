function nifti_reg_applywarp(fmov,fwarp,fref,par)


if ~exist('par','var'),par ='';end

defpar.sge=1;
defpar.jobname = 'niregApplyW';
defpar.walltime = '02:00:00';
defpar.prefix = 'nw_';
defpar.mask = '';
defpar.interp = 1; % Interpolation order (0, 1, 3, 4)[3] (0=NN, 1=LIN; 3=CUB, 4=SINC) 
defpar.folder = 'warp'; % create res in folder where the warp is if = 'mov' 
defpar.inv = 0;

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

% -i ../../../template/mask.nii -r v10_s20141028_SN_Track_Rat1-917505-00001-000001.nii.gz -o iwmask.nii
%-t [aw_v10_s20141028_SN_Track_Rat1-917505-00001-000001_to_ants_template0GenericAffine.mat,1] -t aw_v10_s20141028_SN_Track_Rat1-917505-00001-000001_to_ants_template1InverseWarp.nii.gz

job={};
for k=1:length(fmov)
    path_warp = cellstr(deblank(ores{k}));
    
    ffname_mov = cellstr(fname_mov{k});
    ffmov = cellstr(char(fmov{k}));
    if strcmp(par.folder,'warp')
        path_warp=repmat(path_warp,size(ffmov)); %one warp several move
    end
    
    for nb_mov = 1:length(ffname_mov)
        
        fo = fullfile(path_warp{nb_mov},[par.prefix ffname_mov{nb_mov} '.nii.gz']);
        
        %cmd = sprintf('cd %s',ores{k});
        cmd = sprintf('reg_resample -flo %s -ref %s -res %s ',ffmov{nb_mov},fref{k},fo);
        
        cmd = sprintf('%s ',cmd);        
        cmd = sprintf('%s -trans %s',cmd,fwarp{k});        
        cmd = sprintf('%s -inter %d \n',cmd,par.interp);
                
        job{end+1} = cmd;
    end
end

do_cmd_sge(job,par)