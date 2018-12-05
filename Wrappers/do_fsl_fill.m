function [fo, job] = do_fsl_fill(f,par)
%function fo = do_fsl_bin(f,prefix,seuil)
%if seuil is a vector [min max] min<f<max
%if seuil is a number f>seuil


if ~exist('par','var'),par ='';end

defpar.fsl_output_format = 'NIFTI_GZ';
defpar.prefix = '';
defpar.sge=0;
defpar.jobname = 'fslfill';
defpar.walltime = '00:10:00';

par = complet_struct(par,defpar);

f=cellstr(char(f));

fo = addprefixtofilenames(f,par.prefix);

for k=1:length(f)
  [pp ff] = fileparts(f{k});

  job{k} = sprintf('export FSLOUTPUTTYPE=%s;fslmaths %s -fillh %s \n',par.fsl_output_format,f{k},fo{k});
  
end

if par.sge
   job =  do_cmd_sge(job,par)
end

