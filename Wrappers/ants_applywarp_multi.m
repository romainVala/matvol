function ants_applywarp_multi(fmov,fwarp,fref,par)


if ~exist('par','var'),par ='';end

defpar.sge=0;
defpar.jobname = 'antsApplyW';
defpar.walltime = '02:00:00';
defpar.prefix = 'aw_';
defpar.mask = '';
defpar.interp = 'NN'; %NN BS ML 
%--use-NN: Use Nearest Neighbor Interpolation. 
% --use-BSpline: Use 3rd order B-Spline Interpolation. 
% --use-ML sigma: Use anti-aliasing interpolation for multi-label images, with Gaussian smoothing with standard deviation sigma.

% BSpline[<order=3>] CosineWindowedSinc WelchWindowedSinc HammingWindowedSinc LanczosWindowedSinc
defpar.inv = 0;
defpar.folder = 'mov'; %same dir as the move file %'warp' same dir as the warp file

par = complet_struct(par,defpar);

if length(fref)==1
    fref = repmat(fref,size(fmov));
end

% -i ../../../template/mask.nii -r v10_s20141028_SN_Track_Rat1-917505-00001-000001.nii.gz -o iwmask.nii
%-t [aw_v10_s20141028_SN_Track_Rat1-917505-00001-000001_to_ants_template0GenericAffine.mat,1] -t aw_v10_s20141028_SN_Track_Rat1-917505-00001-000001_to_ants_template1InverseWarp.nii.gz
nbj=0;
for k=1:length(fmov)
    fsermov = cellstr(fmov{k});
    for nbfmov = 1:length(fsermov)
        
        [ppwarp, ~] = get_parent_path(fwarp(k)); 
        [ppmov , fname_mov ] = get_parent_path(fsermov(nbfmov)); fname_mov = change_file_extension(fname_mov,'');
        [ppref , ~] = get_parent_path(fref(k)); 

        switch par.folder
            case 'mov'
                path_warp = ppmov{1}(1,:);
            case 'warp'
                path_warp = ppwarp{1}(1,:);
            case 'ref'
                path_warp = ppref{1}(1,:);
        end
        
        fo = fullfile(path_warp,[par.prefix fname_mov{1} '.nii.gz']);
        
        %cmd = sprintf('cd %s',ppwarp{k});
        cmd = sprintf('WarpImageMultiTransform 3 %s %s -R %s ',fsermov{nbfmov},fo,fref{k});
        
        ffwarp = cellstr(fwarp{k});
        if length(par.inv) ~= length(ffwarp)
            par.inv = repmat(par.inv,size(ffwarp));
        end
        
        for kw = 1:length(ffwarp)
            if par.inv(kw)
                cmd = sprintf('%s -i %s ',cmd,ffwarp{kw});
            else
                cmd = sprintf('%s %s ',cmd,ffwarp{kw});
            end
        end
        switch par.interp
            case 'NN'
                cmd = sprintf('%s --use-NN',cmd);
            case 'BS'
                cmd = sprintf('%s --use-BSpline',cmd);
            case 'ML'
                cmd = sprintf('%s --use-ML 0.8x0.8x0.8vox',cmd); %--use-ML 0.4mm
        end
        nbj=nbj+1; job{nbj} = cmd;
    end
end

do_cmd_sge(job,par)