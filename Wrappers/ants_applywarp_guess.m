function ants_applywarp(fmov,fwarp,fref,par)


if ~exist('par','var'),par ='';end

defpar.sge=1;
defpar.jobname = 'antsApplyW';
defpar.walltime = '02:00:00';
defpar.prefix = '';
defpar.mask = '';
defpar.interp = 'Linear'; % BSpline NearestNeighbor MultiLabel[<sigma=imageSpacing>,<alpha=4.0>] Gaussian[<sigma=imageSpacing>,<alpha=1.0>]
% BSpline[<order=3>] CosineWindowedSinc WelchWindowedSinc HammingWindowedSinc LanczosWindowedSinc


par = complet_struct(par,defpar);

if length(fref)==1
    fref = repmat(fref,size(fmov));
end



[ppwarp fname_warp ] = get_parent_path(fwarp); fname_warp = change_file_extension(fname_warp,'');
[pp fname_mov ] = get_parent_path(fmov); fname_mov = change_file_extension(fname_mov,'');

% -i ../../../template/mask.nii -r v10_s20141028_SN_Track_Rat1-917505-00001-000001.nii.gz -o iwmask.nii
%-t [aw_v10_s20141028_SN_Track_Rat1-917505-00001-000001_to_ants_template0GenericAffine.mat,1] -t aw_v10_s20141028_SN_Track_Rat1-917505-00001-000001_to_ants_template1InverseWarp.nii.gz

for k=1:length(fmov)
    ind = strfind(fname_warp{k},'1InverseWarp');
    if ind
        inv=1;
        if isempty(par.prefix), par.prefix='aiw_'; end
    else
        inv=0;
        ind = strfind(fname_warp{k},'1Warp');
        if isempty(par.prefix), par.prefix='aw_'; end
    end
    
    faff = fullfile(ppwarp{k},[fname_warp{k}(1:ind-1) '0GenericAffine.mat']);
    fo = fullfile(ppwarp{k},[par.prefix fname_mov{k} '.nii.gz']);
    
    %cmd = sprintf('cd %s',ppwarp{k});
    cmd = sprintf('antsApplyTransforms -i %s -r %s -o %s ',fmov{k},fref{k},fo);
    if exist(faff,'file')
        if inv
            cmd = sprintf('%s -t [%s,1] -t %s',cmd,faff,fwarp{k});
        else
            cmd = sprintf('%s -t %s -t %s',cmd,fwarp{k},faff);
        end
    else
        cmd = sprintf('%s -t %s',cmd,fwarp{k});
    end
    
    cmd = sprintf('%s -n %s',cmd,par.interp);
    
    
    job{k} = cmd;
end

do_cmd_sge(job,par)