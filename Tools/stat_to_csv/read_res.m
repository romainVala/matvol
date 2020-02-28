function [param] = read_res(fin,par)

if ~exist('par','var')
    par = ''; % for defpar
end
defpar.pct  = 0; % Parallel Computing Toolbox
defpar.redo = 0;
defpar.out_format = 'cell'; %'cell or table'
defpar.sort = 1;
defpar.delimiter=',';
defpar.comment = '';
defpar.quotes = '';
defpar.options = 'empty2NaN';

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


%[r h] = readtext(fin,',','','','empty2NaN');
[r h] = readtext(fin,par.delimiter,par.comment,par.quotes,par.options);

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
        test_ind=1;
        if isempty(val{k,1}), for kk=1:length(val(k,:)); if ~isempty(val{k,kk}); test_ind=kk;end;end;end
        
        if ischar(val{k,test_ind})
            cout.(hdr{k}) = val(k,:);
        else
            the_val = val(k,:);
            ii= find(cellfun(@(x) isempty(x), the_val)); 
            for kk=1:length(ii), the_val{ii(kk)} = NaN;end
                
            cout.(hdr{k}) = cell2mat(the_val); %val{k,:}; %vals(:,k);
        end
    else
        cout.(hdr{k}) = val{k}; %vals(:,k);
    end
end


end