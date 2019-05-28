function process_mrtrix_tracktoV3(sdata,seed,par)
%function process_mrtrix_trackto(sdata,seed,par)

if ~exist('par')
    par='';
end
defpar.mask='mask_mrtrix.nii.gz';
defpar.grad_file = 'grad.b';
defpar.type='iFOD2';  % FACT, iFOD1, iFOD2, Nulldist, SD_STREAM, Seedtest, VecStream, WBFACT  SD_PROB.

defpar.target_type = 'all'; %or 'single'
defpar.track_num = 1000;
defpar.track_maxnum = '';
defpar.target='';
defpar.track_name='';
defpar.curvature=1;
defpar.stop = 0;
defpar.onedirection = 0;
defpar.exclude = '';
defpar.nthreads = 1;
defpar.option = '';

defpar.sge = 1;
defpar.jobname = 'mrtrix_trackto';

defpar.act = '';
defpar.output_seeds = '';
defpar.do_sift=0;

par = complet_struct(par,defpar);

par.sge_nb_coeur = par.nthreads ;

if ischar(par.mask)
    par.mask  = get_file_from_same_dir(sdata,par.mask);
end

cwd=pwd;
job={};

for nbsuj = 1:length(sdata)
    
    [dir_mrtrix ff ] = fileparts(sdata{nbsuj});
    
    [pp seed_name ex] = fileparts(seed{nbsuj});
    
    seed_file = char(seed{nbsuj});
    
    mask_filename = par.mask{nbsuj};
    
    cmd = sprintf('LD_LIBRARY_PATH=;tckgen %s -force -seed_image %s -select %d -algorithm %s -grad %s -nthreads %d',...
        par.option,seed_file, par.track_num, par.type, fullfile(dir_mrtrix,par.grad_file), par.nthreads);
    
    if ~isempty(par.act)
        cmd = sprintf('%s -act %s',cmd, par.act{nbsuj});
    else % with act you do not need to specify the mask
        cmd = sprintf('%s -mask %s',cmd, mask_filename);
    end
    
    if ~isempty(par.track_maxnum)
        cmd = sprintf('%s -seeds %d',cmd,par.track_maxnum);
    end
    
    if par.stop
        cmd = sprintf('%s -stop',cmd);
    end
    
    if par.onedirection
        cmd = sprintf('%s -seed_unidirectional',cmd);
    end
    
    
    if ~isempty(par.output_seeds)
        output = par.output_seeds;
        cmd = sprintf('%s -output_seeds %s',cmd, output{nbsuj});
    end
    
    if ~isempty(par.exclude)
        exclude_file = cellstr(par.exclude{nbsuj});
        for nbe = 1:length(exclude_file)
            cmd = sprintf('%s -exclude %s',cmd,exclude_file{nbe});
        end
    end
    
    if isempty(par.track_name), par.track_name=['seed' change_file_extension(seed_name,'') ]; end
    if iscell(par.track_name)
        track_name = par.track_name{nbsuj};
    else
        track_name = par.track_name;
    end
    
    if strcmp(track_name(1),'/')==0
        track_name = fullfile(dir_mrtrix,track_name);
    end
    
    if ~isempty(par.target)
        target_file = cellstr(par.target{nbsuj});
        switch  par.target_type
            case 'all'
                
                for nbt=1:length(target_file)
                    %            [pp target_name] = fileparts(target_file{nbt});
                    %            target_name = change_file_extension(target_name,'');
                    %            trackname = [track_name '_to_' target_name];
                    
                    cmd = sprintf('%s -include %s  ',cmd,target_file{nbt});
                    
                end
                cmdtar = sprintf('%s %s %s.tck \n',cmd,sdata{nbsuj},track_name);
                
                job{end+1}  = cmdtar;
                
            case 'single'
                for nbt=1:length(target_file)
                    [pp target_name] = fileparts(target_file{nbt});
                    target_name = change_file_extension(target_name,'');
                    trackname = [track_name '_to_' target_name];
                    
                    %            cmdtar = sprintf('%s -include %s %s.tck ',cmd,target_file{nbt},trackname);
                    cmdtar = sprintf('%s -include %s %s %s.tck \n',cmd,target_file{nbt}, sdata{nbsuj}, trackname);
                    
                    job{end+1}  = cmdtar;
                end
        end
    else
        %        cmd = sprintf('%s %s.tck',cmd,track_name)
        cmd = sprintf('%s %s %s.tck \n',cmd, sdata{nbsuj}, track_name);
        
        job{end+1} = cmd;
    end
    
    if par.do_sift %warning only if one target
        cmd = job{end};
        
        if par.nthreads>1
            cmd = sprintf('%s\nLD_LIBRARY_PATH=; tcksift2 -nthreads %d',cmd,par.nthreads);
        else
            cmd = sprintf('%s\nLD_LIBRARY_PATH=; tcksift2 ',cmd);
        end
        cmd = sprintf('%s %s.tck %s %s_weights.txt',cmd,track_name,sdata{nbsuj},track_name);
        job{end} = cmd;
    end
    
    
end%for nbsuj = 1:length(sdata)

do_cmd_sge(job,par)
