function [param] = read_res(fin,par)

if ~exist('par','var')
    par = ''; % for defpar
end
defpar.pct  = 0; % Parallel Computing Toolbox
defpar.redo = 0;
defpar.out_format = 'cell'; %'cell or table'

par = complet_struct(par,defpar);

pct = par.pct;

%% Main loop

if strcmp(par.out_format, 'cell')
    param = cell(size(fin));
end

%param = repmat(struct,size(fin));

if pct
    
    if strcmp(par.out_format, 'cell')
        parfor idx = 1 : numel(fin)
            param{idx} = parse_csv(fin{idx},par);            
        end
    else %table
        parfor idx = 1 : numel(fin)
            param(idx) = parse_csv(fin{idx},par);
        end
        
    end
     
else
    if strcmp(par.out_format, 'cell')
        for idx = 1 : numel(fin)
            param{idx} = parse_csv(fin{idx},par);            
        end
    else %table
        for idx = 1 : numel(fin)
            param(idx) = parse_csv(fin{idx},par);
        end
        
    end
    
end

if strcmp(par.out_format, 'table')
    param = struct2table(param);
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
is_vector = 0;

if size(r,1)> size(r,2) %collumn
    %val = cell2mat(r(2:end,2))' ;
    val = (r(2:end,2))' ;
    hdr = r(2:end,1)';
    if ~ischar(hdr{1}) %may be multiple values
        hdr = r(1,1:end)';
        val = r(2:end,1:end)';
        is_vector=1;
    end        
else %line
    %val = cell2mat(r(2,2:end))' ;
    val = (r(2,1:end))' ;
    hdr = r(1,1:end)';
end
%else
%    val = cell2mat(r(h.numberMask))';
%    hdr = r(h.stringMask)';
%end

hdr = nettoie_dir(hdr);

[hdr indh] = sort(hdr);
if is_vector
    val = val(indh,:);
else
    val = val(indh);
end


cout.suj = get_parent_path(fin);

for k=1:length(hdr)
    if is_vector
        cout.(hdr{k}) = cell2mat(val(k,:)); %val{k,:}; %vals(:,k);
    else
        cout.(hdr{k}) = val{k}; %vals(:,k);
    end
end


end