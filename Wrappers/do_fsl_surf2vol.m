function fo = do_fsl_surf2vol(surfin,outname,outdir,output_vol)
%function fo = do_fsl_surf2vol(surfin,outname,outdir,output_vol)

if ~exist('output_vol')
    output_vol='';
else
    if length(surfin) ~= length(output_vol)
        error('length of reference to reslice volume should be the same as the input volume')
    end
end
if ~iscell(surfin)
    surfin = cellstr(surfin)';
end
if ~iscell(outdir)
    outdir = cellstr(outdir)';
end

if length(surfin) ~= length(outdir)
    error('length outdir should be the same as the input volume')
end

for num_in = 1:length(outname)
    temp1 = surfin{1};
      
    fogii{1} = temp1(num_in,:);
    temp{1} = fullfile(outdir{1}, outname{num_in});
    
    voname = change_file_extension(temp,'.nii');

    cmd = sprintf('surf2volume %s %s %s caret',fogii{1},output_vol{1},voname{1})
    unix(cmd)


end

    
end


