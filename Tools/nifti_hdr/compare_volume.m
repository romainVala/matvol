function sumo = compare_volume(v1,v2)

fo={};

for k=1:length(v1)

    vol1 = spm_vol(v1{k});
    vol2 = spm_vol(v2{k});
   
    vol1=vol1(1);vol2=vol2(1); % for 4 D volume juste take the first one
    Y1=spm_read_vols(vol1);
    Y2=spm_read_vols(vol2);
    
    aa=abs(Y1(:)-Y2(:));
    sumo(k) = sum(aa);
    
end
