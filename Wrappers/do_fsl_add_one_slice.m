function fo = do_fsl_add_one_slice(f,par)
%function fo = do_fsl_bin(f,prefix,seuil)
%if seuil is a vector [min max] min<f<max
%if seuil is a number f>seuil


if ~exist('par'),par ='';end

defpar.fsl_output_format = 'NIFTI_PAIR';
defpar.prefix = 'ad';
defpar.where = 'down';

par = complet_struct(par,defpar);


f=cellstr(char(f));

fo = addprefixtofilenames(f,par.prefix);


for k=1:length(f)
  [pp ff] = fileparts(f{k});
  tmpname = tempname;

  vol = nifti_spm_vol(f{k});

  switch par.where
      case 'down'
          cmd = sprintf('cd %s;\n fslroi %s %s 0 %d 0 %d 0 1 0 %d',pp,ff,tmpname,vol(1).dim(1),vol(1).dim(2),length(vol));
          cmd = sprintf('%s;\nexport FSLOUTPUTTYPE=%s;\n fslmerge -z %s %s %s',cmd,par.fsl_output_format,fo{k},tmpname,ff);
          
      case 'up'
          cmd = sprintf('cd %s;\n fslroi %s %s 0 %d 0 %d %d 1 0 %d',pp,ff,tmpname,vol(1).dim(1),vol(1).dim(2),vol(1).dim(3)-1,length(vol));  
          cmd = sprintf('%s;\nexport FSLOUTPUTTYPE=%s;\n fslmerge -z %s %s %s',cmd,par.fsl_output_format,fo{k},ff,tmpname);
          
  end
  
  cmd = sprintf('%s;\n rm -rf %s',cmd,tmpname);
   
  unix(cmd);

end
