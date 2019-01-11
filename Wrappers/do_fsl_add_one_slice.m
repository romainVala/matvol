function [fo, job] = do_fsl_add_one_slice(f,par)
%function fo = do_fsl_bin(f,prefix,seuil)
%if seuil is a vector [min max] min<f<max
%if seuil is a number f>seuil


if ~exist('par'),par ='';end

defpar.fsl_output_format = 'NIFTI_PAIR';
defpar.prefix = 'ad';
defpar.where = 'down';
defpar.vol = '';

par = complet_struct(par,defpar);


f=cellstr(char(f));

fo = addprefixtofilenames(f,par.prefix);

job = cell(size(f));

for k=1:length(f)
  [pp, ff] = fileparts(change_file_extension(f{k},''));
  tmpname = tempname;
    
  if isempty(par.vol)
      vol = nifti_spm_vol(f{k});
  else
      vol = par.vol; %case of non existing files see dti_import_multiple
  end

  switch par.where
      case 'down'
          cmd = sprintf('#ADDING one slice down\n cd %s;\n fslroi %s %s 0 %d 0 %d 0 1 0 %d',pp,ff,tmpname,vol(1).dim(1),vol(1).dim(2),length(vol));
          cmd = sprintf('%s;\nexport FSLOUTPUTTYPE=%s;\n fslmerge -z %s %s %s',cmd,par.fsl_output_format,fo{k},tmpname,ff);
          
      case 'up'
          cmd = sprintf('cd %s;\n fslroi %s %s 0 %d 0 %d %d 1 0 %d',pp,ff,tmpname,vol(1).dim(1),vol(1).dim(2),vol(1).dim(3)-1,length(vol));  
          cmd = sprintf('%s;\nexport FSLOUTPUTTYPE=%s;\n fslmerge -z %s %s %s',cmd,par.fsl_output_format,fo{k},ff,tmpname);
          
  end
  
  cmd = sprintf('%s;\n rm -rf %s*\n##',cmd,tmpname);
   
  job{k} = cmd;

end

job = do_cmd_sge(job,par);
