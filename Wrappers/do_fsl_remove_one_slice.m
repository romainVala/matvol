function fo = do_fsl_remove_one_slice(f,par)
%function fo = do_fsl_bin(f,prefix,seuil)
%if seuil is a vector [min max] min<f<max
%if seuil is a number f>seuil


if ~exist('par'),par ='';end

defpar.fsl_output_format = 'NIFTI';
defpar.prefix = 'rm';

par = complet_struct(par,defpar);


f=cellstr(char(f));

fo = addprefixtofilenames(f,par.prefix);


for k=1:length(f)

vol = nifti_spm_vol(f{k});

if mod(vol(1).dim(3),2)
  [pp ff] = fileparts(f{k});
%   tmpname = tempname;
  cmd = sprintf('cd %s;\n export FSLOUTPUTTYPE=%s;\n fslroi %s %s 0 %d 0 %d 1 %d 0 %d',...
      pp,par.fsl_output_format,ff,fo{k},vol(1).dim(1),vol(1).dim(2),vol(1).dim(3)-1,length(vol));
  
%   cmd = sprintf('%s;\ne\n fslmerge -z %s %s %s',cmd,par.fsl_output_format,fo{k},tmpname,ff);
%   cmd = sprintf('%s;\n rm -rf %s',cmd,tmpname);
  
%display(cmd)

unix(cmd);
else
fprintf('skiping remove one slice because already a even number of slices\n')
end

end
