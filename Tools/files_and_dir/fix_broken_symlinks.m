
function  fix_broken_symlinks(folderpath, oldpath,newpath)
% fix_broken_symlink replace oldpath with newpath




% /!\ the links in pathfolder and subfolders must have the same oldpath. 

% folderpath :  path to the root folder  



% ---------EXAMPLE---------
%
%   dir = {'path to dir'}
%   fix_broken_symlink(dir,{'/iss01/'},{'/iss02/'})


folderpath = cellstr(folderpath);
oldpath = cellstr(oldpath);
newpath = cellstr(newpath);

cmde = sprintf('cd %s\n', folderpath{1});
cmde = sprintf('%s ls -lrt | grep "^l"',cmde);


[status,links]=unix(cmde);

dirs = gdir(folderpath,'.*');
if ~isempty(links) && status == 0
    
    change_links(folderpath,links,oldpath,newpath);
    
end

if ~isempty(dirs)
    for i = 1: length(dirs)
        
        fix_broken_symlinks(dirs(i), oldpath,newpath); 
        
    end
end    
    
end    
   
%PathName = uigetdir;

function change_links(folderpath,links,oldpath,newpath)

if isdir(folderpath{1})
    cmd = sprintf('cd %s\n', folderpath{1});
    links = splitlines(links);
    for ln = 1:length(links)-1
        
        [name, linkpath] = split_link(links{ln});

        if contains(linkpath{1},oldpath{1})
            newlinkpath = strrep(linkpath,oldpath{1},newpath{1});
            cmd = sprintf('%s ln -fns %s %s\n',cmd,newlinkpath{1},name{1});
            
        end
        
    end
    unix(cmd);
end
    

end





function  [name, linkpath] = split_link(link)


pieces =split(link, ' ');

name = pieces(end-2);
linkpath = pieces(end);

end 



 