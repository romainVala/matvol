function [ fo, job ] = do_fsl_coreg_reslice(src,ref,par,jobappend) % prefix,interp_fsl)
%function fo = do_fsl_reslice(src,ref,prefix)
%if iscell(prefix) prefix is then the matrix output

if ~exist('par'),par ='';end
if ~exist('jobappend','var'), jobappend ='';end


defpar.prefix = 'rfsl_';
defpar.interp_fsl = 'trilinear'; % trilinear nearestneighbour sinc spline
defpar.trans_mat = '';
defpar.sge = 0;
defpar.jobname='fsl_reslice';
defpar.fsl_output_format = 'NIFTI_GZ';
defpar.outfilename='' ;

par = complet_struct(par,defpar);

prefix=par.prefix;

nbj=1;

if iscell(prefix)
    for k=1:length(ref)
        cmd = sprintf('export FSLOUTPUTTYPE=%s;flirt -in %s -ref %s -omat %s  -usesqform -interp %s ',...
            par.fsl_output_format,src{k},ref{k},prefix{k},par.interp_fsl);
        job{nbj} = cmd;
        nbj=nbj+1;
    end
    
else
    
    if isempty(par.outfilename)
        fo = addprefixtofilenames(src,prefix);
    else
        fo = par.outfilename;
    end
    
    switch par.fsl_output_format
        case 'NIFTI_GZ'
            fo=change_file_extension(fo,'.nii.gz');
    end
    
    for k=1:length(ref)
        ff = cellstr(src{k});
        ffo = cellstr(fo{k});
        ffomat = change_file_extension(ffo,'.txt');
        
        for kk=1:length(ff)
            if isempty(par.trans_mat)
                cmd = sprintf('export FSLOUTPUTTYPE=%s;flirt -in %s -ref %s -omat %s  -usesqform  -interp %s ',...
                    par.fsl_output_format,ff{kk},ref{k},ffomat{kk},par.interp_fsl);
            else
                cmd = sprintf('export FSLOUTPUTTYPE=%s;flirt -in %s -ref %s -omat %s  -init %s  -interp %s ',...
                    par.fsl_output_format,ff{kk},ref{k},ffomat{kk},par.trans_mat{k},par.interp_fsl);
            end
            cmd = sprintf('%s\napplyxfm4D %s %s %s %s  -singlematrix\n',cmd,ff{kk},ref{k},ffo{k},ffomat{kk});
            %unix(cmd);
            job{nbj} = cmd;
            nbj=nbj+1;
        end
        
    end
    
end

job = do_cmd_sge(job,par,jobappend);

end % function
