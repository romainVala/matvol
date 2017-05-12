function jobs = job_apply_normalize(anat_matfile,ff, par)
%for spm12 anat_matfile, is indeed the flow field y_*.nii or iy_*.nii

if ~exist('par')
    par='';
end

%write option
defpar.preserve = 0;
defpar.bb = [-78 -112 -70 ; 78 76 85];
defpar.vox = [2 2 2];
defpar.interp = 4;

defpar.wrap = [0 0 0];
defpar.prefix = 'w';

defpar.redo = 0;
defpar.sge = 0;
defpar.run = 0;
defpar.display=0;
defpar.jobname='spm_apply_norm';


par = complet_struct(par,defpar);

%check spm_version
[v , r]=spm('Ver','spm');

skip = [];

if strfind(r,'SPM8')
    
    for k=1:length(anat_matfile)
        
        jobs{k}.spm.spatial.normalise.write.subj(1).matname = anat_matfile(k);
        jobs{k}.spm.spatial.normalise.write.subj(1).resample = cellstr(ff{k});
        jobs{k}.spm.spatial.normalise.write.roptions.preserve =  par.preserve;
        jobs{k}.spm.spatial.normalise.write.roptions.bb =  par.bb;
        jobs{k}.spm.spatial.normalise.write.roptions.vox = par.vox;
        jobs{k}.spm.spatial.normalise.write.roptions.interp = par.interp;
        jobs{k}.spm.spatial.normalise.write.roptions.wrap = par.wrap;
        jobs{k}.spm.spatial.normalise.write.roptions.prefix = par.prefix;
        
    end
    
    
elseif strfind(r,'SPM12')
    for k=1:length(anat_matfile)
        
        jobs{k}.spm.spatial.normalise.write.subj(1).def = anat_matfile(k);
        jobs{k}.spm.spatial.normalise.write.subj(1).resample = cellstr(ff{k});
        
        %test if exist
        folast = addprefixtofilenames(cellstr(char(ff(k))),par.prefix);
        if ~par.redo
            if exist(folast{end},'file'),   skip = [skip k];     fprintf('skiping becasue %s exist',folast{1});    end
        end
        jobs{k}.spm.spatial.normalise.write.woptions.bb = par.bb;
        jobs{k}.spm.spatial.normalise.write.woptions.vox = par.vox;
        jobs{k}.spm.spatial.normalise.write.woptions.interp = par.interp;
        jobs{k}.spm.spatial.normalise.write.woptions.prefix = par.prefix;
                
    end
    
    
end


jobs(skip)=[];
if isempty(jobs), return;end

if par.sge
    for k=1:length(jobs)
        j=jobs(k);
        cmd = {'spm_jobman(''run'',j)'};
        varfile = do_cmd_matlab_sge(cmd,par);
        save(varfile{1},'j');
    end
end

if par.display
    spm_jobman('interactive',jobs);
    spm('show');
end

if par.run
    spm_jobman('run',jobs)
end
