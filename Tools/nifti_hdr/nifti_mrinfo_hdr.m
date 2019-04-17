function [vol ] = nifti_mrinfo_hdr(fname)
% function [vol Data] = nifti_spm_vol(fname)
% return the spm header (vol) and if 2 argument is given
% it return the data in a matlab 3D matrix

if iscell(fname)
    if length(fname) >1 % we supose a list of 3D volume
        for k=1:length(fname)
            [vol(k) Data(:,:,:,k)] = nifti_spm_vol(fname{k});
        end
    else
        [vol Data] = nifti_spm_vol(fname{1});
    end
    return
end

cmd = sprintf('LD_LIBRARY_PATH=;mrinfo %s', fname);
[a, b] = unix(cmd);

bb=strsplit(b);
for k=1:length(bb)
    if findstr(bb{k},'Dimension')
        
dim = bb([6 8 10])


keyboard

[PATHSTR,NAME1,EXT] = fileparts(deblank( fname));

if(strcmp(EXT,'.gz'))
    t=tempname;
    command = sprintf('sh -c ". ${FSLDIR}/etc/fslconf/fsl.sh; FSLOUTPUTTYPE=NIFTI; export FSLOUTPUTTYPE; $FSLDIR/bin/fslmaths %s %s;"\n', fname, t);
    system(command);
    file_tmp = [t '.nii'];
    vol = spm_vol(file_tmp);
    
    if nargout > 1
        Data = spm_read_vols(vol);
    end
    
    if nargout > 2
        [nii.hdr,nii.filetype,nii.fileprefix,nii.machine] = load_nii_hdr(file_tmp);
    end
    
     
    delete(file_tmp);
else
    vol = spm_vol(fname);
    if nargout > 1
        Data = spm_read_vols(vol);
    end
end
