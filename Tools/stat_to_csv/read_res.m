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
function [varargout] = parse_csv(fin,par)

ind_to_remove=[];
if ischar(fin)
    fin={fin};
end

for k=1:length(fin)
    if k==2
        keyboard
    end
    
    [r h] = readtext(fin{k});
    
    % not working if some val are string
    %    val = cell2mat(r(h.numberMask))';
    %    hdr = r(h.stringMask)';
    % so assume first line is hdr second is val and first collum only is a string
    if ischar(r{2,1})
        
        val = cell2mat(r(2,2:end))' ;
        hdr = r(1,2:end)';
    else
        val = cell2mat(r(h.numberMask))';
        hdr = r(h.stringMask)';
    end
    
    [hdr indh] = sort(hdr);
    val = val(indh);
    
    if k==1
        hdrref=hdr;
    end
    if length(hdr)~=length(hdrref)
        fprintf('prb with %s\n',fin{k});
        ind_to_remove(end+1) = k;
        keyboard
        continue
    end
    
    if any(any(char(hdr)-char(hdrref)))
        %error('not the same label')
        fprintf('prb with %s\n',fin{k});
        ind_to_remove(end+1) = k;
        keyboard
        continue
    end
    
    vals(k,:) = val;
    
end

fin(ind_to_remove) = '';
cout.suj = get_parent_path(fin);
cout.ind_to_remove = ind_to_remove;

for k=1:length(hdr)
    cout = setfield(cout,hdr{k},vals(:,k));
    
end

if nargout==1
    varargout{1} = cout;
elseif nargout==2
    varargout{1} = hdrref;
    varargout{2} = vals;
end
end