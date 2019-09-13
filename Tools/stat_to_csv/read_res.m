function [param] = read_res(fin,par)

if ~exist('par','var')
    par = ''; % for defpar
end
defpar.pct  = 0; % Parallel Computing Toolbox
defpar.redo = 0;
defpar.out_format = 'cell'; %'cell or table'
defpar.sort = 1;

par = complet_struct(par,defpar);

pct = par.pct;

if ischar(fin), fin = {fin}; end

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



[r h] = readtext(fin,',','','','empty2NaN');

is_vector = 0; % ie multiple subjects

%decide if multiple values 
if min(size(r))>2
    is_vector=1;
end
   
if is_vector % assume suj in line value in columns
    hdr = r(1,1:end)';
    val = r(2:end,1:end)';

else
    if size(r,1)> size(r,2) %collumn
        %val = cell2mat(r(2:end,2))' ;
        val = (r(2:end,2))' ;
        hdr = r(2:end,1)';
    else %line
        %val = cell2mat(r(2,2:end))' ;
        val = (r(2,1:end))' ;
        hdr = r(1,1:end)';
    end
    
end


hdr = nettoie_dir(hdr);
if par.sort
    [hdr indh] = sort(hdr);
else
    indh=1:length(hdr);
end

if is_vector
    val = val(indh,:);
else
    val = val(indh);
end

%cout.suj_file = fin;

for k=1:length(hdr)
    if is_vector
        if ischar(val{k,1})
            cout.(hdr{k}) = val(k,:);
        else
            cout.(hdr{k}) = cell2mat(val(k,:)); %val{k,:}; %vals(:,k);
        end
    else
        cout.(hdr{k}) = val{k}; %vals(:,k);
    end
end


end