function [fout, fout_not_exist] = change_prefix_path(fin,path_to_remove,new_path)
%[fout, fout_not_exist] = change_prefix_path(fin,path_to_remove,new_path)
%it will change the path_to_remove to new_path for each files or dir in fin
%if a second output argument is given it give in 2 separate variable the
%new file that exist and the one that does not exist


fout=cell(size(fin));
fout_not_exist=cell(size(fin));
ii1 = zeros(size(fout));
ii2 = zeros(size(fout));
        
check_file_exist = 0;
if nargout>1, check_file_exist=1; end

if check_file_exist
    for k=1:length(fin)
        
        ff=fin{k};
        %if multiple line per cell (idem multiple file per subjects)
        clear ffo ffmiss
        for kk=1:size(ff,1)
            
            one_path = ff(kk,:);
            one_path(1:length(path_to_remove))='';
            one_path = fullfile(new_path,one_path);
            
            if exist(one_path)
                ffo{kk} = one_path;
                ii2(k)=1;
            else
                ffmiss{kk} = one_path;
                ii1(k)=1;
            end
            
        end
        
        if exist('ffo','var'),        fout{k} = char(ffo); end
        if exist('ffmiss','var'),     fout_not_exist{k} = char(ffmiss); end
        
    end
    
else
    for k=1:length(fin)
        
        ff=fin{k};
        %if multiple line per cell (idem multiple file per subjects)
        
        for kk=1:size(ff,1)
            
            one_path = ff(kk,:);
            one_path(1:length(path_to_remove))='';
            one_path = fullfile(new_path,one_path);
            
            ffo{kk} = one_path;
        end
        
        fout{k} = char(ffo);
        
    end
    
end

if check_file_exist
    fout(ii1==1)='';
    fout_not_exist(ii2==1)='';    
end

