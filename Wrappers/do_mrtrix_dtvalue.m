function do_mrtrix_dtvalue(fi)
%to compute eigen value from mrtrix dt tensor 



for k =1:length(fi)
    fdt = fi{k};
    
    [pp ff]=get_parent_path({fdt});
    
    cmd = sprintf('cd %s; tensor_metric -num 1 -value e1_long.nii  %s ',pp{1},ff{1});
    unix(cmd);
    cmd = sprintf('cd %s; tensor_metric -num 2 -value e2.nii  %s ',pp{1},ff{1});
    unix(cmd);
    cmd = sprintf('cd %s; tensor_metric -num 2 -value e3.nii  %s ',pp{1},ff{1});
    unix(cmd);
    
    cmd = sprintf('cd %s; fslmaths e2.nii -add e3.nii -div 2 e_radial;rm -f e2.nii e3.nii',pp{1});
    unix(cmd);
end

