function [ pathArray ] = toJob( mvArray, flag )
% TOJOB fetches serieArray.path, just as would do [ get_subdir_regex_multi ]
% flag means activate multilevel or not


%% Check input arguments

if nargin < 2
    switch class(mvArray)
        case 'exam'
            flag = 0;
        case 'serie'
            flag = 1;
        case 'volume'
            flag = 0;
        case 'stim'
            flag = 0;
        case 'model'
            flag = 0;
        case 'json'
            flag = 0;
        otherwise
            error('Unknown object class. Is it really an mvObject ?')
    end
end

assert( isnumeric(flag) && (flag==0 || flag==1 || flag==2) , 'flag must be 0, 1, 2' )


%% Print

pathArray = cell(size(mvArray,1),1);

for idx = 1:size(mvArray,1)
    
    if flag == 1
        
        pathArray{idx} = {mvArray(idx,:).removeEmpty.path}';
        
        % to simulate the output of get_subdir_regex_multi
        if isempty(char(mvArray(idx,:).path))
            pathArray{idx} = {};
        end
        
    elseif flag == 0
        
        pathArray{idx} = char(mvArray(idx,:).removeEmpty.path);
        
        % to simulate the output of get_subdir_regex_multi
        if isempty(char(mvArray(idx,:).path))
            pathArray{idx} = '';
        end
        
    end
    
end

if flag == 2
    
    pathArray = cell(size(mvArray,1),size(mvArray,2));

    for i = 1 : size(mvArray,1)
        for j = 1 : size(mvArray,2)
            pathArray{i,j} = {mvArray(i,j,:).path}';
        end
    end
    
end


end % function
