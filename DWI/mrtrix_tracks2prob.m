function [job fout] = mrtrix_tracks2prob(intrk,ref,par,jobappend)
%input trk output volume ref volume or ref voxel size

if ~exist('par','var'), par='';end
if ~exist('jobappend','var'), jobappend ='';end

defpar.volout = {};
defpar.jobname = 'mrtrix_track2prob';
defpar.tck_weights=1; % either 1 to find the default [intrack]_weights.txt or a cell of path

par = complet_struct(par,defpar);

if isstr(intrk),    intrk=cellstr(intrk);end

volout = par.volout;
if isstr(volout),    volout = repmat({volout},size(intrk));end

do_voxsize=0;
if any(size(intrk)-size(ref))
    if isnumeric(ref)
        ref={ref}; ref = repmat(ref,size(intrk));
        do_voxsize=1;
    else
        error('rrr \n the 2 input must have the same size\n')
    end
    
else
    if isnumeric(ref)
        ref={ref}; ref = repmat(ref,size(intrk));
        do_voxsize=1;
    end
end


job={};

for k=1:length(intrk)
    alltrk = cellstr(intrk{k});

    %Automaticaly find the weigh names and check if exist
    if isnumeric(par.tck_weights) && par.tck_weights
        fweight = change_file_extension(alltrk,'.txt');
        fweight = addsuffixtofilenames(fweight,'_weights');
        tckweights = fweight;
        fweight_exist=1;
        for rrk=1:length(fweight)
            if ~exist(fweight{rrk},'file'),
                fweight_exist=0; fprintf('\nWARNING no weiths %s\n',fweight{rrk});
                break
            end
        end
        if ~fweight_exist, tckweights='';end
    else
        tckweights ='';
    end
    
% 
%     if ~isempty( par.tck_weights)
%         tckweights = cellstr(par.tck_weights{k});
%     else
%         tckweights = '';
%     end

    for kv=1:length(alltrk)
        [dir_mrtrix ff ] = fileparts(alltrk{kv});
        
        if ~isempty(volout)
            out = volout{k}(kv,:);
        else
            out = fullfile(dir_mrtrix,[ff '_prob.nii']);
        end
        
        
        if ~isempty( tckweights)
            cmd = sprintf('tckmap -force -tck_weights_in %s',tckweights{kv});
        else
            cmd = sprintf('tckmap -force');
        end
        
        if do_voxsize
            cmd = sprintf('%s -vox %d %s - |mrconvert - -force %s -datatype Int32 \n',...
                cmd,ref{k},alltrk{kv},out);
        else
            cmd = sprintf('%s -template %s %s - |mrconvert - -force %s -datatype Int32 \n',...
                cmd,ref{k},alltrk{kv},out);
        end
        
        job{end+1} = cmd;
        ffout{kv} = out;
    end
    fout{k} = char(ffout);
end

do_cmd_sge(job,par,jobappend);
