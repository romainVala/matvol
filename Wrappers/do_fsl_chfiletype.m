function do_fsl_chfiletype(fin,str_type,fout)
%do_fsl_chfiletype(fin,str_type,fout)
%default no fout (same name) and type  NIFTI
%posible type ANALYZE, NIFTI, NIFTI_PAIR,  ANALYZE_GZ, NIFTI_GZ, NIFTI_PAIR_GZ

if ~exist('str_type')
  str_type = 'NIFTI';
end

if exist('fout')
  fout = cellstr(char(fout));
end

if isempty(fin)
  fin = spm_select(inf,'.*','select 4D data','',pwd);
end

fin = cellstr(char(fin));



for k=1:length(fin)
  if exist('fout')
    cmd = sprintf('fslchfiletype %s %s %s',str_type,fin{k},fout{k});
  else
    cmd = sprintf('fslchfiletype %s %s ',str_type,fin{k});
  end

  unix(cmd);
end

