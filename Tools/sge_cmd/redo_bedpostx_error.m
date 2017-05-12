function  redo_bedpostx_error(bdir)

if ~exist('par')
    par='';
end

defpar.jobname='bedpost_again';
defpar.sge=1;

par = complet_struct(par,defpar);


cmd={};



logd = get_subdir_regex_one(bdir,'logs')
for ns=1:length(bdir)

    dd=dir(fullfile(logd{ns},'err*'));
            
    fc = get_subdir_regex_files(bdir(ns),'commands.txt',1);
    
    for kk=1:length(dd)
       if dd(kk).bytes
           ii = findstr(dd(kk).name,'_');
           num_redoo = str2num( dd(kk).name(ii+1:end));
           
           cmd{end+1} = sprintf('command=`cat %s | head -%d | tail -1` ; exec $command',fc{1},num_redoo);
       end       
    end
    
    
    
end


do_cmd_sge(cmd,par)
