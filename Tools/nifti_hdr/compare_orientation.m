function [ res_boolean, diff_vols, diffmat ] = compare_orientation(v1,v2)

diff_vols={};
diffmat=[];

for k=1:length(v1)
    
    res_boolean(k)=1;
    
    vol1 = nifti_spm_vol(v1{k});
    vol2 = nifti_spm_vol(v2{k});
    
    vol1=vol1(1);vol2=vol2(1); % for 4 D volume juste take the first one
    
    if any(vol2.dim - vol1.dim)
        fprintf('Dimemntion differ %s compare to %s \n',v1{k},v2{k})
        res_boolean(k)=0;
        diff_vols(end+1) = v1(k);
    end
    
    if any(any((abs(vol2.mat - vol1.mat))>0.001))
        fprintf('orientation differ %s compare to %s \n',v1{k},v2{k});
        res_boolean(k)=0;
        diff_vols(end+1) = v1(k);
        P1=spm_imatrix(vol1.mat);
        P2=spm_imatrix(vol2.mat);
        diffmat(:,end+1) = P1-P2;
    end
    
end

end % function
