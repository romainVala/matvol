function [ pathArray ] = toJob( mvArray, flag )
% TOJOB fetches serieArray.path, just as would do [ get_subdir_regex_multi ]
% flag means activate multilevel or not


%% Check input arguments

assert( isa(mvArray,'exam') || isa(mvArray,'serie') || isa(mvArray,'volume') || isa(mvArray,'stim') || isa(mvArray,'model') )

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
    end
end

assert( isnumeric(flag) && (flag==0 || flag==1) , 'flag must be 0 or 1' )


%% Print

pathArray = cell(size(mvArray,1),1);

for idx = 1:size(mvArray,1)
    
    if flag
        
        pathArray{idx} = {mvArray(idx,:).path};
        
        % to simulate the output of get_subdir_regex_multi
        if isempty(char(mvArray(idx,:).path))
            pathArray{idx} = {};
        end
        
    else
        
        pathArray{idx} = char(mvArray(idx,:).path);
        
        % to simulate the output of get_subdir_regex_multi
        if isempty(char(mvArray(idx,:).path))
            pathArray{idx} = '';
        end
        
    end
    
end

end % function
