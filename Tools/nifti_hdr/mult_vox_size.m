function mult_vox_size(f,size)

f=cellstr(char(f));

for k=1:length(f)

%	v = spm_vol(f{k});
%	[Y] = spm_read_vols(v);
ff = f{k};

[aa bb ee] = fileparts(ff);

if ~strcmp(ee,'.img') & ~strcmp(ee,'.nii')
   error('You should choose .img or .nii files')
end


fo = addprefixtofilenames(ff,sprintf('v%d_',size));
r_movefile({ff},{fo},'copy');

v=nifti(f{k});
v.dat.fname=fo;   

P=spm_imatrix(v.mat);

P([1:3;7:9]) = P([1:3;7:9])*size;
%  P([7:9]) = P([7:9])*size;
v.mat = spm_matrix(P);

P=spm_imatrix(v.mat0);
P([1:3;7:9]) = P([1:3;7:9])*size;
v.mat0 = spm_matrix(P);


create(v)

end
