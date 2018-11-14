function t = merge_table(varargin)
%
%

% https://fr.mathworks.com/matlabcentral/answers/179290-merge-tables-with-different-dimensions

%% Check input arguments

N = numel(varargin);

for n = 1 : N
    assert( istable(varargin{n}), 'All inputs must be table' )
end


%% Merge all tables, 1 by 1

for n = 2 : N
    
    % Select the 2 tables to merge ----------------------------------------
    
    if n == 2
        t1 = varargin{1}; % initialize with the first table
    else
        t1 = t;
    end
    
    t2 = varargin{n};
    
    
    % Merge process -------------------------------------------------------
    
    t1colmissing = setdiff(t2.Properties.VariableNames, t1.Properties.VariableNames);
    t2colmissing = setdiff(t1.Properties.VariableNames, t2.Properties.VariableNames);
    t1 = [t1 array2table(nan(height(t1), numel(t1colmissing)), 'VariableNames', t1colmissing)]; %#ok<AGROW>
    t2 = [t2 array2table(nan(height(t2), numel(t2colmissing)), 'VariableNames', t2colmissing)]; %#ok<AGROW>
    for colname = t1colmissing
        if iscell(t2.(colname{1}))
            t1.(colname{1}) = cell(height(t1), 1);
        end
    end
    for colname = t2colmissing
        if iscell(t1.(colname{1}))
            t2.(colname{1}) = cell(height(t2), 1);
        end
    end
    t = [t1; t2];
    
end % for each tables


end % function
