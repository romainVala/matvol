function fout=do_fsl_applywarp(fin,fwarp,par)

if ~exist('par'),par ='';end

defpar.jobname = 'applywarp';
defpar.prefix = 'uw_';
defpar.submit_sleep = 1;
defpar.ref='';
defpar.linearref = '';
defpar.skikifexist=1;
defpar.interp='trilinear'	%	interpolation method {nn,trilinear,sinc,spline}
defpar.type = 'scalar'; % vector

%defpar.unwarp_outvol_suffix = '_unwarp';

par = complet_struct(par,defpar);

job={};
for k=1:length(fwarp)
    
    ff = cellstr(fin{k});
    fo = addprefixtofilenames(ff,par.prefix);
    fout{k} = char(fo);
    
    pp=fileparts(fo{1});
    fprintf('working on %s \n',pp);
    
    for kk =1:length(ff)
        if par.skikifexist
            if exist(fo{kk},'file')
                continue
            end
        end
        
        if isempty(par.ref)
            cmd = sprintf('applywarp -i %s -r %s -o %s -w %s ',...
                ff{kk},ff{kk},fo{kk},fwarp{k});
            
        else
            [dirfin finam]= fileparts(ff{kk}); [dddd finam]= fileparts(finam);
            [dddd frefnam] = fileparts(par.linearref{k});[dddd frefnam] =fileparts(frefnam); %twice for .nii.gz
            tmout = fullfile(dirfin,[finam '-to-' frefnam '.mat']);
                        
            cmd = sprintf('flirt -in %s -ref %s -usesqform -applyxfm  -omat %s ',ff{kk},par.linearref{k},tmout);
            
            switch par.type
                case 'scalar'
                    cmd = sprintf('%s\n applywarp -i %s -r %s -o %s -w %s --premat=%s --interp=%s',...
                        cmd,ff{kk},par.ref{k},fo{kk},fwarp{k},tmout,par.interp);
                case 'vector'
                    %todo if premat is not identity (which is ok on connectome data
                    cmd = sprintf('%s\n vecreg  -i %s -r %s -o %s -w %s --interp=%s',...
                        cmd,ff{kk},par.ref{k},fo{kk},fwarp{k},par.interp);
                    
            end
            cmd = sprintf('%s\n rm %s',cmd,tmout);
            
        end
        job{end+1} = cmd;
    end
    
end

do_cmd_sge(job,par)

%/usr/share/fsl/4.1/bin/applywarp -i example_func_orig_distorted -o example_func -w unwarp/EF_UD_warp -r example_func_orig_distorted --abs

