function do_delete(cell_to_delete,ask)
% DO_DELETE deletes all files or dirs in the cell. ask=0/1 to ask for a
% confirmation.


%% Check input arguments

if nargin < 2
    ask = 1;
end

if nargin < 1
    error('Not enough inpur argument')
end


%% Main

% isdir ?
ctd = char(cell_to_delete);
if isdir(deblank(ctd(1,:)))
    ddir = 1;
else
    ddir = 0;
end

% ask confirmation ?
if ask
    fprintf('[%s]: Are you sure you want to delete those %d files/dirs \n',mfilename,size(ctd,1))
    R = input(['[' mfilename ']: yes or no \n'],'s');
else
    R='yes';
end

% do the delete ...
if any(strcmpi(R,{'yes','y'}))
    
    for k=1:size(ctd,1)
        
        if ddir
            cmd = (['rm -rf ', deblank(ctd(k,:))]);
            unix(cmd);
            
        else
            delete(deblank(ctd(k,:)));
        end
        
    end
    
    fprintf('[%s]: done \n', mfilename);
    
else
    
    fprintf('[%s]: nothing done \n', mfilename);
    
end

end % function
