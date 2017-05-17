function jobs = job_realign(fin,par)


if ~exist('par')
    par='';
end


defpar.prefix = 'r';
defpar.file_reg = '^f.*nii';
defpar.type = 'estimate'; %estimate_and_reslice
defpar.which_write = [2 1]; %all + mean

defpar.jobname='spm_realign';
defpar.walltime = '04:00:00';

defpar.sge = 0;
defpar.run = 0;
defpar.display=0;
par.redo=0;
par = complet_struct(par,defpar);

switch par.type
    case 'estimate'
        par.which_write = [0 1];
        
    case 'estimate_and_reslice'
        par.which_write = [2 1];
end

        

if iscell(fin{1})
    nsuj = length(fin);
else
    nsuj=1
end
skip=[];
for ns=1:nsuj
    
    if iscell(fin{1}) %
        ff = get_subdir_regex_files(fin{ns},par.file_reg);
        unzip_volume(ff);
        ff = get_subdir_regex_files(fin{ns},par.file_reg);
        
    else
        ff = fin;
    end
    
    %skip if mean exist
    of = addprefixtofilenames(ff(1),'mean');
    if ~par.redo
        if exist(of{1}),                skip = [skip ns];     fprintf('skiping subj %d because %s exist\n',ns,of{1});       end
    end
    
    for n=1:length(ff)
        ffsession = cellstr(ff{n}) ;
        clear ffs
        
        if length(ffsession) == 1 %4D file
            V = spm_vol(ffsession{1});
            for k=1:length(V)
                ffs{k} = sprintf('%s,%d',ffsession{1},k);
            end
        else
            ffs = ffsession;
        end
        
        jobs{ns}.spm.spatial.realign.estwrite.data{n} = ffs';
        
        %         switch par.type
        %             case 'estimate'
        %                 jobs{ns}.spm.spatial.realign.estimate.data{n} =  ffs;
        %
        %             case 'estimate_and_reslice'
        %                 jobs{ns}.spm.spatial.realign.estwrite.data{n} = ffs;
        %         end
        
    end
    
    %skip if last one exist
    of = addprefixtofilenames(ffsession(end),par.prefix);
    if ~par.redo
        if exist(of{1}),                skip = [skip ns];     fprintf('skiping subj %d because %s exist\n',ns,of{1});       end
    end
    
    
    %     switch par.type
    %         case 'estimate'
    %
    %             jobs{ns}.spm.spatial.realign.estimate.eoptions.quality = 1;
    %             jobs{ns}.spm.spatial.realign.estimate.eoptions.sep = 4;
    %             jobs{ns}.spm.spatial.realign.estimate.eoptions.fwhm = 5;
    %             jobs{ns}.spm.spatial.realign.estimate.eoptions.rtm = 1;
    %             jobs{ns}.spm.spatial.realign.estimate.eoptions.interp = 2;
    %             jobs{ns}.spm.spatial.realign.estimate.eoptions.wrap = [0 0 0];
    %             jobs{ns}.spm.spatial.realign.estimate.eoptions.weight = '';
    
    jobs{ns}.spm.spatial.realign.estwrite.eoptions.quality = 1;
    jobs{ns}.spm.spatial.realign.estwrite.eoptions.sep = 4;
    jobs{ns}.spm.spatial.realign.estwrite.eoptions.fwhm = 5;
    jobs{ns}.spm.spatial.realign.estwrite.eoptions.rtm = 1;
    jobs{ns}.spm.spatial.realign.estwrite.eoptions.interp = 2;
    jobs{ns}.spm.spatial.realign.estwrite.eoptions.wrap = [0 0 0];
    jobs{ns}.spm.spatial.realign.estwrite.eoptions.weight = '';
    jobs{ns}.spm.spatial.realign.estwrite.roptions.which = par.which_write; %all + mean images
    jobs{ns}.spm.spatial.realign.estwrite.roptions.interp = 4;
    jobs{ns}.spm.spatial.realign.estwrite.roptions.wrap = [0 0 0];
    jobs{ns}.spm.spatial.realign.estwrite.roptions.mask = 1;
    jobs{ns}.spm.spatial.realign.estwrite.roptions.prefix = 'r';
    
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

