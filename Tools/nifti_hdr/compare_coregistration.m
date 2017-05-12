function [diffmat mtrans mrot] = compare_coregistration(v1)

diff_vols={};
diffmat=[];

for k=1:length(v1)

    
    vol1 = nifti_spm_vol(v1{k});
    
    vol1=vol1(1); % for 4 D volume juste take the first one
    
    
    P1=spm_imatrix(vol1.mat);
    P2=spm_imatrix(vol1.private.mat0);
    diffmat(:,k) = P1(1:6)-P2(1:6);
    mtrans(k) = sum(abs(P1(1:3)-P2(1:3)));
    mrot(k) = sum(abs(P1(4:6)-P2(4:6)));
    
end
