function ants_applywarp(fmov,fwarp,fref,par)


if ~exist('par','var'),par ='';end

defpar.sge=0;
defpar.jobname = 'antsApplyW';
defpar.walltime = '02:00:00';
defpar.prefix = 'aw_';
defpar.mask = '';
defpar.interp = 'Linear'; % BSpline NearestNeighbor MultiLabel[<sigma=imageSpacing>,<alpha=4.0>] Gaussian[<sigma=imageSpacing>,<alpha=1.0>]
% BSpline[<order=3>] CosineWindowedSinc WelchWindowedSinc HammingWindowedSinc LanczosWindowedSinc
defpar.inv = 0;
defpar.folder = 'mov'; %same dir as the move file %'warp' same dir as the warp file
defpar.nii4D=0

par = complet_struct(par,defpar);

if length(fref)==1
    fref = repmat(fref,size(fmov));
end



[ppwarp fname_warp ] = get_parent_path(fwarp); fname_warp = change_file_extension(fname_warp,'');
[ppmov fname_mov ] = get_parent_path(fmov); fname_mov = change_file_extension(fname_mov,'');

% -i ../../../template/mask.nii -r v10_s20141028_SN_Track_Rat1-917505-00001-000001.nii.gz -o iwmask.nii
%-t [aw_v10_s20141028_SN_Track_Rat1-917505-00001-000001_to_ants_template0GenericAffine.mat,1] -t aw_v10_s20141028_SN_Track_Rat1-917505-00001-000001_to_ants_template1InverseWarp.nii.gz

for k=1:length(fmov)
    switch par.folder
        case 'mov'
            path_warp = ppmov{k}(1,:);
        case 'warp'
            path_warp = ppwarp{k}(1,:);
    end
    
    fo = fullfile(path_warp,[par.prefix fname_mov{k} '.nii.gz']);
    
    %cmd = sprintf('cd %s',ppwarp{k});
    cmd = sprintf('antsApplyTransforms -i %s -r %s -o %s ',fmov{k},fref{k},fo);
    
    if par.nii4D
        cmd=sprintf('%s -e 3 ',cmd)
    end
    
    ffwarp = cellstr(fwarp{k});
    if length(par.inv) ~= length(ffwarp)
        par.inv = repmat(par.inv,size(ffwarp));
    end
    
    for kw = 1:length(ffwarp)
        if par.inv(kw)
            cmd = sprintf('%s -t [%s,1] ',cmd,ffwarp{kw});
        else
            cmd = sprintf('%s -t %s ',cmd,ffwarp{kw});
        end
    end
    
    cmd = sprintf('%s -n %s',cmd,par.interp);
    
    
    job{k} = cmd;
end

do_cmd_sge(job,par)