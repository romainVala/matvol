function fo = do_fsl_split(f,par)
%function fo = do_fsl_bin(f,prefix,seuil)
%if seuil is a vector [min max] min<f<max
%if seuil is a number f>seuil


if ~exist('par'),par ='';end

defpar.fsl_output_format = 'NIFTI';
defpar.prefix = '';
defpar.base_name='split';

par = complet_struct(par,defpar);

f=cellstr(char(f));

for k=1:length(f)
  [pp ff] = fileparts(f{k});
      
  cmd = sprintf('export FSLOUTPUTTYPE=%s;\ncd %s;fslsplit %s %s -t ',par.fsl_output_format,pp,ff,par.base_name);  
  
  unix(cmd);
    
  fo(k) = get_subdir_regex_files(pp,sprintf('^%s',par.base_name));
end
