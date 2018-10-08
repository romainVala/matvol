function [ out, job ]= do_fsl_meant(fin,mask,par,jobappend)

if ~exist('par'),par ='';end
if ~exist('jobappend','var'), jobappend ='';end


defpar.sge=0;
defpar.jobname='fslmeant';
defpar.mean = 'eig'; % or mean to calculate mean instead of Eigenvariate
defpar.no_bin = 1;   % --no_bin	        do not binarise the mask for calculation of Eigenvariates
defpar.skip = 1;
defpar.confound = '';
defpar.rp = '';

job ='';

par = complet_struct(par,defpar);

job = {};
for nbs =1:length(fin)
    fmask = cellstr(char(mask(nbs)));
    
    cmdconf = '';
    if ~isempty(par.confound) %write the confound in a tmp file
        fconf = cellstr(par.confound{nbs});
        timeconf={};
        for nbconf = 1:length(fconf)
            timeconf{nbconf} = tempname;
            cmdconf = sprintf('%s\n fslmeants -i %s -m %s -o %s  ',...
                cmdconf,fin{nbs}, fconf{nbconf},timeconf{nbconf});
            if strcmp(par.mean,'eig'); cmdconf = sprintf('%s --eig ',cmdconf);end
            if par.no_bin; cmdconf = sprintf('%s --no_bin ',cmdconf);end
            
        end
        
    end
    
    for nb_mask = 1:length(fmask)
        [ppin fvolname ] = get_parent_path(change_file_extension(fin{nbs},''));
        [pp maskname ] = get_parent_path(change_file_extension(fmask{nb_mask},''));
        
        out{nbs}{nb_mask} = sprintf('%s/tc_%s_ROIm_%s.txt ', ppin,fvolname,maskname);
        
        if ~isempty(par.confound), tt = tempname; else, tt = out{nbs}{nb_mask}; end
        if nb_mask==1,            cmd=cmdconf;end
        cmd = sprintf('%s\n fslmeants -i %s -m %s -o %s  ',...
            cmd,fin{nbs}, fmask{nb_mask},tt);
                
        if strcmp(par.mean,'eig'); cmd = sprintf('%s --eig ',cmd);end
        if par.no_bin; cmd = sprintf('%s --no_bin ',cmd);end
        
        if  ~isempty(par.confound) %concatenate means timecourse and confounds
            cmd = sprintf('%s\n paste %s',cmd,tt);
            for nbconf = 1:length(fconf)
                cmd = sprintf('%s %s ',cmd,timeconf{nbconf});
            end
            if ~isempty(par.rp)
                cmd = sprintf('%s %s ',cmd,par.rp{nbs});
            end
            
            cmd = sprintf('%s > % s',cmd,out{nbs}{nb_mask});
            
            if nb_mask==length(fmask)
                cmd = sprintf('%s\n rm -f %s ',cmd,tt);
                for nbconf = 1:length(fconf),  cmd = sprintf('%s %s ',cmd,timeconf{nbconf}); end
            end
        end
    end
    job{end+1}=cmd;
    out{nbs} = char(out{nbs});
end

job = do_cmd_sge(job,par,jobappend);


end % function

