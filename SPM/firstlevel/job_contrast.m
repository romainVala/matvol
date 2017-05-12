function jobs = job_contrast(stat_dir,params)

defpar.show=1;
defpar.delete_previous=0;

params = complet_struct(params,defpar);


if isfield(params.contrast,'values')
    names = params.contrast.names;
    values = params.contrast.values;
    types = params.contrast.types;
    
elseif isfield(params.contrast,'string_def')
    [names, values, types] = setContrastsFromOnsetMatfiles(params);
    
elseif isfield(params.contrast,'mfile')
    
    evalstr = ['[names, values,types] = ' params.contrast.mfile ';'];
    eval(evalstr);
    
end

for nbjobs=1:length(stat_dir)
        
    jobs{nbjobs}.spm.stats.con.spmmat = cellstr(fullfile(stat_dir{nbjobs},'SPM.mat'));
    
    for i=1:length(names)
        switch types{i}
            case 'T'
                jobs{nbjobs}.spm.stats.con.consess{i}.tcon.name = names{i};
                jobs{nbjobs}.spm.stats.con.consess{i}.tcon.convec = values{i};
                jobs{nbjobs}.spm.stats.con.consess{i}.tcon.sessrep = 'none';
            case 'F'
                jobs{nbjobs}.spm.stats.con.consess{i}.fcon.name = names{i};
                for j=1:size(values{i},1)
                    jobs{nbjobs}.spm.stats.con.consess{i}.fcon.convec{j} = values{i}(j,:);
                end
                jobs{nbjobs}.spm.stats.con.consess{i}.fcon.sessrep = 'none';
        end
    end
    
    jobs{nbjobs}.spm.stats.con.delete = params.delete_previous;
        

end

if params.show
    spm_jobman('interactive',jobs)
    
end
