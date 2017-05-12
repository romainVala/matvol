function fo = do_c3d_resize(fin,par)

%c3d image.nii -resample 200% -o outimage.nii
%c3d image.nii -resample-mm 1.0x1.0x1.0 -o image.nii
%http://www.itksnap.org/pmwiki/pmwiki.php?n=Convert3D.Documentation

% -interpolation <NearestNeighbor|Linear|Cubic|Sinc|Gaussian>


if ~exist('par'),par ='';end

defpar.resamplemm = '';
defpar.resample = '';
defpar.interp = 'trilinear';
defpar.prefix = 'r';

par = complet_struct(par,defpar);

fin = cellstr(char(fin));
fout = addprefixtofilenames(fin,par.prefix);
fout = change_file_extension(fout,'.nii');

for k=1:length(fin)
    ff=fin{k};
    v=nifti_spm_vol(ff);
    if length(v)>1
        ff=do_fsl_split(ff);
        ff=cellstr(char(ff));
        
        for nbt=1:length(ff)
            do_c3d_resize(ff(nbt),par)
        end
        ffr = addprefixtofilenames(ff,par.prefix);
        do_fsl_merge(ffr,fout{k},struct('checkorient',0));

        do_delete(ffr,0);
        do_delete(ff,0);
    else
        
        if ~isempty(par.resamplemm)
            cmd = sprintf('c3d %s -resample-mm %s -o %s',fin{k},par.resamplemm,fout{k});
            unix(cmd);
        elseif ~isempty(par.resample)
            cmd = sprintf('c3d %s -resample %s%%%% -o %s',fin{k},par.resample,fout{k});
            unix(cmd);
        end
    end
end