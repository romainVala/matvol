function [ fo, job ] = do_mrtrix_reslice(src,par,jobappend) 
%function fo = do_mrtrix_reslice(src,par)

if ~exist('par'),par ='';end
if ~exist('jobappend','var'), jobappend ='';end

defpar.prefix = 'r_';
defpar.interp = 'cubic'; % nearest,linear, cubic, sinc. Default: cubic)
defpar.sge = 0;
defpar.jobname='mrtrix_reslice';
defpar.outfilename='' ;
defpar.ref = '';
defpar.voxel = 0;

par = complet_struct(par,defpar);
prefix=par.prefix;

nbj=1;

if isempty(par.outfilename)
    fo = addprefixtofilenames(src,prefix);
else
    fo = par.outfilename;
end

for k=1:length(src)

    if ~isempty(par.ref )
        cmd_opt = sprintf(' -template %s -stride %s ',par.ref{k},par.ref{k})
    elseif par.voxel
        cmd_opt = sprintf(' -voxel %f ',par.voxel)
    else
        error('you must define either par.template or par.size')
    end
    cmd_opt = sprintf('%s -interp %s ', cmd_opt, par.interp);

    ff = cellstr(src{k});
    ffo = cellstr(fo{k});
    
    for kk=1:length(ff)

        cmd = sprintf('mrgrid %s  regrid  %s  %s  ',ff{kk},cmd_opt, ffo{kk});
        %unix(cmd);
        job{nbj} = cmd;
        nbj=nbj+1;
    end
    
end


job = do_cmd_sge(job,par,jobappend);

end % function
