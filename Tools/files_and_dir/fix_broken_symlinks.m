
function  fix_broken_symlinks(folderpath, oldpath,newpath,par)
% fix_broken_symlink Replace oldpath with newpath in all links containing 
%                    the oldpath string. 
%
%  Input :
%         folderpath : (cellstr) path to forlder
%            oldpath : string part of the old path that need to be change
%            newpath : string part of the new path to replace
%            
%            par     : matvol parameters 
%
% ---------EXAMPLE---------
%
%   folderpath = {'path to dir'};
%   fix_broken_symlinks(folderpath,'/iss01/','/iss02/');
%   fix_broken_symlinks(folderpath,'/lustre/iss01/','/iss/');
%
%
% -------------------------------------------------------------------------

if ~exist('par'),par ='';end

defpar.sge      = 0;
defpar.jobname  = 'mean';
defpar.mem      = '16G';
defpar.waltime  = '48';
defpar.nbthread = 4 ;

par = complet_struct(par,defpar);


if par.sge 
    code = gencode(folderpath, 'folderpath')';
    
    code{end+1} = sprintf(' fix_broken_symlinks(folderpath,''%s'',''%s'');',oldpath, newpath);
     
    do_cmd_matlab_sge({code}, par);

else


cmde = sprintf('cd %s\n', folderpath{1});
cmde = sprintf('%s ls -fl | grep "^l"',cmde);


[status,links] = unix(cmde);

if ~isempty(links) && status == 0
    
    change_links(folderpath,links,oldpath,newpath);
    
end
dirs = gdir(folderpath,'.*');
if ~isempty(dirs)
    for i = 1: length(dirs)
        
        fix_broken_symlinks(dirs(i), oldpath,newpath); 
        
    end
end    
    
end    
end
   
%PathName = uigetdir;

function change_links(folderpath,links,oldpath,newpath)

if isdir(folderpath)
    cmd = sprintf('cd %s\n', folderpath{1});
    links = splitlines(links);
    for ln = 1:length(links)-1
        
        [name, linkpath] = split_link(links{ln});

        if contains(linkpath,oldpath)
            newlinkpath = strrep(linkpath,oldpath,newpath);
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



 