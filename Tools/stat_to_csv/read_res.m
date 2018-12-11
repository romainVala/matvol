function [param] = read_res(fin,par)

if ~exist('par','var')
    par = ''; % for defpar
end
defpar.pct  = 0; % Parallel Computing Toolbox
defpar.redo = 0;

par = complet_struct(par,defpar);

pct = par.pct; 

%% Main loop

param = cell(size(fin));

if pct
    
    parfor idx = 1 : numel(fin)
        param{idx} = parse_csv(fin{idx},par);
    end
    
else
    
    for idx = 1 : numel(fin)
        param{idx} = parse_csv(fin{idx},par);
    end
    
end

end% function

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [cout] = parse_csv(fin,par)



[r h] = readtext(fin);

% not working if some val are string
%    val = cell2mat(r(h.numberMask))';
%    hdr = r(h.stringMask)';
% so assume first line is hdr second is val and first collum only is a string
%if ischar(r{2,1})
    if size(r,1)> size(r,2) %collumn
        %val = cell2mat(r(2:end,2))' ;
        val = (r(2:end,2))' ;
        hdr = r(2:end,1)';
    else %line
        %val = cell2mat(r(2,2:end))' ;
        val = (r(2,2:end))' ;
        hdr = r(1,2:end)';
    end
%else
%    val = cell2mat(r(h.numberMask))';
%    hdr = r(h.stringMask)';
%end

hdr = nettoie_dir(hdr);

[hdr indh] = sort(hdr);
val = val(indh);

cout.suj = get_parent_path(fin);

for k=1:length(hdr)
    cout.(hdr{k}) = val{k}; %vals(:,k);    
end


end