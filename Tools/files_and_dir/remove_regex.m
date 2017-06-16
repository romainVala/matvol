function [accpeted, rejected] = remove_regex(inputlist, reg_ex)
% REMOVE_REGEX removes elements from a list corresponding to the regular
% exression.
%
% note : the 'inputlist' will remain a char or a cell, depending on its
% nature.
%

%% Check input arguments

if nargin ~= 2
    error('inputlist & reg_ex must be defined')
end


%% Prepare inputs and outputs format

reg_ex = cellstr(reg_ex); % avoid problems of class or dimensions

% If the inputlist is char, we want the accpeted to also be char
makeitchar = 0;
if ischar(inputlist)
    inputlist  = cellstr(inputlist);
    makeitchar = 1;
end


%% Remove the elements corresponding do the regexp

ind_to_remove = [];

for line = 1:length(inputlist)
    
    for nb_reg = 1:length(reg_ex)
        if  ~isempty( regexp(inputlist{line}, reg_ex{nb_reg}, 'once') )
            ind_to_remove = [ind_to_remove line]; %#ok<AGROW>
            break
        end
    end
    
    
end

accpeted                = inputlist; % copy
accpeted(ind_to_remove) = [];        % remove the rejected elements

rejected                = inputlist(ind_to_remove);

if makeitchar
    accpeted = char(accpeted);
    rejected = char(rejected);
end


end % function
