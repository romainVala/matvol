function out = do_fsl_copy_sform(fin,par)

if ~exist('par'),par ='';end

defpar.sge=0;
%defpar.fsl_output_format = 'NIFTI_GZ'; %ANALYZE, NIFTI, NIFTI_PAIR, NIFTI_GZ
par = complet_struct(par,defpar);

job={};

fin = cellstr(char(fin));

for nbs=1:length(fin)
    
    cmd = sprintf('fslorient -copysform2qform %s \n',fin{nbs});
    
    if par.sge
        job{end+1} = cmd;
    else
        unix(cmd);
    end
end


if par.sge
    do_cmd_sge(job,par)
end
