function do_fsl_apply_topup(fin,ftopup,par,jobappend)

if ~exist('par'),par ='';end
if ~exist('jobappend','var'), jobappend ='';end


defpar.outprefix = 'ut';
defpar.sge=1;
defpar.index=0;
defpar.acqpfile = 'acqp.txt';
defpar.fsl_output_format = 'NIFTI';
defpar.redo=0;
defpar.submit_sleep =0;
defpar.sge_queu = 'long';
defpar.jobname = 'fsl_apply_topup';

par = complet_struct(par,defpar);

fin = cellstr(char(fin));

fo = addprefixtofilenames(fin,par.outprefix);

if length(ftopup)==1
    ftopup = repmat(ftopup,size(fin));
end

if exist(fo{end}) && ~par.redo
    fprintf('skiping topup write, because %s exist\n',fo{end});
else
    for k=1:length(fin)
        [dirtopup fff] = fileparts(ftopup{k});
        
        cmd = sprintf('cd %s;export FSLOUTPUTTYPE=%s; applytopup --imain=%s --datain=%s --method=jac --inindex=%d  --topup=%s --out=%s;\n',...
            dirtopup,par.fsl_output_format,fin{k},par.acqpfile,par.index,fff,fo{k});
        job{k} = cmd;
    end
    
    job = do_cmd_sge(job,par,jobappend);
end