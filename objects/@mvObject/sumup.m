function varargout = sumup( mvArray, remove_obj )
%SUMUP converts the mvArray into a table, and print it

if nargin < 2
    remove_obj = 1;
end

% To structure, because it's easer to convert into table
s = mvArray.toStruct;

if remove_obj
    
    % Remove the non builtin datatypes
    fields = fieldnames(s);
    for f = 1 : length(fields)
        if ~exist(class(mvArray(1).(fields{f})),'builtin')
            s = rmfield(s,fields{f});
        end
    end
    
end

% Convert to table
Table = struct2table(s,'AsArray',1);

% Output
if nargout
    varargout{1} = Table;
else
    disp(Table)
end

end % function
