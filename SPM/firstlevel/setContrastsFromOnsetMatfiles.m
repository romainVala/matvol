function [names, values, types] = setContrastsFromOnsetMatfiles(p)
 
%to be remove
%to be readapt in job_fist_level_contrast to have the possibily to define contrast by regressor name
% for instance {'MotL',1,'Rest',0}, will look in the desing matrix regressor name MotL and Rest and deduce the contrast vector


%% Create real onset matfiles list
onsFileList = {};
for o = 1:length(p.onset_matfile)
    onschk = fullfile(p.subjectdir, p.onset_matfile{o});
    onspath = fileparts(onschk);
    onsdir = dir(onschk);
    
    for d = 1:length(onsdir)
        if exist(fullfile(onspath, onsdir(d).name), 'file')
            onsFileList = [onsFileList fullfile(onspath, onsdir(d).name)];
        end
    end
end

nbOnsFile = length(onsFileList);

%%
for iContrast = 1:length(p.contrast.string_def) % Loop on contrasts
    L = length(p.contrast.string_def{iContrast});
    if mod(L,2) % If p.contrast.string_def has an odd number of members
        error('parameters.contrast.string_def: bad format');
    end
    
    values{iContrast} = searchCondInOnsetMatfiles(onsFileList,p.contrast.string_def{iContrast}{2}, p.rp) * p.contrast.string_def{iContrast}{1};
    
    for k = 3:2:L
        if p.contrast.string_def{iContrast}{k}
            values{iContrast} = values{iContrast} + searchCondInOnsetMatfiles(onsFileList, p.contrast.string_def{iContrast}{k+1}, p.rp) * p.contrast.string_def{iContrast}{k};
        end
    end
end

%% "names" variable
names = {};
if isfield(p.contrast,'name')
    names = p.contrast.name;
end

% If there are not enough names in the "names" variable
for i = (length(names)+1):length(p.contrast.string_def)
    n = '';
    if p.contrast.string_def{i}{1} == -1
        n = strcat(n, '-');
    end
    
    for j = 2:length(p.contrast.string_def{i})
        switch p.contrast.string_def{i}{j}
            case 1
                n = strcat(n, '+');
            case -1
                n = strcat(n, '-');
            otherwise
                n = strcat(n, p.contrast.string_def{i}{j});
        end
    end
    
    names{i} = n;
end

%% "types" variable
types = {};
if isfield(p.contrast, 'type')
    types = p.contrast.type;
end

% If there are not enough types in the "types" variable
for i = (length(types)+1):length(p.contrast.string_def)
    types{i} = 'T';
end

ind_to_remove='';
for k=1:length(values)
  if ~any(values{k})
    ind_to_remove(end+1) = k;
  end
end

if ~isempty(ind_to_remove)
  for k=1:length(ind_to_remove)
    fprintf('removing contrast %s\n',names{ind_to_remove(k)})
  end
  names(ind_to_remove)='';
  values(ind_to_remove)='';
  types(ind_to_remove)='';
  
end

