function [o no]=remove_regex(indir,reg_ex)


if ~iscell(reg_ex), reg_ex={reg_ex};end

o={};
no={};

ind_to_remove =[];

for nb_dir=1:length(indir)
    
    for nb_reg=1:length(reg_ex)
        if  ~isempty(regexp(indir{nb_dir},reg_ex{nb_reg}))
            ind_to_remove = [ind_to_remove nb_dir];
            break
        end
    end
    
    
end

o = indir;
no = indir(ind_to_remove);

o(ind_to_remove)='';
